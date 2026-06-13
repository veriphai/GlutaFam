// The current slider for Squared Loss (PRD §16) — a custom track with a glowing
// handle. The ONLY variable in the learner's hand. Zero momentum: the handle is
// exactly the clamped finger x; release leaves it where it is (the controller
// snaps to the nearest detent in detent mode). Detent ticks at ×1/×2/×3/×4 fade
// OUT in sweep mode (continuous). Locked phases dim the track + ignore touches.
//
// A Listener (not GestureDetector) forwards raw pointer x to the controller as a
// normalized [0,1] along the track, so the handle tracks the finger precisely.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/squared_loss_copy.dart';
import '../config/squared_loss_tuning.dart';
import '../state/squared_loss_controller.dart';

class CurrentSlider extends StatelessWidget {
  const CurrentSlider({super.key, required this.controller});
  final SquaredLossController controller;

  static const double _trackInsetFactor = 0.10; // track runs 0.10·w → 0.90·w
  static const double _height = 60;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final trackLeft = _trackInsetFactor * w;
            final trackRight = (1 - _trackInsetFactor) * w;
            final trackW = trackRight - trackLeft;

            double localToNorm(double localX) =>
                ((localX - trackLeft) / trackW).clamp(0.0, 1.0);

            final locked = controller.sliderLocked;
            return Opacity(
              opacity: locked ? 0.5 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The label so it's clear this slider drives CURRENT (as in 2.3),
                  // aligned to the track's left edge.
                  Padding(
                    padding: EdgeInsets.only(left: trackLeft),
                    child: Text(
                      SLCopy.chipCurrent,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: locked ? null : (e) => controller.onHandleDown(localToNorm(e.localPosition.dx)),
                    onPointerMove: locked ? null : (e) => controller.onHandleMove(localToNorm(e.localPosition.dx)),
                    onPointerUp: locked ? null : (e) => controller.onHandleUp(),
                    onPointerCancel: locked ? null : (e) => controller.onHandleUp(),
                    child: SizedBox(
                      height: _height,
                      width: w,
                      child: CustomPaint(
                        painter: _SliderPainter(
                          controller: controller,
                          trackLeft: trackLeft,
                          trackRight: trackRight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SliderPainter extends CustomPainter {
  _SliderPainter({
    required this.controller,
    required this.trackLeft,
    required this.trackRight,
  });
  final SquaredLossController controller;
  final double trackLeft;
  final double trackRight;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final trackW = trackRight - trackLeft;
    const railH = 9.0;
    final railRect = Rect.fromCenter(
        center: Offset((trackLeft + trackRight) / 2, cy), width: trackW, height: railH);
    final rail = RRect.fromRectAndRadius(railRect, const Radius.circular(railH / 2));

    // The handle position along the FULL ×1..×4 track (matches the detent ticks).
    final norm = controller.handleX;
    final hx = trackLeft + norm * trackW;
    final heat = controller.wireGlow.clamp(0.0, 1.0); // felt glow (the square)

    // ── recessed machined groove — vertical 3-stop (dark top lip → wall → lit floor).
    canvas.drawRRect(
      rail,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, cy - railH / 2),
          Offset(0, cy + railH / 2),
          const [Color(0xFF080E1E), Color(0xFF161E3C), Color(0xFF263255)],
          const [0.0, 0.55, 1.0],
        ),
    );
    canvas.save();
    canvas.clipRRect(rail);
    // inner top shadow (the groove has depth).
    canvas.drawLine(
      Offset(trackLeft, cy - railH / 2 + 1.2),
      Offset(trackRight, cy - railH / 2 + 1.2),
      Paint()
        ..strokeWidth = 2.0
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    // warm fill glowing from INSIDE the groove (energy → ember).
    final fillW = (hx - trackLeft).clamp(0.0, trackW);
    if (fillW > 0) {
      canvas.drawRect(
        Rect.fromLTWH(trackLeft, cy - railH / 2, fillW + railH / 2, railH),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(trackLeft, cy),
            Offset(hx, cy),
            [SLTune.energy.withValues(alpha: 0.85), SLTune.heat.withValues(alpha: 0.95)],
          ),
      );
    }
    canvas.restore();
    // top gloss lip (the groove's near edge catching the key light).
    canvas.drawLine(
      Offset(trackLeft + railH / 2, cy - railH / 2 + 0.6),
      Offset(trackRight - railH / 2, cy - railH / 2 + 0.6),
      Paint()
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.08),
    );
    // additive bloom rising off the filled channel (∝ heat).
    if (fillW > 0 && heat > 0.01) {
      canvas.drawLine(
        Offset(trackLeft, cy),
        Offset(hx, cy),
        Paint()
          ..strokeWidth = railH * 0.9
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 + 6 * heat)
          ..color = SLTune.heat.withValues(alpha: 0.28 * heat),
      );
    }

    // Detent ticks + labels at ×1..×4 (just BELOW the groove so the knob never covers
    // them) — fade OUT in sweep (continuous) mode. Positioned along the FULL span.
    final tickAlpha = controller.detentMode ? 0.55 : 0.10;
    final tickPaint = Paint()..style = PaintingStyle.fill;
    final baseLabelA = controller.detentMode ? 0.6 : 0.16;
    final tickY = cy + railH / 2 + 7;
    for (final d in SLTune.detents4) {
      final f = (d - 1.0) / 3.0;
      final tx = trackLeft + f * trackW;
      final inRange = d >= controller.rangeMin - 1e-6 && d <= controller.rangeMax + 1e-6;
      tickPaint.color = Colors.white.withValues(alpha: inRange ? tickAlpha : tickAlpha * 0.4);
      canvas.drawCircle(Offset(tx, tickY), 2.0, tickPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: '×${d.toInt()}',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: inRange ? baseLabelA : baseLabelA * 0.4),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(tx - tp.width / 2, tickY + 5));
    }

    // ── The glossy-glass HEAT KNOB (warm port of 2.1/2.3 piston). Its warmth rides
    // the felt glow (the square) + a touch / idle-nudge lift; zero momentum.
    final touched = controller.pointerDown;
    final pulse = controller.idlePulse; // gentle nudge after a long idle
    final lift = (touched ? 0.25 : 0.0) + 0.3 * pulse;
    final lit = (heat + lift).clamp(0.0, 1.0);
    final tc = Offset(hx, cy);
    const r = 13.0;

    // 1) under-glow halo (∝ felt glow).
    if (lit > 0.01) {
      canvas.drawCircle(
        tc,
        13 + 11 * lit,
        Paint()
          ..blendMode = BlendMode.plus
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11)
          ..color = SLTune.heat.withValues(alpha: 0.20 + 0.30 * lit),
      );
    }
    // 2) drop shadow — the knob sits proud of the groove.
    canvas.drawCircle(
      tc.translate(0, r * 0.16),
      r,
      Paint()
        ..color = const Color(0xFF03060F).withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, r * 0.30),
    );
    // 3) glass body — radial 4-stop warm (bright up-left → deep lower-right).
    canvas.drawCircle(
      tc,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          tc.translate(-r * 0.35, -r * 0.45),
          r * 1.35,
          const [Color(0xFFFFE9B8), Color(0xFFFFD27A), Color(0xFFFF9A4E), Color(0xFFC7521A)],
          const [0.0, 0.34, 0.74, 1.0],
        ),
    );
    // 4) crisp specular cap (the gloss-seller), up-left of centre.
    canvas.drawCircle(
      tc.translate(-r * 0.32, -r * 0.34),
      r * 0.30,
      Paint()..color = Colors.white.withValues(alpha: 0.65),
    );
    // 5) rim — vertical 2-stop (bright top → deep base) so the form rounds.
    canvas.drawCircle(
      tc,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..shader = ui.Gradient.linear(
          Offset(0, tc.dy - r),
          Offset(0, tc.dy + r),
          [
            const Color(0xFFFFE9B8).withValues(alpha: 0.95),
            const Color(0xFF7A2E10).withValues(alpha: 0.70),
          ],
        ),
    );
    // 6) hot ember core — grows + whitens with the felt glow.
    canvas.drawCircle(
      tc,
      r * 0.34 * (0.5 + 0.5 * lit),
      Paint()
        ..blendMode = BlendMode.plus
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5)
        ..color = SLTune.heatCore.withValues(alpha: 0.5 + 0.4 * lit),
    );
  }

  @override
  bool shouldRepaint(_SliderPainter old) => true;
}
