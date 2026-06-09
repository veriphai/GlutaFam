// Stage 3 — Keep It Powered (PRD §14). Solar tilt DIAL (rotate gesture) aligns
// the panels with the Sun → the segmented power meter rises (PRD §14.5
// formula lives in the controller). Holding strong charge triggers the Earth
// shadow script: warning → 3…2…1 countdown → shadow falls → the child pulls
// the BATTERY RESERVE lever. Early pull is forgiven; late pull keeps
// prompting (no fail screens).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/scc_assets.dart';
import '../config/scc_stage_configs.dart';
import '../config/scc_theme.dart';
import '../state/mission_stage_controller.dart';
import '../state/mission_state.dart';

class PowerScene extends StatelessWidget {
  const PowerScene({super.key, required this.controller});

  final MissionStageController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final p = controller.state.power;
        final align = controller.alignmentScore(p.panelAngleDeg);
        final inShadow = p.phase == PowerPhase.shadow ||
            p.phase == PowerPhase.stabilized ||
            p.phase == PowerPhase.done;
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: sceneVignette(strength: 0.4)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
            children: [
              // ── scene: satellite + Sun + beams + shadow ──────────────────
              Expanded(
                child: Stack(
                  children: [
                    // Sun top-right (dims in shadow)
                    Positioned(
                      top: 0,
                      right: 0,
                      width: 110,
                      height: 110,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 600),
                        opacity: inShadow ? 0.15 : 1,
                        child: sccImage(SCC.flutter(SCC.sunGlow)),
                      ),
                    ),
                    // gold beams — procedural + additive (the sprite's matte
                    // fringe veiled the scene over the dark bg); strength
                    // follows panel alignment
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 250),
                          opacity: inShadow ? 0 : 1,
                          child: CustomPaint(
                            painter: _SunBeamPainter(strength: align),
                          ),
                        ),
                      ),
                    ),
                    // the satellite rotates 1:1 with the dial (at perfect
                    // alignment it sits in its natural pose, panels sunward)
                    Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.62,
                        child: Transform.rotate(
                          angle: (p.panelAngleDeg - PowerTuning.sunAngleDeg) *
                              math.pi /
                              180,
                          child: sccImage(SCC.flutter(SCC.satWeatherPowerMode)),
                        ),
                      ),
                    ),
                    // strong-charge glow (procedural soft green halo)
                    if (!inShadow && align > PowerTuning.strongAlignment)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Center(
                            child: Container(
                              width: 230,
                              height: 230,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: SccColors.success
                                        .withValues(alpha: 0.30),
                                    blurRadius: 70,
                                    spreadRadius: 14,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Earth shadow sweeping in
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 800),
                          opacity: inShadow ? 0.78 : 0,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Color(0xEE02050D), Color(0x5502050D)],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // countdown chip
                    if (p.phase == PowerPhase.countdown)
                      Positioned(
                        top: 8,
                        left: 0,
                        right: 0,
                        child: Center(child: _CountdownChip(n: p.countdown)),
                      ),
                  ],
                ),
              ),
              // ── console ──────────────────────────────────────────────────
              _PowerMeter(power: p.power, strong: align > PowerTuning.strongAlignment),
              const SizedBox(height: 10),
              SizedBox(
                height: 128,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _SolarDial(
                        angleDeg: p.panelAngleDeg,
                        enabled: p.phase == PowerPhase.aligning ||
                            p.phase == PowerPhase.shadowWarning,
                        onAngle: controller.setPanelAngle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BatteryLever(
                        pulled: p.leverPulled,
                        urgent: p.phase == PowerPhase.shadow && !p.leverPulled,
                        onPull: controller.pullBatteryLever,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Soft gold rays from the Sun (top-right) toward the satellite (centre),
/// painted additively so they GLOW over the dark space bg instead of veiling
/// it. Intensity follows the live alignment score.
class _SunBeamPainter extends CustomPainter {
  _SunBeamPainter({required this.strength});
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final sun = Offset(size.width - 55, 55);
    final sat = Offset(size.width / 2, size.height * 0.52);
    final dir = sat - sun;
    final n = dir / dir.distance;
    final perp = Offset(-n.dy, n.dx);
    canvas.saveLayer(null, Paint()..blendMode = BlendMode.plus);
    const gold = Color(0xFFFFCE5A);
    final a = 0.06 + 0.30 * strength;
    for (final spread in const [-0.22, 0.0, 0.22]) {
      final end = sat + perp * (size.width * spread);
      canvas.drawLine(
        sun,
        end,
        Paint()
          ..color = gold.withValues(alpha: a * (spread == 0 ? 1 : 0.6))
          ..strokeWidth = spread == 0 ? 26 : 14
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }
    // hot core ray when strongly aligned
    if (strength > 0.8) {
      canvas.drawLine(
        sun,
        sat,
        Paint()
          ..color = gold.withValues(alpha: 0.5)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SunBeamPainter old) => old.strength != strength;
}

class _CountdownChip extends StatelessWidget {
  const _CountdownChip({required this.n});
  final int n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: sccPanel(borderColor: SccColors.warningAmber),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_rounded, color: SccColors.warningAmber, size: 18),
          const SizedBox(width: 8),
          Text('EARTH SHADOW IN  $n',
              style: SccText.meterValue.copyWith(color: SccColors.warningAmber)),
        ],
      ),
    );
  }
}

class _PowerMeter extends StatelessWidget {
  const _PowerMeter({required this.power, required this.strong});
  final double power;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    const segments = 12;
    final lit = (power * segments).round();
    final color = power < 0.3
        ? SccColors.alertRed
        : strong
            ? SccColors.success
            : SccColors.warningAmber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: sccPanel(borderColor: strong ? SccColors.success : null),
      child: Row(
        children: [
          // status LED (instrument language, matches the Stage-5 scope)
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
          Text('POWER', style: SccText.label),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < segments; i++)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: i < lit
                            ? color
                            : SccColors.panelNavy.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: i < lit
                            ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 5)]
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 48,
            child: Text('${(power * 100).round()}%',
                style: SccText.meterValue.copyWith(color: color),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

/// Rotate-gesture dial: pan around the centre maps to the panel tilt angle.
class _SolarDial extends StatelessWidget {
  const _SolarDial({required this.angleDeg, required this.enabled, required this.onAngle});

  final double angleDeg;
  final bool enabled;
  final ValueChanged<double> onAngle;

  void _track(Offset local, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final v = local - c;
    final deg = math.atan2(v.dy, v.dx) * 180 / math.pi + 90; // 0 = up
    onAngle(((deg % 360) + 360) % 360);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: sccPanel(),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text('SOLAR TILT', style: SccText.label.copyWith(fontSize: 9.5)),
          const SizedBox(height: 4),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final size = Size(box.maxWidth, box.maxHeight);
                return IgnorePointer(
                  ignoring: !enabled,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (d) => _track(d.localPosition, size),
                    onPanUpdate: (d) => _track(d.localPosition, size),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // tick ring behind the dial — lights around the
                        // current angle (instrument language, matches the
                        // Stage-5 tuner)
                        CustomPaint(
                          size: Size(size.width, size.height),
                          painter: _DialScalePainter(angleDeg: angleDeg),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Transform.rotate(
                            angle: angleDeg * math.pi / 180,
                            child: sccImage(SCC.flutter(SCC.solarDial),
                                fit: BoxFit.contain),
                          ),
                        ),
                        // glowing pointer dot on the rim
                        Transform.rotate(
                          angle: angleDeg * math.pi / 180,
                          child: SizedBox(
                            width: size.width,
                            height: size.height,
                            child: Align(
                              alignment: const Alignment(0, -0.92),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: SccColors.cyan,
                                  boxShadow: [
                                    BoxShadow(color: SccColors.cyan, blurRadius: 7)
                                  ],
                                ),
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
        ],
      ),
    );
  }
}

/// Full-circle tick ring; the ticks near the current dial angle glow.
class _DialScalePainter extends CustomPainter {
  _DialScalePainter({required this.angleDeg});
  final double angleDeg;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 1;
    const ticks = 36;
    for (var i = 0; i < ticks; i++) {
      final deg = i * 360 / ticks;
      var d = (deg - (angleDeg - 90)) % 360; // dial 0° points up
      if (d > 180) d -= 360;
      final lit = d.abs() < 18;
      final p = Paint()
        ..color = lit
            ? SccColors.cyan.withValues(alpha: 0.9)
            : SccColors.panelBorder.withValues(alpha: 0.7)
        ..strokeWidth = lit ? 2.2 : 1.3
        ..strokeCap = StrokeCap.round;
      final ang = deg * math.pi / 180;
      final dir = Offset(math.sin(ang), -math.cos(ang));
      canvas.drawLine(c + dir * (r - 5), c + dir * r, p);
    }
  }

  @override
  bool shouldRepaint(covariant _DialScalePainter old) => old.angleDeg != angleDeg;
}

/// Battery reserve lever — vertical drag DOWN pulls it (PRD §14.5).
class _BatteryLever extends StatefulWidget {
  const _BatteryLever({required this.pulled, required this.urgent, required this.onPull});

  final bool pulled;
  final bool urgent;
  final VoidCallback onPull;

  @override
  State<_BatteryLever> createState() => _BatteryLeverState();
}

class _BatteryLeverState extends State<_BatteryLever>
    with SingleTickerProviderStateMixin {
  double _drag = 0;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = widget.urgent ? SccColors.warningAmber : null;
    return GestureDetector(
      onVerticalDragUpdate: widget.pulled
          ? null
          : (d) {
              setState(() => _drag = (_drag + d.delta.dy).clamp(0.0, 56.0));
              if (_drag >= 52) widget.onPull();
            },
      onVerticalDragEnd: (_) => setState(() => _drag = widget.pulled ? 56 : 0),
      child: Container(
        decoration: sccPanel(borderColor: border),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text('BATTERY RESERVE',
                style: SccText.label.copyWith(
                    fontSize: 9.5,
                    color: widget.urgent ? SccColors.warningAmber : null)),
            const SizedBox(height: 4),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // lever artwork slides down as it's pulled
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 160),
                    alignment: Alignment(
                        0, -0.8 + 1.6 * ((widget.pulled ? 56 : _drag) / 56)),
                    child: FractionallySizedBox(
                      heightFactor: 0.7,
                      child: sccImage(SCC.flutter(SCC.batteryLever),
                          fit: BoxFit.contain),
                    ),
                  ),
                  if (!widget.pulled)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: widget.urgent
                          // urgent: the pull arrow bounces for attention
                          ? ScaleTransition(
                              scale: Tween<double>(begin: 0.85, end: 1.25)
                                  .animate(CurvedAnimation(
                                      parent: _pulse,
                                      curve: Curves.easeInOut)),
                              child: const Icon(
                                  Icons.keyboard_double_arrow_down_rounded,
                                  color: SccColors.warningAmber,
                                  size: 24),
                            )
                          : const Icon(Icons.keyboard_double_arrow_down_rounded,
                              color: SccColors.cyan, size: 22),
                    ),
                  if (widget.pulled)
                    const Align(
                      alignment: Alignment.bottomCenter,
                      child: Icon(Icons.check_circle_rounded,
                          color: SccColors.success, size: 22),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
