// Ember — concepts/shelter/shelter_placeable_defs.dart
//
// The static catalogue entries for the shelter leaf's four placeable types: the
// quick Lean-to, the portable Hide tent, the sturdy Hut (wood + thatch), and the
// Palisade defense wall. Each def carries its build cost, allowed terrain, tier
// chain, art key, seed payload (an initial [Dwelling] baked into ext — including
// the FROZEN capacity key the PopulationSystem reads), build duration, and the
// shared [DwellingBehavior] the sim ticks. The registry collects these; the sim
// reads them via SimRegistry.defFor(type). No shared-file edits — art keys reuse
// the frozen [PlaceableArtKey] names 1:1.
//
// Tradeoff encoded in COST + payload (the §3 learning objective): the hide tent
// is cheap + fast but cold/low (capacity/comfort/durability), while the hut is
// warm + sturdy + roomy but needs TOOLS (a stone-tools cross-link) + more wood
// and takes far longer to raise.

import '../../art/art_keys.dart';
import '../../contracts/placeable_def.dart';
import '../../core/enums.dart';
import '../../data/models/resource_cost.dart';
import 'dwelling_behavior.dart';
import 'model/dwelling.dart';

/// Builds the four shelter [PlaceableDef]s. A single [DwellingBehavior] instance
/// is shared across them (it is const + stateless).
class ShelterPlaceableDefs {
  const ShelterPlaceableDefs._();

  static const DwellingBehavior _behavior = DwellingBehavior();

  /// Dwellings go on dry, walkable ground. Crucially they MAY be built on a
  /// flood-risk grass tile (the riverbank) — that bad-site choice is the SITE
  /// lesson; the world tolerates it and the flood bites it. They are NOT allowed
  /// on water itself.
  static const List<TerrainType> _dryGround = <TerrainType>[
    TerrainType.grass,
    TerrainType.rocky,
    TerrainType.highGround,
  ];

  /// The seed ext payload for a fresh shelter of [type] — a full-health dwelling
  /// with capacity published under the foundation-frozen key.
  static Map<String, dynamic> _payload(DwellingType type) =>
      Dwelling.initial(type).toExt();

  /// All shelter defs, in build-menu order (lean-to first — the starter roof).
  static List<PlaceableDef> all() => <PlaceableDef>[
        leanTo(),
        hideTent(),
        hut(),
        palisade(),
      ];

  static PlaceableDef leanTo() => PlaceableDef(
        kind: PlaceableType.leanTo,
        displayName: 'Lean-to',
        artKey: PlaceableArtKey.leanTo.name,
        // Cheap + fast: a few branches leaned against a frame.
        cost: ResourceCost(<ResourceType, int>{ResourceType.wood: 4}),
        buildDurationMs: 1200,
        allowedTerrain: _dryGround,
        tierChain: <int>[1, 2],
        behavior: _behavior,
        initialPayload: _payload(DwellingType.leanTo),
      );

  static PlaceableDef hideTent() => PlaceableDef(
        kind: PlaceableType.hideTent,
        displayName: 'Hide Tent',
        artKey: PlaceableArtKey.hideTent.name,
        // Hides over a light frame — portable, quick, costs wood + hide.
        cost: ResourceCost(<ResourceType, int>{
          ResourceType.wood: 5,
          ResourceType.hide: 4,
        }),
        buildDurationMs: 1800,
        allowedTerrain: _dryGround,
        tierChain: <int>[1, 2],
        behavior: _behavior,
        initialPayload: _payload(DwellingType.hideTent),
      );

  static PlaceableDef hut() => PlaceableDef(
        kind: PlaceableType.hut,
        displayName: 'Hut',
        artKey: PlaceableArtKey.hut.name,
        // The costly, sturdy build: lots of wood + hide + STONE (needs tools to
        // cut/shape) and the longest raise. The tradeoff against the tent.
        cost: ResourceCost(<ResourceType, int>{
          ResourceType.wood: 12,
          ResourceType.hide: 6,
          ResourceType.stone: 4,
        }),
        buildDurationMs: 4000,
        allowedTerrain: _dryGround,
        // Tier 2 = bone-and-hide reinforcement (the Ice-Age showcase, deferred
        // depth); tier 3 = stilted/raised (a flood countermeasure).
        tierChain: <int>[1, 2, 3],
        behavior: _behavior,
        initialPayload: _payload(DwellingType.hut),
      );

  static PlaceableDef palisade() => PlaceableDef(
        kind: PlaceableType.palisade,
        displayName: 'Palisade',
        artKey: PlaceableArtKey.palisade.name,
        // A thorn/timber wall section — wood + a little stone to anchor posts.
        cost: ResourceCost(<ResourceType, int>{
          ResourceType.wood: 6,
          ResourceType.stone: 2,
        }),
        buildDurationMs: 1500,
        allowedTerrain: _dryGround,
        tierChain: <int>[1, 2],
        behavior: _behavior,
        initialPayload: _payload(DwellingType.palisade),
      );
}
