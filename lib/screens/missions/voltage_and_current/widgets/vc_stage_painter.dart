// Voltage and Current — the pure renderer (PRD §15/§16). Reads controller getters
// only; never mutates state. Paint order back→front:
//   ambient motes → loop wire (the FIXED wire) + conductive sheen → surge feed →
//   current RIVER (additive, the current made visible, with trails) → pressure
//   console + glowing PISTON (the cool control, VOLTAGE on the head) → lamp
//   (imported paintBulb) wrapped in volumetric BLOOM + GOD-RAYS → SAME WIRE pin
//   chip → CURRENT gauge → cutoff flash + scatter + shockwave.
//
// House style (PRD §7): the lamp + current river are the brightest things on
// screen; the console/chrome/numbers recede (cool, never out-glowing the warm
// hero); additive glows (BlendMode.plus); IBM Plex Mono numbers. The wire shows NO
// heat, ever — the sheen is COOL only (heat is 2.3's job — PRD §7.59, §12).

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../hand_crank_lamp/widgets/bulb.dart'; // read-only import: shared lamp
import '../config/vc_config.dart';
import '../config/vc_copy.dart';
import '../state/vc_controller.dart';

class VCStagePainter extends CustomPainter {
  VCStagePainter(this.c) : super(repaint: c);
  final VCController c;

  @override
  void paint(Canvas canvas, Size size) {
    c.setStageSize(size);

    _paintAmbientMotes(canvas, size);
    _paintLoopWire(canvas);
    _paintConductiveSheen(canvas);
    _paintSurge(canvas);
    _paintCurrentRiver(canvas);
    _paintConsole(canvas);
    _paintLampBloom(canvas); // volumetric bloom behind the bulb
    _paintLightRays(canvas); // radiant god-rays from the lit lamp
    _paintLamp(canvas); // the imported shared bulb
    _paintCurrentGauge(canvas);
    _paintShockwave(canvas);
    _paintScatter(canvas);
    _paintFlash(canvas, size);
  }

  // ── Ambient cool motes drifting behind the stage (≤20, PRD §7) ───────
  void _paintAmbientMotes(Canvas canvas, Size size) {
    final n = VCTune.ambientMoteCount;
    final p = Paint()..blendMode = BlendMode.plus;
    final rng = math.Random(31);
    final t = c.reducedMotion ? 0.0 : c.ambientPhase;
    for (var i = 0; i < n; i++) {
      final bx = rng.nextDouble();
      final by = rng.nextDouble();
      final sp = 0.012 + rng.nextDouble() * 0.02;
      final drift = (by + t * sp) % 1.0;
      final x = bx * size.width;
      final y = drift * size.height;
      final r = (0.7 + rng.nextDouble() * 1.4);
      p.color = const Color(0xFF6FA8FF).withValues(alpha: 0.05 + rng.nextDouble() * 0.05);
      canvas.drawCircle(Offset(x, y), r, p);
    }
  }

  // ── The loop wire — the FIXED wire (cool steel, never warms) ─────────
  void _paintLoopWire(Canvas canvas) {
    final loop = c.loopRRect;
    final reveal = c.loopReveal.clamp(0.0, 1.0);
    if (reveal <= 0.01) return;
    final path = Path()..addRRect(loop);
    // A soft under-glow so the wire reads premium, NOT hot (cool steel only).
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = c.wireStroke * 2.4
        ..color = VCTune.wireSteel.withValues(alpha: 0.16 * reveal)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = c.wireStroke
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            VCTune.wireSteel.withValues(alpha: 0.9 * reveal),
            const Color(0xFF45527A).withValues(alpha: 0.9 * reveal),
          ],
        ).createShader(loop.outerRect),
    );
  }

  // ── Conductive sheen (P1.8) — a COOL bright band travelling the live wire ─
  // Reads as "the circuit is alive". COOL only — the wire NEVER warms (hard rule).
  void _paintConductiveSheen(Canvas canvas) {
    if (!c.sheenActive) return;
    final reveal = c.loopReveal.clamp(0.0, 1.0);
    if (reveal <= 0.01) return;
    final head = c.sheenPhase; // 0..1 around the loop
    final samples = 14;
    final span = VCTune.sheenWidthFraction; // band length as a loop fraction
    final p = Paint()
      ..blendMode = BlendMode.plus
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = c.wireStroke * 1.5
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, c.wireStroke);
    for (var i = 0; i < samples; i++) {
      final f = i / (samples - 1); // 0 (tail) → 1 (head)
      final t = (head - span * (1 - f)) % 1.0;
      final a = f * f * 0.5 * reveal; // brightest at the head, fading back
      p.color = VCTune.controlCoolLite.withValues(alpha: a);
      canvas.drawCircle(_pointOnLoop(t < 0 ? t + 1 : t), c.wireStroke * 0.7, p);
    }
  }

  // ── Surge feed (P1.4) — particles streaming up from the console corners ─
  void _paintSurge(Canvas canvas) {
    final ps = c.surgeParticles;
    if (ps.isEmpty) return;
    final p = Paint()..blendMode = BlendMode.plus;
    for (final s in ps) {
      final a = s.t; // 1 → 0
      p.color = VCTune.controlCool.withValues(alpha: 0.35 * a);
      p.maskFilter = MaskFilter.blur(BlurStyle.normal, s.size * 1.6);
      canvas.drawCircle(s.pos, s.size * 1.8, p);
      p.maskFilter = null;
      p.color = VCTune.controlCoolLite.withValues(alpha: 0.8 * a);
      canvas.drawCircle(s.pos, s.size * 0.8, p);
    }
  }

  // ── The CURRENT RIVER — the current made visible (P0.2) ──────────────
  // Density ∝ current (few motes low, many high); each mote has a short fading
  // trail; bigger, brighter warm cores + a hot centre + soft glow; speed AND alpha
  // ∝ current. At current 0 the WHOLE river STOPS and VANISHES the same frame (the
  // hard cutoff) — no trail tail lingering (alpha gate returns early).
  void _paintCurrentRiver(Canvas canvas) {
    final alpha = c.moteAlpha;
    if (alpha <= 0) return; // vanished — no current (same frame)
    final n = c.moteCount;
    if (n <= 0) return;
    final reveal = c.loopReveal.clamp(0.0, 1.0);
    final a0 = (alpha * reveal).clamp(0.0, 1.0);
    final rMote = c.lampRadius * 0.14;
    final trail = c.reducedMotion ? 1 : VCTune.moteTrailSamples;
    final glow = Paint()..blendMode = BlendMode.plus;
    final core = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < n; i++) {
      final base = (c.motePhase + i / n) % 1.0;
      // Trail: samples BEHIND the head along the loop, fading toward the tail.
      for (var s = trail - 1; s >= 0; s--) {
        final t = (base - s * VCTune.moteTrailSpacing) % 1.0;
        final pos = _pointOnLoop(t < 0 ? t + 1 : t);
        final fade = trail == 1 ? 1.0 : 1.0 - s / trail; // head bright, tail faint
        final a = a0 * fade;
        final rr = rMote * (0.55 + 0.45 * fade); // tail thins
        // soft warm halo
        glow.color = VCTune.moteWarm.withValues(alpha: 0.5 * a);
        glow.maskFilter = MaskFilter.blur(BlurStyle.normal, rr * 1.6);
        canvas.drawCircle(pos, rr * 1.7, glow);
        if (s == 0) {
          // the head — a brighter warm core + a hot white-ish centre.
          core.maskFilter = null;
          core.color = VCTune.moteWarm.withValues(alpha: 0.95 * a);
          canvas.drawCircle(pos, rr * 1.15, core);
          core.color = VCTune.moteHot.withValues(alpha: 0.98 * a);
          canvas.drawCircle(pos, rr * 0.62, core);
        }
      }
    }
  }

  /// A point at perimeter fraction [t] (0..1) walking the rounded-rect CLOCKWISE,
  /// starting at the top-centre and going right-down-left-up. Corners are arcs.
  Offset _pointOnLoop(double t) {
    final loop = c.loopRRect;
    final r = loop.tlRadiusX; // uniform corner radius
    final rect = loop.outerRect;
    final l = rect.left, rt = rect.right, tp = rect.top, bt = rect.bottom;
    final straightH = (rt - l) - 2 * r; // top & bottom straight length
    final straightV = (bt - tp) - 2 * r; // left & right straight length
    final arc = (math.pi / 2) * r; // each corner arc length
    final total = 2 * straightH + 2 * straightV + 4 * arc;
    var d = (t % 1.0) * total;

    // Start at top-centre, go RIGHT along the top.
    // Segment order: topRight-half → TR corner → right side → BR corner →
    // bottom → BL corner → left side → TL corner → topLeft-half.
    final cx = (l + rt) / 2;
    // 1) top-centre → top-right straight (half the top straight)
    final halfTop = straightH / 2;
    if (d <= halfTop) {
      return Offset(cx + d, tp);
    }
    d -= halfTop;
    // 2) TR corner arc (centre at (rt-r, tp+r), from -90° to 0°)
    if (d <= arc) {
      final a = -math.pi / 2 + (d / arc) * (math.pi / 2);
      return Offset(rt - r + r * math.cos(a), tp + r + r * math.sin(a));
    }
    d -= arc;
    // 3) right side straight (down)
    if (d <= straightV) {
      return Offset(rt, tp + r + d);
    }
    d -= straightV;
    // 4) BR corner arc (centre (rt-r, bt-r), 0° to 90°)
    if (d <= arc) {
      final a = (d / arc) * (math.pi / 2);
      return Offset(rt - r + r * math.cos(a), bt - r + r * math.sin(a));
    }
    d -= arc;
    // 5) bottom straight (left)
    if (d <= straightH) {
      return Offset(rt - r - d, bt);
    }
    d -= straightH;
    // 6) BL corner arc (centre (l+r, bt-r), 90° to 180°)
    if (d <= arc) {
      final a = math.pi / 2 + (d / arc) * (math.pi / 2);
      return Offset(l + r + r * math.cos(a), bt - r + r * math.sin(a));
    }
    d -= arc;
    // 7) left side straight (up)
    if (d <= straightV) {
      return Offset(l, bt - r - d);
    }
    d -= straightV;
    // 8) TL corner arc (centre (l+r, tp+r), 180° to 270°)
    if (d <= arc) {
      final a = math.pi + (d / arc) * (math.pi / 2);
      return Offset(l + r + r * math.cos(a), tp + r + r * math.sin(a));
    }
    d -= arc;
    // 9) top-left straight → back to top-centre
    return Offset(l + r + d, tp);
  }

  // ── The PRESSURE CONSOLE + glowing PISTON (P0.3 / P1.4 / P1.5) ────────
  void _paintConsole(Canvas canvas) {
    final reveal = c.sourceReveal.clamp(0.0, 1.0);
    if (reveal <= 0.01) return;
    final v = c.voltage.clamp(0.0, 1.0);
    final rect = c.consoleRect;
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(rect.height * 0.20));

    // entrance: console rises up + powers on
    canvas.save();
    canvas.translate(0, (1 - reveal) * rect.height * 0.5);

    // Charge glow (P1.4): the console "strains" as voltage climbs — a cool aura
    // around the housing intensifies with v.
    if (v > 0.02) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(rect.height * 0.10), Radius.circular(rect.height * 0.3)),
        Paint()
          ..blendMode = BlendMode.plus
          ..color = VCTune.controlCool.withValues(alpha: 0.16 * v * reveal)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, rect.height * 0.22),
      );
    }

    // Glass housing.
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF18213F).withValues(alpha: 0.96 * reveal),
            const Color(0xFF0C1330).withValues(alpha: 0.96 * reveal),
          ],
        ).createShader(rect),
    );
    // top inner highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.42),
        Radius.circular(rect.height * 0.20),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.05 * reveal),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = VCTune.controlCool.withValues(alpha: (0.30 + 0.25 * v) * reveal),
    );

    // ── The vertical TRACK (where the piston travels) ──────────────────
    final track = c.trackRect;
    final trackRR = RRect.fromRectAndRadius(track, Radius.circular(track.width * 0.42));
    canvas.drawRRect(
      trackRR,
      Paint()..color = const Color(0xFF0A1124).withValues(alpha: 0.92 * reveal),
    );

    // pressure column BELOW the head — brighter near the head (P0.3).
    final headY = c.pistonHeadY;
    if (v > 0.001) {
      canvas.save();
      canvas.clipRRect(trackRR);
      final fillRect = Rect.fromLTRB(track.left, headY, track.right, track.bottom);
      canvas.drawRect(
        fillRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              const Color(0xFF205F92).withValues(alpha: 0.95 * reveal),
              VCTune.controlCool.withValues(alpha: 0.98 * reveal),
            ],
          ).createShader(fillRect),
      );
      // a brighter additive cap right under the head
      canvas.drawRect(
        Rect.fromLTRB(track.left, headY, track.right, headY + track.width * 0.9),
        Paint()
          ..blendMode = BlendMode.plus
          ..color = VCTune.controlCoolLite.withValues(alpha: 0.45 * reveal)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, track.width * 0.35),
      );
      canvas.restore();
    }

    // ── Scale ticks (P1.5) — synced to the 0.1 detent haptics ──────────
    // A tick every 10 units; the one nearest the head highlights.
    final tickPaint = Paint()..strokeCap = StrokeCap.round;
    final headDetent = (v / VCTune.detentStep).round();
    for (var k = 0; k <= 10; k++) {
      final ty = track.bottom - track.height * (k / 10.0);
      final near = k == headDetent;
      final tw = track.width * (near ? 0.95 : 0.62);
      tickPaint
        ..strokeWidth = near ? 2.4 : 1.4
        ..color = (near ? VCTune.controlCoolLite : VCTune.controlCool)
            .withValues(alpha: (near ? 0.85 : 0.30) * reveal);
      canvas.drawLine(
        Offset(track.right + track.width * 0.18, ty),
        Offset(track.right + track.width * 0.18 + tw, ty),
        tickPaint,
      );
    }

    // ── The dimensional PISTON HEAD — the thing the finger pushes ──────
    _paintPistonHead(canvas, reveal, v);

    // Premium "push up" affordance at rest — soft chevrons rising + fading
    // above the head (replaces the flat outlined triangle).
    if (v < 0.05) _paintGrabHint(canvas, reveal);

    canvas.restore();
  }

  // ── The grab hint — two glowing chevrons that rise and fade above the head,
  //    inviting the push. Premium, animated; only shown at rest (v < 0.05).
  void _paintGrabHint(Canvas canvas, double reveal) {
    final cx = c.consoleCenter.dx;
    final headTop = c.pistonHeadRect.top;
    final unit = c.lampRadius;
    final s = unit * 0.17; // chevron half-width
    final base = c.reducedMotion ? 0.35 : (c.ambientPhase * 0.85) % 1.0;
    for (var i = 0; i < 2; i++) {
      final rise = (base + i * 0.5) % 1.0; // 0 (at head) → 1 (risen + faded)
      final cy = headTop - unit * 0.15 - rise * unit * 0.32;
      final a = (1.0 - rise) * 0.9 * reveal;
      if (a <= 0.03) continue;
      final path = Path()
        ..moveTo(cx - s, cy + s * 0.55)
        ..lineTo(cx, cy - s * 0.50)
        ..lineTo(cx + s, cy + s * 0.55);
      // soft glow pass + crisp core
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..blendMode = BlendMode.plus
          ..color = VCTune.controlCool.withValues(alpha: 0.45 * a)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..blendMode = BlendMode.plus
          ..color = VCTune.controlCoolLite.withValues(alpha: a),
      );
    }
  }

  void _paintPistonHead(Canvas canvas, double reveal, double v) {
    final headBase = c.pistonHeadRect;
    // strain shimmer at very high V (P1.4) — a tiny, premium vibration, not jitter.
    var off = Offset.zero;
    if (v > 0.85 && !c.reducedMotion) {
      final amp = (v - 0.85) / 0.15 * (headBase.height * 0.05);
      off = Offset(math.sin(c.ambientPhase * 38) * amp, math.cos(c.ambientPhase * 34) * amp * 0.5);
    }
    final rect = headBase.shift(off);
    final radius = Radius.circular(rect.height * 0.5); // full pill
    final rr = RRect.fromRectAndRadius(rect, radius);

    // 1) soft cool glow beneath — the live grab point (intensifies with v).
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(rect.height * 0.42), Radius.circular(rect.height)),
      Paint()
        ..blendMode = BlendMode.plus
        ..color = VCTune.controlCool.withValues(alpha: (0.20 + 0.34 * v) * reveal)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rect.height * 0.6),
    );
    // 2) drop shadow for depth — the knob sits proud of the track.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.shift(Offset(0, rect.height * 0.16)), radius),
      Paint()
        ..color = const Color(0xFF03060F).withValues(alpha: 0.55 * reveal)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rect.height * 0.24),
    );

    // 3) glossy glass body — light top → cool mid → deep base (real material).
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFDCF1FF).withValues(alpha: 0.99 * reveal),
            const Color(0xFF74C4F4).withValues(alpha: 0.99 * reveal),
            const Color(0xFF2E78B6).withValues(alpha: 0.99 * reveal),
            const Color(0xFF1B4A73).withValues(alpha: 0.99 * reveal),
          ],
          stops: const [0.0, 0.34, 0.74, 1.0],
        ).createShader(rect),
    );

    // 4) crisp top specular highlight — a bright thin glass band that sells gloss.
    final specRect = Rect.fromLTWH(rect.left + rect.width * 0.07, rect.top + rect.height * 0.12,
        rect.width * 0.86, rect.height * 0.30);
    canvas.drawRRect(
      RRect.fromRectAndRadius(specRect, Radius.circular(specRect.height * 0.6)),
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0.6 * reveal), Colors.white.withValues(alpha: 0.0)],
        ).createShader(specRect),
    );

    // 5) rim — brighter at the top, deeper at the base (rounds the form).
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            VCTune.controlCoolLite.withValues(alpha: 0.95 * reveal),
            const Color(0xFF14375A).withValues(alpha: 0.7 * reveal),
          ],
        ).createShader(rect),
    );

    // 6) the VOLTAGE number — clean and centred, on a clear glossy face. A soft
    //    dark wash directly behind the value keeps it legible over the gloss.
    final unit = c.lampRadius;
    final labelTp = _textPainter('${VCCopy.voltageLabel} ', const Color(0xFF0A2740),
        unit * 0.20, letterSpacing: 1.6, weight: FontWeight.w700);
    final valTp = _textPainter('${c.rollVoltage}', Colors.white, unit * 0.34, weight: FontWeight.w800);
    final totalW = labelTp.width + valTp.width;
    final lx = rect.center.dx - totalW / 2;
    labelTp.paint(canvas, Offset(lx, rect.center.dy - labelTp.height / 2));
    // a faint glow behind the value digits so they pop on the bright knob.
    canvas.drawCircle(
      Offset(lx + labelTp.width + valTp.width / 2, rect.center.dy),
      valTp.height * 0.5,
      Paint()
        ..color = const Color(0xFF0A2740).withValues(alpha: 0.22 * reveal)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, valTp.height * 0.4),
    );
    valTp.paint(canvas, Offset(lx + labelTp.width, rect.center.dy - valTp.height / 2));
  }

  // ── The volumetric lamp BLOOM (P0.1, ported from _paintDeviceBloom) ──
  // Radial additive bloom; radius scales with brightness, modulated by the breath.
  // Gated on brightness which is HARD-ZEROED at cutoff — bloom snaps to nothing
  // the instant the lamp dies. Breath only modulates a LIT lamp (b>0), so the
  // hard zero is preserved.
  void _paintLampBloom(Canvas canvas) {
    final b = c.lampBrightness.clamp(0.0, 1.0);
    if (b <= 0.01) return;
    final ctr = c.lampCenter;
    final r = c.lampRadius;
    final breath = c.lampBreath;
    final radius = r * (1.7 + 2.6 * b) * breath;
    // outer soft bloom
    canvas.drawCircle(
      ctr,
      radius,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [VCTune.lampWarm.withValues(alpha: 0.5 * b), VCTune.lampWarm.withValues(alpha: 0)],
          stops: const [0, 1],
        ).createShader(Rect.fromCircle(center: ctr, radius: radius)),
    );
    // tighter inner core bloom (hotter)
    canvas.drawCircle(
      ctr,
      r * (0.9 + 0.9 * b),
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF6E0).withValues(alpha: 0.42 * b),
            VCTune.lampWarm.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: ctr, radius: r * (0.9 + 0.9 * b))),
    );
  }

  // ── God-rays from the lit lamp (P0.1, ported from _paintLightRays) ───
  // ~16 rays, per-ray shimmer, length ∝ brightness × breath, BlendMode.plus.
  void _paintLightRays(Canvas canvas) {
    final b = c.lampBrightness.clamp(0.0, 1.0);
    if (b <= 0.05) return;
    final center = c.lampCenter;
    final breath = c.lampBreath;
    final rays = VCTune.lampRayCount;
    final maxLen = c.lampRadius * (VCTune.lampRayLenFactor + VCTune.lampRayLenGain * b) * breath;
    final spin = c.reducedMotion ? 0.0 : c.ambientPhase * 0.5;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(spin * 0.7);
    for (var i = 0; i < rays; i++) {
      final a = i / rays * 2 * math.pi;
      // per-ray shimmer so it twinkles like a star, not a fixed sunburst.
      final len = maxLen * (0.55 + 0.45 * (0.5 + 0.5 * math.sin(i * 1.7 + spin * 3)));
      final tip = Offset(math.cos(a), math.sin(a)) * len;
      canvas.drawLine(
        Offset.zero,
        tip,
        Paint()
          ..blendMode = BlendMode.plus
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round
          ..shader = ui.Gradient.linear(
            Offset.zero,
            tip,
            [VCTune.lampWarm.withValues(alpha: 0.5 * b), VCTune.lampWarm.withValues(alpha: 0)],
          ),
      );
    }
    canvas.restore();
  }

  // ── The lamp — the imported shared bulb (bigger, P0.1) ───────────────
  void _paintLamp(Canvas canvas) {
    final ctr = c.lampCenter;
    final r = c.lampRadius;
    final b = c.lampBrightness.clamp(0.0, 1.0);
    final reveal = c.loopReveal.clamp(0.0, 1.0);
    canvas.save();
    canvas.translate(0, (1 - reveal) * -r * 0.3);
    paintBulb(canvas, ctr, r, b); // reused AS-IS (PRD §10 continuity)
    canvas.restore();
  }

  // ── The CURRENT gauge — instrument-grade (P2.9), under the lamp ──────
  // Exactly TWO live numbers total: VOLTAGE (on the piston head) + CURRENT (here).
  // Value-linked glow, a thin accent arc, smoothed rolling digits on the way UP,
  // and a HARD-ZERO the same frame at cutoff (rollCurrent is gated to 0).
  void _paintCurrentGauge(Canvas canvas) {
    final reveal = c.loopReveal.clamp(0.0, 1.0);
    if (reveal <= 0.01) return;
    final center = c.currentChipCenter;
    final unit = c.lampRadius;
    final value = c.rollCurrent;
    // intensity ∝ current (drives the gauge's own glow — but recedes vs the lamp).
    final intensity = (c.current / VCTune.kCurrentRatio).clamp(0.0, 1.0);
    final accent = VCTune.moteWarm;

    final labelTp = _textPainter(VCCopy.currentLabel, VCTune.chipText.withValues(alpha: 0.62),
        unit * 0.2, letterSpacing: 1.6, weight: FontWeight.w600);
    final valueTp = _textPainter('$value', accent, unit * 0.46, weight: FontWeight.w800);
    final padX = unit * 0.34;
    final padY = unit * 0.16;
    final innerGap = unit * 0.10;
    final chipW = math.max(labelTp.width, valueTp.width) + padX * 2 + unit * 0.2;
    final chipH = labelTp.height + innerGap + valueTp.height + padY * 2 + unit * 0.12;
    final rect = Rect.fromCenter(center: center, width: chipW, height: chipH);
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(unit * 0.2));

    // value-linked glow (recedes vs the warm hero — capped low).
    if (intensity > 0.01) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(unit * 0.12), Radius.circular(unit * 0.32)),
        Paint()
          ..blendMode = BlendMode.plus
          ..color = accent.withValues(alpha: 0.14 * intensity * reveal)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.2),
      );
    }
    canvas.drawRRect(rr, Paint()..color = VCTune.chipGlass.withValues(alpha: 0.9 * reveal));
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = accent.withValues(alpha: (0.24 + 0.2 * intensity) * reveal),
    );

    // label (top), value (bottom) — clearer hierarchy.
    labelTp.paint(canvas, Offset(center.dx - labelTp.width / 2, rect.top + padY));
    final valueY = rect.top + padY + labelTp.height + innerGap;
    valueTp.paint(canvas, Offset(center.dx - valueTp.width / 2, valueY));

    // a thin accent bar under the value, length ∝ current (the instrument needle).
    final barW = chipW - padX * 2;
    final barY = valueY + valueTp.height + unit * 0.07;
    final barL = rect.center.dx - barW / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barL, barY, barW, unit * 0.045), Radius.circular(unit * 0.03)),
      Paint()..color = accent.withValues(alpha: 0.16 * reveal),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barL, barY, barW * intensity, unit * 0.045), Radius.circular(unit * 0.03)),
      Paint()
        ..blendMode = BlendMode.plus
        ..color = accent.withValues(alpha: 0.85 * reveal),
    );
  }

  // ── Cutoff after-punctuation: dark shockwave + scatter (P1.6) ────────
  // These are NOT the death (the lamp/motes/numbers already hit 0 that frame) —
  // they are the punctuation. The shockwave is a dark ring expanding from the now-
  // dead lamp; the scatter is the river's motes flying outward + fading.
  void _paintShockwave(Canvas canvas) {
    final s = c.shockwave;
    if (s <= 0.001) return;
    final ctr = c.lampCenter;
    final r = c.lampRadius;
    final ringR = r * (0.8 + 4.0 * (1 - s)); // expands as it fades
    canvas.drawCircle(
      ctr,
      ringR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.5 * s
        ..color = const Color(0xFF040610).withValues(alpha: 0.55 * s)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.4),
    );
  }

  void _paintScatter(Canvas canvas) {
    final ps = c.scatterParticles;
    if (ps.isEmpty) return;
    final p = Paint()..blendMode = BlendMode.plus;
    for (final s in ps) {
      final a = s.t * s.t; // fade fast
      p.color = VCTune.moteWarm.withValues(alpha: 0.5 * a);
      p.maskFilter = MaskFilter.blur(BlurStyle.normal, s.size * 1.4);
      canvas.drawCircle(s.pos, s.size * 1.6, p);
      p.maskFilter = null;
      p.color = VCTune.moteHot.withValues(alpha: 0.85 * a);
      canvas.drawCircle(s.pos, s.size * 0.7, p);
    }
  }

  // ── The cutoff discovery flash (a quick cool ring + dim, ~0.7 s) ─────
  void _paintFlash(Canvas canvas, Size size) {
    final f = c.flashIntensity;
    if (f <= 0.001) return;
    // a soft cool ring expanding from the (now dark) lamp — the "it died" beat.
    final ctr = c.lampCenter;
    final rr = c.lampRadius * (1.4 + 2.4 * (1 - f));
    canvas.drawCircle(
      ctr,
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = c.lampRadius * 0.18 * f
        ..blendMode = BlendMode.plus
        ..color = const Color(0xFF8FB8FF).withValues(alpha: 0.5 * f)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, c.lampRadius * 0.3),
    );
  }

  TextPainter _textPainter(String text, Color color, double size,
      {double letterSpacing = 0, FontWeight weight = FontWeight.w500}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.ibmPlexMono(
          fontSize: size,
          color: color,
          fontWeight: weight,
          letterSpacing: letterSpacing,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    tp.layout();
    return tp;
  }

  @override
  bool shouldRepaint(VCStagePainter old) => false; // repaint driven by controller
}
