// Ember — data/models/terrain_type.dart
//
// Static, DERIVED properties of each TerrainType (buildable + base flood risk).
// These are defaults a tile can override; the enum itself stays in core/.

import '../../core/enums.dart';

/// Derived, read-only properties for a [TerrainType].
class TerrainProps {
  const TerrainProps({
    required this.type,
    required this.buildable,
    required this.baseFloodRisk,
    required this.gatherable,
  });

  final TerrainType type;

  /// Whether placeables may be built on this terrain by default.
  final bool buildable;

  /// Base 0..1 flood risk contributed by this terrain alone.
  final double baseFloodRisk;

  /// Whether resource nodes can sit on / be harvested from this terrain.
  final bool gatherable;
}

/// The single source of derived terrain properties.
class TerrainCatalog {
  const TerrainCatalog._();

  static const Map<TerrainType, TerrainProps> _all = <TerrainType, TerrainProps>{
    TerrainType.grass: TerrainProps(
      type: TerrainType.grass,
      buildable: true,
      baseFloodRisk: 0.15,
      gatherable: true,
    ),
    TerrainType.water: TerrainProps(
      type: TerrainType.water,
      buildable: false,
      baseFloodRisk: 1.0,
      gatherable: false,
    ),
    TerrainType.forest: TerrainProps(
      type: TerrainType.forest,
      buildable: true,
      baseFloodRisk: 0.2,
      gatherable: true,
    ),
    TerrainType.rocky: TerrainProps(
      type: TerrainType.rocky,
      buildable: true,
      baseFloodRisk: 0.1,
      gatherable: true,
    ),
    TerrainType.highGround: TerrainProps(
      type: TerrainType.highGround,
      buildable: true,
      baseFloodRisk: 0.0,
      gatherable: true,
    ),
  };

  static TerrainProps of(TerrainType t) => _all[t]!;

  static bool buildable(TerrainType t) => of(t).buildable;
  static double baseFloodRisk(TerrainType t) => of(t).baseFloodRisk;
  static bool gatherable(TerrainType t) => of(t).gatherable;
}
