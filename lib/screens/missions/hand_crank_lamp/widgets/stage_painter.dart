// The single canvas (PRD §6: "CustomPainter for crank, wire, lamp, pulse, the
// onDiscovery emphasis ring, and the three alternate outputs. Single canvas;
// transparent background.").
//
// Pure renderer: it reads the controller's getters and repaints every frame via
// `repaint: controller`. It holds NO state and makes NO decisions — brightness,
// generating, the spin angle, the discovery flash are all computed in the
// controller. Glow/flash/pulse use additive blending so they read as light.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../config/output_defs.dart';
import '../state/crank_controller.dart';
import 'bulb.dart';

class StagePainter extends CustomPainter {
  StagePainter(this.c) : super(repaint: c);

  final CrankController c;

  /// The active device's bloom/ray/particle colour.
  Color get _bloom => kOutputDefs[c.activeOutput.value]!.bloom;

  /// Where the wire connects to the device — the BOTTOM of the device, facing
  /// down toward the generator box below it (vertical layout). The bulb wires to
  /// its SCREW BASE; the housing-disc devices to their bottom edge.
  Offset get _wireEnd {
    final ctr = c.outputCenter;
    final r = c.outputRadius;
    if (c.activeOutput.value == ActiveOutput.lamp) {
      return Offset(ctr.dx, ctr.dy + r * 1.12); // screw base, bottom-centre
    }
    return Offset(ctr.dx, ctr.dy + r * 0.94); // housing device, bottom-centre
  }

  @override
  void paint(Canvas canvas, Size size) {
    c.setStageSize(size);

    _paintSurface(canvas); // grounding contact shadows (the hero sits on a surface)
    _paintDeviceBloom(canvas); // light into the dark
    _paintLightRays(canvas); // radiant god-rays from the lit device
    _paintWireAndPulse(canvas); // box → device
    _paintBox(canvas); // the generator (covers the wire's start)
    _paintOutput(canvas); // device (covers the wire's end)
    _paintDiscoveryRing(canvas);
    _paintShaft(canvas); // handle → box (vertical)
    _paintCrank(canvas); // hub covers the shaft's bottom end
    _paintParticles(canvas); // sparks + device debris, on top
  }

  // --- The generator box (handle → shaft → BOX → wire → device) --------------
  void _paintBox(Canvas canvas) {
    final ctr = c.boxCenter;
    final s = c.boxSize;
    final b = c.brightness;
    final bloom = _bloom;
    final rect = Rect.fromCenter(center: ctr, width: s.width, height: s.height);
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(s.width * 0.12));

    // Housing — beveled metal body + rim + a top inner highlight.
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6E7EB8), Color(0xFF45548C)],
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.4),
          Radius.circular(s.width * 0.12)),
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
    canvas.drawRRect(rr, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0xFFAEB9E8));

    // Cooling vents — slots on the left third.
    for (var i = 0; i < 3; i++) {
      final vy = ctr.dy - s.height * 0.22 + i * s.height * 0.22;
      final v = Rect.fromCenter(
          center: Offset(ctr.dx - s.width * 0.27, vy), width: s.width * 0.26, height: s.height * 0.07);
      canvas.drawRRect(
        RRect.fromRectAndRadius(v, Radius.circular(s.height * 0.04)),
        Paint()..color = Colors.black.withValues(alpha: 0.4),
      );
    }

    // Inspection port — a sealed dark window (NO rotor; a spinning part read as a
    // second fan). It glows softly from within while generating, so it reads as
    // working without any literal moving part.
    final win = Offset(ctr.dx + s.width * 0.16, ctr.dy);
    final winR = s.height * 0.30;
    canvas.drawCircle(win, winR, Paint()..color = const Color(0xFF070B1A));
    if (b > 0.01) {
      canvas.drawCircle(
        win,
        winR,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(colors: [bloom.withValues(alpha: 0.5 * b), bloom.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: win, radius: winR)),
      );
    }
    canvas.drawCircle(win, winR * 0.86, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = Colors.black.withValues(alpha: 0.4));
    canvas.drawCircle(win, winR, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = const Color(0xFFAEB9E8));

    // Working indicator LED — green-bright while generating.
    final led = Offset(ctr.dx - s.width * 0.30, ctr.dy - s.height * 0.32);
    final ledOn = b > 0.02;
    canvas.drawCircle(led, s.width * 0.028,
        Paint()..color = ledOn ? const Color(0xFF7CF08A) : const Color(0xFF1C2A40));
    if (ledOn) {
      canvas.drawCircle(led, s.width * 0.05,
          Paint()..blendMode = BlendMode.plus..color = const Color(0xFF7CF08A).withValues(alpha: 0.6 * b));
    }

    // Corner bolts.
    final inset = Offset(s.width * 0.4, s.height * 0.32);
    for (final sx in [-1.0, 1.0]) {
      for (final sy in [-1.0, 1.0]) {
        final bp = ctr + Offset(sx * inset.dx, sy * inset.dy);
        canvas.drawCircle(bp, s.width * 0.022, Paint()..color = const Color(0xFF0C1430));
        canvas.drawCircle(bp.translate(-0.6, -0.6), s.width * 0.01, Paint()..color = Colors.white.withValues(alpha: 0.3));
      }
    }
  }

  // --- The shaft (handle → box) — a VERTICAL cylindrical axle with travelling
  // rib-rings: the handle below turns the shaft up into the generator box.
  void _paintShaft(Canvas canvas) {
    final pivot = c.pivot;
    final len = c.handleLength;
    final start = Offset(pivot.dx, pivot.dy - len * 0.3); // from inside the flange, upward
    final end = Offset(c.boxCenter.dx, c.boxCenter.dy + c.boxSize.height / 2 - 1); // box bottom
    if (end.dy >= start.dy) return;
    final halfW = c.outputRadius * 0.13;
    final rect = Rect.fromLTRB(start.dx - halfW, end.dy, start.dx + halfW, start.dy);

    // Drop shadow.
    canvas.drawRect(
      rect.shift(const Offset(3, 0)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    // Cylindrical body (dark edges → bright centre) — horizontal gradient for a
    // vertical axle.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF515E94), Color(0xFFB9C4F0), Color(0xFF515E94)],
          stops: [0, 0.5, 1],
        ).createShader(rect),
    );
    // Rib rings travelling with the rotation (the handle turns the shaft).
    final ribPhase = ((c.handleAngle * 0.4) % 1.0 + 1.0) % 1.0;
    const n = 5;
    for (var i = 0; i < n; i++) {
      final t = ((i + ribPhase) / n) % 1.0;
      final p = Offset.lerp(start, end, t)!;
      canvas.drawLine(
        Offset(p.dx - halfW, p.dy),
        Offset(p.dx + halfW, p.dy),
        Paint()..color = const Color(0xFF3A4670).withValues(alpha: 0.7)..strokeWidth = 1.6,
      );
    }
    // Coupling collar at the box end.
    canvas.drawCircle(end, halfW * 1.5, Paint()..color = const Color(0xFF3E4C80));
    canvas.drawCircle(end, halfW * 1.5, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = const Color(0xFFAEB9E8));
  }

  // --- Surface grounding (polish Phase C) ------------------------------------
  /// Soft contact shadows under the crank base + device so the hero reads as
  /// sitting on a surface, not floating in a void.
  void _paintSurface(Canvas canvas) {
    final pivot = c.pivot;
    final len = c.handleLength;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    // Vertical layout: soft grounding under the handle (the apparatus's base);
    // the box + bulb float on the wired column above it.
    canvas.drawOval(
      Rect.fromCenter(center: pivot.translate(0, len * 0.95), width: len * 1.9, height: len * 0.5),
      shadow,
    );
  }

  // --- Radiant light rays from the lit device (polish Phase B) ---------------
  void _paintLightRays(Canvas canvas) {
    final out = c.activeOutput.value;
    // Rays read as radiance — fitting for the lamp + heater; fan/speaker get
    // their own effects instead.
    if (out != ActiveOutput.lamp && out != ActiveOutput.heater) return;
    final b = c.brightness;
    if (b <= 0.05) return;
    final center = c.outputCenter;
    final color = _bloom;
    const rays = 14;
    final maxLen = c.outputRadius * (2.4 + 3.4 * b);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(c.pulsePhase * 0.7);
    for (var i = 0; i < rays; i++) {
      final a = i / rays * 2 * math.pi;
      // Per-ray shimmer so it twinkles like a star, not a fixed sunburst.
      final len = maxLen * (0.55 + 0.45 * (0.5 + 0.5 * math.sin(i * 1.7 + c.spinAngle)));
      final tip = Offset(math.cos(a), math.sin(a)) * len;
      canvas.drawLine(
        Offset.zero,
        tip,
        Paint()
          ..blendMode = BlendMode.plus
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..shader = ui.Gradient.linear(
            Offset.zero,
            tip,
            [color.withValues(alpha: 0.5 * b), color.withValues(alpha: 0)],
          ),
      );
    }
    canvas.restore();
  }

  // --- Energy particles (polish Phase B) -------------------------------------
  void _paintParticles(Canvas canvas) {
    final ps = c.particles;
    if (ps.isEmpty) return;
    for (final p in ps) {
      final a = p.alpha;
      canvas.drawCircle(
        p.pos,
        p.size * 1.9,
        Paint()
          ..blendMode = BlendMode.plus
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
          ..color = p.color.withValues(alpha: 0.5 * a),
      );
      canvas.drawCircle(
        p.pos,
        p.size,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = p.color.withValues(alpha: 0.9 * a),
      );
    }
  }

  /// The device casts a soft radial bloom into the dark, intensity scaling with
  /// crank speed (brightness). Gated on brightness, which is HARD-ZEROED on stop
  /// — so the bloom snaps to nothing the instant cranking stops (§2/§4.4). No
  /// fade is applied here; that would undo the lesson.
  void _paintDeviceBloom(Canvas canvas) {
    final b = c.brightness;
    if (b <= 0.01) return;
    final center = c.outputCenter;
    final r = c.outputRadius;
    final bloom = _bloom;
    final radius = r * (1.7 + 2.6 * b);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [bloom.withValues(alpha: 0.5 * b), bloom.withValues(alpha: 0)],
          stops: const [0, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  // --- Wire + travelling energy pulse (PRD §4.5) -----------------------------
  void _paintWireAndPulse(Canvas canvas) {
    final start = c.wireStart;
    final end = _wireEnd;
    // A gentle sideways bow on the vertical run between box and device.
    final mid = Offset((start.dx + end.dx) / 2 + 16, (start.dy + end.dy) / 2);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);

    final b = c.brightness;
    final flowing = c.isGenerating && b > 0.01;
    final pulseColor = _bloom;

    // Base wire — a live conduit. Dim when idle; faintly warmed while current
    // flows (snaps back to dim on stop, since `b` hard-zeroes).
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = Color.lerp(const Color(0xFF2C3A63), pulseColor, flowing ? 0.25 * b : 0.0)!,
    );

    // Continuous additive glow along the whole wire while current flows — the
    // conduit itself lights up (snaps off with `b` on stop).
    if (flowing) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.plus
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
          ..color = pulseColor.withValues(alpha: 0.22 * b),
      );
    }

    // Current-pulse — luminous warm dots with a soft blur-glow travelling
    // crank → device. ONLY while generating; never on a dark/held-still crank
    // (criterion 7).
    if (!flowing) return;
    final metric = path.computeMetrics().first;
    final len = metric.length;

    const packets = 3;
    for (var i = 0; i < packets; i++) {
      final f = (c.pulsePhase + i / packets) % 1.0;
      final pos = metric.getTangentForOffset(f * len)?.position;
      if (pos == null) continue;
      // Fade packets in/out near the ends so they appear to be "carried".
      final edge = math.sin(f * math.pi).clamp(0.0, 1.0);
      final a = (b * edge).clamp(0.0, 1.0);
      // Soft blurred halo.
      canvas.drawCircle(
        pos,
        10,
        Paint()
          ..blendMode = BlendMode.plus
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
          ..color = pulseColor.withValues(alpha: 0.55 * a),
      );
      // Bright warm core with a white-hot centre.
      canvas.drawCircle(pos, 6, Paint()..blendMode = BlendMode.plus..color = pulseColor.withValues(alpha: 0.85 * a));
      canvas.drawCircle(pos, 3, Paint()..blendMode = BlendMode.plus..color = Colors.white.withValues(alpha: 0.9 * a));
    }
  }

  // --- The active output device (PRD §3.3, §4.7) -----------------------------
  void _paintOutput(Canvas canvas) {
    final def = kOutputDefs[c.activeOutput.value]!;
    final center = c.outputCenter;
    final r = c.outputRadius;
    final b = c.brightness;

    // The housing disc + idle ember are for the fan/heater/speaker only — the
    // lamp is the self-contained glass bulb (its own globe + screw base).
    if (def.output != ActiveOutput.lamp) {
      // Device housing — a dark disc with inner depth. Radial body (darker
      // centre) + an inset shadow ring + a top rim highlight = a recessed socket.
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.3, -0.4),
            colors: [Color(0xFF52628E), Color(0xFF323F68)],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
      canvas.drawCircle(
        center,
        r * 0.9,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.14
          ..color = Colors.black.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0xFFAEB9E8),
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r - 1),
        math.pi * 0.85,
        math.pi * 0.7,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.16),
      );
      // Idle standby ember — a faint breathing glow so the device is never fully
      // dead at rest. Vanishes the moment real output begins.
      if (b <= 0.02) {
        final pulse = 0.05 + 0.035 * (0.5 + 0.5 * math.sin(c.clock * 1.4));
        canvas.drawCircle(
          center,
          r * 0.6,
          Paint()
            ..blendMode = BlendMode.plus
            ..shader = RadialGradient(
              colors: [_bloom.withValues(alpha: pulse), _bloom.withValues(alpha: 0)],
            ).createShader(Rect.fromCircle(center: center, radius: r * 0.6)),
        );
      }
    }

    switch (def.output) {
      case ActiveOutput.lamp:
        // The shared trace_it_back glass bulb — self-contained art.
        paintBulb(canvas, center, r, b);
      case ActiveOutput.fan:
        _paintFan(canvas, center, r, b, def.accent);
      case ActiveOutput.heater:
        _paintHeater(canvas, center, r, b, def.accent);
      case ActiveOutput.speaker:
        _paintSpeaker(canvas, center, r, b, def.accent);
    }
  }

  void _paintFan(Canvas canvas, Offset center, double r, double b, Color accent) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    final bladeR = r * 0.72;
    final lit = Color.lerp(const Color(0xFF8997C6), accent, b)!;

    // Draw the 4-blade rotor at a given spin offset + alpha (for motion-blur
    // ghosts that trail the spin — more/blurrier the faster it turns).
    void rotor(double offset, double alpha) {
      canvas.save();
      canvas.rotate(c.spinAngle + offset); // frozen on stop → fan stops instantly
      final paint = Paint()..color = lit.withValues(alpha: alpha);
      for (var i = 0; i < 4; i++) {
        canvas.save();
        canvas.rotate(i * math.pi / 2);
        final path = Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(bladeR * 0.5, -bladeR * 0.34, bladeR, -bladeR * 0.05)
          ..quadraticBezierTo(bladeR * 0.6, bladeR * 0.18, 0, 0)
          ..close();
        canvas.drawPath(path, paint);
        canvas.restore();
      }
      canvas.restore();
    }

    if (b > 0.05) {
      rotor(-0.24 * b, 0.20 * b);
      rotor(-0.48 * b, 0.11 * b);
    }
    rotor(0, 1.0);
    canvas.drawCircle(Offset.zero, r * 0.16, Paint()..color = const Color(0xFF0C1430));
    canvas.restore();
    // A faint motion glow while running.
    if (b > 0.01) {
      canvas.drawCircle(
        center,
        r * 0.8,
        Paint()
          ..blendMode = BlendMode.plus
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = accent.withValues(alpha: 0.35 * b),
      );
    }
  }

  void _paintHeater(Canvas canvas, Offset center, double r, double b, Color accent) {
    // Glowing coils — represent ACTIVE heat production, no retained warmth. The
    // glow is driven straight off brightness, which is hard-zeroed on stop, so
    // there is NO thermal afterglow (PRD §4.7, criterion 9).
    final coilColor = Color.lerp(const Color(0xFF8C7060), accent, b)!;
    final n = 4;
    final span = r * 1.3;
    for (var i = 0; i < n; i++) {
      final y = center.dy - span / 2 + span * i / (n - 1);
      final rect = Rect.fromLTWH(center.dx - r * 0.65, y - 4, r * 1.3, 8);
      if (b > 0.01) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.inflate(4), const Radius.circular(8)),
          Paint()
            ..blendMode = BlendMode.plus
            ..color = accent.withValues(alpha: 0.6 * b),
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()..color = coilColor,
      );
    }
  }

  void _paintSpeaker(Canvas canvas, Offset center, double r, double b, Color accent) {
    // Cone.
    final coneColor = Color.lerp(const Color(0xFF66729E), accent, b * 0.6)!;
    canvas.drawCircle(center, r * 0.42, Paint()..color = coneColor);
    canvas.drawCircle(center, r * 0.18, Paint()..color = const Color(0xFF0C1430));
    // Sound waves — concentric arcs that exist ONLY while producing (b>0); gone
    // instantly on stop.
    if (b <= 0.01) return;
    for (var i = 0; i < 3; i++) {
      final phase = (c.pulsePhase + i / 3) % 1.0;
      final radius = r * (0.5 + phase * 0.7);
      final a = (1 - phase) * b;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 4,
        math.pi / 2,
        false,
        Paint()
          ..blendMode = BlendMode.plus
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = accent.withValues(alpha: 0.7 * a),
      );
    }
  }

  // --- onDiscovery visual emphasis (PRD §4.6) --------------------------------
  // A brief expanding ring/flash on the lamp + wire at the instant of cutoff. No
  // text — the explanation is the scripted afterLine ~420ms later.
  void _paintDiscoveryRing(Canvas canvas) {
    final f = c.flashIntensity;
    if (f <= 0.01) return;
    final center = c.outputCenter;
    final baseR = c.outputRadius;
    // Ring expands as the flash decays.
    final ringR = baseR * (1.0 + 1.4 * (1 - f));
    canvas.drawCircle(
      center,
      ringR,
      Paint()
        ..blendMode = BlendMode.plus
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.white.withValues(alpha: 0.9 * f),
    );
    // A sympathetic pulse on the wire's device end.
    canvas.drawCircle(
      _wireEnd,
      18 * (1 + (1 - f)),
      Paint()
        ..blendMode = BlendMode.plus
        ..color = const Color(0xFF9AD8FF).withValues(alpha: 0.5 * f),
    );
  }

  // --- The crank (PRD §3.2) --------------------------------------------------
  void _paintCrank(Canvas canvas) {
    final pivot = c.pivot;
    final len = c.handleLength;

    // Mounting flange — a metal base plate the crank is bolted to (Phase C
    // craft: it reads as mounted hardware, not a floating stick).
    final flangeR = len * 0.46;
    canvas.drawCircle(
      pivot,
      flangeR,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.45),
          colors: [Color(0xFF6D7DB6), Color(0xFF3E4C80)],
        ).createShader(Rect.fromCircle(center: pivot, radius: flangeR)),
    );
    canvas.drawCircle(
      pivot,
      flangeR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFAEB9E8),
    );
    // Bolt heads around the flange.
    for (var i = 0; i < 4; i++) {
      final a = math.pi / 4 + i * math.pi / 2;
      final bp = pivot + Offset(math.cos(a), math.sin(a)) * flangeR * 0.78;
      canvas.drawCircle(bp, len * 0.035, Paint()..color = const Color(0xFF0C1430));
      canvas.drawCircle(bp.translate(-0.6, -0.6), len * 0.016, Paint()..color = Colors.white.withValues(alpha: 0.3));
    }

    // Housing — recessed (radial body + rim).
    canvas.drawCircle(
      pivot,
      len * 0.32,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Color(0xFF5E6EA6), Color(0xFF3E4C80)],
        ).createShader(Rect.fromCircle(center: pivot, radius: len * 0.32)),
    );
    canvas.drawCircle(
      pivot,
      len * 0.32,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFAEB9E8),
    );

    // The handle arm rotates by handleAngle — the SIGN of angular velocity (the
    // handle "visually turns the way the finger drags"). It does NOT free-spin.
    final knob = Offset(
      pivot.dx + len * math.cos(c.handleAngle),
      pivot.dy + len * math.sin(c.handleAngle),
    );
    // Arm with a soft drop shadow + a beveled metal body.
    canvas.drawLine(
      pivot.translate(0, 2.5),
      knob.translate(0, 2.5),
      Paint()
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawLine(
      pivot,
      knob,
      Paint()
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [Color(0xFF8794C8), Color(0xFF515E94)],
        ).createShader(Rect.fromPoints(pivot, knob)),
    );

    // Beveled grab knob — drop shadow → radial body (energy-tinted) → highlight.
    final knobR = len * 0.2;
    final knobColor = Color.lerp(
      const Color(0xFFB9C4F0),
      _bloom,
      c.isGenerating ? (0.45 + 0.5 * c.energyInput) : 0.0,
    )!;
    canvas.drawCircle(
      knob.translate(0, 3),
      knobR,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      knob,
      knobR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: [Color.lerp(knobColor, Colors.white, 0.5)!, knobColor],
        ).createShader(Rect.fromCircle(center: knob, radius: knobR)),
    );
    // Specular highlight + rim.
    canvas.drawCircle(
      knob.translate(-knobR * 0.32, -knobR * 0.32),
      knobR * 0.28,
      Paint()..color = Colors.white.withValues(alpha: 0.65),
    );
    canvas.drawCircle(
      knob,
      knobR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.45),
    );
    // Grip ridges across the knob (aligned with the arm) — a handle you grip.
    canvas.save();
    canvas.translate(knob.dx, knob.dy);
    canvas.rotate(c.handleAngle);
    final ridge = Paint()
      ..color = Colors.black.withValues(alpha: 0.20)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var i = -1; i <= 1; i++) {
      final x = i * knobR * 0.42;
      canvas.drawLine(Offset(x, -knobR * 0.5), Offset(x, knobR * 0.5), ridge);
    }
    canvas.restore();
    // Centre hub cap.
    canvas.drawCircle(pivot, len * 0.085, Paint()..color = const Color(0xFF0C1430));
    canvas.drawCircle(
      pivot,
      len * 0.085,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFFAEB9E8),
    );
  }

  @override
  bool shouldRepaint(covariant StagePainter old) => false; // repaint: c drives it
}
