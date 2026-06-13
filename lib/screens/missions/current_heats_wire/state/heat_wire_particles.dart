// Heat shimmer for The Hot Wire — pooled rising heat motes shed off the glowing
// span, plus a calm far-layer of ambient cool motes.
//
// THE LOAD-BEARING RULE: heat-mote spawning is driven by a spawn RATE the
// controller hands in each frame; that rate is HARD 0 the instant heatInput is 0
// (current at 0 with no rub). Already-airborne motes finish their short rise and
// dissolve — that is them leaving as heat, not a softening fade of generation.
// The controller never spawns once heatInput hits 0.

import 'dart:math' as math;

import 'package:flutter/painting.dart' show Offset;

class HeatMote {
  HeatMote({
    required this.pos,
    required this.vel,
    required this.life,
    required this.maxLife,
    required this.size,
    required this.warmth,
    required this.swayAmp,
    required this.swayPhase,
    required this.swayFreq,
  });

  Offset pos;
  Offset vel;
  double life;
  final double maxLife;
  final double size;
  final double warmth; // 0..1 — hotter motes glow more orange near the wire
  // a gentle horizontal sine sway so the rising motes read as heat-shimmer, not
  // a straight upward stream.
  final double swayAmp;
  final double swayPhase;
  final double swayFreq;
  double age = 0;

  double get alpha => (life / maxLife).clamp(0.0, 1.0);
}

/// The rising heat shimmer. Emission rate is supplied per frame by the controller
/// (it bakes in heatInput, beat-C emphasis, and the hard 0 cutoff).
class HeatMoteField {
  HeatMoteField({required this.maxMotes, required this.life, required this.riseTopY});

  final int maxMotes;
  final double life;
  final double riseTopY; // pixel y the motes drift toward
  final List<HeatMote> motes = [];
  final math.Random _rng = math.Random();
  double _acc = 0;

  void update(double dt) {
    for (final m in motes) {
      m.age += dt;
      m.vel = Offset(m.vel.dx, m.vel.dy - 6 * dt); // gentle upward decel
      // horizontal shimmer sway (a derivative of the sine, so it reads as drift,
      // not teleport): the mote curls side to side as it rises.
      final sway = m.swayAmp * m.swayFreq *
          math.cos(m.age * m.swayFreq + m.swayPhase) * dt;
      m.pos = Offset(m.pos.dx + m.vel.dx * dt + sway, m.pos.dy + m.vel.dy * dt);
      m.life -= dt;
    }
    motes.removeWhere((m) => m.life <= 0 || m.pos.dy <= riseTopY);
  }

  /// Spawn along the glowing span. [ratePerSec] already includes heatInput +
  /// emphasis; pass 0 to stop dead (the controller does this the frame current 0).
  /// [spanPoint] returns a point on the catenary for a given t in [0,1].
  void spawn({
    required double dt,
    required double ratePerSec,
    required double Function() pickT,
    required Offset Function(double t) spanPoint,
    required double riseSpeed,
  }) {
    if (ratePerSec <= 0) return;
    _acc += dt * ratePerSec;
    while (_acc >= 1) {
      _acc -= 1;
      if (motes.length >= maxMotes) break;
      final t = pickT();
      final base = spanPoint(t);
      motes.add(HeatMote(
        pos: base + Offset((_rng.nextDouble() - 0.5) * 6, 0),
        vel: Offset((_rng.nextDouble() - 0.5) * 10, -riseSpeed * (0.7 + _rng.nextDouble() * 0.6)),
        life: life * (0.7 + _rng.nextDouble() * 0.5),
        maxLife: life,
        size: 1.2 + _rng.nextDouble() * 2.2,
        warmth: 0.6 + _rng.nextDouble() * 0.4,
        swayAmp: 7 + _rng.nextDouble() * 12, // px of horizontal curl
        swayPhase: _rng.nextDouble() * math.pi * 2,
        swayFreq: 2.2 + _rng.nextDouble() * 1.8,
      ));
    }
  }

  /// Drop the spawn accumulator (so a stop never bursts a backlog later).
  void resetSpawnAccumulator() => _acc = 0;
}

/// A single calm far-layer mote — cool, dim, barely drifting. These are ambient
/// scene texture (PRD §16: <=20), independent of heat.
class AmbientMote {
  AmbientMote(this.x, this.y, this.size, this.warm, this.driftPhase);
  double x; // 0..1 factor
  double y; // 0..1 factor
  final double size;
  final bool warm;
  final double driftPhase;
}

class AmbientMoteField {
  AmbientMoteField(int count) {
    final r = math.Random(13);
    for (var i = 0; i < count; i++) {
      _motes.add(AmbientMote(
        r.nextDouble(),
        r.nextDouble(),
        1.0 + r.nextDouble() * 1.3,
        i.isEven,
        r.nextDouble(),
      ));
    }
  }

  final List<AmbientMote> _motes = [];
  List<AmbientMote> get motes => _motes;
}
