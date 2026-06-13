// AC vs DC — the activity controller (controller-owns-geometry). Owns the sim,
// the geometry, the phase machine, and the discrete UI channels; the Flame game
// reports the stage size once, forwards taps on the dock, and ticks the
// controller each frame. Every scene layer is a near-pure renderer reading these
// getters.
//
// THE HONEST ENGINE (the whole pedagogy lives here, hard-gated in tick):
//   currentLevel (−1..+1) → fieldLevel follows with lag τ ≈ 0.08 s →
//   fieldRate = |d(fieldLevel)/dt| → outputLevel = fieldRate>eps ? f(rate) : 0 →
//   bulbBrightness = fast attack from outputLevel, INSTANT release.
// • Steady DC: current pinned at +1 → field freezes → fieldRate ≈ 0 → DEAD.
//   The cutoff is a HARD GATE every frame, never a decay (true with reduced
//   motion ON too).
// • Each flip: a 120 ms current sweep +1↔−1 → the field collapses/rebuilds →
//   one output kick whose WIDTH equals the sweep width → the bulb blinks once,
//   then dies the instant the field settles.
// • The machine wave: current never stops reversing → fieldRate near-always
//   above eps → a steady-bright bulb (50 Hz flicker honestly fuses).
// The machine wave's amplitude == the battery's flat-line height (both 1.0), so
// the failure reads as changelessness, never as low strength.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Offset, Size;

import '../config/acdc_copy.dart';
import '../config/acdc_tuning.dart';

enum AcdcPhase {
  intro,
  connect,
  steadyDead,
  flipOnce,
  flipFast,
  handoff,
  alive,
  naming,
  synthesis,
  bridge,
  done,
}

/// What is sitting in the dock — the battery (learner flips it) or the machine
/// source (auto-reverses). [none] is the pre-connect grab-hint state.
enum DockOccupant { battery, machine }

class AcdcController extends ChangeNotifier {
  AcdcController();

  // --- Discrete UI channels (rebuild only on change) -------------------------
  final ValueNotifier<AcdcCaption> caption = ValueNotifier(AcdcCopy.introWaits);
  final ValueNotifier<AcdcPhase> phase = ValueNotifier(AcdcPhase.intro);
  final ValueNotifier<bool> showCardEarn = ValueNotifier(false);
  final ValueNotifier<bool> showContinue = ValueNotifier(false);

  // --- Polish hooks (haptics, set by the shell) ------------------------------
  void Function()? onFlip; // selectionClick per flip / connect
  void Function()? onDiscovery; // heavyImpact at lines 5, 10, 14
  void Function(String evidenceId)? onCapture; // lightImpact + snapshot in shell

  /// Reduced motion (MediaQuery.disableAnimations): calm motes + softer flash +
  /// shorter reveals — but the frozen field, the 50 ms cutoff, and the witnessed
  /// dead hold are pedagogical and are NEVER softened.
  bool reducedMotion = false;

  // --- Geometry (pixels = factors × stage size) ------------------------------
  Size _stage = Size.zero;
  Size get stageSize => _stage;
  void setStageSize(Size s) => _stage = s;

  Offset _f(Offset factor) => Offset(factor.dx * _stage.width, factor.dy * _stage.height);
  Offset get bulbCenter => _f(AcdcTune.bulbCenterFactor);
  Offset get outputFrom => _f(AcdcTune.outputFromFactor);
  Offset get outputTo => _f(AcdcTune.outputToFactor);
  Offset get coreCenter => _f(AcdcTune.coreCenterFactor);
  Offset get inputFrom => _f(AcdcTune.inputFromFactor);
  Offset get inputTo => _f(AcdcTune.inputToFactor);
  Offset get dockCenter => _f(AcdcTune.dockCenterFactor);
  Offset get graphCenter => _f(AcdcTune.graphCenterFactor);

  double get bulbRadius => AcdcTune.bulbRadiusFactor * _stage.width;
  double get coreOuterW => AcdcTune.coreOuterWFactor * _stage.width;
  double get coreOuterH => AcdcTune.coreOuterHFactor * _stage.height;
  double get limbThickness => AcdcTune.limbThicknessFactor * _stage.width;
  double get dockW => AcdcTune.dockWFactor * _stage.width;
  double get dockH => AcdcTune.dockHFactor * _stage.height;
  double get batteryW => AcdcTune.batteryWFactor * _stage.width;
  double get batteryH => AcdcTune.batteryHFactor * _stage.height;
  double get graphW => AcdcTune.graphWFactor * _stage.width;
  double get graphH => AcdcTune.graphHFactor * _stage.height;

  /// The battery (left of the dock centre) + the ON switch (right of it).
  Offset get batteryCenter => dockCenter.translate(AcdcTune.batteryDxFactor * _stage.width, 0);
  Offset get switchCenter => dockCenter.translate(AcdcTune.switchDxFactor * _stage.width, 0);
  double get switchW => AcdcTune.switchWFactor * _stage.width;
  double get switchH => AcdcTune.switchHFactor * _stage.height;
  bool get isConnected => _connected;

  /// The ON-switch hit rect — tap here to START (connect) the circuit.
  bool switchHit(Offset local) => _hit(local, switchCenter, AcdcTune.switchHitHalfWFactor);

  /// The battery hit rect — tap here to FLIP the battery's polarity.
  bool batteryHit(Offset local) => _hit(local, batteryCenter, AcdcTune.batteryHitHalfWFactor);

  bool _hit(Offset local, Offset center, double halfWFactor) {
    if (_stage.isEmpty) return false;
    return (local.dx - center.dx).abs() <= _stage.width * halfWFactor &&
        (local.dy - center.dy).abs() <= _stage.height * AcdcTune.dockHitHalfHFactor;
  }

  // --- Hot-path sim state (read by the renderer via getters) -----------------
  double _currentLevel = 0; // −1..+1 actual current
  double _fieldLevel = 0; // follows currentLevel with lag
  double _fieldRate = 0; // |d(fieldLevel)/dt|, normalised 0..1
  double _outputLevel = 0; // HARD GATE: fieldRate>eps ? f(rate) : 0
  double _bulbBrightness = 0; // fast attack, INSTANT release
  double _shimmer = 0; // free-running ambient clock

  // Battery flip animation + scripted current sweep.
  double _flipT = 1.0; // 0..1 battery 180° rotation (1 = settled)
  bool _flipping = false;
  int _flipDir = 1; // sign(currentLevel) the battery currently feeds: +1 / −1
  double _sweepT = 1.0; // 0..1 current-sweep progress (1 = settled)
  double _sweepFrom = 1.0, _sweepTo = 1.0;

  // Connection blip + DC field ramp (connect → steadyDead).
  bool _connected = false;
  double _connectRamp = 0; // 0..1 the field rises once over connectFieldRampSeconds

  // The machine wave (handoff → alive).
  double _wavePhase = 0; // radians
  double _waveHz = 0; // current oscillator frequency
  bool _machineLive = false; // the machine is reversing the current
  double _swapT = 0; // 0..1 battery-out / machine-in slide
  DockOccupant _occupant = DockOccupant.battery;

  // The graph ring buffer (currentLevel vs time) + its window/label.
  final List<double> _graph = List<double>.filled(AcdcTune.graphSamples, 0);
  int _graphHead = 0;
  double _graphAccum = 0;
  double _graphWindow = AcdcTune.graphWindowSeconds;
  double _labelReveal = 0; // the 50-label fade (alive)

  // Flash + dim + entrance reveals.
  double _flashIntensity = 0;
  double _sceneDim = 0;
  double _entranceT = 0; // 0..1 overall entrance progress driver

  // The glorious spring-to-life envelope (0..1) — a fast attack to 1 at the
  // alive-phase flash, then a decay back to 0 over aliveFlashSeconds. The bulb's
  // overshoot rides it; it is the ONLY moment the bulb may outshine the core.
  double _aliveSpring = 0;
  bool _springActive = false;
  double _springElapsed = 0;

  // Flip bookkeeping (burst detection).
  int _flipCount = 0;
  final List<double> _flipTimestamps = [];

  // --- Read-only getters for the renderer ------------------------------------
  double get currentLevel => _currentLevel;
  double get fieldLevel => _fieldLevel;
  double get fieldRate => _fieldRate;
  double get outputLevel => _outputLevel;
  double get bulbBrightness => _bulbBrightness;

  /// The bulb's DISPLAYED brightness — the hard-gated [bulbBrightness], plus a
  /// brief overshoot at the spring-to-life so the bulb FLOODS past full for the
  /// one ≤1200 ms moment it may outshine the core. The overshoot rides
  /// [aliveSpring] (which is non-zero only in the alive flash window), so the
  /// instant-release cutoff on the underlying [bulbBrightness] is untouched.
  double get bulbBrightnessDisplay =>
      (_bulbBrightness * (1 + (AcdcTune.aliveBulbOvershoot - 1) * _aliveSpring))
          .clamp(0.0, 1.4);

  /// 0..1 spring-to-life intensity — the glorious "field bursts alive" flash.
  /// Non-zero ONLY across the alive-phase spring (drives the bulb overshoot and
  /// lets the core/bulb know the bulb may briefly outshine it). Everywhere else 0.
  double get aliveSpring => _aliveSpring;

  double get shimmer => _shimmer;
  double get flipT => _flipT;
  double get flipDir => _flipDir.toDouble();
  double get swapT => _swapT;
  double get flashIntensity => _flashIntensity;
  double get sceneDim => _sceneDim;
  double get labelReveal => _labelReveal;
  double get graphWindow => _graphWindow;
  bool get machineLive => _machineLive;
  DockOccupant get occupant => _occupant;
  AcdcPhase get currentPhase => phase.value;

  /// The 8 fixed secondary / 4 fixed primary loops (the held constant).
  int get primaryTurns => AcdcTune.primaryTurns;
  int get secondaryTurns => AcdcTune.secondaryTurns;

  /// Entrance reveals (staggered like the_transformer): core 0, coils +0.15,
  /// bulb +0.30, dock + graph +0.45.
  double get coreReveal => _reveal(0.00);
  double get coilReveal => _reveal(0.15);
  double get bulbReveal => _reveal(0.30);
  double get dockReveal => _reveal(0.45);
  double _reveal(double delay) =>
      ((_entranceT - delay) / (1.0 - delay)).clamp(0.0, 1.0);

  /// Show the dock grab hint until the learner connects.
  bool get grabHintActive => phase.value == AcdcPhase.connect && !_connected;

  /// The graph trace as a list of samples oldest→newest, for the strip chart.
  List<double> graphSamplesOrdered() {
    final out = List<double>.filled(AcdcTune.graphSamples, 0);
    for (var i = 0; i < AcdcTune.graphSamples; i++) {
      out[i] = _graph[(_graphHead + i) % AcdcTune.graphSamples];
    }
    return out;
  }

  /// True only in alive/naming/synthesis/bridge/done (the 50-label may show).
  bool get hzLabelVisible => _labelReveal > 0.01;

  // --- Input (Flutter Listener forwards): a tap inside the dock rect ---------
  void onTapDown(Offset local) {
    if (_stage.isEmpty) return;
    final ph = phase.value;
    if (ph == AcdcPhase.connect) {
      if (switchHit(local)) _connect(); // the ON switch starts the circuit
    } else if ((ph == AcdcPhase.flipOnce || ph == AcdcPhase.flipFast) &&
        _occupant == DockOccupant.battery) {
      if (batteryHit(local)) _flip(); // tap the battery to flip its polarity
    }
    // Everywhere else the dock is inert.
  }

  void _connect() {
    if (_connected) return;
    _connected = true;
    onFlip?.call(); // selectionClick — the battery clicks into the terminals
    _currentLevel = AcdcTune.currentAmplitude; // steady +1 one-way DC
    _flipDir = 1;
    _connectRamp = 0; // field will rise once over the ramp, then freeze
    _enterSteadyDead();
    notifyListeners();
  }

  void _flip() {
    if (_flipT < AcdcTune.flipReentryT) return; // reject mid-flip taps
    _flipping = true;
    _flipT = 0;
    _flipDir = -_flipDir;
    // Scripted current sweep across the flip: +1 → −1 (or back).
    _sweepFrom = _currentLevel;
    _sweepTo = AcdcTune.currentAmplitude * _flipDir;
    _sweepT = 0;
    onFlip?.call(); // selectionClick per flip

    _flipCount++;
    _flipTimestamps.add(_shimmer);

    if (phase.value == AcdcPhase.flipOnce) {
      // The first flip's kick dies → line 7 → hold → flipFast.
      if (_flipCount == 1) {
        _schedule(AcdcTune.flipOnceLine7DelayMs, () {
          if (phase.value != AcdcPhase.flipOnce) return;
          caption.value = AcdcCopy.flipWakes;
          _schedule(AcdcTune.flipOnceHoldMs, _enterFlipFast);
        });
      }
    } else if (phase.value == AcdcPhase.flipFast) {
      _evaluateFlipGate();
    }
    notifyListeners();
  }

  /// During flipFast: a fast run (≥2 flips within 0.9 s) shows the feedback line;
  /// the gate (≥5 total AND a burst of ≥3 within 1.2 s) advances to handoff.
  bool _lawFired = false;
  void _evaluateFlipGate() {
    // The echo law gate (the fast-run feedback line was cut).
    final burst = _flipTimestamps
        .where((t) => _shimmer - t <= AcdcTune.flipBurstWindow)
        .length;
    if (!_lawFired &&
        _flipCount >= AcdcTune.flipGateTotal &&
        burst >= AcdcTune.flipBurstCount) {
      _lawFired = true;
      caption.value = AcdcCopy.onlyChanging;
      onDiscovery?.call(); // heavyImpact (line 10)
      _schedule(AcdcTune.flipFastLawHoldMs, _enterHandoff);
    }
  }

  // --- Lifecycle / phase entry ----------------------------------------------
  bool _started = false;
  void start() {
    if (_started) return;
    _started = true;
    phase.value = AcdcPhase.intro;
    caption.value = AcdcCopy.introWaits; // a silent entrance reveal → connect
    _schedule(AcdcTune.introMs, _enterConnect);
    notifyListeners();
  }

  void _enterConnect() {
    phase.value = AcdcPhase.connect;
    caption.value = AcdcCopy.connect;
    notifyListeners();
  }

  void _enterSteadyDead() {
    phase.value = AcdcPhase.steadyDead;
    caption.value = AcdcCopy.introWaits; // witnessed absence: NO text first
    // ~2800 ms of stillness → the dead verdict (heavyImpact + a scene-dim underline,
    // NO capture: the shared EP2 catalog dropped dc_dead_transformer) → flipOnce.
    _schedule(AcdcTune.steadyHoldMs, () {
      if (phase.value != AcdcPhase.steadyDead) return;
      caption.value = AcdcCopy.steadyDead;
      onDiscovery?.call(); // heavyImpact
      _startFlash(0.5); // a slight scene-dim underline, not a bright bloom
      _schedule(AcdcTune.steadyExitMs, _enterFlipOnce);
    });
    notifyListeners();
  }

  void _enterFlipOnce() {
    phase.value = AcdcPhase.flipOnce;
    caption.value = AcdcCopy.flip;
    _flipCount = 0;
    _flipTimestamps.clear();
    notifyListeners();
  }

  void _enterFlipFast() {
    phase.value = AcdcPhase.flipFast;
    caption.value = AcdcCopy.flipFast;
    _lawFired = false;
    // Keep the running flip history so a fast burst right after the prompt counts.
    notifyListeners();
  }

  void _enterHandoff() {
    phase.value = AcdcPhase.handoff;
    caption.value = AcdcCopy.introWaits; // silent while the hand hands off to the machine
    _schedule(AcdcTune.handoffSwapStartMs, () {
      _swapT = 0.0001; // start the battery-out / machine-in slide (advanced in tick)
    });
    _schedule(AcdcTune.handoffLine12Ms, () => caption.value = AcdcCopy.reversesItself);
    _schedule(AcdcTune.handoffMs, _enterAlive);
    notifyListeners();
  }

  void _enterAlive() {
    phase.value = AcdcPhase.alive;
    caption.value = AcdcCopy.introWaits;
    _machineLive = true; // ensure the wave is fully running
    // 1200 ms: flash + heavyImpact + CAPTURE (ac_springs_alive) + line 14.
    _schedule(AcdcTune.aliveFlashMs, () {
      _startFlash(1.0);
      _startSpring(); // the glorious bulb-floods-to-full burst (≤1200 ms)
      onDiscovery?.call(); // heavyImpact (line 14)
      onCapture?.call('ac_springs_alive'); // the ONE capture for this beat
      caption.value = AcdcCopy.fullyAlive;
    });
    // 3800 ms: the 50-label fades onto the graph + line 15.
    _schedule(AcdcTune.aliveLabelMs, () => caption.value = AcdcCopy.fiftyCycles);
    _schedule(AcdcTune.aliveMs, _enterNaming);
    notifyListeners();
  }

  void _enterNaming() {
    phase.value = AcdcPhase.naming;
    caption.value = AcdcCopy.naming; // "Steady is DC. Reversing is AC." — both names, one line
    _schedule(AcdcTune.namingMs, _enterSynthesis);
    notifyListeners();
  }

  void _enterSynthesis() {
    phase.value = AcdcPhase.synthesis;
    caption.value = AcdcCopy.synthesis;
    _schedule(AcdcTune.synthesisMs, _enterBridge);
    notifyListeners();
  }

  void _enterBridge() {
    phase.value = AcdcPhase.bridge;
    // No bridge line (cut) — the synthesis rule stays showing + the scene dims into
    // the card earn.
    _schedule(AcdcTune.bridgeMs, () {
      phase.value = AcdcPhase.done;
      showCardEarn.value = true;
      notifyListeners();
    });
    notifyListeners();
  }

  void onCardCollected() {
    showCardEarn.value = false;
    caption.value = AcdcCopy.synthesis; // the rule persists behind Continue
    showContinue.value = true;
    notifyListeners();
  }

  // --- Timers (independent, cancel-on-dispose) -------------------------------
  final List<_Timer> _timers = [];
  void _schedule(int ms, void Function() action) =>
      _timers.add(_Timer(ms.toDouble(), action));

  // --- Flash envelope --------------------------------------------------------
  bool _flashActive = false;
  double _flashElapsed = 0;
  double _flashPeak = 1.0;
  static const double _flashSeconds = 0.7;
  void _startFlash(double peak) {
    _flashActive = true;
    _flashElapsed = 0;
    _flashPeak = reducedMotion ? peak * 0.45 : peak;
  }

  /// Kick the spring-to-life envelope — a fast burst to full then a decay over
  /// aliveFlashSeconds. Reduced motion softens the overshoot but keeps the
  /// spring (the spring-to-life is the payoff, not gratuitous motion).
  void _startSpring() {
    _springActive = true;
    _springElapsed = 0;
  }

  static double _approach(double cur, double target, double dt, double tau) =>
      cur + (target - cur) * (1 - math.exp(-dt / tau));

  // --- The tick: sim + the silent step machine -------------------------------
  void tick(double dt) {
    if (dt <= 0) return;
    _shimmer += dt;
    final ph = phase.value;

    // Entrance progress (intro reveals).
    final entSpeed = reducedMotion ? 3.2 : 1.9;
    _entranceT = (_entranceT + dt * entSpeed).clamp(0.0, 1.0);

    // 1) Drive currentLevel per phase ----------------------------------------
    _driveCurrent(dt, ph);

    // 2) fieldLevel follows currentLevel with lag (the honest coupling) -------
    final prevField = _fieldLevel;
    _fieldLevel = _approach(_fieldLevel, _currentLevel, dt, AcdcTune.fieldTau);
    // During the one-time connect ramp, the field rises once then is held — its
    // rate decays to ~0 (the freeze). The ramp is purely a visual gate on the
    // first rise; after it completes the field simply tracks the steady current,
    // so |d/dt| → 0 naturally (the dead state).
    final dField = _fieldLevel - prevField;
    final rate = (dField.abs() / dt);
    _fieldRate = (rate / AcdcTune.fieldRateNorm).clamp(0.0, 1.0);

    // 3) HARD GATE: output is alive only while the field is changing ----------
    _outputLevel = _fieldRate > AcdcTune.fieldRateEps ? _fieldRate : 0.0;

    // 4) Bulb: fast attack, INSTANT release (≤2% within ~50 ms) --------------
    final target = _outputLevel;
    final tau = target > _bulbBrightness ? AcdcTune.bulbAttackTau : AcdcTune.bulbReleaseTau;
    _bulbBrightness = _approach(_bulbBrightness, target, dt, tau);
    if (_bulbBrightness < 0.02 && target <= 0.0) _bulbBrightness = 0.0; // snap clean

    // 5) Graph ring buffer (samples currentLevel into the window) ------------
    _graphWindow = _approach(_graphWindow,
        ph == AcdcPhase.alive || ph.index > AcdcPhase.alive.index
            ? AcdcTune.graphAliveWindowSeconds
            : AcdcTune.graphWindowSeconds,
        dt, 0.5);
    final samplePeriod = _graphWindow / AcdcTune.graphSamples;
    _graphAccum += dt;
    while (_graphAccum >= samplePeriod) {
      _graphAccum -= samplePeriod;
      // Write the newest sample at head, then advance — head marks the OLDEST.
      _graph[_graphHead] = _currentLevel;
      _graphHead = (_graphHead + 1) % AcdcTune.graphSamples;
    }

    // 6) The 50-label reveal (only from alive's label beat on) ---------------
    final labelTarget = (ph == AcdcPhase.alive && caption.value.sameAs(AcdcCopy.fiftyCycles)) ||
            ph == AcdcPhase.naming ||
            ph == AcdcPhase.synthesis ||
            ph == AcdcPhase.bridge ||
            ph == AcdcPhase.done
        ? 1.0
        : 0.0;
    _labelReveal = _approach(_labelReveal, labelTarget, dt,
        reducedMotion ? 0.12 : AcdcTune.aliveLabelFadeMs / 1000);

    // 7) Battery flip + machine swap animations ------------------------------
    if (_flipping) {
      _flipT = (_flipT + dt / AcdcTune.flipAnimSeconds).clamp(0.0, 1.0);
      if (_flipT >= 1.0) _flipping = false;
    }
    if (_sweepT < 1.0) {
      _sweepT = (_sweepT + dt / AcdcTune.currentSweepSeconds).clamp(0.0, 1.0);
    }
    if (_swapT > 0 && _swapT < 1.0) {
      _swapT = (_swapT + dt * 1000 / AcdcTune.handoffSwapMs).clamp(0.0, 1.0);
      if (_swapT >= 0.5 && _occupant == DockOccupant.battery) {
        _occupant = DockOccupant.machine; // half-way: the machine has arrived
        _machineLive = true;
      }
    }

    // 8) Scene dim — steadyDead/connect underline the absence; bridge calms ---
    final dimTarget = ph == AcdcPhase.steadyDead
        ? 0.22
        : (ph == AcdcPhase.bridge || ph == AcdcPhase.done ? 0.16 : 0.0);
    _sceneDim = _approach(_sceneDim, dimTarget, dt, 0.45);

    // 9) Flash envelope -------------------------------------------------------
    if (_flashActive) {
      _flashElapsed += dt;
      final t = (_flashElapsed / _flashSeconds).clamp(0.0, 1.0);
      _flashIntensity = (t < 0.15 ? t / 0.15 : 1.0 - (t - 0.15) / 0.85) * _flashPeak;
      if (_flashElapsed >= _flashSeconds) {
        _flashActive = false;
        _flashIntensity = 0;
      }
    }

    // 9b) The spring-to-life envelope — a fast burst to 1 then a decay to 0 over
    //     aliveFlashSeconds (≤1200 ms). Reduced motion damps the overshoot peak.
    if (_springActive) {
      _springElapsed += dt;
      final t = (_springElapsed / AcdcTune.aliveFlashSeconds).clamp(0.0, 1.0);
      final shape = t < 0.12 ? t / 0.12 : 1.0 - (t - 0.12) / 0.88; // fast attack, ease out
      _aliveSpring = shape.clamp(0.0, 1.0) * (reducedMotion ? 0.45 : 1.0);
      if (_springElapsed >= AcdcTune.aliveFlashSeconds) {
        _springActive = false;
        _aliveSpring = 0;
      }
    }

    // 10) Drive the timers (dt in ms). A fired timer may schedule more. -------
    if (_timers.isNotEmpty) {
      final due = <_Timer>[];
      for (final t in _timers) {
        t.remaining -= dt * 1000;
        if (t.remaining <= 0) due.add(t);
      }
      if (due.isNotEmpty) {
        _timers.removeWhere(due.contains);
        for (final t in due) {
          t.action();
        }
      }
    }

    notifyListeners();
  }

  /// Set currentLevel from the active source for this phase.
  void _driveCurrent(double dt, AcdcPhase ph) {
    // The machine wave (handoff once the swap is live, and alive onward).
    if (_machineLive) {
      // Ramp the oscillator frequency: slow at handoff, full speed in alive.
      final targetHz = ph == AcdcPhase.handoff ? AcdcTune.waveStartHz : AcdcTune.waveFullHz;
      _waveHz = _approach(_waveHz, targetHz, dt, AcdcTune.waveRampSeconds);
      _wavePhase += dt * _waveHz * 2 * math.pi;
      _currentLevel = AcdcTune.currentAmplitude * math.sin(_wavePhase);
      return;
    }

    // The battery: a steady DC level, or a scripted sweep during a flip.
    if (_connected) {
      if (_sweepT < 1.0) {
        // Smooth 120 ms sweep between +1 and −1 (the reversal).
        final e = _easeInOut(_sweepT);
        _currentLevel = _sweepFrom + (_sweepTo - _sweepFrom) * e;
      } else if (_connectRamp < 1.0) {
        // The one-time connection rise — the steady DC current ramps up ONCE
        // over connectFieldRampSeconds (so the field visibly rises once, induces
        // a single faint blip, §13.1), then holds flat and freezes. After this
        // there is no further change → the field is frozen → the bulb is dark.
        _connectRamp = (_connectRamp + dt / AcdcTune.connectFieldRampSeconds).clamp(0.0, 1.0);
        _currentLevel = AcdcTune.currentAmplitude * _flipDir * _easeInOut(_connectRamp);
      } else {
        _currentLevel = AcdcTune.currentAmplitude * _flipDir;
      }
    } else {
      _currentLevel = 0;
    }
  }

  double get connectRamp => _connectRamp;

  static double _easeInOut(double t) =>
      t < 0.5 ? 2 * t * t : 1 - math.pow(-2 * t + 2, 2).toDouble() / 2;

  @override
  void dispose() {
    caption.dispose();
    phase.dispose();
    showCardEarn.dispose();
    showContinue.dispose();
    _timers.clear();
    super.dispose();
  }
}

class _Timer {
  _Timer(this.remaining, this.action);
  double remaining;
  final void Function() action;
}
