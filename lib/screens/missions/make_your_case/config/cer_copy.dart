// All kid-facing copy for the "Make Your Case" closing flow (PRD §4, §7.4). Kept
// in one place so the tone stays consistent and tunable. The soul (PRD §1): "build
// a case out of things you witnessed" — never a quiz. No copy here states the
// answer up front (§2.2) and nothing marks a choice right/wrong (§5.4).

import '../../episode_board/evidence_models.dart';

class CerCopy {
  CerCopy._();

  static const String beatName = 'Make Your Case';
  static const String question = kEpisode1Question;

  // ── Screen 1 — Evidence ────────────────────────────────────────────────────
  static const String evidenceTask = 'Which clues answer the question?';
  static const String evidenceHint = 'Tap a clue to open it, then keep the ones that fit.';
  static const String moreCta = 'More clues';
  static const String backCta = 'Back';
  static const String toClaimCta = 'State your answer';

  // ── Screen 2 — Claim (2-slot template; the kid AUTHORS it, §4.2) ────────────
  static const String claimTask = "So — what's your answer?";
  static const String claimPrefix = 'We use';
  static const String claimMid = 'different sources because no single one';
  static const String claimSuffix = '.';
  // 2–3 chips per slot — all grammatical, none a trap (§5.5). The intended insight
  // is the kid's tap (the two ideas of the claim: MANY, and no-single-one-complete).
  static const List<String> slot1Options = ['many', 'one', 'a few'];
  static const List<String> slot2Options = [
    'is good at everything',
    'is perfect',
    'can do it all',
  ];
  static const String slot1Placeholder = '?';
  static const String slot2Placeholder = '…';
  static const String toPlaybackCta = 'See your case';

  // ── Screen 3 — Reasoning / playback (the case PLAYED BACK, not a score §5.4) ─
  static const String playbackTitle = "Here's your case.";
  static const String capstone =
      '…so no single source wins on its own — which is why we use many.';
  static const String incompleteNudge =
      'Your case feels unfinished — a clue might be missing. Want to add more?';
  static const String addEvidenceCta = 'Add a clue';
  static const String finishCta = 'Finish';
  static const String finishAnywayCta = 'Finish anyway';

  // ── Card-earn brag (the synthesis card) ────────────────────────────────────
  static const String earnEyebrow = 'CASE CLOSED';
  static const String earnBrag =
      'You made your case — every source the same trick, each with its own catch. '
      "That's why the grid is a mix.";
}
