// The journey band (PRD §16) — a DIAGONAL span: the plant LOWER-LEFT, the town feed
// UPPER-RIGHT (continuity with 2.3/2.4's diagonal hot spans), the hot cable climbing
// across the whole band with a catenary sag. The plant is small, dim, and STATIC (it
// never changes — it always sends full power).
//
// THE HERO WIRE'S DRAIN (P0.2 + P0.3): the wire is the ENEMY. At low voltage it is a
// FIERCE ember-hot VOLUMINOUS cable — a cool cylindrical body filled with an ember
// core (#FF7A2E → #FFF1D8 white-hot), wrapped in layered additive bloom + a rising
// heat-haze shimmer band + heat motes, ALL ∝ wireHeat = I² (the SQUARE law, 2.4's
// payoff). As the learner raises the voltage the current falls, the heat DRAINS away
// SAME-FRAME: the ember core thins, the bloom collapses, the haze and motes stop, and
// the cable cools to a thin bare conductor. At max voltage: zero glow / zero haze /
// zero motes, a hairline current — but the town stays full (current ≠ power).
//
// Craft cohesion: this is the 2.3/2.4 hot-wire treatment (voluminous cable + ember
// core + bloom + heat-haze + dimensional lattice towers) ported into the Flame layer,
// reading the controller's diagonal `wirePoint(t)` catenary sampler.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart' show Component;
import 'package:flutter/material.dart';

import '../../config/transmission_tuning.dart';
import '../../state/transmission_controller.dart';

class JourneyLayer extends Component {
  JourneyLayer(this.c);
  final TransmissionController c;

  // Global key light direction (upper-left) for the steel members' chamfer rim.
  static const Offset _lightUL = Offset(-0.7071, -0.7071);

  final math.Random _rng = math.Random(7);
  final List<_HeatMote> _motes = [];

  @override
  void update(double dt) {
    if (c.stageSize.isEmpty) return;
    if (_motes.isEmpty) {
      for (var i = 0; i < TTTune.moteCap; i++) {
        _motes.add(_HeatMote(_rng.nextDouble(), _rng.nextDouble(),
            0.4 + _rng.nextDouble() * 0.9, _rng.nextDouble()));
      }
    }
    final spd = c.reducedMotion ? 0.2 : 1.0;
    for (final m in _motes) {
      m.t -= dt * 0.85 * m.speed * spd; // rise + fade over its lifetime
      if (m.t <= 0) {
        m.t = 1;
        m.along = _rng.nextDouble();
        m.seed = _rng.nextDouble();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    final heat = c.wireHeat; // 0..1, ∝ I²

    // The diagonal terrain the scene climbs — a subtle wedge below the ground line so
    // the stepped plant/tower/town read as standing on rising ground, not floating.
    _drawGround(canvas, math.max(c.plantReveal, c.wireReveal));

    final rev = c.wireReveal;
    if (rev > 0.001) {
      canvas.saveLayer(Offset.zero & c.stageSize,
          Paint()..color = Colors.white.withValues(alpha: rev));
      // The single dimensional lattice tower (recessive — chrome, not hero).
      _drawTower(canvas, c.pylon1);
      // Heat-haze shimmer band rising above the span (under the motes).
      if (heat > 0.02) _drawHeatHaze(canvas, heat);
      // The voluminous draining cable (HERO of this band).
      _drawWire(canvas, heat, rev);
      // Traveling current pulses (count/thickness ∝ current — current ≠ power).
      _drawPulses(canvas);
      // Rising heat motes hugging the span (∝ wireHeat).
      if (heat > 0.01) _drawHeatMotes(canvas, heat);
      canvas.restore();
    }

    // The plant — dimensional, dim, STATIC (drawn after so its terminal node sits on
    // top of the cable root). Its own reveal gate.
    _drawPlant(canvas);
  }

  // ── The diagonal terrain wedge — a subtle dark slope rising left→right under the
  // climbing elements, with a faint rim catch-light along the ground edge. Keeps the
  // dossier background reading through (low alpha); just enough to seat the staircase.
  void _drawGround(Canvas canvas, double rev) {
    if (rev <= 0.001) return;
    final w = c.stageSize.width, h = c.stageSize.height;
    final gl = c.groundY(0), gr = c.groundY(1);
    final path = Path()
      ..moveTo(0, gl)
      ..lineTo(w, gr)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, math.min(gl, gr)),
          Offset(0, h),
          [
            const Color(0xFF1A2240).withValues(alpha: 0.5 * rev),
            const Color(0xFF0A0E20).withValues(alpha: 0.0),
          ],
        ),
    );
    // faint rim catch-light along the ground edge.
    canvas.drawLine(
      Offset(0, gl),
      Offset(w, gr),
      Paint()
        ..color = TTTune.towerRim.withValues(alpha: 0.22 * rev)
        ..strokeWidth = 1.2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6),
    );
  }

  // ── The diagonal catenary cable path (sampled from the controller) ─────
  Path _wirePath({double dy = 0}) {
    final start = c.wirePoint(0);
    final p = Path()..moveTo(start.dx, start.dy + dy);
    const n = 44;
    for (var k = 1; k <= n; k++) {
      final pt = c.wirePoint(k / n);
      p.lineTo(pt.dx, pt.dy + dy);
    }
    return p;
  }

  // ── The wire (hero of the band) — voluminous conductor + draining ember ──
  void _drawWire(Canvas canvas, double heat, double rev) {
    final h = c.stageSize.height;
    final w = c.stageSize.width;
    final path = _wirePath();
    final baseStroke = c.wireStroke;

    // Soft contact under-shadow so the thick cable reads seated, not floating.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = baseStroke * 1.15
        ..strokeCap = StrokeCap.round
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.006),
    );

    // ── Cool cylindrical BODY (always present — the bare conductor). Three stacked
    // strokes (dark edge → body → cool specular spine) so the thick cable reads as a
    // lit cylinder, not a flat line. At max voltage this is ALL that remains.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = baseStroke
        ..strokeCap = StrokeCap.round
        ..color = TTTune.wireCoolDeep,
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = baseStroke * 0.74
        ..strokeCap = StrokeCap.round
        ..color = TTTune.wireCool,
    );
    canvas.drawPath(
      _wirePath(dy: -baseStroke * 0.16),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = baseStroke * TTTune.cableHighlightFrac * 1.6
        ..strokeCap = StrokeCap.round
        ..color = TTTune.wireSpecular.withValues(alpha: 0.32 - 0.20 * heat)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, baseStroke * 0.18),
    );

    // ── EMBER FILL + layered additive bloom, ALL ∝ wireHeat (∝ I²). The cable fills
    // from within: a wide soft outer bloom, a mid ember band, then a hot core spine
    // that goes white-hot at full heat. As voltage rises, heat → 0 and ALL of this
    // collapses SAME-FRAME, draining the cable to the cool body above.
    if (heat > 0.01) {
      final glowWidth = baseStroke * (1.0 + TTTune.glowWidenMax * heat);

      // outer soft bloom (the cable pouring light into the dark).
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = glowWidth * 2.6
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.012 + h * 0.022 * heat)
          ..color = TTTune.emberCore.withValues(alpha: 0.10 + 0.30 * heat),
      );
      // mid ember band — the heat filling the conductor body.
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = baseStroke * (0.92 + 0.5 * heat)
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.003 + h * 0.005 * heat)
          ..shader = LinearGradient(
            colors: [
              TTTune.heatFierce.withValues(alpha: 0.50 + 0.35 * heat),
              TTTune.energyWarm.withValues(alpha: 0.42 + 0.40 * heat),
            ],
          ).createShader(Offset.zero & Size(w, h)),
      );
      // hot ember core spine — orange → white-hot at full heat.
      final whiteHot = ((heat - 0.45) / 0.55).clamp(0.0, 1.0);
      final coreCol = Color.lerp(TTTune.emberCore, TTTune.emberHot, 0.4 + 0.6 * whiteHot)!;
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = baseStroke * (0.40 + 0.30 * heat)
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.plus
          ..color = coreCol.withValues(alpha: 0.30 + 0.55 * heat),
      );

      // Cooling-ember speckle — as the wire cools (heat present but low) the core
      // breaks into a cooling speckle so the glow fades as embers, never snapping to
      // black. Density/brightness ride heat; seeded stably so it doesn't flicker.
      _drawEmberSpeckle(canvas, heat, coreCol, baseStroke);
    }
  }

  void _drawEmberSpeckle(Canvas canvas, double heat, Color coreCol, double baseStroke) {
    final coolBand = (1.0 - (heat - 0.55).clamp(0.0, 0.45) / 0.45) * heat;
    if (coolBand <= 0.02) return;
    final n = (8 + 14 * coolBand).round();
    final paint = Paint()..blendMode = BlendMode.plus;
    final rng = math.Random(91);
    for (var i = 0; i < n; i++) {
      final t = 0.06 + 0.88 * rng.nextDouble();
      final p = c.wirePoint(t);
      final jitter = Offset(
        (rng.nextDouble() - 0.5) * baseStroke * 0.5,
        (rng.nextDouble() - 0.5) * baseStroke * 0.5,
      );
      final flick = 0.55 + 0.45 * rng.nextDouble();
      canvas.drawCircle(
        p + jitter,
        baseStroke * (0.16 + 0.18 * rng.nextDouble()),
        paint..color = coreCol.withValues(alpha: 0.5 * coolBand * flick),
      );
    }
  }

  // ── Heat-haze shimmer band (rising refraction approximation; ∝ wireHeat) ──
  void _drawHeatHaze(Canvas canvas, double heat) {
    final h = c.stageSize.height;
    final w = c.stageSize.width;
    final t = heat.clamp(0.0, 1.0);
    final scroll = c.reducedMotion ? 0.0 : c.hazePhase;
    final waveLen = TTTune.hazeWaveLenF * w;
    final amp = TTTune.hazeWaveAmpF * h;
    final rise = TTTune.hazeRiseF * h;
    const steps = 28;
    for (var b = 0; b < TTTune.hazeBands; b++) {
      final bf = (b + 1) / TTTune.hazeBands; // how high this band floats
      final bandAlpha = TTTune.hazeBaseAlpha * t * (1.0 - 0.55 * bf);
      if (bandAlpha <= 0.004) continue;
      final path = Path();
      for (var i = 0; i <= steps; i++) {
        final st = i / steps;
        final base = c.wirePoint(0.06 + 0.88 * st);
        final phase = (base.dx / waveLen) - scroll + bf * 1.7;
        final dx = math.sin(phase * math.pi * 2) * amp * (0.6 + 0.8 * bf);
        final dy = -rise * bf - amp * 0.4 * math.cos(phase * math.pi * 2);
        final p = Offset(base.dx + dx, base.dy + dy);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      final col = Color.lerp(TTTune.emberCore, TTTune.energyWarm, 0.35 + 0.5 * bf)!;
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * (0.018 + 0.02 * bf)
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * (0.012 + 0.016 * bf))
          ..color = col.withValues(alpha: bandAlpha),
      );
    }
  }

  // ── Premium steel lattice tower (ported from 2.3 hot wire) ─────────────
  // Each member is a CYLINDRICAL steel bar (dark edge → bright spine → dark edge)
  // with an upper-left chamfer rim; bolted joints with AO; a ground-contact shadow;
  // and a ceramic insulator string at the apex where the wire clamps. Kept dim/
  // recessive so the HOT WIRE always stays the hero. Alpha handled by the caller's
  // saveLayer (the wire-reveal envelope), so members draw at full strength here.
  void _drawTower(Canvas canvas, Offset top) {
    final h = c.stageSize.height;
    final footY = c.groundY(top.dx / c.stageSize.width); // foot on the diagonal ground
    final towerH = footY - top.dy;
    if (towerH <= 1) return;
    const a = 1.0;

    final headHalf = TTTune.towerHeadHalfF * h;
    final baseHalf = TTTune.towerBaseHalfF * h;
    final legW = TTTune.towerLegWF * h;
    final braceW = TTTune.towerBraceWF * h;

    final headL = Offset(top.dx - headHalf, top.dy);
    final headR = Offset(top.dx + headHalf, top.dy);
    final footL = Offset(top.dx - baseHalf, footY);
    final footR = Offset(top.dx + baseHalf, footY);

    // 1) ground-contact shadow — a wide flat blurred ellipse so the feet sit on a floor.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(top.dx + h * 0.004, footY + h * 0.006),
        width: baseHalf * 3.0,
        height: baseHalf * 0.7,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.30 * a)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.013),
    );

    // 2) one blurred silhouette of the leg outline, offset down-right → cheap lift/depth.
    final sil = Path()
      ..moveTo(headL.dx, headL.dy)
      ..lineTo(headR.dx, headR.dy)
      ..lineTo(footR.dx, footR.dy)
      ..lineTo(footL.dx, footL.dy)
      ..close();
    canvas.drawPath(
      sil.shift(Offset(h * 0.004, h * 0.006)),
      Paint()
        ..color = TTTune.towerBolt.withValues(alpha: 0.28 * a)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.006),
    );

    // 3) lattice cross-braces (drawn first; legs overlap their ends at the joints).
    final rungs = TTTune.towerRungs;
    Offset onLeg(Offset head, Offset foot, double f) =>
        Offset(head.dx + (foot.dx - head.dx) * f, head.dy + (foot.dy - head.dy) * f);
    for (var i = 0; i <= rungs; i++) {
      final f = i / rungs;
      final pl = onLeg(headL, footL, f);
      final pr = onLeg(headR, footR, f);
      _steelBrace(canvas, pl, pr, braceW, a); // horizontal rung
      if (i < rungs) {
        final pl2 = onLeg(headL, footL, (i + 1) / rungs);
        final pr2 = onLeg(headR, footR, (i + 1) / rungs);
        _steelBrace(canvas, pl, pr2, braceW, a); // X diagonals
        _steelBrace(canvas, pr, pl2, braceW, a);
      }
    }

    // 4) the two main legs as cylindrical steel bars (dark → spine → dark gradient).
    _steelLeg(canvas, headL, footL, legW, a);
    _steelLeg(canvas, headR, footR, legW, a);

    // 5) bolted joints with a tiny up-left specular at each rung↔leg junction.
    for (var i = 0; i <= rungs; i++) {
      final f = i / rungs;
      _bolt(canvas, onLeg(headL, footL, f), legW * 0.6, a);
      _bolt(canvas, onLeg(headR, footR, f), legW * 0.6, a);
    }

    // 6) the ceramic insulator string the wire clamps onto, at the apex.
    _insulatorString(canvas, top, h, a);
  }

  // A cylindrical steel member: a cross-section gradient (dark edge → bright spine →
  // dark edge) perpendicular to the member axis, plus an upper-left chamfer rim.
  void _steelLeg(Canvas canvas, Offset a, Offset b, double width, double alpha) {
    final d = b - a;
    final len = d.distance;
    if (len < 1) return;
    final dir = Offset(d.dx / len, d.dy / len);
    final n = Offset(-dir.dy, dir.dx); // perpendicular (across the bar)
    final m = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    final half = width / 2;
    canvas.drawLine(
      a,
      b,
      Paint()
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(
          Offset(m.dx - n.dx * half, m.dy - n.dy * half),
          Offset(m.dx + n.dx * half, m.dy + n.dy * half),
          [
            TTTune.towerEdge.withValues(alpha: alpha),
            TTTune.towerSpine.withValues(alpha: alpha),
            TTTune.towerEdge.withValues(alpha: alpha),
          ],
          const [0.0, 0.5, 1.0],
        ),
    );
    // upper-left chamfer rim light (the catch-light on the bevel).
    final ro = width * 0.34;
    canvas.drawLine(
      a.translate(_lightUL.dx * ro, _lightUL.dy * ro),
      b.translate(_lightUL.dx * ro, _lightUL.dy * ro),
      Paint()
        ..strokeWidth = width * 0.30
        ..strokeCap = StrokeCap.round
        ..color = TTTune.towerRim.withValues(alpha: 0.55 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5),
    );
  }

  // A thin brace: solid body + a faint upper-left rim (cheaper than the full leg).
  void _steelBrace(Canvas canvas, Offset a, Offset b, double width, double alpha) {
    canvas.drawLine(
      a,
      b,
      Paint()
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..color = TTTune.towerBody.withValues(alpha: 0.92 * alpha),
    );
    final ro = width * 0.40;
    canvas.drawLine(
      a.translate(_lightUL.dx * ro, _lightUL.dy * ro),
      b.translate(_lightUL.dx * ro, _lightUL.dy * ro),
      Paint()
        ..strokeWidth = width * 0.42
        ..strokeCap = StrokeCap.round
        ..color = TTTune.towerRim.withValues(alpha: 0.38 * alpha),
    );
  }

  // A machined bolt head: a dark recessed dot + a tiny up-left specular speck.
  void _bolt(Canvas canvas, Offset at, double r, double alpha) {
    canvas.drawCircle(at, r, Paint()..color = TTTune.towerBolt.withValues(alpha: 0.85 * alpha));
    canvas.drawCircle(
      at.translate(_lightUL.dx * r * 0.5, _lightUL.dy * r * 0.5),
      r * 0.45,
      Paint()..color = Colors.white.withValues(alpha: 0.30 * alpha),
    );
  }

  // The suspension insulator string the wire clamps onto at the apex: a dark clamp
  // + a short stack of dome-shaded ceramic bells.
  void _insulatorString(Canvas canvas, Offset anchor, double h, double alpha) {
    final r = TTTune.insulatorDiscRF * h;
    canvas.drawCircle(anchor, r * 0.55, Paint()..color = TTTune.towerBolt.withValues(alpha: 0.9 * alpha));
    for (var i = 0; i < TTTune.insulatorDiscs; i++) {
      final cc = Offset(anchor.dx, anchor.dy + r * 1.15 * (i + 0.7));
      final rect = Rect.fromCenter(center: cc, width: r * 2.0, height: r * 1.3);
      canvas.drawOval(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(cc.dx + _lightUL.dx * r * 0.5, cc.dy + _lightUL.dy * r * 0.4),
            r * 1.5,
            [
              TTTune.insulatorCeramic.withValues(alpha: 0.95 * alpha),
              TTTune.towerEdge.withValues(alpha: 0.92 * alpha),
            ],
          ),
      );
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = TTTune.towerRim.withValues(alpha: 0.5 * alpha),
      );
    }
  }

  // ── Traveling current pulses — count + thickness ∝ current (current ≠ power) ──
  void _drawPulses(Canvas canvas) {
    final count = c.pulseCount;
    if (count <= 0) return;
    final h = c.stageSize.height;
    final current = c.current;
    final tNorm = TTTune.currentNorm(current); // 0 at hairline, 1 at full current
    final thick = h * (0.0035 + 0.007 * tNorm);
    for (var i = 0; i < count; i++) {
      final frac = 0.05 + 0.90 * (((i / count) + c.pulsePhase) % 1.0);
      final pos = c.wirePoint(frac);
      canvas.drawCircle(
        pos,
        thick * 2.2,
        Paint()
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, thick * 2.0)
          ..color = TTTune.energyWarm.withValues(alpha: 0.42 * (0.5 + 0.5 * tNorm)),
      );
      canvas.drawCircle(
        pos,
        thick,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = TTTune.energyWarm.withValues(alpha: 0.85),
      );
    }
  }

  // ── Rising heat motes hugging the span — count/alpha ∝ wireHeat (∝ I²) ──
  void _drawHeatMotes(Canvas canvas, double heat) {
    final h = c.stageSize.height;
    final w = c.stageSize.width;
    final shown = (_motes.length * heat).round();
    for (var i = 0; i < shown && i < _motes.length; i++) {
      final m = _motes[i];
      final anchor = c.wirePoint(0.06 + 0.88 * m.along);
      final rise = (1 - m.t) * h * 0.11;
      final p = Offset(
        anchor.dx + math.sin(m.seed * 6.28 + c.hazePhase * 6.28) * w * 0.009,
        anchor.dy - rise,
      );
      final a = (m.t * 0.5 * heat).clamp(0.0, 0.5);
      final col = Color.lerp(TTTune.energyWarm, TTTune.emberCore, m.t)!;
      canvas.drawCircle(
        p,
        w * 0.008 * m.speed * (0.6 + 0.7 * m.t),
        Paint()
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.012)
          ..color = col.withValues(alpha: a),
      );
    }
  }

  // ── The plant — compact, DIMENSIONAL, dim, STATIC (it never changes) ──────
  // Lower-left of the band. It always sends full power, so it never brightens; it
  // must not compete with the gold rectangle as the brightest steady element.
  void _drawPlant(Canvas canvas) {
    final rev = c.plantReveal;
    if (rev <= 0.001) return;
    final w = c.stageSize.width;
    final h = c.stageSize.height;
    final pw = c.plantWidth;
    final base = c.plantBase;
    final footY = base.dy; // the powerhouse sits at its own (lowest) point on the ground
    final bodyTop = footY - h * 0.085;
    final body = Rect.fromLTRB(base.dx - pw / 2, bodyTop, base.dx + pw / 2, footY);

    canvas.saveLayer(Offset.zero & c.stageSize,
        Paint()..color = Colors.white.withValues(alpha: rev));

    // Ground-contact shadow so the powerhouse sits on the ground (the lowest step of
    // the diagonal) rather than floating.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(base.dx, footY + h * 0.005),
        width: pw * 1.5,
        height: pw * 0.34,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.32)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.012),
    );

    // Low building block — a dimensional slab: vertical body gradient + lit left edge.
    final rr = RRect.fromRectAndRadius(body, Radius.circular(w * 0.01));
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [TTTune.plantEdge, TTTune.plantBody],
        ).createShader(body),
    );
    // Lit left edge (a thin specular so the block reads dimensional).
    canvas.drawLine(
      Offset(body.left + 0.5, bodyTop + w * 0.006),
      Offset(body.left + 0.5, footY - w * 0.006),
      Paint()
        ..color = TTTune.plantLite.withValues(alpha: 0.7)
        ..strokeWidth = 1.4,
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = TTTune.plantEdge,
    );
    // Two cooling stacks (dim — never bright).
    for (final sx in [base.dx - pw * 0.24, base.dx + pw * 0.14]) {
      final stack = Rect.fromLTWH(sx, bodyTop - h * 0.052, pw * 0.13, h * 0.058);
      canvas.drawRRect(
        RRect.fromRectAndRadius(stack, Radius.circular(w * 0.006)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [TTTune.plantLite, TTTune.plantEdge],
          ).createShader(stack),
      );
    }
    // A couple of dim service windows (static — the plant is alive but never changes).
    final wp = Paint()..color = const Color(0xFF3A4470).withValues(alpha: 0.85);
    for (var r = 0; r < 2; r++) {
      for (var col = 0; col < 3; col++) {
        final wx = body.left + pw * (0.16 + col * 0.27);
        final wy = bodyTop + h * (0.022 + r * 0.034);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(wx, wy, pw * 0.13, h * 0.018), const Radius.circular(1.5)),
          wp,
        );
      }
    }
    // The terminal where the wire leaves — a small steady warm node (the source),
    // capped low so it never rivals the rectangle.
    canvas.drawCircle(
      c.wireStart,
      w * 0.009,
      Paint()
        ..blendMode = BlendMode.plus
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.016)
        ..color = TTTune.energyWarm.withValues(alpha: 0.4),
    );
    canvas.drawCircle(c.wireStart, w * 0.005, Paint()..color = TTTune.energyWarm.withValues(alpha: 0.7));
    canvas.restore();
  }
}

class _HeatMote {
  _HeatMote(this.along, this.t, this.speed, this.seed);
  double along; // 0..1 along the span
  double t; // 1 → 0 lifetime (rises + fades)
  final double speed;
  double seed;
}
