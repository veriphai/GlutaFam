// The VOLTAGE slider — the one simple control (the only manipulated variable), the
// same glass-groove + warm glass-knob craft as 2.3/2.4. Slide right → the sending
// voltage rises → the current falls by itself (the pinned area) → the wire cools →
// the town lights. The slider's position is the controller's voltage (single source
// of truth), so it stays exact; selectionClick per +10 V detent is fired by the
// controller. Dimmed/locked until the intro reaches the raise phase.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/transmission_beats.dart';
import '../config/transmission_tuning.dart';
import '../state/transmission_controller.dart';

class VoltageSlider extends StatelessWidget {
  const VoltageSlider({super.key, required this.controller});

  final TransmissionController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final enabled = controller.controlEnabled;
        return Opacity(
          opacity: enabled ? 1.0 : 0.4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                TTCopy.voltageLabel,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 4),
              _Track(
                value: controller.sliderNorm,
                enabled: enabled,
                onChanged: enabled ? controller.onSliderChanged : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({required this.value, required this.enabled, required this.onChanged});

  final double value; // 0..1 (controller.sliderNorm)
  final bool enabled;
  final ValueChanged<double>? onChanged;

  // Thumb inset (px) — the painter clamps the thumb centre to [inset, w-inset]; the
  // pointer→value mapping uses the SAME inset so the thumb tracks the touch to both
  // rails and the extremes (V 10 / V 200) still register cleanly.
  static const double _thumbInset = 15.0;

  @override
  Widget build(BuildContext context) {
    const trackH = 52.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        void update(Offset localPos) {
          if (onChanged == null) return;
          final usable = (width - 2 * _thumbInset);
          final v = usable <= 0 ? 0.0 : ((localPos.dx - _thumbInset) / usable).clamp(0.0, 1.0);
          onChanged!(v);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => update(d.localPosition),
          onHorizontalDragStart: (d) => update(d.localPosition),
          onHorizontalDragUpdate: (d) => update(d.localPosition),
          child: SizedBox(
            height: trackH,
            width: width,
            child: CustomPaint(painter: _SliderPainter(value: value, enabled: enabled)),
          ),
        );
      },
    );
  }
}

class _SliderPainter extends CustomPainter {
  _SliderPainter({required this.value, required this.enabled});

  final double value;
  final bool enabled;

  static const double _inset = 15.0;
  static const double _knobR = 15.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cy = h / 2;
    final lit = value.clamp(0.0, 1.0);

    const railH = 11.0;
    final railRect = Rect.fromCenter(center: Offset(w / 2, cy), width: w, height: railH);
    final rail = RRect.fromRectAndRadius(railRect, const Radius.circular(railH / 2));

    // recessed machined groove (dark top lip → wall → lit floor).
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
    canvas.drawLine(
      Offset(0, cy - railH / 2 + 1.2),
      Offset(w, cy - railH / 2 + 1.2),
      Paint()
        ..strokeWidth = 2.0
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    // warm gold fill glowing from INSIDE the groove (voltage filled = power sending).
    final usable = (w - 2 * _inset).clamp(0.0, w);
    final tx = _inset + usable * value;
    if (value > 0.005) {
      canvas.drawRect(
        Rect.fromLTWH(0, cy - railH / 2, tx + railH / 2, railH),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, cy),
            Offset(tx, cy),
            [
              TTTune.goldHot.withValues(alpha: 0.85),
              TTTune.gold.withValues(alpha: 0.95),
            ],
          ),
      );
    }
    canvas.restore();
    // top gloss lip.
    canvas.drawLine(
      Offset(railH / 2, cy - railH / 2 + 0.6),
      Offset(w - railH / 2, cy - railH / 2 + 0.6),
      Paint()
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.08),
    );
    // additive bloom rising off the filled channel (∝ value).
    if (value > 0.005 && lit > 0.01) {
      canvas.drawLine(
        Offset(_inset, cy),
        Offset(tx, cy),
        Paint()
          ..strokeWidth = railH * 0.9
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 + 6 * lit)
          ..color = TTTune.gold.withValues(alpha: 0.26 * lit),
      );
    }

    // ── The glossy-glass GOLD KNOB. ──
    final thumb = Offset(tx, cy);
    const R = _knobR;
    if (lit > 0.01) {
      canvas.drawCircle(
        thumb,
        14 + 12 * lit,
        Paint()
          ..blendMode = BlendMode.plus
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
          ..color = TTTune.gold.withValues(alpha: 0.18 + 0.28 * lit),
      );
    }
    canvas.drawCircle(
      thumb.translate(0, R * 0.16),
      R,
      Paint()
        ..color = const Color(0xFF03060F).withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, R * 0.30),
    );
    canvas.drawCircle(
      thumb,
      R,
      Paint()
        ..shader = ui.Gradient.radial(
          thumb.translate(-R * 0.35, -R * 0.45),
          R * 1.35,
          const [Color(0xFFFFF3D8), Color(0xFFFFE9B8), Color(0xFFF5C451), Color(0xFFB7841F)],
          const [0.0, 0.34, 0.74, 1.0],
        ),
    );
    canvas.drawCircle(
      thumb.translate(-R * 0.32, -R * 0.34),
      R * 0.30,
      Paint()..color = Colors.white.withValues(alpha: 0.65),
    );
    canvas.drawCircle(
      thumb,
      R,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..shader = ui.Gradient.linear(
          Offset(0, thumb.dy - R),
          Offset(0, thumb.dy + R),
          [
            TTTune.goldHot.withValues(alpha: enabled ? 0.95 : 0.5),
            TTTune.goldDeep.withValues(alpha: enabled ? 0.70 : 0.4),
          ],
        ),
    );
    // hot core — a small bright centre so the knob reads as a lit gold bead.
    canvas.drawCircle(
      thumb,
      R * 0.34,
      Paint()
        ..blendMode = enabled ? BlendMode.plus : BlendMode.srcOver
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5)
        ..color = TTTune.goldHot.withValues(alpha: enabled ? (0.5 + 0.4 * lit) : 0.4),
    );
  }

  @override
  bool shouldRepaint(_SliderPainter old) => old.value != value || old.enabled != enabled;
}
