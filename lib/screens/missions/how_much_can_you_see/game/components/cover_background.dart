// Full-bleed scene background that BoxFit.cover-fills the stage and crossfades
// between levels (PRD §11.1): old fades out, new fades in while easing from a
// 1.04 zoom back to 1.0.

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

class CoverBackground extends PositionComponent {
  CoverBackground({required Vector2 stageSize}) {
    size = stageSize;
  }

  SpriteComponent? _current;

  void resize(Vector2 stageSize) {
    size = stageSize;
    final c = _current;
    if (c != null) _fit(c);
  }

  // Size the child so it covers the whole stage, centred (scale stays 1.0; the
  // crossfade animates scale separately).
  void _fit(SpriteComponent c) {
    final src = c.sprite!.srcSize;
    final cover = (size.x / src.x) > (size.y / src.y) ? size.x / src.x : size.y / src.y;
    c
      ..size = Vector2(src.x * cover, src.y * cover)
      ..anchor = Anchor.center
      ..position = size / 2;
  }

  void setInitial(Sprite sprite) {
    _current?.removeFromParent();
    final c = SpriteComponent(sprite: sprite)..priority = 0;
    _fit(c);
    _current = c;
    add(c);
  }

  void crossfadeTo(Sprite sprite, {double seconds = 0.52}) {
    final old = _current;
    final next = SpriteComponent(sprite: sprite)
      ..priority = 1
      ..opacity = 0
      ..scale = Vector2.all(1.04);
    _fit(next);
    add(next);
    next.add(OpacityEffect.to(1, EffectController(duration: seconds, curve: Curves.easeInOut)));
    next.add(ScaleEffect.to(Vector2.all(1), EffectController(duration: seconds, curve: Curves.easeOutCubic)));
    _current = next;

    if (old != null) {
      old.add(OpacityEffect.to(0, EffectController(duration: seconds * 0.9, curve: Curves.easeInOut)));
      old.add(RemoveEffect(delay: seconds + 0.05));
    }
  }
}
