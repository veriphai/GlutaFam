// Orchestrates a single lesson's resource sequence — the list of
// (video|image|activity) steps the backend returns on each lesson DTO.
//
// Pattern: each resource is its own Navigator route. We push, await the
// pop, then push the next. The activity screens themselves are oblivious
// to lessons — they pop when done, same as they have always done.
//
// Pop-result protocol: media screens (MissionVideoScreen /
// LessonImageScreen) pop with `true` when the resource FINISHED (video
// ended, Skip tapped, image timed out / tapped). System back on a VIDEO
// first raises the premium leave-confirm modal (leaveLessonDialog.dart —
// the video pauses while it's up); a confirmed leave pops with `false`.
// A media-screen back-out (`false` from a video, null from an image)
// stops the run — no completion POST, no further pushes — so back means
// "leave the lesson", not "fast-forward through it".
//
// Activities are NOT guarded: they finish via Navigator.maybePop() from
// their own success screens, and a system back uses the same maybePop —
// indistinguishable — so any activity pop counts as completion (the
// pre-existing behaviour). Wrapping them in a PopScope leave-guard would
// have made the "Continue" button itself trigger the leave dialog.
//
// Returns false when none of the resources resolved to a real screen, so
// callers can surface a "not available yet" snackbar. Unknown / unplayable
// individual resources are silently skipped rather than aborting the whole
// lesson, so a partially-content-complete lesson still progresses through
// what's available.
//
// Precache pipelining: when the *next* resource in the queue is an activity
// (its images live on S3), we kick off precacheActivityImages BEFORE
// pushing the current resource. That way the activity's sprites fetch in
// the background while the user is watching the intro video, and by the
// time the video pops the activity has its bytes warm in memory.
//
// Progress writes: after every resource pops we fire-and-forget
// {@link howwowMarkResourceCompleted}. We do NOT await — a slow network
// shouldn't stall the next resource — and we tolerate failures: the
// server is authoritative, and the next /career/professions/{id}/detail
// load will re-derive the right state. Re-submission of an already-completed
// index is idempotent on the server.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../apis/apiClient.dart' show ApiException;
import '../../apis/howwow/howwowProgress.dart';
import '../../models/howwow/howwowProgress.dart';
import '../../models/howwow/howwowProfile.dart' show HowwowLessonResource;
import '../../utils/howwowEventLogger.dart';
import '../../utils/howwowEventNames.dart';
import '../../utils/s3_assets.dart';
import '../../utils/s3_audio.dart';
import 'activityRegistry.dart';
import 'lessonImageScreen.dart';
import 'missionVideoScreen.dart';

/// Outcome of an [openLesson] run, so the caller can refresh the timeline
/// and (when the lesson fully completed) prompt the next episode.
class LessonRunResult {
  const LessonRunResult({
    required this.launchedAny,
    this.lessonCompleted = false,
    this.nextLessonId,
  });

  /// At least one resource produced a real screen. False → the caller
  /// surfaces the "not available yet" snackbar.
  final bool launchedAny;

  /// The just-completed resource was the lesson's last AND the server
  /// confirmed the whole lesson is now complete (from the final
  /// completion POST's response). False when the user backed out early.
  final bool lessonCompleted;

  /// Id of the next lesson in the chain (from the server), or null when
  /// this was the final lesson of the profession.
  final String? nextLessonId;

  static const LessonRunResult none = LessonRunResult(launchedAny: false);
}

/// Push each resource in [resources] in order, awaiting one before pushing
/// the next. After every successful pop, queues the per-resource completion
/// POST onto a serial chain (see the chain note in the body). When
/// [lessonId] is null the completion calls are skipped — useful for the
/// dev/test path where a lesson is run without backend wiring.
///
/// [startFromIndex] lets a partially-completed lesson resume — if the user
/// already watched the intro video, the next open of the lesson skips
/// straight to the activity. Pass `lastCompletedResourceIndex + 1` from
/// the profession-detail DTO. Defaults to 0 (start from the beginning).
///
/// Returns a [LessonRunResult] — `launchedAny` is false when the list was
/// empty, every resource was unrecognised, or [startFromIndex] is past the
/// end; `lessonCompleted` + `nextLessonId` drive the caller's next-episode
/// prompt.
Future<LessonRunResult> openLesson(
  BuildContext context,
  List<HowwowLessonResource> resources, {
  String? lessonId,
  int startFromIndex = 0,
}) async {
  if (resources.isEmpty) return LessonRunResult.none;
  // If the resume index is past the end (e.g. user taps a fully-completed
  // lesson hoping to re-watch), restart from the beginning instead of
  // falling through to the "not available yet" snackbar. Re-submission
  // of an already-completed index is idempotent server-side.
  final start = (startFromIndex < 0 || startFromIndex >= resources.length)
      ? 0
      : startFromIndex;

  // ignore: avoid_print
  print('[howwow-lesson] openLesson → lesson=$lessonId '
      'start=$start total=${resources.length} '
      'types=${resources.map((r) => r.type).join(",")}');

  // Distinct events for fresh start vs resume — the funnel slices
  // differently for the two and we want to see both.
  HowwowEventLogger.instance.logImmediate(
    start > 0 ? HowwowEvents.lessonResumed : HowwowEvents.lessonStarted,
    props: {
      'lesson_id': lessonId,
      'start_from_index': start,
      'total_resources': resources.length,
    },
  );

  bool launchedAny = false;
  bool backedOut = false;
  int? lastIndexEntered;
  // Completion POSTs are serialized through this chain rather than fired
  // concurrently. The server enforces MONOTONIC submission — index N is
  // rejected unless 0..N-1 are already recorded — and only marks the
  // lesson complete (→ adds it to completedLessonIds, which unlocks the
  // next episode) when the FINAL index is accepted. Firing them
  // fire-and-forget raced the writes: if an early POST was still in flight
  // when the final POST hit the server, the final was rejected as
  // non-monotonic and the lesson silently never completed — the flaky
  // "sometimes the next episode unlocks, sometimes it stays locked" bug.
  // Chaining keeps the UI non-blocking (screens still push instantly)
  // while guaranteeing in-order delivery; we await the whole chain before
  // returning so the caller's post-lesson reload reads the final state.
  Future<void> completionChain = Future.value();
  // Captures the most recent completion POST response — the final
  // resource's tells us whether the whole lesson is now complete and the
  // next lesson id, for the caller's next-episode prompt.
  HowwowResourceCompleteResponse? lastCompletion;
  for (int i = start; i < resources.length; i++) {
    if (!context.mounted) {
      await completionChain;
      return LessonRunResult(
        launchedAny: launchedAny,
        lessonCompleted: lastCompletion?.lessonCompleted ?? false,
        nextLessonId: lastCompletion?.nextLessonId,
      );
    }
    final r = resources[i];
    final route = _routeFor(r, lessonId: lessonId, resourceIndex: i);
    if (route == null) continue;

    // Background-warm the NEXT upcoming activity (if any) while the
    // current resource plays. No await.
    final nextActivityId = _peekNextActivityId(resources, i);
    if (nextActivityId != null) {
      _kickoffPrecache(context, nextActivityId);
    }

    // For an activity we're ABOUT to push: if precache hasn't already
    // been kicked off by an earlier look-ahead, fire it now and wait —
    // otherwise the activity opens against cold S3.
    if (r.type == 'activity' &&
        r.activityId != null &&
        r.activityId!.isNotEmpty &&
        !_precachingFor.containsKey(r.activityId)) {
      await _kickoffPrecache(context, r.activityId!);
    }

    launchedAny = true;
    lastIndexEntered = i;
    // Telemetry on the resource being pushed — paired with the
    // resource_completed mirror that fires after the pop (we already
    // POST progress; the event is just the analytics-side echo).
    HowwowEventLogger.instance.log(
      HowwowEvents.resourceStarted,
      props: {
        'lesson_id': lessonId,
        'resource_index': i,
        'type': r.type,
      },
    );
    // State-side start write (distinct from the analytics event above —
    // events are a lossy telemetry queue; this writes `startedAt` /
    // `lastResourceStartedIndex` on the server's progress doc so the
    // home card can say "Resume Episode 3 — step 2 of 3" even when no
    // resource has COMPLETED yet). Fire-and-forget: a lost write costs
    // nudge/copy precision, never progress.
    if (lessonId != null && lessonId.isNotEmpty) {
      unawaited(_postStart(lessonId, i, r.type));
    }
    final result = await Navigator.of(context).push(route);

    // Pop-result protocol:
    //   • media screens (video/image) pop `true` when they FINISH (video
    //     ended, Skip tapped, image timed out or was tapped). A confirmed
    //     leave on a video pops `false`; a system-back on an image pops
    //     null — both count as a back-out.
    //   • activities are oblivious to lessons and complete by calling
    //     Navigator.maybePop() (no result) from their success screens.
    //     Both "finished the activity" and "system back" route through
    //     maybePop identically, so we CAN'T distinguish them here — any
    //     activity pop counts as completion, same as before the lesson
    //     runner existed. (A leave-confirm for activities would need each
    //     activity to pop its completion via an unconditional
    //     Navigator.pop() so a guarded back could differ — see git note.)
    // Backing out of a media screen means "leave the lesson" — stop
    // pushing further resources and do NOT mark this one complete, so the
    // next open resumes right here.
    final finished = r.type == 'activity' || result == true;
    if (!finished) {
      backedOut = true;
      break;
    }

    // Queue the completion POST onto the serial chain (see the chain's
    // declaration above for why ordering matters). Capture idx/type so the
    // closure doesn't depend on the loop cursor. _postCompletion swallows
    // its own errors and never throws, so the chain can't break.
    if (lessonId != null && lessonId.isNotEmpty) {
      final lid = lessonId;
      final idx = i;
      final type = r.type;
      completionChain = completionChain.then((_) async {
        final resp = await _postCompletion(lid, idx, type);
        if (resp != null) lastCompletion = resp;
      });
    }
  }

  // Wait for every queued completion POST to land before returning. This
  // preserves the old "final resource is awaited" guarantee — by the time
  // openLesson returns, the server has marked the lesson complete and
  // advanced currentLessonId — so the profession-detail reload that fires
  // next reads the unlocked state instead of racing an in-flight write.
  await completionChain;
  // If the user back-popped out of a resource (any index, including the
  // final one) or we never reached the final index, the lesson run ended
  // early — fire lesson_abandoned with the last resource they saw so we
  // can map drop-off by index.
  if (lessonId != null &&
      lastIndexEntered != null &&
      (backedOut || lastIndexEntered < resources.length - 1)) {
    HowwowEventLogger.instance.logImmediate(
      HowwowEvents.lessonAbandoned,
      props: {
        'lesson_id': lessonId,
        'last_resource_index': lastIndexEntered,
        'total_resources': resources.length,
      },
    );
  }
  // ignore: avoid_print
  print('[howwow-lesson] openLesson ✓ lesson=$lessonId '
      'launchedAny=$launchedAny lastIndex=$lastIndexEntered '
      'completed=${lastCompletion?.lessonCompleted ?? false} '
      'next=${lastCompletion?.nextLessonId}');
  return LessonRunResult(
    launchedAny: launchedAny,
    lessonCompleted: lastCompletion?.lessonCompleted ?? false,
    nextLessonId: lastCompletion?.nextLessonId,
  );
}

/// Per-call dedupe map: activityId → Future of the precache pass started
/// for it. Cleared implicitly when the lesson ends and this function
/// returns — a new openLesson() call starts fresh, which is the right
/// scope (Flutter's ImageCache keeps the actual bytes around across
/// sessions anyway).
final Map<String, Future<void>> _precachingFor = {};

Future<void> _kickoffPrecache(BuildContext context, String activityId) {
  return _precachingFor.putIfAbsent(activityId, () {
    // Images warm Flutter's ImageCache; audio downloads to the app cache
    // dir (see s3_audio.dart) so Orbit VO/SFX play with file-local latency.
    // Both fan out over the network, so run them together.
    return Future.wait([
      precacheActivityImages(context, activityId),
      precacheActivityAudio(activityId),
    ]);
  });
}

/// Return the activityId of the NEXT activity resource after [fromIndex],
/// skipping intervening videos/images. Returns null if there is no
/// upcoming activity (the lesson is just media).
String? _peekNextActivityId(List<HowwowLessonResource> resources, int fromIndex) {
  for (int j = fromIndex + 1; j < resources.length; j++) {
    final r = resources[j];
    if (r.type == 'activity' && r.activityId != null && r.activityId!.isNotEmpty) {
      return r.activityId;
    }
  }
  return null;
}

/// Build a MaterialPageRoute for a single resource, or null if the resource
/// can't be played (unknown activity id, malformed entry, etc.).
///
/// Routes are typed `<bool>` for the pop-result protocol: media screens
/// pop `true` on finish, null on back-out (see the loop in openLesson).
MaterialPageRoute<bool>? _routeFor(HowwowLessonResource r,
    {String? lessonId, int? resourceIndex}) {
  switch (r.type) {
    case 'video':
      final url = r.url;
      if (url == null || url.isEmpty) return null;
      return MaterialPageRoute<bool>(
        builder: (_) => MissionVideoScreen(
          source: url,
          lessonId: lessonId,
          resourceIndex: resourceIndex,
          // Letterbox-fit so a 9:16 video shows entirely on a 9:21 phone
          // (black bars top + bottom) instead of cropping the edges —
          // important for intro/outro frames that touch the canvas edges.
          fit: BoxFit.contain,
        ),
      );
    case 'image':
      final url = r.url;
      if (url == null || url.isEmpty) return null;
      final secs = r.durationSeconds;
      return MaterialPageRoute<bool>(
        builder: (_) => LessonImageScreen(
          source: url,
          autoAdvanceAfter:
              (secs != null && secs > 0) ? Duration(seconds: secs) : null,
          caption: r.caption,
        ),
      );
    case 'activity':
      final widget = buildActivityScreen(r.activityId);
      if (widget == null) return null;
      // No leave-confirm wrapper here: activities finish via
      // Navigator.maybePop() from their success screens, which a
      // PopScope(canPop:false) guard would intercept — making the
      // "Continue" button open the leave dialog and trap the user (the
      // exact bug this replaced). Activities just pop = done.
      return MaterialPageRoute<bool>(builder: (_) => widget);
    default:
      return null;
  }
}

/// True once a resource-start POST has come back 404 this session —
/// meaning the backend hasn't deployed the /start endpoint yet. Skip
/// further start writes until the next app launch instead of spamming
/// a dead route on every resource push.
bool _startEndpointMissing = false;

/// Fire-and-forget mirror of [_postCompletion] for the resource-start
/// write. Failures are logged and dropped; a 404 latches
/// [_startEndpointMissing] so we stop calling a route that doesn't exist.
Future<void> _postStart(String lessonId, int index, String type) async {
  if (_startEndpointMissing) return;
  try {
    await howwowMarkResourceStarted(
      lessonId: lessonId,
      resourceIndex: index,
      type: type,
    );
    // ignore: avoid_print
    print('[howwow-lesson] START ✓ lesson=$lessonId idx=$index type=$type');
  } on ApiException catch (e) {
    if (e.statusCode == 404) {
      _startEndpointMissing = true;
      // ignore: avoid_print
      print('[howwow-lesson] START endpoint 404 — backend not deployed '
          'yet, suppressing start writes for this session');
      return;
    }
    // ignore: avoid_print
    print('[howwow-lesson] START ✗ lesson=$lessonId idx=$index error=$e');
  } catch (e) {
    // ignore: avoid_print
    print('[howwow-lesson] START ✗ lesson=$lessonId idx=$index error=$e');
  }
}

/// Wrap the completion API call. Returns the server response on success
/// (used to detect lesson completion + next-lesson id) or null on error —
/// errors are logged and dropped, since the next
/// /career/professions/{id}/detail load re-derives progress from the
/// server's authoritative state.
///
/// Heavy diagnostic logging on every transition so we can pinpoint the
/// bug if the unlock chain doesn't advance on device. Grep adb logcat
/// for `[howwow-lesson]` to see the full POST sequence.
Future<HowwowResourceCompleteResponse?> _postCompletion(
    String lessonId, int index, String type) async {
  // ignore: avoid_print
  print('[howwow-lesson] POST → lesson=$lessonId idx=$index type=$type');
  final stopwatch = Stopwatch()..start();
  try {
    final resp = await howwowMarkResourceCompleted(
      lessonId: lessonId,
      resourceIndex: index,
      type: type,
    );
    stopwatch.stop();
    // ignore: avoid_print
    print('[howwow-lesson] POST ✓ lesson=$lessonId idx=$index '
        '(${stopwatch.elapsedMilliseconds}ms) '
        'lessonCompleted=${resp.lessonCompleted} '
        'next=${resp.nextLessonId} '
        'completedIndices=${resp.resourcesCompleted}');
    return resp;
  } catch (e) {
    stopwatch.stop();
    // ignore: avoid_print
    print('[howwow-lesson] POST ✗ lesson=$lessonId idx=$index '
        '(${stopwatch.elapsedMilliseconds}ms) error=$e');
    return null;
  }
}
