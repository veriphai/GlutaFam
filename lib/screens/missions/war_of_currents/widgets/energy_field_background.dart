// The energy-field background for War of the Currents — a near-black 1880s map
// base (#070A1C) with a deep cool gradient that RECEDES so the warm/cool hero line
// blooms against it, a whisper-faint circuit texture, and a radial vignette darkest
// ALONG the route's diagonal (bottom-left plant → top-right city). Copy-adapted from
// the shipped EnergyFieldBackground (trace_it_back) — static, reduced-motion-safe.

import 'dart:math' as math;

import 'package:flutter/material.dart';

class EnergyFieldBackground extends StatelessWidget {
  const EnergyFieldBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base — the ink map, lit faintly along the route's diagonal.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, 0.05),
                radius: 1.15,
                colors: [Color(0xFF141C3C), Color(0xFF0B1026), Color(0xFF070A1C)],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
        // A faint cool wash along the route's diagonal (bottom-left plant → top-right
        // city) so the dark feels lit where the hero line crosses — recessive.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.85, 0.85),
                end: Alignment(0.85, -0.85),
                colors: [Color(0x140F1C3A), Color(0x00000000), Color(0x120F1C3A)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _CircuitTexturePainter())),
        // Vignette — darken the edges so the lit route reads as a stage.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [Color(0x00000000), Color(0x44050712), Color(0xBB040610)],
                stops: [0.42, 0.74, 1.0],
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
      ..color = const Color(0xFF6FA8FF).withValues(alpha: 0.04);
    final node = Paint()..color = const Color(0xFF6FA8FF).withValues(alpha: 0.05);
    final rng = math.Random(28);
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
        canvas.drawCircle(Offset(x, cy), 1.5, node);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CircuitTexturePainter old) => false;
}
