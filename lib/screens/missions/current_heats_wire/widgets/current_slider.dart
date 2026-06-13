// The CURRENT slider — the one essential control (the only manipulated variable).
// Detentless (NO 1×/2×/3× stops — that would pre-spoil 2.4's square), a warm thumb
// glow whose intensity rides the value, a mono CURRENT label, and a locked/dimmed
// state for beat B (slider pinned at 0, deliberately visible the whole rub beat).
// selectionClick per 0.1 crossing is fired by the controller (onSliderChanged).

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/heat_wire_beats.dart';
import '../state/heat_wire_controller.dart';

class CurrentSlider extends StatefulWidget {
  const CurrentSlider({super.key, required this.controller});

  final HeatWireController controller;

  @override
  State<CurrentSlider> createState() => _CurrentSliderState();
}

class _CurrentSliderState extends State<CurrentSlider> {
  double _value = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.sliderEnabled.addListener(_onLock);
  }

  void _onLock() {
    // When the controller locks the slider (beat B), animate the visible thumb to 0.
    if (!widget.controller.sliderEnabled.value && _value != 0) {
      setState(() => _value = 0);
    }
  }

  @override
  void dispose() {
    widget.controller.sliderEnabled.removeListener(_onLock);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.controller.sliderEnabled,
      builder: (context, enabled, _) {
        final opacity = enabled ? 1.0 : 0.4;
        return Opacity(
          opacity: opacity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                HWCopy.sliderLabel,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 4),
              _Track(
                value: enabled ? _value : 0,
                enabled: enabled,
                controller: widget.controller, // for thumb glow (wireTemp) + repaint
                onChanged: enabled
                    ? (v) {
                        setState(() => _value = v);
                        widget.controller.onSliderChanged(v);
                      }
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({
    required this.value,
    required this.enabled,
    required this.controller,
    required this.onChanged,
  });

  final double value;
  final bool enabled;
  final HeatWireController controller; // wireTemp drives the thumb glow + repaint
  final ValueChanged<double>? onChanged;

  // Thumb inset (px) — the painter clamps the thumb centre to [inset, w-inset];
  // the pointer→value mapping must use the SAME inset so the thumb tracks the
  // touch all the way to both rails and the last few px of travel still register
  // (so 'sustain >= 0.75' and 'drop <= 0.15' land cleanly at the extremes). Matches
  // the larger glass knob radius so the knob never clips past the ends.
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
          final v = usable <= 0
              ? 0.0
              : ((localPos.dx - _thumbInset) / usable).clamp(0.0, 1.0);
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
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) => CustomPaint(
                painter: _SliderPainter(
                  value: value,
                  enabled: enabled,
                  heat: controller.wireTemp,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SliderPainter extends CustomPainter {
  _SliderPainter({required this.value, required this.enabled, required this.heat});

  final double value;
  final bool enabled;
  final double heat; // controller.wireTemp — the glow sustains with the real wire

  // Must match _Track._thumbInset so the painted thumb tracks the touch mapping.
  static const double _inset = 15.0;
  static const double _knobR = 15.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cy = h / 2;
    // immediate response on touch (value) but sustained by the real heat.
    final lit = math.max(value * 0.45, heat).clamp(0.0, 1.0);

    const railH = 11.0;
    final railRect = Rect.fromCenter(center: Offset(w / 2, cy), width: w, height: railH);
    final rail = RRect.fromRectAndRadius(railRect, const Radius.circular(railH / 2));

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
      Offset(0, cy - railH / 2 + 1.2),
      Offset(w, cy - railH / 2 + 1.2),
      Paint()
        ..strokeWidth = 2.0
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    // ── warm fill glowing from INSIDE the groove.
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
              const Color(0xFFFFE9B8).withValues(alpha: 0.85),
              const Color(0xFFFF7A2E).withValues(alpha: 0.95),
            ],
          ),
      );
    }
    canvas.restore();
    // top gloss lip (the groove's near edge catching the key light).
    canvas.drawLine(
      Offset(railH / 2, cy - railH / 2 + 0.6),
      Offset(w - railH / 2, cy - railH / 2 + 0.6),
      Paint()
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.08),
    );
    // additive bloom rising off the filled channel (∝ heat).
    if (value > 0.005 && lit > 0.01) {
      canvas.drawLine(
        Offset(_inset, cy),
        Offset(tx, cy),
        Paint()
          ..strokeWidth = railH * 0.9
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 + 6 * lit)
          ..color = const Color(0xFFFF7A2E).withValues(alpha: 0.28 * lit),
      );
    }

    // ── The glossy-glass HEAT KNOB — a warm port of 2.1's piston (radial gloss). ──
    final thumb = Offset(tx, cy);
    const R = _knobR;
    // 1) under-glow halo (∝ heat).
    if (lit > 0.01) {
      canvas.drawCircle(
        thumb,
        14 + 12 * lit,
        Paint()
          ..blendMode = BlendMode.plus
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
          ..color = const Color(0xFFFF7A2E).withValues(alpha: 0.20 + 0.30 * lit),
      );
    }
    // 2) drop shadow — the knob sits proud of the groove.
    canvas.drawCircle(
      thumb.translate(0, R * 0.16),
      R,
      Paint()
        ..color = const Color(0xFF03060F).withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, R * 0.30),
    );
    // 3) glass body — radial 4-stop warm (bright up-left → deep lower-right).
    canvas.drawCircle(
      thumb,
      R,
      Paint()
        ..shader = ui.Gradient.radial(
          thumb.translate(-R * 0.35, -R * 0.45),
          R * 1.35,
          const [Color(0xFFFFE9B8), Color(0xFFFFD27A), Color(0xFFFF9A4E), Color(0xFFC7521A)],
          const [0.0, 0.34, 0.74, 1.0],
        ),
    );
    // 4) crisp specular cap (the gloss-seller), up-left of centre.
    canvas.drawCircle(
      thumb.translate(-R * 0.32, -R * 0.34),
      R * 0.30,
      Paint()..color = Colors.white.withValues(alpha: 0.65),
    );
    // 5) rim — vertical 2-stop (bright top → deep base) so the form rounds.
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
            const Color(0xFFFFE9B8).withValues(alpha: enabled ? 0.95 : 0.5),
            const Color(0xFF7A2E10).withValues(alpha: enabled ? 0.70 : 0.4),
          ],
        ),
    );
    // 6) hot ember core — grows + whitens with heat.
    canvas.drawCircle(
      thumb,
      R * 0.34 * (0.5 + 0.5 * lit),
      Paint()
        ..blendMode = enabled ? BlendMode.plus : BlendMode.srcOver
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5)
        ..color = const Color(0xFFFFF1D8).withValues(alpha: enabled ? (0.5 + 0.4 * lit) : 0.4),
    );
  }

  @override
  bool shouldRepaint(_SliderPainter old) =>
      old.value != value || old.enabled != enabled || old.heat != heat;
}
