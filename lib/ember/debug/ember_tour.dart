// Ember — debug/ember_tour.dart
//
// EMBER_TOUR self-drive. simctl can screenshot but cannot tap, so this widget
// drives the app through the key states on a timer for automated capture. It is
// gated by `const bool.fromEnvironment('EMBER_TOUR')` at the call site
// (main_ember.dart) — when that flag is off this file is never mounted and
// behaviour is unchanged.
//
// At the START of each state it prints a marker line `EMBER_TOUR_STATE:<name>`
// via debugPrint (the runner greps these), dwells ~3s, then advances; the whole
// sequence loops. It drives the SAME deterministic controller paths the debug
// scene picker uses (newGame / setSiteTile / debugForceNight / debugForceDay /
// debugTriggerFlood) PLUS the real activity host + beat machine for the fire
// experience (launch -> beat walk -> the real placement path drops the Hearth).
// No gameplay/state logic is invented here: the tour only calls existing
// controller/host/scene methods (a few DEBUG-only hooks added for the walk).
//
// Sequence:
//   site-selection -> world-day -> world-night -> world-flood
//     -> explore-walk -> explore-npc -> explore-gather -> explore-discovery
//     -> fire-activity-setup -> fire-activity-tinder -> fire-activity-heat
//     -> fire-activity-interact -> fire-activity-discover
//     -> fire-activity-itclicks -> fire-activity-apply
//     -> world-with-hearth -> world-night-fire -> world-fire-objects
//     -> tools-activity-setup -> tools-activity-interact -> tools-activity-strike
//     -> tools-activity-haft -> tools-activity-discover
//     -> tools-activity-itclicks -> tools-activity-apply -> world-with-tools
//     -> shelter-activity-setup -> shelter-activity-interact
//     -> shelter-activity-material -> shelter-activity-assemble
//     -> shelter-activity-storm -> shelter-activity-discover
//     -> shelter-activity-itclicks -> shelter-activity-apply -> world-with-shelter
//     -> world-flood-event -> settled-village -> (loop)
//
// TOOLS + SHELTER are walked by REPLAYING their REAL inputs (the prereq cascade is
// satisfied because Fire is completed earlier in the tour): each is launched via
// the host, its interact UI is mounted via beginInteract() (a short dwell captures
// the picker chrome), then its heart stages are driven by the scene's own input
// methods so they are CAPTURED at quality — Knapping replays a clean strike on the
// aim pad (tools-activity-strike) then the haft choice (tools-activity-haft);
// Raise-a-Shelter replays the material tradeoff (shelter-activity-material), the
// ordered assemble checklist (shelter-activity-assemble), and the storm test
// (shelter-activity-storm). The real success input lands the placeHint, so the
// made structure drops via the REAL path; debugForceSuccess is only a fallback if
// the typed scene isn't available.
//
// The tour is invisible (a zero-size widget); it only orchestrates and logs.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../activity/activity_host.dart';
import '../activity/activity_scene.dart';
import '../activity/beat_controller.dart';
import '../concepts/fire/make_fire_activity.dart';
import '../concepts/fire/make_fire_scene.dart';
import '../concepts/fire/model/fire_object.dart';
import '../concepts/shelter/model/dwelling.dart';
import '../concepts/shelter/raise_shelter_activity.dart';
import '../concepts/shelter/raise_shelter_scene.dart';
import '../concepts/shelter/raise_shelter_sim.dart';
import '../concepts/shelter/shelter_widgets.dart';
import '../concepts/tools/knapping_activity.dart';
import '../concepts/tools/knapping_scene.dart';
import '../concepts/tools/model/tool.dart';
import '../concepts/tools/strike_resolver.dart';
import '../core/enums.dart';
import '../core/geometry.dart';
import '../data/models/resource_node.dart';
import '../data/models/world_state.dart';
import '../game/ember_game.dart';
import '../game/exploration/discovery_nodes.dart';
import '../state/world_controller.dart';
import '../ui/world_screen.dart';

/// The marker prefix printed (via debugPrint) at the start of every tour state.
/// The capture runner relies on this exact prefix + the state names below.
const String kEmberTourMarkerPrefix = 'EMBER_TOUR_STATE:';

/// The ordered tour state names, emitted as `EMBER_TOUR_STATE:<name>`.
const List<String> kEmberTourStates = <String>[
  // ---- Foundation world states (loop #1) ----
  'site-selection',
  'world-day',
  'world-night',
  'world-flood',
  // ---- The EXPLORATION layer walk (avatar drive + proximity seams) ----
  // The avatar is driven by the REAL joystick vector (game.debugWalkToward sets
  // it; the PlayerComponent walks + the camera follows), then each proximity seam
  // is verified: stop beside the Elder (talk prompt), gather a node (+N pop),
  // walk onto the Fire discovery node (launch).
  'explore-walk',
  'explore-npc',
  'explore-gather',
  'explore-discovery',
  // ---- The FIRE activity walk (loop #2) ----
  'fire-activity-setup',
  // Dwell on the tinder picker (beat 1) + the drill/heat meter (beat 2) so each
  // is captured, before driving on to the catch-the-ember stage (interact).
  'fire-activity-tinder',
  'fire-activity-heat',
  'fire-activity-interact',
  'fire-activity-discover',
  'fire-activity-itclicks',
  'fire-activity-apply',
  // ---- The world after fire (hearth + fire objects) ----
  'world-with-hearth',
  'world-night-fire',
  'world-fire-objects',
  // ---- The TOOLS activity walk (Knapping; gated on Fire, now satisfied) ----
  'tools-activity-setup',
  'tools-activity-interact',
  // The STRIKE mini-game (angle + force aim pad), captured by REPLAYING a real
  // strike + the haft choice — not the generic debugForceSuccess advance.
  'tools-activity-strike',
  'tools-activity-haft',
  'tools-activity-discover',
  'tools-activity-itclicks',
  'tools-activity-apply',
  'world-with-tools',
  // ---- The SHELTER activity walk (Raise a Shelter; gated on Fire+Tools) ----
  'shelter-activity-setup',
  'shelter-activity-interact',
  // The MATERIAL tradeoff, the ordered ASSEMBLE checklist, and the storm TEST,
  // each captured by REPLAYING the real inputs (choose site -> material -> tap
  // frame/cover/anchor -> run the test) instead of debugForceSuccess.
  'shelter-activity-material',
  'shelter-activity-assemble',
  'shelter-activity-storm',
  'shelter-activity-discover',
  'shelter-activity-itclicks',
  'shelter-activity-apply',
  'world-with-shelter',
  // ---- The FLAGSHIP flood hitting the settled village, then the finished camp ----
  'world-flood-event',
  'settled-village',
];

/// How long each state is held before advancing (the dwell for capture).
const Duration kEmberTourDwell = Duration(seconds: 3);

/// A short settle delay after [newGame] so the fresh first-run site-selection
/// screen is mounted before the marker fires + the screenshot is taken.
const Duration _kSettle = Duration(milliseconds: 350);

/// How long to wait for the world screen's [ActivityHost] to come online after
/// the world mounts (game onLoad publishes it). Bounded so we never hang.
const Duration _kHostWaitTimeout = Duration(seconds: 8);
const Duration _kHostPollInterval = Duration(milliseconds: 100);

/// The self-driving tour overlay. Mount it (inside the module ProviderScope)
/// only when EMBER_TOUR is set; it renders nothing and advances on a timer.
class EmberTour extends ConsumerStatefulWidget {
  const EmberTour({super.key});

  @override
  ConsumerState<EmberTour> createState() => _EmberTourState();
}

class _EmberTourState extends ConsumerState<EmberTour> {
  Timer? _timer;
  int _index = 0;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    // Kick off after the first frame so the controller + tree are mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) => _enter(0));
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }

  WorldController get _controller =>
      ref.read(worldControllerProvider.notifier);

  /// The live activity host published by the world screen (null until the world
  /// is mounted + the game's onLoad has run). DEBUG accessor — see WorldScreen.
  ActivityHost? get _host => WorldScreen.debugActivityHost.value;

  /// The fire scene if the make-fire activity is currently running, else null.
  MakeFireScene? get _fireScene {
    final ActivityScene? scene = _host?.activeScene;
    return scene is MakeFireScene ? scene : null;
  }

  /// The knapping scene if the tools activity is running, else null.
  KnappingScene? get _knapScene {
    final ActivityScene? scene = _host?.activeScene;
    return scene is KnappingScene ? scene : null;
  }

  /// The raise-a-shelter scene if the shelter activity is running, else null.
  RaiseShelterScene? get _shelterScene {
    final ActivityScene? scene = _host?.activeScene;
    return scene is RaiseShelterScene ? scene : null;
  }

  /// The beat machine for the running fire activity (null if none running).
  BeatController? get _beat => _host?.activeScene?.controller;

  /// Enters tour state [i], driving the app into the matching condition, printing
  /// its marker, then scheduling the next state.
  Future<void> _enter(int i) async {
    if (_disposed || !mounted) return;
    _index = i % kEmberTourStates.length;
    final String name = kEmberTourStates[_index];

    // Clear any leftover DEBUG flood whenever we are NOT in a flood state, so the
    // flood banner/overlay never leak over the calm world-showcase frames (the
    // "cries wolf" leak). The two flood states below re-trigger it themselves.
    if (name != 'world-flood' && name != 'world-flood-event') {
      _controller.debugClearFlood();
    }

    switch (name) {
      // -------------------- Foundation world states --------------------
      case 'site-selection':
        // Hard reset to a brand-new game; clears the site-chosen flag so
        // _EmberRoot rebuilds into the first-run SiteSelectionScreen.
        await _controller.newGame();
        await _settle();
      case 'world-day':
        // Auto-pick a site (the seeded balanced grassland) to enter the world.
        _autoPickSite();
        _forceDay();
      case 'world-night':
        _controller.debugForceNight();
      case 'world-flood':
        _controller.debugForceDay();
        _controller.debugTriggerFlood();

      // ----------------------- Exploration layer -----------------------
      case 'explore-walk':
        // Daylight, calm world. Drive the avatar with the REAL joystick vector
        // toward the open ground SE of camp so the hero visibly WALKS + the
        // camera follows during this dwell (proves the joystick drive).
        _controller.debugForceDay();
        await _exploreWalkTowardFood();
      case 'explore-npc':
        // Walk back beside the Elder, then stop: the proximity resolver surfaces
        // the "Talk to Elder" walk-up prompt (the NPC seam) for capture.
        await _exploreApproachElder();
      case 'explore-gather':
        // Stand beside a resource node and gather through the proximity seam —
        // dispatches GatherIntent (the +N pop fires on the node).
        await _exploreGatherNode();
      case 'explore-discovery':
        // Walk onto the Fire discovery node (the glowing firebow spot) and launch
        // the activity through the discovery seam — flowing into the fire walk.
        await _exploreLaunchFireDiscovery();

      // ------------------------- Fire activity -------------------------
      case 'fire-activity-setup':
        await _launchFireActivity();
      case 'fire-activity-tinder':
        // Setup -> Interact: mounts the sim + the FireInteractPanel's TINDER
        // picker (beat 1). Dwell here so the picker is captured.
        _fireBeginInteract();
      case 'fire-activity-heat':
        // FUEL: choose dry tinder, then a few drills so the HEAT meter (beat 2)
        // shows partial progress for capture (NOT enough to catch yet).
        _fireBuildSomeHeat();
      case 'fire-activity-interact':
        // Drill the rest of the way so an ember is caught and the AIR/catch-ember
        // stage (beat 3) is shown.
        _fireDrillToEmber();
      case 'fire-activity-discover':
        _fireDriveToIgnition();
      case 'fire-activity-itclicks':
        _beat?.revealClick(); // discover -> itClicks
      case 'fire-activity-apply':
        _beat?.proceedToApply(); // itClicks -> apply

      // ----------------------- World after fire ------------------------
      case 'world-with-hearth':
        // Finish the activity through the REAL path: the host folds the result
        // and the placeHint drops the first built Hearth at the village site.
        _fireScene?.finish();
        _controller.debugForceDay();
      case 'world-night-fire':
        // Push to night so the hearth glow lights the village.
        _controller.debugForceNight();
      case 'world-fire-objects':
        // Add a torch + a cooking fire near the site (real built fire objects).
        _controller.debugForceDay();
        _placeFireObjects();

      // ------------------------- Tools activity -------------------------
      case 'tools-activity-setup':
        // Fire is done by now, so Knapping's prereq is satisfied — launch it via
        // the host so its Setup beat (Elder framing) is shown for capture.
        await _launchActivity(KnappingActivity.id);
      case 'tools-activity-interact':
        // Setup -> Interact: mount the sim + the KnappingInteractPanel chrome.
        // Dwell on the STONE PICKER (the first phase) so it is the captured frame
        // (glassy-vs-soft material lesson).
        _beginInteract();
      case 'tools-activity-strike':
        // Pick a glassy stone (flint) to advance to the STRIKE phase, then replay
        // ONE clean strike on the aim pad (ideal angle + good force) so the
        // FlakeMeter shows progress + the guide wedge is captured — the core
        // material/technique mechanic, captured at quality (not narrated).
        _knappingChooseStone();
        _knappingStrikeOnce();
      case 'tools-activity-haft':
        // Finish shaping the blade (more clean strikes) so the optional HAFT CHOICE
        // (spear vs hand blade) appears — captured during this dwell. We do NOT tap
        // haft yet, so the choice card is the captured frame.
        _knappingShapeBlade();
      case 'tools-activity-discover':
        // Tap "Haft a spear" to finish the blade (lands the Knapping Station
        // placeHint) + drive the success signal -> Discover. Fallback to the
        // generic advance only if the typed scene wasn't available / still interact.
        _knappingHaft();
        _toolsEnsureDiscover();
      case 'tools-activity-itclicks':
        _beat?.revealClick(); // discover -> itClicks
      case 'tools-activity-apply':
        _beat?.proceedToApply(); // itClicks -> apply
      case 'world-with-tools':
        // Finish the activity (folds the unlock/flags through the reducer), then
        // drop a real built Knapping Station carrying a made tool at the camp.
        _host?.activeScene?.finish();
        _controller.debugForceDay();
        _placeKnappingStation();

      // ------------------------ Shelter activity ------------------------
      case 'shelter-activity-setup':
        // Fire + Tools are both done now, so Raise a Shelter's prereqs are met —
        // launch it via the host so its Setup beat is shown for capture.
        await _launchActivity(RaiseShelterActivity.id);
      case 'shelter-activity-interact':
        // Setup -> Interact: mount the sim + the ShelterInteractPanel chrome.
        // Dwell on the SITE picker (the first phase) so it is the captured frame.
        _beginInteract();
      case 'shelter-activity-material':
        // Replay choosing the SAFE high-ground site so the phase advances to the
        // MATERIAL tradeoff (tent vs hut) — captured here.
        _shelterChooseSafeSite();
      case 'shelter-activity-assemble':
        // Replay choosing a material (hut) so the ordered ASSEMBLE checklist
        // (frame -> cover -> anchor -> smoke hole) is captured, then tap the steps.
        _shelterAssemble();
      case 'shelter-activity-storm':
        // Replay "Face the storm" so the wind/rain TEST progress bar is captured.
        _shelterRunStorm();
      case 'shelter-activity-discover':
        // The storm test resolves to success (safe site + anchored) and drives the
        // success signal -> Discover. Fallback to the generic advance only if the
        // typed scene wasn't available and we're still on interact.
        _shelterEnsureDiscover();
      case 'shelter-activity-itclicks':
        _beat?.revealClick(); // discover -> itClicks
      case 'shelter-activity-apply':
        _beat?.proceedToApply(); // itClicks -> apply
      case 'world-with-shelter':
        // Finish the activity (folds the unlocks + population bump), then drop a
        // couple of real built dwellings + a palisade around the village.
        _host?.activeScene?.finish();
        _controller.debugForceDay();
        _placeDwellings();

      // -------------------- The flagship flood event --------------------
      case 'world-flood-event':
        // The river floods the now-SETTLED village. Unlike the early empty-world
        // `world-flood` showcase, this runs the REAL FloodResolver against the
        // built camp so the low riverbank dwelling (the hut placed on a flood-risk
        // tile) takes damage + leans/cracks while the high-ground homes stay dry —
        // the flagship "predictable cycle" reframe landing on actual homes. The
        // flood event stays present so the rising-water overlay + banner show over
        // the now-damaged camp.
        _controller.debugForceDay();
        _controller.debugResolveFlood();
      case 'settled-village':
        // Daylight over the finished camp — the whole Hunter-Gatherer slice
        // standing together (the loop restarts from a fresh game after this).
        _controller.debugForceDay();
    }

    if (_disposed || !mounted) return;
    debugPrint('$kEmberTourMarkerPrefix$name');

    // When EMBER_TOUR_HOLD names this state, stop advancing so a reviewer can
    // park the tour on one state (e.g. to inspect a specific beat). Gated +
    // no-op unless the define is set, like EMBER_TOUR itself.
    const String hold = String.fromEnvironment('EMBER_TOUR_HOLD');
    if (hold.isNotEmpty && hold == name) return;

    _timer?.cancel();
    _timer = Timer(kEmberTourDwell, () => _enter(_index + 1));
  }

  // ===========================================================================
  // World helpers
  // ===========================================================================

  /// Commits the current seed's village site, flipping the site-chosen flag so
  /// _EmberRoot swaps SiteSelectionScreen out for the world.
  void _autoPickSite() {
    if (_controller.siteChosen) return;
    final EmberWorldState s = ref.read(worldControllerProvider);
    _controller.setSiteTile(s.village.siteTile);
  }

  /// Nudges the day/night phase into the daytime window using the existing debug
  /// path (clear mid-morning), so the world reads as bright daylight.
  void _forceDay() => _controller.debugForceDay();

  // ===========================================================================
  // Exploration drive (avatar joystick + proximity seams). DEBUG seams only:
  // the avatar is presentation-only (never enters EmberWorldState), so warping /
  // pushing the joystick / reading proximity touches no sim state.
  // ===========================================================================

  /// EXPLORE-WALK: warp the hero back to the village site, then push the REAL
  /// joystick vector toward the nearest food node SE of camp so it visibly walks
  /// for the dwell (the camera follows). Proves the joystick drive end-to-end.
  Future<void> _exploreWalkTowardFood() async {
    final EmberGame? game = await _waitForGame();
    if (game == null) return;
    final EmberWorldState s = ref.read(worldControllerProvider);
    game.debugWarpAvatar(s.village.siteTile.x, s.village.siteTile.y);
    final GridCoord? node = _nearestNode(s, s.village.siteTile);
    final GridCoord target = node ?? s.village.siteTile.translate(3, 2);
    game.debugWalkToward(target.x.toDouble(), target.y.toDouble());
  }

  /// EXPLORE-NPC: stop the walk, place the hero one tile beside the Elder, so the
  /// proximity resolver publishes the NPC target and the world_screen shows the
  /// "Talk to Elder" walk-up prompt (the NPC seam) for the capture dwell.
  Future<void> _exploreApproachElder() async {
    final EmberGame? game = await _waitForGame();
    if (game == null) return;
    final EmberWorldState s = ref.read(worldControllerProvider);
    final GridCoord site = s.village.siteTile; // Elder sits on the site tile.
    // Stand one tile south of the Elder (in range, not on top of them).
    game.debugWarpAvatar(site.x, site.y + 1);
  }

  /// EXPLORE-GATHER: stand beside a resource node, let the resolver pick it up,
  /// then resolve the GATHER seam (dispatches GatherIntent -> the node's +N pop).
  Future<void> _exploreGatherNode() async {
    final EmberGame? game = await _waitForGame();
    if (game == null) return;
    final EmberWorldState s = ref.read(worldControllerProvider);
    final GridCoord? node = _nearestNode(s, s.village.siteTile);
    if (node == null) return;
    // Stand one tile from the node so the resolver registers it as nearest.
    game.debugWarpAvatar(node.x, node.y + 1);
    // Let a couple of game frames run so the ProximityResolver publishes the node
    // target, then confirm the gather through the same seam world_screen uses.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    game.proximity.confirmGather();
  }

  /// EXPLORE-DISCOVERY: walk the hero onto the FIRE discovery node (the glowing
  /// firebow spot — shown because Fire is unlocked from the start) and launch the
  /// activity through the discovery seam, flowing into the fire-activity walk.
  Future<void> _exploreLaunchFireDiscovery() async {
    final EmberGame? game = await _waitForGame();
    if (game == null) return;
    final EmberWorldState s = ref.read(worldControllerProvider);
    final DiscoveryNodeDef? fire =
        discoveryForActivity(MakeFireActivity.id);
    if (fire != null) {
      final GridCoord at = fire.coordFor(s.village.siteTile);
      game.debugWarpAvatar(at.x, at.y);
    }
    // Let the resolver register the discovery (focus the ring), then launch via
    // the host exactly as the walk-up prompt would. The subsequent
    // fire-activity-setup state no-ops if this already launched.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final ActivityHost? host = _host;
    if (host != null && !host.isRunning) host.launch(MakeFireActivity.id);
  }

  /// The nearest gatherable (non-depleted) node to [from], or null if none.
  GridCoord? _nearestNode(EmberWorldState s, GridCoord from) {
    GridCoord? best;
    double bestD = double.infinity;
    for (final ResourceNode n in s.nodes) {
      if (n.isDepleted) continue;
      final double d = from.euclideanTo(n.coord);
      if (d < bestD) {
        bestD = d;
        best = n.coord;
      }
    }
    return best;
  }

  /// Polls for the live EmberGame (via the published host) until available or the
  /// host-wait timeout elapses. Bounded so the tour never hangs.
  Future<EmberGame?> _waitForGame() async {
    final ActivityHost? host = await _waitForHost();
    return host?.game;
  }

  // ===========================================================================
  // Fire-activity drive (DEBUG hooks only — no real fire logic is touched)
  // ===========================================================================

  /// Wait for the world screen's host to come online, then launch the make-fire
  /// activity so its Setup beat (Elder framing) is shown for capture.
  Future<void> _launchFireActivity() async {
    final ActivityHost? host = await _waitForHost();
    if (host == null) return; // robustness: world not ready; skip gracefully.
    if (host.isRunning) return; // already launched (defensive).
    host.launch(MakeFireActivity.id);
  }

  /// Setup -> Interact: mounts the sim + the FireInteractPanel chrome so the
  /// TINDER picker (beat 1) is shown for capture. Stops there.
  void _fireBeginInteract() {
    _fireScene?.beginInteract();
  }

  /// FUEL + partial HEAT: pick dry tinder, then drill a FEW taps so the HEAT
  /// meter (beat 2) shows partial progress for capture — deliberately NOT enough
  /// to catch an ember yet (so the meter is mid-fill on screen).
  void _fireBuildSomeHeat() {
    final MakeFireScene? scene = _fireScene;
    if (scene == null) return;
    // FUEL: choose dry tinder (damp would fail the attempt — that's the lesson).
    scene.selectTinder(dry: true);
    // A handful of drills: heatPerTap 0.16 -> ~4 taps lands the meter ~0.6 (mid).
    for (int n = 0; n < 4; n++) {
      scene.drill();
    }
  }

  /// Finish building HEAT so an ember is caught and the catch-ember stage (beat
  /// 3) is shown. Once phase == catchEmber, further drills are no-ops.
  ///
  /// Robustness: the heat dwell (3s) sits right at the sim's stall threshold, so
  /// the partial-heat attempt may have surfaced the "too slow" fail while we
  /// dwelled. If so, re-arm a fresh attempt (retry + re-pick dry tinder) before
  /// drilling, so the walk always reaches the ember deterministically.
  void _fireDrillToEmber() {
    final MakeFireScene? scene = _fireScene;
    if (scene == null) return;
    if (scene.view.failed) {
      scene.retryAttempt();
      scene.selectTinder(dry: true);
    }
    for (int n = 0; n < 12; n++) {
      scene.drill();
    }
  }

  /// Finish the interaction by REALLY igniting the fire (so the scene's onIgnited
  /// stamps the Hearth placeHint, which the finish() in world-with-hearth then
  /// drops as the first built Hearth). The prior beats' 3s capture dwells leave
  /// the attempt in an indeterminate phase (heat may have decayed/failed, or the
  /// ember may have faded), so this re-arms a CLEAN attempt and drives the whole
  /// sequence — fresh dry tinder, drill past the ember, blow past ignition — in
  /// one synchronous burst (no decay between calls). debugForceSuccess is only a
  /// last-ditch fallback (it advances the beat WITHOUT a placeHint, so the Hearth
  /// would not drop — we avoid relying on it).
  void _fireDriveToIgnition() {
    final MakeFireScene? scene = _fireScene;
    final BeatController? beat = _beat;
    if (scene != null && beat?.beat == ActivityBeat.interact) {
      // Re-arm a clean attempt so phase/heat/ember are deterministic regardless
      // of how the capture dwells left the prior attempt.
      scene.retryAttempt();
      scene.selectTinder(dry: true);
      // HEAT: drill past the ember threshold (heatPerTap 0.16 -> ~7 reach 1.0).
      for (int n = 0; n < 12; n++) {
        scene.drill();
      }
      // AIR: blow past ignition (blowPerPuff 0.22 -> ~5 reach 1.0); the crossing
      // blow emits `ignited`, which sets the placeHint + advances to Discover.
      // NOTE: the sim's events are delivered async (broadcast stream), so the
      // controller's beat may still read `interact` synchronously right after
      // this — the real ignited event lands on the next microtask. The fallback
      // below only fires if the beat is STILL interact, but by then the async
      // ignited has set the scene's placeHint, so the Hearth still drops.
      for (int n = 0; n < 8; n++) {
        scene.blow();
      }
    }
    // Last-ditch fallback: only if the real path still didn't advance the beat.
    final BeatController? b = _beat;
    if (b != null && b.beat == ActivityBeat.interact) {
      b.debugForceSuccess();
    }
  }

  /// Place a torch + a cooking fire near the village site (real BUILT, lit fire
  /// objects). Uses the controller's DEBUG placer with fire-leaf ext payloads
  /// built here (the tour may know the leaf; the controller stays leaf-blind).
  void _placeFireObjects() {
    final EmberWorldState s = ref.read(worldControllerProvider);
    final GridCoord site = s.village.siteTile;
    // Candidate offsets around the site; the placer skips occupied/out-of-bounds.
    _tryPlaceFire(FireType.torch, site.translate(-1, 1));
    _tryPlaceFire(FireType.cookingFire, site.translate(1, 1));
  }

  void _tryPlaceFire(FireType fireType, GridCoord coord) {
    final PlaceableType type = placeableTypeForFire(fireType);
    final Map<String, dynamic> ext =
        FireObject.initial(fireType).toExt(pos: coord);
    _controller.debugPlaceBuiltFire(type: type, coord: coord, ext: ext);
  }

  // ===========================================================================
  // Generic activity drive (tools + shelter) — DETERMINISTIC.
  //
  // Fire is completed earlier in the tour, so each leaf's prereqs are satisfied
  // when we reach it. We launch via the host, mount the interact chrome via
  // beginInteract() (so it's captured), then advance with the GENERIC
  // BeatController.debugForceSuccess() (we do NOT replay the leaf's specific
  // inputs). debugForceSuccess advances WITHOUT a placeHint, so the made objects
  // are dropped into the world afterwards via the leaf-blind debugPlaceBuilt.
  // ===========================================================================

  /// Wait for the world screen's host, then launch activity [activityId] so its
  /// Setup beat (Elder framing) is shown for capture. Robust: no-op if the world
  /// isn't ready, an activity is already running, or the launch is refused (e.g.
  /// an unexpected unmet prereq) — the walk then degrades gracefully.
  Future<void> _launchActivity(String activityId) async {
    final ActivityHost? host = await _waitForHost();
    if (host == null) return; // world not ready; skip gracefully.
    if (host.isRunning) return; // already launched (defensive).
    host.launch(activityId);
  }

  /// Setup -> Interact for whatever activity is currently running: build the
  /// leaf's sim + mount its interact chrome (so the picker/assemble UI is shown
  /// for capture). Generic — works for any ActivityScene (tools/shelter/fire).
  void _beginInteract() {
    _host?.activeScene?.beginInteract();
  }

  // ---- Knapping (tools) real-input drive (captures the strike mini-game) ----

  /// Pick a glassy stone (flint) so the sim advances from the stone picker to the
  /// STRIKE phase — so the next dwell captures the aim pad, not the picker.
  void _knappingChooseStone() {
    _knapScene?.chooseStone(StoneMaterial.flint);
  }

  /// A clean strike on the aim pad: the ideal glancing angle + a good, controlled
  /// force (mid of the [minForce]..[maxForce] window). One clean flake is ~0.34..
  /// 0.5 of a blade — NOT enough to finish — so the strike phase stays up with the
  /// FlakeMeter mid-fill + the guide wedge captured.
  void _knappingStrikeOnce() {
    final KnappingScene? scene = _knapScene;
    if (scene == null) return;
    const double angle = StrikeResolver.idealAngleDeg; // dead-on the good window
    const double force = 0.55; // comfortably inside minForce..maxForce
    scene.strike(angle, force);
  }

  /// Finish SHAPING the blade with more clean strikes so the optional HAFT CHOICE
  /// (spear vs hand blade) appears for capture. Idempotent once shaped (onStrike
  /// no-ops outside the strike phase). Does NOT tap haft — leaves the choice up.
  void _knappingShapeBlade() {
    final KnappingScene? scene = _knapScene;
    if (scene == null) return;
    const double angle = StrikeResolver.idealAngleDeg;
    const double force = 0.55;
    scene.strike(angle, force);
    scene.strike(angle, force);
  }

  /// Replay the optional HAFT choice ("Haft a spear"), which FINISHES the activity
  /// — the scene's onFinished sets the Knapping Station placeHint, so the real path
  /// drops it on finish — and drives the success signal -> Discover. If the blade
  /// isn't shaped yet (defensive), shape it first so haft is valid.
  void _knappingHaft() {
    final KnappingScene? scene = _knapScene;
    if (scene == null) return;
    _knappingShapeBlade();
    scene.haft();
  }

  /// If the typed knapping scene wasn't available (so the real strike never ran),
  /// fall back to the generic deterministic advance so the walk still reaches
  /// Discover. No-op once the real success already advanced the beat.
  void _toolsEnsureDiscover() {
    final BeatController? b = _beat;
    if (b != null && b.beat == ActivityBeat.interact) {
      b.debugForceSuccess();
    }
  }

  // ---- Raise a Shelter real-input drive (captures material/assemble/storm) ----

  /// Replay choosing the SAFE high-ground site (the offered lowest-risk option) so
  /// the phase advances to the MATERIAL tradeoff (captured next). No-op if the
  /// sites haven't resolved yet (degrades to the generic advance later).
  void _shelterChooseSafeSite() {
    final RaiseShelterScene? scene = _shelterScene;
    if (scene == null) return;
    final List<SiteOption> sites = scene.sites;
    if (sites.isEmpty) return;
    scene.chooseSite(_safestSite(sites));
  }

  /// Replay choosing a material (hut) + tapping the assemble steps IN ORDER
  /// (frame -> cover -> anchor -> smoke hole). Choosing first advances to the
  /// assemble phase; the taps then fill the ordered checklist for capture. ANCHOR
  /// is included so the storm test STANDS (the success path).
  void _shelterAssemble() {
    final RaiseShelterScene? scene = _shelterScene;
    if (scene == null) return;
    scene.chooseMaterial(ShelterMaterial.hut);
    scene.assembleStep(AssembleStep.frame);
    scene.assembleStep(AssembleStep.cover);
    scene.assembleStep(AssembleStep.anchor);
    scene.assembleStep(AssembleStep.smokeHole);
  }

  /// Replay "Face the storm" so the wind/rain TEST progress bar is captured. The
  /// sim runs the bar over ~1.6s and resolves it deterministically — a safe site +
  /// anchored shelter STANDS, driving the success signal.
  void _shelterRunStorm() {
    _shelterScene?.runTest();
  }

  /// If the typed shelter scene wasn't available (so the real flow never ran),
  /// fall back to the generic deterministic advance. No-op once the real success
  /// (the standing storm test) already advanced the beat.
  void _shelterEnsureDiscover() {
    final BeatController? b = _beat;
    if (b != null && b.beat == ActivityBeat.interact) {
      b.debugForceSuccess();
    }
  }

  /// The lowest-flood-risk offered site (the safe high-ground pick). [sites] is
  /// guaranteed non-empty by the caller.
  SiteOption _safestSite(List<SiteOption> sites) {
    SiteOption best = sites.first;
    for (final SiteOption s in sites) {
      if (s.risk < best.risk) best = s;
    }
    return best;
  }

  /// Place a real BUILT Knapping Station (carrying a made tool) one tile east of
  /// the village site, so `world-with-tools` shows the felt tools upgrade. The
  /// tour supplies the tool's ext bag; the controller's placer stays leaf-blind.
  void _placeKnappingStation() {
    final EmberWorldState s = ref.read(worldControllerProvider);
    final GridCoord site = s.village.siteTile;
    final Tool tool = const Tool(type: ToolType.spear, tier: 1);
    _controller.debugPlaceBuilt(
      type: PlaceableType.knappingStation,
      coord: site.translate(1, 0),
      ext: tool.toExt(),
    );
  }

  /// Place a couple of real BUILT dwellings + a palisade around the village site,
  /// so `world-with-shelter` shows the settled, housed camp. The tour supplies
  /// each dwelling's ext bag; the controller's placer stays leaf-blind.
  void _placeDwellings() {
    final EmberWorldState s = ref.read(worldControllerProvider);
    final GridCoord site = s.village.siteTile;
    // A hut + a hide tent flanking the camp, and a palisade wall on one side.
    _tryPlaceDwelling(DwellingType.hut, site.translate(-1, -1));
    _tryPlaceDwelling(DwellingType.hideTent, site.translate(1, -1));
    _tryPlaceDwelling(DwellingType.palisade, site.translate(0, -2));
  }

  void _tryPlaceDwelling(DwellingType dwellingType, GridCoord coord) {
    final PlaceableType type = placeableTypeForDwelling(dwellingType);
    final Map<String, dynamic> ext = Dwelling.initial(dwellingType).toExt();
    _controller.debugPlaceBuilt(type: type, coord: coord, ext: ext);
  }

  // ===========================================================================
  // Plumbing
  // ===========================================================================

  /// Polls for the world screen's [ActivityHost] until it is published or the
  /// timeout elapses (bounded so the tour never hangs on a missing world).
  Future<ActivityHost?> _waitForHost() async {
    final DateTime deadline = DateTime.now().add(_kHostWaitTimeout);
    while (!_disposed && mounted) {
      final ActivityHost? host = _host;
      if (host != null) return host;
      if (DateTime.now().isAfter(deadline)) return null;
      await Future<void>.delayed(_kHostPollInterval);
    }
    return null;
  }

  Future<void> _settle() async {
    await Future<void>.delayed(_kSettle);
  }

  @override
  Widget build(BuildContext context) {
    // The tour is purely an orchestrator: it draws nothing and intercepts
    // nothing, so the underlying screens render normally for capture.
    return const SizedBox.shrink();
  }
}
