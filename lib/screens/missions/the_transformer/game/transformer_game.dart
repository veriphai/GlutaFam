// The Flame stage — the living transformer world. The game owns NO gestures and
// NO logic: the controller owns geometry + the sim + the phase machine, the game
// reports the stage size once, ticks the controller each frame, and every layer is
// a near-pure renderer reading controller getters (controller-owns-geometry, the
// trace_it_back template).
//
// Backgrounds + chrome are Flutter (behind/over the GameWidget); only the hero
// scene lives in Flame. The gesture (the vertical wind on the secondary limb) is a
// transparent Flutter Listener above the GameWidget, forwarded to the controller.

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart' show Color, Size;

import '../state/transformer_controller.dart';
import 'components/scene_components.dart';

class TransformerGame extends FlameGame {
  TransformerGame({required this.controller});

  final TransformerController controller;

  // Transparent so the Flutter energy-field background shows through.
  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    // Back→front: ambient → glow → the journey (plant → input → core hero →
    // output → pylons) → chips → the flash.
    addAll([
      AmbientMotesLayer(controller),
      BackgroundGlowLayer(controller),
      PlantSilhouetteLayer(controller),
      InputLineLayer(controller), // the always-alive surge pulses (the CHANGING current)
      OutputLineLayer(controller), // reach-gated cool-blue pulses
      HorizonPylonsLayer(controller), // far-pylon ignition
      CoreFieldLayer(controller), // HERO: iron ring + additive amber breathing field
      PrimaryCoilLayer(controller), // 4 fixed loops (the held constant)
      SecondaryCoilLayer(controller), // 2..8 countable loops + wind anim + grab hint
      VoltageChipsLayer(controller), // IN/OUT mono chips
      FlashLayer(controller), // kick + ignition flashes
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
    // Guard a huge first/background-resume delta the same way the Ticker shell does.
    if (dt > 0 && dt < 0.1) controller.tick(dt);
  }
}
