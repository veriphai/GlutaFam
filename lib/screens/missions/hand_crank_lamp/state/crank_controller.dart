// The activity controller — owns the physics AND the geometry (the
// "controller-owns-geometry" pattern for continuous-logic activities). The
// view reports the stage size once and forwards raw pointer positions; the
// controller computes signed angular velocity, energy, brightness, the
// discovery transition, and drives the bot engine. The painter is then a pure
// renderer that reads controller getters and repaints via `repaint: controller`.
//
// THE LOAD-BEARING REQUIREMENT (PRD §4.4) lives in tick(): when generation
// ceases, brightness is HARD-GATED to zero the same frame — no eased fade, no
// coast-down, no afterglow. Everything else is in service of not softening that.
//
// Notification model:
//   • This ChangeNotifier notifies EVERY frame → the single CustomPainter
//     repaints (no widget rebuild — it reads getters directly).
//   • Discrete UI changes (bot line, swap-unlock, active output) are pushed to
//     dedicated ValueNotifiers so the bubble/tray rebuild only on real changes,
//     not 60×/second.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Offset, Size;

import '../config/beat_script.dart';
import '../config/crank_config.dart';
import '../config/output_defs.dart';
import '../engine/bot_beat_engine.dart';

/// Voltix introduces himself ONCE per app run (the intro is the first-session
/// hook; later runs get the plain beforeLine). No cross-launch persistence in
/// this self-contained module — this process-level flag is a faithful
/// approximation of "first-ever entry" for the session.
bool _voltixIntroSeen = false;

class CrankController extends ChangeNotifier {
  CrankController() {
    _engine = BotBeatEngine(
      config: kHandCrankBeat,
      onLine: (u) => botLine.value = u,
      onDiscoveryVisual: (_) => _startDiscoveryFlash(),
      onOutro: () => canFinish.value = true,
    );
  }

  late final BotBeatEngine _engine;

  // --- Discrete UI channels (rebuild only on change) -------------------------
  final ValueNotifier<BotUtterance?> botLine = ValueNotifier(null);
  final ValueNotifier<bool> swapUnlocked = ValueNotifier(false);
  final ValueNotifier<ActiveOutput> activeOutput = ValueNotifier(ActiveOutput.lamp);

  /// True once Voltix's outro has landed — the screen reveals a "Continue" CTA
  /// so the kid can finish the lesson resource.
  final ValueNotifier<bool> canFinish = ValueNotifier(false);

  /// Non-lamp devices Voltix has already reacted to (so revisiting one doesn't
  /// re-fire "it's spinning now?").
  final Set<ActiveOutput> _reactedSwaps = {};

  // --- Optional polish hooks (stubbed at the call site; PRD §6) --------------
  /// A light haptic tick per crank rotation step (keys off MOTION, not contact).
  void Function()? onCrankTick;

  /// Sound presence tracks `isGenerating` (cuts WITH the light on stop).
  void Function(bool generating)? onGeneratingChanged;

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
  Offset get wireStart => Offset(
        CrankConfig.wireStartFactor.dx * _stage.width,
        CrankConfig.wireStartFactor.dy * _stage.height,
      );
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
  bool _hasLitOnce = false; // brightness crossed clearlyLitThreshold
  bool _hasStoppedOnce = false; // isGenerating went false after hasLitOnce
  double _handleAngle = 0; // visual handle rotation (sign-driven)
  double _pulsePhase = 0; // wire pulse travel [0,1)
  double _spinAngle = 0; // fan-blade / device motion angle (FROZEN on stop)

  // Per-frame angle integration.
  double _lastAngle = 0;
  double _frameAngleDelta = 0;
  bool _sampleThisFrame = false;
  double _sampleElapsed = 0;
  double _hapticAccum = 0; // abs rotation since last haptic tick

  // Discovery flash envelope.
  bool _flashActive = false;
  double _flashElapsed = 0;

  // Idle clock (ms of no productive progress).
  double _idleElapsed = 0;
  bool _started = false;

  // --- Read-only getters for the painter -------------------------------------
  bool get isPointerDown => _isPointerDown;
  bool get isGenerating => _isGenerating;
  double get angularVelocity => _angularVelocity;
  double get brightness => _brightness;
  double get energyInput => _energyInput;
  bool get hasLitOnce => _hasLitOnce;
  bool get hasStoppedOnce => _hasStoppedOnce;
  double get handleAngle => _handleAngle;
  double get pulsePhase => _pulsePhase;
  double get spinAngle => _spinAngle;

  /// Discovery flash intensity [0,1] — fast rise, slow decay; 0 when inactive.
  double get flashIntensity {
    if (!_flashActive) return 0;
    final t = (_flashElapsed / CrankConfig.discoveryFlashSeconds).clamp(0.0, 1.0);
    // Rise in the first 15%, decay over the rest.
    return t < 0.15 ? t / 0.15 : 1.0 - (t - 0.15) / 0.85;
  }

  // --- Lifecycle -------------------------------------------------------------
  /// Begin the beat: fires Voltix's intro (first session) or beforeLine.
  void start() {
    if (_started) return;
    _started = true;
    final firstSession = !_voltixIntroSeen;
    _voltixIntroSeen = true;
    _engine.enter(firstSession: firstSession);
  }

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

  /// Release ⇒ angular velocity goes to zero PROMPTLY, not on a spin-down curve
  /// (PRD §3.2, §4.4). No coasting that keeps generating.
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

  /// Normalise an angle delta into (-π, π] so crossing the ±π seam doesn't read
  /// as a huge spurious velocity.
  static double _unwrap(double d) {
    while (d > math.pi) {
      d -= 2 * math.pi;
    }
    while (d <= -math.pi) {
      d += 2 * math.pi;
    }
    return d;
  }

  // --- The tick: physics + discovery + engine timers -------------------------
  void tick(double dt) {
    if (dt <= 0) return;

    // 1) Resolve signed angular velocity for this frame.
    if (_sampleThisFrame) {
      _angularVelocity = _frameAngleDelta / dt; // average over the frame
      _frameAngleDelta = 0;
      _sampleThisFrame = false;
      _sampleElapsed = 0;
    } else {
      _sampleElapsed += dt;
      // Bridge a <~100ms gap between move events during active cranking; beyond
      // that (held-still) OR not pointer-down (released) ⇒ velocity is zero.
      if (!_isPointerDown || _sampleElapsed >= CrankConfig.sampleTimeoutSeconds) {
        _angularVelocity = 0;
      }
    }

    // 2) Energy + generating (keys off MOTION, never pointer contact).
    _energyInput = CrankConfig.normalizeEnergy(_angularVelocity);
    final wasGenerating = _isGenerating;
    _isGenerating = CrankConfig.isGeneratingAt(_angularVelocity);

    // 3) Brightness. Ripple-smoothed WHILE generating; HARD-GATED to zero on
    //    stop — the §4.4 load-bearing instant cutoff. The low-pass is bypassed
    //    entirely on the stop path so no fade tail can leak in.
    if (_isGenerating) {
      final target = CrankConfig.brightnessCurve(_energyInput);
      final alpha = 1 - math.exp(-dt / CrankConfig.rippleTau);
      _brightness += (target - _brightness) * alpha;
    } else {
      _brightness = CrankConfig.stopBrightness; // == 0, immediately
    }

    // 4) Wire pulse — advances only while generating; the painter draws it only
    //    while generating, so it can never persist on a dark/held-still crank.
    if (_isGenerating) {
      _pulsePhase = (_pulsePhase + dt * CrankConfig.pulseSpeed) % 1.0;
      // Device motion (fan blades / speaker) advances with brightness while
      // generating and FREEZES in place on stop — the fan stops the instant you
      // stop, it does NOT spin down (§4.4 applies to all four outputs).
      _spinAngle += dt * (2.0 + 12.0 * _brightness);
    } else {
      _pulsePhase = 0;
    }

    // 5) hasLitOnce — brightness crossed the "clearly lit" threshold. Voltix's
    //    warm "there it is" (names nothing — the discovery is the STOP).
    if (!_hasLitOnce && _brightness >= CrankConfig.clearlyLitThreshold) {
      _hasLitOnce = true;
      _engine.reportFirstLight();
    }

    // 6) Discovery — the FIRST generating→false transition AFTER hasLitOnce.
    //    Routes through the engine, which fires the onDiscovery visual
    //    (suppression-exempt) now and schedules afterLine ~420ms later.
    if (wasGenerating && !_isGenerating && _hasLitOnce && !_hasStoppedOnce) {
      _hasStoppedOnce = true;
      _engine.triggerDiscovery();
      swapUnlocked.value = true; // output-swap unlocks only AFTER discovery (§4.7)
    }

    // 7) Polish hooks.
    if (_isGenerating != wasGenerating) {
      onGeneratingChanged?.call(_isGenerating);
    }
    if (_isGenerating && _hapticAccum >= _hapticStep) {
      _hapticAccum %= _hapticStep;
      onCrankTick?.call();
    }

    // 8) Idle clock — reset on PROGRESS (generating); otherwise accrue and nudge
    //    LATE. The engine gates cooldown/maxFires and suppresses after afterLine.
    if (_isGenerating) {
      _idleElapsed = 0;
    } else if (!_hasStoppedOnce) {
      _idleElapsed += dt * 1000;
      if (_idleElapsed >= kHandCrankBeat.idleThresholdMs) {
        _engine.reportIdle();
      }
    }

    // 9) Discovery flash envelope.
    if (_flashActive) {
      _flashElapsed += dt;
      if (_flashElapsed >= CrankConfig.discoveryFlashSeconds) _flashActive = false;
    }

    // 10) Engine timers (afterLine countdown, cooldowns) in ms.
    _engine.update(dt * 1000);

    notifyListeners(); // repaint the canvas
  }

  static const double _hapticStep = math.pi / 2; // a tick every quarter turn

  void _startDiscoveryFlash() {
    _flashActive = true;
    _flashElapsed = 0;
  }

  // --- Output swap (PRD §4.7) ------------------------------------------------
  /// Swap the active output. Gated by the UI to be reachable only after
  /// discovery (§4.7). Voltix reacts to the first two NEW non-lamp devices and
  /// then the engine schedules the synthesis; revisiting a device is silent.
  void setActiveOutput(ActiveOutput out) {
    if (!swapUnlocked.value) return; // ordering enforced (criterion 8)
    if (out == activeOutput.value) return;
    activeOutput.value = out;
    final line = kDeviceSwapLines[out];
    if (line != null && _reactedSwaps.add(out)) {
      _engine.reportDeviceSwap(line);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    botLine.dispose();
    swapUnlocked.dispose();
    activeOutput.dispose();
    canFinish.dispose();
    super.dispose();
  }
}
