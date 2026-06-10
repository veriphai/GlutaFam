// The activity controller — owns the physics AND the geometry (the
// "controller-owns-geometry" pattern for continuous-logic activities). The view
// reports the stage size once and forwards raw pointer positions; the controller
// computes signed angular velocity, energy, brightness, particles, and drives a
// SEQUENTIAL step machine (lamp → fan → heater → speaker, one at a time — no
// device chooser). The painter is a pure renderer reading getters via
// `repaint: controller`.
//
// THE LOAD-BEARING REQUIREMENT (PRD §4.4) lives in tick(): when generation
// ceases, brightness is HARD-GATED to zero the same frame — no eased fade, no
// coast-down, no afterglow. Each step is "drive it, let go (it dies instantly),
// advance".

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Color, Offset, Size;

import '../config/crank_config.dart';
import '../config/output_defs.dart';
import '../config/sequence.dart';
import 'crank_particles.dart';

class CrankController extends ChangeNotifier {
  // --- Sequential step machine (discrete UI channels) ------------------------
  /// The active device — driven by the step machine, NOT by user choice.
  final ValueNotifier<ActiveOutput> activeOutput =
      ValueNotifier(kSequence.first.device);

  /// The short, large top instruction ("Spin the Handle", "Try the Fan", …).
  final ValueNotifier<String> instruction = ValueNotifier(kSequence.first.prompt);

  /// 0-based index of the current step (clamped to kSequence.length while done).
  final ValueNotifier<int> stepIndex = ValueNotifier(0);

  /// True once every device has been driven → the Continue / earn-card moment.
  final ValueNotifier<bool> done = ValueNotifier(false);

  bool _stepLit = false; // current device driven clearly this step

  // The lamp's death message ("No Spin, No Light") is held for a beat before
  // advancing, so the lesson lands.
  bool _diedHolding = false;
  double _diedElapsed = 0;
  static const double _diedHoldSeconds = 1.8;

  // --- Auto-crank victory lap (done state) -----------------------------------
  bool _autoCrank = false;
  static const double _autoCrankSpeed = 7.2; // rad/s → a bright, lively glow

  // --- Optional polish hook --------------------------------------------------
  /// A light haptic tick per crank rotation step (keys off MOTION, not contact).
  void Function()? onCrankTick;

  // --- Geometry (pixels, derived from factors × stage size) ------------------
  Size _stage = Size.zero;
  Size get stageSize => _stage;
  void setStageSize(Size size) => _stage = size;

  Offset get pivot => Offset(
        CrankConfig.pivotFactor.dx * _stage.width,
        CrankConfig.pivotFactor.dy * _stage.height,
      );
  double get handleLength => CrankConfig.handleLenFactor * _stage.width;
  Offset get outputCenter => Offset(
        CrankConfig.outputFactor.dx * _stage.width,
        CrankConfig.outputFactor.dy * _stage.height,
      );
  double get outputRadius => CrankConfig.outputRadiusFactor * _stage.width;

  /// The generator box between the handle and the device.
  Offset get boxCenter => Offset(
        CrankConfig.boxFactor.dx * _stage.width,
        CrankConfig.boxFactor.dy * _stage.height,
      );
  Size get boxSize => Size(
        CrankConfig.boxWidthFactor * _stage.width,
        CrankConfig.boxHeightFactor * _stage.width,
      );

  /// The wire runs UP from the GENERATOR BOX (top edge) to the device above it.
  Offset get wireStart => Offset(boxCenter.dx, boxCenter.dy - boxSize.height / 2 * 0.92);
  Offset get wireEnd => Offset(
        CrankConfig.wireEndFactor.dx * _stage.width,
        CrankConfig.wireEndFactor.dy * _stage.height,
      );

  // --- Physics state (hot path — read via getters) ---------------------------
  bool _isPointerDown = false; // finger touching the crank — NOT generating
  double _angularVelocity = 0; // signed, rad/s
  double _brightness = 0; // [0,1]
  double _energyInput = 0; // normalize(abs(angularVelocity))
  bool _isGenerating = false; // abs(angularVelocity) > lowSpeedFloor
  double _handleAngle = 0; // visual handle rotation (sign-driven)
  double _pulsePhase = 0; // wire pulse travel [0,1)
  double _spinAngle = 0; // fan-blade / device motion angle (FROZEN on stop)

  // Per-frame angle integration.
  double _lastAngle = 0;
  double _frameAngleDelta = 0;
  bool _sampleThisFrame = false;
  double _sampleElapsed = 0;
  double _hapticAccum = 0; // abs rotation since last haptic tick

  // Discovery flash envelope (fires on each "let go").
  bool _flashActive = false;
  double _flashElapsed = 0;

  // --- Read-only getters for the painter -------------------------------------
  bool get isGenerating => _isGenerating;
  double get angularVelocity => _angularVelocity;
  double get brightness => _brightness;
  double get energyInput => _energyInput;
  double get handleAngle => _handleAngle;
  double get pulsePhase => _pulsePhase;
  double get spinAngle => _spinAngle;

  /// The crank knob's live position (where sparks fly off).
  Offset get knobPosition => Offset(
        pivot.dx + handleLength * math.cos(_handleAngle),
        pivot.dy + handleLength * math.sin(_handleAngle),
      );

  /// Live energy particles for the painter (sparks + device debris).
  List<Particle> get particles => _particleField.particles;
  final ParticleField _particleField = ParticleField();

  /// Discovery flash intensity [0,1] — fast rise, slow decay; 0 when inactive.
  double get flashIntensity {
    if (!_flashActive) return 0;
    final t = (_flashElapsed / CrankConfig.discoveryFlashSeconds).clamp(0.0, 1.0);
    return t < 0.15 ? t / 0.15 : 1.0 - (t - 0.15) / 0.85;
  }

  /// Free-running seconds clock (always advances) — drives idle breathing.
  double _clock = 0;
  double get clock => _clock;

  // --- Lifecycle -------------------------------------------------------------
  /// No-op kept for shell compatibility (the first instruction is set up front).
  void start() {}

  // --- Pointer input (forwarded from the gesture surface) --------------------
  void onPointerDown(Offset local) {
    _isPointerDown = true;
    _lastAngle = _angleTo(local);
    _frameAngleDelta = 0;
    _sampleThisFrame = false;
    _sampleElapsed = 0;
  }

  void onPointerMove(Offset local) {
    if (!_isPointerDown) return;
    final angle = _angleTo(local);
    final delta = _unwrap(angle - _lastAngle);
    _lastAngle = angle;
    _frameAngleDelta += delta;
    _handleAngle += delta; // sign drives the on-screen handle rotation
    _hapticAccum += delta.abs();
    _sampleThisFrame = true;
  }

  /// Release ⇒ angular velocity goes to zero PROMPTLY (PRD §3.2, §4.4).
  void onPointerUp() {
    _isPointerDown = false;
    _angularVelocity = 0;
    _frameAngleDelta = 0;
    _sampleThisFrame = false;
  }

  double _angleTo(Offset local) {
    final p = pivot;
    return math.atan2(local.dy - p.dy, local.dx - p.dx);
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

  // --- The tick: physics + step machine --------------------------------------
  void tick(double dt) {
    if (dt <= 0) return;
    _clock += dt;

    // 1) Resolve signed angular velocity for this frame.
    if (_autoCrank) {
      _angularVelocity = _autoCrankSpeed; // done-state victory lap, ignores input
      _handleAngle += _autoCrankSpeed * dt;
      _sampleThisFrame = false;
    } else if (_sampleThisFrame) {
      _angularVelocity = _frameAngleDelta / dt;
      _frameAngleDelta = 0;
      _sampleThisFrame = false;
      _sampleElapsed = 0;
    } else {
      _sampleElapsed += dt;
      if (!_isPointerDown || _sampleElapsed >= CrankConfig.sampleTimeoutSeconds) {
        _angularVelocity = 0;
      }
    }

    // 2) Energy + generating (keys off MOTION, never pointer contact).
    _energyInput = CrankConfig.normalizeEnergy(_angularVelocity);
    final wasGenerating = _isGenerating;
    _isGenerating = CrankConfig.isGeneratingAt(_angularVelocity);

    // 3) Brightness — ripple-smoothed WHILE generating; HARD-GATED to zero on
    //    stop (the §4.4 instant cutoff). No fade tail.
    if (_isGenerating) {
      final target = CrankConfig.brightnessCurve(_energyInput);
      final alpha = 1 - math.exp(-dt / CrankConfig.rippleTau);
      _brightness += (target - _brightness) * alpha;
    } else {
      _brightness = CrankConfig.stopBrightness; // == 0, immediately
    }

    // 4) Wire pulse + device spin advance only while generating.
    if (_isGenerating) {
      _pulsePhase = (_pulsePhase + dt * CrankConfig.pulseSpeed) % 1.0;
      _spinAngle += dt * (2.0 + 12.0 * _brightness);
    } else {
      _pulsePhase = 0;
    }

    // 4b) Energy particles — cleared instantly on stop (the cutoff is total).
    if (_isGenerating && _brightness > 0.02) {
      final bloom = kOutputDefs[activeOutput.value]!.bloom;
      _particleField.spawnSparks(
        dt: dt,
        knob: knobPosition,
        knobSpeed: _angularVelocity.abs() * handleLength,
        dirSign: _angularVelocity.sign,
        handleAngle: _handleAngle,
        energy: _energyInput,
        color: const Color(0xFFFFF1C2),
      );
      switch (activeOutput.value) {
        case ActiveOutput.heater:
          _particleField.spawnEmbers(
              dt: dt, center: outputCenter, r: outputRadius, b: _brightness, color: bloom);
        case ActiveOutput.fan:
          _particleField.spawnWind(
              dt: dt, center: outputCenter, r: outputRadius, b: _brightness, color: bloom);
        case ActiveOutput.lamp:
          _particleField.spawnMotes(
              dt: dt, center: outputCenter, r: outputRadius, b: _brightness, color: bloom);
        case ActiveOutput.speaker:
          break; // air ripples drawn in the painter, not particles
      }
      _particleField.update(dt);
    } else {
      _particleField.clear();
    }

    // 5) Step machine. Drive the device clearly, then release: it dies instantly
    //    (the lesson). The lamp holds "No Spin, No Light" for a beat first; the
    //    other devices advance straight away.
    if (!_autoCrank && !done.value) {
      if (!_stepLit && _brightness >= CrankConfig.clearlyLitThreshold) {
        _stepLit = true;
      }
      if (wasGenerating && !_isGenerating && _stepLit && !_diedHolding) {
        _startDiscoveryFlash();
        final dies = kSequence[stepIndex.value].diesText;
        if (dies != null) {
          _diedHolding = true;
          _diedElapsed = 0;
          _updateInstruction(); // → the death message
        } else {
          _advanceStep();
        }
      }
      // Hold the death message, then advance on the next still frame (so the
      // device never swaps under the kid's hand if they re-crank).
      if (_diedHolding) {
        _diedElapsed += dt;
        if (_diedElapsed >= _diedHoldSeconds && !_isGenerating) {
          _diedHolding = false;
          _advanceStep();
        }
      }
    }

    // 6) Haptic tick per rotation.
    if (_isGenerating && _hapticAccum >= _hapticStep) {
      _hapticAccum %= _hapticStep;
      onCrankTick?.call();
    }

    // 7) Discovery flash envelope.
    if (_flashActive) {
      _flashElapsed += dt;
      if (_flashElapsed >= CrankConfig.discoveryFlashSeconds) _flashActive = false;
    }

    notifyListeners(); // repaint the canvas
  }

  static const double _hapticStep = math.pi / 2; // a tick every quarter turn

  void _startDiscoveryFlash() {
    _flashActive = true;
    _flashElapsed = 0;
  }

  /// Advance to the next device, or — once all are driven — enter the done state:
  /// switch to the lamp and auto-crank it as a little victory lap.
  void _advanceStep() {
    final next = stepIndex.value + 1;
    _stepLit = false;
    if (next >= kSequence.length) {
      done.value = true;
      activeOutput.value = ActiveOutput.lamp;
      _autoCrank = true;
    } else {
      stepIndex.value = next;
      activeOutput.value = kSequence[next].device;
    }
    _updateInstruction();
  }

  void _updateInstruction() {
    if (done.value) {
      instruction.value = kDoneText;
      return;
    }
    final step = kSequence[stepIndex.value];
    instruction.value = (_diedHolding && step.diesText != null) ? step.diesText! : step.prompt;
  }

  @override
  void dispose() {
    activeOutput.dispose();
    instruction.dispose();
    stepIndex.dispose();
    done.dispose();
    super.dispose();
  }
}
