// The Earth Detective state machine. Owns the immutable [EarthDetectiveState],
// drives scene transitions, scanner/zoom/slider interaction, correct/wrong
// resolution, hint escalation (PRD §14), and Orbit's voice pacing. The Flame
// stage and Flutter scenes both listen to this single ChangeNotifier.
//
// Voice integration follows the playbook's CHOKE-POINT pattern: every Orbit
// line flows through `helperMessage`, so [_set] stamps `voiceClip`/`voiceToken`
// whenever the message changes to a line in [orbitClipFor]. Monologues (intro /
// tutorial / mission-open / summary) advance on voice completion via
// [onVoiceFinished], with a reading-time fallback timer when muted.

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../config/missions.dart';
import '../models/earth_detective_mission.dart';
import 'analytics.dart';
import 'earth_detective_state.dart';

/// Sound + haptic intents the shell fulfils (kept out of the controller so it
/// stays platform-free).
enum EdCue { scannerPickup, near, lock, correct, wrong, complete }

class EarthDetectiveController extends ChangeNotifier {
  EarthDetectiveController({this.onCue}) {
    // Orbit's intro monologue starts immediately (clip 1 fires on first build:
    // voiceToken 1 vs the shell's _lastVoiceToken 0).
    _beginMonologue(EdCopy.introLines);
  }

  /// Fired for SFX + haptics; the shell wires it to audio/HapticFeedback.
  final void Function(EdCue cue)? onCue;

  EarthDetectiveState _state = EarthDetectiveState(
    helperMessage: EdCopy.introLines.first,
    voiceClip: orbitClipFor[EdCopy.introLines.first],
    voiceToken: 1,
  );
  EarthDetectiveState get state => _state;

  EarthDetectiveMission get mission => kMissions[_state.missionIndex];

  Timer? _resolveTimer;

  // Ambient prompts (scan/near/lock) are voiced ONCE per mission — otherwise
  // wiggling across the proximity boundary machine-guns the clips.
  final Set<int> _ambientVoiced = {};
  late final Set<int?> _ambientClips = {
    orbitClipFor[EdCopy.scanHint],
    orbitClipFor[EdCopy.nearPrompt],
    orbitClipFor[EdCopy.lockPrompt],
  };

  /// Single mutation choke point: stamps the matching Orbit clip whenever the
  /// helper message changes to a mapped line (repeated identical text does NOT
  /// re-voice — right for ambient nudges).
  void _set(EarthDetectiveState next) {
    var out = next;
    final msg = next.helperMessage;
    if (msg != null && msg != _state.helperMessage) {
      final clip = orbitClipFor[msg];
      if (clip != null) {
        final ambient = _ambientClips.contains(clip);
        if (!ambient || !_ambientVoiced.contains(clip)) {
          if (ambient) _ambientVoiced.add(clip);
          out = next.copyWith(voiceClip: clip, voiceToken: next.voiceToken + 1);
        }
      }
    }
    _state = out;
    notifyListeners();
  }

  // ── Orbit monologue driver (intro / tutorial / mission-open / summary) ──
  // Advances on voice completion (+ a small breath); a periodic reading-time
  // fallback paces muted users / missing clips — it DEFERS to live audio.
  List<String>? _monoLines;
  int _monoIdx = 0;
  bool _monoStopsOnInteraction = false;
  Timer? _monoFallback;
  Timer? _monoBreath;

  void _beginMonologue(List<String> lines, {bool stopsOnInteraction = false}) {
    _endMonologue();
    _monoLines = lines;
    _monoIdx = 0;
    _monoStopsOnInteraction = stopsOnInteraction;
    if (lines.length <= 1) return;
    _monoFallback = Timer.periodic(const Duration(milliseconds: 4200), (_) {
      if (_state.voicePlaying) return; // live narration paces instead
      _advanceMonologue();
    });
  }

  void _advanceMonologue() {
    final lines = _monoLines;
    if (lines == null) return;
    if (_monoStopsOnInteraction &&
        (_state.phase != PlayPhase.investigating || _state.scannerActive)) {
      _endMonologue();
      return;
    }
    if (_monoIdx >= lines.length - 1) {
      _endMonologue(); // hold on the last line
      return;
    }
    _monoIdx++;
    _set(_state.copyWith(helperMessage: lines[_monoIdx]));
  }

  void _endMonologue() {
    _monoFallback?.cancel();
    _monoBreath?.cancel();
    _monoLines = null;
  }

  // ── Voice lane callbacks (from the shell's _voice player) ───────────────
  void voiceStarted() {
    if (!_state.voicePlaying) _set(_state.copyWith(voicePlaying: true));
  }

  /// Playback failed/was cut — clear the flag WITHOUT routing an advance (the
  /// reading-time fallback paces instead; instant advance would fast-cycle a
  /// monologue silently).
  void voiceInterrupted() {
    if (_state.voicePlaying) _set(_state.copyWith(voicePlaying: false));
  }

  /// THE single router for "what happens after this line ends".
  void onVoiceFinished() {
    if (_state.voicePlaying) _set(_state.copyWith(voicePlaying: false));

    // voice-paced reveal: success line done → impact message
    if (_state.phase == PlayPhase.resolving &&
        _state.helperMessage == mission.successMessage) {
      _markFound();
      return;
    }

    // active monologue → next line after a small breath
    final lines = _monoLines;
    if (lines != null &&
        _monoIdx < lines.length &&
        _state.helperMessage == lines[_monoIdx]) {
      _monoBreath?.cancel();
      _monoBreath = Timer(const Duration(milliseconds: 350), _advanceMonologue);
    }
  }

  // ── Scene transitions ──────────────────────────────────────────────────
  void startMission() {
    EdAnalytics.activityStarted();
    _set(_state.copyWith(
      scene: EdScene.tutorial,
      helperMessage: EdCopy.tutorialLines.first,
    ));
    // Orbit narrates the tutorial card (the card shows all three lines).
    _beginMonologue(EdCopy.tutorialLines);
  }

  void finishTutorial() {
    EdAnalytics.tutorialDone();
    openMission(0); // linear flow: tutorial flows straight into mission 1
  }

  void goToSelect() => _set(_state.copyWith(scene: EdScene.missionSelect));

  /// Opens mission [i] and resets all per-mission interaction state.
  void openMission(int i) {
    if (i < 0 || i >= kMissions.length) return;
    EdAnalytics.missionOpened(kMissions[i].id);
    _resolveTimer?.cancel();
    _ambientVoiced.clear();
    _set(_state.copyWith(
      scene: EdScene.missionPlay,
      missionIndex: i,
      phase: PlayPhase.investigating,
      scannerNorm: _startOffsetFor(kMissions[i]),
      scannerActive: false,
      scannerState: ScannerState.idle,
      wrongAttempts: 0,
      hintLevel: 0,
      zoomLevel: 1.0,
      sliderNorm: 0.5,
      mascotPose: MascotPose.explaining,
      helperMessage: kMissions[i].openLines.first,
    ));
    _beginMonologue(kMissions[i].openLines, stopsOnInteraction: true);
  }

  // ── Scanner drag (scan / zoom / followTrail) ───────────────────────────
  void onScannerDrag(Offset norm) {
    if (_state.phase != PlayPhase.investigating) return;
    _endMonologue(); // child is acting — Orbit stops narrating
    final clamped = Offset(norm.dx.clamp(0.0, 1.0), norm.dy.clamp(0.0, 1.0));

    // Compare mission: dragging ONLY slides the reveal divider; aiming is
    // tap-based (the target appears where the child taps — see onStageTap).
    if (mission.interactionMode == InteractionMode.compareBeforeAfter) {
      _set(_state.copyWith(
        sliderNorm: clamped.dx.clamp(0.08, 0.92),
        mascotPose: _state.mascotPose == MascotPose.explaining
            ? MascotPose.curious
            : _state.mascotPose,
      ));
      return;
    }

    final next = _scannerStateFor(clamped);
    if (!_state.scannerActive) onCue?.call(EdCue.scannerPickup);
    if (next != _state.scannerState) {
      if (next == ScannerState.near) onCue?.call(EdCue.near);
      if (next == ScannerState.lock) onCue?.call(EdCue.lock);
    }
    _set(_state.copyWith(
      scannerNorm: clamped,
      scannerActive: true,
      scannerState: next,
      // state-driven guidance so the child always knows the next action
      helperMessage: _scanMessageFor(next),
      mascotPose: next == ScannerState.lock ? MascotPose.celebrating : MascotPose.curious,
    ));
  }

  ScannerState _scannerStateFor(Offset norm) {
    if (mission.clueHitZone.contains(norm)) return ScannerState.lock;
    if (mission.clueProximityZone.contains(norm)) return ScannerState.near;
    return ScannerState.idle;
  }

  /// A start position OFFSET from the clue (opposite quadrant of the image) so
  /// aiming is a skill — the scanner never spawns sitting on the answer.
  Offset _startOffsetFor(EarthDetectiveMission m) {
    final c = m.clueCenter;
    return Offset(c.dx < 0.5 ? 0.80 : 0.20, c.dy < 0.5 ? 0.78 : 0.22);
  }

  /// State-driven guidance shown in the mascot bubble while scanning. Keeps an
  /// active hint visible when idle (doesn't clobber it).
  String _scanMessageFor(ScannerState st) {
    switch (st) {
      case ScannerState.lock:
        return EdCopy.lockPrompt;
      case ScannerState.near:
        return EdCopy.nearPrompt;
      case ScannerState.idle:
        return _state.hintLevel >= 2 ? _helperForLevel(_state.hintLevel) : EdCopy.scanHint;
    }
  }

  // ── Tap to lock / confirm ──────────────────────────────────────────────
  void onStageTap(Offset norm) {
    if (_state.phase != PlayPhase.investigating) return;
    _endMonologue();
    final clamped = Offset(norm.dx.clamp(0.0, 1.0), norm.dy.clamp(0.0, 1.0));

    // Compare mission: tap-to-aim. The target jumps to the tapped spot —
    // green lock on the changed area (resolves), cyan target on a miss.
    if (mission.interactionMode == InteractionMode.compareBeforeAfter) {
      if (mission.clueHitZone.contains(clamped)) {
        _resolveCorrect(clamped);
      } else {
        _set(_state.copyWith(
          scannerNorm: clamped,
          scannerActive: true, // first tap reveals the target
          scannerState: mission.clueProximityZone.contains(clamped)
              ? ScannerState.near
              : ScannerState.idle,
        ));
        _resolveWrong();
      }
      return;
    }

    final hit = mission.clueHitZone.contains(norm) ||
        mission.clueHitZone.contains(_state.scannerNorm);
    if (hit) {
      _resolveCorrect(norm);
    } else {
      _resolveWrong();
    }
  }

  void _resolveCorrect(Offset norm) {
    _resolveTimer?.cancel();
    onCue?.call(EdCue.correct);
    _set(_state.copyWith(
      phase: PlayPhase.resolving,
      scannerState: ScannerState.lock,
      scannerNorm: mission.clueCenter,
      scannerActive: true,
      mascotPose: MascotPose.celebrating,
      helperMessage: mission.successMessage,
      successToken: _state.successToken + 1,
      sweepToken: _state.sweepToken + 1,
    ));
    _armResolveFallback();
  }

  /// Found is voice-paced (the success line completing drives it via
  /// [onVoiceFinished]); this timer is the muted/failed-audio fallback — it
  /// re-arms while a line is live so it never cuts Orbit off mid-word.
  void _armResolveFallback() {
    _resolveTimer?.cancel();
    _resolveTimer = Timer(const Duration(milliseconds: 1600), () {
      if (_state.phase != PlayPhase.resolving) return;
      if (_state.voicePlaying) {
        _armResolveFallback();
      } else {
        _markFound();
      }
    });
  }

  void _markFound() {
    if (_state.phase != PlayPhase.resolving) return; // idempotent (timer+voice)
    final solved = {..._state.solvedMissions, _state.missionIndex};
    EdAnalytics.clueFound(mission.id, _state.wrongAttempts, _state.hintLevel);
    _set(_state.copyWith(
      phase: PlayPhase.found,
      solvedMissions: solved,
      mascotPose: MascotPose.celebrating,
      helperMessage: mission.impactExplanation,
    ));
  }

  void _resolveWrong() {
    final attempts = _state.wrongAttempts + 1;
    final level = attempts >= 4 ? 4 : attempts; // 1..4
    final newHint = level > _state.hintLevel ? level : _state.hintLevel;
    EdAnalytics.wrongTap(mission.id, attempts);
    onCue?.call(EdCue.wrong);
    _set(_state.copyWith(
      wrongAttempts: attempts,
      hintLevel: newHint,
      mascotPose: MascotPose.supportive,
      helperMessage: _helperForLevel(newHint),
      wrongToken: _state.wrongToken + 1,
    ));
  }

  String _helperForLevel(int level) {
    switch (level) {
      case 0:
      case 1:
        return EdCopy.wrongGeneric;
      case 2:
        return mission.hints[0];
      case 3:
        return mission.hints[1];
      default:
        return EdCopy.wrongRepeated; // repeated wrong taps — extra reassurance
    }
  }

  /// Manual Hint button — escalates and reveals the next hint.
  void requestHint() {
    if (_state.phase != PlayPhase.investigating) return;
    _endMonologue();
    final level = _state.hintLevel < 2 ? 2 : (_state.hintLevel + 1).clamp(2, 4);
    EdAnalytics.hintShown(mission.id, level);
    _set(_state.copyWith(
      hintLevel: level,
      mascotPose: MascotPose.curious,
      helperMessage: _helperForLevel(level),
    ));
  }

  // ── Zoom (free exploration on every scanning mission) ─────────────────
  void zoomIn() => _setZoom(_state.zoomLevel + 0.4);
  void zoomOut() => _setZoom(_state.zoomLevel - 0.4);
  void _setZoom(double z) {
    // Zoom is a free-exploration aid on every scanning mission; only the
    // before/after mission (drag = slider) opts out.
    if (mission.interactionMode == InteractionMode.compareBeforeAfter) return;
    final clamped = z.clamp(1.0, 2.4);
    if (clamped == _state.zoomLevel) return;
    onCue?.call(EdCue.scannerPickup);
    _set(_state.copyWith(zoomLevel: clamped));
  }

  // ── Found → impact → next ──────────────────────────────────────────────
  void continueToImpact() {
    _endMonologue();
    _set(_state.copyWith(scene: EdScene.missionImpact));
  }

  void nextFromImpact() {
    if (_state.allSolved) {
      EdAnalytics.allCluesFound();
      _set(_state.copyWith(
        scene: EdScene.summary,
        mascotPose: MascotPose.celebrating,
        helperMessage: EdCopy.summaryLines.first,
      ));
      _beginMonologue(EdCopy.summaryLines);
    } else {
      // linear auto-advance (Restore Earth model): straight into the next clue
      openMission(_state.missionIndex + 1);
    }
  }

  void continueFromSummary() {
    EdAnalytics.rewardShown();
    onCue?.call(EdCue.complete);
    _endMonologue();
    _set(_state.copyWith(scene: EdScene.reward));
  }

  void toggleSound() => _set(_state.copyWith(soundOn: !_state.soundOn));

  /// Idle nudge fired by the shell timer while the child lingers without acting.
  void onIdleNudge() {
    if (_state.phase != PlayPhase.investigating || _state.scannerActive) return;
    if (_monoLines != null) return; // Orbit is still doing the mission opener
    _set(_state.copyWith(
      mascotPose: MascotPose.curious,
      helperMessage: EdCopy.scanHint,
    ));
  }

  @override
  void dispose() {
    _resolveTimer?.cancel();
    _endMonologue();
    super.dispose();
  }
}
