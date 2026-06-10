// Tunable constants + pure math for the town-day simulation (Activity 3 · 1.2).
//
// Everything here is data: the day-cycle speed, the per-source-day OUTPUT models
// (the only "physics" in this activity — value mappings, not Forge2D), the haze /
// cost accumulation rates, the lit-state thresholds, and the sky palette. A live
// on-device tuning pass is expected; one place to nudge.
//
// Output is RELATIVE, never absolute (PRD §4.4 / §9.2): the town NEEDS ~1.0; a
// source SUPPLIES some multiple of that across the day. The felt question is only
// "can it cover the town right now?" — never a megawatt number.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'source_personality_defs.dart';

class TownTune {
  TownTune._();

  // --- The town's need + the day clock -------------------------------------

  /// The town's roughly-constant power need. Demand variation across the day is
  /// Episode 4's job (PRD §4.2, §10) — deliberately flat here.
  static const double townNeed = 1.0;

  /// Each source-run auto-plays a brisk time-lapse from morning to midnight
  /// (update spec Change 4) so the catch is ALWAYS witnessed. The run spans
  /// [dayStart, dayEnd]; the scrubber maps to this window (transport, not driver).
  static const double dayStart = 7.0; // morning
  static const double dayEnd = 24.0; // midnight (well past sunset, deep night)
  static double get dayHours => dayEnd - dayStart;

  /// Real seconds to auto-play one full 24h. The run (dayStart→dayEnd) plays in
  /// dayHours/24 × this — solar reaches nightfall in ~8s. Drag to fast-forward.
  static const double dayLengthSeconds = 17.0;

  /// The cost meter is shown as a fraction of this ceiling (relative, not money).
  static const double costFullScale = 120.0;

  // --- Derived felt channels (driven by how far the DAY has progressed, NOT
  //     wall-clock runtime — so the scrubber's fast-forward reaches each catch) -
  /// Haze = hazeRate × day-hours elapsed × this. Tuned so coal (rate 0.075)
  /// reaches its 0.6 catch by ~mid-afternoon (≈9 day-hours) and maxes by evening;
  /// gas (rate 0.04) stays visibly lighter, topping out ~0.6.
  static const double hazeScale = 0.9;

  /// Cost climb = costRate × day-hours elapsed × this (added to the build cost),
  /// over the ~17h day. A rate-1.0 source climbs ~50 units across a day.
  static const double costScale = 3.0;

  /// Hydro's reservoir drains over this many day-hours — stays mostly lit but the
  /// water gauge visibly drops ("clean and reliable — while there's water").
  static const double hydroDrainHours = 22.0;

  // --- Catch-moment thresholds (when Beat 2 fires; update spec Change 3) -----
  static const double coalHazeCatch = 0.6; // air visibly filthy
  static const double gasHazeCatch = 0.32; // lighter haze shows
  static const double windLull = 0.34; // gust this low = a stall (the flicker)
  static const double windMinElapsedH = 2.0; // ignore an opening-second lull
  static const double windFallbackElapsedH = 11.0; // guarantee a catch by evening
  static const double nuclearCostCatch = 0.45; // cost has climbed noticeably
  static const double nuclearFallbackElapsedH = 10.0;
  static const double hydroElapsedCatch = 9.0; // ~mid-day → state the condition

  // --- Live readouts (real numbers, tunable units) -------------------------
  /// Relative supply 1.0 maps to ~this many kW for the POWER readout. Steady
  /// sources land ~4.6 kW, solar peaks ~5.3, wind bounces 0 → ~5.
  static const double kWPerSupply = 4.0;

  /// Gust (0..~1.35) → windspeed km/h for the WIND readout.
  static const double windKmh = 26.0;

  // --- Sun / day position --------------------------------------------------

  /// Sun is up between these hours; altitude peaks at solar noon (13:00 here for
  /// a touch of asymmetry). 0 at/under the horizon, 1 at peak.
  static const double sunrise = 6.0;
  static const double sunset = 18.5;

  static double sunAltitude(double t) {
    if (t <= sunrise || t >= sunset) return 0;
    // Half-sine across the daylight window.
    final x = (t - sunrise) / (sunset - sunrise); // 0..1
    return math.sin(x * math.pi).clamp(0.0, 1.0);
  }

  /// 0 at sunrise → 1 at sunset, used to place the sun along its arc (x). Outside
  /// daylight it parks the sun off-screen low.
  static double sunArcX(double t) => ((t - sunrise) / (sunset - sunrise)).clamp(-0.1, 1.1);

  // --- Wind gust model (deterministic + repeatable; phase = time of day) ---
  // GENUINELY ERRATIC (update spec §5): multi-octave incommensurate sines for a
  // non-repeating feel, multiplied by a slow "lull envelope" that occasionally
  // craters the wind for real stalls — so the windspeed/power numbers and the
  // town flicker feel suspenseful, not a tidy loop. Still pure-deterministic in
  // timeOfDay, so scrubbing is repeatable and reversible.
  static double gust(double t) {
    final base = 0.5 +
        0.30 * math.sin(t * 0.91 + 0.4) +
        0.22 * math.sin(t * 2.37 + 1.1) +
        0.17 * math.sin(t * 5.13 + 2.0) +
        0.12 * math.sin(t * 9.73 + 0.7);
    // Lull envelope: a product of two slow waves dips toward 0 at irregular
    // intervals → real stalls between gusts.
    final lull = 0.5 + 0.5 * math.sin(t * 1.27 + 0.3) * math.sin(t * 0.41 + 2.2);
    final env = (0.18 + 1.05 * lull).clamp(0.0, 1.25);
    return (base * env).clamp(0.0, 1.35);
  }

  // --- Per-source instantaneous SUPPLY (relative to townNeed) --------------
  // The heart of "each source is different across the day". No labels — the
  // town's brightness is the whole readout.
  static double supplyFor(SourcePersonality s, double t, double waterLevel) {
    switch (s.kind) {
      case SourceKind.solar:
        // Follows the sun: blazing at noon, nothing after dark.
        return sunAltitude(t) * 1.32;
      case SourceKind.wind:
        // Rides the gusts — bright, dim, dark, bright.
        return gust(t);
      case SourceKind.coal:
      case SourceKind.gas:
      case SourceKind.nuclear:
        // Steady, controllable, day and night.
        return 1.16;
      case SourceKind.hydro:
        // Reliable, but the brightness visibly TRACKS the water volume (update
        // spec §1): more water → brighter. Drains gently across the day, so the
        // town dims slowly and the WATER readout falls in lockstep.
        return 1.16 * (0.55 + 0.45 * waterLevel.clamp(0.0, 1.0));
    }
  }

  // --- Lit-state thresholds (supply → how the town reads) ------------------
  // townLight 0..1 drives window brightness; the discrete litState is for copy /
  // future scoring. Supply oscillation (wind) naturally makes this flicker.
  static double townLight(double supply) {
    final s = supply.clamp(0.0, 1.4);
    if (s >= 0.9) return 1.0; // fully lit
    if (s <= 0.12) return 0.0; // dark
    return ((s - 0.12) / (0.9 - 0.12)).clamp(0.0, 1.0);
  }

  // --- Geometry (factors of the stage rect) --------------------------------
  // The town sits along the lower band; the sky fills above; the source visual
  // anchors to the lower-left, feeding the town to its right.
  static const double horizonFactor = 0.72; // ground line y-factor
  static const double townTopFactor = 0.46; // tallest rooftops reach ~here
  static const Offset sourceAnchorFactor = Offset(0.16, 0.6); // source visual centre
  static const double hazeBandTopFactor = 0.30; // smog accumulates over this band

  // --- Timing knobs (ms) ---------------------------------------------------
  static const int revealDelayMs = 800; // entry → world interactive
  static const int synthesisDelayMs = 2400; // last source tried → begin the wrap
  static const int synthesisToCardMs = 1600; // wrap → card earn

  // --- Sky palette (dawn → noon → dusk → night) ----------------------------
  // Sampled by sunAltitude + time-of-day; a literal starry night here is
  // DIEGETIC and intended (PRD §7) — do not "fix" it away.
  static const Color skyNightTop = Color(0xFF070B1E);
  static const Color skyNightBottom = Color(0xFF14203F);
  static const Color skyDuskTop = Color(0xFF243056);
  static const Color skyDuskBottom = Color(0xFFC9743F);
  static const Color skyDayTop = Color(0xFF3E78C8);
  static const Color skyDayBottom = Color(0xFFA9D2F0);
}
