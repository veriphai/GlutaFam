// The satellite: body + a transmitting glow that fades in while sending. Carries
// the AntennaComponent as a child so the dish (a SEPARATE sprite on a SEPARATE
// mount/hinge sprite) bobs with it. Position is owned entirely by update() (base
// + idle bob) — never by an Effect — so the two never fight over `position`.
//
// The body size is driven by SRTune.satelliteWidthFactor; the hinge + dish are
// sized off the stage (in AntennaComponent), so scaling the body up does NOT
// scale the hinge/dish.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../../config/signal_tuning.dart';
import 'antenna_component.dart';

class SatelliteComponent extends PositionComponent {
  SatelliteComponent({
    required this.bodySprite,
    required this.glowBodySprite,
    required this.antenna,
    required Vector2 stage,
  }) : _stage = stage;

  final Sprite bodySprite;
  final Sprite glowBodySprite;
  final AntennaComponent antenna;
  final Vector2 _stage;

  late final SpriteComponent _body;
  late final SpriteComponent _txGlow;

  /// Base centre (set by the game each frame from controller geometry).
  final Vector2 base = Vector2.zero();
  bool bob = true;
  double _t = 0;

  @override
  Future<void> onLoad() async {
    final w = SRTune.satelliteWidthFactor * _stage.x;
    final h = w * bodySprite.srcSize.y / bodySprite.srcSize.x;
    size = Vector2(w, h);
    anchor = Anchor.center;

    _body = SpriteComponent(
      sprite: bodySprite,
      anchor: Anchor.center,
      size: Vector2(w, h),
      position: Vector2(w / 2, h / 2),
      priority: 1,
    );

    _txGlow = SpriteComponent(
      sprite: glowBodySprite,
      anchor: Anchor.center,
      size: Vector2(w * 1.12, w * 1.12 * glowBodySprite.srcSize.y / glowBodySprite.srcSize.x),
      position: Vector2(w / 2, h / 2),
      priority: 2,
    )
      ..paint.blendMode = BlendMode.plus
      ..opacity = 0;

    // antenna mounts at the top-centre of the body
    antenna.position = Vector2(w / 2, h * 0.16);
    antenna.priority = 3;

    add(_body);
    add(_txGlow);
    add(antenna);
  }

  /// World-space point where the beam originates (the dish base).
  Vector2 get beamOrigin => antenna.absolutePosition;

  void setTransmitting(bool on) {
    _txGlow.add(OpacityEffect.to(on ? 0.85 : 0.0, EffectController(duration: 0.4)));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final bobY = bob ? math.sin(_t * 1.6) * _stage.y * 0.006 : 0.0;
    position
      ..x = base.x
      ..y = base.y + bobY;
  }
}
