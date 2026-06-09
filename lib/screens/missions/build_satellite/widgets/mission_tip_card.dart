// Small contextual "Mission Tip" card. Updates per step (PRD §7.5).
// Rendered as a compact floating chip inside the build stage.

import 'package:flutter/material.dart';

import '../../../home/career/careerTheme.dart';
import '../state/build_satellite_controller.dart';

class MissionTipCard extends StatelessWidget {
  const MissionTipCard({super.key, required this.controller});

  final BuildSatelliteController controller;

  @override
  Widget build(BuildContext context) {
    final tip = controller.state.isComplete
        ? 'Tap Launch Preview to power up your satellite!'
        : controller.currentStep.tip;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xCC0B1538),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CareerColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💡', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 7),
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: Text(
                tip,
                key: ValueKey(tip),
                style: CareerText.body.copyWith(color: CareerColors.textSecondary, fontSize: 10.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
