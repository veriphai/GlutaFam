// The Flame stage — the living AC-vs-DC world. The game owns NO gestures and NO
// logic: the controller owns geometry + the sim + the phase machine, the game
// reports the stage size once, ticks the controller each frame, and every layer
// is a near-pure renderer reading controller getters (controller-owns-geometry,
// the the_transformer / trace_it_back template).
//
// Backgrounds + chrome are Flutter (behind/over the GameWidget); only the hero
// scene lives in Flame. The gesture (a tap on the source dock) is a transparent
// Flutter Listener above the GameWidget, forwarded to the controller.

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart' show Color, Size;

import '../state/acdc_controller.dart';
import 'components/scene_components.dart';

class AcdcGame extends FlameGame {
  AcdcGame({required this.controller});

  final AcdcController controller;

  // Transparent so the Flutter energy-field background shows through.
  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    // Back→front: ambient → glow → input line → output line → the core hero +
    // its two fixed coils → the source dock → the bulb → the tiny graph → flash.
    addAll([
      AmbientMotesLayer(controller),
      BackgroundGlowLayer(controller),
      InputLineLayer(controller), // directional pulses; reverse on every flip
      OutputLineLayer(controller), // kick-gated cool-blue pulses to the bulb
      CoreFieldLayer(controller), // HERO: iron ring + additive amber field
      PrimaryCoilLayer(controller), // 4 fixed loops (held constant)
      SecondaryCoilLayer(controller), // 8 fixed loops (held constant)
      SourceDockLayer(controller), // battery (flip anim) + machine swap + grab hint
      OutputBulbLayer(controller), // the aliveness readout — snaps off
      GraphStripLayer(controller), // strip chart + CURRENT eyebrow + 50-label
      FlashLayer(controller), // spring-to-life + dead-underline flashes
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
