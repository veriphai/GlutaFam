// The energy-field background for The Transformer — a copy-adapt of the shipped
// static dark vignette variant (house style, §7): a deep cool gradient that
// RECEDES so the warm core blooms against it, a whisper-faint circuit texture, and
// a vignette darkest where the hero core sits (centre-left, per the layout). No
// starfield — its bright dots would compete with the additive amber glow.

import 'dart:math' as math;

import 'package:flutter/material.dart';

class EnergyFieldBackground extends StatelessWidget {
  const EnergyFieldBackground({super.key});

  @override
  Widget build(BuildContext context) {
    // The core sits at (0.46w, 0.49h) → roughly centre, a touch left. Every gradient
    // is anchored on (-0.08, -0.02) so the hero sits in its own deep light-well.
    return Stack(
      children: const [
        // Base — near-black #070A1C with a faint indigo lift toward the core.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.08, -0.02), // toward the core (centre-left)
                radius: 1.15,
                colors: [Color(0xFF18203F), Color(0xFF0B1026), Color(0xFF070A1C)],
                stops: [0.0, 0.52, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _CircuitTexturePainter())),
        // A deeper light-well right BEHIND THE CORE — a soft cool-indigo lift so the
        // hero (and its amber bloom) sit in their own pool against the deep field.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.08, -0.02),
                radius: 0.62,
                colors: [Color(0x161E2A55), Color(0x00000000)],
                stops: [0.0, 1.0],
              ),
            ),
          ),
        ),
        // Vignette — darkest at the edges so the lit core reads as a stage. Deepened
        // for a more premium light-well behind the hero.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.08, -0.02),
                radius: 1.02,
                colors: [Color(0x00000000), Color(0x55050712), Color(0xBB030509)],
                stops: [0.40, 0.72, 1.0],
              ),
            ),
          ),
        ),
        // Top/bottom falloff so the central staging reads as a column of light.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x88040610),
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xAA030509),
                ],
                stops: [0.0, 0.22, 0.74, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CircuitTexturePainter extends CustomPainter {
  const _CircuitTexturePainter();

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
