// Ember — game/iso/iso_tile_map_component.dart
//
// The data-driven isometric ground layer. Renders the whole [TileGrid] as
// diamond tile faces in ONE component (cheap: a single render pass, no
// per-tile components), reading each tile's look from the [EmberArt] facade so
// the tonal language is consistent and a sprite pass can swap behind it.
//
// It paints back-to-front (painter's order over gx+gy) so raised tile side-walls
// composite correctly. Buildable/flood-risk affordances come straight from the
// art instruction's `overlay`. The component listens to the [GameBridge] world
// snapshot and repaints when the grid changes (terrain rarely changes, but flood
// overlays + occupancy can), and exposes an optional per-tile highlight set the
// placement controller drives.
//
// flame_tiled DROP-IN SEAM: this is intentionally a hand-rolled renderer so the
// module ships with zero asset/TMX dependency. To swap in flame_tiled later:
//   1. author the map as a .tmx with an isometric orientation matching
//      EmberMetrics.tileWidth/Height,
//   2. replace this component with `await TiledComponent.load('ember.tmx', ...)`
//      added to the same world layer (priority unchanged),
//   3. keep IsoProjection as the single grid<->screen authority (Tiled's own
//      projection must be configured to match it),
//   4. map TerrainType -> tile gid in the seed instead of TileVisual.
// Nothing else in the game layer needs to change — components project through
// IsoProjection, not through this renderer.

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../art/ember_art.dart';
import '../../art/ember_palette.dart';
import '../../art/sprite_compositor.dart';
import '../../core/enums.dart';
import '../../core/geometry.dart';
import '../../data/models/tile.dart';
import '../../data/models/tile_grid.dart';
import '../ember_game.dart';
import '../riverpod_flame_bridge.dart';
import 'iso_projection.dart';

/// Renders the iso ground from the live [TileGrid]. Positioned at world origin;
/// each tile is drawn at its projected center.
class IsoTileMapComponent extends PositionComponent
    with HasGameReference<EmberGame>, BridgedComponent {
  IsoTileMapComponent({
    this.projection = IsoProjection.standard,
    super.priority = priorityGround,
  }) : super(position: Vector2.zero(), anchor: Anchor.topLeft);

  /// Painter priority of the ground layer (everything else sorts above it).
  static const int priorityGround = -1000000;

  final IsoProjection projection;

  EmberArt get _art => game.art;
  EmberPalette get _palette => _art.palette;

  /// Cells the placement controller wants highlighted (valid = green tint),
  /// and cells it wants flagged invalid (red tint). Set externally; the layer
  /// repaints on the next frame.
  final Set<GridCoord> highlightValid = <GridCoord>{};
  final Set<GridCoord> highlightInvalid = <GridCoord>{};

  /// Cached corner offsets (same for every tile).
  late final List<Vector2> _corners = projection.diamondCorners();

  /// The frozen `world.*` flag the flood resolver raises once the flood has
  /// enriched the bank (the silt -> best-soil payoff). Referenced by its stable
  /// contract string so the leaf-blind world layer stays free of any concept-leaf
  /// import (matches ShelterKnowledge.bestSoilNextSeason).
  static const String _kBestSoilNextSeasonFlag = 'world.bestSoilNextSeason';

  @override
  Future<void> onLoad() async {
    // Repaint whenever the world snapshot changes (flood overlays, occupancy).
    listenWorld(() {
      // PositionComponent has no dirty flag; Flame repaints every frame, so we
      // only need the snapshot to be re-read in render(). Nothing to do here
      // beyond keeping the binding alive, but we re-evaluate size on grid change.
      _syncSize();
    }, fireImmediately: true);
  }

  void _syncSize() {
    final TileGrid grid = bridge.state.tiles;
    final Rect b = projection.mapBounds(grid.width, grid.height);
    size = Vector2(b.width, b.height);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final TileGrid grid = bridge.state.tiles;

    // THE flood-mastery payoff: once the player has lived a flood through and the
    // resolver flagged the silt fertile, flood-path tiles wear a rich dark-soil
    // sheen — "the same water that swept the camp lays the best soil next season"
    // made visible, not just spoken.
    final bool richSilt =
        bridge.state.knowledge.get(_kBestSoilNextSeasonFlag);

    // Back-to-front: iterate by (x+y) diagonal so side-walls overlap correctly.
    final int w = grid.width;
    final int h = grid.height;
    for (int sum = 0; sum <= (w - 1) + (h - 1); sum++) {
      for (int x = 0; x < w; x++) {
        final int y = sum - x;
        if (y < 0 || y >= h) continue;
        final GridCoord c = GridCoord(x, y);
        final Tile? tile = grid.at(c);
        if (tile == null || !tile.explored) continue;
        _drawTile(canvas, tile, richSilt: richSilt);
      }
    }
  }

  void _drawTile(Canvas canvas, Tile tile, {bool richSilt = false}) {
    final TileVisual v = _art.tile(
      tile.terrain,
      buildable: tile.buildable,
      floodRisk: tile.floodRisk >= 0.5,
    );
    final Vector2 center = projection.gridToScreen(tile.coord);

    canvas.save();
    canvas.translate(center.x, center.y);

    final Path topFace = _diamondPath();
    final Rect faceRect = topFace.getBounds();

    // SPRITE PATH: when the art facade provides a tile sprite, draw it as the iso
    // diamond ground face (it bakes its own soil walls + lit top), then layer the
    // SAME affordance/overlay washes on top (clipped to the diamond) so flood
    // risk, fertile silt, the village clearing, and placement highlights still
    // read. Side-walls + the programmatic gradients/pattern are SKIPPED (the
    // sprite carries that depth itself).
    final SpriteHandle? tileSprite = _art.tileSprite(tile.terrain);
    if (tileSprite != null) {
      // Overscan by ~2px so neighbouring tile sprites overlap a hairline and the
      // baked diamond edge stops reading as a visible grid (runner finding: tile
      // grid lines). Back-to-front paint order keeps the overlap clean.
      SpriteCompositor.drawDiamond(
        canvas,
        tileSprite,
        tileWidth: projection.tileWidth,
        tileHeight: projection.tileHeight,
        overscan: 2.0,
      );
      _drawTileOverlays(canvas, tile, topFace, faceRect, richSilt: richSilt);
      canvas.restore();
      return;
    }

    // Side walls (a little iso thickness) drawn first, under the top face.
    if (v.depth > 0) {
      _drawSideWalls(canvas, topFace, v);
    }

    // Top face: a DIRECTIONAL sun gradient. Light comes from the upper-left
    // (matching EmberMetrics.lightAlign + the sky's sun position), so each
    // diamond catches a warm highlight on its sun-facing corner and falls into
    // cool shade on the far corner — this is what turns a flat checkerboard into
    // a lit, painterly iso field. Water keeps its own flat treatment below.
    final bool isWaterFace = tile.terrain == TerrainType.water;
    if (isWaterFace) {
      canvas.drawPath(
        topFace,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[v.top, v.topDark],
          ).createShader(faceRect),
      );
    } else {
      final Color lit = Color.lerp(v.top, _palette.spark, 0.14) ?? v.top;
      final Color shade = Color.lerp(v.topDark, _palette.night, 0.10) ?? v.topDark;
      canvas.drawPath(
        topFace,
        Paint()
          ..shader = LinearGradient(
            // Upper-left (sun) -> lower-right (shade): the iso key light.
            begin: EmberMetrics.lightAlign,
            end: const Alignment(0.6, 0.85),
            colors: <Color>[lit, v.top, shade],
            stops: const <double>[0.0, 0.5, 1.0],
          ).createShader(faceRect),
      );
      // Soft ambient occlusion: a faint dark wash pooling at the bottom (front)
      // corner of the diamond, where it tucks under the next tile. Cheap depth.
      canvas.drawPath(
        topFace,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0.0, 0.85),
            radius: 0.9,
            colors: <Color>[
              _palette.shadow.withValues(alpha: 0.16),
              const Color(0x00000000),
            ],
          ).createShader(faceRect),
      );
    }

    // Water gets a soft diagonal flow highlight so the river reads as flowing
    // rather than a flat saturated ribbon — a cheap depth/life cue.
    if (tile.terrain == TerrainType.water) {
      canvas.drawPath(
        topFace,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              _palette.spark.withValues(alpha: 0.20),
              _palette.water.withValues(alpha: 0.0),
              _palette.waterDeep.withValues(alpha: 0.18),
            ],
            stops: const <double>[0.0, 0.5, 1.0],
          ).createShader(faceRect),
      );
    }

    // Cheap texture stipple per pattern.
    _drawPattern(canvas, v, faceRect);

    // Affordance overlay (flood-risk / non-buildable).
    final Color? overlay = v.overlay;
    if (overlay != null) {
      canvas.drawPath(topFace, Paint()..color = overlay);
    }

    // Fertile silt payoff: a warm dark-soil sheen + a few green sprout flecks on
    // the flood-path land the river just enriched (gated on the mastery flag, and
    // only on buildable ground, never on water). The richer the flood risk, the
    // darker the silt — the bank by the water gets the best soil.
    if (richSilt &&
        tile.terrain != TerrainType.water &&
        tile.buildable &&
        tile.floodRisk >= 0.4) {
      final double k = (0.16 + 0.18 * tile.floodRisk).clamp(0.0, 0.4);
      // Dark, rich silt wash.
      canvas.drawPath(
        topFace,
        Paint()..color = _palette.forestDark.withValues(alpha: k),
      );
      // A warm gold glint of new growth so the silt reads as LIFE, not mud.
      canvas.drawPath(
        topFace,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(
            center: const Alignment(-0.2, -0.2),
            radius: 0.8,
            colors: <Color>[
              _palette.food.withValues(alpha: 0.14),
              const Color(0x00000000),
            ],
          ).createShader(faceRect),
      );
      // A couple of tiny sprout ticks (deterministic — fixed offsets, no Random).
      final Paint sprout = Paint()
        ..color = _palette.grass
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      final double cx = faceRect.center.dx;
      final double cy = faceRect.center.dy;
      for (final double dx in <double>[-9, 3, 11]) {
        canvas.drawLine(
            Offset(cx + dx, cy + 3), Offset(cx + dx + 1.5, cy - 4), sprout);
      }
    }

    // A warm "clearing" tint on the village site + its immediate neighbours to
    // draw the eye toward where the player will build their settlement.
    final GridCoord site = bridge.state.village.siteTile;
    final int dxs = (tile.coord.x - site.x).abs();
    final int dys = (tile.coord.y - site.y).abs();
    if (dxs <= 1 && dys <= 1) {
      final double k = (dxs == 0 && dys == 0) ? 0.18 : 0.09;
      canvas.drawPath(
        topFace,
        Paint()..color = _palette.emberBright.withValues(alpha: k),
      );
    }

    // Placement highlight (drawn over everything on this face).
    if (highlightInvalid.contains(tile.coord)) {
      canvas.drawPath(
        topFace,
        Paint()..color = _palette.danger.withValues(alpha: 0.40),
      );
    } else if (highlightValid.contains(tile.coord)) {
      canvas.drawPath(
        topFace,
        Paint()..color = _palette.success.withValues(alpha: 0.40),
      );
    }

    // Hairline outline. Water gets a much softer, water-tinted edge so the
    // river doesn't read as a hard-edged cyan ribbon cut into the land.
    final bool isWater = tile.terrain == TerrainType.water;
    canvas.drawPath(
      topFace,
      Paint()
        ..color = isWater
            ? _palette.waterDeep.withValues(alpha: 0.30)
            : v.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = isWater ? 1.0 : EmberMetrics.strokeWidth,
    );

    canvas.restore();
  }

  /// The affordance/feedback washes layered ON a tile (works for both the
  /// programmatic face and the sprite face). For the sprite path this is the only
  /// per-tile decoration drawn on top of the baked sprite. Canvas is already
  /// translated to the diamond center.
  void _drawTileOverlays(
    Canvas canvas,
    Tile tile,
    Path topFace,
    Rect faceRect, {
    required bool richSilt,
  }) {
    // Flood-risk / non-buildable affordance (only the meaningful tints; the
    // sprite already carries the base terrain look).
    final Color? overlay = _art.tile(
      tile.terrain,
      buildable: tile.buildable,
      floodRisk: tile.floodRisk >= 0.5,
    ).overlay;
    if (overlay != null) {
      canvas.drawPath(topFace, Paint()..color = overlay);
    }

    // Fertile silt payoff (same gating as the programmatic path).
    if (richSilt &&
        tile.terrain != TerrainType.water &&
        tile.buildable &&
        tile.floodRisk >= 0.4) {
      final double k = (0.16 + 0.18 * tile.floodRisk).clamp(0.0, 0.4);
      canvas.drawPath(
        topFace,
        Paint()..color = _palette.forestDark.withValues(alpha: k),
      );
      canvas.drawPath(
        topFace,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(
            center: const Alignment(-0.2, -0.2),
            radius: 0.8,
            colors: <Color>[
              _palette.food.withValues(alpha: 0.14),
              const Color(0x00000000),
            ],
          ).createShader(faceRect),
      );
      final Paint sprout = Paint()
        ..color = _palette.grass
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      final double cx = faceRect.center.dx;
      final double cy = faceRect.center.dy;
      for (final double dx in <double>[-9, 3, 11]) {
        canvas.drawLine(
            Offset(cx + dx, cy + 3), Offset(cx + dx + 1.5, cy - 4), sprout);
      }
    }

    // Village clearing tint.
    final GridCoord site = bridge.state.village.siteTile;
    final int dxs = (tile.coord.x - site.x).abs();
    final int dys = (tile.coord.y - site.y).abs();
    if (dxs <= 1 && dys <= 1) {
      final double k = (dxs == 0 && dys == 0) ? 0.18 : 0.09;
      canvas.drawPath(
        topFace,
        Paint()..color = _palette.emberBright.withValues(alpha: k),
      );
    }

    // Placement highlight.
    if (highlightInvalid.contains(tile.coord)) {
      canvas.drawPath(
        topFace,
        Paint()..color = _palette.danger.withValues(alpha: 0.40),
      );
    } else if (highlightValid.contains(tile.coord)) {
      canvas.drawPath(
        topFace,
        Paint()..color = _palette.success.withValues(alpha: 0.40),
      );
    }
  }

  Path _diamondPath() {
    return Path()
      ..moveTo(_corners[0].x, _corners[0].y)
      ..lineTo(_corners[1].x, _corners[1].y)
      ..lineTo(_corners[2].x, _corners[2].y)
      ..lineTo(_corners[3].x, _corners[3].y)
      ..close();
  }

  void _drawSideWalls(Canvas canvas, Path topFace, TileVisual v) {
    final double d = v.depth;
    // Front-left wall (bottom -> left) and front-right wall (bottom -> right).
    final Vector2 top = _corners[0];
    final Vector2 right = _corners[1];
    final Vector2 bottom = _corners[2];
    final Vector2 left = _corners[3];

    // Iso side-wall lighting: with the sun upper-left, the LEFT wall faces away
    // (deep shade) and the RIGHT wall catches a little warm light. Each wall
    // gets a vertical gradient (top brighter, base darkest) so the field has a
    // grounded, earthy 'soil cut' depth rather than flat colour bands.
    final Color rightTop = Color.lerp(v.side, _palette.spark, 0.06) ?? v.side;
    final Color rightBot = Color.lerp(v.side, const Color(0xFF000000), 0.20)!;
    final Color leftTop = Color.lerp(v.side, const Color(0xFF000000), 0.22)!;
    final Color leftBot = Color.lerp(v.side, const Color(0xFF000000), 0.40)!;

    // Left wall.
    final Path leftWall = Path()
      ..moveTo(left.x, left.y)
      ..lineTo(bottom.x, bottom.y)
      ..lineTo(bottom.x, bottom.y + d)
      ..lineTo(left.x, left.y + d)
      ..close();
    canvas.drawPath(
      leftWall,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[leftTop, leftBot],
        ).createShader(leftWall.getBounds()),
    );

    // Right wall.
    final Path rightWall = Path()
      ..moveTo(bottom.x, bottom.y)
      ..lineTo(right.x, right.y)
      ..lineTo(right.x, right.y + d)
      ..lineTo(bottom.x, bottom.y + d)
      ..close();
    canvas.drawPath(
      rightWall,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[rightTop, rightBot],
        ).createShader(rightWall.getBounds()),
    );

    // Wall outlines.
    final Paint outline = Paint()
      ..color = v.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = EmberMetrics.strokeWidth;
    canvas.drawPath(leftWall, outline);
    canvas.drawPath(rightWall, outline);

    // Keep `top` referenced for clarity of the corner basis (no-op use).
    assert(top.y <= bottom.y);
  }

  void _drawPattern(Canvas canvas, TileVisual v, Rect face) {
    if (v.pattern == TilePattern.flat) return;
    final Paint p = Paint()
      ..color = v.topDark.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    final double cx = face.center.dx;
    final double cy = face.center.dy;
    switch (v.pattern) {
      case TilePattern.blades:
        for (final double dx in <double>[-12, 0, 12]) {
          canvas.drawLine(
            Offset(cx + dx, cy + 4),
            Offset(cx + dx + 2, cy - 4),
            p,
          );
        }
      case TilePattern.ripples:
        // Brighter, more numerous ripple crests so water reads as flowing.
        final Paint crest = Paint()
          ..color = _palette.spark.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round;
        for (final double dy in <double>[-7, -1, 5]) {
          final Path rip = Path()
            ..moveTo(cx - 16, cy + dy)
            ..quadraticBezierTo(cx, cy + dy - 3.5, cx + 16, cy + dy);
          canvas.drawPath(rip, crest);
        }
      case TilePattern.pebbles:
        for (final Offset o in <Offset>[
          Offset(cx - 8, cy),
          Offset(cx + 6, cy - 3),
          Offset(cx + 2, cy + 5),
        ]) {
          canvas.drawCircle(o, 2.2, p..style = PaintingStyle.fill);
        }
      case TilePattern.canopy:
        canvas.drawCircle(
          Offset(cx, cy - 2),
          7,
          p
            ..style = PaintingStyle.fill
            ..color = v.topDark.withValues(alpha: 0.30),
        );
      case TilePattern.flat:
        break;
    }
  }
}
