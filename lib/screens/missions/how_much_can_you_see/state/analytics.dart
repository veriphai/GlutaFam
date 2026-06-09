// No-op analytics for Activity 2. Calls are wired at the real event points; swap
// the bodies for a real tracker later without touching callers (mirrors the
// Restore Earth pattern).

import 'package:flutter/foundation.dart';

import '../config/height_levels.dart';

class HowMuchAnalytics {
  const HowMuchAnalytics();

  static const String activityId = 'how_much_can_you_see';
  static const String episodeId = 'satellite_engineer_ep2';

  void _log(String event, [Map<String, Object?> props = const {}]) {
    if (kDebugMode) debugPrint('[analytics] $event $props');
  }

  void activityStarted() =>
      _log('activity_started', {'activityId': activityId, 'episodeId': episodeId});

  void viewTestStarted() => _log('view_test_started', {'activityId': activityId});

  void heightLevelViewed(ViewHeightLevel level) =>
      _log('height_level_viewed', {'level': level.name});

  void satelliteReached() => _log('satellite_reached', {'activityId': activityId});

  void challengeOpened() => _log('challenge_opened', {'activityId': activityId});

  void challengeAnswered(String option, bool correct, int attemptNo) => _log(
      'challenge_answered',
      {'option': option, 'correct': correct, 'attemptNo': attemptNo});

  void activityCompleted(int totalWrong) =>
      _log('activity_completed', {'activityId': activityId, 'totalWrong': totalWrong});

  void nextMissionClicked() =>
      _log('next_mission_clicked', {'episodeId': episodeId, 'nextEpisodeId': 'satellite_engineer_ep3'});
}
