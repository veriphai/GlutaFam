// Ember — sim/world_simulation.dart
//
// THE ONE TICK. Live play, offline catch-up, and tests all funnel through
// advance(): a fixed-step integrator that loops [stepMs]-sized steps over the
// systems in a fixed order, advancing simNowMs by exactly stepMs each step. The
// fixed step is the determinism contract — given the same starting state + the
// same dt, the output (incl. the serialized rng) is identical everywhere.
//
// It depends ONLY on the abstract SimRegistry (never on registry/, state/, or
// game/). Chance is drawn exclusively from the world EmberRng carried in state.
//
// NOTE ON SHAPE: EmberWorldState is an immutable value aggregate (systems return
// NEW states via copyWith), so advance RETURNS the new state rather than mutating
// in place. The canonical sketch wrote `void advance(...)`; returning the state is
// the only correct realization given immutable models, and callers (state/ +
// OfflineCatchup) consume the return. See StructuredOutput.deviations.

import '../contracts/event_resolver.dart';
import '../contracts/sim_registry.dart';
import '../core/constants.dart';
import '../data/models/world_state.dart';
import 'systems/build_system.dart';
import 'systems/event_system.dart';
import 'systems/fire_coverage.dart';
import 'systems/npc_system.dart';
import 'systems/population_system.dart';
import 'systems/pressure_system.dart';
import 'systems/resource_system.dart';
import 'systems/time_system.dart';

/// The bundle one fixed step / advance produces: the new world plus the event
/// outcomes that fired during it (for the digest / live feed).
class SimStepResult {
  const SimStepResult(this.state, this.outcomes);
  final EmberWorldState state;
  final List<EventOutcome> outcomes;
}

class WorldSimulation {
  WorldSimulation(this.registry)
      : _resources = ResourceSystem(registry),
        _builds = BuildSystem(registry),
        _events = EventSystem(registry),
        _pressure = const PressureSystem(),
        _time = const TimeSystem(),
        _npcs = const NpcSystem(),
        _population = const PopulationSystem(),
        _coverage = const FireCoverageSystem();

  final SimRegistry registry;

  /// Fixed step in ms. Loop this many ms per system pass — the determinism knob.
  static const int stepMs = EmberConstants.stepMs;

  final ResourceSystem _resources;
  final BuildSystem _builds;
  final EventSystem _events;
  final PressureSystem _pressure;
  final TimeSystem _time;
  final NpcSystem _npcs;
  final PopulationSystem _population;
  final FireCoverageSystem _coverage;

  /// Advances [s] by [dtMs] of sim time in fixed [stepMs] steps and returns the
  /// new state. Any remainder smaller than one step is carried by NOT advancing
  /// (the next call's dt picks it up); callers that need the remainder tracked
  /// should pass multiples of stepMs.
  EmberWorldState advance(EmberWorldState s, int dtMs) =>
      advanceCollecting(s, dtMs).state;

  /// Like [advance] but also returns the event outcomes that fired (for the
  /// AwayDigest / live toasts). This is the workhorse; [advance] discards the
  /// outcomes.
  SimStepResult advanceCollecting(EmberWorldState s, int dtMs) {
    if (dtMs < stepMs) {
      return SimStepResult(s, const <EventOutcome>[]);
    }
    final int steps = dtMs ~/ stepMs;
    EmberWorldState state = s;
    final List<EventOutcome> outcomes = <EventOutcome>[];
    for (int i = 0; i < steps; i++) {
      final SimStepResult r = _stepOnce(state);
      state = r.state;
      outcomes.addAll(r.outcomes);
    }
    return SimStepResult(state, outcomes);
  }

  /// One fixed [stepMs] step over all systems, in a fixed deterministic order.
  SimStepResult _stepOnce(EmberWorldState s) {
    const double dtSec = stepMs / 1000.0;
    EmberWorldState state = s;

    // 0) Advance authoritative sim time FIRST so events scheduled for "now" are
    //    judged against the post-step clock.
    state = state.copyWith(simNowMs: state.simNowMs + stepMs);

    // 1) Time / day-night / season.
    state = _time.advance(state, dtSec);

    // 2) Builds progress (+ behavior onBuilt), then behavior ticks (fuel burn).
    state = _builds.advance(state, dtSec);
    state = _builds.tickBehaviors(state, dtSec);

    // 3) Resources regrow.
    state = _resources.regrow(state, dtSec);

    // 4) Fire coverage (read once; reused by pressure + population).
    final FireCoverage coverage = _coverage.compute(state);

    // 5) NPC mood / workers / visitor arrivals (uses world rng).
    state = _npcs.advance(state, dtSec, state.rng);

    // 6) Population cap + comfort (depends on coverage + dwellings).
    state = _population.recompute(state, coverage);

    // 7) Pressure director: schedule predator/flood (uses world rng).
    state = _pressure.schedule(state, coverage, state.rng);

    // 8) Fire any events now due (resolvers; uses world rng). Collect outcomes.
    final EventPassResult ev = _events.fireDue(state);
    state = ev.state;

    return SimStepResult(state, ev.outcomes);
  }
}
