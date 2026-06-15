// Ember — core/ids.dart
//
// Stable string-backed identifiers plus a DETERMINISTIC id factory. No
// DateTime.now()/Random()/Stopwatch here — ids are derived from an EmberRng and
// a human-readable prefix so the same seed + same call order yields the same
// ids on live play, offline catch-up, and tests.

import 'ember_rng.dart';

/// Opaque identifier for a world entity (placeable, node, npc, event, ...).
typedef EntityId = String;

/// Mints deterministic [EntityId]s from a seeded [EmberRng].
///
/// Holds NO global mutable state of its own — the only entropy is the [EmberRng]
/// the caller threads through, which is itself serialized into the save. Two
/// runs that advance the same rng in the same order produce identical ids.
class IdFactory {
  const IdFactory();

  /// Builds a `<prefix>-<hex>` id by pulling one 32-bit chunk from [rng].
  ///
  /// Mutates [rng] (advances its state) — that mutation is intentional and is
  /// what makes the stream reproducible.
  EntityId mint(String prefix, EmberRng rng) {
    final int n = rng.nextU32();
    return '$prefix-${n.toRadixString(16).padLeft(8, '0')}';
  }

  /// Convenience for a coordinate-anchored id (e.g. seed-time tiles/nodes) that
  /// must be stable WITHOUT consuming rng — same (prefix,x,y) => same id.
  EntityId at(String prefix, int x, int y) => '$prefix-${x}_$y';
}

/// Shared singleton factory (it is stateless, so sharing is safe).
const IdFactory ids = IdFactory();
