// Ember — concepts/fire/fire_behavior.dart
//
// The runtime brain the sim ticks for every fire placeable. Each fixed step it:
//   * burns fuel down by (burnRate * dt) while the fire is lit,
//   * snuffs the fire (isLit -> false) once the tank hits empty,
//   * re-bakes the published [LightSource] payload into the placeable's ext bag
//     so fire_coverage + the night overlay read the CURRENT light/warmth/intensity.
//
// It mutates ONLY the placeable's generic `ext` bag (via the typed [FireObject]
// view) — never the shared model, never world state at large. PURE + DETERMINISTIC:
// it advances solely by [dtSeconds] (no clock/random), so live play, offline
// catch-up, and tests all converge.

import '../../contracts/placeable_behavior.dart';
import '../../data/models/placeable.dart';
import '../../data/models/world_state.dart';
import 'model/fire_object.dart';

/// Burns fuel + publishes light for a fire placeable.
class FireBehavior extends PlaceableBehavior {
  const FireBehavior();

  @override
  void onBuilt(Placeable p, EmberWorldState state) {
    // Seed a full, lit fire if the placement didn't already stamp a payload.
    final FireObject fire = FireObject.fromPlaceable(p);
    // A freshly-built fire starts alight (the player just lit it / placed it).
    final FireObject lit = fire.copyWith(isLit: true);
    lit.applyTo(p);
  }

  @override
  void onTick(Placeable p, EmberWorldState state, double dtSeconds) {
    if (dtSeconds <= 0) return;
    FireObject fire = FireObject.fromPlaceable(p);

    if (fire.isLit && fire.hasFuel) {
      final double burned = fire.fuelBurnRate * dtSeconds;
      final double nextFuel = (fire.fuelLevel - burned).clamp(0.0, double.infinity);
      final bool stillLit = nextFuel > 0.0;
      fire = fire.copyWith(
        fuelLevel: nextFuel,
        // Goes out when the tank empties (fire needs FUEL — the triangle in play).
        isLit: stillLit,
      );
    } else if (!fire.hasFuel && fire.isLit) {
      // Defensive: an empty-but-lit fire (e.g. loaded mid-state) snuffs out.
      fire = fire.copyWith(isLit: false);
    }

    // Re-bake the payload every tick so intensity tracks fuel as it falls and the
    // coverage system always sees the current source (or none, once out).
    fire.applyTo(p);
  }
}
