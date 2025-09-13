import 'dart:math' as math;
import 'package:flutter/material.dart';

class ScribbleBorderPainter extends CustomPainter {
  ScribbleBorderPainter({
    required this.color,
    required this.radius,
    this.strokeWidth = 1.2,
    this.step = 6.0, // distance between sample points
    this.jitter = 1.4, // how “wobbly” the line is
    this.seed, // stable per-tab seed (e.g., hash of id)
    this.drawTop = true,
    this.drawRight = true,
    this.drawBottom = true,
    this.drawLeft = true,
    this.doubleStroke = true, // draw a second pass for pencil feel
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double step;
  final double jitter;
  final int? seed;
  final bool drawTop, drawRight, drawBottom, drawLeft;
  final bool doubleStroke;

  late final _rng = math.Random(seed ?? 1337);

  // stable pseudo-random in [-1, 1]
  double _randUnit() => _rng.nextDouble() * 2 - 1;

  // Jitters a point along its outward normal
  Offset _jitterPoint(Offset p, Offset normal, double amp) {
    final a = amp * _randUnit();
    return Offset(p.dx + normal.dx * a, p.dy + normal.dy * a);
  }

  void _roughLine(Canvas c, Paint p, Offset a, Offset b) {
    final dir = (b - a);
    final len = dir.distance;
    if (len <= 0) return;
    final n = Offset(-dir.dy / len, dir.dx / len); // outward normal
    double t = 0;
    Offset prev = a;
    while (t < len) {
      final nt = math.min(len, t + step);
      final pos = a + dir * (nt / len);
      final jPrev = _jitterPoint(prev, n, jitter);
      final jPos = _jitterPoint(pos, n, jitter);
      c.drawLine(jPrev, jPos, p);
      prev = pos;
      t = nt;
    }
  }

  void _roughArc(Canvas c, Paint p, Rect rect, double start, double sweep) {
    final r = rect.width / 2;
    final cx = rect.left + r, cy = rect.top + r;
    final perim = r * sweep;
    final steps = math.max(4, (perim / step).round());
    Offset polar(double ang) =>
        Offset(cx + r * math.cos(ang), cy + r * math.sin(ang));
    Offset normal(double ang) =>
        Offset(math.cos(ang), math.sin(ang)); // outward
    var prev = polar(start);
    for (int i = 1; i <= steps; i++) {
      final ang = start + sweep * (i / steps);
      final pt = polar(ang);
      final jPrev = _jitterPoint(prev, normal(ang), jitter);
      final jPt = _jitterPoint(pt, normal(ang), jitter);
      c.drawLine(jPrev, jPt, p);
      prev = pt;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void pass(double widthScale, double jitterScale) {
      final p = paint..strokeWidth = strokeWidth * widthScale;
      final j = jitter * jitterScale;

      // Edges (skip corners by radius)
      if (drawTop)
        _roughLine(
            canvas, p, Offset(radius, 0), Offset(size.width - radius, 0));
      if (drawRight)
        _roughLine(canvas, p, Offset(size.width, radius),
            Offset(size.width, size.height - radius));
      if (drawBottom)
        _roughLine(canvas, p, Offset(size.width - radius, size.height),
            Offset(radius, size.height));
      if (drawLeft)
        _roughLine(
            canvas, p, Offset(0, radius), Offset(0, size.height - radius));

      // Corners (quarter arcs, clockwise; Flutter’s Y grows down)
      // TL: 180°→270°, TR: 270°→360°, BR: 0°→90°, BL: 90°→180°
      _roughArc(canvas, p, Rect.fromLTWH(0, 0, radius * 2, radius * 2), math.pi,
          math.pi / 2);
      _roughArc(
          canvas,
          p,
          Rect.fromLTWH(size.width - radius * 2, 0, radius * 2, radius * 2),
          3 * math.pi / 2,
          math.pi / 2);
      _roughArc(
          canvas,
          p,
          Rect.fromLTWH(size.width - radius * 2, size.height - radius * 2,
              radius * 2, radius * 2),
          0,
          math.pi / 2);
      _roughArc(
          canvas,
          p,
          Rect.fromLTWH(0, size.height - radius * 2, radius * 2, radius * 2),
          math.pi / 2,
          math.pi / 2);
    }

    // First pass (thin), second pass slightly thicker & offset → pencil vibe
    pass(1.0, 1.0);
    if (doubleStroke) pass(0.7, 0.5);
  }

  @override
  bool shouldRepaint(covariant ScribbleBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.step != step ||
      old.jitter != jitter ||
      old.seed != seed ||
      old.drawTop != drawTop ||
      old.drawRight != drawRight ||
      old.drawBottom != drawBottom ||
      old.drawLeft != drawLeft ||
      old.doubleStroke != doubleStroke;
}
