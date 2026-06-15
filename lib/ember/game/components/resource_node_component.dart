// Ember — game/components/resource_node_component.dart
//
// A tappable, gatherable resource node. Renders from the [EmberArt] facade
// (NodeVisual by type + remaining), shrinks/dims as it depletes, and on tap
// dispatches a [GatherIntent] (the ONLY way it touches the sim). The visible
// yield-per-tap reflects the EFFECTIVE gather modifier read through the
// registry, so a tool-rack boost shows up on the floating "+N" without this
// component knowing a leaf exists.
//
// Read-only + dispatch only: it reads the bound node each snapshot and emits an
// intent on tap; it NEVER mutates world state.

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

import '../../art/ember_art.dart';
import '../../art/ember_palette.dart';
import '../../art/sprite_compositor.dart';
import '../../core/geometry.dart';
import '../../core/ids.dart';
import '../../data/models/resource_node.dart';
import '../../state/intents.dart';
import '../ember_game.dart';
import '../iso/iso_projection.dart';
import '../riverpod_flame_bridge.dart';

/// On-screen gatherable node bound to a [ResourceNode] doc by id.
class ResourceNodeComponent extends PositionComponent
    with HasGameReference<EmberGame>, BridgedComponent, TapCallbacks {
  ResourceNodeComponent({
    required this.nodeId,
    this.projection = IsoProjection.standard,
  }) : super(anchor: Anchor.bottomCenter);

  final EntityId nodeId;
  final IsoProjection projection;

  ResourceNode? _doc;
  NodeVisual? _visual;

  /// A short-lived floating "+N" pop after a successful gather (seconds left).
  double _popTtl = 0;
  int _popAmount = 0;

  /// A tap-bounce scale animation (seconds left).
  double _bounceTtl = 0;

  EmberArt get art => game.art;
  EmberPalette get palette => art.palette;

  ResourceNode? get doc => _doc;

  /// A stable per-node variation in [-1, 1] derived from the id (presentation
  /// only — no sim impact). Gives the forest/rock fields size + tint variety so
  /// they read as a real forest, not identical wallpaper lollipops.
  late final double _variation =
      ((nodeId.hashCode % 1000) / 500.0) - 1.0;

  @override
  Future<void> onLoad() async {
    listenWorld(_sync, fireImmediately: true);
  }

  void _sync() {
    final ResourceNode? next = bridge.state.nodeById(nodeId);
    if (next == null) {
      removeFromParent();
      return;
    }
    // Detect a successful gather (remaining dropped) to fire the +N pop.
    final ResourceNode? prev = _doc;
    if (prev != null && next.remaining < prev.remaining) {
      _popAmount = (prev.remaining - next.remaining).round();
      _popTtl = 0.9;
    }
    _doc = next;
    final double full = next.effectiveCapacity <= 0
        ? 0
        : (next.remaining / next.effectiveCapacity).clamp(0.0, 1.0);
    _visual = art.node(next.type, remaining: full);
    _positionForCoord(next.coord);
  }

  void _positionForCoord(GridCoord coord) {
    final Vector2 center = projection.gridToScreen(coord);
    position = Vector2(center.x, center.y + projection.halfTileHeight);
    size = Vector2(projection.tileWidth * 0.7, projection.tileHeight * 1.6);
    priority = projection.depthSortKey(coord, heightBias: 1);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_popTtl > 0) _popTtl = math.max(0, _popTtl - dt);
    if (_bounceTtl > 0) _bounceTtl = math.max(0, _bounceTtl - dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final ResourceNode? doc = _doc;
    final NodeVisual? v = _visual;
    if (doc == null || v == null) return;

    canvas.save();
    canvas.translate(size.x / 2, size.y);

    // Tap bounce.
    if (_bounceTtl > 0) {
      final double t = _bounceTtl / 0.18;
      final double s = 1.0 + 0.12 * math.sin(t * math.pi);
      canvas.scale(s, s);
    }

    // Per-node size variation (+-12%) so the forest/rock field has volume and
    // depth instead of identical silhouettes. Stable per id (no sim impact).
    final double sizeJitter = 1.0 + 0.12 * _variation;
    final double bw = size.x * v.scale * sizeJitter;
    final double bh = size.y * 0.85 * v.scale * sizeJitter;
    final double dim = doc.isDepleted ? 0.5 : 1.0;

    // Per-node tint shift (+-8% toward dark) so neighbours don't read as clones.
    final double tintT = 0.08 * _variation;
    final Color fillC = Color.lerp(v.fill, v.fillDark, tintT.abs()) ?? v.fill;

    final Paint fill = Paint()..color = fillC.withValues(alpha: dim);
    final Paint dark = Paint()..color = v.fillDark.withValues(alpha: dim);
    final Paint outline = Paint()
      ..color = v.outline.withValues(alpha: dim)
      ..style = PaintingStyle.stroke
      ..strokeWidth = EmberMetrics.strokeWidth;

    // Stronger, grounded contact shadow so trees/rocks sit ON the tile instead
    // of floating. Sized to the node footprint + softly blurred.
    final Paint shadow = Paint()
      ..color = palette.shadow.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(
      Rect.fromCenter(
          center: const Offset(0, -1), width: bw * 0.92, height: bh * 0.18),
      shadow,
    );

    // SPRITE PATH: when the facade serves a node sprite (tree/stump/boulder/bush)
    // draw it bottom-center, shrunk by the same depletion-scale + per-node jitter
    // the programmatic path uses (so the field still reads as a varied, depleting
    // forest) and dimmed when depleted. hide/huntable have no sprite -> programmatic.
    final SpriteHandle? sprite = art.nodeSprite(doc.type, remaining: v.fullness);
    if (sprite != null) {
      SpriteCompositor.drawBottomCenter(
        canvas,
        sprite,
        tileWidth: projection.tileWidth,
        opacity: dim,
        extraScale: v.scale * sizeJitter,
      );
      if (doc.isDepleted) {
        canvas.drawCircle(
          Offset.zero,
          bw * 0.3,
          Paint()
            ..color = palette.inkSoft.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      if (_popTtl > 0 && _popAmount > 0) {
        final double t = 1.0 - (_popTtl / 0.9);
        _drawPop(canvas, t);
      }
      canvas.restore();
      return;
    }

    _NodeSilhouettePainter.paint(canvas, v.silhouette, bw, bh,
        fill: fill, dark: dark, outline: outline, variation: _variation);

    // Depletion ring under depleted nodes.
    if (doc.isDepleted) {
      canvas.drawCircle(
        Offset.zero,
        bw * 0.3,
        Paint()
          ..color = palette.inkSoft.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Floating +N.
    if (_popTtl > 0 && _popAmount > 0) {
      final double t = 1.0 - (_popTtl / 0.9);
      _drawPop(canvas, t);
    }

    canvas.restore();
  }

  void _drawPop(Canvas canvas, double t) {
    final double y = -size.y * 0.9 - t * 18;
    final double alpha = (1.0 - t).clamp(0.0, 1.0);
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: '+$_popAmount',
        style: TextStyle(
          color: palette.success.withValues(alpha: alpha),
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, y));
  }

  @override
  void onTapDown(TapDownEvent event) {
    final ResourceNode? doc = _doc;
    if (doc == null || doc.isDepleted) return;
    _bounceTtl = 0.18;
    dispatch(GatherIntent(nodeId));
  }
}

/// Pure painter for the closed [NodeSilhouette] set (bottom-center origin).
class _NodeSilhouettePainter {
  const _NodeSilhouettePainter._();

  static void paint(
    Canvas c,
    NodeSilhouette sil,
    double w,
    double h, {
    required Paint fill,
    required Paint dark,
    required Paint outline,
    double variation = 0.0,
  }) {
    switch (sil) {
      case NodeSilhouette.tree:
        // Trunk.
        final Rect trunk =
            Rect.fromCenter(center: Offset(0, -h * 0.18), width: w * 0.14, height: h * 0.36);
        c.drawRect(trunk, dark);
        c.drawRect(trunk, outline);
        // Canopy (three stacked blobs).
        for (final (double dy, double r) in <(double, double)>[
          (-h * 0.45, w * 0.42),
          (-h * 0.62, w * 0.34),
          (-h * 0.78, w * 0.24),
        ]) {
          c.drawCircle(Offset(0, dy), r, fill);
          c.drawCircle(Offset(0, dy), r, outline);
        }
      case NodeSilhouette.boulder:
        // A natural ROCK CLUSTER (not a single identical dome): a main boulder
        // plus 1-2 smaller flanking stones whose count, side, size + lean shift
        // with the stable per-node [variation], so neighbouring outcrops read as
        // a varied rocky field instead of a wall-to-wall grid of clones. The
        // boulders are FACETED (angular crystalline shoulders), not smooth bumps.
        final double vr = variation; // stable per-node in [-1, 1]
        // How many companion rocks (0..2), driven off the variation magnitude.
        final int companions = vr.abs() > 0.55 ? 2 : (vr.abs() > 0.18 ? 1 : 0);
        // A lit upper-left facet (fill brightened) so each boulder reads as a
        // 3-faceted solid, never a flat dome. Derived once, no paint mutation.
        final Paint litPaint = Paint()
          ..color = (Color.lerp(fill.color, const Color(0xFFFFFFFF), 0.18) ??
                  fill.color)
              .withValues(alpha: fill.color.a);

        // Draw a faceted boulder at (cx, baseY) with the given footprint.
        void faceted(double cx, double baseY, double bw, double bh, double skew) {
          // An angular boulder: a flat-ish base, a leaning peak, crisp shoulders.
          final double peakX = cx + bw * 0.16 * skew;
          final Path rock = Path()
            ..moveTo(cx - bw * 0.5, baseY)
            ..lineTo(cx - bw * 0.42, baseY - bh * 0.52)
            ..lineTo(peakX - bw * 0.10, baseY - bh)
            ..lineTo(peakX + bw * 0.22, baseY - bh * 0.84)
            ..lineTo(cx + bw * 0.5, baseY - bh * 0.30)
            ..lineTo(cx + bw * 0.46, baseY)
            ..close();
          c.drawPath(rock, fill);
          // Sun-facing lit face (upper-left).
          final Path lit = Path()
            ..moveTo(cx - bw * 0.42, baseY - bh * 0.52)
            ..lineTo(peakX - bw * 0.10, baseY - bh)
            ..lineTo(cx - bw * 0.04, baseY - bh * 0.46)
            ..lineTo(cx - bw * 0.5, baseY)
            ..close();
          c.drawPath(lit, litPaint);
          // Shaded right facet for volume.
          final Path facet = Path()
            ..moveTo(peakX - bw * 0.10, baseY - bh)
            ..lineTo(peakX + bw * 0.22, baseY - bh * 0.84)
            ..lineTo(cx + bw * 0.5, baseY - bh * 0.30)
            ..lineTo(cx + bw * 0.04, baseY - bh * 0.40)
            ..close();
          c.drawPath(facet, dark);
          c.drawPath(rock, outline);
        }

        // Companion stones FIRST (behind/around), then the main boulder on top.
        final double side = vr >= 0 ? 1.0 : -1.0;
        if (companions >= 1) {
          faceted(side * w * (0.26 + 0.06 * vr.abs()), 0,
              w * (0.34 + 0.06 * vr.abs()), h * (0.34 + 0.10 * vr.abs()),
              -side);
        }
        if (companions >= 2) {
          faceted(-side * w * 0.30, 0, w * 0.26, h * 0.26, side);
        }
        // Main boulder (centre), its size + lean nudged by the variation.
        faceted(w * 0.02 * vr, 0, w * (0.74 + 0.10 * vr), h * (0.66 + 0.12 * vr),
            vr);
      case NodeSilhouette.berryBush:
        final Rect bush = Rect.fromCenter(
            center: Offset(0, -h * 0.28), width: w * 0.9, height: h * 0.56);
        c.drawOval(bush, fill);
        c.drawOval(bush, outline);
        // Berries (dark accents).
        for (final Offset o in <Offset>[
          Offset(-w * 0.18, -h * 0.3),
          Offset(w * 0.16, -h * 0.22),
          Offset(0, -h * 0.42),
        ]) {
          c.drawCircle(o, w * 0.07, dark);
        }
      case NodeSilhouette.gameAnimal:
        // Low four-legged shape suggesting huntable game.
        final Rect bodyR = Rect.fromCenter(
            center: Offset(0, -h * 0.3), width: w * 0.9, height: h * 0.34);
        c.drawRRect(
            RRect.fromRectAndRadius(bodyR, const Radius.circular(8)), fill);
        c.drawRRect(
            RRect.fromRectAndRadius(bodyR, const Radius.circular(8)), outline);
        // Head + legs.
        c.drawCircle(Offset(w * 0.4, -h * 0.34), w * 0.14, fill);
        for (final double dx in <double>[-w * 0.3, w * 0.2]) {
          c.drawLine(Offset(dx, -h * 0.14), Offset(dx, 0),
              outline..strokeWidth = 3);
        }
    }
  }
}
