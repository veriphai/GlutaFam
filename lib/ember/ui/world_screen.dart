// Ember — ui/world_screen.dart
//
// The world map screen: the GameWidget(EmberGame) canvas with the Flutter chrome
// stacked on top — the resource HUD + day/night dial + codex button along the
// top, the concept tracker on the side, a build FAB + the placement/edit bar at
// the bottom, plus the away-digest sheet on resume and the activity phase overlay
// while an activity runs.
//
// It OWNS the EmberGame instance (built once from the shared ProviderContainer)
// and the ActivityHost. Pointer routing: a Listener over the canvas snaps the
// placement ghost while placing and a tap confirms it; component taps (NPCs /
// placeables) are routed through EmberGame callbacks to open dialogue / begin an
// edit. The screen never mutates the world directly — it dispatches via the game
// bridge (placement, build menu) and the controller (activity completion).

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../activity/activity_host.dart';
import '../activity/activity_phase_overlay.dart';
import '../art/ember_palette.dart';
import '../concepts/fire/fire_object_component.dart';
import '../concepts/shelter/dwelling_component.dart';
import '../concepts/tools/tool_station_component.dart';
import '../core/enums.dart';
import '../data/models/npc.dart';
import '../data/models/placeable.dart';
import '../ember_routes.dart';
import '../game/components/placeable_component.dart';
import '../game/ember_game.dart';
import '../game/exploration/proximity_resolver.dart';
import '../game/iso/iso_projection.dart';
import '../game/placement/placement_controller.dart';
import '../state/providers.dart';
import 'away_digest/away_digest_sheet.dart';
import 'build_menu/build_menu_sheet.dart';
import 'build_menu/edit_mode_bar.dart';
import 'controls/proximity_prompt.dart';
import 'controls/speech_bubble.dart';
import 'controls/virtual_joystick.dart';
import 'dialogue/elder_dialogue.dart';
import 'ember_theme.dart';
import 'hud/concept_tracker.dart';
import 'hud/day_night_indicator.dart';
import 'hud/flood_reframe_card.dart';
import 'hud/flood_warning_banner.dart';
import 'hud/resource_hud.dart';
import 'widgets/ember_button.dart';

/// The Ember world map screen.
class WorldScreen extends ConsumerStatefulWidget {
  const WorldScreen({super.key});

  /// DEBUG-ONLY accessor to the live [ActivityHost] this screen owns. It is
  /// published here (and cleared on dispose) ONLY so the EMBER_TOUR self-drive —
  /// which is mounted in EmberApp's overlay, outside this screen's State — can
  /// reach the host to launch + walk the fire activity for automated capture.
  /// Normal play never reads it; nothing in the production tree depends on it.
  static final ValueNotifier<ActivityHost?> debugActivityHost =
      ValueNotifier<ActivityHost?>(null);

  @override
  ConsumerState<WorldScreen> createState() => _WorldScreenState();
}

class _WorldScreenState extends ConsumerState<WorldScreen>
    with SingleTickerProviderStateMixin {
  EmberGame? _game;
  ActivityHost? _host;

  /// True once the game has finished onLoad (so placement + host are wired). The
  /// chrome that depends on the placement controller is gated behind this.
  bool _ready = false;

  EmberGame get game => _game!;
  ActivityHost get host => _host!;

  PlacementController get _placement => game.placement;

  /// The placeable currently being edited (move/remove), if any.
  Placeable? _editing;

  /// The current proximity target (the entity the avatar is standing beside), or
  /// null. Mirrors game.proximity.target; drives the floating prompt.
  ProximityTarget? _proximity;

  /// The NON-BLOCKING walk-up speech bubble: when the avatar STOPS beside an NPC
  /// they say their opening line in a floating bubble over their head (instead of
  /// the old modal bottom sheet that never dismissed). [_greetingTarget] is the
  /// NPC the bubble belongs to; [_greeting] is its content. Both are cleared the
  /// instant the avatar walks out of range (or switches target), and the bubble
  /// is gated behind the `exploring` flag in build() so it can never persist over
  /// an activity / a later screen. The full branching tree is still reachable by
  /// tapping the proximity "Talk" pill.
  ProximityTarget? _greetingTarget;
  DialogueGreeting? _greeting;

  /// A per-frame ticker that repositions the floating proximity prompt as the
  /// camera follows the avatar (the prompt is anchored to a WORLD point, so its
  /// screen position changes every frame even when the target entity is fixed).
  /// It only runs while a target exists, so it costs nothing when idle.
  Ticker? _promptTicker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_game != null) return;
    final ProviderContainer container =
        ProviderScope.containerOf(context, listen: false);
    final EmberGame game = EmberGame(
      container: container,
      placeableFactory: _placeableComponentFor,
      onPlaceableTapped: _onPlaceableTapped,
      onNpcTapped: _onNpcTapped,
    );
    _game = game;
    // placement + host become valid only after the game's onLoad runs.
    game.loaded.then((_) {
      if (!mounted) return;
      _host = ActivityHost(
        container: container,
        game: game,
        placement: game.placement,
      )..addListener(_onHostChange);
      // DEBUG: publish the host for the EMBER_TOUR self-drive (see field doc).
      WorldScreen.debugActivityHost.value = _host;
      game.placement.addListener(_onPlacementChange);
      // Exploration wiring: watch the proximity resolver so the floating prompt
      // appears/disappears, and auto-open dialogue when the avatar stops beside
      // an NPC. The per-frame prompt ticker is started/stopped with the target.
      game.proximity.target.addListener(_onProximityChange);
      game.proximity.autoTalk.addListener(_onAutoTalk);
      _promptTicker = createTicker(_onPromptFrame);
      setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _host?.removeListener(_onHostChange);
    if (_ready) {
      _placement.removeListener(_onPlacementChange);
      game.proximity.target.removeListener(_onProximityChange);
      game.proximity.autoTalk.removeListener(_onAutoTalk);
    }
    _promptTicker?.dispose();
    // DEBUG: drop the published host if it's still ours (see field doc).
    if (WorldScreen.debugActivityHost.value == _host) {
      WorldScreen.debugActivityHost.value = null;
    }
    _host?.dispose();
    super.dispose();
  }

  void _onHostChange() {
    if (mounted) setState(() {});
  }

  void _onPlacementChange() {
    // Entering placement hides the joystick (single-finger now places), so release
    // any held drive vector — otherwise the avatar keeps walking while you place.
    if (_placement.isPlacing) game.joystick = Vector2.zero();
    // When placement ends, drop the edit selection.
    if (!_placement.isPlacing && _editing != null) {
      setState(() => _editing = null);
    }
  }

  // ===========================================================================
  // Exploration: joystick drive + proximity prompt
  // ===========================================================================

  /// The proximity target changed: show/hide the floating prompt and start/stop
  /// the per-frame repositioning ticker. Also AUTO-DISMISSES the walk-up speech
  /// bubble the moment the avatar walks out of range or switches to a different
  /// target (defect C: the bubble must vanish when the player leaves, never sit).
  void _onProximityChange() {
    if (!mounted) return;
    final ProximityTarget? next = game.proximity.target.value;
    setState(() {
      _proximity = next;
      // Drop the greeting bubble unless we're still beside the SAME NPC it
      // belongs to (walked away / switched target -> it disappears).
      if (_greetingTarget != null && !_greetingTarget!.sameAs(next)) {
        _greetingTarget = null;
        _greeting = null;
      }
    });
    final Ticker? t = _promptTicker;
    if (t == null) return;
    if (next != null && !t.isActive) {
      t.start();
    } else if (next == null && t.isActive) {
      t.stop();
    }
  }

  /// Per-frame: nudge a rebuild so the prompt + greeting bubble re-anchor over
  /// the (camera-following) target. Cheap: only runs while a target exists.
  void _onPromptFrame(Duration _) {
    if (mounted && (_proximity != null || _greeting != null)) setState(() {});
  }

  /// The avatar STOPPED beside an NPC: they say their opening line in a floating,
  /// NON-BLOCKING speech bubble (the "walk up, then speak" beat — defect C). This
  /// no longer opens the modal bottom sheet (which never dismissed and sat over
  /// the fire activity + every later screen); the bubble auto-dismisses when the
  /// avatar walks away (see _onProximityChange) and is gated out of build() while
  /// an activity runs. The full branching tree stays reachable via the "Talk"
  /// pill tap (_resolveProximity). Guarded so the bubble never appears mid-
  /// activity / placement.
  void _onAutoTalk() {
    if (!mounted) return;
    final ProximityTarget? t = game.proximity.autoTalk.value;
    game.proximity.consumeAutoTalk();
    if (t == null || t.kind != ProximityKind.npc) return;
    if (host.isRunning || _placement.isPlacing) return;
    final DialogueGreeting? greeting =
        DialogueTree.greetingFor(t.dialogueId);
    if (greeting == null) return; // no tree for this NPC -> nothing to say.
    setState(() {
      _greetingTarget = t;
      _greeting = greeting;
    });
  }

  /// Routes the joystick vector into the game (read by the PlayerComponent).
  void _onJoystick(Vector2 dir) {
    if (_ready) game.joystick = dir;
  }

  /// Resolves the current proximity target by its native seam (tap fallback +
  /// prompt tap). Gather is dispatched game-side; talk/discover are Flutter-side.
  void _resolveProximity(ProximityTarget t) {
    if (!_ready || host.isRunning || _placement.isPlacing) return;
    switch (t.kind) {
      case ProximityKind.resource:
        game.proximity.confirmGather();
      case ProximityKind.npc:
        _openDialogue(t.dialogueId);
      case ProximityKind.discovery:
        if (t.activityId != null) _launchActivity(t.activityId!);
    }
  }

  void _openDialogue(String? dialogueId) {
    // Promote the gentle walk-up bubble to the full branching tree: drop the
    // bubble so it doesn't sit behind the modal the tap opens.
    if (_greeting != null) {
      setState(() {
        _greetingTarget = null;
        _greeting = null;
      });
    }
    final EmberPalette p = ref.read(artProvider).palette;
    ElderDialogue.show(
      context,
      dialogueId: dialogueId,
      palette: p,
      onOpenCodex: (String? entryId) =>
          EmberNav.openCodex(context, entryId: entryId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final EmberPalette p = ref.watch(artProvider).palette;
    // While an activity is running its phase overlay owns the screen — the world
    // HUD (and any transient world warning like the flood banner) is hidden so
    // stale world chrome can't bleed through the Make Fire experience.
    final bool activityActive = _ready && host.activeScene != null;

    // Mirror the platform reduce-motion flag into the game so the avatar's
    // ambient bob + the camera-follow easing are stilled (a calm-ambience choice;
    // same-frame causal drive is never softened).
    if (_ready) {
      game.disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ??
          false;
    }

    // The joystick + walk-up prompt are live only in plain exploration: hidden
    // while an activity runs (its chrome owns the screen) and while placing a
    // building (the placement pointer routing owns single-finger input).
    final bool exploring = _ready && !activityActive && !_placement.isPlacing;

    return Scaffold(
      backgroundColor: p.background,
      // SizedBox.expand forces the body Stack to receive TIGHT full-screen
      // constraints. Without it, the Stack uses StackFit.loose and sizes to its
      // largest NON-positioned child — but while an activity runs every sized
      // non-positioned child (the HUD blocks) is gated out by `!activityActive`,
      // leaving only the 0x0 AwayDigestHost. The loose Stack would then collapse
      // to 0x0, giving its Positioned.fill children (the GameWidget AND the
      // activity overlay) zero size so NOTHING paints (only the tan Scaffold
      // background showed). Tight constraints keep the Stack full-screen always.
      body: SizedBox.expand(
        child: Stack(
          children: <Widget>[
            // ---- The Flame canvas, with pointer routing for placement. ----
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                child: GameWidget<EmberGame>(game: game),
              ),
            ),

          // ---- Top HUD: resources on their own full-width line, then the
          //      day/night dial + codex on a second line, then (when active)
          //      the flood-warning banner. Two lines so the 4 resource chips
          //      always fit on a narrow phone (no more 399px overflow).
          //      Hidden while an activity runs so the activity chrome owns the
          //      screen (no competing resource chips / flood banner).
          //
          //      KEPT MOUNTED (Offstage, not `if`): the FloodWarningBanner is a
          //      world-watching ConsumerStatefulWidget. Structurally removing it
          //      with `if (!activityActive)` deactivates it MID-FRAME — and a live
          //      tick / debug nudge mutating worldControllerProvider in that same
          //      frame fires _notifyListeners -> markNeedsBuild on the now-defunct
          //      element (the assertion crash seen at every activity<->world
          //      transition). Staying mounted + Offstage keeps it subscribed +
          //      active across the toggle (no defunct notify); TickerMode pauses
          //      its pulse animation while hidden so it costs nothing offstage.
          //      Same visual result, no gameplay/determinism change. --
          Offstage(
            offstage: activityActive,
            child: TickerMode(
              enabled: !activityActive,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(EmberUi.gapS),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Line 1: resources span the full width.
                      const Align(
                        alignment: Alignment.topLeft,
                        child: ResourceHud(),
                      ),
                      const SizedBox(height: EmberUi.gapS),
                      // Line 2: day/night dial (left) + codex (right).
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const DayNightIndicator(),
                          const Spacer(),
                          EmberIconButton(
                            icon: Icons.menu_book,
                            tooltip: 'Codex',
                            palette: p,
                            onPressed: () => EmberNav.openCodex(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: EmberUi.gapS),
                      // Line 3: the loud flood banner (renders nothing otherwise).
                      const FloodWarningBanner(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ---- Side: collapsible concept tracker, docked to the left edge so
          //      it no longer occludes the village + NPCs in the center. Hidden
          //      while an activity runs. KEPT MOUNTED (Offstage) for the same
          //      defunct-notify reason as the top HUD above (it is a
          //      world-watching ConsumerStatefulWidget). ----
          Offstage(
            offstage: activityActive,
            child: TickerMode(
              enabled: !activityActive,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding:
                        const EdgeInsets.only(left: EmberUi.gapS, top: 140),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: ConceptTracker(onDiscover: _onDiscoverHint),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ---- Bottom: build FAB OR the edit/placement bar (after load).
          //      Hidden while an activity runs (the activity overlay owns it). --
          if (_ready && !activityActive)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(EmberUi.gap),
                  child: _placement.isPlacing
                      ? EditModeBar(
                          controller: _placement,
                          palette: p,
                          editingId: _editing?.id,
                        )
                      : _buildFab(p),
                ),
              ),
            ),

          // ---- The away-digest watcher (presents once on resume). ----
          const AwayDigestHost(),

          // ---- The flagship flood REFRAME: after the river has bitten the low
          //      camp, the Elder's "it's a predictable cycle you can plan for"
          //      turn lands once (the fear -> mastery beat). KEPT MOUNTED (a
          //      zero-size, self-guarding world-watcher): structurally removing it
          //      with `if (!activityActive)` deactivated it mid-frame and a world
          //      notify then crashed on the defunct element. It only PRESENTS its
          //      modal on the flood-aftermath flag (which never trips during an
          //      activity), so staying mounted changes nothing visually. ----
          const FloodReframeHost(),

          // ---- The floating proximity prompt over the nearest interactable.
          //      Anchored to the target's WORLD position (re-projected to screen
          //      each frame by the prompt ticker as the camera follows). Hidden
          //      while placing/in-activity (exploring gate). ----
          if (exploring && _proximity != null) _buildProximityPrompt(p),

          // ---- The NON-BLOCKING walk-up speech bubble over the NPC the avatar
          //      just stopped beside. Gated by `exploring` so it can NEVER persist
          //      over an activity / a later screen (defect C); auto-dismisses when
          //      the avatar leaves range (see _onProximityChange). The branching
          //      tree is still reachable via the proximity "Talk" pill tap. ----
          if (exploring && _greeting != null && _greetingTarget != null)
            _buildSpeechBubble(p),

          // ---- The virtual JOYSTICK (bottom-left), the avatar's drive. It is
          //      the headline input: replaces one-finger map-pan. Hidden while
          //      placing (single-finger places) or in an activity.
          //
          //      KEPT MOUNTED (Offstage, not `if`): the established mounted-HUD
          //      pattern. Structurally removing it with `if (exploring)`
          //      DEACTIVATED the joystick element MID-FRAME when an activity
          //      launches (exploring -> false) — and its dispose() touching the
          //      ticker did an InheritedWidget (TickerMode) ancestor lookup on
          //      the now-deactivated element ("Looking up a deactivated widget's
          //      ancestor is unsafe"). Staying mounted + Offstage keeps the
          //      element alive across the toggle; TickerMode pauses its spring-
          //      back ticker while hidden (and the joystick zeros its drive on
          //      activity enter via game.joystick, so the avatar never "walks"
          //      under the activity). Same visual result, no defunct dispose. ----
          Offstage(
            offstage: !exploring,
            child: TickerMode(
              enabled: exploring,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(EmberUi.gap),
                    child: VirtualJoystick(
                      onChanged: _onJoystick,
                      palette: p,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ---- The activity phase overlay (while an activity runs). ----
          if (activityActive)
            ActivityPhaseOverlay(scene: host.activeScene!, palette: p),
          ],
        ),
      ),
    );
  }

  Widget _buildFab(EmberPalette p) {
    return EmberButton(
      label: 'Build',
      icon: Icons.add,
      palette: p,
      onPressed: () => BuildMenuSheet.show(
        context,
        onBeginPlace: (PlaceableType type) {
          setState(() => _editing = null);
          _placement.begin(type);
        },
      ),
    );
  }

  /// Anchors the floating proximity prompt over its target. The target's world
  /// position is projected to widget-local screen px through the live camera, so
  /// the pill tracks the entity as the camera follows the avatar. Off-screen
  /// targets render nothing (the Positioned would push it out of view harmlessly).
  Widget _buildProximityPrompt(EmberPalette p) {
    final ProximityTarget t = _proximity!;
    final Vector2 screen =
        game.worldToScreen(Vector2(t.worldX, t.worldY));
    // Center the pill over the anchor; FractionalTranslation pulls it up-left by
    // half its own size so it hovers centered above the entity.
    return Positioned(
      left: screen.x,
      top: screen.y,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -1.0),
        child: ProximityPrompt(
          target: t,
          palette: p,
          onTap: () => _resolveProximity(t),
        ),
      ),
    );
  }

  /// Anchors the NON-BLOCKING speech bubble over its NPC. Lifted a bit higher than
  /// the proximity "Talk" pill (which sits at the NPC's anchor) so the two stack
  /// cleanly — bubble on top, pill beneath. Tracks the NPC as the camera follows
  /// via the same world->screen projection the prompt uses.
  Widget _buildSpeechBubble(EmberPalette p) {
    final ProximityTarget t = _greetingTarget!;
    final DialogueGreeting g = _greeting!;
    // Anchor ~46px above the prompt's world anchor so the bubble hovers over the
    // NPC's head, clear of the "Talk" pill below it.
    final Vector2 screen =
        game.worldToScreen(Vector2(t.worldX, t.worldY - 46));
    return Positioned(
      left: screen.x,
      top: screen.y,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -1.0),
        child: SpeechBubble(
          speakerName: g.speakerName,
          line: g.line,
          palette: p,
        ),
      ),
    );
  }

  // ===========================================================================
  // Pointer routing (placement)
  // ===========================================================================

  void _onPointerMove(PointerMoveEvent e) {
    if (_ready && _placement.isPlacing) {
      game.pointPlacement(e.localPosition.toVector2());
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    if (_ready && _placement.isPlacing) {
      // Snap the ghost to the cell under the release point so the player can
      // fine-tune; the EditModeBar's explicit Place button confirms.
      game.pointPlacement(e.localPosition.toVector2());
    }
  }

  // ===========================================================================
  // Component tap routing
  // ===========================================================================

  void _onNpcTapped(Npc npc) {
    if (!_ready || host.isRunning || _placement.isPlacing) return;
    final EmberPalette p = ref.read(artProvider).palette;
    ElderDialogue.show(
      context,
      dialogueId: npc.dialogueId,
      palette: p,
      onOpenCodex: (String? entryId) =>
          EmberNav.openCodex(context, entryId: entryId),
    );
  }

  void _onPlaceableTapped(Placeable doc) {
    if (!_ready || host.isRunning || _placement.isPlacing) return;
    setState(() => _editing = doc);
    _placement.beginMove(doc.id);
  }

  // ===========================================================================
  // Activity launch
  // ===========================================================================

  /// The concept-tracker JOURNAL no longer launches activities directly (the
  /// walk-up discovery nodes do that). It surfaces the hint; tapping it nudges the
  /// player to go find the spot rather than teleporting into the activity. Kept as
  /// a thin wrapper so the tracker's existing callback signature is unchanged.
  void _onDiscoverHint(String activityId) {
    if (!_ready) return;
    final EmberPalette p = ref.read(artProvider).palette;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: p.surface,
        duration: const Duration(seconds: 2),
        content: Text(
          'Walk to the glowing spot on the map to discover it.',
          style: TextStyle(color: p.ink),
        ),
      ),
    );
  }

  /// Launches [activityId] through the host (used by the walk-up discovery
  /// prompt). Surfaces a kid-readable refusal if the prereq cascade isn't met.
  void _launchActivity(String activityId) {
    if (!_ready) return;
    // Drop any walk-up greeting bubble before the activity takes the screen so no
    // exploration overlay can linger over it (defect C — belt-and-suspenders on
    // top of the `exploring` build gate).
    if (_greeting != null) {
      setState(() {
        _greetingTarget = null;
        _greeting = null;
      });
    }
    final ActivityLaunchResult result = host.launch(activityId);
    if (!result.launched) {
      final EmberPalette p = ref.read(artProvider).palette;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: p.surface,
          content: Text(
            switch (result.refusal!) {
              ActivityLaunchRefusal.prerequisitesUnmet =>
                'Discover the earlier ideas first.',
              ActivityLaunchRefusal.alreadyRunning =>
                'Finish what you started first.',
              ActivityLaunchRefusal.unknownActivity =>
                'That discovery is not ready yet.',
            },
            style: TextStyle(color: p.ink),
          ),
        ),
      );
    }
  }
}

/// The bespoke on-world component for a placeable. This is the foundation's
/// composition root: the ONE place allowed to import all three leaves' visuals
/// and wire them into the generic world (the world layer itself stays leaf-blind,
/// knowing only the [PlaceableComponentFactory] typedef). Each leaf's placeables
/// map to its bespoke component:
///   * fire (hearth / torch / brazier / cooking fire) -> [FireObjectComponent]
///     (live glow pool, flickering flame, ember emitter while lit),
///   * tools (knapping station / tool rack) -> [ToolStationComponent]
///     (finished-tool icon + edge glint + tier pips),
///   * shelter (lean-to / hide tent / hut / palisade) -> [DwellingComponent]
///     (build-up rise, cozy interior glow, stylized flood-damage overlay).
PlaceableComponent? _placeableComponentFor(
  Placeable doc,
  IsoProjection projection,
) {
  switch (doc.type) {
    case PlaceableType.hearth:
    case PlaceableType.torch:
    case PlaceableType.brazier:
    case PlaceableType.cookingFire:
      return FireObjectComponent(placeableId: doc.id, projection: projection);
    case PlaceableType.knappingStation:
    case PlaceableType.toolRack:
      return ToolStationComponent(placeableId: doc.id, projection: projection);
    case PlaceableType.leanTo:
    case PlaceableType.hideTent:
    case PlaceableType.hut:
    case PlaceableType.palisade:
      return DwellingComponent(placeableId: doc.id, projection: projection);
  }
}

/// Local helper: Flutter [Offset] -> Flame [Vector2].
extension on Offset {
  Vector2 toVector2() => Vector2(dx, dy);
}
