// The interactive canvas. A raw [Listener] (not GestureDetector) forwards
// pointer down/move/up to the controller — we need the finger-DOWN signal the
// instant it touches, BEFORE any movement, so a held-still crank is correctly
// "pointer down but not generating" (PRD §4.2, criterion 6). A pan gesture only
// starts after a drag threshold, which would miss that.
//
// The pointer position is reported in this widget's LOCAL space, which is the
// same space the StagePainter draws in (and the controller's geometry getters
// use), so angle-relative-to-pivot is computed consistently.

import 'package:flutter/material.dart';

import '../state/crank_controller.dart';
import 'stage_painter.dart';

class CrankSurface extends StatelessWidget {
  const CrankSurface({super.key, required this.controller});

  final CrankController controller;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) => controller.onPointerDown(e.localPosition),
      onPointerMove: (e) => controller.onPointerMove(e.localPosition),
      onPointerUp: (e) => controller.onPointerUp(),
      onPointerCancel: (e) => controller.onPointerUp(),
      child: RepaintBoundary(
        child: CustomPaint(
          painter: StagePainter(controller),
          size: Size.infinite,
        ),
      ),
    );
  }
}
