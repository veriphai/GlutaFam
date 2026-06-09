// Badge Reveal (PRD §21): the main Satellite Engineer badge pops in first,
// the 5 skill badges follow in a grid, each with a glow pop + cue sound
// (controller's badge script staggers `revealed`). One-line tap-to-reveal
// description per badge; Continue exits the mission.

import 'package:flutter/material.dart';

import '../config/scc_assets.dart';
import '../config/scc_dialogue.dart';
import '../config/scc_stage_configs.dart';
import '../config/scc_theme.dart';
import '../state/mission_stage_controller.dart';
import '../widgets/scc_buttons.dart';

class BadgeScene extends StatelessWidget {
  const BadgeScene({super.key, required this.controller, required this.onExit});

  final MissionStageController controller;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final b = controller.state.badges;
        final main = kBadgeOrder.first;
        final skills = kBadgeOrder.sublist(1);
        return Stack(
          fit: StackFit.expand,
          children: [
            // backdrop comes from the SHELL (full-screen holo console, no
            // seam under the dialogue strip)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                child: Column(
                  children: [
                    Text('BADGES EARNED',
                        style: SccText.missionTitle.copyWith(fontSize: 18)),
                    const SizedBox(height: 10),
                    // main badge
                    Expanded(
                      flex: 5,
                      child: _BadgePop(
                        visible: b.revealed >= 1,
                        big: true,
                        id: main.$1,
                        label: main.$2,
                        sprite: main.$3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // skill badges grid (2 rows of flex tiles — fill the slot)
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          for (var row = 0; row < 2; row++)
                            Expanded(
                              child: Row(
                                children: [
                                  for (var col = 0; col < 3; col++)
                                    if (row * 3 + col < skills.length)
                                      Expanded(
                                        child: _BadgePop(
                                          visible: b.revealed >= row * 3 + col + 2,
                                          big: false,
                                          id: skills[row * 3 + col].$1,
                                          label: skills[row * 3 + col].$2,
                                          sprite: skills[row * 3 + col].$3,
                                        ),
                                      ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SccCta(
                      label: 'CONTINUE',
                      icon: Icons.arrow_forward_rounded,
                      enabled: b.continueEnabled,
                      onTap: onExit,
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BadgePop extends StatelessWidget {
  const _BadgePop({
    required this.visible,
    required this.big,
    required this.id,
    required this.label,
    required this.sprite,
  });

  final bool visible;
  final bool big;
  final String id;
  final String label;
  final String sprite;

  @override
  Widget build(BuildContext context) {
    final blurb = SccDialogue.badgeLines[id];
    return AnimatedScale(
      duration: const Duration(milliseconds: 450),
      curve: Curves.elasticOut,
      scale: visible ? 1 : 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: visible ? 1 : 0,
        child: Tooltip(
          message: blurb ?? '',
          triggerMode: TooltipTriggerMode.tap,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: SccColors.cyan.withValues(alpha: big ? 0.5 : 0.2),
                          blurRadius: big ? 44 : 14,
                          spreadRadius: big ? 6 : 0,
                        ),
                      ],
                    ),
                    child: sccImage(SCC.flutter(sprite), fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 3),
                Text(label,
                    textAlign: TextAlign.center,
                    style: SccText.label.copyWith(fontSize: big ? 12 : 8.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
