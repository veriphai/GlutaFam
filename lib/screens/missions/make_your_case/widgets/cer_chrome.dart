// Shared chrome for the three closing screens — the pinned guiding question and
// the primary CTA pill. Every screen = the pinned question + ONE task + a handful
// of tiles, nothing else (PRD §6). Keeping these here makes that restraint uniform.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/cer_copy.dart';

/// The guiding question, pinned at the top of every closing screen (PRD §4).
class CerQuestionHeader extends StatelessWidget {
  const CerQuestionHeader({super.key, this.step, this.totalSteps = 3});

  /// 1-based step index (1..3) for the tiny progress dots; null hides them.
  final int? step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 13),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1330).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CareerColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.travel_explore_rounded, size: 15, color: CareerColors.gold.withValues(alpha: 0.9)),
              const SizedBox(width: 6),
              Text(
                'THE QUESTION',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                  color: CareerColors.gold.withValues(alpha: 0.85),
                ),
              ),
              const Spacer(),
              if (step != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 1; i <= totalSteps; i++)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        width: i == step ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == step
                              ? CareerColors.gold
                              : Colors.white.withValues(alpha: i < step! ? 0.5 : 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CerCopy.question,
            style: const TextStyle(
              fontSize: 15.5,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// The one primary action per screen. [enabled] dims + blocks taps when false.
class CerCtaPill extends StatelessWidget {
  const CerCtaPill({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.icon = Icons.arrow_forward_rounded,
    this.filled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final IconData icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final pill = Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          gradient: filled ? CareerGradients.gold : null,
          color: filled ? null : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(CareerRadii.pill),
          border: filled ? null : Border.all(color: Colors.white.withValues(alpha: 0.22)),
          boxShadow: filled
              ? [BoxShadow(color: CareerColors.gold.withValues(alpha: 0.45), blurRadius: 18, offset: const Offset(0, 5))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: CareerText.cta.copyWith(
                color: filled ? CareerColors.onLight : Colors.white,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 6),
            Icon(icon, size: 20, color: filled ? CareerColors.onLight : Colors.white),
          ],
        ),
      ),
    );
    return IgnorePointer(
      ignoring: !enabled,
      child: PressableScale(onTap: enabled ? onTap : () {}, child: pill),
    );
  }
}
