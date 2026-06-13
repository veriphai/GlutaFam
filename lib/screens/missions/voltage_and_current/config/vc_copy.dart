// Voltage and Current — the on-screen text (PRD §5). No mascot, no Voltix.
// ONE voice in two registers:
//   • IMPERATIVES (VCCaption.imperative) — short (≤5 words), large, "what to do".
//   • MEANING-LINES (VCCaption.meaning)  — the lesson, de-personified, stated as
//     fact; the two analogy/while lines are the ones allowed to run LONG.
//
// Every line below is VERBATIM from the PRD §5 table (T1–T9). Nothing else is
// said in the activity. The card brag/eyebrow live here too, plus every timing
// constant (ms) the step machine schedules against.

/// A top-text line + which register it's in (drives the style: big bold
/// imperative vs softer meaning-line; the long meaning-lines stay compact).
class VCCaption {
  const VCCaption(this.text, {this.meaning = false, this.long = false});
  const VCCaption.imperative(this.text)
      : meaning = false,
        long = false;
  const VCCaption.meaning(this.text)
      : meaning = true,
        long = false;
  // A meaning-line that's intentionally LONG (kept smaller so it fits).
  const VCCaption.longMeaning(this.text)
      : meaning = true,
        long = true;
  final String text;
  final bool meaning;
  final bool long;
}

class VCCopy {
  VCCopy._();

  // ── The FOUR on-screen lines ─────────────────────────────────────────
  /// 1. Prompt on entry.
  static const VCCaption t1RaiseVoltage = VCCaption.imperative('Raise the Voltage');
  /// 2. The lesson label — fired by the INTERACTION (once they've raised the
  ///    voltage and watched the current follow), never a timer.
  static const VCCaption pushFlow =
      VCCaption.meaning('Voltage is the push. Current is the flow.');
  /// 3. Prompt after they've explored up.
  static const VCCaption t3DropToZero = VCCaption.imperative('Drop Voltage to Zero');
  /// 4. The label on the felt cutoff — the instant it dies.
  static const VCCaption t4NoVoltage = VCCaption.meaning('No Voltage, No Current');

  // ── In-scene labels (painted in the stage so captures include them) ──
  static const String voltageLabel = 'VOLTAGE';
  static const String currentLabel = 'CURRENT';

  // ── Card earn (PRD §5 / §8) ──────────────────────────────────────────
  static const String cardBrag = 'The Push and the Flow — two quantities, two jobs.';
  static const String cardEyebrow = 'NEW CARD';

  // ── Chrome ───────────────────────────────────────────────────────────
  static const String title = 'The Push and the Flow';
  static const String eyebrow = 'EPISODE 2 · TRANSMISSION';

  // ── Timings (ms) ─────────────────────────────────────────────────────
  static const int introToT1Ms = 900; // entrance reveals → "Raise the Voltage"
  static const int cutoffToCardMs = 2600; // "No Voltage, No Current" holds → card earn
}
