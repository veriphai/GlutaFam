// The "Make Your Case" controller — owns the 3-screen closing flow's state
// (PRD §4): which screen, the staged evidence selection, the kept set, the
// N-slot claim, and whether the assembled case feels complete. A single
// ChangeNotifier (no Provider/Riverpod) — the shell rebuilds via ListenableBuilder.
//
// Episode-agnostic: everything specific (catalog, staging, claim template, copy)
// comes from the injected [CerConfig]. Loads the captured evidence from the
// config's source store(s) (PRD §8). If nothing was captured (standalone/dev
// entry), it seeds the FULL catalog so the flow is always playable. NOTE: the
// close is now GATED (a product override of the old §5.4 "never blocks"): Finish
// unlocks ONLY once every answering clue is kept AND no distractor is — see
// [caseSolved]. An on-demand hint bulb ([hintText]) points at what's still missing
// and which kept clue is the distractor to set aside.

import 'package:flutter/foundation.dart';

import '../../episode_board/evidence_models.dart';
import '../../episode_board/evidence_store.dart';
import '../config/cer_config.dart';

enum CerScreen { evidence, claim, playback }

class CerController extends ChangeNotifier {
  CerController({required this.config})
      : slotValues = List<String?>.filled(config.slotOptions.length, null);

  final CerConfig config;

  /// The evidence the kid actually captured (or the full set as a fallback).
  List<EvidenceTile> available = const [];

  /// id → captured scene frame (the real moment the kid saw, PRD §8).
  Map<String, Uint8List> imageBytes = const {};

  bool loaded = false;

  CerScreen screen = CerScreen.evidence;

  /// Screen 1 staging (§4 / §6 — keep ≤6 visible): index into [config.stages].
  int evidenceStage = 0;

  /// The kid's kept evidence (selection — the act of discriminating relevant from
  /// irrelevant IS the reasoning, §4.1).
  final Set<String> kept = {};

  /// The N-slot claim (built, not chosen — §4.2). Sized to the config's template;
  /// null = unfilled. Generalizes the former slot1/slot2 pair.
  final List<String?> slotValues;

  bool showCardEarn = false;
  bool finished = false; // card collected → ready to pop

  /// Screen 1: the tile currently opened in the tap-to-inspect preview (null =
  /// none). Tapping a clue OPENS it (see the captured frame full-size); the
  /// preview is where the kid then keeps/leaves it.
  String? previewId;

  /// Recovery aids for the GATED close. (Product override of the old §5.4
  /// "never blocks": the kid must keep every answering clue AND set aside every
  /// distractor before Finish unlocks.) [attemptedFinish] flips once they bounce
  /// off the playback gate, so the hint bulb only appears after a first unaided
  /// pass; [hintRevealed] toggles that bulb open.
  bool attemptedFinish = false;
  bool hintRevealed = false;

  EvidenceTile? _tile(String id) {
    for (final t in config.tiles) {
      if (t.id == id) return t;
    }
    return null;
  }

  // ── Load ───────────────────────────────────────────────────────────────────
  Future<void> load() async {
    // Defensive: whatever happens, finish loading so the screen never hangs on its
    // spinner (the closing flow must always open after the activities).
    try {
      // Captured ids across every source store, in catalog order (so partial
      // captures still play back in the same order they'd appear).
      final captured = <String>{};
      for (final epId in config.sourceEpisodeIds) {
        captured.addAll(await EvidenceStore.captured(epId));
      }
      final caught = config.tiles.where((t) => captured.contains(t.id)).toList();
      available = caught.isNotEmpty ? caught : List.of(config.tiles);
      final imgs = <String, Uint8List>{};
      for (final t in available) {
        for (final epId in config.sourceEpisodeIds) {
          final b = EvidenceStore.imageBytes(epId, t.id);
          if (b != null) {
            imgs[t.id] = b;
            break;
          }
        }
      }
      imageBytes = Map.unmodifiable(imgs);
    } catch (_) {
      if (available.isEmpty) available = List.of(config.tiles);
    }
    loaded = true;
    notifyListeners();
  }

  // ── Screen 1 — staged evidence groups ──────────────────────────────────────
  // Stages come from config (ordered id groups, each ≤6). Derived against
  // `available` so partial captures still group; empty stages are dropped so the
  // staged UX only appears when there's genuinely a second group of tiles.
  List<List<EvidenceTile>> get _stages {
    final out = <List<EvidenceTile>>[];
    for (final ids in config.stages) {
      final tiles = available.where((t) => ids.contains(t.id)).toList();
      if (tiles.isNotEmpty) out.add(tiles);
    }
    return out;
  }

  /// Whether there is more than one stage to walk through.
  bool get hasStage1 => _stages.length > 1;

  /// The tiles visible on the current stage (≤6 by construction).
  List<EvidenceTile> get stageTiles {
    final stages = _stages;
    if (stages.length <= 1) return available; // ≤6 already → no staging needed
    return stages[evidenceStage.clamp(0, stages.length - 1)];
  }

  int get totalStages {
    final n = _stages.length;
    return n > 1 ? n : 1;
  }

  List<EvidenceTile> get keptTiles =>
      available.where((t) => kept.contains(t.id)).toList();

  void toggleKeep(String id) {
    if (kept.contains(id)) {
      kept.remove(id);
    } else {
      kept.add(id);
    }
    notifyListeners();
  }

  void openPreview(String id) {
    previewId = id;
    notifyListeners();
  }

  void closePreview() {
    previewId = null;
    notifyListeners();
  }

  EvidenceTile? get previewTile => previewId == null ? null : _tile(previewId!);

  void nextStage() {
    if (evidenceStage < totalStages - 1) {
      evidenceStage++;
      notifyListeners();
    }
  }

  void prevStage() {
    if (evidenceStage > 0) {
      evidenceStage--;
      notifyListeners();
    }
  }

  void goToClaim() {
    screen = CerScreen.claim;
    notifyListeners();
  }

  // ── Screen 2 — claim ────────────────────────────────────────────────────────
  void setSlot(int index, String v) {
    slotValues[index] = v;
    notifyListeners();
  }

  bool get claimReady => slotValues.every((v) => v != null);

  /// The claim sentence, interleaving the fixed [config.textParts] with the chosen
  /// slot values (an unfilled slot shows the same ellipsis the playback used).
  /// Tokens are joined with single spaces, except a token starting with sentence
  /// punctuation (e.g. ".") hugs the preceding word — same shape as the old copy.
  String get claimText {
    final parts = config.textParts;
    final tokens = <String>[];
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) tokens.add(parts[i]);
      if (i < slotValues.length) tokens.add(slotValues[i] ?? '…');
    }
    final b = StringBuffer();
    for (var i = 0; i < tokens.length; i++) {
      final t = tokens[i];
      if (i > 0 && !_huggingPunctuation(t)) b.write(' ');
      b.write(t);
    }
    return b.toString();
  }

  static bool _huggingPunctuation(String token) =>
      token.isNotEmpty && '.,!?;:'.contains(token[0]);

  void goToPlayback() {
    if (!claimReady) return;
    screen = CerScreen.playback;
    notifyListeners();
  }

  // ── Screen 3 — playback / the gate ──────────────────────────────────────────
  /// The answering (relevant) clues NOT yet kept — what's still missing.
  List<EvidenceTile> get missingRelevant =>
      available.where((t) => t.relevant && !kept.contains(t.id)).toList();

  /// The distractors the kid is holding — true-but-off-question clues to set aside.
  List<EvidenceTile> get keptDistractors =>
      available.where((t) => !t.relevant && kept.contains(t.id)).toList();

  /// The case is READY only when every answering clue is kept AND no distractor
  /// is kept. Gates the Finish CTA — the close is no longer finish-anyway.
  bool get caseSolved => missingRelevant.isEmpty && keptDistractors.isEmpty;

  /// The non-blocking explainer shown at the gate (missing a clue, holding a
  /// distractor, or both). Episode-specific lines come from the config.
  String get notReadyMessage {
    final missing = missingRelevant.isNotEmpty;
    final extra = keptDistractors.isNotEmpty;
    if (missing && extra) return '${config.incompleteNudge}\n${config.distractorNote}';
    if (extra) return config.distractorNote;
    return config.incompleteNudge;
  }

  /// The on-demand hint (revealed by the bulb): each tile's own hand-written
  /// [EvidenceTile.hint] — a "look for the clue where…" nudge for the first clue
  /// still missing, and/or the "leave it out" note for the first distractor kept.
  /// Recomputes live as the kid toggles clues (so it advances to the next one),
  /// and is null once the case is solved.
  String? get hintText {
    final missing = missingRelevant;
    final extras = keptDistractors;
    if (missing.isEmpty && extras.isEmpty) return null;
    final lines = <String>[];
    if (missing.isNotEmpty) lines.add(missing.first.hint);
    if (extras.isNotEmpty) lines.add(extras.first.hint);
    return lines.join('\n\n');
  }

  void toggleHint() {
    hintRevealed = !hintRevealed;
    notifyListeners();
  }

  /// Go back to Screen 1 to add/adjust evidence (the gate routes here instead of
  /// a finish-anyway). Flips [attemptedFinish] so the hint bulb is now offered;
  /// clears any reasoning-grid placements (they'll be redone after the fix).
  void addMoreEvidence() {
    attemptedFinish = true;
    placed.clear();
    chainBuilt.clear();
    _chainPoolCache = null;
    screen = CerScreen.evidence;
    evidenceStage = 0;
    notifyListeners();
  }

  // ── Screen 3 — active reasoning (coverage grid; config.reasoning != null) ────
  /// tile id → the slot id it has been correctly dropped on (absent = unplaced).
  /// Only correct drops are ever recorded (a wrong drop bounces, see [placeOnSlot]).
  final Map<String, String> placed = {};

  CerReasoning? get reasoning => config.reasoning;

  /// The grid's clue tiles — the placement set, intersected with what the kid
  /// kept (so the grid uses their real captured frames). When [caseSolved] this
  /// is exactly the catches; the gate runs first, so it never shows short.
  List<EvidenceTile> get reasoningTiles {
    final r = config.reasoning;
    if (r == null) return const [];
    return r.tileIds
        .where(kept.contains)
        .map(_tile)
        .whereType<EvidenceTile>()
        .toList();
  }

  /// The optional closer clue (EP1: same_magnet), shown after the grid solves.
  EvidenceTile? get reasoningCloser {
    final id = config.reasoning?.closerId;
    return id == null ? null : _tile(id);
  }

  /// Tiles still in the tray (not yet placed).
  List<EvidenceTile> get unplacedTiles =>
      reasoningTiles.where((t) => !placed.containsKey(t.id)).toList();

  /// Place [tileId] on [slotId] IF that's its correct home. Returns true on a
  /// correct drop (recorded); false on a wrong drop (rejected — the caller
  /// bounces it and shows the wrong-drop note). Never marks a tap right/wrong on
  /// the tile itself; the slot is the unit of the judgment.
  bool placeOnSlot(String tileId, String slotId) {
    final r = config.reasoning;
    if (r is! CerCoverageReasoning) return false;
    if (r.placement[tileId] != slotId) return false;
    placed[tileId] = slotId;
    notifyListeners();
    return true;
  }

  /// Every grid clue dropped on its correct slot (the coverage step is solved).
  bool get gridSolved {
    final tiles = reasoningTiles;
    return tiles.isNotEmpty && tiles.every((t) => placed.containsKey(t.id));
  }

  /// The grid's on-demand hint — the first still-unplaced clue's own [hint] (a
  /// reminder of that source's problem, which points at the need it fails).
  /// Null when the tray is empty.
  String? get gridHintText {
    final t = unplacedTiles;
    return t.isEmpty ? null : t.first.hint;
  }

  // ── Chain reasoning (CerChainReasoning — assemble the causal order) ──────────
  /// The links assembled so far, in order. Only correct "what comes next" taps
  /// are ever appended (a wrong tap nudges — see [tapNextLink]).
  final List<String> chainBuilt = [];

  /// The clue tiles still to be linked, in a stable shuffled pool order.
  List<EvidenceTile> get chainPool {
    final built = chainBuilt.toSet();
    return _chainPool.where((t) => !built.contains(t.id)).toList();
  }

  List<EvidenceTile>? _chainPoolCache;
  List<EvidenceTile> get _chainPool {
    final cached = _chainPoolCache;
    if (cached != null) return cached;
    final tiles = reasoningTiles.toList()..shuffle();
    _chainPoolCache = tiles;
    return tiles;
  }

  /// Tap the clue believed to come NEXT. Appends it IF it's the correct next link
  /// (returns true); otherwise rejects it (false — the caller nudges).
  bool tapNextLink(String tileId) {
    final r = config.reasoning;
    if (r is! CerChainReasoning) return false;
    if (chainBuilt.length >= r.order.length) return false;
    if (r.order[chainBuilt.length] != tileId) return false;
    chainBuilt.add(tileId);
    notifyListeners();
    return true;
  }

  /// The whole chain assembled in correct order.
  bool get chainSolved {
    final r = config.reasoning;
    if (r is! CerChainReasoning) return false;
    return r.order.isNotEmpty && chainBuilt.length == r.order.length;
  }

  /// The chain's on-demand hint — the start hint before anything is placed, then
  /// the connective the last-placed link forces (which points at the next).
  String? get chainHintText {
    final r = config.reasoning;
    if (r is! CerChainReasoning) return null;
    if (chainBuilt.isEmpty) return r.startHint.isEmpty ? null : r.startHint;
    final i = chainBuilt.length - 1;
    final link = i < r.links.length ? r.links[i] : '';
    return link.isEmpty ? (r.startHint.isEmpty ? null : r.startHint) : link;
  }

  void finish() {
    showCardEarn = true;
    notifyListeners();
  }

  void onCardCollected() {
    showCardEarn = false;
    finished = true;
    notifyListeners();
  }
}
