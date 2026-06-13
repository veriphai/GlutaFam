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
      case EvidenceMotif.fossilHaze:
        _fossilHaze(canvas, c, u, size);
      case EvidenceMotif.nuclearCost:
        _nuclearCost(canvas, c, u, size);
      case EvidenceMotif.windDrop:
        _windDrop(canvas, c, u, size);
      case EvidenceMotif.solarNight:
        _solarNight(canvas, c, u, size);
      case EvidenceMotif.hydroRiver:
        _hydroRiver(canvas, c, u, size);
      // ── Episode 2 — transmission ──────────────────────────────────────────
      case EvidenceMotif.ep2PushFlow:
        _ep2PushFlow(canvas, c, u, size);
      case EvidenceMotif.ep2FatWire:
        _ep2FatWire(canvas, c, u, size);
      case EvidenceMotif.ep2HeatLeavesWire:
        _ep2HeatLeavesWire(canvas, c, u, size);
      case EvidenceMotif.ep2RubbedWarm:
        _ep2RubbedWarm(canvas, c, u, size);
      case EvidenceMotif.ep2HeatQuadruples:
        _ep2HeatQuadruples(canvas, c, u, size);
      case EvidenceMotif.ep2CurrentDrops:
        _ep2CurrentDrops(canvas, c, u, size);
      case EvidenceMotif.ep2TurnsStepUp:
        _ep2TurnsStepUp(canvas, c, u, size);
      case EvidenceMotif.ep2AcAlive:
        _ep2AcAlive(canvas, c, u, size);
      case EvidenceMotif.ep2AcSailsAcross:
        _ep2AcSailsAcross(canvas, c, u, size);
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

  void _fossilHaze(Canvas canvas, Offset c, double u, Size size) {
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

  // ── ACT 3 — hydro: clean + steady, but only where a dammed river runs ────────
  void _hydroRiver(Canvas canvas, Offset c, double u, Size size) {
    canvas.drawRect(Offset.zero & size,
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF14324A), Color(0xFF0A1622)]).createShader(Offset.zero & size));
    _skyline(canvas, size, u, 0.7); // a lit-enough town behind the dam
    // the dam wall — a trapezoid spanning the lower frame
    final waterTop = size.height * 0.60;
    final dam = Path()
      ..moveTo(0, waterTop)
      ..lineTo(size.width, waterTop + size.height * 0.05)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(dam, Paint()..color = const Color(0xFF3A4658));
    // the held-back reservoir water above the wall
    canvas.drawRect(Rect.fromLTWH(0, waterTop - size.height * 0.14, size.width, size.height * 0.14),
        Paint()..color = accent.withValues(alpha: 0.45));
    // a couple of ripple lines on the water
    final ripple = _stroke(Colors.white.withValues(alpha: 0.35), u * 0.012);
    for (var i = 0; i < 2; i++) {
      final ry = waterTop - size.height * (0.04 + i * 0.05);
      canvas.drawLine(Offset(size.width * 0.12, ry), Offset(size.width * 0.62, ry), ripple);
    }
    // a thin spillway stream down the dam face
    canvas.drawLine(Offset(size.width * 0.72, waterTop), Offset(size.width * 0.72, size.height * 0.94),
        _stroke(Colors.white.withValues(alpha: 0.4), u * 0.02));
  }

  // ══ Episode 2 — "The Long Way Home" (transmission) ══════════════════════════
  // All in the same unit-square style as the EP1 motifs: a dark field, the felt
  // moment re-drawn simply and legibly, on the tile's transmission accent.

  static const Color _ep2HeatCore = Color(0xFFFF7A2E);
  static const Color _ep2Warm = Color(0xFFFFD27A);
  static const Color _ep2Blue = Color(0xFF3FB9F5);

  void _ep2Field(Canvas canvas, Size size, List<Color> colors) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(Offset.zero & size),
    );
  }

  // ── 2.3 — heat leaves the wire: a sagging span glowing at midspan, three short
  //         heat strokes rising off it, a dim bulb at the right end ─────────────
  void _ep2HeatLeavesWire(Canvas canvas, Offset c, double u, Size size) {
    _ep2Field(canvas, size, const [Color(0xFF1C1410), Color(0xFF0A0706)]);
    // a catenary span from a left post to a right post
    final lx = size.width * 0.10, rx = size.width * 0.90;
    final topY = size.height * 0.34, sagY = size.height * 0.54;
    final span = Path()
      ..moveTo(lx, topY)
      ..quadraticBezierTo(size.width * 0.5, sagY + size.height * 0.10, rx, topY + size.height * 0.04);
    // glow underlay
    canvas.drawPath(
      span,
      _stroke(_ep2HeatCore.withValues(alpha: 0.55), u * 0.075)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(span, _stroke(_ep2Warm.withValues(alpha: 0.95), u * 0.028));
    // posts
    final post = _stroke(Colors.white.withValues(alpha: 0.4), u * 0.02);
    canvas.drawLine(Offset(lx, topY), Offset(lx, size.height * 0.78), post);
    canvas.drawLine(Offset(rx, topY + size.height * 0.04), Offset(rx, size.height * 0.78), post);
    // heat strokes rising off the midspan
    final midY = sagY + size.height * 0.06;
    for (var i = 0; i < 3; i++) {
      final x = size.width * (0.36 + i * 0.14);
      final p = Path()
        ..moveTo(x, midY)
        ..relativeQuadraticBezierTo(u * 0.04, -u * 0.10, -u * 0.02, -u * 0.20)
        ..relativeQuadraticBezierTo(-u * 0.05, -u * 0.08, u * 0.03, -u * 0.16);
      canvas.drawPath(p, _stroke(_ep2HeatCore.withValues(alpha: 0.5 - i * 0.08), u * 0.016));
    }
    _bulb(canvas, Offset(rx, topY - size.height * 0.02), u, 0.45); // dim — robbed of energy
  }

  // ── 2.3 distractor — rubbing warms: a straight wire, a finger-stroke arc above,
  //         warm glow pooled under the stroke ──────────────────────────────────
  void _ep2RubbedWarm(Canvas canvas, Offset c, double u, Size size) {
    _ep2Field(canvas, size, const [Color(0xFF1A1512), Color(0xFF0A0807)]);
    final y = size.height * 0.58, lx = size.width * 0.16, rx = size.width * 0.84;
    // warm pool under the stroke
    _glow(canvas, Offset(size.width * 0.5, y), u * 0.22, _ep2HeatCore.withValues(alpha: 0.4));
    canvas.drawLine(Offset(lx, y), Offset(rx, y),
        _stroke(Colors.white.withValues(alpha: 0.75), u * 0.03));
    // finger-stroke arc above the wire, with back-and-forth motion dashes
    final arc = Path()
      ..moveTo(size.width * 0.30, size.height * 0.34)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.22, size.width * 0.70, size.height * 0.34);
    canvas.drawPath(arc, _stroke(accent.withValues(alpha: 0.85), u * 0.026));
    // a small finger pad on the wire
    canvas.drawCircle(Offset(size.width * 0.5, y - u * 0.02), u * 0.05,
        Paint()..color = accent.withValues(alpha: 0.9));
    // double-headed motion hint
    final hint = _stroke(Colors.white.withValues(alpha: 0.5), u * 0.016);
    canvas.drawLine(Offset(size.width * 0.40, size.height * 0.30),
        Offset(size.width * 0.60, size.height * 0.30), hint);
  }

  // ── 2.4 — quadruple heat: two ember columns rising off the same wire, the
  //         second four times taller than the first ───────────────────────────
  void _ep2HeatQuadruples(Canvas canvas, Offset c, double u, Size size) {
    _ep2Field(canvas, size, const [Color(0xFF1E1109), Color(0xFF0A0605)]);
    final baseY = size.height * 0.78;
    canvas.drawLine(Offset(size.width * 0.08, baseY), Offset(size.width * 0.92, baseY),
        _stroke(Colors.white.withValues(alpha: 0.6), u * 0.022));
    void column(double x, double h, double w) {
      final top = baseY - h;
      final rect = Rect.fromLTRB(x - w / 2, top, x + w / 2, baseY);
      canvas.drawRect(
        rect.inflate(u * 0.02),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [accent.withValues(alpha: 0.9), accent.withValues(alpha: 0.0)],
          ).createShader(rect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(w * 0.3)),
        Paint()..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [_ep2HeatCore, _ep2Warm.withValues(alpha: 0.2)],
        ).createShader(rect),
      );
    }
    column(size.width * 0.30, size.height * 0.16, size.width * 0.10); // ×1
    column(size.width * 0.66, size.height * 0.62, size.width * 0.12); // ×4 — fourfold
    // little ×1 / ×4 tick marks (felt disproportion, no numbers)
    final tick = _stroke(Colors.white.withValues(alpha: 0.35), u * 0.012);
    canvas.drawLine(Offset(size.width * 0.30, baseY + u * 0.03),
        Offset(size.width * 0.30, baseY + u * 0.07), tick);
    canvas.drawLine(Offset(size.width * 0.66, baseY + u * 0.03),
        Offset(size.width * 0.66, baseY + u * 0.07), tick);
  }

  // ── 2.5 — current drops: a tall narrow gold rectangle over a faint squat ghost
  //         rectangle (same area, new shape) ────────────────────────────────────
  void _ep2CurrentDrops(Canvas canvas, Offset c, double u, Size size) {
    _ep2Field(canvas, size, const [Color(0xFF15120A), Color(0xFF080705)]);
    final cx = size.width * 0.5, baseY = size.height * 0.86;
    // ghost: squat + wide (low voltage, big current)
    final ghostW = size.width * 0.64, ghostH = size.height * 0.18;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - ghostW / 2, baseY - ghostH, ghostW, ghostH),
        Radius.circular(u * 0.03)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.014
        ..color = accent.withValues(alpha: 0.3),
    );
    // current: tall + narrow (high voltage, tiny current) — same area
    final tallW = size.width * 0.20, tallH = size.height * 0.58;
    final rect = Rect.fromLTWH(cx - tallW / 2, baseY - tallH, tallW, tallH);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(u * 0.03), Radius.circular(u * 0.04)),
      Paint()
        ..color = accent.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(u * 0.03)),
      Paint()..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [accent, _ep2Warm.withValues(alpha: 0.85)],
      ).createShader(rect),
    );
    // up arrow on the top edge — the only thing the learner raised
    final tip = Offset(cx, rect.top - u * 0.06);
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tip.dx - u * 0.06, tip.dy + u * 0.07)
        ..lineTo(tip.dx + u * 0.06, tip.dy + u * 0.07)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  // ── 2.6 — turns step up: a ring core with dense loops on one limb and a pulse
  //         line climbing toward a tiny far pylon ─────────────────────────────
  void _ep2TurnsStepUp(Canvas canvas, Offset c, double u, Size size) {
    _ep2Field(canvas, size, const [Color(0xFF0E1320), Color(0xFF06070F)]);
    final coreC = Offset(size.width * 0.34, size.height * 0.62);
    final ringR = u * 0.22;
    // the iron core ring
    canvas.drawCircle(coreC, ringR,
        _stroke(const Color(0xFF566178), u * 0.06));
    // breathing amber field hint
    canvas.drawCircle(coreC, ringR,
        _stroke(_ep2Warm.withValues(alpha: 0.5), u * 0.02)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    // dense secondary loops on the right limb
    final loopX = coreC.dx + ringR;
    final loop = _stroke(accent.withValues(alpha: 0.9), u * 0.018);
    for (var i = 0; i < 6; i++) {
      final y = coreC.dy - ringR * 0.7 + (ringR * 1.4) * (i / 5);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(loopX, y), width: u * 0.16, height: u * 0.05),
        loop,
      );
    }
    // a pulse line climbing to a tiny far pylon (lit)
    final pylon = Offset(size.width * 0.84, size.height * 0.22);
    canvas.drawLine(Offset(loopX + u * 0.08, coreC.dy - ringR * 0.6), pylon,
        _stroke(_ep2Blue.withValues(alpha: 0.7), u * 0.02));
    // pulse dots
    for (var i = 0; i < 3; i++) {
      final t = 0.3 + i * 0.25;
      final p = Offset.lerp(Offset(loopX + u * 0.08, coreC.dy - ringR * 0.6), pylon, t)!;
      canvas.drawCircle(p, u * 0.02, Paint()..color = _ep2Blue.withValues(alpha: 0.9));
    }
    // the lit far pylon
    _glow(canvas, pylon, u * 0.08, _ep2Warm.withValues(alpha: 0.6));
    canvas.drawLine(pylon, Offset(pylon.dx, pylon.dy + u * 0.14),
        _stroke(Colors.white.withValues(alpha: 0.6), u * 0.016));
  }

  // ── 2.1 distractor — push & flow: a voltage "push" pressure column feeding a
  //         glowing current loop (defines the two quantities) ───────────────────
  void _ep2PushFlow(Canvas canvas, Offset c, double u, Size size) {
    _ep2Field(canvas, size, const [Color(0xFF130F24), Color(0xFF06040E)]);
    // the current loop — a rounded ring the flow rides
    final ring = Rect.fromCenter(
        center: Offset(size.width * 0.58, c.dy), width: size.width * 0.46, height: size.height * 0.46);
    canvas.drawRRect(RRect.fromRectAndRadius(ring, Radius.circular(u * 0.10)),
        _stroke(accent.withValues(alpha: 0.85), u * 0.028));
    // flow motes along the top run
    final mote = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (var i = 0; i < 7; i++) {
      canvas.drawCircle(Offset(ring.left + ring.width * (i / 6), ring.top), u * 0.012, mote);
    }
    // a lit bulb riding the loop top
    _glow(canvas, Offset(ring.center.dx, ring.top), u * 0.16, accent.withValues(alpha: 0.45));
    // the voltage "push" pressure column on the left, filled high
    final col = Rect.fromLTWH(size.width * 0.13, size.height * 0.28, size.width * 0.11, size.height * 0.44);
    canvas.drawRRect(RRect.fromRectAndRadius(col, Radius.circular(u * 0.03)),
        Paint()..color = accent.withValues(alpha: 0.22));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTRB(col.left, col.top + col.height * 0.30, col.right, col.bottom),
          Radius.circular(u * 0.03)),
      Paint()..color = accent.withValues(alpha: 0.85),
    );
    // an up-arrow atop the column = the "push"
    final ax = col.center.dx;
    canvas.drawPath(
      Path()
        ..moveTo(ax, col.top - u * 0.02)
        ..lineTo(ax - u * 0.05, col.top + u * 0.07)
        ..lineTo(ax + u * 0.05, col.top + u * 0.07)
        ..close(),
      Paint()..color = accent,
    );
  }

  // ── 2.2 distractor — fat wire runs: a thin choked wire beside a fat free one
  //         (a different lever — change the wire, not the voltage) ──────────────
  void _ep2FatWire(Canvas canvas, Offset c, double u, Size size) {
    _ep2Field(canvas, size, const [Color(0xFF1A1206), Color(0xFF080503)]);
    final top = size.height * 0.18, bot = size.height * 0.82;
    // the THIN wire (left) — narrow + dim (chokes the flow)
    final thinX = size.width * 0.34;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTRB(thinX - u * 0.02, top, thinX + u * 0.02, bot), Radius.circular(u * 0.02)),
      Paint()..color = accent.withValues(alpha: 0.45),
    );
    // the FAT wire (right) — wide + bright (lets it run)
    final fatX = size.width * 0.66;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTRB(fatX - u * 0.10, top, fatX + u * 0.10, bot), Radius.circular(u * 0.06)),
      Paint()..color = accent.withValues(alpha: 0.85),
    );
    _glow(canvas, Offset(fatX, c.dy), u * 0.22, accent.withValues(alpha: 0.30));
    // motes: a single-file thin column vs a wide braid in the fat wire
    final mote = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (var i = 0; i < 4; i++) {
      final y = top + (bot - top) * (i / 3);
      canvas.drawCircle(Offset(thinX, y), u * 0.012, mote);
      canvas.drawCircle(Offset(fatX - u * 0.045, y), u * 0.014, mote);
      canvas.drawCircle(Offset(fatX + u * 0.045, y), u * 0.014, mote);
    }
  }

  // ── 2.7 — alive on AC: a sine-wave strip under a small bulb at full bloom ─────
  void _ep2AcAlive(Canvas canvas, Offset c, double u, Size size) {
    _ep2Field(canvas, size, const [Color(0xFF0B1422), Color(0xFF05070F)]);
    // the bulb, full bloom
    _bulb(canvas, Offset(size.width * 0.5, size.height * 0.32), u, 1.0);
    // breathing field hint behind it
    _glow(canvas, Offset(size.width * 0.5, size.height * 0.32), u * 0.30,
        _ep2Warm.withValues(alpha: 0.22));
    // the AC sine strip, drawn left→right
    final y0 = size.height * 0.72, amp = size.height * 0.13;
    final wave = Path();
    const n = 48;
    for (var i = 0; i <= n; i++) {
      final t = i / n;
      final x = size.width * (0.08 + 0.84 * t);
      final y = y0 - math.sin(t * 3 * 2 * math.pi) * amp;
      if (i == 0) {
        wave.moveTo(x, y);
      } else {
        wave.lineTo(x, y);
      }
    }
    // centerline
    canvas.drawLine(Offset(size.width * 0.08, y0), Offset(size.width * 0.92, y0),
        _stroke(Colors.white.withValues(alpha: 0.18), u * 0.01));
    canvas.drawPath(
      wave,
      _stroke(accent.withValues(alpha: 0.5), u * 0.035)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(wave, _stroke(accent.withValues(alpha: 0.95), u * 0.02));
  }

  // ── 2.8 — AC sails across: a thin cool route line crossing dark terrain to a
  //         cluster of lit windows (the far city) ───────────────────────────────
  void _ep2AcSailsAcross(Canvas canvas, Offset c, double u, Size size) {
    _ep2Field(canvas, size, const [Color(0xFF0A1020), Color(0xFF05070E)]);
    // faint terrain ridge
    final ridge = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.64,
          size.width * 0.6, size.height * 0.70)
      ..quadraticBezierTo(size.width * 0.82, size.height * 0.74, size.width, size.height * 0.68);
    canvas.drawPath(ridge, _stroke(Colors.white.withValues(alpha: 0.06), u * 0.02));
    // the cool route from the plant (lower-left) to the city (upper-right)
    final plant = Offset(size.width * 0.10, size.height * 0.80);
    final city = Offset(size.width * 0.80, size.height * 0.30);
    final route = Path()
      ..moveTo(plant.dx, plant.dy)
      ..quadraticBezierTo(size.width * 0.40, size.height * 0.66, city.dx, city.dy);
    canvas.drawPath(route,
        _stroke(_ep2Blue.withValues(alpha: 0.45), u * 0.035)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawPath(route, _stroke(_ep2Blue.withValues(alpha: 0.9), u * 0.014));
    // a few thin fast pulse dots
    for (var i = 0; i < 3; i++) {
      final t = 0.25 + i * 0.22;
      final p = Offset.lerp(plant, city, t)!;
      canvas.drawCircle(Offset(p.dx, p.dy - u * 0.02), u * 0.018,
          Paint()..color = _ep2Blue.withValues(alpha: 0.95));
    }
    // the small dim plant at the route's start
    canvas.drawRect(
      Rect.fromCenter(center: plant, width: u * 0.10, height: u * 0.08),
      Paint()..color = const Color(0xFF2A2F45),
    );
    // the far city — lit windows + warm bloom
    _glow(canvas, city, u * 0.26, accent.withValues(alpha: 0.45));
    final win = Paint()..color = const Color(0xFFFFE7A0);
    final widths = [0.05, 0.04, 0.06, 0.045, 0.05];
    final heights = [0.06, 0.10, 0.05, 0.12, 0.07];
    double x = city.dx - size.width * 0.13;
    final baseY = city.dy + size.height * 0.10;
    for (var i = 0; i < widths.length; i++) {
      final w = size.width * widths[i], h = size.height * heights[i];
      canvas.drawRect(Rect.fromLTWH(x, baseY - h, w, h), win);
      x += w + size.width * 0.012;
    }
  }

  @override
  bool shouldRepaint(EvidenceMotifPainter old) => old.motif != motif || old.accent != accent;
}
