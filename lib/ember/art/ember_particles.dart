// Ember — art/ember_particles.dart
//
// Semantic particle factories. The world + activities request an effect by
// [ParticleArtKey]; this builds the matching Flame [ParticleSystemComponent].
// Presentation-only (art/): the small per-mote jitter uses dart:math Random,
// which is fine here — particles are cosmetic and NEVER feed back into world
// state (the determinism fence covers core/data/sim/contracts/activity, not the
// FX layer).
//
// Each factory returns a self-contained component you add at a world position;
// it removes itself when its particle finishes (ParticleSystemComponent already
// removeFromParent()s when the inner Particle.shouldRemove flips true).

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';

import 'art_keys.dart';
import 'ember_palette.dart';

/// Builds keyed particle effects from the central palette.
class EmberParticles {
  EmberParticles({this.palette = EmberPalette.dusk});

  final EmberPalette palette;

  /// Cosmetic-only RNG (see file header). Not serialized, not world state.
  final math.Random _rng = math.Random();

  double _between(double a, double b) => a + _rng.nextDouble() * (b - a);

  /// Build the effect for [key] at the given local size hint [intensity]
  /// (1.0 = default). Returns a fresh, self-removing component.
  ParticleSystemComponent build(ParticleArtKey key, {double intensity = 1.0}) {
    return switch (key) {
      ParticleArtKey.ember => embers(intensity: intensity),
      ParticleArtKey.spark => sparks(intensity: intensity),
      ParticleArtKey.chip => chips(intensity: intensity),
      ParticleArtKey.rain => rain(intensity: intensity),
      ParticleArtKey.splash => splash(intensity: intensity),
      ParticleArtKey.dust => dust(intensity: intensity),
      ParticleArtKey.smoke => smoke(intensity: intensity),
    };
  }

  /// Slow rising warm motes (over a fire). Loops by re-emitting via short life.
  ParticleSystemComponent embers({double intensity = 1.0}) {
    final int count = (8 * intensity).round().clamp(3, 24);
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: _between(1.2, 2.0),
        generator: (int i) {
          final double r = _between(1.0, 2.6);
          final Color c = i.isEven ? palette.ember : palette.emberBright;
          return AcceleratedParticle(
            acceleration: Vector2(_between(-4, 4), -2),
            speed: Vector2(_between(-6, 6), _between(-26, -42)),
            position: Vector2(_between(-6, 6), 0),
            child: ComputedParticle(
              renderer: (Canvas canvas, Particle p) {
                final double fade = (1.0 - p.progress).clamp(0.0, 1.0);
                canvas.drawCircle(
                  Offset.zero,
                  r * fade,
                  Paint()..color = c.withValues(alpha: fade),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Fast bright pops (ignite, success burst). Radial spray.
  ParticleSystemComponent sparks({double intensity = 1.0}) {
    final int count = (14 * intensity).round().clamp(6, 40);
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: _between(0.4, 0.8),
        generator: (int i) {
          final double angle = _between(0, math.pi * 2);
          final double spd = _between(40, 120);
          return AcceleratedParticle(
            acceleration: Vector2(0, 80),
            speed: Vector2(math.cos(angle) * spd, math.sin(angle) * spd - 30),
            child: ComputedParticle(
              renderer: (Canvas canvas, Particle p) {
                final double fade = (1.0 - p.progress).clamp(0.0, 1.0);
                canvas.drawCircle(
                  Offset.zero,
                  _between(1.0, 2.2) * fade,
                  Paint()..color = palette.spark.withValues(alpha: fade),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Stone flakes flying off a knapping strike. Sideways + gravity, grey shards.
  ParticleSystemComponent chips({double intensity = 1.0}) {
    final int count = (10 * intensity).round().clamp(4, 24);
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: _between(0.5, 0.9),
        generator: (int i) {
          final double dir = i.isEven ? 1 : -1;
          final double len = _between(2.5, 5.0);
          return AcceleratedParticle(
            acceleration: Vector2(0, 160),
            speed: Vector2(dir * _between(30, 90), _between(-60, -20)),
            child: ComputedParticle(
              renderer: (Canvas canvas, Particle p) {
                final double fade = (1.0 - p.progress).clamp(0.0, 1.0);
                final Paint paint = Paint()
                  ..color = palette.stoneChip.withValues(alpha: fade);
                canvas.drawRect(
                  Rect.fromCenter(
                      center: Offset.zero, width: len * fade, height: 2.0),
                  paint,
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Falling rain streaks (storm / wet weather). Cover a wide band.
  ParticleSystemComponent rain({double intensity = 1.0}) {
    final int count = (24 * intensity).round().clamp(8, 80);
    final double span = 140.0 * intensity;
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: _between(0.5, 0.9),
        generator: (int i) {
          final double x = _between(-span, span);
          return AcceleratedParticle(
            acceleration: Vector2(8, 60),
            speed: Vector2(20, _between(260, 360)),
            position: Vector2(x, _between(-span, -span * 0.4)),
            child: ComputedParticle(
              renderer: (Canvas canvas, Particle p) {
                final double fade = (1.0 - p.progress * 0.4).clamp(0.0, 1.0);
                final Paint paint = Paint()
                  ..color = palette.water.withValues(alpha: 0.55 * fade)
                  ..strokeWidth = 1.6
                  ..strokeCap = StrokeCap.round;
                canvas.drawLine(Offset.zero, const Offset(2, 10), paint);
              },
            ),
          );
        },
      ),
    );
  }

  /// Upward water splash (flood / river edge). Droplets arc up + out.
  ParticleSystemComponent splash({double intensity = 1.0}) {
    final int count = (12 * intensity).round().clamp(5, 30);
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: _between(0.5, 0.9),
        generator: (int i) {
          final double dir = _between(-1, 1);
          return AcceleratedParticle(
            acceleration: Vector2(0, 220),
            speed: Vector2(dir * _between(20, 70), _between(-140, -90)),
            child: ComputedParticle(
              renderer: (Canvas canvas, Particle p) {
                final double fade = (1.0 - p.progress).clamp(0.0, 1.0);
                canvas.drawCircle(
                  Offset.zero,
                  _between(1.4, 3.0) * fade,
                  Paint()..color = palette.waterDeep.withValues(alpha: fade),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Soft dust puff (build complete, footfalls). Low, spreading, fading.
  ParticleSystemComponent dust({double intensity = 1.0}) {
    final int count = (9 * intensity).round().clamp(4, 20);
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: _between(0.5, 0.9),
        generator: (int i) {
          final double angle = _between(-math.pi, 0); // upper hemisphere out
          final double spd = _between(20, 50);
          return AcceleratedParticle(
            acceleration: Vector2(0, 30),
            speed: Vector2(math.cos(angle) * spd, math.sin(angle) * spd * 0.5),
            child: ComputedParticle(
              renderer: (Canvas canvas, Particle p) {
                final double grow = 1.0 + p.progress * 1.6;
                final double fade = (1.0 - p.progress).clamp(0.0, 1.0);
                canvas.drawCircle(
                  Offset.zero,
                  _between(2.0, 4.0) * grow,
                  Paint()..color = palette.highGround.withValues(alpha: 0.4 * fade),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Drifting smoke wisp (low / extinguished fire). Slow rise + grow + fade.
  ParticleSystemComponent smoke({double intensity = 1.0}) {
    final int count = (6 * intensity).round().clamp(3, 16);
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: _between(1.6, 2.6),
        generator: (int i) {
          return AcceleratedParticle(
            acceleration: Vector2(_between(-3, 6), -1),
            speed: Vector2(_between(-4, 4), _between(-14, -26)),
            position: Vector2(_between(-4, 4), 0),
            child: ComputedParticle(
              renderer: (Canvas canvas, Particle p) {
                final double grow = 1.0 + p.progress * 2.2;
                final double fade = (1.0 - p.progress).clamp(0.0, 1.0) * 0.35;
                canvas.drawCircle(
                  Offset.zero,
                  _between(3.0, 5.0) * grow,
                  Paint()
                    ..color = palette.inkSoft.withValues(alpha: fade)
                    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
