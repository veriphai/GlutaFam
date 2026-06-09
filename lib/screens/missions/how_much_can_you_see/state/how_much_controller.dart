// HOW ACTIVITY 2 STATE UPDATES.
//
// One ChangeNotifier owns the immutable [HeightViewActivityState]. The Flutter
// rail calls setLevel(); the Flame stage + Flutter shell rebuild from state. No
// Riverpod (self-contained activity).
//
// Flow (PRD §16): storyIntro → missionTestIntro → heightExploration (drag the
// camera Ground→…→Satellite) → [satellite reveal, then unlock] → cycloneChallenge
// → (wrong feedback / retry) → correctAnswerSuccess → successStoryBeat →
// nextMissionTeaser.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/asset_paths.dart';
import '../config/challenge_options.dart';
import '../config/height_levels.dart';
import 'analytics.dart';
import 'how_much_state.dart';

/// Outcome of a challenge tap, returned to the scene so it can play visuals.
enum ChallengeOutcome { wrong, correct }

class HowMuchController extends ChangeNotifier {
  HowMuchController({HowMuchAnalytics? analytics})
      : analytics = analytics ?? const HowMuchAnalytics(),
        _state = const HeightViewActivityState(
          scene: ActivityScene.storyIntro,
          currentLevel: ViewHeightLevel.ground,
          visitedLevels: {},
          hasReachedSatellite: false,
          challengeUnlocked: false,
          challengeCompleted: false,
          selectedChallengeOption: null,
          missionControlMessage: '',
          mascot: MascotMood.idle,
        );

  final HowMuchAnalytics analytics;
  HeightViewActivityState _state;
  HeightViewActivityState get state => _state;

  int _totalWrong = 0;
  Timer? _satelliteUnlockTimer;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _satelliteUnlockTimer?.cancel();
    super.dispose();
  }

  void _set(HeightViewActivityState s) {
    if (_disposed) return;
    _state = s;
    notifyListeners();
  }

  // ── Scene 0 → 1 ───────────────────────────────────────────────────────────
  void startViewTest() {
    if (_state.scene != ActivityScene.storyIntro) return;
    analytics.activityStarted();
    _set(_state.copyWith(
      scene: ActivityScene.missionTestIntro,
      mascot: MascotMood.pointing,
      voiceClip: HMSounds.vcTestIntro,
      voiceToken: _state.voiceToken + 1,
    ));
  }

  // ── Scene 1 → 2 (begin exploration at Ground) ──────────────────────────────
  void beginExploration() {
    if (_state.scene != ActivityScene.missionTestIntro) return;
    analytics.viewTestStarted();
    const first = ViewHeightLevel.ground;
    final cfg = kHeightLevels[first]!;
    analytics.heightLevelViewed(first);
    _set(_state.copyWith(
      scene: ActivityScene.heightExploration,
      currentLevel: first,
      visitedLevels: {first},
      missionControlMessage: cfg.missionText,
      mascot: MascotMood.idle,
      showDragHint: false,
      voiceClip: cfg.voiceClip,
      voiceToken: _state.voiceToken + 1,
    ));
  }

  // ── Scene 2: drag the camera to a level (PRD §19) ──────────────────────────
  void setLevel(ViewHeightLevel level) {
    if (_state.scene != ActivityScene.heightExploration) return;
    if (level == _state.currentLevel && _state.visitedLevels.contains(level)) {
      // Re-selecting the same level: still clear the drag hint, no churn.
      if (_state.showDragHint) _set(_state.copyWith(showDragHint: false));
      return;
    }
    final cfg = kHeightLevels[level]!;
    final visited = {..._state.visitedLevels, level};
    analytics.heightLevelViewed(level);

    final reachedSatNow = level == ViewHeightLevel.satellite && !_state.hasReachedSatellite;
    _set(_state.copyWith(
      currentLevel: level,
      visitedLevels: visited,
      missionControlMessage: cfg.missionText,
      hasReachedSatellite: _state.hasReachedSatellite || level == ViewHeightLevel.satellite,
      showDragHint: false,
      mascot: level == ViewHeightLevel.satellite ? MascotMood.thumbsUp : MascotMood.idle,
      voiceClip: cfg.voiceClip,
      voiceToken: _state.voiceToken + 1,
    ));

    // Satellite "aha": let the reveal breathe, THEN unlock the challenge (PRD §10).
    if (reachedSatNow) {
      analytics.satelliteReached();
      _satelliteUnlockTimer?.cancel();
      _satelliteUnlockTimer = Timer(const Duration(milliseconds: 1800), () {
        if (_state.scene != ActivityScene.heightExploration) return;
        _set(_state.copyWith(challengeUnlocked: true, showTakeChallenge: true));
      });
    }
  }

  /// Idle nudge if the child lingers on Ground (PRD §24).
  void onGroundIdle() {
    if (_state.scene != ActivityScene.heightExploration) return;
    if (_state.currentLevel != ViewHeightLevel.ground) return;
    if (_state.hasReachedSatellite) return;
    _set(_state.copyWith(showDragHint: true));
  }

  // ── Scene 2 → 8 ─────────────────────────────────────────────────────────
  void takeChallenge() {
    if (!_state.challengeUnlocked) return; // never before satellite (PRD §24)
    analytics.challengeOpened();
    _set(_state.copyWith(
      scene: ActivityScene.cycloneChallenge,
      selectedChallengeOption: null,
      mascot: MascotMood.pointing,
      voiceClip: HMSounds.vcChallenge,
      voiceToken: _state.voiceToken + 1,
    ));
  }

  // ── Scene 8: tap an option (PRD §19/§20) ───────────────────────────────────
  ChallengeOutcome selectChallengeOption(ChallengeOptionId option) {
    final correct = option == kCorrectChallengeOption;
    if (correct) {
      analytics.challengeAnswered(option.name, true, _state.wrongAttempts + 1);
      _set(_state.copyWith(
        challengeCompleted: true,
        selectedChallengeOption: option,
        mascot: MascotMood.thumbsUp,
      ));
      return ChallengeOutcome.correct;
    }
    final attempt = _state.wrongAttempts + 1;
    _totalWrong++;
    analytics.challengeAnswered(option.name, false, attempt);
    _set(_state.copyWith(
      scene: ActivityScene.wrongAnswerFeedback,
      selectedChallengeOption: option,
      wrongAttempts: attempt,
      // PRD §12/§24: pulse the satellite card after repeated misses.
      hintPulseSatellite: attempt >= 1,
      missionControlMessage: challengeOption(option).wrongFeedback,
      wrongShakeToken: _state.wrongShakeToken + 1,
      wrongShakeOption: option,
      mascot: MascotMood.oops,
      // Voice matches what the bubble shows: option line, or the hint after 2+.
      voiceClip: attempt >= 2 ? HMSounds.vcHint : challengeOption(option).wrongVoiceClip,
      voiceToken: _state.voiceToken + 1,
    ));
    return ChallengeOutcome.wrong;
  }

  /// Scene calls this once the correct-card glow/sparkle has played.
  void confirmCorrect() {
    if (!_state.challengeCompleted) return;
    _set(_state.copyWith(scene: ActivityScene.correctAnswerSuccess, mascot: MascotMood.thumbsUp));
  }

  /// Success scene calls this when the capture sequence ends and the outcome
  /// (Orbit's bubble) appears — that's when the success line should speak.
  bool _successVoicePlayed = false;
  void onSuccessOutcomeShown() {
    if (_state.scene != ActivityScene.correctAnswerSuccess || _successVoicePlayed) return;
    _successVoicePlayed = true;
    _set(_state.copyWith(
      voiceClip: HMSounds.vcSuccess,
      voiceToken: _state.voiceToken + 1,
    ));
  }

  /// Owned by the shell around its voice player; primary CTAs gate on it.
  void setVoicePlaying(bool playing) {
    if (_state.voicePlaying == playing) return;
    _set(_state.copyWith(voicePlaying: playing));
  }

  // ── Scene 9 → 10 → 11 ──────────────────────────────────────────────────────
  void continueFromSuccess() {
    _set(_state.copyWith(scene: ActivityScene.successStoryBeat, mascot: MascotMood.thumbsUp));
  }

  void continueFromBridge() {
    _set(_state.copyWith(scene: ActivityScene.nextMissionTeaser, mascot: MascotMood.idle));
  }

  void finishAndAdvance() {
    analytics.activityCompleted(_totalWrong);
    analytics.nextMissionClicked();
  }
}
