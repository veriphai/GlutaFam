// Launch Preview CTA. Disabled (dim) until every part is installed; then it
// glows and pulses. Tapping it flips the controller into the launch sequence,
// which the Flame game observes and plays.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../state/build_satellite_controller.dart';

class LaunchPreviewButton extends StatelessWidget {
  const LaunchPreviewButton({super.key, required this.controller});

  final BuildSatelliteController controller;

  @override
  Widget build(BuildContext context) {
    final enabled = controller.state.launchPreviewUnlocked && !controller.state.launching;

    Widget button = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        gradient: enabled
            ? const LinearGradient(colors: [Color(0xFFFF7A3D), Color(0xFFFF4D6D)])
            : null,
        color: enabled ? null : Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(CareerRadii.pill),
        border: Border.all(
            color: enabled ? Colors.transparent : CareerColors.glassBorder, width: 1),
        boxShadow: enabled
            ? [BoxShadow(color: const Color(0xFFFF4D6D).withValues(alpha: 0.5), blurRadius: 18)]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(enabled ? '🚀  Launch Preview' : '🔒  Launch Preview',
              style: CareerText.cta.copyWith(
                  fontSize: 15,
                  color: enabled ? Colors.white : CareerColors.textMuted)),
        ],
      ),
    );

    if (enabled) {
      button = button
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(end: 1.03, duration: 900.ms, curve: Curves.easeInOut);
    }

    return PressableScale(
      onTap: enabled ? controller.startLaunch : null,
      pressedScale: enabled ? 0.97 : 1,
      child: button,
    );
  }
}
