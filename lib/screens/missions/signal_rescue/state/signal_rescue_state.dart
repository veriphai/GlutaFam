// Immutable state for Signal Rescue. The controller owns the single mutable
// instance and hands out copies via copyWith; the Flutter overlays + the Flame
// game both read from it. Nothing here knows about widgets or Flame.

import 'package:flutter/foundation.dart';

enum MissionPhase {
  intro,
  explainParts,
  alignAntenna,
  waitForRange,
  checkPower,
  dataLocked,
  transmitting,
  success,
  failed,
}

enum SignalState { noSignal, weak, strong, locked }

/// Helper-robot mood, mapped to a mascot sprite by the helper card.
enum MascotMood { idle, explaining, alert, happy, celebrate }

@immutable
class SignalRescueState {
  const SignalRescueState({
    this.phase = MissionPhase.intro,
    this.signalState = SignalState.noSignal,
    this.antennaAngle = 0,
    this.targetAngle = 0,
    this.angleDifference = 180,
    this.isGroundStationInRange = false,
    this.signalStrength = 0,
    this.batteryLevel = 85,
    this.canTransmit = false,
    this.isTransmitting = false,
    this.transmissionProgress = 0,
    this.monitorRevealProgress = 0,
    this.stormEnabled = false,
    this.stormTimerProgress = 0,
    this.explainStep = 0,
    this.helperMessage = '',
    this.mascot = MascotMood.idle,
    this.batteryWarning = false,
    this.missionCompleted = false,
    this.hintLevel = 0,
    this.voiceClip = 0,
    this.voiceToken = 0,
    this.voicePlaying = false,
  });

  final MissionPhase phase;
  final SignalState signalState;

  /// Antenna direction in degrees (0 = pointing right, increases CW on screen).
  final double antennaAngle;
  final double targetAngle;
  final double angleDifference; // shortest distance, 0..180
  final bool isGroundStationInRange;
  final double signalStrength; // 0..1, for the meter fill

  final double batteryLevel; // 0..100
  final bool canTransmit;
  final bool isTransmitting;
  final double transmissionProgress; // 0..1
  final double monitorRevealProgress; // 0..1

  final bool stormEnabled;
  final double stormTimerProgress; // 0..1 (1 = time's up)

  final int explainStep; // 0..2 during explainParts
  final String helperMessage;
  final MascotMood mascot;
  final bool batteryWarning;
  final bool missionCompleted;
  final int hintLevel; // 0 = none; escalates with idle / failed taps

  /// Orbit voice: which clip to play + a token BUMPED on every (re)trigger —
  /// the screen plays whenever the token differs from its last-seen value
  /// (clip equality alone would swallow back-to-back identical lines).
  final int voiceClip;
  final int voiceToken;
  /// True while a clip is playing — primary CTAs (Start/Continue) gate on it.
  final bool voicePlaying;

  bool get controlsLive =>
      phase == MissionPhase.alignAntenna ||
      phase == MissionPhase.waitForRange ||
      phase == MissionPhase.checkPower ||
      phase == MissionPhase.dataLocked;

  SignalRescueState copyWith({
    MissionPhase? phase,
    SignalState? signalState,
    double? antennaAngle,
    double? targetAngle,
    double? angleDifference,
    bool? isGroundStationInRange,
    double? signalStrength,
    double? batteryLevel,
    bool? canTransmit,
    bool? isTransmitting,
    double? transmissionProgress,
    double? monitorRevealProgress,
    bool? stormEnabled,
    double? stormTimerProgress,
    int? explainStep,
    String? helperMessage,
    MascotMood? mascot,
    bool? batteryWarning,
    bool? missionCompleted,
    int? hintLevel,
    int? voiceClip,
    int? voiceToken,
    bool? voicePlaying,
  }) {
    return SignalRescueState(
      phase: phase ?? this.phase,
      signalState: signalState ?? this.signalState,
      antennaAngle: antennaAngle ?? this.antennaAngle,
      targetAngle: targetAngle ?? this.targetAngle,
      angleDifference: angleDifference ?? this.angleDifference,
      isGroundStationInRange: isGroundStationInRange ?? this.isGroundStationInRange,
      signalStrength: signalStrength ?? this.signalStrength,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      canTransmit: canTransmit ?? this.canTransmit,
      isTransmitting: isTransmitting ?? this.isTransmitting,
      transmissionProgress: transmissionProgress ?? this.transmissionProgress,
      monitorRevealProgress: monitorRevealProgress ?? this.monitorRevealProgress,
      stormEnabled: stormEnabled ?? this.stormEnabled,
      stormTimerProgress: stormTimerProgress ?? this.stormTimerProgress,
      explainStep: explainStep ?? this.explainStep,
      helperMessage: helperMessage ?? this.helperMessage,
      mascot: mascot ?? this.mascot,
      batteryWarning: batteryWarning ?? this.batteryWarning,
      missionCompleted: missionCompleted ?? this.missionCompleted,
      hintLevel: hintLevel ?? this.hintLevel,
      voiceClip: voiceClip ?? this.voiceClip,
      voiceToken: voiceToken ?? this.voiceToken,
      voicePlaying: voicePlaying ?? this.voicePlaying,
    );
  }
}
