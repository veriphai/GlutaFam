// THE tuning map for Orbit Launcher V2.
//
// Every spatial value is a FACTOR of the Flame stage size (resolution
// independent). The stage has two regimes that crossfade:
//   • GROUND  — NASA launchpad bg + parallax clouds; rocket lifts off / climbs
//   • SPACE   — atmosphere→space + curved Earth (fails) or full globe (orbit)
//
// Tune by editing one number here.

import 'dart:ui' show Color, Offset;

import '../state/orbit_launcher_state.dart';

class OT {
  OT._();

  // ── inputs → outcome (PRD §10; "almost" omitted → nearest failure) ──────────
  static const double defaultPower = 50;
  static const double defaultTilt = 50;

  static OrbitOutcome outcomeFor(double power, double tilt) {
    if (power < 45) return OrbitOutcome.notEnoughPower;
    if (tilt < 35) return OrbitOutcome.tooStraight;
    if (tilt > 80 && power < 75) return OrbitOutcome.tooMuchTilt;
    if (power > 85 && tilt > 75) return OrbitOutcome.tooFast;
    if (power >= 55 && power <= 82 && tilt >= 45 && tilt <= 72) {
      return OrbitOutcome.orbitLocked;
    }
    // a forgiving "almost" ring just outside the exact success zone
    if (power >= 50 && power <= 85 && tilt >= 38 && tilt <= 78) {
      return OrbitOutcome.almost;
    }
    // beyond that → nearest corrective nudge
    if (power < 55) return OrbitOutcome.notEnoughPower;
    if (tilt < 45) return OrbitOutcome.tooStraight;
    if (tilt > 72) return OrbitOutcome.tooMuchTilt;
    if (power > 82) return OrbitOutcome.tooFast;
    return OrbitOutcome.almost;
  }

  // ── rocket on the launchpad (GROUND framing) ────────────────────────────────
  static const double rocketWidthFactor = 0.34; // of stage width
  static const Offset rocketPadCenter = Offset(0.5, 0.585); // rests on the glowing pad
  static const Offset straightApex = Offset(0.5, 0.17); // top of the straight-up climb

  // ── parallax clouds (GROUND ascent) ─────────────────────────────────────────
  static const double cloudFarWidthFactor = 1.5; // overscan so it spans width
  static const double cloudNearWidthFactor = 1.7;
  static const double cloudFarRestY = 0.42; // resting band (factor of height)
  static const double cloudNearRestY = 0.72;
  static const double cloudFarScroll = 0.55; // how far it slides down per ascent (factor of height)
  static const double cloudNearScroll = 1.05; // near layer moves faster (parallax)

  // ── space framing ───────────────────────────────────────────────────────────
  // Curved-earth horizon (fail outcomes): a band filling the bottom.
  static const double horizonHeightFactor = 0.42; // of stage height
  static const double horizonBottomY = 1.04;
  // Full globe (orbit success + bridge).
  static const Offset globeCenter = Offset(0.5, 0.47);
  static const double globeWidthFactor = 0.62;
  static double get globeRadiusFactor => globeWidthFactor / 2;
  static const double orbitRadiusMul = 1.18;

  static const double satWidthFactor = 0.17; // satellite after separation

  // ── projectile physics (ballistic fail launches) ────────────────────────────
  // A real projectile: launch speed from power, angle from tilt, gravity each
  // frame. Height AND flight time scale with power, so weak launches are low &
  // short and strong ones are high & long ("obeying physics").
  static const double gFactor = 0.62; // gravity = gFactor × stageHeight (px/s²)
  static const double apexFracLow = 0.20; // straight-up apex (screen-height frac) at power 0
  static const double apexFracHigh = 0.80; // …at power 100
  static const double maxTiltRad = 1.15; // visual lean of the rocket at tilt 100 (~66°)
  static const double vxFactor = 0.85; // sideways speed = vxFactor × (tilt/100) × vy0

  /// Straight-up forced launch uses a fixed moderate power (no control yet).
  static const double straightPower = 56;

  // ── powered ascent to space (orbit / too-fast) ──────────────────────────────
  // The successful climb is a long cinematic ascent through the clouds; its
  // duration scales with power (more power → longer flight before it resolves).
  static const double ascentMinDur = 3.2;
  static const double ascentMaxDur = 6.5;
  static double ascentDurForPower(double power) =>
      ascentMinDur + (ascentMaxDur - ascentMinDur) * (power.clamp(0, 100) / 100);

  // ── other durations (seconds) ───────────────────────────────────────────────
  static const double spaceCrossfade = 0.9;
  static const double arcFlight = 1.7; // space arc tail (orbit lead-in)
  static const double escapeFlight = 1.6;
  static const double orbitEntry = 1.6; // fly-in before the orbit locks
  static const double orbitPeriod = 6.0;

  // ── outcome colours (match the mock card tags) ──────────────────────────────
  static const Color colAscend = Color(0xFF6FE0FF); // straight-up rise dashes
  static const Color colNotEnoughPower = Color(0xFFFF5A4D); // red
  static const Color colTooStraight = Color(0xFFFF8A3D); // orange
  static const Color colTooMuchTilt = Color(0xFFFF5E3A); // red-orange
  static const Color colTooFast = Color(0xFFB45CFF); // purple
  static const Color colAlmost = Color(0xFFFFD24A); // gold (near-miss arc)
  static const Color colOrbit = Color(0xFF5BE36B); // green (mock orbit ring)

  static Color trajColor(OrbitOutcome o) => switch (o) {
        OrbitOutcome.notEnoughPower => colNotEnoughPower,
        OrbitOutcome.tooStraight => colTooStraight,
        OrbitOutcome.tooMuchTilt => colTooMuchTilt,
        OrbitOutcome.tooFast => colTooFast,
        OrbitOutcome.almost => colAlmost,
        OrbitOutcome.orbitLocked => colOrbit,
      };
}
