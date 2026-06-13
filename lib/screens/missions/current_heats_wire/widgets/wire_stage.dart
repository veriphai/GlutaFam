// The interactive stage. A raw [Listener] (not GestureDetector) forwards pointer
// down/move/up to the controller in this widget's LOCAL space — the same space
// the StagePainter draws in and the controller's rub-band hit-test uses. The
// controller decides whether a pointer counts (only inside the rub band, during
// the rub beat); the slider is its own widget below the stage.

import 'package:flutter/material.dart';

import '../state/heat_wire_controller.dart';
import 'stage_painter.dart';

class WireStage extends StatelessWidget {
  const WireStage({super.key, required this.controller});

  final HeatWireController controller;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) => controller.onPointerDown(e.localPosition),
      onPointerMove: (e) => controller.onPointerMove(e.localPosition),
      onPointerUp: (e) => controller.onPointerUp(),
      onPointerCancel: (e) => controller.onPointerUp(),
      child: CustomPaint(
        painter: StagePainter(controller),
        size: Size.infinite,
      ),
    );
  }
}
