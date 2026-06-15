// Ember — art/ember_palette.dart
//
// The central style guide: every colour, the isometric tile metrics, and the
// global lighting angle live here so the whole module reads from ONE place.
// This is presentation-only (art/), so importing dart:ui/flutter painting is
// fine — but there is NO clock and NO randomness here.
//
// Style intent: warm Stone-Age dusk. Earthy greens + sandy ground, ember-orange
// accents, cool teal water, muted greys for stone. Soft gradients, readable
// silhouettes. The placeholder art derives EVERYTHING from this palette so a
// later sprite pass keeps the same tonal language.

import 'package:flutter/painting.dart';

/// The frozen colour + metric constants for the Ember look.
///
/// Implemented as an instantiable value type (rather than a bag of statics) so a
/// future "night palette" or "wet-season palette" can be swapped behind the same
/// shape, while [EmberPalette.dusk] stays the default everyone reads.
class EmberPalette {
  const EmberPalette({
    required this.background,
    required this.backgroundDeep,
    required this.surface,
    required this.surfaceRaised,
    required this.outline,
    required this.ink,
    required this.inkSoft,
    required this.ember,
    required this.emberBright,
    required this.emberDeep,
    required this.spark,
    required this.grass,
    required this.grassDark,
    required this.water,
    required this.waterDeep,
    required this.forest,
    required this.forestDark,
    required this.rock,
    required this.rockDark,
    required this.highGround,
    required this.highGroundDark,
    required this.wood,
    required this.woodDark,
    required this.hide,
    required this.hideDark,
    required this.food,
    required this.stoneChip,
    required this.success,
    required this.warning,
    required this.danger,
    required this.cold,
    required this.night,
    required this.shadow,
  });

  // ---- Chrome / UI surfaces ---------------------------------------------
  /// Canvas backdrop (sky/ambient behind the iso world).
  final Color background;

  /// Deeper backdrop band (bottom of a vertical sky gradient).
  final Color backgroundDeep;

  /// Default panel/card fill (rounded placeholder panels).
  final Color surface;

  /// A raised/active panel fill (chips, selected states).
  final Color surfaceRaised;

  /// Hairline outline/stroke colour for panels & tiles.
  final Color outline;

  /// Primary text/icon ink.
  final Color ink;

  /// Secondary/disabled ink.
  final Color inkSoft;

  // ---- Fire / accent -----------------------------------------------------
  /// The signature ember-orange (primary accent).
  final Color ember;

  /// Hot highlight at the core of a flame.
  final Color emberBright;

  /// Deep base of a flame / smouldering coal.
  final Color emberDeep;

  /// Tiny bright spark / particle highlight.
  final Color spark;

  // ---- Terrain -----------------------------------------------------------
  final Color grass;
  final Color grassDark;
  final Color water;
  final Color waterDeep;
  final Color forest;
  final Color forestDark;
  final Color rock;
  final Color rockDark;
  final Color highGround;
  final Color highGroundDark;

  // ---- Resources ---------------------------------------------------------
  final Color wood;
  final Color woodDark;
  final Color hide;
  final Color hideDark;
  final Color food;
  final Color stoneChip;

  // ---- Semantic feedback -------------------------------------------------
  final Color success;
  final Color warning;
  final Color danger;
  final Color cold;
  final Color night;

  /// Multiply-style shadow tint dropped under placeables/actors.
  final Color shadow;

  /// Linear-interpolate between two palettes (e.g. day -> night blend).
  /// Never returns null: clamps [t] to 0..1.
  EmberPalette lerpTo(EmberPalette other, double t) {
    final double k = t.clamp(0.0, 1.0);
    Color c(Color a, Color b) => Color.lerp(a, b, k)!;
    return EmberPalette(
      background: c(background, other.background),
      backgroundDeep: c(backgroundDeep, other.backgroundDeep),
      surface: c(surface, other.surface),
      surfaceRaised: c(surfaceRaised, other.surfaceRaised),
      outline: c(outline, other.outline),
      ink: c(ink, other.ink),
      inkSoft: c(inkSoft, other.inkSoft),
      ember: c(ember, other.ember),
      emberBright: c(emberBright, other.emberBright),
      emberDeep: c(emberDeep, other.emberDeep),
      spark: c(spark, other.spark),
      grass: c(grass, other.grass),
      grassDark: c(grassDark, other.grassDark),
      water: c(water, other.water),
      waterDeep: c(waterDeep, other.waterDeep),
      forest: c(forest, other.forest),
      forestDark: c(forestDark, other.forestDark),
      rock: c(rock, other.rock),
      rockDark: c(rockDark, other.rockDark),
      highGround: c(highGround, other.highGround),
      highGroundDark: c(highGroundDark, other.highGroundDark),
      wood: c(wood, other.wood),
      woodDark: c(woodDark, other.woodDark),
      hide: c(hide, other.hide),
      hideDark: c(hideDark, other.hideDark),
      food: c(food, other.food),
      stoneChip: c(stoneChip, other.stoneChip),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      danger: c(danger, other.danger),
      cold: c(cold, other.cold),
      night: c(night, other.night),
      shadow: c(shadow, other.shadow),
    );
  }

  /// The default warm-dusk palette. This is the canonical Ember look.
  static const EmberPalette dusk = EmberPalette(
    background: Color(0xFFF1E2C6),
    backgroundDeep: Color(0xFFE0C79B),
    surface: Color(0xFFFFFBF2),
    surfaceRaised: Color(0xFFFFF1D6),
    outline: Color(0xFF5C4630),
    ink: Color(0xFF3A2A1A),
    inkSoft: Color(0xFF8A745A),
    ember: Color(0xFFF2873B),
    emberBright: Color(0xFFFFD15C),
    emberDeep: Color(0xFFC0451E),
    spark: Color(0xFFFFE9A8),
    grass: Color(0xFF8FB85A),
    grassDark: Color(0xFF6E963F),
    water: Color(0xFF5FB6C4),
    waterDeep: Color(0xFF3C8C9C),
    forest: Color(0xFF5C8C46),
    forestDark: Color(0xFF3F6B30),
    // Warmed toward sandy-grey (was 0xFFA9A096 / 0xFF7C7269 cool grey) so the
    // rocky SE field sits in the same warm family as the soil/grass instead of
    // fighting the palette.
    rock: Color(0xFFB8A990),
    rockDark: Color(0xFF8C7C64),
    highGround: Color(0xFFC9B68C),
    highGroundDark: Color(0xFFA8945F),
    wood: Color(0xFFB07A45),
    woodDark: Color(0xFF855322),
    hide: Color(0xFFCBA06A),
    hideDark: Color(0xFF9C734A),
    food: Color(0xFFE3603F),
    stoneChip: Color(0xFFBFB7AD),
    success: Color(0xFF5BA85A),
    warning: Color(0xFFE0A93C),
    danger: Color(0xFFD24B3A),
    cold: Color(0xFF7FA6D6),
    night: Color(0xFF2A3358),
    shadow: Color(0x33241608),
  );

  /// A cooler night variant (used by lerp for day->night transitions).
  static const EmberPalette night2 = EmberPalette(
    background: Color(0xFF2B3357),
    backgroundDeep: Color(0xFF1A2140),
    surface: Color(0xFF3A3F5C),
    surfaceRaised: Color(0xFF4A4F70),
    outline: Color(0xFF11152B),
    ink: Color(0xFFE8E6F0),
    inkSoft: Color(0xFFA7A8C2),
    ember: Color(0xFFF2873B),
    emberBright: Color(0xFFFFD15C),
    emberDeep: Color(0xFFC0451E),
    spark: Color(0xFFFFE9A8),
    grass: Color(0xFF4C6B43),
    grassDark: Color(0xFF35502F),
    water: Color(0xFF356E80),
    waterDeep: Color(0xFF23495A),
    forest: Color(0xFF34543A),
    forestDark: Color(0xFF223A28),
    rock: Color(0xFF6B6760),
    rockDark: Color(0xFF49463F),
    highGround: Color(0xFF7C7560),
    highGroundDark: Color(0xFF5C5642),
    wood: Color(0xFF6F5235),
    woodDark: Color(0xFF4E381F),
    hide: Color(0xFF8A6F4C),
    hideDark: Color(0xFF63492F),
    food: Color(0xFFB54E36),
    stoneChip: Color(0xFF7A746B),
    success: Color(0xFF4A8C4A),
    warning: Color(0xFFC79338),
    danger: Color(0xFFB8453A),
    cold: Color(0xFF6E8FC0),
    night: Color(0xFF11152B),
    shadow: Color(0x55050810),
  );
}

/// Isometric tile metrics + the global lighting direction. These are the
/// geometric constants the renderer (F3c) and the placeholder art share so
/// silhouettes, shadows, and projected positions all line up.
class EmberMetrics {
  const EmberMetrics._();

  /// Full width of one diamond tile face, in logical px.
  static const double tileWidth = 96.0;

  /// Full height of one diamond tile face (2:1 iso ratio).
  static const double tileHeight = 48.0;

  /// Half extents — handy for projecting grid coords to screen.
  static const double halfTileWidth = tileWidth / 2;
  static const double halfTileHeight = tileHeight / 2;

  /// Apparent "thickness" of a raised tile (the side wall under the top face).
  static const double tileDepth = 14.0;

  /// Corner radius used by all rounded placeholder panels / chips.
  static const double panelRadius = 14.0;
  static const double chipRadius = 10.0;

  /// Default hairline stroke width for outlines.
  static const double strokeWidth = 1.5;

  /// Global key-light direction (normalized-ish), used to tint the lit vs.
  /// shaded faces of placeholder solids. Light comes from upper-left.
  static const Offset lightDir = Offset(-0.55, -0.83);

  /// Where the warm key light sits, expressed as an [Alignment], for gradients.
  static const Alignment lightAlign = Alignment(-0.6, -0.8);

  /// How tall (in tile-heights) a 1-footprint placeable stands by default.
  static const double placeableStandFactor = 1.6;

  /// Drop-shadow blur radius beneath placeables/actors.
  static const double shadowBlur = 6.0;
}
