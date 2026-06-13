// Squared Loss (beat 2.4) — all the knobs in one place (PRD §10, §14, §16): the
// factor-based scene geometry, per-phase slider ranges + detents, the physics
// relations (relative units), particle caps, number-roll durations, and the timing
// constants for the silent step machine. Geometry is expressed as FACTORS of the
// stage size S = w×h; the controller multiplies by the stage reported once per paint.
//
// 10x REBUILD — DIAGONAL SPAN (continuity with 2.3 `current_heats_wire`). The two
// pylons are re-placed diagonally to fill the frame (killing the centered-U dead
// air): the LEFT pylon sits LOWER (top ≈ 0.54·H) and the RIGHT pylon HIGHER
// (top ≈ 0.26·H), so the wire runs as a dramatic diagonal from lower-left up to
// upper-right with a catenary SAG dipping below the straight diagonal. The wire's
// drawn geometry is the HELD-CONSTANT — identical across every beat; only its glow
// widens/brightens with the square. No lamp, no town (2.5 owns that payoff).

import 'dart:ui' show Color;

class SLTune {
  SLTune._();

  // ── Physics (relative units; base = 100 at ×1) ───────────────────────
  // heat   = 100 · I²   → 100 / 400 / 900 / 1600 at ×1/×2/×3/×4
  // volts  = 100 · I    → 100 / 200 / 300 / 400
  static const double currentBase = 1.0;
  static double heatFor(double i) => 100.0 * i * i;
  static double lostVoltsFor(double i) => 100.0 * i;

  /// Normalised wire glow [0,1] — keyed off the SQUARE so the leap is felt.
  /// At ×4 the square would saturate hard; we map (I/maxI)² and clamp. This is the
  /// load-bearing disproportion: ×1→0.0625, ×2→0.25 (4×), ×3→0.5625 (9×), ×4→1.0.
  static const double maxCurrent = 4.0;
  static double wireGlowFor(double i) {
    final g = (i / maxCurrent) * (i / maxCurrent);
    return g.clamp(0.0, 1.0);
  }

  /// The faint warm glow the wire already carries at ×1 (the 2.3 inheritance —
  /// current already heats it a little). wireGlowFor(1) ≈ 0.0625, lifted to a
  /// readable floor so the wire is never cold-dark at rest.
  static const double restGlow = 0.10;

  // ── Slider ranges per phase (×current) + detents ─────────────────────
  static const double rangeMinDefault = 1.0;
  static const double detentSnapFraction = 0.06; // snap within 6% of a tick
  static const List<double> detents4 = [1.0, 2.0, 3.0, 4.0];

  // ── Number-roll durations (the felt channel is NOT eased — only digits) ──
  static const double rollSeconds = 0.55; // 400–600 ms band → 550 ms

  // ── Reveals / fades ──────────────────────────────────────────────────
  static const double sceneRevealSeconds = 0.45; // lbReveal-style entrance
  static const double graphRevealSeconds = 0.45;
  static const double ghostRevealSeconds = 0.40;
  static const int textSwapMs = 190;

  // ── Discovery flash envelope ─────────────────────────────────────────
  static const double flashSeconds = 0.70;

  // ── Ember burst (the 4× LEAP, fired at the ×2 / ×3 detent landings) ──
  // A quick dense puff of embers off the span dramatizing "nudge a little → jumps
  // a LOT". The burst count scales with the landing's glow so ×3 puffs more than ×2.
  static const int emberBurstBase = 14; // burst at the ×2 landing
  static const int emberBurstPerGlow = 26; // extra ∝ glow (×3 lands more)
  static const double emberBurstSpeedMin = 90;
  static const double emberBurstSpeedMax = 200;
  static const double leapPulseSeconds = 0.55; // glow-leap envelope at a landing

  // ── Particles ────────────────────────────────────────────────────────
  static const int maxEmbers = 64; // raised from 48 for the denser leap
  static const int maxMotes = 20;
  static const double emberLifeMin = 1.1;
  static const double emberLifeMax = 1.7;

  // ── Heat-haze shimmer band (ported from 2.3 — rising refraction) ─────
  // A stack of translucent wavy warm bands above the glowing span, blurred + slowly
  // sine-displaced so it reads as rising heat-shimmer. Intensity scales with heat.
  static const int hazeBands = 6; // wavy translucent layers (denser → a sheet, not ribbons)
  static const double hazeRiseF = 0.20; // how far the shimmer climbs above the span (of H)
  static const double hazeWaveAmpF = 0.013; // sine displacement amplitude (of H)
  static const double hazeWaveLenF = 0.22; // sine wavelength along the span (of W)
  static const double hazeSpeed = 0.55; // shimmer scroll speed (cycles/sec)
  static const double hazeBaseAlpha = 0.15; // peak alpha per band at full heat

  // ── Voluminous cable / ember core shading (ported from 2.3) ──────────
  static const double cableHighlightFrac = 0.20; // specular band width on the cool body
  static const double glowWidenMax = 2.4; // ember bloom widens to this × stroke at max glow
  // The hero's loss gradient (2.3 port): the ember is hottest at the PLANT (left/low)
  // end and cools toward the RIGHT, so the wire reads as bleeding energy as heat.
  static const double lossTaper = 0.5; // right-end keeps (1 − lossTaper) of left brightness

  // ── Sweep coverage (the learner draws the curve) ─────────────────────
  static const int coverageBuckets = 24;
  static const int coverageGate = 21; // ≥21/24 visited → sweep complete

  // ── Idle nudge (the only nudge — handle pulses gently) ───────────────
  static const double idlePulseSeconds = 7.0;

  // ── Timing constants (ms) for the step machine ───────────────────────
  static const int introToRaiseMs = 2600; // intro hold → slider unlocks at ×1
  static const int twoToThreeMs = 2600; // ×2 lands (discovery) → re-open for ×3
  static const int discoveryCaptureMs = 650; // ×2 landing → capture heat_quadruples
  static const int threeToSweepMs = 2600; // ×3 lands → sweep
  static const int sweepCaptureMs = 600; // sweep complete → curve glow close
  static const int curveToGhostMs = 2400; // 'curve bends up' → the dashed ghost line
  static const int ghostToNamedMs = 3000; // ghost line → the naming line
  static const int namedToCardMs = 4200; // naming line → card earn

  // ── Scene geometry FACTORS of the stage (PRD §16) — DIAGONAL SPAN ────
  // Pylons re-placed diagonally (continuity with 2.3): the LEFT pylon sits LOWER,
  // the RIGHT pylon HIGHER, so the span climbs across the whole frame.
  static const double pylonLeftX = 0.10; // left pylon x (lower-left)
  static const double pylonRightX = 0.90; // right pylon x (upper-right)
  static const double pylonLeftTopY = 0.54; // left anchor top y (LOWER)
  static const double pylonRightTopY = 0.26; // right anchor top y (HIGHER)
  static const double pylonBaseY = 0.92; // post foot y (both feet near the floor)
  // Catenary midspan low point as an EXTRA sag DEPTH below the straight diagonal
  // (factor of H). The dip reads as real cable weight.
  static const double sagDepthF = 0.075; // max sag below the straight diagonal (of H)
  static const double wireStrokeF = 0.017; // voluminous conductor body width (of H)
  static const double emberDieY = 0.04; // embers die rising past this y (of H)

  // Lattice tower build (factors of H) — premium steel rebuild (2.3 port). The
  // pylon heights are NOT lifted here (unlike 2.3): the gauges sit just above the
  // wire, so the towers are widened/sturdier rather than taller.
  static const double towerLegWF = 0.0062; // leg member width
  static const double towerBraceWF = 0.0032; // cross-brace member width
  static const double towerHeadHalfF = 0.015; // half-width at the apex
  static const double towerBaseHalfF = 0.044; // half-width at the splayed feet
  static const int towerRungs = 5; // lattice panels (X-braced)
  static const double insulatorDiscRF = 0.0056; // ceramic insulator disc radius
  static const int insulatorDiscs = 2; // bells in the suspension string

  // Static held-constant tag — an annotation pill in the gutter just BELOW the wire
  // midspan, with a leader up to the wire (out of the hot span so it stays legible).
  static const double tagX = 0.50; // centre-anchored at midspan
  static const double tagY = 0.55; // below the midspan sag (leadered to the wire)

  // ── Readout chips / gauges (in-painter, inside the snapshot) ─────────
  // Re-seated to the lower-LEFT band, clear of the high-right wire end and above
  // the graph panel, so the two gauges never collide with the diagonal.
  static const double chipCurrentX = 0.26; // centre x (CURRENT gauge)
  static const double chipRightX = 0.74; // centre x (HEAT / LOST VOLTS gauge)
  static const double chipY = 0.435; // centre y (clear of the diagonal, above the panel)
  static const double chipHeightFactor = 0.072; // × h (taller gauge body)

  // ── Graph panel — a CENTERED MODAL (hidden until sweep; backdrop-scrimmed) ─
  // A proper labeled-axes card in the middle of the stage; on `voltsStep` it
  // DISMISSES completely (slides down + fades — not a dim).
  static const double panelLeftX = 0.06;
  static const double panelTopY = 0.22; // centered vertically
  static const double panelRightX = 0.94;
  static const double panelBottomY = 0.78;
  static const double panelSlideFromY = 0.06; // entrance/exit slide offset (of H)
  static const double panelDismissSeconds = 0.45; // slide-down + fade-out on voltsStep
  static const double panelScrimAlpha = 0.55; // backdrop scrim behind the modal

  // ── Color tokens (PRD §4 / §7) ───────────────────────────────────────
  static const Color base = Color(0xFF070A1C);
  static const Color ink = Color(0xFF0B1026);
  static const Color heat = Color(0xFFFF7A2E); // ember / heat orange
  static const Color heatFierce = Color(0xFFFF5A24); // the fourfold leap
  static const Color heatCore = Color(0xFFFFF1D8); // near-white hot core (2.3 emberHot)
  static const Color heatCoreSoft = Color(0xFFFFE9C0); // warm near-white
  static const Color copperCool = Color(0xFF8A5A38); // dull copper at rest
  static const Color energy = Color(0xFFFFD27A); // warm energy
  static const Color coolMote = Color(0xFF6FA8FF); // ambient cool mote
  static const Color gold = Color(0xFFF5C451); // CTA / accents
  static const Color glassFill = Color(0x14FFFFFF);
  static const Color glassBorder = Color(0x26FFFFFF);

  // Voluminous-cable palette (ported from 2.3 HWTune for cohesion).
  static const Color wireCool = Color(0xFF59648C); // cold cable body
  static const Color wireCoolDeep = Color(0xFF333C5E); // cable edge (cylindrical)
  static const Color wireSpecular = Color(0xFFAEBCE6); // cool specular band

  // Steel tower ramp (brushed-steel, ported from 2.3 / hand_crank_lamp; cooler &
  // dimmer than the crank so the towers stay recessive vs the hot wire). Global key
  // light = UPPER-LEFT; each member is drawn as a cylindrical dark→spine→dark bar.
  static const Color towerEdge = Color(0xFF1B2138); // member dark edge (curvature falloff)
  static const Color towerBody = Color(0xFF3C466B); // member mid body
  static const Color towerSpine = Color(0xFF707FAE); // member lit spine (cylindrical sheen)
  static const Color towerRim = Color(0xFF98A6D4); // upper-left chamfer rim light
  static const Color towerBolt = Color(0xFF0C1430); // bolt heads / joint ambient occlusion
  static const Color insulatorCeramic = Color(0xFFB9C4E6); // ceramic insulator discs
}
