// Episode-scoped persistence for captured evidence (PRD §8). Two tiers:
//
//  • IDS — which moments were captured — in `shared_preferences` (same approach as
//    the deck), so the collected SET survives across the separate activity routes
//    the lesson runner pushes, and across sessions. Capture ORDER is preserved.
//
//  • IMAGES — the real captured scene FRAMES — in an in-memory byte cache keyed per
//    episode. The episode is played back-to-back in ONE app session (Act 2 → Act 3
//    → closing), so a session cache is exactly the episode scope; it also works
//    identically on web + device with no file-IO that can hang/throw (the earlier
//    `path_provider`/`dart:io` disk approach broke on web — froze the closing screen
//    on its spinner and dropped captures). If the app is killed mid-episode the
//    bytes are lost but the ids persist, so tiles gracefully fall back to the drawn
//    motif until re-captured.

import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

class EvidenceStore {
  EvidenceStore._();

  static String _key(String episodeId) => 'howwow_evidence_$episodeId';

  // ── Captured ids (persistent, cross-session) ────────────────────────────────
  static Future<List<String>> captured(String episodeId) async {
    final prefs = await SharedPreferences.getInstance();
    return List<String>.from(prefs.getStringList(_key(episodeId)) ?? const <String>[]);
  }

  /// Record a captured moment (idempotent). Returns true when newly added.
  static Future<bool> add(String episodeId, String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = List<String>.from(prefs.getStringList(_key(episodeId)) ?? <String>[]);
    if (list.contains(id)) return false;
    list.add(id);
    await prefs.setStringList(_key(episodeId), list);
    return true;
  }

  static Future<bool> has(String episodeId, String id) async =>
      (await captured(episodeId)).contains(id);

  // ── Captured scene IMAGES (in-memory, session-scoped, PRD §8) ───────────────
  static final Map<String, Uint8List> _images = {};

  static String _imgKey(String episodeId, String id) => '$episodeId|$id';

  static void putImage(String episodeId, String id, Uint8List bytes) =>
      _images[_imgKey(episodeId, id)] = bytes;

  /// The captured scene frame for [id], or null (→ the tile uses its drawn motif).
  static Uint8List? imageBytes(String episodeId, String id) => _images[_imgKey(episodeId, id)];

  /// Clear the board for an episode (a "play again" reset). Not wired to UI yet.
  static Future<void> clear(String episodeId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key(episodeId)) ?? const <String>[];
    for (final id in ids) {
      _images.remove(_imgKey(episodeId, id));
    }
    await prefs.remove(_key(episodeId));
  }
}
