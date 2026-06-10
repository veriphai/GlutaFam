// The parametric creature — the hero primitive (PRD §4, criterion 5: rendered
// entirely from a [Genome] with NO sprite/art assets). One CustomPainter draws a
// volumetric, alive head+body critter across all four render modes
// (live/wireframe/photo/broken) + the extinction dissolve + the rebuild splash,
// reading everything from the controller's getters (repaint: controller).
//
// The four genes map to four unmistakable, INDEPENDENT responses (criterion 1):
//   size    → overall scale of the whole creature
//   limbs   → leg length (the critter lifts onto longer legs)
//   colour  → body + head hue
//   pattern → number of spots
//
// Premium treatment (Tier 1): radial body shading + rim-light + specular,
// a soft contact shadow on a faint platform, a pulsing life-aura, ears + snout +
// glossy eyes (blink + idle look-around), and an idle-wagging tail.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../config/creature_tuning.dart';
import '../config/genome.dart';
import '../state/recipe_creature_controller.dart';

class CreaturePainter extends CustomPainter {
  CreaturePainter(this.c) : super(repaint: c);

  final RecipeCreatureController c;

  // Fixed spot anchors inside the body/head (normalised to the body radii).
  // pattern density just reveals the first N, so spots fade in/out, never jump.
  static const List<Offset> _spots = [
    Offset(-0.40, 0.05), Offset(0.34, -0.05), Offset(0.02, 0.34),
    Offset(-0.18, -0.30), Offset(0.46, 0.28), Offset(-0.52, 0.34),
    Offset(0.24, 0.52), Offset(-0.04, 0.60), Offset(0.52, -0.22),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final g = c.displayGenome;
    final mode = c.renderMode;
    final phase = c.phase.value;
    final u = size.shortestSide;
    final center = Offset(size.width / 2, size.height * 0.5);

    if (!c.creatureVisible) {
      if (phase == RCPhase.selecting && c.snapshotForGhost != null) {
        _drawGhost(canvas, center, u, c.snapshotForGhost!);
      }
      return;
    }

    // ── Global envelope (alpha · scale · y-offset · saturation · sway) ───────
    double alpha = 1, scale = 1, dy = 0, satMul = 1, sway = 0;
    final flash = c.traitFlash;

    if (phase == RCPhase.extinction) {
      final t = c.extinctionProgress;
      alpha = (1 - t).clamp(0.0, 1.0);
      dy = -u * 0.14 * t;
      satMul = 1 - 0.85 * t;
      scale = 1 - 0.06 * t;
    } else if (mode == CreatureRenderMode.live && c.rebuildProgress < 1) {
      final t = c.rebuildProgress;
      alpha = Curves.easeOut.transform(t);
      scale = 0.32 + 0.68 * _easeOutBack(t);
      satMul = 0.18 + 0.82 * t;
    } else if (mode != CreatureRenderMode.live) {
      alpha = Curves.easeOut.transform(c.assembleProgress);
    }

    // size gene → overall scale (composes with the envelope scale).
    scale *= 0.62 + 0.5 * g.size;

    // Idle life (live + settled + motion on).
    final settledLive = mode == CreatureRenderMode.live && c.liveMotion && c.rebuildProgress >= 1;
    double breath = 0, wag = 0, look = 0, blink = 1;
    if (settledLive) {
      breath = math.sin(c.clock * 2 * math.pi * RC.breathHz);
      scale *= 1 + 0.025 * breath;
      dy += breath * u * 0.006;
      sway = math.sin(c.clock * 0.9) * 0.035; // gentle ±2°
      wag = math.sin(c.clock * 2.4); // tail wag
      look = math.sin(c.clock * 0.7) * 0.5; // pupils drift
      if (math.sin(c.clock * 1.7) > 0.985) blink = 0.12; // occasional blink
    }
    scale *= 1 + 0.05 * flash;

    final p = _Pal(g.hue, mode, alpha, satMul);

    final rebuilding = mode == CreatureRenderMode.live && c.rebuildProgress < 1;
    final dissolving = phase == RCPhase.extinction && c.liveMotion;

    canvas.save();
    canvas.translate(center.dx, center.dy + dy);
    canvas.scale(scale);

    // Aura + contact shadow live in the unrotated space.
    if (mode == CreatureRenderMode.live) _drawAura(canvas, u, p, flash);
    _drawShadow(canvas, u, g, mode, alpha);

    // Rebuild: a coiled strand descends + particles converge BEHIND the forming
    // creature (the genome pouring back into a body).
    if (rebuilding && c.liveMotion) _drawConverge(canvas, u, g, c.rebuildProgress);

    canvas.save();
    canvas.rotate(sway);
    _drawCreature(canvas, u, g, mode, p, wag, look, blink);
    canvas.restore();

    // Extinction: the creature scatters into rising particles + floating code.
    if (dissolving) _drawDissolve(canvas, u, g, c.extinctionProgress);

    // Rebuild "born" flash + shockwave near the end of the splash.
    if (rebuilding && c.rebuildProgress > 0.5) {
      final rt = ((c.rebuildProgress - 0.5) / 0.5).clamp(0.0, 1.0);
      canvas.drawCircle(Offset(0, -u * 0.02), u * (0.16 + 0.55 * rt),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5 * (1 - rt)
            ..color = RC.lifeGreen.withValues(alpha: 0.65 * (1 - rt)));
      if (rt < 0.4) {
        canvas.drawCircle(Offset(0, -u * 0.02), u * 0.34,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.5 * (1 - rt / 0.4))
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
      }
    }

    // Trait-change ripple — a quick outward ring on each gene move.
    if (flash > 0.02 && mode == CreatureRenderMode.live) {
      canvas.drawCircle(Offset(0, -u * 0.02), u * (0.20 + 0.24 * (1 - flash)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5 * flash
            ..color = p.light.withValues(alpha: 0.45 * flash));
    }
    canvas.restore();
  }

  // Points around the body + head silhouette (local coords) — emit/target sites.
  List<Offset> _silhouette(double u) {
    final bodyC = Offset(0, u * 0.085), headC = Offset(0, -u * 0.085);
    const bRX = 0.155, bRY = 0.140, hRX = 0.140, hRY = 0.128;
    final pts = <Offset>[];
    for (var i = 0; i < 16; i++) {
      final a = i / 16 * 2 * math.pi;
      pts.add(Offset(bodyC.dx + math.cos(a) * bRX * u, bodyC.dy + math.sin(a) * bRY * u));
    }
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * 2 * math.pi;
      pts.add(Offset(headC.dx + math.cos(a) * hRX * u, headC.dy + math.sin(a) * hRY * u));
    }
    return pts;
  }

  // ── Anatomy ────────────────────────────────────────────────────────────────
  void _drawCreature(Canvas canvas, double u, Genome g, CreatureRenderMode mode, _Pal p,
      double wag, double look, double blink) {
    final isWire = mode == CreatureRenderMode.wireframe;
    final isBroken = mode == CreatureRenderMode.broken;

    final bodyC = Offset(0, u * 0.085);
    final bodyRX = u * 0.155, bodyRY = u * 0.140;
    final headC = Offset(0, -u * 0.085);
    final headRX = u * 0.140, headRY = u * 0.128;
    final legLen = u * (0.015 + 0.16 * g.limbLength);
    final legTopY = bodyC.dy + bodyRY * 0.66;

    // Broken = "half a creature": clip away the right portion (ragged cut).
    final cutX = bodyRX * 0.12;
    if (isBroken) {
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(-u, -u, cutX, u));
    }

    // 1) Tail (behind the body), wagging on idle.
    _drawTail(canvas, bodyC, bodyRX, bodyRY, u, p, isWire, wag);

    // 2) Legs (behind the body) — length from the limbs gene.
    _drawLegs(canvas, bodyC, bodyRX, legTopY, legLen, u, p, isWire);

    // 3) Ears (behind the head).
    _drawEars(canvas, headC, headRX, headRY, p, isWire);

    // 4) Body + head (volumetric).
    _drawBlob(canvas, Rect.fromCenter(center: bodyC, width: bodyRX * 2, height: bodyRY * 2), p, isWire);
    _drawBlob(canvas, Rect.fromCenter(center: headC, width: headRX * 2, height: headRY * 2), p, isWire);

    // 5) Pattern spots (on body + head).
    if (!isWire) {
      final n = (g.patternDensity * _spots.length).round().clamp(0, _spots.length);
      final spot = Paint()..color = p.spot;
      for (var i = 0; i < n; i++) {
        final s = _spots[i];
        // alternate spots between body and head for spread.
        final on = i.isEven ? bodyC : headC;
        final rr = i.isEven ? Offset(bodyRX, bodyRY) : Offset(headRX, headRY);
        canvas.drawCircle(Offset(on.dx + s.dx * rr.dx, on.dy + s.dy * rr.dy), bodyRX * 0.11, spot);
      }
    }

    // 6) Face — snout + eyes (glossy, blink, look) + mouth.
    _drawFace(canvas, headC, headRX, headRY, mode, p, look, blink);

    if (isBroken) {
      canvas.restore();
      _drawRaggedEdge(canvas, cutX, headC.dy - headRY, bodyC.dy + bodyRY, bodyRX, p.alpha);
    }
  }

  // A volumetric oval: radial gradient body + rim light + specular + outline.
  void _drawBlob(Canvas canvas, Rect r, _Pal p, bool isWire) {
    if (isWire) {
      canvas.drawOval(r, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = p.wire);
      return;
    }
    // Body fill — radial gradient (highlight top-left → base → shade bottom).
    final fill = Paint()
      ..shader = ui.Gradient.radial(
        Offset(r.center.dx - r.width * 0.22, r.center.dy - r.height * 0.28),
        r.longestSide * 0.62,
        [p.light, p.base, p.dark],
        [0.0, 0.55, 1.0],
      );
    canvas.drawOval(r, fill);
    if (!p.flat) {
      // Specular highlight (soft).
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(r.center.dx - r.width * 0.20, r.center.dy - r.height * 0.26),
          width: r.width * 0.42,
          height: r.height * 0.34,
        ),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.16 * p.alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // Rim light — a bright arc on the lower-right edge.
      canvas.drawArc(
        r.deflate(1.2),
        math.pi * 0.05,
        math.pi * 0.6,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..color = p.light.withValues(alpha: 0.5 * p.alpha),
      );
    }
    // Outline for definition.
    canvas.drawOval(r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = p.outline);
  }

  void _drawEars(Canvas canvas, Offset headC, double headRX, double headRY, _Pal p, bool isWire) {
    for (final sign in [-1.0, 1.0]) {
      final base = Offset(headC.dx + sign * headRX * 0.56, headC.dy - headRY * 0.74);
      final tip = Offset(headC.dx + sign * headRX * 0.78, headC.dy - headRY * 1.34);
      final path = Path()
        ..moveTo(base.dx - sign * headRX * 0.22, base.dy)
        ..quadraticBezierTo(tip.dx - sign * headRX * 0.16, (base.dy + tip.dy) / 2, tip.dx, tip.dy)
        ..quadraticBezierTo(base.dx + sign * headRX * 0.20, (base.dy + tip.dy) / 2, base.dx + sign * headRX * 0.18, base.dy)
        ..close();
      if (isWire) {
        canvas.drawPath(path, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = p.wire);
      } else {
        canvas.drawPath(path, Paint()..color = p.dark);
        // inner ear.
        canvas.drawPath(path, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = p.outline);
      }
    }
  }

  void _drawLegs(Canvas canvas, Offset bodyC, double bodyRX, double legTopY, double legLen, double u, _Pal p, bool isWire) {
    final xs = [-0.62, -0.24, 0.24, 0.62];
    final legPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = bodyRX * 0.34
      ..color = isWire ? p.wire : p.dark;
    for (final fx in xs) {
      final topx = bodyC.dx + fx * bodyRX;
      final splay = fx.sign * legLen * 0.18;
      final foot = Offset(topx + splay, legTopY + legLen);
      canvas.drawLine(Offset(topx, legTopY), foot, legPaint);
      if (!isWire) canvas.drawCircle(foot, bodyRX * 0.18, Paint()..color = p.dark); // paw
    }
  }

  void _drawTail(Canvas canvas, Offset bodyC, double bodyRX, double bodyRY, double u, _Pal p, bool isWire, double wag) {
    final root = Offset(bodyC.dx + bodyRX * 0.9, bodyC.dy + bodyRY * 0.05);
    final mid = Offset(root.dx + bodyRX * 0.5, bodyC.dy - bodyRY * (0.4 + 0.12 * wag));
    final tip = Offset(root.dx + bodyRX * (0.75 + 0.1 * wag), bodyC.dy - bodyRY * (1.0 + 0.18 * wag));
    final path = Path()
      ..moveTo(root.dx, root.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, tip.dx, tip.dy);
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = bodyRX * 0.30
      ..color = isWire ? p.wire : p.dark);
    if (!isWire) canvas.drawCircle(tip, bodyRX * 0.13, Paint()..color = p.base); // soft tail tip
  }

  void _drawFace(Canvas canvas, Offset headC, double headRX, double headRY, CreatureRenderMode mode,
      _Pal p, double look, double blink) {
    final isWire = mode == CreatureRenderMode.wireframe;
    final isPhoto = mode == CreatureRenderMode.photo;
    final isBroken = mode == CreatureRenderMode.broken;
    final eyeY = headC.dy - headRY * 0.06;
    final eyeDX = headRX * 0.40;
    final eyeR = headRX * 0.27;

    void eye(double cx) {
      if (isWire) {
        canvas.drawCircle(Offset(cx, eyeY), eyeR, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = p.wire);
        return;
      }
      // white sclera (blinks).
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, eyeY), width: eyeR * 2, height: eyeR * 2 * blink),
        Paint()..color = Colors.white.withValues(alpha: (isPhoto ? 0.72 : 0.97) * p.alpha),
      );
      if (blink > 0.5) {
        final pupil = Offset(cx + look * eyeR * 0.3, eyeY + eyeR * 0.08);
        canvas.drawCircle(pupil, eyeR * 0.52, Paint()..color = const Color(0xFF14203A).withValues(alpha: p.alpha));
        if (!isPhoto) {
          canvas.drawCircle(Offset(pupil.dx - eyeR * 0.18, pupil.dy - eyeR * 0.2), eyeR * 0.18,
              Paint()..color = Colors.white.withValues(alpha: 0.95 * p.alpha));
        }
      }
    }

    eye(headC.dx - eyeDX);
    if (!isBroken) eye(headC.dx + eyeDX);

    // Snout/nose.
    if (!isWire) {
      final nose = Offset(headC.dx, headC.dy + headRY * 0.30);
      canvas.drawOval(
        Rect.fromCenter(center: nose, width: headRX * 0.30, height: headRX * 0.22),
        Paint()..color = p.outline,
      );
    }

    // Mouth.
    final mouth = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = isWire ? p.wire : p.outline.withValues(alpha: p.alpha);
    final my = headC.dy + headRY * 0.52;
    if (isBroken) {
      canvas.drawLine(Offset(headC.dx - headRX * 0.18, my), Offset(headC.dx + headRX * 0.02, my), mouth);
    } else if (!isWire) {
      final smile = isPhoto ? 0.0 : 1.0;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(headC.dx, my - headRX * 0.08 * smile), width: headRX * 0.6, height: headRX * 0.46),
        0.12 * math.pi, 0.76 * math.pi, false, mouth,
      );
    }
  }

  // ── Atmosphere ───────────────────────────────────────────────────────────
  void _drawAura(Canvas canvas, double u, _Pal p, double flash) {
    final pulse = 0.5 + 0.5 * math.sin(c.clock * 1.3);
    canvas.drawCircle(
      Offset(0, -u * 0.02),
      u * (0.30 + 0.02 * pulse),
      Paint()
        ..color = HSVColor.fromAHSV((0.18 + 0.06 * pulse + 0.18 * flash) * p.alpha, p.hue, 0.7, 1).toColor()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
    );
  }

  void _drawShadow(Canvas canvas, double u, Genome g, CreatureRenderMode mode, double alpha) {
    if (mode == CreatureRenderMode.wireframe) return;
    final legLen = u * (0.015 + 0.16 * g.limbLength);
    final footY = u * 0.085 + u * 0.140 * 0.66 + legLen + u * 0.02;
    // soft platform glow.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, footY), width: u * 0.5, height: u * 0.09),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.32 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  // ── Broken / extinction / ghost helpers ───────────────────────────────────
  void _drawRaggedEdge(Canvas canvas, double cutX, double top, double bottom, double bodyRX, double alpha) {
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE2557A).withValues(alpha: 0.85 * alpha);
    final path = Path()..moveTo(cutX, top);
    final span = bottom - top;
    for (var i = 1; i <= 9; i++) {
      final t = i / 9;
      final jitter = (i.isEven ? 1 : -1) * bodyRX * 0.08;
      path.lineTo(cutX + jitter, top + span * t);
    }
    canvas.drawPath(path, edge);
  }

  void _drawGhost(Canvas canvas, Offset center, double u, Genome g) {
    final s = 0.62 + 0.5 * g.size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Colors.white.withValues(alpha: 0.12);
    final body = Rect.fromCenter(center: center + Offset(0, u * 0.085 * s), width: u * 0.31 * s, height: u * 0.28 * s);
    final head = Rect.fromCenter(center: center + Offset(0, -u * 0.085 * s), width: u * 0.28 * s, height: u * 0.256 * s);
    _drawDashed(canvas, Path()..addOval(body), paint, 26);
    _drawDashed(canvas, Path()..addOval(head), paint, 24);
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint, int segs) {
    for (final m in path.computeMetrics()) {
      final dash = m.length / segs;
      var d = 0.0, draw = true;
      while (d < m.length) {
        final next = math.min(d + dash * 0.6, m.length);
        if (draw) canvas.drawPath(m.extractPath(d, next), paint);
        d += dash * (draw ? 0.6 : 0.4);
        draw = !draw;
      }
    }
  }

  // Extinction: the creature scatters into rising particles that fade, with a
  // few A/T/C/G letters floating up (it dissolves back into its instructions).
  void _drawDissolve(Canvas canvas, double u, Genome g, double t) {
    final pts = _silhouette(u);
    final prog = Curves.easeOut.transform(t);
    for (var i = 0; i < pts.length; i++) {
      final swirl = (i % 7) / 7.0;
      final lift = Offset(
        (i.isEven ? 1 : -1) * u * 0.14 * swirl * prog,
        -u * (0.10 + 0.34 * swirl) * prog,
      );
      final pos = pts[i] + lift;
      final a = (1 - t).clamp(0.0, 1.0) * 0.85;
      final col = HSVColor.fromAHSV(a, g.hue % 360, 0.5, 1).toColor();
      canvas.drawCircle(pos, u * 0.013 * (1 - t * 0.6),
          Paint()..color = col..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6));
    }
    // Floating code — a handful of A/T/C/G glyphs drifting up + fading.
    if (t > 0.12) {
      const letters = ['A', 'T', 'C', 'G', 'A', 'T'];
      for (var i = 0; i < letters.length; i++) {
        final fx = (i - 2.5) / 2.5;
        final p = Offset(fx * u * 0.18, -u * (0.14 + 0.5 * t) - i * u * 0.02);
        _glyph(canvas, letters[i], p, u * 0.05,
            HSVColor.fromAHSV((1 - t).clamp(0.0, 1.0) * 0.8, g.hue % 360, 0.35, 1).toColor());
      }
    }
  }

  // Rebuild: a coiled strand descends and particles converge onto the silhouette
  // — the genome pouring back into a living body.
  void _drawConverge(Canvas canvas, double u, Genome g, double t) {
    // Descending double-helix above, pouring in (early).
    if (t < 0.5) {
      final fall = Curves.easeIn.transform((t / 0.5).clamp(0.0, 1.0));
      final cx = 0.0, top = -u * (0.55 - 0.45 * fall);
      final a = (1 - fall) * 0.9;
      final strand = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = RC.lifeGreen.withValues(alpha: a);
      for (final dir in [1.0, -1.0]) {
        final path = Path();
        for (var i = 0; i <= 16; i++) {
          final f = i / 16;
          final y = top + f * u * 0.3;
          final x = cx + dir * math.sin(f * 2.6 * math.pi) * u * 0.05;
          i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        }
        canvas.drawPath(path, strand);
      }
    }
    // Converging particles (spread → silhouette), fading in then out on arrival.
    final cp = Curves.easeOut.transform((t / 0.72).clamp(0.0, 1.0));
    final pts = _silhouette(u);
    for (var i = 0; i < pts.length; i++) {
      final target = pts[i];
      final dir = Offset(math.cos(i * 2.39), math.sin(i * 2.39));
      final start = target + dir * u * 0.42;
      final pos = Offset.lerp(start, target, cp)!;
      final a = (cp < 1 ? (1 - (cp - 0.5).abs() * 2) : 0).clamp(0.0, 1.0) * 0.7;
      canvas.drawCircle(pos, u * 0.012,
          Paint()..color = RC.lifeGreen.withValues(alpha: a)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6));
    }
  }

  void _glyph(Canvas canvas, String s, Offset center, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  static double _easeOutBack(double t) {
    const c1 = 1.70158, c3 = c1 + 1;
    final x = t - 1;
    return 1 + c3 * x * x * x + c1 * x * x;
  }

  @override
  bool shouldRepaint(CreaturePainter old) => false; // repaint via controller
}

/// The active mode's palette, derived from the hue gene + render mode.
class _Pal {
  _Pal(double hue, CreatureRenderMode mode, this.alpha, double satMul) : hue = hue % 360 {
    final isPhoto = mode == CreatureRenderMode.photo;
    flat = isPhoto;
    final sat = (isPhoto ? 0.14 : 0.58) * satMul;
    final val = isPhoto ? 0.80 : 0.95;
    base = HSVColor.fromAHSV(alpha, this.hue, sat.clamp(0.0, 1.0), val).toColor();
    light = HSVColor.fromAHSV(alpha, this.hue, (sat * 0.55).clamp(0.0, 1.0), (val + 0.06).clamp(0.0, 1.0)).toColor();
    dark = HSVColor.fromAHSV(alpha, this.hue, (sat + 0.14).clamp(0.0, 1.0), val * 0.6).toColor();
    spot = HSVColor.fromAHSV(0.85 * alpha, this.hue, (sat + 0.16).clamp(0.0, 1.0), val * 0.7).toColor();
    outline = HSVColor.fromAHSV(0.55 * alpha, this.hue, (sat + 0.2).clamp(0.0, 1.0), val * 0.5).toColor();
    wire = RC.inertGrey.withValues(alpha: 0.85 * alpha);
  }
  final double hue;
  final double alpha;
  late final Color base, light, dark, spot, outline, wire;
  late final bool flat;
}
