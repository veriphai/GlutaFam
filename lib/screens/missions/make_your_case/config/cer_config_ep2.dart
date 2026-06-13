// The Episode 2 "Make Your Case" CER config — the closing flow for "The Long Way
// Home" (transmission) as one immutable const, mirroring `kEp1CerConfig`. The
// engine (CerController + the 3 screens) reads everything episode-specific from
// here: the EP2 evidence catalog, the guiding question, the two-stage staging,
// the 2-slot claim template, the playback capstone, every kid-facing string, and
// the episode-synthesis card. Content is verbatim from prd_make_your_case_ep2.md
// (the catalog owner): §5 (on-screen text), §6 (the locked 8-tile catalog), §7
// (staging), §10 (the High Road card). The wrapper (make_your_case_ep2_screen.dart)
// returns `MakeYourCaseScreen(config: kEp2CerConfig)`.
//
// Reconciliation note: the PRD's §11 example listed an extra `distractorNote`
// field, but the SHIPPED `CerConfig` (config/cer_config.dart) has no such field
// (the kept-distractor aside is not a separate engine string). The PRD's §11
// explicitly keys the config "to the SHIPPED CerConfig field names", so that
// field is omitted here. Every other string is verbatim from §5/§11.

import '../../../collectibles/collectible_models.dart';
import '../../episode_board/evidence_models.dart';
import 'cer_config.dart';

/// Episode 2 — "The Long Way Home". The synthesis closer: from the 9 witnessed
/// moments the learner keeps the 6 that carry the chain (heat leaves → leaps with
/// the square → current falls when voltage rises → the transformer lifts it → AC
/// keeps it alive → the power sails across), sets aside the 3 true-but-different
/// clues (2.1's push/flow, 2.2's fat wire, 2.3's friction warmth), assembles the
/// claim, and watches the argument cross the distance — then pockets The High Road.
const CerConfig kEp2CerConfig = CerConfig(
  episodeId: kEpisode2Id,
  sourceEpisodeIds: [kEpisode2Id],
  question: kEpisode2Question,
  beatName: 'Make Your Case',
  episodeTitle: 'The Long Way Home',
  briefing:
      "The power plant is hundreds of kilometres away, and the wire leaks heat the "
      'whole journey. Investigate how the electricity survives the trip — and snap a '
      "photo of every clue. At the end, you'll use them to crack one big question.",
  tiles: kEpisode2Evidence,
  // 9 tiles → three screens of 3 (≤4 per screen, each fits without scroll; 9 is
  // odd, so 3×3 beats 4+4+1's lone-card screen). Roughly beat-ordered, with the
  // 3 distractors spread across the first two screens for relevance judgment.
  stages: [
    ['push_flow', 'fat_wire', 'heat_leaves_wire'], // 2.1/2.2 foundations + the 2.3 problem
    ['rubbed_warm', 'heat_quadruples', 'current_drops_itself'], // 2.3 distractor + loss mechanics
    ['turns_step_up', 'ac_springs_alive', 'ac_sails_across'], // the enablers + the proof
  ],
  // The 2-slot claim (PRD §5): textParts[0] · slot0 · textParts[1] · slot1 ·
  // textParts[2]. Honest assembly: "…the current stays tiny — because the wire's
  // heat grows with the square of the current."
  textParts: [
    'We send the power at enormous voltage so the current stays',
    "— because the wire's heat grows with the",
    'of the current.',
  ],
  slotOptions: [
    ['steady', 'tiny', 'huge'],
    ['speed', 'square', 'direction'],
  ],
  slotCaptions: ['The current stays…', 'Heat grows with the…'],
  slotPlaceholders: ['…', '…'],
  capstone:
      'Enormous voltage, tiny current, almost nothing lost as heat — and the '
      'transformer, running on AC, is what lifts the voltage that high.',
  // ── Screen 1 — Evidence ──────────────────────────────────────────────────
  evidenceTask: 'Which of these clues answer the question?',
  evidenceHint: 'Tap a clue to open it, then keep the ones that fit.',
  moreCta: 'More clues',
  backCta: 'Back',
  toClaimCta: 'State your answer',
  // ── Screen 2 — Claim ─────────────────────────────────────────────────────
  claimTask: "So, what's your answer?",
  toPlaybackCta: 'See your case',
  // ── Screen 3 — Playback ──────────────────────────────────────────────────
  incompleteNudge: "Played back, your case doesn't quite reach the far city yet.",
  distractorNote:
      'One of your clues is a true thing you found — but it answers a different question.',
  addEvidenceCta: 'Add a clue',
  finishCta: 'Finish',
  finishAnywayCta: 'Finish anyway',
  // ── Card-earn — the episode-synthesis card (PRD §10) ─────────────────────
  card: kHighRoadCard,
  earnEyebrow: 'CASE CLOSED',
  earnBrag:
      'You built the case: enormous voltage, tiny current, AC all the way.',
  // The active reasoning step (Screen 3): EP2 is a causal CHAIN, so the kid
  // assembles the argument in order — tap the clue that comes next, each link
  // snapping in with the connective that IS the reasoning (so / but how / put
  // it together). Order = the beat order 2.3→2.8.
  reasoning: CerChainReasoning(
    intro: 'Lay out the argument in order.',
    task: 'Tap the clue that comes next.',
    order: [
      'heat_leaves_wire', // the problem: loss IS heat
      'heat_quadruples', // why it's brutal: heat ∝ current²
      'current_drops_itself', // the trick: raise voltage → current falls
      'turns_step_up', // the enabler: a transformer steps the voltage up
      'ac_springs_alive', // the fuel: only AC keeps the transformer alive
      'ac_sails_across', // the proof: cold line, far city lit
    ],
    links: [
      'So what makes that loss so brutal?',
      'Double the current = four times the heat — so shrink the current.',
      'Raise the voltage and the current falls by itself. But how do you raise it?',
      'A transformer steps it up — but it only works on…',
      'AC. Put it all together…',
      '',
    ],
    startHint:
        'Start with the PROBLEM — the clue that shows power being lost. Then '
        'follow what each step forces next.',
    verdict:
        "There's the chain: the loss is heat, and heat grows with the square of "
        'the current — so we send it at enormous voltage to keep the current '
        'tiny, with the transformer (running on AC) doing the lifting. Almost '
        'nothing lost.',
  ),
);
