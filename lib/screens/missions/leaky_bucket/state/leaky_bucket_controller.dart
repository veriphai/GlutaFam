// The Leaky Bucket — the activity controller. A build-and-watch-it-leak
// DEMONSTRATION: the kid SNAP-BUILDS the plant (drags the 4 machines in; each
// snaps to its correct place — no wrong order, no fail), then POWERS IT UP and the
// machines wake in sequence, each leaking heat as it comes online, until the bulb
// lands dim (~38). No plugging, no fixing, no puzzle.
//
// Owns the Sankey MODEL, the stage GEOMETRY (pixel anchors = factors × stage
// size), the build state, the power-up sweep, and the phase machine. The Flame
// game reports the stage size once, ticks the controller each frame, and renders
// as a near-pure reader of getters (controller-owns-geometry). NO mascot: a short
// large-font instruction line (set by the engine) tells the kid what to do.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Offset, Size;

import '../config/leaky_chain_defs.dart';
import '../config/leaky_tuning.dart';
import '../engine/leaky_bot_engine.dart';
import 'leaky_model.dart';

class LeakyBucketController extends ChangeNotifier {
  LeakyBucketController() {
    _engine = LeakyBotEngine(
      onInstruction: (t) => instruction.value = t,
      onPhase: (p) => phase.value = p,
      onFireCard: () => showCardEarn.value = true,
      onOutro: () => canFinish.value = true,
    );
  }

  late final LeakyBotEngine _engine;
  final LeakyModel model = LeakyModel();

  // --- Discrete UI channels --------------------------------------------------
  final ValueNotifier<LBPhase> phase = ValueNotifier(LBPhase.build);
  final ValueNotifier<String> instruction = ValueNotifier('');
  final ValueNotifier<bool> showCardEarn = ValueNotifier(false);
  final ValueNotifier<bool> canFinish = ValueNotifier(false);

  void Function()? onSelectHaptic;

  // --- Build state -----------------------------------------------------------
  final Set<LeakStepKind> placed = {};
  final Map<LeakStepKind, double> _placedAt = {};
  double _clock = 0;

  int get stepCount => model.def.steps.length;
  LeakStepKind _kindAt(int i) => model.def.steps[i].kind;
  int homeIndex(LeakStepKind k) => model.def.steps.indexWhere((s) => s.kind == k);

  bool isPlaced(LeakStepKind k) => placed.contains(k);
  bool get allPlaced => placed.length == stepCount;

  /// The machines still in the tray (in chain order, for a stable layout).
  List<LeakStepKind> get unplacedMachines =>
      model.def.steps.map((s) => s.kind).where((k) => !placed.contains(k)).toList();

  /// 0..1 pop-in for the machine whose home is slot [i] (-1 if not placed).
  double nodeAge(int i) {
    final k = _kindAt(i);
    final t = _placedAt[k];
    return t == null ? -1 : (_clock - t);
  }

  // --- Power-up state --------------------------------------------------------
  bool _powered = false;
  bool get powered => _powered;
  bool get readyToPower => allPlaced && !_powered;
  double flowProgress = 0; // 0 at the coal feed, 1 at the bulb (during power-up)

  // --- Turbine spin (auto, only when alive — no flick) -----------------------
  double _turbineAngle = 0;
  double _turbineAV = 0;
  double get turbineAngle => _turbineAngle;
  double get spinNorm => (_turbineAV / LBTune.turbineMaxSpinAV).clamp(0.0, 1.0);
  int get _spinIndex => model.def.steps.indexWhere((s) => s.kind == LeakStepKind.spin);

  // --- Geometry --------------------------------------------------------------
  Size _stage = Size.zero;
  Size get stageSize => _stage;
  void setStageSize(Size s) => _stage = s;

  double get _shortSide => math.min(_stage.width, _stage.height);
  double get _colX => LBTune.columnX * _stage.width;

  Offset get inputCenter => Offset(_colX, LBTune.inputY * _stage.height);
  Offset get bulbCenter => Offset(_colX, LBTune.bulbY * _stage.height);
  double get inputRadius => LBTune.inputRadiusF * _shortSide;
  double get bulbRadius => LBTune.bulbRadiusF * _shortSide;
  double get nodeRadius => LBTune.nodeRadiusF * _shortSide;
  double get streamMaxWidth => LBTune.streamMaxWidthF * _shortSide;
  double get leakMaxWidth => LBTune.leakMaxWidthF * _shortSide;

  double _nodeYFactor(int i, int count) {
    if (count <= 1) return (LBTune.chainTopY + LBTune.chainBottomY) / 2;
    return LBTune.chainTopY + (LBTune.chainBottomY - LBTune.chainTopY) * (i / (count - 1));
  }

  List<Offset> get nodeCenters =>
      List.generate(stepCount, (i) => Offset(_colX, _nodeYFactor(i, stepCount) * _stage.height));

  Offset centerOf(LeakStepKind k) => nodeCenters[homeIndex(k)];
  Offset? get turbineCenter => (_spinIndex >= 0) ? nodeCenters[_spinIndex] : null;

  // --- Power-up reveal math (flow front passes each stage) --------------------
  double _nodeFlowFraction(int i) {
    final y = _nodeYFactor(i, stepCount);
    return ((y - LBTune.inputY) / (LBTune.bulbY - LBTune.inputY)).clamp(0.0, 1.0);
  }

  /// 0..1 — how far the flow has revealed leak [i] (0 until the flow reaches it).
  double leakReveal(int i) {
    if (!_powered) return 0;
    return ((flowProgress - _nodeFlowFraction(i)) / 0.08).clamp(0.0, 1.0);
  }

  /// A machine is "alive" (warm, leaking, spinning) once the power-up flow reaches it.
  bool machineAlive(int i) => _powered && flowProgress >= _nodeFlowFraction(i) - 0.001;

  double get bulbReveal => _powered ? ((flowProgress - 0.9) / 0.1).clamp(0.0, 1.0) : 0.0;

  /// The Y the energy stream currently reaches (input during build; sweeps to the
  /// bulb during power-up).
  double get frontY => _powered
      ? inputCenter.dy + (bulbCenter.dy - inputCenter.dy) * flowProgress
      : inputCenter.dy;

  // --- Read-through ----------------------------------------------------------
  List<LeakySegment> get segments => model.segments;
  double get input => LeakyModel.input;
  double get output => model.output;
  double get totalHeat => model.totalHeat;
  double get bulbGlow => model.bulbBrightness * bulbReveal;

  bool _started = false;

  // --- Lifecycle -------------------------------------------------------------
  void start() {
    if (_started) return;
    _started = true;
    _engine.enter();
  }

  // --- Input: snap-build -----------------------------------------------------
  /// Drop a machine into the chain — it SNAPS to its correct slot (no wrong order
  /// possible). Lenient: the overlay calls this when a tray machine is released
  /// over the scene.
  void placeMachine(LeakStepKind k) {
    if (phase.value != LBPhase.build || placed.contains(k)) return;
    placed.add(k);
    _placedAt[k] = _clock;
    onSelectHaptic?.call();
    if (allPlaced) _engine.reportBuilt();
    notifyListeners();
  }

  /// The kid tapped "Power It Up" — start the per-stage leak reveal.
  void powerUp() {
    if (!readyToPower) return;
    _powered = true;
    flowProgress = 0;
    _engine.reportPowerStart();
    onSelectHaptic?.call();
    notifyListeners();
  }

  /// The kid added Card 04 to the deck — dismiss the overlay and close.
  void onCardCollected() {
    showCardEarn.value = false;
    _engine.onCardCollected();
  }

  // --- Tick ------------------------------------------------------------------
  void tick(double dt) {
    if (dt <= 0) return;
    _clock += dt;

    if (_powered && flowProgress < 1) {
      flowProgress += LBTune.powerSweepSpeed * dt;
      if (flowProgress >= 1) {
        flowProgress = 1;
        _engine.reportPowered();
      }
    }

    // Turbine spins once the power-up flow reaches it; speed ∝ what it converts.
    if (_spinIndex >= 0 && machineAlive(_spinIndex)) {
      final out = segments[_spinIndex].outValue;
      final baseline = (out / LBTune.turbineSpinOutDiv).clamp(0.0, 1.0) * LBTune.turbineMaxSpinAV;
      _turbineAV += (baseline - _turbineAV) * (1 - math.exp(-dt / 0.6));
      _turbineAngle += _turbineAV * dt;
    } else {
      _turbineAV = 0;
    }

    _engine.update(dt * 1000);
    notifyListeners();
  }

  @override
  void dispose() {
    phase.dispose();
    instruction.dispose();
    showCardEarn.dispose();
    canFinish.dispose();
    super.dispose();
  }
}
