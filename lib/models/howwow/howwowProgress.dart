// Typed Dart mirror of HowwowResourceCompleteResponse — the 200 body of
// POST /howwow/lessons/{lessonId}/resources/{idx}/complete.

import 'howwowProfile.dart' show HowwowStats;

/// State after a successful resource-completion write. The lesson runner
/// fire-and-forgets the POST so callers usually don't read this — it's
/// here for the home/career screens that DO update local state when the
/// response surfaces a streak bump or a new currentLesson target.
class HowwowResourceCompleteResponse {
  const HowwowResourceCompleteResponse({
    this.resourcesCompleted = const [],
    this.lessonCompleted = false,
    this.nextLessonId,
    this.stats,
  });

  /// All completed resource indices for this lesson AFTER the just-recorded
  /// write. Always a contiguous prefix `[0..N]` thanks to the server's
  /// monotonic enforcement.
  final List<int> resourcesCompleted;

  /// True iff the lesson is now fully complete (the just-completed index
  /// was the last in the lesson).
  final bool lessonCompleted;

  /// Id of the next lesson in the same profession, or {@code null} when
  /// this was the final lesson.
  final String? nextLessonId;

  /// Refreshed header stats — XP / badges / streakDays. Streak may have
  /// bumped if this was the user's first completion of the local day.
  final HowwowStats? stats;

  factory HowwowResourceCompleteResponse.fromJson(Map<String, dynamic> j) =>
      HowwowResourceCompleteResponse(
        resourcesCompleted: (j['resourcesCompleted'] as List?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            const [],
        lessonCompleted: j['lessonCompleted'] == true,
        nextLessonId: j['nextLessonId'] as String?,
        stats: j['stats'] is Map
            ? HowwowStats.fromJson(Map<String, dynamic>.from(j['stats'] as Map))
            : null,
      );
}
