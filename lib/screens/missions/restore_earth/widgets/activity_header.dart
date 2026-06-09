// Header: EP 1 · RESTORE EARTH · x/7 (PRD §7.3). Dark glass panel, cyan accents.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/scenarios.dart';
import '../state/restore_earth_controller.dart';

class ActivityHeader extends StatelessWidget {
  const ActivityHeader({super.key, required this.controller});

  final RestoreEarthController controller;

  @override
  Widget build(BuildContext context) {
    final solved = controller.state.solvedCount;
    return Row(
      children: [
        PressableScale(
          onTap: () => Navigator.of(context).maybePop(),
          child: GlassSurface(
            radius: 12,
            padding: const EdgeInsets.all(7),
            child: const Icon(Icons.arrow_back_rounded, size: 18, color: CareerColors.textPrimary),
          ),
        ),
        const SizedBox(width: 10),
        Text('EP 1', style: CareerText.statValue.copyWith(fontSize: 12, color: CareerColors.cyan)),
        Expanded(
          child: Text('RESTORE EARTH',
              textAlign: TextAlign.center,
              style: CareerText.greeting.copyWith(fontSize: 17, letterSpacing: 1.2)),
        ),
        Text('$solved/$kScenarioCount',
            style: CareerText.statValue.copyWith(fontSize: 14, color: CareerColors.cyan)),
        const SizedBox(width: 4),
      ],
    );
  }
}
