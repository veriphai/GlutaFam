// 7-node progress rail (PRD §7.4). Nodes fill left-to-right as systems are
// restored; the current node glows, solved ones show a check. Themed icons echo
// the seven Earth systems (decorative — fill is driven by solvedCount).

import 'package:flutter/material.dart';

import '../../../home/career/careerTheme.dart';
import '../config/scenarios.dart';
import '../state/restore_earth_controller.dart';

// One icon per system, in rail order (matches the mockup's themed nodes).
const List<IconData> _railIcons = [
  Icons.location_city_rounded,
  Icons.waves_rounded,
  Icons.bolt_rounded,
  Icons.directions_boat_rounded,
  Icons.cell_tower_rounded,
  Icons.agriculture_rounded,
  Icons.water_rounded,
];

class ProgressRail extends StatelessWidget {
  const ProgressRail({super.key, required this.controller});

  final RestoreEarthController controller;

  @override
  Widget build(BuildContext context) {
    final solved = controller.state.solvedCount;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CareerColors.glassBorder),
      ),
      child: Row(
        children: [
          for (var i = 0; i < kScenarioCount; i++) ...[
            _Node(icon: _railIcons[i], done: i < solved, current: i == solved && !controller.state.isComplete),
            if (i < kScenarioCount - 1)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  color: i < solved ? CareerColors.cyan : Colors.white.withValues(alpha: 0.12),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.icon, required this.done, required this.current});

  final IconData icon;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: (done || current)
            ? const LinearGradient(colors: [CareerColors.cyan, CareerColors.blue])
            : null,
        color: (done || current) ? null : Colors.white.withValues(alpha: 0.08),
        border: Border.all(
            color: (done || current) ? Colors.white.withValues(alpha: 0.85) : CareerColors.glassBorder,
            width: 1.2),
        boxShadow: current
            ? [BoxShadow(color: CareerColors.cyan.withValues(alpha: 0.6), blurRadius: 10)]
            : null,
      ),
      alignment: Alignment.center,
      child: Icon(done ? Icons.check_rounded : icon, size: 16,
          color: (done || current) ? Colors.white : CareerColors.textMuted),
    );
  }
}
