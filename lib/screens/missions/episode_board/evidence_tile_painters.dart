// The replayable VISUAL moment for each evidence tile (PRD §5.1: captured felt
// MOMENTS, never text bullets). Each motif re-DRAWS the moment the kid felt — the
// convergence onto one magnet, a hazy skyline, a dark solar night — as a small
// thumbnail (the "short replayable representation of the actual scene", §8). We
// re-draw rather than screenshot the live Flame stage: crisp at any size, no async
// image capture, fully controllable — the same approach the deck's card motifs use.
//
// All drawing is in a UNIT square scaled to the tile; nothing is hardcoded in px.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'evidence_models.dart';

/// One painter for every [EvidenceMotif] — switched internally so a tile is just
/// `CustomPaint(painter: EvidenceMotifPainter(tile.motif, tile.accent))`.
class EvidenceMotifPainter extends CustomPainter {
  EvidenceMotifPainter(this.motif, this.accent);

  final EvidenceMotif motif;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final u = math.min(size.width, size.height);
    final c = Offset(size.width / 2, size.height / 2);
    switch (motif) {
      case EvidenceMotif.sameMagnet:
        _sameMagnet(canvas, c, u);
      case EvidenceMotif.stillMagnet:
        _stillMagnet(canvas, c, u);
      case EvidenceMotif.turbineSpin:
        _turbine(canvas, c, u);
      case EvidenceMotif.coalHaze:
        _coalHaze(canvas, c, u, size);
      case EvidenceMotif.nuclearCost:
        _nuclearCost(canvas, c, u, size);
      case EvidenceMotif.windDrop:
        _windDrop(canvas, c, u, size);
      case EvidenceMotif.solarNight:
        _solarNight(canvas, c, u, size);
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────
  Paint _stroke(Color color, double w) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..color = color;

  void _glow(Canvas canvas, Offset at, double r, Color color) {
    canvas.drawCircle(
      at,
      r,
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.6),
    );
  }

  void _coil(Canvas canvas, Offset center, double u, {Color? color}) {
    final p = _stroke(color ?? Colors.white.withValues(alpha: 0.85), u * 0.03);
    const rings = 4;
    for (var i = 0; i < rings; i++) {
      final y = center.dy - u * 0.13 + u * 0.26 * (i / (rings - 1));
      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx, y), width: u * 0.30, height: u * 0.085),
        p,
      );
    }
  }

  void _barMagnet(Canvas canvas, Offset center, double u, {double angle = 0, bool dim = false}) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final w = u * 0.34, h = u * 0.12;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      Radius.circular(h * 0.3),
    );
    final nColor = dim ? const Color(0xFF6B7280) : accent;
    final sColor = dim ? const Color(0xFF4B5563) : const Color(0xFF4A6CC8);
    canvas.save();
    canvas.clipRRect(rect);
    canvas.drawRect(Rect.fromLTWH(-w / 2, -h / 2, w / 2, h), Paint()..color = sColor);
    canvas.drawRect(Rect.fromLTWH(0, -h / 2, w / 2, h),
        Paint()..color = nColor.withValues(alpha: 0.95));
    canvas.restore();
    canvas.drawRRect(rect, _stroke(Colors.white.withValues(alpha: 0.7), u * 0.018));
    canvas.restore();
  }

  void _bulb(Canvas canvas, Offset at, double u, double lit) {
    if (lit > 0) _glow(canvas, at, u * 0.13 * lit, const Color(0xFFFFE9A8).withValues(alpha: 0.6 * lit));
    canvas.drawCircle(at, u * 0.06,
        Paint()..color = Color.lerp(const Color(0xFF2A2F45), const Color(0xFFFFE9A8), lit)!);
    canvas.drawCircle(at, u * 0.06, _stroke(Colors.white.withValues(alpha: 0.5), u * 0.012));
  }

  // ── ACT 2 — the convergence: every source spins the SAME magnet ─────────────
  void _sameMagnet(Canvas canvas, Offset c, double u) {
    // Three little sources (flame / drop / sun) converging arrows onto ONE coil+magnet.
    final coilC = Offset(c.dx, c.dy + u * 0.05);
    final srcY = c.dy - u * 0.30;
    final srcs = <(double, Color)>[
      (c.dx - u * 0.34, const Color(0xFFFF7A2E)),
      (c.dx, const Color(0xFF6FE0C8)),
      (c.dx + u * 0.34, const Color(0xFFFFD15C)),
    ];
    final arrow = _stroke(accent.withValues(alpha: 0.6), u * 0.022);
    for (final (x, col) in srcs) {
      _glow(canvas, Offset(x, srcY), u * 0.07, col.withValues(alpha: 0.5));
      canvas.drawCircle(Offset(x, srcY), u * 0.045, Paint()..color = col);
      // converging line toward the magnet
      canvas.drawLine(Offset(x, srcY + u * 0.06), Offset(coilC.dx, coilC.dy - u * 0.16), arrow);
    }
    // field bloom (it's MOVING) then the magnet through the coil
    for (var i = 0; i < 3; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: coilC, radius: u * (0.16 + i * 0.05)),
        -math.pi * 0.85, math.pi * 0.7, false,
        _stroke(accent.withValues(alpha: 0.4 - i * 0.1), u * 0.016),
      );
    }
    _coil(canvas, coilC, u);
    _barMagnet(canvas, coilC, u, angle: -0.35);
  }

  // ── ACT 2 distractor — a still magnet does nothing (HOW, not WHY) ────────────
  void _stillMagnet(Canvas canvas, Offset c, double u) {
    final coilC = Offset(c.dx - u * 0.04, c.dy + u * 0.04);
    _coil(canvas, coilC, u, color: Colors.white.withValues(alpha: 0.55));
    _barMagnet(canvas, coilC, u, angle: 0, dim: true); // flat, no tilt = at rest
    // a "no motion" hush: a flat dash line + a dark bulb above
    canvas.drawLine(
      Offset(c.dx - u * 0.18, c.dy - u * 0.28),
      Offset(c.dx + u * 0.18, c.dy - u * 0.28),
      _stroke(Colors.white.withValues(alpha: 0.3), u * 0.02),
    );
    _bulb(canvas, Offset(c.dx + u * 0.30, c.dy - u * 0.18), u, 0); // dark — nothing made
  }

  // ── ACT 2 distractor — a turbine spins the magnet (HOW, not WHY) ─────────────
  void _turbine(Canvas canvas, Offset c, double u) {
    final wheelC = Offset(c.dx - u * 0.12, c.dy + u * 0.06);
    final r = u * 0.26;
    // blades
    final blade = Paint()..color = Colors.white.withValues(alpha: 0.85)..style = PaintingStyle.fill;
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 + 0.3;
      final path = Path()
        ..moveTo(wheelC.dx, wheelC.dy)
        ..lineTo(wheelC.dx + math.cos(a) * r, wheelC.dy + math.sin(a) * r)
        ..lineTo(wheelC.dx + math.cos(a + 0.5) * r * 0.7, wheelC.dy + math.sin(a + 0.5) * r * 0.7)
        ..close();
      canvas.drawPath(path, blade);
    }
    canvas.drawCircle(wheelC, u * 0.05, Paint()..color = accent);
    // shaft to a small coil+magnet + a lit bulb on the right
    final coilC = Offset(c.dx + u * 0.26, c.dy + u * 0.04);
    canvas.drawLine(Offset(wheelC.dx + r * 0.4, wheelC.dy),
        Offset(coilC.dx, coilC.dy), _stroke(Colors.white.withValues(alpha: 0.6), u * 0.03));
    _coil(canvas, coilC, u);
    _barMagnet(canvas, coilC, u, angle: -0.4);
    _bulb(canvas, Offset(c.dx + u * 0.30, c.dy - u * 0.24), u, 0.9);
  }

  // ── ACT 3 — coal: the skyline chokes in haze (dirty) ────────────────────────
  void _skyline(Canvas canvas, Size size, double u, double darkness) {
    // a row of building silhouettes along the bottom
    final base = size.height * 0.82;
    final b = Paint()..color = Color.lerp(const Color(0xFF2A2E3E), const Color(0xFF12141C), darkness)!;
    final widths = [0.10, 0.07, 0.13, 0.08, 0.11, 0.09];
    final heights = [0.26, 0.40, 0.20, 0.46, 0.30, 0.36];
    double x = size.width * 0.06;
    for (var i = 0; i < widths.length; i++) {
      final w = size.width * widths[i];
      final h = size.height * heights[i];
      canvas.drawRect(Rect.fromLTWH(x, base - h, w, h), b);
      x += w + size.width * 0.025;
    }
  }

  void _coalHaze(Canvas canvas, Offset c, double u, Size size) {
    // brown sky wash
    canvas.drawRect(Offset.zero & size,
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF6B5B3E), Color(0xFF3A3326)]).createShader(Offset.zero & size));
    _skyline(canvas, size, u, 0.4);
    // smokestack + plume
    final sx = size.width * 0.72;
    canvas.drawRect(Rect.fromLTWH(sx, size.height * 0.40, size.width * 0.06, size.height * 0.42),
        Paint()..color = const Color(0xFF20242F));
    final smog = Paint()..color = const Color(0xFF8A8270).withValues(alpha: 0.7);
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(Offset(sx + size.width * (0.03 - i * 0.04), size.height * (0.36 - i * 0.06)),
          u * (0.07 + i * 0.02), smog);
    }
    // thick haze band over the rooftops
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.42, size.width, size.height * 0.30),
      Paint()..color = const Color(0xFFB7AE97).withValues(alpha: 0.42)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  // ── ACT 3 — nuclear: the cost soars (expensive) ─────────────────────────────
  void _nuclearCost(Canvas canvas, Offset c, double u, Size size) {
    canvas.drawRect(Offset.zero & size,
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1430), Color(0xFF0E0A1E)]).createShader(Offset.zero & size));
    // cooling tower (hourglass silhouette) with a clean steam puff
    final tx = size.width * 0.26;
    final base = size.height * 0.82, top = size.height * 0.42;
    final tower = Path()
      ..moveTo(tx - u * 0.13, base)
      ..lineTo(tx - u * 0.07, (base + top) / 2)
      ..lineTo(tx - u * 0.11, top)
      ..lineTo(tx + u * 0.11, top)
      ..lineTo(tx + u * 0.07, (base + top) / 2)
      ..lineTo(tx + u * 0.13, base)
      ..close();
    canvas.drawPath(tower, Paint()..color = const Color(0xFF3A4256));
    _glow(canvas, Offset(tx, top - u * 0.06), u * 0.10, Colors.white.withValues(alpha: 0.4));
    // a soaring cost bar — rising columns + an upward arrow (₹)
    final barX = size.width * 0.56;
    final bw = size.width * 0.09;
    final hs = [0.16, 0.28, 0.44, 0.62];
    for (var i = 0; i < hs.length; i++) {
      final h = size.height * hs[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barX + i * (bw + size.width * 0.03), size.height * 0.82 - h, bw, h),
          Radius.circular(bw * 0.2)),
        Paint()..color = accent.withValues(alpha: 0.55 + i * 0.12),
      );
    }
    // soaring arrow
    final ax = barX, ay = size.height * 0.66;
    final tip = Offset(size.width * 0.92, size.height * 0.18);
    canvas.drawLine(Offset(ax, ay), tip, _stroke(accent, u * 0.03));
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tip.dx - u * 0.10, tip.dy + u * 0.02)
        ..lineTo(tip.dx - u * 0.02, tip.dy + u * 0.11)
        ..close(),
      Paint()..color = accent,
    );
  }

  // ── ACT 3 — wind: the town goes dark when the wind drops (unreliable) ────────
  void _windDrop(Canvas canvas, Offset c, double u, Size size) {
    canvas.drawRect(Offset.zero & size,
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF202A3A), Color(0xFF11151F)]).createShader(Offset.zero & size));
    _skyline(canvas, size, u, 0.85); // dark town, lights out
    // a wind turbine with LIMP/drooping blades (no wind)
    final hubX = size.width * 0.30, hubY = size.height * 0.40;
    canvas.drawLine(Offset(hubX, hubY), Offset(hubX, size.height * 0.82),
        _stroke(Colors.white.withValues(alpha: 0.55), u * 0.025));
    final blade = _stroke(Colors.white.withValues(alpha: 0.6), u * 0.03);
    // blades all sagging downward = stalled
    for (final a in [math.pi * 0.5, math.pi * 0.72, math.pi * 0.28]) {
      canvas.drawLine(Offset(hubX, hubY),
          Offset(hubX + math.cos(a) * u * 0.22, hubY + math.sin(a) * u * 0.22), blade);
    }
    canvas.drawCircle(Offset(hubX, hubY), u * 0.03, Paint()..color = accent);
    // a "no wind" hush — a faint flat gust line
    canvas.drawLine(Offset(size.width * 0.50, hubY - u * 0.10),
        Offset(size.width * 0.86, hubY - u * 0.10),
        _stroke(accent.withValues(alpha: 0.3), u * 0.02));
  }

  // ── ACT 3 — solar: the town goes dark every night (nightly, most dramatic) ───
  void _solarNight(Canvas canvas, Offset c, double u, Size size) {
    canvas.drawRect(Offset.zero & size,
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1430), Color(0xFF05070F)]).createShader(Offset.zero & size));
    // moon + stars
    _glow(canvas, Offset(size.width * 0.76, size.height * 0.24), u * 0.13, accent.withValues(alpha: 0.4));
    canvas.drawCircle(Offset(size.width * 0.76, size.height * 0.24), u * 0.08,
        Paint()..color = const Color(0xFFEDEFFF));
    canvas.drawCircle(Offset(size.width * 0.80, size.height * 0.21), u * 0.07,
        Paint()..color = const Color(0xFF05070F)); // crescent bite
    final star = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (final p in [const Offset(0.18, 0.20), Offset(0.40, 0.14), Offset(0.55, 0.30), Offset(0.30, 0.34)]) {
      canvas.drawCircle(Offset(size.width * p.dx, size.height * p.dy), u * 0.012, star);
    }
    _skyline(canvas, size, u, 0.9); // pitch-dark town
    // dim solar panels in front, asleep
    final py = size.height * 0.74;
    for (var i = 0; i < 2; i++) {
      final px = size.width * (0.16 + i * 0.20);
      final panel = Path()
        ..moveTo(px, py)
        ..lineTo(px + u * 0.16, py - u * 0.05)
        ..lineTo(px + u * 0.16, py + u * 0.06)
        ..lineTo(px, py + u * 0.11)
        ..close();
      canvas.drawPath(panel, Paint()..color = const Color(0xFF243049));
      canvas.drawPath(panel, _stroke(Colors.white.withValues(alpha: 0.18), u * 0.012));
    }
  }

  @override
  bool shouldRepaint(EvidenceMotifPainter old) => old.motif != motif || old.accent != accent;
}
