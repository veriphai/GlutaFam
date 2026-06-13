// The Flame scene layers for The Transformer — a portrait staging of the journey:
//   plant (bottom-left) → INPUT run rising → the iron CORE (hero, centre) with its
//   PRIMARY (left, 4 fixed loops) + SECONDARY (right, 2..8 wound loops) coils →
//   OUTPUT run climbing to the top-right → HORIZON pylons (the farthest ignites).
//
// Each layer is a near-pure renderer reading the controller's pixel/sim getters.
// HARD GATES honoured everywhere:
//   • OUT/lineReach land in the same frame the controller steps a detent.
//   • The far pylon's core glow snaps dark the frame OUT drops below 200.
//   • The output kick (amber field) tracks |d(field)/dt| — slack at the crest.
// The core's amber field CIRCULATES the iron window (BlendMode.plus, a current
// loop) and is the brightest, most-alive thing on screen; BOTH the input AND output
// line pulses are cool transmission-blue (#3FB9F5) — the only warm on screen is the
// FLUX INSIDE THE CORE. No line pulse is ever warm (heat = loss is 2.3's iconography
// and must not be contradicted).

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart' show Component;
import 'package:flutter/material.dart';

import '../../config/transformer_tuning.dart';
import '../../state/transformer_controller.dart';

Color _c(int v) => Color(v);
final Color _amber = _c(TxTune.coreFieldAmber);
final Color _amberHot = _c(TxTune.coreFieldAmberHot);
final Color _blue = _c(TxTune.transmissionBlue); // ALL line pulses — input + output
final Color _blueLite = _c(TxTune.transmissionBlueLite);
final Color _ironDark = _c(TxTune.ironDark);
final Color _ironMid = _c(TxTune.ironMid);
final Color _ironLite = _c(TxTune.ironLite);
final Color _ironBevel = _c(TxTune.ironBevel);
final Color _copper = _c(TxTune.copper);
final Color _copperLite = _c(TxTune.copperLite);
final Color _copperHot = _c(TxTune.copperHot);
final Color _copperDark = _c(TxTune.copperDark);
final Color _cityWarm = _c(TxTune.cityWarm);
// Brushed steel ramp (activity-3 craft) — towers + plant.
final Color _steelEdge = _c(TxTune.steelEdge);
final Color _steelBody = _c(TxTune.steelBody);
final Color _steelSpine = _c(TxTune.steelSpine);
final Color _steelRim = _c(TxTune.steelRim);
final Color _steelBolt = _c(TxTune.steelBolt);
final Color _insulatorCeramic = _c(TxTune.insulatorCeramic);

/// Light direction (upper-left) for the steel chamfer rim — matches activity 3.
const Offset _lightUL = Offset(-0.7071, -0.7071);

Paint _glow(Color color, double sigma, {double alpha = 1}) => Paint()
  ..color = color.withValues(alpha: alpha)
  ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);

/// Entrance helper: slide + scale + fade a component in as [rev] goes 0→1.
void _reveal(Canvas canvas, Size stage, double rev, Offset slide, Offset pivot, VoidCallback draw) {
  if (rev >= 0.999) {
    draw();
    return;
  }
  if (rev <= 0.001) return;
  canvas.saveLayer(Offset.zero & stage, Paint()..color = Colors.white.withValues(alpha: rev));
  canvas.translate(slide.dx * (1 - rev), slide.dy * (1 - rev));
  final s = 0.88 + 0.12 * rev;
  canvas.translate(pivot.dx, pivot.dy);
  canvas.scale(s);
  canvas.translate(-pivot.dx, -pivot.dy);
  draw();
  canvas.restore();
}

// ── Ambient motes — the hero's energy claims the void (16–22, §7) ──────────────
class AmbientMotesLayer extends Component {
  AmbientMotesLayer(this.c);
  final TransformerController c;
  final math.Random _rng = math.Random(26);
  final List<_Mote> _motes = [];

  @override
  void update(double dt) {
    if (c.stageSize.isEmpty) return;
    if (_motes.isEmpty) {
      for (var i = 0; i < 20; i++) {
        _motes.add(_Mote(_rng.nextDouble(), _rng.nextDouble(), 0.2 + _rng.nextDouble() * 0.5,
            0.4 + _rng.nextDouble() * 0.8));
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
    final core = c.coreCenter;
    for (final m in _motes) {
      final p = Offset(m.x * w, m.y * h);
      // Brighter near the core (where the energy is).
      final d = (p - core).distance / w;
      final bias = (1 - d).clamp(0.0, 1.0);
      final a = m.alpha * 0.06 * (0.4 + 0.6 * bias);
      canvas.drawCircle(p, m.r * 2.2, _glow(_c(0xFF9FC0FF), m.r * 2.0, alpha: a));
    }
  }
}

// ── Background glow — the core's amber field washes the dark, plus the warm city
//    bloom at the lit far pylon (§7: warm hero vs cool dark) ─────────────────────
class BackgroundGlowLayer extends Component {
  BackgroundGlowLayer(this.c);
  final TransformerController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    final core = c.coreCenter;
    final fb = c.fieldBloom;
    // The core's breathing amber bloom — the brightest wash on screen, pulsing with
    // the input surges (two layers: a wide soft halo + a tighter hotter heart).
    final r = c.coreOuterW * (0.72 + 0.58 * fb);
    canvas.drawCircle(
      core,
      r,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(colors: [
          _amber.withValues(alpha: (0.10 + 0.22 * fb)),
          _amber.withValues(alpha: 0),
        ], stops: const [0.0, 1.0]).createShader(Rect.fromCircle(center: core, radius: r)),
    );
    final rh = c.coreOuterW * (0.34 + 0.22 * fb);
    canvas.drawCircle(
      core,
      rh,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(colors: [
          _amberHot.withValues(alpha: (0.08 + 0.20 * fb)),
          _amberHot.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: core, radius: rh)),
    );
    // The far city's warm bloom — only while the farthest tower is lit.
    if (c.farPylonLit && c.towerApexes.isNotEmpty) {
      final far = c.towerApexes.last;
      final cr = c.stageSize.width * 0.16;
      canvas.drawCircle(
        far,
        cr,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(colors: [
            _cityWarm.withValues(alpha: 0.30),
            _cityWarm.withValues(alpha: 0),
          ]).createShader(Rect.fromCircle(center: far, radius: cr)),
      );
    }
  }
}

// ── The faint plant silhouette (bottom-left) — recedes (§7) ────────────────────
class PlantSilhouetteLayer extends Component {
  PlantSilhouetteLayer(this.c);
  final TransformerController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    _reveal(canvas, c.stageSize, c.lineReveal, Offset(0, c.stageSize.height * 0.05), c.plant,
        () => _draw(canvas));
  }

  void _draw(Canvas canvas) {
    final w = c.stageSize.width, h = c.stageSize.height;
    final base = c.plant;
    // A small but READABLE steel power plant (the same brushed-steel ramp as the
    // towers) — the sending end of the journey. Recessive vs the hero, but no longer
    // a near-black blob: a steel block body + two steel cooling chimneys.
    final blockRect = Rect.fromLTWH(base.dx - w * 0.085, base.dy - h * 0.05, w * 0.17, h * 0.06);
    final block = RRect.fromRectAndRadius(blockRect, Radius.circular(w * 0.012));
    final bodyFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_steelBody.withValues(alpha: 0.96), _steelEdge.withValues(alpha: 0.96)],
      ).createShader(blockRect);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _steelRim.withValues(alpha: 0.42);
    // Contact shadow under the block.
    canvas.drawRRect(block.shift(Offset(0, h * 0.006)),
        _glow(Colors.black, w * 0.02, alpha: 0.30));
    canvas.drawRRect(block, bodyFill);
    canvas.drawRRect(block, edge);
    // Lit top edge (the catch-light) so it reads as a 3D steel block.
    canvas.drawLine(
      Offset(blockRect.left + w * 0.012, blockRect.top + 0.8),
      Offset(blockRect.right - w * 0.012, blockRect.top + 0.8),
      Paint()
        ..color = _steelRim.withValues(alpha: 0.55)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i < 2; i++) {
      final sx = base.dx - w * 0.04 + i * w * 0.06;
      final tRect = Rect.fromLTWH(sx - w * 0.022, base.dy - h * 0.11, w * 0.044, h * 0.06);
      final tower = Path()
        ..moveTo(sx - w * 0.022, base.dy - h * 0.05)
        ..lineTo(sx - w * 0.014, base.dy - h * 0.11)
        ..lineTo(sx + w * 0.014, base.dy - h * 0.11)
        ..lineTo(sx + w * 0.022, base.dy - h * 0.05)
        ..close();
      canvas.drawPath(
        tower,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              _steelEdge.withValues(alpha: 0.96),
              _steelSpine.withValues(alpha: 0.96),
              _steelEdge.withValues(alpha: 0.96),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(tRect),
      );
      canvas.drawPath(tower, edge);
    }
  }
}

// ── The INPUT run — the always-alive surge pulses rising plant → primary bottom.
//    This is the CHANGING current; it never stops (the field breathes off it). ──
class InputLineLayer extends Component {
  InputLineLayer(this.c);
  final TransformerController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    _reveal(canvas, c.stageSize, c.lineReveal, Offset(0, c.stageSize.height * 0.05),
        c.inputTo, () => _draw(canvas));
  }

  void _draw(Canvas canvas) {
    final w = c.stageSize.width;
    final s = c.plant.translate(0, -c.stageSize.height * 0.05);
    final e = c.inputTo;
    // Dimensional cool conductor — a dark casing + a thin steel sheen down the spine.
    canvas.drawLine(s, e, Paint()
      ..color = _c(0xFF202A4C)
      ..strokeWidth = w * 0.016
      ..strokeCap = StrokeCap.round);
    canvas.drawLine(s, e, Paint()
      ..color = _ironLite.withValues(alpha: 0.40)
      ..strokeWidth = w * 0.0045
      ..strokeCap = StrokeCap.round);

    // Surge pulses — COOL transmission-blue, NEVER warm (these are the CHANGING
    // current; only the flux INSIDE the core is amber). The surge clock drives them;
    // in slowSurge a single isolated pulse walks the line slowly (scripted shape).
    if (c.reducedMotion && !c.isSlowSurge) {
      // Calm: a steady soft cool glow instead of travelling dots, breathing softly.
      canvas.drawLine(s, e, _glow(_blue, w * 0.018, alpha: 0.32 * c.fieldBloom)
        ..strokeWidth = w * 0.014
        ..strokeCap = StrokeCap.round);
      return;
    }
    final r = w * 0.013;
    if (c.isSlowSurge) {
      // One isolated cool pulse rising as the field builds (0 → crest), tied to bloom.
      final t = c.fieldBloom.clamp(0.0, 1.0);
      final p = Offset.lerp(s, e, t)!;
      final a = (0.5 + 0.5 * c.fieldBloom).clamp(0.0, 1.0);
      canvas.drawCircle(p, r * 2.0, _glow(_blue, r * 2.4, alpha: 0.9 * a));
      canvas.drawCircle(p, r * 0.8, Paint()..color = _blueLite.withValues(alpha: a));
    } else {
      final pulses = TxTune.inputPulseCount;
      for (var i = 0; i < pulses; i++) {
        final t = (c.shimmer * TxTune.inputPulseSpeed + i / pulses) % 1.0;
        final p = Offset.lerp(s, e, t)!;
        // The pulse fades as it nears the core — it is feeding the field there.
        final a = (math.sin(t * math.pi)).clamp(0.0, 1.0);
        canvas.drawCircle(p, r * 1.8, _glow(_blue, r * 2.2, alpha: 0.78 * a));
        canvas.drawCircle(p, r * 0.7, Paint()..color = _blueLite.withValues(alpha: 0.95 * a));
      }
    }
  }
}

// ── The OUTPUT run — a real transmission span: the conductor leaves the secondary
//    (HV) bushing and is STRUNG TOWER-TO-TOWER (sagging between suspension points)
//    all the way to the far city tower. The steel conductor is ALWAYS drawn end-to-
//    end (the infrastructure connecting transformer → towers → city); the bright
//    cool-blue CURRENT pulses travel only as far as lineReach allows, so more turns
//    push the energy farther and at OUT 200 it reaches the city (ignition). The
//    output's liveness tracks the field's rate of change (outputKick) in slowSurge
//    so it slackens at the bloom crest. ───────────────────────────────────────────
class OutputLineLayer extends Component {
  OutputLineLayer(this.c);
  final TransformerController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    _reveal(canvas, c.stageSize, c.lineReveal, Offset(0, c.stageSize.height * 0.04),
        c.outputFrom, () => _draw(canvas));
  }

  /// The full sagging conductor — outputFrom → tower1 → tower2 → city — sampled into
  /// a dense polyline with cumulative arc length, so the current can walk it end-to-
  /// end. Each span dips downward (catenary) at mid-span like a real strung wire.
  _Poly _conductor() {
    final pts = <Offset>[];
    final cum = <double>[];
    final way = <Offset>[c.outputFrom, ...c.towerApexes];
    const perSpan = 16;
    double acc = 0;
    Offset? prev;
    for (var s = 0; s < way.length - 1; s++) {
      final a = way[s], b = way[s + 1];
      final sag = (b - a).distance * TxTune.catenarySagFactor;
      for (var i = 0; i <= perSpan; i++) {
        if (s > 0 && i == 0) continue; // don't duplicate the shared apex
        final t = i / perSpan;
        final dip = 4 * sag * t * (1 - t); // 0 at the ends, `sag` at mid-span (downward)
        final p = Offset.lerp(a, b, t)!.translate(0, dip);
        if (prev != null) acc += (p - prev).distance;
        pts.add(p);
        cum.add(acc);
        prev = p;
      }
    }
    return _Poly(pts, cum);
  }

  Offset _along(_Poly poly, double d) {
    final pts = poly.pts, cum = poly.cum;
    if (pts.isEmpty) return Offset.zero;
    final target = d.clamp(0.0, cum.last);
    for (var i = 1; i < pts.length; i++) {
      if (cum[i] >= target) {
        final seg = cum[i] - cum[i - 1];
        final f = seg <= 0 ? 0.0 : (target - cum[i - 1]) / seg;
        return Offset.lerp(pts[i - 1], pts[i], f)!;
      }
    }
    return pts.last;
  }

  void _draw(Canvas canvas) {
    final w = c.stageSize.width;
    final poly = _conductor();
    if (poly.pts.length < 2) return;
    final total = poly.cum.last;

    final full = Path()..moveTo(poly.pts.first.dx, poly.pts.first.dy);
    for (var i = 1; i < poly.pts.length; i++) {
      full.lineTo(poly.pts[i].dx, poly.pts[i].dy);
    }

    // 1) The strung steel conductor — ALWAYS visible end-to-end (the wire that
    //    connects the transformer to the city through every tower). Soft under-glow
    //    → dark steel body → a thin lit spine. Cool steel, never warm.
    canvas.drawPath(full, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _steelEdge.withValues(alpha: 0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.006));
    canvas.drawPath(full, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.0072
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _steelBody);
    canvas.drawPath(full, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.0026
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _steelSpine.withValues(alpha: 0.7));

    // 2) The current flows the FULL conductor end-to-end — a complete series circuit
    //    through EVERY tower to the city (on-device feedback: it must not stop at the
    //    first tower). Voltage (the turns) drives the FLOW BRIGHTNESS, not the reach;
    //    at max turns the far city ignites. live tracks outputKick in slowSurge (the
    //    honest envelope, slack at the bloom crest), steady otherwise.
    final live = c.isSlowSurge ? c.outputKick : 1.0;
    final vNorm = c.lineReach.clamp(0.0, 1.0); // turns → 0..1 (brightness, not length)

    // The energised cool-blue overlay over the whole steel conductor.
    canvas.drawPath(full, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.0072
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _blue.withValues(alpha: (0.26 + 0.30 * vNorm) * (0.6 + 0.4 * live)));

    // Travelling cool-blue current pulses along the WHOLE wire (the static overlay
    // above carries reduced motion). Brighter as voltage climbs; in slowSurge the
    // clock advances ∝ outputKick so the pulses STALL at the bloom crest.
    if (!c.reducedMotion) {
      const pulses = 7;
      final r = w * 0.012;
      final clock = c.outputPhase;
      for (var i = 0; i < pulses; i++) {
        final t = (clock + i / pulses) % 1.0;
        final d = t * total;
        final p = _along(poly, d);
        final persp = 1 - 0.45 * (d / total).clamp(0.0, 1.0);
        final a = ((0.45 + 0.40 * vNorm) * (0.6 + 0.4 * live)).clamp(0.0, 1.0);
        canvas.drawCircle(p, r * 1.7 * persp, _glow(_blue, r * 2.0 * persp, alpha: 0.85 * a));
        canvas.drawCircle(p, r * 0.66 * persp, Paint()..color = _blueLite.withValues(alpha: 0.9 * a));
      }
    }

    // 3) The ignition pulse-train: a bright cool packet + comet tail sails the FULL
    //    conductor to the city — "now it's high enough to send".
    final ig = c.ignitionT;
    if (ig > 0 && ig < 1) {
      final tail = c.reducedMotion ? 1 : 6;
      for (var s = tail - 1; s >= 0; s--) {
        final tp = (ig - s * 0.045).clamp(0.0, 1.0);
        final p = _along(poly, total * tp);
        final persp = 1 - 0.5 * tp;
        final fade = tail == 1 ? 1.0 : 1.0 - s / tail;
        final r = w * 0.02 * persp;
        canvas.drawCircle(p, r * 2.4 * (0.5 + 0.5 * fade),
            _glow(_blue, r * 3.0, alpha: 0.95 * fade));
        if (s == 0) {
          canvas.drawCircle(p, r * 1.1, Paint()..blendMode = BlendMode.plus..color = _blueLite);
          canvas.drawCircle(p, r * 0.5, Paint()..color = Colors.white);
        }
      }
    }
  }
}

// ── The HORIZON transmission towers — a receding row of STEEL lattice pylons (the
//    activity-3 cylindrical-steel craft) that the output conductor is strung across.
//    Each apex carries an insulator string where the wire clamps. The farthest tower
//    is the city / ignition target: its warm bloom snaps on at ignition and snaps
//    DARK the frame OUT drops below 200 (windDown). No fade tail. ─────────────────
class HorizonPylonsLayer extends Component {
  HorizonPylonsLayer(this.c);
  final TransformerController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    final apexes = c.towerApexes;
    final pivot = apexes.isEmpty ? c.coreCenter : apexes.first;
    _reveal(canvas, c.stageSize, c.pylonReveal, Offset(0, -c.stageSize.height * 0.03),
        pivot, () => _draw(canvas));
  }

  void _draw(Canvas canvas) {
    final apexes = c.towerApexes;
    final scales = c.towerScales;
    // Draw farthest → nearest so nearer (larger) towers overlap the distant ones.
    for (var i = apexes.length - 1; i >= 0; i--) {
      final scale = i < scales.length ? scales[i] : 1.0;
      final th = c.towerHeight * scale;
      final isCity = i == apexes.length - 1;
      _paintTower(canvas, apexes[i], th, 1.0);
      if (isCity && c.farPylonLit) _cityIgnite(canvas, apexes[i], th);
    }
  }

  // ── Premium steel lattice tower (cylindrical members, bolted joints, insulator
  //    string at the apex) — ported from current_heats_wire. Kept cool/recessive so
  //    the warm core stays hero.
  void _paintTower(Canvas canvas, Offset apex, double th, double a) {
    if (th <= 1) return;
    final headHalf = th * TxTune.towerHeadHalfF;
    final baseHalf = th * TxTune.towerBaseHalfF;
    final legW = math.max(1.0, th * TxTune.towerLegWF);
    final braceW = math.max(0.7, th * TxTune.towerBraceWF);
    final footY = apex.dy + th;
    final headL = Offset(apex.dx - headHalf, apex.dy);
    final headR = Offset(apex.dx + headHalf, apex.dy);
    final footL = Offset(apex.dx - baseHalf, footY);
    final footR = Offset(apex.dx + baseHalf, footY);

    // ground-contact haze under the feet (a distant tower stands on the horizon).
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(apex.dx, footY + th * 0.01), width: baseHalf * 3.0, height: baseHalf * 0.7),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.26 * a)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, th * 0.02),
    );
    // a blurred silhouette offset down-right → cheap lift/depth.
    final sil = Path()
      ..moveTo(headL.dx, headL.dy)
      ..lineTo(headR.dx, headR.dy)
      ..lineTo(footR.dx, footR.dy)
      ..lineTo(footL.dx, footL.dy)
      ..close();
    canvas.drawPath(
      sil.shift(Offset(th * 0.01, th * 0.012)),
      Paint()
        ..color = _steelBolt.withValues(alpha: 0.26 * a)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, th * 0.01),
    );

    // lattice cross-braces (drawn first; legs overlap their ends at the joints).
    final rungs = TxTune.towerRungs;
    Offset onLeg(Offset head, Offset foot, double f) =>
        Offset(head.dx + (foot.dx - head.dx) * f, head.dy + (foot.dy - head.dy) * f);
    for (var i = 0; i <= rungs; i++) {
      final f = i / rungs;
      final pl = onLeg(headL, footL, f);
      final pr = onLeg(headR, footR, f);
      _brace(canvas, pl, pr, braceW, a);
      if (i < rungs) {
        final pl2 = onLeg(headL, footL, (i + 1) / rungs);
        final pr2 = onLeg(headR, footR, (i + 1) / rungs);
        _brace(canvas, pl, pr2, braceW, a);
        _brace(canvas, pr, pl2, braceW, a);
      }
    }
    // the two cylindrical steel legs.
    _leg(canvas, headL, footL, legW, a);
    _leg(canvas, headR, footR, legW, a);
    // bolted joints.
    for (var i = 0; i <= rungs; i++) {
      final f = i / rungs;
      _bolt(canvas, onLeg(headL, footL, f), legW * 0.6, a);
      _bolt(canvas, onLeg(headR, footR, f), legW * 0.6, a);
    }
    // the ceramic insulator string the conductor clamps onto, at the apex.
    _insulator(canvas, apex, th, a);
  }

  // A cylindrical steel member: a cross-section gradient (dark edge → bright spine →
  // dark edge) perpendicular to the axis + an upper-left chamfer rim.
  void _leg(Canvas canvas, Offset a, Offset b, double width, double alpha) {
    final d = b - a;
    final len = d.distance;
    if (len < 1) return;
    final dir = Offset(d.dx / len, d.dy / len);
    final n = Offset(-dir.dy, dir.dx);
    final m = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    final half = width / 2;
    canvas.drawLine(
      a,
      b,
      Paint()
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(
          Offset(m.dx - n.dx * half, m.dy - n.dy * half),
          Offset(m.dx + n.dx * half, m.dy + n.dy * half),
          [
            _steelEdge.withValues(alpha: alpha),
            _steelSpine.withValues(alpha: alpha),
            _steelEdge.withValues(alpha: alpha),
          ],
          const [0.0, 0.5, 1.0],
        ),
    );
    final ro = width * 0.34;
    canvas.drawLine(
      a.translate(_lightUL.dx * ro, _lightUL.dy * ro),
      b.translate(_lightUL.dx * ro, _lightUL.dy * ro),
      Paint()
        ..strokeWidth = width * 0.30
        ..strokeCap = StrokeCap.round
        ..color = _steelRim.withValues(alpha: 0.55 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5),
    );
  }

  void _brace(Canvas canvas, Offset a, Offset b, double width, double alpha) {
    canvas.drawLine(
      a,
      b,
      Paint()
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..color = _steelBody.withValues(alpha: 0.92 * alpha),
    );
    final ro = width * 0.40;
    canvas.drawLine(
      a.translate(_lightUL.dx * ro, _lightUL.dy * ro),
      b.translate(_lightUL.dx * ro, _lightUL.dy * ro),
      Paint()
        ..strokeWidth = width * 0.42
        ..strokeCap = StrokeCap.round
        ..color = _steelRim.withValues(alpha: 0.38 * alpha),
    );
  }

  void _bolt(Canvas canvas, Offset at, double r, double alpha) {
    canvas.drawCircle(at, r, Paint()..color = _steelBolt.withValues(alpha: 0.85 * alpha));
    canvas.drawCircle(
      at.translate(_lightUL.dx * r * 0.5, _lightUL.dy * r * 0.5),
      r * 0.45,
      Paint()..color = Colors.white.withValues(alpha: 0.30 * alpha),
    );
  }

  void _insulator(Canvas canvas, Offset anchor, double th, double alpha) {
    final r = TxTune.insulatorDiscRF * th;
    canvas.drawCircle(anchor, r * 0.55, Paint()..color = _steelBolt.withValues(alpha: 0.9 * alpha));
    for (var i = 0; i < TxTune.insulatorDiscs; i++) {
      final cc = Offset(anchor.dx, anchor.dy + r * 1.15 * (i + 0.7));
      final rect = Rect.fromCenter(center: cc, width: r * 2.0, height: r * 1.3);
      canvas.drawOval(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(cc.dx + _lightUL.dx * r * 0.5, cc.dy + _lightUL.dy * r * 0.4),
            r * 1.5,
            [
              _insulatorCeramic.withValues(alpha: 0.95 * alpha),
              _steelEdge.withValues(alpha: 0.92 * alpha),
            ],
          ),
      );
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = _steelRim.withValues(alpha: 0.5 * alpha),
      );
    }
  }

  // The far CITY catching light at ignition — warm halo, hot core, glints (the ≤1400
  // ms payoff; the one moment the periphery may briefly outshine the hero core).
  void _cityIgnite(Canvas canvas, Offset apex, double th) {
    final at = apex.translate(0, th * 0.5);
    final u = th * 0.6;
    canvas.drawCircle(at, u * 1.4, _glow(_cityWarm, u * 1.1, alpha: 0.5));
    canvas.drawCircle(at, u * 0.9, _glow(_cityWarm, u * 0.7, alpha: 0.85));
    canvas.drawCircle(at, u * 0.28, Paint()..color = _amberHot);
    canvas.drawCircle(at, u * 0.14, Paint()..color = Colors.white.withValues(alpha: 0.9));
    final glint = Paint()
      ..blendMode = BlendMode.plus
      ..color = _cityWarm.withValues(alpha: 0.7)
      ..strokeWidth = math.max(1.0, th * 0.012)
      ..strokeCap = StrokeCap.round;
    final gl = u * 1.3;
    canvas.drawLine(at.translate(-gl, 0), at.translate(gl, 0), glint);
    canvas.drawLine(at.translate(0, -gl), at.translate(0, gl), glint);
  }
}

// ── THE HERO — the dark iron core ring with its breathing amber field ──────────
class CoreFieldLayer extends Component {
  CoreFieldLayer(this.c);
  final TransformerController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    _reveal(canvas, c.stageSize, c.coreReveal, Offset(0, c.stageSize.height * 0.02),
        c.coreCenter, () => _draw(canvas));
  }

  void _draw(Canvas canvas) {
    final ctr = c.coreCenter;
    final ow = c.coreOuterW, oh = c.coreOuterH;
    final lt = c.limbThickness;
    final outer = RRect.fromRectAndRadius(
      Rect.fromCenter(center: ctr, width: ow, height: oh),
      Radius.circular(lt * 0.7),
    );
    final inner = RRect.fromRectAndRadius(
      Rect.fromCenter(center: ctr, width: ow - lt * 2, height: oh - lt * 2),
      Radius.circular(lt * 0.4),
    );
    final fb = c.fieldBloom.clamp(0.0, 1.0);

    // 1) Soft contact shadow under the heavy iron ring (it has weight).
    canvas.drawRRect(outer.shift(Offset(0, oh * 0.045)),
        _glow(Colors.black, lt * 1.1, alpha: 0.34));

    // 2) The dark iron body — a laminated steel ring (the "window" frame), drawn as
    //    an even-odd ring path with a directional gradient (top-left lit, foot dark).
    final body = Path()
      ..addRRect(outer)
      ..addRRect(inner)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_ironLite.withValues(alpha: 0.55), _ironMid, _ironDark],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(outer.outerRect),
    );

    // 3) The dimensional bevels — a bright lit edge on the OUTER top-left and a dark
    //    recessed edge on the INNER (window) top-left, so the ring reads as a heavy
    //    chamfered block rather than a flat outline.
    _bevels(canvas, outer, inner, lt);

    // 4) The richer lamination texture (the stacked steel sheets).
    _laminations(canvas, ctr, ow, oh, lt);

    // 5) Crisp outer + inner edge strokes (a thin specular rim).
    canvas.drawRRect(outer, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = _ironLite.withValues(alpha: 0.40));
    canvas.drawRRect(inner, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _c(0xFF0A0E22).withValues(alpha: 0.85));

    // 6) THE HERO — the amber FLUX circulating the iron window like a current loop
    //    (additive). It brightens in pulses synced to the input surges; the output
    //    (right) limb rides the kick so it slackens at the bloom crest.
    _fluxLoop(canvas, ctr, ow, oh, lt, fb);
  }

  /// Dimensional bevels — a lit outer top-left edge and a recessed inner top edge so
  /// the iron ring reads as a heavy chamfered block with real depth.
  void _bevels(Canvas canvas, RRect outer, RRect inner, double lt) {
    final band = lt * TxTune.coreBevelFactor;
    final or = outer.outerRect, ir = inner.outerRect;
    // Outer lit edge — a soft inset highlight on the top + left faces.
    canvas.save();
    canvas.clipRRect(outer);
    final litPaint = Paint()
      ..color = _ironBevel.withValues(alpha: 0.55)
      ..strokeWidth = band
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(or.left, or.top + band), Offset(or.right, or.top + band), litPaint);
    canvas.drawLine(Offset(or.left + band, or.top), Offset(or.left + band, or.bottom), litPaint);
    // Outer dark edge — bottom + right faces fall into shadow.
    final shadePaint = Paint()
      ..color = _c(0xFF080B1C).withValues(alpha: 0.6)
      ..strokeWidth = band
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(or.left, or.bottom - band), Offset(or.right, or.bottom - band), shadePaint);
    canvas.drawLine(Offset(or.right - band, or.top), Offset(or.right - band, or.bottom), shadePaint);
    canvas.restore();
    // Inner window edge — recessed: dark on the top/left, faint lift on bottom/right
    // (the window is cut INTO the iron, so its lighting is inverted).
    final innerDark = Paint()
      ..color = _c(0xFF05081A).withValues(alpha: 0.7)
      ..strokeWidth = band * 0.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(ir.left, ir.top + band * 0.5), Offset(ir.right, ir.top + band * 0.5), innerDark);
    canvas.drawLine(Offset(ir.left + band * 0.5, ir.top), Offset(ir.left + band * 0.5, ir.bottom), innerDark);
    final innerLift = Paint()
      ..color = _ironLite.withValues(alpha: 0.22)
      ..strokeWidth = band * 0.7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(ir.left, ir.bottom - band * 0.5), Offset(ir.right, ir.bottom - band * 0.5), innerLift);
    canvas.drawLine(Offset(ir.right - band * 0.5, ir.top), Offset(ir.right - band * 0.5, ir.bottom), innerLift);
  }

  void _laminations(Canvas canvas, Offset ctr, double ow, double oh, double lt) {
    // Stacked steel-sheet hairlines down both limbs + across the top/bottom yokes —
    // alternating a faint dark groove and a faint lit ridge so the steel reads as
    // laminated, not solid.
    final n = TxTune.coreLaminations;
    for (final sign in [-1.0, 1.0]) {
      final lx = ctr.dx + sign * (ow * 0.5 - lt * 0.5);
      for (var i = -(n ~/ 2); i <= n ~/ 2; i++) {
        final x = lx + i * (lt * 0.9 / n);
        final groove = i.isEven;
        canvas.drawLine(
          Offset(x, ctr.dy - oh * 0.5 + lt * 0.22),
          Offset(x, ctr.dy + oh * 0.5 - lt * 0.22),
          Paint()
            ..color = (groove ? _c(0xFF0A0E22) : _ironLite).withValues(alpha: groove ? 0.5 : 0.16)
            ..strokeWidth = 1.0,
        );
      }
    }
    // Top + bottom yoke laminations (horizontal hairlines across the cross-pieces).
    for (final sy in [-1.0, 1.0]) {
      final ly = ctr.dy + sy * (oh * 0.5 - lt * 0.5);
      for (var i = -(n ~/ 2); i <= n ~/ 2; i++) {
        final y = ly + i * (lt * 0.9 / n);
        final groove = i.isEven;
        canvas.drawLine(
          Offset(ctr.dx - ow * 0.5 + lt * 0.22, y),
          Offset(ctr.dx + ow * 0.5 - lt * 0.22, y),
          Paint()
            ..color = (groove ? _c(0xFF0A0E22) : _ironLite).withValues(alpha: groove ? 0.4 : 0.12)
            ..strokeWidth = 1.0,
        );
      }
    }
  }

  /// THE HERO — the magnetic FLUX circulating the iron window like a current loop.
  /// A base ribbon breathes (alpha ∝ fieldBloom) around the whole window, and two
  /// bright comet-heads with fading tails TRAVEL the perimeter (BlendMode.plus) so
  /// the field unmistakably MOVES around the core while nothing mechanical does.
  /// The output (right) limb rides the kick so it slackens at the bloom crest.
  void _fluxLoop(Canvas canvas, Offset ctr, double ow, double oh, double lt, double fb) {
    final innerW = ow - lt * 2, innerH = oh - lt * 2;
    // The flux travels through the MIDDLE of the iron band (the magnetic path),
    // just outside the window edge — that is where the field lives in the steel.
    final pathW = innerW + lt, pathH = innerH + lt;
    final rect = Rect.fromCenter(center: ctr, width: pathW, height: pathH);
    final radius = lt * 0.55;
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final stroke = lt * TxTune.fluxStrokeFactor;

    // 1) Base flux glow around the whole loop — breathes with the surge (the field
    //    is always alive; brightens in pulses at each surge crest).
    final baseAlpha = (TxTune.fluxRibbonAlphaFloor + TxTune.fluxRibbonAlphaGain * fb).clamp(0.0, 1.0);
    canvas.drawRRect(
      rr,
      Paint()
        ..blendMode = BlendMode.plus
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = _amber.withValues(alpha: baseAlpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, lt * 0.5),
    );
    // A thin sharp core line on top so the loop has a crisp moving spine, not a haze.
    canvas.drawRRect(
      rr,
      Paint()
        ..blendMode = BlendMode.plus
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 0.32
        ..strokeCap = StrokeCap.round
        ..color = _amber.withValues(alpha: (0.10 + 0.30 * fb).clamp(0.0, 1.0)),
    );

    // 2) The travelling comet-heads — the unmistakable CIRCULATION. With reduced
    //    motion this calms to a steady bloom (no travel), per the locked guardrail.
    final headBright = (0.45 + TxTune.fieldBloomGain * fb).clamp(0.0, 1.0);
    if (!c.reducedMotion) {
      final heads = TxTune.fluxHeadCount;
      final span = TxTune.fluxHeadSpanFactor;
      final samples = TxTune.fluxTrailSamples;
      for (var hI = 0; hI < heads; hI++) {
        final head = (c.shimmer * TxTune.fluxLoopSpeed + hI / heads) % 1.0;
        // Draw the tail first (furthest-back sample → nearest), head LAST so it sits
        // on top. s2 = 0 is the head; larger s2 trails behind it along the loop.
        for (var s2 = samples - 1; s2 >= 0; s2--) {
          final f = s2 / (samples - 1); // 0 (head) → 1 (tail-end)
          final t = (head - span * f) % 1.0; // each sample sits BEHIND the head
          final tt = t < 0 ? t + 1 : t;
          final p = _onRoundedLoop(rect, radius, tt);
          final fade = (1 - f) * (1 - f); // bright at the head, fading to the tail
          final a = (headBright * fade).clamp(0.0, 1.0);
          if (s2 == 0) {
            // the bright head — a hot amber core + a soft halo.
            canvas.drawCircle(p, stroke * 0.95, _glow(_amberHot, stroke * 1.1, alpha: headBright));
            canvas.drawCircle(p, stroke * 0.45,
                Paint()..blendMode = BlendMode.plus..color = _amberHot.withValues(alpha: headBright));
          } else {
            canvas.drawCircle(p, stroke * (0.4 + 0.45 * fade),
                _glow(_amber, stroke * 0.7, alpha: a * 0.85));
          }
        }
      }
    } else {
      // Reduced motion: a steady symmetric bloom on the loop (no travelling head).
      canvas.drawRRect(
        rr,
        Paint()
          ..blendMode = BlendMode.plus
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 0.6
          ..strokeCap = StrokeCap.round
          ..color = _amberHot.withValues(alpha: 0.30 * headBright)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, lt * 0.4),
      );
    }

    // 3) The OUTPUT (right) limb rides the kick during slowSurge — the induction
    //    moment. Slack at the bloom crest (where the field stops changing), alive on
    //    the rise + fall. A felt, not-numbered signal that the output kicks ONLY
    //    while the field is changing. This is a HARD envelope — never softened.
    final rightLimbX = ctr.dx + ow * 0.5 - lt * 0.5;
    final kick = (c.isSlowSurge ? c.outputKick : fb).clamp(0.0, 1.0);
    final glowRect = Rect.fromCenter(
        center: Offset(rightLimbX, ctr.dy), width: lt * 1.5, height: oh * 0.88);
    canvas.drawRRect(
      RRect.fromRectAndRadius(glowRect, Radius.circular(lt * 0.45)),
      Paint()
        ..blendMode = BlendMode.plus
        ..color = _amberHot.withValues(alpha: 0.58 * kick)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, lt * 0.62),
    );
  }

  /// A point at perimeter fraction [t] (0..1) walking the rounded-rect window loop,
  /// clockwise from top-centre, with the corners traced as arcs (so the comet does
  /// not jump the rounded corners). Mirrors the 2.1–2.5 `_pointOnLoop` craft.
  Offset _onRoundedLoop(Rect rect, double r, double t) {
    final l = rect.left, rt = rect.right, tp = rect.top, bt = rect.bottom;
    final straightH = (rt - l) - 2 * r;
    final straightV = (bt - tp) - 2 * r;
    final arc = (math.pi / 2) * r;
    final total = 2 * straightH + 2 * straightV + 4 * arc;
    var d = (t % 1.0) * total;
    final cx = (l + rt) / 2;
    final halfTop = straightH / 2;
    if (d <= halfTop) return Offset(cx + d, tp);
    d -= halfTop;
    if (d <= arc) {
      final a = -math.pi / 2 + (d / arc) * (math.pi / 2);
      return Offset(rt - r + r * math.cos(a), tp + r + r * math.sin(a));
    }
    d -= arc;
    if (d <= straightV) return Offset(rt, tp + r + d);
    d -= straightV;
    if (d <= arc) {
      final a = (d / arc) * (math.pi / 2);
      return Offset(rt - r + r * math.cos(a), bt - r + r * math.sin(a));
    }
    d -= arc;
    if (d <= straightH) return Offset(rt - r - d, bt);
    d -= straightH;
    if (d <= arc) {
      final a = math.pi / 2 + (d / arc) * (math.pi / 2);
      return Offset(l + r + r * math.cos(a), bt - r + r * math.sin(a));
    }
    d -= arc;
    if (d <= straightV) return Offset(l, bt - r - d);
    d -= straightV;
    if (d <= arc) {
      final a = math.pi + (d / arc) * (math.pi / 2);
      return Offset(l + r + r * math.cos(a), tp + r + r * math.sin(a));
    }
    d -= arc;
    return Offset(l + r + d, tp);
  }
}

// ── The PRIMARY coil — 4 FIXED loops on the LEFT limb. They never change and stay
//    on screen throughout (the held constant, alongside IN 100). ────────────────
class PrimaryCoilLayer extends Component {
  PrimaryCoilLayer(this.c);
  final TransformerController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    _reveal(canvas, c.stageSize, c.coilReveal, Offset(-c.stageSize.width * 0.03, 0),
        c.coreCenter, () => _draw(canvas));
  }

  void _draw(Canvas canvas) {
    final ctr = c.coreCenter;
    final ow = c.coreOuterW, oh = c.coreOuterH, lt = c.limbThickness;
    final limbX = ctr.dx - ow * 0.5 + lt * 0.5;
    _drawCoil(canvas, limbX, ctr.dy, oh, lt, TxTune.primaryTurns, 1.0);
  }
}

// ── The SECONDARY coil — 2..8 COUNTABLE loops on the RIGHT limb. The ONLY thing
//    the learner changes; the loop-wrap flourish plays on each detent. ──────────
class SecondaryCoilLayer extends Component {
  SecondaryCoilLayer(this.c);
  final TransformerController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    _reveal(canvas, c.stageSize, c.coilReveal, Offset(c.stageSize.width * 0.03, 0),
        c.coreCenter, () => _draw(canvas));
    _grabHint(canvas);
  }

  void _draw(Canvas canvas) {
    final ctr = c.coreCenter;
    final ow = c.coreOuterW, oh = c.coreOuterH, lt = c.limbThickness;
    final limbX = ctr.dx + ow * 0.5 - lt * 0.5;
    _drawCoil(canvas, limbX, ctr.dy, oh, lt, c.turnsOut.value, c.coilWindT);
  }

  /// An elegant upward "wind me" hint on the secondary limb until the learner winds.
  /// Three soft amber chevrons drift up the limb and fade as they rise (a gentle
  /// invitation, not a flashing arrow), pulsing as one.
  void _grabHint(Canvas canvas) {
    if (!c.grabHintActive) return;
    final ctr = c.coreCenter;
    final ow = c.coreOuterW, oh = c.coreOuterH, lt = c.limbThickness;
    final x = ctr.dx + ow * 0.5 - lt * 0.5;
    final breathe = 0.5 + 0.25 * math.sin(c.shimmer * 2.2); // a calm overall pulse
    final up = (c.shimmer * 0.55) % 1.0;
    final s = c.stageSize.width * 0.024;
    for (var k = 0; k < 3; k++) {
      final prog = (up + k / 3.0) % 1.0; // 0 (bottom) → 1 (top)
      final fy = ctr.dy + oh * 0.34 - prog * oh * 0.62;
      // Fade in from the bottom, fade out toward the top (a travelling glint).
      final travel = math.sin(prog * math.pi).clamp(0.0, 1.0);
      final a = (0.55 * breathe * travel).clamp(0.0, 1.0);
      if (a < 0.02) continue;
      final paint = Paint()
        ..color = _amberHot.withValues(alpha: a)
        ..strokeWidth = c.stageSize.width * 0.0075
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);
      canvas.drawLine(Offset(x - s, fy + s * 0.62), Offset(x, fy), paint);
      canvas.drawLine(Offset(x + s, fy + s * 0.62), Offset(x, fy), paint);
    }
  }
}

/// Shared coil renderer — [turns] DIMENSIONAL copper windings wrapped around a
/// vertical limb at [limbX], centred at [cy], spanning [oh]. Each turn is a back arc
/// (behind the limb, recessed/dark) + a front arc (in front, bright copper with a
/// rounded cylindrical shade + a specular sheen) so the coil reads as 3D wound wire.
/// [windT] (0..1) plays the newest loop's crisp wrap-on flourish: it sweeps on from
/// the back, scales up, and flashes a sheen — visual only; the turn count is instant.
void _drawCoil(Canvas canvas, double limbX, double cy, double oh, double lt,
    int turns, double windT) {
  final span = oh * 0.80;
  final top = cy - span / 2;
  final loopH = span / turns;
  final loopW = lt * TxTune.coilLoopWidthFactor;
  final wire = lt * TxTune.coilWireFactor;
  final sheenW = math.max(1.0, lt * TxTune.coilSheenFactor);

  // Back arcs first (whole stack), so every front arc overlaps the back of the loop
  // below it — the woven, overlapping look of real wound wire.
  for (var i = 0; i < turns; i++) {
    final y = top + loopH * (i + 0.5);
    final isNewest = i == turns - 1;
    final scale = isNewest ? (0.55 + 0.45 * windT) : 1.0;
    final rect = Rect.fromCenter(
        center: Offset(limbX, y), width: loopW * scale, height: loopH * 0.96);
    // Back arc (behind the limb — recessed, dark copper).
    canvas.drawArc(rect, -math.pi / 2, math.pi, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = wire * 0.92
          ..strokeCap = StrokeCap.round
          ..color = _copperDark.withValues(alpha: 0.9 * (isNewest ? windT.clamp(0.2, 1.0) : 1.0)));
  }

  // Front arcs (bright copper) over the top — these are what the eye reads as loops.
  for (var i = 0; i < turns; i++) {
    final y = top + loopH * (i + 0.5);
    final isNewest = i == turns - 1;
    final scale = isNewest ? (0.55 + 0.45 * windT) : 1.0;
    final rect = Rect.fromCenter(
        center: Offset(limbX, y), width: loopW * scale, height: loopH * 0.96);
    final a = isNewest ? windT.clamp(0.0, 1.0) : 1.0; // the new loop fades in as it wraps

    // A soft contact shadow under each loop (it sits ON the limb).
    canvas.drawArc(rect.shift(Offset(0, wire * 0.35)), math.pi / 2, math.pi, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = wire * 1.05
          ..strokeCap = StrokeCap.round
          ..color = Colors.black.withValues(alpha: 0.22 * a));

    // The front copper arc — a cylindrical shade across the wire (lit top, dark foot).
    canvas.drawArc(rect, math.pi / 2, math.pi, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = wire
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _copperLite.withValues(alpha: a),
              _copper.withValues(alpha: a),
              _copperDark.withValues(alpha: a),
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(rect));

    // A thin specular sheen riding the upper edge of the wire — the copper highlight.
    final sheenRect = Rect.fromCenter(
        center: rect.center.translate(0, -wire * 0.22),
        width: rect.width, height: rect.height);
    canvas.drawArc(sheenRect, math.pi / 2 + 0.35, math.pi - 0.7, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = sheenW
          ..strokeCap = StrokeCap.round
          ..color = _copperHot.withValues(alpha: 0.7 * a));

    // The newest loop's wrap flourish — a brief additive bloom as it snaps home.
    if (isNewest && windT < 0.999) {
      final bloom = (1 - windT) * windT * 4; // 0→peak→0 across the wrap
      if (bloom > 0.02) {
        canvas.drawArc(rect, math.pi / 2, math.pi, false,
            Paint()
              ..blendMode = BlendMode.plus
              ..style = PaintingStyle.stroke
              ..strokeWidth = wire * 1.4
              ..strokeCap = StrokeCap.round
              ..color = _copperHot.withValues(alpha: 0.5 * bloom.clamp(0.0, 1.0))
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, wire));
      }
    }
  }
}

// ── IN / OUT mono chips — the EXACTLY two live numbers. IN 100 is pinned (alive
//    but constant, micro-shimmer synced to the surge); OUT steps with turns. ─────
class VoltageChipsLayer extends Component {
  VoltageChipsLayer(this.c);
  final TransformerController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    // IN: pinned 100, the FLUX-amber accent (it feeds the field), micro-shimmer in
    // sync with the surges (alive but constant). Its needle is full (held constant).
    _chip(canvas, c.inChip, 'IN', c.inVoltage.round(), _amber,
        shimmer: c.inChipShimmer, intensity: 1.0, reveal: c.lineReveal);
    // OUT: cool-blue accent, steps with turns. Its glow + needle read the SAME frame
    // as each detent (no eased lag) — intensity is OUT/200 (relative, never numbered).
    final outIntensity = (c.outVoltage / TxTune.outVoltageFor(TxTune.maxTurns)).clamp(0.0, 1.0);
    _chip(canvas, c.outChip, 'OUT', c.outVoltage.round(), _blue,
        shimmer: 1.0, intensity: outIntensity, reveal: c.lineReveal);
  }

  void _chip(Canvas canvas, Offset center, String label, int value, Color accent,
      {required double shimmer, required double intensity, required double reveal}) {
    if (reveal < 0.02) return;
    final w = c.stageSize.width;
    final pad = w * 0.022;
    // Measure the value + label (mono, tabular — the instrument digits).
    final valTp = TextPainter(
      text: TextSpan(
        text: '$value',
        style: TextStyle(
          fontFamily: 'monospace',
          fontFeatures: const [FontFeature.tabularFigures()],
          fontSize: w * 0.052,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final labTp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: w * 0.026,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: accent.withValues(alpha: 0.95),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final barH = w * 0.012;
    final chipW = math.max(valTp.width, labTp.width) + pad * 2;
    final chipH = valTp.height + labTp.height + pad * 1.6 + barH + w * 0.012;
    final rect = Rect.fromCenter(center: center, width: chipW, height: chipH);
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(w * 0.02));

    canvas.saveLayer(rect.inflate(w * 0.08), Paint()..color = Colors.white.withValues(alpha: reveal));
    // Value-linked outer glow (recedes vs the hero — capped low, like 2.1–2.5).
    if (intensity > 0.01) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(w * 0.018), Radius.circular(w * 0.028)),
        _glow(accent, w * 0.03, alpha: 0.18 * intensity * shimmer),
      );
    }
    // Dark glass fill + accent border, micro-shimmer on the IN chip.
    canvas.drawRRect(rr, Paint()..color = _c(0xFF0B1026).withValues(alpha: 0.84));
    // Top inner highlight band (the glass catch-light).
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.4),
        Radius.circular(w * 0.02),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.05),
    );
    canvas.drawRRect(rr, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = accent.withValues(alpha: (0.30 + 0.25 * intensity) * shimmer));

    labTp.paint(canvas, Offset(center.dx - labTp.width / 2, rect.top + pad * 0.7));
    valTp.paint(canvas, Offset(center.dx - valTp.width / 2, rect.top + pad * 0.7 + labTp.height));

    // The instrument needle — a thin accent bar, length ∝ value (relative, no number).
    // The OUT needle lands in the SAME frame as a detent (no easing on the value).
    final barW = chipW - pad * 2;
    final barY = rect.bottom - pad * 0.7 - barH;
    final barL = rect.center.dx - barW / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barL, barY, barW, barH), Radius.circular(barH * 0.5)),
      Paint()..color = accent.withValues(alpha: 0.14),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barL, barY, barW * intensity, barH), Radius.circular(barH * 0.5)),
      Paint()
        ..blendMode = BlendMode.plus
        ..color = accent.withValues(alpha: 0.85 * shimmer),
    );
    canvas.restore();
  }
}

// ── The kick + ignition flash — a brief additive bloom at the core/horizon. The
//    pedagogical instant (the cutoff) is NOT here; this only adds drama. ─────────
class FlashLayer extends Component {
  FlashLayer(this.c);
  final TransformerController c;

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty) return;
    final f = c.flashIntensity;
    if (f <= 0.01) return;
    // Anchor: the core (for the slowSurge kick) or the far tower (for ignition).
    final atPylon = c.farPylonLit && !c.isSlowSurge && c.towerApexes.isNotEmpty;
    final at = atPylon ? c.towerApexes.last : c.coreCenter;
    final unit = atPylon ? c.coreOuterW * 0.5 : c.coreOuterW;
    // A soft expanding bloom + a crisp expanding ring (the "it kicked" beat).
    final bloomR = unit * (0.35 + (1 - f) * 0.9);
    canvas.drawCircle(
      at,
      bloomR,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(colors: [
          _amberHot.withValues(alpha: 0.42 * f),
          _amberHot.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: at, radius: bloomR)),
    );
    final ringR = unit * (0.4 + (1 - f) * 0.95);
    canvas.drawCircle(
      at,
      ringR,
      Paint()
        ..blendMode = BlendMode.plus
        ..style = PaintingStyle.stroke
        ..strokeWidth = c.stageSize.width * 0.012 * f
        ..color = _amberHot.withValues(alpha: 0.78 * f)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + 8 * f),
    );
  }
}

class _Mote {
  _Mote(this.x, this.y, this.speed, this.r) : phase = x * 6.28, alpha = 0.5 + r;
  double x, y;
  final double speed;
  final double r;
  final double phase;
  final double alpha;
}

/// A sampled polyline (the sagging output conductor) + its cumulative arc length,
/// so the current can be walked end-to-end across every tower span.
class _Poly {
  _Poly(this.pts, this.cum);
  final List<Offset> pts;
  final List<double> cum;
}
