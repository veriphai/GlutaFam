// Ember — concepts/fire/fire_object_component.dart
//
// The bespoke on-world component for a fire placeable. It subclasses the engine's
// [PlaceableComponent] and overrides ONLY the protected leaf hooks to add fire
// visuals on top of the shared silhouette:
//   * paintUnder  — a warm additive light/warmth POOL whose radius + alpha track
//     the live [FireObject] intensity (so it visibly dims as fuel burns down),
//   * paintOver   — a flickering flame + glowing ember core (drawn over the pit),
//   * extraScale  — a gentle "breathing" pulse so the fire feels alive,
//   * onPlaceableChanged — (re)attach a looping ember-particle emitter while lit,
//     swap to a smoke wisp + detach embers once it goes out.
//
// The component is READ-ONLY over world state (it re-reads the bound doc each
// snapshot via the base) and emits LightSource purely as a VISUAL pool here — the
// authoritative LightSource the sim consumes is published into the doc's ext bag
// by [FireBehavior], not by this view. Presentation flicker uses the Flame loop.

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../art/art_keys.dart';
import '../../art/ember_art.dart';
import '../../art/ember_particles.dart';
import '../../data/models/placeable.dart';
import '../../game/components/placeable_component.dart';
import 'model/fire_object.dart';

/// Renders a fire placeable by tier/state with a live glow + flame + embers.
class FireObjectComponent extends PlaceableComponent {
  FireObjectComponent({required super.placeableId, super.projection});

  /// The typed view over the bound doc's ext bag (refreshed on each change).
  FireObject? _fire;

  /// The looping ember emitter attached while the fire is lit (null when out).
  Component? _emberEmitter;

  /// A free-running clock for flame flicker (presentation only).
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
    final FireObject next = FireObject.fromPlaceable(doc);
    final FireObject? prev = _fire;
    _fire = next;

    final bool wasBurning = (prev?.isLit ?? false) && (prev?.hasFuel ?? false);
    final bool nowBurning = next.isLit && next.hasFuel;

    if (nowBurning && _emberEmitter == null) {
      _attachEmbers();
    } else if (!nowBurning && _emberEmitter != null) {
      _detachEmbers();
      // A brief smoke wisp as it goes out (only on the burning->out transition).
      if (wasBurning) {
        add(_particles.build(ParticleArtKey.smoke, intensity: 0.7)
          ..position = Vector2(0, -size.y * 0.55)
          ..priority = 5);
      }
    }
  }

  void _attachEmbers() {
    // Emit from where THIS fire's flame lives (a torch's embers leave the pole
    // top; a cooking fire's leave its low bed) so the motes look attached.
    final double emitY = switch (_fire?.fireType) {
      FireType.torch => -size.y * 0.9,
      FireType.brazier => -size.y * 0.55,
      FireType.cookingFire => -size.y * 0.18,
      _ => -size.y * 0.5,
    };
    final Component e = _particles.build(ParticleArtKey.ember, intensity: 1.0)
      ..position = Vector2(0, emitY)
      ..priority = 5;
    _emberEmitter = e;
    add(e);
  }

  void _detachEmbers() {
    _emberEmitter?.removeFromParent();
    _emberEmitter = null;
  }

  @override
  double extraScale() {
    final FireObject? f = _fire;
    if (f == null || !f.isLit || !f.hasFuel) return 1.0;
    // A small breathing pulse scaled by intensity.
    final double amp = 0.02 + 0.03 * f.intensity;
    return 1.0 + amp * math.sin(_t * 5.0);
  }

  @override
  void paintUnder(Canvas canvas, Placeable doc, PlaceableVisual v) {
    final FireObject? f = _fire;
    if (f == null || f.intensity <= 0.0) return;
    // A warm light/warmth POOL on the ground under the fire. Additive so it reads
    // as glow; radius + alpha scale with intensity (dims as fuel burns down). The
    // hearth pools the widest light (the camp's heart); a torch is a tight light.
    final double poolMul = switch (f.fireType) {
      FireType.hearth => 1.25,
      FireType.brazier => 1.0,
      FireType.cookingFire => 0.9,
      FireType.torch => 0.7,
    };
    final double r = (size.x * 0.7) * poolMul * (0.6 + 0.7 * f.intensity);
    final Paint pool = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        colors: <Color>[
          palette.emberBright.withValues(alpha: 0.30 * f.intensity),
          palette.ember.withValues(alpha: 0.14 * f.intensity),
          palette.ember.withValues(alpha: 0.0),
        ],
        stops: const <double>[0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    // Slightly squashed to sit on the iso ground plane.
    canvas.save();
    canvas.scale(1.0, 0.5);
    canvas.drawCircle(Offset.zero, r, pool);
    canvas.restore();

    // BACKLIGHT HALO: a soft additive bloom centred on the fire BODY (not just
    // the ground pool). Drawn behind the fire sprite so the campfire reads as a
    // bright hero at the camp's heart at night even when a dense tribe clusters
    // around it (runner finding: hearth prominence). A gentle flicker keeps it
    // alive; the radius/alpha track intensity so it fades with the fuel.
    final double halo = 0.9 + 0.1 * math.sin(_t * 7.0 + doc.coord.x.toDouble());
    final double hr = (size.x * 0.85) * poolMul * (0.7 + 0.5 * f.intensity) * halo;
    final Offset hc = Offset(0, -size.y * 0.32);
    final Paint bloom = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        colors: <Color>[
          palette.emberBright.withValues(alpha: 0.26 * f.intensity),
          palette.ember.withValues(alpha: 0.10 * f.intensity),
          palette.ember.withValues(alpha: 0.0),
        ],
        stops: const <double>[0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: hc, radius: hr));
    canvas.drawCircle(hc, hr, bloom);
  }

  @override
  void paintOver(Canvas canvas, Placeable doc, PlaceableVisual v) {
    final FireObject? f = _fire;
    if (f == null || f.intensity <= 0.0) return;

    final double flicker = 0.9 + 0.1 * math.sin(_t * 12.0 + doc.coord.x.toDouble());
    final double level = f.intensity;

    // Per-type CHARACTER: each fire reads differently at a glance.
    //   * hearth   — a broad, tall, generous flame (the camp's heart),
    //   * torch    — a single slim flame riding HIGH on the pole,
    //   * cookingFire — a low, wide working flame with glowing coals,
    //   * brazier  — a contained flame sitting up in its bowl.
    final double baseY = switch (f.fireType) {
      FireType.torch => -size.y * 0.86, // flame sits at the pole top
      FireType.brazier => -size.y * 0.5, // up in the bowl
      FireType.cookingFire => -size.y * 0.10, // low working fire
      FireType.hearth => -size.y * 0.16,
    };
    final double widthMul = switch (f.fireType) {
      FireType.torch => 0.6,
      FireType.cookingFire => 1.3,
      FireType.brazier => 0.9,
      FireType.hearth => 1.1,
    };
    final double heightMul = switch (f.fireType) {
      FireType.torch => 0.85,
      FireType.cookingFire => 0.7,
      FireType.brazier => 0.9,
      FireType.hearth => 1.15,
    };

    // Glowing ember BED at the pit centre — a pulsing coal pool (brighter,
    // satisfying core). Cooking fires show a wider bed of coals.
    final double pulse = 0.85 + 0.15 * math.sin(_t * 6.0 + doc.coord.y.toDouble());
    final double er = size.x * 0.11 * widthMul * (0.7 + 0.5 * level) * pulse;
    canvas.drawCircle(
      Offset(0, baseY),
      er,
      Paint()..color = palette.emberDeep.withValues(alpha: 0.75 * level),
    );
    canvas.drawCircle(
      Offset(0, baseY),
      er * 0.5,
      Paint()..color = palette.emberBright.withValues(alpha: 0.7 * level),
    );

    // The flame, scaled by intensity + tier (bigger fires = taller flames).
    final double tierBoost = 1.0 + 0.18 * (doc.tier - 1);
    final double h =
        size.y * (0.30 + 0.45 * level) * tierBoost * heightMul * flicker;
    final double w = size.x * (0.16 + 0.10 * level) * widthMul;
    final Path outer = _flamePath(w, h, baseY);
    canvas.drawPath(outer, Paint()..color = palette.ember.withValues(alpha: 0.92));
    final Path inner = _flamePath(w * 0.55, h * 0.7, baseY);
    canvas.drawPath(
      inner,
      Paint()..color = palette.emberBright.withValues(alpha: 0.95),
    );

    // A few swirling rising embers above the flame (matches the make-fire stage
    // language so a placed fire feels as alive as the one you just made). Cosmetic,
    // deterministic per-index phase keyed off the tile so two fires don't sync.
    _renderSwirl(canvas, baseY - h * 0.5, level, doc.coord.x + doc.coord.y);
  }

  /// Always-on cosmetic swirling embers above a lit fire (no RNG; phase keyed off
  /// the tile + the free clock so it's lively without touching world state).
  void _renderSwirl(Canvas canvas, double topY, double level, int seed) {
    const int count = 5;
    for (int i = 0; i < count; i++) {
      final double phase = (i * 0.83 + seed * 0.37) % 1.0;
      final double speed = 0.5 + (i % 3) * 0.18;
      final double p = ((_t * speed + phase) % 1.0);
      final double rise = -p * size.y * 0.5 * (0.6 + level);
      final double curl =
          math.sin((_t * 1.8 + phase * 6.28)) * size.x * 0.12 * (0.6 + level);
      final double fade = (1.0 - p) * level;
      if (fade <= 0.03) continue;
      final double r = size.x * 0.018 * (0.6 + 0.8 * fade);
      final Color c = i.isEven ? palette.emberBright : palette.ember;
      canvas.drawCircle(
        Offset(curl, topY + rise),
        r,
        Paint()
          ..color = c.withValues(alpha: (0.7 * fade).clamp(0.0, 1.0))
          ..blendMode = BlendMode.plus,
      );
    }
  }

  Path _flamePath(double w, double h, double baseY) {
    return Path()
      ..moveTo(0, baseY)
      ..quadraticBezierTo(w, baseY - h * 0.35, w * 0.25, baseY - h * 0.7)
      ..quadraticBezierTo(0, baseY - h * 0.9, 0, baseY - h)
      ..quadraticBezierTo(0, baseY - h * 0.9, -w * 0.25, baseY - h * 0.7)
      ..quadraticBezierTo(-w, baseY - h * 0.35, 0, baseY)
      ..close();
  }

  @override
  void onRemove() {
    _detachEmbers();
    super.onRemove();
  }
}
