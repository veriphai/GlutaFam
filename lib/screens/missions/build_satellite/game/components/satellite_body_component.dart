// The satellite body: renders `satellite_body_empty`, gently hovers, and acts
// as the parent coordinate space for every drop zone and installed part (so a
// child placed at a slot's local position moves naturally with the hover).

import 'dart:math' as math;

import 'package:flame/components.dart';

import '../../config/slot_config.dart';
import '../build_satellite_game.dart';

class SatelliteBodyComponent extends PositionComponent
    with HasGameReference<BuildSatelliteGame> {
  SatelliteBodyComponent({
    required this.bodySprite,
    required Vector2 size,
    required Vector2 center,
  })  : _baseY = center.y,
        super(size: size, position: center, anchor: Anchor.center);

  final Sprite bodySprite;
  final double _baseY;
  double _t = 0;

  /// Disabled during the launch-preview lift so the sine doesn't fight it.
  bool hoverEnabled = true;

  // Idle hover (PRD Scene 0): a slow vertical sine.
  static const double _hoverSpeed = 1.1; // rad/s-ish
  double get _hoverAmplitude => size.y * 0.012;

  @override
  Future<void> onLoad() async {
    // Body fills this component; children (slots/parts) draw on top.
    add(SpriteComponent(sprite: bodySprite, size: size.clone(), anchor: Anchor.topLeft));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!hoverEnabled) return;
    _t += dt;
    position.y = _baseY + math.sin(_t * _hoverSpeed * math.pi) * _hoverAmplitude;
  }

  /// Local position (relative to this component's top-left) of a slot anchor.
  Vector2 slotLocal(SlotConfig s) =>
      Vector2(s.positionFactor.dx * size.x, s.positionFactor.dy * size.y);

  /// Absolute (game-space) position of a slot anchor, accounting for hover.
  /// Body has no rotation and anchor = center, so top-left = position - size/2.
  Vector2 slotWorld(SlotConfig s) =>
      position - size / 2 + slotLocal(s);
}
