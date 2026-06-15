// Ember — concepts/shelter/dwelling_component.dart
//
// The bespoke on-world component for a shelter placeable. It subclasses the
// engine's [PlaceableComponent] and overrides ONLY the protected leaf hooks to
// add shelter visuals on top of the shared silhouette:
//   * paintUnder  — a soft "footprint" ground patch + (for housing dwellings) a
//     warm hint of a lit interior glimpsed at the doorway when comfortable,
//   * paintOver   — a cozy smoke wisp from the smoke hole for warm huts, plus a
//     stylized DAMAGE overlay (lean + a couple of cracks) that grows as durability
//     falls after a flood — gentle, never graphic, no peril to people,
//   * extraScale  — a gentle build-up "rise" while constructing (buildProgress),
//   * onPlaceableChanged — react to durability/state changes: a dust puff on
//     completion, a stylized splash wisp when newly flood-damaged.
//
// The component is READ-ONLY over world state (it re-reads the bound doc each
// snapshot via the base) — it contributes capacity/comfort purely by READING the
// typed [Dwelling] view off the ext bag the behavior maintains; it never writes
// the doc. Presentation animation uses the Flame loop, not world state.

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../art/art_keys.dart';
import '../../art/ember_art.dart';
import '../../art/ember_particles.dart';
import '../../core/enums.dart';
import '../../data/models/placeable.dart';
import '../../game/components/placeable_component.dart';
import 'model/dwelling.dart';

/// Renders a shelter placeable by tier/state with a build-up rise, a cozy
/// interior hint, and a stylized flood-damage overlay.
class DwellingComponent extends PlaceableComponent {
  DwellingComponent({required super.placeableId, super.projection});

  /// The typed view over the bound doc's ext bag (refreshed on each change).
  Dwelling? _dwelling;

  /// A free-running clock for the smoke wisp + interior flicker (presentation).
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
    final Dwelling next = Dwelling.fromExt(doc.type, doc.ext);
    final Dwelling? prev = _dwelling;
    _dwelling = next;

    // Completion puff: a soft dust kick when the dwelling finishes building.
    final bool wasBuilding = prev == null && doc.state == PlaceableState.built;
    final bool justBuilt = doc.state == PlaceableState.built &&
        doc.buildProgress >= 1.0 &&
        prev == null;
    if (wasBuilding || justBuilt) {
      add(_particles.build(ParticleArtKey.dust, intensity: 0.8)
        ..position = Vector2(0, -size.y * 0.1)
        ..priority = 6);
    }

    // Newly flood-damaged: a gentle splash wisp at the base (stylized).
    final double prevDur = prev?.durability ?? next.durability;
    if (next.durability < prevDur - 0.001) {
      add(_particles.build(ParticleArtKey.splash, intensity: 0.7)
        ..position = Vector2(0, -size.y * 0.05)
        ..priority = 7);
    }
  }

  @override
  double extraScale() {
    final Placeable? d = doc;
    if (d == null) return 1.0;
    // A gentle "raising" rise while constructing: the silhouette grows from 70%
    // to full as buildProgress climbs (the build-up animation, never instant).
    if (d.state == PlaceableState.building) {
      final double p = d.buildProgress.clamp(0.0, 1.0);
      return 0.7 + 0.3 * p;
    }
    return 1.0;
  }

  @override
  void paintUnder(Canvas canvas, Placeable doc, PlaceableVisual v) {
    // A soft earth footprint patch grounding the structure on its tile.
    final double r = size.x * 0.42;
    final Paint patch = Paint()
      ..color = palette.highGroundDark.withValues(alpha: 0.18);
    canvas.save();
    canvas.scale(1.0, 0.5);
    canvas.drawCircle(Offset.zero, r, patch);
    canvas.restore();

    // Warm interior glimpse at the doorway for a comfortable, sound HOUSING
    // dwelling (not a defense wall) — the cozy payoff seen through the door.
    final Dwelling? dw = _dwelling;
    if (dw != null && dw.housesAnyone && dw.comfort >= 0.5 && dw.durability > 0.3) {
      final double warmth = (dw.comfort * dw.durability).clamp(0.0, 1.0);
      final double flicker = 0.85 + 0.15 * math.sin(_t * 6.0);
      final double gr = size.x * 0.16 * warmth * flicker;
      final Paint glow = Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: <Color>[
            palette.emberBright.withValues(alpha: 0.40 * warmth),
            palette.ember.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(0, -size.y * 0.18), radius: gr),
        );
      canvas.drawCircle(Offset(0, -size.y * 0.18), gr, glow);
    }
  }

  @override
  void paintOver(Canvas canvas, Placeable doc, PlaceableVisual v) {
    final Dwelling? dw = _dwelling;
    if (dw == null) return;

    // Cozy smoke wisp from the smoke hole for a warm, sound HUT (the link back to
    // Fire's indoor hearth). Drawn as a few soft drifting puffs.
    if (dw.dwellingType == DwellingType.hut &&
        dw.comfort >= 0.6 &&
        dw.durability > 0.4) {
      _paintSmokeHole(canvas);
    }

    // Stylized DAMAGE overlay: as durability falls (after a flood), draw a slight
    // lean and a couple of cracks so the player READS the setback at a glance —
    // gentle, never graphic, never a character in peril.
    if (dw.durability < 0.75) {
      _paintDamage(canvas, 1.0 - dw.durability);
    }
  }

  void _paintSmokeHole(Canvas canvas) {
    final double topY = -size.y * 0.9;
    final Paint smoke = Paint()
      ..color = palette.inkSoft.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    for (int i = 0; i < 3; i++) {
      final double phase = _t * 1.4 + i * 1.1;
      final double dy = -(phase % 2.0) * 14.0;
      final double dx = math.sin(phase) * 4.0;
      final double rr = 2.5 + (phase % 2.0) * 2.0;
      canvas.drawCircle(Offset(dx, topY + dy), rr, smoke);
    }
  }

  void _paintDamage(Canvas canvas, double severity) {
    final double s = severity.clamp(0.0, 1.0);
    final double bw = size.x * 0.7;
    final double bh = size.y * 0.9;
    // A couple of dark cracks running down the body — count grows with severity.
    final Paint crack = Paint()
      ..color = palette.outline.withValues(alpha: 0.35 + 0.35 * s)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final int cracks = 1 + (s * 2).round();
    for (int i = 0; i < cracks; i++) {
      final double x = -bw * 0.25 + (i * bw * 0.25);
      final Path p = Path()
        ..moveTo(x, -bh * 0.1)
        ..lineTo(x + bw * 0.05, -bh * 0.35)
        ..lineTo(x - bw * 0.04, -bh * 0.55)
        ..lineTo(x + bw * 0.03, -bh * 0.7);
      canvas.drawPath(p, crack);
    }
    // A faint waterline tint at the base for a heavily-flooded wreck.
    if (s > 0.5) {
      final Paint waterline = Paint()
        ..color = palette.waterDeep.withValues(alpha: 0.18 * s);
      canvas.drawRect(
        Rect.fromLTWH(-bw * 0.5, -bh * 0.12, bw, bh * 0.12),
        waterline,
      );
    }
  }
}
