// Cost meter — a quiet, refined readout that CLIMBS (PRD §7): cost is a felt
// consequence, not a loud number. A thin bar that fills with runningCost plus a
// small relative figure. Deliberately unit-less / relative (PRD §4.4): no money,
// no megawatts — just "this is costing more". Climbs on coal/gas runtime; LEAPS
// on nuclear's build cost.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../state/source_personalities_controller.dart';

class CostMeter extends StatelessWidget {
  const CostMeter({super.key, required this.controller});
  final SourcePersonalitiesController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final f = controller.costFraction;
        if (!controller.sim.hasSource) return const SizedBox.shrink();
        // A calm cool→warm shift as it climbs — felt, never alarming.
        final barColor = Color.lerp(const Color(0xFF6FA8C8), const Color(0xFFE08A4D), f)!;
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 9),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1330).withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bounded to the bar width below so the Spacer has a definite
              // width (an unbounded Spacer here collapsed the whole telemetry row).
              SizedBox(
                width: 96,
                child: Row(
                  children: [
                    Text(
                      'COST',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      controller.sim.runningCost.round().toString(),
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: barColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  width: 96,
                  height: 5,
                  child: Stack(
                    children: [
                      Container(color: Colors.white.withValues(alpha: 0.08)),
                      FractionallySizedBox(
                        widthFactor: f.clamp(0.0, 1.0),
                        child: Container(color: barColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
