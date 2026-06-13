// Voltage and Current — tunable constants + geometry factors (PRD §15 file plan
// `config/vc_config.dart`, §16 scene sketch). Everything here is DATA: the sim
// ratio, the gate thresholds, the geometry anchors (FACTORS of the stage rect,
// never pixels — resolution independent), the timing/sustain knobs and the
// palette tokens. A live on-device tuning pass is expected; keeping it in one
// place means a nudge is a one-number edit. PRD references are inline so the
// "why" of each magic number is traceable.

import 'dart:ui' show Color, Offset;

class VCTune {
  VCTune._();

  // ── The sim (PRD §4, §10, §13.1) ─────────────────────────────────────
  /// current = kCurrentRatio × voltage. Deliberately 0.4 (not 1.0) so VOLTAGE
  /// (0–100) and CURRENT (0–40) NEVER display the same number — the two
  /// quantities can never read as one quantity with two names (PRD §12 anti-
  /// pattern, §11.4 acceptance). The wire is "the same wire" — this ratio is the
  /// fixed wire, held constant the whole activity (the 2.5 flip pins POWER).
  static const double kCurrentRatio = 0.4;

  /// Display scales — the two live numbers (PRD §4): VOLTAGE 0–100, CURRENT 0–40.
  static const double voltageScale = 100;
  static const double currentScale = 40; // = voltageScale × kCurrentRatio

  /// The cutoff floor (PRD §6.4, §11.2): at/below this the current, motes and lamp
  /// are HARD-GATED to zero THE SAME FRAME — no decay, no fade tail, ever.
  static const double cutoffFloor = 0.02; // V ≤ 2 on the 0–100 scale

  /// Raised-and-the-current-follows: V ≥ this fires the "push / flow" lesson
  /// label (interaction-driven, not a timer).
  static const double pushFlowGate = 0.30; // V ≥ 30 → "Voltage is the push…"

  /// "High" — arms the drop prompt and the cutoff (PRD §6.3/§6.4, §14 gates).
  static const double highVoltage = 0.80; // V ≥ 80
  static const double dropPromptSustainSec = 0.70; // V ≥ 80 sustained 700 ms → T3

  /// The pin-beat gate (PRD §6.6, §14): the SAME WIRE chip pulses + T8 fires at
  /// V ≥ 70; if already ≥70 at beat entry a 600 ms dwell satisfies it.
  static const double pinGate = 0.70; // V ≥ 70
  static const double pinDwellSec = 0.60;

  // ── Drag mapping (PRD §6.2, §14 input) ───────────────────────────────
  /// A full 0→1 voltage sweep maps over this fraction of stage HEIGHT of drag —
  /// generous so fine control feels good and the column never snaps.
  static const double dragRangeFactor = 0.30;

  /// Haptic detent: a selectionClick every 0.1 of the 0–1 range (every 10 units).
  static const double detentStep = 0.10;

  // ── Lamp response (PRD §10, §14) ─────────────────────────────────────
  /// Brightness ripple toward current (tau 0.11 s) WHILE current > 0; forced to 0
  /// the same frame current hits 0 (never a cool-down — the paintBulb filament is
  /// driven straight off this).
  static const double lampRippleTau = 0.11;

  /// Premium hero (P0.1): a low-amplitude "breath" on the LIT lamp's bloom + ray
  /// length so it feels alive — never enough to prevent the same-frame hard zero
  /// (breath modulates only when brightness > 0; at cutoff b = 0 so it vanishes).
  static const double lampBreathHz = 0.5; // ~0.5 Hz breathing
  static const double lampBreathAmp = 0.07; // ± fraction on bloom/ray length

  /// God-rays around the lit lamp (P0.1, ported from hand_crank _paintLightRays).
  static const int lampRayCount = 16; // ~16 rays
  static const double lampRayLenFactor = 2.6; // base ray length / lampRadius
  static const double lampRayLenGain = 3.2; // extra length × brightness

  // ── Mote stream — the luminous CURRENT RIVER (P0.2, PRD §10) ──────────
  /// Motes ride the loop path clockwise; speed AND alpha ∝ current → at current 0
  /// they STOP and VANISH the same frame. DENSITY now scales with current: few at
  /// low voltage, many at high (the river thickens as the push grows).
  static const int moteCountMin = 6; // motes at the faintest live current
  static const int moteCountMax = 30; // motes at full current
  static const double moteBaseSpeed = 0.26; // loops/sec at full current
  static const int moteTrailSamples = 5; // fading trail samples behind each mote
  static const double moteTrailSpacing = 0.012; // loop-fraction gap between samples
  static const int ambientMoteCount = 18; // background drift (≤20, PRD §7)

  // ── Surge particles (P1.4): fed into the loop from the console corners ─
  /// Spawned at the two lower loop corners (~0.70h) at a rate ∝ current; they
  /// stream UP into the loop, reading as the console "charging" the circuit.
  static const double surgeSpawnRate = 26.0; // particles/sec at full current
  static const int surgeMax = 70; // hard cap on live surge particles
  static const double surgeLifeSec = 0.9;
  static const double surgeRiseSpeedFactor = 0.55; // up-speed / stage height per sec

  // ── Scatter burst at the cutoff (P1.6) — the after-punctuation only ───
  /// On the cutoff frame the river's motes fly outward + fade. NOT the death (the
  /// motes already hard-zeroed that frame); this is the visual punctuation.
  static const double scatterLifeSec = 0.55;
  static const double scatterSpeedFactor = 0.6; // outward speed / stage width per sec
  static const double shockwaveSec = 0.55; // dark shockwave ring from the dead lamp

  // ── Envelopes ────────────────────────────────────────────────────────
  static const double discoveryFlashSec = 0.70; // the cutoff flash (PRD §6.4)
  static const double chipPulseSec = 0.90; // SAME WIRE chip pulse at T8 (PRD §6.6)
  static const double revealTau = 0.40; // entrance reveals (slide+fade)

  /// Orchestrated entrance (P1.7): a single "energize-in" envelope, ~0.9 s, that
  /// the loop / console / lamp-first-breath ride (richer than uniform tau fades).
  static const double entranceSec = 0.9;

  /// Conductive sheen (P1.8): a COOL bright band travelling the live wire while
  /// current > 0 (reads as "circuit alive"). COOL ONLY — the wire NEVER warms.
  static const double sheenLoopsPerSec = 0.5; // band travels at this rate
  static const double sheenWidthFraction = 0.12; // band length / loop perimeter

  /// Display roll (P2.9): the readout numbers lerp UP only (rolling digits on the
  /// way up); they HARD-ZERO the same frame at cutoff (no roll-down lag).
  static const double displayRollTau = 0.07;

  // ── Geometry anchors (FACTORS of stage size — PRD §16) ───────────────
  static const Offset lampFactor = Offset(0.50, 0.165); // bulb centre
  static const double lampRadiusFactor = 0.135; // bulb radius / stage width (bigger hero)
  static const double lampBloomFactor = 0.46; // max bloom radius / stage width

  static const Offset currentChipFactor = Offset(0.50, 0.335); // CURRENT gauge, clears the bigger bulb
  static const Offset pinChipFactor = Offset(0.04, 0.45); // ON the (now near-edge) left wire run

  // The loop (rounded rect): left/right vertical runs + top/bottom corners.
  // Near-edge wide + taller — the bulb sits IN the TOP run (centre) and the
  // voltage console straddles the BOTTOM run (centre), embedded in the circuit.
  static const double loopLeftX = 0.04; // left run x (near the edge — ~30% wider)
  static const double loopRightX = 0.96; // right run x (near the edge)
  static const double loopTopY = 0.20; // just below the bulb base (loop is taller)
  static const double loopBottomY = 0.76; // the bottom run the console straddles
  static const double loopCornerFactor = 0.06; // corner radius / stage width
  static const double wireStrokeFactor = 0.012; // wire stroke / stage width

  // ── The PRESSURE CONSOLE + glowing PISTON (P0.3) ─────────────────────
  // The voltage source, placed IN the circuit's bottom run like the bulb is in
  // the top run: its TOP overlaps loopBottomY (the run goes into it), centred,
  // narrower than the loop so the bottom run flanks it on both sides. The whole
  // console rect (with slop) stays the forgiving drag target; the VOLTAGE number
  // rides ON the piston head (no separate voltage chip).
  static const Offset consoleFactor = Offset(0.50, 0.76); // centred ON the bottom run (straddles it)
  static const double consoleWidthFactor = 0.52; // narrower than the loop — the bottom run flanks it
  static const double consoleHeightFactor = 0.205; // console height / stage height

  /// The vertical piston track inside the console (where the head travels).
  static const double trackWidthFactor = 0.13; // track width / stage width
  static const double trackInsetFactor = 0.022; // track top/bottom inset / stage h

  /// The piston HEAD — a wide rounded knob bar that rides at the voltage level.
  static const double pistonHeadWidthFactor = 0.30; // head width / stage width
  static const double pistonHeadHeightFactor = 0.052; // head thickness / stage height

  // ── Palette (PRD §7 house style) ─────────────────────────────────────
  static const Color base = Color(0xFF070A1C); // near-black base
  static const Color moteWarm = Color(0xFFFFD27A); // the current, made visible
  static const Color moteHot = Color(0xFFFFF1D6); // hot centre of each mote
  static const Color lampWarm = Color(0xFFFFE9B8); // the lamp bloom
  static const Color controlCool = Color(0xFF3FB9F5); // the console — clearly the control
  static const Color controlCoolLite = Color(0xFF7FD8FF); // piston-head top highlight / glow
  static const Color wireSteel = Color(0xFF5E6E92); // the fixed wire (cool steel)
  static const Color chipText = Color(0xFFD6E2FF); // mono readout text
  static const Color chipGlass = Color(0xCC0B1330); // dark glass chip fill
  static const Color glassBorder = Color(0x26FFFFFF);
}
