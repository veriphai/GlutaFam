// Ember — core/constants.dart
//
// Centralized tuning. Pure constants only (no clock/random). Anything the sim,
// seed, or balancing touches lives here so designers tweak one file. The flood
// damage curve is exposed as a pure function (no state).

import 'enums.dart';

class EmberConstants {
  const EmberConstants._();

  // ---- World shape -------------------------------------------------------
  /// The starting map is a small, hand-readable square.
  static const int gridWidth = 16;
  static const int gridHeight = 16;

  // ---- Simulation cadence ------------------------------------------------
  /// Fixed sim step. WorldSimulation loops this many ms per system pass; this
  /// fixed step is the determinism contract (live + offline + tests align).
  static const int stepMs = 1000;

  /// Offline catch-up is capped so a player gone a week doesn't fast-forward a
  /// week of events. 12 hours.
  static const int offlineCapMs = 12 * 60 * 60 * 1000;

  // ---- Day / night -------------------------------------------------------
  /// One full day-night cycle, in ms (default 8 real minutes).
  static const int dayLengthMs = 8 * 60 * 1000;

  /// Phase (0..1) at/after which it counts as night.
  static const double nightStartPhase = 0.55;

  /// Phase (0..1) before which it counts as night (wraps past 1.0 -> dawn).
  static const double nightEndPhase = 0.95;

  // ---- Fire / fuel -------------------------------------------------------
  /// Fuel a fresh fire holds (arbitrary fuel units).
  static const double fireFuelCapacity = 100.0;

  /// Fuel burned per second by a lit fire (base, tier 1).
  static const double fireFuelBurnPerSec = 0.5;

  /// Fuel restored per "tend" interaction.
  static const double fireFuelPerTend = 30.0;

  /// Light radius (tiles) of a base hearth at full fuel.
  static const double fireBaseLightRadius = 3.0;

  // ---- Resources ---------------------------------------------------------
  /// Default per-type storage cap when a new game starts.
  static const int defaultResourceCap = 200;

  /// Default "low" threshold that flips a resource into a warning state.
  static const int defaultResourceThreshold = 20;

  /// Base yield pulled from a node per gather action (before tool multiplier).
  static const int baseGatherYield = 5;

  /// Default node regrowth per second (food regrows; wood/stone are 0 here).
  static const double defaultRegrowRate = 0.0;
  static const double foodRegrowRate = 0.02;

  // ---- Population / shelter ---------------------------------------------
  /// Population a brand-new village supports before any shelter is built.
  static const int basePopulationCap = 3;

  // ---- Events ------------------------------------------------------------
  /// Earliest (ms into the game) the flood event may be scheduled.
  static const int floodEarliestMs = 6 * 60 * 1000;

  /// Base per-night chance a predator event is scheduled (sim may modulate).
  static const double predatorBaseChance = 0.25;

  /// Base per-day chance the tribe sets out on a stylized spear hunt (only once
  /// Stone Tools is learned). Rolled once per day during daylight; deterministic.
  static const double huntBaseChance = 0.5;

  // ---- Flood damage curve ------------------------------------------------
  /// Flood damage applied to a placeable as a fraction of build progress, as a
  /// PURE function of (a) how flood-prone its tile is [floodRisk in 0..1] and
  /// (b) the event's [severity] in 0..1. No randomness in here — callers feed
  /// any rng-derived severity in. Result clamped to [0,1].
  ///
  /// Shape: damage = severity * floodRisk^0.75, gently sub-linear in risk so a
  /// low-risk tile shrugs most floods off while a riverbank tile takes the hit.
  static double floodDamageFraction({
    required double floodRisk,
    required double severity,
  }) {
    final double r = floodRisk.clamp(0.0, 1.0);
    final double s = severity.clamp(0.0, 1.0);
    final double shaped = _pow(r, 0.75);
    return (s * shaped).clamp(0.0, 1.0);
  }

  // ---- Season weighting --------------------------------------------------
  /// Multiplier on flood likelihood per season (wet season floods more).
  static double floodSeasonMultiplier(Season s) => switch (s) {
        Season.warm => 0.6,
        Season.cold => 0.4,
        Season.wet => 1.4,
      };

  /// Multiplier on cold-night likelihood per season.
  static double coldSeasonMultiplier(Season s) => switch (s) {
        Season.warm => 0.2,
        Season.cold => 1.5,
        Season.wet => 0.8,
      };
}

/// Small integer/float power without dart:math import churn for fractional
/// exponents we need at constant-eval-time-ish call sites. Uses exp/ln via a
/// cheap series-free path: defer to dart:math.pow through a thin wrapper kept
/// local so constants.dart stays import-light.
double _pow(double base, double exp) {
  if (base <= 0) return 0.0;
  // a^b = e^(b * ln a)
  return _exp(exp * _ln(base));
}

// Minimal exp/ln so we avoid importing dart:math just for one curve. These are
// standard, deterministic, and pure.
double _ln(double x) {
  // ln via atanh series: ln(x) = 2*atanh((x-1)/(x+1)).
  final double t = (x - 1) / (x + 1);
  final double t2 = t * t;
  double term = t;
  double sum = 0.0;
  for (int k = 0; k < 24; k++) {
    sum += term / (2 * k + 1);
    term *= t2;
  }
  return 2 * sum;
}

double _exp(double x) {
  // Taylor series; x here is small/negative (b*ln a with a in (0,1]) so it
  // converges fast.
  double term = 1.0;
  double sum = 1.0;
  for (int k = 1; k < 32; k++) {
    term *= x / k;
    sum += term;
  }
  return sum;
}
