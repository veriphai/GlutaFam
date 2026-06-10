// The 0.2 "peek under" panel — reveals that one gene's value as a long, repeating
// A/T/C/G string in mono type (PRD §6 Beat 0.2). The neutral control label
// quietly resolves to its real sense. ILLUSTRATIVE letters only (see Genome).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/creature_tuning.dart';
import '../config/genome.dart';
import '../state/recipe_creature_controller.dart';

class DnaPeek extends StatelessWidget {
  const DnaPeek({super.key, required this.controller});
  final RecipeCreatureController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.peekOpen,
      builder: (context, open, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SizeTransition(sizeFactor: anim, axisAlignment: -1, child: child),
          ),
          child: !open
              ? const SizedBox(width: double.infinity, key: ValueKey('peek-none'))
              : _Panel(
                  key: const ValueKey('peek-open'),
                  label: '${controller.peekField.label} instruction',
                  // Read off the live creature's gene (mode is `live` in 0.2).
                  code: controller.displayGenome.encodeForDisplay(controller.peekField),
                ),
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({super.key, required this.label, required this.code});
  final String label;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 13),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1224).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RC.lifeAmber.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.ibmPlexMono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: RC.lifeAmber.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            code,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}
