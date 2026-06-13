// Per-activity capture plumbing shared by every capture-bearing activity (Act 2,
// Act 3). Owns the captured-ids list (seeded from the persistent store so a
// re-entered activity shows what was already pinned), the captured-image bytes
// (the REAL scene frames, PRD §8), and a small flash QUEUE so back-to-back
// captures each play their pin animation in turn. The activity shell snapshots its
// scene at the discovery beat and hands the bytes here.

import 'package:flutter/foundation.dart';

import 'evidence_models.dart';
import 'evidence_store.dart';

class EpisodeBoardCapture {
  EpisodeBoardCapture(this.episodeId);

  final String episodeId;

  /// Captured tile ids in capture order — the board strip fills from this.
  final ValueNotifier<List<String>> capturedIds = ValueNotifier(const []);

  /// id → captured scene frame (the actual moment the kid saw). Tiles with no
  /// entry fall back to their drawn motif.
  final ValueNotifier<Map<String, Uint8List>> images = ValueNotifier(const {});

  /// The tile whose capture animation is currently playing (null = none).
  final ValueNotifier<EvidenceTileFlash?> flashing = ValueNotifier(null);

  final List<EvidenceTileFlash> _queue = [];

  /// Start a FRESH episode run: wipe any evidence persisted from a prior run so the
  /// board begins empty and is collected anew. Called by the episode's FIRST
  /// activity ONLY; later activities call [load] to keep what's accumulated.
  Future<void> reset() async {
    await EvidenceStore.clear(episodeId);
    capturedIds.value = const [];
    images.value = const {};
    _queue.clear();
    flashing.value = null;
  }

  /// Seed from the store (pinned ids) + the in-memory image cache (frames from
  /// earlier in this session). Never throws — id load is the only await.
  Future<void> load() async {
    final ids = await EvidenceStore.captured(episodeId);
    capturedIds.value = List.unmodifiable(ids);
    final imgs = <String, Uint8List>{};
    for (final id in ids) {
      final b = EvidenceStore.imageBytes(episodeId, id);
      if (b != null) imgs[id] = b;
    }
    images.value = Map.unmodifiable(imgs);
  }

  /// The capture hook handed to an activity controller (after the shell snapshots
  /// the scene). [imageBytes] is the real captured frame (null → drawn motif). On a
  /// REPLAY (id already pinned) it still backfills a fresh frame but doesn't
  /// re-pin/re-animate, so re-running the activity refreshes a missing image.
  void capture(String id, {Uint8List? imageBytes}) {
    final tile = evidenceByIdFor(episodeId, id);
    if (tile == null) return;
    final already = capturedIds.value.contains(id);
    if (imageBytes != null && images.value[id] == null) {
      EvidenceStore.putImage(episodeId, id, imageBytes);
      images.value = Map.unmodifiable({...images.value, id: imageBytes});
    }
    if (already) return; // don't re-pin / re-animate an already-captured moment
    EvidenceStore.add(episodeId, id); // fire-and-forget id persistence
    capturedIds.value = List.unmodifiable([...capturedIds.value, id]);
    _queue.add(EvidenceTileFlash(tile, imageBytes ?? images.value[id]));
    if (flashing.value == null) flashing.value = _queue.first;
  }

  /// Called by the shell when the current CaptureFlash finishes.
  void flashDone() {
    if (_queue.isNotEmpty) _queue.removeAt(0);
    flashing.value = _queue.isNotEmpty ? _queue.first : null;
  }

  void dispose() {
    capturedIds.dispose();
    images.dispose();
    flashing.dispose();
  }
}

/// A tile + its captured scene frame, for the flash overlay.
class EvidenceTileFlash {
  const EvidenceTileFlash(this.tile, this.imageBytes);
  final EvidenceTile tile;
  final Uint8List? imageBytes;
}
