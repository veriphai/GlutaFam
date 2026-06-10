// Town — the hero, rebuilt for premium feel. Three depth bands of buildings
// (far → mid → near) with atmospheric perspective, architectural variety
// (setbacks, rooftops, water tanks, antennas), sun-side face-shading, windows
// that WAKE UP one-by-one as the town gains power, a foreground street with
// streetlights that switch on at night, and a "the town went dark" loss state
// (emergency lights + cold moonlight) distinct from "not powered yet".
//
// All driven by controller.townLight / sunAltitude / source — no labels, the town
// IS the reliability readout.

import 'dart:math' as math;

import 'package:flame/components.dart' show Component;
import 'package:flutter/material.dart';

import '../../state/source_personalities_controller.dart';

const Color _warmA = Color(0xFFFFE3A0); // most windows
const Color _warmB = Color(0xFFFFC976); // warmer
const Color _coolWhite = Color(0xFFCFE0FF); // a few office-white windows
const Color _windowOff = Color(0xFF0B1026);

class TownLayer extends Component {
  TownLayer(this.c, {this.reducedMotion = false});
  final SourcePersonalitiesController c;
  final bool reducedMotion;

  double _clock = 0;
  List<_Building>? _far, _mid, _near;
  List<_Prop>? _fg;
  double _builtForWidth = -1;

  @override
  void update(double dt) {
    if (!reducedMotion) _clock += dt;
  }

  void _ensure(double w, double townTop, double horizon) {
    if (_near != null && (_builtForWidth - w).abs() < 1) return;
    _builtForWidth = w;
    final span = horizon - townTop;
    _far = _row(w, townTop, horizon, seed: 11,
        gap: 0.014, wRange: const [0.045, 0.075], topFrac: const [0.42, 0.72], depth: 0.78);
    _mid = _row(w, townTop, horizon, seed: 41,
        gap: 0.013, wRange: const [0.055, 0.085], topFrac: const [0.18, 0.5], depth: 0.42);
    _near = _row(w, townTop, horizon, seed: 91,
        gap: 0.02, wRange: const [0.07, 0.12], topFrac: const [0.0, 0.38], depth: 0.0);
    // Foreground props (streetlights + trees) along the front kerb.
    final rng = math.Random(7);
    final fg = <_Prop>[];
    double x = w * 0.06;
    var lamp = true;
    while (x < w * 0.98) {
      fg.add(_Prop(x, lamp ? _PropKind.lamp : _PropKind.tree, 0.7 + rng.nextDouble() * 0.5,
          rng.nextDouble() * math.pi * 2));
      x += w * (0.16 + rng.nextDouble() * 0.06);
      lamp = !lamp;
    }
    _fg = fg;
    // Keep span referenced (atmospheric math reads it indirectly via topFrac).
    assert(span > 0);
  }

  List<_Building> _row(double w, double townTop, double horizon,
      {required int seed,
      required double gap,
      required List<double> wRange,
      required List<double> topFrac,
      required double depth}) {
    final rng = math.Random(seed);
    final span = horizon - townTop;
    final list = <_Building>[];
    double x = -w * 0.03;
    while (x < w * 1.03) {
      final bw = w * (wRange[0] + rng.nextDouble() * (wRange[1] - wRange[0]));
      final roof = townTop + span * (topFrac[0] + rng.nextDouble() * (topFrac[1] - topFrac[0]));
      final hasSetback = depth < 0.5 && rng.nextDouble() < 0.5;
      final prop = depth < 0.5
          ? _RoofProp.values[rng.nextInt(_RoofProp.values.length)]
          : _RoofProp.none;
      final cols = (1 + (bw / (w * 0.024)).floor()).clamp(2, 6);
      final rows = ((horizon - roof) / (w * 0.034)).floor().clamp(2, 9);
      final windows = <_Window>[];
      for (var r = 0; r < rows; r++) {
        for (var col = 0; col < cols; col++) {
          windows.add(_Window(
            (col + 0.5) / cols,
            (r + 0.5) / rows,
            rng.nextDouble() * math.pi * 2,
            0.55 + rng.nextDouble() * 0.45, // occupied likelihood
            rng.nextDouble() * 0.7, // wake threshold (staggers turn-on)
            rng.nextDouble(), // warm/cool pick
          ));
        }
      }
      final warmBias = 0.8 + rng.nextDouble() * 0.4;
      list.add(_Building(x, bw, roof, cols, rows, windows, depth, hasSetback, prop, warmBias));
      x += bw + w * gap;
    }
    return list;
  }

  @override
  void render(Canvas canvas) {
    final size = c.stageSize;
    if (size.isEmpty) return;
    final w = size.width, h = size.height;
    final horizon = c.horizonY, townTop = c.townTopY;
    _ensure(w, townTop, horizon);

    final alt = c.sunAltitude;
    final hasSource = c.source != null;
    final light = hasSource ? c.townLight.clamp(0.0, 1.0) : 0.16; // waiting-for-power ambient
    final blackout = hasSource && c.townLight < 0.12; // went dark = a loss
    final isWind = c.source?.isWind ?? false;
    final sunOnLeft = c.sunArcX < 0.5;
    // Golden warmth on building faces near sunrise/sunset.
    final golden = (alt > 0.001 ? (1 - (alt * 1.7).clamp(0.0, 1.0)) : 0.0);

    // Ground.
    final groundTop = Color.lerp(const Color(0xFF0C1024), const Color(0xFF2A3344), alt * 0.5)!;
    final groundBot = Color.lerp(const Color(0xFF070A18), const Color(0xFF1A222F), alt * 0.5)!;
    final groundRect = Rect.fromLTWH(0, horizon, w, h - horizon);
    canvas.drawRect(
      groundRect,
      Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [groundTop, groundBot]).createShader(groundRect),
    );

    // Town bloom — the warm halo a lit town throws into the dusk.
    if (light > 0.04 && !blackout) {
      final glowC = Offset(w * 0.6, (townTop + horizon) / 2 + (horizon - townTop) * 0.1);
      final glowR = w * 0.62;
      canvas.drawCircle(
        glowC, glowR,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(colors: [
            _warmA.withValues(alpha: 0.14 * light),
            _warmA.withValues(alpha: 0),
          ]).createShader(Rect.fromCircle(center: glowC, radius: glowR)),
      );
    }

    // Buildings, back to front.
    for (final b in _far!) {
      _drawBuilding(canvas, b, horizon, alt, light, golden, sunOnLeft, isWind, blackout);
    }
    for (final b in _mid!) {
      _drawBuilding(canvas, b, horizon, alt, light, golden, sunOnLeft, isWind, blackout);
    }
    for (final b in _near!) {
      _drawBuilding(canvas, b, horizon, alt, light, golden, sunOnLeft, isWind, blackout);
    }

    // Foreground street + streetlights + trees.
    _drawForeground(canvas, w, horizon, h, alt);
  }

  void _drawBuilding(Canvas canvas, _Building b, double horizon, double alt, double light,
      double golden, bool sunOnLeft, bool isWind, bool blackout) {
    final w = c.stageSize.width;
    // Atmospheric perspective: fade far rows toward the sky's lower colour.
    final skyLow = Color.lerp(const Color(0xFF14203F), const Color(0xFFA9D2F0), alt)!;
    final baseLit = Color.lerp(const Color(0xFF1B2444), const Color(0xFF44597A), alt * 0.5)!;
    final faceColor = Color.lerp(baseLit, skyLow, b.depth * 0.7)!;

    // Optional setback (a narrower upper block) before the main body.
    double bodyTop = b.roofY;
    if (b.hasSetback) {
      final sbW = b.width * 0.6;
      final sbTop = b.roofY - (horizon - b.roofY) * 0.16;
      final sbRect = Rect.fromLTWH(b.x + (b.width - sbW) / 2, sbTop, sbW, b.roofY - sbTop + 1);
      canvas.drawRect(sbRect, Paint()..color = faceColor);
      _roofCap(canvas, b.x + (b.width - sbW) / 2, sbTop, sbW, faceColor, alt);
    }

    final body = Rect.fromLTWH(b.x, bodyTop, b.width, horizon - bodyTop);
    // Face with a soft vertical gradient + sun-side lit edge.
    canvas.drawRect(
      body,
      Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
          faceColor,
          Color.lerp(faceColor, Colors.black, 0.22)!,
        ]).createShader(body),
    );
    // Sun-side warm edge + shadow-side dark edge (reads as a 3D volume).
    if (b.depth < 0.6) {
      final edgeW = b.width * 0.16;
      final lit = Color.lerp(faceColor, golden > 0.2 ? const Color(0xFFFFC98A) : Colors.white,
          0.18 + 0.4 * golden)!;
      final shadow = Color.lerp(faceColor, Colors.black, 0.28)!;
      final litRect = sunOnLeft
          ? Rect.fromLTWH(b.x, bodyTop, edgeW, horizon - bodyTop)
          : Rect.fromLTWH(b.x + b.width - edgeW, bodyTop, edgeW, horizon - bodyTop);
      final shadowRect = sunOnLeft
          ? Rect.fromLTWH(b.x + b.width - edgeW, bodyTop, edgeW, horizon - bodyTop)
          : Rect.fromLTWH(b.x, bodyTop, edgeW, horizon - bodyTop);
      canvas.drawRect(litRect, Paint()..color = lit.withValues(alpha: 0.5));
      canvas.drawRect(shadowRect, Paint()..color = shadow.withValues(alpha: 0.45));
    }
    _roofCap(canvas, b.x, bodyTop, b.width, faceColor, alt);
    _roofProp(canvas, b, horizon, faceColor, alt);

    // Windows.
    final colGap = b.width / (b.cols + 1);
    final rowGap = (horizon - bodyTop) / (b.rows + 1);
    final ww = (colGap * 0.5).clamp(1.5, w);
    final wh = (rowGap * 0.46).clamp(1.5, w);
    final dimDepth = (1 - b.depth * 0.65); // far windows dimmer
    for (final win in b.windows) {
      final cx = b.x + colGap * (win.col * b.cols + 1);
      final cy = bodyTop + rowGap * (win.row * b.rows + 1);
      double lit;
      if (isWind && !reducedMotion) {
        final flick = 0.5 + 0.5 * math.sin(_clock * 6.0 + win.phase);
        lit = light * (0.2 + 0.8 * flick) * win.occupied;
      } else {
        lit = light * win.occupied;
      }
      // Staggered wake-up: a window lights only once supply clears its threshold.
      final on = lit > (0.12 + win.wake * 0.5);
      bool emergency = false;
      if (!on && blackout && win.wake < 0.12) {
        emergency = true; // a few backup lights stay on in the dark
      }
      Color col;
      double a;
      if (on) {
        final warm = win.warm < 0.78
            ? Color.lerp(_warmA, _warmB, win.warm / 0.78)!
            : _coolWhite;
        col = Color.lerp(_windowOff, warm, (lit * b.warmBias).clamp(0.0, 1.0))!;
        a = dimDepth;
      } else if (emergency) {
        col = const Color(0xFF8FA0C0);
        a = 0.5;
      } else {
        col = _windowOff;
        a = 0.7 * dimDepth + (alt * 0.2);
      }
      final wr = Rect.fromCenter(center: Offset(cx, cy), width: ww, height: wh);
      canvas.drawRect(wr, Paint()..color = col.withValues(alpha: a.clamp(0.0, 1.0)));
    }

    // Cold moonlight rim when the town has gone dark (the loss).
    if (blackout && b.depth < 0.45) {
      final rimW = b.width * 0.1;
      final rim = sunOnLeft
          ? Rect.fromLTWH(b.x + b.width - rimW, bodyTop, rimW, horizon - bodyTop)
          : Rect.fromLTWH(b.x, bodyTop, rimW, horizon - bodyTop);
      canvas.drawRect(rim, Paint()..color = const Color(0xFF9FB4E0).withValues(alpha: 0.12));
    }
  }

  void _roofCap(Canvas canvas, double x, double top, double width, Color face, double alt) {
    canvas.drawRect(
      Rect.fromLTWH(x - 1, top - 2.5, width + 2, 2.5),
      Paint()..color = Color.lerp(face, Colors.white, 0.12 + 0.1 * alt)!,
    );
  }

  void _roofProp(Canvas canvas, _Building b, double horizon, Color face, double alt) {
    if (b.prop == _RoofProp.none) return;
    final cx = b.x + b.width * 0.5;
    final roofY = b.roofY - (b.hasSetback ? (horizon - b.roofY) * 0.16 : 0);
    final propColor = Color.lerp(face, Colors.black, 0.2)!;
    final u = b.width;
    switch (b.prop) {
      case _RoofProp.tank:
        final tw = u * 0.34;
        canvas.drawRect(Rect.fromLTWH(cx - tw / 2, roofY - u * 0.34, tw, u * 0.3),
            Paint()..color = propColor);
        canvas.drawLine(Offset(cx - tw / 2 + 2, roofY - u * 0.04), Offset(cx - tw / 2 + 2, roofY),
            Paint()..color = propColor..strokeWidth = 2);
        canvas.drawLine(Offset(cx + tw / 2 - 2, roofY - u * 0.04), Offset(cx + tw / 2 - 2, roofY),
            Paint()..color = propColor..strokeWidth = 2);
      case _RoofProp.antenna:
        canvas.drawLine(Offset(cx, roofY), Offset(cx, roofY - u * 0.5),
            Paint()..color = propColor..strokeWidth = 1.6);
        canvas.drawLine(Offset(cx - u * 0.1, roofY - u * 0.32), Offset(cx + u * 0.1, roofY - u * 0.32),
            Paint()..color = propColor..strokeWidth = 1.4);
        // A faint red aviation light.
        if (alt < 0.1) {
          canvas.drawCircle(Offset(cx, roofY - u * 0.5), 1.6,
              Paint()..color = const Color(0xFFFF5A4D).withValues(alpha: 0.9));
        }
      case _RoofProp.acbox:
        canvas.drawRect(Rect.fromLTWH(cx - u * 0.18, roofY - u * 0.16, u * 0.36, u * 0.16),
            Paint()..color = propColor);
      case _RoofProp.none:
        break;
    }
  }

  void _drawForeground(Canvas canvas, double w, double horizon, double h, double alt) {
    final night = (1 - alt / 0.18).clamp(0.0, 1.0);
    final kerbY = horizon + (h - horizon) * 0.5;
    // Sidewalk line.
    canvas.drawRect(
      Rect.fromLTWH(0, kerbY, w, 2),
      Paint()..color = Colors.white.withValues(alpha: 0.05 + 0.05 * alt),
    );
    for (final p in _fg!) {
      if (p.kind == _PropKind.lamp) {
        final baseY = kerbY + (h - kerbY) * 0.18;
        final topY = baseY - (h - horizon) * 0.42 * p.scale;
        // Post.
        canvas.drawLine(Offset(p.x, baseY), Offset(p.x, topY),
            Paint()..color = const Color(0xFF0A0E1C)..strokeWidth = 2.4);
        canvas.drawLine(Offset(p.x, topY), Offset(p.x + 8, topY),
            Paint()..color = const Color(0xFF0A0E1C)..strokeWidth = 2.4);
        final lampC = Offset(p.x + 8, topY + 2);
        if (night > 0.05) {
          // Warm lamp + downward cone glow at night.
          canvas.drawCircle(lampC, 9 * night,
              Paint()..color = const Color(0xFFFFD98A).withValues(alpha: 0.5 * night)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
          final cone = Path()
            ..moveTo(lampC.dx, lampC.dy)
            ..lineTo(lampC.dx - 16, baseY)
            ..lineTo(lampC.dx + 16, baseY)
            ..close();
          canvas.drawPath(cone, Paint()
            ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
              const Color(0xFFFFD98A).withValues(alpha: 0.22 * night),
              const Color(0xFFFFD98A).withValues(alpha: 0),
            ]).createShader(Rect.fromLTRB(lampC.dx - 16, lampC.dy, lampC.dx + 16, baseY)));
          canvas.drawCircle(lampC, 2.4, Paint()..color = const Color(0xFFFFF0C8));
        } else {
          canvas.drawCircle(lampC, 2.2, Paint()..color = const Color(0xFF2A3146));
        }
      } else {
        // Tree silhouette.
        final baseY = kerbY + (h - kerbY) * 0.22;
        final r = (h - horizon) * 0.12 * p.scale;
        final trunkTop = baseY - r * 1.2;
        canvas.drawLine(Offset(p.x, baseY), Offset(p.x, trunkTop),
            Paint()..color = const Color(0xFF0A0E1C)..strokeWidth = r * 0.18);
        final canopy = Color.lerp(const Color(0xFF0A1020), const Color(0xFF16331F), alt * 0.7)!;
        canvas.drawCircle(Offset(p.x, trunkTop - r * 0.3), r, Paint()..color = canopy);
        canvas.drawCircle(Offset(p.x - r * 0.6, trunkTop), r * 0.7, Paint()..color = canopy);
        canvas.drawCircle(Offset(p.x + r * 0.6, trunkTop), r * 0.7, Paint()..color = canopy);
      }
    }
  }
}

enum _RoofProp { none, tank, antenna, acbox }

enum _PropKind { lamp, tree }

class _Building {
  _Building(this.x, this.width, this.roofY, this.cols, this.rows, this.windows, this.depth,
      this.hasSetback, this.prop, this.warmBias);
  final double x, width, roofY;
  final int cols, rows;
  final List<_Window> windows;
  final double depth; // 0 near .. ~0.8 far (atmospheric)
  final bool hasSetback;
  final _RoofProp prop;
  final double warmBias;
}

class _Window {
  _Window(this.col, this.row, this.phase, this.occupied, this.wake, this.warm);
  final double col, row, phase, occupied, wake, warm;
}

class _Prop {
  _Prop(this.x, this.kind, this.scale, this.phase);
  final double x;
  final _PropKind kind;
  final double scale, phase;
}
