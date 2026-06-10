// Power readout — the live telemetry panel (update spec §2, §3). A real POWER
// number with units + a rise/fall trend arrow, and (for variable sources) the
// DRIVER as a live number right below it — windspeed, sunlight, water flow.
// The kid watches the driver and the power rise and fall TOGETHER and deduces the
// rule. Quiet glass, riding alongside the scene; the city stays the hero.
//
// NOT a static ratings table (the banned anti-pattern) — these are genuine
// physical quantities changing in real time.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../state/source_personalities_controller.dart';

class PowerReadout extends StatelessWidget {
  const PowerReadout({super.key, required this.controller});
  final SourcePersonalitiesController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.sim.hasSource) return const SizedBox.shrink();
        final kw = controller.displayPowerKW;
        final trend = controller.powerTrend;
        final accent = controller.source?.accent ?? const Color(0xFF7FB4E0);
        final dLabel = controller.driverLabel;
        final dValue = controller.driverValue;
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
              Text(
                'POWER',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    kw.toStringAsFixed(1),
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: Text(
                      'kW',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _TrendArrow(trend: trend),
                ],
              ),
              if (dLabel != null && dValue != null) ...[
                const SizedBox(height: 6),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dLabel,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: accent.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dValue,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TrendArrow extends StatelessWidget {
  const _TrendArrow({required this.trend});
  final int trend;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (trend) {
      1 => (Icons.arrow_upward_rounded, const Color(0xFF7CE0A8)),
      -1 => (Icons.arrow_downward_rounded, const Color(0xFFE8896B)),
      _ => (Icons.trending_flat_rounded, Colors.white.withValues(alpha: 0.4)),
    };
    return Icon(icon, size: 16, color: color);
  }
}
