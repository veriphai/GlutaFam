// The live number layer — readouts anchored to the scene during the power-up:
// 100 IN at the top, a loss number on each leak as the flow reveals it, and at the
// bulb both answers the activity now asks — how much BECAME HEAT (≈62) and how
// much REACHED THE BULB (≈38). Mono (IBM Plex Mono), relative (no units) — the
// numbers label the stream; the stream + the escaping heat are the experience.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/leaky_chain_defs.dart';
import '../state/leaky_bucket_controller.dart';

class SceneNumbers extends StatelessWidget {
  const SceneNumbers({super.key, required this.controller});
  final LeakyBucketController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final stage = controller.stageSize;
        if (stage.isEmpty || !controller.powered) return const SizedBox.shrink();

        final segs = controller.segments;
        final centers = controller.nodeCenters;
        final input = controller.inputCenter;
        final bulb = controller.bulbCenter;
        final chips = <Widget>[];

        // 100 IN — centred above the coal feed.
        chips.add(Positioned(
          left: 0,
          right: 0,
          top: input.dy - controller.inputRadius - 34,
          child: const Center(child: _NumChip(value: '100', label: 'IN', color: kEnergyColor)),
        ));

        // Per-leak loss — revealed as the flow passes each machine.
        for (var i = 0; i < segs.length; i++) {
          final reveal = controller.leakReveal(i);
          if (reveal <= 0.02 || segs[i].leak < 0.5) continue;
          final c = centers[i];
          final onLeft = i.isEven;
          chips.add(Positioned(
            top: c.dy - 16,
            left: onLeft ? null : c.dx + controller.nodeRadius + 10,
            right: onLeft ? stage.width - (c.dx - controller.nodeRadius - 10) : null,
            child: Opacity(
              opacity: reveal,
              child: _NumChip(value: '−${segs[i].leak.round()}', label: 'HEAT', color: kHeatColor, dense: true),
            ),
          ));
        }

        // At the bulb — both answers: how much became heat, how much reached it.
        final br = controller.bulbReveal;
        if (br > 0.02) {
          chips.add(Positioned(
            left: 0,
            right: 0,
            top: bulb.dy + controller.bulbRadius + 16,
            child: Center(
              child: Opacity(
                opacity: br,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NumChip(value: '${controller.totalHeat.round()}', label: 'BECAME HEAT', color: kHeatColor, dense: true),
                    const SizedBox(height: 6),
                    _NumChip(value: '${controller.output.round()}', label: 'REACHES THE BULB', color: const Color(0xFFFFE9A8), emphasised: true),
                  ],
                ),
              ),
            ),
          ));
        }

        return IgnorePointer(child: Stack(children: chips));
      },
    );
  }
}

class _NumChip extends StatelessWidget {
  const _NumChip({required this.value, required this.label, required this.color, this.dense = false, this.emphasised = false});
  final String value;
  final String label;
  final Color color;
  final bool dense;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 11, vertical: dense ? 4 : 6),
      decoration: BoxDecoration(
        color: const Color(0xFF070C1E).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: emphasised ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 14, spreadRadius: 1)] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: GoogleFonts.ibmPlexMono(fontSize: emphasised ? 22 : (dense ? 14 : 17), fontWeight: FontWeight.w700, height: 1, color: color)),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.ibmPlexMono(fontSize: dense ? 7.5 : 8.5, fontWeight: FontWeight.w600, letterSpacing: 0.8, height: 1.1, color: Colors.white.withValues(alpha: 0.55))),
        ],
      ),
    );
  }
}
