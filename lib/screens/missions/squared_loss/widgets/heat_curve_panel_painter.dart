// The heat-vs-current graph for Squared Loss (PRD §16) — a CENTERED MODAL with a
// backdrop scrim and PROPER LABELLED AXES, so the learner can read exactly what the
// curve plots: CURRENT (×1..×4) across the bottom, HEAT (1× / 4× / 9× / 16×) up the
// side. Faint gridlines at the heat levels make the square legible (×2 → 4× the
// height). The learner's own trail builds as a glowing warm curve under the finger;
// a crisp dashed GHOST line shows what a straight (linear) relationship would do.
// Hidden until `sweep`; on `voltsStep` it DISMISSES COMPLETELY (slide-down + fade),
// never a dim.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/squared_loss_copy.dart';
import '../config/squared_loss_tuning.dart';
import '../state/squared_loss_controller.dart';

enum _Align { center, centerTop, rightCenter }

class HeatCurvePanelPainter extends CustomPainter {
  HeatCurvePanelPainter(this.c) : super(repaint: c);
  final SquaredLossController c;

  // The detent levels the axes annotate (current ×, with heat-multiple = ×²).
  static const List<int> _levels = [1, 2, 3, 4];

  @override
  void paint(Canvas canvas, Size size) {
    final reveal = c.graphReveal;
    final dismiss = c.panelDismiss;
    if (reveal <= 0.001 || dismiss >= 1.0) return;
    final op = reveal * (1.0 - dismiss); // overall visibility 0..1
    if (op <= 0.001) return;

    final w = size.width, h = size.height;

    // 0) backdrop scrim over the whole stage — focuses the modal.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black.withValues(alpha: SLTune.panelScrimAlpha * op),
    );

    // The modal card rect, with an entrance slide-up and a dismiss slide-down.
    final rect = Rect.fromLTRB(
      SLTune.panelLeftX * w,
      SLTune.panelTopY * h,
      SLTune.panelRightX * w,
      SLTune.panelBottomY * h,
    );
    final slideIn = (1.0 - reveal) * SLTune.panelSlideFromY * h;
    final slideOut = dismiss * SLTune.panelSlideFromY * h * 1.6;
    canvas.save();
    canvas.translate(0, slideIn + slideOut);

    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(20));

    // soft outer drop shadow so the card lifts off the scene.
    canvas.drawRRect(
      rr.shift(const Offset(0, 6)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45 * op)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    // dark-glass body + top sheen + warm-gold hairline border.
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF141E40).withValues(alpha: 0.97 * op),
            const Color(0xFF0A1126).withValues(alpha: 0.97 * op),
          ],
        ).createShader(rect),
    );
    canvas.drawLine(
      Offset(rect.left + 18, rect.top + 1.5),
      Offset(rect.right - 18, rect.top + 1.5),
      Paint()
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.07 * op),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = SLTune.gold.withValues(alpha: 0.22 * op),
    );

    // Title.
    _label(
      canvas,
      SLCopy.graphTitle,
      Offset(rect.center.dx, rect.top + rect.height * 0.085),
      size: rect.height * 0.058,
      color: SLTune.energy.withValues(alpha: 0.92 * op),
      ls: 2.0,
      align: _Align.center,
    );

    // The inner plotting area (room left for the Y labels/title + X labels/title).
    final inner = Rect.fromLTRB(
      rect.left + rect.width * 0.17,
      rect.top + rect.height * 0.22,
      rect.right - rect.width * 0.07,
      rect.bottom - rect.height * 0.20,
    );
    Offset plot(Offset n) => Offset(
          inner.left + n.dx * inner.width,
          inner.top + n.dy * inner.height,
        );
    final labelSize = rect.height * 0.05;

    // ── Y gridlines + labels (heat multiples) at each ×level's heat height. ──
    final gridPaint = Paint()
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.08 * op);
    for (final i in _levels) {
      final ny = 1.0 - (i * i) / 16.0; // heat / heatMax  (heat = 100·I², max = 1600)
      final y = inner.top + ny * inner.height;
      canvas.drawLine(Offset(inner.left, y), Offset(inner.right, y), gridPaint);
      _label(
        canvas,
        '${i * i}×',
        Offset(inner.left - 8, y),
        size: labelSize,
        color: Colors.white.withValues(alpha: 0.55 * op),
        align: _Align.rightCenter,
      );
    }

    // ── Axis frame (L-shape) + X ticks + X labels. ──
    final axisPaint = Paint()
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.32 * op);
    canvas.drawLine(Offset(inner.left, inner.top), Offset(inner.left, inner.bottom), axisPaint);
    canvas.drawLine(Offset(inner.left, inner.bottom), Offset(inner.right, inner.bottom), axisPaint);
    for (final i in _levels) {
      final nx = (i - 1) / 3.0;
      final x = inner.left + nx * inner.width;
      canvas.drawLine(Offset(x, inner.bottom), Offset(x, inner.bottom + 4), axisPaint);
      _label(
        canvas,
        '×$i',
        Offset(x, inner.bottom + 8),
        size: labelSize,
        color: Colors.white.withValues(alpha: 0.55 * op),
        align: _Align.centerTop,
      );
    }

    // Axis titles — CURRENT (under the X labels) + HEAT (rotated, left of the Y labels).
    _label(
      canvas,
      SLCopy.graphXAxis,
      Offset(inner.center.dx, rect.bottom - rect.height * 0.055),
      size: labelSize * 0.95,
      color: Colors.white.withValues(alpha: 0.42 * op),
      ls: 1.6,
      align: _Align.center,
    );
    canvas.save();
    canvas.translate(rect.left + rect.width * 0.05, inner.center.dy);
    canvas.rotate(-math.pi / 2);
    _label(
      canvas,
      SLCopy.graphYAxis,
      Offset.zero,
      size: labelSize * 0.95,
      color: Colors.white.withValues(alpha: 0.42 * op),
      ls: 1.6,
      align: _Align.center,
    );
    canvas.restore();

    // ── The STRAIGHT ghost line — what heat WOULD do if it only kept pace with
    // current: from the shared ×1 / 1× start (0, 0.9375) to linear-at-×4 (4× = 0.75),
    // versus the curve's real 16× at ×4. Crisp, faint, dashed.
    if (c.ghostReveal > 0.001) {
      final g = c.ghostReveal * op;
      _dashedLine(
        canvas,
        plot(const Offset(0, 0.9375)),
        plot(const Offset(1, 0.75)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.28 * g),
      );
    }

    // ── The learner's trail — drawn only where the handle has been (honest gaps),
    // a layered glowing curve (wide bloom → mid band → bright core).
    final trail = c.curveTrail;
    if (trail.isNotEmpty) {
      final pulse = c.curveClosePulse;
      _trailPath(
        canvas,
        trail,
        plot,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11 + 7 * pulse
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..blendMode = BlendMode.plus
          ..color = SLTune.heat.withValues(alpha: (0.14 + 0.26 * pulse) * op)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      _trailPath(
        canvas,
        trail,
        plot,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 + 2 * pulse
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..blendMode = BlendMode.plus
          ..color = SLTune.energy.withValues(alpha: (0.30 + 0.3 * pulse) * op)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );
      _trailPath(
        canvas,
        trail,
        plot,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = Color.lerp(SLTune.energy, SLTune.heatCore, 0.3 + 0.5 * pulse)!
              .withValues(alpha: 0.95 * op),
      );

      // the live glowing head dot (where the handle is right now during the sweep).
      if (!c.curveClosed && c.pointerDown) {
        final head = plot(trail.last);
        canvas.drawCircle(
          head,
          9,
          Paint()
            ..blendMode = BlendMode.plus
            ..color = SLTune.heat.withValues(alpha: 0.5 * op)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
        canvas.drawCircle(
          head,
          4.5,
          Paint()
            ..color = SLTune.heatCore.withValues(alpha: 0.95 * op)
            ..blendMode = BlendMode.plus,
        );
      }
    }

    // ── Data-point markers at ×2 / ×3 / ×4 with dotted projection lines to BOTH
    // axes, so each point reads off cleanly (×2 → 4×, ×3 → 9×, ×4 → 16×). They
    // appear once the curve is complete (the close pulse covers the reveal).
    if (c.curveClosed) {
      final projPaint = Paint()
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..color = SLTune.energy.withValues(alpha: 0.5 * op);
      for (final i in const [2, 3, 4]) {
        final nx = (i - 1) / 3.0;
        final ny = 1.0 - (i * i) / 16.0; // heat / heatMax
        final p = plot(Offset(nx, ny));
        // dotted drop to the X axis + dotted run across to the Y axis.
        _dashedLine(canvas, p, Offset(p.dx, inner.bottom), projPaint, dash: 2, gap: 3);
        _dashedLine(canvas, p, Offset(inner.left, p.dy), projPaint, dash: 2, gap: 3);
        // marker — soft glow + warm core + ring.
        canvas.drawCircle(
          p,
          6,
          Paint()
            ..blendMode = BlendMode.plus
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
            ..color = SLTune.heat.withValues(alpha: 0.5 * op),
        );
        canvas.drawCircle(p, 3.3, Paint()..color = SLTune.heatCore.withValues(alpha: 0.98 * op));
        canvas.drawCircle(
          p,
          3.3,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.3
            ..color = SLTune.energy.withValues(alpha: 0.95 * op),
        );
      }
    }

    canvas.restore();
  }

  // ── Text helper ─────────────────────────────────────────────────────────
  void _label(
    Canvas canvas,
    String text,
    Offset at, {
    required double size,
    required Color color,
    double weight = 700,
    double ls = 0.5,
    _Align align = _Align.centerTop,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: size,
          fontWeight: FontWeight.values[(weight ~/ 100) - 1],
          letterSpacing: ls,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = at.dx, dy = at.dy;
    switch (align) {
      case _Align.center:
        dx -= tp.width / 2;
        dy -= tp.height / 2;
      case _Align.centerTop:
        dx -= tp.width / 2;
      case _Align.rightCenter:
        dx -= tp.width;
        dy -= tp.height / 2;
    }
    tp.paint(canvas, Offset(dx, dy));
  }

  /// Plot the trail as connected segments with honest gaps. Per x-bucket keep the
  /// lowest y (highest heat) so the drawn curve is the upper envelope the learner
  /// traced; a >2-bucket x-gap breaks the path so an incomplete sweep reads so.
  void _trailPath(Canvas canvas, List<Offset> trail, Offset Function(Offset) plot, Paint paint) {
    if (trail.isEmpty) return;
    const buckets = SLTune.coverageBuckets;
    final best = List<Offset?>.filled(buckets, null);
    for (final pt in trail) {
      final b = (pt.dx * (buckets - 1)).round().clamp(0, buckets - 1);
      final cur = best[b];
      if (cur == null || pt.dy < cur.dy) best[b] = pt;
    }
    Path? path;
    int? lastB;
    for (var b = 0; b < buckets; b++) {
      final pt = best[b];
      if (pt == null) {
        path = _flush(canvas, path, paint);
        lastB = null;
        continue;
      }
      final p = plot(pt);
      if (path == null || lastB == null || b - lastB > 2) {
        path = _flush(canvas, path, paint);
        path = Path()..moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
      lastB = b;
    }
    _flush(canvas, path, paint);
  }

  Path? _flush(Canvas canvas, Path? path, Paint paint) {
    if (path != null) canvas.drawPath(path, paint);
    return null;
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint,
      {double dash = 6.0, double gap = 5.0}) {
    final total = (b - a).distance;
    if (total <= 0) return;
    final dir = (b - a) / total;
    var d = 0.0;
    while (d < total) {
      final s = a + dir * d;
      final e = a + dir * (d + dash).clamp(0, total);
      canvas.drawLine(s, e, paint);
      d += dash + gap;
    }
  }

  @override
  bool shouldRepaint(HeatCurvePanelPainter old) => true;
}
