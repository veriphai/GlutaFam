// The output-swap affordance (PRD §4.7). INACCESSIBLE until
// `hasLitOnce && hasStoppedOnce` (criterion 8) — the generalisation cannot
// appear before the discovery. Locked state = dimmed AND IgnorePointer (a dim
// button that still fires is a UX trap — see the playbook gotcha), with a small
// lock hint. Once unlocked it fades in and the learner swaps lamp → fan →
// heater → speaker, all driven by the SAME crank/energy.

import 'package:flutter/material.dart';

import '../../../home/career/careerTheme.dart';
import '../config/output_defs.dart';
import '../state/crank_controller.dart';

class OutputSwapTray extends StatelessWidget {
  const OutputSwapTray({super.key, required this.controller});

  final CrankController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.swapUnlocked,
      builder: (context, unlocked, _) {
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 450),
          opacity: unlocked ? 1 : 0.4,
          child: IgnorePointer(
            ignoring: !unlocked,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      unlocked ? Icons.swap_horiz_rounded : Icons.lock_rounded,
                      size: 13,
                      color: CareerColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      unlocked
                          ? 'Same crank — swap the device'
                          : 'Crank, then stop to unlock more',
                      style: CareerText.statLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                ValueListenableBuilder<ActiveOutput>(
                  valueListenable: controller.activeOutput,
                  builder: (context, active, __) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final out in kOutputOrder)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: _OutputChip(
                              def: kOutputDefs[out]!,
                              selected: out == active,
                              onTap: () => controller.setActiveOutput(out),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OutputChip extends StatelessWidget {
  const _OutputChip({required this.def, required this.selected, required this.onTap});

  final OutputDef def;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? def.accent.withValues(alpha: 0.22) : CareerColors.glassFill,
          borderRadius: BorderRadius.circular(CareerRadii.chip),
          border: Border.all(
            color: selected ? def.accent : CareerColors.glassBorder,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(def.icon, size: 22, color: selected ? def.accent : CareerColors.textSecondary),
            const SizedBox(height: 5),
            Text(
              def.label,
              style: CareerText.chip.copyWith(
                color: selected ? CareerColors.textPrimary : CareerColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
