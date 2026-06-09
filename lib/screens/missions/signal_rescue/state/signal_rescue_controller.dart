// The brain of Signal Rescue. Owns the single immutable [SignalRescueState], the
// scene geometry (computed from SRTune factor-anchors × the stage size the game
// reports once), the orbit clock, the signal logic (verbatim from PRD §10), the
// phase machine, battery, timers and helper copy.
//
// Division of labour (keeps logic testable + away from rendering):
//  • The Flame game reports the stage size once, ticks the controller each frame
//    (`tick`), renders purely from controller geometry/state, and feeds back ONLY
//    the antenna drag (`setAntennaAngle`).
//  • The controller decides everything else and notifies once per change.

import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import '../config/asset_paths.dart';
import '../config/signal_tuning.dart';
import 'analytics.dart';
import 'signal_rescue_state.dart';

double _deg(double rad) => rad * 180 / math.pi;

/// Shortest unsigned angular distance between two degree angles, 0..180.
double shortestAngleDistance(double a, double b) {
  var d = (a - b) % 360;
  d = (d + 540) % 360 - 180;
  return d.abs();
}

class SignalRescueController extends ChangeNotifier {
  SignalRescueController({this.onSound, SignalRescueAnalytics? analytics})
      : _analytics = analytics ?? const SignalRescueAnalytics();

  final void Function(String assetFile)? onSound;
  final SignalRescueAnalytics _analytics;

  SignalRescueState _state = const SignalRescueState();
  SignalRescueState get state => _state;

  // stage geometry (pixels) reported by the game
  double _w = 390, _h = 700;

  // clocks / latches
  double _orbitPhase = 0; // 0..1 looping, advanced once searching
  double _explainT = 0;
  double _idleT = 0;
  // helper line sequencer: which state's sequence is playing + time within it
  String _seqKey = '';
  double _seqT = 0;
  bool _antennaInit = false;
  bool _announcedRange = false;
  bool _lockedAnnounced = false;
  bool _disposed = false;

  // ── lifecycle ───────────────────────────────────────────────────────────────
  void setStageSize(double w, double h) {
    _w = w;
    _h = h;
  }

  void onFirstBuild() {
    _analytics.missionStarted();
    _set(_state.copyWith(
      phase: MissionPhase.intro,
      helperMessage: SRTune.introLine,
      mascot: MascotMood.explaining,
      batteryLevel: SRTune.startBattery,
      stormEnabled: SRTune.stormEnabledDefault,
    ));
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _set(SignalRescueState s) {
    if (_disposed) return;
    // VOICE CHOKE POINT: every mutation flows through here, so stamping the clip
    // when the helper line CHANGES covers all call sites at once. Repeated
    // identical text deliberately does NOT re-voice (right for ambient nudges).
    if (s.helperMessage != _state.helperMessage) {
      final clip = SRTune.orbitClipFor[s.helperMessage];
      if (clip != null) {
        s = s.copyWith(voiceClip: clip, voiceToken: _state.voiceToken + 1);
      }
    }
    _state = s;
    notifyListeners();
  }

  // ── voice pacing (screen reports clip start/end) ────────────────────────────
  // While a clip plays the briefing + line-sequencer clocks FREEZE (voice-paced);
  // on completion they release to a ~0.35s breath before the next line. Muted
  // users never report a start, so pacing falls back to the fixed clocks.
  bool _voiceActive = false;

  void voiceStarted() {
    if (_disposed) return;
    _voiceActive = true;
    _set(_state.copyWith(voicePlaying: true));
  }

  void voiceFinished() {
    if (_disposed || (!_voiceActive && !_state.voicePlaying)) return;
    _voiceActive = false;
    if (_state.phase == MissionPhase.explainParts) {
      _explainT = (_state.explainStep + 1) * SRTune.explainStepDur - 0.35;
    } else {
      final idx = (_seqT / SRTune.seqLineDur).floor();
      _seqT = (idx + 1) * SRTune.seqLineDur - 0.35;
    }
    _set(_state.copyWith(voicePlaying: false));
  }

  // ── geometry (pixels) — single source of truth, shared with the game ─────────
  Offset _px(Offset factor) => Offset(factor.dx * _w, factor.dy * _h);

  /// Satellite centre, drifting along a shallow arc once range-searching begins.
  Offset get satelliteCenterPx {
    final c = SRTune.orbitArcCenter;
    final a = _orbitPhase * 2 * math.pi;
    final fx = c.dx + SRTune.orbitArcHalfWidth * math.sin(a);
    final fy = c.dy - SRTune.orbitArcRise * (1 - math.cos(a)) * 0.5;
    return Offset(fx * _w, fy * _h);
  }

  // The game pushes the dish's real world pivot each frame (so the aim target
  // always matches the drawn dish, even when the body is resized). Falls back to
  // a factor estimate before the first push.
  Offset? _pivotOverride;
  void setAntennaPivot(double x, double y) => _pivotOverride = Offset(x, y);

  Offset get antennaPivotPx {
    if (_pivotOverride != null) return _pivotOverride!;
    final s = satelliteCenterPx;
    return Offset(
      s.dx + SRTune.antennaPivotOffset.dx * _w,
      s.dy + SRTune.antennaPivotOffset.dy * _h,
    );
  }

  /// The station's base on the pad (where the component is anchored).
  Offset get stationCenterPx => _px(SRTune.groundStationCenter);

  /// The station's dish — the beam endpoint + the angle target (lifted above the
  /// base so the antenna points at the dish, not the ground).
  Offset get stationAimPx {
    final b = stationCenterPx;
    return Offset(b.dx, b.dy - SRTune.stationAimRise * _h);
  }

  /// Direction (screen degrees, 0 = +x / right, CW positive) from the antenna
  /// pivot to the ground-station dish — the angle the dish must match.
  double get _computedTargetAngle {
    final p = antennaPivotPx;
    final t = stationAimPx;
    return _deg(math.atan2(t.dy - p.dy, t.dx - p.dx));
  }

  bool get _inWindow =>
      _orbitPhase >= SRTune.windowStart && _orbitPhase <= SRTune.windowEnd;

  // ── intro / explain auto-sequence ────────────────────────────────────────────
  /// Tap "Start" or auto-dwell → run the parts tour.
  void startMission() {
    if (_state.phase != MissionPhase.intro) return;
    _explainT = 0;
    _set(_state.copyWith(
      phase: MissionPhase.explainParts,
      explainStep: 0,
      helperMessage: SRTune.explainLines[0],
      mascot: MascotMood.explaining,
    ));
  }

  void _beginAlign() {
    _analytics.partsExplained();
    _idleT = 0;
    _set(_state.copyWith(
      phase: MissionPhase.alignAntenna,
      helperMessage: SRTune.alignLine,
      mascot: MascotMood.explaining,
    ));
  }

  // ── per-frame tick (driven by the game) ──────────────────────────────────────
  void tick(double dt) {
    final s = _state;

    // Initialise the antenna pointing the WRONG way (the problem reveal) the
    // moment we know the geometry.
    if (!_antennaInit && _w > 1) {
      _antennaInit = true;
      _state = s.copyWith(
        antennaAngle: _computedTargetAngle + 150,
        targetAngle: _computedTargetAngle,
      );
    }

    switch (s.phase) {
      case MissionPhase.intro:
        // Just the urgency hook ("let's fix it"); the cyclone fact comes AFTER the
        // child taps Start (as the first briefing line). Never auto-starts.
        return;
      case MissionPhase.explainParts:
        if (!_voiceActive) _explainT += dt; // voice-paced: hold while Orbit talks
        final step = (_explainT / SRTune.explainStepDur).floor();
        if (step >= SRTune.explainLines.length) {
          _beginAlign();
        } else if (step != s.explainStep) {
          _set(s.copyWith(
            explainStep: step,
            helperMessage: SRTune.explainLines[step],
            mascot: MascotMood.explaining,
          ));
        }
        return;
      case MissionPhase.success:
      case MissionPhase.failed:
        return;
      case MissionPhase.transmitting:
        // progress is driven by the game via updateTransmission()
        _advanceStorm(dt);
        return;
      default:
        break;
    }

    // Searching cluster: align → waitForRange → checkPower → dataLocked.
    // Advance the orbit clock once we're past pure alignment — but HOLD it while
    // locked: the lock window (~2.7s) is shorter than Orbit's "data locked / tap
    // send" clips, so without the hold the satellite drifts out of range while
    // the child is still being told to send (guided-hold, kid-fair).
    if (s.phase != MissionPhase.alignAntenna && s.phase != MissionPhase.dataLocked) {
      _orbitPhase = (_orbitPhase + dt / SRTune.orbitPeriod) % 1.0;
    }

    // Gentle battery drain while hunting for signal (systems thinking; stays > min).
    var battery = s.batteryLevel;
    if (s.phase != MissionPhase.alignAntenna) {
      battery = (battery - SRTune.searchDrainPerSec * dt)
          .clamp(SRTune.minBatteryToTransmit + 8, 100.0);
    }

    _idleT += dt;
    if (!_voiceActive) _seqT += dt; // voice-paced: hold while Orbit talks
    _advanceStorm(dt);
    _recompute(battery: battery, idleHintCheck: true);
  }

  void _advanceStorm(double dt) {
    if (!_state.stormEnabled) return;
    final p = (_state.stormTimerProgress + dt / SRTune.stormDuration).clamp(0.0, 1.0);
    if (p != _state.stormTimerProgress) {
      _state = _state.copyWith(stormTimerProgress: p);
    }
  }

  // ── antenna input (from the in-stage drag) ───────────────────────────────────
  /// Raw screen angle the child dragged the dish to (degrees). Applies gentle
  /// magnetic easing toward the target so young users can settle a lock — assist,
  /// never auto-solve.
  void setAntennaAngle(double rawDeg) {
    if (!_state.controlsLive) return;
    final target = _computedTargetAngle;
    var angle = rawDeg;
    final diff = shortestAngleDistance(rawDeg, target);
    if (diff < SRTune.magnetBand) {
      // signed delta toward target
      var signed = (target - rawDeg) % 360;
      signed = (signed + 540) % 360 - 180;
      angle = rawDeg + signed * SRTune.magnetStrength;
    }
    _idleT = 0;
    _state = _state.copyWith(antennaAngle: angle);
    _recompute();
  }

  // ── the signal logic (PRD §10) ────────────────────────────────────────────────
  void _recompute({double? battery, bool idleHintCheck = false}) {
    final s = _state;
    final target = _computedTargetAngle;
    final diff = shortestAngleDistance(s.antennaAngle, target);
    final inRange = _inWindow && s.phase != MissionPhase.alignAntenna;
    final bat = battery ?? s.batteryLevel;

    // signal state cascade
    SignalState sig;
    if (!inRange) {
      sig = diff < SRTune.outOfRangeWeakDiff ? SignalState.weak : SignalState.noSignal;
    } else if (diff > SRTune.weakMaxDiff) {
      sig = SignalState.noSignal;
    } else if (diff > SRTune.strongMaxDiff) {
      sig = SignalState.weak;
    } else if (diff > SRTune.lockMaxDiff) {
      sig = SignalState.strong;
    } else if (bat >= SRTune.minBatteryToTransmit) {
      sig = SignalState.locked;
    } else {
      sig = SignalState.strong;
    }

    final angleAccuracy = 1.0 - (diff / SRTune.maxAllowedDiff).clamp(0.0, 1.0);
    final rangeFactor = inRange ? 1.0 : 0.25;
    final strength = angleAccuracy * rangeFactor;
    final canTx = sig == SignalState.locked && bat >= SRTune.minBatteryToTransmit;

    // phase derivation within the search cluster
    var phase = s.phase;
    if (phase != MissionPhase.alignAntenna) {
      phase = switch (sig) {
        SignalState.locked => MissionPhase.dataLocked,
        SignalState.strong => MissionPhase.checkPower,
        _ => MissionPhase.waitForRange,
      };
    }

    // one-shot announcements + sfx
    var mascot = s.mascot;
    if (inRange && !_announcedRange) {
      _announcedRange = true;
      _analytics.enteredRange();
      onSound?.call(SRSounds.tap);
    }
    if (sig == SignalState.locked && !_lockedAnnounced) {
      _lockedAnnounced = true;
      _analytics.dataLocked();
      onSound?.call(SRSounds.correct);
    }
    if (sig != SignalState.locked) _lockedAnnounced = false;

    // helper copy + mascot mood — multi-line states auto-advance one line every
    // seqLineDur while the state holds (holding on the last line).
    final (seqKey, lines, mood) = _helperSeqFor(phase, sig, inRange, diff);
    if (seqKey != _seqKey) {
      _seqKey = seqKey;
      _seqT = 0;
    }
    final lineIdx = (_seqT / SRTune.seqLineDur).floor().clamp(0, lines.length - 1);
    final msg = lines[lineIdx];
    mascot = mood;

    // idle hint escalation
    var hint = s.hintLevel;
    if (idleHintCheck && _idleT >= SRTune.idleHintAfter && phase != MissionPhase.dataLocked) {
      _idleT = 0;
      hint = (hint + 1).clamp(0, 5);
      _analytics.hintShown(hint);
    }

    _set(s.copyWith(
      phase: phase,
      signalState: sig,
      targetAngle: target,
      angleDifference: diff,
      isGroundStationInRange: inRange,
      signalStrength: strength,
      batteryLevel: bat,
      canTransmit: canTx,
      batteryWarning: bat < SRTune.minBatteryToTransmit,
      mascot: mascot,
      helperMessage: msg,
      hintLevel: hint,
    ));
  }

  /// (sequence key, lines for this state, mood). The key identifies the state —
  /// when it changes the sequencer restarts from the first line.
  (String, List<String>, MascotMood) _helperSeqFor(
      MissionPhase phase, SignalState sig, bool inRange, double diff) {
    if (phase == MissionPhase.alignAntenna) {
      // three coaching bands by aim error
      if (diff <= SRTune.alignAdvanceDiff) {
        return ('align-close', const [SRTune.weakLine], MascotMood.explaining);
      }
      if (diff <= SRTune.weakMaxDiff) {
        return ('align-coach', const [SRTune.alignCoachLine], MascotMood.explaining);
      }
      return ('align-far', const [SRTune.alignLine], MascotMood.alert);
    }
    if (sig == SignalState.locked) {
      return ('locked', SRTune.lockedLines, MascotMood.happy);
    }
    if (sig == SignalState.strong) {
      return ('strong', SRTune.strongLines, MascotMood.happy);
    }
    if (inRange) {
      // in range but aim slipped — urgent nudge
      return ('in-range', const [SRTune.inRangeLine], MascotMood.alert);
    }
    // out of range: aim held → the "short pass" teaching sequence; aim lost → re-ask
    return diff <= SRTune.strongMaxDiff
        ? ('wait-pass', SRTune.waitLines, MascotMood.explaining)
        : ('re-align', const [SRTune.alignLine], MascotMood.alert);
  }

  /// Called by the game once the child has held a decent aim long enough to
  /// graduate from alignment to the range hunt.
  void onAlignDwellComplete() {
    if (_state.phase != MissionPhase.alignAntenna) return;
    _analytics.antennaAligned(_state.angleDifference);
    _orbitPhase = 0;
    _announcedRange = false;
    _set(_state.copyWith(
      phase: MissionPhase.waitForRange,
      helperMessage: SRTune.waitLines.first,
      mascot: MascotMood.explaining,
    ));
  }

  // ── send / transmission ──────────────────────────────────────────────────────
  /// Returns null on success (transmission started), or a friendly reason string
  /// when blocked. Never punishes.
  String? attemptSend() {
    final s = _state;
    if (s.canTransmit && s.phase == MissionPhase.dataLocked) {
      _analytics.transmissionStarted();
      onSound?.call(SRSounds.tap);
      _set(s.copyWith(
        phase: MissionPhase.transmitting,
        isTransmitting: true,
        canTransmit: false,
        helperMessage: SRTune.transmitLines.first,
        mascot: MascotMood.happy,
      ));
      return null;
    }
    // friendly reason, most-specific first: range → way off → off → battery → almost
    final reason = !s.isGroundStationInRange
        ? SRTune.reasonRange
        : s.angleDifference > SRTune.weakMaxDiff
            ? SRTune.reasonAim
            : s.angleDifference > SRTune.strongMaxDiff
                ? SRTune.reasonWeak
                : s.batteryLevel < SRTune.minBatteryToTransmit
                    ? SRTune.reasonBattery
                    : SRTune.reasonAlmost;
    _analytics.sendAttemptBlocked(reason);
    onSound?.call(SRSounds.wrong);
    _set(s.copyWith(
      helperMessage: reason,
      mascot: MascotMood.alert,
      hintLevel: (s.hintLevel + 1).clamp(0, 5),
    ));
    return reason;
  }

  /// Driven by the game's packet flight (0..1). Reveals the monitor + dips the
  /// battery; completes the mission at 1.0.
  void updateTransmission(double progress) {
    final s = _state;
    if (s.phase != MissionPhase.transmitting) return;
    final p = progress.clamp(0.0, 1.0);
    final battery = (SRTune.startBattery - SRTune.transmitDrain * p)
        .clamp(SRTune.minBatteryToTransmit, 100.0);
    // narration follows the packets: sending → pieces → rebuilding → the eye.
    // Windows (transmitLineFracs) are sized to each clip's length so lines
    // aren't cut mid-word.
    final f = SRTune.transmitLineFracs;
    final line = p < f[0]
        ? SRTune.transmitLines[0]
        : p < f[1]
            ? SRTune.transmitLines[1]
            : p < f[2]
                ? SRTune.transmitLines[2]
                : SRTune.transmitLines[3];
    _set(s.copyWith(
      transmissionProgress: p,
      monitorRevealProgress: (p * 1.08).clamp(0.0, 1.0),
      batteryLevel: battery,
      helperMessage: line,
    ));
    if (p >= 1.0) _succeed();
  }

  void _succeed() {
    _analytics.missionCompleted();
    onSound?.call(SRSounds.complete);
    _set(_state.copyWith(
      phase: MissionPhase.success,
      isTransmitting: false,
      missionCompleted: true,
      signalState: SignalState.locked,
      monitorRevealProgress: 1,
      transmissionProgress: 1,
      helperMessage: SRTune.successLine,
      mascot: MascotMood.celebrate,
    ));
  }

  // ── misc ──────────────────────────────────────────────────────────────────
  void finish() {/* hook for analytics flush on exit */}
}
