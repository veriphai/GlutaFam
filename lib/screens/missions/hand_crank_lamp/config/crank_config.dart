// Tunable constants + pure math helpers for the Hand-Crank LED Lamp (beat P.1).
//
// Everything here is data: the speed/brightness physics, the geometry anchors
// (expressed as FACTORS of the stage rect, never pixels — resolution
// independent), and the timing knobs. A live on-device tuning pass is expected;
// keeping it all in one place means a nudge is a one-number edit.
//
// PRD references are inline so the "why" of each magic number is traceable.

import 'dart:math' as math;

import 'dart:ui' show Offset;

class CrankConfig {
  CrankConfig._();

  // --- Speed → energy (PRD §4.2, §4.3) -------------------------------------

  /// The angular speed (rad/s, absolute) below which NOTHING generates.
  /// "Barely turning it" must produce no light, so effort feels connected to
  /// output (PRD §4.3) and a held-still crank stays dark (PRD §4.4, criterion 6).
  static const double lowSpeedFloor = 1.3;

  /// The speed mapped to full energy. abs(angularVelocity) is clamped into
  /// [lowSpeedFloor, maxSpeed] then normalised to [0,1].
  static const double maxSpeed = 11.0;

  /// Brightness at/above which the lamp counts as "clearly lit" — arms the
  /// discovery condition (PRD §4.2, default 0.35, tunable).
  static const double clearlyLitThreshold = 0.35;

  /// `energyInput = normalize(abs(angularVelocity))` (PRD §2-change-2, §4.3).
  /// The SIGN is deliberately discarded here — cranking either direction
  /// generates (criterion 3); the sign only ever rotates the handle on screen.
  static double normalizeEnergy(double angularVelocity) {
    final v = angularVelocity.abs();
    if (v <= lowSpeedFloor) return 0.0;
    final t = (v - lowSpeedFloor) / (maxSpeed - lowSpeedFloor);
    return t.clamp(0.0, 1.0);
  }

  /// Is the learner actually MAKING electricity right now? Keys off MOTION,
  /// never pointer contact (PRD §4.2) — this is the `isPointerDown` ≠
  /// `isGenerating` split that protects the lesson.
  static bool isGeneratingAt(double angularVelocity) =>
      angularVelocity.abs() > lowSpeedFloor;

  /// Maps normalised energy → target brightness along a gentle curve so effort
  /// reads as proportional to light without a harsh knee. Stays in [0,1].
  static double brightnessCurve(double energyInput) =>
      math.pow(energyInput.clamp(0.0, 1.0), 0.85).toDouble();

  // --- Ripple smoothing vs the stop envelope (PRD §4.3, §4.4) ---------------

  /// Low-pass time constant (seconds) applied to brightness WHILE generating,
  /// so a real crank's per-rotation ripple reads as a steady glow (the "LED
  /// smoothing capacitor" analog, PRD §4.3, criterion 2).
  static const double rippleTau = 0.11;

  /// The smoothing of [rippleTau] is BYPASSED on stop. When generation ceases,
  /// brightness is hard-gated to 0 — no eased fade, no coast-down (PRD §4.4,
  /// criterion 4: ≤2% within 50 ms). This is the pedagogical payload.
  static const double stopBrightness = 0.0;

  /// A new pointer sample must arrive within this window or angular velocity
  /// decays to zero. Covers BOTH release and a held-still crank with one rule
  /// (PRD §6: "rotation below floor for ~100 ms ⇒ not generating").
  static const double sampleTimeoutSeconds = 0.10;

  // --- Wire energy pulse (PRD §4.5) ----------------------------------------

  /// Pulse travel speed along the wire (cycles/second) while generating. The
  /// pulse exists ONLY while `isGenerating` and vanishes the instant it goes
  /// false (criterion 7) — handled in the controller, not here.
  static const double pulseSpeed = 1.6;

  // --- Discovery salience (PRD §3.1, §4.6, §6) ------------------------------

  /// `onDiscovery` visual emphasis duration (the ring/flash on lamp + wire).
  static const double discoveryFlashSeconds = 0.7;

  /// Gap between the `onDiscovery` visual (fires AT the cutoff) and the spoken
  /// `afterLine` (~300–500 ms later, PRD §4.6 / §3.1-change-1).
  static const int discoveryToAfterMs = 420;

  // --- Idle nudges (PRD §3.1, §5) ------------------------------------------

  /// Fire `onIdle` LATE and sparingly — exploration needs pauses (PRD §3.1).
  static const int idleThresholdMs = 7000;

  // --- Geometry anchors (factors of the stage rect) ------------------------
  // Eyeballed; expect a live tuning pass. centre = (x*w, y*h).

  /// Crank pivot — left third, vertically centred on the stage.
  static const Offset pivotFactor = Offset(0.24, 0.52);

  /// Handle arm length as a factor of stage width.
  static const double handleLenFactor = 0.115;

  /// Output device (lamp/fan/heater/speaker) centre — right third.
  static const Offset outputFactor = Offset(0.76, 0.46);

  /// Output glyph radius as a factor of stage width.
  static const double outputRadiusFactor = 0.135;

  /// Where the wire meets the crank (at the pivot, so it visibly joins the base
  /// — emerges from under the housing/hub) and the output (just left of the
  /// device). Factors of the stage rect.
  static const Offset wireStartFactor = pivotFactor;
  static const Offset wireEndFactor = Offset(0.635, 0.50);
}
