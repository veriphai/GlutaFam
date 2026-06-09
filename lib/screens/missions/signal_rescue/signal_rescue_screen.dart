// Signal Rescue Mission (Activity 7) — the Flutter shell hosting the Flame stage.
//
// Layout is a full-bleed Stack of Positioned.fill layers (per the playbook, so
// the bottom controls can never be pushed off a tall viewport): cosmic bg → the
// Flame GameWidget (built ONCE) → a SafeArea overlay carrying the top bar, the
// signal/battery meters, the explain-parts callouts, and a bottom cluster
// (monitor → helper card → action slot). A success overlay fades over everything.
//
// AUDIO: three lanes — _sfx (blips), _voice (Orbit's 29 clips), _bgm (loop) —
// separate players so a packet blip never cuts Orbit mid-word. Voice fires on a
// voiceToken diff (the controller's choke point stamps clips when the helper
// line changes); BGM ducks under speech. Every player gets an
// AudioFocus.none/mixWithOthers context BEFORE the loop starts — otherwise
// Android pauses the BGM lane forever the first time Orbit speaks.

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../../../utils/s3_audio.dart';
import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/material.dart';

import '../../home/career/careerTheme.dart';
import '../../home/career/cosmicBackground.dart';
import 'config/asset_paths.dart';
import 'config/signal_tuning.dart';
import 'game/signal_rescue_game.dart';
import 'state/signal_rescue_controller.dart';
import 'state/signal_rescue_state.dart';
import 'widgets/activity_top_bar.dart';
import 'widgets/battery_meter.dart';
import 'widgets/cyclone_overlay.dart';
import 'widgets/helper_card.dart';
import 'widgets/mission_intro_scene.dart';
import 'widgets/mission_monitor.dart';
import 'widgets/mission_success_overlay.dart';
import 'widgets/part_callouts.dart';
import 'widgets/send_data_button.dart';
import 'widgets/signal_meter.dart';

class SignalRescueScreen extends StatefulWidget {
  const SignalRescueScreen({super.key});

  @override
  State<SignalRescueScreen> createState() => _SignalRescueScreenState();
}

class _SignalRescueScreenState extends State<SignalRescueScreen> {
  late final SignalRescueController _controller;
  late final SignalRescueGame _game;
  late final Widget _gameWidget;

  // Three audio lanes (see header note).
  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _voice = AudioPlayer();
  final AudioPlayer _bgm = AudioPlayer();
  static const double _bgmVolume = 0.20; // ambient bed
  static const double _bgmDucked = 0.05; // while Orbit speaks

  int _lastVoiceToken = 0;
  Timer? _voiceSafety; // advances the flow if onPlayerComplete never arrives
  // success voice chain: 22 (via token) → 23 → 24 → Continue enabled
  int _successStep = 0;
  bool get _successVoiceDone => _successStep >= 3;

  @override
  void initState() {
    super.initState();
    _controller = SignalRescueController(onSound: _playSound);
    _game = SignalRescueGame(controller: _controller);
    _gameWidget = GameWidget(game: _game); // built ONCE — never inside a rebuild
    _sfx.setReleaseMode(ReleaseMode.stop);
    _voice.setReleaseMode(ReleaseMode.stop);
    _voice.onPlayerComplete.listen((_) => _voiceDone());
    _bgm.setReleaseMode(ReleaseMode.loop);
    _controller.addListener(_onStateForVoice);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // contexts FIRST so the intro clip (fired by onFirstBuild's notify)
      // already plays on a focus-free player.
      await _startAudio();
      if (mounted) _controller.onFirstBuild();
    });
  }

  /// Per-player AudioFocus.none + mixWithOthers BEFORE starting the BGM loop —
  /// `audioplayers` requests Android audio focus per play() from each player's
  /// OWN context (a global call only affects players created after it), so
  /// without this the voice lane starting would pause the BGM lane forever.
  Future<void> _startAudio() async {
    if (!mounted) return;
    final mix = AudioContext(
      android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
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
    _bgm.play(audioSource(SRSounds.bgm), volume: _bgmVolume).catchError((_) {});
  }

  @override
  void dispose() {
    _voiceSafety?.cancel();
    _controller.removeListener(_onStateForVoice);
    _controller.dispose();
    _sfx.dispose();
    _voice.dispose();
    _bgm.stop().catchError((_) {});
    _bgm.dispose();
    super.dispose();
  }

  void _playSound(String assetFile) => _sfx.play(audioSource(assetFile)).catchError((_) {});

  // ── Orbit voice ─────────────────────────────────────────────────────────────
  void _onStateForVoice() {
    final s = _controller.state;
    if (s.voiceToken != _lastVoiceToken) {
      _lastVoiceToken = s.voiceToken;
      if (s.voiceClip > 0) _playVoice(s.voiceClip);
    }
  }

  void _playVoice(int clip) async {
    _voiceSafety?.cancel();
    // stop() before play() so close-together lines never overlap (stop() does
    // NOT fire onPlayerComplete — exactly what we want).
    await _voice.stop();
    if (!mounted) return;
    _bgm.setVolume(_bgmDucked).catchError((_) {}); // duck the bed under Orbit
    _controller.voiceStarted();
    // safety: a missing file / focus loss / dropped completion must not strand
    // the voice-paced flow.
    _voiceSafety = Timer(const Duration(seconds: 12), _voiceDone);
    _voice.play(audioSource(SRSounds.orbitVoice(clip))).catchError((_) => _voiceDone());
  }

  void _voiceDone() {
    _voiceSafety?.cancel();
    if (!mounted) return;
    _bgm.setVolume(_bgmVolume).catchError((_) {}); // restore the bed
    _bgm.resume().catchError((_) {}); // belt-and-braces vs focus pauses
    _controller.voiceFinished();
    // Success chain: 22 played via the token; 23 + 24 are routed here, then the
    // Continue CTA unlocks (listen-before-skip).
    if (_controller.state.phase == MissionPhase.success && _successStep < 3) {
      _successStep += 1;
      if (_successStep <= 2) {
        _playVoice(22 + _successStep); // 23, then 24
      } else {
        setState(() {}); // unlock Continue
      }
    }
  }

  void _exit() {
    _controller.finish();
    Navigator.of(context).maybePop();
  }

  Widget _reactive(Widget Function(SignalRescueState s) build) => AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => build(_controller.state),
      );

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
            // The cyclone on the Earth's ocean (Flutter, factor-anchored over the
            // fixed stage). Highlighted while Orbit introduces it (briefing line
            // 1 = whole storm, line 2 = its eye).
            Positioned.fill(
              child: IgnorePointer(
                child: _reactive((s) => CycloneOverlay(
                      highlight: s.phase == MissionPhase.explainParts
                          ? (s.explainStep == 0
                              ? CycloneHighlight.whole
                              : s.explainStep == 1
                                  ? CycloneHighlight.eye
                                  : CycloneHighlight.none)
                          : CycloneHighlight.none,
                    )),
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                child: Stack(
                  children: [
                    // Top bar.
                    Positioned(
                      top: 6,
                      left: 12,
                      right: 12,
                      child: _reactive((s) => ActivityTopBar(phase: s.phase, onBack: _exit)),
                    ),
                    // Meters (top-right, fade in as they become relevant).
                    Positioned(
                      top: 54,
                      right: 12,
                      child: _reactive(_meters),
                    ),
                    // Explain-parts callouts over the stage.
                    Positioned.fill(
                      child: _reactive((s) => s.phase == MissionPhase.explainParts
                          // per-step callout map: cyclone/eye lines highlight no
                          // part; then ANTENNA, then GROUND STATION (held).
                          ? PartCallouts(
                              step: SRTune.explainCalloutStep[s.explainStep
                                  .clamp(0, SRTune.explainCalloutStep.length - 1)])
                          : const SizedBox.shrink()),
                    ),
                    // Bottom cluster: monitor → action slot → helper.
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 12,
                      child: _reactive(_bottomCluster),
                    ),
                    // Success overlay.
                    Positioned.fill(
                      child: _reactive((s) => AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            child: s.phase == MissionPhase.success
                                ? MissionSuccessOverlay(
                                    key: const ValueKey('success'),
                                    onDone: _exit,
                                    continueEnabled: _successVoiceDone,
                                  )
                                : const SizedBox.shrink(key: ValueKey('none')),
                          )),
                    ),
                  ],
                ),
              ),
            ),
            // Full-screen story-intro poster — covers the stage + HUD until the
            // child taps START MISSION, then fades out to reveal the game.
            Positioned.fill(
              child: _reactive((s) => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    child: s.phase == MissionPhase.intro
                        ? MissionIntroScene(
                            key: const ValueKey('intro'),
                            mood: s.mascot,
                            message: s.helperMessage,
                            onHome: _exit,
                            onStart: _controller.startMission,
                            startEnabled: !s.voicePlaying, // listen, then start
                          )
                        : const SizedBox.shrink(key: ValueKey('no-intro')),
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meters(SignalRescueState s) {
    final showSignal = s.controlsLive || s.phase == MissionPhase.transmitting;
    final showBattery = s.phase.index >= MissionPhase.waitForRange.index &&
        s.phase != MissionPhase.success;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedOpacity(
          opacity: showSignal ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          child: SignalMeter(signal: s.signalState, strength: s.signalStrength),
        ),
        const SizedBox(height: 8),
        AnimatedOpacity(
          opacity: showBattery ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          child: BatteryMeter(level: s.batteryLevel, warning: s.batteryWarning),
        ),
      ],
    );
  }

  Widget _bottomCluster(SignalRescueState s) {
    final receiving = s.phase == MissionPhase.transmitting || s.phase == MissionPhase.success;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Compact status strip during play; expands to the full screen only while
        // the image is actually being received.
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomCenter,
          child: MissionMonitor(state: s, expanded: receiving),
        ),
        const SizedBox(height: 10),
        // Bot dialogue sits ABOVE the action button.
        HelperCard(mood: s.mascot, message: s.helperMessage),
        const SizedBox(height: 10),
        // fixed-height action slot (Start / Send), pinned to the bottom.
        SizedBox(
          height: 54,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: _action(s),
          ),
        ),
      ],
    );
  }

  Widget _action(SignalRescueState s) {
    // (intro Start lives on the full-screen MissionIntroScene poster now)
    final showSend = s.phase == MissionPhase.waitForRange ||
        s.phase == MissionPhase.checkPower ||
        s.phase == MissionPhase.dataLocked ||
        s.phase == MissionPhase.transmitting;
    if (showSend) {
      return SendDataButton(
        key: const ValueKey('send'),
        ready: s.canTransmit && !s.isTransmitting,
        onTap: () => _controller.attemptSend(),
      );
    }
    return const SizedBox.shrink(key: ValueKey('empty'));
  }
}
