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
import '../../episode_board/photo_card.dart';
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
    final cardW = (width - 48) / 2;
    final photo = (cardW / 1.12).clamp(110.0, 170.0);

    return Column(
      children: [
        CerQuestionHeader(question: c.config.question, step: 1),
        const SizedBox(height: 18),
        Text(
          c.config.evidenceTask,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15),
        ),
        const SizedBox(height: 4),
        Text(
          c.config.evidenceHint,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 18),
        // The bulb hint — offered only AFTER a first unaided pass (once the kid has
        // bounced off the playback gate), so the first attempt stays their own.
        if (c.attemptedFinish) ...[
          _EvidenceHintRow(controller: c),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: Wrap(
                  key: ValueKey(c.evidenceStage),
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 18,
                  children: [
                    for (var i = 0; i < tiles.length; i++)
                      PressableScale(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          c.openPreview(tiles[i].id); // tap opens the clue to inspect + keep
                        },
                        child: PhotoCard(
                          tile: tiles[i],
                          size: photo,
                          kept: c.kept.contains(tiles[i].id),
                          tilt: (i.isEven ? 1 : -1) * 0.025,
                          imageBytes: c.imageBytes[tiles[i].id],
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
                label: c.config.backCta,
                icon: Icons.arrow_back_rounded,
                filled: false,
                onTap: c.prevStage,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: lastStage
                  ? CerCtaPill(label: c.config.toClaimCta, onTap: c.goToClaim)
                  : CerCtaPill(label: c.config.moreCta, onTap: c.nextStage),
            ),
          ],
        ),
      ],
    );
  }
}

// The on-demand hint: a "Need a hint?" bulb that reveals where the missing
// clue(s) are and/or which kept clue is the distractor. The hint recomputes live
// as the kid toggles clues — so once the case is solved it flips to an all-clear.
const Color _hintGold = Color(0xFFE0B24C);

class _EvidenceHintRow extends StatelessWidget {
  const _EvidenceHintRow({required this.controller});
  final CerController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final hint = c.hintText;
    return Column(
      children: [
        PressableScale(
          onTap: c.toggleHint,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _hintGold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _hintGold.withValues(alpha: 0.45)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, size: 15, color: _hintGold),
                const SizedBox(width: 6),
                Text(
                  c.hintRevealed ? 'Hide hint' : 'Need a hint?',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFFF0D08A)),
                ),
              ],
            ),
          ),
        ),
        if (c.hintRevealed) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _hintGold.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _hintGold.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(hint == null ? Icons.check_circle_rounded : Icons.lightbulb_rounded,
                    size: 16, color: _hintGold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hint ?? 'Your case looks complete — head to "State your answer".',
                    style: TextStyle(fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.92)),
                  ),
                ),
              ],
            ),
          ),
        ],
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
