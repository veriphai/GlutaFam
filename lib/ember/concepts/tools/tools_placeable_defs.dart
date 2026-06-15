// Ember — concepts/tools/tools_placeable_defs.dart
//
// The static catalogue entries for the tools leaf's two placeable types: the
// Knapping Station (make + upgrade tools) and the Tool Rack (holds tools; a small
// capacity gate). Each def carries its build cost, allowed terrain, tier chain,
// art key, seed payload (a base [Tool] baked into ext), build duration, and the
// shared [ToolsBehavior] the sim ticks. The registry collects these; the sim
// reads them via SimRegistry.defFor(type). No shared-file edits — art keys reuse
// the frozen [PlaceableArtKey] names 1:1 (knappingStation -> slab silhouette,
// toolRack -> rack silhouette).

import '../../art/art_keys.dart';
import '../../contracts/placeable_def.dart';
import '../../core/enums.dart';
import '../../data/models/resource_cost.dart';
import 'model/tool.dart';
import 'tools_behavior.dart';

/// Builds the two tools [PlaceableDef]s. A single [ToolsBehavior] instance is
/// shared across them (it is const + stateless).
class ToolsPlaceableDefs {
  const ToolsPlaceableDefs._();

  static const ToolsBehavior _behavior = ToolsBehavior();

  /// Tool workstations sit on open, workable ground (stone is best, but grass +
  /// high ground also work). Not water/forest.
  static const List<TerrainType> _toolTerrain = <TerrainType>[
    TerrainType.grass,
    TerrainType.rocky,
    TerrainType.highGround,
  ];

  /// All tools defs, in build-menu order (the station first — it's the maker).
  static List<PlaceableDef> all() => <PlaceableDef>[
        knappingStation(),
        toolRack(),
      ];

  static PlaceableDef knappingStation() => PlaceableDef(
        kind: PlaceableType.knappingStation,
        displayName: 'Knapping Station',
        artKey: PlaceableArtKey.knappingStation.name,
        // A slab + hammerstone — cheap stone work surface.
        cost: ResourceCost(<ResourceType, int>{
          ResourceType.stone: 5,
          ResourceType.wood: 2,
        }),
        buildDurationMs: 1600,
        allowedTerrain: _toolTerrain,
        // Tier 1 flake station -> 2 hand-axe bench -> 3 fine-blade bench. Higher
        // tiers are gated on Fire (heat-treatment) in the activity/upgrade copy.
        tierChain: <int>[1, 2, 3],
        behavior: _behavior,
        // Seed the all-purpose hand axe so a station gives a felt multiplier.
        initialPayload: const Tool(type: ToolType.handAxe, tier: 1).toExt(),
      );

  static PlaceableDef toolRack() => PlaceableDef(
        kind: PlaceableType.toolRack,
        displayName: 'Tool Rack',
        artKey: PlaceableArtKey.toolRack.name,
        // An A-frame of poles + lashing — mostly wood.
        cost: ResourceCost(<ResourceType, int>{
          ResourceType.wood: 4,
          ResourceType.stone: 1,
        }),
        buildDurationMs: 1000,
        allowedTerrain: _toolTerrain,
        tierChain: <int>[1, 2],
        behavior: _behavior,
        // A rack starts holding a basic chopper (the small capacity gate is the
        // `stored` count the behavior seeds + the component reads).
        initialPayload: <String, dynamic>{
          ...const Tool(type: ToolType.chopper, tier: 1).toExt(),
          ToolExtKeys.stored: 1,
        },
      );
}
