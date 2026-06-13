// Tunable constants + pure math for The Transformer (Episode 2 · beat 2.6).
//
// The scene is a VERTICAL portrait staging of the journey (PRD §16): bottom-left
// plant → input run rising → the iron CORE (hero, centre) with its two coils →
// output run climbing top-right → horizon pylons. All geometry is FACTORS of the
// Flame stage rect (resolution-independent); a live on-device pass is expected, so
// a nudge is a one-number edit.
//
// THE LOAD-BEARING RULES (hard gates, never softened by a fade):
//   • Each turn detent steps OUT and the line's reach in the SAME frame.
//   • The far pylon goes DARK the frame OUT drops below 200 (windDown).
//   • The output kick tracks |d(field)/dt| every frame (slack at the bloom crest).
// These are enforced in the controller's tick; this file only holds the knobs.

import 'dart:ui' show Offset;

class TxTune {
  TxTune._();

  // --- Turns & voltage mapping (PRD §13.2 / §4) ------------------------------
  /// The primary coil's turns — drawn, FIXED, never change (the held constant).
  static const int primaryTurns = 4;

  /// The secondary coil's turns — the only thing the learner changes.
  static const int minTurns = 2; // OUT 50
  static const int maxTurns = 8; // OUT 200 (ignition target)
  static const int startTurns = 4; // OUT 100 — matches IN at entry

  /// IN is pinned (held constant, alive). Per primary turn the device adds 25 V of
  /// output for each secondary turn: OUT = turnsOut / primaryTurns * inVoltage.
  /// At the extremes this keeps "twice the turns — twice the voltage" literally
  /// true: 4 turns → 100, 8 turns → 200 (PRD §13.2).
  static const double inVoltage = 100;
  static double outVoltageFor(int turnsOut) => turnsOut / primaryTurns * inVoltage;

  /// lineReach (0..1): how far the output pulses travel toward the horizon. 1.0
  /// only at OUT 200 (max turns) — the moment the farthest pylon can catch light.
  static double lineReachFor(int turnsOut) =>
      ((turnsOut - minTurns) / (maxTurns - minTurns)).clamp(0.0, 1.0);

  // --- The wind gesture (NO momentum — release stops detents where they are) -
  /// Vertical drag distance (logical px) that advances ONE turn detent. Dragging
  /// UP on the secondary limb winds on; dragging DOWN unwinds.
  static const double detentDrag = 34.0;

  // --- The always-alive input surge (the CHANGING current) -------------------
  /// Period (s) of the looping input-surge clock (the ambient breathing field).
  /// In slowSurge the surge is NOT globally time-scaled; instead the single
  /// isolated bloom is stretched in shape over [slowSurgeBloomEnd] real seconds
  /// (see the controller's _scriptSlowSurge) so the field's rate of change is
  /// readable and the output kick can be watched — the visual dilation lives in
  /// the bloom shape, not a clock multiplier.
  static const double surgePeriod = 1.1;

  // --- Phase timings (ms) — the §6 / §14 schedule ---------------------------
  // Intro is now TEXTLESS (the intro caption was cut) — it just reveals the scene
  // in, then hands off to the wind gesture, so it is short.
  static const int introMs = 1600; // intro reveal → windUp (no caption)

  static const int windUpFirstTurnLineMs = 600; // delay before "More Turns…"
  static const int ignitionMs = 1400; // pulse-train sails to horizon, far pylon lights
  static const int ignitionHoldMs = 2600; // line held before windDown

  static const int windDownExitHoldMs = 3000; // line held before watchCore

  // watchCore now shows ONE directive line ("Watch the Core — Nothing Moves"); it
  // persists into the slow-mo build-up, so the phase itself is shorter.
  static const int watchCoreMs = 3400; // auto-advance → slowSurge

  static const int slowSurgeMs = 7400; // auto-advance
  // The output kick (the induction line + heavyImpact + capture) is NOT a wall-clock
  // timer: it fires from the surge clock when the bloom reaches its crest at
  // [slowSurgeBloomEnd] (2.6 s), so it stays hard-synced to the field's rate.
  static const double slowSurgeBloomEnd = 2.6; // field blooms 0–2.6 s, crest at end

  static const int depthStopMs = 4600;

  static const int synthesisMs = 3000;
  static const int synthesisRewindMs = 700; // turns auto-rewind to 8

  static const int cliffLine2Ms = 2400; // line 17 → line 18
  static const int cliffToCardMs = 2600; // line 18 held → card earn (≥2400 total)

  // --- Geometry anchors (factors of the Flame stage rect, PRD §16) ----------
  // Flow reads bottom-left (plant) → core (centre) → top-right (horizon).

  /// HORIZON transmission towers — the receding row the output conductor is STRUNG
  /// ACROSS (nearest → farthest = the city / ignition target). Each apex is the
  /// suspension point where the wire clamps onto the insulator string, so the
  /// conductor visibly threads tower-to-tower end-to-end (PRD §16 + on-device
  /// feedback: "the wire must pass through the towers, current flows end to end").
  /// Two distant towers climbing to the top-right horizon, set ABOVE the core's
  /// right side (feet clear of the coil) so the hero stays centred. Two reads
  /// cleaner than three (three climbed too far up — on-device feedback).
  static const List<Offset> towerApexFactors = [
    Offset(0.780, 0.210), // nearest
    Offset(0.880, 0.140), // farthest — the city (ignition)
  ];
  // Perspective scale per tower (nearest large → farthest small).
  static const List<double> towerScales = [1.0, 0.72];
  static const double towerHeightFactor = 0.078; // tower height (× stage H) at scale 1
  /// The conductor sags between towers (catenary) — fraction of each span length.
  static const double catenarySagFactor = 0.06;

  /// THE TRANSFORMER (hero) — upright rounded core ring, CENTRED on the stage axis.
  /// Enlarged (the main attraction); the coils span symmetrically about x=0.5.
  static const Offset coreCenterFactor = Offset(0.50, 0.485);
  static const double coreOuterWFactor = 0.54; // outer width (× stage width)
  static const double coreOuterHFactor = 0.355; // outer height (× stage height)
  static const double limbThicknessFactor = 0.066; // limb thickness (× stage width)

  // IN / OUT readouts sit on the core's vertical axis: OUT above the core, IN below
  // — both horizontally centred (on-device feedback), clear of the top messaging.
  static const Offset outChipFactor = Offset(0.50, 0.235); // OUT — above the core
  static const Offset inChipFactor = Offset(0.50, 0.730); // IN — below the core

  /// INPUT RUN — from the small steel plant up to the primary (left-limb) bottom.
  static const Offset plantFactor = Offset(0.12, 0.875);

  // --- The circulating flux loop (the HERO motion — P0.1) -------------------
  // The amber flux travels AROUND the iron window like a current loop. These tune
  // the travelling bright head's look + speed; the base ribbon's breathing alpha
  // floor/range; and how hard an input surge BLOOMS the loop (the pulse sync).
  static const double fluxLoopSpeed = 0.34; // perimeter laps / second (ambient, calm)
  static const int fluxHeadCount = 2; // bright heads circulating the window
  static const double fluxHeadSpanFactor = 0.34; // comet-tail length as a loop fraction
  static const int fluxTrailSamples = 16; // samples drawn along each comet head
  static const double fluxRibbonAlphaFloor = 0.16; // base ribbon glow at rest
  static const double fluxRibbonAlphaGain = 0.50; // + this × bloom at the crest
  static const double fluxStrokeFactor = 0.50; // ribbon stroke (× limbThickness)
  static const double fieldBloomGain = 0.55; // bloom adds this much head brightness

  // --- Dimensional core + windings (P0.2) -----------------------------------
  static const double coreBevelFactor = 0.16; // bevel/edge band (× limbThickness)
  static const int coreLaminations = 5; // hairline laminations per limb
  static const double coilLoopWidthFactor = 2.15; // loop ellipse width (× limbThickness)
  static const double coilWireFactor = 0.30; // copper wire stroke (× limbThickness)
  static const double coilSheenFactor = 0.10; // bright sheen highlight (× limbThickness)

  // --- The cool input surge pulses (the CHANGING current — COOL, never warm) --
  static const int inputPulseCount = 3; // travelling pulses on the input run
  static const double inputPulseSpeed = 0.62; // input pulse laps / second

  // --- Palette --------------------------------------------------------------
  static const int coreFieldAmber = 0xFFFFD27A; // the breathing FLUX inside the core (additive)
  static const int coreFieldAmberHot = 0xFFFFE9B8;
  static const int transmissionBlue = 0xFF3FB9F5; // ALL line pulses — input + output (NEVER warm)
  static const int transmissionBlueLite = 0xFFBFE6FF; // the bright pulse core (cool white-blue)
  static const int ironDark = 0xFF161B36; // the dark iron core body (deepened for depth)
  static const int ironMid = 0xFF2C3768;
  static const int ironLite = 0xFF5F6FA8;
  static const int ironBevel = 0xFF8092C8; // the lit top-left bevel edge of the iron
  static const int copper = 0xFFC9844A;
  static const int copperLite = 0xFFF0BD82;
  static const int copperHot = 0xFFFFE4BC; // the copper sheen highlight
  static const int copperDark = 0xFF5A3A20; // the back-arc copper (deepened)
  static const int cityWarm = 0xFFFFE9B8;

  // --- Steel ramp for the towers + the plant (ported from current_heats_wire /
  //     activity 3, the established EP2 steel craft — on-device feedback: reuse it
  //     for visibility). Brushed cool steel: dark edge → mid body → lit spine → rim.
  static const int steelEdge = 0xFF1B2138; // member dark edge (curvature falloff)
  static const int steelBody = 0xFF3C466B; // member mid body
  static const int steelSpine = 0xFF707FAE; // member lit spine (cylindrical sheen)
  static const int steelRim = 0xFF98A6D4; // upper-left chamfer rim light
  static const int steelBolt = 0xFF0C1430; // bolt heads / joint ambient occlusion
  static const int insulatorCeramic = 0xFFB9C4E6; // ceramic insulator discs

  // --- Tower lattice members (factors; scaled per-tower by towerScales) ----------
  static const double towerHeadHalfF = 0.020; // half-width at the apex (× tower height)
  static const double towerBaseHalfF = 0.052; // half-width at the splayed feet
  static const double towerLegWF = 0.011; // leg member width (× tower height)
  static const double towerBraceWF = 0.0055; // cross-brace member width
  static const int towerRungs = 4; // lattice panels (X-braced segments)
  static const double insulatorDiscRF = 0.022; // ceramic disc radius (× tower height)
  static const int insulatorDiscs = 2; // bells in the suspension string
}
