// The pure renderer for "Shape the Wire". Reads ONLY controller getters; owns no
// state. Paint order back→front (PRD §15):
//   focus well → motes → return path (faint) → source rail + locked dial + pin →
//   HERO CABLE (dimensional cylindrical conductor + 2.1-style current river with
//   trails + cool tension flourish + RESISTANCE specimen) → clamp grip handle →
//   secondary lamp (shared paintBulb) → chips (locked VOLTAGE / instrument CURRENT)
//   → cool choke ring / fat surge → the in-place arm-thick-cable PAYOFF.
//
// THE HERO is the cable + the current inside it — the brightest, most alive thing
// on screen (#FFD27A core + #FFF1D6 hot centre, BlendMode.plus). The cable BODY is
// cool metal and NEVER warms/reddens at any morphT (acceptance §8: no heat). The
// choke reads as fewer/slower/dimmer packets + a cool pinch, never temperature.
//
// CRAFT PORTED FROM 2.1 (vc_stage_painter): the current-river (trails + density +
// lanes + warm core/hot centre/soft halo), the instrument current gauge
// (value-glow + accent needle + trend), and the cool-only conductive read.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../hand_crank_lamp/widgets/bulb.dart';
import '../config/resistance_beats.dart';
import '../config/resistance_tuning.dart';
import '../state/flow_particles.dart';
import '../state/resistance_controller.dart';

class ResistanceStagePainter extends CustomPainter {
  ResistanceStagePainter(this.c) : super(repaint: c);

  final ResistanceController c;

  late Size _s;
  Offset _xy(double fx, double fy) => Offset(fx * _s.width, fy * _s.height);

  @override
  void paint(Canvas canvas, Size size) {
    _s = size;

    // The lab is fully visible until the landing swells the cable in place. Chrome
    // and lamp fade to 12% as landingBlend → 1 (PRD §6 B5).
    final labAlpha = 1.0 - c.landingBlend * (1.0 - RTune.landingDimAlpha);

    _paintFocusWell(canvas);
    _paintMotes(canvas);

    final geo = _WireGeo.from(c, size);
    final loop = _LoopGeo.from(geo, _s);

    canvas.saveLayer(Offset.zero & size, Paint()..color = Colors.white.withValues(alpha: labAlpha));
    _paintLoopWires(canvas, loop);   // the thin steel circuit (leads/bottom/return/top)
    _paintSource(canvas, c.sourceReveal); // the VOLTAGE source module (battery) + pin
    _paintWire(canvas, geo);         // the fat morphable STEEL hero cable
    _paintLoopRiver(canvas, loop, geo); // discrete warm beads flowing around the WHOLE loop
    _paintGrabHandle(canvas, geo);
    _paintLamp(canvas, geo);         // the bulb — glows from the current reaching it
    _paintChokeRing(canvas, geo);
    canvas.restore();

    // Chips ride above the lab dim so the two live numbers stay readable until
    // the landing fully takes over.
    canvas.saveLayer(Offset.zero & size, Paint()..color = Colors.white.withValues(alpha: labAlpha));
    _paintChips(canvas, geo);
    canvas.restore();

    // The naming specimen sits at full strength (fades back as the landing swells).
    _paintResistanceSpecimen(canvas, geo);
    // THE PAYOFF — a bold, straight, VERTICAL arm-thick cable grows in (fixed
    // geometry; the forearm ghost + label come with it).
    if (c.landingBlend > 0.001) _paintLandingScale(canvas);
  }

  // ── Focus well: a real POOL OF LIGHT behind the hero ──────────────────────
  void _paintFocusWell(Canvas canvas) {
    // A soft cool pool so the cable sits on a lit stage, not pure black — cool +
    // low alpha so the warm river still wins the brightness.
    final pool = _xy(0.5, 0.5);
    canvas.drawCircle(
      pool,
      _s.width * 0.72,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            RTune.controlCool.withValues(alpha: 0.055),
            const Color(0x00000000),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: pool, radius: _s.width * 0.72)),
    );
    // A faint dark seat just under the cable column so the cool rim reads.
    final seat = _xy(0.5, 0.54);
    canvas.drawCircle(
      seat,
      _s.width * 0.42,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0x4A060A1A), Colors.transparent],
        ).createShader(Rect.fromCircle(center: seat, radius: _s.width * 0.42)),
    );
  }

  // ── Ambient motes: ≤20 quiet cool dust specks drifting behind the hero ─────
  void _paintMotes(Canvas canvas) {
    final reveal = c.sourceReveal; // fade in with the scene
    if (reveal <= 0.02) return;
    final p = Paint()..color = const Color(0xFF8FA6FF);
    for (final m in c.flow.motes) {
      final pos = Offset(m.x * _s.width, m.y * _s.height);
      p.color = const Color(0xFF8FA6FF).withValues(alpha: 0.06 * reveal);
      canvas.drawCircle(pos, m.r, p);
    }
  }

  // ── The thin steel CIRCUIT WIRES (everything except the fat hero body) ──────
  // The leads from the source, the lap under the bulb, the return run up the right,
  // and the top run back to the source — drawn as one continuous tubular steel
  // conductor so the loop reads as a real, closed circuit. The fat hero cable is
  // painted on top of its segment by _paintWire.
  void _paintLoopWires(Canvas canvas, _LoopGeo loop) {
    final reveal = c.wireReveal.clamp(0.0, 1.0);
    if (reveal <= 0.02) return;
    final path = Path()..moveTo(loop.pts.first.dx, loop.pts.first.dy);
    for (var i = 1; i <= loop.wireEndIdx; i++) {
      path.lineTo(loop.pts[i].dx, loop.pts[i].dy); // up to the − terminal (no wire under the battery)
    }
    final w = RTune.thinWireWidthFactor * _s.width;
    // soft contact shadow so the wires sit on the stage.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 1.6
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.black.withValues(alpha: 0.28 * reveal)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // dark steel underbody
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = RTune.steelEdge.withValues(alpha: reveal),
    );
    // steel body
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.74
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = RTune.steelMid.withValues(alpha: reveal),
    );
    // bright centreline highlight (the lit top of the round wire)
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.30
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = RTune.steelLite.withValues(alpha: 0.85 * reveal),
    );
  }

  // ── The VOLTAGE SOURCE module — the pinned "battery" wired into the loop ─────
  // A glossy cyan source: "VOLTAGE 100" lives ON it (no separate chip), its two
  // terminals join the loop wires (current leaves one post, returns to the other),
  // and the gold PIN clamped in its lock seat = the voltage is pinned (tapping it
  // refuses). It is unmistakably the source — not a meter.
  Rect _sourceRect() {
    final cx = RTune.sourceX * _s.width;
    final cy = RTune.sourceBarY * _s.height;
    final w = RTune.sourceWidthFactor * _s.width;
    final h = RTune.sourceHeightFactor * _s.height;
    final shake = c.pinDenyShake > 0
        ? math.sin(c.pinDenyShake * math.pi * 7) * c.pinDenyShake * 6.0
        : 0.0;
    return Rect.fromCenter(center: Offset(cx + shake, cy), width: w, height: h);
  }

  Offset _sourceLockSpot() {
    final r = _sourceRect();
    return Offset(r.right - r.height * 0.55, r.center.dy);
  }

  void _paintSource(Canvas canvas, double reveal) {
    if (reveal <= 0.01) return;
    final rect = _sourceRect();
    final glint = c.pinFlight >= 1.0 ? c.pinDenyShake : 0.0;
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(rect.height * 0.28));
    final unit = rect.height;

    // the two battery TERMINALS where the loop wires connect.
    final postW = rect.height * 0.22;
    for (final px in [rect.left, rect.right]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(px, rect.center.dy), width: postW * 2, height: rect.height * 0.42),
          Radius.circular(postW * 0.5)),
        Paint()..color = RTune.steelRim.withValues(alpha: reveal),
      );
    }

    // a deny LOCK-PULSE — refuses input (the pinned voltage cannot change).
    if (glint > 0.01) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            rect.inflate(rect.height * (0.10 + 0.5 * (1 - glint))), Radius.circular(rect.height)),
        Paint()
          ..blendMode = BlendMode.plus
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 + 3 * glint
          ..color = RTune.controlCoolLite.withValues(alpha: 0.5 * glint)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
    // soft cool seat glow.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(rect.height * 0.3), Radius.circular(rect.height)),
      Paint()
        ..blendMode = BlendMode.plus
        ..color = RTune.controlCool.withValues(alpha: 0.09 * reveal)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rect.height * 0.5),
    );
    // drop shadow.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          rect.shift(Offset(0, rect.height * 0.12)), Radius.circular(rect.height * 0.28)),
      Paint()
        ..color = const Color(0xFF03060F).withValues(alpha: 0.5 * reveal)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rect.height * 0.2),
    );
    // glossy cyan body (the source/control — the 2.1 cyan).
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [RTune.pistonTop, RTune.pistonHi, RTune.pistonMid, RTune.pistonDeep],
          stops: const [0.0, 0.32, 0.72, 1.0],
        ).createShader(rect),
    );
    // top specular band.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left + rect.width * 0.05, rect.top + rect.height * 0.12,
            rect.width * 0.9, rect.height * 0.30),
        Radius.circular(rect.height * 0.2),
      ),
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0.5 * reveal), Colors.white.withValues(alpha: 0)],
        ).createShader(rect),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = RTune.controlCoolLite.withValues(alpha: (0.7 + 0.3 * glint) * reveal),
    );

    // "VOLTAGE" label + "100" value on the LEFT; the pin lock seat on the RIGHT.
    final labelTp = _text(RCopy.voltageChip, unit * 0.24, FontWeight.w700,
        const Color(0xFF08233B).withValues(alpha: 0.85 * reveal), mono: true, ls: 1.6);
    final valTp = _text('100', unit * 0.5, FontWeight.w800,
        Colors.white.withValues(alpha: 0.98 * reveal), mono: true, ls: 0.5);
    final textLeft = rect.left + rect.width * 0.12;
    labelTp.paint(canvas, Offset(textLeft, rect.center.dy - unit * 0.36));
    valTp.paint(canvas, Offset(textLeft, rect.center.dy - unit * 0.05));

    // the lock SEAT (where the pin clamps) on the right.
    final lock = _sourceLockSpot();
    canvas.drawCircle(lock, unit * 0.30, Paint()..color = RTune.pistonDeep.withValues(alpha: 0.55 * reveal));
    canvas.drawCircle(
      lock,
      unit * 0.30,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = RTune.controlCoolLite.withValues(alpha: 0.5 * reveal),
    );

    // The PIN — flies from the wire's mid (its 2.1 home) and clamps into the seat.
    _paintPin(canvas, lock, unit * 0.42);
  }


  void _paintPin(Canvas canvas, Offset dialC, double dialR) {
    final t = c.pinFlight.clamp(0.0, 1.0);
    // Start point: on the mid wire (its 2.1 home), end: on the dial.
    final wireMid = _xy(RTune.heroCenterX, 0.45);
    Offset pos;
    double alpha;
    if (c.reducedMotion) {
      // Fade-out at wire, fade-in at dial — no flight arc.
      if (t < 0.5) {
        pos = wireMid;
        alpha = 1 - t * 2;
      } else {
        pos = dialC;
        alpha = (t - 0.5) * 2;
      }
    } else {
      // A punchier arc from wire → dial: ease-in-out flight, a taller arc, and a
      // motion trail behind the head so the move reads cinematic (P1.6).
      final te = Curves.easeInOutCubic.transform(t);
      final mid = Offset((wireMid.dx + dialC.dx) / 2,
          math.min(wireMid.dy, dialC.dy) - _s.height * 0.085);
      pos = _quad(wireMid, mid, dialC, te);
      alpha = 1.0;
      // trail samples behind the flight head (faded), only mid-flight.
      if (t > 0.04 && t < 0.97) {
        for (var k = 1; k <= 4; k++) {
          final tp = (te - k * 0.06).clamp(0.0, 1.0);
          final pp = _quad(wireMid, mid, dialC, tp);
          canvas.drawCircle(
            pp,
            dialR * 0.74 * 0.5 * (1 - k / 5),
            Paint()
              ..blendMode = BlendMode.plus
              ..color = RTune.goldPin.withValues(alpha: 0.18 * (1 - k / 5))
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3),
          );
        }
      }
    }
    final glint = c.pinFlight >= 1.0 ? c.pinDenyShake : 0.0;
    // a clamp snap-flare the instant the pin lands.
    _drawPinGlyph(canvas, pos, dialR * 0.74, alpha, glint);
  }

  void _drawPinGlyph(Canvas canvas, Offset p, double r, double alpha, double glint) {
    if (alpha <= 0.01) return;
    final gold = RTune.goldPin;
    // glow
    canvas.drawCircle(
      p,
      r * (1.4 + glint * 0.8),
      Paint()
        ..blendMode = BlendMode.plus
        ..color = gold.withValues(alpha: (0.30 + glint * 0.4) * alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.6),
    );
    // pin head (a rounded clamp)
    canvas.drawCircle(p, r * 0.62, Paint()..color = gold.withValues(alpha: alpha));
    canvas.drawCircle(
      p,
      r * 0.62,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFFFF0C4).withValues(alpha: 0.9 * alpha),
    );
    // a small clamp tail pointing down into the dial
    final tail = Path()
      ..moveTo(p.dx - r * 0.28, p.dy + r * 0.2)
      ..lineTo(p.dx, p.dy + r * 0.95)
      ..lineTo(p.dx + r * 0.28, p.dy + r * 0.2);
    canvas.drawPath(tail, Paint()..color = gold.withValues(alpha: alpha));
    // specular dot
    canvas.drawCircle(
      p.translate(-r * 0.2, -r * 0.22),
      r * 0.16,
      Paint()..color = Colors.white.withValues(alpha: 0.85 * alpha),
    );
  }

  // ── THE HERO CABLE: a fat morphable POLISHED-STEEL conductor (the variable run
  //    of the circuit). The warm current beads ride ON it (drawn loop-wide by
  //    _paintLoopRiver) — the steel itself stays cool and never warms.
  void _paintWire(Canvas canvas, _WireGeo geo) {
    final reveal = c.wireReveal;
    if (reveal <= 0.01) return;
    // P2.9: at landing the body swells in place (handled in _paintLandingScale)
    // — so once the swell is well underway the morph body recedes to it.
    final bodyA = reveal * (1.0 - (c.landingBlend - 0.15).clamp(0.0, 1.0) / 0.85);

    // P1.7 entrance: the cable MATERIALIZES hanging from its top terminal.
    final materializing = reveal < 0.999 && !c.reducedMotion;
    if (materializing) {
      canvas.save();
      final dropTo = geo.topY + geo.length * Curves.easeOut.transform(reveal);
      canvas.clipRect(Rect.fromLTRB(0, 0, _s.width, dropTo + geo.halfWidthBase + 2));
    }

    final body = geo.bodyPath();

    // soft contact shadow under the body to seat it (the cable casts onto the lab).
    canvas.drawPath(
      body,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.42 * bodyA)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    if (bodyA > 0.01) {
      _paintSteelBody(canvas, geo, body, bodyA);
    }

    // a subtle COOL rim glow that scales with current — the conductor reads
    // "energised" without ever warming (the warm beads carry the heat-free glow).
    final live = (c.currentNorm / 4.0).clamp(0.0, 1.0);
    canvas.drawPath(
      body,
      Paint()
        ..blendMode = BlendMode.plus
        ..style = PaintingStyle.stroke
        ..strokeWidth = geo.bloomWidth
        ..color = RTune.steelRim.withValues(alpha: (0.03 + 0.06 * live) * reveal)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, geo.bloomWidth * 0.9),
    );

    // The COOL tension flourish on the taut (thin) cable — purely visual.
    _paintTensionSheen(canvas, geo, reveal);

    if (materializing) canvas.restore();
  }

  // Polished STEEL cylinder shading (the hand_crank_lamp prologue look): dark steel
  // edges → a bright steel highlight band biased left (lit upper-left) → dark edges;
  // a crisp rim. A real metal cable, COOL at every morphT (no warm/red, no heat).
  void _paintSteelBody(Canvas canvas, _WireGeo geo, Path body, double a) {
    final bounds = body.getBounds();
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            RTune.steelEdge.withValues(alpha: a),
            RTune.steelMid.withValues(alpha: a),
            RTune.steelLite.withValues(alpha: a),
            RTune.steelMid.withValues(alpha: a),
            RTune.steelEdge.withValues(alpha: a),
          ],
          stops: const [0.0, 0.32, 0.45, 0.62, 1.0],
        ).createShader(bounds),
    );
    // a tight bright specular streak left of centre (sells the polished cylinder).
    final streak = geo.specularStreakPath();
    canvas.drawPath(
      streak,
      Paint()
        ..blendMode = BlendMode.plus
        ..color = RTune.steelRim.withValues(alpha: 0.42 * a)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, geo.halfWidthBase * 0.30 + 1),
    );
    // crisp rim along the rounded edges.
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = RTune.steelRim.withValues(alpha: 0.55 * a),
    );
  }

  // ── THE CURRENT, MADE VISIBLE — discrete warm beads flowing around the WHOLE
  //    loop (source → down the steel hero → through the bulb → up the return →
  //    back to the source). Density / speed / lane-spread ∝ current: thin = a slow
  //    single-file trickle, fat = a fast multi-lane stream. The beads are the ONLY
  //    warm thing (the steel stays cool — no heat). The visible MOVEMENT is the
  //    lesson — you watch the same current travel the circuit and light the bulb.
  void _paintLoopRiver(Canvas canvas, _LoopGeo loop, _WireGeo geo) {
    final reveal = c.wireReveal;
    if (reveal <= 0.02) return;
    final fat = c.fatShimmer;
    final choke = c.discoveryFlash;
    final trail = c.reducedMotion ? 1 : RTune.loopTrailSamples;
    final halo = Paint()..blendMode = BlendMode.plus;
    final core = Paint()..blendMode = BlendMode.plus;
    final laneScale = (geo.lanesAllowed - 1).clamp(0, 3).toDouble();
    final flowLum = 0.62 + 0.38 * (c.currentNorm / 4.0).clamp(0.0, 1.0);
    final hsT = loop.heroStartT, heT = loop.heroEndT;
    final beadThin = RTune.beadThinRFactor * _s.width;

    for (var i = 0; i < c.flow.activeCount; i++) {
      final FlowPacket p = c.flow.packets[i];
      for (var sIdx = trail - 1; sIdx >= 0; sIdx--) {
        final t = (((p.u - sIdx * RTune.loopTrailSpacing) % 1.0) + 1.0) % 1.0;
        if (t > loop.visibleEndT) continue; // the bead is inside the battery — hidden
        Offset pos;
        double baseR;
        if (t >= hsT && t <= heT) {
          // inside the fat hero — ride within the cable width (lanes). The bead is a
          // FIXED small dot (only shrunk if the cable is too thin to hold it) so the
          // fat cable shows MANY discrete dots across its lanes, never a white blur.
          final uu = ((t - hsT) / (heT - hsT)).clamp(0.0, 1.0);
          final pt = geo.pointAt(uu);
          final hw = geo.halfWidthAt(uu);
          final laneMul = (0.55 + 0.12 * laneScale) * (1.0 - choke * 0.55);
          final off = p.lane * hw * RTune.riverLaneSpread * laneMul;
          pos = pt + geo.normalAt(uu) * off;
          baseR = math.min(beadThin * (0.95 + 0.3 * p.size), hw * 0.85);
        } else {
          // single-file along the thin steel wire (leads / bottom / return / top).
          pos = loop.at(t);
          baseR = beadThin * (0.85 + 0.3 * p.size);
        }
        final fade = trail == 1 ? 1.0 : 1.0 - sIdx / trail; // head bright, tail faint
        final rr = baseR * (0.7 + 0.3 * fade) * (1.0 - choke * 0.30) * (1.0 + fat * 0.25);
        final tw = 0.6 + 0.4 * math.sin((p.u + p.seed) * math.pi * 2 + c.flowPhase * 2);
        final a = (0.55 + 0.45 * tw) * fade * reveal * flowLum;

        // a MODEST warm halo (discrete dot, never an additive white-out blanket)
        halo.color = RTune.energyGlow.withValues(alpha: 0.38 * a);
        halo.maskFilter = MaskFilter.blur(BlurStyle.normal, rr * 1.3);
        canvas.drawCircle(pos, rr * 1.7, halo);

        if (sIdx == 0) {
          // the head — a bright warm core + a hot centre (the discrete bead).
          core.maskFilter = null;
          core.color = RTune.energy.withValues(alpha: 0.95 * a);
          canvas.drawCircle(pos, rr * 1.05, core);
          core.color = RTune.energyHot.withValues(alpha: 0.95 * a);
          canvas.drawCircle(pos, rr * 0.55, core);
        }
      }
    }
  }

  // ── The COOL elastic-tension sheen on the taut (thin) cable (P1.4) ──────────
  // Purely a render flourish — NO warm tint, NO morph easing, NO spring-back. A
  // faint cool specular strain band that brightens as the cable stretches taut.
  void _paintTensionSheen(Canvas canvas, _WireGeo geo, double reveal) {
    final t = ((c.morphT - RTune.tensionOnset) / (1 - RTune.tensionOnset)).clamp(0.0, 1.0);
    if (t <= 0.01 || c.reducedMotion) {
      // reduced motion still gets a faint static strain hint when fully taut.
      if (t > 0.5 && c.reducedMotion) {
        _strainBand(canvas, geo, RTune.tensionSheenAlpha * 0.5 * reveal);
      }
      return;
    }
    // a slow travelling shimmer makes the strain read alive without heat.
    final shimmer = 0.7 + 0.3 * math.sin(c.flowPhase * 1.8);
    _strainBand(canvas, geo, RTune.tensionSheenAlpha * t * shimmer * reveal);
  }

  void _strainBand(Canvas canvas, _WireGeo geo, double alpha) {
    if (alpha <= 0.01) return;
    final p = Path();
    const steps = 24;
    for (var i = 0; i <= steps; i++) {
      final u = i / steps;
      final pt = geo.pointAt(u);
      final n = geo.normalAt(u);
      // a thin band riding slightly right of the specular centre.
      final pos = pt + n * geo.halfWidthAt(u) * 0.22;
      if (i == 0) {
        p.moveTo(pos.dx, pos.dy);
      } else {
        p.lineTo(pos.dx, pos.dy);
      }
    }
    canvas.drawPath(
      p,
      Paint()
        ..blendMode = BlendMode.plus
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, geo.halfWidthBase * 0.5)
        ..strokeCap = StrokeCap.round
        ..color = RTune.tensionCool.withValues(alpha: alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, geo.halfWidthBase * 0.4 + 1),
    );
  }

  // ── The tactile TERMINAL CLAMP grip at the cable's lower end (P0.3) ─────────
  // A real dimensional grip the finger pulls; the cable stretches taut under it.
  // Up/down hint chevrons show only until the first drag. The forgiving hit-test
  // (whole lower region) is unchanged — this is the clear visual affordance.
  void _paintGrabHandle(Canvas canvas, _WireGeo geo) {
    final phase = c.phase.value;
    // Hide once we leave the interactive band (landing/synthesis/done) and before
    // input ever unlocks (intro/pinMove). Visible across stretch…naming.
    if (phase.index < RPhase.stretch.index || phase.index >= RPhase.landing.index) {
      return;
    }
    final live = c.inputEnabled;
    final reveal = c.wireReveal;
    if (reveal <= 0.02) return;

    final anchor = geo.pointAt(RTune.handleAnchorU);
    final w = RTune.handleWidthFactor * _s.width;
    final h = RTune.handleHeightFactor * _s.height;
    // the clamp sits just under the cable end, gripping it.
    final center = anchor.translate(0, h * 0.32);
    final rect = Rect.fromCenter(center: center, width: w, height: h);
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(h * 0.34));

    final hasDragged = c.morphT != RTune.morphStart || phase.index > RPhase.stretch.index;
    final pulse = c.reducedMotion ? 0.5 : (0.5 + 0.5 * math.sin(c.flowPhase * 3.0));

    // a soft cool grab glow under the clamp (reads as the live pull point).
    if (live) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(h * 0.5), Radius.circular(h)),
        Paint()
          ..blendMode = BlendMode.plus
          ..color = RTune.tensionCool.withValues(alpha: (0.10 + 0.10 * pulse) * reveal)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.7),
      );
    }

    // the two grip jaws clasping the cable above the body.
    final jawW = w * 0.92;
    final jaw = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center.translate(0, -h * 0.52), width: jawW, height: h * 0.34),
      Radius.circular(h * 0.16),
    );
    canvas.drawRRect(
      jaw,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF6FB6E0).withValues(alpha: reveal),
            const Color(0xFF2E5A86).withValues(alpha: reveal),
          ],
        ).createShader(jaw.outerRect),
    );

    // the clamp body — a beveled cyan-steel grip the finger pulls (the control).
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF8FD0F4).withValues(alpha: reveal),
            const Color(0xFF35608C).withValues(alpha: reveal),
          ],
        ).createShader(rect),
    );
    // top highlight band (so it reads dimensional).
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left + w * 0.08, rect.top + h * 0.14, w * 0.84, h * 0.26),
        Radius.circular(h * 0.18),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.4 * reveal),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = RTune.controlCoolLite.withValues(alpha: 0.7 * reveal),
    );
    // grip ridges
    final grip = Paint()
      ..color = const Color(0xFF1A2348).withValues(alpha: 0.5 * reveal)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var k = -2; k <= 2; k++) {
      final gx = center.dx + k * w * 0.13;
      canvas.drawLine(
        Offset(gx, center.dy - h * 0.2),
        Offset(gx, center.dy + h * 0.2),
        grip,
      );
    }

    // up/down hint chevrons — only until the first drag.
    if (live && !hasDragged) {
      final chev = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..color = RTune.tensionCool.withValues(alpha: (0.5 + 0.35 * pulse) * reveal);
      final off = h * (1.05 + 0.18 * pulse);
      _chevron(canvas, center.translate(0, -off), up: true, paint: chev);
      _chevron(canvas, center.translate(0, off), up: false, paint: chev);
    }
  }

  void _chevron(Canvas canvas, Offset tip, {required bool up, required Paint paint}) {
    final dy = up ? 6.0 : -6.0;
    canvas.drawLine(tip.translate(-6, dy), tip, paint);
    canvas.drawLine(tip.translate(6, dy), tip, paint);
  }

  // ── The BULB, wired in series in the loop — it lights from the current that
  //    reaches it (the steel loop wire runs into it; the beads flow through). ────
  void _paintLamp(Canvas canvas, _WireGeo geo) {
    final reveal = c.lampReveal;
    if (reveal <= 0.01) return;
    final center = geo.lampCenter;
    final r = geo.lampRadius;
    // brightness ∝ normalized current, kept SMALL (secondary). paintBulb hard-
    // gates off brightness with no cooling fade — same instant response.
    final b = (c.lampGlow * reveal).clamp(0.0, 1.0);
    // a small living bloom around the LIT bulb (kept secondary — never the hero).
    if (b > 0.02) {
      final breath = c.reducedMotion
          ? 1.0
          : 1.0 + math.sin(c.flowPhase * 2 * math.pi * RTune.lampBreathHz) * RTune.lampBreathAmp;
      final bloomR = r * (1.4 + 2.2 * b) * breath;
      canvas.drawCircle(
        center,
        bloomR,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(
            colors: [
              RTune.energyGlow.withValues(alpha: 0.42 * b),
              RTune.energyGlow.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: bloomR)),
      );
    }
    paintBulb(canvas, center, r, b);
  }

  // ── The live CURRENT readout (the only floating chip — VOLTAGE now lives ON
  //    the source module, so it can't be mistaken for a wired-in component). ─────
  void _paintChips(Canvas canvas, _WireGeo geo) {
    // CURRENT chip — instrument-grade: rolling value + value-linked glow + ↑/↓.
    final intensity = (c.currentNorm / 4.0).clamp(0.0, 1.0);
    _chip(
      canvas,
      _xy(RTune.currentChipX, RTune.currentChipY),
      RCopy.currentChip,
      '${c.displayCurrent.value}',
      trend: c.currentTrend.value,
      locked: false,
      intensity: intensity,
      alpha: c.wireReveal,
    );
  }

  void _chip(Canvas canvas, Offset center, String label, String value,
      {required int trend,
      required bool locked,
      required double intensity,
      required double alpha}) {
    if (alpha <= 0.02) return;
    final accent = RTune.energy;
    final labelTp = _text(label, 9, FontWeight.w700, RTune.chipText.withValues(alpha: 0.7 * alpha),
        mono: true, ls: 1.5);
    final valColor = locked
        ? Colors.white.withValues(alpha: 0.97 * alpha)
        : accent.withValues(alpha: 0.98 * alpha);
    final valTp = _text(value, 19, FontWeight.w800, valColor, mono: true, ls: 0.5);
    final glyphW = locked ? 14.0 : (trend != 0 ? 13.0 : 0.0);
    final innerW = math.max(labelTp.width, valTp.width + glyphW + 4);
    final padX = 11.0, padY = 7.0;
    final w = innerW + padX * 2;
    final h = labelTp.height + valTp.height + padY * 2 + 4;
    final rect = Rect.fromCenter(center: center, width: w, height: h);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    // value-linked glow for the CURRENT chip (recedes vs the warm hero — capped).
    if (intensity > 0.01) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(4), const Radius.circular(15)),
        Paint()
          ..blendMode = BlendMode.plus
          ..color = accent.withValues(alpha: 0.14 * intensity * alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    canvas.drawRRect(rr, Paint()..color = RTune.chipGlass.withValues(alpha: alpha));
    // a thin top gloss line so the dark glass reads dimensional.
    canvas.drawLine(
      Offset(rect.left + 10, rect.top + 2.6),
      Offset(rect.right - 10, rect.top + 2.6),
      Paint()
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.10 * alpha),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = (locked ? RTune.chipBorder : accent.withValues(alpha: 0.24 + 0.2 * intensity))
            .withValues(alpha: alpha),
    );
    final top = center.dy - h / 2 + padY;
    labelTp.paint(canvas, Offset(center.dx - labelTp.width / 2, top));
    final valY = top + labelTp.height + 3;
    final valX = center.dx - (valTp.width + glyphW + (glyphW > 0 ? 4 : 0)) / 2;
    valTp.paint(canvas, Offset(valX, valY));
    final glyphCenter = Offset(valX + valTp.width + 4 + glyphW / 2, valY + valTp.height / 2);
    if (locked) {
      _drawLockGlyph(canvas, glyphCenter.translate(0, -1), 6.0, alpha);
    } else if (trend != 0) {
      _drawTrend(canvas, glyphCenter, trend > 0, alpha);
    }

    // CURRENT instrument needle — a thin accent bar under the value, length ∝ I.
    if (!locked) {
      final barW = w - padX * 2;
      final barY = rect.bottom - padY * 0.5;
      final barL = rect.center.dx - barW / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(barL, barY, barW, 2.2), const Radius.circular(2)),
        Paint()..color = accent.withValues(alpha: 0.16 * alpha),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(barL, barY, barW * intensity, 2.2), const Radius.circular(2)),
        Paint()
          ..blendMode = BlendMode.plus
          ..color = accent.withValues(alpha: 0.85 * alpha),
      );
    }
  }

  // A small pin+lock glyph for the LOCKED voltage chip (the held-constant proof).
  void _drawLockGlyph(Canvas canvas, Offset p, double r, double alpha) {
    final gold = RTune.goldPin;
    // pin head
    canvas.drawCircle(p, r * 0.62, Paint()..color = gold.withValues(alpha: alpha));
    canvas.drawCircle(
      p,
      r * 0.62,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = const Color(0xFFFFF0C4).withValues(alpha: 0.9 * alpha),
    );
    // clamp tail
    final tail = Path()
      ..moveTo(p.dx - r * 0.28, p.dy + r * 0.2)
      ..lineTo(p.dx, p.dy + r * 0.95)
      ..lineTo(p.dx + r * 0.28, p.dy + r * 0.2);
    canvas.drawPath(tail, Paint()..color = gold.withValues(alpha: alpha));
    canvas.drawCircle(
      p.translate(-r * 0.2, -r * 0.22),
      r * 0.16,
      Paint()..color = Colors.white.withValues(alpha: 0.85 * alpha),
    );
  }

  void _drawTrend(Canvas canvas, Offset center, bool up, double alpha) {
    final col = (up ? RTune.energy : RTune.returnCool).withValues(alpha: 0.95 * alpha);
    final p = Path();
    const s = 5.0;
    if (up) {
      p.moveTo(center.dx, center.dy - s);
      p.lineTo(center.dx - s, center.dy + s);
      p.lineTo(center.dx + s, center.dy + s);
    } else {
      p.moveTo(center.dx, center.dy + s);
      p.lineTo(center.dx - s, center.dy - s);
      p.lineTo(center.dx + s, center.dy - s);
    }
    p.close();
    canvas.drawPath(p, Paint()..color = col);
  }

  // ── The cool CHOKE pinch ring + the fat SURGE shimmer (P1.5) ───────────────
  // At THIN discovery the stream PINCHES (handled in _paintRiver via choke) and a
  // COOL clarity ring snaps out here — emphatically NOT warm/heat (acceptance §8):
  // it reads as "the flow just cut", never a temperature event. At the FAT moment a
  // wide cool SURGE shimmer gushes outward (no second heavy flash).
  void _paintChokeRing(Canvas canvas, _WireGeo geo) {
    final f = c.discoveryFlash;
    final fat = c.fatShimmer;
    final center = geo.pointAt(0.5);

    // FAT surge — a wide cool gush radiating from the cable mid (flow pours).
    if (fat > 0.01) {
      final r = _s.width * (0.16 + 0.34 * (1 - fat));
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..blendMode = BlendMode.plus
          ..style = PaintingStyle.stroke
          ..strokeWidth = (5 + 18 * fat)
          ..color = RTune.controlCoolLite.withValues(alpha: 0.30 * fat)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 16 * fat + 4),
      );
      // a soft WARM inner bloom — the current itself surging (more flow, not heat).
      canvas.drawCircle(
        center,
        geo.halfWidthBase * (2.2 + 3 * fat),
        Paint()
          ..blendMode = BlendMode.plus
          ..color = RTune.energyGlow.withValues(alpha: 0.20 * fat)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, geo.halfWidthBase * 1.4 + 2),
      );
    }

    // THIN choke — a crisp cool clarity ring that reads "the flow just cut".
    if (f > 0.001) {
      if (c.reducedMotion) {
        canvas.drawCircle(
          center,
          _s.width * 0.18,
          Paint()
            ..blendMode = BlendMode.plus
            ..color = RTune.controlCoolLite.withValues(alpha: 0.45 * f)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
        );
        return;
      }
      final maxR = _s.width * 0.52;
      final r = maxR * (1 - f);
      // the travelling snap ring
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 + 8 * f
          ..blendMode = BlendMode.plus
          ..color = RTune.controlCoolLite.withValues(alpha: 0.62 * f)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * f),
      );
      // a tight inner pinch right at the cable — the choke point itself.
      canvas.drawCircle(
        center,
        geo.halfWidthBase * 1.8 + 4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * f
          ..blendMode = BlendMode.plus
          ..color = RTune.controlCool.withValues(alpha: 0.55 * f)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  // ── The mono "RESISTANCE" specimen label — an elegant reveal at naming (P2.10)
  void _paintResistanceSpecimen(Canvas canvas, _WireGeo geo) {
    final a = c.resistLabelFade * (1.0 - c.landingBlend);
    if (a <= 0.02) return;
    final anchor = geo.pointAt(0.5);
    final tp = _text(RCopy.resistanceSpecimenLabel, 11, FontWeight.w700,
        const Color(0xFFD6E0FF).withValues(alpha: 0.92 * a),
        mono: true, ls: 3.4);
    final labelPos = Offset(anchor.dx + _s.width * 0.10, anchor.dy);
    // an elegant specimen leader: a small ring on the cable + a thin elbow line
    // to the mono label (reads like a labelled museum specimen, not a tooltip).
    final ringR = geo.halfWidthAt(0.5) + 5;
    canvas.drawCircle(
      anchor,
      ringR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFD6E0FF).withValues(alpha: 0.5 * a),
    );
    final elbow = Offset(anchor.dx + _s.width * 0.055, anchor.dy);
    canvas.drawLine(
      anchor.translate(ringR, 0),
      elbow,
      Paint()
        ..strokeWidth = 1
        ..color = const Color(0xFFD6E0FF).withValues(alpha: 0.4 * a),
    );
    canvas.drawLine(
      elbow,
      Offset(labelPos.dx - 4, labelPos.dy),
      Paint()
        ..strokeWidth = 1
        ..color = const Color(0xFFD6E0FF).withValues(alpha: 0.4 * a),
    );
    // a small dot at the label anchor for the specimen-tag feel.
    canvas.drawCircle(Offset(labelPos.dx - 4, labelPos.dy), 1.6,
        Paint()..color = const Color(0xFFD6E0FF).withValues(alpha: 0.6 * a));
    tp.paint(canvas, Offset(labelPos.dx, labelPos.dy - tp.height / 2));
  }

  // ── THE PAYOFF (Pillar 4): a bold, straight, VERTICAL arm-thick conductor ───
  // grows in along the stage centreline — a FIXED geometry (independent of the
  // morphT the learner left), so the reveal is always a clean premium cable and
  // never a squat horizontal blob. Dark cylindrical sheath, twisted stranded-
  // aluminium bundle, a lit specular streak, a forearm ghost for scale, and the
  // mono "REAL TRANSMISSION CABLE". Driven off landingBlend (timing owned by ctrl).
  void _paintLandingScale(Canvas canvas) {
    final t = Curves.easeInOut.transform(c.landingBlend.clamp(0.0, 1.0));
    if (t <= 0.001) return;

    final topY = RTune.landingTopY * _s.height;
    final botY = RTune.landingBottomY * _s.height;
    final cx = 0.5 * _s.width;
    final len = botY - topY;
    final halfW = RTune.landingHalfWidthFrac * _s.width * t; // grows in

    // local half-width with domed end caps (a real cylinder, not a flat slab).
    final capU = ((halfW * 0.85) / math.max(len, 1)).clamp(0.04, 0.45);
    double hwAt(double u) {
      double cap = 1.0;
      if (u < capU) cap = math.sin((u / capU) * math.pi / 2);
      if (u > 1 - capU) cap = math.sin(((1 - u) / capU) * math.pi / 2);
      return halfW * cap.clamp(0.12, 1.0);
    }
    final body = _vOutline(cx, topY, len, hwAt);
    final mid = Offset(cx, topY + len * 0.5);

    // forearm ghost silhouette beside the cable (≈9% alpha) — the scale cue.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: mid.translate(_s.width * 0.16, 0),
          width: halfW * 2.6,
          height: len * 1.04,
        ),
        Radius.circular(halfW),
      ),
      Paint()
        ..color = RTune.forearmGhost.withValues(alpha: 0.09 * t)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // contact shadow grounding the cable.
    canvas.drawPath(
      body,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.42 * t)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    // dark cylindrical sheath shading (deep edges → aluminium centre).
    final bounds = body.getBounds();
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            RTune.cableSheath,
            RTune.cableAluDeep,
            RTune.cableAlu,
            RTune.cableAluDeep,
            RTune.cableSheath,
          ],
          stops: const [0.0, 0.26, 0.5, 0.74, 1.0],
        ).createShader(bounds),
    );
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = RTune.cableAluLite.withValues(alpha: 0.5 * t),
    );

    // the twisted stranded-aluminium bundle resolves across the reveal.
    if (t > 0.16) {
      final strandA = ((t - 0.16) / 0.84).clamp(0.0, 1.0);
      canvas.save();
      canvas.clipPath(body);
      _paintStrandsStraight(canvas, cx, topY, len, halfW, strandA);
      canvas.restore();
    }

    // a bright centre specular streak — the lit side of the cylinder.
    canvas.save();
    canvas.clipPath(body);
    final streak = Path();
    for (var i = 0; i <= 26; i++) {
      final u = i / 26;
      final p = Offset(cx - hwAt(u) * 0.30, topY + len * u);
      if (i == 0) {
        streak.moveTo(p.dx, p.dy);
      } else {
        streak.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      streak,
      Paint()
        ..blendMode = BlendMode.plus
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2, halfW * 0.5)
        ..strokeCap = StrokeCap.round
        ..color = RTune.cableAluLite.withValues(alpha: 0.26 * t)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, halfW * 0.4 + 1),
    );
    canvas.restore();

    // mono label under the cable.
    final tp = _text(RCopy.cableLabel, 10.5, FontWeight.w700,
        RTune.cableAlu.withValues(alpha: 0.94 * t),
        mono: true, ls: 2.2);
    final labelY = botY + halfW + _s.height * 0.025;
    tp.paint(canvas, Offset(cx - tp.width / 2, labelY));
  }

  /// A closed straight-vertical capsule outline (left edge down, right edge up).
  Path _vOutline(double cx, double topY, double len, double Function(double u) hwAt) {
    const steps = 40;
    final left = <Offset>[];
    final right = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final u = i / steps;
      final y = topY + len * u;
      final hw = hwAt(u);
      left.add(Offset(cx - hw, y));
      right.add(Offset(cx + hw, y));
    }
    final path = Path()..moveTo(left.first.dx, left.first.dy);
    for (final p in left.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    for (final p in right.reversed) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    return path;
  }

  // The stranded bundle as TWISTED vertical strand-lines (reads as laid aluminium,
  // not a bag of marbles). Cylindrical shading across the bundle; a gentle helical
  // twist so the strands look spun. Clipped to the body by the caller.
  void _paintStrandsStraight(
      Canvas canvas, double cx, double topY, double len, double halfW, double a) {
    final sr = RTune.landingStrandWidthFrac * _s.width; // strand thickness unit
    if (sr <= 0.5) return;
    final n = (halfW * 2 / (sr * 1.4)).clamp(3, 14).round(); // strands across
    for (var k = 0; k < n; k++) {
      final fx = (k + 0.5) / n; // 0..1 across the bundle
      final off = (fx * 2 - 1) * (halfW - sr * 0.5);
      // cylindrical shading: bright toward the lit side (left-of-centre), dark edges.
      final lit = math.cos((fx - 0.42) * math.pi).clamp(0.0, 1.0);
      final col = Color.lerp(RTune.cableAluDeep, RTune.cableAluLite, lit)!;
      final path = Path();
      const steps = 28;
      for (var i = 0; i <= steps; i++) {
        final u = i / steps;
        final y = topY + len * u;
        final twist = math.sin(u * math.pi * 3 + k * 0.9) * sr * 0.5; // helical lay
        if (i == 0) {
          path.moveTo(cx + off + twist, y);
        } else {
          path.lineTo(cx + off + twist, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = sr * 0.92
          ..strokeCap = StrokeCap.round
          ..color = col.withValues(alpha: a),
      );
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────
  TextPainter _text(String s, double size, FontWeight w, Color color,
      {bool mono = false, double ls = 0}) {
    final style = mono
        ? GoogleFonts.ibmPlexMono(
            fontSize: size, fontWeight: w, letterSpacing: ls, color: color)
        : GoogleFonts.plusJakartaSans(
            fontSize: size, fontWeight: w, letterSpacing: ls, color: color);
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp;
  }

  static Offset _quad(Offset a, Offset b, Offset c, double t) {
    final mt = 1 - t;
    return a * (mt * mt) + b * (2 * mt * t) + c * (t * t);
  }

  @override
  bool shouldRepaint(covariant ResistanceStagePainter old) => true;
}

// ── The CLOSED-LOOP circuit path, resolved once per paint ────────────────────
// A polyline walked clockwise from the source (dial): top run → lead → down the
// HERO centreline → into the bulb → out to the return rail → up the return → back
// across the top to the source. The current beads march this whole loop, so the
// learner sees the same current travel the circuit end-to-end and light the bulb.
class _LoopGeo {
  late List<Offset> pts;       // loop waypoints, clockwise from the source + terminal
  late List<double> cum;       // cumulative arc length at each waypoint
  late double total;           // loop perimeter (incl. the battery-internal return)
  late double heroStartT;      // loop fraction where the hero run begins (its top)
  late double heroEndT;        // loop fraction where the hero run ends (its bottom)
  late int wireEndIdx;         // last DRAWN wire waypoint (the − terminal)
  late double visibleEndT;     // loop fraction past which beads are inside the battery

  static _LoopGeo from(_WireGeo geo, Size s) {
    final g = _LoopGeo();
    final cx = geo.cx;
    final barY = RTune.sourceBarY * s.height;
    final returnX = RTune.returnPathX * s.width;
    final bulbY = geo.lampCenter.dy;
    final sxL = (RTune.sourceX - RTune.sourceWidthFactor / 2) * s.width; // + terminal
    final sxR = (RTune.sourceX + RTune.sourceWidthFactor / 2) * s.width; // − terminal

    final pts = <Offset>[];
    pts.add(Offset(sxL, barY));       // the source + terminal (current leaves here)
    pts.add(Offset(cx, barY));        // top run → above the hero
    pts.add(Offset(cx, geo.topY));    // lead down to the hero top
    final heroStartIdx = pts.length - 1;
    const heroSamples = 22;
    for (var i = 1; i <= heroSamples; i++) {
      pts.add(geo.pointAt(i / heroSamples)); // DOWN the hero centreline (incl. quiver)
    }
    final heroEndIdx = pts.length - 1;
    pts.add(Offset(cx, bulbY));        // into the bulb
    pts.add(Offset(returnX, bulbY));   // out to the return rail
    pts.add(Offset(returnX, barY));    // up the return
    pts.add(Offset(sxR, barY));        // back to the source − terminal
    final wireEndIdx = pts.length - 1;
    pts.add(Offset(sxL, barY));        // battery-INTERNAL return (hidden under the module)
    g.pts = pts;
    g.wireEndIdx = wireEndIdx;

    final cum = <double>[0];
    for (var i = 1; i < pts.length; i++) {
      cum.add(cum[i - 1] + (pts[i] - pts[i - 1]).distance);
    }
    g.cum = cum;
    g.total = cum.last <= 0 ? 1.0 : cum.last;
    g.heroStartT = cum[heroStartIdx] / g.total;
    g.heroEndT = cum[heroEndIdx] / g.total;
    g.visibleEndT = cum[wireEndIdx] / g.total;
    return g;
  }

  /// Position at loop fraction [t] (0..1), by arc length along the polyline.
  Offset at(double t) {
    final tt = ((t % 1.0) + 1.0) % 1.0;
    final d = tt * total;
    for (var i = 1; i < pts.length; i++) {
      if (cum[i] >= d) {
        final segLen = cum[i] - cum[i - 1];
        final f = segLen <= 0 ? 0.0 : (d - cum[i - 1]) / segLen;
        return Offset.lerp(pts[i - 1], pts[i], f)!;
      }
    }
    return pts.last;
  }
}

// ── Wire geometry resolved once per paint from the controller + stage size ───
class _WireGeo {
  _WireGeo._();

  late Size size;
  late double topY; // wire top (pixels)
  late double endY; // wire end (pixels)
  late double cx; // wire centre x
  late double halfWidthBase; // half-width at the top (pixels)
  late double serpAmp; // serpentine amplitude (pixels) — 0 now (straight taut cable)
  late double quiverAmp; // strained-tremor amplitude on the taut cable (pixels)
  late double flowPhase; // free-running clock (drives the quiver)
  late double morphT;
  late double currentNorm;
  late double relax; // 0..1 fat relaxation (mid-bulge)
  late double tension; // 0..1 taut straightening

  static _WireGeo from(ResistanceController c, Size s) {
    final g = _WireGeo._();
    g.size = s;
    g.morphT = c.morphT;
    g.currentNorm = c.currentNorm;
    g.cx = RTune.heroCenterX * s.width;
    g.topY = RTune.wireTopY * s.height;

    final lf = c.lengthFactor; // physical length factor (0.60 fat … 1.80 thin)

    // Rendered LENGTH is LINEAR in lf (carries the literal conservation read).
    final lenFat = RTune.wireEndYFat * s.height - g.topY;
    final lenThin = RTune.wireEndYThin * s.height - g.topY;
    final pxPerUnit = (lenThin - lenFat) / (RTune.lengthFactorThin - RTune.lengthFactorFat);
    g.endY = g.topY + lenFat + (lf - RTune.lengthFactorFat) * pxPerUnit;

    // Rendered full-width fraction through the three §16 anchors (one source of
    // truth: RTune.widthFracAt) → half-width in pixels.
    g.halfWidthBase = RTune.widthFracAt(c.morphT) * s.width / 2;

    // fat relaxation (mid-bulge) below relaxOnset; taut straightening above
    // tensionOnset (both purely visual flourishes — no morph state change).
    g.relax = ((RTune.relaxOnset - c.morphT) / RTune.relaxOnset).clamp(0.0, 1.0);
    g.tension = ((c.morphT - RTune.tensionOnset) / (1 - RTune.tensionOnset)).clamp(0.0, 1.0);

    // serpentine only above onset, scaling in smoothly; the taut cable straightens
    // it back out slightly (tension), so thin reads straighter/strained.
    final s01 = ((c.morphT - RTune.serpentineOnset) / (1 - RTune.serpentineOnset)).clamp(0.0, 1.0);
    g.serpAmp = s01 * RTune.serpentineAmpFactor * s.width * (1.0 - 0.35 * g.tension);
    // a tiny strained tremor scales in with tension (taut thin cable only).
    g.flowPhase = c.flowPhase;
    g.quiverAmp = c.reducedMotion ? 0.0 : g.tension * RTune.quiverAmpFactor * s.width;
    return g;
  }

  double get length => endY - topY;
  double get lampRadius => RTune.lampRadiusFactor * size.width;
  Offset get lampCenter => Offset(cx, endY + RTune.lampDropBelowEnd * size.height);
  double get maxPacketR => RTune.wireWidthFat * size.width * 0.30;
  double get bloomWidth => halfWidthBase * 2 + 10;

  /// How many lanes the current width affords (thin = single file).
  int get lanesAllowed => (halfWidthBase / (size.width * 0.012)).clamp(1, 4).round();

  /// Centreline point at param u (0 top → 1 end), including the serpentine bend.
  Offset pointAt(double u) {
    final y = topY + length * u;
    final bend = serpAmp == 0 ? 0.0 : math.sin(u * math.pi * 2) * serpAmp;
    // a strained tremor on the taut cable — a high-frequency, sub-pixel-ish shiver
    // that reads as "pulled tight", never a floppy wave.
    final quiver = quiverAmp <= 0
        ? 0.0
        : math.sin(u * math.pi * 3 + flowPhase * RTune.quiverHz) * quiverAmp;
    return Offset(cx + bend + quiver, y);
  }

  Offset normalAt(double u) {
    const e = 0.001;
    final a = pointAt((u - e).clamp(0.0, 1.0));
    final b = pointAt((u + e).clamp(0.0, 1.0));
    final tan = b - a;
    final len = tan.distance;
    if (len == 0) return const Offset(1, 0);
    return Offset(tan.dy / len, -tan.dx / len);
  }

  /// Half-width at param u — rounded capsule ends + a fat mid-bulge when relaxed.
  double halfWidthAt(double u) {
    // rounded end caps: shrink toward the very top/bottom so it reads as a real
    // cylinder with domed ends, not a flat-cut rectangle.
    final capU = ((RTune.cableEndCapFrac * halfWidthBase) / math.max(length, 1)).clamp(0.02, 0.45);
    double cap = 1.0;
    if (u < capU) cap = math.sin((u / capU) * math.pi / 2);
    if (u > 1 - capU) cap = math.sin(((1 - u) / capU) * math.pi / 2);
    // a gentle mid-bulge that grows when the cable is squashed fat (relaxed).
    final bulge = 1.0 + RTune.relaxBulge * relax * math.sin(u * math.pi);
    // a subtle base taper so even mid reads drawn, not extruded.
    final taper = 0.92 + 0.08 * math.sin(u * math.pi);
    return halfWidthBase * cap.clamp(0.18, 1.0) * bulge * taper;
  }

  /// The closed body path (left edge down, right edge up) following the centreline.
  Path bodyPath() => _outline((u) => halfWidthAt(u));

  Path _outline(double Function(double u) hwAt) {
    const steps = 30;
    final left = <Offset>[];
    final right = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final u = i / steps;
      final ctr = pointAt(u);
      final n = normalAt(u);
      final hw = hwAt(u);
      left.add(ctr + n * hw);
      right.add(ctr - n * hw);
    }
    final path = Path()..moveTo(left.first.dx, left.first.dy);
    for (final p in left.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    for (final p in right.reversed) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    return path;
  }

  /// A tight bright specular streak just left of the cylinder centre.
  Path specularStreakPath() => _streak((u) => halfWidthAt(u));

  Path _streak(double Function(double u) hwAt) {
    const steps = 26;
    final p = Path();
    for (var i = 0; i <= steps; i++) {
      final u = i / steps;
      final ctr = pointAt(u);
      final n = normalAt(u);
      final pos = ctr + n * hwAt(u) * 0.28; // ride just left of centre
      if (i == 0) {
        p.moveTo(pos.dx, pos.dy);
      } else {
        p.lineTo(pos.dx, pos.dy);
      }
    }
    return p;
  }
}
