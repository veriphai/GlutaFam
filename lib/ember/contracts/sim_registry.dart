// Ember — contracts/sim_registry.dart
//
// THE seam that lets sim/ stay leaf-blind. WorldSimulation depends on this
// ABSTRACT interface, never on the concrete registry/concept_registry.dart (which
// imports all three leaves and implements this last). Through it the sim asks:
// "what's the effective gather modifier? what behavior runs this placeable type?
// who resolves this event? what's the def for this type?" — all answered by the
// registry without the sim ever knowing a leaf exists.

import '../core/enums.dart';
import 'event_resolver.dart';
import 'gather_modifier.dart';
import 'placeable_behavior.dart';
import 'placeable_def.dart';

/// Read-only registry view the simulation consumes. Implemented later by
/// registry/concept_registry.dart. Every method is pure/deterministic.
abstract interface class SimRegistry {
  /// The effective (composed) gather modifier across all installed concepts.
  /// Defaults to x1.0 ([DefaultGatherModifier]) when no leaf pushes tools.
  GatherModifier get gatherModifier;

  /// The runtime behavior for placeable [type], or null if the type has no def
  /// registered (the sim treats null as inert).
  PlaceableBehavior? behaviorFor(PlaceableType type);

  /// The resolvers that can handle a [WorldEventType], in priority order. The
  /// event system runs the first whose canResolve(type) is true.
  List<EventResolver> resolversFor(WorldEventType type);

  /// The static def for placeable [type], or null if unregistered.
  PlaceableDef? defFor(PlaceableType type);
}

/// An empty registry: x1.0 gathering, no behaviors, no resolvers, no defs.
/// Lets the sim and tests run before any concept is wired (and is a safe
/// fallback). Pure + const.
class EmptySimRegistry implements SimRegistry {
  const EmptySimRegistry();

  @override
  GatherModifier get gatherModifier => const DefaultGatherModifier();

  @override
  PlaceableBehavior? behaviorFor(PlaceableType type) => null;

  @override
  List<EventResolver> resolversFor(WorldEventType type) => const <EventResolver>[];

  @override
  PlaceableDef? defFor(PlaceableType type) => null;
}
