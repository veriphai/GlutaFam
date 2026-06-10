// The Flame stage — the vertical energy-flow Sankey (PRD §3, §8): warm energy
// enters at the top, flows DOWN through the conversion steps, HEAT leaks sideways
// at each junction, and a dim bulb sits at the bottom lit by the survivor.
//
// The game owns NO gestures and NO logic: the controller owns the model + the
// flow + the geometry; the game reports the stage size once, ticks the
// controller each frame, and the scene is a near-pure renderer reading
// controller getters (controller-owns-geometry — the same split as Source
// Personalities / Trace It Back). Chrome (Voltix, number chips, Improve buttons,
// source toggle, card earn) is Flutter, over the GameWidget.

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart' show Color, Size;

import '../state/leaky_bucket_controller.dart';
import 'components/scene_components.dart';

class LeakyBucketGame extends FlameGame {
  LeakyBucketGame({required this.controller, this.reducedMotion = false});

  final LeakyBucketController controller;
  final bool reducedMotion;

  // Transparent so the Flutter EnergyFieldBackground shows through.
  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    addAll([
      GlowWashLayer(controller),
      AmbientMotesLayer(controller, reducedMotion: reducedMotion),
      LeakySceneLayer(controller, reducedMotion: reducedMotion),
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
    // Clamp (don't DROP) a huge first / background-resume / throttled-tab delta,
    // so the beat logic still advances a steady step instead of freezing.
    if (dt > 0) controller.tick(dt > 0.05 ? 0.05 : dt);
  }
}
