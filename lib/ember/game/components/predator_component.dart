// Ember — game/components/predator_component.dart
//
// The night predator: a menacing prowler that appears at the map EDGE while a
// `nightPredator` world-event is active and it is night, and circles the village
// staying OUT of any fire LightSource radius (well-lit camps push it back; a dark
// camp lets it close in). It is pure presentation feedback driven by the world
// snapshot (active event + light sources, both read from the GameBridge) — the
// predator does no damage itself (the event system/resolvers own outcomes).
//
// Movement is the render loop only (no clock/random in the determinism fence):
// the prowler orbits the village site at an angle advanced by dt, and its orbit
// radius is pushed outward whenever its next step would land inside a lit tile —
// so the light coverage visibly keeps it at bay.

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../animation/animated_actor.dart';
import '../../art/ember_palette.dart';
import '../../contracts/light_source.dart';
import '../../core/enums.dart';
import '../../core/geometry.dart';
import '../../data/models/world_event.dart';
import '../../data/models/world_state.dart';
import '../ember_game.dart';
import '../iso/iso_projection.dart';
import '../riverpod_flame_bridge.dart';

/// A single prowling predator that only manifests during an active night
/// predator event. Spawns/retires itself based on the world snapshot.
class PredatorComponent extends PositionComponent
    with HasGameReference<EmberGame>, BridgedComponent {
  PredatorComponent({this.projection = IsoProjection.standard})
      : super(anchor: Anchor.bottomCenter);

  final IsoProjection projection;

  AnimatedActor? _actor;

  /// Orbit angle (radians) around the village site; advanced each frame.
  double _angle = 0;

  /// Current orbit radius in TILES (pushed out by light, pulled in in dark).
  double _orbitTiles = 6.0;

  /// Whether the predator is currently manifested.
  bool _active = false;

  EmberPalette get palette => game.art.palette;

  @override
  Future<void> onLoad() async {
    _actor = game.art.actor(ActorKind.predator);
    size = Vector2(projection.tileWidth * 0.9, projection.tileHeight * 1.4);
    listenWorld(_evaluatePresence, fireImmediately: true);
  }

  /// Shows/hides the predator based on (active nightPredator event && night).
  /// Visibility is controlled by adding/removing the actor's component (the
  /// AnimatedActor exposes only `component`, so we manage presence, not opacity).
  void _evaluatePresence() {
    final bool shouldShow = _hasActivePredatorEvent(bridge.state) &&
        bridge.isNight;
    if (shouldShow == _active) return;
    _active = shouldShow;
    final AnimatedActor? actor = _actor;
    if (actor == null) return;
    if (_active) {
      if (!actor.component.isMounted) add(actor.component);
      actor.play(AnimState.walk);
      // Enter from an edge: start the orbit at a corner-ish angle.
      _angle = math.pi * 1.25;
      _orbitTiles = 6.5;
    } else {
      actor.play(AnimState.idle);
      actor.component.removeFromParent();
    }
  }

  bool _hasActivePredatorEvent(EmberWorldState s) {
    for (final WorldEvent e in s.events) {
      if (e.type != WorldEventType.nightPredator) continue;
      // Active = its time has come and the night hasn't fully cleared it. We
      // treat an unresolved due event OR a recently-resolved one (this tick) as
      // "manifest" for the visual; the sim owns the real lifecycle.
      if (e.scheduledForMs <= s.simNowMs && !e.resolved) return true;
    }
    return false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_active) return;

    // Orbit the village site.
    _angle += dt * 0.5; // slow prowl
    final GridCoord site = bridge.state.village.siteTile;

    // Probe the candidate cell; if it's lit, push the orbit outward; if dark,
    // creep inward (but never inside 3 tiles).
    final List<LightSource> lights = bridge.lightSources;
    final GridCoord probe = _cellAt(site, _angle, _orbitTiles);
    final bool lit = _isLit(probe, lights);
    if (lit) {
      _orbitTiles = math.min(9.0, _orbitTiles + dt * 2.2);
    } else {
      _orbitTiles = math.max(3.0, _orbitTiles - dt * 1.2);
    }

    final double gx = site.x + math.cos(_angle) * _orbitTiles;
    final double gy = site.y + math.sin(_angle) * _orbitTiles;
    final Vector2 center = projection.gridToScreenXY(gx, gy);
    position = Vector2(center.x, center.y + projection.halfTileHeight);
    priority = projection.depthSortKey(GridCoord(gx.round(), gy.round()),
        heightBias: 2);
  }

  GridCoord _cellAt(GridCoord site, double angle, double radius) {
    final int gx = (site.x + math.cos(angle) * radius).round();
    final int gy = (site.y + math.sin(angle) * radius).round();
    return GridCoord(gx, gy);
  }

  bool _isLit(GridCoord c, List<LightSource> lights) {
    for (final LightSource src in lights) {
      if (src.coverageAt(c) > 0) return true;
    }
    return false;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!_active) return;
    // A faint red menace ring under the prowler.
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, -2),
        width: size.x * 0.9,
        height: size.y * 0.16,
      ),
      Paint()
        ..color = palette.danger.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
  }
}
