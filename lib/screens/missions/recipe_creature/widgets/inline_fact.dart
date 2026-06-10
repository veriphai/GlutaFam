// Inline fact (Layer 1) — the single 2-metres-of-DNA fact in Beat 0.2, beside
// the creature (PRD §8). Glanceable, skippable, NON-BLOCKING — never a gate.
// One slot; if it ever feels like filler, leave it empty rather than weaken it.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/creature_tuning.dart';
import '../config/prologue_beats.dart';
import '../state/recipe_creature_controller.dart';

class InlineFact extends StatefulWidget {
  const InlineFact({super.key, required this.controller});
  final RecipeCreatureController controller;

  @override
  State<InlineFact> createState() => _InlineFactState();
}

class _InlineFactState extends State<InlineFact> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.controller.showFact,
      builder: (context, show, _) {
        final visible = show && !_dismissed;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SizeTransition(sizeFactor: anim, axisAlignment: -1, child: child),
          ),
          child: !visible
              ? const SizedBox.shrink(key: ValueKey('fact-none'))
              : _Chip(
                  key: const ValueKey('fact'),
                  text: PrologueBeats.inlineFact,
                  onDismiss: () => setState(() => _dismissed = true),
                ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({super.key, required this.text, required this.onDismiss});
  final String text;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 230),
      padding: const EdgeInsets.fromLTRB(11, 9, 7, 9),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1426).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: RC.lifeGreen.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 14, color: RC.lifeGreen),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                height: 1.3,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Icon(Icons.close_rounded, size: 14, color: Colors.white.withValues(alpha: 0.45)),
            ),
          ),
        ],
      ),
    );
  }
}
