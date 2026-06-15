// Ember — state/world_controller.dart
//
// The single owner of the source of truth. WorldController is a Riverpod
// Notifier<EmberWorldState>: it holds the world, applies Intents (mutate ->
// persist), runs the offline catch-up on resume, and drives the live tick through
// WorldSimulation. The Flame layer OBSERVES this state (via a GameBridge) and
// DISPATCHES Intents back — it never mutates the world itself.
//
// DETERMINISM BOUNDARY: the controller is the ONLY place in the read path allowed
// to touch the wall clock (via EmberClock, for lastSeenMs stamps + the offline
// window). The actual world transform is always WorldSimulation.advance, which
// stays clock/random-free; chance flows through the world's serialized EmberRng.
//
// The controller depends on the ABSTRACT SimRegistry (via simRegistryProvider),
// never the concrete registry — so it builds + ticks the world without knowing a
// concept leaf exists.

import 'dart:async';

// `show WidgetsBinding` only: importing all of widgets.dart would pull in
// Flutter's own `Intent` class, which collides with this module's `Intent`
// sealed type (intents.dart) and breaks the dispatch() switch.
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../activity/activity_result.dart';
import '../activity/apply_reducer.dart';
import '../contracts/event_resolver.dart';
import '../contracts/placeable_def.dart';
import '../contracts/sim_registry.dart';
import '../core/constants.dart';
import '../core/ember_clock.dart';
import '../core/ember_rng.dart';
import '../core/enums.dart';
import '../core/geometry.dart';
import '../core/ids.dart';
import '../core/result.dart';
import '../data/models/npc.dart';
import '../data/models/placeable.dart';
import '../data/models/resource_cost.dart';
import '../data/models/save_envelope.dart';
import '../data/models/tile.dart';
import '../data/models/tile_grid.dart';
import '../data/models/world_event.dart';
import '../data/models/world_state.dart';
import '../data/repository/save_repository.dart';
import '../data/seed/world_seed.dart';
import '../sim/away_digest.dart';
import '../sim/offline_catchup.dart';
import '../sim/systems/fire_coverage.dart';
import '../sim/systems/resource_system.dart';
import '../sim/world_simulation.dart';
import 'intents.dart';
import 'providers.dart';
import 'seams.dart';

/// The away digest from the most recent bootstrap/resume catch-up, or null if
/// none has run (or it was empty). The UI reads + clears this.
final StateProvider<AwayDigest?> awayDigestProvider =
    StateProvider<AwayDigest?>((Ref ref) => null);

/// A rolling feed of event outcomes that fired during LIVE ticks (for toasts).
/// Capped; the UI drains it. Separate from the world so it never bloats the save.
final StateProvider<List<EventOutcome>> liveOutcomesProvider =
    StateProvider<List<EventOutcome>>((Ref ref) => const <EventOutcome>[]);

/// True once [WorldController.bootstrap] has finished (load + catch-up). The UI
/// shows a loader until then.
final StateProvider<bool> worldReadyProvider =
    StateProvider<bool>((Ref ref) => false);

/// The world controller provider. State IS the [EmberWorldState] (per the frozen
/// contract). Observers watch this; the game dispatches Intents into the notifier.
final NotifierProvider<WorldController, EmberWorldState> worldControllerProvider =
    NotifierProvider<WorldController, EmberWorldState>(WorldController.new);

class WorldController extends Notifier<EmberWorldState> {
  /// Pure folders, constructed once (stateless).
  static const ApplyReducer _reducer = ApplyReducer();
  static const FireCoverageSystem _coverage = FireCoverageSystem();

  /// Max live outcomes kept in the rolling feed before the oldest are dropped.
  static const int _maxLiveOutcomes = 20;

  late SimRegistry _registry;
  late WorldSimulation _sim;
  late OfflineCatchup _catchup;
  late ResourceSystem _resources;

  EmberClock get _clock => ref.read(clockProvider);
  SaveRepository get _repo => ref.read(saveRepositoryProvider);

  @override
  EmberWorldState build() {
    _registry = ref.read(simRegistryProvider);
    _sim = WorldSimulation(_registry);
    _catchup = OfflineCatchup(_sim);
    _resources = ResourceSystem(_registry);
    // Synchronous starting point: a fresh seeded world. bootstrap() replaces it
    // with the loaded + caught-up save (or persists this fresh one).
    return WorldSeed.newGame();
  }

  // ===========================================================================
  // Lifecycle
  // ===========================================================================

  /// Loads the save (or starts a new game), runs offline catch-up to now, and
  /// persists. Stamps the away digest for the UI. Idempotent-ish: safe to call
  /// once at startup.
  Future<void> bootstrap() async {
    final int nowMs = _clock.nowMs();
    final SaveEnvelope? envelope = await _repo.load();

    if (envelope == null) {
      // New game: seed, stamp lastSeen = now, persist.
      final EmberWorldState fresh =
          WorldSeed.newGame().copyWith(lastSeenMs: nowMs);
      state = fresh;
      await _persist();
      _setAwayDigest(null);
    } else {
      // Resume: replay the away window through the SAME sim the live loop uses.
      final CatchupResult result = _catchup.run(envelope.state, nowMs);
      state = result.state;
      await _persist();
      _setAwayDigest(result.digest.isEmpty ? null : result.digest);
    }

    ref.read(worldReadyProvider.notifier).state = true;
  }

  /// Re-runs offline catch-up for the gap since lastSeenMs (used on app resume
  /// without a full reload). Stamps a fresh away digest.
  Future<void> resume() async {
    final int nowMs = _clock.nowMs();
    final CatchupResult result = _catchup.run(state, nowMs);
    state = result.state;
    await _persist();
    _setAwayDigest(result.digest.isEmpty ? null : result.digest);
  }

  /// Stamps lastSeenMs = now and persists (used on app pause/background).
  Future<void> persistNow() async {
    state = state.copyWith(lastSeenMs: _clock.nowMs());
    await _persist();
  }

  /// Knowledge flag set true once the player has made the first-run site choice.
  /// The UI reads it to decide whether to show the site-selection flow.
  static const String kSiteChosenFlag = 'world.siteChosen';

  /// Whether the first-run site decision has been made.
  bool get siteChosen => state.knowledge.get(kSiteChosenFlag);

  /// Records the first-run village site decision: anchors [coord] as the village
  /// site (camera home / Elder spot) and marks the choice made. Persists.
  void setSiteTile(GridCoord coord) {
    state = state.copyWith(
      village: state.village.copyWith(siteTile: coord),
      knowledge: state.knowledge.set(kSiteChosenFlag),
    );
    _persistSoon();
  }

  /// Hard reset: wipe the save and start a brand-new game.
  ///
  /// Clearing [kSiteChosenFlag] makes [_EmberRoot] swap the WorldScreen subtree
  /// (its world-watching HUD ConsumerWidgets — the concept tracker, flood
  /// banner/reframe — PLUS the live-ticking EmberGame) out for the first-run
  /// site-selection screen.
  ///
  /// THE DEFUNCT-ELEMENT CRASH (tour loop restart): the old `newGame()` did the
  /// whole reset as ONE `state = WorldSeed.newGame()` notify. That single
  /// `worldControllerProvider` notification BOTH (a) flipped the site flag, which
  /// makes _EmberRoot rebuild and tear the WorldScreen subtree down, AND (b) was
  /// the very notification the soon-to-be-torn-down HUD ConsumerStatefulWidgets
  /// were subscribed to. Riverpod's _notifyListeners fans a fresh world out to a
  /// HUD element in the SAME beat the swap is deactivating it — re-readying the
  /// tick a frame later then races the still-unmounting subtree — so a notify
  /// lands on a DEFUNCT element (the markNeedsBuild assertion). Freezing
  /// worldReadyProvider alone was not enough: the reseed's own `state =` notify
  /// still hit the HUD across the swap.
  ///
  /// FIX (defer the reseed past the unmount): split the reset into two notifies,
  /// separated by a post-frame so the old subtree FULLY unmounts in between.
  ///   1) Freeze the live tick (worldReadyProvider=false) so the old EmberGame
  ///      can't tick `state` across the swap.
  ///   2) Flip ONLY the site flag on the CURRENT (still-valid) world. This one
  ///      notify drives the world->site-selection swap; the HUD widgets it lands
  ///      on are still MOUNTED + active here (they tear down during the ensuing
  ///      build, after every markNeedsBuild has already returned — safe).
  ///   3) AWAIT a post-frame: the WorldScreen subtree (and its HUD world-watchers)
  ///      is now unmounted; only the freshly built SiteSelectionScreen watches the
  ///      world.
  ///   4) NOW reseed the full fresh world. This `state =` notify lands only on the
  ///      active SiteSelectionScreen — no defunct element exists to notify.
  ///   5) Re-ready on the next post-frame so the next world (built once a site is
  ///      chosen) ticks normally again.
  /// Determinism is untouched: the reseed is still a pure WorldSeed.newGame(seed)
  /// + a clock stamp; only the NOTIFY ordering changed, not the resulting state.
  Future<void> newGame({int seed = WorldSeed.defaultSeed}) async {
    await _repo.wipe();
    // 1) Freeze the live tick so the OLD game can't notify across the swap.
    ref.read(worldReadyProvider.notifier).state = false;
    // 2) Flip the site flag on the current world -> _EmberRoot swaps to
    //    site-selection. Notify lands on still-active widgets.
    state = state.copyWith(
      knowledge: state.knowledge.set(kSiteChosenFlag, false),
    );
    // 3) Let the old WorldScreen subtree (its HUD world-watchers) fully unmount
    //    before the reseed notify, so no defunct element is ever notified.
    await _nextFrame();
    // 4) Reseed the fresh world. Only the active SiteSelectionScreen watches it.
    state = WorldSeed.newGame(seed: seed).copyWith(lastSeenMs: _clock.nowMs());
    await _persist();
    _setAwayDigest(null);
    // 5) Re-ready once the new subtree has settled, so the next world ticks.
    await _nextFrame();
    ref.read(worldReadyProvider.notifier).state = true;
  }

  /// Completes after the next frame is rendered (post-frame). Used by [newGame]
  /// to let a being-swapped subtree finish unmounting between notifies.
  Future<void> _nextFrame() {
    final Completer<void> done = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => done.complete());
    // A frame may not be scheduled if nothing is dirty; nudge one so the
    // post-frame callback is guaranteed to run (and we never hang).
    WidgetsBinding.instance.scheduleFrame();
    return done.future;
  }

  // ===========================================================================
  // Live tick
  // ===========================================================================

  /// Advances the live simulation by [dtMs] of sim time (the game's render loop
  /// drives this in fixed-ish chunks). Collects any event outcomes into the live
  /// feed. Does NOT persist every tick (the game/lifecycle persists on a cadence
  /// + on pause) to avoid IO churn.
  void tick(int dtMs) {
    if (dtMs < WorldSimulation.stepMs) return;
    final SimStepResult result = _sim.advanceCollecting(state, dtMs);
    state = result.state;
    if (result.outcomes.isNotEmpty) {
      _pushLiveOutcomes(result.outcomes);
    }
  }

  // ===========================================================================
  // Intents
  // ===========================================================================

  /// Folds [intent] into a new world state. Most intents mutate + persist; the
  /// debug time-jump runs the sim. Placement validity is the game's job — a
  /// dispatched ConfirmPlace/MovePlace is trusted (cost is still re-checked here
  /// so the world can never go negative).
  void dispatch(Intent intent) {
    switch (intent) {
      case GatherIntent(:final EntityId nodeId):
        _gather(nodeId);
      case ConfirmPlace():
        _confirmPlace(intent);
      case MovePlace():
        _movePlace(intent);
      case RemovePlace(:final EntityId id):
        _removePlace(id);
      case TendFire(:final EntityId id):
        _tendFire(id);
      case AssignNpc():
        _assignNpc(intent);
      case CompleteActivity(:final ActivityResult result):
        _completeActivity(result);
      case AdvanceTimeDebug(:final int ms):
        _advanceTimeDebug(ms);
      case BeginPlace():
        // Transient: the ghost lives in the game layer until ConfirmPlace. No
        // world mutation, no persist.
        break;
      case StartActivity():
        // Transient: opening a scene is a game/UI concern; completion arrives as
        // CompleteActivity. No world mutation.
        break;
    }
  }

  // ---- Intent handlers ---------------------------------------------------

  void _gather(EntityId nodeId) {
    final Result<EmberWorldState> result = _resources.gather(state, nodeId);
    switch (result) {
      case Ok<EmberWorldState>(:final EmberWorldState value):
        state = value;
        _persistSoon();
      case Err<EmberWorldState>():
        // Gather failed (node missing/depleted): no-op; the game surfaces the
        // failure code if it wants to.
        break;
    }
  }

  void _confirmPlace(ConfirmPlace i) {
    final PlaceableDef? def = _registry.defFor(i.type);
    final ResourceCost cost = def?.cost ?? ResourceCost.empty;
    if (!state.stock.canAfford(cost)) return; // safety: never go negative.

    // Mint a deterministic id from a CLONE of the rng, then thread it back so the
    // entropy stream advances exactly once.
    final EmberRng rng = state.rng.clone();
    final EntityId id = ids.mint('placeable', rng);

    final Map<String, dynamic> ext = def == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.of(def.initialPayload);
    final Placeable placeable = Placeable(
      id: id,
      type: i.type,
      tier: i.tier,
      coord: i.coord,
      rotation: i.rotation,
      state: PlaceableState.ghost,
      buildProgress: 0.0,
      ext: ext,
    );

    final int w = def?.footprint.width ?? 1;
    final int h = def?.footprint.height ?? 1;
    final TileGrid tiles = _stampOccupant(state.tiles, i.coord, w, h, id);

    state = state.copyWith(
      placeables: <Placeable>[...state.placeables, placeable],
      tiles: tiles,
      stock: state.stock.spend(cost),
      rng: rng,
    );
    _persistSoon();
  }

  void _movePlace(MovePlace i) {
    final Placeable? p = state.placeableById(i.id);
    if (p == null) return;
    final PlaceableDef? def = _registry.defFor(p.type);
    final int w = def?.footprint.width ?? 1;
    final int h = def?.footprint.height ?? 1;

    // Free the old footprint, occupy the new one.
    TileGrid tiles = _clearOccupant(state.tiles, p.coord, w, h);
    tiles = _stampOccupant(tiles, i.coord, w, h, i.id);

    final List<Placeable> next = <Placeable>[
      for (final Placeable q in state.placeables)
        if (q.id == i.id)
          q.copyWith(coord: i.coord, rotation: i.rotation ?? q.rotation)
        else
          q,
    ];
    state = state.copyWith(placeables: next, tiles: tiles);
    _persistSoon();
  }

  void _removePlace(EntityId id) {
    final Placeable? p = state.placeableById(id);
    if (p == null) return;
    final PlaceableDef? def = _registry.defFor(p.type);
    final int w = def?.footprint.width ?? 1;
    final int h = def?.footprint.height ?? 1;

    final TileGrid tiles = _clearOccupant(state.tiles, p.coord, w, h);
    final List<Placeable> next = <Placeable>[
      for (final Placeable q in state.placeables)
        if (q.id != id) q,
    ];
    // Partial refund (half the build cost, scaled by how built it was).
    final ResourceCost refund =
        (def?.cost ?? ResourceCost.empty).refund(0.5 * p.buildProgress);
    state = state.copyWith(
      placeables: next,
      tiles: tiles,
      stock: state.stock.addCost(refund),
    );
    _persistSoon();
  }

  void _tendFire(EntityId id) {
    final Placeable? p = state.placeableById(id);
    if (p == null || !p.isActive) return;
    // The fire leaf owns the fuel semantics; the controller routes a generic
    // "tend" request into the ext bag the fire behavior reads next tick. Storing
    // a refuel request keeps the controller leaf-blind.
    final Map<String, dynamic> ext = Map<String, dynamic>.of(p.ext);
    final num pending = (ext[_kPendingTendKey] as num?) ?? 0;
    ext[_kPendingTendKey] = pending.toDouble() + EmberConstants.fireFuelPerTend;
    final List<Placeable> next = <Placeable>[
      for (final Placeable q in state.placeables)
        if (q.id == id) q.copyWith(ext: ext) else q,
    ];
    state = state.copyWith(placeables: next);
    _persistSoon();
  }

  void _assignNpc(AssignNpc i) {
    final Npc? npc = state.npcById(i.npcId);
    if (npc == null) return;
    final List<Npc> next = <Npc>[
      for (final Npc n in state.npcs)
        if (n.id == i.npcId)
          (i.nodeId == null
              ? n.copyWith(clearAssignment: true, state: AnimState.idle)
              : n.copyWith(assignedNodeId: i.nodeId, state: AnimState.work))
        else
          n,
    ];
    state = state.copyWith(npcs: next);
    _persistSoon();
  }

  void _completeActivity(ActivityResult result) {
    state = _reducer.apply(state, result);
    _persistSoon();
  }

  void _advanceTimeDebug(int ms) {
    if (ms < WorldSimulation.stepMs) return;
    final SimStepResult r = _sim.advanceCollecting(state, ms);
    state = r.state;
    if (r.outcomes.isNotEmpty) _pushLiveOutcomes(r.outcomes);
    _persistSoon();
  }

  // ===========================================================================
  // Debug helpers (scene-picker / review loop). Deterministic: they nudge the
  // serialized world + run the SAME sim the live/offline paths use. Not part of
  // the Intent set (they are dev-only and never persisted as commands).
  // ===========================================================================

  /// DEBUG: force the day/night clock into the middle of the night window so the
  /// reviewer can see night ambience + predator pressure immediately.
  void debugForceNight() {
    const double mid = (EmberConstants.nightStartPhase +
            EmberConstants.nightEndPhase) /
        2;
    state = state.copyWith(dayNight: state.dayNight.copyWith(phase: mid));
    _persistSoon();
  }

  /// DEBUG: force the day/night clock into clear mid-morning daytime so the
  /// reviewer can escape the night/flood confusion (and so the flood is shown in
  /// daylight, where the rising water reads unmistakably rather than under a
  /// night scrim). Phase 0.25 is well before the night window (0.55).
  void debugForceDay() {
    state = state.copyWith(dayNight: state.dayNight.copyWith(phase: 0.25));
    _persistSoon();
  }

  /// DEBUG: schedule a flood due NOW and leave it unresolved so the flood
  /// overlay (rising water + cyan wash) and the HUD flood banner are observably
  /// exercised during the review loop.
  ///
  /// NOTE: we deliberately do NOT step the sim here. With no shelter leaf there
  /// is no flood resolver, and the deterministic [EventSystem] would otherwise
  /// mark a due-but-unresolvable event `resolved` (with an `unresolved:true`
  /// outcome) on the very first step — which would clear `_activeFlood` and the
  /// flood would never visibly render. Scheduling it due-now and not stepping
  /// keeps `scheduledForMs <= simNow && !resolved` true, so the overlay/banner
  /// show. Once the shelter leaf installs a real flood resolver, the live path
  /// will resolve it normally.
  void debugTriggerFlood() {
    final EmberRng rng = state.rng.clone();
    final EntityId id = ids.mint('event-flood', rng);
    final WorldEvent flood = WorldEvent(
      id: id,
      type: WorldEventType.flood,
      scheduledForMs: state.simNowMs,
      payload: <String, dynamic>{'severity': 0.8, 'debug': true},
    );
    // Drop any PRIOR debug flood first so they never stack — a debug flood is a
    // one-shot review trigger, not a persistent condition. Without this, repeated
    // triggers (or a trigger left behind after leaving the flood state) keep the
    // flood banner/overlay alive over calm world-showcase frames (the "cries
    // wolf" leak): the banner/overlay treat a present debug flood as active for
    // as long as it EXISTS, so it must be removed when the flood is over.
    final List<WorldEvent> kept = state.events
        .where((WorldEvent e) =>
            !(e.type == WorldEventType.flood && e.payload['debug'] == true))
        .toList(growable: true);
    state = state.copyWith(
      events: <WorldEvent>[...kept, flood],
      rng: rng,
    );
    _persistSoon();
  }

  /// DEBUG: clear any debug-triggered flood so the flood overlay + HUD banner
  /// stop showing. Called by the review-loop tour when LEAVING the flood state
  /// (entering a calm world-showcase state), so the alarm read is reserved for an
  /// ACTUALLY-resolving flood — the "world-with-X" object showcase + settled play
  /// must show the contextual action pill, never a stale flood banner. No-op if
  /// there is no debug flood (a real, resolver-backed flood is untouched).
  void debugClearFlood() {
    final bool hasDebugFlood = state.events.any((WorldEvent e) =>
        e.type == WorldEventType.flood && e.payload['debug'] == true);
    if (!hasDebugFlood) return;
    final List<WorldEvent> kept = state.events
        .where((WorldEvent e) =>
            !(e.type == WorldEventType.flood && e.payload['debug'] == true))
        .toList(growable: true);
    state = state.copyWith(events: kept);
    _persistSoon();
  }

  /// DEBUG: run the REAL flood resolver against the current settled world so the
  /// flagship flood is shown STRIKING the village — low/weak dwellings on flood-
  /// risk ground take damage (the [DwellingComponent] then leans + cracks + shows
  /// a waterline tint) while high-ground homes stay dry. This makes the "the river
  /// floods in a predictable cycle" reframe LAND on the built camp instead of
  /// reading as a gentle color shift over an empty map.
  ///
  /// Deterministic + leaf-blind: it asks the registry for the [WorldEventType.flood]
  /// resolver (the shelter leaf's FloodResolver) and applies it to a synthesized
  /// due flood event, threading the world rng exactly like the live EventSystem.
  /// The flood event stays present (debug) so the overlay/banner show alongside the
  /// damage. No-op if no flood resolver is registered (e.g. shelter leaf absent).
  void debugResolveFlood({double severity = 0.85}) {
    final List<EventResolver> resolvers =
        _registry.resolversFor(WorldEventType.flood);
    EventResolver? resolver;
    for (final EventResolver r in resolvers) {
      if (r.canResolve(WorldEventType.flood)) {
        resolver = r;
        break;
      }
    }
    if (resolver == null) return;

    final EmberRng rng = state.rng.clone();
    final EntityId id = ids.mint('event-flood', rng);
    final WorldEvent flood = WorldEvent(
      id: id,
      type: WorldEventType.flood,
      scheduledForMs: state.simNowMs,
      payload: <String, dynamic>{'severity': severity, 'debug': true},
    );
    // Resolve against the current state (damages low dwellings, spares high), then
    // keep the flood event PRESENT (unresolved + debug) so the rising-water overlay
    // + banner show over the now-damaged camp for the capture dwell.
    final EventOutcome outcome = resolver.resolve(flood, state, rng);
    final List<WorldEvent> kept = outcome.state.events
        .where((WorldEvent e) =>
            !(e.type == WorldEventType.flood && e.payload['debug'] == true))
        .toList(growable: true);
    state = outcome.state.copyWith(
      events: <WorldEvent>[...kept, flood],
      rng: rng,
    );
    _persistSoon();
  }

  /// DEBUG: drop an already-built placeable of [type] at [coord] with the given
  /// pre-baked [ext] payload, and flag its type unlocked. This mirrors the real
  /// reducer's `_applyPlaceHint` (mint a deterministic id from a cloned rng, mark
  /// it built, stamp the footprint occupant) so the EMBER_TOUR self-drive can show
  /// real built objects (a fire, a knapping station, dwellings, a palisade)
  /// standing in the village without walking each build tutorial. Stays LEAF-BLIND:
  /// the CALLER (the debug tour) supplies the leaf's ext bag, so the controller
  /// never imports a concept leaf — it only round-trips through the open `ext` bag.
  ///
  /// The placeable's FOOTPRINT (from its [PlaceableDef], 1x1 if none) is checked +
  /// stamped, so multi-tile structures occupy their full area like the real path.
  ///
  /// No-op if [coord] (or any footprint tile) is out of bounds or already occupied
  /// (so it can't corrupt the grid). Dev-only: never invoked by normal play.
  void debugPlaceBuilt({
    required PlaceableType type,
    required GridCoord coord,
    required Map<String, dynamic> ext,
  }) {
    final PlaceableDef? def = _registry.defFor(type);
    final int w = def?.footprint.width ?? 1;
    final int h = def?.footprint.height ?? 1;

    // Bail unless the whole footprint is in-bounds + free (mirrors placement).
    for (final GridCoord c in coord.footprint(w, h)) {
      final Tile? t = state.tiles.at(c);
      if (t == null || t.isOccupied) return;
    }

    final EmberRng rng = state.rng.clone();
    final EntityId id = ids.mint('placeable', rng);
    final Placeable placeable = Placeable(
      id: id,
      type: type,
      tier: 1,
      coord: coord,
      state: PlaceableState.built,
      buildProgress: 1.0,
      ext: Map<String, dynamic>.of(ext),
    );
    final TileGrid tiles = _stampOccupant(state.tiles, coord, w, h, id);
    state = state.copyWith(
      placeables: <Placeable>[...state.placeables, placeable],
      tiles: tiles,
      // Flag the type unlocked so the build menu/tracker reflect it too.
      knowledge: state.knowledge.set('unlock.${type.name}'),
      rng: rng,
    );
    _persistSoon();
  }

  /// DEBUG: back-compat alias for the fire-objects tour step. Delegates to the
  /// leaf-blind [debugPlaceBuilt] (the caller supplies the fire's ext bag).
  void debugPlaceBuiltFire({
    required PlaceableType type,
    required GridCoord coord,
    required Map<String, dynamic> ext,
  }) =>
      debugPlaceBuilt(type: type, coord: coord, ext: ext);

  // ===========================================================================
  // Derived reads (cheap helpers the game/UI can call through the notifier)
  // ===========================================================================

  /// The current fire-coverage pass (lit/warm tiles) over the live world.
  FireCoverage currentCoverage() => _coverage.compute(state);

  // ===========================================================================
  // Internals
  // ===========================================================================

  /// The ext-bag key a tend request is parked under for the fire behavior to
  /// consume. Frozen so the controller stays leaf-blind (mirrors the
  /// LightSources convention).
  static const String _kPendingTendKey = 'pendingTend';

  TileGrid _stampOccupant(
    TileGrid grid,
    GridCoord origin,
    int w,
    int h,
    EntityId id,
  ) {
    return grid.withTiles(
      origin.footprint(w, h),
      (Tile t) => t.copyWith(occupantId: id),
    );
  }

  TileGrid _clearOccupant(TileGrid grid, GridCoord origin, int w, int h) {
    return grid.withTiles(
      origin.footprint(w, h),
      (Tile t) => t.copyWith(clearOccupant: true),
    );
  }

  void _setAwayDigest(AwayDigest? digest) {
    ref.read(awayDigestProvider.notifier).state = digest;
  }

  void _pushLiveOutcomes(List<EventOutcome> outcomes) {
    final List<EventOutcome> current = ref.read(liveOutcomesProvider);
    final List<EventOutcome> merged = <EventOutcome>[...current, ...outcomes];
    final List<EventOutcome> trimmed = merged.length > _maxLiveOutcomes
        ? merged.sublist(merged.length - _maxLiveOutcomes)
        : merged;
    ref.read(liveOutcomesProvider.notifier).state = trimmed;
  }

  /// Persist the current state (stamps savedAt = now). Fire-and-forget for the
  /// non-lifecycle paths; the lifecycle observer awaits [persistNow].
  Future<void> _persist() async {
    final SaveEnvelope envelope = SaveEnvelope(
      schemaVersion: SaveEnvelope.currentSchemaVersion,
      savedAtMs: _clock.nowMs(),
      state: state,
    );
    await _repo.save(envelope);
  }

  /// Persist without awaiting (intent handlers stay synchronous so dispatch is
  /// fire-and-forget from the game loop).
  void _persistSoon() {
    // ignore: discarded_futures — best-effort autosave; lifecycle does the
    // guaranteed save on pause.
    _persist();
  }
}
