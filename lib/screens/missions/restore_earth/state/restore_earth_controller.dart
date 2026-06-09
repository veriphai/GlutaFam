// HOW MISSION STATE UPDATES.
//
// One ChangeNotifier owns the immutable [RestoreEarthState]. The Flame game
// calls it at gameplay beats (power select happens in Flutter; release/repair in
// Flame), and the Flutter shell rebuilds via ListenableBuilder. No Riverpod.
//
// Flow: startMission → (per scenario) selectPower → game aims+fires →
// onBeamReleased returns miss/wrong/correct → on correct the game plays the
// repair timeline then calls onRepairComplete + advanceToNext → … → complete.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/powers.dart';
import '../config/scenarios.dart';
import 'analytics.dart';
import 'restore_earth_state.dart';

enum BeamOutcome { miss, wrong, correct }

class RestoreEarthController extends ChangeNotifier {
  RestoreEarthController({RestoreEarthAnalytics? analytics})
      : analytics = analytics ?? const RestoreEarthAnalytics(),
        _state = const RestoreEarthState(
          phase: ActivityPhase.intro,
          scenarioIndex: 0,
          solvedCount: 0,
          selectedPower: null,
          wrongAttempts: 0,
          missionText: 'I’ll show you four satellite powers: Location, Weather, Signal, and Scan. We’ll use them to help Earth.',
          mascot: MascotMood.idle,
          voiceClip: 2, // game-intro line
          voiceToken: 1,
        );

  final RestoreEarthAnalytics analytics;
  RestoreEarthState _state;
  RestoreEarthState get state => _state;

  DateTime _activityStart = DateTime.now();
  DateTime _scenarioStart = DateTime.now();
  int _totalWrong = 0;

  /// Set by the Flame game once it's ready to clean up the current problem
  /// and move to the next scenario. The controller invokes it AFTER Orbit's
  /// learning line finishes (driven by the screen's onPlayerComplete stream),
  /// so the next scenario never spawns over a still-speaking line.
  VoidCallback? onAdvanceReady;

  // Safety: in case the audio file is missing / interrupted and the screen
  // never delivers an onPlayerComplete, this fires the next step anyway so
  // the activity can't get stuck waiting for a voice that never ends.
  Timer? _voiceSafety;
  void _scheduleVoiceSafety() {
    _voiceSafety?.cancel();
    _voiceSafety = Timer(const Duration(seconds: 12), onVoiceFinished);
  }

  void _cancelVoiceSafety() {
    _voiceSafety?.cancel();
    _voiceSafety = null;
  }

  @override
  void dispose() {
    _cancelVoiceSafety();
    super.dispose();
  }

  ScenarioDef get currentScenario => kScenarios[_state.scenarioIndex];

  /// The closing monologue (clip, text) in play order. The next-episode hook
  /// (clip 54: "But now I'm wondering… why do these helpers need to be so high
  /// up in space?") is intentionally commented out — kids exit on Continue
  /// after Final 3 instead.
  static const List<(int, String)> _finalSequence = [
    (51, 'Amazing! We brought all Earth systems back online.'),
    (52, 'You used four satellite powers: Location, Weather, Signal, and Scan.'),
    (53, 'That’s why satellites matter. They help Earth find, watch, connect, and see.'),
    // (54, 'But now I’m wondering… why do these helpers need to be so high up in space?'),
  ];

  // ── Start ────────────────────────────────────────────────────────────────
  void startMission() {
    if (_state.phase != ActivityPhase.intro) return;
    _activityStart = DateTime.now();
    analytics.activityStarted();
    _spawnScenario(0);
  }

  void _spawnScenario(int index) {
    _cancelVoiceSafety();
    _scenarioStart = DateTime.now();
    final s = kScenarios[index];
    _state = _state.copyWith(
      phase: ActivityPhase.playing,
      scenarioIndex: index,
      selectedPower: null,
      wrongAttempts: 0,
      hintPulsePower: null,
      missionText: s.copy.spawn,
      mascot: MascotMood.idle,
      voiceClip: s.voiceBase + 0, // spawn
      voiceToken: _state.voiceToken + 1,
    );
    analytics.scenarioSpawned(s.id, s.round);
    notifyListeners();
  }

  // ── Power selection (from the Flutter buttons) ─────────────────────────────
  void selectPower(PowerId id) {
    if (_state.phase != ActivityPhase.playing) return;
    _state = _state.copyWith(
      selectedPower: id,
      missionText: power(id).aimCopy,
      mascot: MascotMood.idle,
      hintPulsePower: null,
      voiceClip: power(id).aimVoice,
      voiceToken: _state.voiceToken + 1,
    );
    analytics.powerSelected(currentScenario.id, id.name);
    notifyListeners();
  }

  // ── Beam released (from the Flame game) ────────────────────────────────────
  /// [targetHit] = reticle was within the active hotspot. Returns what the game
  /// should visually play. State (text/hints/progress) is applied here.
  BeamOutcome onBeamReleased(bool targetHit) {
    final s = currentScenario;
    final selected = _state.selectedPower;
    if (selected == null) return BeamOutcome.miss;

    analytics.beamReleased(s.id, selected.name, targetHit);

    // Missed target is NOT counted as a wrong power (PRD §25).
    if (!targetHit) {
      _state = _state.copyWith(
        missionText: 'Almost! Move the glowing target closer to the blinking problem.',
        mascot: MascotMood.hint,
        voiceClip: 7, // miss
        voiceToken: _state.voiceToken + 1,
      );
      notifyListeners();
      return BeamOutcome.miss;
    }

    if (selected != s.correctPower) {
      final attempt = _state.wrongAttempts + 1;
      _totalWrong++;
      final hint = attempt <= 1
          ? s.copy.wrong1
          : attempt == 2
              ? s.copy.wrong2
              : s.copy.wrong3;
      analytics.wrongPowerUsed(s.id, selected.name, s.correctPower.name, attempt);
      analytics.hintShown(s.id, attempt);
      _state = _state.copyWith(
        wrongAttempts: attempt,
        missionText: hint,
        mascot: MascotMood.oops,
        hintPulsePower: attempt >= 2 ? s.correctPower : null,
        wrongShakeToken: _state.wrongShakeToken + 1,
        wrongShakePower: selected,
        // wrong1 → base+1, wrong2 → base+2, wrong3 → base+3 (capped at +3).
        voiceClip: s.voiceBase + attempt.clamp(1, 3),
        voiceToken: _state.voiceToken + 1,
      );
      notifyListeners();
      return BeamOutcome.wrong;
    }

    // Correct: the game plays the beam + repair timeline.
    _state = _state.copyWith(phase: ActivityPhase.repairing, mascot: MascotMood.excited);
    notifyListeners();
    return BeamOutcome.correct;
  }

  /// Game calls this when the correct-repair visual timeline finishes.
  /// Plays the success voice; advancement to learning + the next scenario is
  /// driven by [onVoiceFinished] (called by the screen on player-complete).
  void onRepairComplete() {
    final s = currentScenario;
    final solved = _state.solvedCount + 1;
    analytics.scenarioCompleted(
        s.id, _state.wrongAttempts + 1, DateTime.now().difference(_scenarioStart).inMilliseconds);
    _state = _state.copyWith(
      solvedCount: solved,
      missionText: s.copy.success,
      mascot: MascotMood.excited,
      selectedPower: null,
      hintPulsePower: null,
      voiceClip: s.voiceBase + 4, // success
      voiceToken: _state.voiceToken + 1,
    );
    notifyListeners();
    _scheduleVoiceSafety();
  }

  /// Game calls this a beat after [onRepairComplete] to move on (or finish).
  void advanceToNext() {
    if (_state.solvedCount >= kScenarioCount) {
      _enterComplete();
    } else {
      _spawnScenario(_state.scenarioIndex + 1);
    }
  }

  void _enterComplete() {
    analytics.activityCompleted(
        DateTime.now().difference(_activityStart).inMilliseconds, _totalWrong);
    _cancelVoiceSafety();
    final (clip, text) = _finalSequence.first;
    _state = _state.copyWith(
      phase: ActivityPhase.complete,
      missionText: text,
      mascot: MascotMood.celebrate,
      selectedPower: null,
      hintPulsePower: null,
      voiceClip: clip,
      voiceToken: _state.voiceToken + 1,
    );
    notifyListeners();
    _scheduleVoiceSafety();
  }

  // ── Voice-driven advancement ─────────────────────────────────────────────
  /// Screen calls this when the current Orbit voice clip finishes (or after a
  /// safety timeout if onPlayerComplete never fires). Drives the only beats
  /// that *should* wait for Orbit:
  ///   • repairing + success(N+4) → swap to learning(N+5)
  ///   • repairing + learning(N+5) → tell the game to clean up + advance
  ///   • complete + final-1..3 → swap to next final line
  /// Everything else (spawn, aim, wrong, miss, idle, hook) is a no-op.
  void onVoiceFinished() {
    _cancelVoiceSafety();
    final clip = _state.voiceClip;
    if (clip == null) return;

    if (_state.phase == ActivityPhase.repairing) {
      final base = currentScenario.voiceBase;
      if (clip == base + 4) {
        // Success done → say the teaching line.
        _state = _state.copyWith(
          missionText: currentScenario.copy.learning,
          voiceClip: base + 5,
          voiceToken: _state.voiceToken + 1,
        );
        notifyListeners();
        _scheduleVoiceSafety();
        return;
      }
      if (clip == base + 5) {
        // Learning done → let the game clean up the current problem and
        // call advanceToNext (which spawns the next scenario or completes).
        onAdvanceReady?.call();
        return;
      }
    }

    if (_state.phase == ActivityPhase.complete) {
      final i = _finalSequence.indexWhere((e) => e.$1 == clip);
      if (i >= 0 && i + 1 < _finalSequence.length) {
        final (nextClip, nextText) = _finalSequence[i + 1];
        _state = _state.copyWith(
          missionText: nextText,
          voiceClip: nextClip,
          voiceToken: _state.voiceToken + 1,
        );
        notifyListeners();
        _scheduleVoiceSafety();
      } else if (i == _finalSequence.length - 1) {
        // Final line just finished — light up Continue.
        _state = _state.copyWith(continueEnabled: true);
        notifyListeners();
      }
      return;
    }
  }

  // ── Idle nudge (PRD §33.1) ─────────────────────────────────────────────────
  void onIdleHint() {
    if (_state.phase != ActivityPhase.playing || _state.selectedPower == null) return;
    _state = _state.copyWith(
      missionText: 'Drag the glowing target onto the problem. I’ll keep the beam ready.',
      mascot: MascotMood.hint,
      voiceClip: 8, // idle
      voiceToken: _state.voiceToken + 1,
    );
    notifyListeners();
  }

  void nextMission() => analytics.nextMissionClicked('satellite_engineer_ep2');
}
