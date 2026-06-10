// The Leaky Bucket premium scene — a living power station. The kid SNAP-BUILDS it
// (machines appear cold at their slots) then POWERS IT UP: the flow sweeps
// top→bottom and each machine WAKES as the flow reaches it, leaking heat, the
// stream thinning stage by stage, until the bulb lands dim. Every layer is a
// near-pure renderer reading controller getters (controller-owns-geometry).

import 'dart:math' as math;

import 'package:flame/components.dart' show Component;
import 'package:flutter/material.dart';

import '../../config/leaky_chain_defs.dart';
import '../../engine/leaky_bot_engine.dart' show LBPhase;
import '../../state/leaky_bucket_controller.dart';
import '../../state/leaky_model.dart';
import '../../widgets/bulb.dart';
import 'lb_paint.dart';

// ── Background glow wash ─────────────────────────────────────────────────
class GlowWashLayer extends Component {
  GlowWashLayer(this.controller);
  final LeakyBucketController controller;

  @override
  void render(Canvas canvas) {
    final s = controller.stageSize;
    if (s.isEmpty) return;
    final b = controller.bulbGlow;
    final col = Rect.fromCenter(center: Offset(s.width * 0.5, s.height * 0.55), width: s.width * 0.95, height: s.height * 0.9);
    canvas.drawRect(
      col,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(radius: 0.7, colors: [lbWarm.withValues(alpha: 0.05 + 0.12 * b), lbWarm.withValues(alpha: 0)]).createShader(col),
    );
  }
}

// ── Ambient motes ───────────────────────────────────────────────────────
class AmbientMotesLayer extends Component {
  AmbientMotesLayer(this.controller, {this.reducedMotion = false});
  final LeakyBucketController controller;
  final bool reducedMotion;

  final math.Random _rng = math.Random(31);
  final List<_Mote> _motes = [];
  double _clock = 0;

  @override
  void update(double dt) {
    _clock += dt;
    final s = controller.stageSize;
    if (s.isEmpty) return;
    if (_motes.isEmpty) {
      for (var i = 0; i < 26; i++) {
        _motes.add(_Mote(Offset(_rng.nextDouble() * s.width, _rng.nextDouble() * s.height), 0.6 + _rng.nextDouble() * 1.6, 0.4 + _rng.nextDouble() * 0.6));
      }
    }
    if (reducedMotion) return;
    for (final m in _motes) {
      m.p = Offset(m.p.dx + math.sin(_clock * 0.5 + m.p.dy) * 0.15, m.p.dy - m.speed * 6 * dt);
      if (m.p.dy < -4) m.p = Offset(_rng.nextDouble() * s.width, s.height + 4);
    }
  }

  @override
  void render(Canvas canvas) {
    final w = controller.stageSize.width.clamp(1, 99999).toDouble();
    for (final m in _motes) {
      final tw = 0.5 + 0.5 * math.sin(_clock * 1.3 + m.p.dx);
      final centreBias = 1 - ((m.p.dx / w - 0.5).abs() * 2).clamp(0.0, 1.0);
      final a = (0.04 + 0.06 * tw) * (0.5 + 0.5 * centreBias);
      canvas.drawCircle(m.p, m.r * 1.8, lbGlow(const Color(0xFF9FC0FF), m.r * 1.6, alpha: a));
    }
  }
}

class _Mote {
  _Mote(this.p, this.r, this.speed);
  Offset p;
  final double r;
  final double speed;
}

// ── The machine chain ───────────────────────────────────────────────────
class LeakySceneLayer extends Component {
  LeakySceneLayer(this.controller, {this.reducedMotion = false});
  final LeakyBucketController controller;
  final bool reducedMotion;

  final math.Random _rng = math.Random(7);
  final List<_Heat> _heat = [];
  double _clock = 0;
  final List<double> _spawnAccum = [];

  double get _machineR => controller.nodeRadius * 1.7;

  @override
  void update(double dt) {
    _clock += dt;
    final segs = controller.segments;
    while (_spawnAccum.length < segs.length) {
      _spawnAccum.add(0);
    }
    final centers = controller.nodeCenters;
    if (!reducedMotion && controller.stageSize.height > 0) {
      for (var i = 0; i < segs.length; i++) {
        final reveal = controller.leakReveal(i);
        final leak = segs[i].leak;
        if (reveal <= 0.02 || leak <= 0.5) continue;
        _spawnAccum[i] += leak * 0.5 * reveal * dt;
        final sign = i.isEven ? -1.0 : 1.0;
        while (_spawnAccum[i] >= 1) {
          _spawnAccum[i] -= 1;
          final c = centers[i];
          _heat.add(_Heat(c + Offset(sign * _machineR * 0.8, (_rng.nextDouble() - 0.5) * _machineR * 0.5),
              Offset(sign * (30 + _rng.nextDouble() * 55), -28 - _rng.nextDouble() * 40), 0.9 + _rng.nextDouble() * 0.9, _machineR * (0.28 + leak / 120)));
        }
      }
    }
    for (final h in _heat) {
      h.life -= dt;
      h.pos += h.vel * dt;
      h.vel = Offset(h.vel.dx * (1 - 0.9 * dt), h.vel.dy - 6 * dt);
      h.size += dt * _machineR * 0.5;
    }
    _heat.removeWhere((h) => h.life <= 0);
  }

  @override
  void render(Canvas canvas) {
    final s = controller.stageSize;
    if (s.isEmpty) return;
    final segs = controller.segments;
    final centers = controller.nodeCenters;
    final input = controller.inputCenter;
    final bulb = controller.bulbCenter;
    final building = controller.phase.value == LBPhase.build;

    if (controller.powered) _drawStream(canvas, segs, centers, input, controller.frontY);
    _drawHeat(canvas);

    for (var i = 0; i < segs.length; i++) {
      final kind = segs[i].kind;
      if (controller.isPlaced(kind)) {
        final rev = (controller.nodeAge(i) / 0.45).clamp(0.0, 1.0);
        final aliveK = controller.leakReveal(i);
        lbReveal(canvas, s, rev, Offset(0, s.height * 0.06), centers[i], () => _drawMachine(canvas, centers[i], segs[i], aliveK));
      } else if (building) {
        _drawGhostSlot(canvas, centers[i], false);
      }
    }

    _drawInput(canvas, input);

    if (controller.bulbReveal > 0.001 || controller.bulbGlow > 0.001) {
      paintBulb(canvas, bulb, controller.bulbRadius, controller.bulbGlow);
    } else {
      // Empty bulb socket (ghost) until power-up reaches it.
      canvas.drawCircle(bulb, controller.bulbRadius, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = Colors.white.withValues(alpha: 0.12));
    }
  }

  void _drawMachine(Canvas canvas, Offset c, LeakySegment seg, double aliveK) {
    switch (seg.kind) {
      case LeakStepKind.burn:
        _drawFurnace(canvas, c, aliveK);
      case LeakStepKind.boil:
        _drawBoiler(canvas, c, aliveK);
      case LeakStepKind.spin:
        _drawTurbine(canvas, c, aliveK);
      case LeakStepKind.wire:
        _drawGenerator(canvas, c, aliveK);
    }
  }

  void _drawFurnace(Canvas canvas, Offset at, double alive) {
    final r = _machineR;
    final flick = 0.85 + 0.15 * math.sin(_clock * 9 + 1) + 0.08 * math.sin(_clock * 17);
    final box = RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: r * 2.0, height: r * 1.8), Radius.circular(r * 0.24));
    canvas.drawRRect(box.shift(const Offset(0, 4)), lbGlow(Colors.black, 8, alpha: 0.4));
    canvas.drawRRect(box, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [lbSteel, lbSteelDark]).createShader(box.outerRect));
    canvas.drawRRect(box, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = lbSteelLite.withValues(alpha: 0.6));
    final mouth = Rect.fromCenter(center: at.translate(0, r * 0.1), width: r * 1.3, height: r * 0.95);
    // Mouth: dark when cold, glowing ember when alive.
    if (alive > 0.02) {
      canvas.drawRRect(RRect.fromRectAndRadius(mouth.inflate(4), Radius.circular(r * 0.12)), lbGlow(lbEmber, r * 0.7, alpha: 0.9 * flick * alive));
      canvas.drawRRect(RRect.fromRectAndRadius(mouth, Radius.circular(r * 0.1)), Paint()..shader = RadialGradient(colors: [lbWarmHot.withValues(alpha: 0.95 * alive), Color.lerp(const Color(0xFF1A0E08), lbEmber, alive)!]).createShader(mouth));
    } else {
      canvas.drawRRect(RRect.fromRectAndRadius(mouth, Radius.circular(r * 0.1)), Paint()..color = const Color(0xFF160C06));
    }
    for (var i = 0; i < 3; i++) {
      final x = mouth.left + mouth.width * (i + 0.5) / 3;
      canvas.drawLine(Offset(x, mouth.top + 2), Offset(x, mouth.bottom - 2), Paint()..color = const Color(0xFF3A1E0E).withValues(alpha: 0.55)..strokeWidth = 1.6);
    }
  }

  void _drawBoiler(Canvas canvas, Offset at, double alive) {
    final r = _machineR;
    final body = RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: r * 1.7, height: r * 1.9), Radius.circular(r * 0.22));
    canvas.drawRRect(body.shift(const Offset(0, 4)), lbGlow(Colors.black, 8, alpha: 0.38));
    canvas.drawRRect(body, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [lbSteel, lbSteelDark]).createShader(body.outerRect));
    final win = Rect.fromCenter(center: at.translate(0, r * 0.15), width: r * 1.1, height: r * 1.2);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(win, Radius.circular(r * 0.12)));
    final top = Color.lerp(const Color(0xFF1A3A55), const Color(0xFF2A6FB0), alive)!;
    canvas.drawRect(win, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, const Color(0xFF15314F)]).createShader(win));
    if (!reducedMotion && alive > 0.05) {
      for (var i = 0; i < 6; i++) {
        final t = ((_clock * 0.6 + i / 6) % 1.0);
        final bx = win.left + win.width * ((i * 0.37 + 0.1) % 1.0);
        final by = win.bottom - win.height * t;
        canvas.drawCircle(Offset(bx, by), r * 0.07 * (0.5 + t), Paint()..color = Colors.white.withValues(alpha: 0.4 * (1 - t) * alive));
      }
    }
    canvas.restore();
    canvas.drawRRect(RRect.fromRectAndRadius(win, Radius.circular(r * 0.12)), Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = lbSteelLite.withValues(alpha: 0.4));
    canvas.drawRRect(body, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = lbSteelLite.withValues(alpha: 0.5));
    if (!reducedMotion && alive > 0.05) {
      for (var i = 0; i < 3; i++) {
        final t = ((_clock * 0.5 + i / 3) % 1.0);
        final p = at.translate((i - 1) * r * 0.35, -r * 0.95 - t * r * 0.9);
        canvas.drawCircle(p, r * 0.22 * (0.5 + t), lbGlow(lbSteam, r * 0.3, alpha: 0.18 * (1 - t) * alive));
      }
    }
  }

  void _drawTurbine(Canvas canvas, Offset at, double alive) {
    final r = _machineR * 1.05;
    final sp = controller.spinNorm;
    canvas.drawCircle(at.translate(0, r * 0.18), r * 0.95, lbGlow(Colors.black, r * 0.3, alpha: 0.28));
    if (sp > 0.05) canvas.drawCircle(at, r * (1.05 + 0.5 * sp), lbGlow(lbEnergy, r * 0.7, alpha: 0.28 * sp, additive: true));
    if (sp > 0.12) canvas.drawCircle(at, r * 0.95, Paint()..color = lbSteel.withValues(alpha: 0.12 * sp));
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(controller.turbineAngle);
    for (var i = 0; i < 6; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 3);
      final path = Path()..moveTo(0, -r * 0.2)..lineTo(r * 0.96, -r * 0.46)..quadraticBezierTo(r * 1.02, 0, r * 0.96, r * 0.08)..lineTo(0, r * 0.2)..close();
      canvas.drawPath(path, Paint()..shader = const LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [lbSteelDark, lbSteel, lbSteelLite]).createShader(Rect.fromLTWH(0, -r * 0.46, r, r * 0.66)));
      canvas.drawLine(Offset(r * 0.1, -r * 0.2), Offset(r * 0.92, -r * 0.42), Paint()..color = lbSteelLite.withValues(alpha: 0.7)..strokeWidth = 1.4..strokeCap = StrokeCap.round);
      canvas.restore();
    }
    canvas.restore();
    canvas.drawCircle(at, r * 0.26, Paint()..shader = RadialGradient(center: const Alignment(-0.4, -0.4), colors: [lbSteelLite, lbSteelDark]).createShader(Rect.fromCircle(center: at, radius: r * 0.26)));
    canvas.drawCircle(at, r * 0.26, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = lbSteelLite.withValues(alpha: 0.6));
    canvas.drawCircle(at, r * 0.08, Paint()..color = lbGlassDeep);
  }

  void _drawGenerator(Canvas canvas, Offset at, double alive) {
    final r = _machineR;
    final body = RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: r * 2.0, height: r * 1.5), Radius.circular(r * 0.2));
    canvas.drawRRect(body.shift(const Offset(0, 4)), lbGlow(Colors.black, 8, alpha: 0.36));
    canvas.drawRRect(body, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [lbSteel, lbSteelDark]).createShader(body.outerRect));
    const rings = 5;
    for (var i = 0; i < rings; i++) {
      final x = at.dx - r * 0.8 + r * 1.6 * i / (rings - 1);
      final sheen = ((_clock * 0.8 + i / rings) % 1.0);
      final lit = (1 - (sheen - 0.5).abs() * 2).clamp(0.0, 1.0) * alive;
      final col = Color.lerp(const Color(0xFF6E4A2B), const Color(0xFFF0BD82), lit)!;
      canvas.drawLine(Offset(x, at.dy - r * 0.55), Offset(x, at.dy + r * 0.55), Paint()..color = col..strokeWidth = r * 0.16..strokeCap = StrokeCap.round);
    }
    canvas.drawRRect(body, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = lbSteelLite.withValues(alpha: 0.5));
  }

  void _drawStream(Canvas canvas, List<LeakySegment> segs, List<Offset> centers, Offset input, double frontY) {
    final colX = input.dx;
    final maxHalf = controller.streamMaxWidth / 2;
    double valueAt(double y) {
      if (y <= centers.first.dy) return LeakyModel.input;
      for (var i = 0; i < segs.length - 1; i++) {
        if (y <= centers[i + 1].dy) return segs[i].outValue;
      }
      return segs.last.outValue;
    }

    double halfAt(double y) => math.max(2.5, (valueAt(y) / LeakyModel.input) * maxHalf);
    const steps = 48;
    final top = input.dy, bottom = frontY;
    if (bottom <= top + 1) return;
    final left = <Offset>[], right = <Offset>[];
    for (var k = 0; k <= steps; k++) {
      final y = top + (bottom - top) * (k / steps);
      final hw = halfAt(y);
      left.add(Offset(colX - hw, y));
      right.add(Offset(colX + hw, y));
    }
    final path = Path()..moveTo(left.first.dx, left.first.dy);
    for (final p in left.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    for (final p in right.reversed) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, lbGlow(lbEnergy, 16, alpha: 0.34, additive: true));
    canvas.drawPath(path, Paint()..color = lbEnergy.withValues(alpha: 0.5));
    canvas.drawPath(path, Paint()..color = lbWarmHot.withValues(alpha: 0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    if (!reducedMotion) {
      const n = 16;
      for (var i = 0; i < n; i++) {
        final t = ((_clock * 0.55) + i / n) % 1.0;
        final y = top + (bottom - top) * t;
        final hw = halfAt(y);
        final jitter = math.sin(_clock * 4 + i) * hw * 0.4;
        final a = (1 - (t - 0.5).abs() * 1.4).clamp(0.0, 1.0);
        canvas.drawCircle(Offset(colX + jitter, y), 2.4, lbGlow(Colors.white, 3, alpha: 0.5 * a, additive: true));
      }
    }
  }

  void _drawHeat(Canvas canvas) {
    for (final h in _heat) {
      final a = (h.life / 1.8).clamp(0.0, 1.0);
      final hot = Color.lerp(lbHeat, const Color(0xFF6A5048), 1 - a)!;
      final p = Paint()..color = hot.withValues(alpha: 0.5 * a)..blendMode = BlendMode.plus..maskFilter = MaskFilter.blur(BlurStyle.normal, h.size * 1.0);
      canvas.drawCircle(h.pos, h.size * 0.85, p);
      canvas.drawCircle(h.pos + Offset(h.size * 0.32, -h.size * 0.34), h.size * 0.62, p);
      canvas.drawCircle(h.pos + Offset(-h.size * 0.28, -h.size * 0.18), h.size * 0.5, p);
      if (a > 0.6) canvas.drawCircle(h.pos, h.size * 0.34, Paint()..color = lbWarmHot.withValues(alpha: 0.5 * (a - 0.6) / 0.4)..blendMode = BlendMode.plus..maskFilter = MaskFilter.blur(BlurStyle.normal, h.size * 0.4));
    }
  }

  void _drawGhostSlot(Canvas canvas, Offset c, bool isBulb) {
    final r = (isBulb ? controller.bulbRadius : _machineR) * 1.05;
    final pulse = 0.5 + 0.5 * math.sin(_clock * 2 * math.pi * 0.9);
    final col = Colors.white.withValues(alpha: 0.22 + 0.22 * pulse);
    canvas.drawCircle(c, r * (1 + 0.06 * pulse), lbGlow(col, 8, alpha: 0.14 + 0.14 * pulse, additive: true));
    const dashes = 20;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round..color = col;
    for (var i = 0; i < dashes; i++) {
      final a0 = (i / dashes) * 2 * math.pi + _clock * 0.6;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a0, (math.pi / dashes) * 0.9, false, paint);
    }
    _drawGlyph(canvas, Icons.add_rounded, c, r * 0.7, col);
  }

  void _drawInput(Canvas canvas, Offset c) {
    final r = controller.inputRadius;
    final pulse = reducedMotion ? 1.0 : (1 + 0.06 * math.sin(_clock * 2.2));
    canvas.drawCircle(c, r * 1.5 * pulse, lbGlow(lbEmber, r, alpha: 0.32, additive: true));
    canvas.drawCircle(c, r, Paint()..shader = RadialGradient(colors: [lbWarmHot, lbEmber]).createShader(Rect.fromCircle(center: c, radius: r)));
    for (var i = 0; i < 3; i++) {
      final a = i * 2.1 + 0.5;
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r * 0.4, r * 0.26, Paint()..color = const Color(0xFF2A1A12).withValues(alpha: 0.7));
    }
  }

  void _drawGlyph(Canvas canvas, IconData icon, Offset center, double size, Color color) {
    final tp = TextPainter(text: TextSpan(text: String.fromCharCode(icon.codePoint), style: TextStyle(fontSize: size, fontFamily: icon.fontFamily, package: icon.fontPackage, color: color)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }
}

class _Heat {
  _Heat(this.pos, this.vel, this.life, this.size);
  Offset pos;
  Offset vel;
  double life;
  double size;
}
