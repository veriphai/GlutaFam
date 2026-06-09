// Immutable state for the Earth Detective activity. A single [ChangeNotifier]
// owns one of these and swaps it via [copyWith]; the Flutter scenes and the
// Flame stage both read it. Nothing here mutates in place.

import 'package:flutter/widgets.dart';

/// Full-screen scenes routed by the shell's AnimatedSwitcher.
enum EdScene {
  intro, // launch / Mission Control
  tutorial, // how to play
  missionSelect, // progress list of 6 missions
  missionPlay, // satellite image investigation (Flame stage)
  missionImpact, // "why it matters" Mission Control card
  summary, // found all 6
  reward, // emotional payoff + Back to Map
}

/// Sub-phase while a mission is being played.
enum PlayPhase {
  investigating, // child is scanning / comparing
  resolving, // correct tap landed — flash + overlay reveal playing
  found, // clue locked; success banner + Continue
}

/// Scanner lens visual state.
enum ScannerState { idle, near, lock }

/// Which mascot pose + bubble tone to show.
enum MascotPose { explaining, curious, supportive, celebrating, proud }

@immutable
class EarthDetectiveState {
  const EarthDetectiveState({
    this.scene = EdScene.intro,
    this.missionIndex = 0,
    this.solvedMissions = const <int>{},
    this.phase = PlayPhase.investigating,
    this.scannerNorm = const Offset(0.5, 0.5),
    this.scannerActive = false,
    this.scannerState = ScannerState.idle,
    this.wrongAttempts = 0,
    this.hintLevel = 0,
    this.helperMessage,
    this.mascotPose = MascotPose.explaining,
    this.zoomLevel = 1.0,
    this.sliderNorm = 0.5,
    this.soundOn = true,
    this.successToken = 0,
    this.wrongToken = 0,
    this.sweepToken = 0,
    this.voiceClip,
    this.voiceToken = 0,
    this.voicePlaying = false,
  });

  final EdScene scene;
  final int missionIndex;
  final Set<int> solvedMissions;
  final PlayPhase phase;

  final Offset scannerNorm; // normalised image coords
  final bool scannerActive;
  final ScannerState scannerState;

  final int wrongAttempts;

  /// 0 = none, 1 = supportive, 2 = hint 1, 3 = hint 2 + quadrant pulse,
  /// 4+ = broad area glow (PRD §14.4).
  final int hintLevel;

  final String? helperMessage;
  final MascotPose mascotPose;

  final double zoomLevel; // 1.0 .. 2.4 (ship mission)
  final double sliderNorm; // before/after divider (0..1)

  final bool soundOn;

  // One-shot transients (bumped to fire an effect exactly once).
  final int successToken;
  final int wrongToken;
  final int sweepToken;

  // Orbit voice lane: clip number (1..58) + a token bumped on every voiced line
  // (clip equality is NOT a replay trigger — see the VO playbook) + whether a
  // line is currently playing (gates primary CTAs, paces monologues).
  final int? voiceClip;
  final int voiceToken;
  final bool voicePlaying;

  bool get allSolved => solvedMissions.length >= 6;

  EarthDetectiveState copyWith({
    EdScene? scene,
    int? missionIndex,
    Set<int>? solvedMissions,
    PlayPhase? phase,
    Offset? scannerNorm,
    bool? scannerActive,
    ScannerState? scannerState,
    int? wrongAttempts,
    int? hintLevel,
    Object? helperMessage = _sentinel,
    MascotPose? mascotPose,
    double? zoomLevel,
    double? sliderNorm,
    bool? soundOn,
    int? successToken,
    int? wrongToken,
    int? sweepToken,
    int? voiceClip,
    int? voiceToken,
    bool? voicePlaying,
  }) {
    return EarthDetectiveState(
      scene: scene ?? this.scene,
      missionIndex: missionIndex ?? this.missionIndex,
      solvedMissions: solvedMissions ?? this.solvedMissions,
      phase: phase ?? this.phase,
      scannerNorm: scannerNorm ?? this.scannerNorm,
      scannerActive: scannerActive ?? this.scannerActive,
      scannerState: scannerState ?? this.scannerState,
      wrongAttempts: wrongAttempts ?? this.wrongAttempts,
      hintLevel: hintLevel ?? this.hintLevel,
      helperMessage:
          helperMessage == _sentinel ? this.helperMessage : helperMessage as String?,
      mascotPose: mascotPose ?? this.mascotPose,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      sliderNorm: sliderNorm ?? this.sliderNorm,
      soundOn: soundOn ?? this.soundOn,
      successToken: successToken ?? this.successToken,
      wrongToken: wrongToken ?? this.wrongToken,
      sweepToken: sweepToken ?? this.sweepToken,
      voiceClip: voiceClip ?? this.voiceClip,
      voiceToken: voiceToken ?? this.voiceToken,
      voicePlaying: voicePlaying ?? this.voicePlaying,
    );
  }

  static const _sentinel = Object();
}
