// Squared Loss (beat 2.4) — the on-screen text, verbatim from PRD §5. No mascot,
// no narrator. TWO de-personified registers:
//   • IMPERATIVES (SLCaption.imperative) — short, large, Title Case, ≤5 words.
//   • MEANING-LINES (SLCaption.meaning)  — de-personified facts that carry the
//     lesson (name the noun; name the consequence/destination — heat).
// A few meaning-lines are intentionally long (the volts/why lines); they render at
// a smaller size so they fit. Imperatives may carry an optional mono SECONDARY hint.

/// Which top-text line is showing, in beat order. The activity ends on ONE naming
/// line + the card — the old LOST VOLTS → "lost-volts × current" → I²R algebra proof
/// was cut (the felt ×2→4× / ×3→9× disproportion already teaches it; the law lives
/// on the card). "Raise" (not "push") throughout — current is an amount, not the push.
enum SLCaption {
  intro, // enter — "One wire. Only the current changes."
  raiseToTwo, // firstPush — "Raise the Current" / TO ×2
  fourTimes, // ×2 lands (DISCOVERY) — "Double the Current — Four Times the Heat"
  raiseToThree, // secondPush — "Raise It Again" / TO ×3
  nineTimes, // ×3 lands — "Triple the Current — Nine Times the Heat"
  sweep, // sweep — "Sweep the Current" / END TO END
  curveBends, // sweep complete — "The Curve Bends Up — Steeper Every Step"
  named, // name it — "Loss Grows with the Current Squared"
  handoff, // closing (after the card) — the 2.5 hand-off question
}

/// A top-text line + its register (drives the style) + an optional mono secondary.
class SLLine {
  const SLLine(
    this.text, {
    this.meaning = false,
    this.long = false,
    this.secondary = '',
  });
  const SLLine.imperative(this.text, {this.secondary = ''})
      : meaning = false,
        long = false;
  const SLLine.meaning(this.text)
      : meaning = true,
        long = false,
        secondary = '';
  const SLLine.longMeaning(this.text)
      : meaning = true,
        long = true,
        secondary = '';

  /// The big line itself.
  final String text;

  /// Meaning-line (Plus Jakarta Sans) vs imperative (Bricolage Grotesque).
  final bool meaning;

  /// A meaning-line intentionally allowed to run long (rendered smaller to fit).
  final bool long;

  /// The small mono hint shown under an imperative ('' = none).
  final String secondary;
}

/// The copy table, keyed by [SLCaption]. Every string is verbatim from PRD §5.
class SLCopy {
  SLCopy._();

  static const Map<SLCaption, SLLine> lines = {
    SLCaption.intro: SLLine.meaning('One wire. Only the current changes.'),
    SLCaption.raiseToTwo: SLLine.imperative('Raise the Current', secondary: 'TO ×2'),
    SLCaption.fourTimes: SLLine.meaning('Double the Current — Four Times the Heat'),
    SLCaption.raiseToThree: SLLine.imperative('Raise It Again', secondary: 'TO ×3'),
    SLCaption.nineTimes: SLLine.meaning('Triple the Current — Nine Times the Heat'),
    SLCaption.sweep: SLLine.imperative('Sweep the Current', secondary: 'END TO END'),
    SLCaption.curveBends: SLLine.meaning('The Curve Bends Up — Steeper Every Step'),
    SLCaption.named: SLLine.meaning('Loss Grows with the Current Squared'),
    SLCaption.handoff: SLLine.longMeaning(
      'The town still needs full power — and current is punished. So how do you '
      'send big power with a tiny current?',
    ),
  };

  static SLLine of(SLCaption c) => lines[c]!;

  // — Static scene label, chip labels, CTA, card brag (PRD §5 / §8) —
  static const String wireTag = 'SAME WIRE · FIXED RESISTANCE';
  static const String chipCurrent = 'CURRENT';
  static const String chipHeat = 'HEAT';
  static const String chipVolts = 'LOST VOLTS';
  static const String cta = 'Continue';

  // — The graph modal (axes labels) —
  static const String graphTitle = 'HEAT  vs  CURRENT';
  static const String graphXAxis = 'CURRENT';
  static const String graphYAxis = 'HEAT';

  /// One short reward line for the card-earn overlay (PRD §8).
  static const String cardBrag =
      'Double the current, quadruple the waste — you felt the square.';
}
