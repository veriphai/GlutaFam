// No-op analytics (PRD §26). Calls are wired at the real event points; swap the
// bodies for a real tracker later without touching callers (mirrors the
// Restore Earth / How Much Can You See pattern).

import 'package:flutter/foundation.dart';

import '../models/satellite_type.dart';

class ChooseSatelliteAnalytics {
  const ChooseSatelliteAnalytics();

  static const String activityId = 'choose_right_satellite';
  static const int episode = 5;

  void _log(String event, [Map<String, Object?> props = const {}]) {
    if (kDebugMode) {
      debugPrint('[analytics] $event ${{'activity_id': activityId, 'episode': episode, ...props}}');
    }
  }

  void activityStarted() => _log('choose_satellite_activity_started');

  void missionStarted(String missionId) =>
      _log('choose_satellite_mission_started', {'mission_id': missionId});

  void dragStarted(String missionId, SatelliteType type) => _log(
      'choose_satellite_drag_started',
      {'mission_id': missionId, 'selected_satellite_type': type.id});

  void dropCorrect(String missionId, SatelliteType type, int wrongAttempts) => _log(
      'choose_satellite_drop_correct', {
        'mission_id': missionId,
        'selected_satellite_type': type.id,
        'wrong_attempt_count': wrongAttempts,
      });

  void dropWrong(String missionId, SatelliteType selected, SatelliteType correct,
          int wrongAttempts) =>
      _log('choose_satellite_drop_wrong', {
        'mission_id': missionId,
        'selected_satellite_type': selected.id,
        'correct_satellite_type': correct.id,
        'wrong_attempt_count': wrongAttempts,
      });

  void hintShown(String missionId, int hintLevel) =>
      _log('choose_satellite_hint_shown', {'mission_id': missionId, 'hint_level': hintLevel});

  void missionCompleted(String missionId, int wrongAttempts) => _log(
      'choose_satellite_mission_completed',
      {'mission_id': missionId, 'wrong_attempt_count': wrongAttempts});

  void activityCompleted(int totalWrong) =>
      _log('choose_satellite_activity_completed', {'total_wrong': totalWrong});

  void nextActivityClicked() => _log('choose_satellite_next_activity_clicked',
      {'next_activity': 'power_up_the_satellite'});
}
