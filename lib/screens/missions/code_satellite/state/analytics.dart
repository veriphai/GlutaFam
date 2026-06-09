// No-op analytics for Code the Satellite — debug logs at the real event points
// (PRD §20-style instrumentation). Swap the bodies for a real tracker later
// without touching callers.

import 'package:flutter/foundation.dart';

import '../models/satellite_command.dart';

class CSAnalytics {
  CSAnalytics._();

  static void _log(String event, [Map<String, Object?> props = const {}]) {
    if (kDebugMode) debugPrint('[code_satellite] $event ${props.isEmpty ? '' : props}');
  }

  static void activityStarted() => _log('activity_started');
  static void missionBriefShown() => _log('mission_brief_shown');
  static void arrangingStarted() => _log('arranging_started');
  static void blockPlaced(SatelliteCommand c, int slot) =>
      _log('block_placed', {'command': c.name, 'slot': slot});
  static void blockRemoved(SatelliteCommand c) => _log('block_removed', {'command': c.name});
  static void runPressed(List<SatelliteCommand> seq) =>
      _log('run_pressed', {'sequence': seq.map((c) => c.name).toList()});
  static void stepSucceeded(SatelliteCommand c, int i) =>
      _log('step_succeeded', {'command': c.name, 'step': i});
  static void missionFailed(SatelliteCommand c, int i, String reason) =>
      _log('mission_failed', {'command': c.name, 'step': i, 'reason': reason});
  static void missionSucceeded(int attempts) => _log('mission_succeeded', {'attempts': attempts});
  static void reorderPressed() => _log('reorder_pressed');
  static void playAgain() => _log('play_again');
  static void nextMission() => _log('next_mission');
}
