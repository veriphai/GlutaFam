// Ember — game/components/placeable_component.dart
//
// The base on-screen component for a placed object. Binds ONE generic
// [Placeable] doc, positions it by its grid coord (via IsoProjection), and
// renders it from the [EmberArt] facade by kind/tier/state. It is deliberately
// SUBCLASSABLE: concept leaves (fire/tools/shelter) extend this to add bespoke
// behaviour visuals (a fire glow, a tool-rack pip, a smoking hut) WITHOUT
// touching the engine. Subclasses override the protected hooks:
//   * [paintUnder]   — draw behind the silhouette (e.g. a warm light pool),
//   * [paintOver]    — draw in front (e.g. flames, sparks, smoke),
//   * [onPlaceableChanged] — react when the bound doc updates each snapshot,
//   * [extraScale]   — animate a per-frame scale (e.g. a fire's breathing).
// It is tappable (TapCallbacks) and reports taps via [onTapped] so the world
// layer can route an Intent (tend fire, open info) — the base never mutates.
//
// Read-only + dispatch only: the component reads the world via [BridgedComponent]
// and dispatches Intents; it NEVER mutates world state directly.

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

import '../../art/ember_art.dart';
import '../../art/ember_palette.dart';
import '../../art/sprite_compositor.dart';
import '../../core/geometry.dart';
import '../../core/ids.dart';
import '../../data/models/placeable.dart';
import '../ember_game.dart';
import '../iso/iso_projection.dart';
import '../riverpod_flame_bridge.dart';

/// Base component for a placed object. Leaves subclass for bespoke visuals.
class PlaceableComponent extends PositionComponent
    with HasGameReference<EmberGame>, BridgedComponent, TapCallbacks {
  PlaceableComponent({
    required this.placeableId,
    this.projection = IsoProjection.standard,
  }) : super(anchor: Anchor.bottomCenter);

  /// The id of the bound [Placeable] (the doc lives in world state; this view
  /// re-reads it each snapshot so it always reflects the source of truth).
  final EntityId placeableId;

  final IsoProjection projection;

  /// The last-read doc (kept so leaves can read typed views off `ext`).
  Placeable? _doc;

  /// The current art instruction for the bound doc (recomputed on change).
  PlaceableVisual? _visual;

  /// A one-time "placed!" highlight: when a placeable first appears BUILT, a brief
  /// expanding ring + glow plays so the camp -> tooled -> sheltered progression
  /// reads ("a new structure just went up here"). 0 = idle; counts UP to
  /// [_placedPulseDuration] while playing. Presentation only (Flame loop).
  double _placedPulse = 0.0;
  static const double _placedPulseDuration = 0.9;

  /// Whether we have already seen this doc at least once (so we only pulse on the
  /// FIRST built appearance, not on every later snapshot/edit).
  bool _seenBuilt = false;

  /// Whether the FIRST world sync has happened. We suppress the placed-pulse on
  /// the very first sync so structures LOADED FROM SAVE (already built when the
  /// world mounts) don't all flash on app open — only structures that go up DURING
  /// the session (placed/built while we watch) pulse.
  bool _firstSyncDone = false;

  /// Optional tap callback the world layer wires (e.g. tend fire). The base
  /// never mutates; routing is the world layer's job.
  void Function(Placeable doc)? onTapped;

  EmberArt get art => game.art;
  EmberPalette get palette => art.palette;

  /// The bound doc (null only before first sync / after removal).
  Placeable? get doc => _doc;

  /// The current art instruction (null before first sync).
  PlaceableVisual? get visual => _visual;

  @override
  Future<void> onLoad() async {
    listenWorld(_sync, fireImmediately: true);
  }

  void _sync() {
    final Placeable? next = bridge.state.placeableById(placeableId);
    if (next == null) {
      // The doc was removed from the world — retire this component.
      removeFromParent();
      return;
    }
    final bool changed = next != _doc;
    _doc = next;
    _visual = art.placeable(next.type, state: next.state, tier: next.tier);
    _positionForCoord(next.coord);
    // Fire the one-time "placed!" pulse the first snapshot this object is BUILT —
    // but NOT on the very first sync (that would flash save-loaded structures on
    // app open). So a structure that goes up while we watch (build-tutorial finish
    // or a debug drop into the live world) pulses; pre-existing ones don't.
    if (!_seenBuilt && next.isBuilt) {
      _seenBuilt = true;
      if (_firstSyncDone) _placedPulse = _placedPulseDuration;
    }
    _firstSyncDone = true;
    if (changed) onPlaceableChanged(next);
  }

  void _positionForCoord(GridCoord coord) {
    final Vector2 center = projection.gridToScreen(coord);
    // Anchor at the diamond's bottom point so the figure "stands" on the tile.
    position = Vector2(center.x, center.y + projection.halfTileHeight);
    // A standing figure's box is ~1 tile wide; height scales with the visual.
    final double stand = (_visual?.heightFactor ?? 1.0) * EmberMetrics.tileHeight;
    size = Vector2(projection.tileWidth * 0.8, stand);
    priority = projection.depthSortKey(coord, heightBias: 1);
  }

  // ===========================================================================
  // Protected hooks for leaf subclasses
  // ===========================================================================

  /// Override to react to the bound doc changing (tier up, state change, a new
  /// ext payload). Default: no-op.
  void onPlaceableChanged(Placeable doc) {}

  /// Override to paint BEHIND the silhouette (e.g. a warm light pool). Canvas is
  /// already translated to the component's local space (origin bottom-center).
  void paintUnder(Canvas canvas, Placeable doc, PlaceableVisual v) {}

  /// Override to paint IN FRONT of the silhouette (e.g. flames, smoke, sparks).
  void paintOver(Canvas canvas, Placeable doc, PlaceableVisual v) {}

  /// Override to animate a per-frame uniform scale (e.g. a fire's breathing).
  /// Default 1.0.
  double extraScale() => 1.0;

  @override
  void update(double dt) {
    super.update(dt);
    if (_placedPulse > 0) {
      _placedPulse = math.max(0.0, _placedPulse - dt);
    }
  }

  // ===========================================================================
  // Rendering
  // ===========================================================================

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final Placeable? doc = _doc;
    final PlaceableVisual? v = _visual;
    if (doc == null || v == null) return;
    if (v.opacity <= 0) return; // removed.

    canvas.save();
    // Local origin is bottom-center of the box; draw upward from there.
    canvas.translate(size.x / 2, size.y);
    final double s = extraScale();
    if (s != 1.0) canvas.scale(s, s);

    _paintPlacedPulse(canvas);
    paintUnder(canvas, doc, v);
    _paintSilhouette(canvas, doc, v);
    paintOver(canvas, doc, v);

    canvas.restore();
  }

  /// The one-time "placed!" highlight: an expanding ground ring + a soft warm glow
  /// that fades over [_placedPulseDuration], so a newly-built structure visibly
  /// "lands" (the progression read). Drawn at the base, beneath the silhouette.
  void _paintPlacedPulse(Canvas canvas) {
    if (_placedPulse <= 0) return;
    // t goes 0 (just placed) -> 1 (faded out).
    final double t = 1.0 - (_placedPulse / _placedPulseDuration);
    final double fade = (1.0 - t).clamp(0.0, 1.0);
    final double r = size.x * (0.25 + 0.45 * t);

    // Expanding ground ring (squashed to sit on the iso tile).
    canvas.save();
    canvas.scale(1.0, 0.5);
    canvas.drawCircle(
      const Offset(0, -4),
      r,
      Paint()
        ..color = palette.spark.withValues(alpha: 0.55 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.restore();

    // A soft warm glow pop on the body.
    canvas.drawCircle(
      Offset(0, -size.y * 0.3),
      size.x * 0.5 * (0.7 + 0.3 * t),
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: <Color>[
            palette.emberBright.withValues(alpha: 0.22 * fade),
            palette.ember.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(
              center: Offset(0, -size.y * 0.3), radius: size.x * 0.5),
        ),
    );
  }

  /// Draws the closed silhouette family with the art-supplied colours, scaled to
  /// the component box, honouring ghost/building/damaged opacity + tier pips.
  void _paintSilhouette(Canvas canvas, Placeable doc, PlaceableVisual v) {
    final double bw = size.x * 0.7; // body width
    final double bh = size.y * 0.9; // body height
    final double op = v.opacity;

    final Paint shadow = Paint()
      ..color = palette.shadow.withValues(alpha: palette.shadow.a * op)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -2), width: bw, height: bh * 0.12),
      shadow,
    );

    // SPRITE PATH: when the facade serves a placeable sprite for this kind/state,
    // draw it bottom-center (its baked grass base overlaps the tile) instead of
    // the programmatic silhouette. The contact shadow above + the placed-pulse +
    // tier pips + leaf paintUnder/paintOver still composite around it. ghost is
    // rendered translucent via the visual opacity (the GhostComponent has its own
    // tinted preview; this base only ever sees built/building/damaged/removed).
    final SpriteHandle? sprite =
        art.placeableSprite(doc.type, state: doc.state, tier: doc.tier);
    if (sprite != null) {
      SpriteCompositor.drawBottomCenter(
        canvas,
        sprite,
        tileWidth: projection.tileWidth,
        opacity: op,
      );
      // Tier pips along the base (kept from the programmatic path).
      if (v.tierPips > 0) {
        final Paint pip = Paint()..color = palette.spark.withValues(alpha: op);
        for (int i = 0; i < v.tierPips; i++) {
          canvas.drawCircle(Offset(-bw * 0.3 + i * 6.0, 4), 2.0, pip);
        }
      }
      return;
    }

    final Paint body = Paint()..color = v.body.withValues(alpha: op);
    final Paint bodyDark = Paint()..color = v.bodyDark.withValues(alpha: op);
    final Paint accent = Paint()..color = v.accent.withValues(alpha: op);
    final Paint outline = Paint()
      ..color = v.outline.withValues(alpha: op)
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

    // Tier pips along the base.
    if (v.tierPips > 0) {
      final Paint pip = Paint()..color = palette.spark.withValues(alpha: op);
      for (int i = 0; i < v.tierPips; i++) {
        canvas.drawCircle(Offset(-bw * 0.3 + i * 6.0, 4), 2.0, pip);
      }
    }
  }

  // ===========================================================================
  // Input
  // ===========================================================================

  @override
  void onTapDown(TapDownEvent event) {
    final Placeable? doc = _doc;
    if (doc == null) return;
    onTapped?.call(doc);
  }
}

/// Pure painter for the closed [PlaceableSilhouette] set. Draws upward from a
/// bottom-center origin into a [w]x[h] box. Kept separate so leaf subclasses can
/// reuse it for ghost/upgraded variants without re-deriving geometry.
class PlaceableSilhouettePainter {
  const PlaceableSilhouettePainter._();

  static void paint(
    Canvas canvas,
    PlaceableSilhouette sil,
    double w,
    double h, {
    required Paint body,
    required Paint bodyDark,
    required Paint accent,
    required Paint outline,
  }) {
    switch (sil) {
      case PlaceableSilhouette.firePit:
        _firePit(canvas, w, h, body, bodyDark, accent, outline);
      case PlaceableSilhouette.pole:
        _pole(canvas, w, h, body, bodyDark, accent, outline);
      case PlaceableSilhouette.bowl:
        _bowl(canvas, w, h, body, bodyDark, accent, outline);
      case PlaceableSilhouette.slab:
        _slab(canvas, w, h, body, bodyDark, accent, outline);
      case PlaceableSilhouette.rack:
        _rack(canvas, w, h, body, bodyDark, accent, outline);
      case PlaceableSilhouette.leanFrame:
        _leanFrame(canvas, w, h, body, bodyDark, accent, outline);
      case PlaceableSilhouette.cone:
        _cone(canvas, w, h, body, bodyDark, accent, outline);
      case PlaceableSilhouette.dome:
        _dome(canvas, w, h, body, bodyDark, accent, outline);
      case PlaceableSilhouette.fence:
        _fence(canvas, w, h, body, bodyDark, accent, outline);
    }
  }

  // Each helper draws relative to bottom-center origin (y grows upward = -y).

  static void _firePit(Canvas c, double w, double h, Paint body, Paint dark,
      Paint accent, Paint outline) {
    // Ring of stones (ellipse) with an accent flame nub.
    final Rect ring = Rect.fromCenter(
        center: const Offset(0, -6), width: w * 0.9, height: h * 0.34);
    c.drawOval(ring, dark);
    c.drawOval(ring.deflate(3), body);
    c.drawOval(ring, outline);
    // Small flame nub at center (leaves usually paintOver a real flame).
    final Path nub = Path()
      ..moveTo(0, -h * 0.18)
      ..quadraticBezierTo(w * 0.12, -h * 0.05, 0, -h * 0.02)
      ..quadraticBezierTo(-w * 0.12, -h * 0.05, 0, -h * 0.18)
      ..close();
    c.drawPath(nub, accent);
  }

  static void _pole(Canvas c, double w, double h, Paint body, Paint dark,
      Paint accent, Paint outline) {
    final Rect shaft =
        Rect.fromLTWH(-w * 0.06, -h, w * 0.12, h * 0.92);
    final RRect rr = RRect.fromRectAndRadius(shaft, const Radius.circular(3));
    c.drawRRect(rr, body);
    c.drawRRect(rr, outline);
    // Accent ember at the top.
    c.drawCircle(Offset(0, -h * 0.96), w * 0.16, accent);
  }

  static void _bowl(Canvas c, double w, double h, Paint body, Paint dark,
      Paint accent, Paint outline) {
    // Legs.
    for (final double dx in <double>[-w * 0.28, w * 0.28]) {
      c.drawLine(Offset(dx, 0), Offset(dx * 0.5, -h * 0.55),
          outline..strokeWidth = 3);
    }
    // Bowl.
    final Rect bowl = Rect.fromCenter(
        center: Offset(0, -h * 0.6), width: w * 0.8, height: h * 0.3);
    final Path bowlPath = Path()
      ..moveTo(bowl.left, bowl.top)
      ..lineTo(bowl.right, bowl.top)
      ..lineTo(bowl.right - w * 0.1, bowl.bottom)
      ..lineTo(bowl.left + w * 0.1, bowl.bottom)
      ..close();
    c.drawPath(bowlPath, body);
    c.drawPath(bowlPath, outline..strokeWidth = EmberMetrics.strokeWidth);
    c.drawCircle(Offset(0, -h * 0.7), w * 0.16, accent);
  }

  static void _slab(Canvas c, double w, double h, Paint body, Paint dark,
      Paint accent, Paint outline) {
    final Rect slab = Rect.fromCenter(
        center: Offset(0, -h * 0.2), width: w * 0.95, height: h * 0.3);
    final RRect rr = RRect.fromRectAndRadius(slab, const Radius.circular(5));
    c.drawRRect(rr, body);
    c.drawRRect(rr.deflate(3), dark);
    c.drawRRect(rr, outline);
    // A knapping flake (accent) sitting on top.
    c.drawCircle(Offset(w * 0.18, -h * 0.36), w * 0.1, accent);
  }

  static void _rack(Canvas c, double w, double h, Paint body, Paint dark,
      Paint accent, Paint outline) {
    // A-frame: two crossed poles + a crossbar.
    final Paint pole = Paint()
      ..color = body.color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    c.drawLine(Offset(-w * 0.32, 0), Offset(0, -h), pole);
    c.drawLine(Offset(w * 0.32, 0), Offset(0, -h), pole);
    c.drawLine(Offset(-w * 0.2, -h * 0.5), Offset(w * 0.2, -h * 0.5),
        pole..color = accent.color);
    // Hanging tool (accent).
    c.drawCircle(Offset(0, -h * 0.42), w * 0.08, accent);
  }

  static void _leanFrame(Canvas c, double w, double h, Paint body, Paint dark,
      Paint accent, Paint outline) {
    // Single-pitch slanted roof.
    final Path roof = Path()
      ..moveTo(-w * 0.5, 0)
      ..lineTo(w * 0.5, -h)
      ..lineTo(w * 0.5, -h * 0.7)
      ..lineTo(-w * 0.5, -h * 0.15)
      ..close();
    c.drawPath(roof, body);
    c.drawPath(roof, outline);
    // Support post.
    c.drawLine(Offset(w * 0.46, 0), Offset(w * 0.46, -h),
        outline..strokeWidth = 3);
  }

  static void _cone(Canvas c, double w, double h, Paint body, Paint dark,
      Paint accent, Paint outline) {
    final Path tent = Path()
      ..moveTo(0, -h)
      ..lineTo(w * 0.45, 0)
      ..lineTo(-w * 0.45, 0)
      ..close();
    c.drawPath(tent, body);
    // Shaded right half.
    final Path shade = Path()
      ..moveTo(0, -h)
      ..lineTo(w * 0.45, 0)
      ..lineTo(0, 0)
      ..close();
    c.drawPath(shade, dark);
    c.drawPath(tent, outline);
    // Door flap (accent).
    final Path door = Path()
      ..moveTo(0, -h * 0.45)
      ..lineTo(w * 0.12, 0)
      ..lineTo(-w * 0.12, 0)
      ..close();
    c.drawPath(door, accent);
  }

  static void _dome(Canvas c, double w, double h, Paint body, Paint dark,
      Paint accent, Paint outline) {
    final Rect domeRect =
        Rect.fromCenter(center: Offset(0, -h * 0.35), width: w, height: h * 1.3);
    // Half-dome (upper arc) sitting on the ground.
    final Path dome = Path()
      ..moveTo(-w * 0.5, 0)
      ..arcTo(domeRect, math.pi, math.pi, false)
      ..close();
    c.drawPath(dome, body);
    // Shaded right side.
    final Path shade = Path()
      ..moveTo(0, -h * 0.78)
      ..arcTo(domeRect, -math.pi / 2, math.pi / 2, false)
      ..lineTo(0, 0)
      ..close();
    c.drawPath(shade, dark);

    // Thatch ribs: a few concentric arcs hugging the dome so the hut reads as a
    // woven THATCH dwelling, not a smooth boulder — the main "hut vs rock" tell.
    final Paint thatch = Paint()
      ..color = outline.color.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    c.save();
    c.clipPath(dome);
    for (final double f in <double>[0.78, 0.55, 0.32]) {
      final Rect ribRect = Rect.fromCenter(
          center: Offset(0, -h * 0.35), width: w * f, height: h * 1.3 * f);
      c.drawArc(ribRect, math.pi, math.pi, false, thatch);
    }
    c.restore();

    c.drawPath(dome, outline);

    // A pronounced dark DOORWAY (a clear stone-age dwelling tell): a filled
    // arched opening at the base centre, outlined so it reads at default zoom.
    final Rect door = Rect.fromCenter(
        center: Offset(0, -h * 0.16), width: w * 0.30, height: h * 0.32);
    final Path doorway = Path()
      ..moveTo(door.left, 0)
      ..lineTo(door.left, door.center.dy)
      ..arcTo(door, math.pi, math.pi, false)
      ..lineTo(door.right, 0)
      ..close();
    c.drawPath(doorway, Paint()..color = accent.color);
    c.drawPath(
      doorway,
      Paint()
        ..color = outline.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  static void _fence(Canvas c, double w, double h, Paint body, Paint dark,
      Paint accent, Paint outline) {
    final double n = 4;
    final double gap = w / n;
    for (int i = 0; i < n; i++) {
      final double x = -w * 0.5 + gap * (i + 0.5);
      final Path stake = Path()
        ..moveTo(x - 3, 0)
        ..lineTo(x + 3, 0)
        ..lineTo(x + 3, -h * 0.85)
        ..lineTo(x, -h)
        ..lineTo(x - 3, -h * 0.85)
        ..close();
      c.drawPath(stake, body);
      c.drawPath(stake, outline);
    }
    // Lashing rope (accent).
    c.drawLine(Offset(-w * 0.5, -h * 0.6), Offset(w * 0.5, -h * 0.6),
        accent..strokeWidth = 2..style = PaintingStyle.stroke);
  }
}
