// Orbit Launcher (Activity 3 — V2) — the Flutter shell hosting the Flame stage.
//
// Full-bleed Stack: the Flame GameWidget renders the launchpad / parallax sky /
// space / Earth, and Flutter chrome floats on top — a back button (top-left), a
// Mission-Control bubble (top-right), and a bottom panel that swaps with the
// scene (LAUNCH → fail card → tilt unlock → two sliders → outcome card → bridge).
// All overlay children are Positioned so the bottom controls can't be pushed off
// a tall viewport.

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../../../utils/s3_audio.dart';
import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/material.dart';

import '../../home/career/careerCommon.dart';
import '../../home/career/careerTheme.dart';
import 'config/asset_paths.dart';
import 'game/orbit_launcher_game.dart';
import 'state/orbit_launcher_controller.dart';
import 'state/orbit_launcher_state.dart';
// import 'widgets/bridge_panel.dart'; // next-activity bridge disabled for now (kept for later)
import 'widgets/control_panel.dart';
import 'widgets/mission_brief_screen.dart';
import 'widgets/mission_goal_panel.dart';
import 'widgets/mission_control_bubble.dart';
import 'widgets/orbit_button.dart';
import 'widgets/result_card.dart';
import 'widgets/tilt_unlock_panel.dart';

class OrbitLauncherScreen extends StatefulWidget {
  const OrbitLauncherScreen({super.key});

  @override
  State<OrbitLauncherScreen> createState() => _OrbitLauncherScreenState();
}

class _OrbitLauncherScreenState extends State<OrbitLauncherScreen> {
  late final OrbitLauncherController _controller;
  late final OrbitLauncherGame _game;
  late final Widget _gameWidget;
  // Three audio lanes: SFX (taps/crashes), Orbit's narration, and a looping BGM
  // bed that ducks while Orbit speaks. Separate players so they never cut each
  // other (same-player playback replaces the current clip).
  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _voice = AudioPlayer();
  final AudioPlayer _bgm = AudioPlayer();

  static const double _bgmVolume = 0.20; // ambient bed
  static const double _bgmDucked = 0.05; // while Orbit speaks

  bool _muted = false;
  bool _bgmStarted = false;
  String? _lastVoiceKey;
  Timer? _voiceSafety; // clears voicePlaying if onPlayerComplete never arrives

  @override
  void initState() {
    super.initState();
    _controller = OrbitLauncherController();
    _game = OrbitLauncherGame(controller: _controller, onSound: _playSound);
    _gameWidget = GameWidget(game: _game); // built ONCE — never inside a rebuild
    _sfx.setReleaseMode(ReleaseMode.stop);
    _voice.setReleaseMode(ReleaseMode.stop);
    _bgm.setReleaseMode(ReleaseMode.loop);
    _voice.onPlayerComplete.listen((_) => _voiceDone());
    _controller.addListener(_onVoiceCue);
    // Configure per-player mixing FIRST, then start audio (post-frame: playing
    // before the widget is attached fails silently on some devices).
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAudio());
  }

  /// ANDROID AUDIO-FOCUS FIX — the mix context must be set PER PLAYER.
  /// Default `AudioFocus.gain` makes the voice player PAUSE the looping BGM
  /// (and focus-paused players never auto-resume). `AudioPlayer.global.…` only
  /// affects players created AFTER it — ours are field initializers — so set
  /// the context on each player; with `AudioFocus.none` all lanes mix and our
  /// setVolume ducking handles loudness. (See the playbook gotcha.)
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
    _controller.onFirstBuild();
    // NOTE: AssetSource is relative to assets/ (audioplayers adds the prefix).
    if (!_muted) _startBgm();
    _playVoice(OLVoice.brief); // Orbit speaks the start-screen line
  }

  void _startBgm() {
    _bgmStarted = true;
    _bgm.play(audioSource(OLSounds.bgm), volume: _bgmVolume).catchError((_) {});
  }

  @override
  void dispose() {
    _voiceSafety?.cancel();
    _controller.removeListener(_onVoiceCue);
    _controller.dispose();
    _sfx.dispose();
    _voice.dispose();
    _bgm.stop().catchError((_) {});
    _bgm.dispose();
    super.dispose();
  }

  void _playSound(String assetFile) {
    if (_muted) return;
    _sfx.play(audioSource(assetFile)).catchError((_) {});
  }

  void _playVoice(String assetFile) {
    if (_muted) return;
    _voiceSafety?.cancel();
    _voice.stop();
    _bgm.setVolume(_bgmDucked).catchError((_) {}); // duck the bed under Orbit
    _controller.setVoicePlaying(true);
    // Safety: if the platform drops the complete event (missing file, focus
    // loss), un-gate the CTAs anyway.
    _voiceSafety = Timer(const Duration(seconds: 12), _voiceDone);
    _voice.play(audioSource(assetFile)).catchError((_) => _voiceDone());
  }

  /// Narration finished (complete / failed / safety) → restore the bed,
  /// re-enable buttons, and auto-advance multi-part lines.
  void _voiceDone() {
    _voiceSafety?.cancel();
    _bgm.setVolume(_bgmVolume).catchError((_) {}); // restore the bed
    // Self-heal: if anything paused the loop, bring it back (no-op if playing).
    if (!_muted) _bgm.resume().catchError((_) {});
    if (!mounted) return;
    _controller.setVoicePlaying(false);
    final s = _controller.state;
    if (s.scene == OrbitActivityState.straightLaunchFailed &&
        s.bubbleText.startsWith('Did you see')) {
      // small breath between the two parts, then part 2 (+ its audio via the cue)
      Future.delayed(const Duration(milliseconds: 350), _controller.advanceFellBack);
    }
  }

  /// Stops narration without the "what's next" routing (scene without a line).
  void _stopVoice() {
    _voiceSafety?.cancel();
    _voice.stop();
    _bgm.setVolume(_bgmVolume).catchError((_) {});
    _controller.setVoicePlaying(false);
  }

  /// Plays the matching Orbit voice-over whenever a new bubble appears; any
  /// state without a line (launch animations, try-again nudge) stops narration.
  void _onVoiceCue() {
    final s = _controller.state;
    final key = '${s.scene.name}|${s.bubbleText}';
    if (key == _lastVoiceKey) return;
    _lastVoiceKey = key;
    final vo = _voiceFor(s);
    if (vo != null) {
      _playVoice(vo);
    } else {
      _stopVoice();
    }
  }

  String? _voiceFor(OrbitLauncherState s) => switch (s.scene) {
        OrbitActivityState.missionBrief => OLVoice.brief,
        OrbitActivityState.missionGoal => OLVoice.goal1, // goal2 via the panel's onAdvance
        OrbitActivityState.launchpadIntro => OLVoice.launchpad,
        OrbitActivityState.straightLaunchAnimating => OLVoice.upItGoes,
        OrbitActivityState.straightLaunchFailed =>
          s.bubbleText.startsWith('Did you see') ? OLVoice.fellBack1 : OLVoice.fellBack2,
        OrbitActivityState.tiltUnlocked => OLVoice.tiltUnlocked,
        // the try-again nudge has no recorded line
        OrbitActivityState.challengeReady =>
          s.bubbleText.startsWith('Now you control') ? OLVoice.challenge : null,
        OrbitActivityState.notEnoughPower => OLVoice.notEnoughPower,
        OrbitActivityState.tooStraight => OLVoice.tooStraight,
        OrbitActivityState.tooMuchTilt => OLVoice.tooMuchTilt,
        OrbitActivityState.tooFast => OLVoice.tooFast,
        OrbitActivityState.almost => OLVoice.almost,
        OrbitActivityState.orbitLocked => OLVoice.orbitLocked,
        _ => null, // missionLaunching, bridge
      };

  void _exit() {
    _controller.finish();
    Navigator.of(context).maybePop();
  }

  Widget _reactive(Widget Function(OrbitLauncherState s) build) =>
      AnimatedBuilder(animation: _controller, builder: (_, __) => build(_controller.state));

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: const Color(0xFF05102A),
        body: Stack(
          children: [
            Positioned.fill(child: _gameWidget),
            Positioned.fill(
              child: SafeArea(
                child: Stack(
                  children: [
                    // Back button (top-left).
                    Positioned(
                      top: 8,
                      left: 12,
                      child: PressableScale(
                        onTap: _exit,
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CareerColors.blue.withValues(alpha: 0.85),
                            boxShadow: [BoxShadow(color: CareerColors.blue.withValues(alpha: 0.5), blurRadius: 12)],
                          ),
                          child: const Icon(Icons.arrow_back_rounded, size: 22, color: Colors.white),
                        ),
                      ),
                    ),
                    // Mission-Control bubble (top-right).
                    Positioned(
                      top: 8,
                      left: 60,
                      right: 12,
                      child: _reactive((s) => (s.scene == OrbitActivityState.missionBrief ||
                              s.scene == OrbitActivityState.missionGoal)
                          ? const SizedBox.shrink() // Orbit sits at the bottom on these screens
                          : MissionControlBubble(mood: s.mascot, text: s.bubbleText)),
                    ),
                    // Bottom panel — swaps with the scene.
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: _reactive(_bottomPanel),
                    ),
                  ],
                ),
              ),
            ),
            // Start-screen brief — topmost full-bleed overlay; fades out on START.
            Positioned.fill(
              child: _reactive((s) {
                final showing = s.scene == OrbitActivityState.missionBrief;
                return IgnorePointer(
                  ignoring: !showing,
                  child: AnimatedOpacity(
                    opacity: showing ? 1 : 0,
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeInOut,
                    child: MissionBriefScreen(
                      onStart: _controller.readyToLaunch,
                      startEnabled: !s.voicePlaying,
                      onBack: _exit,
                      muted: _muted,
                      onToggleMute: () => setState(() {
                        _muted = !_muted;
                        if (_muted) {
                          _stopVoice();
                          _bgm.pause().catchError((_) {});
                          _controller.advanceFellBack(); // don't strand part 2 if muted mid-line
                        } else {
                          _bgm.setVolume(_bgmVolume).catchError((_) {});
                          if (_bgmStarted) {
                            _bgm.resume().catchError((_) {});
                          } else {
                            _startBgm(); // was muted before the bed ever began
                          }
                        }
                      }),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomPanel(OrbitLauncherState s) {
    final child = switch (s.scene) {
      OrbitActivityState.missionGoal => MissionGoalPanel(
          key: const ValueKey('goal'),
          enabled: !s.voicePlaying,
          onLaunch: _controller.letsLaunch,
          onAdvance: () => _playVoice(OLVoice.goal2),
        ),
      OrbitActivityState.launchpadIntro => OrbitButton(
          key: const ValueKey('launch'),
          label: 'Launch',
          colors: const [Color(0xFF34D17E), Color(0xFF17A95C)],
          leadingIcon: Icons.rocket_launch_rounded,
          onTap: _controller.launch,
          enabled: !s.voicePlaying,
        ),
      OrbitActivityState.tiltUnlocked =>
        TiltUnlockPanel(key: const ValueKey('tilt'), controller: _controller),
      OrbitActivityState.challengeReady =>
        ControlPanel(key: const ValueKey('controls'), controller: _controller),
      OrbitActivityState.straightLaunchFailed ||
      OrbitActivityState.notEnoughPower ||
      OrbitActivityState.tooStraight ||
      OrbitActivityState.tooMuchTilt ||
      OrbitActivityState.tooFast ||
      OrbitActivityState.almost ||
      OrbitActivityState.orbitLocked =>
        // Orbit-Locked AWESOME! exits to the hub for now (bridge screen disabled).
        ResultCard(key: const ValueKey('result'), controller: _controller, onOrbitFinish: _exit),
      // Bridge (next-activity) screen disabled for now (kept for later). AWESOME!
      // exits to the hub, so nextActivityBridge is normally never reached.
      // OrbitActivityState.nextActivityBridge =>
      //   BridgePanel(key: const ValueKey('bridge'), onFinish: _exit),
      // animating scenes (+ disabled bridge): hide controls.
      _ => const SizedBox.shrink(key: ValueKey('empty')),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (c, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.18), end: Offset.zero).animate(a),
          child: c,
        ),
      ),
      child: child,
    );
  }
}
