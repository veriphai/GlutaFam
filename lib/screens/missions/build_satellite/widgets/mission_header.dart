// Top header: back button, title, and "Step X of 7" chip.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../state/build_satellite_controller.dart';
import '../state/mission_steps.dart';

class MissionHeader extends StatelessWidget {
  const MissionHeader({super.key, required this.controller});

  final BuildSatelliteController controller;

  @override
  Widget build(BuildContext context) {
    final s = controller.state;
    final stepLabel = s.isComplete ? 'Complete' : 'Step ${s.currentStep} of $kTotalSteps';

    return Row(
      children: [
        PressableScale(
          onTap: () => Navigator.of(context).maybePop(),
          child: GlassSurface(
            radius: 14,
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.arrow_back_rounded, size: 20, color: CareerColors.textPrimary),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text('Build Your Satellite',
              style: CareerText.greeting.copyWith(fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        GlassSurface(
          radius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Text(stepLabel,
              style: CareerText.statValue.copyWith(fontSize: 11, color: CareerColors.cyan)),
        ),
      ],
    );
  }
}

