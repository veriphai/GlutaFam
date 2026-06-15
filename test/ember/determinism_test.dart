// Ember — test/ember/determinism_test.dart
//
// G2 GATE proof #1: the foundation is DETERMINISTIC. Two independently-built
// new-game worlds from the SAME fixed seed, advanced by the SAME WorldSimulation
// for the SAME sim time, must serialize byte-for-byte identically — that single
// invariant is what lets live play, offline catch-up, and tests share one
// advance() tick. We also prove OfflineCatchup clamps the elapsed real time to
// the 12h cap.
//
// Harness: InMemorySaveRepository + FakeClock only. No platform channels, no
// DateTime.now()/Random()/Stopwatch — time is the FakeClock, randomness is the
// seeded EmberRng baked into the seed.

import 'dart:convert';

import 'package:eureka_app/ember/contracts/sim_registry.dart';
import 'package:eureka_app/ember/core/constants.dart';
import 'package:eureka_app/ember/core/ember_clock.dart';
import 'package:eureka_app/ember/data/models/save_envelope.dart';
import 'package:eureka_app/ember/data/models/world_state.dart';
import 'package:eureka_app/ember/data/repository/in_memory_save_repository.dart';
import 'package:eureka_app/ember/data/seed/world_seed.dart';
import 'package:eureka_app/ember/sim/offline_catchup.dart';
import 'package:eureka_app/ember/sim/world_simulation.dart';
import 'package:flutter_test/flutter_test.dart';

/// One sim-hour in ms (used to express advance windows readably).
const int _hourMs = 60 * 60 * 1000;

/// A fixed, non-default seed so the test pins a concrete reproducible world and
/// doesn't accidentally rely on the seed constant.
const int _fixedSeed = 0x5EED1234;

void main() {
  group('determinism', () {
    test('two independent worlds from one seed advance byte-identically', () {
      // The sim is leaf-blind: it runs against the abstract SimRegistry. The
      // empty registry is the correct G2 fixture (no leaf wired yet).
      final WorldSimulation sim = WorldSimulation(const EmptySimRegistry());

      // Build TWO independent states. They must be separate object graphs:
      // EmberWorldState carries a mutable EmberRng that advance() mutates in
      // place, so copying one state would alias the rng and defeat the test.
      // newGame() mints a fresh seeded rng each call, so identical seed ->
      // identical-but-independent worlds.
      final EmberWorldState a = WorldSeed.newGame(seed: _fixedSeed);
      final EmberWorldState b = WorldSeed.newGame(seed: _fixedSeed);

      // Sanity: they start identical.
      expect(
        jsonEncode(a.toJson()),
        equals(jsonEncode(b.toJson())),
        reason: 'fresh worlds from one seed must seed identically',
      );

      // Capture the rng VALUE up front. advance() mutates the carried EmberRng
      // object in place (copyWith reuses the same rng reference), so reading
      // a.rng.state after advancing would just observe the mutated object — we
      // must snapshot the int now to prove the stream actually moved.
      final int rngBefore = a.rng.state;

      const int sixHours = 6 * _hourMs;
      final EmberWorldState advancedA = sim.advance(a, sixHours);
      final EmberWorldState advancedB = sim.advance(b, sixHours);

      final String jsonA = jsonEncode(advancedA.toJson());
      final String jsonB = jsonEncode(advancedB.toJson());

      expect(
        jsonA,
        equals(jsonB),
        reason: 'same seed + same dt through advance() must be byte-identical',
      );

      // Time really did move: 6h of fixed steps were applied. (The original `a`
      // object is left untouched at simNowMs 0 because advance returns NEW
      // states via copyWith.)
      expect(advancedA.simNowMs, equals(sixHours));
      expect(a.simNowMs, equals(0));

      // And the rng stream actually advanced (the world is not inert — the
      // pressure director consumed entropy across the window).
      expect(advancedA.rng.state, isNot(equals(rngBefore)));
    });

    test('advancing in one big step == advancing in two halves', () {
      final WorldSimulation sim = WorldSimulation(const EmptySimRegistry());

      final EmberWorldState whole = WorldSeed.newGame(seed: _fixedSeed);
      final EmberWorldState halves = WorldSeed.newGame(seed: _fixedSeed);

      const int fourHours = 4 * _hourMs;
      final EmberWorldState wholeOut = sim.advance(whole, fourHours);

      EmberWorldState halvesOut = sim.advance(halves, 2 * _hourMs);
      halvesOut = sim.advance(halvesOut, 2 * _hourMs);

      expect(
        jsonEncode(wholeOut.toJson()),
        equals(jsonEncode(halvesOut.toJson())),
        reason: 'fixed-step integration must be associative across chunking',
      );
    });

    test('a sub-step dt does not advance the world', () {
      final WorldSimulation sim = WorldSimulation(const EmptySimRegistry());
      final EmberWorldState s = WorldSeed.newGame(seed: _fixedSeed);

      final EmberWorldState out = sim.advance(s, WorldSimulation.stepMs - 1);

      expect(out.simNowMs, equals(s.simNowMs));
      expect(out.rng.state, equals(s.rng.state));
      expect(jsonEncode(out.toJson()), equals(jsonEncode(s.toJson())));
    });
  });

  group('offline catch-up', () {
    test('clamps elapsed real time to the 12h cap', () {
      final WorldSimulation sim = WorldSimulation(const EmptySimRegistry());
      final OfflineCatchup catchup = OfflineCatchup(sim);

      // A FakeClock supplies wall time; no DateTime.now() anywhere.
      final FakeClock clock = FakeClock(0);
      final EmberWorldState s = WorldSeed.newGame(seed: _fixedSeed);
      expect(s.lastSeenMs, equals(0));

      // Player was away 48h — far past the 12h cap.
      const int awayMs = 48 * _hourMs;
      clock.setTo(awayMs);

      final CatchupResult result = catchup.run(s, clock.nowMs());

      // The digest reports the raw elapsed but only simulated the capped window.
      expect(result.digest.elapsedMs, equals(awayMs));
      expect(result.digest.cappedElapsedMs, equals(EmberConstants.offlineCapMs));
      expect(result.digest.wasCapped, isTrue);
      expect(
        result.digest.stepsRun,
        equals(EmberConstants.offlineCapMs ~/ WorldSimulation.stepMs),
      );

      // The sim advanced by exactly the cap, not the full 48h.
      expect(result.state.simNowMs, equals(EmberConstants.offlineCapMs));
      // lastSeen is stamped to "now" so the next session measures from here.
      expect(result.state.lastSeenMs, equals(awayMs));
    });

    test('an under-12h window is simulated in full (no clamp)', () {
      final WorldSimulation sim = WorldSimulation(const EmptySimRegistry());
      final OfflineCatchup catchup = OfflineCatchup(sim);

      final FakeClock clock = FakeClock(0);
      final EmberWorldState s = WorldSeed.newGame(seed: _fixedSeed);

      const int awayMs = 3 * _hourMs; // under the 12h cap.
      clock.setTo(awayMs);

      final CatchupResult result = catchup.run(s, clock.nowMs());

      expect(result.digest.wasCapped, isFalse);
      expect(result.digest.elapsedMs, equals(awayMs));
      expect(result.digest.cappedElapsedMs, equals(awayMs));
      expect(result.state.simNowMs, equals(awayMs));
      expect(result.state.lastSeenMs, equals(awayMs));
    });

    test('catch-up is deterministic: same gap -> byte-identical state', () {
      final WorldSimulation sim = WorldSimulation(const EmptySimRegistry());
      final OfflineCatchup catchup = OfflineCatchup(sim);

      final EmberWorldState a = WorldSeed.newGame(seed: _fixedSeed);
      final EmberWorldState b = WorldSeed.newGame(seed: _fixedSeed);

      // Two clocks, same gap.
      const int awayMs = 20 * _hourMs; // > cap, so the clamp path runs too.
      final CatchupResult ra = catchup.run(a, FakeClock(awayMs).nowMs());
      final CatchupResult rb = catchup.run(b, FakeClock(awayMs).nowMs());

      expect(
        jsonEncode(ra.state.toJson()),
        equals(jsonEncode(rb.state.toJson())),
      );
      expect(
        jsonEncode(ra.digest.toJson()),
        equals(jsonEncode(rb.digest.toJson())),
      );
    });

    test('catch-up persists + reloads through the in-memory repository', () async {
      // Proves the whole loop is platform-channel free and round-trips: seed ->
      // catch-up -> save -> load -> identical state.
      final WorldSimulation sim = WorldSimulation(const EmptySimRegistry());
      final OfflineCatchup catchup = OfflineCatchup(sim);
      final InMemorySaveRepository repo = InMemorySaveRepository();
      final FakeClock clock = FakeClock(0);

      final EmberWorldState s = WorldSeed.newGame(seed: _fixedSeed);
      clock.setTo(2 * _hourMs);
      final CatchupResult result = catchup.run(s, clock.nowMs());

      await repo.save(SaveEnvelope(
        schemaVersion: SaveEnvelope.currentSchemaVersion,
        savedAtMs: clock.nowMs(),
        state: result.state,
      ));

      expect(await repo.exists(), isTrue);
      final SaveEnvelope? loaded = await repo.load();
      expect(loaded, isNotNull);
      expect(
        jsonEncode(loaded!.state.toJson()),
        equals(jsonEncode(result.state.toJson())),
        reason: 'save -> load must reproduce the caught-up state exactly',
      );
    });
  });
}
