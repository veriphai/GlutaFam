// Ember — contracts/placeable_def.dart
//
// The static catalogue entry for a placeable TYPE (not an instance). A leaf
// declares one of these per type it owns; the registry collects them and the sim
// reads them via SimRegistry.defFor(type) for cost/footprint/terrain/behavior.
// Instances are the generic [Placeable]; the typed knowledge lives here.

import '../core/enums.dart';
import '../data/models/resource_cost.dart';
import 'placeable_behavior.dart';

class PlaceableDef {
  const PlaceableDef({
    required this.kind,
    required this.displayName,
    required this.artKey,
    required this.cost,
    required this.buildDurationMs,
    this.footprint = const PlaceableFootprint(1, 1),
    required this.allowedTerrain,
    this.tierChain = const <int>[1],
    this.behavior = const InertBehavior(),
    this.initialPayload = const <String, dynamic>{},
  });

  /// The enum type this def describes.
  final PlaceableType kind;

  /// Human-readable name for the build menu / tooltips.
  final String displayName;

  /// Stable art key the [EmberArt] facade maps to a visual (placeholder now).
  final String artKey;

  /// Resource cost to build the base tier.
  final ResourceCost cost;

  /// How long construction takes (ms of sim time) at the base tier.
  final int buildDurationMs;

  /// Tile footprint (width x height).
  final PlaceableFootprint footprint;

  /// Terrain types this placeable may be built on.
  final List<TerrainType> allowedTerrain;

  /// Valid tier values, ascending (e.g. [1,2,3]). Base tier is first.
  final List<int> tierChain;

  /// The runtime behavior ticked by the sim (default inert).
  final PlaceableBehavior behavior;

  /// Seed payload copied into a fresh instance's `ext` at placement.
  final Map<String, dynamic> initialPayload;

  int get maxTier => tierChain.isEmpty ? 1 : tierChain.last;
  int get baseTier => tierChain.isEmpty ? 1 : tierChain.first;

  /// Whether [terrain] is allowed for this placeable.
  bool allowsTerrain(TerrainType terrain) => allowedTerrain.contains(terrain);

  PlaceableDef copyWith({
    PlaceableType? kind,
    String? displayName,
    String? artKey,
    ResourceCost? cost,
    int? buildDurationMs,
    PlaceableFootprint? footprint,
    List<TerrainType>? allowedTerrain,
    List<int>? tierChain,
    PlaceableBehavior? behavior,
    Map<String, dynamic>? initialPayload,
  }) {
    return PlaceableDef(
      kind: kind ?? this.kind,
      displayName: displayName ?? this.displayName,
      artKey: artKey ?? this.artKey,
      cost: cost ?? this.cost,
      buildDurationMs: buildDurationMs ?? this.buildDurationMs,
      footprint: footprint ?? this.footprint,
      allowedTerrain: allowedTerrain ?? this.allowedTerrain,
      tierChain: tierChain ?? this.tierChain,
      behavior: behavior ?? this.behavior,
      initialPayload: initialPayload ?? this.initialPayload,
    );
  }
}

/// Tile footprint of a placeable (width x height in grid cells).
class PlaceableFootprint {
  const PlaceableFootprint(this.width, this.height);

  final int width;
  final int height;

  int get area => width * height;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'width': width, 'height': height};

  factory PlaceableFootprint.fromJson(Map<String, dynamic> j) =>
      PlaceableFootprint(
        (j['width'] as num?)?.toInt() ?? 1,
        (j['height'] as num?)?.toInt() ?? 1,
      );

  @override
  bool operator ==(Object other) =>
      other is PlaceableFootprint &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => '${width}x$height';
}
