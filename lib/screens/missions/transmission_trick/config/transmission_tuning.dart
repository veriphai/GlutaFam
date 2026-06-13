// Tunable constants + pure math for The Transmission Trick (Episode 2 · beat 2.5).
//
// THE PIN IS EXACT (PRD criterion 3): the rectangle's on-screen area is power, held
// constant. We map BOTH axes LINEARLY off one stage size —
//   heightPx = kV · V   (taller = more voltage)
//   widthPx  = kI · I    (wider  = more current),  with  I = viProduct / V
// so heightPx × widthPx = kV·kI·viProduct — a CONSTANT, independent of V. The pin
// is mathematical, not a tween, so it never wobbles (anti-pattern §12).
//
// THE SQUARED PAYOFF (PRD criterion 8): wireHeat = (I / iAtStart)² — heat falls with
// the SQUARE of the current, so halving the current quarters the heat. The wire and
// the town ARE the readouts; no loss %, no heat number (only VOLTAGE/CURRENT show).
//
// All geometry is FACTORS of the Flame stage rect (resolution-independent); a live
// on-device tuning pass is expected, so every nudge is a one-number edit (§13).

import 'dart:ui' show Color, Offset, Size;

class TTTune {
  TTTune._();

  // ── The sim (relative numbers, PRD §4/§10) ───────────────────────────
  /// Sending voltage range. Squat slab at vMin (huge current); tall column at vMax.
  static const double vMin = 10;
  static const double vMax = 200;

  /// Power is pinned: V × I = viProduct (1000). The product is NEVER shown on screen
  /// — the area is felt, not printed (PRD §4).
  static const double viProduct = 1000;

  /// Current = viProduct / V → 100 at vMin, 5 at vMax.
  static double currentFor(double v) => viProduct / v;
  static double get iAtStart => currentFor(vMin); // 100
  static double get iAtMax => currentFor(vMax); // 5

  /// Fraction of power lost as heat when the wire is at its hottest (the start —
  /// huge current). The town gets what's left. Never shown as a number.
  static const double lossAtStart = 0.70;

  /// wireHeat normalized 0..1 = (I / iAtStart)² — the SQUARE law (2.4's payoff).
  static double wireHeat(double current) {
    final r = (current / iAtStart).clamp(0.0, 1.0);
    return r * r;
  }

  /// delivered 0..1 = 1 − loss; loss = lossAtStart × wireHeat. At vMin ≈ 0.30
  /// delivered (dim town); at vMax ≈ 1.0 (full town).
  static double delivered(double current) =>
      (1 - lossAtStart * wireHeat(current)).clamp(0.0, 1.0);

  // ── Beat gates (PRD §6) ──────────────────────────────────────────────
  /// The discovery latch — first time sending voltage ≥ this fires the capture.
  static const double discoveryV = 20;

  /// "Light the Whole Town" gate — delivered ≥ this latches the town bloom.
  static const double townDeliveredGate = 0.95;

  /// "Send It to the Top" gate — voltage ≥ this, held continuously, latches.
  static const double topV = 180;

  /// How long topV must be HELD continuously to latch (a clean capture frame).
  static const double topHoldSeconds = 0.6;

  /// Detent size: a haptic each time the voltage crosses a multiple of this.
  static const double detentV = 10;

  // ── Diagonal span (now FILLS the boxed stage; factors of the STAGE box) ──
  // DIAGONAL SPAN (continuity with 2.3/2.4): the plant sits LOWER-LEFT, the town
  // UPPER-RIGHT, so the hot cable climbs as a dramatic diagonal filling the stage
  // box (no centred dead air). The wire's drawn geometry is the HELD-CONSTANT —
  // identical every frame; only its heat glow/haze/motes vary with wireHeat (∝ I²).
  // The two intermediate pylons sit ON the catenary (apex = wirePoint(t)), so the
  // wire always rests on their insulators.
  // The DIAGONAL GROUND — element feet climb from bottom-left (plant) up to the
  // upper-right (town), so the scene steps up the diagonal and fills the space.
  static const double groundLeftYFactor = 0.96; // foot y at x=0 (the lowest, near the bottom)
  static const double groundRightYFactor = 0.60; // foot y at x=1 (the highest, upper-right)

  static const Offset plantBaseFactor = Offset(0.13, 0.91); // powerhouse foot (most bottom-left)
  static const double plantWidthFactor = 0.15; // × stage width
  static const Offset wireStartFactor = Offset(0.19, 0.82); // plant terminal (just above the powerhouse)
  static const Offset wireEndFactor = Offset(0.92, 0.21); // town feed — lands atop the tallest (right) building
  static const double pylon1Frac = 0.32; // the SINGLE pylon, at this fraction along the span
  static const double wireSagFactor = 0.05; // catenary sag DEPTH below the diagonal (× h)

  // ── Town skyline (a DIAGONAL climbing cluster, upper-right) — the meter ──
  // The buildings step UP left→right (bases AND tops climb the diagonal ground) to
  // the tallest receiving tower at the right corner where the wire lands. Each owns
  // its own window grid (windows never float above a shorter roof — the old bug).
  // The warm-window count = delivered power.
  static const Offset townBaseFactor = Offset(0.74, 0.86); // town centre x (foot y comes from groundY)
  static const double townWidthFactor = 0.42; // × stage width (wide → big buildings)
  static const int townBuildingCount = 4; // few, big buildings
  static const double townShortTopFactor = 0.60; // shortest (left) building top (× h)
  static const double townTallTopFactor = 0.21; // tallest (right, receiving) top (× h) ≈ wire feed
  static const double townBuildingGapFrac = 0.16; // gap between buildings (× slot width)

  // ── Voluminous cable craft (ported from 2.3/2.4 hot wire) ────────────
  static const double wireStrokeFactor = 0.016; // cable body width (× h) — voluminous
  static const double cableHighlightFrac = 0.20; // cool specular band on the body
  static const double glowWidenMax = 2.4; // ember bloom widens to this × stroke at full heat

  // ── Heat-haze shimmer band (rising refraction; intensity ∝ wireHeat) ──
  static const int hazeBands = 4; // wavy translucent layers above the span
  static const double hazeRiseF = 0.14; // how far the shimmer climbs above the span (× h)
  static const double hazeWaveAmpF = 0.011; // sine displacement amplitude (× h)
  static const double hazeWaveLenF = 0.22; // sine wavelength along the span (× w)
  static const double hazeBaseAlpha = 0.10; // peak alpha per band at full heat
  static const double hazeSpeed = 0.5; // shimmer scroll speed (cycles/sec)

  // ── Premium steel lattice tower (ported from 2.3 hot wire HWTune) ─────
  // Each member is a CYLINDRICAL steel bar (dark edge → bright spine → dark edge)
  // with an upper-left chamfer rim; bolted joints; ceramic insulator string at the
  // apex where the wire clamps. Kept dim/recessive so the HOT WIRE stays the hero.
  static const double towerLegWF = 0.0064; // leg member width (× h)
  static const double towerBraceWF = 0.0032; // cross-brace member width (× h)
  static const double towerHeadHalfF = 0.016; // half-width at the apex (× h)
  static const double towerBaseHalfF = 0.044; // half-width at the splayed feet (× h)
  static const int towerRungs = 5; // lattice panels (X-braced segments)
  static const double insulatorDiscRF = 0.0058; // ceramic insulator disc radius (× h)
  static const int insulatorDiscs = 2; // bells in the suspension string

  // ── Readout value-normalisation (relative): VOLTAGE 10..200, CURRENT 5..100 ──
  // Drives the gauge-chip needle bars + the slider fill (0..1).
  static double voltageNorm(double v) => ((v - vMin) / (vMax - vMin)).clamp(0.0, 1.0);
  static double currentNorm(double i) =>
      ((i - iAtMaxConst) / (iAtStartConst - iAtMaxConst)).clamp(0.0, 1.0);
  static const double iAtStartConst = 100; // = viProduct / vMin
  static const double iAtMaxConst = 5; // = viProduct / vMax

  // ── Heat & motes ─────────────────────────────────────────────────────
  static const int moteCap = 18; // ≤18 heat motes (PRD §7)

  // ── Current pulses on the wire (count/thickness ∝ current) ────────────
  static const int pulseMin = 2;
  static const int pulseMax = 14;
  static const double pulseSpeed = 0.5; // cycles/s along the wire

  /// Pulse count for a given current (linear in current; clamped to [min,max]).
  static int pulseCountFor(double current) {
    final t = ((current - iAtMax) / (iAtStart - iAtMax)).clamp(0.0, 1.0);
    return (pulseMin + (pulseMax - pulseMin) * t).round();
  }

  // ── Entrance reveals (PRD §6) ────────────────────────────────────────
  static const double plantRevealTau = 0.32;
  static const double wireRevealTau = 0.34;
  static const double townRevealTau = 0.36;

  // ── Discovery flash / ring envelope ──────────────────────────────────
  static const double discoveryRingSeconds = 0.7;

  // ── Color tokens (house style; ported palette for cohesion with 2.1–2.4) ──
  // Hero gold (the pinned-power rectangle — the brightest steady element).
  static const Color gold = Color(0xFFFFD27A); // warm-gold fill
  static const Color goldHot = Color(0xFFFFE9B8); // specular / hot edge
  static const Color goldDeep = Color(0xFFD9A43B); // shaded base
  // Wire heat (the enemy — drains to a cold bare conductor as voltage rises).
  static const Color emberCore = Color(0xFFFF7A2E); // wire internal heat core
  static const Color emberHot = Color(0xFFFFF1D8); // white-hot spine at high heat
  static const Color heatFierce = Color(0xFFFF5A24); // fiercest heat at full current
  static const Color energyWarm = Color(0xFFFFD27A); // travelling current pulses
  // Cool voluminous-cable palette (ported from 2.3/2.4 HWTune).
  static const Color wireCool = Color(0xFF59648C); // cold cable body
  static const Color wireCoolDeep = Color(0xFF333C5E); // cable edge (cylindrical)
  static const Color wireSpecular = Color(0xFFAEBCE6); // cool specular band
  // Steel tower ramp (ported verbatim from 2.3 HWTune — brushed steel, cooler/dimmer
  // than the hero so the pylons stay recessive vs the hot wire).
  static const Color towerEdge = Color(0xFF1B2138); // member dark edge (curvature falloff)
  static const Color towerBody = Color(0xFF3C466B); // member mid body
  static const Color towerSpine = Color(0xFF707FAE); // member lit spine (cylindrical sheen)
  static const Color towerRim = Color(0xFF98A6D4); // upper-left chamfer rim light
  static const Color towerBolt = Color(0xFF0C1430); // bolt heads / joint ambient occlusion
  static const Color insulatorCeramic = Color(0xFFB9C4E6); // ceramic insulator discs
  // Town + plant.
  static const Color townWindow = Color(0xFFFFE9B8); // warm lit window
  static const Color townWindowDark = Color(0xFF1A2142); // unlit pane
  static const Color buildingBody = Color(0xFF161D3A);
  static const Color buildingEdge = Color(0xFF2A3358);
  static const Color buildingLit = Color(0xFF20294B); // building wall warmed by light
  static const Color bloom = Color(0xFFFFD27A); // town payoff bloom
  static const Color plantBody = Color(0xFF161D3A);
  static const Color plantEdge = Color(0xFF313B66);
  static const Color plantLite = Color(0xFF44507E);
  // Chrome.
  static const Color chipGlass = Color(0xE60B1330);
  static const Color mono = Color(0xFFE7ECFF);

  // ── Geometry helper ──────────────────────────────────────────────────
  static Offset f(Offset factor, Size s) =>
      Offset(factor.dx * s.width, factor.dy * s.height);
}
