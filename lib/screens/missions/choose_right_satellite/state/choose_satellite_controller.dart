// The single source of truth for the activity. A ChangeNotifier owning an
// immutable [ChooseSatelliteState]; the Flutter shell rebuilds via
// ListenableBuilder. No Provider/Riverpod (self-contained activity).
//
// Drop resolution lives here so the rules (one active drag, hint escalation,
// "drop outside card = no attempt") are enforced in one place, while the scene
// owns the continuous animation timing (snap flash / success effect duration).

import 'package:flutter/foundation.dart';

import '../data/choose_satellite_missions.dart';
import '../data/orbit_script.dart';
import '../models/orbit_line.dart';
import '../models/satellite_mission.dart';
import '../models/satellite_type.dart';
import 'analytics.dart';
import 'choose_satellite_state.dart';

class ChooseSatelliteController extends ChangeNotifier {
  ChooseSatelliteController({List<SatelliteMission>? missions})
      : missions = missions ?? kChooseSatelliteMissions {
    _analytics.activityStarted();
  }

  final List<SatelliteMission> missions;
  final ChooseSatelliteAnalytics _analytics = const ChooseSatelliteAnalytics();

  ChooseSatelliteState _state = const ChooseSatelliteState();
  ChooseSatelliteState get state => _state;

  SatelliteMission get mission => missions[_state.currentMissionIndex];
  int get missionCount => missions.length;
  int get missionNumber => _state.currentMissionIndex + 1; // 1-based for display

  void _set(ChooseSatelliteState next) {
    _state = next;
    notifyListeners();
  }

  // --- Scene flow ----------------------------------------------------------

  /// Intro "Begin" -> first mission.
  void beginMissions() {
    _set(_state.copyWith(
      scene: ActivityScene.missionPlay,
      phase: MissionPhase.idle,
      lineIndex: 0,
      voiceToken: _state.voiceToken + 1,
    ));
    _analytics.missionStarted(mission.id);
  }

  /// Advance after the success state has been savoured (PRD §14.4).
  void nextMission() {
    if (_state.currentMissionIndex >= missions.length - 1) {
      _set(_state.copyWith(
        scene: ActivityScene.missionLog,
        lineIndex: 0,
        voiceToken: _state.voiceToken + 1,
      ));
      _analytics.activityCompleted(_state.totalWrong);
      return;
    }
    _set(_state.copyWith(
      currentMissionIndex: _state.currentMissionIndex + 1,
      phase: MissionPhase.idle,
      isHoveringZone: false,
      clearActiveDrag: true,
      wrongAttempts: 0,
      hintLevel: 0,
      clearPulseHint: true,
      lineIndex: 0,
      voiceToken: _state.voiceToken + 1,
    ));
    _analytics.missionStarted(mission.id);
  }

  void toBridge() => _set(_state.copyWith(
        scene: ActivityScene.bridge,
        lineIndex: 0,
        voiceToken: _state.voiceToken + 1,
      ));

  // --- Drag lifecycle ------------------------------------------------------

  void onDragStart(SatelliteType type) {
    if (!_state.canDrag(type)) return;
    _set(_state.copyWith(phase: MissionPhase.dragging, activeDragType: type));
    _analytics.dragStarted(mission.id, type);
  }

  /// Drag released anywhere (Flutter fires this whether accepted or canceled).
  /// Only resets if we're still mid-drag (a correct drop already moved us to
  /// resolving, which we must not clobber).
  void onDragEnd() {
    if (_state.phase == MissionPhase.dragging) {
      _set(_state.copyWith(
          phase: MissionPhase.idle, isHoveringZone: false, clearActiveDrag: true));
    }
  }

  void setHovering(bool hovering) {
    if (_state.phase != MissionPhase.dragging) return;
    if (_state.isHoveringZone == hovering) return;
    _set(_state.copyWith(isHoveringZone: hovering));
  }

  /// Resolve a drop onto the dispatch zone. Returns true if correct.
  /// (A drop OUTSIDE the card never reaches here — see PRD §25.1 — because the
  /// DragTarget only accepts within its bounds.)
  bool resolveDrop(SatelliteType type) {
    if (_state.phase == MissionPhase.resolving || _state.phase == MissionPhase.solved) {
      return false; // ignore extra drops
    }
    final correct = mission.isCorrect(type);
    if (correct) {
      _set(_state.copyWith(
        phase: MissionPhase.resolving,
        isHoveringZone: false,
        clearActiveDrag: true,
        lineIndex: 0,
        voiceToken: _state.voiceToken + 1, // success lines start
      ));
      _analytics.dropCorrect(mission.id, type, _state.wrongAttempts);
      return true;
    }
    // Gentle wrong (PRD §14.5) — no point loss, bounce + hint. The token bump
    // also REPLAYS the hint voice when the same hint level repeats.
    final attempts = _state.wrongAttempts + 1;
    final level = attempts.clamp(0, 3);
    _set(_state.copyWith(
      phase: MissionPhase.idle,
      isHoveringZone: false,
      clearActiveDrag: true,
      wrongAttempts: attempts,
      totalWrong: _state.totalWrong + 1,
      hintLevel: level,
      wrongPulseToken: _state.wrongPulseToken + 1,
      // Pulse the correct card from the 2nd wrong attempt (PRD §14.6).
      pulseHintType: level >= 2 ? mission.correctType : null,
      lineIndex: 0,
      voiceToken: _state.voiceToken + 1,
    ));
    _analytics.dropWrong(mission.id, type, mission.correctType, attempts);
    _analytics.hintShown(mission.id, level);
    return false;
  }

  /// Called by the scene once the snap flash + success effect have finished
  /// playing, to lock in the solved state (PRD §14.4 steps 4–7).
  void markSolved() {
    if (_state.phase != MissionPhase.resolving) return;
    _set(_state.copyWith(
      phase: MissionPhase.solved,
      completedMissionIds: {..._state.completedMissionIds, mission.id},
    ));
    _analytics.missionCompleted(mission.id, _state.wrongAttempts);
  }

  // --- Voice sequencing ------------------------------------------------------

  /// The line the bubble is showing / the voice is speaking right now.
  OrbitLine get currentLine {
    final lines = mascotLines;
    if (lines.isEmpty) return const OrbitLine('');
    return lines[_state.lineIndex.clamp(0, lines.length - 1)];
  }

  /// Single router for "what happens after this line ends" — called by the
  /// screen on AudioPlayer.onPlayerComplete, the muted reading-time fallback,
  /// or the safety timeout. Idempotent: holds on the last line of a sequence.
  void onVoiceFinished() {
    final lines = mascotLines;
    if (_state.lineIndex >= lines.length - 1) {
      if (_state.voicePlaying) _set(_state.copyWith(voicePlaying: false));
      return;
    }
    _set(_state.copyWith(
      lineIndex: _state.lineIndex + 1,
      voiceToken: _state.voiceToken + 1,
    ));
  }

  /// Owned by the shell around the voice player (gates primary CTAs).
  void setVoicePlaying(bool playing) {
    if (_state.voicePlaying == playing) return;
    _set(_state.copyWith(voicePlaying: playing));
  }

  // --- Derived mascot voice ------------------------------------------------

  MascotMood get mascotMood {
    switch (_state.scene) {
      case ActivityScene.intro:
        return MascotMood.welcoming;
      case ActivityScene.missionLog:
        return MascotMood.happy;
      case ActivityScene.bridge:
        return MascotMood.pointingRight;
      case ActivityScene.missionPlay:
        if (_state.isResolving || _state.isSolved) return MascotMood.celebrating;
        if (_state.hintLevel >= 2) return MascotMood.concerned;
        if (_state.hintLevel == 1) return MascotMood.thinking;
        return MascotMood.guiding;
    }
  }

  /// Orbit's dialogue for the current state, as an ordered multi-line sequence
  /// (the bubble cycles through it; each line carries its VO clip number).
  List<OrbitLine> get mascotLines {
    switch (_state.scene) {
      case ActivityScene.intro:
        return kIntroLines;
      case ActivityScene.missionLog:
        return kLogLines;
      case ActivityScene.bridge:
        return const [kBridgeLine];
      case ActivityScene.missionPlay:
        if (_state.isResolving || _state.isSolved) return mission.successLines;
        switch (_state.hintLevel) {
          case 0:
            // The gameplay instruction plays once, before Mission 1's beat.
            return _state.currentMissionIndex == 0
                ? [...kInstructionLines, ...mission.appearLines]
                : mission.appearLines;
          case 1:
            return [mission.hintAfterWrong];
          case 2:
            return [mission.strongerHint];
          default:
            return const [kStrongNudge];
        }
    }
  }
}
