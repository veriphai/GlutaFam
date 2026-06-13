// The Flame stage for The Transmission Trick — the living scene (heat shimmer,
// rising motes, traveling current pulses, the window grid, and THE HERO rectangle).
// The game owns NO gestures and NO logic: the controller owns geometry + the sim;
// the game reports the stage size once, ticks the controller each frame, and every
// layer is a near-pure renderer reading controller getters (controller-owns-geometry).
//
// Layer order (back → front): journey band (plant → hot wire → pulses) → town
// (window grid + bloom). THE PINNED-POWER rectangle is NOT here — in the column
// layout it lives in its own Flutter seat (RectangleReadout) below this boxed stage,
// driven by the VoltageSlider, so the diagonal span can never overlap it. Backgrounds
// + chrome are Flutter, behind/over the GameWidget; only the living scene is Flame.

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart' show Color, Size;

import '../state/transmission_controller.dart';
import 'components/journey_layer.dart';
import 'components/town_layer.dart';

class TransmissionGame extends FlameGame {
  TransmissionGame({required this.controller});

  final TransmissionController controller;

  // Transparent so the Flutter energy-field background shows through.
  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    addAll([
      JourneyLayer(controller), // plant (static, dim) + steel pylons + catenary wire + heat
      TownLayer(controller), // building cluster + window grid (∝ townLit) + bloom
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
