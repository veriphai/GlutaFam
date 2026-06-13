// The two live numbers (PRD §4: exactly 2, relative 0–100, no units). CURRENT and
// HEAT as instrument gauges matching 2.1/2.2: mono rolling digits, a value-linked
// glow, a thin accent needle/bar whose length rides the value, and an ↑/↓ trend
// glyph. Both warm-accent (HEAT ember, CURRENT warm gold). These ride ALONGSIDE
// the wire's glow — the warmth is the felt readout; these stay small. Exactly TWO.

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/heat_wire_beats.dart';
import '../state/heat_wire_controller.dart';

class ReadoutChips extends StatelessWidget {
  const ReadoutChips({super.key, required this.controller});

  final HeatWireController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Chip(
          label: HWCopy.chipCurrent,
          value: controller.currentDisplay,
          trend: controller.currentTrend,
          accent: const Color(0xFFFFD27A), // warm gold
        ),
        const SizedBox(width: 12),
        _Chip(
          label: HWCopy.chipHeat,
          value: controller.heatDisplay,
          trend: controller.heatTrend,
          accent: const Color(0xFFFF7A2E), // ember
          // HEAT shares the hero's exact ember — damp its card flare so the eye
          // reads the WIRE for heat and the chip just confirms it (digits stay full).
          emphasis: 0.7,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.value,
    required this.trend,
    required this.accent,
    this.emphasis = 1.0,
  });

  final String label;
  final ValueListenable<int> value;
  final ValueListenable<int> trend;
  final Color accent;
  final double emphasis; // <1 damps the card flare (glow/border/needle glow) only

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: value,
      builder: (context, v, _) {
        final norm = (v / 100.0).clamp(0.0, 1.0);
        return Container(
          width: 134, // fits a 3-digit value ("100") without overflow
          padding: const EdgeInsets.fromLTRB(12, 7, 12, 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              // the border warms with the value (instrument-grade live read).
              color: Color.lerp(
                Colors.white.withValues(alpha: 0.12),
                accent.withValues(alpha: 0.45),
                norm * emphasis,
              )!,
            ),
            // value-linked glow — recedes vs the warm hero (capped low, × emphasis).
            boxShadow: norm > 0.02
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.16 * norm * emphasis),
                      blurRadius: 10 + 8 * norm,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          // thin top gloss so the dark glass reads dimensional (matches 2.1/2.2).
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.42],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    v.toString().padLeft(2, '0'),
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 3),
                  SizedBox(
                    width: 12,
                    child: ValueListenableBuilder<int>(
                      valueListenable: trend,
                      builder: (context, t, _) => Icon(
                        t > 0
                            ? Icons.arrow_drop_up_rounded
                            : (t < 0 ? Icons.arrow_drop_down_rounded : null),
                        size: 18,
                        color: accent.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              // the instrument needle/bar — length rides the value.
              _NeedleBar(value: norm, accent: accent, emphasis: emphasis),
            ],
          ),
        );
      },
    );
  }
}

/// A thin accent bar under the value — its filled length is the instrument needle,
/// riding the chip's value. Matches the 2.1/2.2 gauge needle.
class _NeedleBar extends StatelessWidget {
  const _NeedleBar({required this.value, required this.accent, this.emphasis = 1.0});
  final double value;
  final Color accent;
  final double emphasis;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return Stack(
            children: [
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                height: 3,
                width: w * value,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: value > 0.02
                      ? [BoxShadow(color: accent.withValues(alpha: 0.5 * value * emphasis), blurRadius: 5)]
                      : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
