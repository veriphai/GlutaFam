// The readouts — three numbers that together ARE the lesson:
//   • POWER (the hero card) — PINNED, always 1000 (= V × I). It never moves, however
//     hard you slide. That constancy is the whole point: you trade voltage for
//     current, but the power delivered is held fixed.
//   • VOLTAGE | CURRENT — the two that move, OPPOSITE each other (raise voltage →
//     current falls by itself).
// POWER is the steady gold card on top; VOLTAGE and CURRENT are the live gauges
// below. (Their product 1000 is now shown ON the POWER card — the pinned value made
// explicit, replacing the morphing area rectangle.)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/transmission_beats.dart';
import '../config/transmission_tuning.dart';
import '../state/transmission_controller.dart';

class ReadoutPanel extends StatelessWidget {
  const ReadoutPanel({super.key, required this.controller});

  final TransmissionController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PowerCard(value: controller.powerNumber),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GaugeChip(
                label: TTCopy.voltageLabel,
                value: controller.voltageNumber,
                norm: controller.voltageNorm,
                trend: controller.voltageTrend,
              ),
              const SizedBox(width: 14),
              _GaugeChip(
                label: TTCopy.currentLabel,
                value: controller.currentNumber,
                norm: controller.currentNorm,
                trend: controller.currentTrend,
                ring: controller.discoveryRing,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// THE PINNED POWER card — the steady hero readout. Gold, a lock glyph, the constant
/// value, and a "PINNED · V × I" tag. No needle bar (it never changes).
class _PowerCard extends StatelessWidget {
  const _PowerCard({required this.value});
  final int value;

  static const Color _accent = TTTune.gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.fromLTRB(18, 9, 18, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _accent.withValues(alpha: 0.14),
            _accent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _accent.withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.20),
            blurRadius: 18,
            spreadRadius: -3,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_rounded, size: 11, color: _accent.withValues(alpha: 0.85)),
                  const SizedBox(width: 4),
                  Text(
                    TTCopy.powerLabel,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                      color: _accent.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                TTCopy.powerPinnedTag,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.0,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value.toString(),
            style: GoogleFonts.ibmPlexMono(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.0,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugeChip extends StatelessWidget {
  const _GaugeChip({
    required this.label,
    required this.value,
    required this.norm,
    required this.trend,
    this.ring = 0,
  });

  final String label;
  final int value;
  final double norm;
  final int trend;
  final double ring;

  static const Color _accent = TTTune.gold;

  @override
  Widget build(BuildContext context) {
    final flare = ring.clamp(0.0, 1.0);
    return Container(
      width: 140,
      padding: const EdgeInsets.fromLTRB(13, 8, 13, 9),
      decoration: BoxDecoration(
        color: TTTune.chipGlass,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Color.lerp(
            Colors.white.withValues(alpha: 0.14),
            _accent.withValues(alpha: 0.5),
            (norm + flare).clamp(0.0, 1.0),
          )!,
        ),
        boxShadow: (norm > 0.02 || flare > 0.01)
            ? [
                BoxShadow(
                  color: _accent.withValues(alpha: (0.16 * norm + 0.45 * flare).clamp(0.0, 0.6)),
                  blurRadius: 10 + 8 * norm + 16 * flare,
                  spreadRadius: -2 + 3 * flare,
                ),
              ]
            : null,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
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
                  color: _accent.withValues(alpha: 0.82),
                ),
              ),
              const Spacer(),
              Text(
                value.toString(),
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(
                width: 14,
                child: Icon(
                  trend > 0
                      ? Icons.arrow_drop_up_rounded
                      : (trend < 0 ? Icons.arrow_drop_down_rounded : null),
                  size: 18,
                  color: _accent.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _NeedleBar(value: norm),
        ],
      ),
    );
  }
}

/// A thin accent bar — its filled length is the instrument needle, riding the value.
class _NeedleBar extends StatelessWidget {
  const _NeedleBar({required this.value});
  final double value;

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
                  color: _GaugeChip._accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                height: 3,
                width: w * value.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  color: _GaugeChip._accent.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: value > 0.02
                      ? [BoxShadow(color: _GaugeChip._accent.withValues(alpha: 0.5 * value), blurRadius: 5)]
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
