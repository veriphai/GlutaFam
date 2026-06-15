// Ember — art/sprite_compositor.dart
//
// The ONE place that composites a [SpriteHandle] onto a Canvas, so every world
// component (tiles, placeables, nodes, actors, ghost) draws sprites with the SAME
// anchor/scale grammar. Keeping the math here (not duplicated per component) means
// a future tuning pass changes one function.
//
// Two anchor modes (matching SpriteAnchorKind):
//   * diamond       — fills the iso tile face. Canvas origin is the DIAMOND
//                     CENTER (as the tile map / ghost translate to). Drawn at
//                     exactly tileWidth x tileHeight.
//   * bottomCenter  — a cutout standing on the tile. Canvas origin is the
//                     BOTTOM-CENTER of the component box (as placeable/node/actor
//                     renderers translate to before drawing upward). Width =
//                     widthTiles * tileWidth; height preserves source aspect.
//
// Presentation-only (art/): pure canvas painting, no clock/randomness.

import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'ember_art.dart';
import 'sprite_slots.dart';

/// Shared sprite compositing onto a Canvas. All methods assume the caller has
/// already translated the canvas to the documented origin for the anchor mode.
class SpriteCompositor {
  const SpriteCompositor._();

  /// Draw [h] as an iso DIAMOND ground face, centered on the canvas origin and
  /// sized exactly [tileWidth] x [tileHeight]. The tile_* sprites bake their own
  /// soil walls, so the caller must NOT also draw programmatic side-walls.
  static void drawDiamond(
    Canvas canvas,
    SpriteHandle h, {
    required double tileWidth,
    required double tileHeight,
    double opacity = 1.0,
    Color? tint,
    double overscan = 0.0,
  }) {
    // [overscan] enlarges the drawn diamond by this many logical px on each axis
    // so adjacent tile sprites OVERLAP by a hairline — this hides the faint
    // baked diamond edge that otherwise betrays the tile grid (runner finding:
    // tile grid lines). Back-to-front paint order keeps the overlap correct.
    final Rect dst = Rect.fromCenter(
      center: Offset.zero,
      width: tileWidth + overscan,
      height: tileHeight + overscan,
    );
    _drawInto(canvas, h.image, dst, opacity: opacity, tint: tint);
  }

  /// Draw [h] as a BOTTOM-CENTER cutout standing on the tile. Caller origin is
  /// the box bottom-center; the sprite is scaled so its width is
  /// [h.widthTiles] * [tileWidth] and its height preserves the source aspect,
  /// then drawn upward from the origin (its base sits on the origin baseline).
  /// [extraScale] uniformly scales around the base (e.g. node depletion shrink).
  static void drawBottomCenter(
    Canvas canvas,
    SpriteHandle h, {
    required double tileWidth,
    double opacity = 1.0,
    double extraScale = 1.0,
    Color? tint,
  }) {
    final double srcW = h.srcW;
    final double srcH = h.srcH;
    if (srcW <= 0 || srcH <= 0) return;
    final double w = h.widthTiles * tileWidth * extraScale;
    final double drawH = w * (srcH / srcW);
    final Rect dst = Rect.fromLTWH(-w / 2, -drawH, w, drawH);
    _drawInto(canvas, h.image, dst, opacity: opacity, tint: tint);
  }

  static void _drawInto(
    Canvas canvas,
    ui.Image image,
    Rect dst, {
    double opacity = 1.0,
    Color? tint,
  }) {
    final Rect src =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final Paint paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..isAntiAlias = true;
    if (opacity < 1.0) {
      paint.color = const Color(0xFFFFFFFF).withValues(alpha: opacity.clamp(0.0, 1.0));
    }
    if (tint != null) {
      // Tint without losing the image (modulate toward the tint colour).
      paint.colorFilter = ColorFilter.mode(
        tint.withValues(alpha: tint.a * opacity),
        BlendMode.srcATop,
      );
    }
    canvas.drawImageRect(image, src, dst, paint);
  }
}

/// Resolves a per-id stable variety index for tribe-member sprite rotation, so a
/// given NPC always shows the same spare cutout (presentation-only — no sim use).
int spriteVarietyKey(Object id) => id.hashCode;

/// The pool size for tribe variety (exposed for callers that want to clamp).
int get tribeVarietyCount => EmberSpriteSlots.tribeVariety.length;
