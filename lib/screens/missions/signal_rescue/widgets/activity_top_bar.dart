// Top mission bar: back, title, and mission-progress dots (Flutter-rendered —
// no sprite text anywhere).

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../state/signal_rescue_state.dart';

class ActivityTopBar extends StatelessWidget {
  const ActivityTopBar({super.key, required this.phase, required this.onBack});

  final MissionPhase phase;
  final VoidCallback onBack;

  static const _order = [
    MissionPhase.intro,
    MissionPhase.explainParts,
    MissionPhase.alignAntenna,
    MissionPhase.waitForRange,
    MissionPhase.checkPower,
    MissionPhase.dataLocked,
    MissionPhase.transmitting,
    MissionPhase.success,
  ];

  @override
  Widget build(BuildContext context) {
    final idx = _order.indexOf(phase).clamp(0, _order.length - 1);
    return Row(
      children: [
        PressableScale(
          onTap: onBack,
          child: GlassSurface(
            radius: 13,
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.home_rounded, size: 18, color: CareerColors.textPrimary),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('SIGNAL RESCUE MISSION',
                  style: CareerText.label.copyWith(fontSize: 11, letterSpacing: 1.0)),
              const SizedBox(height: 5),
              Row(
                children: List.generate(_order.length, (i) {
                  final done = i <= idx;
                  return Container(
                    margin: const EdgeInsets.only(right: 5),
                    width: done ? 14 : 8,
                    height: 5,
                    decoration: BoxDecoration(
                      color: done ? CareerColors.cyan : CareerColors.glassBorder,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: done
                          ? [BoxShadow(color: CareerColors.cyan.withValues(alpha: 0.6), blurRadius: 6)]
                          : null,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
