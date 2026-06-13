// War of the Currents (EP2 · beat 2.8) — the on-screen text. ONE voice: the
// caption itself (no mascot, no narrator, no info-cards). Two de-personified
// registers, exactly as the shipped activities:
//   • IMPERATIVES (≤5 words, Title Case) — "Choose a Current" / "Now Send the
//     Other"; rendered big & bold.
//   • MEANING-LINES — de-personified facts (name the noun; a catch names the
//     consequence/destination, never a behaviour/ending; no rhyme).
//
// Every line below is VERBATIM from the PRD §5 copy table. Do not paraphrase.
// The WocCaption enum is the discrete UI channel; `cap()` resolves each enum to
// its line + register flags (drives style: imperative vs meaning, long-line shrink).

/// One top-text line + its register flags (mirrors TBCaption from trace_it_back).
class WocCaption {
  const WocCaption(this.text, {this.meaning = false, this.long = false});
  const WocCaption.imperative(this.text)
      : meaning = false,
        long = false;
  const WocCaption.meaning(this.text)
      : meaning = true,
        long = false;
  // A meaning-line intentionally LONG (kept at the smaller size so it fits).
  const WocCaption.longMeaning(this.text)
      : meaning = true,
        long = true;
  final String text;
  final bool meaning;
  final bool long;
}

/// Which line is showing (the controller's caption channel). `none` = no text.
enum WocLine {
  none,
  i1Choose, // imperative — "Choose a Current"
  // — DC run (order-independent): sent → result —
  dSent, // "DC — No Transformer, Low Voltage"
  dResult, // "The Line Cooks — It Dies Before Arriving"
  // — AC run (order-independent): sent → result —
  aSent, // "AC — Transformer Alive, Voltage Up"
  aResult, // "The Line Stays Cold — It Sails Across"
  i2Other, // imperative (interlude) — "Now Try the Other"
  verdict, // after BOTH — the closer, persists
}

/// The copy table — verbatim PRD §5. `WocCaption.none` for the empty line.
class WocCopy {
  WocCopy._();

  static WocCaption cap(WocLine line) {
    switch (line) {
      case WocLine.none:
        return const WocCaption('');

      case WocLine.i1Choose:
        return const WocCaption.imperative('Choose a Current');

      // ── DC run (sent → result on the map) ───────────────────────────────
      case WocLine.dSent:
        return const WocCaption.meaning('DC — No Transformer, Low Voltage');
      case WocLine.dResult:
        return const WocCaption.meaning('The Line Cooks — It Dies Before Arriving');

      // ── AC run (sent → result on the map) ───────────────────────────────
      case WocLine.aSent:
        return const WocCaption.meaning('AC — Transformer Alive, Voltage Up');
      case WocLine.aResult:
        return const WocCaption.meaning('The Line Stays Cold — It Sails Across');

      // ── interlude ───────────────────────────────────────────────────────
      case WocLine.i2Other:
        return const WocCaption.imperative('Now Try the Other');

      // ── verdict (after BOTH runs; the closer, persists) ─────────────────
      case WocLine.verdict:
        return const WocCaption.longMeaning(
          'Only AC Could Be Stepped Up — So the Grid Is AC',
        );
    }
  }

  // ── Chrome strings ────────────────────────────────────────────────────
  static const String dcGlyphLabel = 'DC';
  static const String dcSubLabel = 'STEADY';
  static const String acGlyphLabel = 'AC';
  static const String acSubLabel = 'REVERSING';
  static const String ctaLabel = 'Continue';
  // (The persistent era tag + the modern-time fact were removed — the timeline is
  // no longer standing chrome; the war reveal carries the story.)
}
