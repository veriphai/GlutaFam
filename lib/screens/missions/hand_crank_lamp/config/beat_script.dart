// Beat P.1 — Voltix's complete Prologue dialogue, verbatim from
// voltix_voice_and_prologue_dialogue.md, each line with its avatar mood.
//
// Register: warm but treats the kid as capable; first person, short; reacts and
// points, NEVER explains. The single light "naming" is the synthesis line —
// last, after the pattern is felt. Device-swap reactions point at the surprise
// and stop ("…same crank") — they never name the mechanism.

import '../config/crank_config.dart';
import '../config/output_defs.dart';
import '../engine/bot_beat_engine.dart';

const BeatConfig kHandCrankBeat = BeatConfig(
  // Entry — one-time intro (first session) vs the plain before-line after.
  introLine: VoltixLine(
    "Hey — I'm Voltix. Let's make some electricity. See that crank? Give it a "
    'spin, and keep an eye on the lamp.',
    VoltixMood.wave,
  ),
  beforeLine: VoltixLine(
    'Alright — spin that crank, and watch the lamp.',
    VoltixMood.confident,
  ),

  // Idle nudge — encourage, then hint (point, don't tell).
  onIdle: IdleConfig(
    [
      VoltixLine('Go on — give the crank a turn.', VoltixMood.thumbsUp),
      VoltixLine(
        'Keep it spinning steady — the faster you go, the brighter it gets.',
        VoltixMood.idea,
      ),
    ],
    cooldownMs: 8000,
  ),

  // First light — warm reaction, names nothing (the discovery is the STOP).
  onFirstLit: VoltixLine('Ha — there it is.', VoltixMood.thumbsUp),

  // Discovery — fires AT the cutoff, with the flash. Points, never explains.
  discovery: VoltixLine(
    'Whoa — did you catch that? The second you stopped, it just died.',
    VoltixMood.surprised,
  ),

  // Naming — a beat later. Reflective, not authority. No fuel analogy.
  afterLine: VoltixLine(
    "Nothing was stored in there to keep it going. Stop making it, and it's "
    'gone — just like that.',
    VoltixMood.thinking,
  ),

  // Open invitation to swap — singular, the kid chooses.
  swapInvitation: VoltixLine(
    'Now — try swapping the lamp out for something else. See what the same '
    'crank does.',
    VoltixMood.idea,
  ),

  // Synthesis — the ONE place light naming happens, after the pattern is felt.
  generalisation: VoltixLine(
    'Same energy from your hand every time — each device just turns it into '
    'something different: spin, heat, sound.',
    VoltixMood.confident,
  ),

  // Closing hook into Episode 1.
  outro: VoltixLine(
    'You just powered all that with one hand. A whole city, though? That\'d '
    "take a lot more than your arm. Come on — let's go find out who's cranking "
    'for the city.',
    VoltixMood.thinking,
  ),

  discoveryVisual: VisualEmphasis(id: 'cutoff_ring'),
  idleThresholdMs: CrankConfig.idleThresholdMs,
  discoveryToAfterMs: CrankConfig.discoveryToAfterMs,
);

/// Device-swap reactions (PRD §4.7 / Voltix §3) — keyed by output so the host
/// looks up the line for the just-selected device. React and POINT, never name
/// the mechanism; each ends on a dangling "…same crank" the kid completes.
/// All three are voltix_surprised (genuine surprise, WITH the kid). The lamp
/// has no reaction — it's the baseline they swap away from.
const Map<ActiveOutput, VoltixLine> kDeviceSwapLines = {
  ActiveOutput.fan: VoltixLine(
    "Wait — it's spinning now? Same crank in your hand…",
    VoltixMood.surprised,
  ),
  ActiveOutput.heater: VoltixLine(
    'Whoa, now it\'s heating up. Same crank…',
    VoltixMood.surprised,
  ),
  ActiveOutput.speaker: VoltixLine(
    "Now it's making sound?! Same crank…",
    VoltixMood.surprised,
  ),
};
