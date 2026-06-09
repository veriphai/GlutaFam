// No-op analytics for the Earth Detective activity. Events are logged in debug
// so the call sites are real; swap the body for a tracker later without touching
// callers (same shape as the other activities).

import 'package:flutter/foundation.dart';

class EdAnalytics {
  EdAnalytics._();

  static void _log(String event, [Map<String, Object?> props = const {}]) {
    if (kDebugMode) debugPrint('[earth_detective] $event ${props.isEmpty ? '' : props}');
  }

  static void activityStarted() => _log('activity_started');
  static void tutorialDone() => _log('tutorial_done');
  static void missionOpened(String id) => _log('mission_opened', {'id': id});
  static void clueFound(String id, int wrongAttempts, int hintLevel) =>
      _log('clue_found', {'id': id, 'wrong': wrongAttempts, 'hint': hintLevel});
  static void wrongTap(String id, int attempt) => _log('wrong_tap', {'id': id, 'attempt': attempt});
  static void hintShown(String id, int level) => _log('hint_shown', {'id': id, 'level': level});
  static void allCluesFound() => _log('all_clues_found');
  static void rewardShown() => _log('reward_shown');
  static void backToMap() => _log('back_to_map');
}
