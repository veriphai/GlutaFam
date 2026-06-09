// Scene 2 — Height Exploration (PRD §10 Scene 2, the main playable scene).
//
// The Flame [HeightStageGame] renders the animated stage (passed in prebuilt so
// it's never re-attached). On top: the mission header, the draggable height rail
// (left), the Mission Control panel (bottom), and — only after the satellite
// reveal — the TAKE CHALLENGE CTA.

import 'package:flutter/material.dart';

import '../../../home/career/careerTheme.dart';
import '../config/scene_copy.dart';
import '../state/how_much_controller.dart';
import '../widgets/cta_button.dart';
import '../widgets/height_rail.dart';
import '../widgets/mission_header.dart';
import '../widgets/orbit_message.dart';

class ExplorationScene extends StatelessWidget {
  const ExplorationScene({
    super.key,
    required this.controller,
    required this.stage,
    required this.onHome,
  });

  final HowMuchController controller;
  final Widget stage; // the cached Flame GameWidget
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final s = controller.state;
    final cfg = s.currentConfig;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          children: [
            const SizedBox(height: 6),
            MissionHeader(visited: s.visitedLevels, onHome: onHome),
            const SizedBox(height: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(CareerRadii.card),
                child: Stack(
                  children: [
                    Positioned.fill(child: stage),
                    // Height rail on the left (PRD §21).
                    Positioned(
                      left: 2,
                      top: 6,
                      bottom: 6,
                      child: HeightRail(
                        currentLevel: s.currentLevel,
                        visited: s.visitedLevels,
                        onSelect: controller.setLevel,
                        nudgeUp: s.showDragHint,
                      ),
                    ),
                    // Idle drag hint (PRD §24).
                    Positioned(
                      left: 96,
                      top: 12,
                      child: AnimatedOpacity(
                        opacity: s.showDragHint ? 1 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xCC0B2550),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: CareerColors.cyan.withValues(alpha: 0.5)),
                          ),
                          child: Text(SceneCopy.dragHint,
                              style: CareerText.body
                                  .copyWith(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Orbit + message sit CENTRED in the bottom band until the
            // challenge CTA appears; then they shift up (animated) to make room
            // for it. The gap totals match in both states (35+35 ≈ 8+10+52), so
            // the stage height never jumps.
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              height: s.showTakeChallenge ? 8 : 35,
            ),
            OrbitMessage(
              mood: s.mascot,
              message: s.missionControlMessage,
              viewLabel: cfg.viewLabel,
              problemLabel: cfg.problemLabel,
              isBest: cfg.isBest,
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              height: s.showTakeChallenge ? 10 : 35,
            ),
            // CTA slot grows 0 → 52 as it reveals (child laid out at full height
            // inside an OverflowBox + clipped, so nothing overflows mid-anim).
            ClipRect(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                height: s.showTakeChallenge ? 52 : 0,
                child: OverflowBox(
                  minHeight: 52,
                  maxHeight: 52,
                  alignment: Alignment.topCenter,
                  child: AnimatedOpacity(
                    opacity: s.showTakeChallenge ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: CtaButton(
                      label: SceneCopy.takeChallenge,
                      gradient: CareerGradients.challengeCta,
                      icon: Icons.bolt_rounded,
                      onTap: controller.takeChallenge,
                      // Listen-before-act: wait for the satellite line to end.
                      enabled: !s.voicePlaying,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
