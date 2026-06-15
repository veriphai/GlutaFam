// Ember — sim/systems/fire_coverage.dart
//
// Computes the LIT (and WARM) tile sets from active fire placeables — WITHOUT
// importing the fire leaf. The fire leaf PUBLISHES its emitter as a list of
// LightSource maps under the shared ext key [kLightSourcesExtKey]; this system
// reads them back through the shared LightSource type. Night/predator/coverage
// systems consume the result. Pure + deterministic (no clock/random).
//
// A tile is "lit" if total coverage from all sources >= [litThreshold]; "warm"
// uses a lower [warmThreshold] (warmth reaches a bit further than usable light).

import '../../contracts/light_source.dart';
import '../../core/geometry.dart';
import '../../data/models/placeable.dart';
import '../../data/models/world_state.dart';

/// The ext-bag key under which a fire placeable publishes its LightSources.
/// Frozen so the fire leaf and this system agree without coupling.
const String kLightSourcesExtKey = 'lightSources';

/// The result of a coverage pass: the lit + warm tile sets and the raw sources.
class FireCoverage {
  const FireCoverage({
    required this.litTiles,
    required this.warmTiles,
    required this.sources,
  });

  /// Tiles with usable light.
  final Set<GridCoord> litTiles;

  /// Tiles with warmth (superset-ish of lit; reaches slightly further).
  final Set<GridCoord> warmTiles;

  /// All active light sources this pass considered.
  final List<LightSource> sources;

  bool isLit(GridCoord c) => litTiles.contains(c);
  bool isWarm(GridCoord c) => warmTiles.contains(c);

  int get litCount => litTiles.length;
  int get warmCount => warmTiles.length;
  bool get hasAnyLight => sources.isNotEmpty;

  static const FireCoverage empty = FireCoverage(
    litTiles: <GridCoord>{},
    warmTiles: <GridCoord>{},
    sources: <LightSource>[],
  );
}

class FireCoverageSystem {
  const FireCoverageSystem({
    this.litThreshold = 0.25,
    this.warmThreshold = 0.1,
  });

  /// Minimum total coverage for a tile to count as lit.
  final double litThreshold;

  /// Minimum total coverage for a tile to count as warm.
  final double warmThreshold;

  /// Reads all active fire placeables' published LightSources and computes the
  /// lit/warm tile sets across the grid.
  FireCoverage compute(EmberWorldState s) {
    final List<LightSource> sources = collectSources(s);
    if (sources.isEmpty) return FireCoverage.empty;

    final Set<GridCoord> lit = <GridCoord>{};
    final Set<GridCoord> warm = <GridCoord>{};

    // For each source, walk the tiles inside its bounding radius and accumulate
    // coverage. We accumulate per-tile across sources via a temp map.
    final Map<GridCoord, double> coverage = <GridCoord, double>{};
    for (final LightSource src in sources) {
      final int r = src.effectiveRadius.ceil();
      if (r <= 0) continue;
      for (int dy = -r; dy <= r; dy++) {
        for (int dx = -r; dx <= r; dx++) {
          final GridCoord c = src.pos.translate(dx, dy);
          if (!s.tiles.inBounds(c)) continue;
          final double add = src.coverageAt(c);
          if (add <= 0) continue;
          coverage[c] = (coverage[c] ?? 0.0) + add;
        }
      }
    }

    for (final MapEntry<GridCoord, double> e in coverage.entries) {
      if (e.value >= litThreshold) lit.add(e.key);
      if (e.value >= warmThreshold) warm.add(e.key);
    }

    return FireCoverage(litTiles: lit, warmTiles: warm, sources: sources);
  }

  /// Pulls the published LightSources off every active placeable's ext bag.
  /// Leaf-blind: it only knows the shared key + shared LightSource shape.
  List<LightSource> collectSources(EmberWorldState s) {
    final List<LightSource> out = <LightSource>[];
    for (final Placeable p in s.placeables) {
      if (!p.isActive) continue;
      final Object? raw = p.ext[kLightSourcesExtKey];
      if (raw is! List) continue;
      for (final Object? item in raw) {
        if (item is Map) {
          out.add(LightSource.fromJson(item.cast<String, dynamic>()));
        }
      }
    }
    return out;
  }
}
