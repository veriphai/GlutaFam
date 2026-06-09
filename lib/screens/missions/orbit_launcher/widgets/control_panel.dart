// The V2 orbit-challenge controls: two sliders (Launch Power, Tilt Angle) + the
// LAUNCH MISSION button. Sliders disable while a launch animates.

import 'package:flutter/material.dart';

import '../../../home/career/careerTheme.dart';
import '../state/orbit_launcher_controller.dart';
import 'orbit_button.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({super.key, required this.controller});

  final OrbitLauncherController controller;

  @override
  Widget build(BuildContext context) {
    final s = controller.state;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xE60A1838),
        borderRadius: BorderRadius.circular(CareerRadii.card),
        border: Border.all(color: CareerColors.glassBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LabeledSlider(
            title: 'Launch Power',
            leftLabel: 'Low',
            rightLabel: 'High',
            accent: CareerColors.cyan,
            value: s.launchPower,
            enabled: s.controlsEnabled,
            onChanged: controller.setPower,
          ),
          const SizedBox(height: 8),
          _LabeledSlider(
            title: 'Tilt Angle',
            leftLabel: 'Straight',
            rightLabel: 'More Tilt',
            accent: CareerColors.purple,
            value: s.tiltAngle,
            enabled: s.controlsEnabled,
            onChanged: controller.setTilt,
          ),
          const SizedBox(height: 12),
          OrbitButton(
            label: 'Launch Mission',
            colors: const [Color(0xFF34D17E), Color(0xFF17A95C)],
            leadingIcon: Icons.rocket_launch_rounded,
            onTap: controller.launchMission,
            // sliders stay usable during narration; launching waits for Orbit
            enabled: s.controlsEnabled && !s.voicePlaying,
          ),
        ],
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.title,
    required this.leftLabel,
    required this.rightLabel,
    required this.accent,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String leftLabel;
  final String rightLabel;
  final Color accent;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(title,
                style: CareerText.label.copyWith(color: Colors.white, fontSize: 11, letterSpacing: 0.6)),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              activeTrackColor: accent,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.16),
              thumbColor: Colors.white,
              overlayColor: accent.withValues(alpha: 0.18),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 3),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 100,
              onChanged: enabled ? onChanged : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(leftLabel, style: CareerText.statLabel.copyWith(color: Colors.white60, fontSize: 10)),
                Text(rightLabel, style: CareerText.statLabel.copyWith(color: Colors.white60, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
