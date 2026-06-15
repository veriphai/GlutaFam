// Ember — sim/offline_catchup.dart
//
// Runs the SAME WorldSimulation.advance() the live loop uses, but for the gap
// since the player was last present. It clamps the elapsed real time to the 12h
// cap, advances in whole fixed steps, collects every event outcome into an
// AwayDigest, and stamps lastSeenMs = nowMs on the returned state.
//
// DETERMINISM: this file lives in sim/, so it NEVER calls DateTime.now(). The
// caller (state/, which owns the EmberClock) passes nowMs in. Given the same
// (state, nowMs) the result — incl. the serialized rng — is identical, which is
// exactly what makes offline catch-up replay-stable and testable.

import '../contracts/event_resolver.dart';
import '../core/constants.dart';
import '../data/models/world_state.dart';
import 'away_digest.dart';
import 'world_simulation.dart';

/// The product of an offline catch-up: the advanced world + the away digest.
class CatchupResult {
  const CatchupResult(this.state, this.digest);
  final EmberWorldState state;
  final AwayDigest digest;
}

class OfflineCatchup {
  const OfflineCatchup(this.simulation);

  final WorldSimulation simulation;

  /// Advances [state] to account for the time between state.lastSeenMs and
  /// [nowMs], clamped to [EmberConstants.offlineCapMs]. Returns the new state
  /// (with lastSeenMs = nowMs) and an [AwayDigest] of what happened.
  CatchupResult run(EmberWorldState state, int nowMs) {
    final int rawElapsed = nowMs - state.lastSeenMs;

    // No (or negative — clock skew) elapsed time: nothing to catch up. Still
    // refresh lastSeenMs so the next session measures from now.
    if (rawElapsed < WorldSimulation.stepMs) {
      return CatchupResult(
        state.copyWith(lastSeenMs: nowMs),
        AwayDigest(elapsedMs: rawElapsed < 0 ? 0 : rawElapsed),
      );
    }

    final int capped = rawElapsed.clamp(0, EmberConstants.offlineCapMs);
    // Advance in whole steps only; the sub-step remainder is dropped (and picked
    // up by the next live tick).
    final int steps = capped ~/ WorldSimulation.stepMs;
    final int simulatedMs = steps * WorldSimulation.stepMs;

    final SimStepResult result =
        simulation.advanceCollecting(state, simulatedMs);

    final AwayDigest digest = AwayDigest(
      elapsedMs: rawElapsed,
      cappedElapsedMs: simulatedMs,
      stepsRun: steps,
      lines: <AwayDigestLine>[
        for (final EventOutcome outcome in result.outcomes)
          AwayDigestLine.fromOutcome(outcome),
      ],
    );

    return CatchupResult(
      result.state.copyWith(lastSeenMs: nowMs),
      digest,
    );
  }
}
