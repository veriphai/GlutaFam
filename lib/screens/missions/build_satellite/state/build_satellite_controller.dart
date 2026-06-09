// HOW MISSION STATE UPDATES.
//
// A single ChangeNotifier owns the immutable [BuildSatelliteMissionState].
// • The Flame game calls [installPart] / [registerWrongDrop] after spatial
//   slot detection, and [onPartNearCorrectSlot] when a drag hover enters
//   the correct slot for the first time.
// • The Flutter shell (meters, rail, mascot, tray, launch button) rebuilds via
//   ListenableBuilder / AnimatedBuilder whenever [state] changes; it owns the
//   AudioPlayer and forwards player-complete events to [onVoiceFinished].
//
// VOICE: every event queues 1+ OrbitLine clips; the first plays immediately,
// subsequent ones play as each previous clip's onPlayerComplete fires. A 12 s
// safety timer fires onVoiceFinished if the player never completes (missing
// asset, focus loss). Same pattern as Restore Earth.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/orbit_dialogue.dart';
import '../config/part_catalog.dart';
import 'build_satellite_state.dart';
import 'mission_steps.dart';

// Meter starting values (0..100). Parts add their deltas on top.
const double _basePower = 10;
const double _baseSignal = 0;
const double _baseStability = 10;

class BuildSatelliteController extends ChangeNotifier {
  BuildSatelliteController() : _state = _initialState() {
    // First line (Bs.open1) is already on screen; queue the rest of the
    // opening + the Step 1 intro.
    _voiceQueue.addAll([Bs.open2, Bs.open3, Bs.s1Intro]);
    _scheduleVoiceSafety();
  }

  BuildSatelliteMissionState _state;
  BuildSatelliteMissionState get state => _state;

  /// Pending Orbit lines that play one-after-the-other on each
  /// onPlayerComplete. The currently-playing line is NOT in this list — it
  /// lives in `state.voiceClip` (and `state.helperMessage`).
  final List<OrbitLine> _voiceQueue = [];

  /// Safety net: if the audio file is missing / the platform never fires
  /// onPlayerComplete, this fires onVoiceFinished anyway. Cancelled on real
  /// completion or any state change that overwrites the voice.
  Timer? _voiceSafety;
  void _scheduleVoiceSafety() {
    _voiceSafety?.cancel();
    _voiceSafety = Timer(const Duration(seconds: 12), onVoiceFinished);
  }

  void _cancelVoiceSafety() {
    _voiceSafety?.cancel();
    _voiceSafety = null;
  }

  /// Set by the Flame game so the controller can fire subsystem reveals
  /// in sync with each spoken launch-check line. Clip → visual mapping is
  /// inside the game; controller just signals the clip.
  void Function(int clip)? onLaunchClipPlayed;

  @override
  void dispose() {
    _cancelVoiceSafety();
    super.dispose();
  }

  static BuildSatelliteMissionState _initialState() {
    final step = kMissionSteps.first;
    final line = Bs.open1;
    return BuildSatelliteMissionState(
      currentStep: step.number,
      installedParts: const {},
      launchPreviewUnlocked: false,
      powerLevel: _basePower,
      signalLevel: _baseSignal,
      stabilityLevel: _baseStability,
      highlightedPartId: step.requiredPartIds.first,
      helperMessage: line.text,
      mood: line.mood,
      voiceClip: line.clip,
      voiceToken: 1,
    );
  }

  // ── Derived helpers used by the UI + game ──────────────────────────────
  MissionStep get currentStep => missionStep(_state.currentStep);
  bool isInstalled(String partId) => _state.installedParts.contains(partId);

  /// A part is draggable only while its step is the active step and it isn't
  /// installed yet — this enforces the guided sequence (PRD §7.7).
  bool isActive(String partId) {
    if (_state.isComplete || isInstalled(partId)) return false;
    return partById(partId).stepNumber == _state.currentStep;
  }

  /// Slot ids that should glow as drop targets right now.
  Set<String> get activeSlotIds => kSatelliteParts
      .where((p) => isActive(p.id))
      .map((p) => p.slotId)
      .toSet();

  // ── Voice plumbing ─────────────────────────────────────────────────────
  /// Replace whatever's in the queue with [lines]; start playing [lines.first]
  /// immediately. Every voice-triggering event funnels through here so we
  /// never have two queues fighting.
  void _enqueueAndPlay(List<OrbitLine> lines) {
    if (lines.isEmpty) return;
    _voiceQueue
      ..clear()
      ..addAll(lines.skip(1));
    _setVoice(lines.first);
  }

  void _setVoice(OrbitLine line) {
    _state = _state.copyWith(
      helperMessage: line.text,
      mood: line.mood,
      voiceClip: line.clip,
      voiceToken: _state.voiceToken + 1,
    );
    notifyListeners();
    _scheduleVoiceSafety();
    // Game wires this to fire the matching launch-check visual.
    onLaunchClipPlayed?.call(line.clip);
  }

  /// Screen calls this when the current voice clip finishes (or after the
  /// 12 s safety). Drives queue advancement and the two "end of sequence"
  /// transitions (launch → reward popup, last reward → continueEnabled).
  void onVoiceFinished() {
    _cancelVoiceSafety();
    if (_voiceQueue.isNotEmpty) {
      _setVoice(_voiceQueue.removeAt(0));
      return;
    }
    // Queue is empty — handle terminal transitions.
    final clip = _state.voiceClip;
    if (_state.launching && clip == Bs.checkProtection.clip) {
      // Last launch-check line finished → reveal the reward popup, queue its
      // narration lines.
      _state = _state.copyWith(
        launching: false,
        rewardVisible: true,
        mood: MascotMood.celebrating,
      );
      notifyListeners();
      _enqueueAndPlay([Bs.rewardMain, Bs.rewardSkill]);
      return;
    }
    if (_state.rewardVisible && clip == Bs.rewardSkill.clip) {
      // Final reward narration done → light up Continue.
      _state = _state.copyWith(continueEnabled: true);
      notifyListeners();
      return;
    }
  }

  // ── Core transition: a part was correctly placed ───────────────────────
  void installPart(SatellitePart part) {
    if (isInstalled(part.id)) return;

    final installed = {..._state.installedParts, part.id};
    final meters = _recomputeMeters(installed);
    final oldStep = _state.currentStep;
    final newStep = _computeCurrentStep(installed);
    final complete = _isComplete(installed);

    // Update derived state silently — _enqueueAndPlay will notify.
    _state = _state.copyWith(
      installedParts: installed,
      currentStep: newStep,
      powerLevel: meters.$1,
      signalLevel: meters.$2,
      stabilityLevel: meters.$3,
      highlightedPartId: _nextHighlight(newStep, installed),
      launchPreviewUnlocked: complete,
      hintActive: false,
    );

    _enqueueAndPlay(_placementSequence(oldStep, complete));
  }

  /// What Orbit says after a part is placed. Encodes the per-step copy plan
  /// from the dialogue spec (placement → optional followup → optional more →
  /// step-complete or next-step intro).
  List<OrbitLine> _placementSequence(int oldStep, bool complete) {
    if (complete) {
      // Step 7 final placement: placed → followup → final-complete → summary.
      return [Bs.s7Placed, Bs.s7Followup, Bs.s7FinalComplete, Bs.s7Summary];
    }
    final installedNow = _state.installedParts;
    switch (oldStep) {
      case 1:
        final bothPanelsIn = installedNow.contains('left_solar_panel') &&
            installedNow.contains('right_solar_panel');
        if (bothPanelsIn) {
          // 2nd panel just landed → power online + step 2 intro.
          return [Bs.s1Complete, Bs.s2Intro];
        }
        // 1st panel landed → placed + followup + 2nd-panel intro.
        return [Bs.s1P1Placed, Bs.s1P1Followup, Bs.s1P2Intro];
      case 2:
        final bothAntennaIn = installedNow.contains('antenna_base') &&
            installedNow.contains('antenna_dish');
        if (bothAntennaIn) {
          // Dish landed → signal online + more + step 3 intro.
          return [Bs.s2Complete, Bs.s2More, Bs.s3Intro];
        }
        // Base landed → placed + dish intro.
        return [Bs.s2P1Placed, Bs.s2P2Intro];
      case 3:
        return [Bs.s3Complete, Bs.s3Followup, Bs.s3More, Bs.s4Intro];
      case 4:
        return [Bs.s4Complete, Bs.s4Followup, Bs.s4More, Bs.s5Intro];
      case 5:
        return [Bs.s5Complete, Bs.s5Followup, Bs.s5More, Bs.s6Intro];
      case 6:
        return [Bs.s6Complete, Bs.s6Followup, Bs.s6More, Bs.s7Intro];
      default:
        return const [];
    }
  }

  /// A part was dropped on the wrong place: gentle, non-punishing correction.
  /// Two-line sequence (wrongA → wrongB).
  void registerWrongDrop() {
    _state = _state.copyWith(hintActive: false, mood: MascotMood.concerned);
    _enqueueAndPlay([Bs.wrongA, Bs.wrongB]);
  }

  // ── Pickup / hover voice cues ──────────────────────────────────────────
  void onPartPickup(String partId) {
    final line = _pickupLineFor(partId);
    if (line == null) return;
    _enqueueAndPlay([line]);
  }

  OrbitLine? _pickupLineFor(String partId) {
    switch (partId) {
      case 'left_solar_panel':
      case 'right_solar_panel':
        // Only on the FIRST solar panel pickup. The second is preceded by
        // Bs.s1P2Intro queued at first-panel placement, so a pickup line
        // would interrupt it.
        final firstAlreadyPlaced =
            _state.installedParts.contains('left_solar_panel') ||
                _state.installedParts.contains('right_solar_panel');
        return firstAlreadyPlaced ? null : Bs.s1P1Pickup;
      case 'antenna_base':
        return Bs.s2P1Pickup;
      case 'antenna_dish':
        return null; // Bs.s2P2Intro covers this beat.
      case 'camera_module':
        return Bs.s3Pickup;
      case 'computer_core_chip':
        return Bs.s4Pickup;
      case 'battery_module':
        return Bs.s5Pickup;
      case 'thruster':
        return Bs.s6Pickup;
      case 'thermal_blanket':
        return Bs.s7Pickup;
    }
    return null;
  }

  /// Game calls this once when a drag hover first enters the part's correct
  /// slot — fires the "Yes, that's the spot" voice cue when one exists.
  void onPartNearCorrectSlot(String partId) {
    final line = _nearSlotLineFor(partId);
    if (line == null) return;
    _enqueueAndPlay([line]);
  }

  OrbitLine? _nearSlotLineFor(String partId) {
    switch (partId) {
      case 'left_solar_panel':
      case 'right_solar_panel':
        final firstAlreadyPlaced =
            _state.installedParts.contains('left_solar_panel') ||
                _state.installedParts.contains('right_solar_panel');
        return firstAlreadyPlaced ? null : Bs.s1P1NearSlot;
      case 'camera_module':
        return Bs.s3NearSlot;
    }
    return null;
  }

  // ── Idle hinting (two tiers: 6 s → 12 s) ───────────────────────────────
  void nudgeHint() {
    if (_state.isComplete || _state.hintActive || _state.launching) return;
    final partId = _state.highlightedPartId;
    if (partId.isEmpty) return;
    _state = _state.copyWith(hintActive: true);
    _enqueueAndPlay([Bs.idle1For(partId)]);
  }

  void nudgeHintStronger() {
    if (_state.isComplete || _state.launching) return;
    final partId = _state.highlightedPartId;
    if (partId.isEmpty) return;
    _enqueueAndPlay([Bs.idle2For(partId)]);
  }

  void clearHint() {
    if (!_state.hintActive) return;
    _state = _state.copyWith(hintActive: false);
    notifyListeners();
  }

  // ── Launch preview + reward ────────────────────────────────────────────
  void startLaunch() {
    if (!_state.launchPreviewUnlocked || _state.launching) return;
    _state = _state.copyWith(launching: true, mood: MascotMood.thinking);
    _enqueueAndPlay([
      Bs.launchTap,
      Bs.launchOpen,
      Bs.checkPower,
      Bs.checkSignal,
      Bs.checkVision,
      Bs.checkBrain,
      Bs.checkBattery,
      Bs.checkMovement,
      Bs.checkProtection,
    ]);
  }

  /// Legacy hook still called by the existing game launch controller when
  /// the visual sequence finishes. With voice-driven launch this is a no-op
  /// — the reward popup is shown from [onVoiceFinished] after the last
  /// check line completes.
  void onLaunchSequenceComplete() {}

  void dismissReward() {
    _state = _state.copyWith(rewardVisible: false);
    notifyListeners();
  }

  // ── internals ──────────────────────────────────────────────────────────
  (double, double, double) _recomputeMeters(Set<String> installed) {
    var power = _basePower, signal = _baseSignal, stability = _baseStability;
    for (final id in installed) {
      final p = partById(id);
      power += p.powerDelta;
      signal += p.signalDelta;
      stability += p.stabilityDelta;
    }
    double c(double v) => v.clamp(0, 100);
    return (c(power), c(signal), c(stability));
  }

  int _computeCurrentStep(Set<String> installed) {
    for (final step in kMissionSteps) {
      final done = step.requiredPartIds.every(installed.contains);
      if (!done) return step.number;
    }
    return kTotalSteps;
  }

  bool _isComplete(Set<String> installed) =>
      kSatelliteParts.every((p) => installed.contains(p.id));

  String _nextHighlight(int step, Set<String> installed) {
    for (final p in partsForStep(step)) {
      if (!installed.contains(p.id)) return p.id;
    }
    return '';
  }
}
