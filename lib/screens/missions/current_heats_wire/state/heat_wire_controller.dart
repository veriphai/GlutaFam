// The Hot Wire (beat 2.3) — the activity controller (controller-owns-geometry).
// Owns the catenary geometry, the honest sim (current → wireTemp → motes/pulses,
// and rubHeat), the silent phase machine (PRD §14), the _schedule(ms) one-shot
// timers, and the polish/capture hooks. The painter is a pure renderer that reads
// getters only.
//
// THE LOAD-BEARING RULES (PRD §6 / acceptance #2):
//   • The frame current reaches 0, pulse travel STOPS and heat generation (mote
//     spawn-rate + heat input) is EXACTLY 0 that same frame — a hard gate in tick(),
//     never a decay/fade. The residual wire glow then cools on a real thermal decay
//     (tempCoolTau); disableAnimations does NOT change this.
//   • No slider momentum, no coasting; current eases toward the slider value only.
//   • Gates only ever advance (high-water marks); pumping the slider mid-line never
//     breaks the machine.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Offset, Size;

import '../config/heat_wire_beats.dart';
import '../config/heat_wire_tuning.dart';
import 'heat_wire_particles.dart';

class HeatWireController extends ChangeNotifier {
  HeatWireController() {
    _heatMotes = HeatMoteField(
      maxMotes: HWTune.moteMax,
      life: HWTune.moteLife,
      riseTopY: 0, // set on first setStageSize
    );
    _ambient = AmbientMoteField(HWTune.ambientMoteMax);
  }

  // ── Discrete UI channels (rebuild only on change) ────────────────────
  final ValueNotifier<HeatWirePhase> phase = ValueNotifier(HeatWirePhase.raiseCurrent);
  final ValueNotifier<HWCaption> caption = ValueNotifier(const HWCaption(''));
  final ValueNotifier<HWCaption?> secondary = ValueNotifier(null);
  final ValueNotifier<bool> sliderEnabled = ValueNotifier(true);
  final ValueNotifier<bool> showContinue = ValueNotifier(false);
  final ValueNotifier<bool> showCardEarn = ValueNotifier(false);

  // The two live numbers (0–100), sampled at ~5 Hz so they tick legibly, with
  // a trend arrow (-1/0/+1) each.
  final ValueNotifier<int> currentDisplay = ValueNotifier(0);
  final ValueNotifier<int> heatDisplay = ValueNotifier(0);
  final ValueNotifier<int> currentTrend = ValueNotifier(0);
  final ValueNotifier<int> heatTrend = ValueNotifier(0);

  // ── Polish hooks (haptics) + capture ─────────────────────────────────
  void Function()? onSliderTick; // selectionClick per 0.1 slider crossing
  void Function()? onRubStroke; // selectionClick per rub reversal
  void Function()? onDiscovery; // heavyImpact at the A3 discovery
  void Function(String evidenceId)? onCapture; // shell snapshots + pins the tile

  /// Reduced motion (MediaQuery.disableAnimations): calm motes / static shimmer /
  /// flash→fade. The same-frame generation stop is NEVER softened.
  bool reducedMotion = false;

  // ── Geometry (pixels = factors × stage size) ─────────────────────────
  Size _stage = Size.zero;
  Size get stageSize => _stage;
  void setStageSize(Size s) {
    if (s == _stage) return;
    _stage = s;
    _heatMotes = HeatMoteField(
      maxMotes: HWTune.moteMax,
      life: HWTune.moteLife,
      riseTopY: HWTune.moteRiseTop * s.height,
    )..motes.addAll(_heatMotes.motes); // carry airborne motes across a resize
  }

  double get _w => _stage.width;
  double get _h => _stage.height;

  // DIAGONAL anchors: the left/PLANT anchor sits LOW, the right/CITY anchor sits
  // HIGH, so the span climbs across the whole frame (no centered-U dead air).
  Offset get leftAnchor => Offset(HWTune.pylonLeftX * _w, HWTune.pylonLeftTopY * _h);
  Offset get rightAnchor => Offset(HWTune.pylonRightX * _w, HWTune.pylonRightTopY * _h);
  double get wireStroke => HWTune.wireStrokeF * _h;

  /// The catenary point for t in [0,1] (0 = left anchor, 1 = right anchor). The
  /// straight line is now the DIAGONAL between the two differently-heighted
  /// anchors; a parabolic SAG dips below it (max at midspan). Visually a clean
  /// catenary, byte-identical every beat (the wire geometry never changes across
  /// beats; only its glow does — the held-constant).
  Offset wirePoint(double t) {
    final x = leftAnchor.dx + (rightAnchor.dx - leftAnchor.dx) * t;
    final straightY = leftAnchor.dy + (rightAnchor.dy - leftAnchor.dy) * t;
    final sagDepth = HWTune.sagDepthF * _h; // below the straight diagonal
    final sag = sagDepth * 4 * t * (1 - t); // parabola, max at t=0.5
    return Offset(x, straightY + sag);
  }

  // ── Sim state (hot path; painter repaints via the controller) ────────
  double _current = 0; // 0..1, eased toward slider
  double _sliderValue = 0; // 0..1, raw slider
  double _wireTemp = 0; // 0..1, leaky integrator
  double _rubHeat = 0; // 0..1, friction warmth under the finger
  double _heatInput = 0; // current^2*kGain + rubInput, this frame
  double _pulsePhase = 0; // 0..1 travel phase of the lead pulse
  double _hazePhase = 0; // ever-rising clock for the heat-haze shimmer scroll
  double _flash = 0; // 0..1 discovery-flash envelope (decays)
  double _flashClock = 0;
  bool _flashActive = false;

  // rub tracking
  double? _rubLastX; // last clamped pointer x within the band (pixels)
  int _rubDir = 0; // -1 / +1 last stroke direction
  int _rubReversals = 0;
  double _rubInputThisFrame = 0;

  // gate accumulators
  double _sustainAcc = 0; // time current has been >= sustainHi
  bool _moteEmphasis = false; // beat C: ×1.6 motes + amplified pulse taper

  // heat_leaves_wire capture is armed when the C3 timer fires but deferred until
  // the live frame is actually the streaming-loss moment (PRD §9 fire condition:
  // current sustained high, wire hot, motes streaming). This guards
  // against the learner dropping the slider during the C2 "Now Watch the Wire"
  // hold — the captured PNG must always show the high-current loss frame.
  bool _heatLeavesCaptureArmed = false;

  late HeatMoteField _heatMotes;
  late AmbientMoteField _ambient;

  // sampling
  double _sampleAcc = 0;
  int _lastCurrentSample = 0;
  int _lastHeatSample = 0;

  // slider haptic detents
  int _lastDetent = 0;

  // ── Entrance reveal (0→1 across elements) ────────────────────────────
  double _clock = 0; // total elapsed since start()
  bool _started = false;

  // Reveal value for element index i (0..3): pylons, [spare], wire, tags. Index 1
  // formerly faded the lamp glyph (now removed); the slot is kept so the wire/tags
  // reveal timings stay byte-identical.
  double reveal(int i) {
    if (!_started) return 0;
    final start = (HWTune.revealStartMs + i * HWTune.revealStaggerMs) / 1000.0;
    final dur = HWTune.revealDurationMs / 1000.0;
    final v = ((_clock - start) / dur).clamp(0.0, 1.0);
    // easeOutCubic
    final iv = 1 - v;
    return 1 - iv * iv * iv;
  }

  // ── Public read getters for the painter ──────────────────────────────
  double get current => _current;
  double get wireTemp => _wireTemp;
  double get rubHeat => _rubHeat;
  double get heatInput => _heatInput;
  double get pulsePhase => _pulsePhase;
  double get hazePhase => _hazePhase;
  double get flashIntensity => _flash;
  bool get moteEmphasis => _moteEmphasis;
  List<HeatMote> get heatMotes => _heatMotes.motes;
  List<AmbientMote> get ambientMotes => _ambient.motes;
  bool get pulsesMoving => _current > 0.001;

  /// The rub finger glow — clamped pointer x (pixels) + an intensity 0..1.
  double? get rubGlowX => _rubGlowX;
  double get rubGlowIntensity => _rubHeat;
  double? _rubGlowX;

  bool get pulseTaperAmplified => _moteEmphasis;
  double get pulseTaper => _moteEmphasis ? HWTune.pulseTaperEmph : HWTune.pulseTaperBase;

  // ── Lifecycle ────────────────────────────────────────────────────────
  void start() {
    if (_started) return;
    _started = true;
    _schedule(HWCopy.firstCaptionMs, () {
      caption.value = HWCopy.a1RaiseCurrent;
      notifyListeners();
    });
  }

  // ── Slider input (the only manipulated variable; the wire never changes) ─
  void onSliderChanged(double v) {
    if (!sliderEnabled.value) return;
    _sliderValue = v.clamp(0.0, 1.0);
    final detent = (_sliderValue * 10).round();
    if (detent != _lastDetent) {
      _lastDetent = detent;
      onSliderTick?.call();
    }
  }

  // ── Pointer routing for the rub band (beat B) ────────────────────────
  void onPointerDown(Offset local) {
    if (phase.value != HeatWirePhase.rubWire && phase.value != HeatWirePhase.frictionNamed) {
      return;
    }
    _rubLastX = _hitRubBand(local);
  }

  void onPointerMove(Offset local) {
    if (phase.value != HeatWirePhase.rubWire && phase.value != HeatWirePhase.frictionNamed) {
      return;
    }
    final x = _hitRubBand(local);
    if (x == null) {
      _rubLastX = null;
      return;
    }
    if (_rubLastX != null) {
      final dx = x - _rubLastX!;
      final minTravel = HWTune.rubMinTravelF * _w;
      if (dx.abs() >= 1) {
        final speed = dx.abs(); // pixels this move
        // Friction warmth accumulates with stroke speed (normalized by span).
        _rubInputThisFrame += (speed / _w) * HWTune.rubGain;
        final dir = dx > 0 ? 1 : -1;
        if (dir != _rubDir && dx.abs() >= minTravel) {
          if (_rubDir != 0) {
            _rubReversals++;
            onRubStroke?.call();
          }
          _rubDir = dir;
        }
      }
    }
    _rubLastX = x;
    _rubGlowX = x;
  }

  void onPointerUp() {
    _rubLastX = null;
    // glow lingers via _rubHeat cooling; no instant clear
  }

  /// If [local] is inside the rub band, return the clamped x (pixels) on the
  /// wire's playable span; else null.
  double? _hitRubBand(Offset local) {
    final minX = HWTune.rubMinX * _w;
    final maxX = HWTune.rubMaxX * _w;
    final clampedX = local.dx.clamp(minX, maxX);
    final t = ((clampedX - leftAnchor.dx) / (rightAnchor.dx - leftAnchor.dx)).clamp(0.0, 1.0);
    final wy = wirePoint(t).dy;
    if ((local.dy - wy).abs() <= HWTune.rubBandHF * _h && local.dx >= minX && local.dx <= maxX) {
      return clampedX;
    }
    return null;
  }

  // ── The frame loop ───────────────────────────────────────────────────
  void tick(double dt) {
    if (_stage == Size.zero) return;
    _clock += dt;

    // 1) current eases toward the slider (no momentum / coasting).
    _current = _approach(_current, _sliderValue, dt, HWTune.currentTau);
    if (_current < 0.0005) _current = 0;

    // 2) rub heat: rises with this-frame rub input, decays otherwise.
    final isRubBeat = phase.value == HeatWirePhase.rubWire ||
        phase.value == HeatWirePhase.frictionNamed;
    if (isRubBeat && _rubInputThisFrame > 0) {
      _rubHeat = (_rubHeat + _rubInputThisFrame).clamp(0.0, 1.0);
    } else {
      _rubHeat = _approach(_rubHeat, 0, dt, HWTune.rubCoolTau);
      if (_rubHeat < 0.004) _rubHeat = 0;
    }
    final rubInput = isRubBeat ? _rubHeat : 0.0;
    if (_rubHeat <= 0) _rubGlowX = null;

    // 3) heat input — current^2 (honest I^2) + rub. HARD 0 when both are 0.
    final electricHeat = _current * _current * HWTune.kGain;
    _heatInput = electricHeat + rubInput;
    _rubInputThisFrame = 0;

    // 4) wireTemp leaky integrator — rise toward heatInput, cool toward 0.
    //    The cool branch is REAL thermal decay (tempCoolTau), the only thing that
    //    happens to the glow after generation stops.
    if (_heatInput > _wireTemp) {
      _wireTemp = _approach(_wireTemp, _heatInput.clamp(0.0, 1.0), dt, HWTune.tempRiseTau);
    } else {
      _wireTemp = _approach(_wireTemp, _heatInput.clamp(0.0, 1.0), dt, HWTune.tempCoolTau);
    }
    _wireTemp = _wireTemp.clamp(0.0, 1.0);

    // 5) pulses travel only while current flows; STOP DEAD the frame current = 0.
    if (_current > 0) {
      _pulsePhase = (_pulsePhase + HWTune.pulseSpeed * (0.35 + 0.65 * _current) * dt) % 1.0;
    }
    // (when _current == 0 the phase is frozen — pulses do not coast)

    // 5b) heat-haze shimmer scroll — advances with wall time (a render flourish;
    //     the painter renders static bands under reduced motion).
    if (!reducedMotion) _hazePhase += dt * HWTune.hazeSpeed;

    // 6) heat motes — spawn rate baked from heatInput; HARD 0 at heatInput 0.
    final baseRate = HWTune.moteSpawnPerSec * _heatInput;
    final rate = (_heatInput <= 0)
        ? 0.0
        : (reducedMotion ? baseRate * 0.5 : baseRate) *
            (_moteEmphasis ? HWTune.moteEmphasis : 1.0);
    if (rate <= 0) {
      _heatMotes.resetSpawnAccumulator();
    } else {
      _heatMotes.spawn(
        dt: dt,
        ratePerSec: rate,
        pickT: () {
          // During the rub, motes bloom under the finger; otherwise along the span.
          if (isRubBeat && _rubGlowX != null) {
            final t = ((_rubGlowX! - leftAnchor.dx) /
                    (rightAnchor.dx - leftAnchor.dx))
                .clamp(0.0, 1.0);
            return (t + (_rngT() - 0.5) * 0.08).clamp(0.0, 1.0);
          }
          return 0.08 + _rngT() * 0.84; // along the playable span
        },
        spanPoint: wirePoint,
        // rise distance ≈ from the span (midspan sag) up to the rise-top, in px.
        riseSpeed: (wirePoint(0.5).dy - HWTune.moteRiseTop * _h) * 0.9,
      );
    }
    _heatMotes.update(dt);

    // 7) discovery flash envelope (700 ms), decays to 0.
    if (_flashActive) {
      _flashClock += dt;
      final p = (_flashClock / (HWTune.flashMs / 1000.0)).clamp(0.0, 1.0);
      // ease in fast, out slow
      _flash = p < 0.25 ? p / 0.25 : (1 - (p - 0.25) / 0.75);
      _flash = _flash.clamp(0.0, 1.0);
      if (p >= 1) {
        _flashActive = false;
        _flash = 0;
      }
    }

    // 8) timers (single one-shot, per the shipped _schedule pattern).
    _tickSchedule(dt);

    // 9) phase gates that depend on the sim.
    _tickGates(dt);

    // 10) sample the two displayed numbers at ~5 Hz with trend arrows.
    _sampleAcc += dt;
    if (_sampleAcc >= 1.0 / HWTune.sampleHz) {
      _sampleAcc = 0;
      _sampleNumbers();
    }

    notifyListeners();
  }

  void _sampleNumbers() {
    final curN = (_current * 100).round();
    final heatN = (_wireTemp * 100).round();
    currentTrend.value = curN > _lastCurrentSample ? 1 : (curN < _lastCurrentSample ? -1 : 0);
    heatTrend.value = heatN > _lastHeatSample ? 1 : (heatN < _lastHeatSample ? -1 : 0);
    _lastCurrentSample = curN;
    _lastHeatSample = heatN;
    if (curN != currentDisplay.value) currentDisplay.value = curN;
    if (heatN != heatDisplay.value) heatDisplay.value = heatN;
  }

  // ── Gate logic (sim-dependent transitions) ───────────────────────────
  void _tickGates(double dt) {
    switch (phase.value) {
      case HeatWirePhase.raiseCurrent:
        // discovery gate: current >= 0.75 sustained 600 ms.
        if (_current >= HWTune.sustainHi) {
          _sustainAcc += dt * 1000;
          if (_sustainAcc >= HWTune.sustainMs) _enterWireHot();
        } else {
          _sustainAcc = 0;
        }

      case HeatWirePhase.dropLow:
        if (_current <= HWTune.dropLowCurrent && _wireTemp <= HWTune.dropLowTemp) {
          _enterCooled();
        }

      case HeatWirePhase.rubWire:
        if (_rubHeat >= HWTune.rubGateHeat && _rubReversals >= HWTune.rubGateReversals) {
          _enterFrictionNamed();
        }

      case HeatWirePhase.raiseAgain:
        if (_current >= HWTune.sustainHi) {
          _sustainAcc += dt * 1000;
          if (_sustainAcc >= HWTune.sustainMs) _enterLossMoment();
        } else {
          _sustainAcc = 0;
        }

      case HeatWirePhase.lossMoment:
        // Deferred capture (PRD §9): only snapshot heat_leaves_wire on a frame
        // that actually shows the streaming-loss moment — current sustained high
        // and the wire visibly hot. If the learner dropped current during the C2
        // hold, this re-arms automatically and fires when current is high again.
        if (_heatLeavesCaptureArmed &&
            _current >= HWTune.sustainHi &&
            _wireTemp >= HWTune.a2Temp) {
          _heatLeavesCaptureArmed = false;
          onCapture?.call('heat_leaves_wire');
        }

      default:
        break;
    }
  }

  // ── Phase transitions ────────────────────────────────────────────────
  void _enterWireHot() {
    phase.value = HeatWirePhase.wireHot;
    _sustainAcc = 0;
    secondary.value = null;
    // DISCOVERY: glow flash + heavyImpact, then the felt line → the drop prompt.
    _flashActive = true;
    _flashClock = 0;
    onDiscovery?.call();
    caption.value = HWCopy.a2HotterWire;
    _schedule(HWCopy.a2HoldMs, () {
      phase.value = HeatWirePhase.dropLow;
      caption.value = HWCopy.a3DropItLow;
      notifyListeners();
    });
    notifyListeners();
  }

  void _enterCooled() {
    phase.value = HeatWirePhase.cooled;
    // a brief silent beat as the wire cools, then straight into the rub.
    caption.value = const HWCaption('');
    _schedule(HWCopy.coolBridgeMs, _enterRubWire);
    notifyListeners();
  }

  void _enterRubWire() {
    // Animate the slider to 0 over 300 ms, then lock it (CURRENT chip reads 0,
    // dimmed slider, deliberately visible the whole beat).
    _sliderValue = 0;
    sliderEnabled.value = false;
    _rubReversals = 0;
    _rubDir = 0;
    _rubHeat = 0;
    secondary.value = null;
    phase.value = HeatWirePhase.rubWire;
    caption.value = HWCopy.b1RubTheWire;
    notifyListeners();
  }

  void _enterFrictionNamed() {
    phase.value = HeatWirePhase.frictionNamed;
    secondary.value = null;
    // capture the distractor at the rub gate (finger glow, CURRENT chip = 0).
    onCapture?.call('rubbed_warm');
    caption.value = HWCopy.b2RubbingHeatToo;
    _schedule(HWCopy.b2HoldMs, _enterRaiseAgain);
    notifyListeners();
  }

  void _enterRaiseAgain() {
    phase.value = HeatWirePhase.raiseAgain;
    sliderEnabled.value = true;
    _sustainAcc = 0;
    secondary.value = null;
    caption.value = HWCopy.c1RaiseAgain;
    notifyListeners();
  }

  void _enterLossMoment() {
    phase.value = HeatWirePhase.lossMoment;
    _sustainAcc = 0;
    _moteEmphasis = true; // motes ×1.6 + amplified pulse taper
    // The wire is already high + hot at the gate, so arm the relevant-tile capture
    // now; the tick fires it on the first frame that genuinely shows the streaming-
    // loss moment (current sustained high + wire hot) — never a cooling frame.
    _heatLeavesCaptureArmed = true;
    caption.value = HWCopy.c2WastedEnergy;
    _schedule(HWCopy.lossHoldMs, () {
      phase.value = HeatWirePhase.done;
      showContinue.value = true;
      notifyListeners();
    });
    notifyListeners();
  }

  // Called by the shell when Continue is tapped → the card earn overlay.
  void onContinue() {
    showCardEarn.value = true;
  }

  // ── Timer machinery (one one-shot at a time, matching the shipped pattern) ─
  double _step = -1; // ms remaining; <0 = idle
  void Function()? _stepAction;

  void _schedule(int ms, void Function() action) {
    _step = ms.toDouble();
    _stepAction = action;
  }

  void _tickSchedule(double dt) {
    if (_step < 0) return;
    _step -= dt * 1000;
    if (_step <= 0) {
      final a = _stepAction;
      _step = -1;
      _stepAction = null;
      a?.call();
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────
  static double _approach(double cur, double target, double dt, double tau) =>
      cur + (target - cur) * (1 - math.exp(-dt / tau));

  final math.Random _rng = math.Random();
  double _rngT() => _rng.nextDouble();

  @override
  void dispose() {
    phase.dispose();
    caption.dispose();
    secondary.dispose();
    sliderEnabled.dispose();
    showContinue.dispose();
    showCardEarn.dispose();
    currentDisplay.dispose();
    heatDisplay.dispose();
    currentTrend.dispose();
    heatTrend.dispose();
    super.dispose();
  }
}
