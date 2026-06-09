// Progress write-path client surface. Three endpoints:
//
//   POST /howwow/lessons/{lessonId}/resources/{idx}/start
//   POST /howwow/lessons/{lessonId}/resources/{idx}/complete
//   PUT  /howwow/profile/timezone
//
// Auth via the appJwt stored by AuthTokenService (injected automatically
// by ApiClient). The progress POST is intentionally fire-and-forget from
// the lesson runner — failures don't block the next resource, and the
// next /career/professions/{id}/detail load will re-derive the correct
// state from the server's authoritative `howwow_lesson_progress`
// collection.

import '../../models/howwow/howwowProgress.dart';
import '../apiClient.dart';
import '../endpoints.dart';

/// POST `/howwow/lessons/{lessonId}/resources/{resourceIndex}/complete`.
///
/// Records one resource finish (video / image / activity). Server enforces
/// monotonic submission — index N is only accepted if N-1 is already done.
/// On the final resource the server marks the lesson complete, advances
/// {@code user.currentLessonId} to the next lesson, and bumps streak
/// (once per local-timezone day).
///
/// Throws [ApiException] on non-2xx so the caller (the lesson runner's
/// fire-and-forget loop) can swallow + retry on next app launch via the
/// pending queue. For now the client just logs failures and keeps going —
/// the server is the source of truth and re-syncs on the next /detail load.
Future<HowwowResourceCompleteResponse> howwowMarkResourceCompleted({
  required String lessonId,
  required int resourceIndex,
  required String type, // "video" | "image" | "activity" — currently informational
}) async {
  final json = await ApiClient.instance.postJson(
    Endpoints.howwow('/lessons/$lessonId/resources/$resourceIndex/complete'),
    body: {'type': type},
  );
  return HowwowResourceCompleteResponse.fromJson(json);
}

/// POST `/howwow/lessons/{lessonId}/resources/{resourceIndex}/start`.
///
/// Records that the user ENTERED a resource (the runner is about to push
/// its screen). This is the "lesson in progress, on resource N" signal —
/// completion only tells us what's finished; this tells us a lesson was
/// opened at all (kid watched half the intro and left → startedAt is set
/// even though lastCompletedResourceIndex stays -1) and when the user was
/// last inside it (re-engagement nudges).
///
/// Server behaviour (see docs/howwow-resource-start-spec.md):
///   • sets `startedAt` on the progress doc the FIRST time only,
///   • overwrites `lastResourceStartedIndex` / `lastResourceStartedAt`
///     on every call. Idempotent, no monotonic enforcement — this is
///     informational state, not an unlock gate.
///
/// Fire-and-forget from the runner: failures are swallowed there (a lost
/// start write costs telemetry precision, never progress). Throws
/// [ApiException] on non-2xx so the runner can detect a 404 (backend not
/// deployed yet) and stop retrying for the session.
Future<void> howwowMarkResourceStarted({
  required String lessonId,
  required int resourceIndex,
  required String type, // "video" | "image" | "activity"
}) async {
  await ApiClient.instance.postJson(
    Endpoints.howwow('/lessons/$lessonId/resources/$resourceIndex/start'),
    body: {'type': type},
  );
}

/// PUT `/howwow/profile/timezone`.
///
/// Persists the user's IANA timezone id (e.g. `"Asia/Kolkata"`). The
/// streak day-boundary check uses this to compute "today" in the user's
/// local time instead of UTC. Safe to call repeatedly — the backend
/// no-ops when the value is unchanged.
Future<void> howwowSetTimezone(String timezone) async {
  await ApiClient.instance.putJson(
    Endpoints.howwow('/profile/timezone'),
    body: {'timezone': timezone},
  );
}
