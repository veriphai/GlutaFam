// Helix's complete Prologue dialogue (PRD §7), verbatim, each line with its
// mood. Register: first person, warm, SHORT, not childish. Reacts and points;
// never explains. The words "DNA" and "genome" appear NOWHERE until Beat 0.2
// (acceptance criterion 2) — the intro/0.1 lines say "instructions"/"recipe".
//
// Beats map to the engine's BeatConfig sockets. Per-artifact 0.3 reactions live
// separately (the host emits them ad-hoc as each artifact is tapped).

import '../engine/helix_beat_engine.dart';

class PrologueBeats {
  PrologueBeats._();

  // ── Intro (first session only, one breath into action) ───────────────────
  static const HelixLine intro = HelixLine(
    "I'm Helix — I keep the recipes for living things. That creature? Every bit "
    "of it comes from a set of instructions. Go on — change one.",
    Mood.curious,
  );

  // ── Beat 0.1 — the creature is the readout of its instructions (A1, A3) ──
  // The intro doubles as the before-line, so explore enters with emitBefore:false.
  static const BeatConfig explore = BeatConfig(
    id: 'explore',
    onDiscovery: HelixLine(
      "Whoa — you moved the instruction, and it moved. Try another.",
      Mood.surprised,
    ),
    after: HelixLine(
      "So the whole creature is just… its instructions, read out loud.",
      Mood.curious,
    ),
    onIdle: IdleConfig(
      [
        HelixLine("Pick any one. See where it goes.", Mood.curious),
        HelixLine("Grab a slider at the bottom — give it a push.", Mood.curious),
      ],
      cooldownMs: 8000,
    ),
    // onCounterproductive: null — socket wired, no line in the Prologue.
  );

  // ── Beat 0.2 — the instructions have a name and a code (A2) ───────────────
  static const BeatConfig reveal = BeatConfig(
    id: 'reveal',
    before: HelixLine(
      "Want to see what one instruction actually is?",
      Mood.idea, // the ONE place 'idea' is allowed — Helix's own suggestion
    ),
    after: HelixLine(
      "Those four letters, over and over — that's DNA. The whole set has a name "
      "too: the genome.",
      Mood.curious,
    ),
  );

  /// Inline fact (Layer 1, the one slot) — beside the creature in 0.2. Glanceable,
  /// skippable, never a gate. If it ever feels like filler, leave the slot empty.
  static const String inlineFact =
      "Every cell in your body carries your entire genome — about 2 metres of DNA, "
      "coiled up small enough to vanish from sight.";

  // ── Beat 0.3 — it's gone, bring it back (A1 payoff + A4 + card) ───────────
  static const BeatConfig bringBack = BeatConfig(
    id: 'bringBack',
    before: HelixLine(
      "…and it's gone. Extinct. Bring it back — what do you reach for?",
      Mood.curious,
    ),
    onDiscovery: HelixLine(
      "There. That's what it took.",
      Mood.surprised, // at the genome rebuild
    ),
    after: HelixLine(
      "Not the bones, not the picture — the recipe. That's the one thing you "
      "can't do without.",
      Mood.celebrating, // earned — fires the card
    ),
    firesCollectible: true,
  );

  // Per-artifact reactions (0.3) — optional discoveries, point/never explain.
  static const HelixLine onSkeleton =
      HelixLine("Its shape's all there. But… nothing's happening.", Mood.surprised);
  static const HelixLine onPhoto =
      HelixLine("We can see exactly what it looked like. Still nothing.", Mood.surprised);
  static const HelixLine onTorn = HelixLine(
    "Half the recipe… half a creature. Hold onto that.",
    Mood.confused, // shared puzzlement, seeds Ep1
  );

  /// The brag Helix says inside the card-earn overlay (his 0.3 after-line).
  static const String cardBrag =
      "Not the bones, not the picture — the recipe. That's the one thing you can't "
      "do without.";

  // ── Timing knobs (ms) ────────────────────────────────────────────────────
  static const int discoveryToAfterMs = 1500; // 0.1 discovery → afterLine (let them try another)
  static const int peekToAfterMs = 1100; // 0.2 peek → names DNA/genome
  static const int artifactReactMs = 220; // tap an inert artifact → its reaction
  static const int rebuildToAfterMs = 1600; // 0.3 genome rebuild → celebrating + card
}
