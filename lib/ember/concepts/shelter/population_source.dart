// Ember — concepts/shelter/population_source.dart
//
// HOW SHELTER CONTRIBUTES POPULATION CAPACITY — and a precise note on the seam.
//
// The foundation reads dwelling housing capacity the SAME way it reads fire light:
// each active dwelling PUBLISHES its capacity into the generic Placeable.ext bag
// under the FROZEN key [kDwellingCapacityExtKey], and the foundation's
// PopulationSystem (sim/systems/population_system.dart) SUMS that key across
// active dwellings onto the village base cap. That is the authoritative,
// leaf-blind path — we write the key in [Dwelling.toExt] / [DwellingBehavior] and
// the sim recomputes `village.populationCap = base + sum(capacity)` each tick.
//
// There is ALSO a PUSH seam — [populationCapSourceProvider] in state/seams.dart —
// consumed by the read-only `populationCapProvider` selector, which ADDS pushed
// sources ON TOP of `village.populationCap`. Because the sim already bakes our
// dwelling capacity into `village.populationCap`, pushing a source that re-counts
// dwellings would DOUBLE-COUNT in that selector. So the shelter module's
// onInstall is intentionally a NO-OP (mirroring Fire's onInstall, which also
// relies on the ext path). This file documents that decision and exposes a pure
// helper + a ready-made [PopulationCapSource] for any future foundation use that
// wants the push form WITHOUT re-baking it into the sim — central can wire it if
// the consumption model ever changes; the leaf does not push it itself.

import '../../core/enums.dart';
import '../../data/models/placeable.dart';
import '../../data/models/world_state.dart';
import '../../sim/systems/population_system.dart';
import '../../state/seams.dart';
import 'model/dwelling.dart';

/// Pure helper: the housing capacity an active dwelling currently publishes (0
/// for a wreck or a defense wall). Reads the foundation-frozen capacity key,
/// falling back to the typed view's default if the key is absent.
class ShelterPopulation {
  const ShelterPopulation._();

  /// The capacity a single placeable [p] contributes (0 if it is not an active
  /// shelter type or houses no one).
  static int capacityOf(Placeable p) {
    if (!_isShelter(p.type) || !p.isActive) return 0;
    final Object? raw = p.ext[kDwellingCapacityExtKey];
    if (raw is num) return raw.toInt().clamp(0, 1 << 20);
    return Dwelling.fromExt(p.type, p.ext).capacity.clamp(0, 1 << 20);
  }

  /// Total housing capacity across all active dwellings in [s] (matches what the
  /// PopulationSystem sums). Exposed for UI/tests that want the shelter share.
  static int totalCapacity(EmberWorldState s) {
    int sum = 0;
    for (final Placeable p in s.placeables) {
      sum += capacityOf(p);
    }
    return sum;
  }

  /// A [PopulationCapSource] in the PUSH-seam shape, derived from BUILT counts
  /// times each type's full capacity. NOT installed by the leaf (see file header
  /// — it would double-count against the sim's ext path); provided for central /
  /// future use only.
  static int source(PopulationCapInput input) {
    int extra = 0;
    for (final MapEntry<String, int> e in input.builtCounts.entries) {
      final PlaceableType t = placeableTypeFromName(e.key);
      if (!_isShelter(t)) continue;
      final int cap = Dwelling.initial(dwellingTypeFromPlaceable(t)).capacity;
      extra += cap * e.value;
    }
    return extra;
  }

  static bool _isShelter(PlaceableType t) =>
      t == PlaceableType.leanTo ||
      t == PlaceableType.hideTent ||
      t == PlaceableType.hut ||
      t == PlaceableType.palisade;
}
