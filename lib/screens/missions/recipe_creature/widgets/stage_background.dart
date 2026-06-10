// The stage backdrop (Tier 2) — a living, premium base that keeps the creature
// the hero (PRD §9): a deep gradient base, a warm "life" spotlight behind the
// creature, a very faint double-helix + cell watermark, slow drifting life-motes,
// and an edge vignette for focus. Everything is low-contrast so the creature
// always out-glows the chrome. Animated off the controller clock; frozen under
// reduced motion.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../config/creature_tuning.dart';
import '../state/recipe_creature_controller.dart';

class StageBackground extends StatelessWidget {
  const StageBackground({super.key, required this.controller});
  final RecipeCreatureController controller;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _StagePainter(controller), size: Size.infinite);
}

class _Mote {
  _Mote(this.x, this.baseY, this.r, this.speed, this.drift, this.phase, this.warm);
  final double x, baseY, r, speed, drift, phase;
  final bool warm;
}

class _StagePainter extends CustomPainter {
  _StagePainter(this.c) : super(repaint: c);
  final RecipeCreatureController c;

  // Deterministic motes (computed once).
  static final List<_Mote> _motes = List.generate(26, (i) {
    final rnd = math.Random(i * 131 + 17);
    return _Mote(
      rnd.nextDouble(), // x as a fraction
      rnd.nextDouble(), // baseY as a fraction
      0.6 + rnd.nextDouble() * 1.8, // radius px-ish (×0.001·w later)
      0.006 + rnd.nextDouble() * 0.02, // upward speed (fraction/s)
      0.2 + rnd.nextDouble() * 0.8, // horizontal drift amount
      rnd.nextDouble() * math.pi * 2, // twinkle phase
      rnd.nextBool(), // warm vs green tint
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final t = c.liveMotion ? c.clock : 0.0;
    final rect = Offset.zero & size;
    // Where the creature sits on screen (upper-center).
    final hero = Offset(w * 0.5, h * 0.36);

    // 1) Deep base gradient.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [RC.baseTop, RC.baseBottom],
        ).createShader(rect),
    );

    // 2) Faint cell / helix watermark, slowly drifting (very low opacity).
    _watermark(canvas, size, t);

    // 3) Warm "life" spotlight behind the hero (subtle pulse).
    final pulse = 0.5 + 0.5 * math.sin(t * 0.6);
    canvas.drawCircle(
      hero,
      w * (0.66 + 0.02 * pulse),
      Paint()
        ..shader = ui.Gradient.radial(hero, w * 0.66, [
          const Color(0xFF1C3A2E).withValues(alpha: 0.55 + 0.08 * pulse),
          const Color(0x0014261C),
        ], [0.0, 1.0]),
    );

    // 4) Drifting life-motes.
    for (final m in _motes) {
      final y = ((m.baseY - t * m.speed) % 1.0 + 1.0) % 1.0;
      final x = (m.x + math.sin(t * 0.3 + m.phase) * 0.02 * m.drift) % 1.0;
      final twinkle = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * 1.4 + m.phase));
      final col = (m.warm ? RC.lifeAmber : RC.lifeGreen).withValues(alpha: 0.18 * twinkle);
      final pos = Offset(x * w, y * h);
      final r = m.r * w * 0.0024 * (0.8 + 0.4 * twinkle) + 0.8;
      canvas.drawCircle(pos, r * 2.4, Paint()
        ..color = col.withValues(alpha: col.a * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawCircle(pos, r, Paint()..color = col..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
    }

    // 5) Edge vignette for focus.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * 0.5, h * 0.42),
          h * 0.7,
          [const Color(0x00000000), const Color(0x6603060E)],
          [0.6, 1.0],
        ),
    );
  }

  void _watermark(Canvas canvas, Size size, double t) {
    final w = size.width, h = size.height;
    final drift = math.sin(t * 0.08) * 8;

    // A few large soft "cells" — biological bokeh, barely there.
    final cells = [
      Offset(w * 0.16, h * 0.20),
      Offset(w * 0.86, h * 0.30),
      Offset(w * 0.22, h * 0.74),
      Offset(w * 0.80, h * 0.82),
    ];
    for (var i = 0; i < cells.length; i++) {
      final cc = cells[i] + Offset(0, drift * (i.isEven ? 1 : -1));
      canvas.drawCircle(
        cc,
        w * 0.18,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.022),
      );
      canvas.drawCircle(cc, w * 0.05, Paint()..color = Colors.white.withValues(alpha: 0.015));
    }

    // A faint tall double-helix down the right edge.
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = RC.lifeGreen.withValues(alpha: 0.04);
    final cx = w * 0.92;
    final amp = w * 0.05;
    for (final dir in [1.0, -1.0]) {
      final path = Path();
      for (var i = 0; i <= 60; i++) {
        final f = i / 60;
        final y = h * f;
        final x = cx + dir * math.sin(f * 7 + t * 0.1) * amp;
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_StagePainter old) => false; // repaint via controller
}
