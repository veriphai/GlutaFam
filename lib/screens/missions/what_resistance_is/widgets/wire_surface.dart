// The interactive stage: a Listener that forwards pointer events to the controller
// (the wire IS the control — no detached slider), over a CustomPaint whose painter
// repaints on every controller notify. A pointer-down inside the pinned voltage
// dial's hit region routes to onDialTouched (the deny-shake) instead of morphing
// the wire — so tapping the dial proves it's pinned.

import 'package:flutter/material.dart';

import '../state/resistance_controller.dart';
import 'resistance_stage_painter.dart';

class WireSurface extends StatelessWidget {
  const WireSurface({super.key, required this.controller});

  final ResistanceController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            if (_overSource(e.localPosition, size)) {
              controller.onDialTouched();
            } else {
              controller.onPointerDown(e.localPosition);
            }
          },
          onPointerMove: (e) => controller.onPointerMove(e.localPosition, size.height),
          onPointerUp: (e) => controller.onPointerUp(),
          onPointerCancel: (e) => controller.onPointerUp(),
          child: CustomPaint(
            painter: ResistanceStagePainter(controller),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  // The VOLTAGE source module's hit region (a forgiving inflated rect). Tapping it
  // routes to the deny-shake — the pinned voltage refuses input.
  bool _overSource(Offset p, Size s) {
    final cx = 0.50 * s.width;       // RTune.sourceX
    final cy = 0.20 * s.height;      // RTune.sourceBarY
    final w = 0.30 * s.width;        // RTune.sourceWidthFactor
    final h = 0.076 * s.height;      // RTune.sourceHeightFactor
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h).inflate(8);
    return rect.contains(p);
  }
}
