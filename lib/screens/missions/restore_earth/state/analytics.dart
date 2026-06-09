// No-op analytics (PRD §32). Calls are wired at the real event points now; swap
// the bodies for a real tracker (Firebase/Singular/etc.) later without touching
// callers.

import 'package:flutter/foundation.dart';

class RestoreEarthAnalytics {
  const RestoreEarthAnalytics();

  static const String activityId = 'satellite_superpowers_restore_earth';
  static const String episodeId = 'satellite_engineer_ep1';

  void _log(String event, [Map<String, Object?> props = const {}]) {
    // TODO: forward to the real analytics pipeline.
    if (kDebugMode) debugPrint('[analytics] $event $props');
  }

  void activityStarted() =>
      _log('activity_started', {'activityId': activityId, 'episodeId': episodeId});

  void scenarioSpawned(String scenarioId, int round) =>
      _log('scenario_spawned', {'scenarioId': scenarioId, 'round': round});

  void powerSelected(String scenarioId, String selectedPower) =>
      _log('power_selected', {'scenarioId': scenarioId, 'selectedPower': selectedPower});

  void beamReleased(String scenarioId, String selectedPower, bool targetHit) => _log(
      'beam_released',
      {'scenarioId': scenarioId, 'selectedPower': selectedPower, 'targetHit': targetHit});

  void wrongPowerUsed(
          String scenarioId, String selectedPower, String correctPower, int attemptNo) =>
      _log('wrong_power_used', {
        'scenarioId': scenarioId,
        'selectedPower': selectedPower,
        'correctPower': correctPower,
        'attemptNo': attemptNo,
      });

  void scenarioCompleted(String scenarioId, int attempts, int timeSpentMs) => _log(
      'scenario_completed',
      {'scenarioId': scenarioId, 'attempts': attempts, 'timeSpentMs': timeSpentMs});

  void hintShown(String scenarioId, int hintLevel) =>
      _log('hint_shown', {'scenarioId': scenarioId, 'hintLevel': hintLevel});

  void activityCompleted(int totalTimeMs, int totalWrongAttempts) => _log(
      'activity_completed',
      {'totalTimeMs': totalTimeMs, 'totalWrongAttempts': totalWrongAttempts});

  void nextMissionClicked(String nextEpisodeId) =>
      _log('next_mission_clicked', {'episodeId': episodeId, 'nextEpisodeId': nextEpisodeId});
}
