// The "Make Your Case" controller — owns the 3-screen closing flow's state
// (PRD §4): which screen, the staged evidence selection, the kept set, the
// 2-slot claim, and whether the assembled case feels complete. A single
// ChangeNotifier (no Provider/Riverpod) — the shell rebuilds via ListenableBuilder.
//
// Loads the captured evidence from the episode store (PRD §8). If nothing was
// captured (standalone/dev entry), it seeds the FULL catalog so the flow is always
// playable. Selection is never scored — `caseComplete` ONLY drives whether the
// playback feels complete (§4.3), never a ✓/✗ on a tap (§5.4).

import 'package:flutter/foundation.dart';

import '../../episode_board/evidence_models.dart';
import '../../episode_board/evidence_store.dart';

enum CerScreen { evidence, claim, playback }

class CerController extends ChangeNotifier {
  CerController({required this.episodeId});

  final String episodeId;

  /// The evidence the kid actually captured (or the full set as a fallback).
  List<EvidenceTile> available = const [];

  /// id → captured scene frame (the real moment the kid saw, PRD §8).
  Map<String, Uint8List> imageBytes = const {};

  bool loaded = false;

  CerScreen screen = CerScreen.evidence;

  /// Screen 1 staging (§4 / §6 — keep ≤6 visible): stage 0 = the catches; stage 1
  /// = the convergence + the two distractors.
  int evidenceStage = 0;

  /// The kid's kept evidence (selection — the act of discriminating relevant from
  /// irrelevant IS the reasoning, §4.1).
  final Set<String> kept = {};

  /// The 2-slot claim (built, not chosen — §4.2).
  String? slot1;
  String? slot2;

  bool showCardEarn = false;
  bool finished = false; // card collected → ready to pop

  /// Screen 1: the tile currently opened in the tap-to-inspect preview (null =
  /// none). Tapping a clue OPENS it (see the captured frame full-size); the
  /// preview is where the kid then keeps/leaves it.
  String? previewId;

  // ── Load ───────────────────────────────────────────────────────────────────
  Future<void> load() async {
    // Defensive: whatever happens, finish loading so the screen never hangs on its
    // spinner (the closing flow must always open after the activities).
    try {
      final ids = await EvidenceStore.captured(episodeId);
      final caught = ids.map(evidenceById).whereType<EvidenceTile>().toList();
      available = caught.isNotEmpty ? caught : List.of(kEpisode1Evidence);
      final imgs = <String, Uint8List>{};
      for (final t in available) {
        final b = EvidenceStore.imageBytes(episodeId, t.id);
        if (b != null) imgs[t.id] = b;
      }
      imageBytes = Map.unmodifiable(imgs);
    } catch (_) {
      if (available.isEmpty) available = List.of(kEpisode1Evidence);
    }
    loaded = true;
    notifyListeners();
  }

  // ── Screen 1 — staged evidence groups ──────────────────────────────────────
  // Group B (the convergence + distractors) is the Act-2 set; group A is the rest
  // (the Act-3 catches). Derived from `available` so partial captures still group.
  static const Set<String> _groupBIds = {'same_magnet', 'still_magnet', 'turbine_spin'};

  List<EvidenceTile> get _groupA =>
      available.where((t) => !_groupBIds.contains(t.id)).toList();
  List<EvidenceTile> get _groupB =>
      available.where((t) => _groupBIds.contains(t.id)).toList();

  /// Whether there is a second stage to advance to (only if group B has tiles).
  bool get hasStage1 => _groupB.isNotEmpty && _groupA.isNotEmpty;

  /// The tiles visible on the current stage (≤6 by construction).
  List<EvidenceTile> get stageTiles {
    if (!hasStage1) return available; // ≤6 already → no staging needed
    return evidenceStage == 0 ? _groupA : _groupB;
  }

  int get totalStages => hasStage1 ? 2 : 1;

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

  EvidenceTile? get previewTile => previewId == null ? null : evidenceById(previewId!);

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
  void setSlot1(String v) {
    slot1 = v;
    notifyListeners();
  }

  void setSlot2(String v) {
    slot2 = v;
    notifyListeners();
  }

  bool get claimReady => slot1 != null && slot2 != null;

  void goToPlayback() {
    if (!claimReady) return;
    screen = CerScreen.playback;
    notifyListeners();
  }

  // ── Screen 3 — playback / completeness ──────────────────────────────────────
  /// The "ideal" case: every RELEVANT clue kept, no distractor kept. Drives ONLY
  /// the gentle feels-incomplete nudge (§4.3) — never a score (§5.4).
  bool get caseComplete {
    final relevant = available.where((t) => t.relevant).map((t) => t.id).toSet();
    final keptRelevant = kept.where(relevant.contains).length;
    final keptDistractor = kept.where((id) => !relevant.contains(id)).isNotEmpty;
    return keptRelevant == relevant.length && relevant.isNotEmpty && !keptDistractor;
  }

  /// Go back to Screen 1 to add/adjust evidence (gentle, never "wrong" §4.3).
  void addMoreEvidence() {
    screen = CerScreen.evidence;
    evidenceStage = 0;
    notifyListeners();
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
