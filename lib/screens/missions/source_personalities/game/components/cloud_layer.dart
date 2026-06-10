// Clouds — soft, slow-drifting cloud banks that catch warm light at golden hour
// and fade to faint grey at night. Pure atmosphere; this is a big part of what
// makes the sky feel alive and premium rather than a flat gradient.

import 'dart:math' as math;

import 'package:flame/components.dart' show Component;
import 'package:flutter/material.dart';

import '../../state/source_personalities_controller.dart';

class CloudLayer extends Component {
  CloudLayer(this.c, {this.reducedMotion = false});
  final SourcePersonalitiesController c;
  final bool reducedMotion;

  late final List<_Cloud> _clouds = _make();

  List<_Cloud> _make() {
    final rng = math.Random(23);
    return List.generate(6, (i) {
      return _Cloud(
        rng.nextDouble(),
        0.08 + rng.nextDouble() * 0.34, // upper sky band
        0.7 + rng.nextDouble() * 0.9, // scale
        0.004 + rng.nextDouble() * 0.01, // drift speed (parallax)
        rng.nextInt(3), // puff arrangement
      );
    });
  }

  @override
  void update(double dt) {
    if (reducedMotion) return;
    for (final cl in _clouds) {
      cl.x += cl.drift * dt;
      if (cl.x > 1.2) cl.x -= 1.4;
    }
  }

  @override
  void render(Canvas canvas) {
    final size = c.stageSize;
    if (size.isEmpty) return;
    final w = size.width, hz = c.horizonY;
    final alt = c.sunAltitude;
    // Clouds are bright by day, dim/sparse at night.
    final dayVis = (0.25 + alt * 0.75).clamp(0.0, 1.0);
    // Golden underside near sunrise/sunset.
    final golden = alt > 0.001 ? (1 - (alt * 1.7).clamp(0.0, 1.0)) : 0.0;
    final base = Color.lerp(const Color(0xFF2B3656), const Color(0xFFEAF1FB), alt)!;
    final warm = const Color(0xFFFFC78C);

    for (final cl in _clouds) {
      final cx = cl.x * w;
      final cy = cl.y * hz;
      final r = w * 0.085 * cl.scale;
      final a = (0.12 + 0.34 * dayVis) * cl.scale;
      final top = Color.lerp(base, Colors.white, 0.1 + 0.2 * alt)!;
      final under = Color.lerp(base, warm, golden * 0.7)!;
      _puff(canvas, Offset(cx, cy), r, cl.arrangement, top, under, a);
    }
  }

  void _puff(Canvas canvas, Offset c2, double r, int arr, Color top, Color under, double a) {
    // A cluster of overlapping soft circles; the lower ones tinted (underside).
    final offsets = _arrangements[arr];
    for (final o in offsets) {
      final pos = c2 + Offset(o.dx * r, o.dy * r * 0.6);
      final rr = r * o.r;
      final tint = o.dy > 0 ? under : top;
      canvas.drawCircle(
        pos, rr,
        Paint()
          ..color = tint.withValues(alpha: a.clamp(0.0, 1.0))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, rr * 0.55),
      );
    }
  }

  static final List<List<_Puff>> _arrangements = [
    [_Puff(-1.0, 0.1, 0.7), _Puff(-0.3, -0.2, 1.0), _Puff(0.5, -0.1, 0.85), _Puff(1.1, 0.15, 0.6)],
    [_Puff(-0.8, 0.0, 0.8), _Puff(0.0, -0.25, 1.0), _Puff(0.8, 0.05, 0.75)],
    [_Puff(-1.2, 0.15, 0.6), _Puff(-0.5, -0.1, 0.9), _Puff(0.2, -0.2, 1.0), _Puff(0.9, -0.05, 0.8), _Puff(1.5, 0.2, 0.5)],
  ];
}

class _Cloud {
  _Cloud(this.x, this.y, this.scale, this.drift, this.arrangement);
  double x;
  final double y, scale, drift;
  final int arrangement;
}

class _Puff {
  const _Puff(this.dx, this.dy, this.r);
  final double dx, dy, r;
}
