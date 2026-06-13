// MAP LAYER — the receding 1880s landscape the hero line crosses "across the
// country". PREMIUM SUBTLE TERRAIN (PRD §7): faint rolling ridge contours, far
// recessive ridgeline silhouettes near the horizon (a sense of distance), and a
// winding river — ALL low-alpha (≤6%) so the route stays the unmistakable hero.
// Plus the mono 'THE 1880s' era tag pinned top-left (read-only chrome, visible from
// intro through both runs) and 16–22 ambient motes claiming the dark. The whole layer
// dims as the bridge rises (controller.sceneDim → map to 25%).

import 'dart:math' as math;

import 'package:flame/components.dart' show Component;
import 'package:flutter/material.dart';

import '../../config/woc_tuning.dart';
import '../../state/woc_controller.dart';

class MapLayer extends Component {
  MapLayer(this.c);
  final WocController c;

  final math.Random _rng = math.Random(73);
  final List<_Mote> _motes = [];
  final List<_Ridge> _ridges = [];
  final List<_FarRidge> _farRidges = [];

  @override
  void update(double dt) {
    if (c.stageSize.isEmpty) return;
    if (_motes.isEmpty) {
      for (var i = 0; i < WocTune.moteCount; i++) {
        _motes.add(_Mote(
          _rng.nextDouble(),
          _rng.nextDouble(),
          0.2 + _rng.nextDouble() * 0.5,
          0.4 + _rng.nextDouble() * 0.9,
        ));
      }
      // Rolling ridge contours across the lower-mid map (the ground the line crosses).
      for (var i = 0; i < WocTune.terrainRidgeCount; i++) {
        _ridges.add(_Ridge(
          0.40 + i * 0.085 + _rng.nextDouble() * 0.03,
          0.6 + _rng.nextDouble() * 0.7,
          _rng.nextDouble() * math.pi * 2,
          0.012 + _rng.nextDouble() * 0.012,
        ));
      }
      // Far recessive ridgeline silhouettes near the horizon (distance: "across the
      // country"). Two layered ranges, the further one fainter + flatter.
      _farRidges.add(_FarRidge(0.285, 0.030, 2.0, 0.7, 0.55));
      _farRidges.add(_FarRidge(0.315, 0.022, 3.1, 1.9, 1.0));
    }
    final spd = c.reducedMotion ? 0.25 : 1.0;
    for (final m in _motes) {
      m.y -= dt * 0.012 * m.speed * spd;
      m.x += dt * 0.004 * math.sin(c.pulsePhase * m.speed + m.phase) * spd;
      if (m.y < -0.02) {
        m.y = 1.02;
        m.x = _rng.nextDouble();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    final w = c.stageSize.width, h = c.stageSize.height;
    final reveal = c.mapReveal;
    if (reveal <= 0.01) return;
    final dim = 1 - c.sceneDim; // 1 normal → 0.25 during the bridge

    // ── Far recessive ridgelines near the horizon (a sense of distance) ───────
    for (final fr in _farRidges) {
      final path = Path();
      final baseY = fr.y * h;
      path.moveTo(0, baseY);
      for (double x = 0; x <= w; x += w * 0.05) {
        final yy = baseY -
            (math.sin(x / w * math.pi * fr.freq + fr.phase).abs()) * h * fr.amp;
        path.lineTo(x, yy);
      }
      path.lineTo(w, baseY + h * 0.04);
      path.lineTo(0, baseY + h * 0.04);
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = WocTune.terrain
              .withValues(alpha: WocTune.farRidgeAlpha * fr.alpha * reveal * dim)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    // ── Rolling ridge contours (faint, ≤6% alpha) ─────────────────────────────
    final ridgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.011
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    for (final r in _ridges) {
      final path = Path();
      final baseY = r.y * h;
      path.moveTo(0, baseY);
      for (double x = 0; x <= w; x += w * 0.06) {
        final yy = baseY + math.sin(x / w * math.pi * 2 * r.freq + r.phase) * h * r.amp;
        path.lineTo(x, yy);
      }
      canvas.drawPath(
        path,
        ridgePaint..color = WocTune.terrain.withValues(alpha: WocTune.terrainRidgeAlpha * reveal * dim),
      );
    }

    // ── A winding river crossing the map (≤6% alpha) ──────────────────────────
    final river = Path()
      ..moveTo(w * 0.02, h * 0.60)
      ..cubicTo(w * 0.26, h * 0.50, w * 0.40, h * 0.68, w * 0.58, h * 0.58)
      ..cubicTo(w * 0.74, h * 0.50, w * 0.86, h * 0.62, w * 1.0, h * 0.55);
    // River glow then bright thread (still ≤6%) so it reads as water, not a scratch.
    canvas.drawPath(
      river,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.022
        ..strokeCap = StrokeCap.round
        ..color = WocTune.river.withValues(alpha: WocTune.riverAlpha * reveal * dim)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      river,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.007
        ..strokeCap = StrokeCap.round
        ..color = WocTune.river.withValues(alpha: WocTune.riverAlpha * 0.8 * reveal * dim)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // ── Ambient motes ─────────────────────────────────────────────────────────
    final moteBase = Paint()..color = Colors.white;
    for (final m in _motes) {
      final a = 0.06 * m.speed * reveal * dim;
      if (a <= 0.002) continue;
      canvas.drawCircle(
        Offset(m.x * w, m.y * h),
        m.size * 1.2,
        moteBase..color = Colors.white.withValues(alpha: a),
      );
    }
    // (The persistent 'THE 1880s' era tag was removed — the era now lives only in the
    // war reveal's story, not as standing chrome.)
  }
}

class _Mote {
  _Mote(this.x, this.y, this.size, this.speed) : phase = x * 6.0;
  double x, y;
  final double size;
  final double speed;
  final double phase;
}

class _Ridge {
  _Ridge(this.y, this.freq, this.phase, this.amp);
  final double y;
  final double freq;
  final double phase;
  final double amp;
}

class _FarRidge {
  _FarRidge(this.y, this.amp, this.freq, this.phase, this.alpha);
  final double y; // baseline as fraction of h (near the horizon)
  final double amp; // peak height as fraction of h
  final double freq;
  final double phase;
  final double alpha; // recessive scale (further = fainter)
}
