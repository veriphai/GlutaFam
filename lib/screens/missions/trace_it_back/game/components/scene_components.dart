// The Flame scene layers (PRD v2) — a VERTICAL chain, top→bottom:
//   BULB → WIRE → COIL/MAGNET → SHAFT → TURBINE → FLOW → SOURCE.
// Premium pass: every component is a lit, dimensional object (gradients, bevels,
// specular highlights, soft shadows), the bulb is a real glowing glass globe with
// a filament, and the warm light washes the dark column. Each layer is a near-pure
// renderer reading the controller's pixel + motion getters.
//
// CONNECTOR CORRECTNESS (PRD §3a, criterion 6):
//   • WIRE (bulb↔coil) — ELECTRICAL: the ONLY current-pulse (electricity born at
//     the spinning magnet, rising to the bulb);
//   • SHAFT (magnet↔turbine) — MECHANICAL: a turning axle, NO pulse;
//   • FLOW (turbine↔source) — a per-source PARTICLE stream.
//
// THE INSTANT CUTOFF is honoured everywhere: every "alive" treatment keys off
// controller.brightness / isGenerating / fieldBloom, hard-gated to zero the frame
// the kid stops turning (b1/b2). Entrance reveals + the handoff surge come from the
// controller's reveal/ramp getters (motion lives in the controller, not here).

import 'dart:math' as math;

import 'package:flame/components.dart' show Component;
import 'package:flutter/material.dart';

import '../../../hand_crank_lamp/widgets/bulb.dart';
import '../../config/source_defs.dart';
import '../../state/trace_back_controller.dart';

const Color _warm = Color(0xFFFFE9B8);
const Color _warmHot = Color(0xFFFFF6E0);
const Color _wireBase = Color(0xFF2A3358);
const Color _steelDark = Color(0xFF3C466B);
const Color _steel = Color(0xFF8FA0C8);
const Color _steelLite = Color(0xFFC8D4F0);
const Color _copper = Color(0xFFC9844A);
const Color _copperLite = Color(0xFFF0BD82);
const Color _copperDark = Color(0xFF6E4A2B);
const Color _glassDeep = Color(0xFF0C1230);

Paint _glow(Color color, double sigma, {double alpha = 1}) => Paint()
  ..color = color.withValues(alpha: alpha)
  ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);

/// Entrance helper: slide + scale + fade a component in as its [rev] goes 0→1.
/// Only pays for a saveLayer while actually revealing; full draw once settled.
void _reveal(Canvas canvas, Size stage, double rev, Offset slide, Offset pivot, VoidCallback draw) {
  if (rev >= 0.999) {
    draw();
    return;
  }
  if (rev <= 0.001) return;
  canvas.saveLayer(Offset.zero & stage, Paint()..color = Colors.white.withValues(alpha: rev));
  canvas.translate(slide.dx * (1 - rev), slide.dy * (1 - rev));
  final s = 0.86 + 0.14 * rev;
  canvas.translate(pivot.dx, pivot.dy);
  canvas.scale(s);
  canvas.translate(-pivot.dx, -pivot.dy);
  draw();
  canvas.restore();
}

/// Faint dust motes drifting up the field — the hero's energy claims the void (§7).
class AmbientMotesLayer extends Component {
  AmbientMotesLayer(this.c);
  final TraceBackController c;
  final math.Random _rng = math.Random(31);
  final List<_Mote> _motes = [];

  @override
  void update(double dt) {
    if (c.stageSize.isEmpty) return;
    if (_motes.isEmpty) {
      for (var i = 0; i < 22; i++) {
        _motes.add(_Mote(_rng.nextDouble(), _rng.nextDouble(), 0.2 + _rng.nextDouble() * 0.5, 0.4 + _rng.nextDouble() * 0.8));
      }
    }
    final spd = c.reducedMotion ? 0.2 : 1.0;
    for (final m in _motes) {
      m.y -= dt * 0.012 * m.speed * spd;
      m.x += dt * 0.004 * math.sin(c.shimmer * m.speed + m.phase) * spd;
      if (m.y < -0.02) {
        m.y = 1.02;
        m.x = _rng.nextDouble();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    final w = c.stageSize.width, h = c.stageSize.height;
    for (final m in _motes) {
      final p = Offset(m.x * w, m.y * h);
      // Brighter near the centre column (where the energy is).
      final centreBias = 1 - ((m.x - 0.5).abs() * 2).clamp(0.0, 1.0);
      final a = m.alpha * 0.06 * (0.4 + 0.6 * centreBias);
      canvas.drawCircle(p, m.r * 2.2, _glow(const Color(0xFF9FC0FF), m.r * 2.0, alpha: a));
    }
  }
}

/// Warm bloom washing up/down the central column from the bulb, plus the field
/// glow at the coil — the hero's own light fills the frame (PRD §7).
class BackgroundGlowLayer extends Component {
  BackgroundGlowLayer(this.c);
  final TraceBackController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    final b = c.brightness;
    if (b > 0.01) {
      // A tall vertical wash down the column (not just a circle) — light fills it.
      final colRect = Rect.fromCenter(
        center: c.bulbCenter.translate(0, c.stageSize.height * 0.12),
        width: c.stageSize.width * 0.9,
        height: c.stageSize.height * 0.7,
      );
      canvas.drawRect(
        colRect,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(
            radius: 0.7,
            colors: [_warm.withValues(alpha: 0.16 * b), _warm.withValues(alpha: 0)],
          ).createShader(colRect),
      );
      final r = c.bulbRadius * (3.0 + 4.2 * b);
      canvas.drawCircle(
        c.bulbCenter,
        r,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(colors: [_warm.withValues(alpha: 0.5 * b), _warm.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: c.bulbCenter, radius: r)),
      );
    }
    final fb = c.fieldBloom;
    if (fb > 0.02 && c.magnetInChain) {
      final r = c.coilRadius * (2.0 + 1.6 * fb);
      canvas.drawCircle(
        c.magnetCenter,
        r,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(colors: [
            const Color(0xFF6FA8FF).withValues(alpha: 0.22 * fb),
            const Color(0xFF6FA8FF).withValues(alpha: 0),
          ]).createShader(Rect.fromCircle(center: c.magnetCenter, radius: r)),
      );
    }
  }
}

/// The FLOW connector — the premium source front end (bottom) + its per-source
/// particle stream rising to the turbine (or, for solar, to the panel that
/// replaces the magnet). The CORE never changes — only this layer swaps.
class SourceFrontEndLayer extends Component {
  SourceFrontEndLayer(this.c);
  final TraceBackController c;

  final math.Random _rng = math.Random(7);
  late final List<_Particle> _ps =
      List.generate(26, (i) => _Particle(i / 26, _rng.nextDouble() * 2 - 1, 0.7 + _rng.nextDouble() * 0.6));

  @override
  void update(double dt) {
    if (!c.sourcePresent) return;
    final def = c.activeSourceDef;
    if (def == null) return;
    final speed = 0.4 * (c.reducedMotion ? 0.35 : 1.0) * (0.5 + 0.5 * c.handoffRamp);
    for (final p in _ps) {
      p.progress += speed * dt * p.rate;
      if (p.progress >= 1) {
        p.progress -= 1;
        p.perp = _rng.nextDouble() * 2 - 1;
        p.rate = 0.7 + _rng.nextDouble() * 0.6;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty || !c.sourcePresent) return;
    final def = c.activeSourceDef;
    if (def == null) return;
    final rev = c.sourceReveal;
    _reveal(canvas, c.stageSize, rev, Offset(0, c.stageSize.height * 0.08), c.sourceCenter, () {
      _drawFrontEnd(canvas, def, c.sourceCenter);
      if (def.isSolar) _drawSolarPanel(canvas, c.magnetCenter);
    });
    if (rev < 0.4) return; // flow starts once the source has arrived

    final src = c.sourceCenter;
    // Solar sends SUNRAYS straight onto the panel (it skips the turbine + magnet)
    // — not the particle stream the turbine sources use.
    if (def.isSolar) {
      _drawSunRays(canvas, src, c.magnetCenter, rev);
      return;
    }
    final target = c.turbineCenter;
    final dir = target - src;
    final len = dir.distance;
    if (len < 1) return;
    final dirN = dir / len;
    final perpDir = Offset(-dir.dy, dir.dx) / len;
    final amp = c.stageSize.width * 0.045;
    final col = def.flowColor;
    final start = src + dir * (c.sourceRadius / len * 1.0);
    final dotR = c.stageSize.width * 0.007;
    for (final p in _ps) {
      final base = Offset.lerp(start, target, p.progress)!;
      final wob = perpDir * (p.perp * amp * math.sin(p.progress * math.pi));
      final a = math.sin(p.progress * math.pi).clamp(0.0, 1.0) * 0.9 * rev;
      switch (def.kind) {
        case FrontEndKind.heatSteam:
          final pos = base + wob;
          final rr = dotR * (1.4 + 1.4 * p.progress);
          canvas.drawCircle(pos, rr * 1.8, _glow(col, rr * 2.2, alpha: a * 0.4));
          canvas.drawCircle(pos, rr, Paint()..color = col.withValues(alpha: a * 0.7));
        case FrontEndKind.water:
          final pos = base + wob;
          canvas.drawCircle(pos, dotR * 1.4, _glow(col, dotR * 1.6, alpha: a * 0.5));
          canvas.drawCircle(pos, dotR * 0.85, Paint()..color = Colors.white.withValues(alpha: a * 0.75));
        case FrontEndKind.wind:
          final pos = base + wob;
          final tail = pos - dirN * (dotR * 7 * (0.6 + 0.6 * p.rate));
          canvas.drawLine(
            pos,
            tail,
            Paint()
              ..color = col.withValues(alpha: a * 0.7)
              ..strokeWidth = dotR * 1.2
              ..strokeCap = StrokeCap.round
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, dotR),
          );
        case FrontEndKind.sunlight:
          final pos = base + wob;
          canvas.drawCircle(pos, dotR * 1.8, _glow(col, dotR * 2.4, alpha: a * 0.5));
          canvas.drawCircle(pos, dotR * 0.9, Paint()..color = Colors.white.withValues(alpha: a * 0.7));
      }
    }
  }

  void _drawFrontEnd(Canvas canvas, SourceDef def, Offset at) {
    final r = c.sourceRadius;
    switch (def.kind) {
      case FrontEndKind.heatSteam:
        // A HORIZONTAL, LABELLED chain so the plant is understandable at a glance:
        // fuel → heat → boiling water → steam (the steam rises to the turbine).
        // Only the first step differs by source (Coal / Gas / Atoms).
        _drawThermalChain(canvas, def, at);
      case FrontEndKind.water:
        final body = RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: r * 1.7, height: r * 1.8), Radius.circular(r * 0.2));
        canvas.drawRRect(body, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_steel, _steelDark]).createShader(body.outerRect));
        final chute = Rect.fromCenter(center: at, width: r * 1.0, height: r * 1.4);
        canvas.drawRRect(RRect.fromRectAndRadius(chute, Radius.circular(r * 0.12)),
            Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [def.accent.withValues(alpha: 0.95), const Color(0xFF2A6FB0)]).createShader(chute));
        for (var i = -1; i <= 1; i++) {
          canvas.drawLine(at.translate(i * r * 0.3, r * 0.6), at.translate(i * r * 0.3, -r * 0.6), Paint()..color = Colors.white.withValues(alpha: 0.45)..strokeWidth = r * 0.07..strokeCap = StrokeCap.round);
        }
        canvas.drawRRect(body, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = _steelLite.withValues(alpha: 0.5));
      case FrontEndKind.wind:
        // A small pinwheel that spins (its own slow rotation).
        canvas.save();
        canvas.translate(at.dx, at.dy);
        canvas.rotate(c.shimmer * 1.6);
        for (var i = 0; i < 3; i++) {
          canvas.save();
          canvas.rotate(i * 2 * math.pi / 3);
          final blade = Path()
            ..moveTo(0, 0)
            ..quadraticBezierTo(r * 0.5, -r * 0.2, r * 0.85, 0)
            ..quadraticBezierTo(r * 0.5, r * 0.2, 0, 0)
            ..close();
          canvas.drawPath(blade, Paint()..shader = LinearGradient(colors: [def.accent, _steelDark]).createShader(Rect.fromCircle(center: Offset.zero, radius: r)));
          canvas.restore();
        }
        canvas.drawCircle(Offset.zero, r * 0.16, Paint()..color = _steelLite);
        canvas.restore();
      case FrontEndKind.sunlight:
        canvas.drawCircle(at, r * 1.1, _glow(def.accent, r * 0.8, alpha: 0.7));
        canvas.drawCircle(at, r * 0.72, Paint()..shader = RadialGradient(colors: [_warmHot, def.accent]).createShader(Rect.fromCircle(center: at, radius: r * 0.72)));
        final ray = Paint()..color = def.accent.withValues(alpha: 0.85)..strokeWidth = r * 0.1..strokeCap = StrokeCap.round;
        for (var i = 0; i < 12; i++) {
          final a = i * math.pi / 6 + c.shimmer * 0.3;
          final inner = r * 0.85, outer = r * (1.1 + 0.12 * math.sin(c.shimmer * 2 + i));
          canvas.drawLine(at + Offset(math.cos(a), math.sin(a)) * inner, at + Offset(math.cos(a), math.sin(a)) * outer, ray);
        }
    }
  }

  // ── Thermal source as a horizontal labelled chain ────────────────────────
  /// fuel → heat → boiling water → steam, with a word under each step (the fuel
  /// step is Coal / Gas / Atoms). Steam rises from here to the turbine.
  void _drawThermalChain(Canvas canvas, SourceDef def, Offset at) {
    final w = c.stageSize.width;
    final totalW = w * 0.9;
    final cellW = totalW / 4;
    final left = at.dx - totalW / 2;
    final s = cellW * 0.28; // icon half-size
    final iconCy = at.dy - cellW * 0.18;
    final labelTop = at.dy + cellW * 0.18;
    final fuelLabel = def.source == EnergySource.gas
        ? 'Gas'
        : def.source == EnergySource.nuclear
            ? 'Atoms'
            : 'Coal';
    final labels = [fuelLabel, 'Heat', 'Boiling\nWater', 'Steam'];

    // Subtle backing panel — groups the steps; stays secondary to the magnet hero.
    final panel = RRect.fromRectAndRadius(
      Rect.fromCenter(center: at, width: totalW + w * 0.03, height: cellW * 1.5),
      Radius.circular(w * 0.035),
    );
    canvas.drawRRect(panel, Paint()..color = const Color(0xFF0C1228).withValues(alpha: 0.6));
    canvas.drawRRect(panel, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = _steelLite.withValues(alpha: 0.18));

    for (var i = 0; i < 4; i++) {
      final cx = left + cellW * (i + 0.5);
      // Arrow chevron into the next step.
      if (i < 3) {
        final ax = cx + cellW * 0.5;
        final p = Paint()..color = _steelLite.withValues(alpha: 0.6)..strokeWidth = 2..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(ax - s * 0.22, iconCy - s * 0.3), Offset(ax + s * 0.18, iconCy), p);
        canvas.drawLine(Offset(ax - s * 0.22, iconCy + s * 0.3), Offset(ax + s * 0.18, iconCy), p);
      }
      _thermalStepIcon(canvas, i, def, Offset(cx, iconCy), s);
      _chainLabel(canvas, labels[i], cx, labelTop, cellW * 0.96, s * 0.5);
    }
  }

  void _thermalStepIcon(Canvas canvas, int step, SourceDef def, Offset cc, double s) {
    switch (step) {
      case 0:
        if (def.source == EnergySource.nuclear) {
          _atomIcon(canvas, cc, s, def.accent);
        } else if (def.source == EnergySource.gas) {
          _gasIcon(canvas, cc, s);
        } else {
          _coalIcon(canvas, cc, s);
        }
      case 1:
        _flameIcon(canvas, cc, s);
      case 2:
        _beakerIcon(canvas, cc, s);
      default:
        _steamIcon(canvas, cc, s);
    }
  }

  void _coalIcon(Canvas canvas, Offset cc, double s) {
    final dark = const Color(0xFF2B2B34), lite = const Color(0xFF474752);
    canvas.drawCircle(cc.translate(-s * 0.42, s * 0.28), s * 0.42, Paint()..color = dark);
    canvas.drawCircle(cc.translate(s * 0.42, s * 0.28), s * 0.42, Paint()..color = dark);
    canvas.drawCircle(cc.translate(0, -s * 0.12), s * 0.5, Paint()..color = lite);
  }

  void _gasIcon(Canvas canvas, Offset cc, double s) {
    final cyl = RRect.fromRectAndRadius(Rect.fromCenter(center: cc.translate(0, s * 0.1), width: s * 0.9, height: s * 1.25), Radius.circular(s * 0.26));
    canvas.drawRRect(cyl, Paint()..shader = const LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xFF5A6488), Color(0xFF8B95B8), Color(0xFF5A6488)]).createShader(cyl.outerRect));
    canvas.drawRRect(cyl, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = _steelLite.withValues(alpha: 0.6));
    // valve on top
    canvas.drawRect(Rect.fromCenter(center: cc.translate(0, -s * 0.62), width: s * 0.3, height: s * 0.28), Paint()..color = _steelDark);
  }

  void _atomIcon(Canvas canvas, Offset cc, double s, Color accent) {
    canvas.drawCircle(cc, s * 1.25, _glow(accent, s * 0.5, alpha: 0.4));
    for (var k = 0; k < 3; k++) {
      canvas.save();
      canvas.translate(cc.dx, cc.dy);
      canvas.rotate(c.shimmer * 0.8 + k * math.pi / 3);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: s * 2.1, height: s * 0.7), Paint()..style = PaintingStyle.stroke..strokeWidth = 1.3..color = accent.withValues(alpha: 0.85));
      canvas.restore();
    }
    canvas.drawCircle(cc, s * 0.34, Paint()..color = _warmHot);
    canvas.drawCircle(cc, s * 0.34, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = accent);
  }

  void _flameIcon(Canvas canvas, Offset cc, double s) {
    final base = cc.dy + s * 0.75, tip = cc.dy - s * 0.85;
    final flame = Path()
      ..moveTo(cc.dx - s * 0.55, base)
      ..quadraticBezierTo(cc.dx - s * 0.62, cc.dy, cc.dx, tip)
      ..quadraticBezierTo(cc.dx + s * 0.62, cc.dy, cc.dx + s * 0.55, base)
      ..quadraticBezierTo(cc.dx, base + s * 0.18, cc.dx - s * 0.55, base)
      ..close();
    canvas.drawPath(flame, _glow(const Color(0xFFFF8A3D), s * 0.45, alpha: 0.55));
    canvas.drawPath(flame, Paint()..shader = LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: const [Color(0xFFFF5A28), Color(0xFFFFD37A)]).createShader(Rect.fromLTRB(cc.dx - s * 0.55, tip, cc.dx + s * 0.55, base)));
  }

  void _beakerIcon(Canvas canvas, Offset cc, double s) {
    final rect = Rect.fromCenter(center: cc, width: s * 1.0, height: s * 1.4);
    final body = RRect.fromRectAndCorners(rect, bottomLeft: Radius.circular(s * 0.3), bottomRight: Radius.circular(s * 0.3));
    canvas.save();
    canvas.clipRRect(body);
    final waterTop = rect.bottom - rect.height * 0.62;
    canvas.drawRect(Rect.fromLTRB(rect.left, waterTop, rect.right, rect.bottom), Paint()..color = const Color(0xFF3A7FD0));
    for (var i = 0; i < 2; i++) {
      final bx = cc.dx + (i == 0 ? -s * 0.22 : s * 0.22);
      final by = rect.bottom - rect.height * 0.5 * ((c.shimmer * 0.7 + i * 0.5) % 1.0) - s * 0.1;
      canvas.drawCircle(Offset(bx, by), s * 0.1, Paint()..color = Colors.white.withValues(alpha: 0.5));
    }
    canvas.restore();
    canvas.drawRRect(body, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = _steelLite.withValues(alpha: 0.85));
    // rim
    canvas.drawLine(Offset(rect.left - s * 0.08, rect.top), Offset(rect.right + s * 0.08, rect.top), Paint()..color = _steelLite.withValues(alpha: 0.85)..strokeWidth = 1.5..strokeCap = StrokeCap.round);
  }

  void _steamIcon(Canvas canvas, Offset cc, double s) {
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = s * 0.16..color = Colors.white.withValues(alpha: 0.7)..strokeCap = StrokeCap.round;
    for (var k = -1; k <= 1; k++) {
      final x = cc.dx + k * s * 0.45;
      final path = Path()..moveTo(x, cc.dy + s * 0.8);
      for (var t = 1; t <= 5; t++) {
        final yy = cc.dy + s * 0.8 - t * (s * 1.6 / 5);
        final xx = x + math.sin(t * 1.3 + c.shimmer * 2 + k) * s * 0.2;
        path.lineTo(xx, yy);
      }
      canvas.drawPath(path, p);
    }
  }

  void _chainLabel(Canvas canvas, String text, double cx, double top, double maxW, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, height: 1.05, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.88)),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: maxW);
    tp.paint(canvas, Offset(cx - tp.width / 2, top));
  }

  // A larger, animated solar panel that takes the magnet's place (solar bypasses
  // the core). Glassy cells brighten with the energy received, a sheen sweeps, and
  // a soft glow halo pulses behind it.
  void _drawSolarPanel(Canvas canvas, Offset at) {
    final r = c.coilRadius;
    final w = r * 3.2, h = r * 2.25;
    final b = c.brightness.clamp(0.0, 1.0);
    final pulse = 0.7 + 0.3 * math.sin(c.shimmer * 2.0);

    // Glow halo behind, pulsing with the light received.
    canvas.drawCircle(at, w * 0.62, _glow(const Color(0xFF6FB6FF), r * 0.9, alpha: (0.08 + 0.18 * b) * pulse));

    final rect = RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: w, height: h), Radius.circular(r * 0.16));
    // Contact shadow + metal frame.
    canvas.drawRRect(rect.shift(const Offset(0, 5)), _glow(Colors.black, 10, alpha: 0.35));
    canvas.drawRRect(rect, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2A3358), Color(0xFF12193A)]).createShader(rect.outerRect));

    // Glassy cells, brightening with the energy.
    final cellTop = Color.lerp(const Color(0xFF1E4C8E), const Color(0xFF55B0F7), b)!;
    final cellBot = Color.lerp(const Color(0xFF0E2350), const Color(0xFF1E5C9E), b)!;
    final inset = r * 0.2;
    final cells = Rect.fromCenter(center: at, width: w - inset * 2, height: h - inset * 2);
    const cols = 3, rows = 2;
    final gap = r * 0.1;
    final cw = (cells.width - gap * (cols - 1)) / cols;
    final ch = (cells.height - gap * (rows - 1)) / rows;
    for (var cx = 0; cx < cols; cx++) {
      for (var cy = 0; cy < rows; cy++) {
        final cr = Rect.fromLTWH(cells.left + cx * (cw + gap), cells.top + cy * (ch + gap), cw, ch);
        final rr = RRect.fromRectAndRadius(cr, Radius.circular(r * 0.06));
        canvas.drawRRect(rr, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [cellTop, cellBot]).createShader(cr));
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cr.left, cr.top, cr.width, cr.height * 0.32), Radius.circular(r * 0.06)), Paint()..color = Colors.white.withValues(alpha: 0.07 + 0.13 * b));
      }
    }

    // Sheen sweep across the cells.
    final sweepX = cells.left + cells.width * ((c.shimmer * 0.35) % 1.0);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(cells, Radius.circular(r * 0.08)));
    canvas.drawRect(Rect.fromLTWH(sweepX - r * 0.25, cells.top, r * 0.5, cells.height), _glow(Colors.white, r * 0.3, alpha: 0.18));
    canvas.restore();
    canvas.drawRRect(rect, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = _steelLite.withValues(alpha: 0.55));
  }

  // Sunlight as actual RAYS beaming from the sun up onto the panel — a soft warm
  // cone + a few bright fanned rays that pulse (replaces the dot particles).
  void _drawSunRays(Canvas canvas, Offset sun, Offset panel, double rev) {
    final r = c.sourceRadius;
    final dir = panel - sun;
    final len = dir.distance;
    if (len < 1) return;
    final dirN = dir / len;
    final perp = Offset(-dirN.dy, dirN.dx);
    const warmRay = Color(0xFFFFD27A);
    final panelHalf = c.coilRadius * 1.5;
    final pulse = 0.6 + 0.4 * math.sin(c.shimmer * 2.2);

    // Soft light cone (additive, warm) widening from the sun to the panel.
    final cone = Path()
      ..moveTo(sun.dx + perp.dx * r * 0.35, sun.dy + perp.dy * r * 0.35)
      ..lineTo(panel.dx + perp.dx * panelHalf, panel.dy + perp.dy * panelHalf)
      ..lineTo(panel.dx - perp.dx * panelHalf, panel.dy - perp.dy * panelHalf)
      ..lineTo(sun.dx - perp.dx * r * 0.35, sun.dy - perp.dy * r * 0.35)
      ..close();
    canvas.drawPath(
      cone,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter, // sun side (bright)
          end: Alignment.topCenter, // panel side (fainter)
          colors: [warmRay.withValues(alpha: 0.22 * rev * pulse), warmRay.withValues(alpha: 0.02 * rev)],
        ).createShader(Rect.fromPoints(sun, panel)),
    );

    // A few bright fanned rays, each pulsing on its own phase.
    const n = 5;
    for (var i = 0; i < n; i++) {
      final t = (i / (n - 1)) - 0.5; // -0.5 .. 0.5
      final start = sun + perp * (t * r * 0.5);
      final end = panel + perp * (t * panelHalf * 1.5);
      final a = (0.4 + 0.45 * math.sin(c.shimmer * 2.6 + i * 0.9)).clamp(0.0, 1.0) * rev;
      canvas.drawLine(start, end, _glow(warmRay, r * 0.18, alpha: 0.5 * a)..strokeWidth = r * 0.11..strokeCap = StrokeCap.round);
      canvas.drawLine(start, end, Paint()..color = Colors.white.withValues(alpha: 0.35 * a)..strokeWidth = r * 0.03..strokeCap = StrokeCap.round);
    }
  }
}

/// The SHAFT connector (magnet↔turbine) — MECHANICAL: a cylindrical axle with a
/// moving highlight band and rib rings that travel with the rotation. NO pulse.
class ShaftLayer extends Component {
  ShaftLayer(this.c);
  final TraceBackController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty || !c.shaftPresent || c.coreFade < 0.02) return;
    _reveal(canvas, c.stageSize, c.turbineReveal, Offset(0, c.stageSize.height * 0.04), c.shaftStart, () => _draw(canvas));
  }

  void _draw(Canvas canvas) {
    final s = c.shaftStart, e = c.shaftEnd;
    final w = c.stageSize.width;
    final op = c.coreFade;
    final halfW = w * 0.02;
    final dir = e - s;
    final len = dir.distance;
    if (len < 1) return;
    final perp = Offset(-dir.dy, dir.dx) / len;
    final rect = Rect.fromPoints(s + perp * halfW, e - perp * halfW);

    // Cylindrical body (dark edges → bright centre).
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [_steelDark.withValues(alpha: op), _steelLite.withValues(alpha: op), _steelDark.withValues(alpha: op)],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect),
    );
    // Rib rings travelling with the rotation.
    final ribPhase = (c.shaftRotation * 0.5) % 1.0;
    const n = 5;
    for (var i = 0; i < n; i++) {
      final t = ((i + ribPhase) / n) % 1.0;
      final p = Offset.lerp(s, e, t)!;
      canvas.drawLine(p + perp * halfW, p - perp * halfW, Paint()..color = _steelDark.withValues(alpha: 0.6 * op)..strokeWidth = 2.0);
    }
  }
}

/// The turbine — a dimensional metal wheel (Beat 2+): shaded blades with edge
/// highlights, a beveled hub + bolt, a soft contact shadow, and a faint motion
/// smear at speed. Dims when a source bypasses it (solar).
class TurbineLayer extends Component {
  TurbineLayer(this.c);
  final TraceBackController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty || !c.turbinePresent || c.coreFade < 0.02) return;
    _reveal(canvas, c.stageSize, c.turbineReveal, Offset(0, c.stageSize.height * 0.07), c.turbineCenter, () => _draw(canvas));
  }

  void _draw(Canvas canvas) {
    final ctr = c.turbineCenter;
    final r = c.turbineRadius;
    final op = c.coreFade;

    // Soft contact shadow.
    canvas.drawCircle(ctr.translate(0, r * 0.18), r * 0.95, _glow(Colors.black, r * 0.3, alpha: 0.28 * op));
    // Motion smear at speed.
    final sp = c.spinNorm;
    if (sp > 0.12 && op > 0.5) {
      canvas.drawCircle(ctr, r * 0.95, Paint()..color = _steel.withValues(alpha: 0.10 * sp));
    }

    canvas.save();
    canvas.translate(ctr.dx, ctr.dy);
    canvas.rotate(c.turbineAngle);
    for (var i = 0; i < 6; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 3);
      final path = Path()
        ..moveTo(0, -r * 0.2)
        ..lineTo(r * 0.96, -r * 0.46)
        ..quadraticBezierTo(r * 1.02, 0, r * 0.96, r * 0.08)
        ..lineTo(0, r * 0.2)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [_steelDark.withValues(alpha: op), _steel.withValues(alpha: op), _steelLite.withValues(alpha: op)],
          ).createShader(Rect.fromLTWH(0, -r * 0.46, r, r * 0.66)),
      );
      // Leading-edge highlight.
      canvas.drawLine(Offset(r * 0.1, -r * 0.2), Offset(r * 0.92, -r * 0.42), Paint()..color = _steelLite.withValues(alpha: 0.7 * op)..strokeWidth = 1.4..strokeCap = StrokeCap.round);
      canvas.restore();
    }
    canvas.restore();

    // Hub — beveled disc + bolt.
    canvas.drawCircle(ctr, r * 0.26, Paint()..shader = RadialGradient(center: const Alignment(-0.4, -0.4), colors: [_steelLite.withValues(alpha: op), _steelDark.withValues(alpha: op)]).createShader(Rect.fromCircle(center: ctr, radius: r * 0.26)));
    canvas.drawCircle(ctr, r * 0.26, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = _steelLite.withValues(alpha: 0.6 * op));
    canvas.drawCircle(ctr, r * 0.08, Paint()..color = _glassDeep.withValues(alpha: op));
  }
}

/// The WIRE connector (bulb↔coil) — ELECTRICAL: the ONLY segment carrying the
/// luminous current-pulse, travelling coil→bulb. Dim copper line when idle.
class WireLayer extends Component {
  WireLayer(this.c);
  final TraceBackController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    final s = c.wireEnd, e = c.wireStart; // s = coil side, e = bulb side
    final w = c.stageSize.width;
    // Base wire with a faint round cross-section gradient.
    canvas.drawLine(s, e, Paint()..color = _wireBase..strokeWidth = w * 0.016..strokeCap = StrokeCap.round);
    canvas.drawLine(s, e, Paint()..color = const Color(0xFF3E4A78)..strokeWidth = w * 0.006..strokeCap = StrokeCap.round);
    if (!c.isGenerating) return;
    final b = c.brightness.clamp(0.0, 1.0);
    if (c.reducedMotion) {
      canvas.drawLine(s, e, _glow(_warm, w * 0.02, alpha: 0.6 * b)..strokeWidth = w * 0.016..strokeCap = StrokeCap.round);
      canvas.drawLine(s, e, Paint()..color = Colors.white.withValues(alpha: 0.5 * b)..strokeWidth = w * 0.006..strokeCap = StrokeCap.round);
      return;
    }
    const pulses = 4;
    final r = w * 0.015;
    for (var i = 0; i < pulses; i++) {
      final t = (c.pulsePhase + i / pulses) % 1.0; // travels coil → bulb
      final p = Offset.lerp(s, e, t)!;
      canvas.drawCircle(p, r * 1.8, _glow(_warm, r * 2.2, alpha: 0.85 * b));
      canvas.drawCircle(p, r * 0.7, Paint()..color = Colors.white.withValues(alpha: 0.95 * b));
    }
  }
}

/// The coil (copper windings) + the rotating bar magnet + the field-line bloom
/// (only while moving). Dims to a ghost when a source bypasses the magnet (solar).
class CoilMagnetLayer extends Component {
  CoilMagnetLayer(this.c);
  final TraceBackController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty || c.coreFade < 0.02) return;
    _reveal(canvas, c.stageSize, c.coilReveal, Offset(0, -c.stageSize.height * 0.02), c.magnetCenter, () => _draw(canvas));
  }

  void _draw(Canvas canvas) {
    final ctr = c.magnetCenter;
    final coilR = c.coilRadius;
    final magLen = c.magnetLength;
    final magH = magLen * 0.3;
    final op = c.coreFade;

    // Field-line bloom — loops above & below the magnet, alpha by fieldBloom.
    final fb = c.fieldBloom;
    if (fb > 0.02 && c.magnetInChain) {
      final fieldPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.plus;
      for (var i = 0; i < 3; i++) {
        final rr = coilR * (1.0 + i * 0.45);
        fieldPaint.color = const Color(0xFF8FC2FF).withValues(alpha: (0.5 - i * 0.13) * fb);
        canvas.drawArc(Rect.fromCenter(center: ctr, width: magLen * (1.1 + i * 0.4), height: rr * 2), math.pi, math.pi, false, fieldPaint);
        canvas.drawArc(Rect.fromCenter(center: ctr, width: magLen * (1.1 + i * 0.4), height: rr * 2), 0, math.pi, false, fieldPaint);
      }
    }

    // The coil — copper windings (back half dim, front half bright) the magnet
    // spins within.
    const rings = 6;
    final span = magLen * 0.92;
    final ringH = coilR * 1.75;
    final ringW = coilR * 0.52;
    for (var i = 0; i < rings; i++) {
      final x = ctr.dx - span / 2 + span * i / (rings - 1);
      final rect = Rect.fromCenter(center: Offset(x, ctr.dy), width: ringW, height: ringH);
      // back arc (dim)
      canvas.drawArc(rect, -math.pi / 2, math.pi, false, Paint()..style = PaintingStyle.stroke..strokeWidth = coilR * 0.14..strokeCap = StrokeCap.round..color = _copperDark.withValues(alpha: 0.8 * op));
      // front arc (bright copper)
      canvas.drawArc(rect, math.pi / 2, math.pi, false, Paint()..style = PaintingStyle.stroke..strokeWidth = coilR * 0.16..strokeCap = StrokeCap.round..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_copperLite.withValues(alpha: op), _copper.withValues(alpha: op)]).createShader(rect));
    }

    // Magnet motion smear at speed.
    final sp = c.spinNorm;
    if (sp > 0.12 && op > 0.5) {
      canvas.drawCircle(ctr, magLen * 0.5, Paint()..color = const Color(0xFF8090C0).withValues(alpha: 0.08 * sp));
    }

    // The bar magnet — glossy two-tone (N red, S blue), rotating.
    canvas.save();
    canvas.translate(ctr.dx, ctr.dy);
    canvas.rotate(c.magnetAngle);
    final rrect = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: magLen, height: magH), Radius.circular(magH * 0.3));
    canvas.save();
    canvas.clipRRect(rrect);
    final sRect = Rect.fromLTWH(-magLen / 2, -magH / 2, magLen / 2, magH);
    final nRect = Rect.fromLTWH(0, -magH / 2, magLen / 2, magH);
    canvas.drawRect(sRect, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFF6E8FE0).withValues(alpha: op), const Color(0xFF3A56A8).withValues(alpha: op)]).createShader(sRect));
    canvas.drawRect(nRect, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFFFF7A72).withValues(alpha: op), const Color(0xFFD13B33).withValues(alpha: op)]).createShader(nRect));
    // Top gloss streak.
    canvas.drawRect(Rect.fromLTWH(-magLen / 2, -magH / 2, magLen, magH * 0.28), Paint()..color = Colors.white.withValues(alpha: 0.18 * op));
    canvas.restore();
    canvas.drawRRect(rrect, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = Colors.white.withValues(alpha: 0.55 * op));
    _poleGlyph(canvas, 'N', Offset(magLen * 0.25, 0), magH * 0.5, op);
    _poleGlyph(canvas, 'S', Offset(-magLen * 0.25, 0), magH * 0.5, op);
    canvas.restore();
  }

  void _poleGlyph(Canvas canvas, String s, Offset at, double size, double op) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.95 * op))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }
}

/// The bulb at the TOP — the SHARED glowing glass globe (the exact same art +
/// glow as Activity 1's Hand-Crank Lamp, via paintBulb): its glass FILLS with
/// warm amber as brightness rises, plus a filament and an inner additive bloom.
/// Snaps to dark instantly on stop (brightness is hard-gated).
class BulbLayer extends Component {
  BulbLayer(this.c);
  final TraceBackController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    _reveal(canvas, c.stageSize, c.bulbReveal, Offset(0, -c.stageSize.height * 0.03), c.bulbCenter,
        () => paintBulb(canvas, c.bulbCenter, c.bulbRadius, c.brightness));
  }
}

/// The discovery beat — a brief screen-dim pulse + an expanding shock ring at the
/// coil the instant the held-still magnet kills the light (Beat 1, suppression-
/// exempt). The cutoff stays instant; this only adds drama.
class DiscoveryRingLayer extends Component {
  DiscoveryRingLayer(this.c);
  final TraceBackController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    final dim = c.discoveryDim;
    if (dim > 0.001) {
      canvas.drawRect(Offset.zero & c.stageSize, Paint()..color = const Color(0xFF05070F).withValues(alpha: dim));
    }
    final f = c.flashIntensity;
    if (f <= 0.01) return;
    final ctr = c.magnetCenter;
    final r = c.coilRadius * (1.2 + (1 - f) * 2.8);
    canvas.drawCircle(
      ctr,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = c.stageSize.width * 0.012 * f
        ..color = Colors.white.withValues(alpha: 0.85 * f)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + 7 * f),
    );
  }
}

/// A faint rotating "turn me" hint around the active grab-point (magnet in b1,
/// turbine in b2) until the kid first touches it (PRD §7).
class GrabHintLayer extends Component {
  GrabHintLayer(this.c);
  final TraceBackController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty || !c.grabHintActive) return;
    final ctr = c.grabCenter;
    final base = c.grabIsTurbine ? c.turbineRadius : c.magnetLength * 0.5;
    final r = base * 1.5;
    final spin = c.shimmer * 1.4;
    final pulse = 0.4 + 0.25 * math.sin(c.shimmer * 3);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = c.stageSize.width * 0.008
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFD970).withValues(alpha: pulse);
    for (var k = 0; k < 2; k++) {
      final a0 = spin + k * math.pi;
      canvas.drawArc(Rect.fromCircle(center: ctr, radius: r), a0, math.pi * 0.6, false, paint);
      final ang = a0 + math.pi * 0.6;
      final tip = ctr + Offset(math.cos(ang), math.sin(ang)) * r;
      final back = ang + math.pi / 2;
      final sz = c.stageSize.width * 0.02;
      canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(tip.dx + math.cos(back - 0.5) * sz, tip.dy + math.sin(back - 0.5) * sz)
          ..lineTo(tip.dx + math.cos(back + 0.5) * sz, tip.dy + math.sin(back + 0.5) * sz)
          ..close(),
        Paint()..color = const Color(0xFFFFD970).withValues(alpha: pulse),
      );
    }
  }
}

class _Particle {
  _Particle(this.progress, this.perp, this.rate);
  double progress;
  double perp;
  double rate;
}

class _Mote {
  _Mote(this.x, this.y, this.speed, this.r) : phase = x * 6.28, alpha = 0.5 + r;
  double x, y;
  final double speed;
  final double r;
  final double phase;
  final double alpha;
}
