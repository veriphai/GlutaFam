// The level's hero object (drone / airplane / satellite) on the exploration
// stage. Slides in from off-screen, then loops a gentle idle motion (PRD §18):
//  • drone  — bobs up/down
//  • airplane — slow horizontal glide + tiny bob
//  • satellite — slow float bob (the dramatic top-right slide-in is the reveal)
//
// Position is driven ENTIRELY in update() — an entrance lerp (from → home) that
// hands off to the idle loop — so nothing fights a MoveEffect on the same field.
// Scale uses a one-shot ScaleEffect (update never writes scale) and exit fades
// via OpacityEffect (update never writes opacity).

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

enum FloatStyle { bob, glide }

class FloatingStageObject extends SpriteComponent {
  FloatingStageObject({
    required Sprite sprite,
    required this.home,
    required double width,
    required this.style,
    required this.from,
  }) : super(
          sprite: sprite,
          anchor: Anchor.center,
          size: Vector2(width, width * (sprite.srcSize.y / sprite.srcSize.x)),
        ) {
    position = from.clone();
    priority = 40;
  }

  final Vector2 home; // resting centre
  final Vector2 from; // off-screen entry point
  final FloatStyle style;

  static const double _entranceDur = 0.7;
  double _t = 0;

  @override
  Future<void> onLoad() async {
    scale = Vector2.all(0.85);
    add(ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.5, curve: Curves.easeOutBack)));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t < _entranceDur) {
      final p = Curves.easeOutCubic.transform(_t / _entranceDur);
      position = from + (home - from) * p;
      return;
    }
    final it = _t - _entranceDur; // idle time
    switch (style) {
      case FloatStyle.bob:
        position
          ..x = home.x
          ..y = home.y + math.sin(it * 2.0) * 6;
      case FloatStyle.glide:
        position
          ..x = home.x + math.sin(it * 0.7) * 26
          ..y = home.y + math.sin(it * 1.6) * 3;
        angle = math.sin(it * 0.7) * 0.04;
    }
  }

  void exit({double seconds = 0.4}) {
    add(OpacityEffect.to(0, EffectController(duration: seconds, curve: Curves.easeIn)));
    add(RemoveEffect(delay: seconds + 0.02));
  }
}
