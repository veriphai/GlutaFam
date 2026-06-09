// Reusable Flame components for the Code the Satellite stage:
//  • SatelliteActor — the canonical satellite; swaps its state sprite, holds a
//    constant width (so different-aspect state renders don't jump), idle-bobs,
//    and fades in/out. Position is owned by update() (bob); opacity + scale are
//    owned by Effects — never both on one field (playbook gotcha).
//  • PropActor — a scene prop (Sun / Earth / ground station / storage chip) that
//    fades in when its command runs and stays dimly present afterward.
//  • TravelingSprite — an additive sprite that flies start→end then fades out
//    (solar particles, data packets); self-removes.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart' show Curves;

class SatelliteActor extends SpriteComponent {
  SatelliteActor({
    required Sprite idle,
    required this.stageSize,
    required this.centerFactor,
    required this.compactCenterFactor,
    required this.widthFactor,
    required this.bobAmplitudeFactor,
    required this.bobPeriod,
  }) : super(sprite: idle, anchor: Anchor.center);

  Vector2 stageSize;
  final Offset centerFactor; // full-size centre (steps 1–2)
  final Offset compactCenterFactor; // zoomed-out resting spot (top-left)
  final double widthFactor;
  final double bobAmplitudeFactor;
  final double bobPeriod;

  double _t = 0;
  late Vector2 _fullPx;
  late Vector2 _compactPx;
  Vector2 _base = Vector2.zero();

  // One eased value drives BOTH the zoom and the reframe: 0 = full size at
  // centre, 1 = 50% size parked top-left. A fixed-duration easeInOutCubic gives
  // the premium "camera pulls back and reframes" feel. Size is owned here (never
  // by an Effect) so it won't fight the scale-pop / opacity effects.
  double _z = 0, _zFrom = 0, _zTo = 0, _zT = 1;
  static const _zDur = 0.9;

  double get _widthMul => 1.0 - 0.5 * _z;

  /// Smoothly zoom out + reframe top-left (compact) or back to full/centre.
  void setCompact(bool compact) {
    final target = compact ? 1.0 : 0.0;
    if ((target - _zTo).abs() < 0.001 && _zT >= _zDur) return;
    _zFrom = _z;
    _zTo = target;
    _zT = 0;
  }

  @override
  Future<void> onLoad() async {
    _fullPx = Vector2(stageSize.x * centerFactor.dx, stageSize.y * centerFactor.dy);
    _compactPx = Vector2(stageSize.x * compactCenterFactor.dx, stageSize.y * compactCenterFactor.dy);
    _base = _fullPx.clone();
    _applySize();
    position = _base.clone();
    opacity = 0; // faded in on enterStage()
  }

  void _applySize() {
    final w = stageSize.x * widthFactor * _widthMul;
    final s = sprite!;
    size = Vector2(w, w * (s.srcSize.y / s.srcSize.x));
  }

  /// Swap the displayed state sprite, keeping a constant width; optional pop.
  void setStateSprite(Sprite s, {bool pop = true}) {
    sprite = s;
    _applySize();
    if (pop) {
      scale = Vector2.all(0.92);
      add(ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.28, curve: Curves.easeOutBack)));
    }
  }

  void fadeIn({double duration = 0.45}) =>
      add(OpacityEffect.to(1, EffectController(duration: duration, curve: Curves.easeOut)));

  void fadeTo(double target, {double duration = 0.4}) =>
      add(OpacityEffect.to(target, EffectController(duration: duration, curve: Curves.easeOut)));

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    // Advance the zoom/reframe tween.
    if (_zT < _zDur) {
      _zT += dt;
      final p = (_zT / _zDur).clamp(0.0, 1.0);
      _z = _zFrom + (_zTo - _zFrom) * Curves.easeInOutCubic.transform(p);
      _applySize();
    }
    // Resting base lerps from centre → top-left with the zoom; bob rides on top.
    _base = _fullPx + (_compactPx - _fullPx) * _z;
    final amp = stageSize.y * bobAmplitudeFactor;
    position
      ..x = _base.x
      ..y = _base.y + math.sin(_t * 2 * math.pi / bobPeriod) * amp;
  }
}

class PropActor extends SpriteComponent {
  PropActor({
    required Sprite sprite,
    required this.stageSize,
    required this.centerFactor,
    required this.widthFactor,
  }) : super(sprite: sprite, anchor: Anchor.center);

  Vector2 stageSize;
  final Offset centerFactor;
  final double widthFactor;

  @override
  Future<void> onLoad() async {
    final w = stageSize.x * widthFactor;
    final s = sprite!;
    size = Vector2(w, w * (s.srcSize.y / s.srcSize.x));
    position = Vector2(stageSize.x * centerFactor.dx, stageSize.y * centerFactor.dy);
    opacity = 0;
  }

  void show({double target = 1.0, double duration = 0.45}) =>
      add(OpacityEffect.to(target, EffectController(duration: duration, curve: Curves.easeOut)));

  void hide({double duration = 0.3}) =>
      add(OpacityEffect.to(0, EffectController(duration: duration, curve: Curves.easeIn)));
}

/// A programmatic camera "scan cone" with a pulsing targeting reticle + sweeping
/// scan line over the cyclone — the Flutter/Earth-Detective-style vector beam
/// (no sprite). Drawn additively in global coords; origin tracks the (bobbing,
/// resizing) satellite lens, target tracks the Earth's cyclone. Fades in, and
/// fades out + self-removes on beginExit().
class CameraScan extends Component {
  CameraScan({
    required this.satellite,
    required this.earth,
    required this.originOffsetFactor,
    required this.targetOffsetFactor,
  });

  final SatelliteActor satellite;
  final PropActor earth;
  final Offset originOffsetFactor; // of satellite size, from sat centre
  final Offset targetOffsetFactor; // of earth size, from earth centre (cyclone)

  static const _cyan = Color(0xFF36C5F0);
  double _t = 0;
  double _appear = 0;
  bool _exiting = false;

  void beginExit() => _exiting = true;

  Offset get _origin => Offset(
        satellite.position.x + satellite.size.x * originOffsetFactor.dx,
        satellite.position.y + satellite.size.y * originOffsetFactor.dy,
      );
  Offset get _target => Offset(
        earth.position.x + earth.size.x * targetOffsetFactor.dx,
        earth.position.y + earth.size.y * targetOffsetFactor.dy,
      );

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _appear = (_appear + (_exiting ? -dt * 4 : dt * 3)).clamp(0.0, 1.0);
    if (_exiting && _appear <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final a = _appear;
    if (a <= 0) return;
    final o = _origin, t = _target;
    final dx = t.dx - o.dx, dy = t.dy - o.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1) return;
    final nx = dx / len, ny = dy / len;
    final px = -ny, py = nx; // perpendicular
    final r = earth.size.x * 0.22; // reticle / cone-mouth radius

    final p1 = Offset(t.dx + px * r, t.dy + py * r);
    final p2 = Offset(t.dx - px * r, t.dy - py * r);

    // cone fill (additive translucent)
    canvas.drawPath(
      Path()
        ..moveTo(o.dx, o.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close(),
      Paint()
        ..blendMode = BlendMode.plus
        ..color = _cyan.withValues(alpha: 0.15 * a),
    );
    // cone edges
    final edge = Paint()
      ..blendMode = BlendMode.plus
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _cyan.withValues(alpha: 0.5 * a);
    canvas.drawLine(o, p1, edge);
    canvas.drawLine(o, p2, edge);

    // targeting reticle
    final pulse = 0.82 + 0.18 * math.sin(_t * 5);
    final rr = r * pulse;
    canvas.drawCircle(
        t,
        rr,
        Paint()
          ..blendMode = BlendMode.plus
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..color = _cyan.withValues(alpha: 0.85 * a));
    canvas.drawCircle(
        t,
        rr * 0.62,
        Paint()
          ..blendMode = BlendMode.plus
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = _cyan.withValues(alpha: 0.45 * a));
    final ch = Paint()
      ..blendMode = BlendMode.plus
      ..strokeWidth = 1.6
      ..color = _cyan.withValues(alpha: 0.7 * a);
    canvas.drawLine(Offset(t.dx - rr * 1.25, t.dy), Offset(t.dx + rr * 1.25, t.dy), ch);
    canvas.drawLine(Offset(t.dx, t.dy - rr * 1.25), Offset(t.dx, t.dy + rr * 1.25), ch);

    // sweeping scan line within the reticle
    final sweepY = t.dy - rr + 2 * rr * ((_t * 0.7) % 1.0);
    final dyc = sweepY - t.dy;
    final half = math.sqrt((rr * rr - dyc * dyc).clamp(0.0, rr * rr));
    canvas.drawLine(
        Offset(t.dx - half, sweepY),
        Offset(t.dx + half, sweepY),
        Paint()
          ..blendMode = BlendMode.plus
          ..strokeWidth = 2
          ..color = _cyan.withValues(alpha: 0.85 * a));
  }
}

/// A dashed "uplink" line from the satellite to the ground station — draws in
/// with marching dashes, then crossfades cyan → green once connected. Drawn
/// additively in global coords; the start tracks the live satellite. Fades out
/// + self-removes on beginExit().
class LinkBeam extends Component {
  LinkBeam({required this.satellite, required this.station});

  final SatelliteActor satellite;
  final Vector2 station;

  static const _cyan = Color(0xFF36C5F0);
  static const _green = Color(0xFF49E08B);
  double _t = 0, _appear = 0, _progress = 0, _greenT = 0;
  bool _connected = false, _exiting = false;

  void connect() => _connected = true;
  void beginExit() => _exiting = true;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _appear = (_appear + (_exiting ? -dt * 4 : dt * 3)).clamp(0.0, 1.0);
    if (_exiting && _appear <= 0) {
      removeFromParent();
      return;
    }
    _progress = (_progress + dt * 2.2).clamp(0.0, 1.0); // draws in ~0.45s
    _greenT += ((_connected ? 1.0 : 0.0) - _greenT) * (dt * 4).clamp(0.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    final a = _appear;
    if (a <= 0) return;
    final s = satellite.position;
    final dx = station.x - s.x, dy = station.y - s.y;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1) return;
    final nx = dx / len, ny = dy / len;
    final drawn = len * _progress;
    final color = Color.lerp(_cyan, _green, _greenT)!.withValues(alpha: a);
    const dash = 14.0, gap = 9.0, period = dash + gap;
    final march = (_t * 40) % period;
    final glow = Paint()
      ..blendMode = BlendMode.plus
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.22 * a);
    final core = Paint()
      ..blendMode = BlendMode.plus
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color;
    for (double d = -march; d < drawn; d += period) {
      final d0 = d < 0 ? 0.0 : d;
      final d1 = (d + dash).clamp(0.0, drawn);
      if (d1 <= d0) continue;
      canvas.drawLine(
          Offset(s.x + nx * d0, s.y + ny * d0), Offset(s.x + nx * d1, s.y + ny * d1), glow);
      canvas.drawLine(
          Offset(s.x + nx * d0, s.y + ny * d0), Offset(s.x + nx * d1, s.y + ny * d1), core);
    }
  }
}

class TravelingSprite extends SpriteComponent {
  TravelingSprite({
    required Sprite sprite,
    required this.from,
    required this.to,
    required double diameter,
    required this.travelDuration,
    this.spin = 0,
  }) : super(
          sprite: sprite,
          anchor: Anchor.center,
          position: from.clone(),
          size: Vector2(diameter, diameter * (sprite.srcSize.y / sprite.srcSize.x)),
        ) {
    paint.blendMode = BlendMode.plus;
  }

  final Vector2 from;
  final Vector2 to;
  final double travelDuration;
  final double spin;

  @override
  Future<void> onLoad() async {
    add(MoveEffect.to(to.clone(), EffectController(duration: travelDuration, curve: Curves.easeInOut)));
    if (spin != 0) {
      add(RotateEffect.by(spin, EffectController(duration: travelDuration)));
    }
    add(OpacityEffect.to(0, EffectController(duration: 0.3, startDelay: travelDuration - 0.25)));
    add(RemoveEffect(delay: travelDuration + 0.1));
  }
}
