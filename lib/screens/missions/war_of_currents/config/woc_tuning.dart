// War of the Currents — tunable constants + the scene's factor-based geometry.
// EVERYTHING the controller / layers read for position, colour, timing and the
// sim lives here so a live on-device tuning pass is a one-number edit (the
// shipped TBTune / CrankConfig convention).
//
// THE LOAD-BEARING RULE (PRD §6, criterion 5): the DC failure is a HARD GATE.
// At the failure frame the city flicker, the pulse alphas past the reach-front,
// and the reach-front advance are FORCED to their failed state in the same frame —
// never decayed, never faded, and reduced-motion does NOT soften it.
//
// All anchors are FACTORS of the Flame stage rect (w × h), matching PRD §16's
// scene sketch. centre = (x·w, y·h). Journey reads bottom-left (plant) →
// top-right (city), vertically staged for portrait.

import 'dart:ui' show Color, Offset;

class WocTune {
  WocTune._();

  // ── Palette (PRD §7 discipline — each colour has ONE job) ──────────────────
  static const Color base = Color(0xFF070A1C); // near-black map base
  static const Color ink = Color(0xFF0B1026);
  static const Color terrain = Color(0xFF1A2347); // faint ridges (≤6% alpha applied)
  static const Color river = Color(0xFF22407A); // a faint river (≤6% alpha applied)
  // The cold, un-energised line is a dimensional CYLINDER (2.3/2.4 craft): a dark
  // edge → cool body → cool specular spine so the hero line reads voluminous, not flat.
  static const Color wireBase = Color(0xFF2A3358); // the cold line's body (legacy alias)
  static const Color wireCoolDeep = Color(0xFF333C5E); // cylinder dark edge (2.4 craft)
  static const Color wireCool = Color(0xFF59648C); // cylinder cool body (2.4 craft)
  static const Color wireSpecular = Color(0xFFAEBCE6); // cool specular spine (2.4 craft)
  static const Color pulseWarm = Color(0xFFFFD27A); // low-voltage pulses (both launch warm)
  static const Color pulseWarmCore = Color(0xFFFFF1D6); // warm-pulse hot centre
  static const Color pulseCool = Color(0xFF3FB9F5); // stepped-up high-voltage pulses (AC)
  static const Color pulseCoolCore = Color(0xFFE6F7FF); // cool-pulse cold centre
  static const Color heat = Color(0xFFFF7A2E); // wire heat — ONLY on the wire's glow
  static const Color heatHot = Color(0xFFFFF1D8); // the white-hot flare/ember core (2.4 heatCore)
  static const Color cityWarm = Color(0xFFFFE9B8); // city bloom
  static const Color coreAmber = Color(0xFFFFD27A); // the transformer's live FLUX (AC only)
  static const Color coreAmberHot = Color(0xFFFFE9B8); // the hot flux centre
  static const Color plantDim = Color(0xFF6F7BB0); // the small, dim, unchanging plant
  static const Color gold = Color(0xFFF5C451); // chrome / CTA family

  // ── MINI transformer iron + copper (ported from activity 6/7 — kept small; this
  //    beat is NOT about the transformer, but it should read as the SAME object). ──
  static const Color ironDark = Color(0xFF161B36); // dark iron core body
  static const Color ironMid = Color(0xFF2C3768);
  static const Color ironLite = Color(0xFF5F6FA8);
  static const Color ironBevel = Color(0xFF8092C8); // lit top-left bevel edge
  static const Color copper = Color(0xFFC9844A);
  static const Color copperLite = Color(0xFFF0BD82);
  static const Color copperHot = Color(0xFFFFE4BC);
  static const Color copperDark = Color(0xFF5A3A20);

  // ── Steel ramp for the plant + the line's pylons (activity-3 craft) ───────────
  static const Color steelEdge = Color(0xFF1B2138);
  static const Color steelBody = Color(0xFF3C466B);
  static const Color steelSpine = Color(0xFF707FAE);
  static const Color steelRim = Color(0xFF98A6D4);
  static const Color steelBolt = Color(0xFF0C1430);
  static const Color insulatorCeramic = Color(0xFFB9C4E6);

  // ── Hero-line dimensional cook craft (ported from 2.3/2.4 hot-wire) ─────────
  // The DC run cooks the line: a layered additive ember bloom + a rising heat-haze
  // shimmer band + cooling-ember speckle. None of this appears on the AC line (it is
  // cold — zero heat at all times). Heat colour #FF7A2E lives ONLY here.
  static const double wireStrokeFactor = 0.021; // hero-line body stroke (× w) — a bold strung wire
  static const double cableHighlightFrac = 0.24; // cool specular spine width on the body
  static const double glowWidenMax = 4.2; // ember bloom widens to this × stroke at max heat (swell)
  static const Color heatDeep = Color(0xFFE5371A); // the RED-hot cook core (menace, not white)
  // Heat-haze shimmer bands rising off the cooking stretch (refraction approximation).
  static const int hazeBands = 4; // wavy translucent warm layers
  static const double hazeBaseAlpha = 0.10; // peak alpha per band at full heat
  static const double hazeRiseF = 0.060; // how far the shimmer climbs above the line (× stage h)
  static const double hazeWaveAmpF = 0.010; // sine displacement amplitude (× stage h)
  static const double hazeWaveLenF = 0.20; // sine wavelength along the line (× stage w)
  static const int heatMoteCount = 9; // rising heat motes off the hottest stretch

  // ── The two live numbers (PRD §4 — product pinned at 1000 at both states) ──
  static const double vLaunch = 10; // VOLTAGE at launch (both runs)
  static const double iLaunch = 100; // CURRENT at launch (both runs)
  static const double vStepped = 200; // AC after the transformer
  static const double iStepped = 5; // AC after the transformer (200 × 5 = 1000)
  static const double viRollMs = 600; // the V/I roll duration (in sync with the bloom)

  // ── The sim (heat ∝ I², pulse params per run) ──────────────────────────────
  // DC: V 10, I 100 → enormous current → the wire cooks. AC: V 200, I 5 → trickle.
  static const double dcStallS = 0.62; // DC reach-front stalls at 0.62 of the route
  static const double dcFlareS = 0.45; // the flare blooms at s≈0.45 along the route
  static const double dcHeatPeak = 1.0; // peak wire-heat normalised (∝ (I/100)² = 1)
  static const double dcHeatFalloff = 0.55; // arclength behind the front the heat fades over (line-wide cook)
  static const int dcPulseCount = 4; // fat, slow pulses
  static const double dcPulseThickness = 1.0; // normalised (thick)
  static const double dcPulseSpeed = 0.34; // route-fractions/sec (slow)
  static const int acPulseCount = 3; // thin, fast pulses
  static const double acPulseThickness = 0.5; // normalised (thin)
  static const double acPulseSpeed = 0.42; // route-fractions/sec (fast → sails in ~2.6s)
  static const double flareEnvelopeMs = 700; // the failure flare envelope

  // ── Ambient ────────────────────────────────────────────────────────────────
  static const int moteCount = 20; // 16–22 ambient motes (PRD §7)

  // ── Premium subtle terrain (PRD §7 — all LOW-ALPHA ≤6% so the route stays hero) ─
  static const int terrainRidgeCount = 6; // faint ridge contours suggesting distance
  static const double terrainRidgeAlpha = 0.055; // ≤6% — the route is the unmistakable hero
  static const double riverAlpha = 0.05; // ≤6% — a winding river crossing the country
  // Far recessive ridgeline silhouettes near the horizon (a sense of "across the country").
  static const double farRidgeAlpha = 0.045;

  // ── Geometry anchors (factors of the stage rect, PRD §16) ──────────────────
  // CITY (the payoff readout) — cluster across the upper-right, LOWERED so the
  // skyline no longer overlaps the top message (on-device feedback).
  static const Offset cityFactor = Offset(0.74, 0.26); // cluster centre
  static const double cityWidthFactor = 0.36; // span 0.56→0.92 w
  static const double cityBaseFactor = 0.33; // bases at y≈0.33h (moved up — space on top)
  static const double cityMaxHFactor = 0.14; // tallest building height (× stage h)

  // ROUTE (the hero) — a clean, confident diagonal sweep (was a kinked zigzag).
  // Index 0 is the CITY end (s = 1.0 of the journey); the LAST point is the
  // TRANSFORMER end (s = 0.0). Reach-front s is measured from the transformer end.
  // Even spacing + consistent slope so it reads as one long line across the country.
  // The route's SUPPORT POINTS (where the wire is clamped): the city + two towers +
  // the transformer. The conductor SAGS as a catenary BETWEEN them (activity-3/4
  // craft) so it reads as a strung wire across towers, NOT a rigid pipe.
  // Index 0 = CITY (s=1.0), last = TRANSFORMER (s=0.0).
  static const List<Offset> routeFactors = [
    Offset(0.710, 0.330), // city feed (arrival, s=1.0) — at the city base
    Offset(0.585, 0.435), // tower 2 (clamp point)
    Offset(0.440, 0.560), // tower 1 (clamp point)
    Offset(0.300, 0.700), // transformer (send end, s=0.0)
  ];
  /// Catenary sag between supports — mid-span dips this fraction of the span length
  /// BELOW the straight chord (downward), like a real strung wire (activity 3/4).
  static const double catenarySagFactor = 0.11;
  static const double pylonHeightFactor = 0.052; // steel pylon height (× stage h), small
  // (pylons are drawn AT the intermediate support points above — the towers the wire
  //  is strung between.)

  // STATION — the MINI transformer (ported activity 6/7 iron core + coils, small),
  // the plant, and the two number gauges.
  static const Offset transformerFactor = Offset(0.300, 0.700); // mini core centre
  static const double transformerRadiusFactor = 0.052; // legacy alias (bloom radius unit)
  // Mini iron-core window dimensions (small — this beat is not about the transformer).
  static const double miniCoreWFactor = 0.092; // core outer width (× stage w)
  static const double miniCoreHFactor = 0.082; // core outer height (× stage h)
  static const double miniLimbFactor = 0.020; // limb thickness (× stage w)
  static const int miniCoilTurns = 3; // copper loops per limb (mini)
  static const Offset plantFactor = Offset(0.155, 0.815); // steel plant centre
  static const double plantWidthFactor = 0.20; // span ~0.06→0.26 w
  static const double plantBaseFactor = 0.875; // base sits at y≈0.875h
  // VOLTAGE / CURRENT as instrument GAUGES (matching 2.1–2.7) riding the send end.
  // Centre points (the gauge bodies stack just above the transformer / send end).
  static const Offset voltageChipFactor = Offset(0.69, 0.645); // VOLTAGE gauge centre (nudged right)
  static const Offset currentChipFactor = Offset(0.69, 0.715); // CURRENT gauge centre (nudged right)
  static const double gaugeHeightFactor = 0.060; // gauge body height (× stage h)
  // The two displayed states (for the gauge needle norm): product pinned at 1000.
  static const double vGaugeMax = 200; // VOLTAGE gauge full-scale (norm = V / 200)
  static const double iGaugeMax = 100; // CURRENT gauge full-scale (norm = I / 100)

  // FEED — plant terminal → transformer (the short common-launch segment).
  static const Offset feedStartFactor = Offset(0.20, 0.80); // plant terminal
  static const Offset feedEndFactor = Offset(0.30, 0.70); // transformer

  // (The EP3 BRIDGE VIGNETTE was cut — the activity ends on the war reveal.)

  // ── Timers (ms) — caption + beat schedule. Each run is scripted off these. ──
  // intro — NO caption now; the scene just reveals, then the choice appears.
  static const int introToChooseMs = 1800;
  // common launch (after a chip tap)
  static const int launchBloomMs = 300; // plant bloom + chips fade in
  static const int launchVignetteMs = 1200; // vignette tightens on the transformer
  // DC branch (offsets from the tap): "DC — No Transformer, Low Voltage" → "The Line
  // Cooks — It Dies Before Arriving".
  static const int dcSentMs = 1400; // dSent — dead transformer, low voltage
  static const int dcJourneyMs = 2600; // pulses onto the long route
  static const int dcFailureMs = 7400; // THE FAILURE (hard gate)
  static const int dcResultMs = 7600; // dResult — the line cooks + dies (just post-failure)
  static const int dcRunEndMs = 10500; // hold the dead state, then → interlude/war
  // (No DC capture — `dc_line_cooks` is not in the EP2 catalog; the cook is felt-only.)
  // AC branch (offsets from the tap): "AC — Transformer Alive, Voltage Up" → "The Line
  // Stays Cold — It Sails Across".
  static const int acSentMs = 1400; // aSent — transformer alive, voltage up
  static const int acBloomMs = 1200; // the core blooms alive + V/I roll begins
  static const int acJourneyMs = 2600; // pulses sail the full route
  static const int acArrivalMs = 5200; // ARRIVAL — city window sweep
  static const int acCaptureMs = 6300; // onCapture('ac_sails_across') — full-lit frame
  static const int acResultMs = 6400; // aResult — line cold, sailed across (city lit)
  static const int acRunEndMs = 9800;
  // interlude — "Now Try the Other"
  static const int interludeResetMs = 800; // visible reset so run 2 starts identical
  // war / verdict (after both runs) — the one verdict line, then Continue.
  static const int warCrossfadeMs = 700; // if DC ran last, crossfade to the AC end-state
  static const int warToDoneMs = 5000; // verdict holds ~5s → done (Continue); it persists
  // entrance reveals
  static const int introTerrainMs = 450;
  static const int introRouteStartMs = 300;
  static const int introRouteEndMs = 900;
  static const int textSwapMs = 190;

  // ── Capture (the ONLY valid id for this beat — PRD §9 / evidence catalog) ──
  static const String evAcSailsAcross = 'ac_sails_across';
}
