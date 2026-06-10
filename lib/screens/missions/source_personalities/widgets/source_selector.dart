// Source selector — calm, recessed chrome (PRD §7): the town is the brightest,
// most alive thing, so these stay quiet glass chips. All six sources fit in one
// row of equal-width chips (no scroll, nothing spills past the dock). Selecting
// one gives a soft accent glow + a haptic; a TRIED source gets a green border +
// check badge (so the kid sees which ones are left — they must run every source).
// NO ratings/stars/attribute labels (PRD §4.4) — just name + icon.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../home/career/careerCommon.dart';
import '../config/source_personality_defs.dart';
import '../state/source_personalities_controller.dart';

class SourceSelector extends StatelessWidget {
  const SourceSelector({super.key, required this.controller});
  final SourcePersonalitiesController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SourceKind?>(
      valueListenable: controller.activeSource,
      builder: (context, active, _) {
        return ValueListenableBuilder<Set<SourceKind>>(
          valueListenable: controller.explored,
          builder: (context, exploredSet, __) {
            return SizedBox(
              height: 70,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (var i = 0; i < kSources.length; i++) ...[
                    if (i > 0) const SizedBox(width: 7),
                    Expanded(
                      child: _SourceChip(
                        source: kSources[i],
                        selected: active == kSources[i].kind,
                        explored: exploredSet.contains(kSources[i].kind),
                        onTap: () => controller.selectSource(kSources[i].kind),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip(
      {required this.source, required this.selected, required this.explored, required this.onTap});
  final SourcePersonality source;
  final bool selected;
  final bool explored;
  final VoidCallback onTap;

  static const Color _green = Color(0xFF3FD99B);

  @override
  Widget build(BuildContext context) {
    final accent = source.accent;
    // Border priority: selected (source colour) > explored/catch-seen (green) > idle.
    final Color border = selected
        ? accent.withValues(alpha: 0.85)
        : explored
            ? _green.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.1);
    return PressableScale(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        // Pass the Expanded's full-width constraint through to the chip body so it
        // FILLS its slot (StackFit.loose would shrink it to its content width).
        fit: StackFit.passthrough,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 64,
            decoration: BoxDecoration(
              color: selected
                  ? accent.withValues(alpha: 0.18)
                  : explored
                      ? _green.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: border, width: selected || explored ? 1.6 : 1),
              boxShadow: selected
                  ? [BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: -2)]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(source.icon, size: 22, color: selected ? accent : Colors.white.withValues(alpha: 0.78)),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    source.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected ? Colors.white : Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Green check badge (top-right) once this source's CATCH has been seen.
          if (explored)
            Positioned(
              top: -5,
              right: -3,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0B1124), width: 1.5),
                ),
                child: const Icon(Icons.check_rounded, size: 10, color: Color(0xFF0B1124)),
              ),
            ),
        ],
      ),
    );
  }
}
