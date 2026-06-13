// The Transmission Trick (Episode 2 · beat 2.5) — the on-screen text. No Voltix,
// no mascot, no info-cards. ONE voice: the text itself, in two de-personified
// registers:
//   • IMPERATIVES (≤5 words, Title Case, big bold) — "what to do".
//   • MEANING-LINES (plain, longer allowed) — the lesson, stated as fact, named a
//     beat AFTER it is felt.
// Every line is verbatim from PRD §5 (the catalog of record for this beat). The
// pin-flip line L2 is named on sight (an arrangement, like an object); the trick
// itself (L8) is named LAST, after the full win is felt.

/// A top-text line + which register it's in (drives the style: big bold imperative
/// vs softer meaning-line). [long] keeps a long meaning-line at the smaller size so
/// it fits (L2/L5/L8 render ~16.5, matching trace_it_back's longMeaning rule).
class TTCaption {
  const TTCaption(this.text, {this.meaning = false, this.long = false});
  const TTCaption.imperative(this.text)
      : meaning = false,
        long = false;
  const TTCaption.meaning(this.text)
      : meaning = true,
        long = false;
  const TTCaption.longMeaning(this.text)
      : meaning = true,
        long = true;
  final String text;
  final bool meaning;
  final bool long;
}

/// The beat ids in order. Each maps to one [TTCaption] in [TTCopy.of]; the
/// controller advances these on a silent timer chain. Trimmed to the short shipped
/// set: I1 (slider live) → currentFalls/voltageUpCurrentDown (after discovery) → I2
/// → lessHeatLost (town brightens) → I3 → theTrick → realLines (outward landing).
enum TTCaptionId {
  none,
  i1Raise, // slider goes live
  currentFalls, // after discovery (V ≥ 20)
  voltageUpCurrentDown, // as the numbers move
  i2LightTown, // town gate
  lessHeatLost, // town brightens
  i3SendTop, // final gate
  theTrick, // named last
  realLines, // outward landing
}

class TTCopy {
  TTCopy._();

  /// The verbatim line for each beat id.
  static TTCaption of(TTCaptionId id) {
    switch (id) {
      case TTCaptionId.none:
        return const TTCaption('');
      case TTCaptionId.i1Raise:
        return const TTCaption.imperative('Raise the Voltage');
      // After discovery (V ≥ 20) — the inversion, felt then named.
      case TTCaptionId.currentFalls:
        return const TTCaption.meaning('The Current Falls on Its Own');
      // As the numbers move — the trade, named plainly.
      case TTCaptionId.voltageUpCurrentDown:
        return const TTCaption.meaning('Voltage Up, Current Down');
      case TTCaptionId.i2LightTown:
        return const TTCaption.imperative('Light the Whole Town');
      // The town brightens — the I² payoff, named.
      case TTCaptionId.lessHeatLost:
        return const TTCaption.meaning('Less Current, Less Heat Lost');
      case TTCaptionId.i3SendTop:
        return const TTCaption.imperative('Send It to the Top');
      // The trick — named LAST, after the full win is felt.
      case TTCaptionId.theTrick:
        return const TTCaption.meaning('The Transmission Trick');
      // The outward landing.
      case TTCaptionId.realLines:
        return const TTCaption.meaning(
          'Real lines run at hundreds of thousands of volts.',
        );
    }
  }

  /// The card-earn brag line (PRD §5/§8).
  static const String cardBrag = 'You starved the wire and lit the town.';

  // ── Readout labels (mono, IBM Plex Mono) ─────────────────────────────
  static const String powerLabel = 'POWER';
  static const String powerPinnedTag = 'PINNED · V × I'; // the constant product, named
  static const String voltageLabel = 'VOLTAGE';
  static const String currentLabel = 'CURRENT';

  // ── Beat timings (ms) ────────────────────────────────────────────────
  // Intro (auto): entrance → I1 (no preamble lines).
  static const int introToI1Ms = 1400; // entrance → I1 (raise the voltage)

  // Post-discovery chain: latch → currentFalls → voltageUpCurrentDown → I2.
  static const int discoveryToCurrentFallsMs = 600; // latch → "The Current Falls on Its Own"
  static const int currentFallsHoldMs = 2600; // → "Voltage Up, Current Down"
  static const int voltageUpDownHoldMs = 3000; // → I2 (light the whole town)

  // lightTown chain: town latch → lessHeatLost → I3.
  static const int townLitToLessHeatMs = 500; // town sweep latch → "Less Current, Less Heat Lost"
  static const int lessHeatHoldMs = 3000; // → I3 (send it to the top)

  // closing chain: top latch → theTrick → realLines → card.
  static const int toppedToTrickMs = 400; // top latch → "The Transmission Trick"
  static const int trickHoldMs = 2600; // → "Real lines run at hundreds of thousands of volts."
  static const int realLinesToCardMs = 3000 + 400; // realLines hold → card earn (+400 settle)
}
