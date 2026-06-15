// Ember — game/components/flood_overlay_component.dart
//
// The stylized rising-water visual shown while a `flood` world-event is active.
// It tints flood-risk tiles with a translucent rippling water layer whose level
// rises (in over a couple of seconds) and ebbs as the event resolves. Higher
// event severity floods more tiles (lower flood-risk tiles join in only when the
// flood is severe). Pure presentation feedback read from the GameBridge snapshot
// (active flood event + the tiles' own floodRisk) — it never mutates the world.
//
// World-space component drawn above the ground/placeables but below the night
// scrim, so a flood reads as water creeping over the terrain.

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../art/ember_palette.dart';
import '../../core/enums.dart';
import '../../data/models/tile.dart';
import '../../data/models/world_event.dart';
import '../../data/models/world_state.dart';
import '../ember_game.dart';
import '../iso/iso_projection.dart';
import '../riverpod_flame_bridge.dart';

/// Rising-water overlay on flood-risk tiles during a flood.
class FloodOverlayComponent extends PositionComponent
    with HasGameReference<EmberGame>, BridgedComponent {
  FloodOverlayComponent({
    this.projection = IsoProjection.standard,
    super.priority = priorityFlood,
  });

  /// ABOVE the night scrim (priorityNight = 2_000_000) so flood water is never
  /// buried by nighttime darkening — a flood must always read as water, even at
  /// night. (Was 1_500_000, which drew BENEATH the night scrim — the layering
  /// bug that made every flood frame look like plain night.)
  static const int priorityFlood = 2500000;

  final IsoProjection projection;

  /// 0..1 animated flood level (eases toward the target each frame).
  double _level = 0;

  /// The current event severity gate (which flood-risk tiles are under water).
  double _severity = 0;

  /// Animation phase for ripples (render-loop time; presentation only).
  double _ripplePhase = 0;

  late final List<Vector2> _corners = projection.diamondCorners();

  EmberPalette get palette => game.art.palette;

  @override
  Future<void> onLoad() async {
    listenWorld(_evaluate, fireImmediately: true);
  }

  void _evaluate() {
    final WorldEvent? flood = _activeFlood(bridge.state);
    _severity = flood?.severity ?? 0;
  }

  WorldEvent? _activeFlood(EmberWorldState s) {
    for (final WorldEvent e in s.events) {
      if (e.type != WorldEventType.flood) continue;
      if (e.scheduledForMs > s.simNowMs) continue;
      // A debug-triggered flood (review loop) is shown for as long as it exists,
      // even though the live sim auto-resolves unresolvable events (no shelter
      // leaf -> no flood resolver yet). A real, resolver-backed flood shows only
      // while unresolved.
      final bool isDebug = e.payload['debug'] == true;
      if (isDebug || !e.resolved) return e;
    }
    return null;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _ripplePhase = (_ripplePhase + dt * 1.4) % (math.pi * 2);
    final double target = _severity > 0 ? 1.0 : 0.0;
    final double rate = dt * 0.8;
    if (_level < target) {
      _level = math.min(target, _level + rate);
    } else if (_level > target) {
      _level = math.max(target, _level - rate);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_level <= 0.001) return;

    final EmberWorldState s = bridge.state;

    // 1) A cool cyan/teal WASH over the whole scene. This is the unmistakable
    //    "it's a flood, not night" signal: night darkens toward navy; a flood
    //    casts a distinct cool-cyan light. Drawn first so per-tile water sits on
    //    top of it. (Priority is above the night scrim, so this overrides the
    //    navy darkening with cyan during a flood.)
    final Rect worldRect = _worldRect();
    if (!worldRect.isEmpty) {
      canvas.drawRect(
        worldRect,
        Paint()
          ..blendMode = BlendMode.srcOver
          ..color = palette.water.withValues(alpha: 0.22 * _level),
      );
    }

    // Tiles flood when their own risk clears a severity-scaled gate: a severe
    // flood (sev->1) submerges risk>=0.2; a mild flood only the riskiest tiles.
    final double gate = 0.7 - 0.5 * _severity; // sev 0 -> 0.7, sev 1 -> 0.2

    for (final Tile t in s.tiles.tiles) {
      if (!t.explored) continue;
      if (t.terrain == TerrainType.water) continue; // already water.
      if (t.floodRisk < gate) continue;

      final Vector2 c = projection.gridToScreen(t.coord);
      _drawWaterDiamond(canvas, c, t.floodRisk);
    }
  }

  Rect _worldRect() {
    final int w = bridge.state.tiles.width;
    final int h = bridge.state.tiles.height;
    return projection.mapBounds(w, h, pad: projection.tileWidth);
  }

  void _drawWaterDiamond(Canvas canvas, Vector2 center, double risk) {
    canvas.save();
    canvas.translate(center.x, center.y);

    final Path diamond = Path()
      ..moveTo(_corners[0].x, _corners[0].y)
      ..lineTo(_corners[1].x, _corners[1].y)
      ..lineTo(_corners[2].x, _corners[2].y)
      ..lineTo(_corners[3].x, _corners[3].y)
      ..close();

    // Water alpha grows with level + risk. Bumped up (was 0.28+0.30) so flooded
    // banks read as clearly submerged — the core "water floods" hook.
    final double alpha = (0.42 + 0.34 * risk) * _level;
    canvas.drawPath(
      diamond,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            palette.water.withValues(alpha: alpha.clamp(0.0, 0.85)),
            palette.waterDeep.withValues(alpha: (alpha + 0.1).clamp(0.0, 0.92)),
          ],
        ).createShader(diamond.getBounds()),
    );

    // Foam at the waterline: a bright drifting crest along the upper diamond
    // edges so the rising water has a clear, readable surface (not just a tint).
    final Paint foam = Paint()
      ..color = palette.spark.withValues(alpha: (0.55 * _level).clamp(0.0, 0.7))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final double crestOff = math.sin(_ripplePhase) * 2.0;
    final Path crest = Path()
      ..moveTo(_corners[3].x, _corners[3].y) // left
      ..quadraticBezierTo(
          0, _corners[0].y + crestOff, _corners[1].x, _corners[1].y); // -> right
    canvas.drawPath(crest, foam);

    // A couple of ripple strokes that drift with the phase (inner surface).
    final Paint ripple = Paint()
      ..color = palette.spark.withValues(alpha: 0.22 * _level)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final double dy in <double>[-3, 5]) {
      final double off = math.sin(_ripplePhase + dy) * 3;
      final Path r = Path()
        ..moveTo(-projection.halfTileWidth * 0.5, dy)
        ..quadraticBezierTo(
            off, dy - 3, projection.halfTileWidth * 0.5, dy);
      canvas.drawPath(r, ripple);
    }

    canvas.restore();
  }
}
