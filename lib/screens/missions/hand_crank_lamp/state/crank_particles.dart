// Particle field for the cinematic energy (polish Phase B): sparks spat off the
// spinning handle (denser + faster with crank speed), and per-device debris —
// rising embers (heater), blown streaks (fan), drifting light motes (lamp).
//
// All particles are CLEARED instantly on stop (the controller calls clear()),
// so the cutoff is total — nothing lingers, honouring the lesson.

import 'dart:math' as math;

import 'package:flutter/material.dart' show Color, Offset;

class Particle {
  Particle({
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

class ParticleField {
  final List<Particle> particles = [];
  final math.Random _rng = math.Random();

  static const int _max = 150;
  double _sparkAcc = 0;
  double _deviceAcc = 0;

  void update(double dt) {
    for (final p in particles) {
      p.vel = Offset(p.vel.dx, p.vel.dy + p.gravity * dt);
      p.pos = p.pos + p.vel * dt;
      p.life -= dt;
    }
    particles.removeWhere((p) => p.life <= 0);
  }

  void clear() {
    if (particles.isNotEmpty) particles.clear();
    _sparkAcc = 0;
    _deviceAcc = 0;
  }

  void _add(Particle p) {
    if (particles.length < _max) particles.add(p);
  }

  /// Sparks flung off the knob, tangent to the spin, denser with [energy].
  void spawnSparks({
    required double dt,
    required Offset knob,
    required double knobSpeed,
    required double dirSign,
    required double handleAngle,
    required double energy,
    required Color color,
  }) {
    if (energy <= 0.05) return;
    _sparkAcc += dt * (4 + 46 * energy);
    final tangent = handleAngle + (dirSign >= 0 ? math.pi / 2 : -math.pi / 2);
    while (_sparkAcc >= 1) {
      _sparkAcc -= 1;
      final ang = tangent + (_rng.nextDouble() - 0.5) * 1.0;
      final speed = (50 + knobSpeed * 0.3) * (0.5 + _rng.nextDouble() * 0.9);
      _add(Particle(
        pos: knob + Offset((_rng.nextDouble() - 0.5) * 6, (_rng.nextDouble() - 0.5) * 6),
        vel: Offset(math.cos(ang), math.sin(ang)) * speed,
        life: 0.22 + _rng.nextDouble() * 0.26,
        maxLife: 0.48,
        size: 1.2 + _rng.nextDouble() * 1.8,
        color: color,
        gravity: 220,
      ));
    }
  }

  /// Rising embers from the heater coils.
  void spawnEmbers({
    required double dt,
    required Offset center,
    required double r,
    required double b,
    required Color color,
  }) {
    _deviceAcc += dt * (3 + 20 * b);
    while (_deviceAcc >= 1) {
      _deviceAcc -= 1;
      _add(Particle(
        pos: center + Offset((_rng.nextDouble() - 0.5) * r * 1.1, (_rng.nextDouble() - 0.1) * r * 0.5),
        vel: Offset((_rng.nextDouble() - 0.5) * 22, -42 - _rng.nextDouble() * 46),
        life: 0.5 + _rng.nextDouble() * 0.55,
        maxLife: 1.05,
        size: 1.4 + _rng.nextDouble() * 2.0,
        color: color,
        gravity: -14, // decelerate the rise
      ));
    }
  }

  /// Streaks blown outward by the fan (mostly horizontal, away from the crank).
  void spawnWind({
    required double dt,
    required Offset center,
    required double r,
    required double b,
    required Color color,
  }) {
    _deviceAcc += dt * (4 + 26 * b);
    while (_deviceAcc >= 1) {
      _deviceAcc -= 1;
      final ang = (_rng.nextDouble() - 0.5) * 0.85; // around horizontal-right
      final speed = 130 + _rng.nextDouble() * 150;
      _add(Particle(
        pos: center + Offset((_rng.nextDouble() - 0.5) * r * 0.6, (_rng.nextDouble() - 0.5) * r * 1.3),
        vel: Offset(math.cos(ang), math.sin(ang)) * speed,
        life: 0.28 + _rng.nextDouble() * 0.28,
        maxLife: 0.56,
        size: 1.0 + _rng.nextDouble() * 1.3,
        color: color,
        gravity: 0,
      ));
    }
  }

  /// Slow light motes drifting up around the lamp.
  void spawnMotes({
    required double dt,
    required Offset center,
    required double r,
    required double b,
    required Color color,
  }) {
    _deviceAcc += dt * (1.5 + 7 * b);
    while (_deviceAcc >= 1) {
      _deviceAcc -= 1;
      _add(Particle(
        pos: center + Offset((_rng.nextDouble() - 0.5) * r * 1.4, (_rng.nextDouble() - 0.5) * r * 1.0),
        vel: Offset((_rng.nextDouble() - 0.5) * 12, -14 - _rng.nextDouble() * 16),
        life: 0.7 + _rng.nextDouble() * 0.7,
        maxLife: 1.4,
        size: 1.0 + _rng.nextDouble() * 1.4,
        color: color,
        gravity: -6,
      ));
    }
  }
}
