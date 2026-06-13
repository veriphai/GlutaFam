// The heat particle field for Squared Loss (PRD §10) — adapted from the
// hand_crank_lamp crank_particles. TWO populations:
//   • EMBERS  — heat #FF7A2E, additive (the painter draws with BlendMode.plus),
//     spawned ALONG the wire span, drifting upward, lifetime ~1.4 s; spawn rate
//     scales with heat so the density itself reads the square. Capped at 48.
//   • MOTES   — a handful of slow cool ambient motes so the dark field breathes.
//
// The felt channel (embers thickening with the square) responds same-frame: spawn
// rate is recomputed every tick from the live wireGlow — no easing on the field.

import 'dart:math' as math;

import 'package:flutter/material.dart' show Color, Offset;

import '../config/squared_loss_tuning.dart';

class HeatParticle {
  HeatParticle({
    required this.pos,
    required this.vel,
    required this.life,
    required this.maxLife,
    required this.size,
    required this.color,
    this.gravity = 0,
  });

  Offset pos;
  Offset vel;
  double life;
  final double maxLife;
  final double size;
  final Color color;
  final double gravity; // +down, -up (embers rise)

  double get alpha => (life / maxLife).clamp(0.0, 1.0);
}

class HeatParticleField {
  final List<HeatParticle> embers = [];
  final List<HeatParticle> motes = [];
  final math.Random _rng = math.Random(7);

  double _emberAcc = 0;
  double _moteAcc = 0;

  /// Advance both populations; reap dead particles.
  void update(double dt) {
    for (final p in embers) {
      p.vel = Offset(p.vel.dx, p.vel.dy + p.gravity * dt);
      p.pos = p.pos + p.vel * dt;
      p.life -= dt;
    }
    embers.removeWhere((p) => p.life <= 0);
    for (final p in motes) {
      p.pos = p.pos + p.vel * dt;
      p.life -= dt;
    }
    motes.removeWhere((p) => p.life <= 0);
  }

  void clear() {
    embers.clear();
    motes.clear();
    _emberAcc = 0;
    _moteAcc = 0;
  }

  /// Embers spawned along the catenary span [leftAnchor]→[rightAnchor] sagging to
  /// [sagY], at a rate that grows with [glow] (the square). [calm] slows the
  /// spawn for reduced-motion. The painter renders these additively.
  void spawnEmbers({
    required double dt,
    required Offset leftAnchor,
    required Offset rightAnchor,
    required double sagY,
    required double glow,
    required Color color,
    bool calm = false,
  }) {
    if (glow <= 0.02) return;
    final rate = (2 + 70 * glow) * (calm ? 0.4 : 1.0);
    _emberAcc += dt * rate;
    while (_emberAcc >= 1) {
      _emberAcc -= 1;
      if (embers.length >= SLTune.maxEmbers) {
        _emberAcc = 0;
        break;
      }
      // Pick a point along the catenary (parabolic sag).
      final t = _rng.nextDouble();
      final x = leftAnchor.dx + (rightAnchor.dx - leftAnchor.dx) * t;
      final lineY = leftAnchor.dy + (rightAnchor.dy - leftAnchor.dy) * t;
      final sag = 4 * sagY * t * (1 - t); // 0 at ends, sagY-scaled at mid
      final y = lineY + sag;
      final speed = 30 + 60 * glow + _rng.nextDouble() * 26;
      embers.add(HeatParticle(
        pos: Offset(x + (_rng.nextDouble() - 0.5) * 6, y),
        vel: Offset((_rng.nextDouble() - 0.5) * 20, -speed),
        life: SLTune.emberLifeMin +
            _rng.nextDouble() * (SLTune.emberLifeMax - SLTune.emberLifeMin),
        maxLife: SLTune.emberLifeMax,
        size: 1.3 + _rng.nextDouble() * (1.6 + 1.4 * glow),
        color: color,
        gravity: -10, // decelerate the rise so they hang then fade
      ));
    }
  }

  /// A DENSE one-shot puff of embers off the span — fired at the ×2 / ×3 detent
  /// landings to dramatize the 4× LEAP ("nudge a little → jumps a LOT"). The count
  /// scales with [glow] so ×3 (glow ≈ 0.56) puffs ~2× harder than ×2 (glow ≈ 0.25).
  /// These are faster + brighter than the steady embers so the burst reads as a
  /// shove of heat, not a fade-in.
  void burstEmbers({
    required Offset leftAnchor,
    required Offset rightAnchor,
    required double sagY,
    required double glow,
    required Color color,
    bool calm = false,
  }) {
    final count = ((SLTune.emberBurstBase + SLTune.emberBurstPerGlow * glow) *
            (calm ? 0.45 : 1.0))
        .round();
    for (var i = 0; i < count; i++) {
      if (embers.length >= SLTune.maxEmbers) break;
      final t = _rng.nextDouble();
      final x = leftAnchor.dx + (rightAnchor.dx - leftAnchor.dx) * t;
      final lineY = leftAnchor.dy + (rightAnchor.dy - leftAnchor.dy) * t;
      final sag = 4 * sagY * t * (1 - t);
      final y = lineY + sag;
      final speed = SLTune.emberBurstSpeedMin +
          _rng.nextDouble() * (SLTune.emberBurstSpeedMax - SLTune.emberBurstSpeedMin);
      embers.add(HeatParticle(
        pos: Offset(x + (_rng.nextDouble() - 0.5) * 10, y),
        vel: Offset((_rng.nextDouble() - 0.5) * 60, -speed * (0.6 + 0.4 * glow)),
        life: SLTune.emberLifeMin * (0.7 + _rng.nextDouble() * 0.5),
        maxLife: SLTune.emberLifeMax,
        size: 1.6 + _rng.nextDouble() * (2.0 + 2.0 * glow),
        color: color,
        gravity: 30, // burst embers arc: shoved up, then fall back a touch
      ));
    }
  }

  /// A few slow cool ambient motes across the [stageW]×[stageH] field.
  void spawnMotes({
    required double dt,
    required double stageW,
    required double stageH,
    required Color color,
    bool calm = false,
  }) {
    final rate = calm ? 0.6 : 1.4;
    _moteAcc += dt * rate;
    while (_moteAcc >= 1) {
      _moteAcc -= 1;
      if (motes.length >= SLTune.maxMotes) {
        _moteAcc = 0;
        break;
      }
      motes.add(HeatParticle(
        pos: Offset(_rng.nextDouble() * stageW, stageH * (0.4 + _rng.nextDouble() * 0.6)),
        vel: Offset((_rng.nextDouble() - 0.5) * 8, -6 - _rng.nextDouble() * 8),
        life: 3.0 + _rng.nextDouble() * 3.0,
        maxLife: 6.0,
        size: 0.8 + _rng.nextDouble() * 1.1,
        color: color,
      ));
    }
  }
}
