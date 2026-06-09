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
