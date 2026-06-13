// Squared Loss (beat 2.4) — the activity controller. Owns the sim (current, heat,
// volts, particle field, sweep coverage), the geometry (factors × stage size set
// once per paint), and the silent phase machine with cancellable timers. The
// painters are pure renderers reading getters via `repaint: controller`.
//
// THE LESSON LIVES IN THE FELT CHANNEL (PRD §4, §11.8): glow / embers / shimmer
// respond in the SAME frame the handle moves (no easing). Only the printed HEAT /
// LOST VOLTS numbers roll, fast (~550 ms). The handle has zero momentum: its
// position is exactly the clamped finger x; release leaves it where it is. The two
// scripted resets (auto-ease back to ×1 between derivation steps) are the only
// handle motion the learner doesn't drive — and they read as a visible glide.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Color, Offset, Size, Rect;

import '../config/squared_loss_copy.dart';
import '../config/squared_loss_tuning.dart';
import 'heat_particles.dart';

/// The beat-by-beat phases (PRD §6 / §14).
enum SLPhase {
  enter,
  firstPush,
  secondPush,
  sweep,
  named,
  cardEarn,
  closing,
}

/// The exclusive right-hand chip — never both with CURRENT counted, only one swap.
enum SLChip { heat, volts }

class SquaredLossController extends ChangeNotifier {
  // ── Discrete UI channels ───────────────────────────────────────────────
  final ValueNotifier<SLCaption> caption = ValueNotifier(SLCaption.intro);
  final ValueNotifier<SLPhase> phase = ValueNotifier(SLPhase.enter);
  final ValueNotifier<SLChip> chip = ValueNotifier(SLChip.heat);
  final ValueNotifier<bool> showCardEarn = ValueNotifier(false);
  final ValueNotifier<bool> done = ValueNotifier(false);

  // ── Polish hooks (wired by the shell) ──────────────────────────────────
  void Function()? onDetent; // selectionClick per detent crossing
  void Function()? onDiscovery; // heavyImpact at the ×2 discovery + multiply payoff
  void Function(String id)? onCapture; // lightImpact + scene snapshot → board
  bool reducedMotion = false; // set from MediaQuery each build

  // ── Geometry (pixels = factor × stage size, set once per paint) ─────────
  Size _stage = Size.zero;
  Size get stageSize => _stage;
  void setStageSize(Size size) => _stage = size;

  double get _w => _stage.width;
  double get _h => _stage.height;

  // DIAGONAL anchors (continuity with 2.3): the LEFT anchor sits LOW, the RIGHT
  // anchor sits HIGH, so the span climbs across the whole frame (no centered-U
  // dead air). The wire's drawn geometry is the held-constant — identical every
  // beat; only its glow widens/brightens with the square.
  Offset get leftAnchor => Offset(SLTune.pylonLeftX * _w, SLTune.pylonLeftTopY * _h);
  Offset get rightAnchor => Offset(SLTune.pylonRightX * _w, SLTune.pylonRightTopY * _h);

  /// The voluminous conductor body width, in pixels (factor of H).
  double get wireStroke => SLTune.wireStrokeF * _h;

  /// The catenary point for t in [0,1] (0 = left anchor, 1 = right anchor). The
  /// straight line is the DIAGONAL between the two differently-heighted anchors; a
  /// parabolic SAG dips below it (max at midspan). Byte-identical every beat.
  Offset wirePoint(double t) {
    final x = leftAnchor.dx + (rightAnchor.dx - leftAnchor.dx) * t;
    final straightY = leftAnchor.dy + (rightAnchor.dy - leftAnchor.dy) * t;
    final sag = SLTune.sagDepthF * _h * 4 * t * (1 - t); // parabola, max at t=0.5
    return Offset(x, straightY + sag);
  }

  // Back-compat aliases (the painter / particle field still ask for these).
  Offset get pylonLeft => leftAnchor;
  Offset get pylonRight => rightAnchor;

  /// The midspan extra-sag depth, in pixels (passed to the ember field).
  double get wireSagPx => SLTune.sagDepthF * _h;

  /// The graph panel rect (factor → pixels). Visible only from `sweep` on.
  Rect get panelRect => Rect.fromLTRB(
        SLTune.panelLeftX * _w,
        SLTune.panelTopY * _h,
        SLTune.panelRightX * _w,
        SLTune.panelBottomY * _h,
      );

  // ── Sim state (hot path — read via getters) ────────────────────────────
  double _current = 1.0; // ×, the only learner-held variable
  double _displayHeat = 100; // rolled toward 100·I²
  double _displayVolts = 100; // rolled toward 100·I
  double _heatTarget = 100;
  double _voltsTarget = 100;

  double get current => _current;
  double get heat => SLTune.heatFor(_current);
  double get lostVolts => SLTune.lostVoltsFor(_current);
  double get displayHeat => _displayHeat;
  double get displayVolts => _displayVolts;

  /// Live wire glow [0,1] — keyed off the square, lifted to the rest floor. This is
  /// the FELT channel: it tracks the handle in the same frame (no ease).
  double get wireGlow {
    final g = SLTune.wireGlowFor(_current);
    return math.max(SLTune.restGlow, g);
  }

  // Slider state.
  double _rangeMin = 1.0;
  double _rangeMax = 2.0;
  bool _detentMode = true; // detents (push beats) vs continuous (sweep)
  bool _sliderLocked = true; // locked during enter / resets / named+
  double get rangeMin => _rangeMin;
  double get rangeMax => _rangeMax;
  bool get detentMode => _detentMode;
  bool get sliderLocked => _sliderLocked;

  /// The handle's normalized position along the FULL ×1..×4 track — the SAME span
  /// the detent tick labels use, so the handle always sits under its own ×N label.
  /// The active range only limits how far it can travel (via the clamp in
  /// _applyNorm); it must NOT re-scale the handle, or ×2 would render at the track
  /// end while reading ×1.4 (the prior bug).
  double get handleX => ((_current - 1.0) / 3.0).clamp(0.0, 1.0);

  bool _pointerDown = false;
  bool get pointerDown => _pointerDown;

  // Number-roll state.
  double _heatRollElapsed = SLTune.rollSeconds;
  double _heatRollFrom = 100;
  double _voltsRollElapsed = SLTune.rollSeconds;
  double _voltsRollFrom = 100;

  // ── Particles ──────────────────────────────────────────────────────────
  final HeatParticleField _field = HeatParticleField();
  List<HeatParticle> get embers => _field.embers;
  List<HeatParticle> get motes => _field.motes;

  // ── Haze / flash / leap / reveal envelopes ─────────────────────────────
  /// Ever-rising clock driving the heat-haze shimmer scroll (ported from 2.3).
  double _hazePhase = 0;
  double get hazePhase => _hazePhase;

  /// The glow-LEAP envelope fired at a ×2 / ×3 detent landing — a quick extra
  /// brightening on TOP of the steady-state glow so the 4× jump punches visibly,
  /// then settles. Decays fast-in / slow-out. NOT eased into the felt steady state
  /// (the steady glow is same-frame); this is added punctuation only.
  bool _leapActive = false;
  double _leapElapsed = 0;
  double get leapPulse {
    if (!_leapActive) return 0;
    final t = (_leapElapsed / SLTune.leapPulseSeconds).clamp(0.0, 1.0);
    return t < 0.18 ? t / 0.18 : 1.0 - (t - 0.18) / 0.82;
  }

  bool _flashActive = false;
  double _flashElapsed = 0;
  double get flashIntensity {
    if (!_flashActive) return 0;
    final t = (_flashElapsed / SLTune.flashSeconds).clamp(0.0, 1.0);
    return t < 0.15 ? t / 0.15 : 1.0 - (t - 0.15) / 0.85;
  }

  double _revealT = 0; // entrance reveal 0→1
  double get revealT => _revealT;

  double _graphReveal = 0; // panel slide-up 0→1
  double get graphReveal => _graphReveal;
  bool _graphRevealing = false;

  double _ghostReveal = 0; // straight ghost line 0→1
  double get ghostReveal => _ghostReveal;
  bool _ghostRevealing = false;

  // The graph modal dismisses COMPLETELY on voltsStep (slide-down + fade), not dims.
  double _panelDismiss = 0; // 0 = fully shown, 1 = gone
  bool _panelDismissing = false;
  double get panelDismiss => _panelDismiss;

  double _clock = 0;
  double get clock => _clock;

  // Idle nudge (the handle pulses gently after a long idle in a push beat).
  double _idleElapsed = 0;
  double get idlePulse {
    // A gentle breathing pulse, only meaningful when the gate is waiting.
    if (!_idleWaiting || _idleElapsed < SLTune.idlePulseSeconds) return 0;
    final t = (_idleElapsed - SLTune.idlePulseSeconds);
    return 0.5 + 0.5 * math.sin(t * 3.4);
  }

  bool get _idleWaiting =>
      !_sliderLocked &&
      (phase.value == SLPhase.firstPush || phase.value == SLPhase.secondPush);

  // ── Sweep coverage (the learner draws the curve) ───────────────────────
  final List<bool> _buckets = List<bool>.filled(SLTune.coverageBuckets, false);
  final List<Offset> _curveTrail = []; // normalized (x:(I-1)/3, y:1-heat/1600)
  List<Offset> get curveTrail => List.unmodifiable(_curveTrail);
  int get coverageCount => _buckets.where((b) => b).length;
  bool _curveClosed = false;
  bool get curveClosed => _curveClosed;
  double _curveCloseElapsed = 0;

  // ── Timers (cancellable; all torn down on dispose) ─────────────────────
  final List<Timer> _timers = [];
  bool _disposed = false;

  void _schedule(int ms, void Function() action) {
    if (_disposed) return;
    late Timer t;
    t = Timer(Duration(milliseconds: ms), () {
      _timers.remove(t);
      if (!_disposed) action();
    });
    _timers.add(t);
  }

  void _cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────
  /// Kick off the entrance after the first frame (the shell calls this once).
  void start() {
    _revealStartElapsed = 0;
    _revealing = true;
    // The intro holds while the scene reveals, then the slider unlocks at ×1.
    _schedule(SLTune.introToRaiseMs, _enterFirstPush);
  }

  bool _revealing = false;
  double _revealStartElapsed = 0;

  void _enterFirstPush() {
    phase.value = SLPhase.firstPush;
    caption.value = SLCaption.raiseToTwo;
    _setRange(1.0, 2.0, detent: true);
    _sliderLocked = false;
    _idleElapsed = 0;
    notifyListeners();
  }

  // ── Slider input (forwarded from the track widget) ─────────────────────
  /// [norm] is the finger position along the track, normalized 0..1.
  void onHandleDown(double norm) {
    if (_sliderLocked) return;
    _pointerDown = true;
    _idleElapsed = 0;
    _applyNorm(norm);
  }

  void onHandleMove(double norm) {
    if (_sliderLocked || !_pointerDown) return;
    _idleElapsed = 0;
    _applyNorm(norm);
  }

  void onHandleUp() {
    if (!_pointerDown) return;
    _pointerDown = false;
    if (_detentMode) _snapToNearestDetent();
    _checkGates();
  }

  int _lastDetentIndex = 0;

  void _applyNorm(double norm) {
    // The finger maps onto the FULL ×1..×4 track (so dragging under the ×2 label
    // gives exactly ×2), then clamps to the phase's active range. This is the SAME
    // mapping handleX uses, so the handle, the value, and the tick labels all agree.
    final raw = (1.0 + norm.clamp(0.0, 1.0) * 3.0).clamp(_rangeMin, _rangeMax);
    double next = raw;
    if (_detentMode) {
      // Soft detent magnetism: snap when within the snap fraction of a tick (the
      // fraction is of the FULL ×1..×4 span so it feels the same in every range).
      for (final d in SLTune.detents4) {
        if (d < _rangeMin - 1e-6 || d > _rangeMax + 1e-6) continue;
        if ((raw - d).abs() <= SLTune.detentSnapFraction * 3.0) {
          next = d;
          break;
        }
      }
    }
    _setCurrent(next);
    // Detent crossing haptic (only in detent mode).
    if (_detentMode) {
      final idx = _nearestDetentIndex(_current);
      if (idx != _lastDetentIndex && (_current - SLTune.detents4[idx]).abs() < 1e-3) {
        _lastDetentIndex = idx;
        onDetent?.call();
      }
    }
    // In sweep mode, plot the curve where the handle actually is.
    if (!_detentMode && phase.value == SLPhase.sweep) _plotSweep();
    notifyListeners();
  }

  int _nearestDetentIndex(double i) {
    var best = 0;
    var bestD = double.infinity;
    for (var k = 0; k < SLTune.detents4.length; k++) {
      final d = (SLTune.detents4[k] - i).abs();
      if (d < bestD) {
        bestD = d;
        best = k;
      }
    }
    return best;
  }

  void _snapToNearestDetent() {
    final idx = _nearestDetentIndex(_current);
    final d = SLTune.detents4[idx].clamp(_rangeMin, _rangeMax);
    if ((d - _current).abs() > 1e-4) {
      _setCurrent(d.toDouble());
      onDetent?.call();
    }
    _lastDetentIndex = idx;
  }

  /// Set the current and retarget the rolling numbers (felt channel is instant;
  /// only the printed digits roll).
  void _setCurrent(double i) {
    final clamped = i.clamp(_rangeMin, _rangeMax);
    if ((clamped - _current).abs() < 1e-6) {
      _current = clamped;
      return;
    }
    _current = clamped;
    _heatTarget = SLTune.heatFor(_current);
    _voltsTarget = SLTune.lostVoltsFor(_current);
    _startHeatRoll();
    _startVoltsRoll();
  }

  void _startHeatRoll() {
    _heatRollFrom = _displayHeat;
    _heatRollElapsed = 0;
  }

  void _startVoltsRoll() {
    _voltsRollFrom = _displayVolts;
    _voltsRollElapsed = 0;
  }

  void _setRange(double min, double max, {required bool detent}) {
    _rangeMin = min;
    _rangeMax = max;
    _detentMode = detent;
    _lastDetentIndex = _nearestDetentIndex(_current);
  }

  // ── Gates (a phase only advances forward) ──────────────────────────────
  void _checkGates() {
    switch (phase.value) {
      case SLPhase.firstPush:
        if (_atDetent(2.0)) _onFirstPushLanded();
      case SLPhase.secondPush:
        if (_atDetent(3.0)) _onSecondPushLanded();
      default:
        break;
    }
  }

  bool _atDetent(double v) => (_current - v).abs() < 1e-3;

  // ── firstPush → discovery ──────────────────────────────────────────────
  void _onFirstPushLanded() {
    _sliderLocked = true; // hold the moment; the slider re-opens for secondPush
    _startFlash();
    _fireLeap(); // the 4× leap: glow-leap pulse + dense ember burst off the span
    onDiscovery?.call(); // heavyImpact
    caption.value = SLCaption.fourTimes;
    // Capture fires AFTER the number-roll so HEAT reads 400 in-frame (PRD §9).
    _schedule(SLTune.discoveryCaptureMs, () => onCapture?.call('heat_quadruples'));
    _schedule(SLTune.twoToThreeMs, _enterSecondPush);
    notifyListeners();
  }

  void _enterSecondPush() {
    phase.value = SLPhase.secondPush;
    caption.value = SLCaption.raiseToThree;
    _setRange(1.0, 3.0, detent: true);
    _sliderLocked = false;
    _idleElapsed = 0;
    notifyListeners();
  }

  void _onSecondPushLanded() {
    _sliderLocked = true;
    _fireLeap(); // the ×3 → ×9 leap: a bigger ember burst (count ∝ glow)
    caption.value = SLCaption.nineTimes;
    _schedule(SLTune.threeToSweepMs, _enterSweep);
    notifyListeners();
  }

  // ── sweep — the learner draws the curve ────────────────────────────────
  void _enterSweep() {
    phase.value = SLPhase.sweep;
    caption.value = SLCaption.sweep;
    _graphRevealing = true;
    _curveClosed = false;
    _curveTrail.clear();
    for (var k = 0; k < _buckets.length; k++) {
      _buckets[k] = false;
    }
    _setRange(1.0, 4.0, detent: false); // continuous, detent ticks fade out
    _sliderLocked = false;
    _idleElapsed = 0;
    notifyListeners();
  }

  void _plotSweep() {
    // Only graph where the handle has actually been: mark this bucket + append a
    // trail point in normalized panel space (x:(I-1)/3, y:1-heat/1600).
    final frac = ((_current - 1.0) / 3.0).clamp(0.0, 1.0);
    final bucket = (frac * (SLTune.coverageBuckets - 1)).round();
    _buckets[bucket] = true;
    final nx = frac;
    final ny = (1.0 - (SLTune.heatFor(_current) / 1600.0)).clamp(0.0, 1.0);
    _curveTrail.add(Offset(nx, ny));
    if (!_curveClosed && coverageCount >= SLTune.coverageGate) _onSweepComplete();
  }

  void _onSweepComplete() {
    _curveClosed = true;
    _curveCloseElapsed = 0;
    _sliderLocked = true; // the curve is drawn — stop further plotting while it reads
    // No onCapture here (the EP2 catalog carries no `square_curve` tile). We name the
    // bend, fade in the dashed ghost line for the contrast (NO caption — the visual
    // carries it, the old "it would follow the straight line" line was cut), then
    // name the law. The ×2/×3/×4 data-point markers appear with the close.
    _schedule(SLTune.sweepCaptureMs, () {
      caption.value = SLCaption.curveBends;
      notifyListeners();
      _schedule(SLTune.curveToGhostMs, () {
        _ghostRevealing = true; // the straight ghost line fades in under the curve
        notifyListeners();
        _schedule(SLTune.ghostToNamedMs, _enterNamed);
      });
    });
    notifyListeners();
  }

  // ── named → card → closing ─────────────────────────────────────────────
  void _enterNamed() {
    phase.value = SLPhase.named;
    caption.value = SLCaption.named; // "Loss Grows with the Current Squared" — name-last
    // The curve + wire stay live as the law is named over the felt thing. When the
    // card earns, the graph modal dismisses behind it so the hand-off lands clean.
    _schedule(SLTune.namedToCardMs, () {
      _panelDismissing = true; // remove the graph modal as the card appears
      phase.value = SLPhase.cardEarn;
      showCardEarn.value = true;
      notifyListeners();
    });
    notifyListeners();
  }

  /// Called by the earn overlay's onDone (card added to deck).
  void onCardCollected() {
    showCardEarn.value = false;
    phase.value = SLPhase.closing;
    caption.value = SLCaption.handoff; // the 2.5 hand-off question
    done.value = true;
    notifyListeners();
  }

  void _startFlash() {
    _flashActive = true;
    _flashElapsed = 0;
  }

  /// Dramatize the 4× LEAP at a detent landing: a glow-leap punctuation pulse + a
  /// dense ember BURST off the span (count scales with the landing's glow, so ×3
  /// puffs more than ×2). "Nudge a little → jumps a LOT", made unmistakable.
  void _fireLeap() {
    _leapActive = true;
    _leapElapsed = 0;
    if (_w > 0 && _h > 0) {
      _field.burstEmbers(
        leftAnchor: leftAnchor,
        rightAnchor: rightAnchor,
        sagY: wireSagPx,
        glow: wireGlow,
        color: Color.lerp(SLTune.heat, SLTune.heatCore, wireGlow)!,
        calm: reducedMotion,
      );
    }
  }

  // ── The tick (60 fps; Ticker in shell) ─────────────────────────────────
  void tick(double dt) {
    if (dt <= 0 || _disposed) return;
    _clock += dt;
    // Heat-haze shimmer scroll — advances with wall time (a render flourish; the
    // painter renders static bands under reduced motion).
    if (!reducedMotion) _hazePhase += dt * SLTune.hazeSpeed;

    // Entrance reveal.
    if (_revealing) {
      _revealStartElapsed += dt;
      _revealT = (_revealStartElapsed / SLTune.sceneRevealSeconds).clamp(0.0, 1.0);
      if (_revealT >= 1.0) _revealing = false;
    } else if (_revealT < 1.0) {
      _revealT = 1.0;
    }

    // Graph panel reveal.
    if (_graphRevealing) {
      _graphReveal = (_graphReveal + dt / SLTune.graphRevealSeconds).clamp(0.0, 1.0);
      if (_graphReveal >= 1.0) _graphRevealing = false;
    }
    // Ghost line reveal.
    if (_ghostRevealing) {
      _ghostReveal = (_ghostReveal + dt / SLTune.ghostRevealSeconds).clamp(0.0, 1.0);
      if (_ghostReveal >= 1.0) _ghostRevealing = false;
    }
    // Graph modal dismissal (slide-down + fade-out → gone) when the law is named.
    if (_panelDismissing && _panelDismiss < 1.0) {
      _panelDismiss = (_panelDismiss + dt / SLTune.panelDismissSeconds).clamp(0.0, 1.0);
    }

    // Curve close glow pulse decay tracking.
    if (_curveClosed) _curveCloseElapsed += dt;

    _advanceRolls(dt);

    // Idle nudge accumulation (only while a push gate is waiting).
    if (_idleWaiting) {
      _idleElapsed += dt;
    } else {
      _idleElapsed = 0;
    }

    // Particles — the felt channel. Embers thicken with the square, same-frame.
    if (_w > 0 && _h > 0) {
      _field.spawnEmbers(
        dt: dt,
        leftAnchor: pylonLeft,
        rightAnchor: pylonRight,
        sagY: wireSagPx,
        glow: wireGlow,
        color: Color.lerp(SLTune.heat, SLTune.heatCore, wireGlow * 0.5)!,
        calm: reducedMotion,
      );
      _field.spawnMotes(
        dt: dt,
        stageW: _w,
        stageH: _h,
        color: SLTune.coolMote,
        calm: reducedMotion,
      );
      _field.update(dt);
    }

    // Discovery flash envelope.
    if (_flashActive) {
      _flashElapsed += dt;
      if (_flashElapsed >= SLTune.flashSeconds) _flashActive = false;
    }
    // Glow-leap punctuation envelope (the 4× jump punch at a detent landing).
    if (_leapActive) {
      _leapElapsed += dt;
      if (_leapElapsed >= SLTune.leapPulseSeconds) _leapActive = false;
    }

    notifyListeners();
  }

  void _advanceRolls(double dt) {
    if (reducedMotion) {
      _displayHeat = _heatTarget; // reduced motion → digits step, not roll
      _displayVolts = _voltsTarget;
      return;
    }
    if (_heatRollElapsed < SLTune.rollSeconds) {
      _heatRollElapsed += dt;
      final t = (_heatRollElapsed / SLTune.rollSeconds).clamp(0.0, 1.0);
      _displayHeat = _heatRollFrom + (_heatTarget - _heatRollFrom) * _easeOut(t);
      if (t >= 1.0) _displayHeat = _heatTarget;
    } else {
      _displayHeat = _heatTarget;
    }
    if (_voltsRollElapsed < SLTune.rollSeconds) {
      _voltsRollElapsed += dt;
      final t = (_voltsRollElapsed / SLTune.rollSeconds).clamp(0.0, 1.0);
      _displayVolts = _voltsRollFrom + (_voltsTarget - _voltsRollFrom) * _easeOut(t);
      if (t >= 1.0) _displayVolts = _voltsTarget;
    } else {
      _displayVolts = _voltsTarget;
    }
  }

  static double _easeOut(double t) => 1 - math.pow(1 - t, 3).toDouble();

  /// The recent close-pulse intensity [0,1] for the curve glow (fast in, slow out).
  double get curveClosePulse {
    if (!_curveClosed) return 0;
    const dur = 0.5;
    final t = (_curveCloseElapsed / dur).clamp(0.0, 1.0);
    return t < 0.2 ? t / 0.2 : 1.0 - (t - 0.2) / 0.8;
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelTimers();
    caption.dispose();
    phase.dispose();
    chip.dispose();
    showCardEarn.dispose();
    done.dispose();
    super.dispose();
  }
}
