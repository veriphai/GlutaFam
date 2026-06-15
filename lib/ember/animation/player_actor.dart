// Ember — animation/player_actor.dart
//
// The PLAYER AVATAR: a friendly Stone-Age HERO figure as an [AnimatedActor],
// distinct from the NPC tribe/elder programmatic figures (npc art lives in
// programmatic_actor.dart). It mirrors that biped construction (head + torso +
// two arms + two legs swinging on a phase) but reads CLEARLY as the hero:
//   * slightly LARGER (taller default height),
//   * a distinct warm HERO cloth colour (ember tunic over hide skin) instead of
//     the muted wood/hide NPC clothing,
//   * a small HERO MARKER — a soft floating chevron/spark above the head + a
//     bright sash across the torso — so a kid instantly spots "that's me".
//
// It is built on the SAME programmatic-actor pattern (a self-contained Flame
// PositionComponent that animates from its own update(dt) loop — animation time
// is the render loop, NOT EmberClock; this is presentation, outside the
// determinism fence). The brief requires idle + walk; the figure implements
// every [AnimState] so it satisfies the [AnimatedActor] contract (work/celebrate
// /fail are supported as gentle one-shots that settle to idle, matching the NPC
// figure's behaviour, so a future PlayerComponent can drive any state).
//
// Volumetric limbs + the floating contact shadow are drawn through [CraftKit] so
// the avatar shares the module's lit-solid grammar with the craft props.
//
// disableAnimations-aware: when [reduceMotion] is set the idle bob + marker
// bounce still + the figure simply stands (a calm ambience choice; the figure's
// state still switches instantly, only the ambient motion is stilled).

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../art/craft_kit.dart';
import '../art/ember_palette.dart';
import '../core/enums.dart';
import 'animated_actor.dart';

/// The default player-avatar actor — a tweened programmatic hero figure.
///
/// Construct via [PlayerActor.new] or, preferably, through the art facade so the
/// future PlayerComponent never news up a concrete class:
/// `EmberArt.playerActor()`.
class PlayerActor implements AnimatedActor {
  PlayerActor({
    EmberPalette palette = EmberPalette.dusk,
    double height = 66.0,
    bool reduceMotion = false,
  }) : _component = PlayerActorComponent(
          palette,
          height,
          reduceMotion: reduceMotion,
        );

  final PlayerActorComponent _component;

  @override
  Component get component => _component;

  @override
  AnimState get current => _component.state;

  @override
  void play(AnimState state, {bool loop = true}) {
    _component.setState(state, loop: loop);
  }

  /// Toggle calm ambience (stills the idle bob + marker bounce). The figure's
  /// state still switches instantly — only the ambient motion is stilled.
  set reduceMotion(bool value) => _component.reduceMotion = value;
}

/// The Flame component that owns the hero figure's drawing + per-frame tween.
/// Public so a PlayerComponent (next phase) may reference its type if needed; it
/// is normally added to the tree via [PlayerActor.component].
class PlayerActorComponent extends PositionComponent {
  PlayerActorComponent(
    this.palette,
    this.figureHeight, {
    this.reduceMotion = false,
  }) : super(
          size: Vector2(figureHeight * 0.72, figureHeight),
          anchor: Anchor.bottomCenter,
        );

  final EmberPalette palette;
  final double figureHeight;

  /// Calm-ambience flag (stills idle bob + marker bounce).
  bool reduceMotion;

  AnimState state = AnimState.idle;
  bool _loop = true;

  /// Phase 0..1 advanced each frame; wraps for loops, clamps for one-shots.
  double _phase = 0.0;

  /// Free-running clock for the ambient hero marker (independent of state phase).
  double _t = 0.0;

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
        AnimState.idle => 2.6,
        AnimState.walk => 0.66,
        AnimState.work => 0.6,
        AnimState.celebrate => 0.5,
        AnimState.fail => 1.6,
      };

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final double step = dt / _cycle;
    if (_loop && !_settling) {
      _phase = (_phase + step) % 1.0;
    } else {
      _phase += step;
      if (_phase >= 1.0) {
        _phase = 1.0;
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

  // ---- shared maths ------------------------------------------------------

  double get _tau => math.pi * 2;
  double _sin(double cycles) => math.sin(_phase * _tau * cycles);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final double w = size.x;
    final double h = size.y;

    // Hero palette: a warm ember tunic over hide skin (distinct from the muted
    // wood/hide NPC clothing, so the player pops).
    final Color skin = palette.hide;
    final Color tunic = palette.ember;
    final Color tunicDark = palette.emberDeep;
    final Color sash = palette.emberBright;

    // State-driven offsets (same vocabulary as the NPC figure).
    double bodyBob = 0;
    double leanY = 0;
    double armSwing = 0;
    double legSwing = 0;
    double armRaise = 0; // negative = arms up
    double slump = 0;
    double headTilt = 0;

    switch (state) {
      case AnimState.idle:
        bodyBob = reduceMotion ? 0 : _sin(1) * 1.5;
      case AnimState.walk:
        bodyBob = (_sin(2)).abs() * 2.4;
        armSwing = _sin(1) * 0.55;
        legSwing = _sin(1) * 0.6;
      case AnimState.work:
        final double s = math.sin(_phase * math.pi).clamp(0.0, 1.0);
        armRaise = s * 0.95;
        bodyBob = s * 1.6;
        leanY = s * 2.2;
      case AnimState.celebrate:
        armRaise = -1.0;
        bodyBob = (_sin(2)).abs() * 4.4;
      case AnimState.fail:
        slump = math.sin(_phase * math.pi).clamp(0.0, 1.0) * 5.0;
        headTilt = _sin(2) * 0.18;
        leanY = slump * 0.5;
    }

    // Geometry — a touch chunkier than the NPC figure (the hero reads bigger).
    final double legLen = h * 0.34;
    final double torsoH = h * 0.42;
    final double headR = w * 0.23;

    final Paint skinPaint = Paint()..color = skin;
    final Paint outline = Paint()
      ..color = palette.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = EmberMetrics.strokeWidth;

    // Ground contact shadow (shared craft grammar) at the feet (origin baseline).
    CraftKit.groundContactEllipse(
      canvas,
      center: Offset(w / 2, h - 1),
      width: w * 0.86,
      shadow: palette.shadow,
    );

    canvas.save();
    canvas.translate(w / 2, h);
    canvas.translate(0, leanY + slump - bodyBob);

    // Legs (swing opposite). Lit cylinders so they read volumetric like props.
    final double legSpread = w * 0.17;
    _legCylinder(canvas, Offset(-legSpread, -legLen), legSwing, legLen,
        tunicDark, outline);
    _legCylinder(canvas, Offset(legSpread, -legLen), -legSwing, legLen,
        tunicDark, outline);

    // Torso (ember tunic) — a rounded slab with a bright HERO SASH across it.
    final Rect torso = Rect.fromCenter(
      center: Offset(0, -legLen - torsoH / 2),
      width: w * 0.5,
      height: torsoH,
    );
    final RRect torsoR = RRect.fromRectAndRadius(torso, const Radius.circular(7));
    canvas.drawRRect(
      torsoR,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-0.7, -0.8),
          end: const Alignment(0.7, 0.8),
          colors: <Color>[
            Color.lerp(tunic, const Color(0xFFFFFFFF), 0.18)!,
            tunic,
            tunicDark,
          ],
          stops: const <double>[0.0, 0.5, 1.0],
        ).createShader(torso),
    );
    canvas.drawRRect(torsoR, outline);

    // The hero sash — a bright diagonal band across the tunic (the "I'm special"
    // marker, on-body so it survives any zoom).
    canvas.save();
    canvas.clipRRect(torsoR);
    final Paint sashPaint = Paint()
      ..color = sash
      ..style = PaintingStyle.stroke
      ..strokeWidth = torsoH * 0.22
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(torso.left, torso.top + torsoH * 0.25),
      Offset(torso.right, torso.bottom - torsoH * 0.18),
      sashPaint,
    );
    canvas.restore();

    // Arms (hide skin) — lit cylinders.
    final double shoulderY = -legLen - torsoH * 0.86;
    final double armAngle = armSwing + (armRaise * -1.0);
    _armCylinder(canvas, Offset(-w * 0.24, shoulderY), -armAngle, torsoH * 0.82,
        skin, outline);
    _armCylinder(canvas, Offset(w * 0.24, shoulderY), armAngle, torsoH * 0.82,
        skin, outline);

    // Head (hide skin) with a lit highlight (upper-left key light) + a simple
    // tied-back hair tuft so the hero has a friendly readable face direction.
    canvas.save();
    canvas.translate(0, -legLen - torsoH - headR * 0.72);
    canvas.rotate(headTilt);
    canvas.drawCircle(Offset.zero, headR, skinPaint);
    // Key-light highlight on the upper-left of the head.
    canvas.drawCircle(
      Offset(-headR * 0.32, -headR * 0.32),
      headR * 0.42,
      Paint()..color = Color.lerp(skin, const Color(0xFFFFFFFF), 0.28)!,
    );
    canvas.drawCircle(Offset.zero, headR, outline);
    // A small hair tuft (woodDark) at the crown.
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: headR),
      math.pi * 1.05,
      math.pi * 0.9,
      false,
      Paint()
        ..color = palette.woodDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = headR * 0.55
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();

    canvas.restore();

    // The floating HERO CHEVRON marker above the head (screen-up, gently bobbing)
    // — the unmistakable "this is the player" pip. Drawn outside the body
    // transform so it always hovers cleanly over the figure.
    _drawHeroMarker(canvas, Offset(w / 2, leanY + slump - bodyBob), h, headR);
  }

  /// A soft glowing chevron + spark hovering over the hero's head.
  void _drawHeroMarker(Canvas canvas, Offset bodyShift, double h, double headR) {
    final double bob = reduceMotion ? 0.0 : math.sin(_t * 2.4) * 2.0;
    // The figure's head top sits a little below the component's top edge; hover
    // the marker just above it. [bodyShift.dy] folds in the figure's vertical
    // bob/lean so the marker tracks the head.
    final double markY = bodyShift.dy - h + headR * 0.4 + 2 + bob;
    final Offset at = Offset(bodyShift.dx, markY);

    // Soft warm glow behind the marker.
    CraftKit.bloomStack(
      canvas,
      center: at,
      radius: headR * 1.3,
      intensity: 0.5,
      warm: palette.ember,
      hot: palette.spark,
    );

    // The downward chevron pointing at the hero.
    final double s = headR * 0.7;
    final Path chevron = Path()
      ..moveTo(at.dx - s, at.dy - s * 0.5)
      ..lineTo(at.dx, at.dy + s * 0.5)
      ..lineTo(at.dx + s, at.dy - s * 0.5);
    canvas.drawPath(
      chevron,
      Paint()
        ..color = palette.emberBright
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.4
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  /// A leg as a short lit cylinder rotated by [angle] from [anchor].
  void _legCylinder(Canvas canvas, Offset anchor, double angle, double len,
      Color color, Paint outline) {
    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.rotate(angle);
    // CraftKit cylinder stands up from a base; the limb hangs DOWN from the hip,
    // so draw it as a base at (0,len) extending up to (0,0) in this rotated frame.
    CraftKit.litCylinder(
      canvas,
      base: Offset(0, len),
      w: 7.5,
      h: len,
      body: color,
      outline: outline.color,
      specular: 0.4,
      contactShadow: false,
    );
    canvas.restore();
  }

  /// An arm as a slim lit cylinder rotated by [angle] from [anchor].
  void _armCylinder(Canvas canvas, Offset anchor, double angle, double len,
      Color color, Paint outline) {
    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.rotate(angle);
    CraftKit.litCylinder(
      canvas,
      base: Offset(0, len),
      w: 6.0,
      h: len,
      body: color,
      outline: outline.color,
      specular: 0.45,
      contactShadow: false,
    );
    canvas.restore();
  }
}
