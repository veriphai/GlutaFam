// The hero satellite: assembled from parts (glow < modeRing < body < panels <
// dish < face) with the full idle animation (PRD §10.3) and power-mode changes
// (§10.4). Offsets are factors of the body width — tune live.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../config/asset_paths.dart';
import '../restore_earth_game.dart';

enum SatFace { idle, hint, excited, oops }

class SatelliteComponent extends PositionComponent
    with HasGameReference<RestoreEarthGame> {
  SatelliteComponent({required this.bodyWidth, required Vector2 center})
      : _baseY = center.y,
        super(position: center, anchor: Anchor.center, size: Vector2(bodyWidth * 2.6, bodyWidth * 1.8));

  final double bodyWidth;
  final double _baseY;
  double _t = 0;

  late final SpriteComponent _glow;
  late final SpriteComponent _modeRing;
  late final SpriteComponent _dish;
  late final SpriteComponent _panelL;
  late final SpriteComponent _panelR;
  late final SpriteComponent _face;

  Color? _modeColor; // null = idle (no power)

  Vector2 get _c => size / 2; // local centre

  SpriteComponent _spr(String flamePath, double w, Offset offsetFromCenter,
      {bool additive = false, int priority = 0}) {
    final s = game.sprite(flamePath);
    final h = w * (s.srcSize.y / s.srcSize.x);
    return SpriteComponent(
      sprite: s,
      size: Vector2(w, h),
      anchor: Anchor.center,
      position: _c + Vector2(offsetFromCenter.dx * bodyWidth, offsetFromCenter.dy * bodyWidth),
      priority: priority,
    )..paint = (additive ? (Paint()..blendMode = BlendMode.plus) : Paint());
  }

  @override
  Future<void> onLoad() async {
    _glow = _spr(RE.flame(RE.satGlow), bodyWidth * 1.7, const Offset(0, 0), additive: true, priority: 0);
    _modeRing = _spr(RE.flame(RE.satModeRing), bodyWidth * 1.5, const Offset(0, 0), additive: true, priority: 1)
      ..paint.color = const Color(0x00FFFFFF); // start hidden
    _panelL = _spr(RE.flame(RE.satPanelLeft), bodyWidth * 0.95, const Offset(-0.78, 0.02), priority: 2);
    _panelR = _spr(RE.flame(RE.satPanelRight), bodyWidth * 0.95, const Offset(0.78, 0.02), priority: 2);
    _dish = _spr(RE.flame(RE.satDish), bodyWidth * 0.66, const Offset(0.04, -0.62), priority: 3);
    final body = _spr(RE.flame(RE.satBody), bodyWidth, const Offset(0, 0), priority: 4);
    _face = _spr(RE.flame(RE.faceIdle), bodyWidth * 0.6, const Offset(-0.04, 0.04), priority: 5);
    addAll([_glow, _modeRing, _panelL, _panelR, _dish, body, _face]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final w = _t * 2 * math.pi;

    // Float + slight body rotation.
    position.y = _baseY + math.sin(w * 0.45) * 6; // ~2.2s period, 6px
    angle = math.sin(w * 0.38) * 0.026; // ±1.5°

    // Panels wobble, delayed from the body.
    _panelL.angle = math.sin(w * 0.45 - 0.6) * 0.05;
    _panelR.angle = -math.sin(w * 0.45 - 0.6) * 0.05;

    // Dish gently tilts.
    _dish.angle = math.sin(w * 0.25) * 0.05;

    // Glow opacity pulse 0.55 → 0.85 (tinted toward the mode colour if active).
    final glowOp = 0.55 + 0.30 * (math.sin(w * 0.5) + 1) / 2;
    _glow.paint
      ..color = (_modeColor ?? const Color(0xFF6FE3FF)).withValues(alpha: glowOp)
      ..colorFilter = ColorFilter.mode(_modeColor ?? const Color(0xFF6FE3FF), BlendMode.srcATop);
  }

  /// Enter a power mode (coloured ring + glow) or idle (null). PRD §10.4.
  void setMode(Color? color) {
    _modeColor = color;
    if (color == null) {
      _modeRing.paint.color = const Color(0x00FFFFFF);
    } else {
      _modeRing.paint
        ..color = color.withValues(alpha: 0.9)
        ..colorFilter = ColorFilter.mode(color, BlendMode.srcATop);
      // Activation is conveyed by the coloured ring + glow shift; the dish keeps
      // its idle tilt (driven in update()).
    }
  }

  void setFace(SatFace f) {
    final path = switch (f) {
      SatFace.idle => RE.faceIdle,
      SatFace.hint => RE.faceHint,
      SatFace.excited => RE.faceExcited,
      SatFace.oops => RE.faceOops,
    };
    _face.sprite = game.sprite(RE.flame(path));
  }

  /// Beam emit point (just under the satellite).
  Vector2 get emitPoint => position + Vector2(0, size.y * 0.18);
}
