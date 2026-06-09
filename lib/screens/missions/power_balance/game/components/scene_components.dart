// Persistent scene components for the Power Balance stage. The game positions
// and fades them each frame from controller geometry; these classes only hold
// the custom behaviour (Earth day↔night crossfade, satellite state-sprite swap +
// shadow blink, the programmatic shadow scrim).
//
// Coordinate model: components live on the game root (no camera world), so their
// pixel positions == GameWidget logical pixels (matches signal_rescue).

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

/// A sprite sized to a target width, keeping its source aspect. Helper for the
/// game to lay out plain scene sprites without repeating the aspect math.
void layoutSprite(SpriteComponent c, Offset center, double width) {
  final src = c.sprite!.srcSize;
  c
    ..anchor = Anchor.center
    ..position = Vector2(center.dx, center.dy)
    ..size = Vector2(width, width * src.y / src.x);
}

/// Earth horizon curve — a single space-keyed day Earth (transparent space, so
/// the stars/sun/orbit show above its atmosphere limb). The shadow side is
/// rendered by DARKENING + blue-tinting this same sprite (the night sprite had a
/// different framing + baked checkerboard, so it was dropped).
class EarthCurve extends PositionComponent {
  EarthCurve({required Sprite day}) {
    _day = SpriteComponent(sprite: day, anchor: Anchor.bottomCenter);
    add(_day);
  }

  late final SpriteComponent _day;

  /// [center] is the BOTTOM-centre anchor (the limb is the sprite's top edge).
  void setLayout(Offset bottomCenter, double width) {
    final src = _day.sprite!.srcSize;
    _day
      ..position = Vector2(bottomCenter.dx, bottomCenter.dy)
      ..size = Vector2(width, width * src.y / src.x);
  }

  /// 0 = full day, 1 = deep shadow (darkened + blue-tinted via colour modulate).
  void setShadow(double f) {
    f = f.clamp(0.0, 1.0);
    _day.paint.colorFilter = ColorFilter.mode(
      Color.fromARGB(255, (255 - 140 * f).round(), (255 - 120 * f).round(),
          (255 - 60 * f).round()),
      BlendMode.modulate,
    );
  }
}

enum SatVisual { normal, charging, lowPower, critical, warning, poweredDown, success }

/// The hero satellite. Swaps among the 7 full-state sprites and blinks in the
/// shadow/warning state. Position + width are set by the game each frame.
class SatelliteSprite extends SpriteComponent {
  SatelliteSprite({required this.sprites})
      : super(anchor: Anchor.center, sprite: sprites[SatVisual.normal]);

  final Map<SatVisual, Sprite> sprites;
  SatVisual _visual = SatVisual.normal;
  double _blinkT = 0;

  void setVisual(SatVisual v) {
    if (v == _visual) return;
    _visual = v;
    sprite = sprites[v];
  }

  void setWidth(double width) {
    final src = sprite!.srcSize;
    size = Vector2(width, width * src.y / src.x);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // warning/critical states blink; others stay steady at full opacity.
    final blinks = _visual == SatVisual.warning || _visual == SatVisual.critical;
    if (blinks) {
      _blinkT += dt;
      final b = 0.55 + 0.45 * (0.5 + 0.5 * math.sin(_blinkT * 6.0));
      paint.color = Color.fromRGBO(255, 255, 255, b);
    } else {
      _blinkT = 0;
      paint.color = const Color(0xFFFFFFFF);
    }
  }
}

/// Programmatic orbit-path ring — a faint glowing ellipse the satellite rides,
/// drawn to EXACTLY match the controller's orbit ellipse (so the path and the
/// satellite always line up, unlike a fixed dome sprite). Additive on the dark
/// stage. Drawn in absolute stage pixels, so the component sits at the origin.
class OrbitEllipse extends PositionComponent {
  Offset _center = Offset.zero;
  double _rx = 0, _ry = 0;
  final Paint _glow = Paint()
    ..style = PaintingStyle.stroke
    ..blendMode = BlendMode.plus
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
  final Paint _core = Paint()
    ..style = PaintingStyle.stroke
    ..blendMode = BlendMode.plus;

  void setEllipse(Offset center, double rx, double ry) {
    _center = center;
    _rx = rx;
    _ry = ry;
  }

  @override
  void render(Canvas canvas) {
    if (_rx <= 0) return;
    final rect = Rect.fromCenter(center: _center, width: _rx * 2, height: _ry * 2);
    _glow
      ..color = const Color(0x3370E0FF)
      ..strokeWidth = 9;
    _core
      ..color = const Color(0x9988E0FF)
      ..strokeWidth = 2;
    canvas.drawOval(rect, _glow);
    canvas.drawOval(rect, _core);
  }
}

/// Programmatic shadow scrim — a soft vertical dark gradient over the whole
/// stage, opacity driven by the shadow factor. Replaces the baked overlays.
class ShadowScrim extends PositionComponent {
  double _factor = 0;
  final Paint _paint = Paint();

  void setStage(Vector2 stage) => size = stage;
  void setFactor(double f) => _factor = f.clamp(0.0, 1.0);

  @override
  void render(Canvas canvas) {
    if (_factor <= 0.001) return;
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    _paint.shader = Gradient.linear(
      Offset(0, 0),
      Offset(0, size.y),
      [
        Color.fromRGBO(2, 5, 16, 0.66 * _factor),
        Color.fromRGBO(4, 9, 26, 0.40 * _factor),
      ],
    );
    canvas.drawRect(rect, _paint);
  }
}
