// Ember — art/sprite_art.dart
//
// The sprite-backed EmberArt — the LIVE art layer for the world visuals. It owns
// a [SpriteCache] (decoded PNGs from assets/ember/sprites/, keyed by filename via
// the frozen [EmberSpriteSlots] catalog) and serves a [SpriteHandle] for every
// MAPPED slot. Everything else delegates to [PlaceholderEmberArt]:
//   * the TileVisual / PlaceableVisual / NodeVisual INSTRUCTIONS still come from
//     the placeholder (the components read overlays/affordances/tier off them and
//     composite the sprite ON TOP of / instead of the programmatic body),
//   * unmapped sprite slots (hide nodes, predator, FX, dust, scrims) return null
//     so the component keeps its programmatic draw — the sprite-OR-placeholder
//     seam means NO slot is ever blank,
//   * the animation actors + the generic primitive toolkit are unchanged (this
//     pass leaves activity-internal props + Spine-style frame animation alone).
//
// ACTIVATION: the cache is preloaded by the game at boot (EmberGame.onLoad ->
// preloadMapped). Until a file is decoded its sprite getter returns null and the
// world shows the placeholder for that one slot, then swaps to the sprite once the
// preload completes — never a crash, never a blank.
//
// Presentation-only (art/): no clock/randomness.

import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../animation/animated_actor.dart';
import '../core/enums.dart';
import 'art_keys.dart';
import 'ember_art.dart';
import 'ember_palette.dart';
import 'placeholder_art.dart';
import 'sprite_cache.dart';
import 'sprite_slots.dart';

/// The frozen atlas region-key convention — kept for the (separate) packed-atlas
/// seam. The live flat-pack mapping lives in [EmberSpriteSlots]; this class is
/// retained so any external authoring tooling referencing the region names keeps
/// compiling.
class SpriteAtlasManifest {
  const SpriteAtlasManifest._();

  /// Root asset folder for Ember sprite atlases.
  static const String atlasDir = 'assets/ember/atlas/';

  static String tileRegion(TileArtKey k) => 'tile_${k.name}';

  static String placeableRegion(PlaceableArtKey k, PlaceableState state,
          {int tier = 1}) =>
      'placeable_${k.name}_${state.name}_t$tier';

  static String nodeRegion(NodeArtKey k, {int step = 0}) =>
      'node_${k.name}_$step';

  static String actorRegion(ActorArtKey k, AnimState s, {int frame = 0}) =>
      'actor_${k.name}_${s.name}_$frame';
}

/// Sprite-backed [EmberArt]. Serves mapped slots from [cache]; delegates the rest
/// to [PlaceholderEmberArt].
class SpriteEmberArt implements EmberArt {
  SpriteEmberArt({
    EmberPalette palette = EmberPalette.dusk,
    SpriteCache? cache,
  })  : _palette = palette,
        cache = cache ?? SpriteCache(),
        _fallback = PlaceholderEmberArt(palette: palette);

  final EmberPalette _palette;
  final PlaceholderEmberArt _fallback;

  /// The decoded-image cache (preloaded by the game at boot).
  final SpriteCache cache;

  /// True once at least one mapped sprite is decoded.
  bool get isLoaded => cache.isLoaded;

  @override
  EmberPalette get palette => _palette;

  // ---- Visual instructions: delegate (components still read overlays etc.) --

  @override
  TileVisual tile(TerrainType t,
          {bool buildable = true, bool floodRisk = false}) =>
      _fallback.tile(t, buildable: buildable, floodRisk: floodRisk);

  @override
  PlaceableVisual placeable(
    PlaceableType type, {
    required PlaceableState state,
    int tier = 1,
  }) =>
      _fallback.placeable(type, state: state, tier: tier);

  @override
  NodeVisual node(ResourceType t, {double remaining = 1.0}) =>
      _fallback.node(t, remaining: remaining);

  // ---- Actors + toolkit: unchanged this pass --------------------------------

  @override
  AnimatedActor actor(ActorKind kind) => _fallback.actor(kind);

  @override
  AnimatedActor playerActor({bool reduceMotion = false}) =>
      _fallback.playerActor(reduceMotion: reduceMotion);

  @override
  PositionComponent panel(PanelSpec spec) => _fallback.panel(spec);

  @override
  PositionComponent chip(ChipSpec spec) => _fallback.chip(spec);

  @override
  PositionComponent icon(IconGlyph glyph, {double size = 24.0, Color? color}) =>
      _fallback.icon(glyph, size: size, color: color);

  @override
  PositionComponent shape(
    PrimitiveShape shape, {
    required Vector2 size,
    Color? fill,
    Color? outline,
  }) =>
      _fallback.shape(shape, size: size, fill: fill, outline: outline);

  @override
  Paint verticalGradient(Color from, Color to, double extent) =>
      _fallback.verticalGradient(from, to, extent);

  // ===========================================================================
  // Sprite seam — resolve mapped slots from the cache. Returns null when the slot
  // is unmapped OR not yet decoded, so the component keeps its programmatic draw.
  // ===========================================================================

  SpriteHandle? _handle(SpriteSlotSpec? spec) {
    if (spec == null) return null;
    final ui.Image? img = cache.image(spec.file);
    if (img == null) return null;
    return SpriteHandle(
      image: img,
      anchor: spec.anchor,
      widthTiles: spec.widthTiles,
    );
  }

  @override
  SpriteHandle? tileSprite(TerrainType t) =>
      _handle(EmberSpriteSlots.tile(ArtKeys.tile(t)));

  @override
  SpriteHandle? placeableSprite(PlaceableType type,
          {required PlaceableState state, int tier = 1}) =>
      _handle(EmberSpriteSlots.placeable(ArtKeys.placeable(type), state));

  @override
  SpriteHandle? nodeSprite(ResourceType t, {double remaining = 1.0}) {
    // step 0 = full, step 1 = depleted (wood -> stump). The art instruction's
    // depletion read is here too so the renderer stays dumb.
    final int step = remaining <= 0.001 ? 1 : 0;
    return _handle(EmberSpriteSlots.node(ArtKeys.node(t), step: step));
  }

  @override
  SpriteHandle? actorSprite(ActorKind kind, {int varietyKey = 0}) {
    // Tribe members rotate through the spare variety cutouts for crowd variety;
    // elder uses its confirmed sprite; predator/flame stay programmatic.
    if (kind == ActorKind.tribe) {
      final List<String> pool = EmberSpriteSlots.tribeVariety;
      final String file = pool[varietyKey.abs() % pool.length];
      final ui.Image? img = cache.image(file);
      if (img == null) return null;
      return SpriteHandle(
        image: img,
        anchor: SpriteAnchorKind.bottomCenter,
        widthTiles: 0.6,
      );
    }
    return _handle(EmberSpriteSlots.actor(ArtKeys.actor(kind)));
  }

  @override
  SpriteHandle? playerSprite() => _handle(EmberSpriteSlots.player);

  @override
  SpriteHandle? validRingSprite() =>
      _handle(EmberSpriteSlots.decor(DecorArtKey.selectionRing));
}
