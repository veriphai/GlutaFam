// Build Your Satellite — the Flutter shell that hosts the Flame build stage.
//
// Responsibilities:
//  • owns the BuildSatelliteController (mission state) and the BuildSatelliteGame
//  • lays out header / rail / mascot / stage / meters / tray / launch button
//  • bridges the Flutter Draggable tray to Flame slot detection via a DragTarget
//    wrapped around the GameWidget (global drop offset -> game-local coords)
//  • plays SFX + haptics and runs the idle-hint timer
//  • shows the reward popup when the mission completes.

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../../../utils/s3_audio.dart';
import 'package:flame/components.dart' show Vector2;
import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../home/career/careerCommon.dart';
import '../../home/career/careerTheme.dart';
import '../../home/career/cosmicBackground.dart';
import 'build_satellite_intro_screen.dart' show BuildSatelliteIntroScene;
import 'config/asset_paths.dart';
import 'game/build_satellite_game.dart';
import 'state/build_satellite_controller.dart';
import 'widgets/inventory_tray.dart';
import 'widgets/launch_preview_button.dart';
import 'widgets/mascot_helper.dart';
import 'widgets/mission_header.dart';
import 'widgets/mission_tip_card.dart';
import 'widgets/reward_popup.dart';
import 'widgets/status_meters.dart';
import 'widgets/step_progress_rail.dart';
import 'widgets/tilt_view.dart';

class BuildSatelliteScreen extends StatefulWidget {
  const BuildSatelliteScreen({super.key});

  @override
  State<BuildSatelliteScreen> createState() => _BuildSatelliteScreenState();
}

class _BuildSatelliteScreenState extends State<BuildSatelliteScreen> {
  late final BuildSatelliteController _controller;
  late final BuildSatelliteGame _game;
  late final Widget _gameWidget; // built once so Flame isn't re-attached

  final GlobalKey _stageKey = GlobalKey();
  // Three audio lanes (skill rule — one player per lane): SFX on the same
  // player as voice would cut Orbit mid-word; BGM loops underneath and ducks
  // while Orbit speaks.
  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _voice = AudioPlayer();
  final AudioPlayer _bgm = AudioPlayer();
  StreamSubscription<void>? _voiceCompleteSub;

  static const double _bgmVolume = 0.20; // ambient bed
  static const double _bgmDucked = 0.05; // while Orbit speaks

  Timer? _idleTimer1; // 6 s nudgeHint
  Timer? _idleTimer2; // 12 s nudgeHintStronger
  Timer? _voiceSafetyScreen; // restores BGM if onPlayerComplete never arrives
  bool _voiceDucked = false;
  int _lastVoiceToken = 0;

  /// While true the cover intro is on screen. The gameplay voice queue is
  /// suppressed, the screen plays the cover voice line directly, and the
  /// `_voice` player's onPlayerComplete does NOT advance the controller.
  bool _introVisible = true;

  static const Duration _idleDelay1 = Duration(seconds: 6);
  static const Duration _idleDelay2 = Duration(seconds: 12);

  @override
  void initState() {
    super.initState();
    _controller = BuildSatelliteController();
    _game = BuildSatelliteGame(controller: _controller, onSound: _playSound);
    _gameWidget = GameWidget(game: _game);
    _controller.addListener(_onStateChanged);
    _sfx.setReleaseMode(ReleaseMode.stop);
    _voice.setReleaseMode(ReleaseMode.stop);
    _bgm.setReleaseMode(ReleaseMode.loop);
    // Track the controller's initial voice token so we DON'T auto-play the
    // game-intro line (orbit_02) while the cover scene is up. We bump
    // `_lastVoiceToken` to match the initial state's token, so the first
    // gameplay-voice fires only when the controller bumps it again (after
    // the cover dismisses + the gameplay flow starts).
    _lastVoiceToken = _controller.state.voiceToken;
    _voiceCompleteSub = _voice.onPlayerComplete.listen((_) {
      if (!mounted) return;
      _restoreBgm();
      // While the cover scene is up, the playing clip is orbit_01 (cover) —
      // it's NOT part of the controller's voice queue, so don't advance.
      if (_introVisible) return;
      _controller.onVoiceFinished();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAudio());
    _resetIdle();
  }

  /// Called from the intro scene's Start Mission button. Hides the cover,
  /// kicks off the gameplay voice flow (orbit_02 → …). BGM keeps playing
  /// because we never restart the player.
  void _onStartMission() {
    if (!_introVisible) return;
    setState(() => _introVisible = false);
    // The controller already holds the initial gameplay state (voiceClip=2,
    // voiceToken=1). Stop any in-flight cover voice and play that first
    // gameplay line. We rewind `_lastVoiceToken` so `_maybePlayVoice` sees a
    // change and fires.
    _lastVoiceToken = -1;
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
        .play(audioSource('sounds/build_satellite/bgm.mp3'), volume: _bgmVolume)
        .catchError((_) {});
    // 350 ms beat so the intro fade-in feels in sync with Orbit talking.
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    // Duck once for the cover voice; restore on its onPlayerComplete.
    _voiceDucked = true;
    _bgm.setVolume(_bgmDucked).catchError((_) {});
    _voiceSafetyScreen?.cancel();
    _voiceSafetyScreen = Timer(const Duration(seconds: 15), _restoreBgm);
    _voice
        .play(audioSource('sounds/build_satellite/orbit/orbit_01.wav'))
        .catchError((_) {
      if (mounted) _restoreBgm();
    });
  }

  @override
  void dispose() {
    _idleTimer1?.cancel();
    _idleTimer2?.cancel();
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

  // ── Feedback + idle hinting ────────────────────────────────────────────
  void _playSound(String assetFile) {
    // Existing app SFX (declared under assets/). Best-effort; never throws.
    _sfx.play(audioSource(assetFile)).catchError((_) {});
  }

  /// Restore the BGM bed after Orbit's line ends (natural complete, error,
  /// or screen-side safety timeout). One-shot — no-op if already restored.
  /// Also `resume()`s in case anything paused the loop (focus loss).
  void _restoreBgm() {
    _voiceSafetyScreen?.cancel();
    _voiceSafetyScreen = null;
    if (!_voiceDucked) return;
    _voiceDucked = false;
    _bgm.setVolume(_bgmVolume).catchError((_) {});
    _bgm.resume().catchError((_) {});
  }

  /// Play the controller's current Orbit voice clip iff its token has
  /// advanced since last play. Ducks BGM, arms a 15 s screen-side safety so
  /// the bed restores even if onPlayerComplete never arrives.
  void _maybePlayVoice() {
    final s = _controller.state;
    final clip = s.voiceClip;
    if (clip == null || s.voiceToken == _lastVoiceToken) return;
    _lastVoiceToken = s.voiceToken;
    final n = clip.toString().padLeft(2, '0');
    _voice.stop();
    if (!_voiceDucked) {
      _voiceDucked = true;
      _bgm.setVolume(_bgmDucked).catchError((_) {});
    }
    _voiceSafetyScreen?.cancel();
    _voiceSafetyScreen = Timer(const Duration(seconds: 15), _restoreBgm);
    _voice
        .play(audioSource('sounds/build_satellite/orbit/orbit_$n.wav'))
        .catchError((_) {
      if (!mounted) return;
      _restoreBgm();
      _controller.onVoiceFinished();
    });
  }

  void _resetIdle() {
    _idleTimer1?.cancel();
    _idleTimer2?.cancel();
    if (_controller.state.isComplete || _controller.state.launching) return;
    _idleTimer1 = Timer(_idleDelay1, _controller.nudgeHint);
    _idleTimer2 = Timer(_idleDelay2, _controller.nudgeHintStronger);
  }

  void _onStateChanged() {
    // While the cover scene is up, the controller's voiceClip is the initial
    // gameplay line (orbit_02). We must NOT play it yet — _onStartMission()
    // does that when the kid taps Start Mission.
    if (!_introVisible) _maybePlayVoice();
    _resetIdle();
  }

  void _onPickup(String partId) {
    _controller.clearHint();
    _playSound(SatSounds.pickup);
    HapticFeedback.selectionClick();
    _controller.onPartPickup(partId);
    _resetIdle();
  }

  void _onDrop(String partId, Offset globalOffset) {
    final box = _stageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(globalOffset);
    _game.tryPlace(partId, Vector2(local.dx, local.dy));
    _resetIdle();
  }

  // ── Build ──────────────────────────────────────────────────────────────
  /// Rebuilds [build] whenever the controller notifies.
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
                  child: BuildSatelliteIntroScene(onStart: _onStartMission),
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
        // Positioned.fill forces the content to exactly fill the viewport so
        // the Column/Expanded are height-bounded and the bottom controls
        // (meters / tray / launch) never get pushed below the fold.
        Positioned.fill(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  RevealOnLoad(child: _reactive(() => MissionHeader(controller: _controller))),
                  const SizedBox(height: 10),
                  RevealOnLoad(
                    delay: const Duration(milliseconds: 60),
                    child: _reactive(() => StepProgressRail(controller: _controller)),
                  ),
                  const SizedBox(height: 12),
                  RevealOnLoad(
                    delay: const Duration(milliseconds: 120),
                    child: _reactive(() => MascotHelper(controller: _controller)),
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: _buildStage()),
                  const SizedBox(height: 8),
                  _reactive(() => StatusMeters(controller: _controller)),
                  const SizedBox(height: 12),
                  _reactive(() => InventoryTray(controller: _controller, onPickup: _onPickup)),
                  const SizedBox(height: 10),
                  _reactive(() => LaunchPreviewButton(controller: _controller)),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ),
        // Reward overlay.
        Positioned.fill(
          child: _reactive(() => _controller.state.rewardVisible
              ? RewardPopup(
                  onContinue: () => Navigator.of(context).maybePop(),
                  continueEnabled: _controller.state.continueEnabled,
                )
              : const SizedBox.shrink()),
        ),
      ],
    );
  }

  Widget _buildStage() {
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onMove: (details) {
        final box = _stageKey.currentContext?.findRenderObject() as RenderBox?;
        if (box == null) return;
        final local = box.globalToLocal(details.offset);
        _game.updateHover(details.data, Vector2(local.dx, local.dy));
      },
      onLeave: (_) => _game.clearHover(),
      onAcceptWithDetails: (details) => _onDrop(details.data, details.offset),
      builder: (_, __, ___) => Stack(
        children: [
          // Game canvas: its RenderBox is what we globalToLocal against.
          // TiltView gives a subtle fake-3D feel; drop coords map through it.
          Positioned.fill(
            child: TiltView(child: KeyedSubtree(key: _stageKey, child: _gameWidget)),
          ),
          // Floating mission tip.
          Positioned(
            left: 4,
            right: 4,
            bottom: 4,
            child: _reactive(() => MissionTipCard(controller: _controller)),
          ),
        ],
      ),
    );
  }
}
