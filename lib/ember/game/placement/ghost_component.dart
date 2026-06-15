// Ember — game/placement/ghost_component.dart
//
// The drag-to-place GHOST: a translucent preview of the placeable-to-be that
// snaps to the grid cell under the pointer and tints GREEN (valid) or RED
// (invalid). Validity is decided by the SAME pure [PlacementValidator] the
// confirm step uses, so the preview never lies. The ghost also paints a footprint
// diamond per cell (green/red per-cell) so multi-tile structures read clearly.
//
// The placement controller owns this component's lifecycle and feeds it the
// current target coord + rotation; the ghost just renders. It reads world state
// (for validity) via the bridge but NEVER dispatches — confirm/cancel is the
// controller's job.

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../art/ember_art.dart';
import '../../art/ember_palette.dart';
import '../../art/sprite_compositor.dart';
import '../../contracts/placeable_def.dart';
import '../../core/enums.dart';
import '../../core/geometry.dart';
import '../../core/ids.dart';
import '../components/placeable_component.dart';
import '../ember_game.dart';
import '../iso/iso_projection.dart';
import '../riverpod_flame_bridge.dart';
import 'placement_validator.dart';

/// A grid-snapped, validity-tinted placeable preview.
class GhostComponent extends PositionComponent
    with HasGameReference<EmberGame>, BridgedComponent {
  GhostComponent({
    required this.type,
    required this.def,
    this.ignoreId,
    this.projection = IsoProjection.standard,
    super.priority = priorityGhost,
  }) : super(anchor: Anchor.bottomCenter);

  /// Drawn above everything in the world so it's never occluded.
  static const int priorityGhost = 3000000;

  static const PlacementValidator _validator = PlacementValidator();

  /// What is being placed.
  final PlaceableType type;

  /// The def (footprint/terrain/cost) — may be null if unregistered.
  final PlaceableDef? def;

  /// When editing/moving, the id of the placeable being moved (excluded from the
  /// occupancy check).
  final EntityId? ignoreId;

  final IsoProjection projection;

  /// The cell the ghost currently sits on (top-left footprint anchor).
  GridCoord _coord = GridCoord.zero;

  /// Rotation in quarter-turns.
  int _rotation = 0;

  /// Cached validity for the current coord/rotation.
  PlacementValidity _validity = PlacementValidity.valid;
  Set<GridCoord> _invalidCells = <GridCoord>{};

  EmberArt get art => game.art;
  EmberPalette get palette => art.palette;

  /// Current coord (read by the controller for ConfirmPlace).
  GridCoord get coord => _coord;
  int get rotation => _rotation;
  bool get isValid => _validity.ok;
  PlacementValidity get validity => _validity;

  @override
  Future<void> onLoad() async {
    // Re-validate whenever the world changes under the ghost (e.g. resources
    // spent elsewhere flip affordability).
    listenWorld(_revalidate, fireImmediately: false);
    _revalidate();
  }

  /// Move the ghost to [coord] (snapping handled by the controller).
  void moveTo(GridCoord coord) {
    if (coord == _coord) return;
    _coord = coord;
    _revalidate();
  }

  /// Rotate the ghost one quarter-turn (footprint swaps for odd rotations).
  void rotate() {
    _rotation = (_rotation + 1) % 4;
    _revalidate();
  }

  void _revalidate() {
    _validity = _validator.validate(
      bridge.state,
      def,
      _coord,
      rotation: _rotation,
      ignoreId: ignoreId,
    );
    _invalidCells = _validator.invalidCells(
      bridge.state,
      def,
      _coord,
      rotation: _rotation,
      ignoreId: ignoreId,
    );
    final Vector2 center = projection.gridToScreen(_coord);
    position = Vector2(center.x, center.y + projection.halfTileHeight);
    final double stand = ((def == null) ? 1.0 : 1.6) * EmberMetrics.tileHeight;
    size = Vector2(projection.tileWidth * 0.8, stand);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _drawFootprint(canvas);
    _drawSilhouette(canvas);
  }

  void _drawFootprint(Canvas canvas) {
    final PlaceableDef? d = def;
    final (int w, int h) =
        d == null ? (1, 1) : _validator.footprintFor(d, _rotation);
    final List<Vector2> corners = projection.diamondCorners();
    final Path diamond = Path()
      ..moveTo(corners[0].x, corners[0].y)
      ..lineTo(corners[1].x, corners[1].y)
      ..lineTo(corners[2].x, corners[2].y)
      ..lineTo(corners[3].x, corners[3].y)
      ..close();

    // SPRITE SEAM: the placement-validity ring is the iso-diamond outline sprite
    // (red-tinted for invalid cells; the valid/clear ring as-is). Falls back to
    // the programmatic tinted diamond when no sprite is loaded.
    final SpriteHandle? ring = art.validRingSprite();

    for (final GridCoord cell in _coord.footprint(w, h)) {
      final bool bad = _invalidCells.contains(cell);
      final Color tint =
          (bad ? palette.danger : palette.success).withValues(alpha: 0.42);
      // Footprint cells are drawn in WORLD space relative to the ghost anchor.
      final Vector2 cellCenter = projection.gridToScreen(cell);
      final Vector2 anchorCenter = projection.gridToScreen(_coord);
      final double dx = cellCenter.x - anchorCenter.x;
      final double dy = cellCenter.y - anchorCenter.y;

      canvas.save();
      // Local origin is bottom-center; the anchor cell center sits one
      // half-tile-height up from the bottom point.
      canvas.translate(size.x / 2 + dx, size.y - projection.halfTileHeight + dy);
      if (ring != null) {
        // A faint validity wash under the ring keeps the cell readable; the ring
        // sprite is red-tinted on invalid cells (no separate red-diamond sprite).
        canvas.drawPath(diamond, Paint()..color = tint.withValues(alpha: 0.22));
        SpriteCompositor.drawDiamond(
          canvas,
          ring,
          tileWidth: projection.tileWidth,
          tileHeight: projection.tileHeight,
          tint: bad ? palette.danger : null,
        );
      } else {
        canvas.drawPath(diamond, Paint()..color = tint);
        canvas.drawPath(
          diamond,
          Paint()
            ..color = (bad ? palette.danger : palette.success)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
      canvas.restore();
    }
  }

  void _drawSilhouette(Canvas canvas) {
    final PlaceableVisual v =
        art.placeable(type, state: PlaceableState.ghost, tier: 1);
    final double op = 0.55;
    final Color tint = isValid ? palette.success : palette.danger;

    canvas.save();
    canvas.translate(size.x / 2, size.y);

    // SPRITE SEAM: a translucent, validity-tinted preview of the real placeable
    // sprite (ghost = built sprite at low opacity + green/red tint). Falls back
    // to the tinted programmatic silhouette when no sprite is loaded.
    final SpriteHandle? sprite =
        art.placeableSprite(type, state: PlaceableState.built, tier: 1);
    if (sprite != null) {
      SpriteCompositor.drawBottomCenter(
        canvas,
        sprite,
        tileWidth: projection.tileWidth,
        opacity: op,
        tint: tint.withValues(alpha: 0.45),
      );
      canvas.restore();
      return;
    }

    final double bw = size.x * 0.7;
    final double bh = size.y * 0.9;
    // Tint the body toward green/red so validity reads at a glance.
    final Paint body = Paint()
      ..color = Color.lerp(v.body, tint, 0.4)!.withValues(alpha: op);
    final Paint bodyDark = Paint()
      ..color = Color.lerp(v.bodyDark, tint, 0.4)!.withValues(alpha: op);
    final Paint accent = Paint()..color = tint.withValues(alpha: op);
    final Paint outline = Paint()
      ..color = tint
      ..style = PaintingStyle.stroke
      ..strokeWidth = EmberMetrics.strokeWidth;

    PlaceableSilhouettePainter.paint(
      canvas,
      v.silhouette,
      bw,
      bh,
      body: body,
      bodyDark: bodyDark,
      accent: accent,
      outline: outline,
    );
    canvas.restore();
  }
}
