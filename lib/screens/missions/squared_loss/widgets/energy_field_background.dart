// The energy-field background for Squared Loss (PRD §7), 10x rebuild — a deep cool
// gradient that RECEDES so the warm wire blooms against it, a whisper-faint circuit
// texture, and a DEEP vignette darkest behind the DIAGONAL MIDSPAN (where the hero
// sits). Two stacked wells (a wide vignette + a tighter core) deepen the near-black
// right under the span so the hot wire reads as a stage. Self-contained; the shared
// file is never touched.

import 'dart:math' as math;

import 'package:flutter/material.dart';

class EnergyFieldBackground extends StatelessWidget {
  const EnergyFieldBackground({super.key});

  // The diagonal midspan sag sits a touch below screen centre (left anchor 0.54·H,
  // right anchor 0.26·H → midspan straight y ≈ 0.40·H + sag ≈ 0.48·H). In stage-
  // local alignment that is ≈ -0.04; we bias the wells just above centre.
  static const Alignment _heroFocus = Alignment(0.0, -0.06);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base cool field — a faint indigo lift up top falling to near-black.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF161D3A), Color(0xFF0B1026), Color(0xFF070A1C)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(painter: _CircuitTexturePainter()),
        ),
        // Wide vignette — darken the field toward the edges so the lit wire reads
        // as a stage; darkest behind the diagonal midspan.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: _heroFocus,
                radius: 1.15,
                colors: [Color(0x00000000), Color(0x44050712), Color(0xAA040610)],
                stops: [0.40, 0.74, 1.0],
              ),
            ),
          ),
        ),
        // A tighter near-black core well right under the midspan so the hot wire's
        // bloom punches against the deepest dark.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: _heroFocus,
                radius: 0.6,
                colors: [Color(0x9904060E), Color(0x0004060E)],
                stops: [0.0, 1.0],
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
      ..color = const Color(0xFF6FA8FF).withValues(alpha: 0.045);
    final node = Paint()..color = const Color(0xFF6FA8FF).withValues(alpha: 0.05);
    final rng = math.Random(13);
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
