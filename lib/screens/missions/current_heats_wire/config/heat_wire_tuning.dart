// The Hot Wire — all tunables in one place (PRD §15 file plan, §16 scene sketch).
// Every geometry value is a FACTOR of the one stage size (W×H); the controller
// multiplies through. Time constants, gate thresholds, the heat gain, mote rates
// and all the §6 timings live here so the sim reads as one honest model.
//
// 10x REBUILD — DIAGONAL SPAN. The two towers are re-placed diagonally to fill the
// frame (killing the dead air the centered same-height U left): the LEFT/PLANT
// tower sits LOWER (top ≈ 0.40·H) and the RIGHT/CITY tower sits HIGHER
// (top ≈ 0.12·H), so the wire runs as a dramatic diagonal from lower-left up to
// upper-right, with a catenary SAG dipping below the straight diagonal. The wire's
// drawn geometry is the HELD-CONSTANT — identical across every beat; only its glow
// widens/brightens. All geometry stays factor-based. No lamp glyph — this is a
// TRANSMISSION span; the receiving CITY tower is the destination, so the hero is
// the hot wire bleeding energy as heat between the two towers.

import 'package:flutter/painting.dart' show Color, Rect;

class HWTune {
  HWTune._();

  // ── Scene geometry (factors of stage W×H) — PRD §16, DIAGONAL layout ──
  static const double pylonLeftX = 0.12; // left/PLANT post x (lower-left)
  static const double pylonRightX = 0.88; // right/CITY post x (upper-right)
  // Diagonal anchors: the left anchor sits LOW, the right anchor sits HIGH, so the
  // span climbs PLANT→CITY across the whole frame.
  static const double pylonLeftTopY = 0.40; // left anchor top y (lower) — lifted up
  static const double pylonRightTopY = 0.12; // right anchor top y (higher) — fills the top space
  static const double pylonBaseY = 0.90; // post foot y (both feet near the floor)
  // Catenary midspan low point, as an EXTRA sag DEPTH below the straight diagonal
  // (factor of H). The dip reads as real cable weight.
  static const double sagDepthF = 0.085; // max sag below the straight diagonal (of H)
  static const double wireStrokeF = 0.018; // voluminous conductor body width (of H)

  // ── Lattice tower build (factors of H) — premium steel rebuild ─────────
  // Each member is drawn as a CYLINDRICAL steel bar (dark edge → bright spine →
  // dark edge) with an upper-left chamfer rim, bolted joints + AO, a ground-contact
  // shadow and a real insulator string — the hand_crank_lamp metal craft, kept
  // dim/recessive so the HOT WIRE always stays the hero. Global key light: UPPER-LEFT.
  static const double towerLegWF = 0.0064; // leg member width
  static const double towerBraceWF = 0.0032; // cross-brace member width
  static const double towerHeadHalfF = 0.016; // half-width at the apex
  static const double towerBaseHalfF = 0.046; // half-width at the splayed feet
  static const int towerRungs = 5; // lattice panels (X-braced segments)
  static const double insulatorDiscRF = 0.0058; // ceramic insulator disc radius
  static const int insulatorDiscs = 2; // bells in the suspension string

  // Plant (left) + city (right) — destination tags follow the diagonal anchors.
  // No lamp glyph: the receiving CITY tower IS the destination (heat loss is the
  // hero; energy that leaks as heat never reaches the far tower).
  static const double plantTagX = 0.12;
  static const double plantTagY = 0.945; // grounded plate just under the left foot
  static const double cityTagX = 0.88;
  static const double cityTagY = 0.945; // grounded plate just under the right foot

  // SAME WIRE held-constant tag — an annotation pill in the cooler lower gutter
  // (OUT of the hot midspan bloom) with a thin leader up to the wire.
  static const double sameWireTagX = 0.40;
  static const double sameWireTagY = 0.47;

  // Rub band: hit region is |dy from catenary y(x)| <= rubBandHF*H for
  // x in [rubMinX, rubMaxX]*W. Finger glow radius is a factor of H.
  static const double rubBandHF = 0.075;
  static const double rubMinX = 0.18;
  static const double rubMaxX = 0.82;
  static const double rubGlowRF = 0.065;
  static const double rubMinTravelF = 0.04; // min |dx| per stroke (of W) to count

  // ── Sim time constants ───────────────────────────────────────────────
  static const double currentTau = 0.12; // slider → current ease
  static const double tempRiseTau = 0.25; // wireTemp rise
  static const double tempCoolTau = 0.90; // wireTemp cool (real thermal decay)
  static const double rubCoolTau = 0.90; // rubHeat decay when not rubbing
  static const double kGain = 1.0; // heatInput = current^2 * kGain (+ rub)
  static const double rubGain = 1.55; // pointer-speed → rub heat input scale

  // Displayed numbers sampled this many times per second (legible ticking).
  static const double sampleHz = 5.0;

  // ── Gate thresholds — PRD §14 ────────────────────────────────────────
  static const double sustainHi = 0.75; // current >= this …
  static const double sustainMs = 600; // … held continuously this long → advance
  static const double dropLowCurrent = 0.15; // dropLow gate: current <= this …
  static const double dropLowTemp = 0.25; // … AND wireTemp <= this
  static const double a2Temp = 0.35; // A2 secondary appears once wireTemp >= this
  static const double rubGateHeat = 0.5; // rub gate: rubHeat >= this …
  static const int rubGateReversals = 3; // … AND >= this many stroke reversals
  static const double rubB2Heat = 0.2; // B2 secondary appears at rubHeat >= this

  // ── Discovery flash ──────────────────────────────────────────────────
  static const double flashMs = 700; // glow-flash envelope at the A3 discovery

  // ── Pulses (3 packets along the catenary, left→right) ────────────────
  static const int pulseCount = 3;
  static const double pulseSpeed = 0.34; // span-fraction per second at full current
  static const double pulseTaperBase = 0.30; // subtle brightness taper toward the city
  static const double pulseTaperEmph = 0.72; // amplified taper in beat C
  static const double moteEmphasis = 1.6; // mote emission ×1.6 in beat C

  // ── Heat motes ───────────────────────────────────────────────────────
  static const int moteMax = 110; // pooled heat motes cap
  static const double moteLife = 1.7; // mote lifetime (s)
  static const double moteRiseTop = 0.06; // motes rise toward this y (of H)
  static const double moteSpawnPerSec = 78; // base spawn rate at heatInput=1

  // Ambient cool far-layer motes (PRD §16: <=20).
  static const int ambientMoteMax = 18;

  // ── Heat-haze shimmer band (rising refraction approximation) ─────────
  // A stack of translucent wavy warm bands above the glowing span, blurred + slowly
  // sine-displaced so it reads as rising heat-shimmer. Intensity scales with heat.
  static const int hazeBands = 6; // wavy translucent layers (denser → a sheet, not ribbons)
  static const double hazeRiseF = 0.16; // how far the shimmer climbs above the span (of H)
  static const double hazeWaveAmpF = 0.012; // sine displacement amplitude (of H)
  static const double hazeWaveLenF = 0.22; // sine wavelength along the span (of W)
  static const double hazeSpeed = 0.55; // shimmer scroll speed (cycles/sec)
  static const double hazeBaseAlpha = 0.15; // peak alpha per band at full heat

  // ── Voluminous cable / ember core shading ────────────────────────────
  static const double cableHighlightFrac = 0.20; // specular band width on the cool body
  static const double glowWidenMax = 2.4; // ember bloom widens to this × stroke at max temp
  // The HERO's loss gradient: the ember is hottest at the PLANT end and cools toward
  // the CITY — the city end keeps (1 − lossTaper) of the plant brightness, so the
  // wire visibly bleeds its energy as heat before arriving (the lesson, in the hero).
  static const double lossTaper = 0.5;

  // ── Entrance reveal ──────────────────────────────────────────────────
  static const double revealDurationMs = 460; // per-element reveal
  static const double revealStaggerMs = 90; // stagger between elements
  static const double revealStartMs = 0; // first reveal begins here

  // ── Palette ──────────────────────────────────────────────────────────
  static const Color wireCool = Color(0xFF59648C); // cold cable body
  static const Color wireCoolDeep = Color(0xFF333C5E); // cable edge (cylindrical)
  static const Color wireSpecular = Color(0xFFAEBCE6); // cool specular band
  static const Color emberCore = Color(0xFFFF7A2E); // wire internal heat core
  static const Color emberHot = Color(0xFFFFF1D8); // white-hot core at high temp
  static const Color energyWarm = Color(0xFFFFD27A); // travelling energy pulses
  // Steel tower ramp (brushed-steel, ported from hand_crank_lamp; cooler/dimmer
  // than the crank so the towers stay recessive vs the hot wire).
  static const Color towerEdge = Color(0xFF1B2138); // member dark edge (curvature falloff)
  static const Color towerBody = Color(0xFF3C466B); // member mid body
  static const Color towerSpine = Color(0xFF707FAE); // member lit spine (cylindrical sheen)
  static const Color towerRim = Color(0xFF98A6D4); // upper-left chamfer rim light
  static const Color towerBolt = Color(0xFF0C1430); // bolt heads / joint ambient occlusion
  static const Color insulatorCeramic = Color(0xFFB9C4E6); // ceramic insulator discs
  static const Color heroDark = Color(0xFF070A1C); // near-black field

  // ── Capture crops (mirror the locked EP2 catalog) ────────────────────
  static const Rect heatLeavesCrop = Rect.fromLTRB(0.04, 0.16, 0.96, 0.62);
  static const Rect rubbedWarmCrop = Rect.fromLTRB(0.15, 0.20, 0.85, 0.60);
}
