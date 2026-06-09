// The brain of the Power Balance Challenge. Owns the single immutable
// [PowerBalanceState], the scene geometry (factor-anchors × the stage size the
// game reports once), the orbit clock (with guided HOLDS), the battery
// simulation (verbatim from PRD §11.1), the guided-to-free phase machine, the
// camera/antenna capture+send logic, and all Mission Control copy.
//
// Division of labour (keeps logic testable + away from rendering):
//  • The Flame game reports the stage size once, ticks the controller each frame
//    (`tick`), and renders PURELY from controller geometry/state getters. It owns
//    no gestures — every control is a Flutter dock button calling an intent here.
//  • The controller decides everything else and notifies once per change.

import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import '../config/asset_paths.dart';
import '../config/power_balance_tuning.dart';
import '../models/power_balance_models.dart';
import 'analytics.dart';
import 'power_balance_state.dart';

double _smoothstep(double a, double b, double x) {
  if (a == b) return x < a ? 0 : 1;
  final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

class PowerBalanceController extends ChangeNotifier {
  PowerBalanceController({this.onSound, this.onHaptic, PowerBalanceAnalytics? analytics})
      : _analytics = analytics ?? const PowerBalanceAnalytics();

  final void Function(String assetFile)? onSound;
  final void Function()? onHaptic;
  final PowerBalanceAnalytics _analytics;

  PowerBalanceState _state = const PowerBalanceState();
  PowerBalanceState get state => _state;

  // stage geometry (pixels), reported by the game once
  double _w = 390, _h = 780;

  // clocks / latches
  double _clock = 0; // total play time (spam windows, shadow dwell)
  double _phaseT = 0; // time in current phase (for timed beats)
  double _solarT = 0; // solar-align hold countdown
  double _captureT = 0; // capture beat
  double _sendT = 0; // send beat
  double _idleT = 0;
  double _msgHold = 0; // latches event copy so ambient nudges don't stomp it
  double _thrustBoostT = 0; // remaining time of the thruster speed burst
  double _shadowEnterClock = -1; // when the satellite entered the shadow
  double _lastThrustClock = -99; // for spam detection
  int _lastCaptureLap = -1;
  int _thrusterCount = 0;
  bool _shadowAnnounced = false;
  bool _lowAlertShown = false;
  bool _freeIntroShown = false; // "think like an engineer" said once
  bool _goodSaveShown = false; // per-shadow-pass praise latch
  bool _sentEduShown = false; // "only useful if it sends back" said once
  bool _disposed = false;
  OrbitZone? _prevZone;

  /// Queued Orbit follow-up lines — drained one per messageHold expiry, so a
  /// multi-line beat ("Nice! …" → "That sunlight is becoming power…") plays out
  /// without stomping. Cleared on phase change or when superseded.
  final List<(String, MascotMood)> _followUps = [];

  /// Pop a one-shot achievement/feedback badge (PRD per-scene assets). Mutates
  /// without notifying — the caller commits.
  void _popBadge(FeedbackBadge b) => _mut(_state.copyWith(
        feedbackToken: _state.feedbackToken + 1,
        feedbackBadge: b,
      ));

  // ── lifecycle ────────────────────────────────────────────────────────────
  void setStageSize(double w, double h) {
    _w = w;
    _h = h;
  }

  void onFirstBuild() {
    _analytics.missionStarted();
    _set(_state.copyWith(
      phase: MissionPhase.intro,
      batteryPercent: PBTune.startBattery,
      helperMessage: PBTune.introSubtitle,
      mascot: MascotMood.neutral,
      orbitProgress: PBTune.holdSunlight,
      currentZone: OrbitZone.sunlight,
    ));
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // mutate without notifying (used inside tick; committed once at the end).
  // ONE voice choke point: whenever the helper line changes to a mapped Orbit
  // line, stamp its clip + bump voiceToken so the screen speaks it — no per-call
  // wiring at the ~30 message sites.
  void _mut(PowerBalanceState s) {
    if (s.helperMessage != _state.helperMessage) {
      final clip = PBTune.orbitClipFor[s.helperMessage];
      if (clip != null) {
        s = s.copyWith(voiceClip: clip, voiceToken: s.voiceToken + 1);
      }
    }
    _state = s;
  }

  void _commit() {
    if (!_disposed) notifyListeners();
  }

  // mutate + notify (used by one-shot intents)
  void _set(PowerBalanceState s) {
    _mut(s);
    _commit();
  }

  // ── voice pacing (screen ↔ controller) ─────────────────────────────────────
  // While Orbit is speaking, the current line HOLDS (queue + ambient nudges
  // wait); when the clip ends, a short breath then the next line. Muted users
  // never report voiceStarted, so pacing falls back to the messageHold timer.
  bool _voiceActive = false;
  double _voiceStartClock = 0;

  void voiceStarted() {
    _voiceActive = true;
    _voiceStartClock = _clock;
  }

  void voiceFinished() {
    if (!_voiceActive) return;
    _voiceActive = false;
    if (_msgHold > 0.35) _msgHold = 0.35; // breath, then the next line may play
  }

  // ── geometry (pixels) — single source of truth, shared with the game ──────
  Offset _px(Offset f) => Offset(f.dx * _w, f.dy * _h);

  /// A point on the full-traverse orbit ellipse at progress [p] (0..1).
  /// p≈0 top (sunlight) → 0.25 right (target) → 0.5 bottom (ground/shadow) →
  /// 0.75 left → top. Always on-screen; loops cleanly (closed ellipse).
  Offset orbitPointPx(double p) {
    final c = PBTune.orbitCenter;
    final th = p * 2 * math.pi;
    return Offset(
      (c.dx + PBTune.orbitRadiusX * math.sin(th)) * _w,
      (c.dy - PBTune.orbitRadiusY * math.cos(th)) * _h,
    );
  }

  /// Satellite centre — travels the full orbit ellipse (PRD §18, user choice).
  Offset get satelliteCenterPx => orbitPointPx(_state.orbitProgress);

  double get satelliteWidthPx => PBTune.satelliteWidthFactor * _w;
  Offset get sunCenterPx => _px(PBTune.sunCenter);
  double get sunWidthPx => PBTune.sunWidthFactor * _w;
  Offset get earthBottomCenterPx => _px(PBTune.earthBottomCenter);
  double get earthWidthPx => PBTune.earthWidthFactor * _w;
  Offset get cycloneCenterPx => _px(PBTune.cycloneCenter);
  double get cycloneWidthPx => PBTune.cycloneWidthFactor * _w;
  Offset get groundStationCenterPx => _px(PBTune.groundStationCenter);
  double get groundStationWidthPx => PBTune.groundStationWidthFactor * _w;
  // orbit ellipse params (pixels) for the programmatic path ring
  Offset get orbitCenterPx => _px(PBTune.orbitCenter);
  double get orbitRadiusXPx => PBTune.orbitRadiusX * _w;
  double get orbitRadiusYPx => PBTune.orbitRadiusY * _h;

  // presence/fade getters (0..1) so the game is a pure renderer ──────────────
  double get _p => _state.orbitProgress;

  /// 0 in daylight, eases to 1 deep in Earth's shadow.
  double get shadowFactor {
    final up = _smoothstep(PBTune.groundEnd - 0.02, PBTune.groundEnd + 0.05, _p);
    final down = 1 - _smoothstep(PBTune.shadowEnd - 0.03, PBTune.shadowEnd + 0.03, _p);
    return (up * down).clamp(0.0, 1.0);
  }

  double get sunPresence => (1 - shadowFactor).clamp(0.0, 1.0);

  /// Cyclone visible during the target window (ramped).
  double get cyclonePresence {
    final up = _smoothstep(PBTune.sunlightEnd - 0.03, PBTune.sunlightEnd + 0.03, _p);
    final down = 1 - _smoothstep(PBTune.targetEnd - 0.02, PBTune.targetEnd + 0.04, _p);
    // hide once this lap's cyclone is already captured
    final captured = _lastCaptureLap == _state.orbitLap;
    return ((up * down) * (captured ? 0.0 : 1.0)).clamp(0.0, 1.0);
  }

  /// Ground station in range (ramped).
  double get groundPresence {
    final up = _smoothstep(PBTune.targetEnd - 0.02, PBTune.targetEnd + 0.04, _p);
    final down = 1 - _smoothstep(PBTune.groundEnd - 0.02, PBTune.groundEnd + 0.04, _p);
    return (up * down).clamp(0.0, 1.0);
  }

  // ── orbit zone ─────────────────────────────────────────────────────────────
  OrbitZone _zoneFor(double p) {
    if (p < PBTune.sunlightEnd) return OrbitZone.sunlight;
    if (p < PBTune.targetEnd) return OrbitZone.cycloneTarget;
    if (p < PBTune.groundEnd) return OrbitZone.groundStationRange;
    if (p < PBTune.shadowEnd) return OrbitZone.shadow;
    return OrbitZone.sunlight;
  }

  /// While guided, the orbit advances toward a hold point then freezes there.
  /// The shadow tutorial holds just BEFORE the shadow for a teachable beat
  /// ("Shadow ahead… charge now"), then releases into the dark.
  double? get _holdAt => switch (_state.phase) {
        MissionPhase.lowBatteryCrisis ||
        MissionPhase.solarTutorial =>
          PBTune.holdSunlight,
        MissionPhase.firstCapture => PBTune.holdTarget,
        MissionPhase.firstTransmission => PBTune.holdGround,
        MissionPhase.shadowTutorial =>
          _phaseT < PBTune.preShadowBeat ? PBTune.holdPreShadow : null,
        _ => null,
      };

  // ── per-frame tick (driven by the game) ────────────────────────────────────
  void tick(double dt) {
    if (_disposed) return;
    final phase = _state.phase;
    if (phase == MissionPhase.intro ||
        phase == MissionPhase.success ||
        phase == MissionPhase.failure) {
      return; // orbit frozen; only idle sprite animation runs in the game
    }

    _clock += dt;
    _phaseT += dt;
    _idleT += dt;
    // voice safety: if a clip's completion never arrives (focus loss, platform
    // drop), release the hold after 12s so the flow can't deadlock.
    if (_voiceActive && _clock - _voiceStartClock > 12) voiceFinished();
    if (_msgHold > 0) {
      // while Orbit speaks, the line holds — only count down once quiet
      if (!_voiceActive) _msgHold -= dt;
    } else if (_followUps.isNotEmpty) {
      // play the next queued Orbit line
      final (msg, mood) = _followUps.removeAt(0);
      _msgHold = PBTune.messageHold;
      _mut(_state.copyWith(helperMessage: msg, mascot: mood));
    }
    _advanceOrbit(dt);
    _onZoneTransition();
    _advanceBattery(dt);
    if (_state.phase == MissionPhase.failure) {
      _commit();
      return;
    }
    _advanceSolar(dt);
    _advanceBeats(dt);
    _advancePhase(dt);
    _checkWin();
    _maybeIdleHint();
    _commit();
  }

  /// Reacts once when the satellite crosses a zone boundary: re-arms the
  /// per-shadow praise latch, and a "that was close" if a free-play shadow pass
  /// ended with the battery nearly drained.
  void _onZoneTransition() {
    final zone = _state.currentZone;
    if (_prevZone == OrbitZone.shadow && zone != OrbitZone.shadow) {
      _goodSaveShown = false;
      if (_state.phase == MissionPhase.freeMissionLoop &&
          _state.batteryPercent < PBTune.lowExitBattery) {
        _msgHold = PBTune.messageHold;
        _followUps.clear();
        _mut(_state.copyWith(
            helperMessage: PBTune.recoverClose, mascot: MascotMood.warning));
      }
    }
    _prevZone = zone;
  }

  void _advanceOrbit(double dt) {
    final hold = _holdAt;
    var p = _state.orbitProgress;
    var lap = _state.orbitLap;
    final period =
        _state.phase == MissionPhase.freeMissionLoop ? PBTune.orbitPeriod : PBTune.tutorialOrbitPeriod;
    // thruster burst → temporarily speeds the satellite along its orbit
    final boost = _thrustBoostT > 0 ? PBTune.thrustBoostFactor : 1.0;
    if (_thrustBoostT > 0) _thrustBoostT -= dt;
    final step = dt / period * boost;
    if (hold != null) {
      if (p < hold) p = math.min(p + step, hold); // ease to the hold point
    } else {
      p += step;
      if (p >= 1.0) {
        p -= 1.0;
        lap += 1;
      }
    }
    _mut(_state.copyWith(orbitProgress: p, orbitLap: lap, currentZone: _zoneFor(p)));
  }

  /// Battery simulation — verbatim from PRD §11.1.
  void _advanceBattery(double dt) {
    final s = _state;
    // Fairness: no drain during the locked crisis story beat, nor while Orbit
    // is speaking in the GUIDED phases (the child is listening, not failing).
    // Free play keeps full pressure — its lines are ambient nudges. Charging
    // still works while frozen, so charging through a line is never punished.
    final freezeDrain = s.phase == MissionPhase.lowBatteryCrisis ||
        (_voiceActive && s.phase != MissionPhase.freeMissionLoop);
    double delta = freezeDrain ? 0 : -PBTune.baseDrainPerSec;
    if (s.currentZone.isSunlit) {
      if (s.solarAlign == SolarAlignState.aligned) {
        delta += PBTune.solarAlignedChargePerSec;
      } else if (!freezeDrain) {
        // the misaligned trickle is below base drain by design (net negative);
        // with drain frozen it would CREEP the battery up — skip it then.
        delta += PBTune.solarMisalignedChargePerSec;
      }
    }
    if (!freezeDrain) {
      if (s.cameraOn) delta -= PBTune.cameraDrainPerSec;
      if (s.antennaOn) delta -= PBTune.antennaDrainPerSec;
    }

    final battery = (s.batteryPercent + delta * dt).clamp(0.0, PBTune.maxBattery);
    final charging = delta > 0.3 && battery < PBTune.maxBattery;
    _mut(s.copyWith(
      batteryPercent: battery,
      isCharging: charging,
      batteryWarning: battery <= PBTune.lowThreshold,
    ));
    // "systems shutting down" alert when the battery drops below the low
    // threshold — fires once (re-arms after recovery) and shuts the camera off
    // (a non-critical system) to conserve power.
    if (battery <= PBTune.lowThreshold && battery > 0 && !_lowAlertShown) {
      _lowAlertShown = true;
      onSound?.call(PBSounds.wrong);
      _mut(_state.copyWith(
        lowPowerAlertToken: _state.lowPowerAlertToken + 1,
        cameraOn: false,
      ));
      // mid-game (not the scripted opening crisis): reassure + coach recovery
      final ph = _state.phase;
      if (ph != MissionPhase.lowBatteryCrisis && ph != MissionPhase.solarTutorial) {
        _msgHold = PBTune.messageHold;
        _followUps
          ..clear()
          ..add((PBTune.recoverWrongTime, MascotMood.thinking));
        _mut(_state.copyWith(
            helperMessage: PBTune.recoverAlive, mascot: MascotMood.warning));
      }
    } else if (battery > PBTune.lowThreshold + 6) {
      _lowAlertShown = false;
    }
    if (battery <= 0) _fail();
  }

  void _advanceSolar(double dt) {
    if (_state.solarAlign != SolarAlignState.aligned) return;
    _solarT += dt;
    if (_solarT >= PBTune.solarAlignHold) {
      _mut(_state.copyWith(solarAlign: SolarAlignState.misaligned, isCharging: false));
    }
  }

  // ── capture / send beats ───────────────────────────────────────────────────
  void _advanceBeats(double dt) {
    if (_state.capturing) {
      _captureT += dt;
      if (_captureT >= PBTune.captureBeat) {
        _captureT = 0;
        _msgHold = PBTune.messageHold;
        final imgs = _state.imagesCaptured + 1;
        _analytics.imageCaptured(imgs);
        onSound?.call(PBSounds.correct);
        _mut(_state.copyWith(
          imagesCaptured: imgs,
          capturing: false,
          cameraOn: false, // auto-off after capture (easy mode, PRD §19)
          helperMessage: PBTune.cameraCaptured,
          mascot: MascotMood.excited,
        ));
        // (the capture photo fly-to-counter animation is the capture feedback —
        // see CaptureFlyer; no badge pop needed here)
        if (_state.phase == MissionPhase.firstCapture) {
          _enterPhase(MissionPhase.firstTransmission,
              message: PBTune.antennaHaveImage,
              mascot: MascotMood.thinking,
              hint: ControlHint.antenna,
              followUps: const [(PBTune.antennaComing, MascotMood.thinking)]);
        } else if (_state.phase == MissionPhase.freeMissionLoop) {
          _followUps.add((PBTune.freePraise, MascotMood.success));
        }
      }
    }
    if (_state.sending) {
      _sendT += dt;
      if (_sendT >= PBTune.sendBeat) {
        _sendT = 0;
        _msgHold = PBTune.messageHold;
        final sent = _state.dataSent + 1;
        _analytics.dataSent(sent);
        onSound?.call(PBSounds.correct);
        _mut(_state.copyWith(
          dataSent: sent,
          sending: false,
          antennaOn: false,
          helperMessage: PBTune.antennaSent,
          mascot: MascotMood.success,
          transmitDoneToken: _state.transmitDoneToken + 1, // → "Data Received" pills
        ));
        if (_state.phase == MissionPhase.firstTransmission) {
          // pre-shadow teachable beat: "shadow ahead… charge now", with the
          // orbit held just before the dark (see _holdAt), then released.
          _shadowAnnounced = false;
          _enterPhase(MissionPhase.shadowTutorial,
              message: PBTune.shadowAhead,
              mascot: MascotMood.warning,
              hint: ControlHint.none,
              followUps: const [(PBTune.shadowChargeNow, MascotMood.thinking)]);
        } else if (!_sentEduShown) {
          _sentEduShown = true;
          _followUps.add((PBTune.antennaEdu, MascotMood.thinking));
        } else if (_state.phase == MissionPhase.freeMissionLoop) {
          _followUps.add((PBTune.freePraise, MascotMood.success));
        }
      }
    }
  }

  // ── phase machine + adaptive copy ──────────────────────────────────────────
  void _enterPhase(MissionPhase p,
      {required String message,
      required MascotMood mascot,
      ControlHint hint = ControlHint.none,
      List<(String, MascotMood)> followUps = const []}) {
    _phaseT = 0;
    _idleT = 0;
    _msgHold = PBTune.messageHold; // let the entry line breathe before ambient/queue
    _followUps
      ..clear()
      ..addAll(followUps);
    _mut(_state.copyWith(
      phase: p, helperMessage: message, mascot: mascot, controlHint: hint, hintLevel: 0));
  }

  void _advancePhase(double dt) {
    final s = _state;
    switch (s.phase) {
      case MissionPhase.lowBatteryCrisis:
        // the 4-line crisis story plays out (voice-paced via the queue), then
        // hands off to the solar tutorial
        if (_msgHold <= 0 && _followUps.isEmpty) {
          _enterPhase(MissionPhase.solarTutorial,
              message: PBTune.solarPrompt, mascot: MascotMood.thinking, hint: ControlHint.solar);
        }

      case MissionPhase.solarTutorial:
        // charge to target → cyclone approaches (first capture). The orbit holds
        // here until full, so nudge the child to keep tapping Solar to get there.
        if (s.batteryPercent >= PBTune.solarTutorialTarget) {
          _analytics.solarCharged(s.batteryPercent);
          _enterPhase(MissionPhase.firstCapture,
              message: PBTune.cameraComing,
              mascot: MascotMood.thinking,
              hint: ControlHint.camera,
              followUps: const [(PBTune.cameraGetReady, MascotMood.thinking)]);
        } else if (_msgHold <= 0 && _followUps.isEmpty) {
          if (s.isCharging) {
            if (s.helperMessage != PBTune.solarCharging) {
              _mut(s.copyWith(helperMessage: PBTune.solarCharging, mascot: MascotMood.excited));
            }
          } else if (s.chargeBurstToken == 0) {
            // hasn't tapped Solar yet — keep the FIRST prompt up; "keep
            // charging" only makes sense after a charge burst has decayed
            if (s.helperMessage != PBTune.solarPrompt) {
              _mut(s.copyWith(helperMessage: PBTune.solarPrompt, mascot: MascotMood.thinking));
            }
          } else if (s.helperMessage != PBTune.solarKeepGoing) {
            _mut(s.copyWith(helperMessage: PBTune.solarKeepGoing, mascot: MascotMood.thinking));
          }
        }

      case MissionPhase.firstCapture:
        // "Look below… get ready" while approaching; "Now!" once over the target
        if (_msgHold <= 0 && _followUps.isEmpty && !s.capturing) {
          final inTarget = s.currentZone == OrbitZone.cycloneTarget;
          if (inTarget) {
            if (s.helperMessage != PBTune.cameraPrompt) {
              _mut(s.copyWith(
                  helperMessage: PBTune.cameraPrompt, mascot: MascotMood.excited));
            }
          } else if (s.helperMessage != PBTune.cameraComing &&
              s.helperMessage != PBTune.cameraGetReady) {
            _mut(s.copyWith(
                helperMessage: PBTune.cameraComing, mascot: MascotMood.thinking));
          }
        }

      case MissionPhase.firstTransmission:
        if (_msgHold <= 0 && _followUps.isEmpty && !s.sending) {
          final inRange = s.currentZone == OrbitZone.groundStationRange;
          if (inRange) {
            if (s.helperMessage != PBTune.antennaPrompt) {
              _mut(s.copyWith(
                  helperMessage: PBTune.antennaPrompt, mascot: MascotMood.excited));
            }
          } else if (s.helperMessage != PBTune.antennaHaveImage &&
              s.helperMessage != PBTune.antennaComing) {
            _mut(s.copyWith(
                helperMessage: PBTune.antennaComing, mascot: MascotMood.thinking));
          }
        }

      case MissionPhase.shadowTutorial:
        // entering the dark: "we're in shadow now" → "survive on battery"
        if (!_shadowAnnounced && s.currentZone == OrbitZone.shadow) {
          _shadowAnnounced = true;
          _shadowEnterClock = _clock;
          _analytics.enteredShadow();
          _popBadge(FeedbackBadge.shadow);
          _msgHold = PBTune.messageHold;
          _followUps
            ..clear()
            ..add((PBTune.shadowOnBattery, MascotMood.thinking));
          _mut(s.copyWith(helperMessage: PBTune.shadowEnter, mascot: MascotMood.warning));
        }
        // nag only if the child leaves a power-hungry system on in shadow
        if (_msgHold <= 0 &&
            _shadowAnnounced &&
            (s.cameraOn || s.antennaOn) &&
            s.helperMessage != PBTune.shadowDraining) {
          _mut(s.copyWith(helperMessage: PBTune.shadowDraining, mascot: MascotMood.warning));
        }
        // praise a quiet, well-managed shadow pass once
        if (_msgHold <= 0 &&
            _shadowAnnounced &&
            !_goodSaveShown &&
            !s.cameraOn &&
            !s.antennaOn &&
            _clock - _shadowEnterClock >= PBTune.shadowSaveAfter) {
          _goodSaveShown = true;
          _msgHold = PBTune.messageHold;
          _mut(s.copyWith(helperMessage: PBTune.shadowSaving, mascot: MascotMood.success));
        }
        // survived the shadow → free play
        if (_p >= PBTune.shadowEnd || _p < PBTune.holdSunlight) {
          final scraped = s.batteryPercent < PBTune.lowExitBattery;
          _enterPhase(MissionPhase.freeMissionLoop,
              message: scraped ? PBTune.recoverClose : PBTune.shadowExit,
              mascot: scraped ? MascotMood.warning : MascotMood.success);
        }

      case MissionPhase.freeMissionLoop:
        if (_msgHold <= 0 && _followUps.isEmpty) _freeLoopCopy(s);

      default:
        break;
    }
  }

  /// Short, zone-driven nudges during free play (PRD §12 Scene 6).
  void _freeLoopCopy(PowerBalanceState s) {
    // one-time "think like an engineer" framing as free play opens up
    if (!_freeIntroShown) {
      _freeIntroShown = true;
      _msgHold = PBTune.messageHold;
      _mut(s.copyWith(helperMessage: PBTune.freeThink, mascot: MascotMood.thinking));
      return;
    }
    String msg;
    MascotMood mood;
    if (s.batteryWarning && !s.currentZone.isSunlit) {
      msg = PBTune.loopLowBattery;
      mood = MascotMood.warning;
    } else {
      switch (s.currentZone) {
        case OrbitZone.sunlight:
          msg = PBTune.loopSunlight;
          mood = MascotMood.neutral;
        case OrbitZone.cycloneTarget:
          msg = s.imagesCaptured >= PBTune.imagesNeeded ? PBTune.loopGround : PBTune.loopTarget;
          mood = MascotMood.thinking;
        case OrbitZone.groundStationRange:
          msg = s.unsentImages > 0 ? PBTune.loopGround : PBTune.loopSunlight;
          mood = MascotMood.thinking;
        case OrbitZone.shadow:
          msg = PBTune.loopShadow;
          mood = MascotMood.warning;
      }
    }
    if (s.helperMessage != msg) _mut(s.copyWith(helperMessage: msg, mascot: mood));
  }

  void _checkWin() {
    final s = _state;
    if (s.phase == MissionPhase.freeMissionLoop &&
        s.imagesCaptured >= PBTune.imagesNeeded &&
        s.dataSent >= PBTune.dataNeeded &&
        s.batteryPercent > 0) {
      _succeed();
    }
  }

  void _maybeIdleHint() {
    if (_idleT < PBTune.idleHintAfter) return;
    _idleT = 0;
    final hint = (_state.hintLevel + 1).clamp(0, 5);
    _analytics.hintShown(hint);
    _mut(_state.copyWith(hintLevel: hint));
  }

  // ── control intents (called from the Flutter dock) ─────────────────────────
  /// Whether a control is usable right now (drives the dock's enabled state).
  /// Every control is the child's to use whenever playing — the tutorial only
  /// SUGGESTS via the highlight, it never disables/dims the others (so the child
  /// decides for themselves). Only the brief crisis intro + an in-flight
  /// capture/send beat lock the dock. ([c] kept for caller symmetry.)
  bool controlEnabled(ControlHint c) {
    final s = _state;
    if (!s.isPlaying || s.capturing || s.sending) return false;
    if (s.phase == MissionPhase.lowBatteryCrisis) return false; // ~brief story beat
    return true;
  }

  void tapSolar() {
    final s = _state;
    if (!controlEnabled(ControlHint.solar)) return;
    _solarT = 0;
    _idleT = 0;
    _msgHold = PBTune.messageHold;
    onSound?.call(PBSounds.tap);
    onHaptic?.call();
    final inSun = s.currentZone.isSunlit;
    // teach "sunlight mode" with a badge the first time we charge in the tutorial
    if (inSun && s.phase == MissionPhase.solarTutorial) _popBadge(FeedbackBadge.sunlight);
    // the tutorial charge earns the 3-line teach: glow → becomes power →
    // battery stores it (free-play charges just get the "Nice!" line)
    _followUps.clear();
    if (inSun && s.phase == MissionPhase.solarTutorial) {
      _followUps.addAll(const [
        (PBTune.solarFact, MascotMood.thinking),
        (PBTune.solarStoring, MascotMood.thinking),
      ]);
    }
    _set(_state.copyWith(
      solarAlign: SolarAlignState.aligned,
      chargeBurstToken: _state.chargeBurstToken + 1,
      helperMessage: inSun ? PBTune.solarCharging : PBTune.solarMisaligned,
      mascot: inSun ? MascotMood.excited : MascotMood.warning,
    ));
  }

  /// Praise a proactive power save (turning a tool OFF while in shadow).
  void _maybeGoodCatch() {
    if (_state.currentZone == OrbitZone.shadow && !_goodSaveShown) {
      _goodSaveShown = true;
      _msgHold = PBTune.messageHold;
      _followUps.clear();
      _mut(_state.copyWith(
          helperMessage: PBTune.recoverGoodCatch, mascot: MascotMood.success));
    }
  }

  void toggleCamera() {
    final s = _state;
    if (!controlEnabled(ControlHint.camera) && !s.cameraOn) return;
    _idleT = 0;
    if (s.cameraOn) {
      _followUps.clear(); // "let's turn it off" is now stale
      _maybeGoodCatch();
      _set(_state.copyWith(cameraOn: false)); // turning off is always allowed
      return;
    }
    // camera is a non-critical system — locked while the battery is low.
    if (s.cameraLocked) {
      _msgHold = PBTune.messageHold;
      _followUps.clear();
      onSound?.call(PBSounds.wrong);
      _set(s.copyWith(
        warnToken: s.warnToken + 1,
        helperMessage: PBTune.cameraLowBattery,
        mascot: MascotMood.warning,
      ));
      return;
    }
    final canCapture = s.currentZone == OrbitZone.cycloneTarget &&
        s.imagesCaptured < PBTune.imagesNeeded &&
        _lastCaptureLap != s.orbitLap;
    _msgHold = PBTune.messageHold;
    _followUps.clear();
    if (canCapture) {
      _lastCaptureLap = s.orbitLap;
      _captureT = 0;
      onSound?.call(PBSounds.tap);
      onHaptic?.call();
      _set(s.copyWith(
        cameraOn: true,
        capturing: true,
        captureToken: s.captureToken + 1,
        helperMessage: PBTune.cameraCaptured,
        mascot: MascotMood.excited,
      ));
    } else {
      // wrong use — drains battery, gentle warning + "let's turn it off" chase
      _analytics.wrongCameraUse();
      onSound?.call(PBSounds.wrong);
      _followUps.add((PBTune.cameraTurnOff, MascotMood.thinking));
      _set(s.copyWith(
        cameraOn: true,
        warnToken: s.warnToken + 1,
        helperMessage: PBTune.cameraWrong,
        mascot: MascotMood.warning,
        hintLevel: (s.hintLevel + 1).clamp(0, 5),
      ));
    }
  }

  void toggleAntenna() {
    final s = _state;
    if (!controlEnabled(ControlHint.antenna) && !s.antennaOn) return;
    _idleT = 0;
    if (s.antennaOn) {
      _followUps.clear();
      _maybeGoodCatch();
      _set(_state.copyWith(antennaOn: false));
      return;
    }
    final inRange = s.currentZone == OrbitZone.groundStationRange;
    final hasData = s.unsentImages > 0;
    _msgHold = PBTune.messageHold;
    _followUps.clear();
    if (inRange && hasData) {
      _sendT = 0;
      onSound?.call(PBSounds.tap);
      onHaptic?.call();
      _set(s.copyWith(
        antennaOn: true,
        sending: true,
        sendToken: s.sendToken + 1,
        helperMessage: PBTune.antennaSent,
        mascot: MascotMood.excited,
      ));
    } else {
      _analytics.wrongAntennaUse();
      onSound?.call(PBSounds.wrong);
      if (hasData) {
        // out of range: "if we send now we'll waste power" → "let's wait…"
        _followUps.add((PBTune.antennaWaitEarth, MascotMood.thinking));
      }
      _set(s.copyWith(
        antennaOn: true,
        warnToken: s.warnToken + 1,
        helperMessage: hasData ? PBTune.antennaWrong : PBTune.antennaNoData,
        mascot: MascotMood.warning,
        hintLevel: (s.hintLevel + 1).clamp(0, 5),
      ));
    }
  }

  void tapThruster() {
    final s = _state;
    if (!controlEnabled(ControlHint.none) || s.capturing || s.sending) return;
    _idleT = 0;
    final battery = (s.batteryPercent - PBTune.thrusterCost).clamp(0.0, PBTune.maxBattery);
    _msgHold = PBTune.messageHold;
    _followUps.clear();
    _thrustBoostT = PBTune.thrustBoostDuration; // burst: speeds the satellite up
    _analytics.thrusterFired(battery);
    onSound?.call(PBSounds.tap);
    onHaptic?.call();
    // first use teaches; rapid re-fires get the spam warning; a considered
    // (spaced-out) use earns "good choice".
    _thrusterCount++;
    final spam = _clock - _lastThrustClock < PBTune.thrusterSpamWindow;
    _lastThrustClock = _clock;
    final String msg;
    final MascotMood mood;
    if (_thrusterCount == 1) {
      msg = PBTune.thrusterTip;
      mood = MascotMood.thinking;
      _followUps.add((PBTune.thrusterOnlyWhenNeeded, MascotMood.thinking));
    } else if (spam) {
      msg = PBTune.thrusterSpam;
      mood = MascotMood.warning;
    } else {
      msg = PBTune.thrusterGoodChoice;
      mood = MascotMood.success;
    }
    _set(s.copyWith(
      batteryPercent: battery,
      thrusterToken: s.thrusterToken + 1,
      helperMessage: msg,
      mascot: mood,
      batteryWarning: battery <= PBTune.lowThreshold,
    ));
    if (battery <= 0) _fail();
  }

  // ── start / end ─────────────────────────────────────────────────────────
  void startMission() {
    if (_state.phase != MissionPhase.intro) return;
    // crisis kept to 2 lines — crisis2 is redundant with the POWER CRITICAL
    // popup and crisis4 with the solar prompt that follows immediately.
    _enterPhase(MissionPhase.lowBatteryCrisis,
        message: PBTune.crisis1,
        mascot: MascotMood.warning,
        followUps: const [(PBTune.crisis3, MascotMood.thinking)]);
  }

  void _succeed() {
    _analytics.missionCompleted();
    onSound?.call(PBSounds.complete);
    _mut(_state.copyWith(
      phase: MissionPhase.success,
      cameraOn: false,
      antennaOn: false,
      capturing: false,
      sending: false,
      helperMessage: PBTune.successLine,
      mascot: MascotMood.success,
    ));
  }

  void _fail() {
    if (_state.phase == MissionPhase.failure) return;
    _analytics.missionFailed();
    onSound?.call(PBSounds.wrong);
    _mut(_state.copyWith(
      phase: MissionPhase.failure,
      batteryPercent: 0,
      cameraOn: false,
      antennaOn: false,
      isCharging: false,
      capturing: false,
      sending: false,
      helperMessage: PBTune.failureLine,
      mascot: MascotMood.warning,
    ));
  }

  /// Reset everything for a retry (PRD §8 — kind, no punishment).
  void retry() {
    _analytics.retried();
    _phaseT = _solarT = _captureT = _sendT = _idleT = _thrustBoostT = _clock = 0;
    _shadowEnterClock = -1;
    _lastThrustClock = -99;
    _lastCaptureLap = -1;
    _thrusterCount = 0;
    _shadowAnnounced = false;
    _lowAlertShown = false;
    _freeIntroShown = false;
    _goodSaveShown = false;
    _sentEduShown = false;
    _prevZone = null;
    _voiceActive = false;
    _followUps
      ..clear()
      ..add((PBTune.crisis3, MascotMood.thinking)); // 2-line crisis, see startMission
    _msgHold = PBTune.messageHold;
    _set(const PowerBalanceState().copyWith(
      phase: MissionPhase.lowBatteryCrisis,
      batteryPercent: PBTune.startBattery,
      orbitProgress: PBTune.holdSunlight,
      currentZone: OrbitZone.sunlight,
      helperMessage: PBTune.crisis1,
      mascot: MascotMood.warning,
    ));
  }

  void finish() {/* hook for analytics flush on exit */}
}
