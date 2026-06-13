// STATION LAYER — the journey's send end: a small dim plant silhouette (it never
// changes — it is NOT the hero), its launch bloom (identical both runs), the short
// plant→transformer FEED segment with warm-gold pulses (identical both runs), and
// the SMALL transformer core ring whose amber field blooms ONLY on AC (hard-zero
// for the entire DC run — the dead-core absence, criterion 4; 2.6 owns its close-up).
//
// The two live numbers ride here, INSIDE the RepaintBoundary so captures include
// them: VOLTAGE / CURRENT mono chips, shown only during runs (10/100 at launch;
// AC rolls to 200/5). Heat colour never appears here.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart' show Component;
import 'package:flutter/material.dart';

import '../../config/woc_tuning.dart';
import '../../state/woc_controller.dart';

class StationLayer extends Component {
  StationLayer(this.c);
  final WocController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty || c.stationReveal <= 0.01) return;
    final reveal = c.stationReveal;
    final dim = 1 - c.sceneDim;

    _drawPlant(canvas, reveal, dim);
    _drawFeed(canvas, dim);
    _drawTransformer(canvas, reveal, dim);
    if (c.showNumbers) _drawNumbers(canvas, dim);
  }

  // The plant — a small STEEL power station (the same steel craft as the EP2 towers/
  // transformer-plant). Dim and unchanging (NOT the hero), but now it actually reads.
  void _drawPlant(Canvas canvas, double reveal, double dim) {
    final w = c.stageSize.width;
    final cx = c.plantCenter.dx;
    final baseY = c.plantBaseY;
    final pw = c.plantWidth;
    final a = (reveal * dim).clamp(0.0, 1.0);

    // Cooling tower (steel hyperboloid trapezoid) — cross-lit steel gradient + rim.
    final towerW = pw * 0.52, towerH = pw * 0.70;
    final tx = cx - pw * 0.10;
    final towerRect = Rect.fromLTWH(tx - towerW * 0.5, baseY - towerH, towerW, towerH);
    final tower = Path()
      ..moveTo(tx - towerW * 0.5, baseY)
      ..lineTo(tx - towerW * 0.34, baseY - towerH)
      ..lineTo(tx + towerW * 0.34, baseY - towerH)
      ..lineTo(tx + towerW * 0.5, baseY)
      ..close();
    // contact shadow.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(tx, baseY + w * 0.004), width: towerW * 1.2, height: w * 0.012),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.30 * a)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.01),
    );
    canvas.drawPath(
      tower,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            WocTune.steelEdge.withValues(alpha: 0.96 * a),
            WocTune.steelSpine.withValues(alpha: 0.96 * a),
            WocTune.steelEdge.withValues(alpha: 0.96 * a),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(towerRect),
    );
    canvas.drawPath(
      tower,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = WocTune.steelRim.withValues(alpha: 0.5 * a),
    );
    // Two chimney stacks to the right of the tower.
    for (final frac in [0.28, 0.44]) {
      final sx = cx + pw * frac;
      final sRect = Rect.fromLTRB(sx - pw * 0.05, baseY - towerH * 1.12, sx + pw * 0.05, baseY);
      canvas.drawRect(
        sRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              WocTune.steelEdge.withValues(alpha: 0.96 * a),
              WocTune.steelBody.withValues(alpha: 0.96 * a),
              WocTune.steelEdge.withValues(alpha: 0.96 * a),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(sRect),
      );
      canvas.drawRect(
        sRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = WocTune.steelRim.withValues(alpha: 0.42 * a),
      );
    }

    // Launch bloom at the plant's terminal (identical both runs).
    final bloom = c.launchBloom;
    if (bloom > 0.01) {
      final at = c.feedStart;
      final r = w * (0.03 + 0.05 * bloom);
      canvas.drawCircle(
        at,
        r,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = ui.Gradient.radial(at, r, [
            WocTune.pulseWarm.withValues(alpha: 0.7 * bloom * dim),
            WocTune.pulseWarm.withValues(alpha: 0.0),
          ]),
      );
    }
  }

  // The short feed segment plant→transformer, with warm-gold pulses (identical
  // both runs — the visible held-constant launch).
  void _drawFeed(Canvas canvas, double dim) {
    final a = c.feedStart, b = c.feedEnd;
    canvas.drawLine(
      a,
      b,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = c.stageSize.width * 0.01
        ..strokeCap = StrokeCap.round
        ..color = WocTune.wireBase.withValues(alpha: 0.9 * dim),
    );
    // Warm feed pulses (only while a run is sending and the bloom has fired).
    if (c.phase.value == WocPhase.sending && c.launchBloom > 0.2) {
      final pulse = Paint()
        ..blendMode = BlendMode.plus
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      for (var i = 0; i < 3; i++) {
        final t = (c.feedPulseT + i / 3) % 1.0;
        final p = Offset.lerp(a, b, t)!;
        canvas.drawCircle(
          p,
          c.stageSize.width * 0.012,
          pulse..color = WocTune.pulseWarm.withValues(alpha: 0.6 * dim),
        );
      }
    }
  }

  // The MINI transformer — the SAME iron-core object as activity 6/7 (a laminated
  // iron window + copper coils), kept small (this beat is NOT about the transformer;
  // 2.6 owns its close-up). Its amber FLUX is alive ONLY on AC; on DC the core is
  // dead/dark every frame (the dead-core absence, criterion 4).
  void _drawTransformer(Canvas canvas, double reveal, double dim) {
    final ctr = c.transformerCenter;
    final ow = c.miniCoreW, oh = c.miniCoreH, lt = c.miniLimb;
    final presence = c.transformerPresence.clamp(0.0, 1.0);
    final a = (reveal * dim * presence).clamp(0.0, 1.0);
    if (a <= 0.01) return; // fully gone (the DC run) — nothing to draw
    final bloom = c.coreBloom.clamp(0.0, 1.0);

    final outer = RRect.fromRectAndRadius(
        Rect.fromCenter(center: ctr, width: ow, height: oh), Radius.circular(lt * 0.7));
    final inner = RRect.fromRectAndRadius(
        Rect.fromCenter(center: ctr, width: ow - lt * 2, height: oh - lt * 2),
        Radius.circular(lt * 0.45));

    // Disappear / reappear: the fade rides `a`; a gentle shrink-grow centred on the
    // core sells the materialise (DC fades it away, AC brings it back).
    canvas.save();
    final scale = 0.6 + 0.4 * presence;
    canvas.translate(ctr.dx, ctr.dy);
    canvas.scale(scale);
    canvas.translate(-ctr.dx, -ctr.dy);

    // Amber field bloom BEHIND the core when ALIVE (AC) — a warm wash; nothing on DC.
    if (bloom > 0.01) {
      final breathe = c.reducedMotion ? 1.0 : (0.85 + 0.15 * math.sin(c.pulsePhase * 3));
      final r = ow * (0.85 + 0.55 * bloom) * breathe;
      canvas.drawCircle(
        ctr,
        r,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = ui.Gradient.radial(ctr, r, [
            WocTune.coreAmber.withValues(alpha: 0.50 * bloom * dim * presence),
            WocTune.coreAmber.withValues(alpha: 0.0),
          ]),
      );
    }

    // Contact shadow (the iron has weight).
    canvas.drawRRect(
      outer.shift(Offset(0, oh * 0.06)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.34 * a)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, lt * 0.9),
    );

    // The dark laminated iron ring (the window frame) — topLeft lit → foot dark.
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
          colors: [
            WocTune.ironLite.withValues(alpha: 0.85 * a),
            WocTune.ironMid.withValues(alpha: a),
            WocTune.ironDark.withValues(alpha: a),
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(outer.outerRect),
    );
    // A lit top-left bevel + crisp rim so the iron reads dimensional.
    canvas.save();
    canvas.clipRRect(outer);
    canvas.drawLine(
      Offset(outer.outerRect.left, outer.outerRect.top + lt * 0.18),
      Offset(outer.outerRect.right, outer.outerRect.top + lt * 0.18),
      Paint()
        ..color = WocTune.ironBevel.withValues(alpha: 0.5 * a)
        ..strokeWidth = lt * 0.3
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
    canvas.drawRRect(outer,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = WocTune.ironLite.withValues(alpha: 0.4 * a));
    canvas.drawRRect(inner,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0..color = const Color(0xFF0A0E22).withValues(alpha: 0.85 * a));

    // The amber FLUX circulating the iron window when ALIVE — a breathing additive
    // ribbon + a bright heart (the changing field made visible). DEAD on DC.
    if (bloom > 0.01) {
      final rect = Rect.fromCenter(center: ctr, width: ow - lt, height: oh - lt);
      final rr = RRect.fromRectAndRadius(rect, Radius.circular(lt * 0.5));
      final breathe = c.reducedMotion ? 1.0 : (0.8 + 0.2 * math.sin(c.pulsePhase * 3));
      canvas.drawRRect(
        rr,
        Paint()
          ..blendMode = BlendMode.plus
          ..style = PaintingStyle.stroke
          ..strokeWidth = lt * 0.6
          ..strokeCap = StrokeCap.round
          ..color = WocTune.coreAmber
              .withValues(alpha: (0.30 + 0.40 * bloom) * breathe * dim * presence)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, lt * 0.5),
      );
      canvas.drawCircle(
        ctr,
        lt * 1.1,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = WocTune.coreAmberHot.withValues(alpha: 0.6 * bloom * dim * presence)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, lt * 0.8),
      );
    }

    // The copper coils on each limb (the SAME object as 2.6/2.7, mini).
    _miniCoil(canvas, ctr.dx - ow * 0.5 + lt * 0.5, ctr.dy, oh, lt, a); // primary (left)
    _miniCoil(canvas, ctr.dx + ow * 0.5 - lt * 0.5, ctr.dy, oh, lt, a); // secondary (right)

    canvas.restore(); // end the disappear/reappear scale transform
  }

  // A mini copper coil wound on a vertical limb — back arc (recessed) + bright front
  // arc (cylindrical copper shade) + a thin sheen, per turn. Condensed 2.6 craft.
  void _miniCoil(Canvas canvas, double limbX, double cy, double oh, double lt, double a) {
    final turns = WocTune.miniCoilTurns;
    final span = oh * 0.74;
    final top = cy - span / 2;
    final loopH = span / turns;
    final loopW = lt * 2.0;
    final wire = lt * 0.46;
    for (var i = 0; i < turns; i++) {
      final y = top + loopH * (i + 0.5);
      final rect = Rect.fromCenter(center: Offset(limbX, y), width: loopW, height: loopH * 0.94);
      // back arc (behind the limb — recessed/dark).
      canvas.drawArc(rect, -math.pi / 2, math.pi, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = wire * 0.9
            ..strokeCap = StrokeCap.round
            ..color = WocTune.copperDark.withValues(alpha: 0.9 * a));
      // front arc (bright copper, lit top → dark foot).
      canvas.drawArc(rect, math.pi / 2, math.pi, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = wire
            ..strokeCap = StrokeCap.round
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                WocTune.copperLite.withValues(alpha: a),
                WocTune.copper.withValues(alpha: a),
                WocTune.copperDark.withValues(alpha: a),
              ],
              stops: const [0.0, 0.55, 1.0],
            ).createShader(rect));
      // a thin specular sheen on the upper edge.
      canvas.drawArc(rect.translate(0, -wire * 0.2), math.pi / 2 + 0.35, math.pi - 0.7, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.0, wire * 0.3)
            ..strokeCap = StrokeCap.round
            ..color = WocTune.copperHot.withValues(alpha: 0.7 * a));
    }
  }

  // VOLTAGE / CURRENT as INSTRUMENT GAUGES (matching 2.1–2.7) riding the send end —
  // the ≤2 live numbers, INSIDE the RepaintBoundary so captures include them. Each
  // gauge: dark glass body, mono label + rolling digits, a value-linked glow, an
  // accent bar whose length rides the value, an ↑ trend glyph. NEUTRAL gold accent —
  // never an outcome hint (no red/green). Heat colour never appears here.
  void _drawNumbers(Canvas canvas, double dim) {
    final h = c.stageSize.height;
    final chipH = WocTune.gaugeHeightFactor * h;
    // VOLTAGE — norm = V / 200 (10 → 0.05 at launch, 200 → 1.0 stepped up).
    _drawGauge(
      canvas,
      center: c.voltageChipPos,
      chipH: chipH,
      label: 'VOLTAGE',
      value: c.dispVoltage.round().toString(),
      norm: (c.dispVoltage / WocTune.vGaugeMax).clamp(0.0, 1.0),
      dim: dim,
      trend: c.dispVoltage > WocTune.vLaunch + 0.5, // ↑ only once it steps up (AC)
    );
    // CURRENT — norm = I / 100 (100 → 1.0 at launch, 5 → 0.05 trickle on AC).
    _drawGauge(
      canvas,
      center: c.currentChipPos,
      chipH: chipH,
      label: 'CURRENT',
      value: c.dispCurrent.round().toString(),
      norm: (c.dispCurrent / WocTune.iGaugeMax).clamp(0.0, 1.0),
      dim: dim,
      trend: false, // current never rises (it falls on AC, holds on DC)
    );
  }

  void _drawGauge(
    Canvas canvas, {
    required Offset center,
    required double chipH,
    required String label,
    required String value,
    required double norm,
    required double dim,
    required bool trend,
  }) {
    final accent = WocTune.gold; // neutral chrome accent — NO outcome hint
    final width = chipH * 2.6;
    final rect = Rect.fromCenter(center: center, width: width, height: chipH);
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(chipH * 0.22));

    // value-linked glow halo (instrument-grade live read; recedes vs the hero line).
    if (norm > 0.02) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(chipH * 0.16), Radius.circular(chipH * 0.34)),
        Paint()
          ..blendMode = BlendMode.plus
          ..color = accent.withValues(alpha: 0.14 * norm * dim)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, chipH * 0.3),
      );
    }
    // dark glass body + accent border that warms with the value.
    canvas.drawRRect(rr, Paint()..color = const Color(0xFF0B1330).withValues(alpha: 0.85 * dim));
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
            .withValues(alpha: (0.42 + 0.3 * norm) * dim),
    );

    final padX = chipH * 0.24;
    // label (top, mono small).
    final lp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: chipH * 0.18,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: accent.withValues(alpha: 0.82 * dim),
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
          color: Colors.white.withValues(alpha: 0.96 * dim),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final valueY = rect.top + chipH * 0.13 + lp.height + chipH * 0.05;
    vp.paint(canvas, Offset(rect.left + padX, valueY));
    if (trend) {
      final ap = TextPainter(
        text: TextSpan(
          text: '↑',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: chipH * 0.28,
            fontWeight: FontWeight.w800,
            color: accent.withValues(alpha: 0.9 * dim),
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
      Paint()..color = accent.withValues(alpha: 0.16 * dim),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barL, barY, barW * norm, barH), Radius.circular(barH / 2)),
      Paint()
        ..blendMode = BlendMode.plus
        ..color = accent.withValues(alpha: 0.88 * dim),
    );
  }
}
