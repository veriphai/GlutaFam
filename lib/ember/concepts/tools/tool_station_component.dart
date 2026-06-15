// Ember — concepts/tools/tool_station_component.dart
//
// The bespoke on-world component for a Knapping Station (and, reused, a Tool
// Rack). It subclasses the engine's [PlaceableComponent] and overrides ONLY the
// protected leaf hooks to add tool visuals on top of the shared silhouette:
//   * paintOver — a small finished-tool icon resting on the slab + a moving GLINT
//     streak across its sharp edge (PRD §11 "glint on finished sharp edges"),
//     plus tiny tier pips so an upgraded station reads as better,
//   * onPlaceableChanged — puff a one-shot burst of stone chips when the held
//     tool changes (a fresh flake was knapped / the tool tier bumped).
//
// The component is READ-ONLY over world state (it re-reads the bound doc each
// snapshot via the base). The authoritative [Tool] the gather modifier consumes
// is published into the doc's ext bag by the activity placeHint / behavior, not
// by this view. Presentation glint uses the Flame loop (presentation only).

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../art/art_keys.dart';
import '../../art/ember_art.dart';
import '../../art/ember_particles.dart';
import '../../core/enums.dart';
import '../../data/models/placeable.dart';
import '../../game/components/placeable_component.dart';
import 'model/tool.dart';

/// Renders a knapping station / tool rack with a finished-tool icon + edge glint.
class ToolStationComponent extends PlaceableComponent {
  ToolStationComponent({required super.placeableId, super.projection});

  /// The typed tool view over the bound doc's ext bag (null if it holds none).
  Tool? _tool;

  /// A free-running clock for the edge glint sweep (presentation only).
  double _t = 0.0;

  EmberParticles? _particlesCache;
  EmberParticles get _particles =>
      _particlesCache ??= EmberParticles(palette: palette);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void onPlaceableChanged(Placeable doc) {
    final Tool? next = Tool.fromPlaceable(doc);
    final Tool? prev = _tool;
    _tool = next;

    // A fresh flake / a better tool -> a celebratory puff of stone chips.
    final bool gainedOrImproved = next != null &&
        (prev == null || next.rank > prev.rank || next.tier > prev.tier);
    if (gainedOrImproved && isMounted) {
      add(_particles.build(ParticleArtKey.chip, intensity: 1.0)
        ..position = Vector2(0, -size.y * 0.45)
        ..priority = 5);
    }
  }

  @override
  void paintOver(Canvas canvas, Placeable doc, PlaceableVisual v) {
    final Tool? t = _tool;
    if (t == null) return;

    // The finished tool sits on top of the slab/rack (a little stone blade).
    final double bw = size.x * 0.7;
    final double bh = size.y * 0.9;
    final double cx = bw * 0.16;
    final double cy = -bh * 0.40;

    // Blade body — a leaf-shaped knapped flake.
    final Path blade = Path()
      ..moveTo(cx, cy - bh * 0.10)
      ..quadraticBezierTo(
          cx + bw * 0.10, cy - bh * 0.02, cx + bw * 0.02, cy + bh * 0.10)
      ..quadraticBezierTo(
          cx - bw * 0.10, cy + bh * 0.02, cx, cy - bh * 0.10)
      ..close();
    canvas.drawPath(
      blade,
      Paint()..color = palette.stoneChip,
    );
    canvas.drawPath(
      blade,
      Paint()
        ..color = palette.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // The GLINT — a bright streak sweeping along the sharp edge to advertise the
    // made edge (PRD §11). Triangle of light that travels up the blade on a loop.
    final double phase = (_t * 0.9) % 1.0;
    final double gy = cy + bh * 0.10 - phase * bh * 0.20;
    final double glintAlpha =
        (1.0 - (phase - 0.5).abs() * 2.0).clamp(0.0, 1.0) * 0.9;
    if (glintAlpha > 0.02) {
      canvas.drawCircle(
        Offset(cx + bw * 0.02, gy),
        2.6,
        Paint()
          ..color = palette.spark.withValues(alpha: glintAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }

    // Tier pips above the slab so an upgraded station reads as better at a glance.
    final int pips = (t.tier - 1).clamp(0, 4);
    for (int i = 0; i < pips; i++) {
      canvas.drawCircle(
        Offset(-bw * 0.30 + i * 6.0, -bh * 0.62),
        2.0,
        Paint()..color = palette.ember,
      );
    }

    // A tiny fire-treated mark (warm dot) if the tool was heat-treated.
    if (t.fireTreated) {
      canvas.drawCircle(
        Offset(cx + bw * 0.16, cy - bh * 0.10),
        2.2,
        Paint()..color = palette.emberBright,
      );
    }
  }

  /// Whether this component renders a knapping station (vs a reused tool rack);
  /// kept for any future per-type tweak. Pure read off the bound doc.
  bool get isStation => doc?.type == PlaceableType.knappingStation;

  /// The art key this component renders for (debug/readability).
  PlaceableArtKey get artKey => ArtKeys.placeable(
      doc?.type ?? PlaceableType.knappingStation);
}
