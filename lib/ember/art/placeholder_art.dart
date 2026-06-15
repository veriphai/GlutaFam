// Ember — art/placeholder_art.dart
//
// The DEFAULT EmberArt: clean, attractive, fully-procedural placeholder art for
// EVERY semantic key the world + leaves request, PLUS the generic placeholder-
// primitive toolkit (rounded panels, chips, icon glyphs, gradient fills, simple
// shapes) activity scenes use for bespoke props.
//
// Design language is read entirely from [EmberPalette]/[EmberMetrics] so the
// look is consistent and a later sprite pass keeps the same tonal grammar.
//
// Presentation-only (art/): flame + flutter painting; NO clock/randomness in the
// instruction methods (they are pure functions of their args). The primitive
// components animate from Flame's own loop only.

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../animation/animated_actor.dart';
import '../animation/player_actor.dart';
import '../animation/programmatic_actor.dart';
import '../core/enums.dart';
import 'ember_art.dart';
import 'ember_palette.dart';

/// Programmatic placeholder art — the default [EmberArt] implementation.
class PlaceholderEmberArt implements EmberArt {
  const PlaceholderEmberArt({EmberPalette palette = EmberPalette.dusk})
      : _palette = palette;

  final EmberPalette _palette;

  @override
  EmberPalette get palette => _palette;

  // ===========================================================================
  // Tiles
  // ===========================================================================

  @override
  TileVisual tile(TerrainType t, {bool buildable = true, bool floodRisk = false}) {
    final (Color top, Color dark, Color side, TilePattern pat) = switch (t) {
      TerrainType.grass => (
          _palette.grass,
          _palette.grassDark,
          _palette.grassDark,
          TilePattern.blades,
        ),
      TerrainType.water => (
          _palette.water,
          _palette.waterDeep,
          _palette.waterDeep,
          TilePattern.ripples,
        ),
      TerrainType.forest => (
          _palette.forest,
          _palette.forestDark,
          _palette.forestDark,
          TilePattern.canopy,
        ),
      TerrainType.rocky => (
          _palette.rock,
          _palette.rockDark,
          _palette.rockDark,
          TilePattern.pebbles,
        ),
      TerrainType.highGround => (
          _palette.highGround,
          _palette.highGroundDark,
          _palette.highGroundDark,
          TilePattern.flat,
        ),
    };

    // Water reads flat; everything else gets a little iso thickness.
    final double depth = t == TerrainType.water ? 0.0 : EmberMetrics.tileDepth;

    Color? overlay;
    if (floodRisk) {
      overlay = _palette.danger.withValues(alpha: 0.16);
    } else if (!buildable && t != TerrainType.water) {
      overlay = _palette.outline.withValues(alpha: 0.10);
    }

    return TileVisual(
      top: top,
      topDark: dark,
      side: side,
      outline: _palette.outline.withValues(alpha: 0.45),
      depth: depth,
      overlay: overlay,
      pattern: pat,
    );
  }

  // ===========================================================================
  // Placeables
  // ===========================================================================

  @override
  PlaceableVisual placeable(
    PlaceableType type, {
    required PlaceableState state,
    int tier = 1,
  }) {
    final (
      Color body,
      Color bodyDark,
      Color accent,
      PlaceableSilhouette sil,
      double h,
      bool light,
      String label,
    ) = switch (type) {
      PlaceableType.hearth => (
          _palette.rock,
          _palette.rockDark,
          _palette.ember,
          PlaceableSilhouette.firePit,
          1.1,
          true,
          'Hearth',
        ),
      PlaceableType.cookingFire => (
          _palette.rock,
          _palette.rockDark,
          _palette.ember,
          PlaceableSilhouette.firePit,
          1.0,
          true,
          'Cook Fire',
        ),
      PlaceableType.torch => (
          _palette.wood,
          _palette.woodDark,
          _palette.emberBright,
          PlaceableSilhouette.pole,
          1.8,
          true,
          'Torch',
        ),
      PlaceableType.brazier => (
          _palette.rockDark,
          _palette.outline,
          _palette.ember,
          PlaceableSilhouette.bowl,
          1.5,
          true,
          'Brazier',
        ),
      PlaceableType.knappingStation => (
          _palette.stoneChip,
          _palette.rockDark,
          _palette.wood,
          PlaceableSilhouette.slab,
          0.9,
          false,
          'Knapping',
        ),
      PlaceableType.toolRack => (
          _palette.wood,
          _palette.woodDark,
          _palette.stoneChip,
          PlaceableSilhouette.rack,
          1.6,
          false,
          'Tool Rack',
        ),
      PlaceableType.leanTo => (
          _palette.hide,
          _palette.hideDark,
          _palette.wood,
          PlaceableSilhouette.leanFrame,
          1.4,
          false,
          'Lean-to',
        ),
      PlaceableType.hideTent => (
          _palette.hide,
          _palette.hideDark,
          _palette.woodDark,
          PlaceableSilhouette.cone,
          1.9,
          false,
          'Hide Tent',
        ),
      PlaceableType.hut => (
          // Warm THATCH/earth-brown body (was gray-tan highGround, which blended
          // with the gray boulder/cave domes lining the map so a hut read as
          // terrain). Wood-brown walls + a dark doorway accent give the hut a
          // distinct stone-age dwelling silhouette that separates from the rocks.
          _palette.hide,
          _palette.hideDark,
          _palette.woodDark,
          PlaceableSilhouette.dome,
          1.8,
          false,
          'Hut',
        ),
      PlaceableType.palisade => (
          _palette.woodDark,
          _palette.outline,
          _palette.wood,
          PlaceableSilhouette.fence,
          1.5,
          false,
          'Palisade',
        ),
    };

    // State modifies opacity + accent (ghost = translucent preview, building =
    // dim + scaffolded, damaged = desaturated/cracked, removed = invisible).
    double opacity;
    Color effAccent = accent;
    Color effBody = body;
    switch (state) {
      case PlaceableState.ghost:
        opacity = 0.45;
      case PlaceableState.building:
        opacity = 0.7;
        effAccent = _palette.inkSoft;
      case PlaceableState.built:
        opacity = 1.0;
      case PlaceableState.damaged:
        opacity = 0.9;
        effBody = Color.lerp(body, _palette.inkSoft, 0.35)!;
        effAccent = _palette.danger;
      case PlaceableState.removed:
        opacity = 0.0;
    }

    return PlaceableVisual(
      body: effBody,
      bodyDark: bodyDark,
      accent: effAccent,
      outline: _palette.outline,
      silhouette: sil,
      heightFactor: h * EmberMetrics.placeableStandFactor / 1.6,
      opacity: opacity,
      // Light only when actually built/lit (not while ghost/building/removed).
      emitsLight: light && state == PlaceableState.built,
      tierPips: (tier - 1).clamp(0, 3),
      label: label,
    );
  }

  // ===========================================================================
  // Nodes
  // ===========================================================================

  @override
  NodeVisual node(ResourceType t, {double remaining = 1.0}) {
    final double full = remaining.clamp(0.0, 1.0);
    final (Color fill, Color dark, NodeSilhouette sil) = switch (t) {
      ResourceType.wood => (
          _palette.forest,
          _palette.forestDark,
          NodeSilhouette.tree,
        ),
      ResourceType.stone => (
          _palette.rock,
          _palette.rockDark,
          NodeSilhouette.boulder,
        ),
      ResourceType.food => (
          _palette.food,
          _palette.emberDeep,
          NodeSilhouette.berryBush,
        ),
      ResourceType.hide => (
          _palette.hide,
          _palette.hideDark,
          NodeSilhouette.gameAnimal,
        ),
    };
    return NodeVisual(
      fill: fill,
      fillDark: dark,
      outline: _palette.outline,
      silhouette: sil,
      fullness: full,
      // Depleted nodes shrink a touch but never vanish (so they stay tappable).
      scale: 0.7 + 0.3 * full,
    );
  }

  // ===========================================================================
  // Actors
  // ===========================================================================

  @override
  AnimatedActor actor(ActorKind kind) =>
      ProgrammaticActor(kind, palette: _palette);

  @override
  AnimatedActor playerActor({bool reduceMotion = false}) =>
      PlayerActor(palette: _palette, reduceMotion: reduceMotion);

  // ===========================================================================
  // Sprite seam — the placeholder art has NO sprites, so every slot returns null
  // and each component keeps its programmatic draw.
  // ===========================================================================

  @override
  SpriteHandle? tileSprite(TerrainType t) => null;

  @override
  SpriteHandle? placeableSprite(PlaceableType type,
          {required PlaceableState state, int tier = 1}) =>
      null;

  @override
  SpriteHandle? nodeSprite(ResourceType t, {double remaining = 1.0}) => null;

  @override
  SpriteHandle? actorSprite(ActorKind kind, {int varietyKey = 0}) => null;

  @override
  SpriteHandle? playerSprite() => null;

  @override
  SpriteHandle? validRingSprite() => null;

  // ===========================================================================
  // Generic placeholder-primitive toolkit
  // ===========================================================================

  @override
  PositionComponent panel(PanelSpec spec) =>
      _PanelComponent(spec, _palette);

  @override
  PositionComponent chip(ChipSpec spec) => _ChipComponent(spec, _palette);

  @override
  PositionComponent icon(IconGlyph glyph, {double size = 24.0, Color? color}) =>
      _IconComponent(glyph, size, color ?? _palette.ink);

  @override
  PositionComponent shape(
    PrimitiveShape shape, {
    required Vector2 size,
    Color? fill,
    Color? outline,
  }) =>
      _ShapeComponent(
        shape,
        size,
        fill ?? _palette.surfaceRaised,
        outline ?? _palette.outline,
      );

  @override
  Paint verticalGradient(Color from, Color to, double extent) {
    return Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[from, to],
      ).createShader(Rect.fromLTWH(0, 0, 1, extent));
  }
}

// ===========================================================================
// Primitive toolkit components
// ===========================================================================

/// A rounded panel/card with soft vertical gradient, outline + optional shadow.
class _PanelComponent extends PositionComponent {
  _PanelComponent(this.spec, this.palette)
      : super(size: spec.size.clone());

  final PanelSpec spec;
  final EmberPalette palette;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final double radius = spec.radius ?? EmberMetrics.panelRadius;
    final Color fill = spec.fill ?? palette.surface;
    final Color fillTo =
        spec.fillTo ?? Color.lerp(fill, palette.outline, 0.12)!;
    final Color outline = spec.outline ?? palette.outline;
    final Rect r = size.toRect();
    final RRect rr = RRect.fromRectAndRadius(r, Radius.circular(radius));

    if (spec.elevation > 0) {
      final Rect sr = r.translate(0, spec.elevation * 0.6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(sr, Radius.circular(radius)),
        Paint()
          ..color = palette.shadow
          ..maskFilter = MaskFilter.blur(
              BlurStyle.normal, EmberMetrics.shadowBlur + spec.elevation),
      );
    }

    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[fill, fillTo],
        ).createShader(r),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = EmberMetrics.strokeWidth,
    );
  }
}

/// A small chip/pill with optional inline glyph.
class _ChipComponent extends PositionComponent {
  _ChipComponent(this.spec, this.palette) : super(size: spec.size.clone());

  final ChipSpec spec;
  final EmberPalette palette;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final Rect r = size.toRect();
    final RRect rr =
        RRect.fromRectAndRadius(r, const Radius.circular(EmberMetrics.chipRadius));
    canvas.drawRRect(rr, Paint()..color = spec.fill ?? palette.surfaceRaised);
    canvas.drawRRect(
      rr,
      Paint()
        ..color = spec.outline ?? palette.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = EmberMetrics.strokeWidth,
    );
    final IconGlyph? g = spec.glyph;
    if (g != null) {
      final double gs = math.min(size.x, size.y) * 0.62;
      canvas.save();
      canvas.translate((size.x - gs) / 2, (size.y - gs) / 2);
      IconPainter.paint(canvas, g, gs, spec.glyphColor ?? palette.ink);
      canvas.restore();
    }
  }
}

/// A standalone icon glyph.
class _IconComponent extends PositionComponent {
  _IconComponent(this.glyph, double s, this.color)
      : super(size: Vector2.all(s));

  final IconGlyph glyph;
  final Color color;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    IconPainter.paint(canvas, glyph, size.x, color);
  }
}

/// A simple filled primitive shape with outline.
class _ShapeComponent extends PositionComponent {
  _ShapeComponent(this.shape, Vector2 s, this.fill, this.outline)
      : super(size: s.clone());

  final PrimitiveShape shape;
  final Color fill;
  final Color outline;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final Rect r = size.toRect();
    final Paint fillP = Paint()..color = fill;
    final Paint lineP = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = EmberMetrics.strokeWidth;
    switch (shape) {
      case PrimitiveShape.circle:
        final double rad = math.min(size.x, size.y) / 2;
        canvas.drawCircle(r.center, rad, fillP);
        canvas.drawCircle(r.center, rad, lineP);
      case PrimitiveShape.roundedRect:
        final RRect rr = RRect.fromRectAndRadius(
            r, const Radius.circular(EmberMetrics.chipRadius));
        canvas.drawRRect(rr, fillP);
        canvas.drawRRect(rr, lineP);
      case PrimitiveShape.diamond:
        final Path p = _diamond(r);
        canvas.drawPath(p, fillP);
        canvas.drawPath(p, lineP);
      case PrimitiveShape.triangle:
        final Path p = Path()
          ..moveTo(r.center.dx, r.top)
          ..lineTo(r.right, r.bottom)
          ..lineTo(r.left, r.bottom)
          ..close();
        canvas.drawPath(p, fillP);
        canvas.drawPath(p, lineP);
      case PrimitiveShape.ring:
        final double rad = math.min(size.x, size.y) / 2;
        canvas.drawCircle(
          r.center,
          rad - lineP.strokeWidth,
          Paint()
            ..color = outline
            ..style = PaintingStyle.stroke
            ..strokeWidth = rad * 0.28,
        );
      case PrimitiveShape.blob:
        canvas.drawPath(_blob(r), fillP);
        canvas.drawPath(_blob(r), lineP);
    }
  }

  Path _diamond(Rect r) => Path()
    ..moveTo(r.center.dx, r.top)
    ..lineTo(r.right, r.center.dy)
    ..lineTo(r.center.dx, r.bottom)
    ..lineTo(r.left, r.center.dy)
    ..close();

  Path _blob(Rect r) {
    final double cx = r.center.dx;
    final double cy = r.center.dy;
    final double rx = r.width / 2;
    final double ry = r.height / 2;
    return Path()
      ..moveTo(cx, cy - ry)
      ..cubicTo(cx + rx, cy - ry, cx + rx, cy + ry * 0.6, cx, cy + ry)
      ..cubicTo(cx - rx, cy + ry * 0.6, cx - rx, cy - ry, cx, cy - ry)
      ..close();
  }
}

/// Pure vector icon painter for the closed [IconGlyph] set (no font dep).
/// Draws into a [size]x[size] box at the canvas origin.
class IconPainter {
  const IconPainter._();

  static void paint(Canvas canvas, IconGlyph glyph, double s, Color color) {
    final Paint fill = Paint()..color = color;
    final Paint line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final double c = s / 2;

    switch (glyph) {
      case IconGlyph.flame:
        final Path p = Path()
          ..moveTo(c, s * 0.05)
          ..quadraticBezierTo(s * 0.92, s * 0.5, c, s * 0.95)
          ..quadraticBezierTo(s * 0.08, s * 0.5, c, s * 0.05)
          ..close();
        canvas.drawPath(p, fill);
      case IconGlyph.wood:
        for (final double dx in <double>[-s * 0.18, s * 0.18]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(c + dx - s * 0.07, s * 0.15, s * 0.14, s * 0.7),
              Radius.circular(s * 0.06),
            ),
            fill,
          );
        }
      case IconGlyph.stone:
        canvas.drawPath(_pebble(s), fill);
      case IconGlyph.food:
        canvas.drawCircle(Offset(c, c + s * 0.05), s * 0.32, fill);
        canvas.drawLine(
            Offset(c, c - s * 0.28), Offset(c + s * 0.12, s * 0.06), line);
      case IconGlyph.hide:
        canvas.drawPath(_blobPath(s), fill);
      case IconGlyph.hammer:
        canvas.drawRect(
            Rect.fromLTWH(s * 0.2, s * 0.12, s * 0.6, s * 0.22), fill);
        canvas.drawRect(
            Rect.fromLTWH(c - s * 0.06, s * 0.3, s * 0.12, s * 0.58), fill);
      case IconGlyph.tent:
        final Path p = Path()
          ..moveTo(c, s * 0.12)
          ..lineTo(s * 0.9, s * 0.88)
          ..lineTo(s * 0.1, s * 0.88)
          ..close();
        canvas.drawPath(p, fill);
        canvas.drawLine(
            Offset(c, s * 0.12), Offset(c, s * 0.88), line..color = color);
      case IconGlyph.hut:
        final Path roof = Path()
          ..moveTo(c, s * 0.12)
          ..lineTo(s * 0.9, s * 0.45)
          ..lineTo(s * 0.1, s * 0.45)
          ..close();
        canvas.drawPath(roof, fill);
        canvas.drawRect(
            Rect.fromLTWH(s * 0.22, s * 0.45, s * 0.56, s * 0.42), fill);
      case IconGlyph.spark:
        for (int i = 0; i < 4; i++) {
          final double a = i * math.pi / 2;
          canvas.drawLine(
            Offset(c, c),
            Offset(c + math.cos(a) * c * 0.85, c + math.sin(a) * c * 0.85),
            line,
          );
        }
      case IconGlyph.drop:
        final Path p = Path()
          ..moveTo(c, s * 0.08)
          ..quadraticBezierTo(s * 0.92, s * 0.62, c, s * 0.92)
          ..quadraticBezierTo(s * 0.08, s * 0.62, c, s * 0.08)
          ..close();
        canvas.drawPath(p, fill);
      case IconGlyph.sun:
        canvas.drawCircle(Offset(c, c), s * 0.24, fill);
        for (int i = 0; i < 8; i++) {
          final double a = i * math.pi / 4;
          canvas.drawLine(
            Offset(c + math.cos(a) * s * 0.32, c + math.sin(a) * s * 0.32),
            Offset(c + math.cos(a) * s * 0.45, c + math.sin(a) * s * 0.45),
            line,
          );
        }
      case IconGlyph.moon:
        final Path p = Path()
          ..addOval(Rect.fromCircle(center: Offset(c, c), radius: s * 0.34))
          ..addOval(Rect.fromCircle(
              center: Offset(c + s * 0.16, c - s * 0.05), radius: s * 0.30))
          ..fillType = PathFillType.evenOdd;
        canvas.drawPath(p, fill);
      case IconGlyph.check:
        final Path p = Path()
          ..moveTo(s * 0.2, c)
          ..lineTo(s * 0.42, s * 0.72)
          ..lineTo(s * 0.82, s * 0.26);
        canvas.drawPath(p, line);
      case IconGlyph.cross:
        canvas.drawLine(
            Offset(s * 0.22, s * 0.22), Offset(s * 0.78, s * 0.78), line);
        canvas.drawLine(
            Offset(s * 0.78, s * 0.22), Offset(s * 0.22, s * 0.78), line);
      case IconGlyph.arrowUp:
        _arrow(canvas, line, fill, s, up: true);
      case IconGlyph.arrowDown:
        _arrow(canvas, line, fill, s, up: false);
      case IconGlyph.plus:
        canvas.drawLine(Offset(c, s * 0.2), Offset(c, s * 0.8), line);
        canvas.drawLine(Offset(s * 0.2, c), Offset(s * 0.8, c), line);
      case IconGlyph.minus:
        canvas.drawLine(Offset(s * 0.2, c), Offset(s * 0.8, c), line);
      case IconGlyph.question:
        final Path p = Path()
          ..moveTo(s * 0.32, s * 0.34)
          ..quadraticBezierTo(s * 0.32, s * 0.14, c, s * 0.14)
          ..quadraticBezierTo(s * 0.7, s * 0.14, s * 0.7, s * 0.36)
          ..quadraticBezierTo(s * 0.7, s * 0.52, c, s * 0.58)
          ..lineTo(c, s * 0.66);
        canvas.drawPath(p, line);
        canvas.drawCircle(Offset(c, s * 0.82), s * 0.06, fill);
      case IconGlyph.star:
        canvas.drawPath(_star(s), fill);
      case IconGlyph.heart:
        final Path p = Path()
          ..moveTo(c, s * 0.85)
          ..cubicTo(s * 0.0, s * 0.5, s * 0.18, s * 0.12, c, s * 0.34)
          ..cubicTo(s * 0.82, s * 0.12, s * 1.0, s * 0.5, c, s * 0.85)
          ..close();
        canvas.drawPath(p, fill);
      case IconGlyph.paw:
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(c, s * 0.66), width: s * 0.5, height: s * 0.4),
            fill);
        for (final double dx in <double>[-0.26, -0.09, 0.09, 0.26]) {
          canvas.drawCircle(
              Offset(c + dx * s, s * 0.32), s * 0.09, fill);
        }
      case IconGlyph.person:
        canvas.drawCircle(Offset(c, s * 0.28), s * 0.16, fill);
        final Path body = Path()
          ..moveTo(s * 0.24, s * 0.9)
          ..quadraticBezierTo(c, s * 0.46, s * 0.76, s * 0.9)
          ..close();
        canvas.drawPath(body, fill);
      case IconGlyph.leaf:
        final Path p = Path()
          ..moveTo(s * 0.2, s * 0.8)
          ..quadraticBezierTo(s * 0.2, s * 0.2, s * 0.8, s * 0.2)
          ..quadraticBezierTo(s * 0.8, s * 0.8, s * 0.2, s * 0.8)
          ..close();
        canvas.drawPath(p, fill);
        canvas.drawLine(
            Offset(s * 0.2, s * 0.8), Offset(s * 0.65, s * 0.35), line);
    }
  }

  static void _arrow(Canvas canvas, Paint line, Paint fill, double s,
      {required bool up}) {
    final double c = s / 2;
    final double tip = up ? s * 0.18 : s * 0.82;
    final double tail = up ? s * 0.82 : s * 0.18;
    canvas.drawLine(Offset(c, tail), Offset(c, tip), line);
    final Path head = Path()..moveTo(c, tip);
    if (up) {
      head
        ..lineTo(c - s * 0.2, tip + s * 0.24)
        ..lineTo(c + s * 0.2, tip + s * 0.24);
    } else {
      head
        ..lineTo(c - s * 0.2, tip - s * 0.24)
        ..lineTo(c + s * 0.2, tip - s * 0.24);
    }
    head.close();
    canvas.drawPath(head, fill);
  }

  static Path _pebble(double s) {
    final double c = s / 2;
    return Path()
      ..moveTo(c, s * 0.22)
      ..cubicTo(s * 0.86, s * 0.22, s * 0.9, s * 0.7, c, s * 0.8)
      ..cubicTo(s * 0.14, s * 0.78, s * 0.12, s * 0.3, c, s * 0.22)
      ..close();
  }

  static Path _blobPath(double s) {
    final double c = s / 2;
    return Path()
      ..moveTo(s * 0.2, s * 0.35)
      ..quadraticBezierTo(c, s * 0.05, s * 0.82, s * 0.32)
      ..quadraticBezierTo(s * 0.95, s * 0.7, s * 0.6, s * 0.9)
      ..quadraticBezierTo(s * 0.15, s * 0.92, s * 0.08, s * 0.55)
      ..close();
  }

  static Path _star(double s) {
    final double c = s / 2;
    final double rOuter = s * 0.42;
    final double rInner = s * 0.18;
    final Path p = Path();
    for (int i = 0; i < 10; i++) {
      final double r = i.isEven ? rOuter : rInner;
      final double a = -math.pi / 2 + i * math.pi / 5;
      final Offset pt = Offset(c + math.cos(a) * r, c + math.sin(a) * r);
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    return p..close();
  }
}
