// Stage 7 — Fix the Surprise Issue (PRD §18). Satellite-Doctor thermal board,
// three tactile sub-steps in order:
//   1 CONNECT — trace along the dashed pipe route battery → radiator; the
//     heat pipe ACTIVATES section-by-section under the finger (snap-to-route,
//     not free drawing). When the last section connects, heat flows through
//     it by itself — particles stream battery→radiator and the battery's red
//     glow drains. (You build the path; physics moves the heat.)
//   2 ROTATE  — turn the radiator ring away from the Sun (release to check)
//   3 SWITCH  — flick the extra camera boost OFF
// The temp meter falls red → green as steps land. Off-route scribbling just
// pauses progress; sustained wandering sparks + hints, never fails.
//
// The satellite is the CLEAN idle render + a procedural pulsing red glow on
// the battery zone (the baked "overheating" sprite ships a fake-transparency
// halo, and a procedural glow can fade with the temperature).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/scc_assets.dart';
import '../config/scc_stage_configs.dart';
import '../config/scc_theme.dart';
import '../state/mission_stage_controller.dart';
import '../state/mission_state.dart';

class RepairScene extends StatefulWidget {
  const RepairScene({super.key, required this.controller});

  final MissionStageController controller;

  @override
  State<RepairScene> createState() => _RepairSceneState();
}

class _RepairSceneState extends State<RepairScene>
    with SingleTickerProviderStateMixin {
  // factor anchors on the board area (tuning pass expected)
  static const _batteryF = Offset(0.56, 0.50);
  static const _radiatorF = Offset(0.16, 0.74);

  /// The heat-pipe route, battery → radiator: a cubic bezier shaped like a
  /// rounded-elbow plumbing run (down from the battery, sweep left into the
  /// radiator) — controls chosen so the curve hugs an L, not a semicircle.
  static const _routeF = [
    Offset(0.56, 0.50),
    Offset(0.58, 0.72),
    Offset(0.42, 0.82),
    Offset(0.16, 0.74),
  ];
  static const _samples = 40;
  static const _corridor = 46.0; // finger-to-route forgiveness, px

  late final AnimationController _flow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  int _pipeIdx = 0; // activated samples (0.._samples)
  bool _connected = false;
  double _offRoute = 0; // accumulated wandering distance
  Offset? _sparkAt;
  int _sparkSeq = 0;

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  List<Offset> _routeSamples(Size area) {
    // smooth CURVED pipe: cubic bezier through the four factor waypoints
    // (battery end → two bend controls → radiator end)
    final p = [for (final f in _routeF) Offset(area.width * f.dx, area.height * f.dy)];
    Offset bez(double t) {
      final u = 1 - t;
      return p[0] * (u * u * u) +
          p[1] * (3 * u * u * t) +
          p[2] * (3 * u * t * t) +
          p[3] * (t * t * t);
    }

    return [for (var s = 0; s <= _samples; s++) bez(s / _samples)];
  }

  /// Step-2 rotate: pan anywhere on the board turns the radiator (angle of
  /// the finger around the board centre — big target, kid-friendly).
  void _radiatorDrag(Offset p, Size area) {
    final c = Offset(area.width / 2, area.height / 2);
    final v = p - c;
    final deg = (math.atan2(v.dy, v.dx) * 180 / math.pi + 360) % 360;
    widget.controller.setRadiatorAngle(deg);
  }

  void _pipeDrag(Offset p, Size area) {
    if (_connected) return;
    final samples = _routeSamples(area);
    // advance to the furthest of the next few samples the finger covers
    var advanced = false;
    for (var k = math.min(_pipeIdx + 5, _samples); k > _pipeIdx; k--) {
      if ((samples[k] - p).distance <= _corridor) {
        setState(() => _pipeIdx = k);
        advanced = true;
        break;
      }
    }
    if (advanced) {
      _offRoute = 0;
      if (_pipeIdx >= _samples) {
        _connected = true;
        widget.controller.traceFinished(reachedRadiator: true);
      }
      return;
    }
    // wandering far from the route for a while → spark + PRD hint
    if ((samples[math.min(_pipeIdx + 1, _samples)] - p).distance > _corridor * 1.6) {
      _offRoute += 6;
      if (_offRoute > 320) {
        _offRoute = 0;
        setState(() {
          _sparkAt = p;
          _sparkSeq++;
        });
        widget.controller.traceFinished(reachedRadiator: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final r = widget.controller.state.repair;
        final emergency = r.step != RepairStep.done;
        // heat intensity 0..1 drives the battery glow
        final heat = ((r.temp - RepairTuning.safeTemp) /
                (RepairTuning.startTemp - RepairTuning.safeTemp))
            .clamp(0.0, 1.0);
        return Stack(
          fit: StackFit.expand,
          children: [
            // emergency: the whole scene edge glows red until repaired
            Positioned.fill(
              child: sceneVignette(
                strength: 0.40,
                color: emergency ? const Color(0xFF4A0A14) : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // red mode banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: sccPanel(
                        borderColor: SccColors.alertRed.withValues(alpha: 0.8),
                        radius: 12),
                    child: Text(
                      r.step == RepairStep.done
                          ? 'SATELLITE SAFE'
                          : 'SATELLITE DOCTOR MODE',
                      textAlign: TextAlign.center,
                      style: SccText.chip.copyWith(
                          color: r.step == RepairStep.done
                              ? SccColors.success
                              : SccColors.alertRed,
                          letterSpacing: 1.2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ── satellite board + temp meter ─────────────────────────
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, box) {
                              final area = Size(box.maxWidth, box.maxHeight);
                              return GestureDetector(
                                onPanStart: switch (r.step) {
                                  RepairStep.trace => (d) =>
                                      _pipeDrag(d.localPosition, area),
                                  RepairStep.radiator => (d) =>
                                      _radiatorDrag(d.localPosition, area),
                                  _ => null,
                                },
                                onPanUpdate: switch (r.step) {
                                  RepairStep.trace => (d) =>
                                      _pipeDrag(d.localPosition, area),
                                  RepairStep.radiator => (d) =>
                                      _radiatorDrag(d.localPosition, area),
                                  _ => null,
                                },
                                onPanEnd: r.step == RepairStep.radiator
                                    ? (_) => widget.controller.radiatorReleased()
                                    : null,
                                child: Container(
                                  decoration: sccPanel(radius: 18),
                                  clipBehavior: Clip.antiAlias,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      // clean satellite render (recedes while
                                      // the radiator assembly is front-stage)
                                      AnimatedOpacity(
                                        duration:
                                            const Duration(milliseconds: 350),
                                        opacity: r.step == RepairStep.radiator
                                            ? 0.18
                                            : 1,
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: sccImage(
                                              SCC.flutter(SCC.satWeatherIdle),
                                              fit: BoxFit.contain),
                                        ),
                                      ),
                                      // step 2: the radiator panel, BIG on the
                                      // board — pan to rotate, pivoting on its
                                      // hinge hub (no gimbal ring — cleaner)
                                      if (r.step == RepairStep.radiator) ...[
                                        Center(
                                          child: FractionallySizedBox(
                                            widthFactor: 0.66,
                                            child: AspectRatio(
                                              aspectRatio: 1,
                                              child: Transform.rotate(
                                                angle: r.radiatorDeg *
                                                    math.pi /
                                                    180,
                                                child: sccImage(SCC.flutter(
                                                    SCC.radiatorPanel)),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // the Sun — rotate AWAY from this
                                        Positioned(
                                          top: 12,
                                          right: 12,
                                          width: 54,
                                          height: 54,
                                          child: IgnorePointer(
                                            child: sccImage(
                                                SCC.flutter(SCC.sunGlow)),
                                          ),
                                        ),
                                        Positioned(
                                          top: 66,
                                          right: 8,
                                          child: IgnorePointer(
                                            child: Text('SUN',
                                                style: SccText.label.copyWith(
                                                    fontSize: 8.5,
                                                    color: SccColors
                                                        .warningAmber)),
                                          ),
                                        ),
                                      ],
                                      // procedural battery heat glow — pulses,
                                      // and FADES as the temperature falls
                                      IgnorePointer(
                                        child: AnimatedBuilder(
                                          animation: _flow,
                                          builder: (context, _) => CustomPaint(
                                            size: Size.infinite,
                                            painter: _HeatGlowPainter(
                                              anchor: _batteryF,
                                              heat: heat,
                                              pulse: _flow.value,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // the heat pipe (route → activation →
                                      // flowing heat once connected)
                                      IgnorePointer(
                                        child: AnimatedBuilder(
                                          animation: _flow,
                                          builder: (context, _) => CustomPaint(
                                            size: Size.infinite,
                                            painter: _PipePainter(
                                              samples: _routeSamples(area),
                                              progressIdx:
                                                  _connected ? _samples : _pipeIdx,
                                              connected: _connected,
                                              flowT: _flow.value,
                                              visible: r.step == RepairStep.trace ||
                                                  _connected,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (r.step == RepairStep.trace) ...[
                                        _ZoneMarker(
                                            anchor: _batteryF,
                                            color: SccColors.alertRed,
                                            label: 'BATTERY'),
                                        _ZoneMarker(
                                            anchor: _radiatorF,
                                            color: SccColors.cyan,
                                            label: 'RADIATOR'),
                                      ],
                                      // wrong-wander glitch spark, one-shot
                                      if (_sparkAt != null)
                                        Positioned(
                                          left: _sparkAt!.dx - 34,
                                          top: _sparkAt!.dy - 34,
                                          width: 68,
                                          height: 68,
                                          child: IgnorePointer(
                                            child: TweenAnimationBuilder<double>(
                                              key: ValueKey(_sparkSeq),
                                              tween: Tween(begin: 1, end: 0),
                                              duration: const Duration(
                                                  milliseconds: 550),
                                              builder: (context, t, child) =>
                                                  Opacity(opacity: t, child: child),
                                              child: sccImage(SCC.flutter(
                                                  SCC.fxErrorGlitch)),
                                            ),
                                          ),
                                        ),
                                      // cooling shimmer once the radiator is
                                      // set — procedural soft cyan pulse (the
                                      // burst sprite rendered as a flat blob)
                                      if (r.step == RepairStep.switchOff ||
                                          r.step == RepairStep.done)
                                        IgnorePointer(
                                          child: AnimatedBuilder(
                                            animation: _flow,
                                            builder: (context, _) => CustomPaint(
                                              size: Size.infinite,
                                              painter: _CoolGlowPainter(
                                                anchor: _radiatorF,
                                                pulse: _flow.value,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        _TempMeter(temp: r.temp),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _StepDots(step: r.step),
                  const SizedBox(height: 6),
                  SizedBox(height: 84, child: _stepControl(r)),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _stepControl(RepairSub r) {
    switch (r.step) {
      case RepairStep.trace:
        return _StepCard(
          n: 1,
          text: 'Trace the pipe from the battery to the radiator.',
          child: const Icon(Icons.swipe_rounded, color: SccColors.cyan, size: 26),
        );
      case RepairStep.radiator:
        return _StepCard(
          n: 2,
          text: 'Rotate the radiator to face away from the Sun.',
          child: const Icon(Icons.rotate_90_degrees_ccw_rounded,
              color: SccColors.cyan, size: 26),
        );
      case RepairStep.switchOff:
        return _StepCard(
          n: 3,
          text: 'Flick off the extra camera boost.',
          child: _BoostSwitch(on: r.boostOn, onOff: widget.controller.boostSwitchedOff),
        );
      case RepairStep.done:
        return _StepCard(
          n: 3,
          text: 'Temperature safe. Great work, Satellite Doctor!',
          child: const Icon(Icons.check_circle_rounded,
              color: SccColors.success, size: 30),
        );
    }
  }
}

/// Gentle cyan cooling pulse at the radiator once it sheds heat — small soft
/// radial glow + two expanding rings (procedural; no sprite blob).
class _CoolGlowPainter extends CustomPainter {
  _CoolGlowPainter({required this.anchor, required this.pulse});

  final Offset anchor;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * anchor.dx, size.height * anchor.dy);
    final base = size.width * 0.07;
    canvas.drawCircle(
      c,
      base,
      Paint()
        ..color = SccColors.cyan.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    for (var i = 0; i < 2; i++) {
      final f = (pulse + i / 2) % 1.0;
      canvas.drawCircle(
        c,
        base * (0.8 + 1.6 * f),
        Paint()
          ..color = SccColors.cyan.withValues(alpha: (1 - f) * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CoolGlowPainter old) =>
      old.pulse != pulse || old.anchor != anchor;
}

/// Pulsing radial heat glow on the battery zone; intensity follows the live
/// temperature so each repair step visibly cools the satellite.
class _HeatGlowPainter extends CustomPainter {
  _HeatGlowPainter({required this.anchor, required this.heat, required this.pulse});

  final Offset anchor;
  final double heat;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    if (heat <= 0.01) return;
    final c = Offset(size.width * anchor.dx, size.height * anchor.dy);
    final breathe = 0.85 + 0.15 * math.sin(pulse * 2 * math.pi);
    final r = size.width * 0.16 * breathe;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF5A2A).withValues(alpha: 0.55 * heat),
            const Color(0xFFFF5A2A).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldRepaint(covariant _HeatGlowPainter old) =>
      old.heat != heat || old.pulse != pulse;
}

/// The heat pipe: dashed dim route ahead, glowing activated section behind
/// the finger, joint rings at the bends — and once connected, heat particles
/// flowing battery → radiator (orange near the battery, cyan by the radiator).
class _PipePainter extends CustomPainter {
  _PipePainter({
    required this.samples,
    required this.progressIdx,
    required this.connected,
    required this.flowT,
    required this.visible,
  });

  final List<Offset> samples;
  final int progressIdx;
  final bool connected;
  final double flowT;
  final bool visible;

  Path _pathTo(int endIdx) {
    final path = Path()..moveTo(samples[0].dx, samples[0].dy);
    for (var i = 1; i <= endIdx && i < samples.length; i++) {
      path.lineTo(samples[i].dx, samples[i].dy);
    }
    return path;
  }

  Paint _stroke(Color color, double width, {double blur = 0}) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke // STROKE — a filled bezier is a blob
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (blur > 0) p.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (!visible || samples.length < 2) return;

    final full = _pathTo(samples.length - 1);

    // ── the physical pipe: dark metal casing + hollow inner channel ──────
    canvas.drawPath(full, _stroke(const Color(0xFF2A3A5C), 14));
    canvas.drawPath(full, _stroke(const Color(0xFF0B1226), 8));

    // ── coolant filling the channel up to the finger ──────────────────────
    if (progressIdx > 0) {
      final fill = _pathTo(progressIdx);
      canvas.drawPath(
          fill, _stroke(SccColors.cyan.withValues(alpha: 0.35), 14, blur: 6));
      canvas.drawPath(fill, _stroke(SccColors.cyan, 7));
      canvas.drawPath(
          fill, _stroke(Colors.white.withValues(alpha: 0.75), 2.5));
    }

    // ── flange couplings at the ends + midpoint ───────────────────────────
    for (final f in const [0.0, 0.5, 1.0]) {
      final idx = (f * (samples.length - 1)).round();
      final reached = idx <= progressIdx;
      canvas.drawCircle(
        samples[idx],
        9,
        Paint()
          ..color = reached ? SccColors.cyan : const Color(0xFF44557E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5,
      );
    }

    // pulsing start hint at the battery end while unconnected
    if (!connected) {
      final t = 0.5 + 0.5 * math.sin(flowT * 2 * math.pi);
      canvas.drawCircle(
        samples[math.min(progressIdx, samples.length - 1)],
        8 + 4 * t,
        Paint()
          ..color = SccColors.cyan.withValues(alpha: 0.5 + 0.4 * t)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // heat flowing through the finished pipe — orange cools to cyan en route
    if (connected) {
      for (var i = 0; i < 4; i++) {
        final f = (flowT + i / 4) % 1.0;
        final idx = (f * (samples.length - 1)).floor();
        final p = Offset.lerp(samples[idx],
            samples[math.min(idx + 1, samples.length - 1)],
            f * (samples.length - 1) - idx)!;
        final color =
            Color.lerp(const Color(0xFFFF7A30), SccColors.cyan, f)!;
        canvas.drawCircle(
          p,
          5,
          Paint()
            ..color = color.withValues(alpha: 0.95)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PipePainter old) =>
      old.progressIdx != progressIdx ||
      old.connected != connected ||
      old.flowT != flowT ||
      old.visible != visible;
}

/// 1·2·3 repair-step progress: done = green check, active = amber pulse,
/// upcoming = dim.
class _StepDots extends StatelessWidget {
  const _StepDots({required this.step});
  final RepairStep step;

  @override
  Widget build(BuildContext context) {
    final activeIdx = switch (step) {
      RepairStep.trace => 0,
      RepairStep.radiator => 1,
      RepairStep.switchOff => 2,
      RepairStep.done => 3,
    };
    const labels = ['CONNECT', 'ROTATE', 'SWITCH'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0)
            Container(
              width: 26,
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: i <= activeIdx
                  ? SccColors.success.withValues(alpha: 0.7)
                  : SccColors.panelBorder,
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SccColors.panelNavy,
                  border: Border.all(
                    color: i < activeIdx
                        ? SccColors.success
                        : i == activeIdx
                            ? SccColors.warningAmber
                            : SccColors.panelBorder,
                    width: 1.6,
                  ),
                  boxShadow: i == activeIdx
                      ? [
                          BoxShadow(
                              color:
                                  SccColors.warningAmber.withValues(alpha: 0.5),
                              blurRadius: 8)
                        ]
                      : null,
                ),
                child: Center(
                  child: i < activeIdx
                      ? const Icon(Icons.check_rounded,
                          size: 13, color: SccColors.success)
                      : Text('${i + 1}',
                          style: SccText.chip.copyWith(
                              fontSize: 10,
                              color: i == activeIdx
                                  ? SccColors.warningAmber
                                  : SccColors.textMuted)),
                ),
              ),
              const SizedBox(height: 2),
              Text(labels[i],
                  style: SccText.label.copyWith(
                      fontSize: 7.5,
                      color: i == activeIdx
                          ? SccColors.warningAmber
                          : SccColors.textMuted)),
            ],
          ),
        ],
      ],
    );
  }
}

class _ZoneMarker extends StatelessWidget {
  const _ZoneMarker({required this.anchor, required this.color, required this.label});

  final Offset anchor;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment(anchor.dx * 2 - 1, anchor.dy * 2 - 1),
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)],
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: SccText.label.copyWith(fontSize: 8.5, color: color)),
          ],
        ),
      ),
    );
  }
}

class _TempMeter extends StatelessWidget {
  const _TempMeter({required this.temp});
  final double temp;

  @override
  Widget build(BuildContext context) {
    // 36 (safe) .. 92 (alert) mapped to 0..1
    final t = ((temp - RepairTuning.safeTemp) /
            (RepairTuning.startTemp - RepairTuning.safeTemp))
        .clamp(0.0, 1.0);
    final color = Color.lerp(SccColors.success, SccColors.alertRed, t)!;
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: sccPanel(),
      child: Column(
        children: [
          Text('TEMP', style: SccText.label.copyWith(fontSize: 9)),
          const SizedBox(height: 6),
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: 14,
                  decoration: BoxDecoration(
                    color: SccColors.panelNavy,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: SccColors.panelBorder),
                  ),
                ),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOut,
                  heightFactor: 0.1 + 0.9 * t,
                  child: Container(
                    width: 14,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text('${temp.round()}°C',
              style: SccText.meterValue.copyWith(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

/// Slim single-row step card: gradient hairline panel, glowing step number,
/// instruction, compact control on the right.
class _StepCard extends StatelessWidget {
  const _StepCard({required this.n, required this.text, required this.child});

  final int n;
  final String text;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            SccColors.panelNavy.withValues(alpha: 0.95),
            SccColors.deepSpace.withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SccColors.panelBorder, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: SccColors.warningAmber.withValues(alpha: 0.08),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: SccColors.warningAmber, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: SccColors.warningAmber.withValues(alpha: 0.35),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Text('$n',
                  style: SccText.chip
                      .copyWith(fontSize: 11, color: SccColors.warningAmber)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: SccText.body.copyWith(fontSize: 12.5, height: 1.25))),
          const SizedBox(width: 10),
          SizedBox(width: 84, height: 64, child: Center(child: child)),
        ],
      ),
    );
  }
}

class _BoostSwitch extends StatelessWidget {
  const _BoostSwitch({required this.on, required this.onOff});

  final bool on;
  final VoidCallback onOff;

  @override
  Widget build(BuildContext context) {
    final color = on ? SccColors.thermalOrange : SccColors.success;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: on ? onOff : null,
          onHorizontalDragEnd: on ? (_) => onOff() : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 64,
            height: 32,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: on
                  ? SccColors.thermalOrange.withValues(alpha: 0.30)
                  : SccColors.panelNavy,
              border: Border.all(color: color, width: 1.3),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10),
              ],
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              alignment: on ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 7),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(on ? 'ON' : 'OFF',
            style: SccText.chip.copyWith(fontSize: 9.5, color: color)),
      ],
    );
  }
}
