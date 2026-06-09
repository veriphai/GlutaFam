// Full-screen cosmic backdrop: a deep navy gradient, two soft radial glows,
// and a field of slowly twinkling stars. Sits behind all homepage content.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'careerTheme.dart';

class CosmicBackground extends StatefulWidget {
  const CosmicBackground({super.key});

  @override
  State<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _CosmicBackgroundState extends State<CosmicBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(42);
    _stars = List.generate(70, (_) {
      return _Star(
        Offset(rnd.nextDouble(), rnd.nextDouble()),
        rnd.nextDouble() * 1.4 + 0.5,
        rnd.nextDouble() * math.pi * 2,
        rnd.nextDouble() * 0.5 + 0.3,
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: CareerGradients.page),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _CosmicPainter(_stars, _c.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Star {
  _Star(this.pos, this.radius, this.phase, this.baseOpacity);
  final Offset pos; // normalized
  final double radius;
  final double phase;
  final double baseOpacity;
}

class _CosmicPainter extends CustomPainter {
  _CosmicPainter(this.stars, this.t);
  final List<_Star> stars;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Two ambient radial glows.
    _glow(canvas, Offset(size.width * 0.12, size.height * 0.10), size.width * 0.55,
        CareerColors.purple.withValues(alpha: 0.22));
    _glow(canvas, Offset(size.width * 0.95, size.height * 0.30), size.width * 0.5,
        CareerColors.blue.withValues(alpha: 0.16));

    // Twinkling stars.
    final paint = Paint();
    for (final s in stars) {
      final tw = (math.sin(t * 2 * math.pi + s.phase) + 1) / 2;
      paint.color = Colors.white.withValues(alpha: (s.baseOpacity * (0.4 + tw * 0.6)).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(s.pos.dx * size.width, s.pos.dy * size.height), s.radius, paint);
    }
  }

  void _glow(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_CosmicPainter old) => old.t != t;
}
