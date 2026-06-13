// The hero renderer for Squared Loss — pure CustomPainter (PRD §16), 10x rebuild.
// One precision surface, drawn back→front. The HERO is the hot wire: a VOLUMINOUS
// dimensional conductor (cool cylindrical body) that, as wireGlow rises with the
// SQUARE, fills with an EMBER CORE (#FF7A2E → #FFF1D8 white-hot) wrapped in layered
// additive bloom + a rising HEAT-HAZE SHIMMER band — the disproportion (×2 → 4×
// glow VOLUME) is FELT, not just numbered. The wire's DRAWN GEOMETRY is identical
// across every beat (the held-constant) — only its glow widens/brightens.
//
// Craft cohesion with 2.3 (current_heats_wire/stage_painter): cylindrical conductor
// shading, additive BlendMode.plus bloom, the diagonal catenary span, dimensional
// lattice towers, heat-haze shimmer bands, cooling-ember speckle. The chips are
// instrument gauges matching 2.1–2.3, drawn IN-painter so they sit INSIDE the
// RepaintBoundary snapshot (PRD §9).

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../config/squared_loss_copy.dart';
import '../config/squared_loss_tuning.dart';
import '../state/heat_particles.dart';
import '../state/squared_loss_controller.dart';

class WireStagePainter extends CustomPainter {
  WireStagePainter(this.c) : super(repaint: c);
  final SquaredLossController c;

  @override
  void paint(Canvas canvas, Size size) {
    c.setStageSize(size);
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;
    final reveal = c.revealT;
    // The felt glow + the punctuation leap pulse (added on top, fading fast).
    final glow = c.wireGlow;
    final leap = c.leapPulse;
    final litGlow = (glow + 0.35 * leap).clamp(0.0, 1.0);

    // -1) graded environment — a ground band + faint cool distant glows so the
    //     diagonal has a place to stand (all cool/dim; warm stays the wire's alone).
    _paintEnvironment(canvas, size, reveal);

    // 0) midspan vignette anchor — deepen the dark right behind the hero diagonal.
    final mid = c.wirePoint(0.5);
    canvas.drawCircle(
      mid,
      h * 0.46,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFF05070F).withValues(alpha: 0.55 * reveal), const Color(0x00000000)],
          stops: const [0, 1],
        ).createShader(Rect.fromCircle(center: mid, radius: h * 0.46)),
    );

    // 1) dimensional transmission towers (recessive/cool, rising on entrance).
    _paintTower(canvas, c.leftAnchor, h, reveal);
    _paintTower(canvas, c.rightAnchor, h, reveal);

    // 2) heat-haze shimmer band rising above the whole span (under the embers so it
    //    reads as a refraction layer behind the rising specks). Scales with heat.
    if (litGlow > 0.02) _paintHeatHaze(canvas, size, litGlow);

    // 3) the wire (HERO) — fixed catenary geometry, voluminous body + ember glow.
    _paintWire(canvas, size, litGlow, reveal, c.flashIntensity);

    // 4) embers (additive) + cool motes — the felt density tracks the square.
    _paintEmbers(canvas, c.embers);
    _paintMotes(canvas, c.motes);

    // 5) the static held-constant tag (rides midspan).
    _paintTag(canvas, w, h, reveal);

    // 6) the readout gauges (in-painter, inside the snapshot).
    _paintGauges(canvas, w, h, reveal);

    // 7) discovery flash — a warm wash + a bright ring along the span.
    _paintFlash(canvas, size, c.flashIntensity);
  }

  // ── Catenary sampling (diagonal span + parabolic sag) ──────────────────
  Path _wirePath({double dy = 0}) {
    final start = c.wirePoint(0);
    final p = Path()..moveTo(start.dx, start.dy + dy);
    const n = 48;
    for (var k = 1; k <= n; k++) {
      final pt = c.wirePoint(k / n);
      p.lineTo(pt.dx, pt.dy + dy);
    }
    return p;
  }

  // Global key light — UPPER-LEFT (unifies every separately-drawn steel member into
  // one believable lit object; ported from 2.3 / hand_crank_lamp).
  static const Offset _lightUL = Offset(-0.7071, -0.7071);

  // ── Premium steel lattice tower (hand_crank_lamp / 2.3 metal craft) ────────
  // Each member is a CYLINDRICAL steel bar (dark edge → bright spine → dark edge)
  // with an upper-left chamfer rim; joints are bolted with AO; the post casts a
  // ground shadow + lifts off a blurred silhouette; the wire clamps onto a real
  // ceramic insulator string. Kept dim/recessive so the hot wire stays the hero.
  void _paintTower(Canvas canvas, Offset top, double h, double rev) {
    if (rev <= 0.01) return;
    final footY = SLTune.pylonBaseY * h;
    final riseDy = (1 - rev) * h * 0.06; // rises up from its foot on entrance
    final t = top.translate(0, riseDy);
    final a = rev.clamp(0.0, 1.0);
    final towerH = footY - t.dy;
    if (towerH <= 1) return;

    final headHalf = h * SLTune.towerHeadHalfF;
    final baseHalf = h * SLTune.towerBaseHalfF;
    final legW = h * SLTune.towerLegWF;
    final braceW = h * SLTune.towerBraceWF;

    final headL = Offset(t.dx - headHalf, t.dy);
    final headR = Offset(t.dx + headHalf, t.dy);
    final footL = Offset(t.dx - baseHalf, footY);
    final footR = Offset(t.dx + baseHalf, footY);

    // 1) ground-contact shadow — a wide flat blurred ellipse under the feet.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(t.dx + h * 0.004, footY + h * 0.006),
        width: baseHalf * 3.0,
        height: baseHalf * 0.7,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.30 * a)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.013),
    );
    // 2) one blurred silhouette of the leg outline, offset down-right → lift/depth.
    final sil = Path()
      ..moveTo(headL.dx, headL.dy)
      ..lineTo(headR.dx, headR.dy)
      ..lineTo(footR.dx, footR.dy)
      ..lineTo(footL.dx, footL.dy)
      ..close();
    canvas.drawPath(
      sil.shift(Offset(h * 0.004, h * 0.006)),
      Paint()
        ..color = SLTune.towerBolt.withValues(alpha: 0.28 * a)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.006),
    );
    // 3) cross-braces (first; the legs overlap their ends at the joints).
    final rungs = SLTune.towerRungs;
    Offset onLeg(Offset head, Offset foot, double f) =>
        Offset(head.dx + (foot.dx - head.dx) * f, head.dy + (foot.dy - head.dy) * f);
    for (var i = 0; i <= rungs; i++) {
      final f = i / rungs;
      final pl = onLeg(headL, footL, f);
      final pr = onLeg(headR, footR, f);
      _steelBrace(canvas, pl, pr, braceW, a);
      if (i < rungs) {
        final pl2 = onLeg(headL, footL, (i + 1) / rungs);
        final pr2 = onLeg(headR, footR, (i + 1) / rungs);
        _steelBrace(canvas, pl, pr2, braceW, a);
        _steelBrace(canvas, pr, pl2, braceW, a);
      }
    }
    // 4) the two main legs as cylindrical steel bars.
    _steelLeg(canvas, headL, footL, legW, a);
    _steelLeg(canvas, headR, footR, legW, a);
    // 5) bolted joints with an up-left specular at each rung↔leg junction.
    for (var i = 0; i <= rungs; i++) {
      final f = i / rungs;
      _bolt(canvas, onLeg(headL, footL, f), legW * 0.6, a);
      _bolt(canvas, onLeg(headR, footR, f), legW * 0.6, a);
    }
    // 6) the ceramic insulator string the wire clamps onto, at the apex.
    _insulatorString(canvas, t, h, a);
  }

  // A cylindrical steel member: a cross-section gradient (dark edge → bright spine →
  // dark edge) perpendicular to the axis, plus an upper-left chamfer rim.
  void _steelLeg(Canvas canvas, Offset a, Offset b, double width, double alpha) {
    final d = b - a;
    final len = d.distance;
    if (len < 1) return;
    final dir = Offset(d.dx / len, d.dy / len);
    final n = Offset(-dir.dy, dir.dx);
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
            SLTune.towerEdge.withValues(alpha: alpha),
            SLTune.towerSpine.withValues(alpha: alpha),
            SLTune.towerEdge.withValues(alpha: alpha),
          ],
          const [0.0, 0.5, 1.0],
        ),
    );
    final ro = width * 0.34;
    canvas.drawLine(
      a.translate(_lightUL.dx * ro, _lightUL.dy * ro),
      b.translate(_lightUL.dx * ro, _lightUL.dy * ro),
      Paint()
        ..strokeWidth = width * 0.30
        ..strokeCap = StrokeCap.round
        ..color = SLTune.towerRim.withValues(alpha: 0.55 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5),
    );
  }

  // A thin brace: solid body + a faint upper-left rim.
  void _steelBrace(Canvas canvas, Offset a, Offset b, double width, double alpha) {
    canvas.drawLine(
      a,
      b,
      Paint()
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..color = SLTune.towerBody.withValues(alpha: 0.92 * alpha),
    );
    final ro = width * 0.40;
    canvas.drawLine(
      a.translate(_lightUL.dx * ro, _lightUL.dy * ro),
      b.translate(_lightUL.dx * ro, _lightUL.dy * ro),
      Paint()
        ..strokeWidth = width * 0.42
        ..strokeCap = StrokeCap.round
        ..color = SLTune.towerRim.withValues(alpha: 0.38 * alpha),
    );
  }

  // A machined bolt head: a dark recessed dot + a tiny up-left specular speck.
  void _bolt(Canvas canvas, Offset at, double r, double alpha) {
    canvas.drawCircle(at, r, Paint()..color = SLTune.towerBolt.withValues(alpha: 0.85 * alpha));
    canvas.drawCircle(
      at.translate(_lightUL.dx * r * 0.5, _lightUL.dy * r * 0.5),
      r * 0.45,
      Paint()..color = Colors.white.withValues(alpha: 0.30 * alpha),
    );
  }

  // The suspension insulator string the wire clamps onto: a dark clamp + a short
  // stack of dome-shaded ceramic bells.
  void _insulatorString(Canvas canvas, Offset anchor, double h, double alpha) {
    final r = SLTune.insulatorDiscRF * h;
    canvas.drawCircle(anchor, r * 0.55, Paint()..color = SLTune.towerBolt.withValues(alpha: 0.9 * alpha));
    for (var i = 0; i < SLTune.insulatorDiscs; i++) {
      final ctr = Offset(anchor.dx, anchor.dy + r * 1.15 * (i + 0.7));
      final rect = Rect.fromCenter(center: ctr, width: r * 2.0, height: r * 1.3);
      canvas.drawOval(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(ctr.dx + _lightUL.dx * r * 0.5, ctr.dy + _lightUL.dy * r * 0.4),
            r * 1.5,
            [
              SLTune.insulatorCeramic.withValues(alpha: 0.95 * alpha),
              SLTune.towerEdge.withValues(alpha: 0.92 * alpha),
            ],
          ),
      );
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = SLTune.towerRim.withValues(alpha: 0.5 * alpha),
      );
    }
  }

  // ── The heat-haze shimmer band (rising refraction approximation, 2.3 port) ──
  void _paintHeatHaze(Canvas canvas, Size size, double glow) {
    final h = size.height;
    final t = glow.clamp(0.0, 1.0);
    final scroll = c.reducedMotion ? 0.0 : c.hazePhase;
    final waveLen = SLTune.hazeWaveLenF * size.width;
    final amp = SLTune.hazeWaveAmpF * h;
    final rise = SLTune.hazeRiseF * h;
    const steps = 30;
    for (var b = 0; b < SLTune.hazeBands; b++) {
      final bf = (b + 1) / SLTune.hazeBands; // how high this band floats
      final bandAlpha = SLTune.hazeBaseAlpha * t * (1.0 - 0.55 * bf);
      if (bandAlpha <= 0.004) continue;
      final path = Path();
      for (var i = 0; i <= steps; i++) {
        final st = i / steps;
        final base = c.wirePoint(0.06 + 0.88 * st);
        final phase = (base.dx / waveLen) - scroll + bf * 1.7;
        // a primary sine + a smaller second harmonic (domain warp) so the band reads
        // as turbulent air, not a clean ribbon.
        final dx = (math.sin(phase * math.pi * 2) +
                0.4 * math.sin(phase * math.pi * 4 + bf * 2.0)) *
            amp *
            (0.6 + 0.8 * bf);
        final dy = -rise * bf - amp * 0.4 * math.cos(phase * math.pi * 2);
        final p = Offset(base.dx + dx, base.dy + dy);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      final col = Color.lerp(SLTune.heat, SLTune.energy, 0.35 + 0.5 * bf)!;
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

  // ── The wire (hero) — voluminous dimensional conductor + ember core ────────
  void _paintWire(Canvas canvas, Size size, double glow, double rev, double flash) {
    final h = size.height;
    final path = _wirePath();
    final baseStroke = c.wireStroke;

    // soft contact under-shadow so the thick cable reads seated, not floating.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = baseStroke * 1.15
        ..strokeCap = StrokeCap.round
        ..color = Colors.black.withValues(alpha: 0.30 * rev)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.006),
    );

    // ── Cool cylindrical BODY (always present — the held-constant). Three stacked
    // strokes (dark edge → body → bright specular spine) so the thick cable reads
    // as a lit cylinder, not a flat line.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = baseStroke
        ..strokeCap = StrokeCap.round
        ..color = SLTune.wireCoolDeep.withValues(alpha: 0.95 * rev),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = baseStroke * 0.74
        ..strokeCap = StrokeCap.round
        ..color = SLTune.wireCool.withValues(alpha: 0.95 * rev),
    );
    canvas.drawPath(
      _wirePath(dy: -baseStroke * 0.16),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = baseStroke * SLTune.cableHighlightFrac * 1.6
        ..strokeCap = StrokeCap.round
        ..color = SLTune.wireSpecular.withValues(alpha: (0.32 - 0.18 * glow) * rev)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, baseStroke * 0.18),
    );

    if (glow > 0.01) {
      // ── EMBER FILL driven ALONG THE SPAN: hottest at the left/PLANT end, cooling
      // toward the right — the wire bleeds its energy out as heat (the loss). The
      // bloom WIDTH still grows with the SQUARE so the ×2 → 4× leap reads in glow
      // VOLUME, not just the number. A slow breath keeps it alive; at high glow a
      // white-hot blow-out core + an anamorphic streak read genuinely incandescent.
      final glowWidth = baseStroke * (1.0 + SLTune.glowWidenMax * glow);
      final plant = c.wirePoint(0), town = c.wirePoint(1);
      final keep = 1.0 - SLTune.lossTaper; // right-end fraction of plant brightness
      final breath =
          c.reducedMotion ? 1.0 : (1.0 + 0.06 * math.sin(c.hazePhase * 2 * math.pi * 1.3));

      // outer soft bloom (hot at the plant end → thinner toward the right).
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = glowWidth * 2.6
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.014 + h * 0.022 * glow)
          ..shader = ui.Gradient.linear(plant, town, [
            SLTune.heat.withValues(alpha: (0.10 + 0.34 * glow) * rev * breath),
            SLTune.heat.withValues(alpha: (0.10 + 0.34 * glow) * rev * keep),
          ]),
      );
      // mid ember band — the heat filling the body, tapering plant→right.
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = baseStroke * (0.92 + 0.5 * glow)
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.003 + h * 0.005 * glow)
          ..shader = ui.Gradient.linear(plant, town, [
            SLTune.heat.withValues(alpha: (0.55 + 0.35 * glow) * rev),
            SLTune.energy.withValues(alpha: (0.45 + 0.40 * glow) * rev * keep),
          ]),
      );
      // hot core spine — orange → white-hot, brightest at the plant end.
      final whiteHot = ((glow - 0.45) / 0.55).clamp(0.0, 1.0);
      final coreCol = Color.lerp(SLTune.heat, SLTune.heatCore, 0.4 + 0.6 * whiteHot)!;
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = baseStroke * (0.42 + 0.30 * glow)
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.plus
          ..shader = ui.Gradient.linear(plant, town, [
            coreCol.withValues(alpha: (0.30 + 0.55 * glow) * rev * breath),
            coreCol.withValues(alpha: (0.30 + 0.55 * glow) * rev * keep),
          ]),
      );
      // white-hot BLOW-OUT — a thin pure-white inner spine at high glow, hottest at
      // the plant end.
      if (whiteHot > 0.01) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = baseStroke * (0.16 + 0.14 * whiteHot)
            ..strokeCap = StrokeCap.round
            ..blendMode = BlendMode.plus
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6)
            ..shader = ui.Gradient.linear(plant, town, [
              Colors.white.withValues(alpha: 0.85 * whiteHot * rev * breath),
              Colors.white.withValues(alpha: 0.42 * whiteHot * rev * keep),
            ]),
        );
        // one soft anamorphic streak at the hottest stretch (near the plant).
        final hot = c.wirePoint(0.14);
        canvas.drawLine(
          Offset(hot.dx - glowWidth * 3.4, hot.dy),
          Offset(hot.dx + glowWidth * 3.4, hot.dy),
          Paint()
            ..strokeWidth = baseStroke * 0.5
            ..strokeCap = StrokeCap.round
            ..blendMode = BlendMode.plus
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.006)
            ..color = SLTune.heatCore.withValues(alpha: 0.5 * whiteHot * rev * breath),
        );
      }

      // cooling-ember speckle along the span (the glow breaking into embers).
      _paintEmberSpeckle(canvas, glow, rev, coreCol, baseStroke);
    }

    // discovery flash: a bright ring blooming along the whole span.
    if (flash > 0.01) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = baseStroke * (3 + 5 * flash)
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.03 * flash)
          ..color = SLTune.energy.withValues(alpha: 0.35 * flash),
      );
    }
  }

  // Cooling-ember speckle along the span — small bright cores reading as the glow
  // breaking up into embers. Density/brightness ride glow.
  void _paintEmberSpeckle(Canvas canvas, double glow, double rev, Color coreCol, double baseStroke) {
    final coolBand = (1.0 - (glow - 0.55).clamp(0.0, 0.45) / 0.45) * glow;
    if (coolBand <= 0.02) return;
    final n = (10 + 16 * coolBand).round();
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
        paint..color = coreCol.withValues(alpha: 0.5 * coolBand * flick * rev),
      );
    }
  }

  // ── Embers (additive) + cool motes ─────────────────────────────────────
  void _paintEmbers(Canvas canvas, List<HeatParticle> embers) {
    final paint = Paint()..blendMode = BlendMode.plus;
    for (final p in embers) {
      final a = p.alpha;
      paint.color = p.color.withValues(alpha: 0.5 * a);
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 1.2);
      canvas.drawCircle(p.pos, p.size * (1.0 + 1.4 * a), paint);
      paint.maskFilter = null;
      paint.color = SLTune.heatCore.withValues(alpha: 0.7 * a);
      canvas.drawCircle(p.pos, p.size * 0.55, paint);
    }
  }

  void _paintMotes(Canvas canvas, List<HeatParticle> motes) {
    final paint = Paint()..blendMode = BlendMode.plus;
    for (final p in motes) {
      // soft-blurred cool depth particles (atmosphere, not hard dust).
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, 0.8 + p.size * 0.9);
      paint.color = p.color.withValues(alpha: 0.10 * p.alpha);
      canvas.drawCircle(p.pos, p.size * 1.3, paint);
    }
  }

  // ── Graded environment (a ground band + faint cool distant glows) ──────────
  void _paintEnvironment(Canvas canvas, Size size, double reveal) {
    if (reveal <= 0.01) return;
    final w = size.width, h = size.height;
    final groundY = SLTune.pylonBaseY * h;
    final bandTop = groundY - h * 0.13;
    canvas.drawRect(
      Rect.fromLTWH(0, bandTop, w, h - bandTop),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, bandTop),
          Offset(0, h),
          [const Color(0x000E1430), const Color(0xFF0E1430).withValues(alpha: 0.55 * reveal)],
        ),
    );
    // distant glow behind the upper-right tower (cool, dim).
    canvas.drawCircle(
      Offset(SLTune.pylonRightX * w, SLTune.pylonRightTopY * h * 0.72),
      h * 0.22,
      Paint()
        ..blendMode = BlendMode.plus
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.06)
        ..color = const Color(0xFF2E5C8A).withValues(alpha: 0.10 * reveal),
    );
    // faint industrial glow behind the lower-left tower (cool — warm is the wire's alone).
    canvas.drawCircle(
      Offset(SLTune.pylonLeftX * w, groundY - h * 0.04),
      h * 0.15,
      Paint()
        ..blendMode = BlendMode.plus
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.05)
        ..color = const Color(0xFF2E466B).withValues(alpha: 0.08 * reveal),
    );
  }

  static const Color _tagInk = Color(0xFF9FB0D8);

  // ── The held-constant annotation — a scrim pill + padlock + leader to the wire ──
  void _paintTag(Canvas canvas, double w, double h, double reveal) {
    if (reveal <= 0.01) return;
    final a = reveal.clamp(0.0, 1.0);
    final center = Offset(SLTune.tagX * w, SLTune.tagY * h);
    final wireAt = c.wirePoint(0.5);
    final tp = TextPainter(
      text: TextSpan(
        text: SLCopy.wireTag,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 9,
          letterSpacing: 1.3,
          fontWeight: FontWeight.w700,
          color: _tagInk.withValues(alpha: 0.9 * a),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    const lockW = 8.0, padH = 9.0, padV = 4.5, gap = 5.0;
    final plateW = lockW + gap + tp.width + padH * 2;
    final plateH = tp.height + padV * 2;
    final pillTop = Offset(center.dx, center.dy - plateH / 2);
    // leader from the wire down to the pill (behind it).
    canvas.drawLine(
      wireAt,
      pillTop,
      Paint()
        ..strokeWidth = 1
        ..color = _tagInk.withValues(alpha: 0.30 * a),
    );
    canvas.drawCircle(wireAt, 1.6, Paint()..color = _tagInk.withValues(alpha: 0.5 * a));
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: plateW, height: plateH),
      const Radius.circular(6),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xFF0B1228).withValues(alpha: 0.80 * a));
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF34406A).withValues(alpha: 0.50 * a),
    );
    final lockC = Offset(center.dx - plateW / 2 + padH + lockW / 2, center.dy);
    _lockGlyph(canvas, lockC, lockW, a);
    tp.paint(canvas, Offset(lockC.dx + lockW / 2 + gap, center.dy - tp.height / 2));
  }

  // A minimalist padlock (body RRect + shackle arc).
  void _lockGlyph(Canvas canvas, Offset c, double s, double alpha) {
    final col = _tagInk.withValues(alpha: 0.85 * alpha);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + s * 0.16), width: s * 0.80, height: s * 0.56),
        Radius.circular(s * 0.12),
      ),
      Paint()..color = col,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(c.dx, c.dy - s * 0.10), width: s * 0.50, height: s * 0.50),
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.12
        ..strokeCap = StrokeCap.round
        ..color = col,
    );
  }

  // ── The readout gauges (instrument-style, matching 2.1–2.3) ────────────
  // Exactly TWO numbers: CURRENT (×N.N) + the EXCLUSIVE right gauge (HEAT xor LOST
  // VOLTS). Each gauge: dark glass body, mono label + rolling digits, a value-linked
  // glow, a thin accent needle/bar whose length rides the value, an ↑ trend glyph.
  void _paintGauges(Canvas canvas, double w, double h, double reveal) {
    if (reveal <= 0.01) return;
    final chipH = SLTune.chipHeightFactor * h;
    final isVolts = c.chip.value == SLChip.volts;

    // Left gauge — CURRENT (always present). Normalized 1..4 → 0..1.
    final curNorm = ((c.current - 1.0) / 3.0).clamp(0.0, 1.0);
    _drawGauge(
      canvas,
      center: Offset(SLTune.chipCurrentX * w, SLTune.chipY * h),
      chipH: chipH,
      label: SLCopy.chipCurrent,
      value: '×${c.current.toStringAsFixed(1)}',
      accent: SLTune.energy,
      reveal: reveal,
      norm: curNorm,
      trend: c.current > 1.001 ? 1 : 0,
    );

    // Right gauge — HEAT xor LOST VOLTS (exclusive swap). HEAT 100..1600,
    // LOST VOLTS 100..400. The HEAT gauge glow is keyed off the felt wireGlow so
    // its instrument glow leaps with the square too.
    final value = isVolts ? c.displayVolts : c.displayHeat;
    final norm = isVolts
        ? ((value - 100) / 300).clamp(0.0, 1.0) // volts 100..400
        : c.wireGlow; // heat gauge glow rides the SQUARE (felt)
    _drawGauge(
      canvas,
      center: Offset(SLTune.chipRightX * w, SLTune.chipY * h),
      chipH: chipH,
      label: isVolts ? SLCopy.chipVolts : SLCopy.chipHeat,
      value: value.round().toString(),
      accent: isVolts ? SLTune.gold : SLTune.heatFierce,
      reveal: reveal,
      norm: norm,
      trend: c.current > 1.001 ? 1 : 0,
    );
  }

  void _drawGauge(
    Canvas canvas, {
    required Offset center,
    required double chipH,
    required String label,
    required String value,
    required Color accent,
    required double reveal,
    required double norm,
    required int trend,
  }) {
    final width = chipH * 2.5;
    final rect = Rect.fromCenter(center: center, width: width, height: chipH);
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(chipH * 0.22));

    // value-linked glow halo (instrument-grade live read; recedes vs the hero wire).
    if (norm > 0.02) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(chipH * 0.16), Radius.circular(chipH * 0.34)),
        Paint()
          ..blendMode = BlendMode.plus
          ..color = accent.withValues(alpha: 0.16 * norm * reveal)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, chipH * 0.3),
      );
    }
    // dark glass body + accent border that warms with the value.
    canvas.drawRRect(rr, Paint()..color = const Color(0xFF0B1330).withValues(alpha: 0.85 * reveal));
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Color.lerp(
          Colors.white.withValues(alpha: 0.14),
          accent.withValues(alpha: 0.5),
          norm,
        )!
            .withValues(alpha: (0.42 + 0.3 * norm) * reveal),
    );

    final padX = chipH * 0.24;

    // label (top, mono small).
    final lp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: chipH * 0.18,
          letterSpacing: 1.3,
          fontWeight: FontWeight.w700,
          color: accent.withValues(alpha: 0.82 * reveal),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    lp.paint(canvas, Offset(rect.left + padX, rect.top + chipH * 0.13));

    // value (mono, the live rolling number) + optional ↑ trend glyph.
    final vp = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: chipH * 0.34,
          fontWeight: FontWeight.w800,
          color: Colors.white.withValues(alpha: reveal),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final valueY = rect.top + chipH * 0.13 + lp.height + chipH * 0.05;
    vp.paint(canvas, Offset(rect.left + padX, valueY));
    if (trend > 0) {
      final ap = TextPainter(
        text: TextSpan(
          text: '↑',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: chipH * 0.28,
            fontWeight: FontWeight.w800,
            color: accent.withValues(alpha: 0.9 * reveal),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      ap.paint(canvas, Offset(rect.right - ap.width - padX, valueY + chipH * 0.02));
    }

    // the instrument needle/bar under the value — length rides the value.
    final barW = width - padX * 2;
    final barY = rect.bottom - chipH * 0.16;
    final barL = rect.left + padX;
    final barH = chipH * 0.06;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barL, barY, barW, barH), Radius.circular(barH / 2)),
      Paint()..color = accent.withValues(alpha: 0.16 * reveal),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barL, barY, barW * norm, barH), Radius.circular(barH / 2)),
      Paint()
        ..blendMode = BlendMode.plus
        ..color = accent.withValues(alpha: 0.88 * reveal),
    );
  }

  // ── The discovery flash (a soft full-stage warm wash centred on midspan) ──
  void _paintFlash(Canvas canvas, Size size, double flash) {
    if (flash <= 0.01) return;
    final rect = Offset.zero & size;
    final mid = c.wirePoint(0.5);
    final shader = ui.Gradient.radial(
      mid,
      size.width * 0.8,
      [
        SLTune.heat.withValues(alpha: 0.22 * flash),
        SLTune.heat.withValues(alpha: 0.0),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = shader..blendMode = BlendMode.plus);
  }

  @override
  bool shouldRepaint(WireStagePainter old) => true;
}
