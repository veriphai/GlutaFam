// Stage 2 — Place It in the Right Orbit (PRD §13). Thin Flutter wrapper:
// starfield backdrop + the shared Flame stage (slingshot mechanic lives in
// game/slingshot_stage.dart) + a PULL•AIM•RELEASE hint chip.

import 'package:flutter/material.dart';

import '../config/scc_theme.dart';
import '../state/mission_stage_controller.dart';
import '../state/mission_state.dart';

class OrbitScene extends StatelessWidget {
  const OrbitScene({super.key, required this.controller, required this.stage});

  final MissionStageController controller;
  final Widget stage; // the shell's cached GameWidget

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // shell provides the starfield — the stage layers straight over it
        Positioned.fill(child: stage),
        Positioned.fill(child: sceneVignette(strength: 0.45)),
        // hint chip — fades once the first launch flies
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final o = controller.state.orbit;
                final hide =
                    o.phase == SlingPhase.locked || o.flightToken > 0;
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: hide ? 0 : 1,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: sccPanel(radius: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.swipe_down_rounded,
                              color: SccColors.cyan, size: 18),
                          const SizedBox(width: 8),
                          Text('PULL • AIM • RELEASE',
                              style: SccText.chip.copyWith(color: SccColors.cyan)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
