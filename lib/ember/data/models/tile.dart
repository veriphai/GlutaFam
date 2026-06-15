// Ember — data/models/tile.dart
//
// A single grid cell. `buildable`/`floodRisk` are stored per-tile (seeded from
// TerrainCatalog but overridable, e.g. a riverbank grass tile gets bumped flood
// risk). Pure value object.

import '../../core/enums.dart';
import '../../core/geometry.dart';
import '../../core/ids.dart';
import 'terrain_type.dart';

class Tile {
  const Tile({
    required this.coord,
    required this.terrain,
    required this.buildable,
    required this.floodRisk,
    this.occupantId,
    this.regionId = 0,
    this.explored = true,
  });

  /// Builds a tile with buildable/floodRisk DERIVED from the terrain, with
  /// optional per-tile overrides.
  factory Tile.fromTerrain(
    GridCoord coord,
    TerrainType terrain, {
    bool? buildable,
    double? floodRisk,
    EntityId? occupantId,
    int regionId = 0,
    bool explored = true,
  }) {
    return Tile(
      coord: coord,
      terrain: terrain,
      buildable: buildable ?? TerrainCatalog.buildable(terrain),
      floodRisk: floodRisk ?? TerrainCatalog.baseFloodRisk(terrain),
      occupantId: occupantId,
      regionId: regionId,
      explored: explored,
    );
  }

  final GridCoord coord;
  final TerrainType terrain;
  final bool buildable;

  /// 0..1 flood risk for this specific tile.
  final double floodRisk;

  /// Id of the placeable occupying this tile, if any.
  final EntityId? occupantId;

  /// Region/zone this tile belongs to (0 = starting region).
  final int regionId;

  /// Whether the player has revealed this tile.
  final bool explored;

  bool get isOccupied => occupantId != null;

  Tile copyWith({
    GridCoord? coord,
    TerrainType? terrain,
    bool? buildable,
    double? floodRisk,
    EntityId? occupantId,
    bool clearOccupant = false,
    int? regionId,
    bool? explored,
  }) {
    return Tile(
      coord: coord ?? this.coord,
      terrain: terrain ?? this.terrain,
      buildable: buildable ?? this.buildable,
      floodRisk: floodRisk ?? this.floodRisk,
      occupantId: clearOccupant ? null : (occupantId ?? this.occupantId),
      regionId: regionId ?? this.regionId,
      explored: explored ?? this.explored,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'coord': coord.toJson(),
        'terrain': terrain.name,
        'buildable': buildable,
        'floodRisk': floodRisk,
        if (occupantId != null) 'occupantId': occupantId,
        'regionId': regionId,
        'explored': explored,
      };

  factory Tile.fromJson(Map<String, dynamic> j) => Tile(
        coord: GridCoord.fromJson(
            (j['coord'] as Map).cast<String, dynamic>()),
        terrain: terrainTypeFromName(j['terrain']),
        buildable: j['buildable'] as bool? ?? true,
        floodRisk: (j['floodRisk'] as num?)?.toDouble() ?? 0.0,
        occupantId: j['occupantId'] as String?,
        regionId: (j['regionId'] as num?)?.toInt() ?? 0,
        explored: j['explored'] as bool? ?? true,
      );

  @override
  bool operator ==(Object other) =>
      other is Tile &&
      other.coord == coord &&
      other.terrain == terrain &&
      other.buildable == buildable &&
      other.floodRisk == floodRisk &&
      other.occupantId == occupantId &&
      other.regionId == regionId &&
      other.explored == explored;

  @override
  int get hashCode => Object.hash(
        coord,
        terrain,
        buildable,
        floodRisk,
        occupantId,
        regionId,
        explored,
      );
}
