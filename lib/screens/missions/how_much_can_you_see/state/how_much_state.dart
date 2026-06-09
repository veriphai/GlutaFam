// Immutable snapshot of Activity 2 (PRD §8). The controller swaps a new instance
// on every change; the Flutter shell + Flame stage read from it.

import 'package:flutter/foundation.dart';

import '../config/challenge_options.dart';
import '../config/height_levels.dart';

/// The eight activity scenes (PRD §8). `wrongAnswerFeedback` is a sub-state of
/// the challenge (the child stays on the challenge screen), routed to the same
/// challenge scene widget.
enum ActivityScene {
  storyIntro,
  missionTestIntro,
  heightExploration,
  cycloneChallenge,
  wrongAnswerFeedback,
  correctAnswerSuccess,
  successStoryBeat,
  nextMissionTeaser,
}

/// Mascot expression driver for the robot helper (PRD §18 / §24).
enum MascotMood { idle, pointing, thumbsUp, hint, oops }

@immutable
class HeightViewActivityState {
  const HeightViewActivityState({
    required this.scene,
    required this.currentLevel,
    required this.visitedLevels,
    required this.hasReachedSatellite,
    required this.challengeUnlocked,
    required this.challengeCompleted,
    required this.selectedChallengeOption,
    required this.missionControlMessage,
    this.wrongAttempts = 0,
    this.showTakeChallenge = false,
    this.hintPulseSatellite = false,
    this.showDragHint = false,
    this.wrongShakeToken = 0,
    this.wrongShakeOption,
    this.mascot = MascotMood.idle,
    this.voiceClip,
    this.voiceToken = 0,
    this.voicePlaying = false,
  });

  // ── PRD §8 core model ────────────────────────────────────────────────────
  final ActivityScene scene;
  final ViewHeightLevel currentLevel;
  final Set<ViewHeightLevel> visitedLevels;
  final bool hasReachedSatellite;
  final bool challengeUnlocked;
  final bool challengeCompleted;
  final ChallengeOptionId? selectedChallengeOption;
  final String missionControlMessage;

  // ── UX extras ──────────────────────────────────────────────────────────
  final int wrongAttempts; // wrong challenge taps so far
  final bool showTakeChallenge; // TAKE CHALLENGE CTA visible (after sat reveal)
  final bool hintPulseSatellite; // pulse the satellite card after repeated misses
  final bool showDragHint; // idle nudge on Ground (PRD §24)
  final int wrongShakeToken; // bumped per wrong tap → card runs a one-shot shake
  final ChallengeOptionId? wrongShakeOption;
  final MascotMood mascot;

  // ── Orbit voice-over (see skill: voiceClip/voiceToken pattern) ───────────
  /// Which orbit_NN clip the current line maps to (null = no line yet).
  final int? voiceClip;
  /// Bumped on EVERY new line — the shell plays when this differs from its
  /// cached value (clip equality alone would swallow repeated lines).
  final int voiceToken;
  /// True while Orbit is speaking — primary CTAs gate on this.
  final bool voicePlaying;

  HeightLevelConfig get currentConfig => kHeightLevels[currentLevel]!;

  HeightViewActivityState copyWith({
    ActivityScene? scene,
    ViewHeightLevel? currentLevel,
    Set<ViewHeightLevel>? visitedLevels,
    bool? hasReachedSatellite,
    bool? challengeUnlocked,
    bool? challengeCompleted,
    Object? selectedChallengeOption = _keep,
    String? missionControlMessage,
    int? wrongAttempts,
    bool? showTakeChallenge,
    bool? hintPulseSatellite,
    bool? showDragHint,
    int? wrongShakeToken,
    Object? wrongShakeOption = _keep,
    MascotMood? mascot,
    Object? voiceClip = _keep,
    int? voiceToken,
    bool? voicePlaying,
  }) {
    return HeightViewActivityState(
      scene: scene ?? this.scene,
      currentLevel: currentLevel ?? this.currentLevel,
      visitedLevels: visitedLevels ?? this.visitedLevels,
      hasReachedSatellite: hasReachedSatellite ?? this.hasReachedSatellite,
      challengeUnlocked: challengeUnlocked ?? this.challengeUnlocked,
      challengeCompleted: challengeCompleted ?? this.challengeCompleted,
      selectedChallengeOption: selectedChallengeOption == _keep
          ? this.selectedChallengeOption
          : selectedChallengeOption as ChallengeOptionId?,
      missionControlMessage: missionControlMessage ?? this.missionControlMessage,
      wrongAttempts: wrongAttempts ?? this.wrongAttempts,
      showTakeChallenge: showTakeChallenge ?? this.showTakeChallenge,
      hintPulseSatellite: hintPulseSatellite ?? this.hintPulseSatellite,
      showDragHint: showDragHint ?? this.showDragHint,
      wrongShakeToken: wrongShakeToken ?? this.wrongShakeToken,
      wrongShakeOption:
          wrongShakeOption == _keep ? this.wrongShakeOption : wrongShakeOption as ChallengeOptionId?,
      mascot: mascot ?? this.mascot,
      voiceClip: voiceClip == _keep ? this.voiceClip : voiceClip as int?,
      voiceToken: voiceToken ?? this.voiceToken,
      voicePlaying: voicePlaying ?? this.voicePlaying,
    );
  }

  static const Object _keep = Object();
}
