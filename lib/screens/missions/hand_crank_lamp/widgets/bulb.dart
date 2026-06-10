// The glass bulb — ported from trace_it_back's BulbLayer so both electricity
// activities share the same premium lamp (product cohesion, like Voltix).
//
// A real glowing glass globe: layered glass gradient, a filament that heats with
// brightness, filament leads, an inner warm wash, a specular highlight, and a
// metallic screw base. Parameterised by center / radius / brightness only.
//
// IMPORTANT (PRD §4.4): the filament glow is driven STRAIGHT off `brightness`,
// which the controller hard-zeroes on stop — so it snaps to dark instantly, no
// cooling fade. Never animate a filament cool-down here; that would undo the
// instant-cutoff lesson.

import 'package:flutter/material.dart';

const Color _warm = Color(0xFFFFE9B8);
const Color _warmHot = Color(0xFFFFF6E0);
const Color _steelLite = Color(0xFFC8D4F0);
const Color _glassOff = Color(0xFF505E92);
const Color _glassDeep = Color(0xFF34406E);

Paint _glow(Color color, double sigma, {double alpha = 1}) => Paint()
  ..color = color.withValues(alpha: alpha)
  ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);

/// The bottom of the screw base, relative to the globe centre — the natural
/// point to run the wire to. (radius units below the centre.)
double bulbBaseDrop(double radius) => radius * 1.35;

/// Draw the bulb with its globe centred at [center], [radius] the globe radius,
/// and [brightness] in [0,1].
void paintBulb(Canvas canvas, Offset center, double radius, double brightness) {
  final ctr = center;
  final r = radius;
  final b = brightness.clamp(0.0, 1.0);

  // Metallic screw base.
  final base = RRect.fromRectAndRadius(
    Rect.fromCenter(center: ctr.translate(0, r * 1.02), width: r * 0.82, height: r * 0.66),
    Radius.circular(r * 0.12),
  );
  canvas.drawRRect(
    base,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF5A6488), Color(0xFFAEB8D8), Color(0xFF5A6488)],
      ).createShader(base.outerRect),
  );
  for (var i = 0; i < 3; i++) {
    final y = ctr.dy + r * 0.82 + i * r * 0.16;
    canvas.drawLine(
      Offset(ctr.dx - r * 0.4, y),
      Offset(ctr.dx + r * 0.4, y),
      Paint()
        ..color = const Color(0xFF2A3358).withValues(alpha: 0.6)
        ..strokeWidth = 1.4,
    );
  }

  // Glass globe — dark when off, but FILLS with warm light as it brightens
  // (a luminous amber centre fading to a warm edge), so the bulb truly glows.
  final globeMid = Color.lerp(_glassOff, const Color(0xFFFFD489), b)!;
  final globeEdge = Color.lerp(_glassDeep, const Color(0xFF7C571F), b)!;
  canvas.drawCircle(
    ctr,
    r,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.18, -0.22),
        radius: 0.95,
        colors: [globeMid, globeEdge],
      ).createShader(Rect.fromCircle(center: ctr, radius: r)),
  );

  // Filament — a zigzag that heats up.
  final fil = Path();
  final fw = r * 0.5, fh = r * 0.42;
  fil.moveTo(ctr.dx - fw / 2, ctr.dy + fh / 2);
  const seg = 5;
  for (var i = 0; i <= seg; i++) {
    final x = ctr.dx - fw / 2 + fw * i / seg;
    final y = ctr.dy + (i.isEven ? fh / 2 : -fh / 2);
    fil.lineTo(x, y);
  }
  final filColor = Color.lerp(const Color(0xFF55504A), _warmHot, b)!;
  if (b > 0.02) {
    canvas.drawPath(
      fil,
      _glow(_warm, r * 0.18, alpha: 0.8 * b)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.06
        ..strokeCap = StrokeCap.round,
    );
  }
  canvas.drawPath(
    fil,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.035
      ..strokeCap = StrokeCap.round
      ..color = filColor,
  );
  // Filament leads.
  canvas.drawLine(
    Offset(ctr.dx - fw / 2, ctr.dy + fh / 2),
    Offset(ctr.dx - fw / 2, ctr.dy + r * 0.7),
    Paint()
      ..color = const Color(0xFF6A748F)
      ..strokeWidth = 1.6,
  );
  canvas.drawLine(
    Offset(ctr.dx + fw / 2, ctr.dy + fh / 2),
    Offset(ctr.dx + fw / 2, ctr.dy + r * 0.7),
    Paint()
      ..color = const Color(0xFF6A748F)
      ..strokeWidth = 1.6,
  );

  // Inner warm glow when lit — an additive bloom that fills the globe with
  // light (hot at the centre, fading to the glass edge). This is what makes the
  // inside read as glowing, on top of the warmed glass + the filament.
  if (b > 0.01) {
    canvas.drawCircle(
      ctr,
      r * 0.96,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            _warmHot.withValues(alpha: 0.6 * b),
            _warm.withValues(alpha: 0.24 * b),
            _warm.withValues(alpha: 0),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(Rect.fromCircle(center: ctr, radius: r * 0.96)),
    );
  }

  // Glass rim + specular highlight.
  canvas.drawCircle(
    ctr,
    r,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = _steelLite.withValues(alpha: 0.5),
  );
  canvas.drawCircle(ctr.translate(-r * 0.34, -r * 0.4), r * 0.16, _glow(Colors.white, r * 0.12, alpha: 0.5));
}
