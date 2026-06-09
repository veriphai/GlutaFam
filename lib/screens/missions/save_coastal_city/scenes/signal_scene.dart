// Stage 5 — Send Data to Earth (PRD §16), premium pass. FULL-BLEED scene:
// the starfield + Flame stage fill the whole middle area edge-to-edge; the
// console floats over the scene bottom as glass panels:
//   • oscilloscope SIGNAL panel — gridded scope screen, glowing trace whose
//     colour lerps red → amber → green with live quality, % chip, status LED
//   • SIGNAL TUNER card — knob seated on a tick-arc scale with a glowing
//     position dot and a playful MHz readout that settles when clean
//   • PACKETS counter chip during transmission + a swipe hint that fades
//     after the first aim drag + an edge vignette to seat the chrome.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/scc_assets.dart';
import '../config/scc_stage_configs.dart';
import '../config/scc_theme.dart';
import '../game/save_city_game.dart';
import '../state/mission_stage_controller.dart';
import '../state/mission_state.dart';

class SignalScene extends StatefulWidget {
  const SignalScene(
      {super.key, required this.controller, required this.stage, required this.game});

  final MissionStageController controller;
  final Widget stage;
  final SaveCityGame game;

  @override
  State<SignalScene> createState() => _SignalSceneState();
}

class _SignalSceneState extends State<SignalScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wavePhase = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  bool _hasAimed = false;

  @override
  void dispose() {
    _wavePhase.dispose();
    super.dispose();
  }

  /// Same quality formula the Flame stage uses — keeps every colour in sync.
  double _quality(SignalSub s) {
    if (s.phase != SignalPhase.tuning) return 1;
    final aimGood = s.aimDeg.abs() <= SignalTuning.aimToleranceDeg;
    final freqGood =
        (s.freq - SignalTuning.freqTarget).abs() <= SignalTuning.freqTolerance;
    if (aimGood && freqGood) return 1;
    if (aimGood) return 0.55;
    return 0.18;
  }

  Color _qualityColor(double q) => q < 0.5
      ? Color.lerp(SccColors.alertRed, SccColors.warningAmber, q * 2)!
      : Color.lerp(SccColors.warningAmber, SccColors.success, (q - 0.5) * 2)!;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final s = widget.controller.state.signal;
        if (!_hasAimed && (s.aimDeg - 18).abs() > 2) _hasAimed = true;
        final q = _quality(s);
        final qColor = _qualityColor(q);
        final clean = q >= 1;
        final sending = s.phase == SignalPhase.sending || s.phase == SignalPhase.done;

        return Stack(
          fit: StackFit.expand,
          children: [
            // ── full-bleed scene (shell provides the starfield) ──────────
            Positioned.fill(child: widget.stage),
            Positioned.fill(child: sceneVignette()),
            // ── swipe hint (fades after first aim) ───────────────────────
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: s.phase == SignalPhase.tuning && !_hasAimed ? 1 : 0,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: sccPanel(radius: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.swipe_vertical_rounded,
                              color: SccColors.cyan, size: 18),
                          const SizedBox(width: 8),
                          Text('DRAG TO AIM THE BEAM',
                              style: SccText.chip
                                  .copyWith(color: SccColors.cyan, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // ── packets counter during transmission ──────────────────────
            if (sending)
              Positioned(
                top: 10,
                right: 14,
                child: ValueListenableBuilder<int>(
                  valueListenable: widget.game.signalDelivered,
                  builder: (context, n, _) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: sccPanel(
                        borderColor: SccColors.success.withValues(alpha: 0.7),
                        radius: 12),
                    child: Text('PACKETS  $n/${SignalStagePackets.count}',
                        style: SccText.meterValue
                            .copyWith(fontSize: 12, color: SccColors.success)),
                  ),
                ),
              ),
            // ── floating console ─────────────────────────────────────────
            Positioned(
              left: 14,
              right: 14,
              bottom: 8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ScopePanel(
                    wavePhase: _wavePhase,
                    freq: s.freq,
                    quality: q,
                    color: qColor,
                    clean: clean,
                  ),
                  const SizedBox(height: 10),
                  _TunerConsole(
                    freq: s.freq,
                    clean: clean,
                    color: qColor,
                    enabled: s.phase == SignalPhase.tuning,
                    onFreq: widget.controller.setTunerFreq,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Mirror of SignalStage.packetCount without importing the Flame file here.
class SignalStagePackets {
  static const count = 5;
}

// ─────────────────────────────────────────────────────────────────────────────
// Oscilloscope panel
// ─────────────────────────────────────────────────────────────────────────────

class _ScopePanel extends StatelessWidget {
  const _ScopePanel({
    required this.wavePhase,
    required this.freq,
    required this.quality,
    required this.color,
    required this.clean,
  });

  final Animation<double> wavePhase;
  final double freq;
  final double quality;
  final Color color;
  final bool clean;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: sccPanel(borderColor: clean ? SccColors.success : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // status LED
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [BoxShadow(color: color, blurRadius: 6)],
                ),
              ),
              const SizedBox(width: 8),
              Text('SIGNAL', style: SccText.label.copyWith(fontSize: 9.5)),
              const Spacer(),
              Text('${(quality * 100).round()}%',
                  style: SccText.meterValue.copyWith(fontSize: 12, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          // the scope screen
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 56,
              color: const Color(0xFF040A16),
              child: AnimatedBuilder(
                animation: wavePhase,
                builder: (context, _) => CustomPaint(
                  size: Size.infinite,
                  painter: _ScopePainter(
                    phase: wavePhase.value * 2 * math.pi,
                    noise: clean
                        ? 0.04
                        : ((freq - SignalTuning.freqTarget).abs() /
                                (1 - SignalTuning.freqTarget))
                            .clamp(0.15, 1.0),
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Oscilloscope: faint grid + a glowing trace (blur pass under core pass).
class _ScopePainter extends CustomPainter {
  _ScopePainter({required this.phase, required this.noise, required this.color});

  final double phase;
  final double noise;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // grid
    final grid = Paint()
      ..color = SccColors.cyan.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += size.width / 12) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += size.height / 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final mid = size.height / 2;
    final path = Path()..moveTo(0, mid);
    final rnd = math.Random(7);
    for (double x = 0; x <= size.width; x += 3) {
      final base = math.sin(x / size.width * 6 * math.pi + phase) * mid * 0.5;
      final jitter = math.sin(x * 13.7 + phase * 9) * rnd.nextDouble();
      final y = mid + base + jitter * mid * 0.9 * noise;
      path.lineTo(x, y.clamp(2.0, size.height - 2));
    }
    // glow pass under the core trace
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Color.lerp(color, Colors.white, 0.35)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
  }

  @override
  bool shouldRepaint(covariant _ScopePainter old) =>
      old.phase != phase || old.noise != noise || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tuner console
// ─────────────────────────────────────────────────────────────────────────────

class _TunerConsole extends StatelessWidget {
  const _TunerConsole({
    required this.freq,
    required this.clean,
    required this.color,
    required this.enabled,
    required this.onFreq,
  });

  final double freq;
  final bool clean;
  final Color color;
  final bool enabled;
  final ValueChanged<double> onFreq;

  @override
  Widget build(BuildContext context) {
    // playful MHz readout — jitters until the frequency is clean
    final jitter = clean ? 0.0 : math.sin(freq * 230) * 0.27;
    final mhz = 88 + freq * 20 + jitter;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: sccPanel(borderColor: clean ? SccColors.success : null),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chevron_left_rounded,
                    color: SccColors.textSecondary, size: 20),
                Text('TUNE', style: SccText.label.copyWith(fontSize: 9.5)),
              ],
            ),
          ),
          _TunerKnob(freq: freq, enabled: enabled, color: color, onFreq: onFreq),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${mhz.toStringAsFixed(1)} MHz',
                    style: SccText.meterValue.copyWith(fontSize: 12, color: color)),
                const SizedBox(height: 2),
                Text('FREQUENCY', style: SccText.label.copyWith(fontSize: 9.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rotating tuner knob seated on a tick-arc scale — pan around the centre
/// maps to freq 0..1 over a 270° sweep.
class _TunerKnob extends StatelessWidget {
  const _TunerKnob(
      {required this.freq, required this.enabled, required this.color, required this.onFreq});

  final double freq;
  final bool enabled;
  final Color color;
  final ValueChanged<double> onFreq;

  static const _sweepDeg = 270.0;
  static const _startDeg = 135.0;

  void _track(Offset local, double side) {
    final c = Offset(side / 2, side / 2);
    final v = local - c;
    var deg = math.atan2(v.dy, v.dx) * 180 / math.pi;
    deg = (deg - _startDeg + 360) % 360;
    if (deg > _sweepDeg) deg = deg < (_sweepDeg + (360 - _sweepDeg) / 2) ? _sweepDeg : 0;
    onFreq(deg / _sweepDeg);
  }

  @override
  Widget build(BuildContext context) {
    const side = 112.0;
    final angle = (_startDeg + freq * _sweepDeg) * math.pi / 180;
    return IgnorePointer(
      ignoring: !enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) => _track(d.localPosition, side),
        onPanUpdate: (d) => _track(d.localPosition, side),
        child: SizedBox(
          width: side,
          height: side,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // tick-arc scale behind the knob
              CustomPaint(
                size: const Size(side, side),
                painter: _ArcScalePainter(freq: freq, color: color),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Transform.rotate(
                  angle: angle + math.pi / 2,
                  child: sccImage(SCC.flutter(SCC.tunerKnob), fit: BoxFit.contain),
                ),
              ),
              // glowing position dot on the rim
              Transform.translate(
                offset: Offset(math.cos(angle), math.sin(angle)) * (side * 0.34),
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [BoxShadow(color: color, blurRadius: 7)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 270° tick scale; ticks behind the knob light up to the current position.
class _ArcScalePainter extends CustomPainter {
  _ArcScalePainter({required this.freq, required this.color});

  final double freq;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;
    const ticks = 27;
    for (var i = 0; i <= ticks; i++) {
      final f = i / ticks;
      final ang = (135 + f * 270) * math.pi / 180;
      final lit = f <= freq;
      final p = Paint()
        ..color = lit
            ? color.withValues(alpha: 0.85)
            : SccColors.panelBorder.withValues(alpha: 0.7)
        ..strokeWidth = lit ? 2.2 : 1.4
        ..strokeCap = StrokeCap.round;
      final dir = Offset(math.cos(ang), math.sin(ang));
      canvas.drawLine(c + dir * (r - 6), c + dir * r, p);
    }
  }

  @override
  bool shouldRepaint(covariant _ArcScalePainter old) =>
      old.freq != freq || old.color != color;
}
