// HOW ACTIVITY 3 V2 STATE UPDATES.
//
// One ChangeNotifier owns the immutable [OrbitLauncherState]. The Flutter shell
// rebuilds via ListenableBuilder; the Flame game listens too and plays the
// visuals for each scene, calling back at animation beats (straightLaunchDone,
// missionResolved) to advance the machine.
//
// Flow: launchpadIntro → launch() → [straight up + fall] → straightLaunchDone()
// → straightLaunchFailed → gotIt() → tiltUnlocked → tryIt() → challengeReady →
// setPower/setTilt/launchMission() → [outcome animation] → missionResolved() →
// outcome → tryAgain() | awesome() → nextActivityBridge → finish().

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/orbit_tuning.dart';
import 'analytics.dart';
import 'orbit_launcher_state.dart';

class OrbitLauncherController extends ChangeNotifier {
  OrbitLauncherController({OrbitAnalytics? analytics})
      : analytics = analytics ?? const OrbitAnalytics(),
        _state = const OrbitLauncherState(
          scene: OrbitActivityState.missionBrief,
          launchPower: OT.defaultPower,
          tiltAngle: OT.defaultTilt,
          attemptCount: 0,
          lastOutcome: null,
          mascot: McMood.happy,
          bubbleText: '',
          tiltUnlocked: false,
        );

  final OrbitAnalytics analytics;
  OrbitLauncherState _state;
  OrbitLauncherState get state => _state;

  bool _started = false;
  Timer? _bubbleTimer; // sequences multi-part Orbit lines

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    super.dispose();
  }

  /// The outcome the current LAUNCH MISSION will resolve to (the game reads this
  /// to pick which trajectory to animate).
  OrbitOutcome get launchingOutcome => OT.outcomeFor(_state.launchPower, _state.tiltAngle);

  void _set(OrbitLauncherState s) {
    _state = s;
    notifyListeners();
  }

  void onFirstBuild() {
    if (_started) return;
    _started = true;
    analytics.activityStarted();
  }

  /// "READY TO LAUNCH" on the mission-control start screen → the launchpad.
  /// "START MISSION" on the window start screen → the mission-goal screen.
  void readyToLaunch() {
    if (_state.scene != OrbitActivityState.missionBrief) return;
    _set(_state.copyWith(
      scene: OrbitActivityState.missionGoal,
      mascot: McMood.happy,
      bubbleText: 'Our goal is to place the satellite into orbit.',
    ));
  }

  /// "LET'S LAUNCH" on the mission-goal screen → the launchpad.
  void letsLaunch() {
    if (_state.scene != OrbitActivityState.missionGoal) return;
    _set(_state.copyWith(
      scene: OrbitActivityState.launchpadIntro,
      mascot: McMood.happy,
      bubbleText: 'First, let’s try the simplest idea: launch straight up and see what happens.',
    ));
  }

  // ── straight-up launch (forced, fails) ──────────────────────────────────────
  void launch() {
    if (_state.scene != OrbitActivityState.launchpadIntro) return;
    analytics.straightLaunched();
    _set(_state.copyWith(
      scene: OrbitActivityState.straightLaunchAnimating,
      mascot: McMood.happy,
      bubbleText: 'Up it goes…',
    ));
  }

  /// Whether Orbit's narration audio is currently playing (set by the shell).
  /// Primary buttons dim/disable while true so the child hears the full line.
  void setVoicePlaying(bool playing) {
    if (_state.voicePlaying == playing) return;
    _set(_state.copyWith(voicePlaying: playing));
  }

  static const _fellBackPart1 =
      'Did you see what happened? The rocket went up, but it came right back down. '
      'Gravity pulled it back.';
  static const _fellBackPart2 = 'To make orbit, we need a curved path — not just straight up.';

  /// Game callback: the rocket rose and fell back to the pad. Orbit's lesson
  /// arrives as TWO bubbles: part 2 follows when part 1's AUDIO completes (the
  /// shell calls [advanceFellBack]); a reading-time fallback covers the muted /
  /// audio-blocked case (it skips itself if narration is still playing).
  void straightLaunchDone() {
    if (_state.scene != OrbitActivityState.straightLaunchAnimating) return;
    analytics.straightFailed();
    _set(_state.copyWith(
      scene: OrbitActivityState.straightLaunchFailed,
      mascot: McMood.thinking,
      bubbleText: _fellBackPart1,
    ));
    _bubbleTimer?.cancel();
    _bubbleTimer = Timer(const Duration(milliseconds: 3500), () {
      if (_state.voicePlaying) return; // narration in progress — audio completion advances
      advanceFellBack();
    });
  }

  /// Move from fell-back part 1 to part 2 (idempotent; safe to call anytime).
  void advanceFellBack() {
    if (_state.scene != OrbitActivityState.straightLaunchFailed) return;
    if (_state.bubbleText != _fellBackPart1) return;
    _set(_state.copyWith(bubbleText: _fellBackPart2));
  }

  /// "GOT IT" on the straight-up failure → reveal the Tilt-Angle unlock.
  void gotIt() {
    if (_state.scene != OrbitActivityState.straightLaunchFailed) return;
    _bubbleTimer?.cancel();
    analytics.tiltUnlocked();
    _set(_state.copyWith(
      scene: OrbitActivityState.tiltUnlocked,
      tiltUnlocked: true,
      mascot: McMood.thinking,
      bubbleText: 'So what’s missing? The rocket also needs to turn sideways. '
          'That sideways speed helps create a curved path.',
    ));
  }

  /// "GOT IT!" on the unlock panel → the two-slider challenge.
  void tryIt() {
    if (_state.scene != OrbitActivityState.tiltUnlocked) return;
    _set(_state.copyWith(
      scene: OrbitActivityState.challengeReady,
      mascot: McMood.happy,
      bubbleText: 'Now you control the mission. Launch Power gets it high. '
          'Tilt Angle helps it turn. Find the orbit mix!',
    ));
  }

  // ── challenge ───────────────────────────────────────────────────────────────
  void setPower(double v) {
    if (_state.scene != OrbitActivityState.challengeReady) return;
    final clamped = v.clamp(0, 100).toDouble();
    if (clamped == _state.launchPower) return;
    _set(_state.copyWith(launchPower: clamped));
  }

  void setTilt(double v) {
    if (_state.scene != OrbitActivityState.challengeReady) return;
    final clamped = v.clamp(0, 100).toDouble();
    if (clamped == _state.tiltAngle) return;
    _set(_state.copyWith(tiltAngle: clamped));
  }

  void launchMission() {
    if (_state.scene != OrbitActivityState.challengeReady) return;
    final attempt = _state.attemptCount + 1;
    analytics.missionLaunched(attempt, _state.launchPower.round(), _state.tiltAngle.round());
    _set(_state.copyWith(
      scene: OrbitActivityState.missionLaunching,
      attemptCount: attempt,
      bubbleText: '',
    ));
  }

  /// Game callback: the outcome animation reached its decisive moment.
  void missionResolved() {
    if (_state.scene != OrbitActivityState.missionLaunching) return;
    final outcome = launchingOutcome;
    analytics.outcomeShown(outcome, _state.attemptCount);

    final scene = switch (outcome) {
      OrbitOutcome.notEnoughPower => OrbitActivityState.notEnoughPower,
      OrbitOutcome.tooStraight => OrbitActivityState.tooStraight,
      OrbitOutcome.tooMuchTilt => OrbitActivityState.tooMuchTilt,
      OrbitOutcome.tooFast => OrbitActivityState.tooFast,
      OrbitOutcome.almost => OrbitActivityState.almost,
      OrbitOutcome.orbitLocked => OrbitActivityState.orbitLocked,
    };
    if (outcome == OrbitOutcome.orbitLocked) {
      analytics.orbitLocked(_state.attemptCount, _state.launchPower.round(), _state.tiltAngle.round());
    }

    _set(_state.copyWith(
      scene: scene,
      lastOutcome: outcome,
      mascot: outcome == OrbitOutcome.orbitLocked ? McMood.celebrating : McMood.thinking,
      bubbleText: _outcomeLesson(outcome), // the character explains WHY
    ));
  }

  /// What Mission Control says to teach the *why* behind each outcome.
  String _outcomeLesson(OrbitOutcome o) => switch (o) {
        OrbitOutcome.notEnoughPower =>
          'See that? It didn’t climb high enough. Gravity pulled it back before it could reach space.',
        OrbitOutcome.tooStraight =>
          'It went high, but stayed too straight. It didn’t get enough sideways speed to curve around Earth.',
        OrbitOutcome.tooMuchTilt =>
          'Whoa, it turned too early! It started going sideways before it climbed high enough.',
        OrbitOutcome.tooFast =>
          'Whoa! That was too much speed. It shot away instead of staying in a path around Earth.',
        OrbitOutcome.almost =>
          'That was close! The path started curving around Earth, but it didn’t keep repeating.',
        OrbitOutcome.orbitLocked =>
          'Yes! Now the satellite is following a repeating curved path around Earth. That’s orbit!',
      };

  void tryAgain() {
    if (!_state.isFailOutcome) return;
    analytics.tryAgain(_state.attemptCount);
    _set(_state.copyWith(
      scene: OrbitActivityState.challengeReady,
      mascot: McMood.happy,
      bubbleText: 'Let’s tweak the power and tilt, then launch again!',
    ));
  }

  void awesome() {
    if (_state.scene != OrbitActivityState.orbitLocked) return;
    analytics.bridgeShown();
    _set(_state.copyWith(
      scene: OrbitActivityState.nextActivityBridge,
      mascot: McMood.celebrating,
      bubbleText: 'Great job! Our satellite is now in orbit — but right now it’s just an empty box. '
          'What should we put inside it so it can help people on Earth?',
    ));
  }

  void finish() => analytics.activityFinished();
}
