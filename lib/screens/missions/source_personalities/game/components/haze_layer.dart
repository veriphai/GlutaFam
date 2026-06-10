// Haze — the "missing smoke" made real (PRD §4.4, §7), premium pass. Instead of
// a flat full-screen brown wash, a LOCALIZED smog band that hangs over the
// rooftops — thickest at roof height, thinning toward the ground and fading up
// into clean sky — with layered drifting puffs concentrated in that band. Its
// density reads controller.pollution. This IS "dirty"; never a label. Drawn in
// front of the buildings (smog sits between viewer and town). Normal alpha.

import 'dart:math' as math;

import 'package:flame/components.dart' show Component;
import 'package:flutter/material.dart';

import '../../state/source_personalities_controller.dart';

const Color _smog = Color(0xFF736A54); // dirty brown-grey

class HazeLayer extends Component {
  HazeLayer(this.c, {this.reducedMotion = false});
  final SourcePersonalitiesController c;
  final bool reducedMotion;

  double _clock = 0;
  late final List<_Blob> _blobs = _make();

  List<_Blob> _make() {
    final rng = math.Random(53);
    final n = reducedMotion ? 12 : 22;
    return List.generate(n, (i) {
      return _Blob(
        rng.nextDouble(),
        rng.nextDouble(), // band-relative height 0..1 (0 = rooftop top)
        0.5 + rng.nextDouble() * 1.0,
        (rng.nextDouble() * 2 - 1) * (reducedMotion ? 0.008 : 0.022),
      );
    });
  }

  @override
  void update(double dt) {
    _clock += dt;
    if (reducedMotion) return;
    for (final b in _blobs) {
      b.x += b.drift * dt;
      if (b.x > 1.15) b.x -= 1.3;
      if (b.x < -0.15) b.x += 1.3;
    }
  }

  @override
  void render(Canvas canvas) {
    final size = c.stageSize;
    if (size.isEmpty) return;
    final p = c.pollution.clamp(0.0, 1.0);
    if (p < 0.02) return;

    final w = size.width;
    final townTop = c.townTopY;
    final horizon = c.horizonY;
    final bandTop = townTop - (horizon - townTop) * 0.18;
    final bandBot = horizon + (size.height - horizon) * 0.12;
    final bandH = bandBot - bandTop;

    // The smog band — peaks near rooftop level, fades up into clean sky + down
    // toward the (lower) ground.
    final rect = Rect.fromLTWH(0, bandTop, w, bandH);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _smog.withValues(alpha: 0.03 * p),
            _smog.withValues(alpha: 0.46 * p),
            _smog.withValues(alpha: 0.24 * p),
          ],
          stops: const [0.0, 0.42, 1.0],
        ).createShader(rect),
    );

    // Drifting layered puffs, concentrated in the upper band (over the rooftops).
    for (final b in _blobs) {
      final x = b.x * w;
      final by = bandTop + (0.05 + b.y * 0.55) * bandH +
          (reducedMotion ? 0 : math.sin(_clock * 0.4 + b.size) * bandH * 0.02);
      final r = w * 0.115 * b.size;
      final a = (0.05 + 0.30 * p) * b.size;
      canvas.drawCircle(
        Offset(x, by), r,
        Paint()
          ..color = _smog.withValues(alpha: a.clamp(0.0, 0.4))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.65),
      );
    }
  }
}

class _Blob {
  _Blob(this.x, this.y, this.size, this.drift);
  double x;
  final double y, size, drift;
}
