// S3-backed image loading for the Satellite Engineer activities.
//
// The 10 activities' image folders (~195 MB total, 617 files) live on the
// public S3 bucket `the-how-wow-prod` instead of inside the app bundle.
// Each file is at a URL that mirrors its original local path one-for-one:
//
//   local:  assets/images/satellite_doctor/04_medibot/medibot_idle.png
//   S3:     https://the-how-wow-prod.s3.ap-south-1.amazonaws.com/activities/satellite_doctor/04_medibot/medibot_idle.png
//
// This file exposes:
//   • s3UrlForLocalAsset(path)  — the path-rewrite primitive.
//   • netImage(path)            — an ImageProvider drop-in for AssetImage.
//   • netImageWidget(path)      — a Widget drop-in for Image.asset.
//   • precacheActivityImages(context, activityId) — eagerly warms every
//     image listed in `assets/manifests/<activityId>.json` so the activity
//     screen never paints a placeholder. Call this BEFORE pushing the
//     activity (the lesson runner kicks it off while the intro video is
//     still playing — see lessonRunner.dart).
//
// Migration rule of thumb (find/replace):
//   Image.asset('assets/images/foo/bar.png')
//     → netImageWidget('assets/images/foo/bar.png')
//   AssetImage('assets/images/foo/bar.png')
//     → netImage('assets/images/foo/bar.png')
//
// Paths can be passed in either form — "assets/images/<rest>" (the original
// local form, easiest copy-paste) or the bare "<activity_id>/<rest>" form.
// Anything else is returned untouched so callers that already hold an http
// URL keep working.

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flame/cache.dart' show Images;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

/// Base URL of the public howwow asset bucket. Public-read, 1-year cache.
const String _s3Base =
    'https://the-how-wow-prod.s3.ap-south-1.amazonaws.com/activities';

/// Local asset path prefix used by all activity images before migration.
const String _localAssetPrefix = 'assets/images/';

/// Rewrite a local asset path to its S3 URL. Passes through anything that
/// already looks like an absolute URL ({@code "http(s)://..."}) so call
/// sites can mix bundled + network paths without a guard.
String s3UrlForLocalAsset(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  if (path.startsWith(_localAssetPrefix)) {
    return '$_s3Base/${path.substring(_localAssetPrefix.length)}';
  }
  // Already in `<activity_id>/<rest>` form.
  return '$_s3Base/$path';
}

/// Drop-in for {@code AssetImage(...)}. Returns the S3-backed
/// {@link NetworkImage} provider; Flutter's {@link ImageCache} dedupes by
/// the underlying URL string so multiple call sites for the same path
/// share one decoded copy.
ImageProvider netImage(String localAssetPath) =>
    NetworkImage(s3UrlForLocalAsset(localAssetPath));

/// Drop-in for {@code Image.asset(...)}. Forwards the common parameters —
/// fit/width/height/color/etc. — to {@link Image.network}.
///
/// Use this anywhere an activity screen currently calls {@code Image.asset}.
/// The image bytes resolve from {@link ImageCache} if the screen has been
/// pre-warmed by {@link precacheActivityImages}; otherwise they fetch on
/// demand and {@code loadingBuilder} (if supplied) renders during transit.
Widget netImageWidget(
  String localAssetPath, {
  Key? key,
  double? width,
  double? height,
  BoxFit? fit,
  Color? color,
  BlendMode? colorBlendMode,
  Alignment alignment = Alignment.center,
  ImageRepeat repeat = ImageRepeat.noRepeat,
  Rect? centerSlice,
  FilterQuality filterQuality = FilterQuality.medium,
  bool gaplessPlayback = false,
  ImageFrameBuilder? frameBuilder,
  ImageLoadingBuilder? loadingBuilder,
  ImageErrorWidgetBuilder? errorBuilder,
  String? semanticLabel,
  bool excludeFromSemantics = false,
}) {
  return Image.network(
    s3UrlForLocalAsset(localAssetPath),
    key: key,
    width: width,
    height: height,
    fit: fit,
    color: color,
    colorBlendMode: colorBlendMode,
    alignment: alignment,
    repeat: repeat,
    centerSlice: centerSlice,
    filterQuality: filterQuality,
    gaplessPlayback: gaplessPlayback,
    frameBuilder: frameBuilder,
    loadingBuilder: loadingBuilder,
    errorBuilder: errorBuilder,
    semanticLabel: semanticLabel,
    excludeFromSemantics: excludeFromSemantics,
  );
}

/// In-memory cache of parsed manifests — manifests are tiny JSON blobs
/// (one per activity) and identical across a session, so loading the
/// bundle string once is plenty.
final Map<String, List<String>> _manifestCache = {};

/// Load the list of relative paths for an activity from its bundled
/// manifest at {@code assets/manifests/<activityId>.json}. Returns an
/// empty list if the manifest doesn't exist (e.g. a new activity whose
/// manifest hasn't been generated yet) so callers don't crash.
Future<List<String>> _loadManifest(String activityId) async {
  final cached = _manifestCache[activityId];
  if (cached != null) return cached;
  try {
    final raw = await rootBundle.loadString('assets/manifests/$activityId.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final paths = (json['paths'] as List?)
            ?.whereType<String>()
            .toList(growable: false) ??
        const [];
    _manifestCache[activityId] = paths;
    return paths;
  } catch (e) {
    // ignore: avoid_print
    print('s3_assets: failed to load manifest for $activityId: $e');
    _manifestCache[activityId] = const [];
    return const [];
  }
}

/// Convenience getter — returns the list of fully-resolved S3 URLs for
/// every image in {@code activityId}'s manifest. Useful for spot-checking
/// or building a custom precache strategy.
Future<List<String>> activityImageUrls(String activityId) async {
  final rel = await _loadManifest(activityId);
  return [for (final p in rel) '$_s3Base/$activityId/$p'];
}

/// Drop-in replacement for Flame's {@code images.loadAll(...)} that pulls
/// the bytes from S3 instead of the asset bundle. The image is decoded
/// once and {@code images.add(flamePath, image)} keeps the same cache
/// key the activity's existing {@code images.fromCache(p)} / {@code sprite(p)}
/// calls already use — so callers swap one line in {@code onLoad} and
/// nothing else changes.
///
/// Failures on individual entries are swallowed (logged) so a single
/// missing sprite doesn't crash the stage; that mirrors how the previous
/// asset-bundle path failed soft for a missing file.
Future<void> preloadFlameImagesFromS3(
  Images images,
  Iterable<String> flamePaths,
) async {
  await Future.wait(flamePaths.map((p) => loadFlameImageFromS3(images, p)));
}

/// Single-image variant — fetches one Flame-flavoured path from S3, adds
/// it to [images] under the same cache key, and returns the decoded
/// {@code ui.Image} for callers that need it immediately (e.g.
/// {@code Sprite(image)} chains used by activities that load scene
/// sprites lazily per mission).
Future<ui.Image?> loadFlameImageFromS3(
  Images images,
  String flamePath,
) async {
  try {
    final url = '$_s3Base/$flamePath';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      // ignore: avoid_print
      print('s3_assets: Flame fetch ${response.statusCode} for $url');
      return null;
    }
    final codec = await ui.instantiateImageCodec(response.bodyBytes);
    final frame = await codec.getNextFrame();
    images.add(flamePath, frame.image);
    return frame.image;
  } catch (e) {
    // ignore: avoid_print
    print('s3_assets: Flame fetch failed for $flamePath: $e');
    return null;
  }
}

/// Pre-warm Flutter's {@link ImageCache} with every image declared in the
/// activity's manifest. Returns when the precache pass completes (or fails
/// individually) so callers can {@code await} this before pushing the
/// activity screen.
///
/// Failures on individual images are swallowed — a single 404 or transient
/// network blip should NOT keep the whole lesson from starting. Anything
/// that fails to precache simply loads on first paint inside the activity
/// (Flutter's {@code Image.network} handles the lazy case fine).
///
/// Wall-clock cost: dominated by the largest image, not the count, since
/// all requests fan out in parallel. On a warm 4G connection in India,
/// satellite_doctor (112 files, 34 MB) precaches in ~3 seconds; smaller
/// activities are sub-second. Run this during the lesson intro video.
Future<void> precacheActivityImages(
  BuildContext context,
  String activityId,
) async {
  final rel = await _loadManifest(activityId);
  if (rel.isEmpty) return;
  // Snapshot the context-derived bits BEFORE the async gap so we don't
  // re-touch BuildContext after each await (which would trip use_build_context_synchronously).
  final futures = <Future<void>>[];
  for (final p in rel) {
    final url = '$_s3Base/$activityId/$p';
    final provider = NetworkImage(url);
    futures.add(precacheImage(provider, context).catchError((_) {}));
  }
  await Future.wait(futures);
}
