// No-op analytics for Save the Coastal City — implements the PRD §25 event
// spec as debug logs, wired at the real call points by the controller. Swap
// the bodies for a real tracker later without touching callers.

import 'package:flutter/foundation.dart';

class SccAnalytics {
  SccAnalytics._();

  static void _log(String event, [Map<String, Object?> params = const {}]) {
    if (kDebugMode) debugPrint('[scc-analytics] $event $params');
  }

  static void finalMissionStarted() => _log('final_mission_started');

  static void stageStarted(String stageId) => _log('stage_started', {'stage_id': stageId});

  static void stageCompleted(String stageId, int attempts, int durationMs) =>
      _log('stage_completed',
          {'stage_id': stageId, 'attempts': attempts, 'duration_ms': durationMs});

  static void stageMistake(String stageId, String mistakeType) =>
      _log('stage_mistake', {'stage_id': stageId, 'mistake_type': mistakeType});

  static void hintShown(String stageId, int hintLevel) =>
      _log('hint_shown', {'stage_id': stageId, 'hint_level': hintLevel});

  static void badgeUnlocked(String badgeId) => _log('badge_unlocked', {'badge_id': badgeId});

  static void finalMissionCompleted(int totalDurationMs, int totalAttempts) =>
      _log('final_mission_completed',
          {'total_duration_ms': totalDurationMs, 'total_attempts': totalAttempts});
}
