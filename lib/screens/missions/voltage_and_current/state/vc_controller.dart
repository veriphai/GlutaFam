// Voltage and Current — the activity controller (PRD §14 state machine).
// Controller-owns-geometry: the stage reports its size once per paint; the
// controller computes every anchor (factor × stage), runs the sim, and drives a
// SILENT step machine. The painter is a pure renderer reading getters only.
//
// THE LOAD-BEARING RULES:
//  • current = kCurrentRatio × voltage, HARD-GATED to 0 the same frame voltage ≤
//    cutoffFloor — no decay, no fade tail, reduced-motion changes nothing here
//    (PRD §6.4, §11.2). The lamp, mote speed AND mote alpha die in that frame.
//  • ONLY the voltage column is grabbable. The current is never set — it answers
//    (PRD §3.3, §11.5). The pointer hit-test is limited to the source station.
//  • THE WIRE IS PINNED. The "SAME WIRE" chip is a LABEL, never a number, visible
//    100% of the activity. The word "resistance" appears nowhere (that's 2.2).

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Offset, Size, Rect, RRect, Radius;

import '../config/vc_config.dart';
import '../config/vc_copy.dart';

enum VCPhase { intro, exploreUp, dropPrompt, cutoff, naming, pinBeat, synthesis, done }

/// A tiny live particle (surge feed + cutoff scatter). Plain struct updated in
/// tick(dt) — the crank_particles.dart pattern, no packages, no Forge2D.
class VCParticle {
  VCParticle({
    required this.pos,
    required this.vel,
    required this.life,
    required this.maxLife,
    required this.size,
  });
  Offset pos;
  Offset vel;
  double life;
  final double maxLife;
  final double size;
  double get t => (life / maxLife).clamp(0.0, 1.0); // 1 → 0 over its life
}

class VCController extends ChangeNotifier {
  VCController();

  // ── Discrete UI channels (rebuild only on change) ────────────────────
  /// The big top caption — an imperative or a meaning-line; the flags drive style.
  final ValueNotifier<VCCaption> caption = ValueNotifier(const VCCaption(''));
  final ValueNotifier<VCPhase> phase = ValueNotifier(VCPhase.intro);
  final ValueNotifier<bool> showCardEarn = ValueNotifier(false);
  final ValueNotifier<bool> canFinish = ValueNotifier(false);

  // ── Polish hooks (haptics — wired in the shell) ──────────────────────
  void Function()? onDetent; // selectionClick per 10-unit column detent + on T2
  void Function()? onDiscovery; // heavyImpact at the cutoff double-death

  /// Episode-board capture hook: fired with the evidence-tile id when the
  /// "Voltage is the push, current is the flow" beat lands (the VOLTAGE/CURRENT
  /// labels are on screen). Captures the 2.1 distractor 'push_flow'.
  void Function(String evidenceId)? onCapture;

  /// Reduced motion (MediaQuery.disableAnimations): calm ambient motes + fade-style
  /// reveals. The zero-cutoff is NEVER softened.
  bool reducedMotion = false;

  // ── Geometry (pixels = factors × stage size) ─────────────────────────
  Size _stage = Size.zero;
  Size get stageSize => _stage;
  void setStageSize(Size s) => _stage = s;

  Offset _f(Offset factor) => Offset(factor.dx * _stage.width, factor.dy * _stage.height);
  double _fx(double f) => f * _stage.width;
  double _fy(double f) => f * _stage.height;

  Offset get lampCenter => _f(VCTune.lampFactor);
  double get lampRadius => _fx(VCTune.lampRadiusFactor);
  double get lampBloomRadius => _fx(VCTune.lampBloomFactor);

  Offset get currentChipCenter => _f(VCTune.currentChipFactor);
  Offset get pinChipCenter => _f(VCTune.pinChipFactor);

  // ── The pressure console + glowing piston (P0.3) ─────────────────────
  Offset get consoleCenter => _f(VCTune.consoleFactor);
  double get consoleWidth => _fx(VCTune.consoleWidthFactor);
  double get consoleHeight => _fy(VCTune.consoleHeightFactor);

  Rect get consoleRect =>
      Rect.fromCenter(center: consoleCenter, width: consoleWidth, height: consoleHeight);

  /// The vertical piston track rect (where the head travels, bottom = 0 V, top = 1 V).
  Rect get trackRect {
    final r = consoleRect;
    final inset = _fy(VCTune.trackInsetFactor);
    final w = _fx(VCTune.trackWidthFactor);
    return Rect.fromLTRB(
      r.center.dx - w / 2,
      r.top + inset,
      r.center.dx + w / 2,
      r.bottom - inset,
    );
  }

  /// The y the piston head sits at for the current voltage (0 V → track bottom).
  double get pistonHeadY {
    final t = trackRect;
    return t.bottom - t.height * _voltage.clamp(0.0, 1.0);
  }

  double get pistonHeadWidth => _fx(VCTune.pistonHeadWidthFactor);
  double get pistonHeadHeight => _fy(VCTune.pistonHeadHeightFactor);

  /// The piston head rect (the wide rounded knob bar the finger pushes).
  Rect get pistonHeadRect => Rect.fromCenter(
        center: Offset(consoleCenter.dx, pistonHeadY),
        width: pistonHeadWidth,
        height: pistonHeadHeight,
      );

  /// The full drag target — the whole console rect (PRD §16), with slop. Kept
  /// forgiving so the finger can grab the head OR anywhere in the console.
  Rect get consoleHitRect {
    final c = consoleCenter;
    final pad = Offset(_fx(0.06), _fy(0.04));
    return Rect.fromCenter(
      center: c,
      width: consoleWidth + pad.dx * 2,
      height: consoleHeight + pad.dy * 2,
    );
  }

  /// The loop path as a rounded rect (motes ride it; the painter strokes it).
  RRect get loopRRect {
    final left = _fx(VCTune.loopLeftX);
    final right = _fx(VCTune.loopRightX);
    final top = _fy(VCTune.loopTopY);
    final bottom = _fy(VCTune.loopBottomY);
    return RRect.fromRectAndRadius(
      Rect.fromLTRB(left, top, right, bottom),
      Radius.circular(_fx(VCTune.loopCornerFactor)),
    );
  }

  double get wireStroke => _fx(VCTune.wireStrokeFactor);

  // ── Sim state (hot path — read via getters) ──────────────────────────
  double _voltage = 0; // 0–1, slider-set
  double _lampBrightness = 0;
  double _motePhase = 0; // 0–1, advances clockwise ∝ current
  double _maxVoltageEver = 0;

  // Premium animation state (P0/P1/P2).
  double _breathPhase = 0; // lamp breathing clock (only matters while lit)
  double _sheenPhase = 0; // conductive-sheen band travel (loops, only while live)
  double _entrance = 0; // 0→1 orchestrated energize-in envelope
  double _displayCurrentRoll = 0; // smoothed CURRENT (rolls UP, hard-zero down)
  double _displayVoltageRoll = 0; // smoothed VOLTAGE (rolls UP, hard-zero at cutoff)
  double _shockElapsed = -1; // dark shockwave envelope at cutoff (-1 inactive)

  /// Live particle pools (the crank_particles pattern; cleared instantly at cutoff
  /// for the surge feed — the cutoff is total, nothing lingers).
  final List<VCParticle> _surge = []; // console → loop feed (∝ current)
  final List<VCParticle> _scatter = []; // cutoff after-punctuation burst
  double _surgeAcc = 0; // surge spawn accumulator

  bool _dragging = false;
  double _dragStartY = 0;
  double _dragStartVoltage = 0;
  double _lastDetent = 0; // last crossed detent index (for haptics)

  // Sustain / dwell accumulators.
  double _highSustain = 0; // V ≥ 80 sustained → drop prompt

  // Envelopes / reveals.
  double _flashElapsed = -1; // cutoff discovery flash (-1 = inactive)
  double _loopReveal = 0;
  double _sourceReveal = 0;
  double _chipReveal = 0;
  double _ambientPhase = 0;

  // Step-machine bookkeeping.
  double _step = -1; // ms countdown to the next auto-transition
  void Function()? _stepAction;
  bool _started = false;
  bool _pushFlowFired = false;

  // ── Read-only getters for the renderer ───────────────────────────────
  double get voltage => _voltage;

  /// The current — the ANSWER. Hard-gated to 0 at/below the cutoff floor so the
  /// double-death is instant (no smoothing on the way down).
  double get current => _voltage <= VCTune.cutoffFloor ? 0 : _voltage * VCTune.kCurrentRatio;

  double get lampBrightness => _lampBrightness;
  double get motePhase => _motePhase;

  /// Mote alpha rides current → 0 the same frame current is 0 (motes vanish).
  double get moteAlpha => current <= 0 ? 0 : (0.35 + 0.65 * (current / VCTune.kCurrentRatio));

  /// DENSITY scales with current (P0.2): a thin river at low voltage, a thick one
  /// at full. 0 the same frame current is 0 (the river vanishes — caller guards).
  int get moteCount {
    if (current <= 0) return 0;
    final f = (current / VCTune.kCurrentRatio).clamp(0.0, 1.0);
    return (VCTune.moteCountMin + (VCTune.moteCountMax - VCTune.moteCountMin) * f).round();
  }

  // ── The two LIVE numbers — VOLTAGE (on the head) + CURRENT (gauge) ────
  // displayVoltage/displayCurrent are the *target* integers (used for gating-free
  // truth). The painter reads the *rolled* values, which lerp UP only and HARD-
  // ZERO the same frame at cutoff (P2.9) — no roll-down lag.
  int get displayVoltage => (_voltage * VCTune.voltageScale).round();
  int get displayCurrent => (_voltage <= VCTune.cutoffFloor
      ? 0
      : (_voltage * VCTune.voltageScale * VCTune.kCurrentRatio).round());

  /// Rolled VOLTAGE shown on the piston head (lerps up; hard-zero at cutoff).
  int get rollVoltage => _displayVoltageRoll.round();

  /// Rolled CURRENT shown in the gauge (lerps up; hard-zero at cutoff same frame).
  int get rollCurrent => _displayCurrentRoll.round();

  double get loopReveal => _loopReveal;
  double get sourceReveal => _sourceReveal;
  double get chipReveal => _chipReveal;
  double get ambientPhase => _ambientPhase;
  double get entrance => _entrance.clamp(0.0, 1.0);

  /// The lamp "breath" multiplier on bloom/ray length (1 ± amp), only meaningful
  /// while lit. Reduced motion → no breathing. NEVER changes the hard zero (the
  /// caller multiplies it INTO brightness-gated values, so b=0 ⇒ nothing).
  double get lampBreath {
    if (reducedMotion) return 1.0;
    return 1.0 + VCTune.lampBreathAmp * math.sin(_breathPhase * 2 * math.pi * VCTune.lampBreathHz);
  }

  /// Conductive-sheen band head position along the loop (0..1); valid while live.
  double get sheenPhase => _sheenPhase % 1.0;

  /// The cool sheen is only present while current flows (COOL only, never warm).
  bool get sheenActive => current > 0 && !reducedMotion;

  /// The dark shockwave envelope from the dead lamp at cutoff (1 → 0, ~0.55 s).
  double get shockwave {
    if (_shockElapsed < 0) return 0;
    return (1 - _shockElapsed / VCTune.shockwaveSec).clamp(0.0, 1.0);
  }

  List<VCParticle> get surgeParticles => _surge;
  List<VCParticle> get scatterParticles => _scatter;

  /// The cutoff discovery flash envelope (rise-then-fall, ~0.7 s).
  double get flashIntensity {
    if (_flashElapsed < 0) return 0;
    final t = (_flashElapsed / VCTune.discoveryFlashSec).clamp(0.0, 1.0);
    return t < 0.15 ? t / 0.15 : 1.0 - (t - 0.15) / 0.85;
  }

  VCPhase get currentPhase => phase.value;

  // ── Lifecycle ────────────────────────────────────────────────────────
  void start() {
    if (_started) return;
    _started = true;
    phase.value = VCPhase.exploreUp; // slider is live immediately (PRD §6.1)
    _schedule(VCCopy.introToT1Ms, () {
      if (phase.value == VCPhase.exploreUp && caption.value.text.isEmpty) {
        caption.value = VCCopy.t1RaiseVoltage;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  // ── Input — ONLY the pressure console / piston (PRD §3.3, §6.2) ──────
  // The forgiving hit-test: the finger may grab the piston head OR anywhere in
  // the console. Pointer events on the wire / lamp / motes / CURRENT gauge change
  // NOTHING (the current is an answer — never a handle).
  void onPointerDown(Offset local) {
    if (!consoleHitRect.contains(local)) return; // asymmetry: wire/lamp/chip do nothing
    _dragging = true;
    _dragStartY = local.dy;
    _dragStartVoltage = _voltage;
    _lastDetent = (_voltage / VCTune.detentStep).floorToDouble();
  }

  void onPointerMove(Offset local) {
    if (!_dragging) return;
    final range = _stage.height * VCTune.dragRangeFactor;
    if (range <= 0) return;
    // Drag UP (dy decreases) raises voltage.
    final delta = (_dragStartY - local.dy) / range;
    final next = (_dragStartVoltage + delta).clamp(0.0, 1.0);
    _setVoltage(next);
  }

  void onPointerUp() {
    _dragging = false;
  }

  void _setVoltage(double v) {
    if (v == _voltage) return;
    _voltage = v;
    // Detent haptics each 0.1 crossing.
    final detent = (_voltage / VCTune.detentStep).floorToDouble();
    if (detent != _lastDetent) {
      _lastDetent = detent;
      onDetent?.call();
    }
    if (_voltage > _maxVoltageEver) _maxVoltageEver = _voltage;
  }

  // ── Step transitions (cancelable, single-slot — PRD §14) ─────────────
  void _schedule(int ms, void Function() action) {
    _step = ms.toDouble();
    _stepAction = action;
  }

  void onCardCollected() {
    showCardEarn.value = false;
    caption.value = const VCCaption('');
    phase.value = VCPhase.done;
    canFinish.value = true;
    notifyListeners();
  }

  static double _approach(double cur, double target, double dt, double tau) =>
      cur + (target - cur) * (1 - math.exp(-dt / tau));

  /// easeOutCubic on a 0..1 input (clamped) — the entrance stagger curve.
  static double _ease01(double x) {
    final t = x.clamp(0.0, 1.0);
    final inv = 1 - t;
    return 1 - inv * inv * inv;
  }

  final math.Random _rng = math.Random(91);

  // ── Surge particles (P1.4): console → loop feed, rate ∝ current ──────
  void _updateSurge(double dt, double cur) {
    // advance + cull
    for (final p in _surge) {
      p.pos += p.vel * dt;
      p.life -= dt;
    }
    _surge.removeWhere((p) => p.life <= 0);

    // HARD CUTOFF: no current ⇒ no feed AND clear instantly (nothing lingers).
    if (cur <= 0 || reducedMotion) {
      if (cur <= 0) _surge.clear();
      _surgeAcc = 0;
      return;
    }
    if (_stage == Size.zero) return;
    final f = (cur / VCTune.kCurrentRatio).clamp(0.0, 1.0);
    _surgeAcc += dt * VCTune.surgeSpawnRate * f;
    final rise = _stage.height * VCTune.surgeRiseSpeedFactor;
    // feed points: the two LOWER loop corners (~0.70h), where the console meets
    // the loop. left run x ≈ loopLeftX, right run x ≈ loopRightX.
    while (_surgeAcc >= 1) {
      _surgeAcc -= 1;
      if (_surge.length >= VCTune.surgeMax) break;
      final left = _rng.nextBool();
      final x = (left ? VCTune.loopLeftX : VCTune.loopRightX) * _stage.width +
          (_rng.nextDouble() - 0.5) * _fx(0.03);
      final y = _fy(VCTune.loopBottomY) + (_rng.nextDouble() - 0.5) * _fy(0.02);
      _surge.add(VCParticle(
        pos: Offset(x, y),
        vel: Offset((_rng.nextDouble() - 0.5) * rise * 0.18, -rise * (0.7 + _rng.nextDouble() * 0.6)),
        life: VCTune.surgeLifeSec * (0.6 + _rng.nextDouble() * 0.4),
        maxLife: VCTune.surgeLifeSec,
        size: _fx(0.006) * (0.7 + _rng.nextDouble() * 0.8),
      ));
    }
  }

  // ── Scatter burst (P1.6): the cutoff after-punctuation (NOT the death) ─
  void _spawnScatter() {
    if (reducedMotion) return; // calm under reduced motion (death is still instant)
    if (_stage == Size.zero) return;
    final speed = _stage.width * VCTune.scatterSpeedFactor;
    // scatter from the loop perimeter (where the river was), flying outward.
    final loop = loopRRect.outerRect;
    final ctr = loop.center;
    final n = 22;
    for (var i = 0; i < n; i++) {
      final a = i / n * 2 * math.pi + _rng.nextDouble() * 0.3;
      // start somewhere on the loop, push radially out from the loop centre.
      final r = loop.shortestSide * 0.5 * (0.6 + _rng.nextDouble() * 0.5);
      final pos = ctr + Offset(math.cos(a), math.sin(a)) * r;
      _scatter.add(VCParticle(
        pos: pos,
        vel: Offset(math.cos(a), math.sin(a)) * speed * (0.5 + _rng.nextDouble() * 0.8),
        life: VCTune.scatterLifeSec * (0.6 + _rng.nextDouble() * 0.4),
        maxLife: VCTune.scatterLifeSec,
        size: _fx(0.007) * (0.7 + _rng.nextDouble() * 0.8),
      ));
    }
  }

  void _updateScatter(double dt) {
    if (_scatter.isEmpty) return;
    for (final p in _scatter) {
      p.pos += p.vel * dt;
      p.vel *= (1 - 2.2 * dt).clamp(0.0, 1.0); // drag, so they decelerate as they fade
      p.life -= dt;
    }
    _scatter.removeWhere((p) => p.life <= 0);
  }

  // ── The tick: sim + the silent step machine ──────────────────────────
  void tick(double dt) {
    if (dt <= 0) return;
    _ambientPhase += dt;
    _breathPhase += dt; // lamp breathing clock (only sampled while lit)
    final ph = phase.value;
    final v = _voltage;
    final cur = current;

    // 1) Lamp brightness — ripple toward current WHILE lit, HARD-GATED to 0 the
    //    same frame current is 0 (the instant double-death — never a cool-down).
    if (cur > 0) {
      // normalize current to 0–1 for brightness (current max = kCurrentRatio).
      final target = (cur / VCTune.kCurrentRatio).clamp(0.0, 1.0);
      _lampBrightness = _approach(_lampBrightness, target, dt, VCTune.lampRippleTau);
    } else {
      _lampBrightness = 0; // HARD GATE — no fade
    }

    // 2) Mote stream + conductive sheen — advance ∝ current; frozen at current 0.
    if (cur > 0) {
      final speedFactor = cur / VCTune.kCurrentRatio;
      _motePhase = (_motePhase + dt * VCTune.moteBaseSpeed * speedFactor) % 1.0;
      _sheenPhase = (_sheenPhase + dt * VCTune.sheenLoopsPerSec * speedFactor) % 1.0;
    }

    // 2b) Display roll (P2.9): VOLTAGE + CURRENT lerp UP only; HARD-ZERO at cutoff.
    final tgtV = displayVoltage.toDouble();
    final tgtI = displayCurrent.toDouble();
    _displayVoltageRoll =
        tgtV <= 0 ? 0 : math.max(tgtV, _approach(_displayVoltageRoll, tgtV, dt, VCTune.displayRollTau));
    _displayCurrentRoll =
        tgtI <= 0 ? 0 : math.max(tgtI, _approach(_displayCurrentRoll, tgtI, dt, VCTune.displayRollTau));

    // 2c) Surge feed (P1.4): particles spawn at the lower loop corners ∝ current
    //     and stream UP into the loop. Reduced motion → calm (no surge spawn).
    _updateSurge(dt, cur);
    _updateScatter(dt);
    if (_shockElapsed >= 0) {
      _shockElapsed += dt;
      if (_shockElapsed >= VCTune.shockwaveSec) _shockElapsed = -1;
    }

    // 3) Explore up.
    if (ph == VCPhase.exploreUp) {
      if (v >= VCTune.highVoltage) {
        _highSustain += dt;
      } else {
        _highSustain = 0;
      }
      // Raised it and the current visibly follows → the "push / flow" lesson
      // label (interaction-fired, not a timer).
      if (!_pushFlowFired && v >= VCTune.pushFlowGate) {
        _pushFlowFired = true;
        caption.value = VCCopy.pushFlow;
        onDetent?.call();
        onCapture?.call('push_flow'); // 2.1 distractor — snap with VOLTAGE/CURRENT on screen
      }
      // After exploring up (V ≥ 80 sustained) → "Now Drop It to Zero".
      if (_pushFlowFired &&
          _highSustain >= VCTune.dropPromptSustainSec &&
          caption.value.text != VCCopy.t3DropToZero.text) {
        phase.value = VCPhase.dropPrompt;
        caption.value = VCCopy.t3DropToZero;
      }
    }

    // 4) THE CUTOFF (hard gate): first frame V ≤ floor with maxVoltageEver ≥ 80,
    //    while exploring/prompted. current/lamp/motes are already 0 this frame.
    if ((ph == VCPhase.exploreUp || ph == VCPhase.dropPrompt) &&
        v <= VCTune.cutoffFloor &&
        _maxVoltageEver >= VCTune.highVoltage) {
      phase.value = VCPhase.cutoff;
      _flashElapsed = 0; // start the discovery flash
      onDiscovery?.call(); // heavyImpact
      caption.value = VCCopy.t4NoVoltage;
      // CINEMATIC CUTOFF after-punctuation (P1.6) — the death itself already
      // happened THIS frame (current/lamp/motes/numbers are 0). These are ONLY
      // the punctuation: the river scatters outward + a dark shockwave expands.
      _spawnScatter();
      _shockElapsed = 0;
      // (No capture: this beat captures NO evidence tiles.) The cutoff line holds,
      // then the card earns — the lesson is complete in four lines.
      _schedule(VCCopy.cutoffToCardMs, () => showCardEarn.value = true);
    }

    // 5) Cutoff flash envelope.
    if (_flashElapsed >= 0) {
      _flashElapsed += dt;
      if (_flashElapsed >= VCTune.discoveryFlashSec) _flashElapsed = -1;
    }


    // 8) Orchestrated entrance (P1.7): a single energize-in envelope drives the
    //    loop / console / lamp-first-breath together (richer than uniform fades),
    //    quick (~0.9 s) and reduced-motion-friendly. The legacy reveal getters are
    //    kept (painter reads them) but staged off this one envelope.
    if (_entrance < 1) {
      _entrance = (_entrance + dt / (reducedMotion ? 0.22 : VCTune.entranceSec)).clamp(0.0, 1.0);
    }
    final e = _entrance;
    // loop energizes first (0→0.6), console rises just after (0.15→0.85), chip
    // pins on last (0.55→1.0). Eased so the scene assembles, not just fades.
    _loopReveal = _ease01(e / 0.6);
    _sourceReveal = ph == VCPhase.intro ? 0.0 : _ease01((e - 0.15) / 0.70);
    _chipReveal = _ease01((e - 0.55) / 0.45);

    // 9) Scheduled transition timer.
    if (_step > 0) {
      _step -= dt * 1000;
      if (_step <= 0) {
        _step = -1;
        final a = _stepAction;
        _stepAction = null;
        a?.call();
      }
    }

    notifyListeners();
  }

  @override
  void dispose() {
    caption.dispose();
    phase.dispose();
    showCardEarn.dispose();
    canFinish.dispose();
    super.dispose();
  }
}
