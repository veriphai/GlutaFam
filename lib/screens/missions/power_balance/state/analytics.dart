// No-op analytics for the Power Balance Challenge — the spec's events as debug
// logs, wired at the real call sites. Swap the bodies for a real tracker later
// without touching callers (playbook pattern).

import 'package:flutter/foundation.dart';

class PowerBalanceAnalytics {
  const PowerBalanceAnalytics();

  void _log(String event, [Map<String, Object?> data = const {}]) {
    if (kDebugMode) debugPrint('[power_balance] $event ${data.isEmpty ? '' : data}');
  }

  void missionStarted() => _log('mission_started');
  void solarCharged(double battery) => _log('solar_charged', {'battery': battery});
  void imageCaptured(int count) => _log('image_captured', {'count': count});
  void wrongCameraUse() => _log('wrong_camera_use');
  void dataSent(int count) => _log('data_sent', {'count': count});
  void wrongAntennaUse() => _log('wrong_antenna_use');
  void enteredShadow() => _log('entered_shadow');
  void thrusterFired(double battery) => _log('thruster_fired', {'battery': battery});
  void missionCompleted() => _log('mission_completed');
  void missionFailed() => _log('mission_failed');
  void retried() => _log('retried');
  void hintShown(int level) => _log('hint_shown', {'level': level});
}
