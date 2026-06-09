// Horizontal 7-node mission rail. The active step glows; completed steps show
// a checkmark; upcoming steps are dimmed.

import 'package:flutter/material.dart';

import '../../../home/career/careerTheme.dart';
import '../state/build_satellite_controller.dart';
import '../state/mission_steps.dart';

class StepProgressRail extends StatelessWidget {
  const StepProgressRail({super.key, required this.controller});

  final BuildSatelliteController controller;

  @override
  Widget build(BuildContext context) {
    final installed = controller.state.installedParts;
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          for (final step in kMissionSteps) ...[
            Expanded(child: _Node(step: step, done: _isDone(step, installed), current: _isCurrent(step, installed))),
          ],
        ],
      ),
    );
  }

  bool _isDone(MissionStep step, Set<String> installed) =>
      step.requiredPartIds.every(installed.contains);

  bool _isCurrent(MissionStep step, Set<String> installed) =>
      !_isDone(step, installed) && step.number == controller.state.currentStep;
}

class _Node extends StatelessWidget {
  const _Node({required this.step, required this.done, required this.current});

  final MissionStep step;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final Color circleColor = done
        ? CareerColors.green
        : current
            ? CareerColors.blue
            : Colors.white.withValues(alpha: 0.10);
    final Color textColor = (done || current) ? CareerColors.textPrimary : CareerColors.textMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: current
                ? const LinearGradient(colors: [CareerColors.cyan, CareerColors.purple])
                : null,
            color: current ? null : circleColor,
            border: Border.all(
              color: done
                  ? CareerColors.green
                  : current
                      ? Colors.white.withValues(alpha: 0.8)
                      : CareerColors.glassBorder,
              width: 1.4,
            ),
            boxShadow: current
                ? [BoxShadow(color: CareerColors.blue.withValues(alpha: 0.6), blurRadius: 12)]
                : null,
          ),
          alignment: Alignment.center,
          child: done
              ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
              : Text('${step.number}',
                  style: CareerText.statValue.copyWith(fontSize: 12, color: textColor)),
        ),
        const SizedBox(height: 3),
        Text(step.system,
            maxLines: 1,
            overflow: TextOverflow.clip,
            textAlign: TextAlign.center,
            style: CareerText.statLabel.copyWith(fontSize: 7.5, color: textColor)),
      ],
    );
  }
}
