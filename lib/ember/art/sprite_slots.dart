// Ember — art/sprite_slots.dart
//
// The FROZEN slot->filename catalog for the real sprite pack. This is the single
// source of truth that maps every semantic art SLOT the world renders to a flat
// PNG under assets/ember/sprites/. SpriteEmberArt reads this; PlaceholderEmberArt
// ignores it (it has no sprites). Unmapped slots return null -> the component
// keeps its programmatic placeholder draw (the sprite-OR-placeholder seam).
//
// Naming mirrors the prep pack's category-prefixed flat names exactly, so the
// catalog is a 1:1 lookup with no path munging at call sites. The descriptive
// guidance (anchor/scale per category) is encoded as data on [SpriteSlotSpec] so
// the renderers stay dumb (they just read kind + scale off the spec).
//
// Presentation-only (art/): no clock/randomness; pure const data.

import '../core/enums.dart';
import 'art_keys.dart';

/// Root asset folder for the flattened sprite pack.
const String kEmberSpriteDir = 'assets/ember/sprites/';

/// How a sprite anchors onto the iso scene, which drives the compositing math in
/// the component renderers.
enum SpriteAnchorKind {
  /// Fills the iso diamond ground face exactly (tile_* terrain). Anchored at the
  /// diamond center; drawn at tileWidth x tileHeight.
  diamond,

  /// A bottom-center cutout standing on the tile (placeables, nodes, actors,
  /// the fire props). Width tuned by [SpriteSlotSpec.widthTiles]; height
  /// preserves the source aspect ratio.
  bottomCenter,
}

/// A frozen sprite slot: its PNG filename plus the render hints the components
/// need (anchor kind + target width in tile-widths). Height is derived from the
/// source image aspect ratio at draw time so nothing gets squashed.
class SpriteSlotSpec {
  const SpriteSlotSpec(this.file, this.anchor, {this.widthTiles = 1.0});

  /// Bare filename under [kEmberSpriteDir] (no path).
  final String file;

  /// How this sprite anchors/scales onto the scene.
  final SpriteAnchorKind anchor;

  /// Target on-screen width as a multiple of the tile width (bottomCenter only;
  /// diamond sprites always draw at exactly one tile face).
  final double widthTiles;

  /// The full asset path (folder + file) for the Flame loader / rootBundle.
  String get assetPath => '$kEmberSpriteDir$file';
}

/// The frozen catalog. Every method returns the slot's spec, or null if the slot
/// is intentionally left programmatic (no good sprite in the pack — see notes).
class EmberSpriteSlots {
  const EmberSpriteSlots._();

  // ---- Terrain (diamond ground faces) -----------------------------------
  static SpriteSlotSpec? tile(TileArtKey k) => switch (k) {
        TileArtKey.grass => const SpriteSlotSpec(
            'tile_isometric_grassy_terrain_game_tile.png',
            SpriteAnchorKind.diamond),
        TileArtKey.water => const SpriteSlotSpec(
            'tile_shallow_water_on_grassy_shoreline.png',
            SpriteAnchorKind.diamond),
        TileArtKey.forest => const SpriteSlotSpec(
            'tile_leafy_terrain_tile_with_berries.png',
            SpriteAnchorKind.diamond),
        TileArtKey.rocky => const SpriteSlotSpec(
            'tile_floating_water_and_stone_tile.png',
            SpriteAnchorKind.diamond),
        TileArtKey.highGround => const SpriteSlotSpec(
            'tile_grassy_floating_plateau_tile.png',
            SpriteAnchorKind.diamond),
      };

  // ---- Placeables (bottom-center cutouts on a baked grass base) ----------
  // State variants: built = primary; damaged = ruined/debris where one exists;
  // building = under-construction where one exists. ghost/removed are handled by
  // the component (opacity), reusing the built sprite.
  static SpriteSlotSpec? placeable(PlaceableArtKey k, PlaceableState state) {
    switch (k) {
      case PlaceableArtKey.hut:
        switch (state) {
          case PlaceableState.damaged:
            return const SpriteSlotSpec(
                'bld_ruined_primitive_hut_on_grassy_patch.png',
                SpriteAnchorKind.bottomCenter,
                widthTiles: 1.25);
          case PlaceableState.building:
            return const SpriteSlotSpec(
                'bld_primitive_tent_under_construction.png',
                SpriteAnchorKind.bottomCenter,
                widthTiles: 1.2);
          case PlaceableState.ghost:
          case PlaceableState.built:
          case PlaceableState.removed:
            return const SpriteSlotSpec(
                'bld_primitive_hut_on_grassy_terrain.png',
                SpriteAnchorKind.bottomCenter,
                widthTiles: 1.25);
        }
      case PlaceableArtKey.leanTo:
        return const SpriteSlotSpec(
            'bld_primitive_campsite_with_lean_to_shelter.png',
            SpriteAnchorKind.bottomCenter,
            widthTiles: 1.15);
      case PlaceableArtKey.hideTent:
        return const SpriteSlotSpec(
            'bld_rustic_camp_tent_on_grassy_patch.png',
            SpriteAnchorKind.bottomCenter,
            widthTiles: 1.15);
      case PlaceableArtKey.palisade:
        if (state == PlaceableState.damaged) {
          return const SpriteSlotSpec(
              'bld_damaged_wooden_palisade_with_debris.png',
              SpriteAnchorKind.bottomCenter,
              widthTiles: 1.15);
        }
        return const SpriteSlotSpec(
            'bld_game_asset_wooden_palisade_gate.png',
            SpriteAnchorKind.bottomCenter,
            widthTiles: 1.15);
      case PlaceableArtKey.knappingStation:
        return const SpriteSlotSpec(
            'craft_primitive_stone_working_station_diorama.png',
            SpriteAnchorKind.bottomCenter,
            widthTiles: 1.1);
      case PlaceableArtKey.toolRack:
        return const SpriteSlotSpec(
            'craft_primitive_tools_and_weapons_rack.png',
            SpriteAnchorKind.bottomCenter,
            widthTiles: 1.0);
      case PlaceableArtKey.hearth:
        // The camp's HEART — scaled up ~20% (0.95 -> 1.15) so the hearth reads as
        // a clear hero at night and is not visually lost among a dense tribe
        // cluster (runner finding: hearth prominence).
        return const SpriteSlotSpec(
            'fx_stone_fire_pit_with_wooden_logs.png',
            SpriteAnchorKind.bottomCenter,
            widthTiles: 1.15);
      case PlaceableArtKey.torch:
        return const SpriteSlotSpec(
            'fx_flaming_torch_with_wooden_staff.png',
            SpriteAnchorKind.bottomCenter,
            widthTiles: 0.45);
      case PlaceableArtKey.brazier:
        return const SpriteSlotSpec(
            'fx_stylized_fire_brazier_with_glowing_embers.png',
            SpriteAnchorKind.bottomCenter,
            widthTiles: 0.85);
      case PlaceableArtKey.cookingFire:
        // Also a camp-heart fire — scaled up ~18% (0.95 -> 1.12) to match the
        // hearth's increased prominence at the village centre.
        return const SpriteSlotSpec(
            'fx_campfire_cooking_setup_in_stone_pit.png',
            SpriteAnchorKind.bottomCenter,
            widthTiles: 1.12);
    }
  }

  // ---- Resource nodes ----------------------------------------------------
  // [step] selects depletion frames: wood step>0 -> stump. hide has NO node
  // sprite (only inventory icons) -> programmatic; gameAnimal has none -> prog.
  static SpriteSlotSpec? node(NodeArtKey k, {int step = 0}) {
    switch (k) {
      case NodeArtKey.woodNode:
        if (step > 0) {
          return const SpriteSlotSpec(
              'prop_tree_stump_on_patch_of_grass.png',
              SpriteAnchorKind.bottomCenter,
              widthTiles: 0.9);
        }
        return const SpriteSlotSpec(
            'prop_isometric_stylized_fantasy_tree_asset.png',
            SpriteAnchorKind.bottomCenter,
            widthTiles: 1.0);
      case NodeArtKey.stoneNode:
        return const SpriteSlotSpec(
            'prop_rocky_outcrop_with_grassy_base.png',
            SpriteAnchorKind.bottomCenter,
            widthTiles: 0.95);
      case NodeArtKey.foodNode:
        return const SpriteSlotSpec(
            'prop_lush_berry_bush_on_grass_tile.png',
            SpriteAnchorKind.bottomCenter,
            widthTiles: 0.9);
      case NodeArtKey.hideNode:
        // No hide-resource world node sprite in the pack -> programmatic.
        return null;
    }
  }

  // ---- Actors (NPC archetypes) ------------------------------------------
  // predator/flame are NOT humanoid sprites: predator has no beast sprite (keep
  // programmatic); flame is an FX leaf, not driven through actor().
  static SpriteSlotSpec? actor(ActorArtKey k) {
    switch (k) {
      case ActorArtKey.elder:
        return const SpriteSlotSpec(
            'char_elder_tribal_sage_with_staff.png',
            SpriteAnchorKind.bottomCenter,
            widthTiles: 0.62);
      case ActorArtKey.tribe:
        return const SpriteSlotSpec(
            'char_confident_caveman_villager_in_motion.png',
            SpriteAnchorKind.bottomCenter,
            widthTiles: 0.6);
      case ActorArtKey.predator:
        return null; // no beast sprite — programmatic menacing silhouette.
      case ActorArtKey.flame:
        return null; // FX leaf, handled by fire props, not actor().
    }
  }

  /// Spare tribe-member cutouts, rotated per-NPC by a stable index for crowd
  /// variety (the confirmed tribe sprite is index 0). Same bottom-center anchor.
  static const List<String> tribeVariety = <String>[
    'char_confident_caveman_villager_in_motion.png',
    'char_primitive_villager_walking_in_dynamic_stride.png',
    'char_prehistoric_adventurer_in_motion.png',
    'char_adventurer_in_tribal_attire.png',
    'char_optimistic_caveman_in_stride.png',
    'char_stone_age_adventurer_in_mid_stride.png',
    'char_friendly_caveman_character_in_3d_style.png',
    'char_prehistoric_adventurer_in_rugged_attire.png',
  ];

  /// The PLAYER hero cutout (driven by PlayerComponent, not actor()).
  static const SpriteSlotSpec player = SpriteSlotSpec(
      'char_caveman_character_walking_in_game_style.png',
      SpriteAnchorKind.bottomCenter,
      widthTiles: 0.66);

  // ---- Decor / placement validity ring ----------------------------------
  static SpriteSlotSpec? decor(DecorArtKey k) {
    switch (k) {
      case DecorArtKey.selectionRing:
        // The placement-validity diamond outline — anchored on the iso face.
        return const SpriteSlotSpec(
            'weather_glowing_isometric_diamond_shape_outline.png',
            SpriteAnchorKind.diamond);
      case DecorArtKey.floodSheet:
      case DecorArtKey.buildableHighlight:
      case DecorArtKey.blockedHighlight:
      case DecorArtKey.nightScrim:
        return null; // procedural washes / red-tinted ring — programmatic.
    }
  }

  /// Every distinct file the mapped slots reference — the preload manifest, so
  /// the first paint is never blank. Built once; order is irrelevant.
  static List<String> get preloadFiles {
    final Set<String> files = <String>{};
    for (final TileArtKey k in TileArtKey.values) {
      final SpriteSlotSpec? s = tile(k);
      if (s != null) files.add(s.file);
    }
    for (final PlaceableArtKey k in PlaceableArtKey.values) {
      for (final PlaceableState st in PlaceableState.values) {
        final SpriteSlotSpec? s = placeable(k, st);
        if (s != null) files.add(s.file);
      }
    }
    for (final NodeArtKey k in NodeArtKey.values) {
      for (final int step in <int>[0, 1]) {
        final SpriteSlotSpec? s = node(k, step: step);
        if (s != null) files.add(s.file);
      }
    }
    for (final ActorArtKey k in ActorArtKey.values) {
      final SpriteSlotSpec? s = actor(k);
      if (s != null) files.add(s.file);
    }
    files.addAll(tribeVariety);
    files.add(player.file);
    for (final DecorArtKey k in DecorArtKey.values) {
      final SpriteSlotSpec? s = decor(k);
      if (s != null) files.add(s.file);
    }
    return files.toList(growable: false);
  }
}
