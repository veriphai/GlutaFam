// Screen 1 — Evidence ("Which of these clues answer the question?", PRD §4.1).
// The pinned question + the captured moment-tiles, staged so ≤6 are visible at
// once. The kid taps the tiles that bear on the question → they're kept; the
// irrelevant ones (still magnet, turbine) are simply left behind. This is
// selection (low-friction, tappable), but the act of DISCRIMINATING relevant from
// irrelevant is the reasoning — so there is NO correct/wrong feedback (§5.4):
// tapping only toggles a tile in or out of the case.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../../home/career/careerCommon.dart';
import '../../episode_board/evidence_tile.dart';
import '../config/cer_copy.dart';
import '../state/cer_controller.dart';
import 'cer_chrome.dart';

class EvidenceSelectScreen extends StatelessWidget {
  const EvidenceSelectScreen({super.key, required this.controller});

  final CerController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final tiles = c.stageTiles;
    final lastStage = c.evidenceStage >= c.totalStages - 1;
    final width = MediaQuery.of(context).size.width;
    final tileSize = ((width - 32 - 16) / 2).clamp(120.0, 168.0);

    return Column(
      children: [
        const CerQuestionHeader(step: 1),
        const SizedBox(height: 18),
        Text(
          CerCopy.evidenceTask,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15),
        ),
        const SizedBox(height: 4),
        Text(
          CerCopy.evidenceHint,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: Wrap(
                  key: ValueKey(c.evidenceStage),
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final t in tiles)
                      PressableScale(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          c.openPreview(t.id); // tap opens the clue to inspect + keep
                        },
                        child: EvidenceTileView(
                          tile: t,
                          size: tileSize,
                          selected: c.kept.contains(t.id),
                          showSource: true,
                          imageBytes: c.imageBytes[t.id],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _CollectedBar(controller: c),
        const SizedBox(height: 12),
        Row(
          children: [
            if (c.evidenceStage > 0) ...[
              CerCtaPill(
                label: CerCopy.backCta,
                icon: Icons.arrow_back_rounded,
                filled: false,
                onTap: c.prevStage,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: lastStage
                  ? CerCtaPill(label: CerCopy.toClaimCta, onTap: c.goToClaim)
                  : CerCtaPill(label: CerCopy.moreCta, onTap: c.nextStage),
            ),
          ],
        ),
      ],
    );
  }
}

/// A slim "what's in your case so far" bar — a count + one accent dot per kept
/// clue. Deliberately NOT full tiles, so the screen's visible TILE count stays
/// within the ≤6 cap (§6); the kept pile is revealed in full on Screen 2.
class _CollectedBar extends StatelessWidget {
  const _CollectedBar({required this.controller});
  final CerController controller;

  @override
  Widget build(BuildContext context) {
    final kept = controller.keptTiles;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2_rounded, size: 15, color: Colors.white.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Text(
            kept.isEmpty
                ? 'Your case is empty'
                : '${kept.length} clue${kept.length == 1 ? '' : 's'} in your case',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.8)),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final t in kept)
                Container(
                  margin: const EdgeInsets.only(left: 5),
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: t.accent,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: t.accent.withValues(alpha: 0.6), blurRadius: 5)],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
