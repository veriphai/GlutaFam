// Ember — sim/systems/population_system.dart
//
// Derives the village population cap and comfort index from the world — WITHOUT
// importing the shelter or fire leaves. Dwellings PUBLISH their capacity under the
// shared ext key [kDwellingCapacityExtKey]; this system sums them onto the base
// cap. Comfort blends shelter coverage (sheltered NPCs), fire warmth coverage, and
// a food cushion. Pure + deterministic (no clock/random).

import '../../core/constants.dart';
import '../../core/enums.dart';
import '../../data/models/npc.dart';
import '../../data/models/placeable.dart';
import '../../data/models/resource_stock.dart';
import '../../data/models/village.dart';
import '../../data/models/world_state.dart';
import 'fire_coverage.dart';

/// Ext-bag key under which a shelter dwelling publishes its capacity (int).
/// Frozen so the shelter leaf and this system agree without coupling.
const String kDwellingCapacityExtKey = 'dwellingCapacity';

class PopulationSystem {
  const PopulationSystem();

  /// Recomputes populationCap (base + summed dwelling capacity) and comfortIndex,
  /// writing both back onto the village. [coverage] is the fire-coverage pass
  /// (warm tiles) for this tick; pass FireCoverage.empty if none.
  EmberWorldState recompute(EmberWorldState s, FireCoverage coverage) {
    final int dwellingCap = _dwellingCapacity(s);
    final int cap = EmberConstants.basePopulationCap + dwellingCap;
    final double comfort = _comfortIndex(s, coverage, cap);

    final Village v = s.village;
    if (v.populationCap == cap && v.comfortIndex == comfort) return s;
    return s.copyWith(
      village: v.copyWith(populationCap: cap, comfortIndex: comfort),
    );
  }

  /// Sum of capacity published by active dwellings.
  int _dwellingCapacity(EmberWorldState s) {
    int sum = 0;
    for (final Placeable p in s.placeables) {
      if (!p.isActive) continue;
      final Object? raw = p.ext[kDwellingCapacityExtKey];
      if (raw is num) sum += raw.toInt();
    }
    return sum;
  }

  /// 0..1 comfort: weighted blend of shelter, warmth, and food.
  ///   - shelterShare: how much of the population the dwellings can house.
  ///   - warmShare: fraction of NPCs standing on warm tiles at night-readiness.
  ///   - foodShare: how far the food stock is above its low threshold.
  double _comfortIndex(EmberWorldState s, FireCoverage coverage, int cap) {
    final int pop = s.village.populationCurrent.clamp(0, 1 << 20);
    final int housed = (cap - EmberConstants.basePopulationCap).clamp(0, cap);
    final double shelterShare =
        pop <= 0 ? 1.0 : (housed / pop).clamp(0.0, 1.0);

    // Warmth: fraction of NPCs currently on a warm tile.
    double warmShare = 0.0;
    if (s.npcs.isNotEmpty && coverage.warmTiles.isNotEmpty) {
      int warm = 0;
      for (final Npc npc in s.npcs) {
        if (coverage.isWarm(npc.coord)) warm++;
      }
      warmShare = (warm / s.npcs.length).clamp(0.0, 1.0);
    } else if (coverage.hasAnyLight) {
      warmShare = 0.5; // some fire exists even if no NPC stands in it.
    }

    // Food cushion: stock above threshold, normalized by the cap headroom.
    final StockLine foodLine = s.stock.lineOf(ResourceType.food);
    final int headroom = (foodLine.cap - foodLine.threshold).clamp(1, 1 << 30);
    final double foodShare =
        ((foodLine.amount - foodLine.threshold) / headroom).clamp(0.0, 1.0);

    // Weighted blend (shelter 0.45, warmth 0.35, food 0.20).
    final double comfort =
        shelterShare * 0.45 + warmShare * 0.35 + foodShare * 0.20;
    // Round to 4 decimals for byte-stable round-trips.
    return (comfort.clamp(0.0, 1.0) * 10000).round() / 10000;
  }
}
