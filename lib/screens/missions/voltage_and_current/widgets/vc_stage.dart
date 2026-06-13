// The interactive stage. A raw [Listener] (not GestureDetector) forwards pointer
// down/move/up to the controller in this widget's LOCAL space — the same space
// the painter draws in and the controller's geometry getters use, so the drag
// maps consistently. The controller's hit-test limits response to the source
// station (PRD §3.3, §11.5): touching the wire, lamp, or CURRENT chip does
// nothing — only the voltage column responds. The current is never a handle.

import 'package:flutter/material.dart';

import '../state/vc_controller.dart';
import 'vc_stage_painter.dart';

class VCStage extends StatelessWidget {
  const VCStage({super.key, required this.controller});

  final VCController controller;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) => controller.onPointerDown(e.localPosition),
      onPointerMove: (e) => controller.onPointerMove(e.localPosition),
      onPointerUp: (e) => controller.onPointerUp(),
      onPointerCancel: (e) => controller.onPointerUp(),
      child: CustomPaint(
        painter: VCStagePainter(controller),
        size: Size.infinite,
      ),
    );
  }
}
