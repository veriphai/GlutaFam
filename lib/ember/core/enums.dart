// Ember — core/enums.dart
//
// ALL closed sets for the whole module live here and are enumerated UP FRONT so
// no concept leaf ever has to edit a shared enum mid parallel-build. Every enum
// is serialized by its `.name`; `*FromName` helpers parse back defensively.

/// The three shippable concepts (the leaves). Frozen.
enum ConceptId { fire, stoneTools, shelter }

/// Gatherable / spendable resources.
enum ResourceType { wood, stone, food, hide }

/// Terrain classes for the tile grid. `buildable`/`baseFloodRisk` are DERIVED
/// from the type in `data/models/terrain_type.dart` (not stored per tile by
/// default — a tile may override via its own fields).
enum TerrainType { grass, water, forest, rocky, highGround }

/// Everything a player can drop on the grid, across all three leaves. Frozen so
/// leaves never touch this enum.
enum PlaceableType {
  // fire leaf
  hearth,
  torch,
  brazier,
  cookingFire,
  // stone tools leaf
  knappingStation,
  toolRack,
  // shelter leaf
  leanTo,
  hideTent,
  hut,
  palisade,
}

/// Lifecycle of a placeable instance.
enum PlaceableState { ghost, building, built, damaged, removed }

/// Who an NPC is.
enum NpcRole { elder, tribe, visitor }

/// How an NPC currently feels (drives dialogue + ambient anim).
enum NpcMood { content, uneasy, cold, happy }

/// World events the sim can schedule + (via leaves) resolve. `hunt` is the tools
/// leaf's stylized spear hunt (its own slot, distinct from `nightPredator` so the
/// hunt resolver never collides with fire's predator resolver).
enum WorldEventType { nightPredator, flood, storm, coldNight, hunt }

/// On-screen actor archetypes the art/animation facade can render.
enum ActorKind { elder, tribe, predator, flame }

/// Animation states an [ActorKind] can play.
enum AnimState { idle, walk, work, celebrate, fail }

/// The fixed 5-beat arc every activity walks through.
enum ActivityBeat { setup, interact, discover, itClicks, apply }

/// Coarse season knob (affects cold/flood weighting). Kept minimal & closed.
enum Season { warm, cold, wet }

// ---------------------------------------------------------------------------
// Defensive `.name` <-> enum parsing. Used by every fromJson so a stray/legacy
// string degrades gracefully instead of throwing.
// ---------------------------------------------------------------------------

T _byName<T extends Enum>(List<T> values, Object? name, T fallback) {
  if (name is! String) return fallback;
  for (final T v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

ConceptId conceptIdFromName(Object? n, {ConceptId fallback = ConceptId.fire}) =>
    _byName(ConceptId.values, n, fallback);

ResourceType resourceTypeFromName(Object? n,
        {ResourceType fallback = ResourceType.wood}) =>
    _byName(ResourceType.values, n, fallback);

TerrainType terrainTypeFromName(Object? n,
        {TerrainType fallback = TerrainType.grass}) =>
    _byName(TerrainType.values, n, fallback);

PlaceableType placeableTypeFromName(Object? n,
        {PlaceableType fallback = PlaceableType.hearth}) =>
    _byName(PlaceableType.values, n, fallback);

PlaceableState placeableStateFromName(Object? n,
        {PlaceableState fallback = PlaceableState.ghost}) =>
    _byName(PlaceableState.values, n, fallback);

NpcRole npcRoleFromName(Object? n, {NpcRole fallback = NpcRole.tribe}) =>
    _byName(NpcRole.values, n, fallback);

NpcMood npcMoodFromName(Object? n, {NpcMood fallback = NpcMood.content}) =>
    _byName(NpcMood.values, n, fallback);

WorldEventType worldEventTypeFromName(Object? n,
        {WorldEventType fallback = WorldEventType.nightPredator}) =>
    _byName(WorldEventType.values, n, fallback);

ActorKind actorKindFromName(Object? n, {ActorKind fallback = ActorKind.tribe}) =>
    _byName(ActorKind.values, n, fallback);

AnimState animStateFromName(Object? n, {AnimState fallback = AnimState.idle}) =>
    _byName(AnimState.values, n, fallback);

ActivityBeat activityBeatFromName(Object? n,
        {ActivityBeat fallback = ActivityBeat.setup}) =>
    _byName(ActivityBeat.values, n, fallback);

Season seasonFromName(Object? n, {Season fallback = Season.warm}) =>
    _byName(Season.values, n, fallback);
