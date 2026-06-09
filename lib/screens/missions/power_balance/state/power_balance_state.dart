// Immutable state for the Power Balance Challenge. The controller owns the single
// mutable instance and hands out copies via copyWith; the Flutter overlays AND
// the Flame game both read from it. Nothing here knows about widgets or Flame.

import 'package:flutter/foundation.dart';

import '../models/power_balance_models.dart';

@immutable
class PowerBalanceState {
  const PowerBalanceState({
    this.phase = MissionPhase.intro,
    this.batteryPercent = 18.0,
    this.imagesCaptured = 0,
    this.dataSent = 0,
    this.orbitProgress = 0.0,
    this.orbitLap = 0,
    this.currentZone = OrbitZone.sunlight,
    this.solarAlign = SolarAlignState.misaligned,
    this.isCharging = false,
    this.cameraOn = false,
    this.antennaOn = false,
    this.capturing = false,
    this.sending = false,
    this.controlHint = ControlHint.none,
    this.helperMessage = '',
    this.mascot = MascotMood.neutral,
    this.batteryWarning = false,
    this.hintLevel = 0,
    // transient FX tokens — bump (not toggle) to fire a one-shot effect so a
    // wrong-action pulse can re-fire without a reset (playbook pattern).
    this.captureToken = 0,
    this.sendToken = 0,
    this.warnToken = 0,
    this.thrusterToken = 0,
    this.chargeBurstToken = 0,
    this.feedbackToken = 0,
    this.feedbackBadge = FeedbackBadge.none,
    this.transmitDoneToken = 0,
    this.lowPowerAlertToken = 0,
    this.voiceClip = 0,
    this.voiceToken = 0,
  });

  final MissionPhase phase;

  // simulation
  final double batteryPercent; // 0..100
  final int imagesCaptured;
  final int dataSent;
  final double orbitProgress; // 0..1 looping
  final int orbitLap;
  final OrbitZone currentZone;

  // systems
  final SolarAlignState solarAlign;
  final bool isCharging; // battery actively rising from solar
  final bool cameraOn;
  final bool antennaOn;
  final bool capturing; // mid capture beat
  final bool sending; // mid transmission beat

  // guidance / feedback
  final ControlHint controlHint;
  final String helperMessage;
  final MascotMood mascot;
  final bool batteryWarning;
  final int hintLevel;

  // transient FX triggers
  final int captureToken;
  final int sendToken;
  final int warnToken;
  final int thrusterToken;
  final int chargeBurstToken;

  // one-shot achievement/feedback badge pop (bump token to fire)
  final int feedbackToken;
  final FeedbackBadge feedbackBadge;

  /// Bumps when a data transmission FINISHES (drives the "Data Received" pills).
  final int transmitDoneToken;

  /// Bumps when the battery first drops below the low threshold (drives the
  /// "systems shutting down" alert). The camera is locked while battery is low.
  final int lowPowerAlertToken;

  /// Orbit voice: the clip to speak (orbit_NN) + a token that bumps whenever a
  /// new line should play. The screen plays on token change (clip number alone
  /// can repeat). Stamped by the controller's message choke point.
  final int voiceClip;
  final int voiceToken;

  /// Camera can't take pictures when the battery is low (it's a non-critical
  /// system that shuts down to conserve power).
  bool get cameraLocked => batteryPercent <= 25.0;

  // ── derived ──────────────────────────────────────────────────────────────
  int get unsentImages => imagesCaptured - dataSent;
  bool get isPlaying =>
      phase != MissionPhase.intro &&
      phase != MissionPhase.success &&
      phase != MissionPhase.failure;
  bool get isCritical => batteryPercent <= 10.0 && batteryPercent > 0;
  bool get isLow => batteryPercent <= 25.0;

  PowerBalanceState copyWith({
    MissionPhase? phase,
    double? batteryPercent,
    int? imagesCaptured,
    int? dataSent,
    double? orbitProgress,
    int? orbitLap,
    OrbitZone? currentZone,
    SolarAlignState? solarAlign,
    bool? isCharging,
    bool? cameraOn,
    bool? antennaOn,
    bool? capturing,
    bool? sending,
    ControlHint? controlHint,
    String? helperMessage,
    MascotMood? mascot,
    bool? batteryWarning,
    int? hintLevel,
    int? captureToken,
    int? sendToken,
    int? warnToken,
    int? thrusterToken,
    int? chargeBurstToken,
    int? feedbackToken,
    FeedbackBadge? feedbackBadge,
    int? transmitDoneToken,
    int? lowPowerAlertToken,
    int? voiceClip,
    int? voiceToken,
  }) {
    return PowerBalanceState(
      phase: phase ?? this.phase,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      imagesCaptured: imagesCaptured ?? this.imagesCaptured,
      dataSent: dataSent ?? this.dataSent,
      orbitProgress: orbitProgress ?? this.orbitProgress,
      orbitLap: orbitLap ?? this.orbitLap,
      currentZone: currentZone ?? this.currentZone,
      solarAlign: solarAlign ?? this.solarAlign,
      isCharging: isCharging ?? this.isCharging,
      cameraOn: cameraOn ?? this.cameraOn,
      antennaOn: antennaOn ?? this.antennaOn,
      capturing: capturing ?? this.capturing,
      sending: sending ?? this.sending,
      controlHint: controlHint ?? this.controlHint,
      helperMessage: helperMessage ?? this.helperMessage,
      mascot: mascot ?? this.mascot,
      batteryWarning: batteryWarning ?? this.batteryWarning,
      hintLevel: hintLevel ?? this.hintLevel,
      captureToken: captureToken ?? this.captureToken,
      sendToken: sendToken ?? this.sendToken,
      warnToken: warnToken ?? this.warnToken,
      thrusterToken: thrusterToken ?? this.thrusterToken,
      chargeBurstToken: chargeBurstToken ?? this.chargeBurstToken,
      feedbackToken: feedbackToken ?? this.feedbackToken,
      feedbackBadge: feedbackBadge ?? this.feedbackBadge,
      transmitDoneToken: transmitDoneToken ?? this.transmitDoneToken,
      lowPowerAlertToken: lowPowerAlertToken ?? this.lowPowerAlertToken,
      voiceClip: voiceClip ?? this.voiceClip,
      voiceToken: voiceToken ?? this.voiceToken,
    );
  }
}
