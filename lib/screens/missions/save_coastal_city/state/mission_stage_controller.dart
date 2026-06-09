// MissionStageController — single ChangeNotifier owning the Save the Coastal
// City flow: the MissionStage state machine, the Orbit dialogue queue, hint
// escalation, the stage-specific rules (slingshot bands, power/shadow script,
// camera lock, signal hold, circle validation, repair steps, command graph,
// upload), readiness meter, badges, and analytics.
//
// Scenes and the Flame game are renderers + input: they call the stage methods
// below and rebuild off [state]. Per the playbook, one-shot FX are bump-token
// ints, and every value a caller needs after a notifying call is captured
// BEFORE the call (synchronous notifyListeners foot-gun).

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/scc_dialogue.dart';
import '../config/scc_stage_configs.dart';
import 'mission_state.dart';
import 'orbit_dialogue_controller.dart';
import 'scc_analytics.dart';

/// Cue events the shell maps to SFX + haptics (house pattern).
enum SccCue { tap, scan, lock, correct, wrong, complete, alert, upload }

class MissionStageController extends ChangeNotifier {
  MissionStageController({this.onCue}) {
    dialogue.onQueueIdle = _onDialogueIdle;
  }

  final void Function(SccCue cue)? onCue;

  MissionState _state = const MissionState();
  MissionState get state => _state;

  // ── analytics bookkeeping ──────────────────────────────────────────────────
  final _stageAttempts = <MissionStage, int>{};
  final _stageHints = <MissionStage, int>{};
  DateTime? _stageStartedAt;
  DateTime? _missionStartedAt;
  int _totalAttempts = 0;

  // ── dialogue (queue + pacing live in OrbitDialogueController) ─────────────
  late final OrbitDialogueController dialogue =
      OrbitDialogueController(emit: _emitLine);
  bool get _queueBusy => dialogue.busy;

  /// One-shot continuation fired when the dialogue queue drains (the line's
  /// VOICE included) — voice-paced stage advances / countdowns / CTA gates.
  /// Each closure re-checks state so a stale fire is harmless.
  void Function()? _onIdleOnce;

  void _onDialogueIdle() {
    final fn = _onIdleOnce;
    _onIdleOnce = null;
    fn?.call();
  }

  // misc timers (power script, finale script, badge reveal…)
  final List<Timer> _timers = [];
  Timer _later(Duration d, void Function() fn) {
    final t = Timer(d, fn);
    _timers.add(t);
    return t;
  }

  void _set(MissionState next) {
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    dialogue.dispose();
    _powerTick?.cancel(); // periodic — would notify after dispose if leaked
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Dialogue
  // ───────────────────────────────────────────────────────────────────────────

  void say(List<Line> lines, {bool replace = true}) =>
      dialogue.say(lines, replace: replace);

  void sayOne(Line line, {bool replace = true}) => say([line], replace: replace);

  /// OrbitDialogueController → state: the visible line + face + bump tokens
  /// (dialogueToken drives the bubble swap animation; voiceToken is the VO
  /// hook — clips are null in the text-only build).
  void _emitLine(Line line) {
    _set(_state.copyWith(
      dialogueText: line.text,
      face: line.face,
      dialogueToken: _state.dialogueToken + 1,
      voiceClip: line.clip,
      voiceToken: line.clip != null ? _state.voiceToken + 1 : null,
    ));
  }

  /// Tap-to-advance from the bubble (only meaningful while lines are queued).
  void advanceDialogue() => dialogue.advance();

  // ───────────────────────────────────────────────────────────────────────────
  // Mistakes + hint escalation (PRD §22.4)
  // ───────────────────────────────────────────────────────────────────────────

  void _mistake(MissionStage stage, String type, List<Line> hint) {
    _stageAttempts[stage] = (_stageAttempts[stage] ?? 0) + 1;
    _totalAttempts++;
    SccAnalytics.stageMistake(_stageId(stage), type);
    final level = (_stageHints[stage] ?? 0) + 1;
    _stageHints[stage] = level;
    SccAnalytics.hintShown(_stageId(stage), level.clamp(1, 3));
    onCue?.call(SccCue.wrong);
    say(hint);
  }

  String _stageId(MissionStage s) => kStageInfo[s]?.analyticsId ?? s.name;

  /// How many hints this stage has burned — scenes show a VISUAL guide at
  /// level >= 3 (PRD §22.4: conceptual → direct → show visual guide).
  int hintLevelFor(MissionStage s) => _stageHints[s] ?? 0;

  // ───────────────────────────────────────────────────────────────────────────
  // Stage flow
  // ───────────────────────────────────────────────────────────────────────────

  static const _stageOrder = [
    MissionStage.intro,
    ...kPlayableStages,
    MissionStage.finalSuccess, // the MISSION COMPLETE card screen
    MissionStage.badgeReveal,
  ];

  void begin() {
    _missionStartedAt = DateTime.now();
    SccAnalytics.finalMissionStarted();
    say(SccDialogue.intro.toList());
  }

  /// Intro hold finished — power up the rail and enter Stage 1.
  void introHoldComplete() {
    onCue?.call(SccCue.complete);
    _enterStage(MissionStage.chooseSatellite);
  }

  void _enterStage(MissionStage stage) {
    _stageStartedAt = DateTime.now();
    SccAnalytics.stageStarted(_stageId(stage));
    _set(_state.copyWith(stage: stage));
    switch (stage) {
      case MissionStage.chooseSatellite:
        say(SccDialogue.s1Intro.toList());
      case MissionStage.placeOrbit:
        say(SccDialogue.s2Intro.toList());
      case MissionStage.powerManagement:
        say(SccDialogue.s3Intro.toList());
        _ensurePowerTick(); // the meter lives from the moment the stage opens
      case MissionStage.captureImage:
        say(SccDialogue.s4Intro.toList());
      case MissionStage.sendData:
        say(SccDialogue.s5Intro.toList());
      case MissionStage.readImage:
        say([...SccDialogue.s6Intro, ...SccDialogue.s6CloudLayer]);
      case MissionStage.repairIssue:
        say([...SccDialogue.s7Alert, ...SccDialogue.s7BeforeRepair]);
        onCue?.call(SccCue.alert);
      case MissionStage.uploadCommands:
        say(SccDialogue.s8Intro.toList());
      case MissionStage.finalSuccess:
        // mission-complete card; Orbit reads the payoff + emotional recap
        // below it. Continue lights once the FINAL clip has been heard
        // (listen-before-skip; the muted fallback paces no-audio users).
        say([...SccDialogue.finale, ...SccDialogue.finaleEmotional]);
        _onIdleOnce = () {
          if (_state.stage == MissionStage.finalSuccess) {
            _set(_state.copyWith(
                finale: _state.finale.copyWith(continueEnabled: true)));
          }
        };
      case MissionStage.badgeReveal:
        _runBadgeScript();
      case MissionStage.intro:
        break;
    }
  }

  /// Mark [stage] complete, play its success lines, then auto-advance once the
  /// child has had time to read the learning line.
  void _completeStage(MissionStage stage, List<Line> successLines) {
    onCue?.call(SccCue.complete);
    final completed = {..._state.completed, stage};
    final readiness =
        (5 + completed.length * (95 ~/ kPlayableStages.length)).clamp(0, 100);
    _set(_state.copyWith(completed: completed, readiness: readiness));
    SccAnalytics.stageCompleted(
      _stageId(stage),
      (_stageAttempts[stage] ?? 0) + 1,
      DateTime.now().difference(_stageStartedAt ?? DateTime.now()).inMilliseconds,
    );
    say(successLines);
    // Advance once the success + learning lines have been HEARD (voice-paced
    // — the dialogue controller's muted fallback covers no-audio users).
    _onIdleOnce = () {
      final idx = _stageOrder.indexOf(stage);
      if (idx >= 0 && idx + 1 < _stageOrder.length && _state.stage == stage) {
        _later(const Duration(milliseconds: 500), () {
          if (_state.stage == stage) _enterStage(_stageOrder[idx + 1]);
        });
      }
    };
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Stage 1 · Choose the Right Satellite
  // ───────────────────────────────────────────────────────────────────────────

  void scanSatellite(SatKind kind) {
    if (_state.stage != MissionStage.chooseSatellite || _state.scanner.deployed) return;
    if (_state.scanner.lastScanned == kind) return;
    final def = kSatCatalog.firstWhere((d) => d.kind == kind);
    onCue?.call(SccCue.scan);
    _set(_state.copyWith(
      scanner: _state.scanner.copyWith(
        discovered: {..._state.scanner.discovered, kind},
        lastScanned: kind,
      ),
    ));
    say(def.scanLines.toList());
  }

  void deploySelected() {
    final sel = _state.scanner.lastScanned;
    if (sel == null || _state.scanner.deployed) return;
    if (sel == SatKind.weather) {
      _set(_state.copyWith(scanner: _state.scanner.copyWith(deployed: true)));
      _completeStage(MissionStage.chooseSatellite, SccDialogue.s1Success.toList());
    } else {
      _mistake(MissionStage.chooseSatellite, 'wrong_satellite_${sel.name}',
          SccDialogue.s1WrongDeploy.toList());
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Stage 2 · Orbit slingshot
  // ───────────────────────────────────────────────────────────────────────────

  /// Outcome banding (PRD §13.6 — generous window + snap when close).
  SlingOutcome outcomeFor(double strength) {
    const t = SlingshotTuning.lowMax;
    const f = SlingshotTuning.farMin;
    const m = SlingshotTuning.snapMargin;
    if (strength >= t && strength <= f) return SlingOutcome.locked;
    if (strength >= t - m && strength < t) return SlingOutcome.almost;
    if (strength > f && strength <= f + m) return SlingOutcome.almost;
    return strength < t ? SlingOutcome.tooLow : SlingOutcome.tooFar;
  }

  /// Child released the sling. The game watches flightToken and animates the
  /// flight for [outcome]; it calls [flightResolved] when the animation ends.
  void slingshotReleased(double strength) {
    if (_state.stage != MissionStage.placeOrbit ||
        _state.orbit.phase != SlingPhase.aiming) {
      return;
    }
    if (strength < SlingshotTuning.minPull) return;
    final outcome = outcomeFor(strength);
    onCue?.call(SccCue.tap);
    _set(_state.copyWith(
      orbit: _state.orbit.copyWith(
        phase: SlingPhase.flying,
        outcome: outcome,
        strength: strength,
        flightToken: _state.orbit.flightToken + 1,
      ),
    ));
  }

  /// The Flame flight animation finished.
  void flightResolved() {
    if (_state.stage != MissionStage.placeOrbit) return;
    final outcome = _state.orbit.outcome; // capture before further sets
    switch (outcome) {
      case SlingOutcome.locked: // the generous snap band (PRD §13.6)
        _set(_state.copyWith(orbit: _state.orbit.copyWith(phase: SlingPhase.locked)));
        onCue?.call(SccCue.lock);
        _completeStage(MissionStage.placeOrbit, SccDialogue.s2Success.toList());
      case SlingOutcome.almost: // near-miss fringe → "almost there" hint (PRD §13.7)
        _set(_state.copyWith(orbit: _state.orbit.copyWith(phase: SlingPhase.aiming)));
        _mistake(MissionStage.placeOrbit, 'almost', SccDialogue.s2Almost.toList());
      case SlingOutcome.tooLow:
        _set(_state.copyWith(orbit: _state.orbit.copyWith(phase: SlingPhase.aiming)));
        _mistake(MissionStage.placeOrbit, 'too_low', SccDialogue.s2TooLow.toList());
      case SlingOutcome.tooFar:
        _set(_state.copyWith(orbit: _state.orbit.copyWith(phase: SlingPhase.aiming)));
        _mistake(MissionStage.placeOrbit, 'too_far', SccDialogue.s2TooFar.toList());
      case SlingOutcome.none:
        _set(_state.copyWith(orbit: _state.orbit.copyWith(phase: SlingPhase.aiming)));
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Stage 3 · Keep It Powered
  // ───────────────────────────────────────────────────────────────────────────

  Timer? _powerTick;
  double _strongHeld = 0;
  double _shadowElapsed = 0;
  bool _saidPerfect = false;

  /// PRD §14.5: alignmentScore = 1 − |panelAngle − sunAngle| / maxAllowedAngle.
  /// Uses the SHORTEST angular difference so a full-circle dial works — 350°
  /// is 48° from the Sun's 38°, not 312°.
  double alignmentScore(double panelAngleDeg) {
    final diff = _angleDelta(panelAngleDeg, PowerTuning.sunAngleDeg).abs();
    return (1 - diff / PowerTuning.maxAllowedAngleDeg).clamp(0.0, 1.0);
  }

  void setPanelAngle(double deg) {
    if (_state.stage != MissionStage.powerManagement) return;
    final p = _state.power;
    if (p.phase != PowerPhase.aligning && p.phase != PowerPhase.shadowWarning) return;
    _set(_state.copyWith(power: p.copyWith(panelAngleDeg: deg)));
    _ensurePowerTick();
  }

  void _ensurePowerTick() {
    _powerTick ??= Timer.periodic(const Duration(milliseconds: 100), (_) => _powerStep(0.1));
  }

  void _stopPowerTick() {
    _powerTick?.cancel();
    _powerTick = null;
  }

  void _powerStep(double dt) {
    if (_state.stage != MissionStage.powerManagement) {
      _stopPowerTick();
      return;
    }
    final p = _state.power;
    switch (p.phase) {
      case PowerPhase.aligning:
        final score = alignmentScore(p.panelAngleDeg);
        // charge rate scales with alignment; drains very slowly when weak.
        final rate = score > PowerTuning.strongAlignment
            ? 0.30
            : score > PowerTuning.partialAlignment
                ? 0.12
                : -0.01;
        final power = (p.power + rate * dt).clamp(0.05, 1.0);
        _set(_state.copyWith(power: p.copyWith(power: power)));
        // milestone line (once)
        if (!_saidPerfect && score > PowerTuning.strongAlignment) {
          _saidPerfect = true;
          sayOne(SccDialogue.s3Perfect);
        }
        if (score > PowerTuning.strongAlignment && power > 0.8) {
          _strongHeld += dt;
          if (_strongHeld >= PowerTuning.holdStrongSeconds) {
            _beginShadowWarning();
          }
        } else {
          _strongHeld = 0;
        }
      case PowerPhase.shadow:
        _shadowElapsed += dt;
        if (p.leverPulled) {
          // Battery holds the line — stabilize after a short beat.
          _stopPowerTick();
          _set(_state.copyWith(power: p.copyWith(phase: PowerPhase.stabilized)));
          _later(const Duration(milliseconds: 900), () {
            if (_state.stage == MissionStage.powerManagement) {
              _set(_state.copyWith(
                  power: _state.power.copyWith(phase: PowerPhase.done)));
              _completeStage(MissionStage.powerManagement, SccDialogue.s3Success.toList());
            }
          });
        } else {
          // Draining — forgiving: clamp just above critical, keep prompting.
          final power =
              (p.power - 0.13 * dt).clamp(PowerTuning.criticalPower + 0.02, 1.0);
          _set(_state.copyWith(power: p.copyWith(power: power)));
          if (_shadowElapsed > PowerTuning.leverWindowSeconds && !_queueBusy) {
            sayOne(SccDialogue.s3BatteryLate);
            _mistakeQuiet(MissionStage.powerManagement, 'battery_late');
            _shadowElapsed = 0; // re-prompt period
          }
        }
      case PowerPhase.shadowWarning:
      case PowerPhase.countdown:
      case PowerPhase.stabilized:
      case PowerPhase.done:
        break;
    }
  }

  /// Mistake bookkeeping without hijacking the current dialogue (used where
  /// the prompt line is already being said).
  void _mistakeQuiet(MissionStage stage, String type) {
    _stageAttempts[stage] = (_stageAttempts[stage] ?? 0) + 1;
    _totalAttempts++;
    SccAnalytics.stageMistake(_stageId(stage), type);
    onCue?.call(SccCue.wrong);
  }

  void _beginShadowWarning() {
    final p = _state.power;
    _set(_state.copyWith(power: p.copyWith(phase: PowerPhase.shadowWarning)));
    say(SccDialogue.s3ShadowWarning.toList());
    // countdown starts only after the warning lines have been HEARD —
    // a fixed delay would start it mid-clip (timing-audit rule)
    _onIdleOnce = () {
      if (_state.stage != MissionStage.powerManagement) return;
      _set(_state.copyWith(
          power: _state.power.copyWith(phase: PowerPhase.countdown, countdown: 3)));
      // (countdown is the visual 3-2-1 chip; the script has no spoken line)
      _countdownStep(3);
    };
  }

  void _countdownStep(int n) {
    _later(const Duration(seconds: 1), () {
      if (_state.stage != MissionStage.powerManagement ||
          _state.power.phase != PowerPhase.countdown) {
        return;
      }
      if (n > 1) {
        _set(_state.copyWith(power: _state.power.copyWith(countdown: n - 1)));
        _countdownStep(n - 1);
      } else {
        _shadowElapsed = 0;
        _set(_state.copyWith(
            power: _state.power.copyWith(phase: PowerPhase.shadow, countdown: 0)));
        sayOne(SccDialogue.s3BatteryPrompt);
        _ensurePowerTick();
      }
    });
  }

  void pullBatteryLever() {
    if (_state.stage != MissionStage.powerManagement) return;
    final p = _state.power;
    if (p.leverPulled) return;
    switch (p.phase) {
      case PowerPhase.shadow:
        onCue?.call(SccCue.correct);
        _set(_state.copyWith(power: p.copyWith(leverPulled: true)));
      case PowerPhase.aligning:
      case PowerPhase.shadowWarning:
      case PowerPhase.countdown:
        // Early pull — forgiven: slight drain now, still counts when shadow hits.
        onCue?.call(SccCue.tap);
        _set(_state.copyWith(
          power: p.copyWith(
            leverPulled: true,
            leverEarly: true,
            power: (p.power - 0.08).clamp(0.05, 1.0),
          ),
        ));
        say(SccDialogue.s3BatteryEarly.toList());
        _mistakeQuiet(MissionStage.powerManagement, 'battery_early');
      case PowerPhase.stabilized:
      case PowerPhase.done:
        break;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Stage 4 · Capture the cyclone image
  // ───────────────────────────────────────────────────────────────────────────

  DateTime _lastCamHint = DateTime.fromMillisecondsSinceEpoch(0);

  /// Scene reports the live aim each gesture step; controller derives the
  /// lock state and speaks PRD hints on TRANSITIONS (rate-limited).
  void cameraReport({required double centerDistFrac, required double zoom}) {
    if (_state.stage != MissionStage.captureImage) return;
    final c = _state.camera;
    if (c.phase == CameraPhase.captured) return;

    final centered = centerDistFrac <= CameraTuning.centerTolerance;
    final CameraAimState aim;
    if (zoom < CameraTuning.zoomIdealMin) {
      aim = centered ? CameraAimState.tooZoomedOut : CameraAimState.notCentered;
    } else if (zoom > CameraTuning.zoomIdealMax) {
      aim = centered ? CameraAimState.tooZoomedIn : CameraAimState.notCentered;
    } else {
      aim = centered ? CameraAimState.locked : CameraAimState.notCentered;
    }
    if (aim == c.aim) return;

    final locked = aim == CameraAimState.locked;
    _set(_state.copyWith(
      camera: c.copyWith(
        aim: aim,
        phase: locked ? CameraPhase.locked : CameraPhase.exploring,
      ),
    ));
    if (locked) {
      onCue?.call(SccCue.lock);
      say(SccDialogue.s4Locked.toList());
      return;
    }
    // Hint on losing/never-having lock — rate-limited so panning doesn't spam.
    final now = DateTime.now();
    if (now.difference(_lastCamHint).inSeconds < 4) return;
    _lastCamHint = now;
    switch (aim) {
      case CameraAimState.notCentered:
        say(SccDialogue.s4NotCentered.toList());
      case CameraAimState.tooZoomedIn:
        _mistake(MissionStage.captureImage, 'too_zoomed_in', SccDialogue.s4TooZoomedIn.toList());
      case CameraAimState.tooZoomedOut:
        _mistake(MissionStage.captureImage, 'too_zoomed_out', SccDialogue.s4TooZoomedOut.toList());
      case CameraAimState.locked:
        break;
    }
  }

  void captureImage() {
    if (_state.stage != MissionStage.captureImage) return;
    final c = _state.camera;
    if (c.phase != CameraPhase.locked) return;
    onCue?.call(SccCue.correct);
    _set(_state.copyWith(
      camera: c.copyWith(phase: CameraPhase.captured, flashToken: c.flashToken + 1),
    ));
    _completeStage(MissionStage.captureImage, SccDialogue.s4Success.toList());
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Stage 5 · Send data to Earth
  // ───────────────────────────────────────────────────────────────────────────

  double _wrongAimTime = 0, _noisyTime = 0;

  bool get _aimGood =>
      (_state.signal.aimDeg).abs() <= SignalTuning.aimToleranceDeg;
  bool get _freqGood =>
      (_state.signal.freq - SignalTuning.freqTarget).abs() <= SignalTuning.freqTolerance;

  void setAntennaAim(double deg) {
    if (_state.stage != MissionStage.sendData) return;
    final s = _state.signal;
    if (s.phase != SignalPhase.tuning) return;
    _set(_state.copyWith(signal: s.copyWith(aimDeg: deg.clamp(-50.0, 50.0))));
  }

  void setTunerFreq(double f) {
    if (_state.stage != MissionStage.sendData) return;
    final s = _state.signal;
    if (s.phase != SignalPhase.tuning) return;
    _set(_state.copyWith(signal: s.copyWith(freq: f.clamp(0.0, 1.0))));
  }

  /// Called every frame by the Flame stage while Stage 5 is active.
  void signalTick(double dt) {
    if (_state.stage != MissionStage.sendData) return;
    final s = _state.signal;
    if (s.phase != SignalPhase.tuning) return;
    final aimGood = _aimGood, freqGood = _freqGood;
    if (aimGood && freqGood) {
      _wrongAimTime = 0;
      _noisyTime = 0;
      final hold = s.holdProgress + dt / SignalTuning.holdSeconds;
      if (hold >= 1) {
        _set(_state.copyWith(
            signal: s.copyWith(phase: SignalPhase.locked, holdProgress: 1)));
        onCue?.call(SccCue.lock);
        say(SccDialogue.s5Locked.toList());
        // Packets fly once the lock lines have been HEARD (voice-paced —
        // a fixed 2.6s would launch them mid-clip).
        _onIdleOnce = () {
          if (_state.stage == MissionStage.sendData &&
              _state.signal.phase == SignalPhase.locked) {
            _set(_state.copyWith(
              signal: _state.signal.copyWith(
                phase: SignalPhase.sending,
                packetToken: _state.signal.packetToken + 1,
              ),
            ));
            onCue?.call(SccCue.upload);
          }
        };
      } else {
        _set(_state.copyWith(signal: s.copyWith(holdProgress: hold)));
      }
      return;
    }
    // Decay the hold; speak the right PRD hint after sustained wrongness.
    if (s.holdProgress > 0) {
      final weakClose = s.holdProgress > 0.35;
      _set(_state.copyWith(
          signal: s.copyWith(holdProgress: (s.holdProgress - dt * 0.8).clamp(0.0, 1.0))));
      if (weakClose && !_queueBusy) say(SccDialogue.s5WeakClose.toList());
      return;
    }
    if (!aimGood) {
      _wrongAimTime += dt;
      if (_wrongAimTime > 4 && !_queueBusy) {
        _wrongAimTime = 0;
        _mistake(MissionStage.sendData, 'wrong_aim', SccDialogue.s5WrongAim.toList());
      }
    } else {
      _wrongAimTime = 0;
      _noisyTime += dt;
      if (_noisyTime > 4 && !_queueBusy) {
        _noisyTime = 0;
        _mistake(MissionStage.sendData, 'noisy_frequency', SccDialogue.s5Noisy.toList());
      }
    }
  }

  /// Packet-stream animation finished (Flame).
  void packetsDelivered() {
    if (_state.stage != MissionStage.sendData) return;
    if (_state.signal.phase != SignalPhase.sending) return;
    _set(_state.copyWith(signal: _state.signal.copyWith(phase: SignalPhase.done)));
    _completeStage(MissionStage.sendData, SccDialogue.s5Success.toList());
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Stage 6 · Read the satellite image
  // ───────────────────────────────────────────────────────────────────────────

  void setAnalysisLayer(int layer) {
    if (_state.stage != MissionStage.readImage) return;
    final a = _state.analysis;
    if (a.phase != AnalysisPhase.exploring || a.layer == layer) return;
    onCue?.call(SccCue.tap);
    final firstVisit = !a.visitedLayers.contains(layer);
    final visited = {...a.visitedLayers, layer};
    _set(_state.copyWith(
      analysis: a.copyWith(layer: layer, visitedLayers: visited),
    ));
    if (firstVisit) {
      final lines = switch (layer) {
        1 => SccDialogue.s6HeatLayer.toList(),
        2 => SccDialogue.s6WindLayer.toList(),
        _ => <Line>[],
      };
      // the layer tour is complete → unlock + prompt the circle step
      if (visited.length >= 3) lines.add(SccDialogue.s6CircleNow);
      if (lines.isNotEmpty) say(lines);
    }
  }

  /// Scene validated the drawn loop geometry and reports the overlap of the
  /// cyclone target zone covered by the circle + how far its centre was.
  void circleDrawn({required double overlap, required double centerDistFactor}) {
    if (_state.stage != MissionStage.readImage) return;
    final a = _state.analysis;
    if (a.phase != AnalysisPhase.exploring) return;
    // circling unlocks only after the full layer tour
    if (a.visitedLayers.length < 3) {
      sayOne(SccDialogue.s6ViewAllNudge);
      return;
    }
    if (overlap >= AnalysisTuning.minOverlap) {
      _set(_state.copyWith(analysis: a.copyWith(phase: AnalysisPhase.found)));
      onCue?.call(SccCue.correct);
      _completeStage(MissionStage.readImage, SccDialogue.s6Success.toList());
    } else if (centerDistFactor <= AnalysisTuning.closeFactor) {
      _set(_state.copyWith(analysis: a.copyWith(wrongToken: a.wrongToken + 1)));
      _mistake(MissionStage.readImage, 'close_miss', [SccDialogue.s6Close]);
    } else {
      _set(_state.copyWith(analysis: a.copyWith(wrongToken: a.wrongToken + 1)));
      _mistake(MissionStage.readImage, 'wrong_patch', SccDialogue.s6WrongPatch.toList());
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Stage 7 · Fix the surprise issue
  // ───────────────────────────────────────────────────────────────────────────

  void traceFinished({required bool reachedRadiator}) {
    if (_state.stage != MissionStage.repairIssue) return;
    final r = _state.repair;
    if (r.step != RepairStep.trace) return;
    if (reachedRadiator) {
      onCue?.call(SccCue.correct);
      _set(_state.copyWith(
        repair: r.copyWith(step: RepairStep.radiator, temp: RepairTuning.afterTraceTemp),
      ));
      say([SccDialogue.s7AfterTrace, ...SccDialogue.s7RadiatorStep]);
    } else {
      _set(_state.copyWith(repair: r.copyWith(sparkToken: r.sparkToken + 1)));
      _mistake(MissionStage.repairIssue, 'wrong_heat_path', SccDialogue.s7WrongTrace.toList());
    }
  }

  void setRadiatorAngle(double deg) {
    if (_state.stage != MissionStage.repairIssue) return;
    final r = _state.repair;
    if (r.step != RepairStep.radiator) return;
    _set(_state.copyWith(repair: r.copyWith(radiatorDeg: deg)));
  }

  /// Child let go of the rotate ring — check the orientation window.
  void radiatorReleased() {
    if (_state.stage != MissionStage.repairIssue) return;
    final r = _state.repair;
    if (r.step != RepairStep.radiator) return;
    final delta = _angleDelta(r.radiatorDeg, RepairTuning.radiatorTargetDeg).abs();
    if (delta <= RepairTuning.radiatorToleranceDeg) {
      onCue?.call(SccCue.correct);
      _set(_state.copyWith(
        repair: r.copyWith(step: RepairStep.switchOff, temp: RepairTuning.afterRadiatorTemp),
      ));
      say([SccDialogue.s7AfterRadiator, ...SccDialogue.s7SwitchStep]);
    } else {
      _mistake(MissionStage.repairIssue, 'radiator_facing_sun', SccDialogue.s7WrongRadiator.toList());
    }
  }

  double _angleDelta(double a, double b) {
    var d = (a - b) % 360;
    if (d > 180) d -= 360;
    if (d < -180) d += 360;
    return d;
  }

  void boostSwitchedOff() {
    if (_state.stage != MissionStage.repairIssue) return;
    final r = _state.repair;
    if (r.step != RepairStep.switchOff || !r.boostOn) return;
    onCue?.call(SccCue.correct);
    _set(_state.copyWith(
      repair: r.copyWith(step: RepairStep.done, boostOn: false, temp: RepairTuning.safeTemp),
    ));
    _completeStage(MissionStage.repairIssue, SccDialogue.s7Success.toList());
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Stage 8 · Upload command sequence
  // ───────────────────────────────────────────────────────────────────────────

  /// Child drew a line from the path's current tail to [target].
  /// Returns true when the connection is accepted.
  bool tryConnect(CommandNode target) {
    if (_state.stage != MissionStage.uploadCommands) return false;
    final c = _state.command;
    if (c.phase != CommandPhase.connecting) return false;
    // [connected] counts accepted edges, so the path tail is node[connected]
    // and the next expected node is node[connected + 1] (phase==connecting
    // guarantees connected < length - 1).
    final next = kCommandSequence[c.connected + 1];
    if (target == next) {
      final connected = c.connected + 1;
      onCue?.call(SccCue.correct);
      final complete = connected == kCommandSequence.length - 1;
      _set(_state.copyWith(
        command: c.copyWith(
          connected: connected,
          phase: complete ? CommandPhase.readyToUpload : CommandPhase.connecting,
        ),
      ));
      if (complete) say(SccDialogue.s8PathComplete.toList());
      return true;
    }
    _set(_state.copyWith(
      command: c.copyWith(wrongToken: c.wrongToken + 1, wrongTarget: target),
    ));
    _mistake(MissionStage.uploadCommands, 'wrong_connection_${target.name}',
        commandMistakeLines(next, target));
    return false;
  }

  /// Upload hold progress from the scene's AnimationController (0..1).
  /// The per-fifth "Uploading … command" lines key off progress.
  int _lastUploadLine = -1;

  void uploadProgress(double p) {
    if (_state.stage != MissionStage.uploadCommands) return;
    final c = _state.command;
    if (c.phase != CommandPhase.readyToUpload && c.phase != CommandPhase.uploading) return;
    _set(_state.copyWith(
      command: c.copyWith(phase: CommandPhase.uploading, uploadProgress: p.clamp(0.0, 1.0)),
    ));
    final lineIdx = (p * SccDialogue.s8Uploading.length)
        .floor()
        .clamp(0, SccDialogue.s8Uploading.length - 1);
    if (lineIdx != _lastUploadLine) {
      _lastUploadLine = lineIdx;
      sayOne(SccDialogue.s8Uploading[lineIdx]);
    }
  }

  /// Hold released before completion — rewind gracefully (no failure).
  void uploadCancelled() {
    if (_state.stage != MissionStage.uploadCommands) return;
    final c = _state.command;
    if (c.phase != CommandPhase.uploading) return;
    _lastUploadLine = -1;
    _set(_state.copyWith(
      command: c.copyWith(phase: CommandPhase.readyToUpload, uploadProgress: 0),
    ));
    say([SccDialogue.s8PathComplete[1]]);
  }

  void uploadComplete() {
    if (_state.stage != MissionStage.uploadCommands) return;
    final c = _state.command;
    if (c.phase != CommandPhase.uploading) return;
    _set(_state.copyWith(
      command: c.copyWith(phase: CommandPhase.done, uploadProgress: 1),
    ));
    _completeStage(MissionStage.uploadCommands, SccDialogue.s8Success.toList());
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Finale + badges
  // ───────────────────────────────────────────────────────────────────────────

  /// Continue from the mission-complete card → badge reveal.
  void finaleContinue() {
    if (_state.stage != MissionStage.finalSuccess) return;
    if (!_state.finale.continueEnabled) return;
    onCue?.call(SccCue.tap);
    _enterStage(MissionStage.badgeReveal);
  }

  void _runBadgeScript() {
    _set(_state.copyWith(badges: const BadgeSub()));
    for (var i = 0; i < kBadgeOrder.length; i++) {
      _later(Duration(milliseconds: 700 + i * 850), () {
        if (_state.stage != MissionStage.badgeReveal) return;
        final (id, _, _) = kBadgeOrder[i];
        SccAnalytics.badgeUnlocked(id);
        onCue?.call(SccCue.correct);
        _set(_state.copyWith(badges: _state.badges.copyWith(revealed: i + 1)));
      });
    }
    _later(Duration(milliseconds: 700 + kBadgeOrder.length * 850 + 600), () {
      if (_state.stage != MissionStage.badgeReveal) return;
      _set(_state.copyWith(badges: _state.badges.copyWith(continueEnabled: true)));
      SccAnalytics.finalMissionCompleted(
        DateTime.now().difference(_missionStartedAt ?? DateTime.now()).inMilliseconds,
        _totalAttempts,
      );
    });
  }

  void toggleSound() => _set(_state.copyWith(soundOn: !_state.soundOn));
}
