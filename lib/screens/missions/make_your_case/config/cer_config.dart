// The "Make Your Case" CER config — everything that makes the closing flow
// EPISODE-SPECIFIC, in one immutable const value (PRD §4, §7.4). The engine
// (controller + 3 screens) reads from here; the catalog, the guiding question,
// the staged groups, the claim template, all kid-facing copy, and the synthesis
// card all live as data. EP1's config (`kEp1CerConfig` below) folds in the former
// cer_copy.dart strings + kEpisode1Evidence + the original two-stage staging, so
// Episode 1 behaves identically. Future episodes add their own CerConfig (a later
// pass owns those); a grand-finale config can span episodes via [sourceEpisodeIds]
// and a 3-slot claim.

import '../../../collectibles/collectible_models.dart';
import '../../episode_board/evidence_models.dart';

/// An immutable, const-constructible description of one episode's CER closing.
/// Nothing here states the answer up front (§2.2) and nothing marks a choice
/// right/wrong (§5.4) — the config only parameterizes the same restrained flow.
class CerConfig {
  const CerConfig({
    required this.episodeId,
    List<String>? sourceEpisodeIds,
    required this.question,
    required this.beatName,
    required this.episodeTitle,
    required this.briefing,
    required this.tiles,
    required this.stages,
    required this.textParts,
    required this.slotOptions,
    required this.slotCaptions,
    required this.slotPlaceholders,
    required this.capstone,
    required this.evidenceTask,
    required this.evidenceHint,
    required this.moreCta,
    required this.backCta,
    required this.toClaimCta,
    required this.claimTask,
    required this.toPlaybackCta,
    required this.incompleteNudge,
    required this.distractorNote,
    required this.addEvidenceCta,
    required this.finishCta,
    required this.finishAnywayCta,
    required this.card,
    required this.earnEyebrow,
    required this.earnBrag,
    this.reasoning,
  }) : _sourceEpisodeIds = sourceEpisodeIds;

  /// The episode the closing flow is scoped to (its persistence/catalog key).
  final String episodeId;

  /// Evidence stores to read captures from — for a single-episode CER this is
  /// just [episodeId]; a grand finale lists several. Nullable backing field +
  /// getter so the constructor stays const while defaulting to `[episodeId]`.
  final List<String>? _sourceEpisodeIds;
  List<String> get sourceEpisodeIds => _sourceEpisodeIds ?? [episodeId];

  /// The guiding question, pinned at the top of every closing screen (§4).
  final String question;

  /// The flow's title (top bar).
  final String beatName;

  // ── Case briefing (the intro screen shown when the episode opens) ──────────
  final String episodeTitle;
  final String briefing; // framing lines before the question (image-rendered EP1)

  /// The authoritative evidence catalog for this CER (the tiles the closing
  /// flow may show). For a single-episode CER this is that episode's set.
  final List<EvidenceTile> tiles;

  /// Ordered groups of tile ids, each ≤6 shown together (§6). Each inner list is
  /// one Screen-1 stage; the kid advances between them with "More clues".
  final List<List<String>> stages;

  /// The claim template, split around its slots. length == slotOptions.length + 1
  /// (the fixed text BEFORE slot 0, BETWEEN each pair, and AFTER the last slot).
  final List<String> textParts;

  /// Per-slot chip options — 2 or 3 slots, 2–3 chips each (all grammatical, none
  /// a trap §5.5). The intended insight is the kid's tap.
  final List<List<String>> slotOptions;

  /// Per-slot caption shown above its chip group.
  final List<String> slotCaptions;

  /// Per-slot placeholder shown in the live sentence before it's filled.
  final List<String> slotPlaceholders;

  /// The closing line the montage builds toward (§4.3).
  final String capstone;

  // ── Screen 1 — Evidence ──────────────────────────────────────────────────
  final String evidenceTask;
  final String evidenceHint;
  final String moreCta;
  final String backCta;
  final String toClaimCta;

  // ── Screen 2 — Claim ─────────────────────────────────────────────────────
  final String claimTask;
  final String toPlaybackCta;

  // ── Screen 3 — Playback ──────────────────────────────────────────────────
  final String incompleteNudge;

  /// Gentle, non-blocking aside when a true-but-irrelevant clue is included.
  final String distractorNote;
  final String addEvidenceCta;
  final String finishCta;
  final String finishAnywayCta;

  // ── Card-earn (the synthesis card) ───────────────────────────────────────
  final CollectibleCard card;
  final String earnEyebrow;
  final String earnBrag;

  /// An optional ACTIVE-reasoning step (Screen 3) tailored to the episode's
  /// argument shape — when set, it REPLACES the passive playback montage. EP1
  /// uses a coverage grid; episodes without one keep the montage. See
  /// [CerReasoning].
  final CerReasoning? reasoning;
}

/// One drop-slot in a coverage-grid reasoning step — a town "need" the kid maps
/// a source's catch onto (the need that source CAN'T meet).
class CerReasonSlot {
  const CerReasonSlot({required this.id, required this.label});
  final String id; // stable key referenced by [CerCoverageReasoning.placement]
  final String label; // the on-screen need label (e.g. "Clean")
}

/// Base for an ACTIVE reasoning step (Screen 3). Two shapes implement it,
/// matched to the episode's argument structure: [CerCoverageReasoning] (a
/// CONVERGENCE — map each clue to the need it fails; EP1) and
/// [CerChainReasoning] (a CHAIN — assemble the clues in causal order; EP2).
/// Both share the framing copy, the verdict reveal, and an optional closer clue.
abstract class CerReasoning {
  const CerReasoning({
    required this.intro,
    required this.task,
    required this.verdict,
    this.closerId,
    this.closerLine,
  });

  /// The framing line at the top of the step.
  final String intro;

  /// The per-action instruction (above the tray / pool).
  final String task;

  /// The reveal shown once the step is solved.
  final String verdict;

  /// An optional clue shown as the closer card after solving (EP1: same_magnet,
  /// the "they all spin the same magnet, so mixing them is easy" enabler).
  final String? closerId;
  final String? closerLine;

  /// The clue ids this step works with (grid items / chain links).
  List<String> get tileIds;
}

/// The COVERAGE GRID (EP1 convergence): the kid drags each catch-clue onto the
/// one town-need that source fails. Order-free by construction (a clue's home is
/// its [placement] target, not a sequence). A wrong drop bounces back.
class CerCoverageReasoning extends CerReasoning {
  const CerCoverageReasoning({
    required super.intro,
    required super.task,
    required super.verdict,
    super.closerId,
    super.closerLine,
    required this.slots,
    required this.placement,
    this.wrongDropNote = "Not that one — try the need this source can't give.",
  });

  /// The need slots (drop targets), in display order.
  final List<CerReasonSlot> slots;

  /// tile id → the slot id that clue belongs in (the need that source fails).
  /// Several tiles MAY share a slot (EP1: wind + solar both fail "always-on").
  final Map<String, String> placement;

  /// The gentle aside when a clue is dropped on the wrong slot.
  final String wrongDropNote;

  @override
  List<String> get tileIds => placement.keys.toList();
}

/// The CAUSAL CHAIN (EP2): the kid assembles the clues in order by tapping the
/// one that comes NEXT; each correct link snaps in with its connective (the
/// "so / but how / put it together" that IS the reasoning). A wrong tap nudges.
class CerChainReasoning extends CerReasoning {
  const CerChainReasoning({
    required super.intro,
    required super.task,
    required super.verdict,
    super.closerId,
    super.closerLine,
    required this.order,
    required this.links,
    this.startHint = '',
    this.wrongNote = "That's not what comes next — what does the last step force?",
  });

  /// The clue ids in the correct causal order.
  final List<String> order;

  /// The connective shown UNDER each placed link as it bridges to the next
  /// (links[i] follows order[i]); the last entry is typically ''. Length == order.
  final List<String> links;

  /// The bulb hint when nothing's placed yet (how the chain starts).
  final String startHint;

  /// The nudge on a wrong "what comes next" tap.
  final String wrongNote;

  @override
  List<String> get tileIds => order;
}

/// Episode 1 — "Where Power Is Born". The shipped EP1 copy + catalog + staging,
/// as data. Stage 0 = the four Act-3 catches; stage 1 = the convergence + the two
/// distractors (matches the original _groupA/_groupB grouping).
const CerConfig kEp1CerConfig = CerConfig(
  episodeId: kEpisode1Id,
  question: kEpisode1Question,
  beatName: 'Make Your Case',
  episodeTitle: 'Where Power Is Born',
  briefing:
      "You're about to investigate how electricity is really made — spin magnets, "
      'boil water, run a whole town on each power source. Snap a photo of every clue '
      "you find. At the end, you'll use them to crack one big question.",
  tiles: kEpisode1Evidence,
  // Two stages of 4 so each screen is a clean 2×2 (no orphaned 5th tile).
  stages: [
    ['fossil_haze', 'nuclear_cost', 'wind_drop', 'solar_night'],
    ['hydro_river', 'same_magnet', 'still_magnet', 'turbine_spin'],
  ],
  // "We use [many] different sources because no single one [is good at everything]."
  textParts: ['We use', 'different sources because no single one', '.'],
  slotOptions: [
    ['many', 'one', 'a few'],
    ['is good at everything', 'is perfect', 'can do it all'],
  ],
  slotCaptions: ['How many sources?', 'No single one…'],
  slotPlaceholders: ['?', '…'],
  capstone: '…so no single source wins on its own — which is why we use many.',
  evidenceTask: 'Which clues answer the question?',
  evidenceHint: 'Tap a clue to open it, then keep the ones that fit.',
  moreCta: 'More clues',
  backCta: 'Back',
  toClaimCta: 'State your answer',
  claimTask: "So — what's your answer?",
  toPlaybackCta: 'See your case',
  incompleteNudge:
      'Your case feels unfinished — a clue that answers the question is missing. Want to add it?',
  distractorNote:
      'One of your clues is really about HOW electricity is made — not why we use many. Still a true thing you found!',
  addEvidenceCta: 'Add a clue',
  finishCta: 'Finish',
  finishAnywayCta: 'Finish anyway',
  card: kGridMixCard,
  earnEyebrow: 'CASE CLOSED',
  earnBrag:
      'You made your case — every source the same trick, each with its own catch. '
      "That's why the grid is a mix.",
  // The active reasoning step (Screen 3): a coverage grid. EP1 is a CONVERGENCE
  // argument (not a chain), so the kid maps each source's catch onto the one
  // town-need it fails — every need is a gap for someone, no single source
  // covers all four, and the verdict lands "mix them to cover everything".
  reasoning: CerCoverageReasoning(
    intro: "A town needs power that's clean, cheap, always-on, and everywhere — "
        'but every source falls short on ONE.',
    task: "Drag each clue to the thing that source ISN'T.",
    // Slots are the GAP (what the source is NOT) so the drop reads naturally —
    // "Nuclear's Big Cost → Not Cheap", not "nuclear is cheap".
    slots: [
      CerReasonSlot(id: 'clean', label: 'Not Clean'),
      CerReasonSlot(id: 'cheap', label: 'Not Cheap'),
      CerReasonSlot(id: 'always_on', label: 'Not Always-On'),
      CerReasonSlot(id: 'anywhere', label: 'Not Everywhere'),
    ],
    placement: {
      'fossil_haze': 'clean', // burning fuel → not clean (dirty air)
      'nuclear_cost': 'cheap', // clean but not cheap (costly)
      'wind_drop': 'always_on', // not always-on (stops when the wind drops)
      'solar_night': 'always_on', // not always-on (dark every night)
      'hydro_river': 'anywhere', // not everywhere (only where a river runs)
    },
    closerId: 'same_magnet',
    closerLine:
        '…and every one of them spins the same magnet — so combining them is easy.',
    wrongDropNote: 'Not that one — what is this source NOT?',
    verdict:
        'No single source is all four — each one misses something different. '
        'Mix them, and the town gets clean, cheap, always-on power everywhere.',
  ),
);
