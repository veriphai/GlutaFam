// Immutable snapshot of the mission (PRD §11). The controller swaps a new
// instance on every change; widgets + the Flame game read from it.

import 'package:flutter/foundation.dart';

/// Mascot pose, selected by the controller per event so the right Orbit sprite
/// shows for what's happening.
enum MascotMood { welcoming, guiding, happy, concerned, thinking, celebrating }

@immutable
class BuildSatelliteMissionState {
  final int currentStep; // 1..7
  final Set<String> installedParts; // part ids
  final bool launchPreviewUnlocked;
  final double powerLevel; // 0..100
  final double signalLevel; // 0..100
  final double stabilityLevel; // 0..100
  final String highlightedPartId; // next part the child should place ('' = none)
  final String helperMessage; // mascot copy

  final bool hintActive; // idle nudge -> pulse active part/slot
  final bool launching; // launch-preview sequence in progress
  final bool rewardVisible; // reward popup shown
  final MascotMood mood; // which Orbit pose to show

  /// Orbit voice clip to play right now (1..59) — maps to
  /// `assets/sounds/build_satellite/orbit/orbit_NN.wav`. Null = silence.
  final int? voiceClip;

  /// Increments every time a voice line should be (re)played, so the screen
  /// fires playback even when the same clip is set twice in a row.
  final int voiceToken;

  /// True once Orbit's reward-popup monologue (clips 58 + 59) has finished —
  /// the Continue CTA is dim/disabled until then.
  final bool continueEnabled;

  const BuildSatelliteMissionState({
    required this.currentStep,
    required this.installedParts,
    required this.launchPreviewUnlocked,
    required this.powerLevel,
    required this.signalLevel,
    required this.stabilityLevel,
    required this.highlightedPartId,
    required this.helperMessage,
    this.hintActive = false,
    this.launching = false,
    this.rewardVisible = false,
    this.mood = MascotMood.guiding,
    this.voiceClip,
    this.voiceToken = 0,
    this.continueEnabled = false,
  });

  bool get isComplete => launchPreviewUnlocked;

  BuildSatelliteMissionState copyWith({
    int? currentStep,
    Set<String>? installedParts,
    bool? launchPreviewUnlocked,
    double? powerLevel,
    double? signalLevel,
    double? stabilityLevel,
    String? highlightedPartId,
    String? helperMessage,
    bool? hintActive,
    bool? launching,
    bool? rewardVisible,
    MascotMood? mood,
    Object? voiceClip = _keep,
    int? voiceToken,
    bool? continueEnabled,
  }) {
    return BuildSatelliteMissionState(
      currentStep: currentStep ?? this.currentStep,
      installedParts: installedParts ?? this.installedParts,
      launchPreviewUnlocked: launchPreviewUnlocked ?? this.launchPreviewUnlocked,
      powerLevel: powerLevel ?? this.powerLevel,
      signalLevel: signalLevel ?? this.signalLevel,
      stabilityLevel: stabilityLevel ?? this.stabilityLevel,
      highlightedPartId: highlightedPartId ?? this.highlightedPartId,
      helperMessage: helperMessage ?? this.helperMessage,
      hintActive: hintActive ?? this.hintActive,
      launching: launching ?? this.launching,
      rewardVisible: rewardVisible ?? this.rewardVisible,
      mood: mood ?? this.mood,
      voiceClip: voiceClip == _keep ? this.voiceClip : voiceClip as int?,
      voiceToken: voiceToken ?? this.voiceToken,
      continueEnabled: continueEnabled ?? this.continueEnabled,
    );
  }

  static const Object _keep = Object();
}
