// Ember — sim/systems/event_system.dart
//
// Fires every scheduled WorldEvent whose scheduledForMs <= simNow, in time order,
// by handing each to the first SimRegistry.resolversFor(type) resolver that
// canResolve it. This is the SAME path live and offline — the only difference is
// how many events come due in one advance(). Each resolution returns an
// EventOutcome (new state + digest line); the event is marked resolved and its
// outcome bag is stamped. Pure + deterministic: chance flows through the world rng.

import '../../contracts/event_resolver.dart';
import '../../contracts/sim_registry.dart';
import '../../data/models/world_event.dart';
import '../../data/models/world_state.dart';

/// The result of one event pass: the new state plus the outcomes produced (for
/// the AwayDigest / live toast feed).
class EventPassResult {
  const EventPassResult(this.state, this.outcomes);
  final EmberWorldState state;
  final List<EventOutcome> outcomes;
}

class EventSystem {
  const EventSystem(this.registry);

  final SimRegistry registry;

  /// Fires all due events at the current simNowMs. Returns the new state and the
  /// outcomes (empty list if nothing fired). Events fire in (scheduledForMs, id)
  /// order so ties are deterministic.
  EventPassResult fireDue(EmberWorldState s) {
    // Collect due, unresolved events in deterministic order.
    final List<WorldEvent> due = <WorldEvent>[
      for (final WorldEvent e in s.events)
        if (e.isDue(s.simNowMs)) e,
    ]..sort((WorldEvent a, WorldEvent b) {
        final int byTime = a.scheduledForMs.compareTo(b.scheduledForMs);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });

    if (due.isEmpty) return EventPassResult(s, const <EventOutcome>[]);

    EmberWorldState state = s;
    final List<EventOutcome> outcomes = <EventOutcome>[];

    for (final WorldEvent original in due) {
      // Re-fetch the live event (an earlier resolver may have rewritten events).
      final WorldEvent? live = _eventById(state, original.id);
      if (live == null || live.resolved) continue;

      final List<EventResolver> resolvers = registry.resolversFor(live.type);
      EventResolver? chosen;
      for (final EventResolver r in resolvers) {
        if (r.canResolve(live.type)) {
          chosen = r;
          break;
        }
      }

      if (chosen == null) {
        // No resolver: mark resolved with a neutral outcome so it doesn't loop.
        state = _markResolved(state, live, <String, dynamic>{'unresolved': true});
        continue;
      }

      final EventOutcome outcome = chosen.resolve(live, state, state.rng);
      // The resolver returns a new state; stamp the event resolved + outcome.
      state = _markResolved(
        outcome.state,
        live,
        outcome.toJson(),
      );
      outcomes.add(outcome.copyWith(state: state));
    }

    return EventPassResult(state, outcomes);
  }

  WorldEvent? _eventById(EmberWorldState s, String id) {
    for (final WorldEvent e in s.events) {
      if (e.id == id) return e;
    }
    return null;
  }

  EmberWorldState _markResolved(
    EmberWorldState s,
    WorldEvent e,
    Map<String, dynamic> outcome,
  ) {
    final List<WorldEvent> next = <WorldEvent>[
      for (final WorldEvent w in s.events)
        if (w.id == e.id) w.copyWith(resolved: true, outcome: outcome) else w,
    ];
    return s.copyWith(events: next);
  }
}
