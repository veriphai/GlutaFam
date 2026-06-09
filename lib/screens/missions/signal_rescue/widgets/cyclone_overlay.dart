// The cyclone on the Earth's ocean — the storm the satellite photographed.
// Pure Flutter, factor-anchored over the (fixed) Flame stage: a slowly spinning
// top-down swirl, plus briefing highlights — a pulsing ring + label around the
// WHOLE storm while Orbit introduces the cyclone (briefing line 1), then a tight
// ring on its EYE (line 2).

import 'package:flutter/material.dart';

import '../../../../utils/s3_assets.dart';
import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../config/signal_tuning.dart';

enum CycloneHighlight { none, whole, eye }

class CycloneOverlay extends StatefulWidget {
  const CycloneOverlay({super.key, this.highlight = CycloneHighlight.none});

  final CycloneHighlight highlight;

  @override
  State<CycloneOverlay> createState() => _CycloneOverlayState();
}

class _CycloneOverlayState extends State<CycloneOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
      vsync: this, duration: const Duration(seconds: 26))
    ..repeat(); // cyclones spin — slow and ambient
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final h = box.maxHeight;
      final size = SRTune.cycloneWidthFactor * w;
      final cx = SRTune.cycloneCenter.dx * w;
      final cy = SRTune.cycloneCenter.dy * h;
      final hl = widget.highlight;

      return Stack(
        children: [
          // the spinning storm
          Positioned(
            left: cx - size / 2,
            top: cy - size / 2,
            width: size,
            height: size,
            child: RotationTransition(
              turns: _spin,
              child: netImageWidget(SR.flutter(SR.cycloneStorm),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          ),
          // briefing pointer: a label chip + bobbing arrow pointing DOWN at the
          // storm (line 1) or right at its eye (line 2)
          if (hl != CycloneHighlight.none)
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) {
                final eye = hl == CycloneHighlight.eye;
                final bob = _pulse.value * size * 0.07; // gentle up-down nudge
                // arrow tip hovers just above its target (storm top vs centre)
                final tipY = eye ? cy - size * 0.10 : cy - size * 0.56;
                final arrowSize = eye ? size * 0.26 : size * 0.34;
                final blockH = arrowSize + 30; // arrow + chip
                return Positioned(
                  left: cx - size,
                  top: tipY - blockH - bob,
                  width: size * 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E1E3C).withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: CareerColors.gold.withValues(alpha: 0.8), width: 1.2),
                        ),
                        child: Text(
                          eye ? 'THE EYE' : 'CYCLONE',
                          style: CareerText.label.copyWith(color: CareerColors.gold, fontSize: 9.5),
                        ),
                      ),
                      Icon(
                        Icons.arrow_downward_rounded,
                        size: arrowSize,
                        color: CareerColors.gold,
                        shadows: const [
                          Shadow(color: Color(0xAA000000), offset: Offset(0, 2), blurRadius: 5),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      );
    });
  }
}
