// Satellite Doctor (Activity 9) — the Flutter shell hosting the Flame stage.
//
// Full-bleed Stack of Positioned.fill layers (playbook rule so bottom controls
// never get pushed off a tall viewport):
//   cosmic background → the Flame GameWidget (built ONCE, permanent bottom layer
//   showing the satellite stage) → the scene overlay (intro / mission / final),
//   keyed by SceneGroup so each scene animates in/out without remounting.
//
// AUDIO (three lanes, playbook pattern):
//  • _sfx   — taps/correct/wrong/complete chimes.
//  • _voice — Orbit's lines. The controller stamps voiceClip + bumps voiceToken;
//    this screen diffs the token and plays. voiceFollowUp chains the next clip
//    on completion (inspect→teaching, final 59→60). A 12s safety Timer +
//    play().catchError both route to controller.onVoiceFinished() so a missing
//    asset or a dropped onPlayerComplete can never deadlock the voice-paced
//    fix-applied→repaired transition.
//  • _bgm   — looping ambient bed, ducked under Orbit via setVolume.
// Android audio-focus steal fix: EVERY player gets AndroidAudioFocus.none +
// iOS mixWithOthers so lanes mix; loudness is our own setVolume ducking.
//
// AssetSource paths are relative to assets/ (audioplayers adds the prefix).

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../../../utils/s3_audio.dart';
import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../home/career/cosmicBackground.dart';
import 'config/asset_paths.dart';
import 'game/satellite_doctor_game.dart';
import 'scenes/sd_scenes.dart';
import 'state/satellite_doctor_controller.dart';
import 'widgets/sd_ui.dart';

class SatelliteDoctorScreen extends StatefulWidget {
  const SatelliteDoctorScreen({super.key});

  @override
  State<SatelliteDoctorScreen> createState() => _SatelliteDoctorScreenState();
}

class _SatelliteDoctorScreenState extends State<SatelliteDoctorScreen> {
  late final SatelliteDoctorController _controller;
  late final SatelliteDoctorGame _game;
  late final Widget _gameWidget;

  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _voice = AudioPlayer();
  final AudioPlayer _bgm = AudioPlayer();
  static const double _bgmVolume = 0.20; // ambient bed
  static const double _bgmDucked = 0.05; // while Orbit speaks

  int _lastVoiceToken = 0;
  int? _pendingFollowUp;
  Timer? _voiceSafety;

  /// True while Orbit speaks — gates the intro Start CTA (dim + IgnorePointer)
  /// so kids listen to the brief before launching. Cleared on completion,
  /// safety timeout, or a missing asset, so it can never stay stuck.
  final ValueNotifier<bool> _voicePlaying = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _game = SatelliteDoctorGame();
    _controller = SatelliteDoctorController(
      onSound: _playSfx,
      onHaptic: HapticFeedback.selectionClick,
      onExit: _exit,
    );
    _controller.attachStage(_game);
    _controller.addListener(_onControllerChanged);
    _gameWidget = GameWidget(game: _game); // built ONCE — never inside a rebuild
    _sfx.setReleaseMode(ReleaseMode.stop);
    _bgm.setReleaseMode(ReleaseMode.loop);
    _voice.onPlayerComplete.listen((_) => _onVoiceDone());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.onFirstBuild();
      _startAudio();
      _playVoice(1); // Orbit's greeting
    });
  }

  /// Opt every player OUT of Android audio focus (and iOS mixWithOthers) so the
  /// voice lane can't pause the BGM loop; loudness is handled by setVolume
  /// ducking. Then start the bed. (Playbook: audio-focus steal gotcha.)
  Future<void> _startAudio() async {
    final mix = AudioContext(
      android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {AVAudioSessionOptions.mixWithOthers},
      ),
    );
    await Future.wait([
      _bgm.setAudioContext(mix).catchError((_) {}),
      _voice.setAudioContext(mix).catchError((_) {}),
      _sfx.setAudioContext(mix).catchError((_) {}),
    ]);
    _bgm.play(audioSource(SDSounds.bgm), volume: _bgmVolume).catchError((_) {});
  }

  @override
  void dispose() {
    _voiceSafety?.cancel();
    _voicePlaying.dispose();
    _controller.removeListener(_onControllerChanged);
    _voice.stop().catchError((_) {});
    _bgm.stop().catchError((_) {});
    _controller.dispose();
    _sfx.dispose();
    _voice.dispose();
    _bgm.dispose();
    super.dispose();
  }

  void _playSfx(String assetFile) =>
      _sfx.play(audioSource(assetFile)).catchError((_) {});

  // ── voice lane ────────────────────────────────────────────────────────────
  void _onControllerChanged() {
    final c = _controller;
    if (c.voiceToken != _lastVoiceToken && c.voiceClip != null) {
      _lastVoiceToken = c.voiceToken;
      _playVoice(c.voiceClip!, followUp: c.voiceFollowUp);
    }
  }

  void _playVoice(int clip, {int? followUp}) {
    _pendingFollowUp = followUp;
    _voiceSafety?.cancel();
    // safety: if onPlayerComplete never arrives (missing file / focus loss),
    // run the same completion path after 12s so nothing deadlocks.
    _voiceSafety = Timer(const Duration(seconds: 12), _onVoiceDone);
    _voicePlaying.value = true;
    _voice.stop().catchError((_) {}); // never overlap two lines
    _bgm.setVolume(_bgmDucked).catchError((_) {}); // duck the bed under Orbit
    _voice.play(audioSource(SDSounds.orbit(clip))).catchError((_) {
      _onVoiceDone(); // missing asset → advance immediately
    });
  }

  void _onVoiceDone() {
    _voiceSafety?.cancel();
    final next = _pendingFollowUp;
    _pendingFollowUp = null;
    if (next != null) {
      _playVoice(next);
      return;
    }
    _voicePlaying.value = false;
    _bgm.setVolume(_bgmVolume).catchError((_) {}); // restore the bed
    _bgm.resume().catchError((_) {}); // belt-and-braces vs focus pauses
    _controller.onVoiceFinished(); // single router (fix-applied → repaired)
  }

  void _exit() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: SDColors.bg,
        body: Stack(
          children: [
            const Positioned.fill(child: CosmicBackground()),
            Positioned.fill(child: _gameWidget),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: KeyedSubtree(
                      key: ValueKey(_controller.scene),
                      child: _scene(),
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

  Widget _scene() {
    switch (_controller.scene) {
      case SceneGroup.intro:
        return IntroScene(
            onStart: _controller.startDiagnosis,
            onBack: _exit,
            voicePlaying: _voicePlaying);
      case SceneGroup.mission:
        return MissionScene(controller: _controller, onBack: _exit);
      case SceneGroup.complete:
        return FinalScene(onReplay: _controller.replay, onExit: _exit);
    }
  }
}
