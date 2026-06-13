// The stage layer for Squared Loss — composes the two pure renderers (the hero
// wire + the graph panel) into one paint surface. Both share the same stage size
// (the controller sets it once per paint from the wire painter). This whole widget
// sits INSIDE the RepaintBoundary the shell wraps, so a capture snapshots the wire
// band + chips (and the panel, when revealed) — exactly the PRD §9 crop.
//
// No gesture here: the current slider lives below the stage and forwards pointers
// to the controller directly. This is a passive renderer.

import 'package:flutter/material.dart';

import '../state/squared_loss_controller.dart';
import 'heat_curve_panel_painter.dart';
import 'wire_stage_painter.dart';

class WireStage extends StatelessWidget {
  const WireStage({super.key, required this.controller});
  final SquaredLossController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The hero wire + chips + embers + shimmer (sets the stage size).
        Positioned.fill(
          child: CustomPaint(painter: WireStagePainter(controller)),
        ),
        // The graph panel (hidden until sweep; reads the same stage size).
        Positioned.fill(
          child: CustomPaint(painter: HeatCurvePanelPainter(controller)),
        ),
      ],
    );
  }
}
