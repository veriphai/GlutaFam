// The (single) Flame game for Save the Coastal City. It renders the two
// stages whose mechanics are spatial sprite motion — Stage 2 (orbit
// slingshot) and Stage 5 (signal downlink) — everything else is Flutter.
//
// Sync pattern: NO controller listeners (a scene-switched embedded GameWidget
// loses onLoad-registered listeners forever — playbook gotcha). Instead the
// game diffs controller state in update() every frame while mounted, mounting
// the matching stage root and forwarding ticks/tokens.
//
// The GameWidget is built ONCE by the shell and passed to the scenes that
// embed it (earth_detective pattern), so this game instance survives scene
// switches; only attach/detach happens.

import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/material.dart' show Colors;

import '../../../../utils/s3_assets.dart';
import '../config/scc_assets.dart';
import '../state/mission_state.dart';
import '../state/mission_stage_controller.dart';
import 'signal_stage.dart';
import 'slingshot_stage.dart';

class SaveCityGame extends FlameGame {
  SaveCityGame({required this.controller});

  final MissionStageController controller;

  SlingshotStage? _slingshot;
  SignalStage? _signal;
  MissionStage? _mountedFor;
  bool _assetsReady = false;
  bool get assetsReady => _assetsReady;

  /// Stage-5 packets that have reached the dish (the Flutter console's
  /// PACKETS chip listens to this; survives stage remounts).
  final ValueNotifier<int> signalDelivered = ValueNotifier(0);

  @override
  Color backgroundColor() => const Color(0x00000000); // Flutter bg shows through

  @override
  Future<void> onLoad() async {
    // Fetch the Flame-rendered sprites from S3 (manifest precache only warms
    // Flutter's ImageCache, not Flame's). Individual failures are soft — the
    // stage components draw procedural placeholders for anything missing.
    await preloadFlameImagesFromS3(images, SCC.flamePreload);
    _assetsReady = true;
    add(_GestureCatcher(game: this));
  }

  /// Null-safe sprite lookup — missing S3 fetches degrade to procedural
  /// shapes inside the components instead of `fromCache` throwing.
  Sprite? maybeSprite(String bareName) {
    final key = SCC.flame(bareName);
    return images.containsKey(key) ? Sprite(images.fromCache(key)) : null;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final stage = controller.state.stage;
    if (stage != _mountedFor) {
      _mountedFor = stage;
      _syncStageRoot(stage);
    }
    // Stage 5 runs its hold/hint logic on the game clock.
    if (stage == MissionStage.sendData) controller.signalTick(dt);
  }

  void _syncStageRoot(MissionStage stage) {
    if (stage != MissionStage.placeOrbit && _slingshot != null) {
      _slingshot!.removeFromParent();
      _slingshot = null;
    }
    if (stage != MissionStage.sendData && _signal != null) {
      _signal!.removeFromParent();
      _signal = null;
    }
    if (stage == MissionStage.placeOrbit && _slingshot == null) {
      _slingshot = SlingshotStage(game: this);
      add(_slingshot!);
    }
    if (stage == MissionStage.sendData && _signal == null) {
      _signal = SignalStage(game: this);
      add(_signal!);
    }
  }

  // Gesture forwarding (full-stage catcher → active stage root).
  void handleDragStart(Vector2 p) {
    _slingshot?.onStageDragStart(p);
    _signal?.onStageDragStart(p);
  }

  void handleDragUpdate(Vector2 p, Vector2 delta) {
    _slingshot?.onStageDragUpdate(p, delta);
    _signal?.onStageDragUpdate(p, delta);
  }

  void handleDragEnd() {
    _slingshot?.onStageDragEnd();
    _signal?.onStageDragEnd();
  }

  void handleTap(Vector2 p) {
    _slingshot?.onStageTap(p);
  }
}

/// Full-stage gesture catcher (playbook pattern): a PositionComponent with
/// Tap+Drag callbacks whose containsLocalPoint is always true, added on top;
/// reliably handles both tap and drag (game-level PanDetector misses taps,
/// TapDetector is deprecated).
class _GestureCatcher extends PositionComponent
    with TapCallbacks, DragCallbacks {
  _GestureCatcher({required this.game});

  final SaveCityGame game;

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void onTapUp(TapUpEvent event) => game.handleTap(event.canvasPosition);

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    game.handleDragStart(event.canvasPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    game.handleDragUpdate(event.canvasEndPosition, event.localDelta);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    game.handleDragEnd();
  }
}

/// Tiny helper for procedural placeholder circles when a sprite is missing
/// (pre-S3-upload dev, or a transient fetch failure).
void drawPlaceholder(Canvas canvas, Offset center, double radius, Color color) {
  final paint = Paint()..color = color;
  canvas.drawCircle(center, radius, paint);
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );
}
