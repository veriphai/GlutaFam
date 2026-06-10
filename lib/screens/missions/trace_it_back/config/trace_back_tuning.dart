// Tunable constants + pure math for Trace It Back (Episode 1 · beat 1.1) · v2.
//
// v2 is a VERTICAL, mobile-first chain (PRD §3): top→bottom is
//   bulb → WIRE → coil/magnet → SHAFT → turbine → FLOW → source.
// Vertical gives each hero component full width to be large and finger-operable.
// Geometry anchors are FACTORS of the Flame stage rect (resolution-independent);
// a live on-device pass is expected, so a nudge is a one-number edit.
//
// THE LOAD-BEARING RULE (PRD §4.2/§4.3, criterion 4): when the kid stops turning
// (the magnet in b1, the turbine in b2), brightness / current-pulse / field-line
// bloom snap to ZERO the same frame — a hard gate, never a fade. In b3 the source
// drives the turning continuously, so the chain is steadily lit (correct — a plant
// doesn't tire); the cutoff is only ever about the KID's input stopping.

import 'dart:math' as math;
import 'dart:ui' show Offset;

class TBTune {
  TBTune._();

  // --- Induction physics (the magnet → coil → wire → bulb core) ------------

  /// Angular speed (rad/s, absolute) below which NOTHING generates — a held-still
  /// magnet/turbine stays dark (the b1 discovery state), and a barely-turning one.
  static const double lowSpeedFloor = 1.3;

  /// Speed mapped to full energy. abs(angularVelocity) clamps into
  /// [lowSpeedFloor, maxSpeed] then normalises to [0,1].
  static const double maxSpeed = 11.0;

  /// Brightness at/above which the bulb counts as "clearly lit" — arms discovery.
  static const double clearlyLitThreshold = 0.34;

  /// energyInput = normalize(abs(angularVelocity)). Sign is discarded (either
  /// direction generates); the sign only rotates the magnet/turbine visual.
  static double normalizeEnergy(double angularVelocity) {
    final v = angularVelocity.abs();
    if (v <= lowSpeedFloor) return 0.0;
    return ((v - lowSpeedFloor) / (maxSpeed - lowSpeedFloor)).clamp(0.0, 1.0);
  }

  static bool isGeneratingAt(double angularVelocity) =>
      angularVelocity.abs() > lowSpeedFloor;

  /// Normalised energy → target brightness along a gentle curve.
  static double brightnessCurve(double energyInput) =>
      math.pow(energyInput.clamp(0.0, 1.0), 0.85).toDouble();

  /// Low-pass time constant (s) on brightness WHILE generating; BYPASSED on stop.
  static const double rippleTau = 0.11;

  /// Hard-gated to 0 on stop (no fade, no coast-down). The pedagogical payload.
  static const double stopBrightness = 0.0;

  /// A new gesture sample must arrive within this window or angular velocity
  /// decays to zero — covers BOTH release and a held-still grab with one rule.
  static const double sampleTimeoutSeconds = 0.10;

  // --- Beat 3 — the source takes over the turning (the handoff) -------------

  /// The source drives the turbine at a steady angular velocity (rad/s) — the
  /// tireless replacement for the kid's hand. Clearly lit, continuous.
  static const double sourceDriveAV = 7.5;

  /// Solar bypasses the turbine + magnet: light → electricity directly. Its
  /// steady output (with a faint shimmer applied in the controller).
  static const double solarBaseEnergy = 0.82;

  // --- Wire energy pulse (ONLY on the wire — electricity is born at the magnet)
  static const double pulseSpeed = 1.6; // cycles/s while generating

  // --- Discovery salience ---------------------------------------------------
  static const double discoveryFlashSeconds = 0.7;

  // --- Geometry anchors (factors of the Flame stage rect) ──────────────────
  // VERTICAL chain down the centre, top→bottom. centre = (x*w, y*h).
  // Eyeballed; expect a live tuning pass.

  static const Offset bulbFactor = Offset(0.5, 0.245);
  static const Offset magnetFactor = Offset(0.5, 0.44); // coil + magnet
  static const Offset turbineFactor = Offset(0.5, 0.635);
  static const Offset sourceFactor = Offset(0.5, 0.825);

  /// WIRE — bulb bottom → coil top (electrical; carries the current-pulse).
  static const Offset wireStartFactor = Offset(0.5, 0.335);
  static const Offset wireEndFactor = Offset(0.5, 0.385);

  /// SHAFT — magnet bottom → turbine top (mechanical; rotation, NO pulse).
  static const Offset shaftStartFactor = Offset(0.5, 0.515);
  static const Offset shaftEndFactor = Offset(0.5, 0.565);

  /// FLOW — turbine bottom → source top (per-source particle stream).
  static const Offset flowStartFactor = Offset(0.5, 0.725);
  static const Offset flowEndFactor = Offset(0.5, 0.770);

  /// Element sizes as factors of stage WIDTH — bigger now we use the full column
  /// height (vertical lets the hero be big — §7).
  static const double bulbRadiusFactor = 0.115;
  static const double coilRadiusFactor = 0.125;
  static const double magnetLenFactor = 0.25;
  static const double turbineRadiusFactor = 0.155;
  static const double sourceRadiusFactor = 0.125;
}
