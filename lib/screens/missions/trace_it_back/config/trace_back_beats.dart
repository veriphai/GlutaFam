// Trace It Back — the on-screen text (consolidated update). No Voltix, no mascot.
// TWO de-personified registers:
//   • IMPERATIVES (TBCaption.imperative) — short, large, "what to do".
//   • MEANING-LINES (TBCaption.meaning)  — a few plain lines that carry the lesson
//     ("what just happened / why"); the depth-stop is the one allowed to run long.
// Beat 3 walks the six sources in a FIXED order, each as TWO converging beats
// (input varies → result lands on the same "spin" word so the sameness accumulates).

import 'source_defs.dart';

/// A top-text line + which register it's in (drives the style: big bold imperative
/// vs softer meaning-line).
class TBCaption {
  const TBCaption(this.text, {this.meaning = false, this.long = false});
  const TBCaption.imperative(this.text)
      : meaning = false,
        long = false;
  const TBCaption.meaning(this.text)
      : meaning = true,
        long = false;
  // A meaning-line that's intentionally LONG (kept at the smaller size so it fits).
  const TBCaption.longMeaning(this.text)
      : meaning = true,
        long = true;
  final String text;
  final bool meaning;
  final bool long;
}

class TBCopy {
  TBCopy._();

  // ── Beat 1 — spin the magnet ─────────────────────────────────────────
  static const TBCaption spinMagnet = TBCaption.imperative('Spin the Magnet');
  static const TBCaption fasterBrighter = TBCaption.imperative('Faster — Brighter');
  static const TBCaption holdStill = TBCaption.imperative('Now Hold It Still');
  static const TBCaption onlyMoving = TBCaption.meaning('Only a Moving Magnet Works');
  // The depth-stop — the awe + the honest "why" (NOT "nobody knows why"); the one
  // meaning-line allowed to run long. Lives on the MAGNET beat, not the sources.
  static const TBCaption depthStop = TBCaption.longMeaning(
    'Electricity and magnetism are two sides of the same coin called electromagnetism.',
  );

  // ── Beat 2 — turn the turbine (by hand) ──────────────────────────────
  static const TBCaption turnTurbine = TBCaption.imperative('Turn the Turbine');
  static const TBCaption sameTrick = TBCaption.meaning('Same Trick, One Step Back');
  static const TBCaption stillYourArm = TBCaption.meaning('Still Your Arm Doing It');

  // ── Beat 3 — the handoff, then the sources ───────────────────────────
  static const TBCaption handoff = TBCaption.meaning('Now Something Turns It For You');

  /// The two converging beats for a source: (input — varies, result — converges
  /// on the spin word). Both are imperative-register (punchy) so the repeated
  /// spin word accumulates.
  static (TBCaption, TBCaption) sourceBeats(EnergySource s) {
    switch (s) {
      case EnergySource.coal:
        return (const TBCaption.imperative('Coal Burns'), const TBCaption.imperative('Steam Spins It'));
      case EnergySource.gas:
        return (const TBCaption.imperative('Gas Burns'), const TBCaption.imperative('Steam Spins It'));
      case EnergySource.nuclear:
        return (const TBCaption.imperative('Atoms Split'), const TBCaption.imperative('Still Just Steam — Same Spin'));
      case EnergySource.hydro:
        return (const TBCaption.imperative('Water Falls'), const TBCaption.imperative('No Fire — Same Spin'));
      case EnergySource.wind:
        return (const TBCaption.imperative('Wind Blows'), const TBCaption.imperative('Same Wheel Again'));
      case EnergySource.solar:
        return (const TBCaption.imperative('No Spinning Here'), const TBCaption.imperative('Light Itself Makes It'));
    }
  }

  /// Solar's optional depth-stop hook (small/secondary — the default path stays
  /// crisp; mirrors induction, no faked photovoltaic "why").
  static const String solarHook = 'Light knocks tiny charges loose — a deeper trick for later.';

  // ── Synthesis → card (after solar; names the ubiquity, name-last) ─────
  static const TBCaption synthesis = TBCaption.meaning('Almost Everything Spins a Magnet');
  static const String cardBrag = 'The Magnet Trick — behind almost every power plant on Earth.';

  // ── Timings (ms) ─────────────────────────────────────────────────────
  static const int litToHoldMs = 2200; // first light → "hold it still"
  static const int onlyMovingToDepthMs = 2600; // discovery line → depth-stop
  static const int depthToTurbineMs = 4400; // depth-stop (long) → turbine beat
  static const int sameTrickToArmMs = 2400; // "same trick" → "still your arm"
  static const int armToSourceMs = 2800; // "still your arm" → the source handoff
  static const int handoffToSourceMs = 2600; // handoff line → first source beat
  static const int beat1To2Ms = 1900; // a source's beat 1 → beat 2
  static const int synthesisToCardMs = 2600; // synthesis line → card earn
}

/// The fixed order the activity walks through the sources (solar last).
const List<EnergySource> kSourceOrder = [
  EnergySource.coal,
  EnergySource.gas,
  EnergySource.nuclear,
  EnergySource.hydro,
  EnergySource.wind,
  EnergySource.solar,
];
