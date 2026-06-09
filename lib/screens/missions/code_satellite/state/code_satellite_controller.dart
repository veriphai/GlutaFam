// The orchestrator for Code the Satellite. Owns the immutable [CodeSatelliteState]
// and drives every transition: intro → brief → arranging (drag/drop) → running
// (the step-by-step execution loop) → failed/success.
//
// Division of labour: this controller owns ALL discrete state + the run loop and
// pushes imperative animation calls to the Flame stage through the [MissionStage]
// interface (one-directional: controller → game, no import cycle, no listener on
// the game side). The game's playCommand/showFailure/showSuccess return Futures
// that complete when their animation finishes, so the loop simply awaits them.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../config/asset_paths.dart';
import '../config/code_satellite_tuning.dart';
import '../config/orbit_voice.dart';
import '../models/satellite_command.dart';
import 'analytics.dart';
import 'code_satellite_state.dart';
import 'mission_validation.dart';

/// What the Flame stage exposes to the controller. Implemented by
/// CodeSatelliteGame; kept abstract here so state/ never imports game/.
abstract class MissionStage {
  /// Fade the idle satellite in and reset props (entering the puzzle).
  void enterStage();

  /// Return the satellite to its idle state (after a failure, before a retry).
  void resetToIdle();

  /// Shrink the satellite (50%) while the mission runs so props/effects read;
  /// full size otherwise.
  void setCompact(bool compact);

  /// Play one command's animation; completes when the beat finishes.
  Future<void> playCommand(SatelliteCommand command, {required bool capturesImage});

  /// Play the failure beat for [command]; [serious] swaps to the error sprite.
  Future<void> showFailure(SatelliteCommand command, {required bool serious});

  /// Play the full success sequence (data → ground station + celebration).
  Future<void> showSuccess();
}

/// Where a dragged block came from (null origin = the tray).
class CommandDrag {
  final SatelliteCommand command;
  final int? originSlot;
  const CommandDrag(this.command, {this.originSlot});
}

class CodeSatelliteController extends ChangeNotifier {
  CodeSatelliteController({
    this.onSound,
    this.onHaptic,
    this.onExit,
    math.Random? random,
  }) : _rng = random ?? math.Random();

  final void Function(String assetFile)? onSound;
  final void Function()? onHaptic;
  final VoidCallback? onExit;
  final math.Random _rng;

  MissionStage? _stage;
  void attachStage(MissionStage stage) => _stage = stage;

  int _attempts = 0;
  bool _disposed = false;

  CodeSatelliteState _state = CodeSatelliteState(
    phase: Activity10Phase.storyIntro,
    slots: List<SatelliteCommand?>.filled(kCorrectOrder.length, null),
    tray: const [],
  );
  CodeSatelliteState get state => _state;

  void _set(CodeSatelliteState s) {
    if (_disposed) return;
    // Voice choke point (Power Balance pattern): every play-phase message with
    // a mapped clip gets stamped here — unless the caller already stamped one
    // explicitly (token differs). Repeated identical text does not re-voice.
    if (s.voiceToken == _state.voiceToken &&
        s.message != _state.message &&
        s.phase.sceneGroup == SceneGroup.play) {
      final clip = kOrbitClipForMessage[s.message];
      if (clip != null) {
        s = s.copyWith(voiceClip: clip, voiceToken: s.voiceToken + 1);
      }
    }
    _state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _closeStepGate();
    _voiceSafety?.cancel();
    super.dispose();
  }

  // ── lifecycle / phase transitions ──────────────────────────────────────────
  void onFirstBuild() {
    CSAnalytics.activityStarted();
    _set(_state.copyWith(
      phase: Activity10Phase.storyIntro,
      mascot: OrbitMood.welcoming,
      message: "I'm Orbit! I'll guide you on this mission.",
    ));
  }

  void startMission() {
    onSound?.call(CSSounds.tap);
    CSAnalytics.missionBriefShown();
    _set(_state.copyWith(
      phase: Activity10Phase.missionBrief,
      mascot: OrbitMood.explaining,
      message: 'Look down at Earth — a cyclone is forming over the ocean.',
    ));
  }

  void beginArranging() {
    onSound?.call(CSSounds.tap);
    CSAnalytics.arrangingStarted();
    _closeStepGate();
    final shuffled = _shuffledCommands();
    _set(_state.copyWith(
      phase: Activity10Phase.arranging,
      slots: List<SatelliteCommand?>.filled(kCorrectOrder.length, null),
      tray: shuffled,
      correctSteps: const {},
      clearActive: true,
      clearFailed: true,
      clearWrong: true,
      clearFailureMessage: true,
      imageCaptured: false,
      awaitingNextStep: false,
      mascot: OrbitMood.pointing,
      // Orbit coaches the very first step (guided learning, not a test).
      message: kCorrectOrder.first.coach,
    ));
    _stage?.enterStage();
  }

  List<SatelliteCommand> _shuffledCommands() {
    final list = [...kCorrectOrder];
    // Fisher–Yates; reshuffle if it lands already-sorted (rare but possible).
    do {
      for (var i = list.length - 1; i > 0; i--) {
        final j = _rng.nextInt(i + 1);
        final t = list[i];
        list[i] = list[j];
        list[j] = t;
      }
    } while (_isSorted(list));
    return list;
  }

  bool _isSorted(List<SatelliteCommand> l) {
    for (var i = 0; i < l.length; i++) {
      if (l[i] != kCorrectOrder[i]) return false;
    }
    return true;
  }

  // ── guided arrangement ──────────────────────────────────────────────────────
  // Slots fill strictly left-to-right. Orbit coaches the next step; the child
  // drags the matching command onto the active slot. Correct → it locks in
  // (green) and Orbit moves on. Wrong → the slot flashes red, Orbit gently
  // redirects, and the command stays in the tray. It's guided learning — there
  // is no penalty and nothing to "fail".
  /// Whether [command] is the next correct command (pure query — no state
  /// change). The scene uses this to decide whether to play the fly-in or the
  /// wrong-flash.
  bool isCorrectNext(SatelliteCommand command) {
    if (_state.phase != Activity10Phase.arranging) return false;
    final step = _state.filledCount;
    if (step >= _state.slots.length) return false;
    return command == kCorrectOrder[step];
  }

  /// Light feedback when a correct card is selected (before it flies in).
  void playSelectFeedback() {
    onSound?.call(CSSounds.tap);
    onHaptic?.call();
  }

  /// Commit a correct placement — called when the fly-in animation lands.
  void confirmPlace(SatelliteCommand command) {
    if (_state.phase != Activity10Phase.arranging) return;
    final step = _state.filledCount;
    if (step >= _state.slots.length || command != kCorrectOrder[step]) return;
    final slots = [..._state.slots]..[step] = command;
    final tray = [..._state.tray]..remove(command);
    final correct = {..._state.correctSteps, step};
    onSound?.call(CSSounds.correct);
    onHaptic?.call();
    CSAnalytics.blockPlaced(command, step);

    final nextStep = step + 1;
    final allDone = nextStep >= slots.length;
    _set(_state.copyWith(
      slots: slots,
      tray: tray,
      correctSteps: correct,
      clearWrong: true,
      mascot: allDone ? OrbitMood.celebrate : OrbitMood.pointing,
      message: allDone ? kMsgAllPlaced : kCorrectOrder[nextStep].coach,
    ));
  }

  /// Wrong tap: flash the active slot red + a gentle, encouraging redirect (the
  /// command is NOT placed).
  void rejectPlace(SatelliteCommand command) {
    if (_state.phase != Activity10Phase.arranging) return;
    final step = _state.filledCount;
    if (step >= _state.slots.length) return;
    final expected = kCorrectOrder[step];
    onSound?.call(CSSounds.wrong);
    CSAnalytics.blockPlaced(command, -1);
    _set(_state.copyWith(
      wrongSlotIndex: step,
      mascot: OrbitMood.thinking,
      message: expected.wrong,
      // explicit stamp: a repeated identical wrong line must still re-voice.
      voiceClip: kClipWrongBase + step,
      voiceToken: _state.voiceToken + 1,
    ));
    final token = ++_wrongToken;
    Future<void>.delayed(const Duration(milliseconds: 750), () {
      if (_disposed || token != _wrongToken) return;
      if (_state.phase == Activity10Phase.arranging) {
        _set(_state.copyWith(clearWrong: true));
      }
    });
  }

  /// Non-animated convenience (correct → place, wrong → reject).
  void attemptPlace(SatelliteCommand command) =>
      isCorrectNext(command) ? confirmPlace(command) : rejectPlace(command);

  int _wrongToken = 0;

  // ── run the mission (PRD §9) ────────────────────────────────────────────────
  Future<void> runMission() async {
    if (!_state.canRun) return;
    final sequence = _state.slots.cast<SatelliteCommand>();
    _attempts++;
    CSAnalytics.runPressed(sequence);
    onSound?.call(CSSounds.tap);
    // Stay full-size for wake-up + check-battery; the stage zooms out at the
    // solar step (when the Sun/Earth need room).

    // Run start — two narrated lines, each paced by its clip.
    _set(_state.copyWith(
      phase: Activity10Phase.running,
      correctSteps: const {},
      clearActive: true,
      clearFailed: true,
      clearFailureMessage: true,
      imageCaptured: false,
      awaitingNextStep: false,
      mascot: OrbitMood.thinking,
      message: kMsgUpload,
    ));
    await _voicePaced();
    if (_disposed) return;
    _set(_state.copyWith(message: kMsgWatchClosely));
    await _voicePaced();
    if (_disposed) return;

    final missionState = MissionState();
    final correct = <int>{};

    for (var i = 0; i < sequence.length; i++) {
      final command = sequence[i];
      // "Running: X" narrates OVER the command animation.
      _set(_state.copyWith(activeStepIndex: i, message: 'Running: ${command.label}'));

      final result = validateAndApply(command: command, stepIndex: i, state: missionState);

      if (!result.success) {
        CSAnalytics.missionFailed(command, i, result.failureMessage!);
        onSound?.call(CSSounds.wrong);
        final serious = command == SatelliteCommand.sendData;
        await _stage?.showFailure(command, serious: serious);
        if (_disposed) return;
        _set(_state.copyWith(
          phase: Activity10Phase.failed,
          failedStepIndex: i,
          failureMessage: result.failureMessage,
          correctSteps: correct,
          clearActive: true,
          awaitingNextStep: false,
          mascot: OrbitMood.debug,
          message: kMsgOops,
        ));
        return;
      }

      CSAnalytics.stepSucceeded(command, i);
      onSound?.call(CSSounds.correct);
      final capturesImage = command == SatelliteCommand.takePicture;
      await _stage?.playCommand(command, capturesImage: capturesImage);
      if (_disposed) return;
      // Let the "Running: X" narration finish before the beat line replaces it.
      await _voicePaced();
      if (_disposed) return;

      correct.add(i);
      _set(_state.copyWith(
        correctSteps: {...correct},
        message: result.teachingMessage,
        imageCaptured: _state.imageCaptured || capturesImage,
        photoToken: capturesImage ? _state.photoToken + 1 : null,
      ));
      // Pace between steps on the beat's narration (clip-length fallback when
      // muted); in step-through debug also wait for the "Next Step" tap.
      await _voicePaced();
      if (_disposed) return;
      if (CSDebug.stepThrough) {
        await _waitForStep();
        if (_disposed) return;
      }
    }

    // All nine succeeded.
    CSAnalytics.missionSucceeded(_attempts);
    onSound?.call(CSSounds.complete);
    await _stage?.showSuccess();
    if (_disposed) return;
    _set(_state.copyWith(
      phase: Activity10Phase.success,
      awaitingNextStep: false,
      clearActive: true,
      mascot: OrbitMood.successJump,
      message: "You did it! You built a real command sequence.",
    ));
  }

  // ── step-through debug gate ─────────────────────────────────────────────────
  Completer<void>? _stepGate;

  Future<void> _waitForStep() {
    _stepGate = Completer<void>();
    _set(_state.copyWith(awaitingNextStep: true));
    return _stepGate!.future;
  }

  /// Advance to the next command (debug step-through "Next Step" button).
  void advanceStep() {
    final gate = _stepGate;
    if (gate != null && !gate.isCompleted) {
      _stepGate = null;
      _set(_state.copyWith(awaitingNextStep: false));
      gate.complete();
    }
  }

  /// Re-play the current paused step's animation (debug "Replay" button) without
  /// advancing the run.
  bool _replaying = false;
  Future<void> replayCurrentStep() async {
    if (!_state.awaitingNextStep || _replaying) return;
    final idx = _state.activeStepIndex;
    if (idx == null || idx < 0 || idx >= _state.slots.length) return;
    final command = _state.slots[idx];
    if (command == null) return;
    _replaying = true;
    await _stage?.playCommand(command, capturesImage: command == SatelliteCommand.takePicture);
    _replaying = false;
    // Re-trigger the capture cinematic when replaying the take-picture step.
    if (command == SatelliteCommand.takePicture) {
      _set(_state.copyWith(photoToken: _state.photoToken + 1));
    }
  }

  void _closeStepGate() {
    final gate = _stepGate;
    _stepGate = null;
    if (gate != null && !gate.isCompleted) gate.complete();
    _releaseVoiceGate();
  }

  // ── voice pacing (shell-reported) ───────────────────────────────────────────
  bool _voiceActive = false;
  int _voiceFinishedToken = -1;
  int _voiceFailedToken = -1;
  Completer<void>? _voiceGate;
  Timer? _voiceSafety;

  void _releaseVoiceGate() {
    _voiceSafety?.cancel();
    final g = _voiceGate;
    _voiceGate = null;
    if (g != null && !g.isCompleted) g.complete();
  }

  /// Shell: a clip actually started playing.
  void voiceStarted() {
    _voiceActive = true;
    if (!_state.voicePlaying) _set(_state.copyWith(voicePlaying: true));
  }

  /// Shell: the clip finished (onPlayerComplete).
  void voiceFinished() {
    _voiceActive = false;
    _voiceFinishedToken = _state.voiceToken;
    _releaseVoiceGate();
    if (_state.voicePlaying) _set(_state.copyWith(voicePlaying: false));
  }

  /// Shell: the clip could not play (missing asset / autoplay block). Per the
  /// playbook, anything gated on it advances immediately.
  void voiceFailed() {
    _voiceActive = false;
    _voiceFailedToken = _state.voiceToken;
    _releaseVoiceGate();
    if (_state.voicePlaying) _set(_state.copyWith(voicePlaying: false));
  }

  /// Waits for the current line: live audio → until onPlayerComplete (+breath),
  /// with a clip-length+5s safety; already finished → tiny breath; failed →
  /// advance now; never started (muted) → reading-time fallback from the
  /// measured clip length. NEVER a bare fixed timer (playbook gotcha).
  Future<void> _voicePaced() async {
    await Future<void>.delayed(const Duration(milliseconds: 350)); // start grace
    if (_disposed) return;
    final token = _state.voiceToken;
    if (_voiceActive) {
      _voiceGate = Completer<void>();
      final cap = (kOrbitClipSecs[_state.voiceClip] ?? 8.0) + 5.0;
      _voiceSafety?.cancel();
      _voiceSafety = Timer(Duration(milliseconds: (cap * 1000).round()), _releaseVoiceGate);
      await _voiceGate!.future;
      if (_disposed) return;
      await Future<void>.delayed(const Duration(milliseconds: 300)); // breath
      return;
    }
    if (_voiceFinishedToken == token) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return;
    }
    if (_voiceFailedToken == token) return;
    // muted / no audio signal: reading-time fallback.
    final secs = (kOrbitClipSecs[_state.voiceClip] ?? 3.0) * 0.8;
    await Future<void>.delayed(Duration(milliseconds: (secs * 1000).round()));
  }

  // ── debug / retry / replay (PRD §17 transitions) ────────────────────────────
  void reorderCommands() {
    CSAnalytics.reorderPressed();
    onSound?.call(CSSounds.tap);
    _closeStepGate();
    _stage?.resetToIdle();
    _set(_state.copyWith(
      phase: Activity10Phase.arranging,
      clearActive: true,
      clearFailed: true,
      clearFailureMessage: true,
      correctSteps: const {},
      imageCaptured: false,
      awaitingNextStep: false,
      mascot: OrbitMood.pointing,
      message: kMsgReorder,
    ));
  }

  void playAgain() {
    CSAnalytics.playAgain();
    beginArranging();
  }

  void nextMission() {
    CSAnalytics.nextMission();
    onExit?.call();
  }
}
