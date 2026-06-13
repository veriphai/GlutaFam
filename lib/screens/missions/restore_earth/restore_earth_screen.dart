// Satellite Superpowers — Restore Earth: the Flutter shell hosting the Flame
// stage (PRD §31.3). Owns the controller + game + SFX + idle-hint timer; lays
// out header / rail / stage(+zone labels) / mission panel / power panel / CTA.

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../../../utils/s3_audio.dart';
import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/material.dart';

import '../../home/career/careerTheme.dart';
import '../../home/career/cosmicBackground.dart';
import 'config/powers.dart';
import 'game/restore_earth_game.dart';
import 'restore_earth_intro_screen.dart' show RestoreEarthIntroScene;
import 'state/restore_earth_controller.dart';
import 'state/restore_earth_state.dart';
import 'widgets/activity_header.dart';
import 'widgets/cta_button.dart';
import 'widgets/mission_panel.dart';
import 'widgets/power_panel.dart';
import 'widgets/progress_rail.dart';
import 'widgets/zone_labels.dart';
import '../lessonRunner.dart';

class RestoreEarthScreen extends StatefulWidget {
  const RestoreEarthScreen({super.key});

  @override
  State<RestoreEarthScreen> createState() => _RestoreEarthScreenState();
}

class _RestoreEarthScreenState extends State<RestoreEarthScreen> {
  late final RestoreEarthController _controller;
  late final RestoreEarthGame _game;
  late final Widget _gameWidget;
  // Three audio lanes (skill rule — one player per lane): SFX on the same
  // player as voice would cut Orbit mid-word; BGM loops underneath and
  // ducks while Orbit speaks.
  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _voice = AudioPlayer();
  final AudioPlayer _bgm = AudioPlayer();
  StreamSubscription<void>? _voiceCompleteSub;

  static const double _bgmVolume = 0.20; // ambient bed
  static const double _bgmDucked = 0.05; // while Orbit speaks

  Timer? _idleTimer;
  Timer? _voiceSafetyScreen; // restores BGM if onPlayerComplete never arrives
  bool _voiceDucked = false;
  PowerId? _lastSelected;
  int _lastVoiceToken = 0;

  /// While true the cover intro is on screen. The gameplay voice queue is
  /// suppressed, the screen plays the cover voice line directly, and the
  /// `_voice` player's onPlayerComplete does NOT advance the controller.
  bool _introVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = RestoreEarthController();
    _game = RestoreEarthGame(controller: _controller, onSound: _playSound);
    _gameWidget = GameWidget(game: _game);
    _sfx.setReleaseMode(ReleaseMode.stop);
    _voice.setReleaseMode(ReleaseMode.stop);
    _bgm.setReleaseMode(ReleaseMode.loop);
    // Match the controller's initial voiceToken so the gameplay-intro line
    // (game-intro / orbit_02) does NOT auto-play while the cover is up.
    _lastVoiceToken = _controller.state.voiceToken;
    _voiceCompleteSub = _voice.onPlayerComplete.listen((_) {
      if (!mounted) return;
      _restoreBgm();
      // While the cover scene is up, the playing clip is orbit_01 — it's
      // NOT in the controller's voice queue, so don't advance.
      if (_introVisible) return;
      _controller.onVoiceFinished();
    });
    _controller.addListener(_onStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAudio());
  }

  /// Intro scene's Start Mission button. Hides the cover, kicks off the
  /// gameplay voice flow. BGM keeps playing — we never restart the player.
  void _onStartMission() {
    if (!_introVisible) return;
    setState(() => _introVisible = false);
    _lastVoiceToken = -1; // force the next _maybePlayVoice to fire
    _maybePlayVoice();
  }

  /// ANDROID AUDIO-FOCUS FIX — see how_much_can_you_see_screen.dart for the
  /// long version. Short version: every play() requests audio focus per the
  /// player's OWN AudioContextAndroid; with default `AudioFocus.gain` the
  /// voice player starting PAUSES the looping BGM. Set `AudioFocus.none` on
  /// each player so they all mix; we duck manually via setVolume. On iOS the
  /// per-player call sets the shared session (playback + mixWithOthers).
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
    _bgm
        .play(audioSource('sounds/restore_earth/bgm.mp3'), volume: _bgmVolume)
        .catchError((_) {});
    // 350 ms beat so the intro fade-in feels in sync with Orbit talking.
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    _voiceDucked = true;
    _bgm.setVolume(_bgmDucked).catchError((_) {});
    _voiceSafetyScreen?.cancel();
    _voiceSafetyScreen = Timer(const Duration(seconds: 15), _restoreBgm);
    _voice
        .play(audioSource('sounds/restore_earth/orbit/orbit_01.wav'))
        .catchError((_) {
      if (mounted) _restoreBgm();
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _voiceSafetyScreen?.cancel();
    _voiceCompleteSub?.cancel();
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    _sfx.dispose();
    _voice.dispose();
    _bgm.stop().catchError((_) {});
    _bgm.dispose();
    super.dispose();
  }

  void _playSound(String assetFile) => _sfx.play(audioSource(assetFile)).catchError((_) {});

  /// Restore the BGM bed after Orbit's line ends (natural complete, error,
  /// or screen-side safety timeout). One-shot — no-op if already restored.
  /// Also resume()s in case anything paused the loop (focus loss).
  void _restoreBgm() {
    _voiceSafetyScreen?.cancel();
    _voiceSafetyScreen = null;
    if (!_voiceDucked) return;
    _voiceDucked = false;
    _bgm.setVolume(_bgmVolume).catchError((_) {});
    _bgm.resume().catchError((_) {});
  }

  /// Plays the controller's current voice clip iff its token has advanced
  /// since last play. Ducks BGM, arms a 15 s screen-side safety so the bed
  /// restores even if onPlayerComplete never arrives.
  void _maybePlayVoice() {
    final s = _controller.state;
    final clip = s.voiceClip;
    if (clip == null || s.voiceToken == _lastVoiceToken) return;
    _lastVoiceToken = s.voiceToken;
    final n = clip.toString().padLeft(2, '0');
    _voice.stop(); // interrupt any previous line so they don't overlap
    if (!_voiceDucked) {
      _voiceDucked = true;
      _bgm.setVolume(_bgmDucked).catchError((_) {});
    }
    _voiceSafetyScreen?.cancel();
    _voiceSafetyScreen = Timer(const Duration(seconds: 15), _restoreBgm);
    _voice
        .play(audioSource('sounds/restore_earth/orbit/orbit_$n.wav'))
        // If the file is missing / play throws, immediately tell the
        // controller "voice is done" AND restore BGM so we don't deadlock
        // ducked.
        .catchError((_) {
      if (!mounted) return;
      _restoreBgm();
      _controller.onVoiceFinished();
    });
  }

  // Idle-hint timer (PRD §33.1): if a power is selected but not fired within 5s.
  void _onStateChanged() {
    final s = _controller.state;
    if (s.selectedPower != _lastSelected) {
      _lastSelected = s.selectedPower;
      _idleTimer?.cancel();
      if (s.selectedPower != null && s.phase == ActivityPhase.playing) {
        _idleTimer = Timer(const Duration(seconds: 5), _controller.onIdleHint);
      }
    }
    // While the cover scene is up, suppress the gameplay voice queue —
    // _onStartMission triggers the first gameplay line on dismiss.
    if (!_introVisible) _maybePlayVoice();
  }

  Widget _reactive(Widget Function() build) =>
      AnimatedBuilder(animation: _controller, builder: (_, __) => build());

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: CareerColors.bgMid,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 360),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _introVisible
              ? KeyedSubtree(
                  key: const ValueKey('intro'),
                  child: RestoreEarthIntroScene(onStart: _onStartMission),
                )
              : KeyedSubtree(
                  key: const ValueKey('gameplay'),
                  child: _buildGameplay(context),
                ),
        ),
      ),
    );
  }

  Widget _buildGameplay(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: CosmicBackground()),
        Positioned.fill(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  _reactive(() => ActivityHeader(controller: _controller)),
                  const SizedBox(height: 8),
                  _reactive(() => ProgressRail(controller: _controller)),
                  const SizedBox(height: 6),
                  Expanded(child: _buildStage()),
                  const SizedBox(height: 6),
                  // Fixed-height bottom region (mission + powers + CTA). Slots
                  // keep constant heights so the GameWidget never resizes; only
                  // their ORDER changes by phase (intro: mission drops to just
                  // above Start; play: mission sits above the powers).
                  _reactive(_buildBottom),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Bottom region with constant total height; only the order swaps by phase.
  Widget _buildBottom() {
    final phase = _controller.state.phase;
    final playing = phase == ActivityPhase.playing || phase == ActivityPhase.repairing;

    final mission = SizedBox(height: 100, child: MissionPanel(controller: _controller));
    final powers = SizedBox(
      height: 150,
      width: double.infinity,
      child: AnimatedOpacity(
        opacity: playing ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        child: IgnorePointer(ignoring: !playing, child: PowerPanel(controller: _controller)),
      ),
    );
    final cta = SizedBox(
      height: 56,
      child: CtaButton(
        controller: _controller,
        onNextMission: () => completeActivity(context),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: playing
          // Playing: the (empty) CTA slot sits on TOP — mission + powers fall
          // to the visible bottom. Total height unchanged so the stage above
          // doesn't resize.
          ? [cta, const SizedBox(height: 10), mission, const SizedBox(height: 8), powers]
          : [powers, const SizedBox(height: 10), mission, const SizedBox(height: 8), cta],
    );
  }

  Widget _buildStage() {
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        return Stack(
          children: [
            Positioned.fill(child: _gameWidget),
            // Labels sit on the un-zoomed Earth → only show in the intro overview.
            Positioned.fill(
              child: _reactive(() => _controller.state.phase == ActivityPhase.intro
                  ? ZoneLabels(stageSize: size)
                  : const SizedBox.shrink()),
            ),
          ],
        );
      },
    );
  }
}
