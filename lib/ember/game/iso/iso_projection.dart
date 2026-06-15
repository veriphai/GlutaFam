// Ember — game/iso/iso_projection.dart
//
// Stateless isometric projection math. The single place that converts between
// integer grid space (GridCoord — the source of truth) and screen/world space
// (Vector2 — what Flame positions things at). EVERY component projects through
// this so tiles, placeables, nodes, ghosts, and the camera all agree on where a
// cell lives.
//
// Coordinate convention (2:1 diamond, tile metrics from EmberMetrics):
//   screenX = (gx - gy) * halfTileWidth
//   screenY = (gx + gy) * halfTileHeight
// The grid origin (0,0) maps to world (0,0); +x goes screen-right-and-down,
// +y goes screen-left-and-down — a standard staggered iso. The inverse solves
// the 2x2 system back to fractional grid coords (then floors to the cell).
//
// Presentation-only (game/) — depends on flame Vector2 + the art metrics. No
// clock, no randomness, no world-state. Pure functions only.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../art/ember_palette.dart';
import '../../core/geometry.dart';

/// Stateless iso math. Construct with the tile metrics (defaults to the frozen
/// [EmberMetrics] values) so a future zoomed/retuned tileset can be swapped in
/// without touching call sites.
class IsoProjection {
  const IsoProjection({
    this.tileWidth = EmberMetrics.tileWidth,
    this.tileHeight = EmberMetrics.tileHeight,
  });

  /// The canonical projection using the frozen [EmberMetrics].
  static const IsoProjection standard = IsoProjection();

  /// Full diamond width / height in world px.
  final double tileWidth;
  final double tileHeight;

  double get halfTileWidth => tileWidth / 2;
  double get halfTileHeight => tileHeight / 2;

  // ===========================================================================
  // Grid <-> world projection
  // ===========================================================================

  /// Projects integer grid cell [c] to the world position of its diamond
  /// CENTER (top-face center). Components anchor where it makes sense relative
  /// to this (tiles use the center; tall placeables/actors offset up).
  Vector2 gridToScreen(GridCoord c) =>
      gridToScreenXY(c.x.toDouble(), c.y.toDouble());

  /// Fractional variant — lets the ghost/camera interpolate smoothly between
  /// cells. [gx]/[gy] need not be integers.
  Vector2 gridToScreenXY(double gx, double gy) => Vector2(
        (gx - gy) * halfTileWidth,
        (gx + gy) * halfTileHeight,
      );

  /// Inverse projection: world position -> the grid cell it falls in. Solves
  /// the linear system then floors to the containing cell. World (0,0) is the
  /// center of cell (0,0), so we bias by a half-cell before flooring.
  GridCoord screenToGrid(Vector2 world) {
    final (double fx, double fy) = screenToGridFractional(world);
    return GridCoord(fx.floor(), fy.floor());
  }

  /// Fractional inverse: returns the (possibly negative, non-integer) grid
  /// coordinate a world point maps to, with cell centers on integer+0.5. The
  /// floor of each gives the containing cell (see [screenToGrid]).
  (double, double) screenToGridFractional(Vector2 world) {
    // Forward (relative to cell-center basis):
    //   sx = (gx - gy) * hw ;  sy = (gx + gy) * hh
    // Invert:
    //   gx = (sx/hw + sy/hh) / 2 ;  gy = (sy/hh - sx/hw) / 2
    final double a = world.x / halfTileWidth;
    final double b = world.y / halfTileHeight;
    // +0.5 bias so a point at a cell's center floors to that cell.
    final double gx = (a + b) / 2 + 0.5;
    final double gy = (b - a) / 2 + 0.5;
    return (gx, gy);
  }

  // ===========================================================================
  // Tile face geometry (the diamond corners), in LOCAL space around the center.
  // ===========================================================================

  /// The four corners of a tile's top face, relative to its center (0,0):
  /// top, right, bottom, left — clockwise. Renderers stroke/fill this path.
  List<Vector2> diamondCorners() => <Vector2>[
        Vector2(0, -halfTileHeight), // top
        Vector2(halfTileWidth, 0), // right
        Vector2(0, halfTileHeight), // bottom
        Vector2(-halfTileWidth, 0), // left
      ];

  // ===========================================================================
  // Depth sorting
  // ===========================================================================

  /// A monotonic depth key for painter's-order sorting: things further "back"
  /// (smaller gx+gy) draw first; ties broken by gx so left-of-screen wins. The
  /// game uses this as a component priority so the iso scene composites without
  /// z-fighting. [heightBias] nudges tall objects (placeables) to sort after the
  /// tile they stand on.
  int depthSortKey(GridCoord c, {int heightBias = 0}) {
    // Pack (gx+gy) as the major key and gx as the minor key into one int.
    // Grid is small (<= 256); 12 bits per axis is plenty of headroom.
    // heightBias occupies the high bits so a standing object always sorts
    // after the tiles on its own (and the previous) row.
    final int major = (c.x + c.y) & 0xFFF;
    final int minor = c.x & 0xFFF;
    return (heightBias << 24) | (major << 12) | minor;
  }

  /// Float depth key (same ordering as [depthSortKey]) for fractional positions
  /// like a dragging ghost.
  double depthSortKeyXY(double gx, double gy) => (gx + gy) * 1000.0 + gx;

  // ===========================================================================
  // Map bounds
  // ===========================================================================

  /// The axis-aligned world rect that tightly bounds a [width]x[height] grid's
  /// projected diamonds (top-face extents). The camera clamps pan to this.
  /// [pad] grows the rect on every side so the edges aren't flush to the screen.
  Rect mapBounds(int width, int height, {double pad = 0}) {
    if (width <= 0 || height <= 0) {
      return Rect.fromLTWH(-pad, -pad, 2 * pad, 2 * pad);
    }
    // Extreme corners of the diamond field (use full tile-height extents so
    // raised tiles + standing placeables aren't clipped at the top).
    final Vector2 topCorner = gridToScreenXY(0, 0); // upper apex region
    final Vector2 rightCorner = gridToScreenXY(width.toDouble(), 0);
    final Vector2 leftCorner = gridToScreenXY(0, height.toDouble());
    final Vector2 bottomCorner =
        gridToScreenXY(width.toDouble(), height.toDouble());

    final double minX = leftCorner.x - halfTileWidth - pad;
    final double maxX = rightCorner.x + halfTileWidth + pad;
    final double minY = topCorner.y - halfTileHeight - pad;
    final double maxY = bottomCorner.y + halfTileHeight + pad;
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// The world position of the grid's visual center (camera home).
  Vector2 mapCenter(int width, int height) =>
      gridToScreenXY(width / 2, height / 2);

  /// Smallest zoom that still fits the whole map inside [viewport] (px), so the
  /// camera's lower clamp can be derived rather than hard-coded if desired.
  double fitZoom(int width, int height, Vector2 viewport, {double pad = 0}) {
    final Rect b = mapBounds(width, height, pad: pad);
    if (b.width <= 0 || b.height <= 0) return 1.0;
    final double zx = viewport.x / b.width;
    final double zy = viewport.y / b.height;
    return math.min(zx, zy);
  }
}
