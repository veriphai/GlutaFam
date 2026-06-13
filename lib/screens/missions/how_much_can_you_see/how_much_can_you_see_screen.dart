// "How Much Can You See?" (Activity 2) — the Flutter shell.
//
// Owns the controller + the Flame [HeightStageGame] (built once so it's never
// re-attached) + SFX + the Ground idle-hint timer. Routes the eight PRD scenes
// through an AnimatedSwitcher; only Scene 2 embeds the Flame stage.

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../../../utils/s3_audio.dart';
import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/material.dart';

import '../../home/career/careerTheme.dart';
import '../../home/career/cosmicBackground.dart';
import 'config/asset_paths.dart';
import 'config/height_levels.dart';
import 'game/height_stage_game.dart';
import 'scenes/cyclone_challenge_scene.dart';
import 'scenes/exploration_scene.dart';
import 'scenes/mission_test_scene.dart';
import 'scenes/story_bridge_scene.dart';
import 'scenes/story_intro_scene.dart';
import 'scenes/success_scene.dart';
import 'scenes/teaser_scene.dart';
import '../lessonRunner.dart';
import 'state/how_much_controller.dart';
import 'state/how_much_state.dart';

class HowMuchCanYouSeeScreen extends StatefulWidget {
  const HowMuchCanYouSeeScreen({super.key});

  @override
  State<HowMuchCanYouSeeScreen> createState() => _HowMuchCanYouSeeScreenState();
}

class _HowMuchCanYouSeeScreenState extends State<HowMuchCanYouSeeScreen> {
  late final HowMuchController _controller;
  late final HeightStageGame _game;
  late final Widget _gameWidget;
  // Three audio lanes (skill rule — one player per lane): SFX on the same
  // player as voice would cut Orbit mid-word; BGM loops underneath and ducks
  // while he speaks.
  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _voice = AudioPlayer();
  final AudioPlayer _bgm = AudioPlayer();

  static const double _bgmVolume = 0.20; // ambient bed
  static const double _bgmDucked = 0.05; // while Orbit speaks

  Timer? _idleTimer;
  Timer? _voiceSafety; // clears voicePlaying if onPlayerComplete never arrives
  ViewHeightLevel? _lastLevel;
  ActivityScene? _lastScene;
  int _lastVoiceToken = 0; // state inits voiceToken at 0; first line bumps to 1

  @override
  void initState() {
    super.initState();
    _controller = HowMuchController();
    _game = HeightStageGame(controller: _controller, onSound: _playSound);
    _gameWidget = GameWidget(game: _game);
    _sfx.setReleaseMode(ReleaseMode.stop);
    _voice.setReleaseMode(ReleaseMode.stop);
    _voice.onPlayerComplete.listen((_) => _voiceDone());
    _controller.addListener(_onStateChanged);
    _bgm.setReleaseMode(ReleaseMode.loop);
    // Configure per-player mixing FIRST, then start the music bed (post-frame:
    // playing before the widget is attached fails silently on some devices).
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAudio());
  }

  /// ANDROID AUDIO-FOCUS FIX — the mix context must be set PER PLAYER.
  ///
  /// On Android every play() requests audio focus using the player's OWN
  /// AudioContextAndroid (default `AudioFocus.gain`), so the voice player
  /// starting PAUSES the looping BGM player — and focus-paused players never
  /// auto-resume. Crucially, `AudioPlayer.global.setAudioContext` only changes
  /// the DEFAULT context copied into players created AFTER it (see
  /// AudioplayersPlugin.kt: `defaultAudioContext.copy()` at create) — our three
  /// players are field initializers, created before any global call lands, so a
  /// global-only fix does nothing for them. With `AudioFocus.none` the player
  /// never requests focus (FocusManager skips the request entirely) → all
  /// in-app lanes mix, and our manual setVolume ducking handles loudness.
  /// On iOS a per-player call sets the shared session (playback+mixWithOthers,
  /// same effect). Web/desktop have no focus system — why this only failed on
  /// the phone.
  Future<void> _startAudio() async {
    if (!mounted) return;
    final mix = AudioContext(
      android: AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {AVAudioSessionOptions.mixWithOthers},
      ),
    );
    await Future.wait<void>([
      _bgm.setAudioContext(mix).catchError((_) {}),
      _voice.setAudioContext(mix).catchError((_) {}),
      _sfx.setAudioContext(mix).catchError((_) {}),
    ]);
    if (!mounted) return;
    _bgm.play(audioSource(HMSounds.bgm), volume: _bgmVolume).catchError((_) {});
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _voiceSafety?.cancel();
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    _sfx.dispose();
    _voice.dispose();
    _bgm.stop().catchError((_) {});
    _bgm.dispose();
    super.dispose();
  }

  void _playSound(String assetFile) => _sfx.play(audioSource(assetFile)).catchError((_) {});

  // ── Orbit voice lane ───────────────────────────────────────────────────────
  void _playVoice(int clip) async {
    _voiceSafety?.cancel();
    // Stop-before-play: two close-together lines must not overlap (stop() does
    // NOT fire onPlayerComplete — exactly what we want).
    await _voice.stop();
    _bgm.setVolume(_bgmDucked).catchError((_) {}); // duck the bed under Orbit
    _controller.setVoicePlaying(true);
    // Safety: if the platform drops the complete event (missing file, audio
    // focus loss), un-gate the CTAs anyway.
    _voiceSafety = Timer(const Duration(seconds: 12), _voiceDone);
    // NOTE: AssetSource is relative to assets/ (audioplayers adds the prefix).
    _voice.play(audioSource(HMSounds.orbitVoice(clip))).catchError((_) => _voiceDone());
  }

  void _voiceDone() {
    _voiceSafety?.cancel();
    _bgm.setVolume(_bgmVolume).catchError((_) {}); // restore the bed
    // Self-heal: if anything (focus loss, interruption) paused the loop,
    // bring it back — resume() is a no-op while already playing.
    _bgm.resume().catchError((_) {});
    if (mounted) _controller.setVoicePlaying(false);
  }

  // Ground idle nudge (PRD §24) + voice-token diffing.
  void _onStateChanged() {
    final s = _controller.state;

    // Play Orbit's line whenever the token moved (clip equality alone would
    // swallow a repeated line, e.g. wrong → retry → same wrong).
    if (s.voiceToken != _lastVoiceToken) {
      _lastVoiceToken = s.voiceToken;
      final clip = s.voiceClip;
      if (clip != null && clip > 0) _playVoice(clip);
    }

    if (s.scene != _lastScene || s.currentLevel != _lastLevel) {
      _lastScene = s.scene;
      _lastLevel = s.currentLevel;
      _idleTimer?.cancel();
      final waiting = s.scene == ActivityScene.heightExploration &&
          s.currentLevel == ViewHeightLevel.ground &&
          !s.hasReachedSatellite;
      if (waiting) {
        _idleTimer = Timer(const Duration(seconds: 6), _controller.onGroundIdle);
      }
    }
  }

  void _home() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: CareerColors.bgMid,
        body: Stack(
          children: [
            const Positioned.fill(child: CosmicBackground()),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.98, end: 1).animate(anim),
                        child: child,
                      ),
                    ),
                    child: _sceneFor(_controller.state.scene),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sceneFor(ActivityScene scene) {
    switch (scene) {
      case ActivityScene.storyIntro:
        return KeyedSubtree(
          key: const ValueKey('storyIntro'),
          child: StoryIntroScene(controller: _controller, onHome: _home),
        );
      case ActivityScene.missionTestIntro:
        return KeyedSubtree(
          key: const ValueKey('missionTest'),
          child: MissionTestScene(controller: _controller, onHome: _home),
        );
      case ActivityScene.heightExploration:
        return KeyedSubtree(
          key: const ValueKey('exploration'),
          child: ExplorationScene(controller: _controller, stage: _gameWidget, onHome: _home),
        );
      case ActivityScene.cycloneChallenge:
      case ActivityScene.wrongAnswerFeedback:
        return KeyedSubtree(
          key: const ValueKey('challenge'),
          child: CycloneChallengeScene(
              controller: _controller, onHome: _home, onSound: _playSound),
        );
      case ActivityScene.correctAnswerSuccess:
        // After the MCQ success the activity EXITS directly (CONTINUE → onExit).
        // The story-bridge + teaser scenes below are bypassed for now; to
        // restore them, change the SuccessScene CTA back to
        // controller.continueFromSuccess.
        return KeyedSubtree(
          key: const ValueKey('success'),
          child: SuccessScene(controller: _controller, onExit: () => completeActivity(context), onSound: _playSound),
        );
      // --- Bypassed for now (kept for easy restore) -------------------------
      case ActivityScene.successStoryBeat:
        return KeyedSubtree(
          key: const ValueKey('bridge'),
          child: StoryBridgeScene(controller: _controller),
        );
      case ActivityScene.nextMissionTeaser:
        return KeyedSubtree(
          key: const ValueKey('teaser'),
          child: TeaserScene(controller: _controller, onNext: () => completeActivity(context)),
        );
    }
  }
}
