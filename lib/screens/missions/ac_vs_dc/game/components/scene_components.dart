// The Flame scene layers for AC vs DC — a portrait staging of the journey:
//   the SOURCE DOCK (bottom, the one gesture surface) → INPUT line rising →
//   the iron CORE (hero, center) with its PRIMARY (left, 4 fixed loops) +
//   SECONDARY (right, 8 fixed loops) coils → OUTPUT line climbing to the BULB
//   (top-center) → a tiny CURRENT graph at the very bottom.
//
// Each layer is a near-pure renderer reading the controller's pixel/sim getters.
// HARD GATES honoured everywhere (never a fade, reduced motion included):
//   • The amber field's brightness/breath = |fieldLevel| — FROZEN solid on the
//     steady DC feed (no shimmer, no breathing) — dead means motionless.
//   • The output line + bulb track outputLevel (= fieldRate>eps ? f : 0), so they
//     blink for the width of each flip and snap dark the instant the field
//     settles. At wave speed the kick is near-continuous → a steady bulb.
//   • The input pulses follow sign(currentLevel) and visibly reverse on a flip.
// The amber field is additive (BlendMode.plus) and is the brightest thing on
// screen except the bulb for ≤1200 ms at the spring-to-life. Input/output pulses
// are cool transmission-blue (#3FB9F5), NEVER warm (heat = loss is 2.3's
// iconography and must not be contradicted here).

import 'dart:math' as math;

import 'package:flame/components.dart' show Component;
import 'package:flutter/material.dart';

import '../../../hand_crank_lamp/widgets/bulb.dart' show paintBulb, bulbBaseDrop;
import '../../config/acdc_copy.dart';
import '../../config/acdc_tuning.dart';
import '../../state/acdc_controller.dart';

Color _c(int v) => Color(v);
final Color _amber = _c(AcdcTune.coreFieldAmber);
final Color _amberHot = _c(AcdcTune.coreFieldAmberHot);
final Color _blue = _c(AcdcTune.transmissionBlue);
final Color _blueLite = _c(AcdcTune.transmissionBlueLite);
final Color _ironDark = _c(AcdcTune.ironDark);
final Color _ironMid = _c(AcdcTune.ironMid);
final Color _ironLite = _c(AcdcTune.ironLite);
final Color _ironBevel = _c(AcdcTune.ironBevel);
final Color _copper = _c(AcdcTune.copper);
final Color _copperLite = _c(AcdcTune.copperLite);
final Color _copperHot = _c(AcdcTune.copperHot);
final Color _copperDark = _c(AcdcTune.copperDark);
final Color _posTerm = _c(AcdcTune.posTerminal);
final Color _negTerm = _c(AcdcTune.negTerminal);

Paint _glow(Color color, double sigma, {double alpha = 1}) => Paint()
  ..color = color.withValues(alpha: alpha)
  ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);

// A clean glowing conductor in the hand_crank_lamp style: a gently BOWED conduit
// stroke (dim steel → cool blue as it lights) with an additive glow along the run
// and travelling pulses — NO junction hardware. [litFrac] lights the base wire;
// [mag] sets the pulse brightness; [dir] flips the pulse march (current reversal);
// pulses animate only when [animate], else the steady glow carries it.
void _leadWire(
  Canvas canvas,
  Offset start,
  Offset end, {
  required double bowX,
  required double litFrac,
  required double mag,
  required double dir,
  required double pulsePhase,
  required int pulseCount,
  required double w,
  required bool animate,
  double bowY = 0,
}) {
  final lit = litFrac.clamp(0.0, 1.0);
  final mid = Offset((start.dx + end.dx) / 2 + bowX, (start.dy + end.dy) / 2 + bowY);
  final path = Path()
    ..moveTo(start.dx, start.dy)
    ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);

  // base conduit — a clean dim-steel stroke, warming toward cool blue as it lights.
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.014
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(_c(0xFF2C3A63), _blue, 0.45 * lit)!,
  );
  // additive glow along the whole run while live (snaps off with litFrac).
  if (lit > 0.01) {
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.02
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.plus
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.012)
        ..color = _blue.withValues(alpha: 0.24 * lit),
    );
  }
  if (mag < 0.02 || !animate) return;
  // travelling pulses along the path (faded in/out near the ends, so "carried").
  final metric = path.computeMetrics().first;
  final len = metric.length;
  final r = w * 0.013;
  for (var i = 0; i < pulseCount; i++) {
    var f = (pulsePhase + i / pulseCount) % 1.0;
    if (dir < 0) f = 1.0 - f;
    final pos = metric.getTangentForOffset(f * len)?.position;
    if (pos == null) continue;
    final edge = math.sin(f * math.pi).clamp(0.0, 1.0);
    final a = (mag * edge).clamp(0.0, 1.0);
    canvas.drawCircle(pos, r * 1.8, _glow(_blue, r * 2.2, alpha: 0.8 * a));
    canvas.drawCircle(pos, r * 0.7, Paint()..color = _blueLite.withValues(alpha: 0.95 * a));
  }
}

/// Entrance helper: slide + scale + fade a component in as [rev] goes 0→1.
void _reveal(Canvas canvas, Size stage, double rev, Offset slide, Offset pivot, VoidCallback draw) {
  if (rev >= 0.999) {
    draw();
    return;
  }
  if (rev <= 0.001) return;
  canvas.saveLayer(Offset.zero & stage, Paint()..color = Colors.white.withValues(alpha: rev));
  canvas.translate(slide.dx * (1 - rev), slide.dy * (1 - rev));
  final s = 0.88 + 0.12 * rev;
  canvas.translate(pivot.dx, pivot.dy);
  canvas.scale(s);
  canvas.translate(-pivot.dx, -pivot.dy);
  draw();
  canvas.restore();
}

// ── Ambient motes — the hero's energy claims the void (16–22, §7) ──────────────
class AmbientMotesLayer extends Component {
  AmbientMotesLayer(this.c);
  final AcdcController c;
  final math.Random _rng = math.Random(27);
  final List<_Mote> _motes = [];

  @override
  void update(double dt) {
    if (c.stageSize.isEmpty) return;
    if (_motes.isEmpty) {
      for (var i = 0; i < 18; i++) {
        _motes.add(_Mote(_rng.nextDouble(), _rng.nextDouble(), 0.2 + _rng.nextDouble() * 0.5,
            0.4 + _rng.nextDouble() * 0.8));
      }
    }
    final spd = c.reducedMotion ? 0.2 : 1.0;
    for (final m in _motes) {
      m.y -= dt * 0.012 * m.speed * spd;
      m.x += dt * 0.004 * math.sin(c.shimmer * m.speed + m.phase) * spd;
      if (m.y < -0.02) {
        m.y = 1.02;
        m.x = _rng.nextDouble();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    final w = c.stageSize.width, h = c.stageSize.height;
    final core = c.coreCenter;
    for (final m in _motes) {
      final p = Offset(m.x * w, m.y * h);
      final d = (p - core).distance / w;
      final bias = (1 - d).clamp(0.0, 1.0);
      final a = m.alpha * 0.06 * (0.4 + 0.6 * bias);
      canvas.drawCircle(p, m.r * 2.2, _glow(_c(0xFF9FC0FF), m.r * 2.0, alpha: a));
    }
  }
}

// ── Background glow — a DEEP vignette pool behind the core, then the core's amber
//    field washing the dark. Critically: the bloom rides |fieldLevel| only AND a
//    breath that is gated to ZERO when the field isn't changing — so on the frozen
//    DC feed the wash is a FAINT, MOTIONLESS amber (no pulsing glow), and it surges
//    only while the field breathes (alive / each flip). Two layers (a wide soft
//    halo + a tighter hotter heart) ported from 2.6 for the premium bloom. ───────
class BackgroundGlowLayer extends Component {
  BackgroundGlowLayer(this.c);
  final AcdcController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    final core = c.coreCenter;

    // A deep cool vignette pool seated UNDER the core — darkest right behind the
    // hero so the amber blooms against the void (P2: deep vignette behind core).
    final vr = c.coreOuterW * 1.7;
    canvas.drawCircle(
      core,
      vr,
      Paint()
        ..shader = RadialGradient(colors: [
          _c(0xFF000308).withValues(alpha: 0.55),
          _c(0xFF000308).withValues(alpha: 0),
        ], stops: const [0.0, 1.0]).createShader(Rect.fromCircle(center: core, radius: vr)),
    );

    // The amber bloom — brightness = |fieldLevel| (static, present even when
    // dead), boosted by a breath that is gated OFF unless the field is changing.
    // changing → a live surge; frozen DC / between flips → a faint still wash.
    final fb = c.fieldLevel.abs().clamp(0.0, 1.0);
    final changing = c.fieldRate > AcdcTune.fieldRateEps;
    final breath = changing ? c.fieldRate.clamp(0.0, 1.0) : 0.0;
    final bloom = (fb + 0.4 * breath).clamp(0.0, 1.0);

    // Wide soft halo.
    final r = c.coreOuterW * (0.72 + 0.55 * bloom);
    canvas.drawCircle(
      core,
      r,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(colors: [
          // A faint amber floor so even the DEAD core warms the void a touch.
          _amber.withValues(alpha: 0.05 + 0.18 * bloom),
          _amber.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: core, radius: r)),
    );
    // Tighter hotter heart — only meaningful when the field is bright/breathing.
    final rh = c.coreOuterW * (0.34 + 0.22 * bloom);
    canvas.drawCircle(
      core,
      rh,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(colors: [
          _amberHot.withValues(alpha: 0.05 + 0.20 * bloom),
          _amberHot.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: core, radius: rh)),
    );

    // Scene dim — a soft darkening over the whole stage in steadyDead/bridge.
    if (c.sceneDim > 0.01) {
      canvas.drawRect(Offset.zero & c.stageSize,
          Paint()..color = _c(0xFF050712).withValues(alpha: c.sceneDim));
    }
  }
}

// ── The INPUT line — source dock → primary bottom. Directional pulses follow
//    sign(currentLevel): they march UP on +current and REVERSE (march down) on
//    a flip — the felt "the current reverses". Cool transmission-blue. ──────────
class InputLineLayer extends Component {
  InputLineLayer(this.c);
  final AcdcController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    _reveal(canvas, c.stageSize, c.dockReveal, Offset(0, c.stageSize.height * 0.04),
        c.inputTo, () => _draw(canvas));
  }

  void _draw(Canvas canvas) {
    final w = c.stageSize.width;
    final cur = c.currentLevel;
    final mag = cur.abs().clamp(0.0, 1.0);
    final dir = cur >= 0 ? 1.0 : -1.0; // +1 = up toward the core, −1 = back to the source
    // A clean glowing conduit (hand_crank_lamp style) from the source up to the
    // primary coil; the pulse march reverses with the current (the felt reversal).
    _leadWire(
      canvas,
      c.inputFrom,
      c.inputTo,
      bowX: -w * 0.008,
      litFrac: mag,
      mag: mag,
      dir: dir,
      pulsePhase: c.shimmer * AcdcTune.inputPulseSpeed,
      pulseCount: AcdcTune.inputPulseCount,
      w: w,
      animate: !c.reducedMotion,
    );
  }
}

// ── The OUTPUT line — secondary top → bulb base. Cool-blue pulses whose liveness
//    tracks outputLevel (the kick): alive for the width of each flip, dark the
//    instant the field settles. Steady-bright while the wave runs. ─────────────
class OutputLineLayer extends Component {
  OutputLineLayer(this.c);
  final AcdcController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    _reveal(canvas, c.stageSize, c.bulbReveal, Offset(0, -c.stageSize.height * 0.03),
        c.outputFrom, () => _draw(canvas));
  }

  void _draw(Canvas canvas) {
    final w = c.stageSize.width;
    final from = c.outputFrom;
    // Join the bulb at the bottom of its screw base (the natural lead point), so the
    // wire connects cleanly into the bulb rather than stopping short.
    final to = c.bulbCenter.translate(0, bulbBaseDrop(c.bulbRadius));
    final live = c.outputLevel.clamp(0.0, 1.0); // the HARD-GATED kick
    // A clean glowing conduit — always present (dim) so the dead output reads as a
    // wire waiting; it lights + pulses for the width of each kick, snapping dark the
    // instant the field settles. bowY lifts it UP so it arcs OVER the core rather
    // than cutting through the top of the window.
    _leadWire(
      canvas,
      from,
      to,
      bowX: w * 0.012,
      bowY: -c.stageSize.height * 0.045,
      litFrac: live,
      mag: (0.5 + 0.5 * live) * live,
      dir: 1.0,
      pulsePhase: c.shimmer * AcdcTune.outputPulseSpeed,
      pulseCount: AcdcTune.outputPulseCount,
      w: w,
      animate: !c.reducedMotion,
    );
  }
}

// ── THE HERO — the dark iron core ring with its amber field. The field's
//    brightness/breath = |fieldLevel|; the travelling flux highlight runs only
//    when the field is CHANGING (fieldRate above eps) — so on the steady DC feed
//    it is FROZEN solid (no shimmer, no breathing). Dead means motionless. ──────
class CoreFieldLayer extends Component {
  CoreFieldLayer(this.c);
  final AcdcController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    _reveal(canvas, c.stageSize, c.coreReveal, Offset(0, c.stageSize.height * 0.02),
        c.coreCenter, () => _draw(canvas));
  }

  void _draw(Canvas canvas) {
    final ctr = c.coreCenter;
    final ow = c.coreOuterW, oh = c.coreOuterH;
    final lt = c.limbThickness;
    final outer = RRect.fromRectAndRadius(
      Rect.fromCenter(center: ctr, width: ow, height: oh),
      Radius.circular(lt * 0.7),
    );
    final inner = RRect.fromRectAndRadius(
      Rect.fromCenter(center: ctr, width: ow - lt * 2, height: oh - lt * 2),
      Radius.circular(lt * 0.4),
    );
    final fb = c.fieldLevel.abs().clamp(0.0, 1.0);

    // 1) Soft contact shadow under the heavy iron ring (it has weight).
    canvas.drawRRect(outer.shift(Offset(0, oh * 0.045)),
        _glow(Colors.black, lt * 1.1, alpha: 0.34));

    // 2) The dark iron body — a laminated steel ring (the "window" frame), drawn
    //    as an even-odd ring path with a directional gradient (top-left lit, foot
    //    dark) — ported from 2.6's dimensional core.
    final body = Path()
      ..addRRect(outer)
      ..addRRect(inner)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_ironLite.withValues(alpha: 0.55), _ironMid, _ironDark],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(outer.outerRect),
    );

    // 3) Dimensional bevels — a lit outer top-left edge + a recessed inner window
    //    edge, so the ring reads as a heavy chamfered block, not a flat outline.
    _bevels(canvas, outer, inner, lt);

    // 4) The richer lamination texture (the stacked steel sheets).
    _laminations(canvas, ctr, ow, oh, lt);

    // 5) Crisp outer + inner edge strokes (a thin specular rim).
    canvas.drawRRect(outer, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = _ironLite.withValues(alpha: 0.40));
    canvas.drawRRect(inner, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _c(0xFF0A0E22).withValues(alpha: 0.85));

    // 6) THE HERO — the amber FLUX. A faint static ribbon when DEAD; a vivid
    //    circulating comet-loop when ALIVE (the field is changing).
    _fluxLoop(canvas, ctr, ow, oh, lt, fb);
  }

  /// Dimensional bevels (ported from 2.6) — a lit outer top-left edge + a shaded
  /// bottom-right, and a recessed inner window edge (inverted lighting, since the
  /// window is cut INTO the iron) so the ring reads as a heavy chamfered block.
  void _bevels(Canvas canvas, RRect outer, RRect inner, double lt) {
    final band = lt * AcdcTune.coreBevelFactor;
    final or = outer.outerRect, ir = inner.outerRect;
    canvas.save();
    canvas.clipRRect(outer);
    final litPaint = Paint()
      ..color = _ironBevel.withValues(alpha: 0.55)
      ..strokeWidth = band
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(or.left, or.top + band), Offset(or.right, or.top + band), litPaint);
    canvas.drawLine(Offset(or.left + band, or.top), Offset(or.left + band, or.bottom), litPaint);
    final shadePaint = Paint()
      ..color = _c(0xFF080B1C).withValues(alpha: 0.6)
      ..strokeWidth = band
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(or.left, or.bottom - band), Offset(or.right, or.bottom - band), shadePaint);
    canvas.drawLine(Offset(or.right - band, or.top), Offset(or.right - band, or.bottom), shadePaint);
    canvas.restore();
    // Inner window edge — recessed: dark on top/left, faint lift on bottom/right.
    final innerDark = Paint()
      ..color = _c(0xFF05081A).withValues(alpha: 0.7)
      ..strokeWidth = band * 0.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(ir.left, ir.top + band * 0.5), Offset(ir.right, ir.top + band * 0.5), innerDark);
    canvas.drawLine(Offset(ir.left + band * 0.5, ir.top), Offset(ir.left + band * 0.5, ir.bottom), innerDark);
    final innerLift = Paint()
      ..color = _ironLite.withValues(alpha: 0.22)
      ..strokeWidth = band * 0.7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(ir.left, ir.bottom - band * 0.5), Offset(ir.right, ir.bottom - band * 0.5), innerLift);
    canvas.drawLine(Offset(ir.right - band * 0.5, ir.top), Offset(ir.right - band * 0.5, ir.bottom), innerLift);
  }

  void _laminations(Canvas canvas, Offset ctr, double ow, double oh, double lt) {
    // Stacked steel-sheet hairlines down both limbs + across the yokes —
    // alternating a faint dark groove and a faint lit ridge (ported from 2.6).
    final n = AcdcTune.coreLaminations;
    for (final sign in [-1.0, 1.0]) {
      final lx = ctr.dx + sign * (ow * 0.5 - lt * 0.5);
      for (var i = -(n ~/ 2); i <= n ~/ 2; i++) {
        final x = lx + i * (lt * 0.9 / n);
        final groove = i.isEven;
        canvas.drawLine(
          Offset(x, ctr.dy - oh * 0.5 + lt * 0.22),
          Offset(x, ctr.dy + oh * 0.5 - lt * 0.22),
          Paint()
            ..color = (groove ? _c(0xFF0A0E22) : _ironLite).withValues(alpha: groove ? 0.5 : 0.16)
            ..strokeWidth = 1.0,
        );
      }
    }
    for (final sy in [-1.0, 1.0]) {
      final ly = ctr.dy + sy * (oh * 0.5 - lt * 0.5);
      for (var i = -(n ~/ 2); i <= n ~/ 2; i++) {
        final y = ly + i * (lt * 0.9 / n);
        final groove = i.isEven;
        canvas.drawLine(
          Offset(ctr.dx - ow * 0.5 + lt * 0.22, y),
          Offset(ctr.dx + ow * 0.5 - lt * 0.22, y),
          Paint()
            ..color = (groove ? _c(0xFF0A0E22) : _ironLite).withValues(alpha: groove ? 0.4 : 0.12)
            ..strokeWidth = 1.0,
        );
      }
    }
  }

  /// THE HERO — the magnetic FLUX circulating the iron window like a current loop
  /// (ported from 2.6). A base ribbon whose alpha rides |fieldLevel|, and bright
  /// comet-heads with fading tails that TRAVEL the perimeter.
  ///
  /// THE DISCOVERY LIVES HERE: the comet-heads + the breath circulate ONLY while
  /// the field is CHANGING (fieldRate > eps). On the steady DC feed and between
  /// every pair of flips the loop is SKIPPED entirely — the field is a FAINT,
  /// MOTIONLESS amber (no travelling flux, no breathing, no shimmer). Dead means
  /// motionless; that stillness is the discovery and is never softened. Reduced
  /// motion calms the travel to a steady bloom but keeps the dead/alive contrast.
  void _fluxLoop(Canvas canvas, Offset ctr, double ow, double oh, double lt, double fb) {
    final innerW = ow - lt * 2, innerH = oh - lt * 2;
    // The flux travels through the MIDDLE of the iron band (the magnetic path).
    final pathW = innerW + lt, pathH = innerH + lt;
    final rect = Rect.fromCenter(center: ctr, width: pathW, height: pathH);
    final radius = lt * 0.55;
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final stroke = lt * AcdcTune.fluxStrokeFactor;

    // Is the field changing? This single gate decides motion vs stillness.
    final changing = c.fieldRate > AcdcTune.fieldRateEps;
    // The breath only lifts the ribbon while changing; frozen → a static floor.
    final breath = changing ? c.fieldRate.clamp(0.0, 1.0) : 0.0;

    // 1) Base flux glow around the whole loop. The floor is present even when
    //    DEAD (so the core stays the visual center, a faint still amber), lifted
    //    by |field| × breath only while changing.
    final baseAlpha = (AcdcTune.fluxRibbonAlphaFloor +
            AcdcTune.fluxRibbonAlphaGain * fb * (0.35 + 0.65 * breath))
        .clamp(0.0, 1.0);
    canvas.drawRRect(
      rr,
      Paint()
        ..blendMode = BlendMode.plus
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = _amber.withValues(alpha: baseAlpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, lt * 0.5),
    );
    // A thin sharp core line so the loop has a crisp spine, not a haze. Its
    // brightness also rides the breath, so the DEAD core is faint but PRESENT.
    canvas.drawRRect(
      rr,
      Paint()
        ..blendMode = BlendMode.plus
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 0.32
        ..strokeCap = StrokeCap.round
        ..color = _amber.withValues(alpha: (0.07 + 0.30 * fb * breath).clamp(0.0, 1.0)),
    );

    // 2) The travelling comet-heads — the unmistakable CIRCULATION, drawn ONLY
    //    while the field is changing AND motion is allowed. On the frozen DC
    //    field (and between flips) this is skipped: ZERO motion. With reduced
    //    motion the travel is replaced by a steady (still) bloom while changing.
    final headBright = (0.45 + AcdcTune.fieldBloomGain * fb * breath).clamp(0.0, 1.0);
    if (changing && !c.reducedMotion) {
      final heads = AcdcTune.fluxHeadCount;
      final span = AcdcTune.fluxHeadSpanFactor;
      final samples = AcdcTune.fluxTrailSamples;
      for (var hI = 0; hI < heads; hI++) {
        final head = (c.shimmer * AcdcTune.fluxLoopSpeed + hI / heads) % 1.0;
        for (var s2 = samples - 1; s2 >= 0; s2--) {
          final f = s2 / (samples - 1); // 0 (head) → 1 (tail-end)
          final t = (head - span * f) % 1.0;
          final tt = t < 0 ? t + 1 : t;
          final p = _onRoundedLoop(rect, radius, tt);
          final fade = (1 - f) * (1 - f);
          final a = (headBright * fade).clamp(0.0, 1.0);
          if (s2 == 0) {
            canvas.drawCircle(p, stroke * 0.95, _glow(_amberHot, stroke * 1.1, alpha: headBright));
            canvas.drawCircle(p, stroke * 0.45,
                Paint()..blendMode = BlendMode.plus..color = _amberHot.withValues(alpha: headBright));
          } else {
            canvas.drawCircle(p, stroke * (0.4 + 0.45 * fade),
                _glow(_amber, stroke * 0.7, alpha: a * 0.85));
          }
        }
      }
    } else if (changing && c.reducedMotion) {
      // Reduced motion: a steady symmetric bloom on the loop (no travel) — but
      // ONLY while changing, so the dead stillness still reads with RM on.
      canvas.drawRRect(
        rr,
        Paint()
          ..blendMode = BlendMode.plus
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 0.6
          ..strokeCap = StrokeCap.round
          ..color = _amberHot.withValues(alpha: 0.30 * headBright)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, lt * 0.4),
      );
    }

    // 3) The OUTPUT (right) limb glow rides the kick (outputLevel) — slack/dead
    //    exactly the frame the field settles. A felt, not-numbered signal that the
    //    output works only while the field is changing. A HARD envelope.
    final rightLimbX = ctr.dx + ow * 0.5 - lt * 0.5;
    final kick = c.outputLevel.clamp(0.0, 1.0);
    final glowRect = Rect.fromCenter(
        center: Offset(rightLimbX, ctr.dy), width: lt * 1.5, height: oh * 0.88);
    canvas.drawRRect(
      RRect.fromRectAndRadius(glowRect, Radius.circular(lt * 0.45)),
      Paint()
        ..blendMode = BlendMode.plus
        ..color = _amberHot.withValues(alpha: 0.58 * kick)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, lt * 0.62),
    );
  }

  /// A point at perimeter fraction [t] (0..1) walking the rounded-rect window
  /// loop, with the corners traced as arcs (ported from 2.6's `_onRoundedLoop`).
  Offset _onRoundedLoop(Rect rect, double r, double t) {
    final l = rect.left, rt = rect.right, tp = rect.top, bt = rect.bottom;
    final straightH = (rt - l) - 2 * r;
    final straightV = (bt - tp) - 2 * r;
    final arc = (math.pi / 2) * r;
    final total = 2 * straightH + 2 * straightV + 4 * arc;
    var d = (t % 1.0) * total;
    final cx = (l + rt) / 2;
    final halfTop = straightH / 2;
    if (d <= halfTop) return Offset(cx + d, tp);
    d -= halfTop;
    if (d <= arc) {
      final a = -math.pi / 2 + (d / arc) * (math.pi / 2);
      return Offset(rt - r + r * math.cos(a), tp + r + r * math.sin(a));
    }
    d -= arc;
    if (d <= straightV) return Offset(rt, tp + r + d);
    d -= straightV;
    if (d <= arc) {
      final a = (d / arc) * (math.pi / 2);
      return Offset(rt - r + r * math.cos(a), bt - r + r * math.sin(a));
    }
    d -= arc;
    if (d <= straightH) return Offset(rt - r - d, bt);
    d -= straightH;
    if (d <= arc) {
      final a = math.pi / 2 + (d / arc) * (math.pi / 2);
      return Offset(l + r + r * math.cos(a), bt - r + r * math.sin(a));
    }
    d -= arc;
    if (d <= straightV) return Offset(l, bt - r - d);
    d -= straightV;
    if (d <= arc) {
      final a = math.pi + (d / arc) * (math.pi / 2);
      return Offset(l + r + r * math.cos(a), tp + r + r * math.sin(a));
    }
    d -= arc;
    return Offset(l + r + d, tp);
  }
}

// ── The PRIMARY coil — 4 FIXED loops on the LEFT limb (held constant). ─────────
class PrimaryCoilLayer extends Component {
  PrimaryCoilLayer(this.c);
  final AcdcController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    _reveal(canvas, c.stageSize, c.coilReveal, Offset(-c.stageSize.width * 0.03, 0),
        c.coreCenter, () => _draw(canvas));
  }

  void _draw(Canvas canvas) {
    final ctr = c.coreCenter;
    final ow = c.coreOuterW, oh = c.coreOuterH, lt = c.limbThickness;
    final limbX = ctr.dx - ow * 0.5 + lt * 0.5;
    _drawCoil(canvas, limbX, ctr.dy, oh, lt, c.primaryTurns);
  }
}

// ── The SECONDARY coil — 8 FIXED loops on the RIGHT limb (held constant). Never
//    rewound or moved — matches 2.6's ending state. ─────────────────────────────
class SecondaryCoilLayer extends Component {
  SecondaryCoilLayer(this.c);
  final AcdcController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    _reveal(canvas, c.stageSize, c.coilReveal, Offset(c.stageSize.width * 0.03, 0),
        c.coreCenter, () => _draw(canvas));
  }

  void _draw(Canvas canvas) {
    final ctr = c.coreCenter;
    final ow = c.coreOuterW, oh = c.coreOuterH, lt = c.limbThickness;
    final limbX = ctr.dx + ow * 0.5 - lt * 0.5;
    _drawCoil(canvas, limbX, ctr.dy, oh, lt, c.secondaryTurns);
  }
}

/// Shared coil renderer — [turns] DIMENSIONAL copper windings wrapped around a
/// vertical limb at [limbX], centred at [cy], spanning [oh] (ported from 2.6's
/// 3D copper coil). Each turn is a back arc (behind the limb, recessed/dark) + a
/// front arc (in front, bright copper with a cylindrical shade + a specular
/// sheen) so the coil reads as wound wire with depth. FIXED — these coils never
/// change all activity (the held constant); no wrap flourish.
void _drawCoil(Canvas canvas, double limbX, double cy, double oh, double lt, int turns) {
  final span = oh * 0.80;
  final top = cy - span / 2;
  final loopH = span / turns;
  final loopW = lt * AcdcTune.coilLoopWidthFactor;
  final wire = lt * AcdcTune.coilWireFactor;
  final sheenW = math.max(1.0, lt * AcdcTune.coilSheenFactor);

  // Back arcs first (whole stack), so every front arc overlaps the back of the
  // loop below it — the woven, overlapping look of real wound wire.
  for (var i = 0; i < turns; i++) {
    final y = top + loopH * (i + 0.5);
    final rect = Rect.fromCenter(center: Offset(limbX, y), width: loopW, height: loopH * 0.96);
    canvas.drawArc(rect, -math.pi / 2, math.pi, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = wire * 0.92
          ..strokeCap = StrokeCap.round
          ..color = _copperDark.withValues(alpha: 0.9));
  }

  // Front arcs (bright copper) over the top — these read as the loops.
  for (var i = 0; i < turns; i++) {
    final y = top + loopH * (i + 0.5);
    final rect = Rect.fromCenter(center: Offset(limbX, y), width: loopW, height: loopH * 0.96);

    // A soft contact shadow under each loop (it sits ON the limb).
    canvas.drawArc(rect.shift(Offset(0, wire * 0.35)), math.pi / 2, math.pi, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = wire * 1.05
          ..strokeCap = StrokeCap.round
          ..color = Colors.black.withValues(alpha: 0.22));

    // The front copper arc — a cylindrical shade across the wire (lit top, dark foot).
    canvas.drawArc(rect, math.pi / 2, math.pi, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = wire
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_copperLite, _copper, _copperDark],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(rect));

    // A thin specular sheen riding the upper edge of the wire — the copper highlight.
    final sheenRect = Rect.fromCenter(
        center: rect.center.translate(0, -wire * 0.22),
        width: rect.width, height: rect.height);
    canvas.drawArc(sheenRect, math.pi / 2 + 0.35, math.pi - 0.7, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = sheenW
          ..strokeCap = StrokeCap.round
          ..color = _copperHot.withValues(alpha: 0.7));
  }
}

// ── The OUTPUT BULB — top-center; the aliveness readout. Driven STRAIGHT off
//    bulbBrightnessDisplay (= the hard-gated bulbBrightness, plus a brief spring
//    overshoot). The underlying bulbBrightness is hard-zeroed the instant the
//    field settles — it SNAPS off, never a cooling fade. At the spring-to-life
//    the bulb FLOODS to full with an extra additive bloom — the one ≤1200 ms
//    moment it may briefly outshine the core. ──────────────────────────────────
class OutputBulbLayer extends Component {
  OutputBulbLayer(this.c);
  final AcdcController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    _reveal(canvas, c.stageSize, c.bulbReveal, Offset(0, -c.stageSize.height * 0.03),
        c.bulbCenter, () => _draw(canvas));
  }

  void _draw(Canvas canvas) {
    final ctr = c.bulbCenter;
    final r = c.bulbRadius;
    final b = c.bulbBrightnessDisplay;
    final spring = c.aliveSpring;

    // The spring-to-life flood — a wide warm halo behind the bulb that swells at
    // the burst (so the bulb visibly FLOODS to full and briefly outshines the
    // core). Rides aliveSpring, so it exists ONLY in the ≤1200 ms spring window.
    if (spring > 0.01) {
      final hr = r * (2.0 + 1.6 * spring);
      canvas.drawCircle(
        ctr,
        hr,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(colors: [
            const Color(0xFFFFF6E0).withValues(alpha: 0.5 * spring),
            const Color(0xFFFFE9B8).withValues(alpha: 0.18 * spring),
            const Color(0xFFFFE9B8).withValues(alpha: 0),
          ], stops: const [0.0, 0.45, 1.0]).createShader(Rect.fromCircle(center: ctr, radius: hr)),
      );
    }

    paintBulb(canvas, ctr, r, b);

    // A crisp expanding ring at the spring crest — the "it sprang alive" beat.
    if (spring > 0.02) {
      final ringR = r * (1.1 + (1 - spring) * 1.3);
      canvas.drawCircle(
        ctr,
        ringR,
        Paint()
          ..blendMode = BlendMode.plus
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.10 * spring
          ..color = const Color(0xFFFFF6E0).withValues(alpha: 0.6 * spring)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.12),
      );
    }
  }
}

// ── The SOURCE DOCK (the one gesture surface) — a dark-glass bay. The battery
//    sits in it with a flip animation (180° rotation reading flipT) and visible
//    +/− ends; at handoff it slides out left and the machine source slides in
//    (same footprint, NO label/icon, no waveform). A grab hint pulses until the
//    learner connects. ──────────────────────────────────────────────────────────
class SourceDockLayer extends Component {
  SourceDockLayer(this.c);
  final AcdcController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    _reveal(canvas, c.stageSize, c.dockReveal, Offset(0, c.stageSize.height * 0.05),
        c.dockCenter, () => _draw(canvas));
  }

  void _draw(Canvas canvas) {
    // The battery sits in its OWN fixed compartment; the ON switch is a SEPARATE
    // unit to the right. At handoff the battery slides out of the compartment and
    // the machine slides into the same compartment; the switch stays put.
    final bc = c.batteryCenter;
    _drawCompartment(canvas, bc);

    final swap = c.swapT;
    if (c.occupant == DockOccupant.battery || swap < 0.5) {
      final slide = -c.dockW * 1.4 * Curves.easeIn.transform((swap / 0.5).clamp(0.0, 1.0));
      _drawBattery(canvas, bc.translate(slide, 0));
    }
    if (swap > 0.5) {
      final tIn = ((swap - 0.5) / 0.5).clamp(0.0, 1.0);
      final slide = c.dockW * 1.4 * (1 - Curves.easeOut.transform(tIn));
      _drawMachine(canvas, bc.translate(slide, 0));
    }

    // The separate, premium ON switch — its own unit, outside the compartment.
    _drawSwitch(canvas, c.switchCenter);
    if (c.grabHintActive) _grabHint(canvas, c.switchCenter);
  }

  // The battery's OWN compartment — a recessed dark-glass bay it seats into (deep
  // fill, inset well, top catch-light, crisp rim; cohesive with the 2.1–2.6 chrome).
  void _drawCompartment(Canvas canvas, Offset ctr) {
    final w = c.stageSize.width;
    // Longer (wider) so the horizontal cell seats with margin on both ends.
    final cw = c.batteryW * 1.45, ch = c.batteryH * 2.1;
    final rect = Rect.fromCenter(center: ctr, width: cw, height: ch);
    final bay = RRect.fromRectAndRadius(rect, Radius.circular(w * 0.028));
    canvas.drawRRect(bay.shift(Offset(0, ch * 0.05)), _glow(Colors.black, w * 0.018, alpha: 0.30));
    canvas.drawRRect(bay, Paint()..color = _c(0xFF0B1026).withValues(alpha: 0.62));
    canvas.drawRRect(bay, Paint()..color = _c(0x14FFFFFF));
    // Recessed well — a SMALL horizontal inset (so the cell fits end-to-end) + a
    // taller vertical frame (the old uniform height-based inset over-pinched the sides).
    final well = RRect.fromRectAndRadius(
      Rect.fromLTRB(rect.left + cw * 0.05, rect.top + ch * 0.17, rect.right - cw * 0.05, rect.bottom - ch * 0.17),
      Radius.circular(w * 0.02),
    );
    canvas.drawRRect(well, Paint()..color = _c(0xFF05081A).withValues(alpha: 0.55));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.34),
        Radius.circular(w * 0.028),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.05),
    );
    canvas.drawRRect(bay, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _c(0x26FFFFFF));
  }

  void _drawBattery(Canvas canvas, Offset ctr) {
    final w = c.stageSize.width;
    final bw = c.batteryW, bh = c.batteryH;
    canvas.save();
    canvas.translate(ctr.dx, ctr.dy);
    // 180° flip about the battery's vertical center: scale X by cos(flipT*π),
    // so it reads as a physical rotation (the + / − ends swap as it passes edge-on).
    final ang = c.flipT * math.pi;
    final sx = math.cos(ang);
    canvas.scale(sx.abs() < 0.04 ? 0.04 * sx.sign : sx, 1.0);

    // A proper horizontal CYLINDRICAL cell: a + nub protrudes on the LEFT end, a
    // flat − end on the right, a metal body with a cylindrical (dark→lit→dark)
    // cross-section shade and a top specular, and warm/cool sleeves marking ± .
    final nubW = bw * 0.05;
    final coreW = bw - nubW;
    final bodyRect = Rect.fromCenter(center: Offset(nubW * 0.5, 0), width: coreW, height: bh);
    final body = RRect.fromRectAndRadius(bodyRect, Radius.circular(bh * 0.34));

    // the + nub (drawn first, behind the body left edge).
    final nub = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(bodyRect.left - nubW * 0.35, 0), width: nubW * 1.6, height: bh * 0.44),
      Radius.circular(nubW * 0.4),
    );
    canvas.drawRRect(
      nub,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_c(0xFF9AA6D4), _c(0xFF4A5790)],
        ).createShader(nub.outerRect),
    );

    // cylindrical body (dark top edge → lit body → dark bottom edge).
    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_c(0xFF222A52), _c(AcdcTune.batteryShellLite), _c(AcdcTune.batteryShell)],
          stops: const [0.0, 0.40, 1.0],
        ).createShader(body.outerRect),
    );
    // warm + sleeve (left) / cool − sleeve (right), clipped to the rounded body.
    final capW = coreW * 0.20;
    canvas.save();
    canvas.clipRRect(body);
    canvas.drawRect(
      Rect.fromLTWH(bodyRect.left, bodyRect.top, capW, bh),
      Paint()..color = _posTerm.withValues(alpha: 0.80),
    );
    canvas.drawRect(
      Rect.fromLTWH(bodyRect.right - capW, bodyRect.top, capW, bh),
      Paint()..color = _negTerm.withValues(alpha: 0.80),
    );
    // top specular sheen line across the metal body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bodyRect.left + coreW * 0.05, bodyRect.top + bh * 0.10, coreW * 0.9, bh * 0.20),
        Radius.circular(bh * 0.12),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );
    canvas.restore();
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _ironLite.withValues(alpha: 0.6),
    );

    // + / − glyphs on each end cap.
    final lp = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..strokeWidth = w * 0.006
      ..strokeCap = StrokeCap.round;
    final g = bh * 0.18;
    final pc = Offset(bodyRect.left + capW * 0.5, 0);
    final mc = Offset(bodyRect.right - capW * 0.5, 0);
    canvas.drawLine(pc.translate(-g, 0), pc.translate(g, 0), lp);
    canvas.drawLine(pc.translate(0, -g), pc.translate(0, g), lp);
    canvas.drawLine(mc.translate(-g, 0), mc.translate(g, 0), lp);
    canvas.restore();
  }

  // The premium ON switch — its OWN machined unit beside the battery compartment.
  // A raised metal housing (bevelled, lit up-left) with a "POWER" label + an LED
  // that lights green, and a recessed toggle whose chrome knob slides off→on while
  // the channel floods green. The surface the learner taps to START (connect gate).
  void _drawSwitch(Canvas canvas, Offset ctr) {
    final w = c.stageSize.width;
    final sw = c.switchW, sh = c.switchH;
    final on = c.connectRamp.clamp(0.0, 1.0); // 0 off → 1 on (smooth)
    final green = _c(AcdcTune.switchOn);

    // A small "POWER" label above the toggle.
    final tp = TextPainter(
      text: TextSpan(
        text: 'POWER',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: sh * 0.34,
          letterSpacing: 1.3,
          fontWeight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.55),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(ctr.dx - tp.width / 2, ctr.dy - sh * 0.5 - tp.height - sh * 0.22));

    // The toggle is a PILL track + a sliding glossy knob (iOS-style). Off = dark
    // recessed track, knob left; on = the channel floods green and the knob slides
    // smoothly to the right.
    final trackR = Rect.fromCenter(center: ctr, width: sw, height: sh);
    final track = RRect.fromRectAndRadius(trackR, Radius.circular(sh * 0.5));
    canvas.drawRRect(track.shift(Offset(0, sh * 0.14)), _glow(Colors.black, w * 0.012, alpha: 0.32));
    canvas.drawRRect(track, Paint()..color = _c(0xFF0A1124).withValues(alpha: 0.95));
    // green flood from the left, growing with `on`.
    canvas.save();
    canvas.clipRRect(track);
    if (on > 0.001) {
      canvas.drawRect(
        Rect.fromLTRB(trackR.left, trackR.top, trackR.left + trackR.width * on + sh * 0.5, trackR.bottom),
        Paint()
          ..shader = LinearGradient(
            colors: [green.withValues(alpha: 0.45), green.withValues(alpha: 0.8)],
          ).createShader(trackR),
      );
    }
    // inner top shadow — the channel reads recessed.
    canvas.drawLine(
      Offset(trackR.left, trackR.top + sh * 0.06),
      Offset(trackR.right, trackR.top + sh * 0.06),
      Paint()
        ..strokeWidth = sh * 0.12
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sh * 0.06),
    );
    canvas.restore();
    if (on > 0.02) canvas.drawRRect(track, _glow(green, w * 0.009, alpha: 0.45 * on));
    canvas.drawRRect(track, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = _ironLite.withValues(alpha: 0.5));

    // the glossy chrome knob slides left (off) → right (on), smoothly.
    final knobR = sh * 0.40;
    final pad = sh * 0.10 + knobR;
    final knobX = trackR.left + pad + (trackR.width - 2 * pad) * on;
    final knobC = Offset(knobX, ctr.dy);
    canvas.drawCircle(knobC.translate(0, knobR * 0.16), knobR, _glow(Colors.black, sh * 0.09, alpha: 0.42));
    canvas.drawCircle(
      knobC,
      knobR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          colors: [_c(0xFFF6F9FF), _c(0xFF98A6CC)],
        ).createShader(Rect.fromCircle(center: knobC, radius: knobR)),
    );
    canvas.drawCircle(knobC.translate(-knobR * 0.3, -knobR * 0.32), knobR * 0.26,
        Paint()..color = Colors.white.withValues(alpha: 0.8));
    canvas.drawCircle(knobC, knobR, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.6));
  }

  void _drawMachine(Canvas canvas, Offset ctr) {
    final w = c.stageSize.width;
    final bw = c.batteryW * 1.06, bh = c.batteryH * 1.05;
    // A quiet rounded unit — NO "AC" label, NO waveform icon (criterion 5).
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: ctr, width: bw, height: bh),
      Radius.circular(bh * 0.34),
    );
    canvas.drawRRect(body, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_c(AcdcTune.machineShellLite), _c(AcdcTune.machineShell)],
      ).createShader(body.outerRect));
    canvas.drawRRect(body, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _blue.withValues(alpha: 0.40));
    // A neutral cool port glow at the output edge (energy, not a symbol).
    canvas.drawCircle(ctr.translate(bw * 0.32, 0), bh * 0.22,
        _glow(_blue, w * 0.012, alpha: 0.5 * c.fieldLevel.abs().clamp(0.0, 1.0)));
    // Two recessed seams — an anonymous machine face.
    final seam = Paint()
      ..color = _c(0xFF0B1026).withValues(alpha: 0.7)
      ..strokeWidth = 1.4;
    for (var i = -1; i <= 1; i += 2) {
      final x = ctr.dx + i * bw * 0.18;
      canvas.drawLine(Offset(x, ctr.dy - bh * 0.28), Offset(x, ctr.dy + bh * 0.28), seam);
    }
  }

  void _grabHint(Canvas canvas, Offset ctr) {
    final w = c.stageSize.width;
    final pulse = 0.35 + 0.30 * (0.5 + 0.5 * math.sin(c.shimmer * 3));
    // A pulsing pill ring hugging the toggle (the "Turn Power On" caption guides it).
    final ring = Rect.fromCenter(center: ctr, width: c.switchW * 1.22, height: c.switchH * 1.9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(ring, Radius.circular(c.switchH * 0.95)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.006
        ..color = _c(0xFFFFD970).withValues(alpha: pulse),
    );
  }
}

// ── The GRAPH STRIP (tiny) — a strip chart of currentLevel vs time. Centerline
//    zero, mono micro-eyebrow CURRENT, no axis numbers; flat on DC, square steps
//    on hand-flips, smooth wave on the machine. The 50 CYCLES / SEC mono label
//    fades in (top-right) only during alive. ≤0.10 of stage height. ────────────
class GraphStripLayer extends Component {
  GraphStripLayer(this.c);
  final AcdcController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    _reveal(canvas, c.stageSize, c.dockReveal, Offset(0, c.stageSize.height * 0.05),
        c.graphCenter, () => _draw(canvas));
  }

  void _draw(Canvas canvas) {
    final w = c.stageSize.width;
    final ctr = c.graphCenter;
    final gw = c.graphW, gh = c.graphH;
    final rect = Rect.fromCenter(center: ctr, width: gw, height: gh);
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(w * 0.02));

    // Dark glass panel + a soft drop shadow + a top inner catch-light band so the
    // little scope reads as premium dark glass (cohesive with the dock chrome).
    canvas.drawRRect(rr.shift(Offset(0, gh * 0.05)), _glow(Colors.black, w * 0.016, alpha: 0.24));
    canvas.drawRRect(rr, Paint()..color = _c(AcdcTune.graphGlass).withValues(alpha: 0.82));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.42),
        Radius.circular(w * 0.02),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.04),
    );
    canvas.drawRRect(rr, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = _c(0x26FFFFFF));

    canvas.save();
    canvas.clipRRect(rr);

    final plotLeft = rect.left + gw * 0.06;
    final plotRight = rect.right - gw * 0.02;
    final plotW = plotRight - plotLeft;
    // The plot sits BELOW the CURRENT label so a steady DC line (+1) never rides up
    // into it; the zero centerline is the plot's centre, with ±1 fitting the area.
    final plotTop = rect.top + gh * 0.34;
    final plotBottom = rect.bottom - gh * 0.10;
    final midY = (plotTop + plotBottom) / 2;
    final amp = (plotBottom - plotTop) / 2 * 0.86; // ±1 maps to ±amp

    // Centerline zero (dim) — a single faint baseline, no gridlines, no numbers.
    canvas.drawLine(Offset(plotLeft, midY), Offset(plotRight, midY),
        Paint()..color = _c(0xFF6FA8FF).withValues(alpha: 0.18)..strokeWidth = 1.0);

    // The trace — flat (DC) → hand-made square steps (the flips) → smooth wave (AC).
    final samples = c.graphSamplesOrdered();
    final n = samples.length;
    final path = Path();
    for (var i = 0; i < n; i++) {
      final x = plotLeft + plotW * (i / (n - 1));
      final y = midY - samples[i].clamp(-1.0, 1.0) * amp;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    // A wide soft under-glow, a mid glow, then the crisp glowing trace.
    canvas.drawPath(path, _glow(_blue, w * 0.012, alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.009
      ..strokeJoin = StrokeJoin.round);
    canvas.drawPath(path, _glow(_blue, 2.0, alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.006
      ..strokeJoin = StrokeJoin.round);
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.004
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _blueLite.withValues(alpha: 0.98));

    // A bright head dot at the newest sample (the live cursor of the scope).
    if (n > 0) {
      final hx = plotRight;
      final hy = midY - samples[n - 1].clamp(-1.0, 1.0) * amp;
      canvas.drawCircle(Offset(hx, hy), w * 0.008, _glow(_blue, w * 0.01, alpha: 0.7));
      canvas.drawCircle(Offset(hx, hy), w * 0.0035, Paint()..color = _blueLite);
    }

    canvas.restore();

    // Mono micro-eyebrow CURRENT (left).
    final eb = TextPainter(
      text: TextSpan(
        text: AcdcCopy.graphEyebrow,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: gh * 0.15,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
          color: _blue.withValues(alpha: 0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    eb.paint(canvas, Offset(rect.left + gw * 0.03, rect.top + gh * 0.09));

    // The 50 CYCLES / SEC mono label (top-right) — alive onward only.
    if (c.labelReveal > 0.01) {
      final lab = TextPainter(
        text: TextSpan(
          text: AcdcCopy.graphHzLabel,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: gh * 0.15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: _amberHot.withValues(alpha: 0.92 * c.labelReveal),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      lab.paint(canvas, Offset(rect.right - lab.width - gw * 0.03, rect.top + gh * 0.09));
    }
  }
}

// ── The flash — a brief additive bloom at the core (the spring-to-life) or a
//    soft dead-underline. The pedagogical instant (the cutoff) lives in the bulb
//    + output gate, NOT here; this only adds the orchestrated moment. ───────────
class FlashLayer extends Component {
  FlashLayer(this.c);
  final AcdcController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    final f = c.flashIntensity;
    if (f <= 0.01) return;
    final at = c.coreCenter;
    final unit = c.coreOuterW;
    // A soft expanding bloom — bright at the spring-to-life, fainter at the dead
    // underline (the dead underline uses a low flash peak; ported from 2.6's
    // two-part flash for the alive burst).
    final bloomR = unit * (0.35 + (1 - f) * 0.9);
    canvas.drawCircle(
      at,
      bloomR,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(colors: [
          _amberHot.withValues(alpha: 0.42 * f),
          _amberHot.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: at, radius: bloomR)),
    );
    // A crisp expanding ring (the "it kicked / sprang alive" beat).
    final ringR = unit * (0.4 + (1 - f) * 0.95);
    canvas.drawCircle(
      at,
      ringR,
      Paint()
        ..blendMode = BlendMode.plus
        ..style = PaintingStyle.stroke
        ..strokeWidth = c.stageSize.width * 0.012 * f
        ..color = _amberHot.withValues(alpha: 0.78 * f)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + 8 * f),
    );
  }
}

class _Mote {
  _Mote(this.x, this.y, this.speed, this.r) : phase = x * 6.28, alpha = 0.5 + r;
  double x, y;
  final double speed;
  final double r;
  final double phase;
  final double alpha;
}
