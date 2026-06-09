// Programmatic scan/GPS beam (the playbook's "programmatic beam" pattern): a
// cone drawn in Flutter from a SOURCE point (the docked satellite) widening to a
// TARGET point (the boat / fire), so it visibly emanates from the satellite
// instead of being a free-floating sprite. Multi-pass glow: soft outer halo →
// gradient body → bright core line → a pulsing hit-glow at the target.
//
// Driven by a single 0..1 [progress]: the cone GROWS from the satellite to the
// target over the first third, then holds with a gentle shimmer, and fades via
// an envelope. Composited additively (BlendMode.plus) over the dark card.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class BeamConePainter extends CustomPainter {
  BeamConePainter({
    required this.source,
    required this.target,
    required this.progress,
    required this.color,
    this.targetHalfWidth = 46,
  });

  /// Apex of the cone (where the satellite sits), in scene pixels.
  final Offset source;

  /// Where the beam points / lands, in scene pixels.
  final Offset target;

  /// 0..1 lifetime.
  final double progress;
  final Color color;

  /// Half-width of the cone at the target end (pixels).
  final double targetHalfWidth;

  double get _envelope {
    final t = progress;
    if (t < 0.12) return (t / 0.12).clamp(0.0, 1.0);
    if (t > 0.9) return (1 - (t - 0.9) / 0.1).clamp(0.0, 1.0);
    return 1.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final env = _envelope;
    if (env <= 0.001) return;

    final dir = target - source;
    final len = dir.distance;
    if (len < 1) return;

    final n = dir / len; // unit direction
    final perp = Offset(-n.dy, n.dx);

    // Grow the beam tip from the satellite to the target over the first third.
    final grow = Curves.easeOutCubic.transform((progress / 0.34).clamp(0.0, 1.0));
    final tip = Offset.lerp(source, target, grow)!;
    final curHalf = ui.lerpDouble(4, targetHalfWidth, grow)!;
    final shimmer = 0.86 + 0.14 * math.sin(progress * 2 * math.pi * 3);

    const apexHalf = 5.0;
    Path cone(double scale) => Path()
      ..moveTo((source + perp * apexHalf * scale).dx, (source + perp * apexHalf * scale).dy)
      ..lineTo((source - perp * apexHalf * scale).dx, (source - perp * apexHalf * scale).dy)
      ..lineTo((tip - perp * curHalf * scale).dx, (tip - perp * curHalf * scale).dy)
      ..lineTo((tip + perp * curHalf * scale).dx, (tip + perp * curHalf * scale).dy)
      ..close();

    // Pass 1 — soft outer halo.
    canvas.drawPath(
      cone(1.35),
      Paint()
        ..blendMode = BlendMode.plus
        ..color = color.withValues(alpha: 0.16 * env)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // Pass 2 — gradient body (bright at the satellite, fading to the target).
    canvas.drawPath(
      cone(1.0),
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.linear(source, tip, [
          color.withValues(alpha: 0.55 * env * shimmer),
          color.withValues(alpha: 0.12 * env),
        ])
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Pass 3 — bright core line.
    canvas.drawLine(
      source,
      tip,
      Paint()
        ..blendMode = BlendMode.plus
        ..color = Color.lerp(color, Colors.white, 0.6)!.withValues(alpha: 0.85 * env * shimmer)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Pass 4 — pulsing hit-glow at the target (only once the beam reaches it).
    if (grow > 0.85) {
      final hit = 0.6 + 0.4 * math.sin(progress * 2 * math.pi * 2.5);
      canvas.drawCircle(
        tip,
        curHalf * 0.55,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = color.withValues(alpha: 0.5 * env * hit)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + 6 * hit),
      );
    }
  }

  @override
  bool shouldRepaint(covariant BeamConePainter old) =>
      old.progress != progress || old.source != source || old.target != target || old.color != color;
}
