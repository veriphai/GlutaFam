// Ember — concepts/fire/fire_placeable_defs.dart
//
// The static catalogue entries for the fire leaf's four placeable types: the
// central Hearth, perimeter Torch + Brazier lights, and the Cooking fire. Each
// def carries its build cost, allowed terrain, tier chain, art key, seed payload
// (an initial full + lit [FireObject] baked into ext), build duration, and the
// shared [FireBehavior] the sim ticks. The registry collects these; the sim reads
// them via SimRegistry.defFor(type). No shared-file edits — art keys reuse the
// frozen [PlaceableArtKey] names 1:1.

import '../../art/art_keys.dart';
import '../../contracts/placeable_def.dart';
import '../../core/enums.dart';
import '../../data/models/resource_cost.dart';
import 'fire_behavior.dart';
import 'model/fire_object.dart';

/// Builds the four fire [PlaceableDef]s. A single [FireBehavior] instance is
/// shared across them (it is const + stateless).
class FirePlaceableDefs {
  const FirePlaceableDefs._();

  static const FireBehavior _behavior = FireBehavior();

  /// Fires can sit on the open, walkable ground families (not water/forest).
  static const List<TerrainType> _fireTerrain = <TerrainType>[
    TerrainType.grass,
    TerrainType.rocky,
    TerrainType.highGround,
  ];

  /// The seed ext payload for a fire of [type] — a full, lit fire with NO baked
  /// light source yet (the behavior bakes the source on build/tick). Stored under
  /// the leaf's stable ext keys so [FireObject.fromPlaceable] reads it straight.
  static Map<String, dynamic> _payload(FireType type) =>
      FireObject.initial(type).toExt();

  /// All fire defs, in build-menu order (hearth first — it's the keystone).
  static List<PlaceableDef> all() => <PlaceableDef>[
        hearth(),
        torch(),
        brazier(),
        cookingFire(),
      ];

  static PlaceableDef hearth() => PlaceableDef(
        kind: PlaceableType.hearth,
        displayName: 'Hearth',
        artKey: PlaceableArtKey.hearth.name,
        // The first fire is cheap — it's the camp's heart.
        cost: ResourceCost(<ResourceType, int>{ResourceType.wood: 6}),
        buildDurationMs: 1500,
        allowedTerrain: _fireTerrain,
        // Tier 2 = stone-ringed (cross-linked to Stone Tools later); tier 3 = big.
        tierChain: <int>[1, 2, 3],
        behavior: _behavior,
        initialPayload: _payload(FireType.hearth),
      );

  static PlaceableDef torch() => PlaceableDef(
        kind: PlaceableType.torch,
        displayName: 'Torch',
        artKey: PlaceableArtKey.torch.name,
        cost: ResourceCost(<ResourceType, int>{ResourceType.wood: 3}),
        buildDurationMs: 800,
        allowedTerrain: _fireTerrain,
        tierChain: <int>[1, 2],
        behavior: _behavior,
        initialPayload: _payload(FireType.torch),
      );

  static PlaceableDef brazier() => PlaceableDef(
        kind: PlaceableType.brazier,
        displayName: 'Brazier',
        artKey: PlaceableArtKey.brazier.name,
        cost: ResourceCost(<ResourceType, int>{
          ResourceType.wood: 4,
          ResourceType.stone: 2,
        }),
        buildDurationMs: 1200,
        allowedTerrain: _fireTerrain,
        tierChain: <int>[1, 2],
        behavior: _behavior,
        initialPayload: _payload(FireType.brazier),
      );

  static PlaceableDef cookingFire() => PlaceableDef(
        kind: PlaceableType.cookingFire,
        displayName: 'Cooking Fire',
        artKey: PlaceableArtKey.cookingFire.name,
        cost: ResourceCost(<ResourceType, int>{ResourceType.wood: 4}),
        buildDurationMs: 1000,
        allowedTerrain: _fireTerrain,
        tierChain: <int>[1, 2],
        behavior: _behavior,
        initialPayload: _payload(FireType.cookingFire),
      );
}
