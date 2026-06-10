// The Flame stage — the living chain (source → turbine → magnet/coil → wire →
// lamp). The PRD chose Flame here because this is the first genuinely multi-
// component animated world (rotating parts + per-source particle flows). The game
// owns NO gestures and NO logic: the controller owns geometry + physics, the game
// reports the stage size once, ticks the controller each frame, and every layer
// is a near-pure renderer reading controller getters (controller-owns-geometry).
//
// Backgrounds + chrome are Flutter (behind/over the GameWidget); only the hero
// chain lives in Flame — the Flame-scene + Flutter-overlay pattern the heavier
// later beats inherit (PRD §2, §3).

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart' show Color, Size;

import '../state/trace_back_controller.dart';
import 'components/scene_components.dart';

class TraceBackGame extends FlameGame {
  TraceBackGame({required this.controller});

  final TraceBackController controller;

  // Transparent so the Flutter energy-field background shows through.
  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    // Back→front, matching the vertical chain (PRD §8 + §3a connectors).
    addAll([
      AmbientMotesLayer(controller), // drifting dust — the hero's energy fills the void
      BackgroundGlowLayer(controller), // warm bloom up/down the central column
      SourceFrontEndLayer(controller), // FLOW: front end + per-source particles
      ShaftLayer(controller), // SHAFT: mechanical rotation, NO pulse
      TurbineLayer(controller), // the bladed wheel (Beat 2+)
      WireLayer(controller), // WIRE: the ONLY current-pulse
      CoilMagnetLayer(controller), // coil + rotating magnet + field-line bloom
      BulbLayer(controller), // the bulb (top) + its lit core
      DiscoveryRingLayer(controller), // the cutoff flash (Beat 1)
      GrabHintLayer(controller), // the "turn me" hint on the active grab-point
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
