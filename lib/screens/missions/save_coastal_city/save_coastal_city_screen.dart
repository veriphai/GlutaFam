// "Save the Coastal City" (Episode 11 — Satellite Engineer FINAL BOSS) —
// the Flutter shell. Owns the MissionStageController + the Flame SaveCityGame
// (built once, embedded only by the scenes that need sprite motion) + SFX +
// haptics. Portrait layout (PRD §9): top mission chrome (title, stage, 8-node
// rail, readiness chip) / middle interactive scene routed by an
// AnimatedSwitcher keyed per MissionStage / bottom Orbit dialogue overlay.

import 'package:audioplayers/audioplayers.dart';

import '../../../utils/s3_audio.dart';
import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../home/career/careerTheme.dart';
import 'config/scc_assets.dart';
import 'config/scc_theme.dart';
import 'game/save_city_game.dart';
import 'scenes/analysis_scene.dart';
import 'scenes/badge_scene.dart';
import 'scenes/camera_scene.dart';
import 'scenes/command_scene.dart';
import 'scenes/finale_scene.dart';
import 'scenes/intro_scene.dart';
import 'scenes/orbit_scene.dart';
import 'scenes/power_scene.dart';
import 'scenes/repair_scene.dart';
import 'scenes/scanner_scene.dart';
import 'scenes/signal_scene.dart';
import 'state/mission_stage_controller.dart';
import 'state/mission_state.dart';
import 'widgets/mission_dialogue_overlay.dart';
import 'widgets/mission_progress_rail.dart';

class SaveCoastalCityMissionScreen extends StatefulWidget {
  const SaveCoastalCityMissionScreen({super.key});

  @override
  State<SaveCoastalCityMissionScreen> createState() =>
      _SaveCoastalCityMissionScreenState();
}

class _SaveCoastalCityMissionScreenState
    extends State<SaveCoastalCityMissionScreen> {
  late final MissionStageController _controller;
  late final SaveCityGame _game;
  late final Widget _gameWidget;

  // Three audio LANES — SFX on the voice player would cut Orbit mid-word.
  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _voice = AudioPlayer();
  final AudioPlayer _bgm = AudioPlayer();
  static const _bgmVolume = 0.20;
  static const _bgmDucked = 0.05;
  int _lastVoiceToken = 0;

  @override
  void initState() {
    super.initState();
    _controller = MissionStageController(onCue: _playCue);
    _game = SaveCityGame(controller: _controller);
    _gameWidget = GameWidget(game: _game);
    _sfx.setReleaseMode(ReleaseMode.stop);
    _bgm.setReleaseMode(ReleaseMode.loop);
    _voice.onPlayerComplete.listen((_) => _voiceDone());
    _controller.addListener(_onStateForVoice);
    _setupAudio();
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.begin());
  }

  /// Android audio-focus fix (verified pattern): every player gets
  /// `AndroidAudioFocus.none` PER PLAYER (the global default is only copied
  /// at create-time, so a global call never reaches these players) + iOS
  /// playback/mixWithOthers — all in-app lanes mix, loudness handled by our
  /// setVolume ducking. Contexts first, THEN the BGM loop starts.
  Future<void> _setupAudio() async {
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
    _bgm.setVolume(_bgmVolume).catchError((_) {});
    // NOTE audioplayers prefixes `assets/` — path is relative to assets/.
    _bgm.play(audioSource('sounds/save_coastal_city/bgm.mp3')).catchError((_) {});
  }

  /// Play Orbit's clip whenever the voice token bumps (token, not clip — the
  /// same clip twice in a row must replay).
  void _onStateForVoice() {
    final s = _controller.state;
    if (s.voiceToken == _lastVoiceToken) return;
    _lastVoiceToken = s.voiceToken;
    final clip = s.voiceClip;
    if (clip == null) return;
    if (!s.soundOn) return; // muted: the dialogue's reading fallback paces
    _bgm.setVolume(_bgmDucked).catchError((_) {}); // duck the bed under Orbit
    _voice.stop(); // never overlap two lines (stop() does NOT fire complete)
    // MP3, not m4a — Chrome's media element rejects afconvert M4As on web
    // ("MEDIA_ELEMENT_ERROR: Format error"); MP3 plays on web+Android+iOS.
    final src = 'sounds/save_coastal_city/orbit_${clip.toString().padLeft(3, '0')}.mp3';
    _controller.dialogue.voiceStarted();
    _voice.play(audioSource(src)).catchError((_) {
      if (mounted) _voiceDone(); // missing asset → advance immediately
    });
  }

  void _voiceDone() {
    _bgm.setVolume(_controller.state.soundOn ? _bgmVolume : 0)
        .catchError((_) {});
    _bgm.resume().catchError((_) {}); // belt-and-braces vs focus pauses
    _controller.dialogue.voiceFinished();
  }

  void _toggleSound() {
    final wasOn = _controller.state.soundOn;
    _controller.toggleSound();
    if (wasOn) {
      // muting mid-line must never strand a voice-paced flow
      _voice.stop().catchError((_) {});
      _bgm.setVolume(0).catchError((_) {});
      _controller.dialogue.voiceFinished();
    } else {
      _bgm.setVolume(_bgmVolume).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateForVoice);
    _controller.dispose();
    _sfx.dispose();
    _voice.dispose();
    _bgm.dispose();
    super.dispose();
  }

  void _playCue(SccCue cue) {
    if (_controller.state.soundOn) {
      final file = switch (cue) {
        SccCue.tap || SccCue.scan => SCCSounds.tap,
        SccCue.lock || SccCue.correct || SccCue.upload => SCCSounds.correct,
        SccCue.wrong || SccCue.alert => SCCSounds.wrong,
        SccCue.complete => SCCSounds.complete,
      };
      _sfx.play(audioSource(file)).catchError((_) {});
    }
    switch (cue) {
      case SccCue.tap:
      case SccCue.scan:
        HapticFeedback.selectionClick();
      case SccCue.lock:
      case SccCue.correct:
      case SccCue.complete:
      case SccCue.upload:
        HapticFeedback.mediumImpact();
      case SccCue.alert:
        HapticFeedback.heavyImpact();
      case SccCue.wrong:
        HapticFeedback.lightImpact(); // soft — no harsh failure feedback
    }
  }

  void _exit() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: CareerColors.bgMid,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [SccColors.spaceNavy, SccColors.deepSpace],
            ),
          ),
          // ONE starfield behind the entire mission (chrome included) so every
          // stage lives in the same place — scenes layer over it full-bleed.
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: sccImage(SCC.flutter(SCC.bgStarfield), fit: BoxFit.cover),
              ),
              // closing screens (mission complete + badges) get the
              // holo-console backdrop FULL-SCREEN — behind the dialogue strip
              // too, so there's no seam under the scene area
              Positioned.fill(
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    final cine =
                        _controller.state.stage == MissionStage.finalSuccess ||
                            _controller.state.stage == MissionStage.badgeReveal;
                    return IgnorePointer(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 400),
                        opacity: cine ? 1 : 0,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            sccImage(SCC.flutter(SCC.bgHoloConsole),
                                fit: BoxFit.cover),
                            Container(
                                color: SccColors.deepSpace
                                    .withValues(alpha: 0.55)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                final s = _controller.state;
                // Title-card intro + the closing cinematic run chrome-less;
                // the intro embeds its own Orbit bubble so the CTA can sit
                // below it.
                final cinematic = s.stage == MissionStage.intro ||
                    s.stage == MissionStage.finalSuccess ||
                    s.stage == MissionStage.badgeReveal;
                return Column(
                  children: [
                    // ── top mission chrome (hidden for the cinematic) ──────
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 400),
                      crossFadeState: cinematic
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                        child: MissionTopBar(
                          state: s,
                          onExit: _exit,
                          onToggleSound: _toggleSound,
                          railLit: s.stage != MissionStage.intro,
                        ),
                      ),
                      secondChild: const SizedBox(width: double.infinity),
                    ),
                    // ── middle: the active stage scene ─────────────────────
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 420),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeIn,
                        // expand children so full-bleed scenes actually fill
                        // (the AnimatedSwitcher loose-Stack dead-zone gotcha)
                        layoutBuilder: (current, previous) => Stack(
                          fit: StackFit.expand,
                          children: [...previous, if (current != null) current],
                        ),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: child,
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(s.stage),
                          child: _sceneFor(s.stage),
                        ),
                      ),
                    ),
                    // ── bottom: Orbit + dialogue (constant height) ─────────
                    // Scenes with a bottom CTA embed the bubble themselves so
                    // the message reads ABOVE the button (intro, stage 1).
                    if (s.stage != MissionStage.intro &&
                        s.stage != MissionStage.chooseSatellite)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 6, 14, 10),
                        child: MissionDialogueOverlay(controller: _controller),
                      ),
                  ],
                );
              },
            ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sceneFor(MissionStage stage) {
    switch (stage) {
      case MissionStage.intro:
        return IntroScene(
            controller: _controller,
            onExit: _exit,
            onToggleSound: _toggleSound);
      case MissionStage.chooseSatellite:
        return ScannerScene(controller: _controller);
      case MissionStage.placeOrbit:
        return OrbitScene(controller: _controller, stage: _gameWidget);
      case MissionStage.powerManagement:
        return PowerScene(controller: _controller);
      case MissionStage.captureImage:
        return CameraScene(controller: _controller);
      case MissionStage.sendData:
        return SignalScene(
            controller: _controller, stage: _gameWidget, game: _game);
      case MissionStage.readImage:
        return AnalysisScene(controller: _controller);
      case MissionStage.repairIssue:
        return RepairScene(controller: _controller);
      case MissionStage.uploadCommands:
        return CommandScene(controller: _controller);
      case MissionStage.finalSuccess:
        return FinaleScene(controller: _controller);
      case MissionStage.badgeReveal:
        return BadgeScene(controller: _controller, onExit: _exit);
    }
  }
}
