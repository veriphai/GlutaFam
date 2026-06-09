// Immutable snapshot of the activity (PRD §24/§30). The controller swaps a new
// instance on every change; the Flutter shell + Flame game read from it.

import 'package:flutter/foundation.dart';

import '../config/powers.dart';

/// Coarse phase that drives the shell (the fine PRD state machine is expressed
/// through the fields below + the game's own sequencing).
enum ActivityPhase { intro, playing, repairing, complete }

enum MascotMood { idle, hint, excited, celebrate, oops }

@immutable
class RestoreEarthState {
  final ActivityPhase phase;
  final int scenarioIndex; // 0..6
  final int solvedCount; // 0..7
  final PowerId? selectedPower;
  final int wrongAttempts; // for the current scenario
  final String missionText;
  final MascotMood mascot;

  /// The correct power pulses after repeated wrong tries (PRD §12.3 hintPulse).
  final PowerId? hintPulsePower;

  /// Bumped each time a wrong power fires; the matching button watches it to
  /// run a one-shot shake (PRD §12.3 wrongShake).
  final int wrongShakeToken;
  final PowerId? wrongShakePower;

  /// Orbit voice clip to play (1..54) — matches the bundled
  /// `assets/sounds/restore_earth/orbit/orbit_XX.wav`. Null means silence.
  final int? voiceClip;

  /// Increments every time a voice line should be (re)played, so the screen
  /// can fire even when the same clip is set twice in a row (e.g. wrong1
  /// triggered again after a different beat).
  final int voiceToken;

  /// True once Orbit's full closing monologue has finished — the Continue
  /// CTA is dim/disabled until then so kids don't skip the recap.
  final bool continueEnabled;

  const RestoreEarthState({
    required this.phase,
    required this.scenarioIndex,
    required this.solvedCount,
    required this.selectedPower,
    required this.wrongAttempts,
    required this.missionText,
    required this.mascot,
    this.hintPulsePower,
    this.wrongShakeToken = 0,
    this.wrongShakePower,
    this.voiceClip,
    this.voiceToken = 0,
    this.continueEnabled = false,
  });

  bool get isComplete => phase == ActivityPhase.complete;
  bool get reticleVisible => selectedPower != null && phase == ActivityPhase.playing;

  RestoreEarthState copyWith({
    ActivityPhase? phase,
    int? scenarioIndex,
    int? solvedCount,
    Object? selectedPower = _keep,
    int? wrongAttempts,
    String? missionText,
    MascotMood? mascot,
    Object? hintPulsePower = _keep,
    int? wrongShakeToken,
    Object? wrongShakePower = _keep,
    Object? voiceClip = _keep,
    int? voiceToken,
    bool? continueEnabled,
  }) {
    return RestoreEarthState(
      phase: phase ?? this.phase,
      scenarioIndex: scenarioIndex ?? this.scenarioIndex,
      solvedCount: solvedCount ?? this.solvedCount,
      selectedPower:
          selectedPower == _keep ? this.selectedPower : selectedPower as PowerId?,
      wrongAttempts: wrongAttempts ?? this.wrongAttempts,
      missionText: missionText ?? this.missionText,
      mascot: mascot ?? this.mascot,
      hintPulsePower:
          hintPulsePower == _keep ? this.hintPulsePower : hintPulsePower as PowerId?,
      wrongShakeToken: wrongShakeToken ?? this.wrongShakeToken,
      wrongShakePower:
          wrongShakePower == _keep ? this.wrongShakePower : wrongShakePower as PowerId?,
      voiceClip: voiceClip == _keep ? this.voiceClip : voiceClip as int?,
      voiceToken: voiceToken ?? this.voiceToken,
      continueEnabled: continueEnabled ?? this.continueEnabled,
    );
  }

  static const Object _keep = Object();
}
