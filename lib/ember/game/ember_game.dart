// Ember — game/ember_game.dart
//
// The Flame host. EmberGame is a FlameGame that:
//   * owns the [ProviderContainer] (handed in at bootstrap — the SAME container
//     ConceptModule.onInstall ran against) and builds the [GameBridge] over it,
//   * builds the iso [WorldRoot] + an [EmberCamera] (pan/pinch/bounds), and
//     drives the live sim by accumulating real dt into fixed sim steps,
//   * exposes the placement state machine ([PlacementController]) wired to drop
//     its ghost into the world and snap to the cell under the pointer,
//   * routes gestures: a ScaleDetector handles pan + pinch-zoom; component-level
//     TapCallbacks handle entity taps; while placing, a tap confirms.
//
// ACTIVITY ROUTE HOOK (F4 seam): an activity is a Flame [World] (F4's
// ActivityScene extends World). EmberGame routes one in by SWAPPING the game's
// `world` to the activity world and restoring the iso world on exit — without
// importing ActivityScene (it accepts a `World Function(EmberGame)` builder), so
// this stage stays dir-/layer-clean even though F4 hasn't landed yet.
//
// COMPONENT->SIM CONTRACT: components touch the sim ONLY through `bridge`
// (read-only view + dispatch Intent). EmberGame is the one place that holds the
// container + clock-driven tick; determinism + persistence stay in the controller.

import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../art/ember_art.dart';
import '../art/sprite_art.dart';
import '../contracts/placeable_def.dart';
import '../core/enums.dart';
import '../core/geometry.dart';
import '../data/models/npc.dart';
import '../data/models/placeable.dart';
import '../sim/world_simulation.dart';
import '../state/providers.dart';
import '../state/seams.dart';
import 'components/activity_backdrop_component.dart';
import 'components/player_component.dart';
import 'components/sky_backdrop_component.dart';
import 'ember_camera.dart';
import 'exploration/proximity_resolver.dart';
import 'game_bridge.dart';
import 'iso/iso_projection.dart';
import 'placement/placement_controller.dart';
import 'world/world_root.dart';

/// The Ember Flame game. Generic over [World] so it can swap between the iso
/// [WorldRoot] and an activity scene world (F4) at runtime.
class EmberGame extends FlameGame<World> with ScaleDetector {
  EmberGame({
    required this.container,
    this.projection = IsoProjection.standard,
    this.placeableFactory,
    this.onPlaceableTapped,
    this.onNpcTapped,
    this.onActivityExit,
  });

  /// The Riverpod container the bridge reads/dispatches through. Owned by the
  /// host (ember_app); EmberGame does NOT dispose it.
  final ProviderContainer container;

  final IsoProjection projection;

  /// Leaf factory for bespoke placeable visuals (forwarded to [WorldRoot]).
  final PlaceableComponentFactory? placeableFactory;

  /// Routed when a placeable is tapped (default: begin a move on long-lived UI).
  final void Function(Placeable doc)? onPlaceableTapped;

  /// Routed when an NPC is tapped (default: open dialogue in the UI).
  final void Function(Npc doc)? onNpcTapped;

  /// Called when an activity scene asks to exit (so the host can update UI).
  final void Function()? onActivityExit;

  late final GameBridge bridge;
  late final EmberArt art;
  late final WorldRoot isoWorld;
  late final EmberCamera cameraRig;
  late final PlacementController placement;

  /// The avatar driver. Resolves the nearest interactable each frame + publishes
  /// it for the world_screen (built in onLoad once the avatar exists).
  late final ProximityResolver proximity;

  /// The current JOYSTICK direction (screen-space, y-down, 0..1). The world_screen
  /// writes this from the virtual joystick; the [PlayerComponent] reads it each
  /// frame. Zero when the stick is released (the avatar stands).
  Vector2 joystick = Vector2.zero();

  /// Whether the platform asks for reduced motion (set by world_screen from
  /// MediaQuery). Stills the avatar's ambient bob + the camera-follow easing is
  /// kept (a same-frame causal update is never softened, but follow is ambient).
  bool disableAnimations = false;

  /// The player avatar (exploration hero), via the iso world.
  PlayerComponent get player => isoWorld.player;

  /// The world currently shown when NOT in an activity (always the iso world).
  World? _restoreWorld;

  /// True while an activity scene is routed in.
  bool get inActivity => _restoreWorld != null;

  /// Live 0..1 ambient darkness (0 = full day, 1 = deep night). Read by the sky
  /// backdrop + any presentation that tints with time-of-day.
  double get darkness => bridge.isReady ? bridge.darkness : 0.0;

  /// Transparent base so the atmospheric sky backdrop (and, behind it, the
  /// Scaffold) shows through instead of FlameGame's default opaque black.
  @override
  Color backgroundColor() => const Color(0x00000000);

  // ---- Live tick accumulation -------------------------------------------
  /// Real ms accumulated since the last sim step was dispatched.
  double _accumMs = 0;

  /// Cap on how much real time we fold per frame (avoids a huge catch-up if the
  /// app was backgrounded but lifecycle catch-up hasn't run yet).
  static const double _maxAccumMs = 4.0 * WorldSimulation.stepMs;

  @override
  Future<void> onLoad() async {
    art = container.read(artProvider);
    // SPRITE PRELOAD: decode the mapped sprite pack BEFORE building the world so
    // the first paint is sprite-backed, not blank/placeholder-then-pop. A missing
    // file is swallowed per-sprite (that slot stays programmatic). No-op for
    // placeholder art (which has no cache).
    final EmberArt loadedArt = art;
    if (loadedArt is SpriteEmberArt) {
      await loadedArt.cache.preloadMapped();
    }
    bridge = GameBridge(container);

    final dynamic s = bridge.state;
    final int gw = s.tiles.width as int;
    final int gh = s.tiles.height as int;

    isoWorld = WorldRoot(
      projection: projection,
      placeableFactory: placeableFactory,
      onPlaceableTapped: onPlaceableTapped,
      onNpcTapped: onNpcTapped,
    );

    // Replace the default empty world with the iso world.
    world = isoWorld;

    cameraRig = EmberCamera.forWorld(
      world: isoWorld,
      projection: projection,
      gridWidth: gw,
      gridHeight: gh,
    );
    camera = cameraRig.camera;
    // The atmospheric sky lives in the camera's static backdrop slot (screen
    // space, behind the world): a day->night sky gradient + sun/moon bloom +
    // horizon haze + vignette so the iso field sits under a real sky rather than
    // floating on a flat fill.
    camera.backdrop.add(SkyBackdropComponent());

    placement = PlacementController(
      bridge: bridge,
      projection: projection,
      onSpawnGhost: (c) => isoWorld.add(c),
      onDespawnGhost: (c) => c.removeFromParent(),
    )..defResolver = _defFor;

    // The proximity resolver drives the walk-up interactions. The avatar +
    // discovery nodes are mounted by the iso world's onLoad (which runs when the
    // world is mounted); the resolver reads them lazily each frame.
    proximity = ProximityResolver(
      bridge: bridge,
      player: isoWorld.player,
      discoveryNodesProvider: () => isoWorld.discoveries,
    );
  }

  PlaceableDef? _defFor(PlaceableType type) =>
      container.read(simRegistryProvider).defFor(type);

  // ===========================================================================
  // Live tick
  // ===========================================================================

  @override
  void update(double dt) {
    super.update(dt);
    if (inActivity) return; // the activity scene owns its own loop.
    if (!bridge.isReady) return; // wait for bootstrap.

    _accumMs += dt * 1000.0;
    if (_accumMs > _maxAccumMs) _accumMs = _maxAccumMs;
    if (_accumMs >= WorldSimulation.stepMs) {
      final int steps =
          (_accumMs ~/ WorldSimulation.stepMs) * WorldSimulation.stepMs;
      bridge.tick(steps);
      _accumMs -= steps;
    }

    // ---- Exploration layer: camera-follow + proximity (same-frame) ----
    // The avatar moves itself from `joystick` in its own update (already run by
    // super.update above), so the figure's position is current here.
    _followAvatar(dt);
    proximity.update();
  }

  /// Ease the camera toward the avatar's world position each frame (exp approach
  /// so it trails smoothly, never snapping), staying within the map bounds (the
  /// rig's lookAt re-clamps). Pinch-zoom + placement are untouched; we don't move
  /// the camera while placing so the player can frame the build site by hand.
  void _followAvatar(double dt) {
    if (placement.isPlacing) return; // hand control to the placement framing.
    final PlayerComponent p = player;
    if (!p.isMounted || !p.isSeeded) return; // wait for the hero to be placed.
    final Vector2 want = p.position; // bottom-center world pos of the avatar.
    final Vector2 cur = cameraRig.camera.viewfinder.position;
    // tau ~220ms follow: snappy enough to feel attached, soft enough to trail.
    final double k = disableAnimations ? 1.0 : (1 - math.exp(-dt / 0.22));
    cameraRig.lookAt(cur + (want - cur) * k);
  }

  // ===========================================================================
  // Camera gestures: PINCH-ZOOM ONLY.
  //
  // The headline change: one-finger map-pan is GONE — the camera now FOLLOWS the
  // joystick-driven avatar (see _followAvatar), so a single finger is free to
  // drive the joystick (handled in Flutter, world_screen) and to place buildings
  // (the placement pointer routing in world_screen still fires while placing).
  // Two fingers pinch-zoom, exactly as before. We deliberately drop the
  // single-finger pan branch so a stray one-finger drag on the map never fights
  // the avatar-follow camera.
  // ===========================================================================

  double _zoomAtScaleStart = 1.0;

  @override
  void onScaleStart(ScaleStartInfo info) {
    _zoomAtScaleStart = cameraRig.zoom;
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    if (inActivity) return;
    // PINCH-ZOOM ONLY (two fingers). Single-finger drags are no longer panning
    // the map — they drive the joystick / place buildings.
    if (info.pointerCount > 1) {
      final double scale = info.scale.global.y; // uniform scale factor
      if ((scale - 1.0).abs() > 0.005) {
        cameraRig.setZoom(_zoomAtScaleStart * scale);
      }
    }
  }

  // ===========================================================================
  // Tap routing (placement confirm). Entity taps are handled by component-level
  // TapCallbacks; this game-level handler only resolves placement confirm when a
  // ghost is live and the tap lands on a valid cell.
  // ===========================================================================

  /// Converts a widget-local pointer position to world space via the camera.
  Vector2 toWorld(Vector2 widgetPoint) =>
      camera.globalToLocal(widgetPoint);

  /// Converts a WORLD-space point to widget-local screen px via the active camera
  /// (the inverse of [toWorld]). The world_screen uses this to anchor the
  /// floating proximity prompt over the targeted entity. Safe to call any frame:
  /// it reads the live viewfinder so it tracks the camera-follow.
  Vector2 worldToScreen(Vector2 worldPoint) =>
      camera.localToGlobal(worldPoint);

  // ===========================================================================
  // EMBER_TOUR self-drive seams (DEBUG-only). The exploration tour states use
  // these to PROVE the joystick drive (push a real direction so the avatar walks
  // + the camera follows) and to place the hero beside a target before verifying
  // a proximity seam. They touch only the avatar's presentation layer + the
  // joystick field — never EmberWorldState — so determinism is untouched.
  // ===========================================================================

  /// DEBUG: set the joystick so the avatar walks from its current cell toward the
  /// world cell at fractional grid ([tx],[ty]). Returns the screen-space unit
  /// vector pushed (zero if already there). The avatar then walks in update().
  Vector2 debugWalkToward(double tx, double ty) {
    final double dgx = tx - player.gx;
    final double dgy = ty - player.gy;
    final double gl = math.sqrt(dgx * dgx + dgy * dgy);
    if (gl < 0.05) {
      joystick = Vector2.zero();
      return joystick;
    }
    // Project the grid-space direction back to SCREEN space (the joystick's
    // frame) and normalize — the PlayerComponent re-inverts it to grid space.
    final double sx = (dgx - dgy) * projection.halfTileWidth;
    final double sy = (dgx + dgy) * projection.halfTileHeight;
    final double sl = math.sqrt(sx * sx + sy * sy);
    joystick = sl < 0.0001 ? Vector2.zero() : Vector2(sx / sl, sy / sl);
    return joystick;
  }

  /// DEBUG: stop the avatar (release the joystick).
  void debugStopWalk() => joystick = Vector2.zero();

  /// DEBUG: warp the avatar beside a target cell (see PlayerComponent.debugWarpTo).
  void debugWarpAvatar(int x, int y) {
    debugStopWalk();
    player.debugWarpTo(GridCoord(x, y));
  }

  /// Snap the active placement ghost to a widget-local pointer position.
  void pointPlacement(Vector2 widgetPoint) {
    if (!placement.isPlacing) return;
    placement.pointTo(Vector2World(toWorld(widgetPoint)));
  }

  /// Confirm the active placement (no-op if not placing / invalid).
  bool confirmPlacement() => placement.confirm();

  /// Cancel the active placement.
  void cancelPlacement() => placement.cancel();

  // ===========================================================================
  // Activity routing (F4 seam)
  // ===========================================================================

  /// Route an activity scene IN. [build] returns the activity [World] (F4's
  /// ActivityScene). The iso world is swapped out + restored on [exitActivity].
  /// EmberGame does not import ActivityScene — it only knows it is a [World].
  ///
  /// A dedicated activity camera is mounted to FRAME the activity world's flat
  /// stage at screen centre (zoom 1.0), so the bespoke interact props sit centred
  /// on screen rather than wherever the panned-to-village iso camera would put
  /// them (the old reuse of the iso cameraRig framed the stage off-screen — only
  /// a sliver showed). [stageFocus] / [stageZoom] let a caller nudge the framing
  /// (default = canvas centre at 1:1). The iso [cameraRig] camera is restored on
  /// exit.
  void enterActivity(
    World Function(EmberGame game) build, {
    Vector2? stageFocus,
    double stageZoom = 1.0,
  }) {
    if (inActivity) return;
    placement.cancel();
    // Release the joystick so the avatar isn't still "walking" when the iso world
    // is restored on exit (the joystick widget is hidden during an activity and
    // can't emit its own zero, so a stale vector would otherwise persist).
    joystick = Vector2.zero();
    _restoreWorld = world;
    final World activityWorld = build(this);
    world = activityWorld;

    // Swap to a fresh camera looking at the activity world. We build a NEW
    // CameraComponent (not the iso rig's) so its viewfinder lives in the stage's
    // flat coord space — centred on game.size/2 by default — and restore the iso
    // camera on exit. Setting `camera` mounts the new one + queues removal of the
    // old (the iso camera is re-added in exitActivity).
    final CameraComponent activityCamera = CameraComponent(world: activityWorld);
    activityCamera.viewfinder.anchor = Anchor.center;
    activityCamera.viewfinder.zoom = stageZoom;
    activityCamera.viewfinder.position = stageFocus ?? (size / 2);
    // A warm Stone-Age-night backdrop behind the stage (screen space) so the
    // props sit in a believable cold-night-by-the-fire scene, not a dead fill.
    activityCamera.backdrop.add(ActivityBackdropComponent());
    camera = activityCamera;
  }

  /// Exit the current activity scene and restore the iso world + camera.
  ///
  /// Restoring the iso WORLD also (via FlameGame's `world` setter) re-points
  /// whatever camera is currently active — but that's the activity camera, so we
  /// MUST then re-point the iso cameraRig's own camera back at the iso world (its
  /// `.world` was clobbered to the activity world by `enterActivity`'s world swap)
  /// before swapping it back in. Because the activity camera is a genuinely
  /// DIFFERENT instance, `camera = cameraRig.camera` mounts cleanly (the old bug
  /// was re-assigning the SAME camera instance, whose deferred removeFromParent
  /// left it detached so the world rendered blank).
  void exitActivity() {
    final World? restore = _restoreWorld;
    if (restore == null) return;
    world = restore;
    cameraRig.camera.world = restore;
    camera = cameraRig.camera;
    cameraRig.home();
    _restoreWorld = null;
    onActivityExit?.call();
  }

  @override
  void onRemove() {
    proximity.dispose();
    bridge.dispose();
    super.onRemove();
  }
}
