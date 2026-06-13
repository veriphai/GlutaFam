// The Flame stage for War of the Currents — the living 1880s map. The game owns NO
// gestures and NO logic: the controller owns geometry + the phase machine, the game
// reports the stage size once, ticks the controller each frame, and every layer is
// a near-pure renderer reading controller getters (the trace_it_back template).
//
// Layers are added back→front: the map terrain recedes; the ROUTE is the hero
// (cooking on DC, sailing on AC); the station (plant + transformer + number chips)
// pivots the journey; the city is the payoff readout; the bridge vignette rises in
// the bridge phase. Backgrounds + chrome (dock, fact panel, captions, CTA) are
// Flutter, behind/over this transparent GameWidget.

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart' show Color, Size;

import '../state/woc_controller.dart';
import 'components/city_layer.dart';
import 'components/map_layer.dart';
import 'components/route_layer.dart';
import 'components/station_layer.dart';

class WocGame extends FlameGame {
  WocGame({required this.controller});

  final WocController controller;

  // Transparent so the Flutter energy-field background shows through.
  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    addAll([
      MapLayer(controller), // terrain ridges + river + era tag + ambient motes
      CityLayer(controller), // window grid (flicker / hard-dark / sweep) + bloom
      RouteLayer(controller), // THE HERO: route, pulses, heat glow, reach-front, flare
      StationLayer(controller), // plant + transformer core + VOLTAGE/CURRENT chips
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
    // CLAMP heavy frames — never DROP them. The old `dt < 0.1` drop guard froze the
    // sim's internal clock during first-run shader jank, which stalled the AC run's
    // flow (current stuck at the transformer, city never lit) when AC was chosen
    // first. Clamping keeps the sim advancing every frame while still capping a huge
    // first-frame / background-resume delta.
    if (dt > 0) controller.tick(dt < 0.05 ? dt : 0.05);
  }
}
