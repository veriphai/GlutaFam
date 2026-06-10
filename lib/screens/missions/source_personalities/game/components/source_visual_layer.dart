// Source visual — the swappable plant feeding the town, each visually tied to its
// consequence (PRD §7): a solar array that catches/loses the sun, a wind turbine
// that spins with the gusts, a coal stack feeding the haze, a clean nuclear tower,
// a hydro dam with a reservoir gauge. Plus the output conduit carrying warm pulses
// to the town while it's actually supplying power.
//
// Pure renderer; all state (which source, sun, gust, water, townLight) from the
// controller. No labels — the plant's behaviour is the read.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart' show Component;
import 'package:flutter/material.dart';

import '../../config/source_personality_defs.dart';
import '../../state/source_personalities_controller.dart';

class SourceVisualLayer extends Component {
  SourceVisualLayer(this.c, {this.reducedMotion = false});
  final SourcePersonalitiesController c;
  final bool reducedMotion;

  double _clock = 0;
  double _spin = 0; // wind turbine rotation

  @override
  void update(double dt) {
    if (reducedMotion) {
      _clock += dt * 0.4;
      _spin += (c.source?.isWind ?? false ? c.gust : 0) * dt * 1.6;
      return;
    }
    _clock += dt;
    if (c.source?.isWind ?? false) _spin += (0.4 + c.gust) * dt * 3.2;
  }

  @override
  void render(Canvas canvas) {
    final size = c.stageSize;
    if (size.isEmpty) return;
    final s = c.source;
    if (s == null) return;

    final w = size.width;
    final anchor = c.sourceAnchor;
    final unit = w * 0.20; // plant footprint scale

    // Transmission line to the town (drawn first, behind the plant).
    _drawOutput(canvas, anchor, size.width, unit);
    // A soft ground shadow seats the plant on the earth.
    _groundShadow(canvas, anchor, unit);

    switch (s.kind) {
      case SourceKind.solar:
        _drawSolar(canvas, s, anchor, unit);
      case SourceKind.wind:
        _drawWind(canvas, s, anchor, unit);
      case SourceKind.coal:
        _drawStackPlant(canvas, s, anchor, unit, plumeStrength: 1.0, furnace: true);
      case SourceKind.gas:
        _drawStackPlant(canvas, s, anchor, unit, plumeStrength: 0.5, furnace: false);
      case SourceKind.nuclear:
        _drawNuclear(canvas, s, anchor, unit);
      case SourceKind.hydro:
        _drawHydro(canvas, s, anchor, unit);
    }
  }

  // --- Transmission line (pylons + catenary wires carrying the power) -------
  void _drawOutput(Canvas canvas, Offset from, double w, double unit) {
    final light = c.townLight.clamp(0.0, 1.0);
    final groundY = c.horizonY;
    final towerH = unit * 0.62;
    final topY = groundY - towerH;
    // Tower x-positions marching from the plant toward the town.
    final xs = [w * 0.26, w * 0.34, w * 0.42];
    final wireColor = const Color(0xFF1E2746);

    // Wire run: plant exit → towers → into the town.
    final pts = <Offset>[
      from + Offset(unit * 0.45, -unit * 0.1),
      for (final x in xs) Offset(x, topY),
      Offset(w * 0.5, groundY - unit * 0.2),
    ];
    final wire = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, w * 0.004)
      ..strokeCap = StrokeCap.round
      ..color = wireColor;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final mid = Offset((pts[i - 1].dx + pts[i].dx) / 2, math.max(pts[i - 1].dy, pts[i].dy) + unit * 0.12);
      path.quadraticBezierTo(mid.dx, mid.dy, pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(path, wire);

    // Pulses gliding along the wire while the town draws power.
    if (light > 0.03) {
      final metric = path.computeMetrics().toList();
      final total = metric.fold<double>(0, (a, m) => a + m.length);
      const pulses = 4;
      final r = w * 0.009;
      for (var i = 0; i < pulses; i++) {
        final d = ((_clock * 0.35 + i / pulses) % 1.0) * total;
        final pos = _pointAt(metric, d);
        if (pos == null) continue;
        canvas.drawCircle(pos, r * 1.6, _glow(const Color(0xFFFFE6A8), r * 2.0, 0.8 * light));
        canvas.drawCircle(pos, r * 0.7, Paint()..color = Colors.white.withValues(alpha: 0.95 * light));
      }
    }

    // Lattice pylons.
    for (final x in xs) {
      final tw = unit * 0.16;
      final tower = Path()
        ..moveTo(x - tw * 0.5, groundY)
        ..lineTo(x - tw * 0.16, topY)
        ..lineTo(x + tw * 0.16, topY)
        ..lineTo(x + tw * 0.5, groundY);
      canvas.drawPath(tower, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFF44527A));
      // Cross-arms.
      for (final cy in [topY + towerH * 0.18, topY + towerH * 0.42]) {
        final aw = tw * (cy == topY + towerH * 0.18 ? 0.9 : 1.3);
        canvas.drawLine(Offset(x - aw, cy), Offset(x + aw, cy),
            Paint()..color = const Color(0xFF44527A)..strokeWidth = 1.4);
      }
      // X-brace.
      canvas.drawLine(Offset(x - tw * 0.4, groundY), Offset(x + tw * 0.3, topY + towerH * 0.5),
          Paint()..color = const Color(0xFF222C4C)..strokeWidth = 1);
      canvas.drawLine(Offset(x + tw * 0.4, groundY), Offset(x - tw * 0.3, topY + towerH * 0.5),
          Paint()..color = const Color(0xFF222C4C)..strokeWidth = 1);
    }
  }

  Offset? _pointAt(List<ui.PathMetric> metrics, double d) {
    var acc = 0.0;
    for (final m in metrics) {
      if (d <= acc + m.length) {
        return m.getTangentForOffset(d - acc)?.position;
      }
      acc += m.length;
    }
    return null;
  }

  void _groundShadow(Canvas canvas, Offset at, double unit) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(at.dx, c.horizonY + unit * 0.04), width: unit * 1.3, height: unit * 0.22),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.12),
    );
  }

  // --- Solar ----------------------------------------------------------------
  void _drawSolar(Canvas canvas, SourcePersonality s, Offset at, double unit) {
    final alt = c.sunAltitude;
    // Panel face brightness follows the sun; dark after sunset → town goes dark.
    final face = Color.lerp(const Color(0xFF12244A), const Color(0xFF5FA8E8), alt)!;
    for (var i = -1; i <= 1; i++) {
      final px = at.dx + i * unit * 0.62;
      final py = at.dy + unit * 0.34;
      _panel(canvas, Offset(px, py), unit * 0.5, unit * 0.34, face, alt);
      // Post.
      canvas.drawLine(Offset(px, py + unit * 0.16), Offset(px, at.dy + unit * 0.5),
          Paint()..color = const Color(0xFF38415E)..strokeWidth = unit * 0.04);
    }
    if (alt > 0.05) {
      // Catch-light shimmer toward the sun.
      final shimmer = at.translate(0, unit * 0.1);
      canvas.drawCircle(shimmer, unit * 0.5 * alt,
          _glow(s.accent, unit * 0.4, 0.3 * alt));
    }
  }

  void _panel(Canvas canvas, Offset c2, double pw, double ph, Color face, double alt) {
    final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: c2, width: pw, height: ph), Radius.circular(ph * 0.12));
    canvas.save();
    canvas.translate(c2.dx, c2.dy);
    canvas.rotate(-0.32);
    canvas.translate(-c2.dx, -c2.dy);
    canvas.drawRRect(rect, Paint()..color = face);
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.12 + 0.18 * alt)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final x = c2.dx - pw / 2 + pw * i / 3;
      canvas.drawLine(Offset(x, c2.dy - ph / 2), Offset(x, c2.dy + ph / 2), grid);
    }
    canvas.drawLine(Offset(c2.dx - pw / 2, c2.dy), Offset(c2.dx + pw / 2, c2.dy), grid);
    canvas.drawRRect(rect,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = const Color(0xFF7E8BB0));
    canvas.restore();
  }

  // --- Wind -----------------------------------------------------------------
  void _drawWind(Canvas canvas, SourcePersonality s, Offset at, double unit) {
    final hubY = at.dy - unit * 0.1;
    final hub = Offset(at.dx, hubY);
    // Tower.
    canvas.drawPath(
      Path()
        ..moveTo(at.dx - unit * 0.06, c.horizonY)
        ..lineTo(at.dx - unit * 0.025, hubY)
        ..lineTo(at.dx + unit * 0.025, hubY)
        ..lineTo(at.dx + unit * 0.06, c.horizonY)
        ..close(),
      Paint()..color = const Color(0xFFD6DEEF),
    );
    // Blades.
    final bladePaint = Paint()..color = const Color(0xFFEDF1FA);
    canvas.save();
    canvas.translate(hub.dx, hub.dy);
    canvas.rotate(_spin);
    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.rotate(i * 2 * math.pi / 3);
      final blade = Path()
        ..moveTo(0, -unit * 0.05)
        ..quadraticBezierTo(unit * 0.28, -unit * 0.16, unit * 0.5, 0)
        ..quadraticBezierTo(unit * 0.28, unit * 0.02, 0, unit * 0.05)
        ..close();
      canvas.drawPath(blade, bladePaint);
      canvas.restore();
    }
    canvas.restore();
    canvas.drawCircle(hub, unit * 0.05, Paint()..color = const Color(0xFF9CA8C6));

    // Gust streaks — a wind indicator (faster/denser when gusting).
    final g = c.gust.clamp(0.0, 1.3);
    final streak = Paint()
      ..color = s.accent.withValues(alpha: 0.35 + 0.4 * (g / 1.3))
      ..strokeWidth = unit * 0.03
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = hubY - unit * 0.4 + i * unit * 0.34;
      final off = ((_clock * (0.4 + g)) + i * 0.33) % 1.0;
      final x0 = at.dx - unit * 0.8 + off * unit * 0.5;
      canvas.drawLine(Offset(x0, y), Offset(x0 + unit * 0.3 * (0.4 + g), y), streak);
    }
  }

  // --- Coal / Gas (stack plant) ---------------------------------------------
  void _drawStackPlant(Canvas canvas, SourcePersonality s, Offset at, double unit,
      {required double plumeStrength, required bool furnace}) {
    final baseTop = at.dy + unit * 0.12;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTRB(at.dx - unit * 0.5, baseTop, at.dx + unit * 0.5, c.horizonY),
      Radius.circular(unit * 0.04),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFF2A3147));
    canvas.drawRRect(body,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = const Color(0xFF55617E));

    // Furnace mouth (coal) — a warm glow.
    if (furnace) {
      final mouth = Rect.fromCenter(
          center: Offset(at.dx - unit * 0.2, baseTop + unit * 0.42),
          width: unit * 0.3,
          height: unit * 0.22);
      canvas.drawRect(mouth, _glow(s.accent, unit * 0.16, 0.9));
      canvas.drawRect(mouth, Paint()..color = s.accent);
    }

    // Stack.
    final stackX = at.dx + unit * 0.22;
    final stackTop = at.dy - unit * 0.5;
    canvas.drawRect(
      Rect.fromLTRB(stackX - unit * 0.1, stackTop, stackX + unit * 0.1, baseTop),
      Paint()..color = const Color(0xFF3A4259),
    );
    canvas.drawRect(
      Rect.fromLTWH(stackX - unit * 0.1, stackTop, unit * 0.2, unit * 0.06),
      Paint()..color = s.accent.withValues(alpha: 0.7),
    );

    // Rising smoke plume — the visible source of the accumulating haze.
    final plumes = furnace ? 5 : 3;
    for (var i = 0; i < plumes; i++) {
      final t = ((_clock * 0.5) + i / plumes) % 1.0;
      final y = stackTop - t * unit * 1.4;
      final drift = math.sin(t * math.pi * 2 + i) * unit * 0.18;
      final r = unit * (0.12 + t * 0.34) * plumeStrength;
      final a = (1 - t) * 0.4 * plumeStrength;
      canvas.drawCircle(
        Offset(stackX + drift, y),
        r,
        Paint()
          ..color = const Color(0xFF6B6450).withValues(alpha: a)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.7),
      );
    }
  }

  // --- Nuclear --------------------------------------------------------------
  void _drawNuclear(Canvas canvas, SourcePersonality s, Offset at, double unit) {
    // Cooling tower (hyperboloid hint) with CLEAN white steam.
    final towerX = at.dx + unit * 0.28;
    final tw = unit * 0.5;
    final tower = Path()
      ..moveTo(towerX - tw * 0.5, c.horizonY)
      ..quadraticBezierTo(towerX - tw * 0.22, at.dy - unit * 0.1, towerX - tw * 0.42, at.dy - unit * 0.5)
      ..lineTo(towerX + tw * 0.42, at.dy - unit * 0.5)
      ..quadraticBezierTo(towerX + tw * 0.22, at.dy - unit * 0.1, towerX + tw * 0.5, c.horizonY)
      ..close();
    canvas.drawPath(tower, Paint()..color = const Color(0xFF313A52));
    canvas.drawPath(tower,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = const Color(0xFF606D8B));

    // Containment dome.
    final domeC = Offset(at.dx - unit * 0.34, c.horizonY - unit * 0.22);
    canvas.drawArc(
        Rect.fromCircle(center: domeC, radius: unit * 0.28), math.pi, math.pi, true,
        Paint()..color = const Color(0xFF3C4763));
    canvas.drawCircle(domeC.translate(0, -unit * 0.04), unit * 0.06,
        _glow(s.accent, unit * 0.12, 0.8));

    // Clean white steam.
    for (var i = 0; i < 4; i++) {
      final t = ((_clock * 0.4) + i / 4) % 1.0;
      final y = at.dy - unit * 0.5 - t * unit * 1.1;
      final r = unit * (0.16 + t * 0.3);
      final a = (1 - t) * 0.3;
      canvas.drawCircle(
        Offset(towerX + math.sin(t * 6 + i) * unit * 0.1, y),
        r,
        Paint()
          ..color = Colors.white.withValues(alpha: a)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.8),
      );
    }
  }

  // --- Hydro ----------------------------------------------------------------
  void _drawHydro(Canvas canvas, SourcePersonality s, Offset at, double unit) {
    // Dam wall.
    final wall = Path()
      ..moveTo(at.dx - unit * 0.5, at.dy - unit * 0.3)
      ..lineTo(at.dx + unit * 0.5, at.dy - unit * 0.1)
      ..lineTo(at.dx + unit * 0.42, c.horizonY)
      ..lineTo(at.dx - unit * 0.42, c.horizonY)
      ..close();
    canvas.drawPath(wall, Paint()..color = const Color(0xFF353E55));
    canvas.drawPath(wall,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = const Color(0xFF5E6B89));

    // Reservoir water behind the dam — level reads waterLevel.
    final water = c.waterLevel.clamp(0.0, 1.0);
    final resTop = at.dy - unit * 0.3 + (1 - water) * unit * 0.5;
    canvas.drawRect(
      Rect.fromLTRB(at.dx - unit * 0.95, resTop, at.dx - unit * 0.42, c.horizonY),
      Paint()..color = const Color(0xFF2E6CB0).withValues(alpha: 0.85),
    );
    canvas.drawRect(
      Rect.fromLTWH(at.dx - unit * 0.95, resTop, unit * 0.53, 2),
      Paint()..color = const Color(0xFF8FC4FF).withValues(alpha: 0.8),
    );

    // Falling water — its VOLUME tracks the reservoir (more water → more, wider,
    // brighter streams), so the driver is visible and co-varies with brightness
    // (update spec §1).
    final streams = 3 + (water * 3).round(); // 3..6
    final fall = Paint()
      ..color = const Color(0xFF9CCBFF).withValues(alpha: 0.5 + 0.4 * water)
      ..strokeWidth = unit * (0.03 + 0.035 * water)
      ..strokeCap = StrokeCap.round;
    final spanW = unit * 0.34;
    for (var i = 0; i < streams; i++) {
      final fx = streams == 1 ? at.dx : at.dx - spanW / 2 + spanW * i / (streams - 1);
      final off = ((_clock * 1.6) + i * 0.27) % 1.0;
      canvas.drawLine(Offset(fx, at.dy - unit * 0.05), Offset(fx, c.horizonY - off * unit * 0.12), fall);
    }
  }

  Paint _glow(Color color, double sigma, double alpha) => Paint()
    ..color = color.withValues(alpha: alpha)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);
}
