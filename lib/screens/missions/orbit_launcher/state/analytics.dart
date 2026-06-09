// No-op analytics for Orbit Launcher V2: events as debug logs, wired at the real
// points. Swap the bodies for a real tracker later without touching callers.

import 'package:flutter/foundation.dart';

import 'orbit_launcher_state.dart';

class OrbitAnalytics {
  const OrbitAnalytics();

  void _log(String event, [Map<String, Object?> props = const {}]) {
    if (kDebugMode) debugPrint('[orbit_launcher] $event ${props.isEmpty ? '' : props}');
  }

  void activityStarted() => _log('activity_started');
  void straightLaunched() => _log('straight_launch');
  void straightFailed() => _log('straight_launch_failed');
  void tiltUnlocked() => _log('tilt_unlocked');
  void missionLaunched(int attempt, int power, int tilt) =>
      _log('mission_launch', {'attempt': attempt, 'power': power, 'tilt': tilt});
  void outcomeShown(OrbitOutcome o, int attempt) =>
      _log('outcome', {'outcome': o.name, 'attempt': attempt});
  void tryAgain(int attempt) => _log('try_again', {'attempt': attempt});
  void orbitLocked(int attempt, int power, int tilt) =>
      _log('orbit_locked', {'attempt': attempt, 'power': power, 'tilt': tilt});
  void bridgeShown() => _log('bridge_shown');
  void activityFinished() => _log('activity_finished');
}
