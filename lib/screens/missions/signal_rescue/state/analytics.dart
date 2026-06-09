// No-op analytics for Signal Rescue — the spec's events as debug logs, wired at
// the real call sites. Swap the bodies for a real tracker later without touching
// callers.

import 'package:flutter/foundation.dart';

class SignalRescueAnalytics {
  const SignalRescueAnalytics();

  void _log(String event, [Map<String, Object?> props = const {}]) {
    if (kDebugMode) debugPrint('[signal_rescue] $event ${props.isEmpty ? '' : props}');
  }

  void missionStarted() => _log('mission_started');
  void partsExplained() => _log('parts_explained');
  void antennaAligned(double diff) => _log('antenna_aligned', {'diff': diff.toStringAsFixed(1)});
  void enteredRange() => _log('entered_range');
  void dataLocked() => _log('data_locked');
  void sendAttemptBlocked(String reason) => _log('send_blocked', {'reason': reason});
  void transmissionStarted() => _log('transmission_started');
  void missionCompleted() => _log('mission_completed');
  void hintShown(int level) => _log('hint_shown', {'level': level});
}
