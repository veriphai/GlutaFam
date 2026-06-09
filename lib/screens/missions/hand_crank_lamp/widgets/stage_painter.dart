// The single canvas (PRD §6: "CustomPainter for crank, wire, lamp, pulse, the
// onDiscovery emphasis ring, and the three alternate outputs. Single canvas;
// transparent background.").
//
// Pure renderer: it reads the controller's getters and repaints every frame via
// `repaint: controller`. It holds NO state and makes NO decisions — brightness,
// generating, the spin angle, the discovery flash are all computed in the
// controller. Glow/flash/pulse use additive blending so they read as light.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/output_defs.dart';
import '../state/crank_controller.dart';

class StagePainter extends CustomPainter {
  StagePainter(this.c) : super(repaint: c);

  final CrankController c;

  @override
  void paint(Canvas canvas, Size size) {
    c.setStageSize(size);

    _paintWireAndPulse(canvas);
    _paintOutput(canvas);
    _paintDiscoveryRing(canvas);
    _paintCrank(canvas);
  }

  // --- Wire + travelling energy pulse (PRD §4.5) -----------------------------
  void _paintWireAndPulse(Canvas canvas) {
    final start = c.wireStart;
    final end = c.wireEnd;
    // A gentle catenary-ish sag between crank and device.
    final mid = Offset((start.dx + end.dx) / 2, math.max(start.dy, end.dy) + 26);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);

    // Base wire — always present, dim.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF2C3A63),
    );

    // Energy pulse — ONLY while generating, intensity ~ brightness. Never drawn
    // when dark or on a held-still crank (criterion 7).
    if (!c.isGenerating || c.brightness <= 0.01) return;
    final metric = path.computeMetrics().first;
    final len = metric.length;
    final accent = kOutputDefs[c.activeOutput.value]!.accent;
    final glow = Paint()
      ..blendMode = BlendMode.plus
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // A few bright packets marching crank → device.
    const packets = 3;
    for (var i = 0; i < packets; i++) {
      final f = (c.pulsePhase + i / packets) % 1.0;
      final pos = metric.getTangentForOffset(f * len)?.position;
      if (pos == null) continue;
      // Fade packets in/out near the ends so they appear to be "carried".
      final edge = (math.sin(f * math.pi)).clamp(0.0, 1.0);
      final a = (c.brightness * edge).clamp(0.0, 1.0);
      glow
        ..strokeWidth = 7
        ..color = accent.withValues(alpha: 0.9 * a);
      canvas.drawCircle(pos, 5.5, glow..style = PaintingStyle.fill);
      canvas.drawCircle(
        pos,
        11,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = accent.withValues(alpha: 0.35 * a),
      );
    }
  }

  // --- The active output device (PRD §3.3, §4.7) -----------------------------
  void _paintOutput(Canvas canvas) {
    final def = kOutputDefs[c.activeOutput.value]!;
    final center = c.outputCenter;
    final r = c.outputRadius;
    final b = c.brightness;

    // Device housing — a soft dark disc, always visible so the device reads even
    // when off.
    canvas.drawCircle(
      center,
      r,
      Paint()..color = const Color(0xFF111A33),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF2C3A63),
    );

    switch (def.output) {
      case ActiveOutput.lamp:
        _paintLamp(canvas, center, r, b, def.accent);
      case ActiveOutput.fan:
        _paintFan(canvas, center, r, b, def.accent);
      case ActiveOutput.heater:
        _paintHeater(canvas, center, r, b, def.accent);
      case ActiveOutput.speaker:
        _paintSpeaker(canvas, center, r, b, def.accent);
    }
  }

  void _paintLamp(Canvas canvas, Offset center, double r, double b, Color accent) {
    // Bulb body.
    final bulbR = r * 0.5;
    // Outer halo grows with brightness (additive so 0 brightness = invisible).
    if (b > 0.01) {
      canvas.drawCircle(
        center,
        bulbR + r * 1.0 * b,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(
            colors: [accent.withValues(alpha: 0.85 * b), accent.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: center, radius: bulbR + r * b)),
      );
    }
    // Glass.
    canvas.drawCircle(
      center,
      bulbR,
      Paint()..color = Color.lerp(const Color(0xFF1B2747), accent, b * 0.9)!,
    );
    // Filament core — pops bright with brightness.
    canvas.drawCircle(
      center,
      bulbR * 0.5,
      Paint()
        ..blendMode = BlendMode.plus
        ..color = Colors.white.withValues(alpha: b),
    );
  }

  void _paintFan(Canvas canvas, Offset center, double r, double b, Color accent) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(c.spinAngle); // frozen on stop → fan stops instantly (§4.4)
    final bladeR = r * 0.72;
    final lit = Color.lerp(const Color(0xFF44507A), accent, b)!;
    final blade = Paint()..color = lit;
    for (var i = 0; i < 4; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 2);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(bladeR * 0.5, -bladeR * 0.34, bladeR, -bladeR * 0.05)
        ..quadraticBezierTo(bladeR * 0.6, bladeR * 0.18, 0, 0)
        ..close();
      canvas.drawPath(path, blade);
      canvas.restore();
    }
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
    final coilColor = Color.lerp(const Color(0xFF3A2A22), accent, b)!;
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
    final coneColor = Color.lerp(const Color(0xFF2A3358), accent, b * 0.6)!;
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
      c.wireEnd,
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

    // Housing / base plate.
    canvas.drawCircle(pivot, len * 0.32, Paint()..color = const Color(0xFF1B2747));
    canvas.drawCircle(
      pivot,
      len * 0.32,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF38477A),
    );

    // The handle arm rotates by handleAngle — the SIGN of angular velocity (the
    // handle "visually turns the way the finger drags"). It does NOT free-spin.
    final knob = Offset(
      pivot.dx + len * math.cos(c.handleAngle),
      pivot.dy + len * math.sin(c.handleAngle),
    );
    canvas.drawLine(
      pivot,
      knob,
      Paint()
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF6E7BB5),
    );
    // Grab knob — tinted by how hard they're cranking (energyInput) for feedback.
    final knobColor = Color.lerp(
      const Color(0xFFB9C4F0),
      kOutputDefs[c.activeOutput.value]!.accent,
      c.isGenerating ? (0.4 + 0.5 * c.energyInput) : 0.0,
    )!;
    canvas.drawCircle(knob, len * 0.2, Paint()..color = knobColor);
    canvas.drawCircle(
      knob,
      len * 0.2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.5),
    );
    // Centre hub cap.
    canvas.drawCircle(pivot, len * 0.08, Paint()..color = const Color(0xFF0C1430));
  }

  @override
  bool shouldRepaint(covariant StagePainter old) => false; // repaint: c drives it
}
