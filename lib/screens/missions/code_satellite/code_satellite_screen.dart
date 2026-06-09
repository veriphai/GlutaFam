// Code the Satellite (Activity 10) — the Flutter shell hosting the Flame stage.
//
// Layout is a full-bleed Stack of Positioned.fill layers (playbook rule, so the
// bottom controls can never be pushed off a tall viewport):
//   cosmic background → the Flame GameWidget (built ONCE, permanent bottom layer
//   showing the satellite stage) → the scene switcher (intro / brief / play /
//   success), keyed by SceneGroup so each scene type animates in/out without
//   remounting on every notify.
//
// The controller orchestrates everything and drives the Flame stage through the
// MissionStage interface (controller → game, one-directional).

import 'package:audioplayers/audioplayers.dart';

import '../../../utils/s3_audio.dart';
import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../home/career/careerTheme.dart';
import '../../home/career/cosmicBackground.dart';
import 'config/cs_audio.dart';
import 'config/orbit_voice.dart';
import 'game/code_satellite_game.dart';
import 'scenes/brief_scene.dart';
import 'scenes/intro_scene.dart';
import 'scenes/play_scene.dart';
import 'state/code_satellite_controller.dart';
import 'state/code_satellite_state.dart';
import 'widgets/success_overlay.dart';

class CodeSatelliteScreen extends StatefulWidget {
  const CodeSatelliteScreen({super.key});

  @override
  State<CodeSatelliteScreen> createState() => _CodeSatelliteScreenState();
}

class _CodeSatelliteScreenState extends State<CodeSatelliteScreen> {
  late final CodeSatelliteController _controller;
  late final CodeSatelliteGame _game;
  late final Widget _gameWidget;
  // Two audio lanes (playbook): SFX + Orbit's voice — sharing one player would
  // cut Orbit mid-word on every snap/sparkle.
  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _voice = AudioPlayer();
  int _lastVoiceToken = 0;

  @override
  void initState() {
    super.initState();
    _game = CodeSatelliteGame();
    _controller = CodeSatelliteController(
      onSound: _playSound,
      onHaptic: HapticFeedback.selectionClick,
      onExit: _exit,
    );
    _controller.attachStage(_game);
    _gameWidget = GameWidget(game: _game); // built ONCE — never inside a rebuild
    _sfx.setReleaseMode(ReleaseMode.stop);
    _voice.setReleaseMode(ReleaseMode.stop);
    _voice.onPlayerComplete.listen((_) {
      _unduckForVoice();
      _controller.voiceFinished();
    });
    _controller.addListener(_onVoiceState);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.onFirstBuild();
      _startAudio();
    });
  }

  /// No-focus mix contexts on every lane FIRST, then start the BGM bed —
  /// otherwise the first voice line pauses the bed forever on Android.
  Future<void> _startAudio() async {
    await Future.wait<void>([
      _voice.setAudioContext(kMixAudioContext).catchError((_) {}),
      _sfx.setAudioContext(kMixAudioContext).catchError((_) {}),
    ]);
    if (!mounted) return;
    await CsBgm.I.start();
  }

  // The shell's voice lane holds at most ONE duck (lines can replace each other
  // via stop(), which never fires onPlayerComplete — a counted duck per line
  // would leak and pin the bed quiet).
  bool _bgmDuckHeld = false;
  void _duckForVoice() {
    if (!_bgmDuckHeld) {
      _bgmDuckHeld = true;
      CsBgm.I.duck();
    }
  }

  void _unduckForVoice() {
    if (_bgmDuckHeld) {
      _bgmDuckHeld = false;
      CsBgm.I.unduck();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVoiceState);
    _controller.dispose();
    _sfx.dispose();
    _voice.dispose();
    CsBgm.I.stop();
    super.dispose();
  }

  void _playSound(String assetFile) => _sfx.play(audioSource(assetFile)).catchError((_) {});

  /// Plays Orbit's line whenever the controller stamps a new voiceToken
  /// (arranging/running/failed — the static scenes own their own threads).
  /// Deferred to a microtask so we never re-enter notifyListeners.
  void _onVoiceState() {
    final s = _controller.state;
    if (s.voiceToken == _lastVoiceToken || s.voiceClip == null) return;
    _lastVoiceToken = s.voiceToken;
    final clip = s.voiceClip!;
    Future.microtask(() async {
      try {
        await _voice.stop(); // never overlap two close-together lines
        _duckForVoice();
        await _voice.play(orbitClipSource(clip));
        _controller.voiceStarted();
      } catch (_) {
        _unduckForVoice();
        _controller.voiceFailed(); // missing asset/autoplay block → advance now
      }
    });
  }

  void _exit() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: CareerColors.bgMid,
        body: Stack(
          children: [
            const Positioned.fill(child: CosmicBackground()),
            Positioned.fill(child: _gameWidget),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final s = _controller.state;
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: KeyedSubtree(
                      key: ValueKey(s.phase.sceneGroup),
                      child: _scene(s),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scene(CodeSatelliteState s) {
    switch (s.phase.sceneGroup) {
      case SceneGroup.intro:
        return IntroScene(onStart: _controller.startMission, onBack: _exit);
      case SceneGroup.brief:
        return BriefScene(onBuild: _controller.beginArranging, onBack: _exit);
      case SceneGroup.play:
        return PlayScene(state: s, controller: _controller, onBack: _exit);
      case SceneGroup.success:
        return SuccessOverlay(onContinue: _controller.nextMission);
    }
  }
}
