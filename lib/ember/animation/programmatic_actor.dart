// Ember — animation/programmatic_actor.dart
//
// The DEFAULT AnimatedActor: a tweened, programmatic geometric figure (no sprite,
// no Spine, no assets) that implements EVERY AnimState. It is a self-contained
// Flame component that animates from its own update(dt) loop — animation time is
// the render loop, NOT EmberClock (this is presentation, outside the determinism
// fence).
//
// The figure is a simple but readable "stone-age person" silhouette (head + body
// + two arms + two legs) for elder/tribe, a low four-legged shape for predator,
// and a pure flame for the `flame` actor kind. State drives a small set of
// procedural motions:
//   idle      -> gentle breathing bob
//   walk      -> leg/arm swing + body bounce
//   work      -> repeated arm "strike" downwards
//   celebrate -> arms up + hops (one-shot; settles to idle)
//   fail      -> slump + slow head shake (one-shot; settles to idle)

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../art/ember_palette.dart';
import '../core/enums.dart';
import 'animated_actor.dart';

/// A tweened geometric actor — the default [AnimatedActor] implementation.
class ProgrammaticActor implements AnimatedActor {
  ProgrammaticActor(
    this.kind, {
    EmberPalette palette = EmberPalette.dusk,
    double height = 56.0,
  }) : _component = _ActorComponent(kind, palette, height);

  /// Which archetype this figure draws.
  final ActorKind kind;

  final _ActorComponent _component;

  @override
  Component get component => _component;

  @override
  AnimState get current => _component.state;

  @override
  void play(AnimState state, {bool loop = true}) {
    _component.setState(state, loop: loop);
  }
}

/// The Flame component that owns the figure's drawing + per-frame tween phase.
class _ActorComponent extends PositionComponent {
  _ActorComponent(this.kind, this.palette, this.figureHeight)
      : super(
          size: Vector2(figureHeight * 0.7, figureHeight),
          anchor: Anchor.bottomCenter,
        );

  final ActorKind kind;
  final EmberPalette palette;
  final double figureHeight;

  AnimState state = AnimState.idle;
  bool _loop = true;

  /// Phase 0..1 advanced each frame; wraps for loops, clamps for one-shots.
  double _phase = 0.0;

  /// One-shot states settle back to idle once finished.
  bool _settling = false;

  void setState(AnimState s, {bool loop = true}) {
    if (s == state && loop == _loop) return;
    state = s;
    _loop = loop;
    _phase = 0.0;
    _settling = false;
  }

  /// Cycle duration (seconds) for the current state.
  double get _cycle => switch (state) {
        AnimState.idle => 2.4,
        AnimState.walk => 0.7,
        AnimState.work => 0.6,
        AnimState.celebrate => 0.5,
        AnimState.fail => 1.6,
      };

  @override
  void update(double dt) {
    super.update(dt);
    final double step = dt / _cycle;
    if (_loop && !_settling) {
      _phase = (_phase + step) % 1.0;
    } else {
      _phase += step;
      if (_phase >= 1.0) {
        _phase = 1.0;
        // One-shot finished -> drift to idle.
        if (!_settling) {
          _settling = true;
          state = AnimState.idle;
          _loop = true;
          _phase = 0.0;
          _settling = false;
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    switch (kind) {
      case ActorKind.flame:
        _renderFlame(canvas);
      case ActorKind.predator:
        _renderQuadruped(canvas);
      case ActorKind.elder:
      case ActorKind.tribe:
        _renderBiped(canvas);
    }
  }

  // ---- shared maths ------------------------------------------------------

  double get _tau => math.pi * 2;
  double _sin(double cycles) => math.sin(_phase * _tau * cycles);

  // ---- humanoid ----------------------------------------------------------

  void _renderBiped(Canvas canvas) {
    final double w = size.x;
    final double h = size.y;
    final Color skin = kind == ActorKind.elder ? palette.inkSoft : palette.hide;
    final Color cloth =
        kind == ActorKind.elder ? palette.hideDark : palette.woodDark;

    // State-driven offsets.
    double bodyBob = 0;
    double leanY = 0;
    double armSwing = 0;
    double legSwing = 0;
    double armRaise = 0; // negative = arms up
    double slump = 0;
    double headTilt = 0;

    switch (state) {
      case AnimState.idle:
        bodyBob = _sin(1) * 1.4;
      case AnimState.walk:
        bodyBob = (_sin(2)).abs() * 2.2;
        armSwing = _sin(1) * 0.5;
        legSwing = _sin(1) * 0.55;
      case AnimState.work:
        // Quick down-strike: ease the arm down then snap back.
        final double s = math.sin(_phase * math.pi).clamp(0.0, 1.0);
        armRaise = s * 0.9;
        bodyBob = s * 1.5;
        leanY = s * 2.0;
      case AnimState.celebrate:
        armRaise = -1.0; // arms up
        bodyBob = (_sin(2)).abs() * 4.0; // hops
      case AnimState.fail:
        slump = math.sin(_phase * math.pi).clamp(0.0, 1.0) * 5.0;
        headTilt = _sin(2) * 0.18; // slow head shake
        leanY = slump * 0.5;
    }

    canvas.save();
    canvas.translate(w / 2, h);
    canvas.translate(0, leanY + slump - bodyBob);

    final Paint clothPaint = Paint()..color = cloth;
    final Paint skinPaint = Paint()..color = skin;
    final Paint outline = Paint()
      ..color = palette.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = EmberMetrics.strokeWidth;
    final Paint shadow = Paint()
      ..color = palette.shadow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final double legLen = h * 0.34;
    final double torsoH = h * 0.40;
    final double headR = w * 0.22;

    // Ground shadow.
    canvas.drawOval(
      Rect.fromCenter(
          center: const Offset(0, 2), width: w * 0.7, height: h * 0.10),
      shadow,
    );

    // Legs (swing opposite).
    final double legSpread = w * 0.16;
    _limb(canvas, Offset(-legSpread, -legLen), legSwing, legLen, clothPaint,
        outline);
    _limb(canvas, Offset(legSpread, -legLen), -legSwing, legLen, clothPaint,
        outline);

    // Torso.
    final Rect torso = Rect.fromCenter(
      center: Offset(0, -legLen - torsoH / 2),
      width: w * 0.46,
      height: torsoH,
    );
    final RRect torsoR =
        RRect.fromRectAndRadius(torso, const Radius.circular(6));
    canvas.drawRRect(torsoR, clothPaint);
    canvas.drawRRect(torsoR, outline);

    // Arms.
    final double shoulderY = -legLen - torsoH * 0.85;
    final double armAngle = armSwing + (armRaise * -1.0);
    _limb(canvas, Offset(-w * 0.22, shoulderY), -armAngle, torsoH * 0.8,
        skinPaint, outline);
    _limb(canvas, Offset(w * 0.22, shoulderY), armAngle, torsoH * 0.8, skinPaint,
        outline);

    // Head.
    canvas.save();
    canvas.translate(0, -legLen - torsoH - headR * 0.7);
    canvas.rotate(headTilt);
    canvas.drawCircle(Offset.zero, headR, skinPaint);
    canvas.drawCircle(Offset.zero, headR, outline);
    canvas.restore();

    canvas.restore();
  }

  /// Draws a simple tapered limb from [anchor], rotated by [angle] radians.
  void _limb(Canvas canvas, Offset anchor, double angle, double len,
      Paint fill, Paint outline) {
    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.rotate(angle);
    final Rect r = Rect.fromLTWH(-2.5, 0, 5, len);
    final RRect rr = RRect.fromRectAndRadius(r, const Radius.circular(3));
    canvas.drawRRect(rr, fill);
    canvas.drawRRect(rr, outline);
    canvas.restore();
  }

  // ---- predator ----------------------------------------------------------

  void _renderQuadruped(Canvas canvas) {
    final double w = size.x;
    final double h = size.y;
    final Paint fur = Paint()..color = palette.rockDark;
    final Paint furDark = Paint()..color = palette.outline;
    final Paint outline = Paint()
      ..color = palette.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = EmberMetrics.strokeWidth;
    final Paint shadow = Paint()
      ..color = palette.shadow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    double prowl = 0;
    double legSwing = 0;
    double crouch = 0;
    switch (state) {
      case AnimState.idle:
        prowl = _sin(1) * 1.2;
      case AnimState.walk:
        prowl = (_sin(2)).abs() * 2.0;
        legSwing = _sin(1) * 0.4;
      case AnimState.work:
      case AnimState.celebrate:
        crouch = math.sin(_phase * math.pi) * 3.0; // lunge
      case AnimState.fail:
        crouch = -3.0; // cowed
    }

    canvas.save();
    canvas.translate(w / 2, h);
    canvas.translate(0, crouch - prowl);

    final double bodyTop = -h * 0.55;
    canvas.drawOval(
      Rect.fromCenter(
          center: const Offset(0, 2), width: w * 0.9, height: h * 0.10),
      shadow,
    );

    // Legs.
    for (final double dx in <double>[-w * 0.3, -w * 0.1, w * 0.1, w * 0.3]) {
      final double swing = (dx < 0 ? legSwing : -legSwing);
      _limb(canvas, Offset(dx, bodyTop + h * 0.18), swing, h * 0.30, fur,
          outline);
    }

    // Body.
    final Rect body = Rect.fromCenter(
      center: Offset(0, bodyTop),
      width: w * 0.85,
      height: h * 0.30,
    );
    final RRect bodyR = RRect.fromRectAndRadius(body, const Radius.circular(12));
    canvas.drawRRect(bodyR, fur);
    canvas.drawRRect(bodyR, outline);

    // Head (low, forward).
    canvas.save();
    canvas.translate(w * 0.42, bodyTop - h * 0.02);
    canvas.drawCircle(Offset.zero, w * 0.16, fur);
    canvas.drawCircle(Offset.zero, w * 0.16, outline);
    // Two glinting eyes.
    final Paint eye = Paint()..color = palette.ember;
    canvas.drawCircle(Offset(w * 0.06, -w * 0.03), 1.6, eye);
    canvas.restore();

    // Tail.
    _limb(canvas, Offset(-w * 0.42, bodyTop), -0.6 + prowl * 0.04, h * 0.28,
        furDark, outline);

    canvas.restore();
  }

  // ---- flame -------------------------------------------------------------

  void _renderFlame(Canvas canvas) {
    final double w = size.x;
    final double h = size.y;

    // Flicker amplitude/intensity per state.
    double flick;
    double scaleY;
    switch (state) {
      case AnimState.idle:
        flick = _sin(2) * 0.10;
        scaleY = 1.0 + _sin(3) * 0.06;
      case AnimState.walk:
        flick = _sin(4) * 0.18;
        scaleY = 1.0 + _sin(5) * 0.10;
      case AnimState.work:
      case AnimState.celebrate:
        flick = _sin(5) * 0.08;
        scaleY = 1.25 + _sin(6) * 0.10; // flare up
      case AnimState.fail:
        flick = _sin(1) * 0.04;
        scaleY = 0.55; // guttering
    }

    canvas.save();
    canvas.translate(w / 2, h);

    final Paint shadow = Paint()
      ..color = palette.shadow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(
      Rect.fromCenter(
          center: const Offset(0, 1), width: w * 0.7, height: h * 0.08),
      shadow,
    );

    // Three nested flame teardrops: deep -> mid -> bright core.
    _flameBlob(canvas, w * 0.46, h * 0.95 * scaleY, palette.emberDeep, flick);
    _flameBlob(canvas, w * 0.32, h * 0.72 * scaleY, palette.ember, flick * 1.3);
    _flameBlob(
        canvas, w * 0.18, h * 0.46 * scaleY, palette.emberBright, flick * 1.6);

    canvas.restore();
  }

  void _flameBlob(
      Canvas canvas, double halfW, double height, Color color, double lean) {
    final Paint p = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: <Color>[color, color.withValues(alpha: 0.85)],
      ).createShader(Rect.fromLTWH(-halfW, -height, halfW * 2, height));
    final Path path = Path()
      ..moveTo(-halfW, 0)
      ..quadraticBezierTo(-halfW, -height * 0.6, lean * halfW, -height)
      ..quadraticBezierTo(halfW, -height * 0.6, halfW, 0)
      ..quadraticBezierTo(0, height * 0.18, -halfW, 0)
      ..close();
    canvas.drawPath(path, p);
  }
}
