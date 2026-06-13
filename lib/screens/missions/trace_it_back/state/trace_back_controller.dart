// Trace It Back — the activity controller. Owns the geometry AND the physics
// (controller-owns-geometry): the Flame game reports the stage size once and
// forwards the in-stage turning gesture; the controller computes the magnet's
// (b1) / turbine's (b2) spin, the energy/brightness, the discovery transition, and
// drives a SILENT step machine — no Voltix, no dialogue, no VO. Guidance is a short
// instruction caption at the top; Beat 3 walks the kid through the power sources
// ONE BY ONE (no selector). The game is a near-pure renderer.
//
// THE LOAD-BEARING RULE: the instant the kid stops turning (magnet in b1, turbine
// in b2), brightness / current-pulse / field-line bloom are HARD-GATED to zero the
// same frame — no fade. In b3 the source drives the turning continuously → steadily
// lit; the cutoff is only ever about the KID's input stopping.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Offset, Size;

import '../config/source_defs.dart';
import '../config/trace_back_beats.dart';
import '../config/trace_back_tuning.dart';
import '../engine/trace_back_bot_engine.dart';

class TraceBackController extends ChangeNotifier {
  TraceBackController();

  // --- Discrete UI channels (rebuild only on change) -------------------------
  /// The big top caption — an imperative ("Spin the Magnet") or a meaning-line
  /// ("Only a Moving Magnet Works"); the [TBCaption.meaning] flag drives the style.
  final ValueNotifier<TBCaption> caption = ValueNotifier(const TBCaption(''));

  /// A small secondary line under the caption (solar's optional depth-stop hook).
  final ValueNotifier<String> secondary = ValueNotifier('');

  final ValueNotifier<TBPhase> phase = ValueNotifier(TBPhase.intro);
  final ValueNotifier<EnergySource?> activeSource = ValueNotifier(null);

  /// The "Next →" button is live (Beat 3 — step through the sources).
  final ValueNotifier<bool> showNext = ValueNotifier(false);

  final ValueNotifier<bool> showCardEarn = ValueNotifier(false);
  final ValueNotifier<bool> canFinish = ValueNotifier(false);

  // --- Polish hooks (haptics) ------------------------------------------------
  void Function()? onCrankTick; // a light haptic per quarter-turn while turning
  void Function(bool generating)? onGeneratingChanged;
  void Function()? onDiscovery; // the still→dark beat (b1) — flash + dim
  void Function()? onSourceStep; // a light haptic on the Next button (b3)

  /// Episode-board capture hook (PRD §8): fired at each felt DISCOVERY beat with
  /// the evidence-tile id to auto-capture. Act 2 contributes the convergence
  /// ('same_magnet', snapped on the NUCLEAR source step where its full chain is on
  /// screen) plus the two true-but-irrelevant distractors the kid really witnesses
  /// here ('still_magnet', 'turbine_spin'). The shell persists + pins it.
  void Function(String evidenceId)? onCapture;

  /// Reduced motion (MediaQuery.disableAnimations): static current-pulse + calm
  /// particles. The still-magnet INSTANT CUTOFF is never softened.
  bool reducedMotion = false;

  // --- Geometry (pixels = factors × stage size) ------------------------------
  Size _stage = Size.zero;
  Size get stageSize => _stage;
  void setStageSize(Size s) => _stage = s;

  Offset _f(Offset factor) => Offset(factor.dx * _stage.width, factor.dy * _stage.height);
  Offset get bulbCenter => _f(TBTune.bulbFactor);
  Offset get magnetCenter => _f(TBTune.magnetFactor);
  Offset get turbineCenter => _f(TBTune.turbineFactor);
  Offset get sourceCenter => _f(TBTune.sourceFactor);
  // Connectors are ANCHORED to the actual components (not free factors) so they
  // always join cleanly: the wire runs bulb-base → coil-top; the shaft runs into
  // the coil bottom and into the turbine hub (both ends overlap their component,
  // which draws on top → the join reads solid).
  Offset get wireStart => Offset(bulbCenter.dx, bulbCenter.dy + bulbRadius * 1.35);
  Offset get wireEnd => Offset(magnetCenter.dx, magnetCenter.dy - coilRadius * 0.82);
  Offset get shaftStart => Offset(magnetCenter.dx, magnetCenter.dy + coilRadius * 0.72);
  Offset get shaftEnd => Offset(turbineCenter.dx, turbineCenter.dy - turbineRadius * 0.18);
  Offset get flowStart => _f(TBTune.flowStartFactor);
  Offset get flowEnd => _f(TBTune.flowEndFactor);
  double get bulbRadius => TBTune.bulbRadiusFactor * _stage.width;
  double get coilRadius => TBTune.coilRadiusFactor * _stage.width;
  double get magnetLength => TBTune.magnetLenFactor * _stage.width;
  double get turbineRadius => TBTune.turbineRadiusFactor * _stage.width;
  double get sourceRadius => TBTune.sourceRadiusFactor * _stage.width;

  /// The active turning grab-point: the magnet (b1) or the turbine (b2).
  Offset get grabCenter => phase.value == TBPhase.turbine ? turbineCenter : magnetCenter;
  bool get grabIsTurbine => phase.value == TBPhase.turbine;

  // --- Presence (the chain grows downward as the beats progress) -------------
  bool _turbinePresent = false; // b2 onward
  bool _sourcePresent = false; // b3 onward
  bool get turbinePresent => _turbinePresent;
  bool get shaftPresent => _turbinePresent; // shaft links magnet↔turbine
  bool get sourcePresent => _sourcePresent;

  // --- Physics state (hot path — read via getters) ---------------------------
  bool _grabDown = false;
  double _lastAngle = 0;
  double _frameAngleDelta = 0;
  bool _sampleThisFrame = false;
  double _sampleElapsed = 0;
  double _hapticAccum = 0;
  double _angularVelocity = 0; // signed rad/s (the in-stage gesture)
  double _shimmer = 0;

  // Premium motion: per-component entrance reveals + the b3 source surge.
  double _currentAV = 0;
  double _bulbReveal = 0;
  double _coilReveal = 0;
  double _turbineReveal = 0;
  double _sourceReveal = 0;
  double _handoffRamp = 0; // 0→1 when the source takes over: the bulb surges
  double _coreFade = 1; // 1 = magnet/coil/turbine/shaft present; 0 = solar bypass

  double _brightness = 0;
  double _energyInput = 0;
  bool _isGenerating = false;
  double _magnetAngle = 0;
  double _turbineAngle = 0;
  double _fieldBloom = 0;
  double _pulsePhase = 0;

  // Step-machine bookkeeping.
  bool _hasLitOnce = false; // b1 first light
  bool _hasStoppedOnce = false; // b1 discovery (stop after lit)
  bool _b2LitOnce = false; // b2 first light
  bool _touchedMagnet = false;
  bool _touchedTurbine = false;
  int _sourceIndex = 0; // b3 walkthrough position
  bool _sameMagnetCaptured = false; // the convergence photo — pinned once, on nuclear
  double _step = -1; // ms countdown for the next auto-transition
  void Function()? _stepAction;
  bool _started = false;

  // Discovery flash envelope.
  bool _flashActive = false;
  double _flashElapsed = 0;

  // --- Read-only getters for the renderer ------------------------------------
  double get brightness => _brightness;
  double get energyInput => _energyInput;
  bool get isGenerating => _isGenerating;
  double get angularVelocity => _angularVelocity;
  double get magnetAngle => _magnetAngle;
  double get turbineAngle => _turbineAngle;
  double get shaftRotation => _turbineAngle;
  double get fieldBloom => _fieldBloom;
  double get pulsePhase => _pulsePhase;
  double get shimmer => _shimmer;
  TBPhase get currentPhase => phase.value;

  double get spinNorm => (_currentAV.abs() / TBTune.maxSpeed).clamp(0.0, 1.0);
  double get bulbReveal => _bulbReveal;
  double get coilReveal => _coilReveal;
  double get turbineReveal => _turbineReveal;
  double get sourceReveal => _sourceReveal;
  double get handoffRamp => _handoffRamp;
  double get coreFade => _coreFade;

  double get discoveryDim {
    if (!_flashActive) return 0;
    final t = (_flashElapsed / TBTune.discoveryFlashSeconds).clamp(0.0, 1.0);
    final env = t < 0.2 ? t / 0.2 : 1 - (t - 0.2) / 0.8;
    return (env * 0.32).clamp(0.0, 0.32);
  }

  SourceDef? get activeSourceDef =>
      activeSource.value == null ? null : sourceDef(activeSource.value!);

  bool get magnetInChain {
    final d = activeSourceDef;
    return d == null || d.usesMagnet;
  }

  bool get turbineInChain {
    if (!_turbinePresent) return false;
    final d = activeSourceDef;
    return d == null || d.spinsTurbine;
  }

  bool get grabHintActive {
    if (phase.value == TBPhase.magnet) return !_touchedMagnet;
    if (phase.value == TBPhase.turbine) return !_touchedTurbine;
    return false;
  }

  double get flashIntensity {
    if (!_flashActive) return 0;
    final t = (_flashElapsed / TBTune.discoveryFlashSeconds).clamp(0.0, 1.0);
    return t < 0.15 ? t / 0.15 : 1.0 - (t - 0.15) / 0.85;
  }

  // --- Lifecycle -------------------------------------------------------------
  void start() {
    if (_started) return;
    _started = true;
    phase.value = TBPhase.magnet;
    caption.value = TBCopy.spinMagnet;
    notifyListeners();
  }

  // --- In-stage turning gesture (angle relative to the active grab-point) -----
  void onPointerDown(Offset local) {
    final ph = phase.value;
    if (ph != TBPhase.magnet && ph != TBPhase.turbine) return;
    _grabDown = true;
    _lastAngle = _angleTo(local);
    _frameAngleDelta = 0;
    _sampleThisFrame = false;
    _sampleElapsed = 0;
    if (ph == TBPhase.magnet) _touchedMagnet = true;
    if (ph == TBPhase.turbine) _touchedTurbine = true;
  }

  void onPointerMove(Offset local) {
    if (!_grabDown) return;
    final a = _angleTo(local);
    final delta = _unwrap(a - _lastAngle);
    _lastAngle = a;
    _frameAngleDelta += delta;
    _hapticAccum += delta.abs();
    _sampleThisFrame = true;
  }

  void onPointerUp() {
    _grabDown = false;
    _angularVelocity = 0;
    _frameAngleDelta = 0;
    _sampleThisFrame = false;
  }

  double _angleTo(Offset local) {
    final g = grabCenter;
    return math.atan2(local.dy - g.dy, local.dx - g.dx);
  }

  static double _unwrap(double d) {
    while (d > math.pi) {
      d -= 2 * math.pi;
    }
    while (d <= -math.pi) {
      d += 2 * math.pi;
    }
    return d;
  }

  static double _approach(double cur, double target, double dt, double tau) =>
      cur + (target - cur) * (1 - math.exp(-dt / tau));

  // --- Step transitions ------------------------------------------------------
  void _schedule(int ms, void Function() action) {
    _step = ms.toDouble();
    _stepAction = action;
  }

  void _enterTurbine() {
    phase.value = TBPhase.turbine;
    _turbinePresent = true; // turbine clips on below the magnet
    caption.value = TBCopy.turnTurbine;
    notifyListeners();
  }

  void _enterSource() {
    phase.value = TBPhase.source;
    _sourceIndex = 0;
    activeSource.value = kSourceOrder[0];
    _sourcePresent = true;
    _handoffRamp = 0; // the source takes over → surge the bulb to life
    showNext.value = false;
    secondary.value = '';
    caption.value = TBCopy.handoff; // one-time meaning-line, then the beats
    _schedule(TBCopy.handoffToSourceMs, _showSourceBeats);
    notifyListeners();
  }

  /// Show the current source's TWO converging beats: beat 1 now, beat 2 after a
  /// reading gap; the Next button arrives with beat 2 (so both lines are read).
  void _showSourceBeats() {
    final s = kSourceOrder[_sourceIndex];
    final beats = TBCopy.sourceBeats(s);
    caption.value = beats.$1; // input (varies)
    secondary.value = '';
    showNext.value = false;
    _schedule(TBCopy.beat1To2Ms, () {
      caption.value = beats.$2; // result (converges on the spin word)
      if (s == EnergySource.solar) secondary.value = TBCopy.solarHook;
      showNext.value = true;
      // The convergence photo ('same_magnet') is snapped HERE — while nuclear's
      // full chain is steady + lit and the "spins the magnet" line is on screen,
      // so what the kid sees matches the pinned frame. Fires once. (showNext is
      // false until now, so the kid can't skip past before this lands.)
      if (s == EnergySource.nuclear && !_sameMagnetCaptured) {
        _sameMagnetCaptured = true;
        onCapture?.call('same_magnet');
      }
      notifyListeners();
    });
    notifyListeners();
  }

  /// The "Next →" button — walk to the next source, or (after the last) close on
  /// the running core and fire the card.
  void nextSource() {
    if (phase.value != TBPhase.source) return;
    onSourceStep?.call();
    if (_sourceIndex < kSourceOrder.length - 1) {
      _sourceIndex++;
      activeSource.value = kSourceOrder[_sourceIndex];
      _showSourceBeats();
    } else {
      showNext.value = false;
      secondary.value = '';
      phase.value = TBPhase.closing;
      activeSource.value = EnergySource.coal; // close on the running core (not solar)
      caption.value = TBCopy.synthesis; // name-last: "Almost Everything Spins a Magnet"
      // ('same_magnet' was already snapped on the nuclear step — see _showSourceBeats.)
      _schedule(TBCopy.synthesisToCardMs, () => showCardEarn.value = true);
    }
    notifyListeners();
  }

  void onCardCollected() {
    showCardEarn.value = false;
    caption.value = const TBCaption('');
    secondary.value = '';
    canFinish.value = true;
    notifyListeners();
  }

  // --- The effective drive (where the turning comes from per beat) ------------
  double _effectiveAV() {
    switch (phase.value) {
      case TBPhase.magnet:
      case TBPhase.turbine:
        return _angularVelocity; // the kid turns it
      case TBPhase.source:
      case TBPhase.closing: // keep the chain running through the close
        final d = activeSourceDef;
        if (d == null || !d.spinsTurbine) return 0; // solar bypasses the turbine
        return TBTune.sourceDriveAV * _handoffRamp;
      default:
        return 0;
    }
  }

  double _targetEnergy() {
    final d = activeSourceDef;
    if (d != null && d.isSolar) {
      return (TBTune.solarBaseEnergy * (0.94 + 0.06 * math.sin(_shimmer * 3)) * _handoffRamp)
          .clamp(0.0, 1.0);
    }
    return TBTune.normalizeEnergy(_effectiveAV());
  }

  // --- The tick: physics + the silent step machine ---------------------------
  void tick(double dt) {
    if (dt <= 0) return;
    _shimmer += dt;
    final ph = phase.value;
    final turning = ph == TBPhase.magnet || ph == TBPhase.turbine;

    // 1) Resolve the gesture's signed angular velocity (b1/b2 turning).
    if (turning) {
      if (_sampleThisFrame) {
        _angularVelocity = _frameAngleDelta / dt;
        _frameAngleDelta = 0;
        _sampleThisFrame = false;
        _sampleElapsed = 0;
      } else {
        _sampleElapsed += dt;
        if (!_grabDown || _sampleElapsed >= TBTune.sampleTimeoutSeconds) {
          _angularVelocity = 0;
        }
      }
    }

    // 2) Energy + generating (motion-gated in b1/b2; source-driven in b3).
    final av = _effectiveAV();
    _currentAV = av;
    _energyInput = _targetEnergy();
    final wasGenerating = _isGenerating;
    _isGenerating = _energyInput > 0;

    // 3) Brightness — ripple-smoothed WHILE generating, HARD-GATED to 0 on stop.
    if (_isGenerating) {
      final target = TBTune.brightnessCurve(_energyInput);
      final alpha = 1 - math.exp(-dt / TBTune.rippleTau);
      _brightness += (target - _brightness) * alpha;
    } else {
      _brightness = TBTune.stopBrightness;
    }

    // 4) Magnet + turbine rotation (FREEZE on stop — no spin-down).
    if (_isGenerating && magnetInChain) _magnetAngle += av * dt;
    if (_isGenerating && turbineInChain) _turbineAngle += av * dt;

    // 5) Field-line bloom — only while the magnet MOVES; vanishes instantly.
    if (_isGenerating && magnetInChain) {
      final target = (av.abs() / TBTune.maxSpeed * 1.3).clamp(0.0, 1.0);
      final alpha = 1 - math.exp(-dt / TBTune.rippleTau);
      _fieldBloom += (target - _fieldBloom) * alpha;
    } else {
      _fieldBloom = 0;
    }

    // 6) Wire pulse — advances only while generating.
    if (_isGenerating) {
      _pulsePhase = (_pulsePhase + dt * TBTune.pulseSpeed) % 1.0;
    } else {
      _pulsePhase = 0;
    }

    // 7) Beat 1 — imperatives, first light, then the discovery → meaning-lines
    //    (the rule, named after they feel it) → the depth-stop.
    if (ph == TBPhase.magnet && !_hasStoppedOnce) {
      if (!_hasLitOnce) {
        final want = _isGenerating ? TBCopy.fasterBrighter : TBCopy.spinMagnet;
        if (caption.value.text != want.text) caption.value = want;
        if (_brightness >= TBTune.clearlyLitThreshold) {
          _hasLitOnce = true;
          _schedule(TBCopy.litToHoldMs, () {
            if (phase.value == TBPhase.magnet && !_hasStoppedOnce) caption.value = TBCopy.holdStill;
          });
        }
      }
      if (wasGenerating && !_isGenerating && _hasLitOnce) {
        _hasStoppedOnce = true;
        _startDiscoveryFlash(); // fires onDiscovery
        onCapture?.call('still_magnet'); // distractor: a still magnet does nothing
        caption.value = TBCopy.onlyMoving; // meaning-line: the rule
        _schedule(TBCopy.onlyMovingToDepthMs, () {
          caption.value = TBCopy.depthStop; // the depth-stop (the allowed-longer line)
          _schedule(TBCopy.depthToTurbineMs, _enterTurbine);
        });
      }
    }

    // 8) Beat 2 — imperative, then first turn → meaning-lines → the sources.
    if (ph == TBPhase.turbine && !_b2LitOnce) {
      if (caption.value.text != TBCopy.turnTurbine.text) caption.value = TBCopy.turnTurbine;
      if (_brightness >= TBTune.clearlyLitThreshold) {
        _b2LitOnce = true;
        onCapture?.call('turbine_spin'); // distractor: a turbine spins the magnet
        caption.value = TBCopy.sameTrick; // meaning-line
        _schedule(TBCopy.sameTrickToArmMs, () {
          caption.value = TBCopy.stillYourArm; // meaning-line (sets up the need)
          _schedule(TBCopy.armToSourceMs, _enterSource);
        });
      }
    }

    // 9) Polish hooks.
    if (_isGenerating != wasGenerating) onGeneratingChanged?.call(_isGenerating);
    if (turning && _grabDown && _hapticAccum >= _hapticStep) {
      _hapticAccum %= _hapticStep;
      onCrankTick?.call();
    }

    // 10) Scheduled transition timer.
    if (_step > 0) {
      _step -= dt * 1000;
      if (_step <= 0) {
        _step = -1;
        final a = _stepAction;
        _stepAction = null;
        a?.call();
      }
    }

    // 11) Discovery flash envelope.
    if (_flashActive) {
      _flashElapsed += dt;
      if (_flashElapsed >= TBTune.discoveryFlashSeconds) _flashActive = false;
    }

    // 11b) Entrance reveals + the source surge + the solar core-fade.
    _bulbReveal = _approach(_bulbReveal, 1, dt, 0.45);
    _coilReveal = _approach(_coilReveal, ph == TBPhase.intro ? 0.0 : 1.0, dt, 0.40);
    _turbineReveal = _approach(_turbineReveal, _turbinePresent ? 1 : 0, dt, 0.50);
    _sourceReveal = _approach(_sourceReveal, _sourcePresent ? 1 : 0, dt, 0.55);
    if (_sourcePresent) _handoffRamp = _approach(_handoffRamp, 1, dt, 0.55);
    // A touch slower so entering solar reads as a WITNESSED event — the kid sees
    // the turbine + magnet fade OUT (the part every other source had, removed).
    _coreFade = _approach(_coreFade, magnetInChain ? 1.0 : 0.0, dt, 0.42);

    notifyListeners();
  }

  static const double _hapticStep = math.pi / 2; // a tick every quarter-turn

  void _startDiscoveryFlash() {
    _flashActive = true;
    _flashElapsed = 0;
    onDiscovery?.call();
  }

  @override
  void dispose() {
    caption.dispose();
    secondary.dispose();
    phase.dispose();
    activeSource.dispose();
    showNext.dispose();
    showCardEarn.dispose();
    canFinish.dispose();
    super.dispose();
  }
}
