// The energy-field background for AC vs DC — a copy-adapt of the shipped static
// dark vignette variant (house style, §7): a deep cool gradient that RECEDES so
// the warm core blooms against it, a whisper-faint circuit texture, and a
// vignette darkest where the hero core sits (center, per this layout). No
// starfield — its bright dots would compete with the additive amber glow.

import 'dart:math' as math;

import 'package:flutter/material.dart';

class EnergyFieldBackground extends StatelessWidget {
  const EnergyFieldBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base — near-black #070A1C with a faint indigo lift toward the core, but
        // dropping to the DEEPEST cool black right behind the hero (so the core's
        // amber blooms against the void; P2: deep vignette behind the core).
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.04), // toward the core (center)
                radius: 1.15,
                colors: [
                  Color(0xFF141B38),
                  Color(0xFF0A0F26),
                  Color(0xFF06081A),
                  Color(0xFF04050E),
                ],
                stops: [0.0, 0.42, 0.72, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _CircuitTexturePainter())),
        // Vignette — darkest at the edges so the lit core reads as a stage.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.04),
                radius: 0.98,
                colors: [Color(0x00000000), Color(0x55040610), Color(0xBB02030A)],
                stops: [0.40, 0.74, 1.0],
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
    final rng = math.Random(7);
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
