// The Flame stage for Earth Detective. Built ONCE in the shell and embedded
// only in the mission-play scene (How-Much-Can-You-See pattern), so it's never
// re-attached and its size never changes mid-activity.
//
// Coordinate model: components live on the game root (no camera world) and the
// background is transparent, so canvas coords == GameWidget logical pixels and
// the Flutter Mission-Control background shows through. A single
// [SatelliteImageStage] owns the scene image, the zoom/pan transform, the
// scanner, the clue overlays, the before/after compositing, and ALL
// normalised↔screen conversion — keeping every layer in one transform so they
// never drift apart when the ship mission zooms.

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';

import '../config/asset_paths.dart';
import '../state/earth_detective_controller.dart';
import '../state/earth_detective_state.dart';
import 'components/satellite_image_stage.dart';
import '../../../../utils/s3_assets.dart';

class EarthDetectiveGame extends FlameGame {
  EarthDetectiveGame({required this.controller});

  final EarthDetectiveController controller;

  late final SatelliteImageStage stage;
  bool _ready = false;

  @override
  Color backgroundColor() => const Color(0x00000000);

  Sprite sprite(String flamePath) => Sprite(images.fromCache(flamePath));

  @override
  Future<void> onLoad() async {
    await preloadFlameImagesFromS3(images, const [
      // overlays
      EdAssets.ovCycloneRing, EdAssets.ovCyclonePulse, EdAssets.ovFloodArea,
      EdAssets.ovFloodMarker, EdAssets.ovDryOutline, EdAssets.ovCropStress,
      EdAssets.ovFireHeat, EdAssets.ovSmokeRing, EdAssets.ovShipMarker,
      EdAssets.ovShipWake, EdAssets.ovCoordPin, EdAssets.ovDeforestation,
      // effects + comparison + satellite
      EdAssets.fxSuccessGlow, EdAssets.fxAlertPulse, EdAssets.satelliteTiny,
      EdAssets.cmpSweep,
    ]);

    stage = SatelliteImageStage()..priority = 10;
    add(stage);
    add(_StageGestureLayer()..priority = 100);

    _ready = true;
  }

  // ── gesture entry points (from the full-stage catcher) ─────────────────
  bool get _playable => _ready && controller.state.scene == EdScene.missionPlay;

  void handleTap(Vector2 canvasPos) {
    if (!_playable) return;
    controller.onStageTap(stage.screenToNorm(canvasPos.toOffset()));
  }

  void handleDrag(Vector2 canvasPos) {
    if (!_playable) return;
    // All modes drag the scanner; in compare mode the controller also slides
    // the reveal divider to the scanner's X.
    controller.onScannerDrag(stage.screenToNorm(canvasPos.toOffset()));
  }
}

/// Full-stage invisible gesture catcher. Component-level TapCallbacks +
/// DragCallbacks are the modern (non-deprecated) gesture API and handle both
/// tap (lock the clue) and drag (move scanner / slide divider) reliably.
class _StageGestureLayer extends PositionComponent
    with TapCallbacks, DragCallbacks, HasGameReference<EarthDetectiveGame> {
  final Vector2 _p = Vector2.zero();

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    game.handleTap(event.canvasPosition);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _p.setFrom(event.canvasPosition);
    game.handleDrag(_p);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    _p.add(event.localDelta);
    game.handleDrag(_p);
  }
}
