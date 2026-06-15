// Ember — concepts/shelter/model/dwelling.dart
//
// The TYPED VIEW over a generic [Placeable]'s untyped `ext` bag for shelter
// objects. A dwelling (or a defense wall) stores its bespoke state — capacity,
// comfort, durability, flood-resistance, and live build progress — inside
// Placeable.ext under stable string keys; this class reads it back strongly
// typed and writes it back into the ext bag. It NEVER edits the shared Placeable
// model — it only round-trips through the open `ext` bag (the dir-lock contract).
//
// IMPORTANT cross-concept seam: a dwelling PUBLISHES its housing capacity under
// the FROZEN foundation key [kDwellingCapacityExtKey] (declared in
// sim/systems/population_system.dart). The PopulationSystem sums that key across
// active dwellings onto the village cap — exactly the way Fire publishes a
// LightSource into ext for the coverage system to read back. We write that key
// here so the foundation reads our contribution leaf-blind.
//
// Pure value type: no Flame/Flutter, no clock/random. The behavior + component
// mutate durability/buildProgress through this view; this is the single place
// those raw keys are named.

import '../../../core/enums.dart';
import '../../../sim/systems/population_system.dart';

/// The closed family of shelter objects (mirrors the shelter-owned
/// [PlaceableType]s). Stored as `.name` in the ext bag so it round-trips.
enum DwellingType { leanTo, hideTent, hut, palisade }

/// Maps a [PlaceableType] to its [DwellingType] view and back.
DwellingType dwellingTypeFromPlaceable(PlaceableType t) => switch (t) {
      PlaceableType.leanTo => DwellingType.leanTo,
      PlaceableType.hideTent => DwellingType.hideTent,
      PlaceableType.hut => DwellingType.hut,
      PlaceableType.palisade => DwellingType.palisade,
      // Defensive: a non-shelter placeable should never reach here.
      _ => DwellingType.leanTo,
    };

PlaceableType placeableTypeForDwelling(DwellingType t) => switch (t) {
      DwellingType.leanTo => PlaceableType.leanTo,
      DwellingType.hideTent => PlaceableType.hideTent,
      DwellingType.hut => PlaceableType.hut,
      DwellingType.palisade => PlaceableType.palisade,
    };

DwellingType _dwellingTypeFromName(Object? n) {
  if (n is String) {
    for (final DwellingType v in DwellingType.values) {
      if (v.name == n) return v;
    }
  }
  return DwellingType.leanTo;
}

/// Stable ext-bag keys the shelter leaf owns. Frozen so the behavior, component,
/// activity placeHint, population source, and this view all agree.
///
/// NOTE: [kDwellingCapacityExtKey] (the frozen FOUNDATION key the PopulationSystem
/// reads) is written from [Dwelling.toExt] too — it is NOT redeclared here; we
/// reuse the foundation constant so there is exactly one source of truth.
class DwellingExtKeys {
  const DwellingExtKeys._();

  static const String dwellingType = 'dwellingType';
  static const String comfort = 'comfort';
  static const String durability = 'durability';
  static const String floodResistance = 'floodResistance';
  // capacity is published under kDwellingCapacityExtKey (foundation-frozen).
}

/// A strongly-typed view over a shelter [Placeable]'s ext payload.
///
/// A palisade is modelled as a [Dwelling] with capacity 0 + comfort 0 (it is a
/// pure DEFENSE wall): it still carries durability + floodResistance so the flood
/// resolver and the degradation path treat it uniformly. The [isDefense] getter
/// distinguishes it for the renderer / UI.
class Dwelling {
  const Dwelling({
    required this.dwellingType,
    required this.capacity,
    required this.comfort,
    required this.durability,
    required this.floodResistance,
  });

  /// Which shelter object this is.
  final DwellingType dwellingType;

  /// How many tribe members this dwelling houses (the population lever).
  /// 0 for a palisade (a defense, not housing).
  final int capacity;

  /// 0..1 warmth/coziness this dwelling provides (blends with fire warmth).
  final double comfort;

  /// 0..1 structural soundness. A flood damages this; at 0 the dwelling is a
  /// wreck (still standing, stylized — never peril to people).
  final double durability;

  /// 0..1 how well this dwelling sheds rising water (a hut on stilts > a tent).
  /// Combined with the TILE flood-risk by the flood resolver.
  final double floodResistance;

  /// True for a wall-type defense (no housing).
  bool get isDefense => dwellingType == DwellingType.palisade;

  /// Whether this dwelling currently contributes any housing.
  bool get housesAnyone => capacity > 0;

  /// The defaults for a freshly-built shelter of [type].
  factory Dwelling.initial(DwellingType type) => switch (type) {
        // Cheap, fast, low everything — the first roof over your head.
        DwellingType.leanTo => const Dwelling(
            dwellingType: DwellingType.leanTo,
            capacity: 1,
            comfort: 0.30,
            durability: 0.45,
            floodResistance: 0.25,
          ),
        // Portable + a bit warmer, but light — the fast option, still cold/low.
        DwellingType.hideTent => const Dwelling(
            dwellingType: DwellingType.hideTent,
            capacity: 2,
            comfort: 0.55,
            durability: 0.55,
            floodResistance: 0.35,
          ),
        // Sturdy + warm + roomy — but it costs tools + more wood (the tradeoff).
        DwellingType.hut => const Dwelling(
            dwellingType: DwellingType.hut,
            capacity: 3,
            comfort: 0.85,
            durability: 0.85,
            floodResistance: 0.65,
          ),
        // A thorn/timber wall: no housing, high durability — keeps predators out.
        DwellingType.palisade => const Dwelling(
            dwellingType: DwellingType.palisade,
            capacity: 0,
            comfort: 0.0,
            durability: 0.90,
            floodResistance: 0.50,
          ),
      };

  /// Reads a [Dwelling] out of a placeable's ext bag, falling back to the initial
  /// defaults for that type if a key is missing.
  factory Dwelling.fromExt(PlaceableType pType, Map<String, dynamic> e) {
    final DwellingType type = e.containsKey(DwellingExtKeys.dwellingType)
        ? _dwellingTypeFromName(e[DwellingExtKeys.dwellingType])
        : dwellingTypeFromPlaceable(pType);
    final Dwelling defaults = Dwelling.initial(type);
    return Dwelling(
      dwellingType: type,
      capacity: (e[kDwellingCapacityExtKey] as num?)?.toInt() ??
          defaults.capacity,
      comfort:
          (e[DwellingExtKeys.comfort] as num?)?.toDouble() ?? defaults.comfort,
      durability: (e[DwellingExtKeys.durability] as num?)?.toDouble() ??
          defaults.durability,
      floodResistance:
          (e[DwellingExtKeys.floodResistance] as num?)?.toDouble() ??
              defaults.floodResistance,
    );
  }

  Dwelling copyWith({
    DwellingType? dwellingType,
    int? capacity,
    double? comfort,
    double? durability,
    double? floodResistance,
  }) {
    return Dwelling(
      dwellingType: dwellingType ?? this.dwellingType,
      capacity: capacity ?? this.capacity,
      comfort: comfort ?? this.comfort,
      durability: durability ?? this.durability,
      floodResistance: floodResistance ?? this.floodResistance,
    );
  }

  /// Applies flood damage as a fraction (0..1) of durability lost. Capacity is
  /// withdrawn proportionally while the structure is wrecked: a badly-damaged
  /// dwelling shelters fewer people until it is rebuilt. Returns a NEW view.
  Dwelling damaged(double fraction) {
    final double f = fraction.clamp(0.0, 1.0);
    final double nextDur = (durability - f).clamp(0.0, 1.0);
    // Capacity scales with how sound the structure still is (a wrecked roof
    // houses no one). Round so a small nick doesn't instantly evict a family.
    final int baseCap = Dwelling.initial(dwellingType).capacity;
    final int nextCap = (baseCap * nextDur).round();
    return copyWith(durability: nextDur, capacity: nextCap);
  }

  /// Serializes this dwelling view into a flat ext map. The housing capacity is
  /// published under the FROZEN foundation key [kDwellingCapacityExtKey] so the
  /// PopulationSystem reads our contribution leaf-blind.
  Map<String, dynamic> toExt() => <String, dynamic>{
        DwellingExtKeys.dwellingType: dwellingType.name,
        kDwellingCapacityExtKey: capacity,
        DwellingExtKeys.comfort: comfort,
        DwellingExtKeys.durability: durability,
        DwellingExtKeys.floodResistance: floodResistance,
      };

  @override
  bool operator ==(Object other) =>
      other is Dwelling &&
      other.dwellingType == dwellingType &&
      other.capacity == capacity &&
      other.comfort == comfort &&
      other.durability == durability &&
      other.floodResistance == floodResistance;

  @override
  int get hashCode => Object.hash(
        dwellingType,
        capacity,
        comfort,
        durability,
        floodResistance,
      );
}
