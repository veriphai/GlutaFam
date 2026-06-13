// The Hot Wire — the pure-render stage (PRD §16), 10x rebuild. One precision
// surface, drawn back→front. The HERO is the hot wire: a VOLUMINOUS dimensional
// conductor (cool cylindrical body, 2.2-style shading) that, as wireTemp rises,
// fills with an EMBER CORE (#FF7A2E → #FFF1D8 white-hot) wrapped in layered
// additive bloom + a rising HEAT-HAZE SHIMMER band — the energy LEAVING as heat is
// unmistakable. No lamp glyph: this is a TRANSMISSION span (PLANT → CITY tower), so
// nothing competes with the hot wire. The wire's DRAWN GEOMETRY is identical across
// every beat (the held-constant) — only its glow widens/brightens and its haze/
// motes scale with heat.
//
// Craft cohesion with 2.1 (vc_stage_painter) + 2.2 (resistance_stage_painter):
// cylindrical conductor shading (dark edge → body → specular band → edge), additive
// BlendMode.plus bloom, warm pulses with fading taper, rising motes pool.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../config/heat_wire_beats.dart';
import '../config/heat_wire_tuning.dart';
import '../state/heat_wire_controller.dart';
import '../state/heat_wire_particles.dart';

class StagePainter extends CustomPainter {
  StagePainter(this.c) : super(repaint: c);

  final HeatWireController c;

  static const Color _tagInk = Color(0xFF8FA8E0);

  @override
  void paint(Canvas canvas, Size size) {
    c.setStageSize(size);
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;

    final temp = c.wireTemp;

    // 0) graded environment — a ground the towers stand on + faint distant PLANT/CITY
    //    glows, so the diagonal tells a story. Everything stays cool/dim so the hot
    //    wire remains the only bright, warm thing in the frame.
    _paintEnvironment(canvas, size);

    // 0b) ambient cool far-layer depth motes (calm, dim, blurred).
    _paintAmbient(canvas, size);

    // 1) midspan vignette anchor — deepen the dark right behind the hero diagonal.
    final mid = c.wirePoint(0.5);
    canvas.drawCircle(
      mid,
      h * 0.46,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFF05070F).withValues(alpha: 0.55), const Color(0x00000000)],
          stops: const [0, 1],
        ).createShader(Rect.fromCircle(center: mid, radius: h * 0.46)),
    );

    // 2) dimensional transmission towers (reveal index 0) — recessive/cool, rising.
    final rPosts = c.reveal(0);
    if (rPosts > 0.01) {
      _paintTower(canvas, c.leftAnchor, h, rPosts);
      _paintTower(canvas, c.rightAnchor, h, rPosts);
    }

    // 3) the heat-haze shimmer band rising above the WHOLE span (under the motes so
    //    it reads as a refraction layer behind the rising specks). Scales with heat.
    if (temp > 0.02) {
      _paintHeatHaze(canvas, size, temp);
    }

    // 4) the wire (HERO) — fixed catenary geometry, voluminous body + ember glow.
    final rWire = c.reveal(2);
    if (rWire > 0.01) {
      _paintWire(canvas, size, temp, rWire);
    }

    // 5) travelling pulses along the catenary (stop dead the frame current = 0).
    if (c.current > 0.001 && rWire > 0.5) {
      _paintPulses(canvas, size);
    }

    // 6) heat shimmer motes rising off the glowing span (the loss, made seeable).
    _paintHeatMotes(canvas);

    // 7) rub finger glow (beat B) — warmth blooming under the finger.
    final gx = c.rubGlowX;
    if (gx != null && c.rubGlowIntensity > 0.01) {
      _paintRubGlow(canvas, size, gx, c.rubGlowIntensity);
    }

    // 8) discovery flash ring along the span.
    if (c.flashIntensity > 0.01) {
      _paintFlash(canvas, size, c.flashIntensity);
    }

    // 9) static mono tags (PLANT / CITY / SAME WIRE) — load-bearing chrome.
    final rTags = c.reveal(3);
    if (rTags > 0.01) {
      _paintTags(canvas, size, rTags);
    }
  }

  // Global key light — UPPER-LEFT (the one rule that unifies every separately-drawn
  // steel member into one believable lit object, ported from hand_crank_lamp).
  static const Offset _lightUL = Offset(-0.7071, -0.7071);

  // ── Premium steel lattice tower (hand_crank_lamp metal craft) ──────────────
  // Each member is a CYLINDRICAL steel bar (dark edge → bright spine → dark edge)
  // with an upper-left chamfer rim. Joints are bolted with AO; the whole post casts
  // a ground-contact shadow and lifts off a blurred silhouette; the wire clamps onto
  // a real ceramic insulator string. Kept dim/recessive so the hot wire stays hero.
  void _paintTower(Canvas canvas, Offset top, double h, double rev) {
    final footY = HWTune.pylonBaseY * h;
    final riseDy = (1 - rev) * h * 0.06; // entrance: rises from its foot
    final t = top.translate(0, riseDy);
    final a = rev.clamp(0.0, 1.0);
    final towerH = footY - t.dy;
    if (towerH <= 1) return;

    final headHalf = h * HWTune.towerHeadHalfF;
    final baseHalf = h * HWTune.towerBaseHalfF;
    final legW = h * HWTune.towerLegWF;
    final braceW = h * HWTune.towerBraceWF;

    final headL = Offset(t.dx - headHalf, t.dy);
    final headR = Offset(t.dx + headHalf, t.dy);
    final footL = Offset(t.dx - baseHalf, footY);
    final footR = Offset(t.dx + baseHalf, footY);

    // 1) ground-contact shadow — a wide flat blurred ellipse so the feet sit on a floor.
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
        ..color = HWTune.towerBolt.withValues(alpha: 0.28 * a)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.006),
    );

    // 3) lattice cross-braces (drawn first; legs overlap their ends at the joints).
    final rungs = HWTune.towerRungs;
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

    // 4) the two main legs as cylindrical steel bars (full dark→spine→dark gradient).
    _steelLeg(canvas, headL, footL, legW, a);
    _steelLeg(canvas, headR, footR, legW, a);

    // 5) bolted joints with a tiny up-left specular at each rung↔leg junction.
    for (var i = 0; i <= rungs; i++) {
      final f = i / rungs;
      _bolt(canvas, onLeg(headL, footL, f), legW * 0.6, a);
      _bolt(canvas, onLeg(headR, footR, f), legW * 0.6, a);
    }

    // 6) the ceramic insulator string the wire clamps onto, at the apex.
    _insulatorString(canvas, t, h, a);
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
            HWTune.towerEdge.withValues(alpha: alpha),
            HWTune.towerSpine.withValues(alpha: alpha),
            HWTune.towerEdge.withValues(alpha: alpha),
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
        ..color = HWTune.towerRim.withValues(alpha: 0.55 * alpha)
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
        ..color = HWTune.towerBody.withValues(alpha: 0.92 * alpha),
    );
    final ro = width * 0.40;
    canvas.drawLine(
      a.translate(_lightUL.dx * ro, _lightUL.dy * ro),
      b.translate(_lightUL.dx * ro, _lightUL.dy * ro),
      Paint()
        ..strokeWidth = width * 0.42
        ..strokeCap = StrokeCap.round
        ..color = HWTune.towerRim.withValues(alpha: 0.38 * alpha),
    );
  }

  // A machined bolt head: a dark recessed dot + a tiny up-left specular speck.
  void _bolt(Canvas canvas, Offset at, double r, double alpha) {
    canvas.drawCircle(at, r, Paint()..color = HWTune.towerBolt.withValues(alpha: 0.85 * alpha));
    canvas.drawCircle(
      at.translate(_lightUL.dx * r * 0.5, _lightUL.dy * r * 0.5),
      r * 0.45,
      Paint()..color = Colors.white.withValues(alpha: 0.30 * alpha),
    );
  }

  // The suspension insulator string the wire clamps onto at the apex: a dark clamp
  // + a short stack of dome-shaded ceramic bells.
  void _insulatorString(Canvas canvas, Offset anchor, double h, double alpha) {
    final r = HWTune.insulatorDiscRF * h;
    // the clamp where the conductor grips.
    canvas.drawCircle(anchor, r * 0.55, Paint()..color = HWTune.towerBolt.withValues(alpha: 0.9 * alpha));
    for (var i = 0; i < HWTune.insulatorDiscs; i++) {
      final c = Offset(anchor.dx, anchor.dy + r * 1.15 * (i + 0.7));
      final rect = Rect.fromCenter(center: c, width: r * 2.0, height: r * 1.3);
      canvas.drawOval(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(c.dx + _lightUL.dx * r * 0.5, c.dy + _lightUL.dy * r * 0.4),
            r * 1.5,
            [
              HWTune.insulatorCeramic.withValues(alpha: 0.95 * alpha),
              HWTune.towerEdge.withValues(alpha: 0.92 * alpha),
            ],
          ),
      );
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = HWTune.towerRim.withValues(alpha: 0.5 * alpha),
      );
    }
  }

  // ── The heat-haze shimmer band (rising refraction approximation) ─────────
  // A stack of translucent wavy warm bands above the span, blurred + slowly sine-
  // displaced so it reads as rising heat-shimmer/refraction — warm-on-cool-dark,
  // never fire. Intensity scales with heat. Under reduced motion the bands hold
  // static (no scroll) but still read as a faint warm haze.
  void _paintHeatHaze(Canvas canvas, Size size, double temp) {
    final h = size.height;
    final t = (temp).clamp(0.0, 1.0);
    final scroll = c.reducedMotion ? 0.0 : c.hazePhase;
    final waveLen = HWTune.hazeWaveLenF * size.width;
    final amp = HWTune.hazeWaveAmpF * h;
    final rise = HWTune.hazeRiseF * h;

    // sample the span densely; each haze band rides ABOVE the wire by a growing
    // offset, displaced by a travelling sine so it shimmers.
    const steps = 30;
    for (var b = 0; b < HWTune.hazeBands; b++) {
      final bf = (b + 1) / HWTune.hazeBands; // 0..1 how high this band floats
      // higher bands are fainter + cooler (the heat thins as it rises).
      final bandAlpha = HWTune.hazeBaseAlpha * t * (1.0 - 0.55 * bf);
      if (bandAlpha <= 0.004) continue;
      final path = Path();
      for (var i = 0; i <= steps; i++) {
        final st = i / steps;
        final base = c.wirePoint(0.06 + 0.88 * st);
        // wave displacement: a primary sine + a smaller second harmonic (domain
        // warp) so the band reads as turbulent air, not a clean ribbon.
        final phase = (base.dx / waveLen) - scroll + bf * 1.7;
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
      final col = Color.lerp(HWTune.emberCore, HWTune.energyWarm, 0.35 + 0.5 * bf)!;
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
  void _paintWire(Canvas canvas, Size size, double temp, double rev) {
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

    // ── Cool cylindrical BODY (always present — the held-constant). Built from
    // three stacked strokes (dark edge → body → bright specular spine) so the
    // thick cable reads as a lit cylinder, not a flat line. 2.2-style shading.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = baseStroke
        ..strokeCap = StrokeCap.round
        ..color = HWTune.wireCoolDeep.withValues(alpha: 0.95 * rev),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = baseStroke * 0.74
        ..strokeCap = StrokeCap.round
        ..color = HWTune.wireCool.withValues(alpha: 0.95 * rev),
    );
    // cool specular spine (the cylinder highlight), offset slightly upward.
    canvas.drawPath(
      _wirePath(dy: -baseStroke * 0.16),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = baseStroke * HWTune.cableHighlightFrac * 1.6
        ..strokeCap = StrokeCap.round
        ..color = HWTune.wireSpecular.withValues(alpha: (0.32 - 0.18 * temp) * rev)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, baseStroke * 0.18),
    );

    if (temp > 0.01) {
      // ── EMBER FILL driven ALONG THE SPAN: hottest at the PLANT end, cooling toward
      // the CITY, so the hero wire visibly bleeds its energy out as heat before it
      // arrives (the lesson, made literal in the hero). A slow breath keeps it alive;
      // at high temp a white-hot blow-out core + an anamorphic streak read genuinely
      // incandescent. THIS is the brightest region on screen at high current.
      final glowWidth = baseStroke * (1.0 + HWTune.glowWidenMax * temp);
      final plant = c.wirePoint(0), city = c.wirePoint(1);
      final keep = 1.0 - HWTune.lossTaper; // city-end fraction of plant brightness
      final breath =
          c.reducedMotion ? 1.0 : (1.0 + 0.06 * math.sin(c.hazePhase * 2 * math.pi * 1.3));

      // outer soft bloom (hot at plant → thinner toward city).
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = glowWidth * 2.6
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.014 + h * 0.022 * temp)
          ..shader = ui.Gradient.linear(plant, city, [
            HWTune.emberCore.withValues(alpha: (0.10 + 0.34 * temp) * rev * breath),
            HWTune.emberCore.withValues(alpha: (0.10 + 0.34 * temp) * rev * keep),
          ]),
      );
      // mid ember band — the heat filling the body, tapering plant→city.
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = baseStroke * (0.92 + 0.5 * temp)
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.003 + h * 0.005 * temp)
          ..shader = ui.Gradient.linear(plant, city, [
            HWTune.emberCore.withValues(alpha: (0.55 + 0.35 * temp) * rev),
            HWTune.energyWarm.withValues(alpha: (0.45 + 0.40 * temp) * rev * keep),
          ]),
      );
      // hot core spine — orange → white-hot, brightest at the plant end.
      final whiteHot = ((temp - 0.45) / 0.55).clamp(0.0, 1.0);
      final coreCol = Color.lerp(HWTune.emberCore, HWTune.emberHot, 0.4 + 0.6 * whiteHot)!;
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = baseStroke * (0.42 + 0.30 * temp)
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.plus
          ..shader = ui.Gradient.linear(plant, city, [
            coreCol.withValues(alpha: (0.30 + 0.55 * temp) * rev * breath),
            coreCol.withValues(alpha: (0.30 + 0.55 * temp) * rev * keep),
          ]),
      );
      // white-hot BLOW-OUT — a thin pure-white inner spine at high temp, hottest at
      // the plant end (where the current density bites hardest).
      if (whiteHot > 0.01) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = baseStroke * (0.16 + 0.14 * whiteHot)
            ..strokeCap = StrokeCap.round
            ..blendMode = BlendMode.plus
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6)
            ..shader = ui.Gradient.linear(plant, city, [
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
            ..color = HWTune.emberHot.withValues(alpha: 0.5 * whiteHot * rev * breath),
        );
      }

      // ── EMBER-COOL speckle: as the wire cools (temp present but generation low)
      // the core breaks into a cooling speckle so the glow fades as embers, never
      // snapping to black. Driven purely by temp (the real thermal decay), seeded
      // stably so it doesn't flicker. Brightest speckles trail the hottest stretch.
      _paintEmberSpeckle(canvas, temp, rev, coreCol, baseStroke);
    }
  }

  // Cooling-ember speckle along the span — small bright cores that read as the
  // glow breaking up into embers as the wire cools. Density/brightness ride temp.
  void _paintEmberSpeckle(
      Canvas canvas, double temp, double rev, Color coreCol, double baseStroke) {
    // more speckle in the mid-low band (a cooling read); sparse at full white-hot
    // (it's a solid spine then) and gone near zero.
    final coolBand = (1.0 - (temp - 0.55).clamp(0.0, 0.45) / 0.45) * temp;
    if (coolBand <= 0.02) return;
    final n = (10 + 14 * coolBand).round();
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

  Path _wirePath({double dy = 0}) {
    final start = c.wirePoint(0);
    final path = Path()..moveTo(start.dx, start.dy + dy);
    const steps = 48;
    for (var i = 1; i <= steps; i++) {
      final p = c.wirePoint(i / steps);
      path.lineTo(p.dx, p.dy + dy);
    }
    return path;
  }

  // ── Pulses (energy packets travelling PLANT→CITY, shedding toward the city) ──
  // The energy budget carried by the visual: each pulse THINS + DIMS as it climbs
  // toward the city; in beat C the taper amplifies and motes peel off the head so
  // the loss is unmistakable — never a third number.
  void _paintPulses(Canvas canvas, Size size) {
    final h = size.height;
    final taper = c.pulseTaper;
    final amp = c.pulseTaperAmplified;
    for (var k = 0; k < HWTune.pulseCount; k++) {
      final phase = (c.pulsePhase + k / HWTune.pulseCount) % 1.0;
      // map onto the playable span [0.06, 0.94]
      final st = 0.06 + 0.88 * phase;
      final head = c.wirePoint(st);
      // brightness tapers toward the city: 1 at the plant → (1 - taper) at the city.
      final bright = (1 - taper * st) * (0.55 + 0.45 * c.current);
      // the packet visibly SHRINKS as it climbs — energy arriving diminished.
      final shrink = 0.55 + 0.45 * (1 - st);
      final r = h * (0.013 + 0.007 * c.current) * shrink;

      // comet TAIL — fading samples trailing the head along the wire, so the
      // direction PLANT→CITY is unmistakable and the motion reads smooth.
      const tailN = 6;
      for (var i = tailN; i >= 1; i--) {
        final tt = st - i * 0.020;
        if (tt < 0.04) continue;
        final tf = i / tailN; // 1 far → 0 near
        canvas.drawCircle(
          c.wirePoint(tt),
          r * (1 - 0.6 * tf),
          Paint()
            ..blendMode = BlendMode.plus
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.006)
            ..color = HWTune.energyWarm.withValues(alpha: bright * (1 - tf) * 0.42),
        );
      }
      // head — GOLD (never white, so it never competes with the wire's white-hot core).
      canvas.drawCircle(
        head,
        r * 2.2,
        Paint()
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.011)
          ..color = HWTune.energyWarm.withValues(alpha: 0.30 * bright),
      );
      canvas.drawCircle(
        head,
        r,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = HWTune.energyWarm.withValues(alpha: 0.85 * bright),
      );
      // a tiny bright pinpoint for sparkle (kept small so it never reads as a third light).
      canvas.drawCircle(
        head,
        r * 0.4,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = HWTune.emberHot.withValues(alpha: 0.5 * bright),
      );
      // beat-C emphasis: tiny motes PEEL off the pulse head as it climbs — the
      // visible shedding of energy as heat (the budget carried by the visual).
      if (amp && st > 0.18) {
        final shed = ((st - 0.18) / 0.76).clamp(0.0, 1.0);
        final pk = 1 + ((c.pulsePhase * 13).floor() + k) % 2;
        for (var s = 0; s < pk; s++) {
          final ang = -math.pi / 2 - 0.5 + s * 0.7;
          final off = Offset(math.cos(ang), math.sin(ang)) * h * 0.018 * (0.6 + shed);
          canvas.drawCircle(
            head + off,
            r * 0.5,
            Paint()
              ..blendMode = BlendMode.plus
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.006)
              ..color = HWTune.emberCore.withValues(alpha: 0.30 * shed * (0.55 + 0.45 * c.current)),
          );
        }
      }
    }
  }

  // ── Heat motes ─────────────────────────────────────────────────────────
  void _paintHeatMotes(Canvas canvas) {
    for (final m in c.heatMotes) {
      final a = m.alpha;
      if (a <= 0) continue;
      // a parcel of hot air: cools as it rises (warm gold → dim red → out) and
      // diffuses (blur grows) so it reads as convecting heat, not a flat speck.
      final cool = 1 - a; // 0 young → 1 old
      final col = Color.lerp(HWTune.energyWarm, const Color(0xFFB23A12), cool)!;
      // soft halo — blur scales with the mote size + how far it has cooled.
      canvas.drawCircle(
        m.pos,
        m.size * (1.4 + 1.2 * cool),
        Paint()
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.5 + m.size * 0.8 + 2.0 * cool)
          ..color = col.withValues(alpha: 0.20 * a),
      );
      // bright core.
      canvas.drawCircle(
        m.pos,
        m.size * (0.5 + 0.5 * a),
        Paint()
          ..blendMode = BlendMode.plus
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0)
          ..color = col.withValues(alpha: 0.5 * a),
      );
    }
  }

  // ── Rub finger glow (beat B) — a satisfying warm bloom under the stroke ────
  void _paintRubGlow(Canvas canvas, Size size, double gx, double intensity) {
    final h = size.height;
    final t = ((gx - c.leftAnchor.dx) / (c.rightAnchor.dx - c.leftAnchor.dx)).clamp(0.0, 1.0);
    final center = c.wirePoint(t);
    final r = HWTune.rubGlowRF * h * (0.7 + 0.6 * intensity);
    // wide soft warm bloom
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..blendMode = BlendMode.plus
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.022)
        ..color = HWTune.emberCore.withValues(alpha: 0.46 * intensity),
    );
    // a tighter mid ember
    canvas.drawCircle(
      center,
      r * 0.55,
      Paint()
        ..blendMode = BlendMode.plus
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.006)
        ..color = HWTune.energyWarm.withValues(alpha: 0.55 * intensity),
    );
    // a hot white-warm centre under the finger
    canvas.drawCircle(
      center,
      r * 0.30,
      Paint()
        ..blendMode = BlendMode.plus
        ..color = HWTune.emberHot.withValues(alpha: 0.55 * intensity),
    );
  }

  // ── Discovery flash ────────────────────────────────────────────────────
  void _paintFlash(Canvas canvas, Size size, double intensity) {
    final h = size.height;
    canvas.drawPath(
      _wirePath(),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = c.wireStroke * (3 + 5 * intensity)
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.plus
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.03 * intensity)
        ..color = HWTune.energyWarm.withValues(alpha: 0.35 * intensity),
    );
  }

  // ── Graded environment (ground + distant glows) ───────────────────────────
  void _paintEnvironment(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final groundY = HWTune.pylonBaseY * h;
    // a soft ground band rising from the floor → the towers stand on something.
    final bandTop = groundY - h * 0.13;
    canvas.drawRect(
      Rect.fromLTWH(0, bandTop, w, h - bandTop),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, bandTop),
          Offset(0, h),
          [const Color(0x000E1430), const Color(0xFF0E1430).withValues(alpha: 0.55)],
        ),
    );
    // distant CITY glow behind the upper-right tower (cool, dim).
    canvas.drawCircle(
      Offset(HWTune.pylonRightX * w, HWTune.pylonRightTopY * h * 0.72),
      h * 0.22,
      Paint()
        ..blendMode = BlendMode.plus
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.06)
        ..color = const Color(0xFF2E5C8A).withValues(alpha: 0.10),
    );
    // faint industrial glow behind the lower-left PLANT (cool steel — warm is reserved
    // exclusively for the heat, so the plant never reads as 'hot').
    canvas.drawCircle(
      Offset(HWTune.pylonLeftX * w, groundY - h * 0.04),
      h * 0.15,
      Paint()
        ..blendMode = BlendMode.plus
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.05)
        ..color = const Color(0xFF2E466B).withValues(alpha: 0.08),
    );
  }

  // ── Ambient far motes — blurred cool depth particles (atmosphere, not dust) ──
  void _paintAmbient(Canvas canvas, Size size) {
    for (final AmbientMote m in c.ambientMotes) {
      // muted, never heat-orange (warm is the wire's alone); soft-blurred for depth.
      final col = m.warm ? const Color(0xFF7E6E9A) : const Color(0xFF6E7CA8);
      canvas.drawCircle(
        Offset(m.x * size.width, m.y * size.height),
        m.size * 1.3,
        Paint()
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.8 + m.size * 0.9)
          ..color = col.withValues(alpha: 0.05 + 0.06 * m.driftPhase),
      );
    }
  }

  // ── Grounded location plates + the held-constant annotation ───────────────
  // PLANT / CITY are grounded plates at the base of each tower (the two endpoints
  // of the transmission). SAME WIRE is an annotation pill in the cooler lower gutter
  // with a leader up to the wire — out of the hot midspan so it never fights the hero.
  void _paintTags(Canvas canvas, Size size, double rev) {
    final w = size.width, h = size.height;
    final a = rev.clamp(0.0, 1.0);
    _groundPlate(canvas, HWCopy.tagPlant,
        Offset(c.leftAnchor.dx, HWTune.plantTagY * h), a, kind: _Place.plant);
    _groundPlate(canvas, HWCopy.tagCity,
        Offset(c.rightAnchor.dx, HWTune.cityTagY * h), a, kind: _Place.city);
    // SAME WIRE — leader up to the wire at the matching span fraction.
    final t = ((HWTune.sameWireTagX * w - c.leftAnchor.dx) /
            (c.rightAnchor.dx - c.leftAnchor.dx))
        .clamp(0.0, 1.0);
    _annotationPill(canvas, HWCopy.tagSameWire,
        Offset(HWTune.sameWireTagX * w, HWTune.sameWireTagY * h), c.wirePoint(t), a);
  }

  static const Color _plateFill = Color(0xFF0B1228);
  static const Color _plateBorder = Color(0xFF34406A);

  TextPainter _label(String text, double alpha,
      {double size = 9.5, double weight = 700, double ls = 1.6, double op = 0.92}) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: size,
          fontWeight: FontWeight.values[(weight ~/ 100) - 1],
          letterSpacing: ls,
          color: _tagInk.withValues(alpha: op * alpha),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  // A grounded plate at a tower base: scrim pill + a tiny PLANT/CITY icon + a ground tick.
  void _groundPlate(Canvas canvas, String text, Offset center, double alpha,
      {required _Place kind}) {
    final tp = _label(text, alpha);
    const iconW = 11.0, padH = 9.0, padV = 5.0, gap = 6.0;
    final plateW = iconW + gap + tp.width + padH * 2;
    final plateH = tp.height + padV * 2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: plateW, height: plateH),
      const Radius.circular(7),
    );
    canvas.drawRRect(rect, Paint()..color = _plateFill.withValues(alpha: 0.84 * alpha));
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _plateBorder.withValues(alpha: 0.55 * alpha),
    );
    final iconC = Offset(center.dx - plateW / 2 + padH + iconW / 2, center.dy);
    _placeIcon(canvas, kind, iconC, iconW, alpha);
    tp.paint(canvas, Offset(iconC.dx + iconW / 2 + gap, center.dy - tp.height / 2));
    // ground tick under the plate.
    canvas.drawLine(
      Offset(center.dx - plateW * 0.30, center.dy + plateH / 2 + 4),
      Offset(center.dx + plateW * 0.30, center.dy + plateH / 2 + 4),
      Paint()
        ..strokeWidth = 1
        ..color = _tagInk.withValues(alpha: 0.28 * alpha),
    );
  }

  // Tiny iconographic hint: a smokestack cluster (PLANT) / a skyline (CITY).
  void _placeIcon(Canvas canvas, _Place kind, Offset c, double s, double alpha) {
    final p = Paint()..color = HWTune.towerRim.withValues(alpha: 0.80 * alpha);
    if (kind == _Place.plant) {
      canvas.drawRect(Rect.fromLTWH(c.dx - s / 2, c.dy + s * 0.22, s, s * 0.22), p);
      canvas.drawRect(Rect.fromLTWH(c.dx - s * 0.34, c.dy - s * 0.45, s * 0.22, s * 0.70), p);
      canvas.drawRect(Rect.fromLTWH(c.dx + s * 0.08, c.dy - s * 0.28, s * 0.22, s * 0.52), p);
    } else {
      canvas.drawRect(Rect.fromLTWH(c.dx - s * 0.50, c.dy - s * 0.08, s * 0.26, s * 0.52), p);
      canvas.drawRect(Rect.fromLTWH(c.dx - s * 0.16, c.dy - s * 0.45, s * 0.30, s * 0.90), p);
      canvas.drawRect(Rect.fromLTWH(c.dx + s * 0.22, c.dy - s * 0.24, s * 0.26, s * 0.68), p);
    }
  }

  // The held-constant annotation: a thin leader from the wire to a scrim pill with a
  // little padlock glyph (= this wire is held fixed across every beat).
  void _annotationPill(Canvas canvas, String text, Offset center, Offset wireAt, double alpha) {
    final tp = _label(text, alpha, size: 9.0, weight: 600, ls: 1.5, op: 0.85);
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
        ..color = _tagInk.withValues(alpha: 0.32 * alpha),
    );
    canvas.drawCircle(wireAt, 1.6, Paint()..color = _tagInk.withValues(alpha: 0.5 * alpha));
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: plateW, height: plateH),
      const Radius.circular(6),
    );
    canvas.drawRRect(rect, Paint()..color = _plateFill.withValues(alpha: 0.80 * alpha));
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _plateBorder.withValues(alpha: 0.50 * alpha),
    );
    final lockC = Offset(center.dx - plateW / 2 + padH + lockW / 2, center.dy);
    _lockGlyph(canvas, lockC, lockW, alpha);
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

  @override
  bool shouldRepaint(StagePainter old) => false; // repaints via the controller listenable
}

enum _Place { plant, city }
