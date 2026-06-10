// The card's signature visuals (the one place boldness is spent): a
// circuit-trace guilloché frame and the energy-loop motif. Everything else on
// the card stays quiet around these. Foundational cards render the frame
// PRISMATIC (full-spectrum) to mark them as the rarest.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'collectible_models.dart';

const Color _gold = Color(0xFFF5C451);
const Color _goldBright = Color(0xFFFFD970);

/// Full-spectrum sweep for the Foundations (prismatic) treatment, at a chosen
/// opacity. [phase] rotates the spectrum so a slow drift reads as shimmer.
Shader prismaticShader(Rect rect, {double opacity = 1, double phase = 0}) {
  Color c(double h) => HSVColor.fromAHSV(opacity, (h * 360) % 360, 0.45, 1.0).toColor();
  return SweepGradient(
    transform: GradientRotation(phase),
    colors: [c(0), c(.17), c(.34), c(.5), c(.67), c(.84), c(1)],
    stops: const [0, .17, .34, .5, .67, .84, 1],
  ).createShader(rect);
}

/// Circuit-trace guilloché frame + the gold hairline. Drawn in the band between
/// the card's outer edge and the inner body. Fine concentric line-work
/// (banknote/certificate semiotics) grounded in circuit traces + nodes.
class GuillocheFramePainter extends CustomPainter {
  GuillocheFramePainter({
    required this.section,
    required this.radius,
    required this.band,
    this.phase = 0,
  });

  final CardSection section;
  final double radius; // outer corner radius
  final double band; // frame thickness
  final double phase; // animates the prismatic drift

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final innerR = (radius - band).clamp(2.0, radius);
    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(band, band, size.width - 2 * band, size.height - 2 * band),
      Radius.circular(innerR),
    );

    // 1) Frame fill — prismatic (Foundations) or a tinted accent gradient.
    canvas.save();
    canvas.clipPath(Path()..addRRect(outer)..addRRect(inner), doAntiAlias: true);
    final fullRect = Offset.zero & size;
    final fillPaint = Paint();
    if (section.isPrismatic) {
      fillPaint.shader = prismaticShader(fullRect, opacity: 0.5, phase: phase);
    } else {
      fillPaint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [section.accent.withValues(alpha: 0.55), section.accent.withValues(alpha: 0.18)],
      ).createShader(fullRect);
    }
    canvas.drawRRect(outer, Paint()..color = const Color(0xFF0B1026));
    canvas.drawRRect(outer, fillPaint);

    // 2) Guilloché line-work — fine concentric rounded rects (the "engraved"
    //    feel) in the accent/white at low opacity.
    final lineColor = section.isPrismatic
        ? Colors.white.withValues(alpha: 0.22)
        : section.accent.withValues(alpha: 0.5);
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = lineColor;
    const lines = 7;
    for (var i = 0; i < lines; i++) {
      final t = i / (lines - 1);
      final inset = t * (band - 2);
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(inset, inset, size.width - 2 * inset, size.height - 2 * inset),
        Radius.circular((radius - inset).clamp(2.0, radius)),
      );
      canvas.drawRRect(r, linePaint);
    }
    canvas.restore();

    // 3) Circuit traces + nodes riding the frame — L-bends with little solder
    //    dots, the literal "this is a circuit" grounding.
    _circuitTraces(canvas, size, section.accent);

    // 4) Gold hairline just inside the frame band — the certified edge.
    canvas.drawRRect(
      inner.inflate(1.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..shader = LinearGradient(colors: [_gold, _goldBright, _gold]).createShader(fullRect),
    );
  }

  void _circuitTraces(Canvas canvas, Size size, Color accent) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..color = (section.isPrismatic ? _goldBright : accent).withValues(alpha: 0.85);
    final dot = Paint()..color = _goldBright.withValues(alpha: 0.95);
    final mid = band / 2;
    // One trace + node near the middle of each edge, bending toward a corner.
    final pts = <List<Offset>>[
      [Offset(size.width * 0.30, mid), Offset(size.width * 0.42, mid), Offset(size.width * 0.42, mid + 5)],
      [Offset(size.width * 0.70, size.height - mid), Offset(size.width * 0.58, size.height - mid), Offset(size.width * 0.58, size.height - mid - 5)],
      [Offset(mid, size.height * 0.62), Offset(mid, size.height * 0.50), Offset(mid + 5, size.height * 0.50)],
      [Offset(size.width - mid, size.height * 0.38), Offset(size.width - mid, size.height * 0.50), Offset(size.width - mid - 5, size.height * 0.50)],
    ];
    for (final tr in pts) {
      final path = Path()..moveTo(tr.first.dx, tr.first.dy);
      for (final pt in tr.skip(1)) {
        path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path, p);
      canvas.drawCircle(tr.first, 2.4, dot);
    }
  }

  @override
  bool shouldRepaint(GuillocheFramePainter old) => old.phase != phase || old.section != section;
}

/// The energy-loop motif: arm → spark → light/heat/sound, cycling. A flowing
/// ring with five icon nodes and directional arrows — the law in one glance.
class EnergyLoopPainter extends CustomPainter {
  EnergyLoopPainter({required this.section, this.phase = 0});

  final CardSection section;
  final double phase; // rotates the prismatic ring + flow dashes

  static const _nodes = <IconData>[
    Icons.back_hand_rounded, // arm (your hand)
    Icons.bolt_rounded, // spark
    Icons.lightbulb_rounded, // light
    Icons.local_fire_department_rounded, // heat
    Icons.graphic_eq_rounded, // sound
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) * 0.36;
    final ringRect = Rect.fromCircle(center: c, radius: r);

    // The flow ring — prismatic for Foundations, accent otherwise.
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    if (section.isPrismatic) {
      ringPaint.shader = prismaticShader(ringRect, opacity: 0.95, phase: phase);
    } else {
      ringPaint.color = section.accent;
    }
    // Dashed arc to read as "flow" (gaps animate via phase).
    const seg = 18;
    for (var i = 0; i < seg; i++) {
      if (i.isOdd) continue;
      final a0 = (i / seg) * 2 * math.pi + phase;
      final a1 = ((i + 0.7) / seg) * 2 * math.pi + phase;
      canvas.drawArc(ringRect, a0, a1 - a0, false, ringPaint);
    }

    // Five nodes around the ring, each a glowing chip with an icon.
    for (var i = 0; i < _nodes.length; i++) {
      final ang = -math.pi / 2 + i * (2 * math.pi / _nodes.length);
      final p = c + Offset(math.cos(ang), math.sin(ang)) * r;
      final nodeColor = section.isPrismatic
          ? HSVColor.fromAHSV(1, (i / _nodes.length * 300), 0.5, 1).toColor()
          : section.accent;
      canvas.drawCircle(p, 15, Paint()..color = nodeColor.withValues(alpha: 0.18));
      canvas.drawCircle(
        p,
        13,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = nodeColor.withValues(alpha: 0.9),
      );
      _icon(canvas, _nodes[i], p, 15, Colors.white);
    }

    // Directional arrowheads between nodes (the cycle direction).
    final arrow = Paint()
      ..color = (section.isPrismatic ? _goldBright : section.accent).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < _nodes.length; i++) {
      final ang = -math.pi / 2 + (i + 0.5) * (2 * math.pi / _nodes.length);
      final p = c + Offset(math.cos(ang), math.sin(ang)) * r;
      final tangent = ang + math.pi / 2;
      _arrowHead(canvas, p, tangent, 5, arrow);
    }
  }

  void _arrowHead(Canvas canvas, Offset at, double dir, double s, Paint paint) {
    final path = Path()
      ..moveTo(at.dx + math.cos(dir) * s, at.dy + math.sin(dir) * s)
      ..lineTo(at.dx + math.cos(dir + 2.5) * s, at.dy + math.sin(dir + 2.5) * s)
      ..lineTo(at.dx + math.cos(dir - 2.5) * s, at.dy + math.sin(dir - 2.5) * s)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _icon(Canvas canvas, IconData icon, Offset center, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: fontSize,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(EnergyLoopPainter old) => old.phase != phase;
}

/// Card 02 motif — a bar magnet sweeping past a coil, field lines blooming only
/// in motion (the induction picture, grounded in what the kid felt). Restrained,
/// accent-tinted; [phase] drives the sweep + the field-line bloom pulse.
class InductionMotifPainter extends CustomPainter {
  InductionMotifPainter({required this.section, this.phase = 0});

  final CardSection section;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final accent = section.isPrismatic ? _goldBright : section.accent;
    final c = Offset(size.width / 2, size.height / 2);
    final unit = math.min(size.width, size.height);

    // The coil — a short solenoid of stacked ellipses on the right.
    final coilX = c.dx + unit * 0.34;
    final coilH = unit * 0.5;
    final ringW = unit * 0.16;
    final ringH = unit * 0.072;
    final coilPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.82);
    const rings = 6;
    for (var i = 0; i < rings; i++) {
      final y = c.dy - coilH / 2 + coilH * (i / (rings - 1));
      canvas.drawOval(
        Rect.fromCenter(center: Offset(coilX, y), width: ringW, height: ringH),
        coilPaint,
      );
    }
    // Lead from the coil down toward the wire/lamp (off-card).
    canvas.drawLine(
      Offset(coilX, c.dy + coilH / 2 + ringH * 0.4),
      Offset(coilX, c.dy + coilH / 2 + unit * 0.16),
      coilPaint..strokeWidth = 2.0,
    );

    // The magnet — mid-sweep toward the coil. A faint motion-trail behind it
    // (it only works while moving), and field-line arcs blooming from the poles.
    final sweep = 0.5 + 0.5 * math.sin(phase); // 0..1 across the sweep
    final magCx = c.dx - unit * 0.32 + sweep * unit * 0.18;
    final magCy = c.dy;
    final magW = unit * 0.34;
    final magH = unit * 0.14;
    final bloom = (0.45 + 0.55 * (0.5 + 0.5 * math.sin(phase * 2))).clamp(0.0, 1.0);

    // Field-line bloom — concentric arcs hugging the coil-facing pole.
    final fieldPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final pole = Offset(magCx + magW / 2, magCy);
    for (var i = 0; i < 3; i++) {
      final rr = unit * (0.07 + i * 0.052);
      fieldPaint.color = accent.withValues(alpha: (0.55 - i * 0.14) * bloom);
      canvas.drawArc(
        Rect.fromCircle(center: pole, radius: rr),
        -math.pi / 2.3,
        math.pi / 1.15,
        false,
        fieldPaint,
      );
    }

    // Motion trail — two short streaks behind the magnet.
    final trail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.35 * bloom);
    for (final dy in [-magH * 0.3, magH * 0.3]) {
      canvas.drawLine(
        Offset(magCx - magW / 2 - unit * 0.07, magCy + dy),
        Offset(magCx - magW / 2 - unit * 0.015, magCy + dy),
        trail,
      );
    }

    // The bar magnet body — two halves (N coil-facing accent, S cool).
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(magCx, magCy), width: magW, height: magH),
      Radius.circular(magH * 0.28),
    );
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      Rect.fromLTWH(magCx - magW / 2, magCy - magH / 2, magW / 2, magH),
      Paint()..color = const Color(0xFF4A6CC8), // S
    );
    canvas.drawRect(
      Rect.fromLTWH(magCx, magCy - magH / 2, magW / 2, magH),
      Paint()..color = accent.withValues(alpha: 0.95), // N (toward the coil)
    );
    canvas.restore();
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.7),
    );
    _poleGlyph(canvas, 'N', Offset(magCx + magW * 0.25, magCy), magH * 0.46);
    _poleGlyph(canvas, 'S', Offset(magCx - magW * 0.25, magCy), magH * 0.46);

    // Sweep-direction arrow under the magnet.
    final arrow = Paint()..color = accent.withValues(alpha: 0.85);
    final ay = magCy + magH * 0.95;
    canvas.drawLine(
      Offset(magCx - magW * 0.2, ay),
      Offset(magCx + magW * 0.32, ay),
      Paint()
        ..color = accent.withValues(alpha: 0.6)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
    final tip = Offset(magCx + magW * 0.34, ay);
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tip.dx - unit * 0.035, tip.dy - unit * 0.022)
        ..lineTo(tip.dx - unit * 0.035, tip.dy + unit * 0.022)
        ..close(),
      arrow,
    );
  }

  void _poleGlyph(Canvas canvas, String s, Offset center, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(InductionMotifPainter old) =>
      old.phase != phase || old.section != section;
}

/// Card 03 — "No Free Lunch". A two-pan balance that gently rocks but never sits
/// level: one pan holds the warm, clean light (the good); the other holds the
/// haze + cost it takes (the catch). The trade-off the kid FELT across the
/// sources, made into one quiet icon. [phase] rocks the beam; restrained,
/// accent-tinted.
class TradeoffMotifPainter extends CustomPainter {
  TradeoffMotifPainter({required this.section, this.phase = 0});

  final CardSection section;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final accent = section.isPrismatic ? _goldBright : section.accent;
    final c = Offset(size.width / 2, size.height / 2);
    final unit = math.min(size.width, size.height);

    final pivot = Offset(c.dx, c.dy - unit * 0.04);
    final angle = 0.17 * math.sin(phase); // a slow rock, ±~10° — never level
    final halfBeam = unit * 0.34;
    final cord = unit * 0.16;

    Offset end(double sign) =>
        pivot + Offset(sign * halfBeam * math.cos(angle), sign * halfBeam * math.sin(angle));
    final leftEnd = end(-1), rightEnd = end(1);
    final leftPan = leftEnd + Offset(0, cord);
    final rightPan = rightEnd + Offset(0, cord);

    final metal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.85);

    // Fulcrum post + base.
    final baseY = c.dy + unit * 0.34;
    canvas.drawLine(pivot, Offset(pivot.dx, baseY), metal);
    canvas.drawPath(
      Path()
        ..moveTo(pivot.dx - unit * 0.07, baseY)
        ..lineTo(pivot.dx + unit * 0.07, baseY)
        ..lineTo(pivot.dx, baseY - unit * 0.1)
        ..close(),
      Paint()..color = accent.withValues(alpha: 0.5),
    );

    // Beam + pivot cap.
    canvas.drawLine(leftEnd, rightEnd, metal);
    canvas.drawCircle(pivot, unit * 0.022, Paint()..color = accent);

    // Cords + pans (shallow bowls).
    for (final p in [_PanSide(leftEnd, leftPan), _PanSide(rightEnd, rightPan)]) {
      canvas.drawLine(p.from, p.pan, metal..strokeWidth = 1.4);
      canvas.drawArc(
        Rect.fromCenter(center: p.pan, width: unit * 0.26, height: unit * 0.18),
        0.15 * math.pi,
        0.7 * math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.85),
      );
    }

    // Left pan: the clean warm light (a small sun).
    final sunC = leftPan + Offset(0, -unit * 0.055);
    canvas.drawCircle(sunC, unit * 0.06,
        Paint()..color = accent.withValues(alpha: 0.28)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(sunC, unit * 0.045, Paint()..color = accent);
    final ray = Paint()
      ..color = accent.withValues(alpha: 0.8)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        sunC + Offset(math.cos(a), math.sin(a)) * unit * 0.058,
        sunC + Offset(math.cos(a), math.sin(a)) * unit * 0.078,
        ray,
      );
    }

    // Right pan: the catch — a smog puff over a coin stack (haze + cost).
    final stackC = rightPan + Offset(0, -unit * 0.05);
    final coin = Paint()..color = Colors.white.withValues(alpha: 0.72);
    for (var i = 0; i < 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(center: stackC + Offset(0, i * unit * 0.026), width: unit * 0.11, height: unit * 0.034),
        coin,
      );
    }
    final smogC = stackC + Offset(0, -unit * 0.075);
    final smog = Paint()..color = const Color(0xFF8A8270).withValues(alpha: 0.6);
    canvas.drawCircle(smogC, unit * 0.03, smog);
    canvas.drawCircle(smogC + Offset(unit * 0.028, unit * 0.006), unit * 0.024, smog);
    canvas.drawCircle(smogC - Offset(unit * 0.026, -unit * 0.004), unit * 0.022, smog);
  }

  @override
  bool shouldRepaint(TradeoffMotifPainter old) => old.phase != phase || old.section != section;
}

class _PanSide {
  _PanSide(this.from, this.pan);
  final Offset from, pan;
}

/// Card 04 — "The Great Escape". A warm energy stream pours down the centre and
/// NARROWS as heat wisps peel off sideways at each step, so only a thin survivor
/// reaches a small bulb at the bottom — the leaky bucket in one glance, and the
/// consequence of Card 01's law. [phase] drifts the escaping wisps upward+outward
/// on a loop; accent-tinted (Generation amber), heat in a hotter orange.
class EscapeMotifPainter extends CustomPainter {
  EscapeMotifPainter({required this.section, this.phase = 0});

  final CardSection section;
  final double phase;

  static const Color _heat = Color(0xFFFF7A2E);

  @override
  void paint(Canvas canvas, Size size) {
    final accent = section.isPrismatic ? _goldBright : section.accent;
    final c = Offset(size.width / 2, size.height / 2);
    final unit = math.min(size.width, size.height);
    final colX = c.dx;
    final topY = c.dy - unit * 0.42;
    final bulbY = c.dy + unit * 0.40;
    final streamBottom = bulbY - unit * 0.12;

    final topHalf = unit * 0.135;
    final botHalf = unit * 0.035; // the thin survivor

    double halfAt(double t) => topHalf + (botHalf - topHalf) * t; // t: 0 top → 1 bottom

    // The tapering stream as a filled path.
    const steps = 28;
    final left = <Offset>[];
    final right = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final y = topY + (streamBottom - topY) * t;
      final hw = halfAt(t);
      left.add(Offset(colX - hw, y));
      right.add(Offset(colX + hw, y));
    }
    final stream = Path()..moveTo(left.first.dx, left.first.dy);
    for (final p in left.skip(1)) {
      stream.lineTo(p.dx, p.dy);
    }
    for (final p in right.reversed) {
      stream.lineTo(p.dx, p.dy);
    }
    stream.close();
    canvas.drawPath(
      stream,
      Paint()
        ..color = accent.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(stream, Paint()..color = accent.withValues(alpha: 0.85));

    // Heat wisps peeling off at three steps, alternating sides, looping up+out.
    for (var i = 0; i < 3; i++) {
      final t = 0.22 + i * 0.26;
      final y = topY + (streamBottom - topY) * t;
      final sign = i.isEven ? -1.0 : 1.0;
      final frac = ((phase / (2 * math.pi)) + i / 3.0) % 1.0;
      final base = Offset(colX + sign * halfAt(t), y);
      final tip = base + Offset(sign * unit * (0.10 + 0.16 * frac), -unit * (0.04 + 0.12 * frac));
      final a = (1 - frac) * 0.8;
      final r = unit * (0.03 + 0.02 * frac);
      canvas.drawCircle(tip, r, Paint()
        ..color = _heat.withValues(alpha: a)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r));
    }

    // The small survivor bulb.
    canvas.drawCircle(Offset(colX, bulbY), unit * 0.07,
        Paint()..color = const Color(0xFFFFE9A8).withValues(alpha: 0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(Offset(colX, bulbY), unit * 0.045, Paint()..color = const Color(0xFFFFE9A8));
  }

  @override
  bool shouldRepaint(EscapeMotifPainter old) => old.phase != phase || old.section != section;
}

/// Card 05 — "The Grid Is a Mix". Several distinct source-glyphs (sun, flame,
/// wind, water, atom) arc across the top, each feeding a line into ONE central grid
/// hub that lights a small town below — the synthesis the kid BUILT: many sources,
/// one grid, because no single one is complete. Each feed-line pulses in turn
/// ([phase]) so the "they take turns covering" reads. Restrained, accent-tinted.
class SynthesisMotifPainter extends CustomPainter {
  SynthesisMotifPainter({required this.section, this.phase = 0});

  final CardSection section;
  final double phase;

  static const _sources = <(IconData, Color)>[
    (Icons.local_fire_department_rounded, Color(0xFFFF7A2E)), // coal/flame
    (Icons.bolt_rounded, Color(0xFFB08CF7)), // nuclear
    (Icons.air_rounded, Color(0xFF6FE0C8)), // wind
    (Icons.wb_sunny_rounded, Color(0xFFFFD15C)), // solar
    (Icons.water_drop_rounded, Color(0xFF3FB9F5)), // hydro
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final accent = section.isPrismatic ? _goldBright : section.accent;
    final c = Offset(size.width / 2, size.height / 2);
    final unit = math.min(size.width, size.height);
    final hub = Offset(c.dx, c.dy + unit * 0.14);
    final arcR = unit * 0.40;
    final arcC = Offset(c.dx, c.dy + unit * 0.30);

    // Feed-lines from each source to the hub, one pulsing brighter in turn.
    final lit = (phase / (2 * math.pi) * _sources.length).floor() % _sources.length;
    for (var i = 0; i < _sources.length; i++) {
      final ang = math.pi + (i + 0.5) * (math.pi / _sources.length); // top half-arc
      final p = arcC + Offset(math.cos(ang), math.sin(ang)) * arcR;
      final on = i == lit;
      canvas.drawLine(
        p,
        hub,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = on ? 2.4 : 1.3
          ..strokeCap = StrokeCap.round
          ..color = _sources[i].$2.withValues(alpha: on ? 0.95 : 0.4),
      );
    }
    // The source nodes on the arc.
    for (var i = 0; i < _sources.length; i++) {
      final ang = math.pi + (i + 0.5) * (math.pi / _sources.length);
      final p = arcC + Offset(math.cos(ang), math.sin(ang)) * arcR;
      final col = _sources[i].$2;
      canvas.drawCircle(p, unit * 0.085, Paint()..color = col.withValues(alpha: 0.18));
      canvas.drawCircle(
        p,
        unit * 0.075,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = col.withValues(alpha: 0.9),
      );
      _glyph(canvas, _sources[i].$1, p, unit * 0.085, Colors.white);
    }

    // The grid hub — a glowing node ringed in accent.
    canvas.drawCircle(hub, unit * 0.12,
        Paint()..color = accent.withValues(alpha: 0.22)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawCircle(hub, unit * 0.085, Paint()..color = const Color(0xFF0B1026));
    canvas.drawCircle(hub, unit * 0.085,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 1.8..color = accent);
    _glyph(canvas, Icons.hub_rounded, hub, unit * 0.10, accent);

    // The lit town the mix keeps powered — a small skyline glow at the bottom.
    final townY = hub.dy + unit * 0.26;
    canvas.drawLine(hub + Offset(0, unit * 0.085), Offset(hub.dx, townY - unit * 0.04),
        Paint()..strokeWidth = 1.4..color = accent.withValues(alpha: 0.6));
    final glow = Paint()
      ..color = const Color(0xFFFFE9A8).withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(hub.dx, townY), unit * 0.10, glow);
    final b = Paint()..color = const Color(0xFFFFE7A0);
    final widths = [0.05, 0.04, 0.06, 0.04, 0.05];
    final heights = [0.05, 0.08, 0.04, 0.09, 0.06];
    double x = hub.dx - unit * 0.15;
    for (var i = 0; i < widths.length; i++) {
      final w = unit * widths[i], h = unit * heights[i];
      canvas.drawRect(Rect.fromLTWH(x, townY - h, w, h), b);
      x += w + unit * 0.012;
    }
  }

  void _glyph(Canvas canvas, IconData icon, Offset center, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: fontSize,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(SynthesisMotifPainter old) => old.phase != phase || old.section != section;
}

/// De-extinction Prologue motif — a single coiled DNA strand stamped like a
/// certified specimen (PRD §8). Two helical rails + rungs, prismatic for the
/// Foundations treatment; [phase] drifts a soft sheen up the strand.
class RecipeMotifPainter extends CustomPainter {
  RecipeMotifPainter({required this.section, this.phase = 0});

  final CardSection section;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final unit = math.min(size.width, size.height);
    final halfH = unit * 0.4; // strand runs vertically
    final amp = unit * 0.17; // helix radius
    final accent = section.isPrismatic ? _goldBright : section.accent;
    final rect = Rect.fromCenter(center: c, width: amp * 2, height: halfH * 2);

    Paint railPaint() {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      if (section.isPrismatic) {
        p.shader = prismaticShader(rect, opacity: 0.95, phase: phase);
      } else {
        p.color = accent;
      }
      return p;
    }

    const steps = 40;
    Offset railPoint(int i, double dir) {
      final t = i / steps;
      final y = c.dy - halfH + 2 * halfH * t;
      final x = c.dx + dir * math.sin(t * 2.6 * math.pi + phase * 0.6) * amp;
      return Offset(x, y);
    }

    // The two rails.
    for (final dir in [1.0, -1.0]) {
      final path = Path();
      for (var i = 0; i <= steps; i++) {
        final p = railPoint(i, dir);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, railPaint());
    }

    // Rungs + base-pair nodes, with a sheen pulse riding up the strand.
    final rungBase = Paint()
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 2; i <= steps - 2; i += 3) {
      final a = railPoint(i, 1);
      final b = railPoint(i, -1);
      final t = i / steps;
      // sheen: a soft bright band sweeping 0→1 with phase.
      final sweep = (phase / (2 * math.pi)) % 1.0;
      final glow = (1 - (((t - sweep).abs()) * 3)).clamp(0.0, 1.0);
      final nodeColor = section.isPrismatic
          ? HSVColor.fromAHSV(1, (t * 320) % 360, 0.5, 1).toColor()
          : accent;
      canvas.drawLine(a, b, rungBase..color = Colors.white.withValues(alpha: 0.45 + 0.4 * glow));
      canvas.drawCircle(a, 2.6 + glow, Paint()..color = nodeColor.withValues(alpha: 0.9));
      canvas.drawCircle(b, 2.6 + glow, Paint()..color = nodeColor.withValues(alpha: 0.9));
    }

    // A faint certified-specimen seal ring behind the strand.
    canvas.drawCircle(
      c,
      unit * 0.46,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = (section.isPrismatic ? Colors.white : accent).withValues(alpha: 0.12),
    );
  }

  @override
  bool shouldRepaint(RecipeMotifPainter old) => old.phase != phase || old.section != section;
}
