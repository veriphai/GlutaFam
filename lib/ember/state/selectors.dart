// Ember — state/selectors.dart
//
// Derived, read-only views over the world the UI + game observe. Each selector is
// a thin Provider computed from worldControllerProvider (+ the push seams), so a
// widget can watch exactly the slice it cares about and rebuild only when that
// slice changes. Pure: selectors never mutate or persist.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contracts/light_source.dart';
import '../core/enums.dart';
import '../data/models/resource_stock.dart';
import '../data/models/world_state.dart';
import '../sim/away_digest.dart';
import '../sim/systems/fire_coverage.dart';
import 'seams.dart';
import 'world_controller.dart';

/// The player's resource stockpile.
final Provider<ResourceStock> resourceStockProvider = Provider<ResourceStock>(
  (Ref ref) => ref.watch(worldControllerProvider).stock,
);

/// The amount of a single [ResourceType] (handy for HUD counters).
final ProviderFamily<int, ResourceType> resourceAmountProvider =
    Provider.family<int, ResourceType>(
  (Ref ref, ResourceType type) =>
      ref.watch(worldControllerProvider).stock.amountOf(type),
);

/// Live fire coverage (lit + warm tile sets) over the current world.
final Provider<FireCoverage> fireCoverageProvider = Provider<FireCoverage>(
  (Ref ref) {
    final EmberWorldState s = ref.watch(worldControllerProvider);
    const FireCoverageSystem coverage = FireCoverageSystem();
    return coverage.compute(s);
  },
);

/// The effective population cap: the village base cap plus everything the shelter
/// leaf has PUSHED via [populationCapSourceProvider]. Cap sources are evaluated
/// against built-placeable counts + current warm-tile coverage.
final Provider<int> populationCapProvider = Provider<int>((Ref ref) {
  final EmberWorldState s = ref.watch(worldControllerProvider);
  final List<PopulationCapSource> sources =
      ref.watch(populationCapSourceProvider);
  if (sources.isEmpty) return s.village.populationCap;

  // Built counts by placeable type name.
  final Map<String, int> builtCounts = <String, int>{};
  for (final p in s.placeables) {
    if (p.isBuilt) {
      builtCounts[p.type.name] = (builtCounts[p.type.name] ?? 0) + 1;
    }
  }
  final FireCoverage coverage = ref.watch(fireCoverageProvider);
  final PopulationCapInput input = PopulationCapInput(
    builtCounts: builtCounts,
    warmTileCount: coverage.warmCount,
  );

  int extra = 0;
  for (final PopulationCapSource src in sources) {
    extra += src(input);
  }
  return s.village.populationCap + extra;
});

/// The set of concepts the player has UNLOCKED (can start the activity for).
final Provider<List<ConceptId>> unlockedConceptsProvider =
    Provider<List<ConceptId>>((Ref ref) {
  final EmberWorldState s = ref.watch(worldControllerProvider);
  return <ConceptId>[
    for (final c in s.concepts)
      if (c.unlocked) c.id,
  ];
});

/// The set of concepts the player has COMPLETED.
final Provider<List<ConceptId>> completedConceptsProvider =
    Provider<List<ConceptId>>((Ref ref) {
  final EmberWorldState s = ref.watch(worldControllerProvider);
  return <ConceptId>[
    for (final c in s.concepts)
      if (c.completed) c.id,
  ];
});

/// The away digest from the most recent catch-up (null when none/empty). Mirrors
/// [awayDigestProvider] so the UI can watch it from one selectors surface.
final Provider<AwayDigest?> awayDigestSelector = Provider<AwayDigest?>(
  (Ref ref) => ref.watch(awayDigestProvider),
);

/// Whether it is currently night (drives ambient darkening + predator pressure).
final Provider<bool> isNightProvider = Provider<bool>(
  (Ref ref) => ref.watch(worldControllerProvider).dayNight.isNight,
);

/// 0..1 darkness factor for ambient lighting (peaks mid-night).
final Provider<double> darknessProvider = Provider<double>(
  (Ref ref) => ref.watch(worldControllerProvider).dayNight.darkness,
);

/// The active light sources published by fire placeables (re-exposed from the
/// seam for the selectors surface).
final Provider<List<LightSource>> lightSourcesSelector =
    Provider<List<LightSource>>(
  (Ref ref) => ref.watch(lightSourcesProvider),
);
