// Ember — test/ember/make_fire_test.dart
//
// Proves the rebuilt Make Fire crank actually makes fire — the on-device bug was
// that spinning the drill produced NO heat (the player got stuck at the HEAT
// step) because the heat bled far faster than a continuous crank could build it.
//
// The crank is now a TRUE angular velocity (rad/s): the scene measures the
// finger's angle delta around the crank-wheel centre and integrates it in
// update(dt), with a sample-timeout hold across the gaps between pointer-move
// callbacks (mirroring the Hand-Crank Lamp). The sim turns |vel| straight into
// friction heat (heatPerSpin * |vel| * dt) and bleeds when it reads zero.
//
// These tests drive the SIM directly (it is the deterministic brain): a steady
// crank (inSpin {vel:12} every 1/60s frame) must catch an ember; a stopped crank
// (inSpin {vel:0}) must make the heat strictly DECREASE (the bleed / HEAT gate
// still works). We read the sim's PUBLIC getters (phase / heat) synchronously —
// NOT the broadcast event stream, which delivers asynchronously.

import 'package:eureka_app/ember/activity/activity_contract.dart';
import 'package:eureka_app/ember/activity/activity_sim.dart';
import 'package:eureka_app/ember/concepts/fire/make_fire_activity.dart';
import 'package:eureka_app/ember/concepts/fire/make_fire_sim.dart';
import 'package:flutter_test/flutter_test.dart';

/// One 60 fps frame, the cadence the Flame loop ticks the sim at.
const double _frame = 1.0 / 60.0;

void main() {
  // The rules the sim reads its tunables from — the SAME config the activity
  // ships, so the test pins the live values (heatPerSpin / heatDecay / stall).
  final InteractionRules rules =
      MakeFireActivity.build().interactionRules;

  /// Build a sim, start it with the shipped rules, and seat dry tinder fully so
  /// it advances into the buildHeat phase (where the crank drives heat).
  MakeFireSim armToBuildHeat() {
    final MakeFireSim sim = MakeFireSim()..start(rules);
    expect(sim.phase, MakeFirePhase.gatherTinder);
    sim.onInput(const SimInput(MakeFireSignals.inSelectTinder,
        <String, dynamic>{'dry': true, 'seat': 1.0}));
    expect(sim.phase, MakeFirePhase.buildHeat,
        reason: 'fully-seated dry tinder must advance to buildHeat');
    return sim;
  }

  group('make fire — the crank produces heat', () {
    test('a steady crank catches an ember within ~2.5s', () {
      final MakeFireSim sim = armToBuildHeat();

      // Drive a steady, vigorous crank: every frame the scene forwards the live
      // velocity, then the sim integrates one tick of friction heat.
      const double steadyVel = 12.0; // a comfortable continuous crank (rad/s)
      const int maxFrames = 150; // ~2.5s at 60 fps
      int frames = 0;
      while (sim.phase == MakeFirePhase.buildHeat && frames < maxFrames) {
        sim.onInput(const SimInput(
            MakeFireSignals.inSpin, <String, dynamic>{'vel': steadyVel}));
        sim.tick(_frame);
        frames++;
      }

      expect(sim.phase, MakeFirePhase.catchEmber,
          reason:
              'a steady crank MUST out-build the idle bleed and catch an ember '
              '(the on-device "no heat" bug) — got ${sim.phase} after '
              '${(frames * _frame).toStringAsFixed(2)}s');
      expect(frames * _frame, lessThanOrEqualTo(2.5),
          reason: 'the ember should catch within ~2.5s of steady cranking');
    });

    test('a stopped crank makes the heat strictly decrease (the HEAT gate)', () {
      final MakeFireSim sim = armToBuildHeat();

      // Build some heat first with a short burst of cranking (but not enough to
      // catch the ember), so there is heat to bleed.
      for (int i = 0; i < 20; i++) {
        sim.onInput(const SimInput(
            MakeFireSignals.inSpin, <String, dynamic>{'vel': 12.0}));
        sim.tick(_frame);
      }
      expect(sim.phase, MakeFirePhase.buildHeat,
          reason: 'the short burst must NOT yet catch the ember');
      expect(sim.heat, greaterThan(0.0),
          reason: 'the burst must have built some heat to bleed');

      // Now STOP: feed vel 0 + tick repeatedly. The heat must strictly drop each
      // frame (the HARD-bleed) for a window short enough to stay before the
      // ~2s stall-to-fail gate resolves the attempt.
      double prev = sim.heat;
      for (int i = 0; i < 30; i++) {
        // ~0.5s, well under the 2.0s stall window
        sim.onInput(const SimInput(
            MakeFireSignals.inSpin, <String, dynamic>{'vel': 0.0}));
        sim.tick(_frame);
        expect(sim.heat, lessThan(prev),
            reason: 'a stopped crank must bleed heat every frame');
        prev = sim.heat;
      }
    });
  });
}
