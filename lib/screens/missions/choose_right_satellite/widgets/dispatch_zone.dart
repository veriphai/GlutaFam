// The glowing dispatch drop zone (PRD §10.4, §14.1/§14.3). Idle: the dashed
// glow ring pulses slowly. Hover: the brighter target-pulse ring fades in and
// the "DISPATCH HERE" label lifts. Purely visual — the DragTarget lives on the
// mission card around it.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../../../../utils/s3_assets.dart';

class DispatchZone extends StatefulWidget {
  const DispatchZone({super.key, required this.hovering, required this.diameter});

  final bool hovering;
  final double diameter;

  @override
  State<DispatchZone> createState() => _DispatchZoneState();
}

class _DispatchZoneState extends State<DispatchZone> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.diameter,
      height: widget.diameter,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final idlePulse = 0.5 + 0.5 * math.sin(_c.value * 2 * math.pi);
          return Stack(
            alignment: Alignment.center,
            children: [
              // Idle dashed glow ring — gentle breathing scale + opacity.
              Transform.scale(
                scale: 0.96 + 0.04 * idlePulse,
                child: Opacity(
                  opacity: 0.55 + 0.25 * idlePulse,
                  child: netImageWidget(CrsAssets.dispatchGlowRing, fit: BoxFit.contain),
                ),
              ),
              // Brighter active target ring on hover.
              AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: widget.hovering ? 1 : 0,
                child: Transform.scale(
                  scale: 1.0 + 0.06 * idlePulse,
                  child: netImageWidget(CrsAssets.dispatchTargetPulse, fit: BoxFit.contain),
                ),
              ),
              AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                offset: widget.hovering ? const Offset(0, -0.04) : Offset.zero,
                child: Text(
                  'DISPATCH\nHERE',
                  textAlign: TextAlign.center,
                  style: CareerText.label.copyWith(
                    fontSize: 10.5,
                    height: 1.15,
                    letterSpacing: 1.4,
                    color: widget.hovering ? Colors.white : CareerColors.cyan,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
