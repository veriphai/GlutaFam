// The bottom CTA: "Let's Fix It" in intro, "Continue" on completion, hidden
// during play (PRD §27 / §28.8). The completion-state Continue button stays
// dimmed/disabled until Orbit finishes the closing monologue — it then
// transitions to a glowing/pulsing live state.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../state/restore_earth_controller.dart';
import '../state/restore_earth_state.dart';

class CtaButton extends StatelessWidget {
  const CtaButton({super.key, required this.controller, required this.onNextMission});

  final RestoreEarthController controller;
  final VoidCallback onNextMission;

  @override
  Widget build(BuildContext context) {
    final s = controller.state;
    if (s.phase == ActivityPhase.intro) {
      return _button(
        label: '🚀  LET\'S FIX IT',
        colors: const [Color(0xFF2BB6FF), Color(0xFF1C7FE0)],
        onTap: controller.startMission,
        enabled: true,
      );
    }
    if (s.phase == ActivityPhase.complete) {
      final ready = s.continueEnabled;
      return _button(
        label: 'CONTINUE',
        colors: const [Color(0xFF54D14C), Color(0xFF2E9E2A)],
        onTap: ready
            ? () {
                controller.nextMission();
                onNextMission();
              }
            : null,
        enabled: ready,
      );
    }
    // During play the powers are the controls; collapse so they sit at the bottom.
    return const SizedBox.shrink();
  }

  Widget _button({
    required String label,
    required List<Color> colors,
    required VoidCallback? onTap,
    required bool enabled,
  }) {
    final dimAlpha = enabled ? 1.0 : 0.4;
    Widget pill = AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.first.withValues(alpha: dimAlpha),
            colors.last.withValues(alpha: dimAlpha),
          ],
        ),
        borderRadius: BorderRadius.circular(CareerRadii.pill),
        boxShadow: enabled
            ? [BoxShadow(color: colors.last.withValues(alpha: 0.55), blurRadius: 18)]
            : const [],
      ),
      child: Text(label,
          style: CareerText.cta.copyWith(
              color: Colors.white.withValues(alpha: enabled ? 1.0 : 0.7),
              fontSize: 16,
              letterSpacing: 0.5)),
    );

    if (enabled) {
      pill = pill.animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(
          end: 1.03, duration: 900.ms, curve: Curves.easeInOut);
    }

    return PressableScale(
      onTap: onTap ?? () {},
      pressedScale: enabled ? 0.97 : 1.0,
      child: IgnorePointer(ignoring: !enabled, child: pill),
    );
  }
}
