// Ember — game/components/night_overlay_component.dart
//
// The ambient darkness layer + warm light cut-outs. At night it paints a tinted
// scrim over the WHOLE visible world, then "punches" soft warm holes where fire
// LightSources reach (read from the GameBridge — which republishes
// lightSourcesProvider / fire coverage). The darker the night phase, the heavier
// the scrim; each light pool brightens toward its center via a radial gradient,
// so fire-lit tiles stay readable while unlit ground falls dark.
//
// It is a WORLD-space component (added to the world layer at a high priority) so
// the light holes line up with placeables/tiles under the camera transform. The
// holes are drawn with BlendMode.dstOut to subtract from the scrim (an additive-
// feeling cut-out) and then a warm glow is layered on top.
//
// Read-only: darkness + light sources come from the bridge; it never mutates.

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../art/ember_palette.dart';
import '../../contracts/light_source.dart';
import '../../core/enums.dart';
import '../../data/models/world_event.dart';
import '../../data/models/world_state.dart';
import '../ember_game.dart';
import '../iso/iso_projection.dart';
import '../riverpod_flame_bridge.dart';

/// Full-world night scrim with warm light cut-outs at fire sources.
class NightOverlayComponent extends PositionComponent
    with HasGameReference<EmberGame>, BridgedComponent {
  NightOverlayComponent({
    this.projection = IsoProjection.standard,
    super.priority = priorityNight,
  });

  /// Draws above the world content but below predator/flood feedback.
  static const int priorityNight = 2000000;

  final IsoProjection projection;

  EmberPalette get palette => game.art.palette;

  @override
  Future<void> onLoad() async {
    // Track ambient + light changes (keeps bindings alive; render reads live).
    listen<double>(bridge.darknessListenable, () {}, fireImmediately: false);
    listen<List<LightSource>>(bridge.lightSourcesListenable, () {});
    // The flood-suppression + village-glow read the world snapshot (flood
    // events + village site), so keep a world binding alive too.
    listenWorld(() {});
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    double darkness = bridge.darkness;
    if (darkness <= 0.001) return; // daytime — nothing to scrim.

    final Rect worldRect = _worldRect();
    if (worldRect.isEmpty) return;

    // During a flood, ease the night darkening WAY back so the flood overlay's
    // cool-cyan wash + rising water read clearly (flood must never look like
    // plain night). The flood overlay draws above this scrim anyway, but a
    // lighter scrim keeps the water from muddying to navy.
    if (_isFlooding(bridge.state)) {
      darkness *= 0.35;
    }

    // Scrim strength scales with night darkness. Cap LOWERED (was 0.78) and the
    // tint shifted cooler-but-lighter so SE rocks, huts and NPCs stay legible at
    // night instead of vanishing into a flat navy wash.
    final double scrimAlpha = (0.58 * darkness).clamp(0.0, 0.58);

    // A slightly lighter, cooler night tint than raw palette.night so silhouettes
    // keep their separation under the scrim.
    final Color nightTint =
        Color.lerp(palette.night, palette.cold, 0.18) ?? palette.night;

    // Use a layer so dstOut light holes subtract from the scrim only.
    canvas.saveLayer(worldRect, Paint());
    canvas.drawRect(
      worldRect,
      Paint()..color = nightTint.withValues(alpha: scrimAlpha),
    );

    // Subtract a soft hole at each light source.
    final List<LightSource> sources = bridge.lightSources;
    for (final LightSource src in sources) {
      _punchLightHole(canvas, src);
    }
    // ALWAYS punch a soft warm hole over the village site so the heart of the
    // settlement stays readable + cozy even before a fire leaf exists (with no
    // fire there are zero light sources, so the scene would otherwise be a flat
    // wash). Independent of fire coverage.
    _punchVillageHole(canvas);
    canvas.restore();

    // Warm glow on top of the holes (additive feel).
    for (final LightSource src in sources) {
      _warmGlow(canvas, src);
    }
    // The village hearth-glow anchor (warm, inviting, fire-independent).
    _villageGlow(canvas, darkness);
  }

  bool _isFlooding(EmberWorldState s) {
    for (final WorldEvent e in s.events) {
      if (e.type != WorldEventType.flood) continue;
      if (e.scheduledForMs > s.simNowMs) continue;
      // Mirror FloodOverlayComponent: a debug flood (review loop) counts as
      // active even after the live sim auto-resolves it.
      if (e.payload['debug'] == true || !e.resolved) return true;
    }
    return false;
  }

  /// World-px radius of the fire-independent village glow.
  double _villageRadiusPx() => projection.tileWidth * 2.2;

  Vector2 _villageCenter() =>
      projection.gridToScreen(bridge.state.village.siteTile);

  void _punchVillageHole(Canvas canvas) {
    final double r = _villageRadiusPx();
    final Vector2 c = _villageCenter();
    final Offset o = Offset(c.x, c.y);
    // Clears most (not all) of the scrim so the village reads as moonlit/firelit.
    final Paint hole = Paint()
      ..blendMode = BlendMode.dstOut
      ..shader = const RadialGradient(
        colors: <Color>[
          Color(0xCCFFFFFF), // strongly clears the scrim at center
          Color(0x00FFFFFF), // no effect at the edge
        ],
        stops: <double>[0.0, 1.0],
      ).createShader(Rect.fromCircle(center: o, radius: r));
    canvas.drawCircle(o, r, hole);
  }

  void _villageGlow(Canvas canvas, double darkness) {
    final double r = _villageRadiusPx() * 0.9;
    final Vector2 c = _villageCenter();
    final Offset o = Offset(c.x, c.y);
    final Paint glow = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        colors: <Color>[
          palette.ember.withValues(alpha: 0.22 * darkness),
          palette.ember.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: o, radius: r));
    canvas.drawCircle(o, r, glow);
  }

  Rect _worldRect() {
    final int w = bridge.state.tiles.width;
    final int h = bridge.state.tiles.height;
    // Pad generously so the scrim covers beyond the projected diamonds.
    return projection.mapBounds(w, h, pad: projection.tileWidth);
  }

  /// World-px radius of a light source (intensity-scaled).
  double _radiusPx(LightSource src) =>
      src.effectiveRadius * projection.tileWidth * 0.62;

  void _punchLightHole(Canvas canvas, LightSource src) {
    final double r = _radiusPx(src);
    if (r <= 0) return;
    final Vector2 center = projection.gridToScreen(src.pos);
    final Offset o = Offset(center.x, center.y);
    final Paint hole = Paint()
      ..blendMode = BlendMode.dstOut
      ..shader = const RadialGradient(
        colors: <Color>[
          Color(0xFFFFFFFF), // fully clears the scrim at center
          Color(0x00FFFFFF), // no effect at the edge
        ],
        stops: <double>[0.0, 1.0],
      ).createShader(Rect.fromCircle(center: o, radius: r));
    canvas.drawCircle(o, r, hole);
  }

  void _warmGlow(Canvas canvas, LightSource src) {
    final double r = _radiusPx(src) * 0.85;
    if (r <= 0) return;
    final Vector2 center = projection.gridToScreen(src.pos);
    final Offset o = Offset(center.x, center.y);
    final double intensity = src.intensity.clamp(0.0, 1.0);
    final Paint glow = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        colors: <Color>[
          palette.ember.withValues(alpha: 0.32 * intensity),
          palette.ember.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: o, radius: r));
    canvas.drawCircle(o, r, glow);
  }
}
