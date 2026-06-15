// Ember — art/ember_art.dart
//
// The ONE facade through which all art is requested. The world + activity scenes
// never hardcode colours/shapes; they ask EmberArt for a *render instruction*
// (TileVisual / PlaceableVisual / NodeVisual) or for an [AnimatedActor], and the
// game-layer components (F3c) paint from those instructions.
//
// Plus a generic placeholder-primitive toolkit: rounded panels, chips, icon
// glyphs, gradient fills, simple shapes. Activity scenes use these for bespoke
// interactive props WITHOUT needing a new closed art key — that is what keeps the
// concept leaves dir-locked (no leaf ever edits art_keys.dart).
//
// Default impl = PlaceholderEmberArt (placeholder_art.dart). A sprite-backed impl
// (sprite_art.dart) swaps in behind the same interface via provider override.
//
// Presentation-only: depends on flame + flutter painting; NO clock/randomness in
// the *interface* (placeholder impl may jitter visuals, but that's not state).

import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../animation/animated_actor.dart';
import '../core/enums.dart';
import 'ember_palette.dart';
import 'sprite_slots.dart';

// ===========================================================================
// Visual value types — pure render INSTRUCTIONS (colours/shapes/sizes), NOT
// pre-baked widgets. F3c game components consume these and paint to a Canvas.
// ===========================================================================

/// How a single iso tile face should be drawn.
class TileVisual {
  const TileVisual({
    required this.top,
    required this.topDark,
    required this.side,
    required this.outline,
    this.depth = 0.0,
    this.overlay,
    this.pattern = TilePattern.flat,
  });

  /// Lit top-face fill (sun side).
  final Color top;

  /// Shaded top-face fill (used for a subtle top gradient).
  final Color topDark;

  /// Side-wall fill (under the top face) for raised tiles.
  final Color side;

  /// Hairline edge colour.
  final Color outline;

  /// Apparent thickness of the tile in logical px (0 = flat).
  final double depth;

  /// Optional tint overlaid on the top face (e.g. flood-risk red, lit warm).
  final Color? overlay;

  /// A coarse texture hint the renderer may stipple onto the face.
  final TilePattern pattern;

  TileVisual copyWith({
    Color? top,
    Color? topDark,
    Color? side,
    Color? outline,
    double? depth,
    Color? overlay,
    TilePattern? pattern,
  }) {
    return TileVisual(
      top: top ?? this.top,
      topDark: topDark ?? this.topDark,
      side: side ?? this.side,
      outline: outline ?? this.outline,
      depth: depth ?? this.depth,
      overlay: overlay ?? this.overlay,
      pattern: pattern ?? this.pattern,
    );
  }
}

/// Coarse texture hints for tile tops (rendered as cheap stipples/strokes).
enum TilePattern { flat, blades, ripples, pebbles, canopy }

/// How a placeable should be drawn at a given state/tier.
class PlaceableVisual {
  const PlaceableVisual({
    required this.body,
    required this.bodyDark,
    required this.accent,
    required this.outline,
    required this.silhouette,
    required this.heightFactor,
    this.opacity = 1.0,
    this.emitsLight = false,
    this.tierPips = 0,
    this.label,
  });

  /// Main lit body fill.
  final Color body;

  /// Shaded body fill.
  final Color bodyDark;

  /// Accent colour (roof trim, flame, rope...).
  final Color accent;

  /// Outline colour.
  final Color outline;

  /// The silhouette family the renderer draws (drives the basic shape).
  final PlaceableSilhouette silhouette;

  /// Apparent height in tile-heights.
  final double heightFactor;

  /// Whole-figure opacity (ghost preview < 1, removed -> 0).
  final double opacity;

  /// Whether to attach an ember/light glow at this placeable.
  final bool emitsLight;

  /// Number of tier pips to draw (tier-1 = 0, tier-2 = 1, ...).
  final int tierPips;

  /// Optional short caption shown under the placeholder (debug/readability).
  final String? label;

  PlaceableVisual copyWith({
    Color? body,
    Color? bodyDark,
    Color? accent,
    Color? outline,
    PlaceableSilhouette? silhouette,
    double? heightFactor,
    double? opacity,
    bool? emitsLight,
    int? tierPips,
    String? label,
  }) {
    return PlaceableVisual(
      body: body ?? this.body,
      bodyDark: bodyDark ?? this.bodyDark,
      accent: accent ?? this.accent,
      outline: outline ?? this.outline,
      silhouette: silhouette ?? this.silhouette,
      heightFactor: heightFactor ?? this.heightFactor,
      opacity: opacity ?? this.opacity,
      emitsLight: emitsLight ?? this.emitsLight,
      tierPips: tierPips ?? this.tierPips,
      label: label ?? this.label,
    );
  }
}

/// Basic silhouette families the placeholder renderer knows how to draw. Closed
/// so every placeable maps to a readable, distinct shape.
enum PlaceableSilhouette {
  /// Ring of stones with a flame (hearth, cookingFire).
  firePit,

  /// A tall pole with a flame at the top (torch).
  pole,

  /// A raised bowl/dish on legs with flame (brazier).
  bowl,

  /// A low slab/anvil work surface (knappingStation).
  slab,

  /// An A-frame rack of poles (toolRack).
  rack,

  /// A slanted single-pitch shelter (leanTo).
  leanFrame,

  /// A conical tent (hideTent).
  cone,

  /// A round/domed hut (hut).
  dome,

  /// A row of upright stakes (palisade).
  fence,
}

/// How a resource node should be drawn.
class NodeVisual {
  const NodeVisual({
    required this.fill,
    required this.fillDark,
    required this.outline,
    required this.silhouette,
    required this.fullness,
    this.scale = 1.0,
  });

  /// Lit fill.
  final Color fill;

  /// Shaded fill.
  final Color fillDark;

  /// Outline colour.
  final Color outline;

  /// The node silhouette family.
  final NodeSilhouette silhouette;

  /// 0..1 remaining amount — the renderer shrinks/dims as this drops.
  final double fullness;

  /// Overall size multiplier.
  final double scale;

  NodeVisual copyWith({
    Color? fill,
    Color? fillDark,
    Color? outline,
    NodeSilhouette? silhouette,
    double? fullness,
    double? scale,
  }) {
    return NodeVisual(
      fill: fill ?? this.fill,
      fillDark: fillDark ?? this.fillDark,
      outline: outline ?? this.outline,
      silhouette: silhouette ?? this.silhouette,
      fullness: fullness ?? this.fullness,
      scale: scale ?? this.scale,
    );
  }
}

/// Node silhouette families (one readable shape per resource).
enum NodeSilhouette { tree, boulder, berryBush, gameAnimal }

// ===========================================================================
// Sprite seam value type. A SpriteHandle is a DECODED image + the render hints
// a component needs to composite it (anchor kind + target width in tile-widths).
// EmberArt's sprite-resolver methods return null when a slot is unmapped/unloaded
// so the component falls back to its programmatic draw — the sprite-OR-placeholder
// seam. Only SpriteEmberArt ever returns non-null; PlaceholderEmberArt returns
// null for every slot.
// ===========================================================================

/// A decoded sprite ready to composite onto the iso scene.
class SpriteHandle {
  const SpriteHandle({
    required this.image,
    required this.anchor,
    this.widthTiles = 1.0,
  });

  /// The decoded source image.
  final ui.Image image;

  /// How this sprite anchors onto the scene (diamond face vs bottom-center).
  final SpriteAnchorKind anchor;

  /// Target on-screen width as a multiple of the tile width (bottomCenter only).
  final double widthTiles;

  /// Source pixel size (used to preserve aspect ratio when scaling).
  double get srcW => image.width.toDouble();
  double get srcH => image.height.toDouble();
}

// ===========================================================================
// Generic placeholder-primitive toolkit value types. Activity scenes build
// bespoke props out of these WITHOUT a new closed art key.
// ===========================================================================

/// A rounded panel/card render instruction.
class PanelSpec {
  const PanelSpec({
    required this.size,
    this.fill,
    this.fillTo,
    this.outline,
    this.radius,
    this.elevation = 0.0,
  });

  /// Panel size in logical px.
  final Vector2 size;

  /// Fill (top of vertical gradient); defaults to palette surface.
  final Color? fill;

  /// Bottom of the vertical gradient; defaults to a darker [fill].
  final Color? fillTo;

  /// Outline colour; defaults to palette outline.
  final Color? outline;

  /// Corner radius; defaults to [EmberMetrics.panelRadius].
  final double? radius;

  /// Soft drop-shadow strength (0 = none).
  final double elevation;
}

/// A small chip/pill render instruction (counters, labels).
class ChipSpec {
  const ChipSpec({
    required this.size,
    this.fill,
    this.outline,
    this.glyph,
    this.glyphColor,
  });

  final Vector2 size;
  final Color? fill;
  final Color? outline;

  /// Optional icon glyph drawn inside.
  final IconGlyph? glyph;
  final Color? glyphColor;
}

/// Closed set of simple, hand-drawn icon glyphs the placeholder toolkit can
/// render (vector primitives, no font dependency). Enough to caption any prop.
enum IconGlyph {
  flame,
  wood,
  stone,
  food,
  hide,
  hammer,
  tent,
  hut,
  spark,
  drop,
  sun,
  moon,
  check,
  cross,
  arrowUp,
  arrowDown,
  plus,
  minus,
  question,
  star,
  heart,
  paw,
  person,
  leaf,
}

/// Basic primitive shapes the toolkit can stamp for custom props.
enum PrimitiveShape { circle, roundedRect, diamond, triangle, ring, blob }

// ===========================================================================
// The facade.
// ===========================================================================

/// The single art facade. Default = [PlaceholderEmberArt].
abstract interface class EmberArt {
  /// Render instruction for a [TerrainType] tile. [buildable]/[floodRisk] nudge
  /// the overlay/tint so the renderer shows affordances consistently.
  TileVisual tile(TerrainType t, {bool buildable = true, bool floodRisk = false});

  /// Render instruction for a placeable at [state]/[tier].
  PlaceableVisual placeable(
    PlaceableType type, {
    required PlaceableState state,
    int tier = 1,
  });

  /// Render instruction for a resource node ([remaining] in 0..1).
  NodeVisual node(ResourceType t, {double remaining = 1.0});

  /// A fresh [AnimatedActor] for [kind]. Each call returns a NEW actor wrapping
  /// its own component (actors are stateful and own their figure).
  AnimatedActor actor(ActorKind kind);

  /// A fresh PLAYER-AVATAR [AnimatedActor] — the distinct Stone-Age HERO figure
  /// (slightly larger, an ember tunic + sash, a floating chevron marker) that a
  /// PlayerComponent drives. Separate from [actor] (whose [ActorKind] set is
  /// frozen for NPCs/predator/flame) so the hero never collides with that closed
  /// set. Each call returns a NEW actor owning its own figure. [reduceMotion]
  /// stills the ambient idle bob + marker bounce (calm ambience).
  AnimatedActor playerActor({bool reduceMotion = false});

  /// The palette this art is themed with.
  EmberPalette get palette;

  // ---- Sprite seam ------------------------------------------------------
  // Each returns a decoded [SpriteHandle] for the slot, or NULL when the slot is
  // unmapped or the sprite pack isn't loaded — in which case the component keeps
  // its programmatic draw. PlaceholderEmberArt returns null for all of these;
  // SpriteEmberArt serves the mapped slots from its cache.

  /// Sprite for a terrain tile face, or null (-> programmatic diamond fill).
  SpriteHandle? tileSprite(TerrainType t);

  /// Sprite for a placeable at [state]/[tier], or null (-> programmatic).
  SpriteHandle? placeableSprite(PlaceableType type,
      {required PlaceableState state, int tier = 1});

  /// Sprite for a resource node ([remaining] in 0..1 selects depletion frames),
  /// or null (-> programmatic). hide / huntable have no sprite -> always null.
  SpriteHandle? nodeSprite(ResourceType t, {double remaining = 1.0});

  /// Sprite for an NPC actor [kind]. [varietyKey] (e.g. the NPC id hash) rotates
  /// spare tribe cutouts for crowd variety. null for predator/flame (-> prog).
  SpriteHandle? actorSprite(ActorKind kind, {int varietyKey = 0});

  /// The PLAYER hero cutout sprite, or null (-> programmatic hero figure).
  SpriteHandle? playerSprite();

  /// The placement-validity ring sprite (iso-diamond outline), or null (->
  /// programmatic diamond highlight). Invalid uses the same handle, red-tinted.
  SpriteHandle? validRingSprite();

  // ---- Generic placeholder-primitive toolkit ----------------------------
  // These let activity scenes build bespoke interactive props from primitives
  // so a leaf NEVER needs a new closed art key. Returned components are plain
  // Flame [PositionComponent]s the scene positions/animates itself.

  /// A rounded panel/card component (soft gradient + outline + optional shadow).
  PositionComponent panel(PanelSpec spec);

  /// A small chip/pill component (optionally with an icon glyph).
  PositionComponent chip(ChipSpec spec);

  /// A standalone icon-glyph component drawn at [size] px in [color].
  PositionComponent icon(IconGlyph glyph, {double size = 24.0, Color? color});

  /// A simple filled primitive shape component.
  PositionComponent shape(
    PrimitiveShape shape, {
    required Vector2 size,
    Color? fill,
    Color? outline,
  });

  /// A reusable vertical gradient [Paint] between [from] and [to] over [extent]
  /// px (top->bottom). Activity scenes use this to fill custom geometry.
  Paint verticalGradient(Color from, Color to, double extent);
}
