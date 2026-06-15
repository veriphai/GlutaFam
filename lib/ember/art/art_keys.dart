// Ember — art/art_keys.dart
//
// The CLOSED set of semantic art keys for the whole world. Every tile, placeable,
// node, actor, and particle the world + leaves render is named here — no magic
// strings anywhere in the render path. A sprite atlas (sprite_art.dart) maps each
// of these to a region; the placeholder impl maps each to a procedural drawing.
//
// IMPORTANT (dir-lock): leaves do NOT add keys here. Bespoke interactive props in
// activity scenes use the generic placeholder-primitive toolkit on EmberArt
// instead (rounded panels / chips / icons / shapes), so a leaf never needs a new
// closed art key mid parallel-build.
//
// These enums are deliberately PARALLEL to the core enums (TerrainType,
// PlaceableType, ...) so the art facade can key off the world model directly;
// helper maps below translate model enum -> art key 1:1.

import '../core/enums.dart';

/// Tile art keys — one per [TerrainType].
enum TileArtKey { grass, water, forest, rocky, highGround }

/// Placeable art keys — one per [PlaceableType] across all three leaves.
enum PlaceableArtKey {
  hearth,
  torch,
  brazier,
  cookingFire,
  knappingStation,
  toolRack,
  leanTo,
  hideTent,
  hut,
  palisade,
}

/// Resource-node art keys — one per gatherable [ResourceType].
enum NodeArtKey { woodNode, stoneNode, foodNode, hideNode }

/// Actor art keys — one per [ActorKind].
enum ActorArtKey { elder, tribe, predator, flame }

/// Particle / FX art keys (semantic, not per-emitter). The world + activities
/// request these; the particle factory (ember_particles.dart) builds them.
enum ParticleArtKey {
  /// Slow rising warm motes above a fire.
  ember,

  /// Fast bright pops (ignite, success burst).
  spark,

  /// Stone flakes flying off a knapping strike.
  chip,

  /// Falling rain streaks (storm / wet).
  rain,

  /// Upward water splash (flood / river edge).
  splash,

  /// Soft dust puff (build complete, footfalls).
  dust,

  /// Drifting smoke wisp above an extinguished/low fire.
  smoke,
}

/// Decorative / structural world keys that are not placeables, nodes, or actors
/// (used by the renderer + flood overlay). Closed so overlays stay key-driven.
enum DecorArtKey {
  /// The stylized flood water sheet overlay.
  floodSheet,

  /// A generic selection / ghost-placement ring.
  selectionRing,

  /// A buildable-tile highlight overlay.
  buildableHighlight,

  /// A blocked / invalid placement overlay.
  blockedHighlight,

  /// The night vignette / darkness scrim.
  nightScrim,
}

/// 1:1 translation tables from core model enums to art keys, so the renderer
/// never hand-maps with a `switch` at the call site.
class ArtKeys {
  const ArtKeys._();

  static TileArtKey tile(TerrainType t) => switch (t) {
        TerrainType.grass => TileArtKey.grass,
        TerrainType.water => TileArtKey.water,
        TerrainType.forest => TileArtKey.forest,
        TerrainType.rocky => TileArtKey.rocky,
        TerrainType.highGround => TileArtKey.highGround,
      };

  static PlaceableArtKey placeable(PlaceableType t) => switch (t) {
        PlaceableType.hearth => PlaceableArtKey.hearth,
        PlaceableType.torch => PlaceableArtKey.torch,
        PlaceableType.brazier => PlaceableArtKey.brazier,
        PlaceableType.cookingFire => PlaceableArtKey.cookingFire,
        PlaceableType.knappingStation => PlaceableArtKey.knappingStation,
        PlaceableType.toolRack => PlaceableArtKey.toolRack,
        PlaceableType.leanTo => PlaceableArtKey.leanTo,
        PlaceableType.hideTent => PlaceableArtKey.hideTent,
        PlaceableType.hut => PlaceableArtKey.hut,
        PlaceableType.palisade => PlaceableArtKey.palisade,
      };

  static NodeArtKey node(ResourceType t) => switch (t) {
        ResourceType.wood => NodeArtKey.woodNode,
        ResourceType.stone => NodeArtKey.stoneNode,
        ResourceType.food => NodeArtKey.foodNode,
        ResourceType.hide => NodeArtKey.hideNode,
      };

  static ActorArtKey actor(ActorKind k) => switch (k) {
        ActorKind.elder => ActorArtKey.elder,
        ActorKind.tribe => ActorArtKey.tribe,
        ActorKind.predator => ActorArtKey.predator,
        ActorKind.flame => ActorArtKey.flame,
      };
}
