// Ember — game/components/discovery_node_component.dart
//
// A walk-up DISCOVERY NODE on the iso world: a softly glowing ground ring with a
// concept glyph hovering over it, marking the spot where a new idea can be
// discovered (the fire firebow spot, the knapping outcrop, the sheltered ledge).
// Walking the avatar onto it surfaces a launch prompt (handled by the proximity
// resolver + world_screen); this component is the VISUAL only.
//
// VISIBILITY = the prereq cascade: the ring is shown ONLY while its concept is
// UNLOCKED and NOT yet COMPLETED (read live from the world snapshot through the
// bridge). Locked -> hidden (nothing to find yet); completed -> hidden (you
// already know this), so the map shows exactly the next thing to go discover.
//
// Read-only presentation: it watches the world snapshot to toggle its own
// visibility + pulse; it dispatches nothing and never mutates state. The
// determinism fence is untouched (the pulse runs off Flame's dt loop).

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../art/craft_kit.dart';
import '../../art/ember_palette.dart';
import '../../core/enums.dart';
import '../../core/geometry.dart';
import '../ember_game.dart';
import '../exploration/discovery_nodes.dart';
import '../iso/iso_projection.dart';
import '../riverpod_flame_bridge.dart';

/// The glowing walk-up marker for one [DiscoveryNodeDef].
class DiscoveryNodeComponent extends PositionComponent
    with HasGameReference<EmberGame>, BridgedComponent {
  DiscoveryNodeComponent({
    required this.def,
    this.projection = IsoProjection.standard,
  }) : super(anchor: Anchor.bottomCenter);

  final DiscoveryNodeDef def;
  final IsoProjection projection;

  /// Whether the node is currently available (unlocked && !completed).
  bool _visible = false;

  /// Free-running pulse clock (ambient ring breathing + glyph bob).
  double _t = 0;

  /// True while the avatar is standing close enough to launch (the resolver sets
  /// this so the ring brightens + the glyph lifts as a "press to discover" cue).
  bool focused = false;

  EmberPalette get palette => game.art.palette;

  /// The node's map cell (derived from the live village site).
  GridCoord get cell => def.coordFor(bridge.state.village.siteTile);

  @override
  Future<void> onLoad() async {
    size = Vector2(projection.tileWidth * 0.9, projection.tileHeight * 1.6);
    listenWorld(_sync, fireImmediately: true);
  }

  void _sync() {
    final ConceptId id = def.concept;
    final concept = bridge.state.conceptById(id);
    final bool unlocked = concept?.unlocked ?? false;
    final bool completed = concept?.completed ?? false;
    _visible = unlocked && !completed;
    _positionForCoord(cell);
  }

  void _positionForCoord(GridCoord coord) {
    final Vector2 center = projection.gridToScreenXY(
        coord.x.toDouble(), coord.y.toDouble());
    position = Vector2(center.x, center.y + projection.halfTileHeight);
    priority = projection.depthSortKey(coord, heightBias: 0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_visible) _t += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!_visible) return;

    canvas.save();
    canvas.translate(size.x / 2, size.y);

    final double pulse = 0.5 + 0.5 * math.sin(_t * 2.0);
    final double focusBoost = focused ? 0.5 : 0.0;
    final double intensity = (0.45 + 0.35 * pulse + focusBoost).clamp(0.0, 1.2);

    // Ground glow ring (flat iso ellipse so it reads as ON the tile).
    final double rw = size.x * (0.78 + 0.06 * pulse);
    final double rh = projection.tileHeight * (0.6 + 0.05 * pulse);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -2), width: rw, height: rh),
      Paint()
        ..color = palette.ember.withValues(alpha: 0.18 + 0.18 * intensity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, focused ? 10 : 6),
    );
    // The ring stroke.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -2), width: rw, height: rh),
      Paint()
        ..color = palette.emberBright.withValues(alpha: 0.6 + 0.3 * intensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = focused ? 3.0 : 2.0,
    );

    // The hovering glyph (lifts when focused).
    final double bob = math.sin(_t * 2.4) * 3.0;
    final double lift = (focused ? 26.0 : 18.0) + bob;
    final Offset glyphAt = Offset(0, -projection.tileHeight - lift);
    CraftKit.bloomStack(
      canvas,
      center: glyphAt,
      radius: 14 + 6 * intensity,
      intensity: 0.4 + 0.4 * intensity,
      warm: palette.ember,
      hot: palette.spark,
    );
    _drawGlyph(canvas, glyphAt);

    canvas.restore();
  }

  void _drawGlyph(Canvas canvas, Offset at) {
    final Paint stroke = Paint()
      ..color = palette.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Paint fill = Paint()..color = palette.surface;
    const double s = 9.0;
    switch (def.glyph) {
      case DiscoveryGlyph.fire:
        // A simple flame teardrop.
        final Path flame = Path()
          ..moveTo(at.dx, at.dy - s)
          ..quadraticBezierTo(at.dx + s, at.dy, at.dx, at.dy + s)
          ..quadraticBezierTo(at.dx - s, at.dy, at.dx, at.dy - s)
          ..close();
        canvas.drawPath(flame, fill);
      case DiscoveryGlyph.knap:
        // A hammer-strike: a chevron over a slab.
        canvas.drawLine(
            Offset(at.dx - s, at.dy + s * 0.6),
            Offset(at.dx + s, at.dy + s * 0.6),
            stroke);
        canvas.drawLine(
            Offset(at.dx - s * 0.5, at.dy - s),
            Offset(at.dx + s * 0.3, at.dy + s * 0.2),
            stroke);
      case DiscoveryGlyph.shelter:
        // A roof (triangle).
        final Path roof = Path()
          ..moveTo(at.dx, at.dy - s)
          ..lineTo(at.dx + s, at.dy + s * 0.7)
          ..lineTo(at.dx - s, at.dy + s * 0.7)
          ..close();
        canvas.drawPath(roof, stroke);
    }
  }
}
