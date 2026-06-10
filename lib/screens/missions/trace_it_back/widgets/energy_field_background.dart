// The energy-field background (screen-polish spec §1) — a deep cool gradient that
// RECEDES so the warm chain blooms against it, a whisper-faint circuit texture
// (the same motif as the card guilloché, tying the product together), and a
// vignette darkest where the hero sits. No starfield: its bright dots would
// compete with the glow on a screen whose whole point is light.

import 'dart:math' as math;

import 'package:flutter/material.dart';

class EnergyFieldBackground extends StatelessWidget {
  const EnergyFieldBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.25, -0.05),
                radius: 1.1,
                colors: [Color(0xFF161D3A), Color(0xFF0B1026), Color(0xFF070A1C)],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(painter: _CircuitTexturePainter()),
        ),
        // Vignette — darken the edges (and the sides especially) so the lit
        // central column reads as a stage. Deeper now the hero owns the screen.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.95,
                colors: [Color(0x00000000), Color(0x44050712), Color(0xAA040610)],
                stops: [0.42, 0.74, 1.0],
              ),
            ),
          ),
        ),
        // A subtle vertical column glow seat so the chain sits in a soft light well.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xAA040610),
                  Colors.transparent,
                  Colors.transparent,
                  const Color(0xAA040610),
                ],
                stops: const [0.0, 0.22, 0.78, 1.0],
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
        canvas.drawCircle(Offset(x, cy), 1.6, node);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CircuitTexturePainter old) => false;
}
