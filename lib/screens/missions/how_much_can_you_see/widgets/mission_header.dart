// Top mission header (PRD §6): home button, progress dots, settings.
// Dots track the six climb levels; visited ones light up.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/height_levels.dart';

class MissionHeader extends StatelessWidget {
  const MissionHeader({
    super.key,
    required this.visited,
    required this.onHome,
  });

  final Set<ViewHeightLevel> visited;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PressableScale(
          onTap: onHome,
          child: GlassSurface(
            radius: 12,
            padding: const EdgeInsets.all(7),
            child: const Icon(Icons.home_rounded, size: 18, color: CareerColors.textPrimary),
          ),
        ),
        const Spacer(),
        // Progress dots only — no "MISSION 2" label.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final l in kClimbOrder) _Dot(active: visited.contains(l)),
          ],
        ),
        const Spacer(),
        GlassSurface(
          radius: 12,
          padding: const EdgeInsets.all(7),
          child: const Icon(Icons.settings_rounded, size: 18, color: CareerColors.textSecondary),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: active ? 9 : 7,
      height: active ? 9 : 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? CareerColors.cyan : CareerColors.glassFillStrong,
        border: Border.all(
            color: active ? CareerColors.cyan : CareerColors.glassBorder, width: 1),
        boxShadow: active
            ? [BoxShadow(color: CareerColors.cyan.withValues(alpha: 0.6), blurRadius: 8)]
            : null,
      ),
    );
  }
}
