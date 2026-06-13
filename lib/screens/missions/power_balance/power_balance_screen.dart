// Episode 6 — "Keep the Satellite Alive / Power Balance Challenge" — the Flutter
// shell hosting the Flame stage.
//
// Layout is a full-bleed Stack of Positioned.fill layers (per the playbook so
// the bottom controls can never be pushed off a tall viewport): cosmic bg → the
// Flame GameWidget (built ONCE) → a SafeArea overlay carrying the top HUD and a
// bottom cluster (control dock → Mission Control card). Intro / success / failure
// overlays fade over everything via an AnimatedSwitcher keyed by phase.

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../../../utils/s3_audio.dart';
import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../home/career/cosmicBackground.dart';
import '../../home/career/careerTheme.dart';
import 'config/asset_paths.dart';
import 'config/power_balance_tuning.dart';
import 'game/power_balance_game.dart';
import 'models/power_balance_models.dart';
import 'state/power_balance_controller.dart';
import 'state/power_balance_state.dart';
import '../lessonRunner.dart';
import 'widgets/capture_flyer.dart';
import 'widgets/capture_gallery.dart';
import 'widgets/control_dock.dart';
import 'widgets/feedback_badge.dart';
import 'widgets/low_power_alert.dart';
import 'widgets/mission_control_card.dart';
import 'widgets/mission_overlays.dart';
import 'widgets/transmission_fx.dart';
import 'widgets/top_mission_hud.dart';

class PowerBalanceScreen extends StatefulWidget {
  const PowerBalanceScreen({super.key});

  @override
  State<PowerBalanceScreen> createState() => _PowerBalanceScreenState();
}

class _PowerBalanceScreenState extends State<PowerBalanceScreen> {
  late final PowerBalanceController _controller;
  late final PowerBalanceGame _game;
  late final Widget _gameWidget;

  // Three audio lanes (skill pattern): SFX, Orbit's voice, looping BGM bed.
  // Same player for SFX+voice would cut Orbit mid-word on every sparkle.
  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _voice = AudioPlayer();
  final AudioPlayer _bgm = AudioPlayer();
  static const double _bgmVolume = 0.20; // ambient bed
  static const double _bgmDucked = 0.05; // while Orbit speaks

  bool _galleryOpen = false;
  bool _soundOn = true;

  // voice bookkeeping
  int _lastVoiceToken = 0;
  int _lastClip = 0;

  // intro narration: bubble line index, advanced by voice completion (or the
  // muted reading-time fallback below). Start Mission stays locked until the
  // last line has been heard (listen-before-skip gate).
  final ValueNotifier<int> _introLine = ValueNotifier(0);
  final ValueNotifier<bool> _introReady = ValueNotifier(false);
  Timer? _introFallback;

  @override
  void initState() {
    super.initState();
    _controller = PowerBalanceController(onSound: _playSound, onHaptic: _haptic);
    _game = PowerBalanceGame(controller: _controller);
    _gameWidget = GameWidget(game: _game); // built ONCE — never inside a rebuild
    _sfx.setReleaseMode(ReleaseMode.stop);
    _bgm.setReleaseMode(ReleaseMode.loop);
    _voice.onPlayerComplete.listen((_) => _onVoiceDone());
    _controller.addListener(_onVoiceState);
    _configureAudio();
    // muted users still get the intro lines via reading-time pacing (and the
    // Start gate opens after the last line's reading time)
    _introFallback = Timer.periodic(const Duration(milliseconds: 4600), (_) {
      if (!mounted) return;
      if (_controller.state.phase != MissionPhase.intro || _soundOn) return;
      if (_introLine.value < PBTune.introLines.length - 1) {
        _introLine.value++;
      } else {
        _introReady.value = true;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.onFirstBuild();
      // Orbit's welcome — small delay so it lands with the bubble fade-in
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _controller.state.phase == MissionPhase.intro) {
          _playClip(1);
        }
      });
    });
  }

  /// Android steals audio focus per-player (default AudioFocus.gain), pausing
  /// the BGM lane forever the moment Orbit speaks. Fix per the skill: every
  /// player opts OUT of focus (none) + iOS mixWithOthers; loudness is handled
  /// by our own setVolume ducking.
  Future<void> _configureAudio() async {
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
    if (!mounted) return;
    _bgm.play(audioSource(PBSounds.bgm), volume: _bgmVolume).catchError((_) {});
  }

  @override
  void dispose() {
    _introFallback?.cancel();
    _controller.removeListener(_onVoiceState);
    _controller.dispose();
    _voice.stop().catchError((_) {});
    _bgm.stop().catchError((_) {});
    _sfx.dispose();
    _voice.dispose();
    _bgm.dispose();
    _introLine.dispose();
    _introReady.dispose();
    super.dispose();
  }

  // ── Orbit's voice ──────────────────────────────────────────────────────────
  /// Plays whenever the controller stamps a new voiceToken (one choke point —
  /// every helper-line change with a mapped clip lands here).
  void _onVoiceState() {
    final s = _controller.state;
    if (s.voiceToken != _lastVoiceToken) {
      _lastVoiceToken = s.voiceToken;
      _playClip(s.voiceClip);
    }
  }

  void _playClip(int n) {
    if (n <= 0) return;
    _lastClip = n;
    if (!_soundOn) return; // muted → controller paces lines by timer instead
    _voice.stop().catchError((_) {}); // never overlap two lines
    _bgm.setVolume(_bgmDucked).catchError((_) {}); // duck the bed under Orbit
    _controller.voiceStarted();
    _voice.play(audioSource(PBSounds.orbit(n))).catchError((_) {
      _onVoiceDone(); // missing asset → advance immediately, never deadlock
    });
  }

  void _onVoiceDone() {
    _bgm.setVolume(_bgmVolume).catchError((_) {}); // restore the bed
    _bgm.resume().catchError((_) {}); // belt-and-braces vs focus pauses
    _controller.voiceFinished();
    final phase = _controller.state.phase;
    // terminal-phase chains (these lines never pass through helperMessage)
    if (phase == MissionPhase.intro) {
      if (_introLine.value < PBTune.introLines.length - 1) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (!mounted || _controller.state.phase != MissionPhase.intro) return;
          _introLine.value++;
          _playClip(_introLine.value + 1); // intro lines = clips 1..3
        });
      } else {
        _introReady.value = true; // last welcome line heard → unlock Start
      }
      // (success 50..52 not voiced — the panel + jingle carry the moment)
    } else if (phase == MissionPhase.failure && _lastClip == 53) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted && _controller.state.phase == MissionPhase.failure) _playClip(54);
      });
    }
  }

  void _toggleSound() {
    setState(() => _soundOn = !_soundOn);
    if (!_soundOn) {
      _voice.stop().catchError((_) {});
      _bgm.setVolume(0).catchError((_) {});
      _controller.voiceFinished(); // never strand a voice-paced line on mute
    } else {
      _bgm.setVolume(_bgmVolume).catchError((_) {});
      _bgm.resume().catchError((_) {});
      // unmuted mid-intro: resume the welcome narration from the current line
      // (the muted fallback timer stops once sound is on, so replay drives it)
      if (_controller.state.phase == MissionPhase.intro && !_introReady.value) {
        _playClip(_introLine.value + 1);
      }
    }
  }

  void _playSound(String assetFile) {
    if (!_soundOn) return;
    _sfx.play(audioSource(assetFile)).catchError((_) {});
  }

  void _haptic() => HapticFeedback.lightImpact();

  void _exit() {
    _controller.finish();
    Navigator.of(context).maybePop();
  }

  Widget _reactive(Widget Function(PowerBalanceState s) build) => AnimatedBuilder(
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
            // transmission beam + packets + pills (Flutter), full-screen so its
            // pixel space matches the controller's stage coords.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, __) {
                  final s = _controller.state;
                  return TransmissionFx(
                    startToken: s.sendToken,
                    doneToken: s.transmitDoneToken,
                    satellite: _controller.satelliteCenterPx,
                    dish: _controller.groundStationCenterPx,
                  );
                },
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                child: Stack(
                  children: [
                    // top HUD
                    Positioned(
                      top: 6,
                      left: 12,
                      right: 12,
                      child: _reactive((s) => TopMissionHud(
                            state: s,
                            onBack: _exit,
                            onImagesTap: () => setState(() => _galleryOpen = true),
                          )),
                    ),
                    // bottom cluster: control dock → mission control card
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 10,
                      // whole cluster hides when not actively playing, so it never
                      // bleeds behind the intro / success / failure overlays.
                      child: _reactive((s) => IgnorePointer(
                            ignoring: !s.isPlaying,
                            child: AnimatedOpacity(
                              opacity: s.isPlaying ? 1 : 0.0,
                              duration: const Duration(milliseconds: 250),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ControlDock(controller: _controller, state: s),
                                  const SizedBox(height: 12),
                                  MissionControlCard(mood: s.mascot, message: s.helperMessage),
                                ],
                              ),
                            ),
                          )),
                    ),
                    // one-shot achievement/feedback badge pop (upper-centre)
                    Positioned(
                      top: 96,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _reactive((s) =>
                            FeedbackBadgePop(token: s.feedbackToken, badge: s.feedbackBadge)),
                      ),
                    ),
                    // capture animation: photo pops big then flies to the IMAGES counter
                    Positioned.fill(
                      child: _reactive((s) => CaptureFlyer(token: s.captureToken)),
                    ),
                    // "systems shutting down" low-power alert (~2s)
                    Positioned.fill(
                      child: _reactive((s) => LowPowerAlert(token: s.lowPowerAlertToken)),
                    ),
                  ],
                ),
              ),
            ),
            // intro / success / failure overlays — OUTSIDE the SafeArea so they
            // cover the whole screen edge-to-edge (each has its own inner SafeArea
            // for content padding).
            Positioned.fill(
              child: _reactive((s) => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    // expand children to fill (default StackFit.loose makes a
                    // full-screen scrim shrink to its content — the dead-zone bug).
                    layoutBuilder: (current, previous) => Stack(
                      fit: StackFit.expand,
                      children: [
                        ...previous,
                        if (current != null) current,
                      ],
                    ),
                    child: _overlayFor(s),
                  )),
            ),
            // captured-images gallery (topmost; opened from the IMAGES counter)
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _galleryOpen
                    ? CaptureGallery(
                        key: const ValueKey('gallery'),
                        count: _controller.state.imagesCaptured,
                        onClose: () => setState(() => _galleryOpen = false),
                      )
                    : const SizedBox.shrink(key: ValueKey('nogallery')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overlayFor(PowerBalanceState s) {
    switch (s.phase) {
      case MissionPhase.intro:
        return IntroOverlay(
          key: const ValueKey('intro'),
          onStart: _controller.startMission,
          onBack: _exit,
          soundOn: _soundOn,
          onToggleSound: _toggleSound,
          introLine: _introLine,
          startEnabled: _introReady,
        );
      case MissionPhase.success:
        return SuccessOverlay(key: const ValueKey('success'), onDone: () => completeActivity(context));
      case MissionPhase.failure:
        return FailureOverlay(
          key: const ValueKey('failure'),
          onRetry: _controller.retry,
          onExit: _exit,
        );
      default:
        return const SizedBox.shrink(key: ValueKey('none'));
    }
  }
}
