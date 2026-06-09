// Apply-repair interaction panel (applyRepair step). Each mission gets a small
// hands-on control that produces 0..1 progress → controller.setApplyProgress,
// which the Flame stage reacts to live. Three reusable controls cover all seven:
//   • SDDial   — drag a rotary knob around an arc (rotate / align / point) —
//                matches the mock's "TURN AWAY FROM SUN" round dial.
//   • SDSlider — drag a knob across a track (the lateral debris dodge)
//   • SDHoldButton — press-and-hold to fill a gauge (restart / thruster / deploy)

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/satellite_doctor_mission.dart';
import '../state/satellite_doctor_controller.dart';
import 'sd_ui.dart';

class ApplyPanel extends StatelessWidget {
  const ApplyPanel({super.key, required this.controller});
  final SatelliteDoctorController controller;

  @override
  Widget build(BuildContext context) {
    final m = controller.mission;
    final locked = controller.applyLocked;
    return PremiumCard(
      accent: SDColors.cyan,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionPill(
              icon: Icons.build_circle_outlined,
              label: m.applyTitle.toUpperCase(),
              color: SDColors.cyan),
          const SizedBox(height: 8),
          Text(
            m.applyInstruction,
            textAlign: TextAlign.center,
            style: const TextStyle(color: SDColors.textMuted, fontSize: 12.5, height: 1.25),
          ),
          const SizedBox(height: 16),
          if (locked)
            _FixApplied()
          else
            _control(m),
        ],
      ),
    );
  }

  Widget _control(SatelliteDoctorMission m) {
    switch (m.interaction) {
      case RepairInteraction.rotateAwayFromSun:
        return SDDial(
          leftLabel: 'Facing Sun',
          rightLabel: 'Away',
          leftIcon: Icons.wb_sunny,
          rightIcon: Icons.public,
          value: controller.applyProgress,
          onChanged: controller.setApplyProgress,
        );
      case RepairInteraction.alignAntenna:
        return SDDial(
          leftLabel: 'Off Target',
          rightLabel: 'To Earth',
          leftIcon: Icons.help_outline,
          rightIcon: Icons.public,
          value: controller.applyProgress,
          onChanged: controller.setApplyProgress,
        );
      case RepairInteraction.pointPanelsToSun:
        return SDDial(
          leftLabel: 'Away',
          rightLabel: 'To Sun',
          leftIcon: Icons.public,
          rightIcon: Icons.wb_sunny,
          value: controller.applyProgress,
          onChanged: controller.setApplyProgress,
        );
      case RepairInteraction.dodgeDebris:
        return SDSlider(
          leftLabel: 'Danger Lane',
          rightLabel: 'Safe Lane',
          leftIcon: Icons.warning_amber_rounded,
          rightIcon: Icons.verified_outlined,
          value: controller.applyProgress,
          onChanged: controller.setApplyProgress,
        );
      case RepairInteraction.holdRestart:
        return SDHoldButton(
          label: 'HOLD TO RESTART',
          icon: Icons.restart_alt,
          value: controller.applyProgress,
          onProgress: controller.setApplyProgress,
        );
      case RepairInteraction.thrusterBurn:
        return SDHoldButton(
          label: 'HOLD FOR A SMALL BURN',
          icon: Icons.rocket_launch,
          fillSeconds: 1.6,
          value: controller.applyProgress,
          onProgress: controller.setApplyProgress,
        );
      case RepairInteraction.deployPanel:
        return SDHoldButton(
          label: 'HOLD TO DEPLOY PANEL',
          icon: Icons.unfold_more,
          value: controller.applyProgress,
          onProgress: controller.setApplyProgress,
        );
    }
  }
}

class _FixApplied extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [SDColors.green, SDColors.cyan]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: SDColors.green.withValues(alpha: 0.5), blurRadius: 16)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.check_circle, color: Colors.white, size: 22),
          SizedBox(width: 8),
          Text('FIX APPLIED',
              style: TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }
}

/// Rotary dial: drag the knob around the top arc (left endpoint → 0, right
/// endpoint → 1). Matches the mock's "TURN AWAY FROM SUN" round control. The
/// centre shows a rotating pointer + a curved arrow; the two endpoints are
/// captioned with icons (e.g. Sun ↔ Earth).
class SDDial extends StatefulWidget {
  const SDDial({
    super.key,
    required this.value,
    required this.onChanged,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftIcon,
    required this.rightIcon,
  });
  final double value;
  final ValueChanged<double> onChanged;
  final String leftLabel, rightLabel;
  final IconData leftIcon, rightIcon;

  @override
  State<SDDial> createState() => _SDDialState();
}

class _SDDialState extends State<SDDial> {
  final _key = GlobalKey();

  void _drag(Offset globalPos) {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(globalPos);
    final cx = box.size.width / 2;
    final cy = box.size.height; // pivot at the bottom-centre (top semicircle)
    // theta from +x axis, upward positive; left endpoint → π, right → 0.
    var theta = math.atan2(cy - local.dy, local.dx - cx);
    // Below the diameter line atan2 returns a NEGATIVE angle which would wrap
    // from +π to −π and clamp to 0 — making the far-LEFT read as the far-RIGHT
    // (false success). Snap a below-the-line drag to its nearest endpoint by
    // which horizontal half the finger is on.
    if (theta < 0) theta = local.dx < cx ? math.pi : 0.0;
    theta = theta.clamp(0.0, math.pi);
    widget.onChanged(1 - theta / math.pi);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 132,
          child: GestureDetector(
            key: _key,
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) => _drag(d.globalPosition),
            onPanUpdate: (d) => _drag(d.globalPosition),
            onTapDown: (d) => _drag(d.globalPosition),
            child: CustomPaint(
              painter: _DialPainter(widget.value),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _End(widget.leftIcon, widget.leftLabel, SDColors.orange),
            _End(widget.rightIcon, widget.rightLabel, SDColors.green, right: true),
          ],
        ),
      ],
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter(this.value);
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final r = math.min(size.width / 2 - 14, size.height - 14);
    final trackRect = Rect.fromCircle(center: center, radius: r);
    const cyan = SDColors.cyan;
    const green = SDColors.green;

    // track groove (recessed look: dark wide + subtle inner highlight)
    canvas.drawArc(
      trackRect, math.pi, math.pi, false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF0A1322),
    );
    canvas.drawArc(
      trackRect, math.pi, math.pi, false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.06),
    );

    // progress arc — glow pass + bright gradient core
    final grad = const LinearGradient(colors: [cyan, green]).createShader(trackRect);
    canvas.drawArc(
      trackRect, math.pi, math.pi * value, false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..shader = grad
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawArc(
      trackRect, math.pi, math.pi * value, false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..shader = grad,
    );

    // central hub (glossy disc)
    canvas.drawCircle(
        center, 28, Paint()..shader = const RadialGradient(
          colors: [Color(0xFF1B2B47), Color(0xFF0C1626)],
        ).createShader(Rect.fromCircle(center: center, radius: 28)));
    canvas.drawCircle(
      center, 28,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = cyan.withValues(alpha: 0.5),
    );

    final theta = math.pi * (1 - value); // left=π, right=0
    final dir = Offset(math.cos(theta), -math.sin(theta));

    // pointer
    canvas.drawLine(
      center, center + dir * (r - 16),
      Paint()
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = cyan.withValues(alpha: 0.85),
    );

    // knob — glow halo + glossy body + specular highlight
    final knob = center + dir * r;
    canvas.drawCircle(knob, 20,
        Paint()
          ..color = cyan.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(
        knob, 17, Paint()..shader = const RadialGradient(
          center: Alignment(-0.4, -0.5),
          colors: [Color(0xFF8FE6FF), Color(0xFF2E6BFF), Color(0xFF123A8C)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: knob, radius: 17)));
    canvas.drawCircle(
      knob, 17,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.8),
    );
    // specular dot
    canvas.drawCircle(knob + const Offset(-5, -5), 3.5,
        Paint()..color = Colors.white.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) => old.value != value;
}

/// Drag-a-knob slider, 0..1, with captioned endpoints.
class SDSlider extends StatefulWidget {
  const SDSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftIcon,
    required this.rightIcon,
  });
  final double value;
  final ValueChanged<double> onChanged;
  final String leftLabel, rightLabel;
  final IconData leftIcon, rightIcon;

  @override
  State<SDSlider> createState() => _SDSliderState();
}

class _SDSliderState extends State<SDSlider> {
  final _key = GlobalKey();

  void _drag(Offset globalPos) {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(globalPos);
    final t = (local.dx / box.size.width).clamp(0.0, 1.0);
    widget.onChanged(t);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _End(widget.leftIcon, widget.leftLabel, SDColors.orange),
            _End(widget.rightIcon, widget.rightLabel, SDColors.green, right: true),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onHorizontalDragStart: (d) => _drag(d.globalPosition),
          onHorizontalDragUpdate: (d) => _drag(d.globalPosition),
          onTapDown: (d) => _drag(d.globalPosition),
          child: Container(
            key: _key,
            height: 44,
            decoration: BoxDecoration(
              color: SDColors.bg.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: SDColors.stroke),
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final knobX = (c.maxWidth - 40) * widget.value;
                return Stack(
                  children: [
                    // fill
                    Container(
                      width: (knobX + 40).clamp(40.0, c.maxWidth),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          SDColors.cyan.withValues(alpha: 0.35),
                          SDColors.green.withValues(alpha: 0.5)
                        ]),
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    // knob
                    Positioned(
                      left: knobX,
                      top: 2,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [SDColors.cyan, SDColors.blue]),
                          boxShadow: [
                            BoxShadow(color: SDColors.cyan.withValues(alpha: 0.6), blurRadius: 12)
                          ],
                        ),
                        child: const Icon(Icons.drag_indicator, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _End extends StatelessWidget {
  const _End(this.icon, this.label, this.color, {this.right = false});
  final IconData icon;
  final String label;
  final Color color;
  final bool right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!right) Icon(icon, color: color, size: 16),
        if (!right) const SizedBox(width: 4),
        Text(label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        if (right) const SizedBox(width: 4),
        if (right) Icon(icon, color: color, size: 16),
      ],
    );
  }
}

/// Press-and-hold gauge: fills 0..1 over [fillSeconds]; releasing early resets.
class SDHoldButton extends StatefulWidget {
  const SDHoldButton({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.onProgress,
    this.fillSeconds = 1.3,
  });
  final String label;
  final IconData icon;
  final double value;
  final ValueChanged<double> onProgress;
  final double fillSeconds;

  @override
  State<SDHoldButton> createState() => _SDHoldButtonState();
}

class _SDHoldButtonState extends State<SDHoldButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (widget.fillSeconds * 1000).round()),
  )
    ..addListener(() => widget.onProgress(_c.value))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onProgress(1);
    });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down() {
    if (_c.isCompleted) return;
    _c.forward();
  }

  void _up() {
    if (_c.isCompleted) return;
    _c.stop();
    _c.animateBack(0, duration: const Duration(milliseconds: 250));
    widget.onProgress(0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _down(),
      onTapUp: (_) => _up(),
      onTapCancel: _up,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Container(
            height: 56,
            decoration: BoxDecoration(
              color: SDColors.bg.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SDColors.cyan),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: [
                FractionallySizedBox(
                  widthFactor: _c.value.clamp(0.0, 1.0),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [SDColors.cyan, SDColors.green]),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Text(widget.label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
