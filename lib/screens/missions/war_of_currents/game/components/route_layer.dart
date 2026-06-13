// ROUTE LAYER — THE HERO. The long line from the transformer (send end, s=0) to the
// far city (arrival end, s=1) — the brightest, most-alive thing in every run. It is a
// VOLUMINOUS dimensional conductor (the 2.3/2.4 hot-wire craft, ported): a dark edge →
// cool body → cool specular spine so the line reads as a lit cylinder crossing the
// country, never a flat polyline.
//
//   • DC — THE COOK (visceral, heat ∝ I²): as the run progresses the line fills with
//     an EMBER CORE from the send end (saturated #FF7A2E → white-hot), wrapped in a
//     layered additive bloom that WIDENS with heat, a rising HEAT-HAZE shimmer band,
//     cooling-ember speckle, and rising heat MOTES. FAT SLOW warm-gold pulses travel
//     and visibly THIN as their energy leaves as heat. The reach-front stalls (≈0.62)
//     and the FLARE blooms (700ms afterglow), the advance guttering out short of the
//     city. The line stays WHOLE and cooks — it never breaks/melts.
//   • AC — THE SAIL (elegant): a handful of THIN FAST COOL-blue pulses sail the ENTIRE
//     route over a COLD wire — ZERO heat at all times (no glow/shimmer/speckle/motes
//     on the AC line, ever).
//
// All motion comes from the controller (reachFront, pulsePhase, flareIntensity, wire
// heat ∝ (I/100)²). Heat colour #FF7A2E lives ONLY here — never on pulses or chips.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart' show Component;
import 'package:flutter/material.dart';

import '../../config/woc_tuning.dart';
import '../../state/woc_controller.dart';

class RouteLayer extends Component {
  RouteLayer(this.c);
  final WocController c;

  // Cached arclength sampling of the route polyline (rebuilt when the stage size
  // changes) so we can map an s∈[0,1] (from the SEND end) to a point + tangent.
  Size _cachedStage = Size.zero;
  final List<Offset> _samples = []; // dense points, send-end (s=0) → city (s=1)
  final List<double> _cumLen = [];
  double _totalLen = 0;

  void _ensureSamples() {
    if (_cachedStage == c.stageSize && _samples.isNotEmpty) return;
    _cachedStage = c.stageSize;
    _samples.clear();
    _cumLen.clear();
    // routePoints: index 0 = city (s=1), last = transformer (s=0). Reverse so the
    // sample list runs send-end → city (matches reachFront's measurement origin).
    // The wire SAGS as a catenary between consecutive supports (towers/ends) so it
    // reads as a strung wire, not a rigid pipe (activity-3/4 craft).
    final pts = c.routePoints.reversed.toList();
    const perSeg = 28;
    for (var i = 0; i < pts.length - 1; i++) {
      final a = pts[i], b = pts[i + 1];
      final sag = (b - a).distance * WocTune.catenarySagFactor;
      for (var j = 0; j < perSeg; j++) {
        final t = j / perSeg;
        final dip = 4 * sag * t * (1 - t); // 0 at the supports, `sag` at mid (downward)
        _samples.add(Offset.lerp(a, b, t)!.translate(0, dip));
      }
    }
    _samples.add(pts.last);
    _totalLen = 0;
    _cumLen.add(0);
    for (var i = 1; i < _samples.length; i++) {
      _totalLen += (_samples[i] - _samples[i - 1]).distance;
      _cumLen.add(_totalLen);
    }
  }

  /// Point at arclength fraction s (0 = send end, 1 = city).
  Offset _pointAt(double s) {
    if (_samples.isEmpty) return Offset.zero;
    final target = s.clamp(0.0, 1.0) * _totalLen;
    for (var i = 1; i < _cumLen.length; i++) {
      if (_cumLen[i] >= target) {
        final segLen = _cumLen[i] - _cumLen[i - 1];
        final f = segLen <= 0 ? 0.0 : (target - _cumLen[i - 1]) / segLen;
        return Offset.lerp(_samples[i - 1], _samples[i], f)!;
      }
    }
    return _samples.last;
  }

  // The full hero polyline path (always the same drawn geometry — the held-constant).
  // `upTo` is an INDEX fraction (used for the entrance route-draw, matching the
  // shipped base-line reveal). For arclength-accurate stretches use `_routePathS`.
  Path _routePath({double dy = 0, double upTo = 1.0}) {
    final n = _samples.length;
    final lastIdx = (upTo * (n - 1)).clamp(0, n - 1).floor();
    final path = Path();
    if (lastIdx < 0) return path;
    path.moveTo(_samples[0].dx, _samples[0].dy + dy);
    for (var i = 1; i <= lastIdx; i++) {
      path.lineTo(_samples[i].dx, _samples[i].dy + dy);
    }
    return path;
  }

  // The hero polyline from the send end up to ARCLENGTH fraction s (0..1) — so the
  // cooked stretch ends exactly at the reach-front. Densely sampled for smoothness.
  Path _routePathS(double s, {double dy = 0}) {
    final path = Path();
    final end = s.clamp(0.0, 1.0);
    if (end <= 0) return path;
    const n = 48;
    final start = _pointAt(0);
    path.moveTo(start.dx, start.dy + dy);
    for (var i = 1; i <= n; i++) {
      final p = _pointAt(end * i / n);
      path.lineTo(p.dx, p.dy + dy);
    }
    return path;
  }

  @override
  void render(Canvas canvas) {
    if (c.stageSize.isEmpty || c.routeReveal <= 0.01) return;
    _ensureSamples();
    final reveal = c.routeReveal;
    final dim = 1 - c.sceneDim;

    final dc = c.isDcRun;
    final ac = c.isAcRun;
    // The war reveal AND the done close both show the AC-won world (cool pulses keep
    // sailing the cold line — the grid is running).
    final war = c.phase.value == WocPhase.war || c.phase.value == WocPhase.done;
    // Heat ONLY ever lives on the DC line. (criterion 6: AC shows zero glow always.)
    final heat = dc ? c.reachFront.clamp(0.0, 1.0) : 0.0;

    // Small steel pylons straddling the line (the hero reads as a real transmission
    // line). Drawn first so the glowing conductor sits ON the tower tops.
    _drawPylons(canvas, reveal, dim);

    // The dimensional cylinder body — drawn to the entrance-reveal fraction.
    _drawCylinderBody(canvas, reveal, dim, heat);

    final showHero = dc || ac || war;
    if (showHero) {
      if (war || ac) {
        _drawCoolPulses(canvas, dim);
      }
      if (dc) {
        // THE COOK — heat-haze under the embers, then the ember fill, then the
        // pulses thinning, then the flare. The line stays whole and cooks.
        if (heat > 0.02) _drawHeatHaze(canvas, dim, heat);
        _drawWireHeat(canvas, dim);
        _drawWarmPulses(canvas, dim);
        _drawHeatMotes(canvas, dim);
        _drawFlare(canvas, dim);
      }
    }
  }

  // ── The cold, voluminous CYLINDER body (2.3/2.4 craft) — always present ──────
  // A dark edge → cool body → cool specular spine so the hero line reads as a lit
  // conductor crossing the country, not a flat stroke. The drawn geometry is the
  // held-constant; only the DC ember fill (below) changes per run.
  void _drawCylinderBody(Canvas canvas, double reveal, double dim, double heat) {
    final base = c.stageSize.width * WocTune.wireStrokeFactor;
    final path = _routePath(upTo: reveal);
    if (path.getBounds().isEmpty) return;

    // Soft contact under-shadow so the thick line reads seated, not floating.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = base * 1.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.black.withValues(alpha: 0.32 * dim)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, c.stageSize.height * 0.005),
    );
    // dark cylinder edge.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = base
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = WocTune.wireCoolDeep.withValues(alpha: 0.95 * dim),
    );
    // cool body.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = base * 0.74
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = WocTune.wireCool.withValues(alpha: 0.95 * dim),
    );
    // cool specular spine (the cylinder highlight), offset slightly upward; it dims
    // as the DC line heats so the ember core takes over.
    canvas.drawPath(
      _routePath(dy: -base * 0.16, upTo: reveal),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = base * WocTune.cableHighlightFrac * 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = WocTune.wireSpecular.withValues(alpha: (0.30 - 0.18 * heat) * dim)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, base * 0.18),
    );
  }

  // ── Steel pylons along the line (activity-3 craft, mini) — the line is strung
  //    tower-to-tower across the country. Recessive so the conductor stays hero. ──
  void _drawPylons(Canvas canvas, double reveal, double dim) {
    if (reveal <= 0.5) return; // appear once the route is mostly drawn in
    final th = WocTune.pylonHeightFactor * c.stageSize.height;
    // A pylon stands at each INTERMEDIATE support point (the towers the wire is strung
    // between); the city + transformer ends are drawn by their own layers.
    final pts = c.routePoints; // [city, tower2, tower1, transformer]
    for (var i = 1; i < pts.length - 1; i++) {
      _drawPylon(canvas, pts[i], th, dim);
    }
  }

  void _drawPylon(Canvas canvas, Offset apex, double th, double dim) {
    final headHalf = th * 0.14;
    final baseHalf = th * 0.34;
    final legW = math.max(1.0, th * 0.05);
    final braceW = math.max(0.7, th * 0.028);
    final footY = apex.dy + th;
    final hl = Offset(apex.dx - headHalf, apex.dy), hr = Offset(apex.dx + headHalf, apex.dy);
    final fl = Offset(apex.dx - baseHalf, footY), fr = Offset(apex.dx + baseHalf, footY);
    final a = 0.9 * dim;
    Offset onLeg(Offset head, Offset foot, double f) =>
        Offset(head.dx + (foot.dx - head.dx) * f, head.dy + (foot.dy - head.dy) * f);
    // contact haze under the feet.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(apex.dx, footY), width: baseHalf * 2.6, height: baseHalf * 0.5),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.24 * a)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, th * 0.04),
    );
    final brace = Paint()
      ..strokeWidth = braceW
      ..strokeCap = StrokeCap.round
      ..color = WocTune.steelBody.withValues(alpha: 0.92 * a);
    for (var i = 0; i <= 3; i++) {
      final f = i / 3;
      final pl = onLeg(hl, fl, f), pr = onLeg(hr, fr, f);
      canvas.drawLine(pl, pr, brace);
      if (i < 3) {
        canvas.drawLine(pl, onLeg(hr, fr, (i + 1) / 3), brace);
        canvas.drawLine(pr, onLeg(hl, fl, (i + 1) / 3), brace);
      }
    }
    _leg(canvas, hl, fl, legW, a);
    _leg(canvas, hr, fr, legW, a);
  }

  // A cylindrical steel member (dark edge → bright spine → dark edge) + a rim light.
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
            WocTune.steelEdge.withValues(alpha: alpha),
            WocTune.steelSpine.withValues(alpha: alpha),
            WocTune.steelEdge.withValues(alpha: alpha),
          ],
          const [0.0, 0.5, 1.0],
        ),
    );
    const lightUL = Offset(-0.7071, -0.7071);
    final ro = width * 0.34;
    canvas.drawLine(
      a.translate(lightUL.dx * ro, lightUL.dy * ro),
      b.translate(lightUL.dx * ro, lightUL.dy * ro),
      Paint()
        ..strokeWidth = width * 0.3
        ..strokeCap = StrokeCap.round
        ..color = WocTune.steelRim.withValues(alpha: 0.55 * alpha),
    );
  }

  // ── DC wire heat — the EMBER COOK (heat ∝ I², ported from 2.3/2.4) ───────────
  // The line fills with an ember core from the SEND end, wrapped in a layered
  // additive bloom that WIDENS with heat. Heat grows from the send end and fades
  // behind the reach-front (energy leaving as heat). The line stays WHOLE — it cooks.
  void _drawWireHeat(Canvas canvas, double dim) {
    final front = c.reachFront;
    if (front <= 0.001) return;
    final base = c.stageSize.width * WocTune.wireStrokeFactor;
    final h = c.stageSize.height;
    final peak = WocTune.dcHeatPeak; // ∝ (100/100)² = 1

    // Build the cooked stretch path (send end → reach-front), arclength-accurate.
    final cooked = _routePathS(front);
    if (cooked.getBounds().isEmpty) return;

    // The hottest stretch is at the send end → use that to scale the global bloom.
    final hot = (peak * front).clamp(0.0, 1.0);
    final glowWidth = base * (1.0 + WocTune.glowWidenMax * hot);

    // 1) Wide soft outer bloom — the line pouring heat-light into the dark (a
    //    menacing orange wash that widens with the overload).
    canvas.drawPath(
      cooked,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = glowWidth * 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..blendMode = BlendMode.plus
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.016 + h * 0.026 * hot)
        ..color = WocTune.heat.withValues(alpha: (0.20 + 0.55 * hot) * dim),
    );

    // 2) Mid ember band — the heat filling the conductor body. Per-segment so the
    // glow saturates near the send end and falls off behind the front (∝ I² read).
    const samples = 44;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.004);
    for (var i = 0; i < samples; i++) {
      final s = i / samples;
      if (s > front) break;
      // Heat grows from the SEND end (s=0 hottest) and fades toward the front.
      final fromFront = front - s;
      final falloff = (1 - fromFront / WocTune.dcHeatFalloff).clamp(0.0, 1.0);
      final nearSend = (1 - s * 0.30); // hotter near the send end (whole stretch glows)
      final hk = (peak * nearSend * (0.65 + 0.35 * falloff)).clamp(0.0, 1.0);
      if (hk <= 0.02) continue;
      final a = _pointAt(s);
      final b = _pointAt((s + 1 / samples).clamp(0.0, front));
      final shimmer =
          c.reducedMotion ? 1.0 : (0.84 + 0.16 * math.sin(c.pulsePhase * 9 + s * 22));
      // RED at the send end (hottest, falloff→0) → orange toward the front. Saturated,
      // never washing to gold/white (the menace must read as overheating, not "bright").
      final col = Color.lerp(WocTune.heatDeep, WocTune.heat, 0.15 + 0.6 * falloff)!;
      canvas.drawLine(
        a,
        b,
        glow
          ..strokeWidth = base * (1.05 + 0.78 * hk)
          ..color = col.withValues(alpha: 0.74 * hk * shimmer * dim),
      );
    }

    // 3) Hot ember core spine — orange → RED-hot at the send end (a glowing, swollen
    // overloaded conductor). A whisper of white sits ONLY at the very hottest tip.
    final whiteHot = ((hot - 0.45) / 0.55).clamp(0.0, 1.0);
    final coreCol = Color.lerp(WocTune.heat, WocTune.heatDeep, 0.45 + 0.55 * whiteHot)!;
    final innerEnd = math.min(front, 0.72);
    final inner = _routePathS(innerEnd);
    canvas.drawPath(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = base * (0.55 + 0.44 * hot)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..blendMode = BlendMode.plus
        ..color = coreCol.withValues(alpha: (0.40 + 0.50 * hot) * dim),
    );
    // A small white-hot tip only at the very send end (the worst of the overload).
    final tip = _routePathS(math.min(front, 0.16));
    canvas.drawPath(
      tip,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = base * (0.30 + 0.22 * hot)
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.plus
        ..color = WocTune.heatHot.withValues(alpha: 0.5 * hot * dim),
    );

    // 4) Cooling-ember speckle along the cooked stretch — the glow breaking into
    // embers (it never snaps to black, it cooks as embers). Deterministically seeded.
    _drawEmberSpeckle(canvas, dim, front, hot, coreCol, base);
  }

  // Cooling-ember speckle — small bright cores reading as the glow breaking up into
  // embers as the line cooks. Density/brightness ride heat. (Ported from 2.3/2.4.)
  void _drawEmberSpeckle(
      Canvas canvas, double dim, double front, double hot, Color coreCol, double base) {
    final coolBand = (1.0 - (hot - 0.55).clamp(0.0, 0.45) / 0.45) * hot;
    if (coolBand <= 0.02) return;
    final n = (8 + 12 * coolBand).round();
    final paint = Paint()..blendMode = BlendMode.plus;
    final rng = math.Random(91);
    for (var i = 0; i < n; i++) {
      final s = 0.02 + (front - 0.02).clamp(0.0, 1.0) * rng.nextDouble();
      final p = _pointAt(s);
      final jitter = Offset(
        (rng.nextDouble() - 0.5) * base * 0.6,
        (rng.nextDouble() - 0.5) * base * 0.6,
      );
      final flick = 0.55 + 0.45 * rng.nextDouble();
      canvas.drawCircle(
        p + jitter,
        base * (0.16 + 0.18 * rng.nextDouble()),
        paint..color = coreCol.withValues(alpha: 0.5 * coolBand * flick * dim),
      );
    }
  }

  // ── DC heat-haze shimmer band — rising refraction above the cooking stretch ──
  // A stack of translucent wavy warm bands above the cooked stretch, blurred + sine-
  // displaced so it reads as rising heat-shimmer. Warm-on-dark, never fire. Under
  // reduced motion the bands hold static but still read as a faint warm haze.
  void _drawHeatHaze(Canvas canvas, double dim, double heat) {
    final h = c.stageSize.height;
    final w = c.stageSize.width;
    final front = c.reachFront;
    if (front <= 0.02) return;
    final t = heat.clamp(0.0, 1.0);
    final scroll = c.reducedMotion ? 0.0 : c.pulsePhase * 0.4;
    final waveLen = WocTune.hazeWaveLenF * w;
    final amp = WocTune.hazeWaveAmpF * h;
    final rise = WocTune.hazeRiseF * h;
    const steps = 26;
    for (var b = 0; b < WocTune.hazeBands; b++) {
      final bf = (b + 1) / WocTune.hazeBands; // how high this band floats
      final bandAlpha = WocTune.hazeBaseAlpha * t * (1.0 - 0.55 * bf);
      if (bandAlpha <= 0.004) continue;
      final path = Path();
      for (var i = 0; i <= steps; i++) {
        final st = (i / steps) * front; // only above the cooked stretch
        final pt = _pointAt(st);
        final phase = (pt.dx / waveLen) - scroll + bf * 1.7;
        final dx = math.sin(phase * math.pi * 2) * amp * (0.6 + 0.8 * bf);
        final dy = -rise * bf - amp * 0.4 * math.cos(phase * math.pi * 2);
        final p = Offset(pt.dx + dx, pt.dy + dy);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      final col = Color.lerp(WocTune.heat, WocTune.pulseWarm, 0.35 + 0.5 * bf)!;
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * (0.016 + 0.018 * bf)
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * (0.012 + 0.014 * bf))
          ..color = col.withValues(alpha: bandAlpha * dim),
      );
    }
  }

  // ── Rising heat MOTES off the hottest stretch (the loss, made seeable) ───────
  void _drawHeatMotes(Canvas canvas, double dim) {
    if (c.reducedMotion) return; // calm under reduced motion
    final front = c.reachFront;
    if (front <= 0.02) return;
    final h = c.stageSize.height;
    final mote = Paint()..blendMode = BlendMode.plus;
    final n = WocTune.heatMoteCount;
    for (var i = 0; i < n; i++) {
      final s = (i / n) * front * 0.75; // off the hottest (send-end) stretch
      final base = _pointAt(s);
      final rise = (c.pulsePhase * 0.6 + i * 0.37) % 1.0;
      final y = base.dy - rise * h * 0.055;
      final a = (1 - rise) * 0.34 * dim;
      if (a <= 0.005) continue;
      // hotter (younger) motes are orange, cooling-warm as they rise.
      final col = Color.lerp(WocTune.heat, WocTune.pulseWarm, rise)!;
      canvas.drawCircle(
        Offset(base.dx + math.sin(rise * 6 + i) * 4, y),
        2.4 * (1 - rise * 0.5),
        mote
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0)
          ..color = col.withValues(alpha: a),
      );
    }
  }

  // ── DC warm pulses — FAT, SLOW, thinning with distance (energy leaving as heat) ─
  // KILLED past the reach-front (no pulse crosses where the line cooked out).
  void _drawWarmPulses(Canvas canvas, double dim) {
    final front = c.reachFront;
    if (front <= 0.001) return;
    final w = c.stageSize.width;
    final n = WocTune.dcPulseCount;
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    for (var i = 0; i < n; i++) {
      final phase = (c.pulsePhase * WocTune.dcPulseSpeed + i / n) % 1.0;
      final s = phase * front; // pulses only travel up to the reach-front
      if (s > front) continue;
      // energy remaining falls with distance from the send end → the pulse THINS.
      final energyLeft = (1 - s / math.max(front, 0.01)).clamp(0.0, 1.0);
      final p = _pointAt(s);
      final thick = WocTune.dcPulseThickness * (0.32 + 0.68 * energyLeft);
      final a = (0.55 + 0.4 * energyLeft) * dim;
      // soft warm halo
      canvas.drawCircle(
        p,
        w * 0.018 * thick * 1.4,
        paint..color = WocTune.pulseWarm.withValues(alpha: 0.32 * a),
      );
      // warm body
      canvas.drawCircle(
        p,
        w * 0.016 * thick,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = WocTune.pulseWarm.withValues(alpha: a),
      );
      // hot centre
      canvas.drawCircle(
        p,
        w * 0.008 * thick,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = WocTune.pulseWarmCore.withValues(alpha: a),
      );
    }
  }

  // ── AC cool pulses — THIN, FAST, FEW; sail the FULL route over a COLD wire ────
  // No heat, no haze, no speckle — the AC line is stone-cold (criterion 6).
  void _drawCoolPulses(Canvas canvas, double dim) {
    final front = c.reachFront;
    if (front <= 0.001) return;
    final w = c.stageSize.width;
    final n = WocTune.acPulseCount;
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (var i = 0; i < n; i++) {
      final phase = (c.pulsePhase * WocTune.acPulseSpeed + i / n) % 1.0;
      final s = phase * front;
      final p = _pointAt(s);
      final thick = WocTune.acPulseThickness;
      // cool halo
      canvas.drawCircle(
        p,
        w * 0.013 * thick * 1.6,
        paint..color = WocTune.pulseCool.withValues(alpha: 0.55 * dim),
      );
      // cold centre
      canvas.drawCircle(
        p,
        w * 0.006 * thick,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = WocTune.pulseCoolCore.withValues(alpha: 0.78 * dim),
      );
    }
  }

  // ── The DC failure FLARE — a white-hot bloom at s≈0.45 (700ms envelope) ──────
  // The line stays WHOLE (it cooks, it does not break). Reduced motion: a brief
  // glow step (the controller already snaps the envelope to a step).
  void _drawFlare(Canvas canvas, double dim) {
    final f = c.flareIntensity;
    if (f <= 0.01) return;
    final at = _pointAt(WocTune.dcFlareS);
    final w = c.stageSize.width;
    final r = w * (0.07 + 0.12 * f);
    final shader = ui.Gradient.radial(at, r, [
      WocTune.heatHot.withValues(alpha: 0.95 * f * dim),
      WocTune.heat.withValues(alpha: 0.55 * f * dim),
      WocTune.heat.withValues(alpha: 0.0),
    ], const [0.0, 0.42, 1.0]);
    canvas.drawCircle(
      at,
      r,
      Paint()
        ..shader = shader
        ..blendMode = BlendMode.plus,
    );
    // A bright white-hot core dot.
    canvas.drawCircle(
      at,
      w * 0.020 * f,
      Paint()
        ..blendMode = BlendMode.plus
        ..color = WocTune.heatHot.withValues(alpha: f * dim),
    );
    // A short hot-wash along the cooked stretch at peak (the whole line flashes hot).
    if (f > 0.4) {
      final wash = _routePathS(WocTune.dcStallS);
      canvas.drawPath(
        wash,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * WocTune.wireStrokeFactor * (2.4 + 3.0 * f)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..blendMode = BlendMode.plus
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, c.stageSize.height * 0.02 * f)
          ..color = WocTune.heat.withValues(alpha: 0.30 * f * dim),
      );
    }
  }
}
