// Environmental overlays on the exploration stage (PRD §18): clouds drift
// sideways and loop; atmospheric/feature layers (blocked view, city lights,
// forest, global clouds) breathe. Clouds use normal alpha (opaque white); glow
// layers can use additive.
//
// Opacity + position are driven ENTIRELY in update() (fade-in envelope → steady
// → fade-out on exit), so nothing fights an OpacityEffect on the same field.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

enum DriftStyle { drift, fadePulse }

class DriftOverlay extends SpriteComponent {
  DriftOverlay({
    required Sprite sprite,
    required Vector2 center,
    required double width,
    required this.style,
    this.targetOpacity = 1.0,
    this.amplitude = 26,
    this.additive = false,
    this.driftPeriod = 8.0,
  }) : super(
          sprite: sprite,
          anchor: Anchor.center,
          size: Vector2(width, width * (sprite.srcSize.y / sprite.srcSize.x)),
        ) {
    position = center.clone();
    _homeX = center.x;
    priority = 22;
    opacity = 0;
    if (additive) paint.blendMode = BlendMode.plus;
  }

  final DriftStyle style;
  final double targetOpacity;
  final double amplitude;
  final bool additive;
  final double driftPeriod;

  double _homeX = 0;
  double _t = 0;
  bool _exiting = false;
  double _exitFade = 1.0;

  static const double _fadeIn = 0.6;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;

    if (_exiting) {
      _exitFade = math.max(0, _exitFade - dt / 0.35);
      if (_exitFade <= 0) {
        removeFromParent();
        return;
      }
    }

    final env = math.min(1.0, _t / _fadeIn) * _exitFade;
    final pulse = style == DriftStyle.fadePulse
        ? (0.78 + 0.22 * (0.5 + 0.5 * math.sin(_t * 1.4)))
        : 1.0;
    opacity = (targetOpacity * env * pulse).clamp(0.0, 1.0);

    if (style == DriftStyle.drift) {
      position.x = _homeX + math.sin(_t * (2 * math.pi / driftPeriod)) * amplitude;
    }
  }

  void exit() => _exiting = true;
}
