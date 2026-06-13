// The static dark vignette for "Shape the Wire" — copy-adapted from
// trace_it_back's EnergyFieldBackground (read-only precedent). A deep cool
// gradient that RECEDES so the warm wire blooms against it, a whisper-faint
// circuit texture (~5% alpha), a soft cool depth aura up the column, and a
// vignette darkest behind the hero wire (centred slightly above middle, where the
// wire hangs). No starfield: bright dots would compete with the flow's glow.

import 'dart:math' as math;

import 'package:flutter/material.dart';

class ResistanceBackground extends StatelessWidget {
  const ResistanceBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.18),
                radius: 1.15,
                colors: [Color(0xFF161E3E), Color(0xFF0B1026), Color(0xFF070A1C)],
                stops: [0.0, 0.52, 1.0],
              ),
            ),
          ),
        ),
        // A soft cool DEPTH aura up the central column — recessive (cool, low
        // alpha) so the warm hero still blooms, but the stage reads less flat (P2.10).
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.05),
                radius: 0.62,
                colors: [Color(0x223A56A8), Color(0x00000000)],
                stops: [0.0, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(painter: _CircuitTexturePainter()),
        ),
        // Vignette — darken edges so the central wire reads as a lit stage.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.1),
                radius: 0.98,
                colors: [Color(0x00000000), Color(0x44050712), Color(0xAA040610)],
                stops: [0.40, 0.72, 1.0],
              ),
            ),
          ),
        ),
        // Side wells so the lit column sits in soft dark gutters.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xAA040610),
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xAA040610),
                ],
                stops: [0.0, 0.20, 0.80, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CircuitTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF6FA8FF).withValues(alpha: 0.05);
    final node = Paint()..color = const Color(0xFF6FA8FF).withValues(alpha: 0.06);
    // a few brighter "live" node pads scattered sparsely — depth without clutter.
    final litNode = Paint()
      ..color = const Color(0xFF8FC0FF).withValues(alpha: 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4);
    final rng = math.Random(11);
    const step = 64.0;
    for (double y = step; y < size.height; y += step) {
      var x = 0.0;
      var cy = y;
      final path = Path()..moveTo(0, cy);
      while (x < size.width) {
        final dx = step * (0.7 + rng.nextDouble() * 0.8);
        x += dx;
        if (rng.nextBool()) {
          cy += (rng.nextBool() ? 1 : -1) * step * 0.5;
          path.lineTo(x - dx * 0.5, cy);
        }
        path.lineTo(x, cy);
        if (rng.nextDouble() < 0.12) {
          canvas.drawCircle(Offset(x, cy), 3.0, litNode);
        }
        canvas.drawCircle(Offset(x, cy), 1.6, node);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CircuitTexturePainter old) => false;
}
