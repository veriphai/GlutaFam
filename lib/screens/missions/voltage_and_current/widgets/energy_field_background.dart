// The energy-field background — copied per the shipped pattern (trace_it_back /
// hand_crank_lamp). A deep cool gradient that RECEDES so the warm circuit loop
// blooms against it (PRD §7): near-black #070A1C base, a whisper-faint circuit
// texture (~5% alpha), and a vignette darkest where the hero sits (the lamp,
// top-centre). No starfield — bright dots would compete with the glow.
//
// This is a self-contained copy inside the activity dir (the shipped one lives in
// another module — we never modify it; we tune the vignette centre for THIS
// scene, whose hero sits high, behind the lamp).

import 'dart:math' as math;

import 'package:flutter/material.dart';

class EnergyFieldBackground extends StatelessWidget {
  const EnergyFieldBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base — near-black indigo. A subtle cool lift high on the stage (behind
        // the lamp) gives the depth feel the EP1 hero has; the field falls off to
        // a deep near-black at the edges so the warm hero blooms against it.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.70), // lifted to track the bigger lamp (top-centre)
                radius: 1.2,
                colors: [Color(0xFF18203F), Color(0xFF0B1026), Color(0xFF070A1C), Color(0xFF05060F)],
                stops: [0.0, 0.42, 0.78, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _CircuitTexturePainter())),
        // Vignette — a deeper pool so the lit loop reads as a stage, darkest
        // behind the lamp (the hero) and pulling the edges into shadow.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.62),
                radius: 1.05,
                colors: [Color(0x00000000), Color(0x4A050712), Color(0xBE040610)],
                stops: [0.36, 0.72, 1.0],
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
