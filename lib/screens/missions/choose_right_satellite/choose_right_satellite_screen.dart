// "Choose the Right Satellite" (Episode 5 / Activity 5) — the Flutter shell.
//
// Owns the controller + the SFX player + the sound toggle. Routes the four
// scene types (intro / missionPlay / missionLog / bridge) through an
// AnimatedSwitcher keyed by scene, over the Mission Control background. Pure
// Flutter — drag/drop is Draggable/DragTarget, effects are AnimationControllers
// inside the scenes. Shell layers are Positioned.fill so the Column is
// height-bounded and bottom controls stay on-screen on tall phones.

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../../../utils/s3_audio.dart';
import 'package:flutter/material.dart';

import '../../home/career/careerTheme.dart';
import 'config/asset_paths.dart';
import 'scenes/bridge_scene.dart';
import 'scenes/intro_scene.dart';
import 'scenes/mission_log_scene.dart';
import 'scenes/mission_play_scene.dart';
import 'state/analytics.dart';
import 'state/choose_satellite_controller.dart';
import 'state/choose_satellite_state.dart';
import '../../../utils/s3_assets.dart';

class ChooseRightSatelliteScreen extends StatefulWidget {
  const ChooseRightSatelliteScreen({super.key});

  @override
  State<ChooseRightSatelliteScreen> createState() => _ChooseRightSatelliteScreenState();
}

class _ChooseRightSatelliteScreenState extends State<ChooseRightSatelliteScreen> {
  late final ChooseSatelliteController _controller;
  final AudioPlayer _sfx = AudioPlayer(); // lane 1: one-shot SFX
  final AudioPlayer _ambient = AudioPlayer(); // lane 2: looping scene bed
  final AudioPlayer _voice = AudioPlayer(); // lane 3: Orbit VO
  final AudioPlayer _bgm = AudioPlayer(); // lane 4: looping music bed
  final ChooseSatelliteAnalytics _analytics = const ChooseSatelliteAnalytics();
  bool _soundOn = true;

  static const double _bgmVol = 0.15; // under the scene ambient (0.3)

  String? _currentAmbient;
  double _ambientBaseVol = 0.3;
  bool _ducked = false;
  ActivityScene? _lastScene;
  int _lastMissionIndex = 0;

  int _lastVoiceToken = 0;
  Timer? _readTimer; // muted/no-audio reading-time fallback
  Timer? _safetyTimer; // voice completion never arrived
  Timer? _breathTimer; // ~350ms pause between lines

  @override
  void initState() {
    super.initState();
    _controller = ChooseSatelliteController();
    _sfx.setReleaseMode(ReleaseMode.stop);
    _ambient.setReleaseMode(ReleaseMode.loop);
    _voice.setReleaseMode(ReleaseMode.stop);
    _bgm.setReleaseMode(ReleaseMode.loop);
    _voice.onPlayerComplete.listen((_) => _voiceDone());
    _controller.addListener(_onState);
    // Configure per-player mixing FIRST, then kick off ambient + first line
    // (post-frame: playing before the widget is attached fails silently).
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAudio());
  }

  /// ANDROID AUDIO-FOCUS FIX — the mix context must be set PER PLAYER. With the
  /// default `AudioFocus.gain`, the voice player starting PAUSES the looping
  /// ambient player and it never auto-resumes. `AudioFocus.none` means no focus
  /// request → all in-app lanes mix; loudness is handled by setVolume ducking.
  /// (See how_much_can_you_see for the full write-up.)
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
      _sfx.setAudioContext(mix).catchError((_) {}),
      _ambient.setAudioContext(mix).catchError((_) {}),
      _voice.setAudioContext(mix).catchError((_) {}),
      _bgm.setAudioContext(mix).catchError((_) {}),
    ]);
    if (!mounted) return;
    // Music bed first (contexts must be set BEFORE the first play), then the
    // intro ambient + first Orbit line (which will duck the beds).
    _bgm.play(audioSource(CrsSounds.bgm), volume: _bgmVol).catchError((_) {});
    _onState();
  }

  @override
  void dispose() {
    _readTimer?.cancel();
    _safetyTimer?.cancel();
    _breathTimer?.cancel();
    _controller.removeListener(_onState);
    _controller.dispose();
    _sfx.dispose();
    _ambient.dispose();
    _voice.dispose();
    _bgm.dispose();
    super.dispose();
  }

  void _playSound(String assetFile) {
    if (!_soundOn) return;
    _sfx.play(audioSource(assetFile)).catchError((_) {});
  }

  // Drives ambient/alert/fanfare/voice off controller state transitions.
  void _onState() {
    final s = _controller.state;
    _applyAmbient(_desiredAmbient(s));
    // Alert ping when a new mission appears.
    if (s.scene == ActivityScene.missionPlay &&
        (_lastScene != ActivityScene.missionPlay || s.currentMissionIndex != _lastMissionIndex)) {
      _playSound(CrsSounds.missionAlert);
    }
    // Fanfare when the mission log (activity complete) appears.
    if (s.scene == ActivityScene.missionLog && _lastScene != ActivityScene.missionLog) {
      _playSound(CrsSounds.finishFanfare);
    }
    _lastScene = s.scene;
    _lastMissionIndex = s.currentMissionIndex;

    // Voice: play whenever the token moves (clip equality alone misses repeats).
    if (s.voiceToken != _lastVoiceToken) {
      _lastVoiceToken = s.voiceToken;
      _playCurrentLine();
    }
  }

  // --- Orbit voice lane ------------------------------------------------------

  void _playCurrentLine() {
    _readTimer?.cancel();
    _safetyTimer?.cancel();
    _breathTimer?.cancel();
    final line = _controller.currentLine;

    if (!_soundOn || line.clip == null || line.text.isEmpty) {
      // Muted / text-only: advance on reading time so the flow never strands.
      _controller.setVoicePlaying(false);
      _duck(false);
      _voice.stop().catchError((_) {});
      _readTimer = Timer(const Duration(milliseconds: 3800), _controller.onVoiceFinished);
      return;
    }

    _controller.setVoicePlaying(true);
    _duck(true);
    _startClip(line.clip!);
    // Safety net: if onPlayerComplete never arrives (focus loss, platform drop),
    // route the same finish handler instead of deadlocking the sequence.
    _safetyTimer = Timer(const Duration(seconds: 15), _voiceDone);
  }

  Future<void> _startClip(int clip) async {
    try {
      // Stop before play so close-together lines never overlap (stop() does NOT
      // fire onPlayerComplete — exactly what we want).
      await _voice.stop();
      if (!mounted) return;
      await _voice.play(audioSource(CrsSounds.orbitClip(clip)), volume: 1.0);
    } catch (_) {
      // Missing asset / web autoplay block: fall back to reading-time pacing.
      if (!mounted) return;
      _controller.setVoicePlaying(false);
      _duck(false);
      _readTimer = Timer(const Duration(milliseconds: 3800), _controller.onVoiceFinished);
    }
  }

  void _voiceDone() {
    _safetyTimer?.cancel();
    if (!mounted) return;
    _controller.setVoicePlaying(false);
    _duck(false);
    // Small breath between lines, then ONE router decides what comes next.
    _breathTimer = Timer(const Duration(milliseconds: 350), _controller.onVoiceFinished);
  }

  /// Duck the ambient + music beds while Orbit speaks; restore after.
  void _duck(bool on) {
    _ducked = on;
    _ambient.setVolume(on ? _ambientBaseVol * 0.25 : _ambientBaseVol).catchError((_) {});
    _bgm.setVolume(on ? _bgmVol * 0.3 : _bgmVol).catchError((_) {});
  }

  String? _desiredAmbient(ChooseSatelliteState s) {
    switch (s.scene) {
      case ActivityScene.missionPlay:
        return _controller.mission.ambientSound;
      case ActivityScene.intro:
      case ActivityScene.missionLog:
      case ActivityScene.bridge:
        return CrsSounds.ambControl;
    }
  }

  void _applyAmbient(String? file) {
    if (!_soundOn || file == null) {
      _stopAmbient();
      return;
    }
    if (file == _currentAmbient) return;
    _currentAmbient = file;
    _ambientBaseVol = file == CrsSounds.ambControl ? 0.22 : 0.3;
    _ambient.stop();
    _ambient
        .play(audioSource(file), volume: _ducked ? _ambientBaseVol * 0.25 : _ambientBaseVol)
        .catchError((_) {});
  }

  void _stopAmbient() {
    _currentAmbient = null;
    _ambient.stop().catchError((_) {});
  }

  void _toggleSound() {
    setState(() => _soundOn = !_soundOn);
    if (_soundOn) {
      _bgm.play(audioSource(CrsSounds.bgm), volume: _bgmVol).catchError((_) {});
      _applyAmbient(_desiredAmbient(_controller.state));
      _playCurrentLine(); // resume narration from the current line
    } else {
      _bgm.stop().catchError((_) {});
      _stopAmbient();
      // Muting must never strand the flow: keep advancing at reading pace.
      _voice.stop().catchError((_) {});
      _playCurrentLine(); // takes the muted branch -> reading-time fallback
    }
  }

  void _home() => Navigator.of(context).maybePop();

  void _onNextActivity() {
    _analytics.nextActivityClicked();
    // Power Up the Satellite activity is not built yet — return to the hub.
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: CareerColors.bgMid,
        body: Stack(
          children: [
            // Mission Control room background (PRD §9.1), with a dark overlay
            // for text readability.
            Positioned.fill(
              child: netImageWidget(
                CrsAssets.missionControlBg,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => const ColoredBox(color: CareerColors.bgMid),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      CareerColors.bgTop.withValues(alpha: 0.35),
                      CareerColors.bgBottom.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 460),
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
      case ActivityScene.intro:
        return KeyedSubtree(
          key: const ValueKey('intro'),
          child: IntroScene(
            controller: _controller,
            onHome: _home,
            soundOn: _soundOn,
            onToggleSound: _toggleSound,
          ),
        );
      case ActivityScene.missionPlay:
        return KeyedSubtree(
          key: const ValueKey('missionPlay'),
          child: MissionPlayScene(
            controller: _controller,
            onSound: _playSound,
            onHome: _home,
            soundOn: _soundOn,
            onToggleSound: _toggleSound,
          ),
        );
      case ActivityScene.missionLog:
        return KeyedSubtree(
          key: const ValueKey('missionLog'),
          child: MissionLogScene(
            controller: _controller,
            onHome: _home,
            soundOn: _soundOn,
            onToggleSound: _toggleSound,
          ),
        );
      // NOTE: the bridge / next-activity teaser ("Power Up the Satellite") is
      // currently UNREACHABLE — the activity completes at the Mission Log (see
      // mission_log_scene.dart, FINISH button). Kept wired so restoring it is a
      // one-line change (point the log's CTA back to controller.toBridge).
      case ActivityScene.bridge:
        return KeyedSubtree(
          key: const ValueKey('bridge'),
          child: BridgeScene(
            controller: _controller,
            onNext: _onNextActivity,
            onHome: _home,
            soundOn: _soundOn,
            onToggleSound: _toggleSound,
          ),
        );
    }
  }
}
