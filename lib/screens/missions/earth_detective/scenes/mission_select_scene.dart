// Scene — Mission Select / Progress (storyboard frame 3). A progress bar plus
// the six missions as a tappable list (check / play / lock states). "Next
// Mission" returns here so progress is reinforced between clues.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/missions.dart';
import '../state/earth_detective_controller.dart';
import '../state/earth_detective_state.dart';
import '../widgets/ed_top_bar.dart';
import '../widgets/earth_detective_progress_rail.dart';
import '../widgets/mascot_helper_bubble.dart';

class MissionSelectScene extends StatelessWidget {
  const MissionSelectScene({super.key, required this.controller, required this.onHome});

  final EarthDetectiveController controller;
  final VoidCallback onHome;

  bool _unlocked(int i, Set<int> solved) =>
      i == 0 || solved.contains(i) || solved.contains(i - 1);

  @override
  Widget build(BuildContext context) {
    final solved = controller.state.solvedMissions;
    return SafeArea(
      child: Column(
        children: [
          EdTopBar(title: EdCopy.selectTitle, onBack: onHome, showSignal: true),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GlassSurface(
              radius: CareerRadii.card,
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              child: DetectiveProgressBar(solved: solved.length),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              physics: const BouncingScrollPhysics(),
              itemCount: kMissions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final unlocked = _unlocked(i, solved);
                final done = solved.contains(i);
                return RevealOnLoad(
                  delay: Duration(milliseconds: 50 + i * 60),
                  child: _MissionRow(
                    index: i,
                    title: kMissions[i].title,
                    done: done,
                    unlocked: unlocked,
                    onTap: unlocked ? () => controller.openMission(i) : null,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: MascotHelperBubble(
              pose: MascotPose.explaining,
              message: EdCopy.selectMascot,
              mascotHeight: 84,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  const _MissionRow({
    required this.index,
    required this.title,
    required this.done,
    required this.unlocked,
    this.onTap,
  });

  final int index;
  final String title;
  final bool done;
  final bool unlocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = done
        ? CareerColors.green
        : unlocked
            ? CareerColors.cyan
            : CareerColors.textMuted;
    return PressableScale(
      onTap: onTap,
      child: Opacity(
        opacity: unlocked ? 1 : 0.55,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: CareerColors.glassFillStrong,
            borderRadius: BorderRadius.circular(CareerRadii.smallCard),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.18),
                  border: Border.all(color: accent.withValues(alpha: 0.7)),
                ),
                child: Text('${index + 1}',
                    style: CareerText.statValue.copyWith(color: accent, fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: CareerText.cardTitle.copyWith(
                        fontSize: 14,
                        color: unlocked ? Colors.white : CareerColors.textSecondary)),
              ),
              Icon(
                done
                    ? Icons.check_circle_rounded
                    : unlocked
                        ? Icons.play_circle_fill_rounded
                        : Icons.lock_rounded,
                color: accent,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
