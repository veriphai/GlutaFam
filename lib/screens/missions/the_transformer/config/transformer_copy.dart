// The Transformer (EP2 · beat 2.6) — the on-screen text. No mascot, no info-cards.
// TWO de-personified registers (the shipped house pattern):
//   • IMPERATIVES (TxCaption.imperative) — short, large, Title Case, "what to do".
//   • MEANING-LINES (TxCaption.meaning)  — plain de-personified facts that carry
//     the lesson; the depth-stop is the one allowed to run long.
//
// UPDATED caption set (2026-06-12, on-device pass): the intro line is CUT (the
// motivation carried over from 2.5); the three watch-core/induction monologues are
// COLLAPSED into one directive + one induction line (the slow-mo animation teaches
// it); the depth-stop is corrected (no "you'll learn it later"); the cliffhanger is
// one posed line. Do not paraphrase — these are the approved strings.

/// A top-text line + register flag (drives the style: big bold imperative vs the
/// softer meaning-line; [long] keeps the longer lines at body size).
class TxCaption {
  const TxCaption(this.text, {this.meaning = false, this.long = false});
  const TxCaption.imperative(this.text)
      : meaning = false,
        long = false;
  const TxCaption.meaning(this.text)
      : meaning = true,
        long = false;
  const TxCaption.longMeaning(this.text)
      : meaning = true,
        long = true;
  final String text;
  final bool meaning;
  final bool long;
}

class TxCopy {
  TxCopy._();

  // ── windUp — wind the secondary coil; OUT steps up ───────────────────
  static const TxCaption windCoil = TxCaption.imperative('Wind the Coil');
  static const TxCaption moreTurns = TxCaption.meaning('More Turns — Higher Voltage');
  static const TxCaption twiceVoltage = TxCaption.meaning('Twice the Turns, Twice the Voltage');

  // ── windDown — unwind; OUT steps down; same device steps voltage down ─
  static const TxCaption unwindCoil = TxCaption.imperative('Now Unwind It');
  static const TxCaption fewerTurns = TxCaption.meaning('Fewer Turns — Lower Voltage');
  static const TxCaption stepsDown = TxCaption.meaning('The Same Device Steps Voltage Down');

  // ── watchCore → the induction beat (one sequence; the slow-mo carries it)
  static const TxCaption watchCore = TxCaption.imperative('Watch the Core — Nothing Moves');
  static const TxCaption induction = TxCaption.longMeaning(
    'A changing magnetic field makes the voltage — induction, the magnet trick again.',
  );

  // ── depthStop (corrected — no "you'll learn it later") ───────────────
  static const TxCaption depthStop = TxCaption.longMeaning(
    'Electricity and magnetism are secretly the same thing — one of the deepest ideas in physics.',
  );

  // ── synthesis — the rule named, the device returns to its grid job ───
  static const TxCaption synthesis = TxCaption.longMeaning(
    'A transformer steps voltage up or down — with no moving parts.',
  );

  // ── cliffhanger — posed, never answered here (2.7 owns the answer).
  //    One line; persists behind the card + Continue. ──────────────────
  static const TxCaption cliffhanger = TxCaption.longMeaning(
    'It all runs on a changing field. So what if the current were steady?',
  );

  // ── Card earn brag (overlay one-liner) ───────────────────────────────
  static const String cardBrag = 'The still machine that lifts voltage for the journey.';
}
