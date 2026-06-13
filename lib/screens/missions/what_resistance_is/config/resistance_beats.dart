// The phase machine enum + every on-screen string (PRD §5, verbatim). One voice:
// the captions themselves. Imperatives (Bricolage, instruct only, ≤5 words, Title
// Case) and meaning-lines (Plus Jakarta Sans, de-personified fact) carry style
// flags so the caption widget renders each register correctly.
//
// PRE-NAMING GUARD (acceptance §5): the string "resistance" appears nowhere in
// this file before [RCaption.m5]. The on-screen title is "Shape the Wire"; the
// registry id `what_resistance_is` is internal and never shown.

/// The silent step machine. Forward-only (gates ratchet, never rewind a phase).
enum RPhase {
  intro,
  pinMove,
  stretch,
  thinFound,
  squash,
  fatFound,
  sweep,
  naming,
  landing,
  synthesis,
  done,
}

/// The one register dimension a caption carries: an imperative (action) vs a
/// meaning-line (the lesson). Echoes (e1/e2) are a third, smaller secondary line.
class RCaption {
  const RCaption(this.text, {this.imperative = false, this.echo = false, this.long = false});

  final String text;
  final bool imperative; // Bricolage big bold, Title Case, instruct only
  final bool echo; // small mono secondary line (e1/e2)
  final bool long; // a longer meaning-line → render a touch smaller so it fits

  bool get meaning => !imperative && !echo;

  static const RCaption none = RCaption('');
}

/// ALL the §5 copy, verbatim. Nothing on screen is authored anywhere else.
class RCopy {
  RCopy._();

  // Header
  static const String title = 'Shape the Wire';
  static const String eyebrow = 'EPISODE 2 · THE LONG WAY HOME';

  // Meaning-lines (m2–m8) and imperatives (i1–i3), echoes (e1/e2), guard (d1).
  // (B0/m1 removed — voltage is pinned from the start; the activity opens on i1.)
  static const RCaption i1 = RCaption('Stretch the Wire', imperative: true);
  static const RCaption e1 = RCaption('Longer — Thinner', echo: true);
  static const RCaption m2 = RCaption('The Thin Wire Chokes the Current');

  static const RCaption i2 = RCaption('Now Squash It Fat', imperative: true);
  static const RCaption e2 = RCaption('Shorter — Fatter', echo: true);
  static const RCaption m3 = RCaption('The Fat Wire Lets It Run');

  static const RCaption i3 = RCaption('Sweep It Thin and Fat', imperative: true);
  static const RCaption m4 = RCaption('The Wire’s Shape Sets the Current');

  static const RCaption m5 = RCaption('This Opposition Is Called Resistance');
  static const RCaption m8 = RCaption(
    'Why Power Cables Are Arm-Thick: Fat Wire, Low Resistance',
    long: true,
  );

  // Guard flash when the learner taps/drags the pinned dial (max twice/session).
  static const RCaption d1 = RCaption('Voltage Stays Pinned', imperative: true);

  // In-scene labels (mono).
  static const String resistanceSpecimenLabel = 'RESISTANCE'; // fades in at m5
  static const String cableLabel = 'REAL TRANSMISSION CABLE';
  static const String voltageChip = 'VOLTAGE'; // value 100, pin glyph, frozen
  static const String currentChip = 'CURRENT';

  // Card earn (overlay).
  static const String cardEyebrow = 'NEW CARD';
  static const String cardBrag = 'Thin chokes it, fat frees it — the wire sets the current.';

  static const String cta = 'Continue';
}
