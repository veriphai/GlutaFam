// Ember — test/ember/save_roundtrip_test.dart
//
// G2 GATE proof #2: the save document is ROUND-TRIP STABLE. A seeded world wrapped
// in a SaveEnvelope must survive toJson -> jsonEncode -> jsonDecode -> fromJson ->
// toJson with a byte-identical document. This is the contract the single Hive
// string relies on: one deterministic document, no drift across save/load.
//
// We test both a fresh seed AND a post-advance world (so events/rng-mutated state
// is exercised), and we verify equality two ways: structural (== / deep equal of
// toJson) and byte-level (jsonEncode string equality).

import 'dart:convert';

import 'package:eureka_app/ember/contracts/sim_registry.dart';
import 'package:eureka_app/ember/data/models/save_envelope.dart';
import 'package:eureka_app/ember/data/models/world_state.dart';
import 'package:eureka_app/ember/data/repository/in_memory_save_repository.dart';
import 'package:eureka_app/ember/data/seed/world_seed.dart';
import 'package:eureka_app/ember/sim/world_simulation.dart';
import 'package:flutter_test/flutter_test.dart';

const int _fixedSeed = 0x5EED1234;
const int _hourMs = 60 * 60 * 1000;

SaveEnvelope _envelope(EmberWorldState state, {int savedAtMs = 1234567}) =>
    SaveEnvelope(
      schemaVersion: SaveEnvelope.currentSchemaVersion,
      savedAtMs: savedAtMs,
      state: state,
    );

void main() {
  group('save round-trip', () {
    test('fresh seed: toJson -> fromJson -> toJson is byte-stable', () {
      final EmberWorldState seeded = WorldSeed.newGame(seed: _fixedSeed);
      final SaveEnvelope env = _envelope(seeded);

      final Map<String, dynamic> json1 = env.toJson();
      final SaveEnvelope round = SaveEnvelope.fromJson(json1);
      final Map<String, dynamic> json2 = round.toJson();

      // Byte-level: the encoded document must be identical.
      expect(
        jsonEncode(json2),
        equals(jsonEncode(json1)),
        reason: 'round-tripped save document must be byte-identical',
      );

      // Structural: value equality holds too (== is well-formed).
      expect(round, equals(env));
      expect(round.state, equals(seeded));
    });

    test('round-trip survives a full jsonEncode/jsonDecode pass', () {
      final EmberWorldState seeded = WorldSeed.newGame(seed: _fixedSeed);
      final SaveEnvelope env = _envelope(seeded);

      final String encoded = jsonEncode(env.toJson());
      final Map<String, dynamic> decoded =
          (jsonDecode(encoded) as Map).cast<String, dynamic>();
      final SaveEnvelope round = SaveEnvelope.fromJson(decoded);

      expect(jsonEncode(round.toJson()), equals(encoded));
      expect(round, equals(env));
    });

    test('advanced world: round-trip stays byte-stable after sim time', () {
      final WorldSimulation sim = WorldSimulation(const EmptySimRegistry());
      final EmberWorldState advanced =
          sim.advance(WorldSeed.newGame(seed: _fixedSeed), 6 * _hourMs);
      final SaveEnvelope env = _envelope(advanced, savedAtMs: 6 * _hourMs);

      final Map<String, dynamic> json1 = env.toJson();
      final SaveEnvelope round = SaveEnvelope.fromJson(json1);

      expect(jsonEncode(round.toJson()), equals(jsonEncode(json1)));
      expect(round, equals(env));
      // The rng state (an int) must survive the trip exactly.
      expect(round.state.rng.state, equals(advanced.rng.state));
      expect(round.state.simNowMs, equals(advanced.simNowMs));
    });

    test('envelope metadata round-trips (schemaVersion + savedAtMs)', () {
      final EmberWorldState seeded = WorldSeed.newGame(seed: _fixedSeed);
      final SaveEnvelope env = _envelope(seeded, savedAtMs: 99887766);

      final SaveEnvelope round = SaveEnvelope.fromJson(env.toJson());

      expect(round.schemaVersion, equals(SaveEnvelope.currentSchemaVersion));
      expect(round.savedAtMs, equals(99887766));
    });

    test('persisting through the repository is idempotent', () async {
      // The repo encodes on save + decodes (through migrations) on load, so this
      // exercises the SAME serialization path Hive uses.
      final InMemorySaveRepository repo = InMemorySaveRepository();
      final EmberWorldState seeded = WorldSeed.newGame(seed: _fixedSeed);
      final SaveEnvelope env = _envelope(seeded);

      await repo.save(env);
      final SaveEnvelope? first = await repo.load();
      expect(first, isNotNull);

      // Save the reloaded value again and reload: stable across repeated cycles.
      await repo.save(first!);
      final SaveEnvelope? second = await repo.load();
      expect(second, isNotNull);

      expect(
        jsonEncode(second!.toJson()),
        equals(jsonEncode(env.toJson())),
        reason: 'repeated save/load cycles must not drift the document',
      );
      expect(second, equals(env));
    });
  });
}
