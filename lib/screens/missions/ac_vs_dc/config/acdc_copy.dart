// AC vs DC (EP2 · beat 2.7) — the on-screen text. No mascot, no info-cards.
// TWO de-personified registers (the shipped house pattern, copied from
// the_transformer/trace_it_back):
//   • IMPERATIVES (AcdcCaption.imperative) — short, large, Title Case, "what to do".
//   • MEANING-LINES (AcdcCaption.meaning)  — plain de-personified facts that carry
//     the lesson; the [long] flag keeps a longer meaning-line at body size.
//   • FEEDBACK (AcdcCaption.feedback) — a transient meaning-line shown during the
//     fast-flip burst; styled like a meaning-line.
// Every line below is the PRD §5 verbatim text — do not paraphrase. The strings
// "DC", "AC", "direct", "alternating", "hertz", "Hz", "50" appear ONLY from the
// alive/naming phases on (criterion 5: name-last).

/// A top-text line + register flag (drives the style: big bold imperative vs the
/// softer meaning-line; [long] keeps the longer meaning-line at body size).
class AcdcCaption {
  const AcdcCaption(this.text, {this.meaning = false, this.long = false});
  const AcdcCaption.imperative(this.text)
      : meaning = false,
        long = false;
  const AcdcCaption.meaning(this.text)
      : meaning = true,
        long = false;
  const AcdcCaption.longMeaning(this.text)
      : meaning = true,
        long = true;
  final String text;
  final bool meaning;
  final bool long;

  bool sameAs(AcdcCaption other) =>
      text == other.text && meaning == other.meaning && long == other.long;
}

class AcdcCopy {
  AcdcCopy._();

  /// A silent beat (blank top-text) — used for the entrance reveal + the dead/alive
  /// witnessed-absence holds.
  static const AcdcCaption introWaits = AcdcCaption('');

  // ── connect → dead ────────────────────────────────────────────────────
  static const AcdcCaption connect = AcdcCaption.imperative('Turn Power On');
  static const AcdcCaption steadyDead =
      AcdcCaption.meaning('Steady Current — Transformer Dead');

  // ── flip once → fast ──────────────────────────────────────────────────
  static const AcdcCaption flip = AcdcCaption.imperative('Flip the Battery');
  static const AcdcCaption flipWakes = AcdcCaption.meaning('A Flip Wakes It');
  static const AcdcCaption flipFast = AcdcCaption.imperative('Flip It Fast');
  static const AcdcCaption onlyChanging =
      AcdcCaption.meaning('Only a Changing Current Works');

  // ── hand → machine → alive ────────────────────────────────────────────
  static const AcdcCaption reversesItself =
      AcdcCaption.meaning('Current Reverses Itself');
  static const AcdcCaption fullyAlive =
      AcdcCaption.meaning('Never Stops — Fully Alive');
  static const AcdcCaption fiftyCycles =
      AcdcCaption.longMeaning('Fifty reversals a second — 50 hertz.');

  // ── name → rule ───────────────────────────────────────────────────────
  static const AcdcCaption naming =
      AcdcCaption.meaning('Steady is DC. Reversing is AC.');
  static const AcdcCaption synthesis =
      AcdcCaption.meaning('A transformer works only on AC.');
  // (the bridge "which current can cross…" line was cut — synthesis is the takeaway,
  //  and it persists through the card + behind Continue.)

  // ── Card earn brag (overlay one-liner, PRD §5/§8) ─────────────────────
  static const String cardBrag =
      'The restless current that wakes the transformer.';

  // ── The graph's labels (the only numbers-ish elements) ────────────────
  static const String graphEyebrow = 'CURRENT';
  static const String graphHzLabel = '50 CYCLES / SEC'; // alive only
}
