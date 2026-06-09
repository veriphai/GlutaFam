// Immutable state for the activity (PRD §13), plus the scene/phase/mascot
// enums. The controller owns one of these and rebuilds the UI via notify.

import '../models/satellite_type.dart';

/// Full-screen scenes routed by the shell's AnimatedSwitcher.
enum ActivityScene { intro, missionPlay, missionLog, bridge }

/// Sub-state of the active mission (all on the same missionPlay screen).
enum MissionPhase { idle, dragging, resolving, solved }

/// Mascot expression, mapped to a sprite by [MascotHelper].
enum MascotMood { welcoming, guiding, thinking, concerned, celebrating, happy, pointingRight }

class ChooseSatelliteState {
  const ChooseSatelliteState({
    this.scene = ActivityScene.intro,
    this.phase = MissionPhase.idle,
    this.currentMissionIndex = 0,
    this.completedMissionIds = const {},
    this.activeDragType,
    this.isHoveringZone = false,
    this.wrongAttempts = 0,
    this.hintLevel = 0,
    this.pulseHintType,
    this.wrongPulseToken = 0,
    this.totalWrong = 0,
    this.lineIndex = 0,
    this.voiceToken = 1,
    this.voicePlaying = false,
  });

  final ActivityScene scene;
  final MissionPhase phase;
  final int currentMissionIndex;
  final Set<String> completedMissionIds;

  /// The satellite type currently held in a drag (null when idle). Enforces
  /// "one active drag at a time" — other cards are non-draggable while set.
  final SatelliteType? activeDragType;
  final bool isHoveringZone;

  /// Wrong attempts on the CURRENT mission; drives hint escalation (PRD §14.6).
  final int wrongAttempts;

  /// 0 none · 1 soft hint · 2 stronger hint + subtle card pulse · 3 strong.
  final int hintLevel;

  /// Which tray card to pulse as a hint (set at hintLevel >= 2).
  final SatelliteType? pulseHintType;

  /// Bumped on every wrong drop so the scene can fire a one-shot wrong pulse.
  final int wrongPulseToken;

  /// Cumulative wrong attempts across all missions (analytics).
  final int totalWrong;

  /// Index into the current mascot dialogue sequence (controller-owned pacing).
  final int lineIndex;

  /// Bumped whenever a NEW line should be voiced — the screen plays whenever
  /// `voiceToken != _lastVoiceToken` (clip equality alone misses repeats).
  /// Initialised to 1 (screen starts at 0) so the very first build fires.
  final int voiceToken;

  /// True while an Orbit VO line is actually playing (gates primary CTAs).
  final bool voicePlaying;

  bool get isResolving => phase == MissionPhase.resolving;
  bool get isSolved => phase == MissionPhase.solved;

  /// Tray is interactive only while idle/dragging on the play scene.
  bool get trayEnabled =>
      scene == ActivityScene.missionPlay &&
      (phase == MissionPhase.idle || phase == MissionPhase.dragging);

  /// A given card may begin a drag only if the tray is enabled and no OTHER
  /// card is already being dragged.
  bool canDrag(SatelliteType type) =>
      trayEnabled && (activeDragType == null || activeDragType == type);

  ChooseSatelliteState copyWith({
    ActivityScene? scene,
    MissionPhase? phase,
    int? currentMissionIndex,
    Set<String>? completedMissionIds,
    bool clearActiveDrag = false,
    SatelliteType? activeDragType,
    bool? isHoveringZone,
    int? wrongAttempts,
    int? hintLevel,
    bool clearPulseHint = false,
    SatelliteType? pulseHintType,
    int? wrongPulseToken,
    int? totalWrong,
    int? lineIndex,
    int? voiceToken,
    bool? voicePlaying,
  }) {
    return ChooseSatelliteState(
      scene: scene ?? this.scene,
      phase: phase ?? this.phase,
      currentMissionIndex: currentMissionIndex ?? this.currentMissionIndex,
      completedMissionIds: completedMissionIds ?? this.completedMissionIds,
      activeDragType: clearActiveDrag ? null : (activeDragType ?? this.activeDragType),
      isHoveringZone: isHoveringZone ?? this.isHoveringZone,
      wrongAttempts: wrongAttempts ?? this.wrongAttempts,
      hintLevel: hintLevel ?? this.hintLevel,
      pulseHintType: clearPulseHint ? null : (pulseHintType ?? this.pulseHintType),
      wrongPulseToken: wrongPulseToken ?? this.wrongPulseToken,
      totalWrong: totalWrong ?? this.totalWrong,
      lineIndex: lineIndex ?? this.lineIndex,
      voiceToken: voiceToken ?? this.voiceToken,
      voicePlaying: voicePlaying ?? this.voicePlaying,
    );
  }
}
