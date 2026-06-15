// Ember — contracts/placeable_behavior.dart
//
// The per-placeable runtime brain a leaf implements (e.g. a hearth burns fuel and
// emits a LightSource each tick; a toolRack flags tools available on build). The
// sim resolves behaviors via SimRegistry.behaviorFor(type) so it never imports a
// leaf. Behaviors mutate the placeable's generic `ext` bag in place — that is the
// only state they own — and may read the world (read-only) for context.
//
// PURE + DETERMINISTIC: onTick/onBuilt take dt in seconds and the world but no
// clock/random of their own. Any chance must come from rng threaded by the sim
// (behaviors here are deterministic by [dt]; chance-bearing logic lives in
// systems that hold the EmberRng).

import '../data/models/placeable.dart';
import '../data/models/world_state.dart';

/// Runtime behavior for a placeable type. A leaf provides one via its
/// [PlaceableDef]; the sim ticks it. Default behavior = inert (does nothing).
abstract class PlaceableBehavior {
  const PlaceableBehavior();

  /// Called every fixed sim step while the placeable is active (built/damaged).
  /// [dtSeconds] is the fixed step in seconds. Mutate [p.ext] / [p] in place.
  void onTick(Placeable p, EmberWorldState state, double dtSeconds);

  /// Called once when the placeable transitions to `built`. Seed any payload
  /// (e.g. initial fuel) into [p.ext] here.
  void onBuilt(Placeable p, EmberWorldState state);
}

/// A behavior that does nothing — the default for placeables with no live logic.
class InertBehavior extends PlaceableBehavior {
  const InertBehavior();

  @override
  void onTick(Placeable p, EmberWorldState state, double dtSeconds) {}

  @override
  void onBuilt(Placeable p, EmberWorldState state) {}
}
