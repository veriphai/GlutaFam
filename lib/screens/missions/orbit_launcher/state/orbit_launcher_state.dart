// Immutable snapshot of Activity 3 V2 (Orbit Launcher — launch from Earth).
//
// V2 flow: launchpad → straight-up fails → tilt unlocked → set Launch Power +
// Tilt Angle → mission launch → one of five outcomes → orbit success → bridge.

import 'package:flutter/foundation.dart';

/// The PRD V2 state machine that drives both the UI and the Flame stage.
enum OrbitActivityState {
  missionBrief, // mission-control window start screen → START MISSION
  missionGoal, // goal + orbit definition card → LET'S LAUNCH
  launchpadIntro, // rocket on pad, LAUNCH
  straightLaunchAnimating, // rocket goes straight up + falls back
  straightLaunchFailed, // "Oops! It fell back." → GOT IT
  tiltUnlocked, // "New Control Unlocked!" panel → GOT IT!
  challengeReady, // Launch Power + Tilt Angle sliders + LAUNCH MISSION
  missionLaunching, // outcome animation playing
  notEnoughPower,
  tooStraight,
  tooMuchTilt,
  tooFast,
  almost,
  orbitLocked,
  nextActivityBridge, // orbiting empty satellite + part icons
}

/// The six launch outcomes (thresholds in orbit_tuning.dart). "almost" is a
/// near-miss ring just outside the success zone.
enum OrbitOutcome { notEnoughPower, tooStraight, tooMuchTilt, tooFast, almost, orbitLocked }

/// Which Mission-Control character sprite + tone to show.
enum McMood { happy, thinking, celebrating }

@immutable
class OrbitLauncherState {
  final OrbitActivityState scene;
  final double launchPower; // 0..100
  final double tiltAngle; // 0..100
  final int attemptCount; // LAUNCH MISSION presses
  final OrbitOutcome? lastOutcome; // drives the result card
  final McMood mascot;
  final String bubbleText; // Mission-Control speech-bubble line
  final bool tiltUnlocked; // becomes true after the straight-up failure
  final bool voicePlaying; // Orbit is narrating — primary buttons dim/wait

  const OrbitLauncherState({
    required this.scene,
    required this.launchPower,
    required this.tiltAngle,
    required this.attemptCount,
    required this.lastOutcome,
    required this.mascot,
    required this.bubbleText,
    required this.tiltUnlocked,
    this.voicePlaying = false,
  });

  // ── derived ────────────────────────────────────────────────────────────────
  bool get isAnimating =>
      scene == OrbitActivityState.straightLaunchAnimating ||
      scene == OrbitActivityState.missionLaunching;

  bool get isFailOutcome =>
      scene == OrbitActivityState.notEnoughPower ||
      scene == OrbitActivityState.tooStraight ||
      scene == OrbitActivityState.tooMuchTilt ||
      scene == OrbitActivityState.tooFast ||
      scene == OrbitActivityState.almost;

  bool get isOutcome => isFailOutcome || scene == OrbitActivityState.orbitLocked;

  bool get controlsEnabled => !isAnimating;

  OrbitLauncherState copyWith({
    OrbitActivityState? scene,
    double? launchPower,
    double? tiltAngle,
    int? attemptCount,
    Object? lastOutcome = _keep,
    McMood? mascot,
    String? bubbleText,
    bool? tiltUnlocked,
    bool? voicePlaying,
  }) {
    return OrbitLauncherState(
      scene: scene ?? this.scene,
      launchPower: launchPower ?? this.launchPower,
      tiltAngle: tiltAngle ?? this.tiltAngle,
      attemptCount: attemptCount ?? this.attemptCount,
      lastOutcome: lastOutcome == _keep ? this.lastOutcome : lastOutcome as OrbitOutcome?,
      mascot: mascot ?? this.mascot,
      bubbleText: bubbleText ?? this.bubbleText,
      tiltUnlocked: tiltUnlocked ?? this.tiltUnlocked,
      voicePlaying: voicePlaying ?? this.voicePlaying,
    );
  }

  static const Object _keep = Object();
}
