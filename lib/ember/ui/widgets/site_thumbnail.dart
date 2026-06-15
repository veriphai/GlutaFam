// Ember — ui/widgets/site_thumbnail.dart
//
// A tiny isometric "postcard" of a candidate village site, shown inside each
// site-selection card so kids get a sense of PLACE (water proximity + terrain)
// rather than an abstract Material icon. It paints a small 3x3 iso patch: the
// site tile in the center, the river drawn at a distance that maps to flood risk
// (closer water = higher risk), and a little hut marker on the site. The water +
// risk badge use the SAME flood colour language as the in-world flood visuals
// (cyan water; green/amber/red risk) so the whole flow speaks one language.
//
// Pure presentation: reads only the values passed in (terrain + floodRisk).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../art/ember_palette.dart';
import '../../core/enums.dart';

/// A small iso preview of a site (terrain + water proximity), tinted by risk.
class SiteThumbnail extends StatelessWidget {
  const SiteThumbnail({
    super.key,
    required this.terrain,
    required this.floodRisk,
    required this.palette,
    this.size = 56,
  });

  final TerrainType terrain;
  final double floodRisk;
  final EmberPalette palette;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(EmberMetrics.chipRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _SiteThumbPainter(
            terrain: terrain,
            floodRisk: floodRisk,
            palette: palette,
          ),
        ),
      ),
    );
  }
}

class _SiteThumbPainter extends CustomPainter {
  _SiteThumbPainter({
    required this.terrain,
    required this.floodRisk,
    required this.palette,
  });

  final TerrainType terrain;
  final double floodRisk;
  final EmberPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final EmberPalette p = palette;
    // Sky/ground backdrop.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[p.background, p.backgroundDeep],
        ).createShader(Offset.zero & size),
    );

    final double cx = size.width / 2;
    final double cy = size.height / 2 + 2;
    final double tw = size.width * 0.26; // half tile width
    final double th = tw * 0.5; // half tile height (2:1 iso)

    final (Color top, Color dark) = switch (terrain) {
      TerrainType.grass => (p.grass, p.grassDark),
      TerrainType.forest => (p.forest, p.forestDark),
      TerrainType.rocky => (p.rock, p.rockDark),
      TerrainType.highGround => (p.highGround, p.highGroundDark),
      TerrainType.water => (p.water, p.waterDeep),
    };

    // ELEVATION CUE: high ground (and rocky) sits on a raised plinth so "The High
    // Ground" reads as literally higher than the flat Grassland at a glance — the
    // single clearest tell between the two cards (runner finding: High Ground vs
    // Grassland hard to distinguish from the art alone). Flat terrains use 0 lift.
    final double lift = switch (terrain) {
      TerrainType.highGround => th * 1.3,
      TerrainType.rocky => th * 0.9,
      _ => 0.0,
    };
    final double groundCy = cy - lift;

    // A small patch of ground diamonds around the center (raised by [lift]).
    for (final (int gx, int gy) in <(int, int)>[
      (-1, 0), (0, -1), (1, 0), (0, 1), (0, 0),
    ]) {
      final double dx = (gx - gy) * tw;
      final double dy = (gx + gy) * th;
      // Soil side-wall under each diamond gives the plateau visible thickness.
      if (lift > 0) {
        _sideWall(canvas, Offset(cx + dx, groundCy + dy), tw, th, lift, dark,
            p.outline);
      }
      _diamond(
          canvas, Offset(cx + dx, groundCy + dy), tw, th, top, dark, p.outline);
    }

    // The river: closer to the site the higher the flood risk. risk 0 -> far
    // edge, risk 1 -> right up against the site. The river stays at ground level
    // (cy), so a lifted plateau visibly sits ABOVE the water — reinforcing "high
    // and dry" for High Ground and "right by the water" for the Riverbank. A
    // closer/wider band is drawn for high-risk sites so the riverbank reads wet.
    final double dist = (1.0 - floodRisk.clamp(0.0, 1.0));
    final double riverGy = 1.4 + dist * 1.6; // 1.4 (near) .. 3.0 (far)
    // Riverbank (high risk) gets an extra band of water so the edge reads clearly.
    final List<double> bands =
        floodRisk >= 0.5 ? <double>[-0.9, 0.0, 0.9] : <double>[-0.6, 0.6];
    for (final double gx in bands) {
      final double dx = (gx - riverGy) * tw;
      final double dy = (gx + riverGy) * th;
      _diamond(canvas, Offset(cx + dx, cy + dy), tw, th, p.water, p.waterDeep,
          p.waterDeep.withValues(alpha: 0.4));
    }

    // A little hut marker on the center site tile (riding on the raised ground).
    final Paint hutBody = Paint()..color = p.highGroundDark;
    final Paint hutRoof = Paint()..color = p.woodDark;
    final Rect wall = Rect.fromLTWH(
      cx - tw * 0.34,
      groundCy - th * 0.6,
      tw * 0.68,
      th * 0.9,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(wall, Radius.circular(math.max(1.0, th * 0.2))),
      hutBody,
    );
    final Path roof = Path()
      ..moveTo(cx, groundCy - th * 1.4)
      ..lineTo(cx + tw * 0.5, groundCy - th * 0.3)
      ..lineTo(cx - tw * 0.5, groundCy - th * 0.3)
      ..close();
    canvas.drawPath(roof, hutRoof);
  }

  /// A soil side-wall under a ground diamond, giving a raised plateau visible
  /// thickness (only drawn for elevated terrains). [lift] is the wall height in
  /// px; the wall hangs from the diamond's lower-left/lower-right edges.
  void _sideWall(Canvas canvas, Offset c, double hw, double hh, double lift,
      Color dark, Color outline) {
    final Color wallTop = dark;
    final Color wallBot =
        Color.lerp(dark, const Color(0xFF000000), 0.35) ?? dark;
    // Left wall (bottom point -> left point) and right wall (bottom -> right).
    final Path left = Path()
      ..moveTo(c.dx - hw, c.dy)
      ..lineTo(c.dx, c.dy + hh)
      ..lineTo(c.dx, c.dy + hh + lift)
      ..lineTo(c.dx - hw, c.dy + lift)
      ..close();
    final Path right = Path()
      ..moveTo(c.dx, c.dy + hh)
      ..lineTo(c.dx + hw, c.dy)
      ..lineTo(c.dx + hw, c.dy + lift)
      ..lineTo(c.dx, c.dy + hh + lift)
      ..close();
    for (final (Path wall, double k) in <(Path, double)>[
      (left, 0.55),
      (right, 0.0),
    ]) {
      canvas.drawPath(
        wall,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color.lerp(wallTop, wallBot, k) ?? wallTop,
              wallBot,
            ],
          ).createShader(wall.getBounds()),
      );
      canvas.drawPath(
        wall,
        Paint()
          ..color = outline.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }
  }

  void _diamond(Canvas canvas, Offset c, double hw, double hh, Color top,
      Color dark, Color outline) {
    final Path path = Path()
      ..moveTo(c.dx, c.dy - hh)
      ..lineTo(c.dx + hw, c.dy)
      ..lineTo(c.dx, c.dy + hh)
      ..lineTo(c.dx - hw, c.dy)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[top, dark],
        ).createShader(path.getBounds()),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(_SiteThumbPainter old) =>
      old.terrain != terrain ||
      old.floodRisk != floodRisk ||
      old.palette != palette;
}
