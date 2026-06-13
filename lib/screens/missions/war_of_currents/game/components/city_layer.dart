// CITY LAYER — the journey's PAYOFF READOUT (not a meter; the city IS the meter).
// A DIMENSIONAL building cluster (the 2.5 town craft, ported): each building has a
// vertical body gradient, a lit left edge, and a shaded right flank, and its walls
// WARM as the city lights. The window grid is the readout:
//   • DC: a feeble flicker that never reaches full — then HARD 0 the failure frame
//     (no fade tail; controller.cityLit is forced to 0 in that same frame) — the
//     city is a feeble flicker that HARD-DIES.
//   • AC: a window-by-window SWEEP (900ms) igniting to full + a warm #FFE9B8 bloom —
//     the GLORIOUS orchestrated payoff.
// The city geometry is bit-identical across both runs (held constant — criterion 3).

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart' show Component;
import 'package:flutter/material.dart';

import '../../config/woc_tuning.dart';
import '../../state/woc_controller.dart';

class CityLayer extends Component {
  CityLayer(this.c);
  final WocController c;

  // A deterministic skyline (same seed → same geometry every run).
  final math.Random _rng = math.Random(1880);
  final List<_Building> _buildings = [];

  void _ensure() {
    if (_buildings.isNotEmpty) return;
    var x = 0.0;
    while (x < 1.0) {
      // Strong WIDTH variety (thin towers next to broad blocks) + varied heights +
      // a roof cap (flat / setback / peak-spire / water-tank) so it reads as a real
      // skyline silhouette, never an equalizer of equal bars.
      final bw = 0.055 + _rng.nextDouble() * 0.115;
      final bh = 0.34 + _rng.nextDouble() * 0.62;
      final cols = 2 + _rng.nextInt(2);
      final rows = 2 + _rng.nextInt(3);
      final cap = _rng.nextInt(4); // 0 flat · 1 setback · 2 peak · 3 water-tank
      _buildings.add(_Building(x, bw, bh, cols, rows, _rng.nextInt(1 << 16), cap));
      x += bw + 0.009;
    }
  }

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty || c.cityReveal <= 0.01) return;
    _ensure();
    final reveal = c.cityReveal;
    final dim = 1 - c.sceneDim;

    final center = c.cityCenter;
    final clusterW = c.cityWidth;
    final baseY = c.cityBaseY;
    final left = center.dx - clusterW / 2;
    final maxH = c.stageSize.height * WocTune.cityMaxHFactor;

    final lit = c.cityLit.clamp(0.0, 1.0);

    // ── City bloom behind the skyline (warm, ∝ cityLit) — the PAYOFF FLOOD ─────
    if (lit > 0.02) {
      final bloomAt = Offset(center.dx, baseY - maxH * 0.45);
      // a wide warm flood pouring up off the lit city.
      final r = clusterW * (0.80 + 0.55 * lit);
      canvas.drawCircle(
        bloomAt,
        r,
        Paint()
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, c.stageSize.height * 0.012)
          ..shader = ui.Gradient.radial(bloomAt, r, [
            WocTune.cityWarm.withValues(alpha: 0.52 * lit * dim),
            WocTune.cityWarm.withValues(alpha: 0.0),
          ]),
      );
      // a tighter, hotter heart of the flood (the glorious arrival).
      final rh = clusterW * (0.42 + 0.32 * lit);
      canvas.drawCircle(
        bloomAt,
        rh,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = ui.Gradient.radial(bloomAt, rh, [
            const Color(0xFFFFF6E0).withValues(alpha: 0.42 * lit * dim),
            WocTune.cityWarm.withValues(alpha: 0.0),
          ]),
      );
    }

    final sweep = c.citySweep.clamp(0.0, 1.0); // AC window-sweep progress (0..1)
    final flicker = c.reducedMotion ? 1.0 : (0.6 + 0.4 * math.sin(c.pulsePhase * 9));

    var windowIndex = 0;
    final totalWindows =
        _buildings.fold<int>(0, (s, b) => s + b.cols * b.rows);

    // ── The DIMENSIONAL building cluster (2.5 town craft) + window grid ────────
    for (final b in _buildings) {
      final bx = left + b.x * clusterW;
      final bw = b.bw * clusterW;
      final bh = b.bh * maxH;
      final rect = Rect.fromLTWH(bx, baseY - bh, bw, bh);
      final rr = RRect.fromRectAndRadius(rect, Radius.circular(c.stageSize.width * 0.004));

      // Body gradient — a clear cool-slate silhouette that reads as a building even
      // UNLIT (top-lit → deep base), warming toward the top as the city lights.
      final wallTop = Color.lerp(const Color(0xFF2C3A66), const Color(0xFF4A4630), 0.5 * lit)!;
      final wallBase = Color.lerp(const Color(0xFF10162E), const Color(0xFF2A2418), 0.4 * lit)!;
      canvas.drawRRect(
        rr,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              wallTop.withValues(alpha: reveal * dim),
              wallBase.withValues(alpha: reveal * dim),
            ],
          ).createShader(rect),
      );
      // Lit left edge (dimensional).
      canvas.drawLine(
        Offset(rect.left + 0.6, rect.top + 1),
        Offset(rect.left + 0.6, rect.bottom - 1),
        Paint()
          ..strokeWidth = 1.3
          ..color = const Color(0xFF2A356A).withValues(alpha: 0.9 * reveal * dim),
      );
      // Shaded right flank (depth).
      canvas.save();
      canvas.clipRRect(rr);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [const Color(0x00000000), Colors.black.withValues(alpha: 0.24 * reveal * dim)],
            stops: const [0.6, 1.0],
          ).createShader(rect),
      );
      canvas.restore();
      // Crisp edge.
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFF2A356A).withValues(alpha: 0.6 * reveal * dim),
      );

      // The roof cap (setback / spire / water-tank) — the skyline's character.
      _drawCap(canvas, b, rect, reveal * dim);

      // Window grid.
      final gx = bw / (b.cols + 1);
      final gy = bh / (b.rows + 1);
      final wsz = math.min(gx, gy) * 0.5;
      final wr = math.Random(b.seed);
      for (var col = 0; col < b.cols; col++) {
        for (var row = 0; row < b.rows; row++) {
          final wx = bx + gx * (col + 1);
          final wy = baseY - bh + gy * (row + 1);
          // Per-window "on" amount.
          double on;
          final occupied = wr.nextDouble() > 0.18; // a few always-dark windows
          if (!occupied) {
            on = 0;
          } else if (sweep > 0) {
            // AC sweep: windows ignite in order across the cluster.
            final threshold = totalWindows == 0 ? 0.0 : windowIndex / totalWindows;
            on = ((sweep - threshold) / 0.18).clamp(0.0, 1.0) * lit;
          } else {
            // DC feeble flicker (never reaches full) / hard-dark after the fail.
            on = lit * (0.5 + 0.5 * flicker);
          }
          // Track whether this window is in its sweep-ignition moment (a brief warm
          // POP as it lights — the orchestrated window-by-window payoff).
          double ignite = 0;
          if (sweep > 0 && occupied) {
            final threshold = totalWindows == 0 ? 0.0 : windowIndex / totalWindows;
            ignite = (1 - ((sweep - threshold).abs() / 0.10)).clamp(0.0, 1.0);
          }
          windowIndex++;
          if (on <= 0.02) continue;
          final wRect = Rect.fromCenter(center: Offset(wx, wy), width: wsz, height: wsz * 1.3);
          // Warm pane: a soft halo + a solid lit core (the 2.5 town pane treatment).
          canvas.drawRect(
            wRect.inflate(wsz * (0.35 + 0.4 * ignite)),
            Paint()
              ..blendMode = BlendMode.plus
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.6)
              ..color = WocTune.cityWarm.withValues(alpha: (0.30 + 0.35 * ignite) * on * dim),
          );
          canvas.drawRect(
            wRect,
            Paint()
              ..color = WocTune.cityWarm.withValues(alpha: (0.88 * on * dim).clamp(0.0, 1.0)),
          );
        }
      }
    }
  }

  // A roof cap that gives each building its skyline character (read even unlit).
  void _drawCap(Canvas canvas, _Building b, Rect rect, double a) {
    if (b.cap == 0) return; // flat roof
    final cx = rect.center.dx;
    final fill = Paint()..color = const Color(0xFF222C52).withValues(alpha: a);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF2A356A).withValues(alpha: 0.7 * a);
    switch (b.cap) {
      case 1: // setback — a smaller block stepped on top
        final sw = rect.width * 0.52, sh = rect.height * 0.14;
        final r2 = Rect.fromLTWH(cx - sw / 2, rect.top - sh, sw, sh);
        canvas.drawRect(r2, fill);
        canvas.drawRect(r2, edge);
      case 2: // peak / spire — a thin triangle crown
        final pw = rect.width * 0.34, ph = rect.height * 0.22;
        final tri = Path()
          ..moveTo(cx - pw / 2, rect.top)
          ..lineTo(cx, rect.top - ph)
          ..lineTo(cx + pw / 2, rect.top)
          ..close();
        canvas.drawPath(tri, fill);
        canvas.drawPath(tri, edge);
      case 3: // water-tank on two legs
        final tw = rect.width * 0.32, th = rect.width * 0.22, lh = rect.height * 0.08;
        canvas.drawLine(Offset(cx - tw * 0.3, rect.top), Offset(cx - tw * 0.3, rect.top - lh), edge);
        canvas.drawLine(Offset(cx + tw * 0.3, rect.top), Offset(cx + tw * 0.3, rect.top - lh), edge);
        final tank = RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - tw / 2, rect.top - lh - th, tw, th), Radius.circular(th * 0.3));
        canvas.drawRRect(tank, fill);
        canvas.drawRRect(tank, edge);
    }
  }
}

class _Building {
  _Building(this.x, this.bw, this.bh, this.cols, this.rows, this.seed, this.cap);
  final double x; // left edge as fraction of cluster width
  final double bw; // width as fraction of cluster width
  final double bh; // height as fraction of maxH
  final int cols;
  final int rows;
  final int seed;
  final int cap; // roof style: 0 flat · 1 setback · 2 peak · 3 water-tank
}
