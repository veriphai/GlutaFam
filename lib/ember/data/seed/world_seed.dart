// Ember — data/seed/world_seed.dart
//
// DETERMINISTIC starting world. Given a seed it always builds the same believable
// 16x16 map: a river column down the middle with adjacent flood-risk grass, a
// forest patch (wood nodes), rocky ground (stone nodes), berry bushes (food),
// some high ground, and the Elder NPC near center plus a few tribe members.
//
// PURE: the only randomness comes from the EmberRng it constructs from `seed`,
// and node ids are coordinate-anchored (stable) so the layout never drifts. No
// DateTime/Random/Stopwatch.

import '../../core/constants.dart';
import '../../core/ember_rng.dart';
import '../../core/enums.dart';
import '../../core/geometry.dart';
import '../../core/ids.dart';
import '../models/activity_progress.dart';
import '../models/concept.dart';
import '../models/day_night_state.dart';
import '../models/era_state.dart';
import '../models/npc.dart';
import '../models/placeable.dart';
import '../models/player_knowledge.dart';
import '../models/resource_node.dart';
import '../models/resource_stock.dart';
import '../models/tile.dart';
import '../models/tile_grid.dart';
import '../models/village.dart';
import '../models/world_event.dart';
import '../models/world_state.dart';
import 'concept_seed.dart';

class WorldSeed {
  const WorldSeed._();

  /// Default seed for a fresh game (stable so QA sees the same map).
  static const int defaultSeed = 0xE3B11; // "EMBER"-ish

  /// The river runs down this column; the column just east of it is flood-risk.
  static const int _riverX = 6;

  /// Builds a brand-new world from [seed].
  static EmberWorldState newGame({int seed = defaultSeed}) {
    final EmberRng rng = EmberRng.seed(seed);

    final TileGrid tiles = _buildGrid();
    final List<ResourceNode> nodes = _buildNodes(tiles);
    final GridCoord site = const GridCoord(8, 8);
    final List<Npc> npcs = _buildNpcs(site);

    final Village village = Village(
      id: 'village-home',
      eraId: 'stone_age',
      populationCap: EmberConstants.basePopulationCap,
      populationCurrent: npcs.length,
      comfortIndex: 0.4,
      unlockedRegions: tiles.unlockedRegions.toList()..sort(),
      siteTile: site,
    );

    final List<Concept> concepts = ConceptSeed.initialConcepts();
    final List<ActivityProgress> progress = <ActivityProgress>[
      for (final ActivityProgressSeed s in ConceptSeed.progressIds)
        ActivityProgress(conceptId: s.conceptId),
    ];

    final ResourceStock stock = ResourceStock.initial(
      cap: EmberConstants.defaultResourceCap,
      threshold: EmberConstants.defaultResourceThreshold,
      overrides: <ResourceType, int>{
        // A small starting cushion so the first fire/tools are reachable.
        ResourceType.wood: 20,
        ResourceType.stone: 10,
        ResourceType.food: 15,
        ResourceType.hide: 0,
      },
    );

    return EmberWorldState(
      village: village,
      tiles: tiles,
      placeables: <Placeable>[],
      nodes: nodes,
      stock: stock,
      npcs: npcs,
      concepts: concepts,
      activityProgress: progress,
      era: EraState(),
      events: <WorldEvent>[],
      knowledge: PlayerKnowledge(),
      dayNight: const DayNightState(),
      rng: rng,
      simNowMs: 0,
      lastSeenMs: 0,
    );
  }

  /// An empty, all-grass world (used by previews/tests that want a blank slate).
  static EmberWorldState empty({int seed = defaultSeed}) {
    final TileGrid tiles = TileGrid.filled(
      EmberConstants.gridWidth,
      EmberConstants.gridHeight,
    );
    return EmberWorldState(
      village: const Village(
        id: 'village-empty',
        eraId: 'stone_age',
        populationCap: EmberConstants.basePopulationCap,
        populationCurrent: 0,
        comfortIndex: 0.0,
        unlockedRegions: <int>[0],
        siteTile: GridCoord(8, 8),
      ),
      tiles: tiles,
      placeables: <Placeable>[],
      nodes: <ResourceNode>[],
      stock: ResourceStock.initial(),
      npcs: <Npc>[],
      concepts: ConceptSeed.initialConcepts(),
      activityProgress: <ActivityProgress>[
        for (final ActivityProgressSeed s in ConceptSeed.progressIds)
          ActivityProgress(conceptId: s.conceptId),
      ],
      era: EraState(),
      events: <WorldEvent>[],
      knowledge: PlayerKnowledge(),
      dayNight: const DayNightState(),
      rng: EmberRng.seed(seed),
      simNowMs: 0,
      lastSeenMs: 0,
    );
  }

  // ---- Terrain layout ----------------------------------------------------

  static TileGrid _buildGrid() {
    final int w = EmberConstants.gridWidth;
    final int h = EmberConstants.gridHeight;
    final List<Tile> tiles = <Tile>[];

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final GridCoord c = GridCoord(x, y);
        final TerrainType terrain = _terrainAt(x, y);
        // Riverbank grass (the column immediately east + west of the river)
        // gets elevated flood risk regardless of base terrain risk.
        double? floodOverride;
        if (terrain == TerrainType.grass &&
            (x == _riverX - 1 || x == _riverX + 1)) {
          floodOverride = 0.7;
        } else if (terrain == TerrainType.grass &&
            (x == _riverX - 2 || x == _riverX + 2)) {
          floodOverride = 0.4;
        }
        tiles.add(
          Tile.fromTerrain(
            c,
            terrain,
            floodRisk: floodOverride,
            // Whole starting map is one region, fully explored.
            explored: true,
          ),
        );
      }
    }

    return TileGrid(width: w, height: h, tiles: tiles);
  }

  /// Hand-authored terrain function for the 16x16 map. Deterministic by
  /// position alone (no rng) so the silhouette is reproducible & readable:
  ///
  ///   col 6            -> river (water) running top to bottom
  ///   cols 0-3 rows<7  -> forest patch (wood)
  ///   cols 11-15 rows>9-> rocky ground (stone)
  ///   top-right corner -> high ground (flood-safe building)
  ///   everything else  -> grass (berry bushes scatter on it as nodes)
  static TerrainType _terrainAt(int x, int y) {
    // River column (with a slight kink so it's not a ruler-straight line).
    final int riverColHere = _riverX + ((y >= 8) ? 1 : 0);
    if (x == riverColHere) return TerrainType.water;

    // Forest patch: north-west block.
    if (x <= 3 && y <= 6) return TerrainType.forest;

    // Rocky ground: south-east block.
    if (x >= 11 && y >= 9) return TerrainType.rocky;

    // High ground: north-east corner (flood-safe).
    if (x >= 12 && y <= 3) return TerrainType.highGround;

    return TerrainType.grass;
  }

  // ---- Resource nodes ----------------------------------------------------

  /// Places nodes on terrain that supports them. Ids are coordinate-anchored
  /// (`node-wood-3_2`) so the same map always yields the same node ids.
  static List<ResourceNode> _buildNodes(TileGrid tiles) {
    final List<ResourceNode> nodes = <ResourceNode>[];

    for (final Tile t in tiles.tiles) {
      final int x = t.coord.x;
      final int y = t.coord.y;
      switch (t.terrain) {
        case TerrainType.forest:
          // Wood trees on every other forest tile (a workable cluster).
          if ((x + y) % 2 == 0) {
            nodes.add(_node(ResourceType.wood, t.coord, remaining: 60,
                baseYield: 6));
          }
          break;
        case TerrainType.rocky:
          // Stone outcrops on a SPARSE, clustered pattern so the rocky field
          // reads as terrain with a few rock formations rather than a wall-to-
          // wall grid of identical bumps. A widened cadence (every other row,
          // staggered columns) roughly halves the node count vs the old (x+y)%3
          // field; each node now renders as a varied multi-rock cluster.
          final bool oddRow = y.isOdd;
          final bool stoneSpot = oddRow ? (x % 3 == 1) : (x % 3 == 0);
          if (stoneSpot) {
            nodes.add(_node(ResourceType.stone, t.coord, remaining: 50,
                baseYield: 5));
          }
          break;
        case TerrainType.grass:
          // Berry bushes (food) scattered on dry grass near the village.
          final bool dry = t.floodRisk < 0.3;
          final bool spot = (x % 5 == 2) && (y % 4 == 1);
          if (dry && spot) {
            nodes.add(_node(
              ResourceType.food,
              t.coord,
              remaining: 30,
              baseYield: 4,
              regrowRate: EmberConstants.foodRegrowRate,
            ));
          }
          break;
        case TerrainType.water:
        case TerrainType.highGround:
          break;
      }
    }

    return nodes;
  }

  static ResourceNode _node(
    ResourceType type,
    GridCoord coord, {
    required double remaining,
    required int baseYield,
    double regrowRate = 0.0,
  }) {
    return ResourceNode(
      id: ids.at('node-${type.name}', coord.x, coord.y),
      type: type,
      coord: coord,
      remaining: remaining,
      baseYield: baseYield,
      regrowRate: regrowRate,
      capacity: remaining,
    );
  }

  // ---- NPCs --------------------------------------------------------------

  /// The Elder near center plus a few tribe members around the village site.
  static List<Npc> _buildNpcs(GridCoord site) {
    return <Npc>[
      Npc(
        id: ids.at('npc-elder', site.x, site.y),
        role: NpcRole.elder,
        coord: site,
        mood: NpcMood.content,
        dialogueId: 'elder.intro',
        name: 'Elder',
      ),
      Npc(
        id: ids.at('npc-tribe', site.x - 1, site.y + 1),
        role: NpcRole.tribe,
        coord: GridCoord(site.x - 1, site.y + 1),
        mood: NpcMood.content,
        name: 'Tribe',
      ),
      Npc(
        id: ids.at('npc-tribe', site.x + 2, site.y),
        role: NpcRole.tribe,
        coord: GridCoord(site.x + 2, site.y),
        mood: NpcMood.uneasy,
        name: 'Tribe',
      ),
      Npc(
        id: ids.at('npc-tribe', site.x, site.y + 2),
        role: NpcRole.tribe,
        coord: GridCoord(site.x, site.y + 2),
        mood: NpcMood.content,
        name: 'Tribe',
      ),
    ];
  }
}
