// The Flame stage — the living TOWN (the town_simulation_base world rendered).
// The PRD chose Flame here because this is the module's first full simulated
// world: a sky with a moving sun (day/night), buildings whose windows light /
// dim / flicker / go dark, haze that accumulates, and the source feeding it.
//
// The game owns NO gestures and NO logic: the controller owns the simulation +
// geometry, the game reports the stage size once, ticks the controller each
// frame, and every layer is a near-pure renderer reading controller getters
// (controller-owns-geometry). Chrome (selector, scrubber, Voltix) is Flutter,
// over the GameWidget — the same Flame-scene + Flutter-overlay split as Trace
// It Back.

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart' show Color, Size;

import '../state/source_personalities_controller.dart';
import 'components/sky_layer.dart';
import 'components/cloud_layer.dart';
import 'components/town_layer.dart';
import 'components/haze_layer.dart';
import 'components/source_visual_layer.dart';

class TownGame extends FlameGame {
  TownGame({required this.controller, this.reducedMotion = false});

  final SourcePersonalitiesController controller;
  final bool reducedMotion;

  // Transparent so the Flutter scaffold background shows through if needed.
  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    addAll([
      SkyLayer(controller, reducedMotion: reducedMotion), // gradient + scattered sun + stars
      CloudLayer(controller, reducedMotion: reducedMotion), // drifting cloud banks (atmosphere)
      TownLayer(controller, reducedMotion: reducedMotion), // depth skyline + windows + foreground
      SourceVisualLayer(controller, reducedMotion: reducedMotion), // the plant + transmission line
      HazeLayer(controller, reducedMotion: reducedMotion), // localized smog band (pollution)
    ]);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    controller.setStageSize(Size(size.x, size.y));
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Guard a huge first/background-resume delta the same way a Ticker shell does.
    if (dt > 0 && dt < 0.1) controller.tick(dt);
  }
}
