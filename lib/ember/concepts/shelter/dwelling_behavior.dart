// Ember — concepts/shelter/dwelling_behavior.dart
//
// The runtime brain the sim ticks for every shelter placeable. Its job is to keep
// the dwelling's PUBLISHED housing capacity (under the foundation-frozen
// [kDwellingCapacityExtKey]) consistent with its current state:
//   * onBuilt — seed a full-health [Dwelling] payload (capacity/comfort/durability/
//     floodResistance) if placement did not already stamp one, so the moment the
//     dwelling is built the PopulationSystem can sum its capacity onto the cap.
//   * onTick — re-bake the payload so capacity tracks durability: if the flood
//     resolver lowered durability (stamped a new value into ext), the behavior
//     recomputes the housed capacity from it. A wrecked roof shelters fewer
//     people until rebuilt — taught BY CONSEQUENCE, never by lecture.
//
// It mutates ONLY the placeable's generic `ext` bag (via the typed [Dwelling]
// view) — never the shared model, never world state at large. PURE + DETERMINISTIC:
// it advances solely by reading `ext` (no clock/random), so live play, offline
// catch-up, and tests all converge. (Build PROGRESS itself is advanced by the
// foundation build system; this behavior only owns the dwelling payload.)

import '../../contracts/placeable_behavior.dart';
import '../../data/models/placeable.dart';
import '../../data/models/world_state.dart';
import '../../sim/systems/population_system.dart';
import 'model/dwelling.dart';

/// Publishes + maintains a dwelling's capacity/comfort/durability payload.
class DwellingBehavior extends PlaceableBehavior {
  const DwellingBehavior();

  @override
  void onBuilt(Placeable p, EmberWorldState state) {
    // Seed a full-health dwelling if placement did not already stamp a payload
    // (so a build-menu placement and an activity placeHint converge).
    final Dwelling d = Dwelling.fromExt(p.type, p.ext);
    _bake(p, d);
  }

  @override
  void onTick(Placeable p, EmberWorldState state, double dtSeconds) {
    // Read the current dwelling (durability may have been lowered by the flood
    // resolver) and re-derive the published capacity from it, so the
    // PopulationSystem always sees a capacity consistent with how sound the
    // structure is. Idempotent: a healthy dwelling re-bakes to the same payload.
    final Dwelling current = Dwelling.fromExt(p.type, p.ext);

    // If the structure is degraded, recompute the housed capacity from its
    // durability against the type's full capacity (the degradation path).
    final int baseCap = Dwelling.initial(current.dwellingType).capacity;
    final int consistentCap = (baseCap * current.durability).round();

    if (current.capacity == consistentCap) {
      // Already consistent — still ensure the foundation key is present (e.g. a
      // hand-loaded save missing the key) without thrashing.
      if (p.ext[kDwellingCapacityExtKey] is num &&
          (p.ext[kDwellingCapacityExtKey] as num).toInt() == consistentCap) {
        return;
      }
    }

    _bake(p, current.copyWith(capacity: consistentCap));
  }

  /// Writes the dwelling payload onto [p]'s ext bag in place (the behavior owns
  /// the doc and mutates its ext). Publishes capacity under the frozen key.
  void _bake(Placeable p, Dwelling d) {
    final Map<String, dynamic> next = d.toExt();
    for (final MapEntry<String, dynamic> e in next.entries) {
      p.ext[e.key] = e.value;
    }
  }
}
