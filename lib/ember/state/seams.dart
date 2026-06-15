// Ember — state/seams.dart
//
// The cross-concept PUSH seams. A leaf NEVER imports another leaf; instead, in
// ConceptModule.onInstall(ref) it PUSHES its contribution into one of these
// providers, and the foundation (sim/selectors/UI) READS the composed result.
// That keeps the dependency graph leaf -> foundation only, with zero leaf->leaf
// edges.
//
// Two flavours live here:
//   1. INSTALLABLE seams — mutable registries leaves append to at bootstrap
//      (tools push a GatherModifier; shelter pushes a population-cap source). The
//      controller composes them when applying intents / running the sim.
//   2. DERIVED seams — read-only providers computed from the current world state
//      (light sources are derived from placeables' ext bags; event resolvers come
//      from the registry).
//
// FROZEN: the legacy Riverpod `Ref` is used throughout. Leaves receive this same
// Ref at install time via the bootstrap ProviderContainer.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contracts/event_resolver.dart';
import '../contracts/gather_modifier.dart';
import '../contracts/light_source.dart';
import '../contracts/sim_registry.dart';
import '../core/enums.dart';
import '../data/models/world_state.dart';
import '../sim/systems/fire_coverage.dart';
import 'providers.dart';
import 'world_controller.dart';

// ===========================================================================
// Installable PUSH seams — leaves append to these in onInstall(ref).
// ===========================================================================

/// A single population-cap contributor a leaf pushes (e.g. shelter's "a built
/// hut adds +2"). Pure: it reads the seam's [PopulationCapInput] and returns the
/// extra cap it grants. The controller sums all sources onto the base cap.
typedef PopulationCapSource = int Function(PopulationCapInput input);

/// The read-only context a [PopulationCapSource] is evaluated against.
class PopulationCapInput {
  const PopulationCapInput({
    required this.builtCounts,
    required this.warmTileCount,
  });

  /// How many BUILT placeables of each type exist (by enum name).
  final Map<String, int> builtCounts;

  /// How many tiles are currently warm (fire coverage) — shelter may gate cap on
  /// warmth so unheated huts don't count.
  final int warmTileCount;
}

/// Tool-multiplier PUSH seam. The stone-tools leaf pushes its [GatherModifier]
/// here in onInstall; the resource system reads the EFFECTIVE composed modifier
/// (default x1.0 when empty). Stored as a list so multiple sources compose.
final StateProvider<List<GatherModifier>> toolMultiplierProvider =
    StateProvider<List<GatherModifier>>((Ref ref) => const <GatherModifier>[]);

/// Population-cap PUSH seam. The shelter leaf pushes one or more
/// [PopulationCapSource]s here; selectors sum them onto the base cap.
final StateProvider<List<PopulationCapSource>> populationCapSourceProvider =
    StateProvider<List<PopulationCapSource>>(
  (Ref ref) => const <PopulationCapSource>[],
);

// ===========================================================================
// Derived / read-only seams — computed from world state or the registry.
// ===========================================================================

/// The abstract [SimRegistry] the simulation consumes. Wraps the concrete
/// ConceptRegistry (from [registryProvider]) but EXPOSES ONLY the SimRegistry
/// surface, so anything depending on this stays leaf-blind.
final Provider<SimRegistry> simRegistryProvider = Provider<SimRegistry>(
  (Ref ref) => ref.watch(registryProvider),
);

/// The effective composed tool [GatherModifier] (what tools have pushed, folded
/// into one). Default x1.0 when nothing is installed.
final Provider<GatherModifier> effectiveGatherModifierProvider =
    Provider<GatherModifier>((Ref ref) {
  final List<GatherModifier> parts = ref.watch(toolMultiplierProvider);
  if (parts.isEmpty) return const DefaultGatherModifier();
  if (parts.length == 1) return parts.first;
  return CompositeGatherModifier(parts);
});

/// Read-only: the active LightSources currently published by fire placeables,
/// derived from the live world. Night / predator / coverage readers consume this
/// — the fire leaf only ever PUSHES into the ext bag the sim reads.
final Provider<List<LightSource>> lightSourcesProvider =
    Provider<List<LightSource>>((Ref ref) {
  final EmberWorldState s = ref.watch(worldControllerProvider);
  const FireCoverageSystem coverage = FireCoverageSystem();
  return coverage.collectSources(s);
});

/// Read-only: the event resolvers, sourced from the registry. The sim reads
/// resolvers per-type through SimRegistry; this provider exposes the full set
/// (deduplicated across event types) for UI/debug.
final Provider<List<EventResolver>> eventResolversProvider =
    Provider<List<EventResolver>>((Ref ref) {
  final SimRegistry registry = ref.watch(simRegistryProvider);
  final List<EventResolver> out = <EventResolver>[];
  for (final WorldEventType t in WorldEventType.values) {
    for (final EventResolver r in registry.resolversFor(t)) {
      if (!out.contains(r)) out.add(r);
    }
  }
  return out;
});
