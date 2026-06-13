// The town (PRD §16, UPPER-RIGHT end of the diagonal span) — a DIAGONAL climbing
// skyline whose lit windows ARE the readout of delivered power. THE TOWN IS THE
// METER — no "% delivered" number; you read the lesson off how many windows are warm
// and how the cluster blooms.
//
// The buildings step UP left→right to the tallest receiving tower at the right corner
// (where the wire lands), so the skyline covers the upper-right diagonally instead of
// standing in a flat row. CRUCIAL FIX: every window belongs to a specific building and
// is laid out INSIDE that building's walls, so no window ever floats above a shorter
// roof (the old bug). Windows light bottom-up as power is delivered; at the townLit
// latch the rest sweep on over ~0.8s — the one orchestrated payoff — with a warm bloom.

import 'dart:math' as math;

import 'package:flame/components.dart' show Component;
import 'package:flutter/material.dart';

import '../../config/transmission_tuning.dart';
import '../../state/transmission_controller.dart';

class TownLayer extends Component {
  TownLayer(this.c);
  final TransmissionController c;

  // Deterministic per-window flicker phases (sized to a safe maximum window count).
  final math.Random _rng = math.Random(23);
  late final List<double> _phase = List.generate(200, (_) => _rng.nextDouble() * 6.28);

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    final rev = c.townReveal;
    if (rev <= 0.001) return;

    final buildings = _buildings();
    if (buildings.isEmpty) return;

    canvas.saveLayer(Offset.zero & c.stageSize,
        Paint()..color = Colors.white.withValues(alpha: rev));

    final lit = c.townLit; // 0..1 (high-water once latched)

    // Warm bloom over the town mass — the payoff glow, capped so it never out-glows
    // the rest. Centred on the union of the buildings.
    if (lit > 0.02) {
      final union = _union(buildings);
      final ctr = Offset(union.center.dx, union.top + union.height * 0.45);
      final radius = union.width * (0.62 + 0.5 * lit);
      canvas.drawCircle(
        ctr,
        radius,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(
            colors: [
              TTTune.bloom.withValues(alpha: (0.22 * lit).clamp(0.0, 0.24)),
              TTTune.bloom.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: ctr, radius: radius)),
      );
    }

    // Draw the buildings first (back to front; left→right is fine since they don't
    // overlap), then all windows on top.
    for (final b in buildings) {
      _drawBuilding(canvas, b, lit);
    }

    // Flatten every building's window grid into one list, ordered bottom-up (lower
    // windows light first), so the lit fraction reads as a rising tide of light.
    final windows = <Rect>[];
    for (final b in buildings) {
      windows.addAll(_windowsFor(b));
    }
    windows.sort((p, q) => q.top.compareTo(p.top)); // higher y (lower on screen) first

    final total = windows.length;
    if (total == 0) {
      canvas.restore();
      return;
    }
    final litCount = (lit * total).round();
    final preLatch = (c.deliveredAtLatch * total).round();
    final sweep = c.townSweep;
    for (var k = 0; k < total; k++) {
      _drawWindow(canvas, windows[k], k < litCount, k, preLatch, sweep, lit);
    }

    canvas.restore();
  }

  // ── The climbing skyline — buildings step UP left→right to the tallest at the
  // right corner (where the wire lands). Each is a vertical slab on the floor.
  List<Rect> _buildings() {
    final w = c.stageSize.width, h = c.stageSize.height;
    final base = c.townBase;
    final tw = c.townWidth;
    final left = base.dx - tw / 2;
    final n = TTTune.townBuildingCount;
    if (n <= 0) return const [];
    final slot = tw / n;
    final gap = slot * TTTune.townBuildingGapFrac;
    final bw = slot - gap;
    final shortTop = TTTune.townShortTopFactor * h; // leftmost (short)
    final tallTop = TTTune.townTallTopFactor * h; // rightmost (tall, receiving)
    final list = <Rect>[];
    for (var i = 0; i < n; i++) {
      final f = n == 1 ? 1.0 : i / (n - 1);
      // BOTH the base and the top climb the diagonal: the foot rides the diagonal
      // ground (so each building steps higher than the last) and the roof ramps up to
      // the tall right corner where the wire lands — a clean diagonal staircase.
      final top = shortTop + (tallTop - shortTop) * f;
      final bx = left + slot * i + gap * 0.5;
      final foot = c.groundY((bx + bw / 2) / w); // base on the diagonal ground
      list.add(Rect.fromLTRB(bx, top, bx + bw, foot));
    }
    return list;
  }

  Rect _union(List<Rect> rects) {
    var r = rects.first;
    for (final x in rects.skip(1)) {
      r = r.expandToInclude(x);
    }
    return r;
  }

  void _drawBuilding(Canvas canvas, Rect rect, double lit) {
    final w = c.stageSize.width;
    final h = c.stageSize.height;
    // Ground-contact shadow so the building sits on the diagonal ground (it steps up
    // the slope) rather than floating in the dark.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(rect.center.dx, rect.bottom + h * 0.004),
        width: rect.width * 1.25,
        height: rect.width * 0.30,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.34)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.010),
    );
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(w * 0.008));
    // Body gradient — warms a touch as the town lights (the wall catches the glow).
    final wallLit = Color.lerp(TTTune.buildingBody, TTTune.buildingLit, 0.5 * lit)!;
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(TTTune.buildingEdge, wallLit, 0.5)!, wallLit],
        ).createShader(rect),
    );
    // Lit left edge (dimensional, light from the upper-left).
    canvas.drawLine(
      Offset(rect.left + 0.5, rect.top + w * 0.006),
      Offset(rect.left + 0.5, rect.bottom - w * 0.004),
      Paint()
        ..color = TTTune.buildingEdge.withValues(alpha: 0.9)
        ..strokeWidth = 1.4,
    );
    // Shaded right flank.
    canvas.save();
    canvas.clipRRect(rr);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [const Color(0x00000000), Colors.black.withValues(alpha: 0.22)],
          stops: const [0.6, 1.0],
        ).createShader(rect),
    );
    canvas.restore();
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = TTTune.buildingEdge,
    );
  }

  // ── The window grid for ONE building — laid out strictly inside its walls. Cols/
  // rows scale to the building's size (a square-ish cell), so windows never spill
  // past the roof or sides.
  List<Rect> _windowsFor(Rect b) {
    final cell = c.stageSize.width * 0.034; // target window cell size
    final padX = b.width * 0.16;
    final usableW = b.width - padX * 2;
    if (usableW <= cell * 0.5) return const [];
    final cols = math.max(1, (usableW / cell).floor());
    final topPad = b.height * 0.09;
    final botPad = b.width * 0.12; // a solid base strip (no street-level windows)
    final usableH = b.height - topPad - botPad;
    if (usableH <= cell * 0.5) return const [];
    final rows = math.max(1, (usableH / cell).floor());
    final cw = usableW / cols;
    final ch = usableH / rows;
    final wins = <Rect>[];
    for (var r = 0; r < rows; r++) {
      for (var col = 0; col < cols; col++) {
        final wx = b.left + padX + cw * col + cw * 0.2;
        final wy = b.top + topPad + ch * r + ch * 0.2;
        wins.add(Rect.fromLTWH(wx, wy, cw * 0.6, ch * 0.6));
      }
    }
    return wins;
  }

  void _drawWindow(Canvas canvas, Rect pane, bool isLit, int k, int preLatch, double sweep, double lit) {
    final prr = RRect.fromRectAndRadius(pane, const Radius.circular(2));
    if (!isLit) {
      canvas.drawRRect(prr, Paint()..color = TTTune.townWindowDark);
      return;
    }
    // Flicker when the town is starved (low delivered) — calm under reduced motion.
    double a = 1.0;
    if (!c.reducedMotion && lit < 0.5) {
      final flick = 0.6 + 0.4 * math.sin(c.hazePhase * 12 + _phase[k % _phase.length]);
      a = (0.5 + 0.5 * flick).clamp(0.35, 1.0);
    }
    // Windows that arrived only AT the latch ease in over the 800ms bloom; the ones
    // already warm before the latch stay solid (no re-animation).
    if (c.townSweepActive && k >= preLatch) {
      a *= sweep;
    }
    // Warm pane — a soft halo + a solid lit core.
    canvas.drawRRect(
      prr,
      Paint()
        ..blendMode = BlendMode.plus
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.6)
        ..color = TTTune.townWindow.withValues(alpha: 0.4 * a),
    );
    canvas.drawRRect(prr, Paint()..color = TTTune.townWindow.withValues(alpha: a));
  }
}
