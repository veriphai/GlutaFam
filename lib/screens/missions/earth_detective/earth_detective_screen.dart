// "Earth Detective Mission" (Episode 8, Satellite Engineer) — the Flutter shell.
//
// Owns the controller + the Flame [EarthDetectiveGame] (built once so it's never
// re-attached) + SFX/haptics + the investigation idle-hint timer. Routes the
// scenes through an AnimatedSwitcher keyed by [EdScene]; only the play scene
// embeds the Flame stage.

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../../../utils/s3_audio.dart';
import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../home/career/careerTheme.dart';
import '../../home/career/cosmicBackground.dart';
import 'config/asset_paths.dart';
import 'game/earth_detective_game.dart';
import 'scenes/impact_scene.dart';
import 'scenes/intro_scene.dart';
import 'scenes/mission_play_scene.dart';
import 'scenes/mission_select_scene.dart';
import 'scenes/reward_scene.dart';
import 'scenes/summary_scene.dart';
import 'scenes/tutorial_scene.dart';
import 'state/earth_detective_controller.dart';
import 'state/earth_detective_state.dart';

class EarthDetectiveScreen extends StatefulWidget {
  const EarthDetectiveScreen({super.key});

  @override
  State<EarthDetectiveScreen> createState() => _EarthDetectiveScreenState();
}

class _EarthDetectiveScreenState extends State<EarthDetectiveScreen> {
  late final EarthDetectiveController _controller;
  late final EarthDetectiveGame _game;
  late final Widget _gameWidget;
  // Three audio lanes — sharing a player cuts Orbit mid-word (VO playbook).
  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _voice = AudioPlayer();
  final AudioPlayer _bgm = AudioPlayer();
  static const double _bgmVolume = 0.20; // ambient bed
  static const double _bgmDucked = 0.05; // under Orbit

  Timer? _idleTimer;
  Timer? _voiceSafety;
  EdScene? _lastScene;
  int _lastMission = -1;
  bool _lastScannerActive = false;
  bool _lastSoundOn = true;
  int _lastVoiceToken = 0; // initial state has voiceToken 1 → intro line fires

  @override
  void initState() {
    super.initState();
    _controller = EarthDetectiveController(onCue: _playCue);
    _game = EarthDetectiveGame(controller: _controller);
    _gameWidget = GameWidget(game: _game);
    _sfx.setReleaseMode(ReleaseMode.stop);
    _voice.setReleaseMode(ReleaseMode.stop);
    _bgm.setReleaseMode(ReleaseMode.loop);
    _voice.onPlayerComplete.listen((_) => _voiceDone());
    _controller.addListener(_onStateChanged);
    // Audio contexts must be set per-player BEFORE anything plays (Android
    // audio-focus steal gotcha) — and the first play() must wait for mount.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAudio());
  }

  /// Per-player mix context (AndroidAudioFocus.none + iOS mixWithOthers) so no
  /// lane pauses another on phones, then start the ambient loop + intro line.
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
    _bgm.play(audioSource(EdSounds.bgm), volume: _bgmVolume).catchError((_) {});
    // the controller's initial state carries Orbit's first intro line
    final s = _controller.state;
    if (s.voiceToken != _lastVoiceToken && s.voiceClip != null) {
      _lastVoiceToken = s.voiceToken;
      _playVoice(s.voiceClip!);
    }
  }

  // ── Orbit voice lane ─────────────────────────────────────────────────────
  void _playVoice(int clip) async {
    if (!_controller.state.soundOn) return; // muted: fallback timers pace
    _voiceSafety?.cancel();
    await _voice.stop(); // never overlap two lines (stop() ≠ onPlayerComplete)
    _bgm.setVolume(_bgmDucked).catchError((_) {}); // duck the bed under Orbit
    _controller.voiceStarted();
    // safety: if onPlayerComplete never arrives (focus loss / platform drop),
    // the same completion route fires so the flow can't deadlock.
    _voiceSafety = Timer(const Duration(seconds: 12), _voiceDone);
    _voice.play(audioSource(EdSounds.orbitClip(clip))).catchError((_) {
      // missing/blocked asset: clear the flag, let reading-time fallbacks pace
      _voiceSafety?.cancel();
      _bgm.setVolume(_bgmVolume).catchError((_) {});
      _controller.voiceInterrupted();
    });
  }

  void _voiceDone() {
    _voiceSafety?.cancel();
    _bgm.setVolume(_bgmVolume).catchError((_) {}); // restore the bed
    _bgm.resume().catchError((_) {});
    _controller.onVoiceFinished();
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

  void _playCue(EdCue cue) {
    if (_controller.state.soundOn) {
      final file = switch (cue) {
        EdCue.scannerPickup || EdCue.near => EdSounds.scannerPickup,
        EdCue.lock => EdSounds.lockOn,
        EdCue.correct => EdSounds.correct,
        EdCue.wrong => EdSounds.wrongSoft,
        EdCue.complete => EdSounds.complete,
      };
      _sfx.play(audioSource(file)).catchError((_) {});
    }
    switch (cue) {
      case EdCue.lock:
      case EdCue.scannerPickup:
        HapticFeedback.selectionClick();
      case EdCue.correct:
      case EdCue.complete:
        HapticFeedback.mediumImpact();
      case EdCue.near:
      case EdCue.wrong:
        break; // no / very soft haptic (PRD §17)
    }
  }

  // Idle nudge while the child lingers on a mission without scanning (PRD §23).
  void _onStateChanged() {
    final s = _controller.state;
    // Orbit speaks whenever the voice token moves (clip equality is no trigger).
    if (s.voiceToken != _lastVoiceToken) {
      _lastVoiceToken = s.voiceToken;
      if (s.voiceClip != null) _playVoice(s.voiceClip!);
    }
    // sound toggle gates the ambient bed + cuts any live line (and fires its
    // pending advance so a voice-paced flow never strands on mute).
    if (s.soundOn != _lastSoundOn) {
      _lastSoundOn = s.soundOn;
      if (s.soundOn) {
        _bgm.resume().catchError((_) {});
      } else {
        _bgm.pause().catchError((_) {});
        if (s.voicePlaying) {
          _voice.stop().catchError((_) {});
          _voiceDone();
        }
      }
    }
    if (s.scene != _lastScene || s.missionIndex != _lastMission || s.scannerActive != _lastScannerActive) {
      _lastScene = s.scene;
      _lastMission = s.missionIndex;
      _lastScannerActive = s.scannerActive;
      _idleTimer?.cancel();
      final waiting = s.scene == EdScene.missionPlay &&
          s.phase == PlayPhase.investigating &&
          !s.scannerActive;
      if (waiting) {
        _idleTimer = Timer(const Duration(seconds: 6), _controller.onIdleNudge);
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

  Widget _sceneFor(EdScene scene) {
    switch (scene) {
      case EdScene.intro:
        return KeyedSubtree(
          key: const ValueKey('intro'),
          child: IntroScene(controller: _controller, onHome: _home),
        );
      case EdScene.tutorial:
        return KeyedSubtree(
          key: const ValueKey('tutorial'),
          child: TutorialScene(controller: _controller, onHome: _home),
        );
      case EdScene.missionSelect:
        return KeyedSubtree(
          key: const ValueKey('select'),
          child: MissionSelectScene(controller: _controller, onHome: _home),
        );
      case EdScene.missionPlay:
        return KeyedSubtree(
          key: const ValueKey('play'),
          child: MissionPlayScene(controller: _controller, stage: _gameWidget, onHome: _home),
        );
      case EdScene.missionImpact:
        return KeyedSubtree(
          key: const ValueKey('impact'),
          child: ImpactScene(controller: _controller, onHome: _home),
        );
      case EdScene.summary:
        return KeyedSubtree(
          key: const ValueKey('summary'),
          child: SummaryScene(controller: _controller, onHome: _home),
        );
      case EdScene.reward:
        return KeyedSubtree(
          key: const ValueKey('reward'),
          child: RewardScene(controller: _controller, onHome: _home),
        );
    }
  }
}
