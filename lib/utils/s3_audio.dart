// S3-backed audio loading for the Satellite Engineer activities.
//
// The 11 activities' sound folders (~129 MB, 593 files — Orbit voice-over,
// BGM, SFX) live on the public S3 bucket alongside the activity images:
//
//   local:  assets/sounds/build_satellite/orbit/orbit_01.wav
//   S3:     https://the-how-wow-prod.s3.ap-south-1.amazonaws.com/activities/build_satellite/audio/orbit/orbit_01.wav
//
// Voice/SFX must play with <100ms latency, so unlike images these are NOT
// streamed on demand. The model is download-to-disk-then-play:
//
//   • precacheActivityAudio(activityId) — fetches every file listed in the
//     `audio` array of `assets/manifests/<activityId>.json` into the app
//     cache dir (skipping files already on disk). The lesson runner kicks
//     this off while the intro video plays, in the same window as
//     precacheActivityImages — see lessonRunner.dart.
//   • audioSource(path) — synchronous drop-in for AssetSource. Returns a
//     DeviceFileSource pointing at the cached file when available, falling
//     back to UrlSource (progressive streaming) when the download hasn't
//     landed yet, so a slow network delays a clip instead of crashing it.
//
// Migration rule of thumb (find/replace):
//   player.play(AssetSource('sounds/foo/bar.mp3'))
//     → player.play(audioSource('sounds/foo/bar.mp3'))
//
// Cached files live at <appCacheDir>/activity_audio/<activity_id>/<rest>.
// The OS may purge that dir under disk pressure; the next lesson start
// simply re-downloads whatever is missing.

import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart'
    show AssetSource, DeviceFileSource, Source, UrlSource;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Base URL of the public howwow asset bucket (same as s3_assets.dart).
const String _s3Base =
    'https://the-how-wow-prod.s3.ap-south-1.amazonaws.com/activities';

/// Local asset path prefixes accepted by the helpers. audioplayers'
/// AssetSource takes paths relative to `assets/` (`sounds/<id>/x.mp3`),
/// while pubspec-style call sites may hold the full `assets/sounds/...`
/// form — both normalize to `<activity_id>/<rest>`.
const String _soundsPrefix = 'sounds/';
const String _assetsSoundsPrefix = 'assets/sounds/';

/// In-memory registry: normalized `<activity_id>/<rest>` → absolute path of
/// the downloaded file. Populated by [precacheActivityAudio]; consulted
/// synchronously by [audioSource].
final Map<String, String> _cachedFiles = {};

/// Root of the on-disk audio cache, resolved once per session.
Directory? _cacheRoot;

/// Strip the local-asset prefix so both accepted forms become
/// `<activity_id>/<rest>` (which mirrors the S3 key under
/// `activities/<activity_id>/audio/` — note the id and the rest are split
/// around the injected `audio/` segment when building the URL).
String _normalize(String path) {
  if (path.startsWith(_assetsSoundsPrefix)) {
    return path.substring(_assetsSoundsPrefix.length);
  }
  if (path.startsWith(_soundsPrefix)) {
    return path.substring(_soundsPrefix.length);
  }
  return path;
}

/// Rewrite a local sound asset path to its S3 URL.
///
///   sounds/build_satellite/orbit/orbit_01.wav
///     → $_s3Base/build_satellite/audio/orbit/orbit_01.wav
String s3UrlForAudioAsset(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final rel = _normalize(path); // <activity_id>/<rest>
  final slash = rel.indexOf('/');
  if (slash <= 0) return '$_s3Base/$rel'; // malformed — best effort
  final activityId = rel.substring(0, slash);
  final rest = rel.substring(slash + 1);
  return '$_s3Base/$activityId/audio/$rest';
}

/// Synchronous drop-in for {@code AssetSource(...)}. Accepts the exact same
/// path string the activities already use and routes by prefix:
///   • `sounds/<id>/<rest>` (S3-migrated activity audio) →
///     [DeviceFileSource] when [precacheActivityAudio] has the file on disk
///     (the normal case; file-local latency, offline-safe), falling back to
///     [UrlSource] streaming when the download hasn't landed yet.
///   • "http(s)://..." → [UrlSource] pass-through.
///   • anything else (root-level bundled SFX shared across the app —
///     jumpSound.mp3, correct_answer.mp3, …) → plain [AssetSource], exactly
///     as before. Those stay in the bundle: they're small, shared, and
///     declared individually in pubspec.yaml.
Source audioSource(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return UrlSource(path);
  }
  if (!path.startsWith(_soundsPrefix) &&
      !path.startsWith(_assetsSoundsPrefix)) {
    return AssetSource(path);
  }
  final rel = _normalize(path);
  final cached = _cachedFiles[rel];
  if (cached != null) return DeviceFileSource(cached);
  return UrlSource(s3UrlForAudioAsset(path));
}

/// In-memory cache of parsed audio manifests (same shape as the image-side
/// cache in s3_assets.dart, but reading the `audio` array).
final Map<String, List<String>> _manifestCache = {};

Future<List<String>> _loadAudioManifest(String activityId) async {
  final cached = _manifestCache[activityId];
  if (cached != null) return cached;
  try {
    final raw =
        await rootBundle.loadString('assets/manifests/$activityId.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final paths = (json['audio'] as List?)
            ?.whereType<String>()
            .toList(growable: false) ??
        const [];
    _manifestCache[activityId] = paths;
    return paths;
  } catch (e) {
    // ignore: avoid_print
    print('s3_audio: failed to load audio manifest for $activityId: $e');
    _manifestCache[activityId] = const [];
    return const [];
  }
}

Future<Directory> _resolveCacheRoot() async {
  final existing = _cacheRoot;
  if (existing != null) return existing;
  final base = await getApplicationCacheDirectory();
  final dir = Directory('${base.path}/activity_audio');
  await dir.create(recursive: true);
  _cacheRoot = dir;
  return dir;
}

/// Download every audio file in {@code activityId}'s manifest to the app
/// cache dir and register it for [audioSource]. Files already on disk are
/// registered without re-downloading, so after the first lesson run this
/// resolves in milliseconds and works fully offline.
///
/// Individual failures are swallowed (logged) — a missing clip falls back
/// to UrlSource streaming at play time rather than blocking the lesson.
///
/// On web there is no filesystem; the function is a no-op and [audioSource]
/// always streams (the browser's HTTP cache does the heavy lifting).
Future<void> precacheActivityAudio(String activityId) async {
  if (kIsWeb) return;
  final rel = await _loadAudioManifest(activityId);
  if (rel.isEmpty) return;
  final root = await _resolveCacheRoot();
  await Future.wait(
    [for (final p in rel) _fetchOne(root, activityId, p)],
  );
}

Future<void> _fetchOne(Directory root, String activityId, String rel) async {
  final key = '$activityId/$rel';
  final file = File('${root.path}/$activityId/$rel');
  try {
    if (await file.exists() && (await file.length()) > 0) {
      _cachedFiles[key] = file.path;
      return;
    }
    final url = '$_s3Base/$activityId/audio/$rel';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      // ignore: avoid_print
      print('s3_audio: fetch ${response.statusCode} for $url');
      return;
    }
    await file.parent.create(recursive: true);
    // Write to a temp name then rename so a mid-write kill never leaves a
    // truncated file that the exists()/length() fast-path would trust.
    final tmp = File('${file.path}.part');
    await tmp.writeAsBytes(response.bodyBytes, flush: true);
    await tmp.rename(file.path);
    _cachedFiles[key] = file.path;
  } catch (e) {
    // ignore: avoid_print
    print('s3_audio: fetch failed for $key: $e');
  }
}
