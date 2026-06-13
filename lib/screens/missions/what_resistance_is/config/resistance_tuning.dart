// All the geometry factors, the current model, packet caps, the drag mapping,
// every timer (ms) and the gate windows for "Shape the Wire" (beat 2.2). One
// place to tune the whole feel — the controller and painter read from here so
// the build stays config-driven (the TBTune / CrankConfig pattern).
//
// PEDAGOGY GUARDRAILS encoded here:
//  • Conservation: rendered cross-section × length is held constant — width ∝
//    1/sqrt(lengthFactor). So "longer is visibly thinner, same metal" is true by
//    construction, every frame (acceptance §2).
//  • The squared current law is INTERNAL drama only (never surfaced) — I(t) ∝
//    (Lf(mid)/Lf(t))² gives the ≈9× swing (≈45 thin / 100 mid / ≈400 fat).
//  • No heat anywhere: there is NO warm/red ramp keyed to thinness in this file —
//    the choke reads as LESS flow (sparser, slower, dimmer), never temperature.

import 'package:flutter/material.dart';

class RTune {
  RTune._();

  // ── The morph axis ────────────────────────────────────────────────────────
  /// morphT 0 = short + fat, 1 = long + thin. Start at the 2.1 mid-wire.
  static const double morphStart = 0.5;

  /// lengthFactor across the sweep — drives both rendered length and (inversely)
  /// rendered width, so the same metal stretches/squashes.
  static const double lengthFactorFat = 0.60; // morphT = 0
  static const double lengthFactorThin = 1.80; // morphT = 1

  // ── The current model (relative, ≤2 numbers; squared form is internal) ─────
  /// Baseline displayed current at the mid wire.
  static const double currentBaseline = 100.0;

  // Flow rendering compression so the stream stays legible across a 9× swing.
  static const double flowSpeedExponent = 0.6; // packet speed ∝ I^0.6
  static const int packetCountMin = 4;  // thin: a near single-file trickle (sparser → harder choke)
  static const int packetCountMax = 18; // fat: a fuller multi-lane stream (kept DISCRETE, never a blur)

  // ── The current RIVER inside the wire (ported 2.1 craft, P0.2) ─────────────
  /// Each packet leaves a short fading trail of [riverTrailSamples] samples behind
  /// its head; reduced motion collapses to a single head (no trail).
  static const int riverTrailSamples = 5;   // fading trail samples per packet head
  static const double riverTrailSpacing = 0.020; // along-wire u-gap between samples
  /// Packet core radius as a fraction of the local half-width (kept legible even
  /// thin) — the warm core; the additive halo is a multiple of it.
  static const double riverCoreWidthFrac = 0.52; // core r / local half-width (chunkier on the dark conduit)
  static const double riverCoreRMin = 2.4;  // floor so the thin trickle still reads as bright beads
  static const double riverHaloMul = 2.2;   // halo radius / core radius (a bigger warm bloom)
  /// Lane spread: how far (×local half-width) the outer lanes ride off-centre when
  /// the wire is fat enough to braid. Thin clamps lanes to 1 (single file).
  static const double riverLaneSpread = 0.62;

  // ── Wire geometry (factors of stage size W×H; resolved once per paint) ─────
  // The whole circuit is CENTRED horizontally (hero left run + return right run are
  // symmetric about 0.50) and vertically (the mid-state loop is centred in the
  // stage), and the loop is ~30% wider than before — no dead space on the sides.
  static const double sourceBarCenterX = 0.50;
  static const double sourceBarY = 0.20; // the top run height (where the terminals sit)

  /// The HERO (left vertical run) centre x; the return run mirrors it about 0.50.
  static const double heroCenterX = 0.10;

  // The VOLTAGE SOURCE module — the pinned "battery" wired into the loop. It
  // REPLACES the old meter-dial + floating VOLTAGE chip + supply bar, so it reads
  // unmistakably as the source: the value lives ON it (like activity 1's control),
  // the gold pin = pinned/fixed, and the loop wires enter/leave its two terminals.
  // Centred over the wider loop; size unchanged (already big enough).
  static const double sourceX = 0.50;             // module centre x (stage factor)
  static const double sourceWidthFactor = 0.30;   // module width / stage W
  static const double sourceHeightFactor = 0.076; // module height / stage H
  static const double dialX = 0.685; // (kept for back-compat refs; source center governs)

  static const double wireTopY = 0.285; // the top terminal the wire hangs from
  // Hero run lengths + a lower bulb so the centred loop fills the stage height.
  static const double wireEndYFat = 0.52; // morphT = 0 → short
  static const double wireEndYMid = 0.64; // morphT = 0.5 → the 2.1 wire length
  static const double wireEndYThin = 0.76; // morphT = 1 → long

  // Dimensional-cable width anchors (P0.1). Slightly fatter fat + a thin that is
  // still a TAUT CABLE with a lit core (≥0.030W) — never a hair/thread. The ~6×
  // swing still reads dramatically against the river density swing.
  static const double wireWidthFat = 0.150; // morphT = 0 (trimmed so the far-left fat hero clears the edge)
  static const double wireWidthMid = 0.082; // morphT = 0.5 (the 2.1 mid wire)
  static const double wireWidthThin = 0.032; // morphT = 1 (taut, still a cable)

  /// The rendered full-width FRACTION of stage W at morphT t, piecewise through
  /// the three §16 anchors (fat → mid → thin). One source of truth so the painter
  /// geometry and the controller's lane affordance never drift.
  static double widthFracAt(double t) {
    final c = t.clamp(0.0, 1.0);
    return c <= 0.5
        ? wireWidthFat + (wireWidthMid - wireWidthFat) * (c / 0.5)
        : wireWidthMid + (wireWidthThin - wireWidthMid) * ((c - 0.5) / 0.5);
  }

  /// Serpentine is OFF (Pillar 3): a stretched thin cable reads DEAD-STRAIGHT and
  /// taut under tension, never a floppy wave. Length grows straight down into the
  /// room the stage affords (the thin end sits at ~0.665H, lamp at ~0.77H — on
  /// stage). The taut read comes from the strain sheen + a tiny quiver, not a bend.
  static const double serpentineOnset = 0.70;
  static const double serpentineAmpFactor = 0.0; // straight taut cable — no wave

  /// A tiny premium quiver on the fully-taut (thin) cable — a sub-pixel-ish lateral
  /// vibration that reads as "strained", never a wobble. Scales in above tensionOnset.
  static const double quiverAmpFactor = 0.0042; // × stage W at full thin
  static const double quiverHz = 26.0;          // fast, low-amplitude tremor

  // ── Dimensional cable shading (P0.1) — a 3D cylinder, not a 2D strip ───────
  /// The centre specular highlight band width as a fraction of the full width, and
  /// its peak brightness. Edges go darker (rounded) so the body reads cylindrical.
  static const double cableHighlightFrac = 0.34; // specular band width / full width
  static const double cableEndCapFrac = 0.55;    // rounded end-cap height / local width

  // ── Elastic-tension flourish (P1.4) — COOL only, render-only, no morph easing ─
  /// Above this morphT a faint cool tension sheen appears and the wire straightens
  /// slightly (serpentine already keys here too). Tension is purely visual.
  static const double tensionOnset = 0.60;       // tension reads above this morphT
  static const double tensionSheenAlpha = 0.22;  // peak cool tension-sheen alpha
  /// Fat relaxation: a gentle outward bulge factor on the body below this morphT.
  static const double relaxOnset = 0.40;
  static const double relaxBulge = 0.10;         // extra mid-bulge fraction when fat

  static const double currentChipX = 0.85; // sits right by the return wire
  static const double currentChipY = 0.50;
  static const double lampDropBelowEnd = 0.085; // lamp sits this far below wire end
  static const double lampRadiusFactor = 0.082; // a bigger BULB (the load — reads clearly)
  static const double lampBloomFactor = 0.135;  // bloom stays modest (secondary to the river)
  static const double lampBreathHz = 0.5;       // gentle living breath on the lit lamp
  static const double lampBreathAmp = 0.06;
  static const double returnPathX = 0.90; // the return rail x — mirrors heroCenterX about 0.50

  // ── The CLOSED-LOOP circuit (source → hero → bulb → return → source) ────────
  /// The whole circuit is a VISIBLE steel loop so the learner SEES current travel
  /// end-to-end and light the bulb. The hero is the fat morphable run; the leads /
  /// bottom / return / top are thin fixed steel wires carrying the SAME beads
  /// (series current is conserved around the loop).
  static const double thinWireWidthFactor = 0.013; // thin loop-wire stroke / stage W
  static const double beadThinRFactor = 0.0140;    // bead radius on the thin wire / stage W
  /// Bead spacing along the WHOLE loop — beads stay discrete and clearly moving
  /// (the lesson is the visible flow, not a blur). Lower = more beads.
  static const int loopTrailSamples = 4;           // fading trail behind each bead head
  static const double loopTrailSpacing = 0.012;    // loop-fraction gap between trail samples

  // ── Tactile grab handle / terminal clamp (P0.3) ────────────────────────────
  /// The clamp grip sits at the wire's lower end (u≈this) and is the clear pull
  /// affordance. The forgiving hit-test (whole lower region) is unchanged.
  static const double handleAnchorU = 0.985;       // where the clamp grips the cable
  static const double handleWidthFactor = 0.10;    // clamp body width / stage W (a real grip)
  static const double handleHeightFactor = 0.040;  // clamp body height / stage H

  // ── The drag mapping (no inertia, holds on release) ───────────────────────
  /// Full morphT sweep over this fraction of stage height of vertical drag.
  /// Drag DOWN (positive dy) stretches → morphT up.
  static const double dragRangeHFactor = 0.42;

  /// Detents: a selectionClick each time morphT crosses a multiple of this.
  static const double detentStep = 0.125;

  // ── Gate windows ──────────────────────────────────────────────────────────
  static const double thinGate = 0.85; // morphT ≥ this …
  static const double fatGate = 0.15; // morphT ≤ this …
  static const int gateSustainMs = 400; // … sustained this long → discovery
  static const double sweepBandThin = 0.80; // sweep must visit ≥ this …
  static const double sweepBandFat = 0.20; // … and ≤ this (either order)

  // ── Pin / dial ────────────────────────────────────────────────────────────
  static const double dialHitRadiusFactor = 0.085; // deny-tap hit region (× W)
  static const int denyShakeMs = 520;

  // ── Timers (ms) — the silent step machine ─────────────────────────────────
  static const int introToPinMoveMs = 600;
  static const int pinFlightMs = 900;
  static const int m1HoldMs = 1100; // m1 dwell before i1 + grab ring
  static const int discoveryFlashMs = 700;
  static const int m2HoldMs = 2400; // thin discovery caption dwell → i2
  static const int m3HoldMs = 2400; // fat moment caption dwell → i3
  static const int sweepTimeoutMs = 8000;
  static const int m4HoldMs = 2600;
  static const int m5HoldMs = 3400;
  static const int m6HoldMs = 3200;
  static const int m7HoldMs = 3000;
  static const int landingBlendMs = 1600;
  static const int m8HoldMs = 3200; // landing caption dwell → card
  static const int echoHideMs = 2200; // e1/e2 auto-hide
  static const int resistLabelFadeMs = 600; // mono "RESISTANCE" specimen fade-in

  // Entrance reveals (≤450 ms each).
  static const int sourceRevealMs = 420;
  static const int wireRevealMs = 440;
  static const int lampRevealMs = 420;

  // Display number cadence — tick the CURRENT chip ~9 Hz so it reads, not blurs.
  static const int currentSampleMs = 110;

  // ── Colours — mirrors voltage_and_current (activity 1) house tokens so the
  //    episode speaks ONE cool-conduit + warm-current-river language. The CONDUIT
  //    BODY is DARK and recessive (a glass/steel vessel); the warm additive RIVER
  //    glows through it as the brightest thing on screen. The body NEVER warms
  //    (heat is 2.3's job — the choke reads as LESS flow, never temperature).
  static const Color energy = Color(0xFFFFD27A);    // warm river core   (VC moteWarm)
  static const Color energyHot = Color(0xFFFFF1D6); // hot river centre  (VC moteHot)
  static const Color energyGlow = Color(0xFFFFE9B8);// soft warm halo    (VC lampWarm)

  // The dark conduit body — a cavity the current lights from within; cool steel
  // walls; one thin cool rim. Low value so the additive river dominates.
  static const Color conduitEdge = Color(0xFF0C1326);  // deep rounded edge (near base)
  static const Color conduitWall = Color(0xFF2A3760);  // dark steel wall
  static const Color conduitSheen = Color(0xFF5C72AC); // cool sheen band (the lit side)
  static const Color conduitRim = Color(0xFF9DB4EE);   // thin cool rim line

  // The CONTROL family — the cyan the learner pushed in 2.1 (VC controlCool). The
  // grab handle, strain, choke ring, surge, dial accents all speak this cyan.
  static const Color controlCool = Color(0xFF3FB9F5);
  static const Color controlCoolLite = Color(0xFF7FD8FF);

  // The frozen VOLTAGE control — the glossy cyan piston-knob of 2.1, now pinned.
  static const Color pistonTop = Color(0xFFDCF1FF);
  static const Color pistonHi = Color(0xFF74C4F4);
  static const Color pistonMid = Color(0xFF2E78B6);
  static const Color pistonDeep = Color(0xFF1B4A73);

  // Wire metal (thin lit rim / lead lines) — cool steel, never warm (VC wireSteel).
  static const Color wireMetal = Color(0xFF5E6E92);
  static const Color wireMetalDeep = Color(0xFF2A3760); // darker rounded edge
  static const Color wireSpecular = Color(0xFFC3D3FF);  // cool specular streak

  // POLISHED STEEL (ported from hand_crank_lamp — the prologue cable look). A real
  // metal cylinder: dark steel edges → a bright steel highlight band → dark edges.
  // The hero cable + the thin loop wires (leads/return/top/bottom) all read steel;
  // the warm current beads ride ON the steel as the only warm thing (cool body).
  static const Color steelEdge = Color(0xFF3A4670); // dark steel edge / under-stroke
  static const Color steelMid = Color(0xFF515E94);  // steel body
  static const Color steelLite = Color(0xFFB9C4F0); // bright steel highlight band
  static const Color steelRim = Color(0xFFAEB9E8);  // crisp rim light

  // Landing: the real arm-thick stranded-aluminium cable.
  static const Color cableSheath = Color(0xFF161E3C);  // dark outer sheath
  static const Color cableAlu = Color(0xFFB9C4DC);     // stranded aluminium
  static const Color cableAluLite = Color(0xFFEAF1FF); // strand highlight
  static const Color cableAluDeep = Color(0xFF5E6E92); // strand edge
  static const Color forearmGhost = Color(0xFFE7D8C4);

  // Cool strain / choke / surge — the control-cyan family (NEVER warm).
  static const Color tensionCool = Color(0xFF7FD8FF);  // = controlCoolLite

  // Instrument chips — DARK glass + cool text (VC chipGlass / chipText).
  static const Color chipGlass = Color(0xCC0B1330);
  static const Color chipBorder = Color(0x33FFFFFF);
  static const Color chipText = Color(0xFFD6E2FF);

  static const Color goldPin = Color(0xFFF5C451);    // the gold pin/lock MARKER (frozen proof)
  static const Color returnCool = Color(0xFF45527A); // faint return rail (cool steel)

  // Stage tints
  static const double returnPathAlpha = 0.18; // ≤20% — quiet loop honesty
  static const double landingDimAlpha = 0.12; // chrome/lamp fade at the landing

  // ── The arm-thick-cable PAYOFF (Pillar 4) — a bold, CONSISTENT VERTICAL cable ─
  /// The reveal no longer swells whatever crooked shape the learner left it in
  /// (that produced a squat horizontal blob). It grows a fixed, straight, vertical
  /// arm-thick stranded conductor along the stage centreline — always premium.
  static const double landingTopY = 0.205;        // top of the reveal cable (stage-factor)
  static const double landingBottomY = 0.715;     // bottom of the reveal cable
  static const double landingHalfWidthFrac = 0.150; // half-width / stage W (genuinely arm-thick)
  static const double landingStrandWidthFrac = 0.030; // one strand radius / stage W (a bundle, not marbles)
}
