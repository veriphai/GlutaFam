// Typed model + parser for howwow deep-link URLs.
//
// URL scheme (custom, Android + iOS registered): `howwow://`
//
// Catalog (kept in sync with docs/howwow-fcm-deeplinks.md and the Python
// notification service):
//
//   howwow://home
//   howwow://world/{worldId}
//   howwow://career/{professionId}
//   howwow://career/{professionId}/lesson/{lessonId}
//   howwow://career/{professionId}/lesson/{lessonId}?action=start
//
// Optional query params (any URL):
//   ?deeplink_id=...  — backend-generated UUID for analytics attribution
//   ?source=...       — "push" | "email" | "web" etc. — defaults to "push"
//                       when arriving via FCM, "external" otherwise.
//
// Parsing returns null for unknown / malformed URLs so the caller can
// silently ignore unmatched links rather than crash the navigation.

import 'package:flutter/foundation.dart';

/// Discriminated union of valid howwow deeplink targets. Switch over
/// {@code runtimeType} (or use the named subclasses) at the navigation
/// site.
@immutable
sealed class HowwowDeeplink {
  const HowwowDeeplink({this.deeplinkId, this.source});

  /// Backend-generated id stamped on the URL when the Python service
  /// pushes a notification. Threaded through to {@code notification_tapped}
  /// for funnel attribution.
  final String? deeplinkId;

  /// Where the URL came from — "push", "email", "external", etc.
  final String? source;

  /// True when the target needs an authenticated user to render
  /// correctly. The router uses this to decide whether to stash the
  /// deeplink as pending and route to login.
  bool get requiresAuth;
}

class HomeDeeplink extends HowwowDeeplink {
  const HomeDeeplink({super.deeplinkId, super.source});
  @override
  bool get requiresAuth => true; // home is the user's career page
}

class WorldDeeplink extends HowwowDeeplink {
  const WorldDeeplink({
    required this.worldId,
    super.deeplinkId,
    super.source,
  });
  final String worldId;
  @override
  bool get requiresAuth => false; // world detail is browse-able anonymously
}

class CareerDeeplink extends HowwowDeeplink {
  const CareerDeeplink({
    required this.professionId,
    super.deeplinkId,
    super.source,
  });
  final String professionId;
  @override
  bool get requiresAuth => false; // anonymous browse for cataloging
}

class LessonDeeplink extends HowwowDeeplink {
  const LessonDeeplink({
    required this.professionId,
    required this.lessonId,
    this.autoStart = false,
    super.deeplinkId,
    super.source,
  });

  /// Profession the lesson belongs to — encoded in the URL so the client
  /// doesn't need an extra round trip to resolve professionId from
  /// lessonId before navigating.
  final String professionId;
  final String lessonId;

  /// True iff the URL carried {@code ?action=start}. The profession-detail
  /// screen reads this and auto-fires {@code _launchEpisode} for the
  /// lesson IF it is currently unlocked (per option A — locked lessons
  /// land on the profession page in their locked state, no auto-start).
  final bool autoStart;

  @override
  bool get requiresAuth => true; // lock state is per-user
}

/// Parse [uri] into a typed [HowwowDeeplink], or null when the URL doesn't
/// match any known shape.
///
/// Accepts only the {@code howwow} scheme. URL paths from the {@code tuto}
/// scheme used by the legacy DeepLinkService are not recognised here —
/// each scheme has its own handler.
HowwowDeeplink? parseHowwowDeeplink(Uri uri) {
  if (uri.scheme != 'howwow') return null;

  // Custom-scheme URIs put the first path segment in `host`, the rest in
  // `pathSegments`. Normalise both into one flat list so the matcher
  // doesn't have to special-case shape.
  final segs = <String>[
    if (uri.host.isNotEmpty) uri.host,
    ...uri.pathSegments.where((s) => s.isNotEmpty),
  ];

  final deeplinkId = uri.queryParameters['deeplink_id'];
  final source = uri.queryParameters['source'];

  if (segs.isEmpty || segs.first == 'home') {
    return HomeDeeplink(deeplinkId: deeplinkId, source: source);
  }
  // /world/{id}
  if (segs.length == 2 && segs[0] == 'world') {
    return WorldDeeplink(
      worldId: segs[1],
      deeplinkId: deeplinkId,
      source: source,
    );
  }
  // /career/{professionId}
  if (segs.length == 2 && segs[0] == 'career') {
    return CareerDeeplink(
      professionId: segs[1],
      deeplinkId: deeplinkId,
      source: source,
    );
  }
  // /career/{professionId}/lesson/{lessonId}
  if (segs.length == 4 && segs[0] == 'career' && segs[2] == 'lesson') {
    final autoStart = uri.queryParameters['action'] == 'start';
    return LessonDeeplink(
      professionId: segs[1],
      lessonId: segs[3],
      autoStart: autoStart,
      deeplinkId: deeplinkId,
      source: source,
    );
  }
  return null;
}
