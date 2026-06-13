// Tunable constants + pure math for AC vs DC (Episode 2 · beat 2.7).
//
// The scene is a VERTICAL portrait staging (PRD §16): bulb top-center → output
// line → the iron CORE (hero, center) with its two FIXED coils → input line →
// the source dock (the one gesture surface) → a tiny current graph at the very
// bottom. All geometry is FACTORS of the Flame stage rect (resolution-
// independent); an on-device pass is expected, so a nudge is a one-number edit.
//
// THE LOAD-BEARING RULES (hard gates, enforced in the controller's tick — NEVER
// softened by a fade, including with reduced motion ON):
//   • outputLevel = fieldRate > eps ? f(fieldRate) : 0.0, every frame.
//   • bulbBrightness: fast attack, INSTANT release (≤2% within 50 ms of the field
//     settling) — never a decayed value.
//   • The steady DC feed reaches the SAME |current| height as the AC wave — the
//     failure reads as changelessness, never as low strength.
// This file only holds the knobs.

import 'dart:ui' show Offset;

class AcdcTune {
  AcdcTune._();

  // --- Coils (drawn, FIXED, never change — the held constant, matching 2.6) --
  static const int primaryTurns = 4; // LEFT limb
  static const int secondaryTurns = 8; // RIGHT limb

  // --- The honest engine -----------------------------------------------------
  /// fieldLevel follows currentLevel with this lag (seconds). Small → the field
  /// tracks the current closely; the rate of change is what drives the output.
  static const double fieldTau = 0.08;

  /// Below this |fieldRate| (normalised 0..1) the output is HARD-GATED to zero —
  /// the dead state. The DC steady feed and the gap between flips both sit here.
  static const double fieldRateEps = 0.06;

  /// Bulb attack/release time constants. Attack is fast; release is effectively
  /// instant so the bulb snaps dark the frame the field settles (≤50 ms to ≤2%).
  static const double bulbAttackTau = 0.045;
  static const double bulbReleaseTau = 0.012; // ≈ 2% in ~50 ms

  /// Normalisation: the max |d(field)/dt| we expect, used to map rate → 0..1.
  /// At wave speed the rate is near-continuously above eps → a steady bulb.
  static const double fieldRateNorm = 9.0;

  // --- The flip (scripted, NO momentum) --------------------------------------
  static const double flipAnimSeconds = 0.14; // battery 180° rotation
  static const double currentSweepSeconds = 0.12; // current +1 → −1 sweep
  /// A new flip is rejected until the current one is this far through (prevents
  /// a half-finished flip from being interrupted, which would muddy the kick).
  static const double flipReentryT = 0.6;

  // --- The flip gate (tunable; the burst must be genuinely felt) --------------
  static const int flipGateTotal = 5; // ≥5 total flips
  static const int flipBurstCount = 3; // ≥3 flips …
  static const double flipBurstWindow = 1.2; // … within 1.2 s
  static const double fastRunWindow = 0.9; // ≥2 flips within 0.9 s → feedback line

  // --- The machine oscillator (handoff → alive) ------------------------------
  static const double waveStartHz = 2.0; // slow at handoff
  static const double waveFullHz = 9.0; // render-rate-capped "50 Hz" feel
  static const double waveRampSeconds = 0.9; // alive ramp to full speed
  /// During handoff the wave's amplitude is pinned to the battery's flat-line
  /// height (±0 by construction): both reach exactly 1.0 on the graph.
  static const double currentAmplitude = 1.0;

  // --- The graph strip (tiny strip chart) ------------------------------------
  static const int graphSamples = 96; // ring buffer length
  static const double graphWindowSeconds = 2.6; // visible time window (DC/flip)
  static const double graphAliveWindowSeconds = 0.9; // compressed window in alive

  // --- The circulating flux loop (the HERO motion — ported from 2.6) ---------
  // The amber flux travels AROUND the iron window like a current loop, but ONLY
  // while the field is CHANGING (fieldRate > eps). On the steady DC feed and
  // between every pair of flips this loop is skipped entirely — the field is a
  // FAINT, MOTIONLESS amber (dead means motionless; that stillness IS the
  // discovery). These tune the travelling comet-heads + the base ribbon.
  static const double fluxLoopSpeed = 0.55; // perimeter laps / second when alive
  static const int fluxHeadCount = 2; // bright comet-heads circulating the window
  static const double fluxHeadSpanFactor = 0.34; // comet-tail length as a loop fraction
  static const int fluxTrailSamples = 16; // samples drawn along each comet head
  /// The FROZEN-DEAD base ribbon alpha — a faint static amber so the core stays
  /// the visual center even when dead, against the darkest vignette (the hero
  /// never goes black; it goes still). Kept low so nothing reads as "alive".
  static const double fluxRibbonAlphaFloor = 0.13; // base ribbon glow at rest (DEAD)
  static const double fluxRibbonAlphaGain = 0.52; // + this × |field| when changing
  static const double fluxStrokeFactor = 0.52; // ribbon stroke (× limbThickness)
  static const double fieldBloomGain = 0.58; // breath adds this much head brightness

  // --- Dimensional core + windings (ported from 2.6) -------------------------
  static const double coreBevelFactor = 0.16; // bevel/edge band (× limbThickness)
  static const int coreLaminations = 5; // hairline laminations per limb
  static const double coilLoopWidthFactor = 2.15; // loop ellipse width (× limbThickness)
  static const double coilWireFactor = 0.30; // copper wire stroke (× limbThickness)
  static const double coilSheenFactor = 0.10; // bright sheen highlight (× limbThickness)

  // --- Input / output cool-pulse cadence (ported from 2.6) -------------------
  static const int inputPulseCount = 3; // travelling pulses on the input run
  static const double inputPulseSpeed = 0.62; // input pulse laps / second
  static const int outputPulseCount = 3; // travelling pulses on the output run
  static const double outputPulseSpeed = 0.9; // output pulse laps / second

  // --- The glorious spring-to-life (alive flash; the ONE ≤1200 ms moment the
  //     bulb may briefly outshine the core) -----------------------------------
  static const double aliveFlashSeconds = 1.05; // ≤1200 ms — the bulb-outshines window
  static const double aliveBulbOvershoot = 1.18; // bulb floods past full at the burst

  // --- Phase timings (ms) — the §6 / §14 schedule ----------------------------
  // intro — now a SILENT entrance reveal (the two intro lines were cut), so it's
  // shorter (no text to read) → connect.
  static const int introMs = 2400;

  // connect — gate: battery tapped. Field ramp + freeze.
  static const double connectFieldRampSeconds = 0.6;
  // Doc-only: the honest connection flicker (§13.1) is EMERGENT, not gated. The
  // field rises once over connectFieldRampSeconds → fieldRate briefly > eps → one
  // organic kick. connectBlipSeconds is the felt width that emerges, not a knob
  // anything reads; do not wire it to gate the flicker.
  static const double connectBlipSeconds = 0.22;

  // steadyDead (auto) — witnessed absence, then the dead naming.
  static const int steadyHoldMs = 2800; // nothing, no text
  static const int steadyLine5DelayMs = 1600; // line 4 → +1600 → line 5 (heavyImpact)
  static const int steadyExitMs = 2600; // after line 5 → flipOnce

  // flipOnce — gate: first flip completed.
  static const int flipOnceLine7DelayMs = 700; // after first kick dies → line 7
  static const int flipOnceHoldMs = 2600; // line 7 held → flipFast

  // flipFast — gate: flipCount ≥ 5 AND a burst of ≥3 within 1200 ms.
  static const int flipFastLawHoldMs = 2800; // line 10 held → handoff

  // handoff (7600) — battery slides out, machine slides in, wave begins.
  static const int handoffMs = 7600;
  static const int handoffLine11Ms = 0; // doc-only 0 ms anchor — set inline in _enterHandoff
  static const int handoffSwapStartMs = 2600; // battery slides out / machine in
  static const int handoffSwapMs = 1400; // swap slide duration
  static const int handoffLine12Ms = 3200; // machine slid in
  static const int handoffLine13Ms = 5400; // amplitude-match line

  // alive (7400) — wave ramps to full, spring-to-life, the count.
  static const int aliveMs = 7400;
  static const int aliveFlashMs = 1200; // flash + heavyImpact + CAPTURE + line 14
  static const int aliveLabelMs = 3800; // 50-label + line 15 (1200 + 2600)
  static const int aliveLabelFadeMs = 400;

  // naming (6400) — DC then AC named.
  static const int namingMs = 6400;
  static const int namingLine16Ms = 0; // doc-only 0 ms anchor — set inline in _enterNaming
  static const int namingLine17Ms = 3400;

  // synthesis (3000) — the rule, alone.
  static const int synthesisMs = 3000;

  // bridge (5600) — line 19, then line 20 (persists), → card.
  static const int bridgeMs = 5600;
  static const int bridgeLine19Ms = 0; // doc-only 0 ms anchor — set inline in _enterBridge
  static const int bridgeLine20Ms = 2800;

  // --- Geometry anchors (factors of the Flame stage rect, PRD §16) -----------
  // Flow reads bottom (source) → core → top (bulb).

  /// OUTPUT BULB — top-center; the aliveness readout. Snaps off. Lowered so it
  /// clears the top-text seat (it was colliding with the caption).
  static const Offset bulbCenterFactor = Offset(0.50, 0.24); // lowered further → shorter wire
  static const double bulbRadiusFactor = 0.085; // × stage width

  /// OUTPUT LINE — top of the SECONDARY coil (right limb) → bulb base. Anchored at
  /// the right-limb x (0.695) so the wire leaves the coil, not the core window.
  static const Offset outputFromFactor = Offset(0.695, 0.39); // secondary coil top
  static const Offset outputToFactor = Offset(0.50, 0.315); // bulb base (recomputed from the bulb in-layer)

  /// THE TRANSFORMER (hero) — upright rounded core ring, lowered off the text.
  static const Offset coreCenterFactor = Offset(0.50, 0.50);
  static const double coreOuterWFactor = 0.44; // outer width (× stage width)
  static const double coreOuterHFactor = 0.26; // outer height (× stage height)
  static const double limbThicknessFactor = 0.05; // limb thickness (× stage width)

  /// INPUT LINE — battery compartment → bottom of the PRIMARY coil (left limb);
  /// reverses with sign(current). Anchored at the left-limb x (0.305) so the wire
  /// joins the coil's bottom, not the middle of the core window.
  static const Offset inputFromFactor = Offset(0.33, 0.735); // battery top, toward the coil
  static const Offset inputToFactor = Offset(0.305, 0.605); // primary coil bottom (left limb)

  /// SOURCE DOCK — a control panel holding the BATTERY (left) + an ON SWITCH
  /// (right). The switch STARTS the circuit (connect); the battery is tapped to
  /// FLIP its polarity. At handoff both slide out left and the machine slides in.
  static const Offset dockCenterFactor = Offset(0.50, 0.805);
  static const double dockWFactor = 0.60; // wider — holds the battery + the switch
  static const double dockHFactor = 0.12; // × stage height
  static const double batteryWFactor = 0.24; // × stage width (a proper cell)
  static const double batteryHFactor = 0.072; // × stage height (flatter cylinder)
  static const double batteryDxFactor = -0.13; // battery centre, left of dock centre
  static const double switchDxFactor = 0.18; // ON-switch centre, right of the compartment
  static const double switchWFactor = 0.20; // × stage width (landscape — a horizontal toggle)
  static const double switchHFactor = 0.055; // × stage height
  /// Hit rects (half-extents): tap the SWITCH to start, the BATTERY to flip.
  static const double switchHitHalfWFactor = 0.11;
  static const double batteryHitHalfWFactor = 0.15;
  static const double dockHitHalfHFactor = 0.075;

  /// GRAPH STRIP (tiny) — dark glass at the very bottom; ≤0.10 of stage height.
  static const Offset graphCenterFactor = Offset(0.50, 0.935); // padding below the dock
  static const double graphWFactor = 0.88; // × stage width (x 0.06–0.94)
  static const double graphHFactor = 0.085; // × stage height (≤0.10)

  // --- Palette (matches the_transformer 2.6 for product cohesion) ------------
  static const int coreFieldAmber = 0xFFFFD27A; // the breathing FLUX inside the core (additive)
  static const int coreFieldAmberHot = 0xFFFFE9B8;
  static const int transmissionBlue = 0xFF3FB9F5; // input + output pulses (NEVER warm)
  static const int transmissionBlueLite = 0xFFBFE6FF; // the bright pulse core (cool white-blue)
  static const int ironDark = 0xFF161B36; // the dark iron core body (deepened for depth)
  static const int ironMid = 0xFF2C3768;
  static const int ironLite = 0xFF5F6FA8;
  static const int ironBevel = 0xFF8092C8; // the lit top-left bevel edge of the iron
  static const int copper = 0xFFC9844A;
  static const int copperLite = 0xFFF0BD82;
  static const int copperHot = 0xFFFFE4BC; // the copper sheen highlight
  static const int copperDark = 0xFF5A3A20; // the back-arc copper (deepened)
  static const int batteryShell = 0xFF20294C;
  static const int batteryShellLite = 0xFF3C4A82;
  static const int machineShell = 0xFF18203E;
  static const int machineShellLite = 0xFF34406E;
  static const int graphGlass = 0xFF0B1026;
  static const int posTerminal = 0xFFFF8A6A; // battery + end (warm copper-red)
  static const int negTerminal = 0xFF7FA8E8; // battery − end (cool steel-blue)
  static const int switchOn = 0xFF5FE08A; // the ON-switch live glow (green = on)
  static const int switchTrack = 0xFF05081A; // the toggle track at rest (off, recessed)
}
