// The rotatable antenna assembly: a fixed mount + a dish that pivots to the aim
// angle. Lives as a child of the satellite so it bobs with the body. The dish
// rotation is owned here (lerped toward the target each frame) — nothing else
// writes its `angle`, so update() and effects never fight over the field.
//
// The rotation hint is a clean programmatic GlowRing (cyan + chevrons); the
// pack's rotation-guide sprite had a second dish baked inside it.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../config/signal_tuning.dart';
import 'glow_ring.dart';

double _rad(double deg) => deg * math.pi / 180;

class AntennaComponent extends PositionComponent {
  AntennaComponent({
    required this.dishSprite,
    required this.mountSprite,
    required Vector2 stage,
  }) : _stage = stage;

  final Sprite dishSprite;
  final Sprite mountSprite;
  final Vector2 _stage;

  late final SpriteComponent _dish;
  late final SpriteComponent _mount;
  late final GlowRing _guide;

  double _targetRot = 0; // radians
  double _rot = 0;

  @override
  Future<void> onLoad() async {
    final dishW = SRTune.dishWidthFactor * _stage.x;
    final mountW = SRTune.mountWidthFactor * _stage.x;

    _guide = GlowRing(
      radius: dishW * SRTune.rotationRingRadiusFactor,
      color: const Color(0xFF35B6FF),
      chevrons: true,
    )
      ..position = Vector2(0, -dishW * 0.30)
      ..priority = 0;

    _mount = SpriteComponent(
      sprite: mountSprite,
      anchor: Anchor.bottomCenter,
      size: Vector2(mountW, mountW * mountSprite.srcSize.y / mountSprite.srcSize.x),
      position: Vector2.zero(),
      priority: 1,
    );
    // The dish rotates about its base (where it meets the mount).
    _dish = SpriteComponent(
      sprite: dishSprite,
      anchor: Anchor.bottomCenter,
      size: Vector2(dishW, dishW * dishSprite.srcSize.y / dishSprite.srcSize.x),
      position: Vector2(0, -mountW * 0.35),
      priority: 2,
    );

    add(_guide);
    add(_mount);
    add(_dish);
  }

  /// Aim the dish at a screen-space angle (degrees, 0 = +x, CW positive).
  void setAimAngleDeg(double deg) {
    _targetRot = _rad(deg + 90 + SRTune.dishAngleOffset);
  }

  void showGuide(bool show) => _guide.show(show);

  @override
  void update(double dt) {
    super.update(dt);
    // frame-rate-independent shortest-path lerp toward the target rotation
    var d = (_targetRot - _rot) % (2 * math.pi);
    if (d > math.pi) d -= 2 * math.pi;
    if (d < -math.pi) d += 2 * math.pi;
    _rot += d * (1 - math.pow(0.0008, dt).toDouble());
    _dish.angle = _rot;
  }
}
