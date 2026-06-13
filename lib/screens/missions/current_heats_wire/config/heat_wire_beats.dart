// The Hot Wire (beat 2.3) — the on-screen text (PRD §5, verbatim) + the phase
// machine enum (PRD §14) + every line hold (ms) from the beat flow (PRD §6).
//
// TWO de-personified registers ONLY:
//   • IMPERATIVES (≤5 words, Title Case) — short, large, "what to do".
//   • MEANING-LINES — plain de-personified facts that carry the lesson; "friction"
//     and "loss" land ONLY after they have been felt. No mascot, no info-cards.
//
// This is the module's FIRST FULL TEACHING of loss = heat: name-last is the spine
// (heat → friction → loss), and loss is named as a DESTINATION (energy leaves as
// heat), never as an ending ("gone"/"wasted").

/// The phase machine (PRD §14). Gates only ever advance (high-water marks).
enum HeatWirePhase {
  raiseCurrent, // slider live, rub off → discovery gate (current>=0.75 / 600ms)
  wireHot, // 'More Current, Hotter Wire' → 'Now Drop It Low' (timer)
  dropLow, // gate current<=0.15 && wireTemp<=0.25 → cool bridge
  cooled, // a brief silent bridge, then lock the slider to 0 + enter the rub
  rubWire, // rub live, slider locked → rub gate (rubHeat>=0.5 && 3 reversals)
  frictionNamed, // 'Rubbing Makes Heat Too' (capture 'rubbed_warm') → unlock
  raiseAgain, // 'Raise the Current Again'; gate current>=0.75 for 600ms
  lossMoment, // the loss line + 'heat_leaves_wire' capture → Continue
  done, // showContinue; Continue -> card overlay -> maybePop
}

/// A top-text line + which register it's in. [imperative] drives the big bold
/// Bricolage style; meaning-lines render in softer Plus Jakarta Sans. [long]
/// steps the longest meaning-lines (C4/C5) down a touch so they stay on ≤3 lines.
class HWCaption {
  const HWCaption(this.text, {this.imperative = false, this.long = false});
  const HWCaption.imperative(this.text)
      : imperative = true,
        long = false;
  const HWCaption.meaning(this.text)
      : imperative = false,
        long = false;
  const HWCaption.longMeaning(this.text)
      : imperative = false,
        long = true;

  final String text;
  final bool imperative;
  final bool long;
}

/// All §5 copy as consts. Verbatim — do not paraphrase.
class HWCopy {
  HWCopy._();

  // ── Beat A — push the current (feel it heat) ──────────────────────────
  static const HWCaption a1RaiseCurrent = HWCaption.imperative('Raise the Current');
  /// felt discovery (current held high): the cause→effect, in three words.
  static const HWCaption a2HotterWire = HWCaption.meaning('More Current, Hotter Wire');
  static const HWCaption a3DropItLow = HWCaption.imperative('Now Drop It Low');

  // ── Beat B — rub the wire (friction = the same thing) ─────────────────
  static const HWCaption b1RubTheWire = HWCaption.imperative('Now Rub the Wire');
  /// felt discovery (after several strokes): the rub is the same heat-making.
  static const HWCaption b2RubbingHeatToo = HWCaption.meaning('Rubbing Makes Heat Too');

  // ── Beat C — name the loss (the destination, last) ────────────────────
  static const HWCaption c1RaiseAgain = HWCaption.imperative('Raise the Current Again');
  /// the payoff line — holds high + glowing, fires the auto-capture. The whole
  /// lesson in one sentence: heat = wasted energy that never reaches the city.
  static const HWCaption c2WastedEnergy = HWCaption.longMeaning(
      'This Heat Is Wasted Energy — It Leaves the Wire Instead of '
      'Reaching the City.');

  // ── Chrome (static) ──────────────────────────────────────────────────
  static const String headerTitle = 'The Hot Wire';
  static const String headerEyebrow = 'EPISODE 2 · TRANSMISSION';
  static const String tagPlant = 'PLANT';
  static const String tagCity = 'CITY';
  static const String tagSameWire = 'SAME WIRE';
  static const String chipCurrent = 'CURRENT';
  static const String chipHeat = 'HEAT';
  static const String sliderLabel = 'CURRENT';
  static const String ctaContinue = 'Continue';
  static const String cardEyebrow = 'NEW CARD';
  static const String cardBrag =
      'You watched energy leave — and knew exactly where it went.';

  // ── Line holds (ms) ──────────────────────────────────────────────────
  static const int firstCaptionMs = 600; // entrance → A1
  static const int a2HoldMs = 2800; // 'More Current, Hotter Wire' → 'Now Drop It Low'
  static const int coolBridgeMs = 900; // silent beat after the drop → enter the rub
  static const int b2HoldMs = 2800; // 'Rubbing Makes Heat Too' → unlock + enter Beat C
  static const int lossHoldMs = 4200; // the loss line holds → showContinue

  static const int sliderLockEaseMs = 300; // beat B slider animates to 0
}
