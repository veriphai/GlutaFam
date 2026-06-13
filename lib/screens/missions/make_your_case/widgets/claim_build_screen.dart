// Screen 2 — Claim ("So, what's your answer?", PRD §4.2). The question + ONLY the
// evidence the kid kept (the screen is already lighter). The claim is BUILT, not
// chosen from full pre-written options (§5.2): a near-complete sentence with the
// episode's key ideas as the kid's taps (2–3 slots from the config's template),
// each a quick tap from 2–3 chips. They're AUTHORING the claim — that's what
// keeps the synthesis theirs.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../episode_board/photo_card.dart';
import '../state/cer_controller.dart';
import 'cer_chrome.dart';

class ClaimBuildScreen extends StatelessWidget {
  const ClaimBuildScreen({super.key, required this.controller});

  final CerController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final kept = c.keptTiles;

    return Column(
      children: [
        CerQuestionHeader(question: c.config.question, step: 2),
        const SizedBox(height: 14),
        // Only the kept evidence — the lighter screen (§4.2).
        if (kept.isNotEmpty)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < kept.length; i++)
                PhotoCard(
                  tile: kept[i],
                  size: 42,
                  showLabel: false,
                  tilt: (i.isEven ? 1 : -1) * 0.04,
                  imageBytes: c.imageBytes[kept[i].id],
                )
            ],
          ),
        const SizedBox(height: 16),
        Text(
          c.config.claimTask,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _ClaimSentence(controller: c),
                const SizedBox(height: 22),
                for (var i = 0; i < c.slotValues.length; i++) ...[
                  if (i > 0) const SizedBox(height: 16),
                  _SlotChips(
                    caption: c.config.slotCaptions[i],
                    options: c.config.slotOptions[i],
                    selected: c.slotValues[i],
                    onPick: (v) {
                      HapticFeedback.selectionClick();
                      c.setSlot(i, v);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        CerCtaPill(
          label: c.config.toPlaybackCta,
          enabled: c.claimReady,
          onTap: c.goToPlayback,
        ),
      ],
    );
  }
}

/// The claim, assembled live as the kid taps. The slots highlight as the
/// editable ideas; everything else is fixed scaffolding (the config's text
/// parts, interleaved with the slot tokens; empty parts render nothing).
class _ClaimSentence extends StatelessWidget {
  const _ClaimSentence({required this.controller});
  final CerController controller;

  @override
  Widget build(BuildContext context) {
    const fixed = TextStyle(fontSize: 18, height: 1.5, fontWeight: FontWeight.w600, color: Colors.white);
    final config = controller.config;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1330).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 8,
        children: [
          for (var i = 0; i < controller.slotValues.length; i++) ...[
            if (config.textParts[i].isNotEmpty) Text(config.textParts[i], style: fixed),
            _SlotToken(value: controller.slotValues[i], placeholder: config.slotPlaceholders[i]),
          ],
          if (config.textParts.last.isNotEmpty) Text(config.textParts.last, style: fixed),
        ],
      ),
    );
  }
}

class _SlotToken extends StatelessWidget {
  const _SlotToken({required this.value, required this.placeholder});
  final String? value;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final filled = value != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? const Color(0xFFF5C451).withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: filled ? const Color(0xFFF5C451) : Colors.white.withValues(alpha: 0.3),
          width: filled ? 1.6 : 1.2,
        ),
      ),
      child: Text(
        value ?? placeholder,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: filled ? const Color(0xFFFFD970) : Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _SlotChips extends StatelessWidget {
  const _SlotChips({
    required this.caption,
    required this.options,
    required this.selected,
    required this.onPick,
  });

  final String caption;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          caption.toUpperCase(),
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: Colors.white.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            for (final o in options)
              GestureDetector(
                onTap: () => onPick(o),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                  decoration: BoxDecoration(
                    color: selected == o ? const Color(0xFFF5C451) : Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected == o ? const Color(0xFFF5C451) : Colors.white.withValues(alpha: 0.18),
                    ),
                    boxShadow: selected == o
                        ? [BoxShadow(color: const Color(0xFFF5C451).withValues(alpha: 0.4), blurRadius: 12)]
                        : null,
                  ),
                  child: Text(
                    o,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: selected == o ? const Color(0xFF1A1340) : Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
