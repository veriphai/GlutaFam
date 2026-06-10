// Helix — the de-extinction companion. No sprite art exists yet, so this draws a
// clean, mood-expressive PLACEHOLDER (a little "recipe-keeper" with a double-helix
// crest) and is wired to swap to real art later with zero call-site changes:
// it first tries assets/images/helix/helix_<mood>.png and falls back to the
// drawn placeholder via errorBuilder. When art lands: drop the PNGs in, declare
// assets/images/helix/ in pubspec.yaml, and do a full re-run.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/creature_tuning.dart';
import '../engine/helix_beat_engine.dart';

class HelixAvatar extends StatelessWidget {
  const HelixAvatar({super.key, required this.mood, this.size = 64});

  final Mood mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/helix/helix_${mood.name}.png',
        fit: BoxFit.contain,
        gaplessPlayback: true,
        // No art yet → fall back to the drawn placeholder (and on web the asset
        // manifest 404s until a full re-run, which this also covers).
        errorBuilder: (_, __, ___) => CustomPaint(painter: _HelixPainter(mood)),
      ),
    );
  }
}

Color _moodColor(Mood m) {
  switch (m) {
    case Mood.curious:
      return RC.lifeGreen;
    case Mood.surprised:
      return RC.lifeAmber;
    case Mood.idea:
      return RC.lifeAmber;
    case Mood.celebrating:
      return RC.lifeGreen;
    case Mood.confused:
      return const Color(0xFF9AA6C8);
  }
}

class _HelixPainter extends CustomPainter {
  _HelixPainter(this.mood);
  final Mood mood;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final c = Offset(w / 2, h / 2);
    final accent = _moodColor(mood);

    // Soft glow.
    canvas.drawCircle(c, w * 0.46, Paint()
      ..color = accent.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Body — a rounded "capsule" head.
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: w * 0.74, height: h * 0.74),
      Radius.circular(w * 0.3),
    );
    canvas.drawRRect(bodyRect, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF18233F), Color(0xFF0E1730)],
      ).createShader(bodyRect.outerRect));
    canvas.drawRRect(bodyRect, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = accent.withValues(alpha: 0.85));

    // Double-helix crest (the "recipe keeper" mark) at the top.
    _helixCrest(canvas, Offset(c.dx, h * 0.2), w * 0.22, h * 0.18, accent);

    // Face.
    final eyeY = c.dy + h * 0.02;
    final eyeDX = w * 0.16;
    final eyeR = w * 0.072;
    void eye(double cx, {double open = 1}) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, eyeY), width: eyeR * 2, height: eyeR * 2 * open),
        Paint()..color = Colors.white,
      );
      if (open > 0.5) {
        canvas.drawCircle(Offset(cx, eyeY), eyeR * 0.55, Paint()..color = const Color(0xFF11182B));
      }
    }

    eye(c.dx - eyeDX);
    eye(c.dx + eyeDX);

    // Mouth per mood.
    final mouth = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = accent;
    final my = c.dy + h * 0.2;
    switch (mood) {
      case Mood.surprised:
        canvas.drawCircle(Offset(c.dx, my), w * 0.05, Paint()..color = accent);
      case Mood.celebrating:
        canvas.drawArc(Rect.fromCenter(center: Offset(c.dx, my - h * 0.04), width: w * 0.34, height: h * 0.26),
            0.1 * math.pi, 0.8 * math.pi, false, mouth..strokeWidth = 3);
      case Mood.idea:
        canvas.drawArc(Rect.fromCenter(center: Offset(c.dx, my - h * 0.02), width: w * 0.28, height: h * 0.18),
            0.15 * math.pi, 0.7 * math.pi, false, mouth);
      case Mood.confused:
        final p = Path()..moveTo(c.dx - w * 0.12, my);
        for (var i = 1; i <= 4; i++) {
          p.lineTo(c.dx - w * 0.12 + i * w * 0.06, my + (i.isEven ? -1 : 1) * h * 0.02);
        }
        canvas.drawPath(p, mouth);
      case Mood.curious:
        canvas.drawArc(Rect.fromCenter(center: Offset(c.dx, my - h * 0.01), width: w * 0.22, height: h * 0.12),
            0.15 * math.pi, 0.7 * math.pi, false, mouth);
    }
  }

  void _helixCrest(Canvas canvas, Offset center, double halfW, double halfH, Color accent) {
    final strand = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = accent;
    final a = Path(), b = Path();
    const steps = 10;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final y = center.dy - halfH + 2 * halfH * t;
      final x1 = center.dx + math.sin(t * 2 * math.pi) * halfW;
      final x2 = center.dx - math.sin(t * 2 * math.pi) * halfW;
      if (i == 0) {
        a.moveTo(x1, y);
        b.moveTo(x2, y);
      } else {
        a.lineTo(x1, y);
        b.lineTo(x2, y);
      }
    }
    canvas.drawPath(a, strand);
    canvas.drawPath(b, strand);
    // a couple of rungs.
    for (var i = 2; i <= steps - 2; i += 3) {
      final t = i / steps;
      final y = center.dy - halfH + 2 * halfH * t;
      canvas.drawLine(
        Offset(center.dx + math.sin(t * 2 * math.pi) * halfW, y),
        Offset(center.dx - math.sin(t * 2 * math.pi) * halfW, y),
        strand..strokeWidth = 1.4,
      );
    }
  }

  @override
  bool shouldRepaint(_HelixPainter old) => old.mood != mood;
}
