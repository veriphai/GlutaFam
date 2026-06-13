// The Transformer — the activity controller (controller-owns-geometry). Owns the
// sim, the geometry, the phase machine, and the discrete UI channels; the Flame
// game reports the stage size once, forwards the vertical wind gesture, and ticks
// the controller each frame. Every scene layer is a near-pure renderer reading
// these getters.
//
// THE LOAD-BEARING RULES (hard gates in tick — never a fade):
//   • Each wind detent steps turnsOut, outVoltage and lineReach in the SAME frame.
//   • In windDown the far pylon goes DARK the frame OUT drops below 200.
//   • In slowSurge the output kick == |d(field)/dt| every frame (slack at the
//     bloom crest, alive on rise + fall). The line-13 caption + heavyImpact land
//     AT the 2600 ms kick frame. (This beat captures the 'turns_step_up' tile only;
//     the 'changing_field' distractor was dropped from the EP2 set.)
// Nothing here ever feeds a steady current — the cliffhanger stays unanswered.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Offset, Size;

import '../config/transformer_copy.dart';
import '../config/transformer_tuning.dart';

enum TxPhase {
  intro,
  windUp,
  windDown,
  watchCore,
  slowSurge,
  depthStop,
  synthesis,
  cliffhanger,
  done,
}

class TransformerController extends ChangeNotifier {
  TransformerController();

  // --- Discrete UI channels (rebuild only on change) -------------------------
  /// The big top caption — an imperative ("Wind the Coil") or a meaning-line
  /// (the lesson); the [TxCaption.meaning]/[long] flags drive the style.
  final ValueNotifier<TxCaption> caption = ValueNotifier(const TxCaption(''));

  /// The intro's secondary line (the "needs more voltage" hook under line 1).
  final ValueNotifier<TxCaption?> secondaryCaption = ValueNotifier(null);

  final ValueNotifier<TxPhase> phase = ValueNotifier(TxPhase.intro);

  /// The secondary coil's turns (2..8, detented). Discrete so the chips/loops
  /// rebuild only on a step (the value lands instantly — no easing on the step).
  final ValueNotifier<int> turnsOut = ValueNotifier(TxTune.startTurns);

  final ValueNotifier<bool> showCardEarn = ValueNotifier(false);
  final ValueNotifier<bool> showContinue = ValueNotifier(false);

  // --- Polish hooks (haptics) ------------------------------------------------
  void Function()? onDetent; // selectionClick per wind detent
  void Function()? onKick; // heavyImpact at the slowSurge output kick + ignition

  /// Episode-board capture hook: fired with the evidence-tile id at the windUp
  /// ignition — 'turns_step_up' (relevant: voltage stepped up for the journey).
  /// The shell snapshots the real scene + pins it.
  void Function(String evidenceId)? onCapture;

  /// Reduced motion (MediaQuery.disableAnimations): calm motes + softer flash —
  /// but the surge breathing, the same-frame OUT steps, the pylon-dark frame and
  /// the kick-tracks-change behaviour are pedagogical and are NEVER softened.
  bool reducedMotion = false;

  // --- Geometry (pixels = factors × stage size) ------------------------------
  Size _stage = Size.zero;
  Size get stageSize => _stage;
  void setStageSize(Size s) => _stage = s;

  Offset _f(Offset factor) => Offset(factor.dx * _stage.width, factor.dy * _stage.height);
  Offset get coreCenter => _f(TxTune.coreCenterFactor);
  Offset get outChip => _f(TxTune.outChipFactor);
  Offset get plant => _f(TxTune.plantFactor);
  Offset get inChip => _f(TxTune.inChipFactor);

  double get coreOuterW => TxTune.coreOuterWFactor * _stage.width;
  double get coreOuterH => TxTune.coreOuterHFactor * _stage.height;
  double get limbThickness => TxTune.limbThicknessFactor * _stage.width;

  /// The output conductor leaves the SECONDARY (right) limb top — the HV bushing —
  /// and the input conductor enters the PRIMARY (left) limb bottom (the LV side).
  /// Anchored to the actual limbs so the wires always meet the coils as the core
  /// resizes (no fixed factor drifting off the enlarged hero).
  Offset get outputFrom => Offset(
        coreCenter.dx + coreOuterW * 0.5 - limbThickness * 0.7,
        coreCenter.dy - coreOuterH * 0.5 + limbThickness * 0.6,
      );
  Offset get inputTo => Offset(
        coreCenter.dx - coreOuterW * 0.5 + limbThickness * 0.7,
        coreCenter.dy + coreOuterH * 0.5 - limbThickness * 0.6,
      );

  /// The receding transmission towers' apexes (where the conductor is suspended).
  /// The last is the farthest tower = the city / ignition target.
  List<Offset> get towerApexes =>
      TxTune.towerApexFactors.map(_f).toList(growable: false);
  List<double> get towerScales => TxTune.towerScales;
  double get towerHeight => TxTune.towerHeightFactor * _stage.height;

  /// The gesture rect — the right (secondary) limb ± a comfortable margin (PRD
  /// §16: right limb ±(0.16w, 0.20h)). The ONLY interactive surface.
  bool secondaryLimbHit(Offset local) {
    if (_stage.isEmpty) return false;
    final cx = coreCenter.dx + coreOuterW * 0.5; // right limb x
    final dx = (local.dx - cx).abs();
    final dy = (local.dy - coreCenter.dy).abs();
    return dx <= _stage.width * 0.18 && dy <= _stage.height * 0.22;
  }

  // --- Live, derived values --------------------------------------------------
  double get inVoltage => TxTune.inVoltage; // pinned, alive
  double get outVoltage => TxTune.outVoltageFor(turnsOut.value);
  double get lineReach => TxTune.lineReachFor(turnsOut.value);
  bool get atMaxTurns => turnsOut.value >= TxTune.maxTurns;
  bool get atMinTurns => turnsOut.value <= TxTune.minTurns;

  // --- Hot-path sim state (read by the renderer via getters) -----------------
  double _surgePhase = 0; // 0..1 looping input-surge clock
  double _fieldBloom = 0; // core field intensity, follows the surge
  double _prevField = 0;
  double _fieldRate = 0; // |d(fieldBloom)/dt|, normalised
  double _outputKick = 0; // output-side activity ∝ fieldRate (the honest envelope)
  double _outputPhase = 0; // 0..1 output-pulse travel clock — advances ∝ outputKick
  //                          in slowSurge so the pulses visibly STALL at the crest.
  double _coilWindT = 1; // 0..1 per-detent loop-wrap animation (1 = settled)
  double _flashIntensity = 0; // kick + ignition flash envelope
  double _sceneDim = 0; // watchCore / cliffhanger dimming
  double _shimmer = 0; // free-running clock for ambient shimmer
  double _ignitionT = 0; // 0..1 ignition pulse-train progress (windUp gate)
  bool _farPylonLit = false; // the farthest pylon (only true at OUT 200, post-ignition)
  double _coreReveal = 0; // entrance reveals
  double _coilReveal = 0;
  double _lineReveal = 0;
  double _pylonReveal = 0;
  double _rewindT = 0; // synthesis auto-rewind progress
  int _rewindStart = TxTune.maxTurns; // turns value when synthesis rewind began

  // The scripted slowSurge clock (seconds within the isolated single surge).
  double _surgeClock = 0;
  bool _surgeKickFired = false;

  // Read-only getters for the renderer.
  double get surgePhase => _surgePhase;
  double get fieldBloom => _fieldBloom;
  double get fieldRate => _fieldRate;
  double get outputKick => _outputKick;
  double get outputPhase => _outputPhase;
  double get coilWindT => _coilWindT;
  double get flashIntensity => _flashIntensity;
  double get sceneDim => _sceneDim;
  double get shimmer => _shimmer;
  double get ignitionT => _ignitionT;
  bool get farPylonLit => _farPylonLit;
  double get coreReveal => _coreReveal;
  double get coilReveal => _coilReveal;
  double get lineReveal => _lineReveal;
  double get pylonReveal => _pylonReveal;
  TxPhase get currentPhase => phase.value;
  bool get isSlowSurge => phase.value == TxPhase.slowSurge;

  /// True while the learner may wind/unwind (windUp before ignition, windDown).
  bool get windingLive =>
      (phase.value == TxPhase.windUp && _ignitionT <= 0) ||
      phase.value == TxPhase.windDown;

  /// Show the grab hint on the secondary limb until the learner first winds.
  bool _touchedLimb = false;
  bool get grabHintActive => windingLive && !_touchedLimb;

  // --- Step machine bookkeeping ----------------------------------------------
  bool _started = false;
  bool _windUpFirstTurn = false; // first added turn → "More Turns — Higher Voltage"
  bool _windDownFirstTurn = false; // first removed turn → "Fewer Turns — Lower Voltage"
  bool _ignited = false; // ignition fired once

  // --- Wind gesture (vertical drag, NO momentum) -----------------------------
  bool _dragging = false;
  double _dragAccum = 0; // signed px accumulated toward the next detent
  double _lastDy = 0;

  void onPointerDown(Offset local) {
    if (!windingLive) return;
    if (!secondaryLimbHit(local)) return;
    _dragging = true;
    _dragAccum = 0;
    _lastDy = local.dy;
    _touchedLimb = true;
  }

  void onPointerMove(Offset local) {
    if (!_dragging || !windingLive) return;
    // Drag UP (dy decreasing) winds ON; drag DOWN (dy increasing) unwinds.
    final dy = local.dy;
    _dragAccum += _lastDy - dy; // +ve = upward = wind on
    _lastDy = dy;
    while (_dragAccum >= TxTune.detentDrag) {
      _dragAccum -= TxTune.detentDrag;
      _stepTurns(1);
    }
    while (_dragAccum <= -TxTune.detentDrag) {
      _dragAccum += TxTune.detentDrag;
      _stepTurns(-1);
    }
  }

  void onPointerUp() {
    // Release stops detents WHERE THEY ARE — no momentum, no settle drift.
    _dragging = false;
    _dragAccum = 0;
  }

  /// Apply one detent step. OUT, reach and the loop-wrap animation all land in
  /// the SAME frame (criterion 2). selectionClick per detent.
  void _stepTurns(int delta) {
    final next = (turnsOut.value + delta).clamp(TxTune.minTurns, TxTune.maxTurns);
    if (next == turnsOut.value) return; // clamped — no phantom detent
    final ph = phase.value;
    // Only the right direction is exploration-relevant per beat, but both are
    // allowed inside windUp/windDown so the relationship reads either way.
    turnsOut.value = next;
    _coilWindT = 0; // restart the loop-wrap flourish (visual only — step is instant)
    onDetent?.call();

    if (ph == TxPhase.windUp) {
      if (!_windUpFirstTurn && delta > 0) {
        _windUpFirstTurn = true;
        _schedule(TxTune.windUpFirstTurnLineMs, () {
          if (phase.value == TxPhase.windUp && !_ignited) caption.value = TxCopy.moreTurns;
        });
      }
      if (atMaxTurns && !_ignited) _startIgnition();
    } else if (ph == TxPhase.windDown) {
      if (!_windDownFirstTurn && delta < 0) {
        _windDownFirstTurn = true;
        caption.value = TxCopy.fewerTurns;
      }
      if (atMinTurns) _exitWindDown();
    }
    notifyListeners();
  }

  // --- Lifecycle / phase entry ----------------------------------------------
  void start() {
    if (_started) return;
    _started = true;
    // The intro caption is CUT (the motivation carried over from 2.5) — the scene
    // just reveals in, then goes straight to the wind gesture. No intro text.
    caption.value = const TxCaption('');
    _schedule(TxTune.introMs, _enterWindUp);
    notifyListeners();
  }

  void _enterWindUp() {
    phase.value = TxPhase.windUp;
    secondaryCaption.value = null;
    caption.value = TxCopy.windCoil;
    notifyListeners();
  }

  void _startIgnition() {
    if (_ignited) return;
    _ignited = true;
    _ignitionT = 0.0001; // > 0 so windingLive locks; advanced in tick
    onKick?.call(); // the far pylon catching light is a discovery beat
    notifyListeners();
  }

  void _onIgnitionComplete() {
    _farPylonLit = true; // the farthest pylon is now lit (OUT 200)
    _startFlash(0.8);
    onCapture?.call('turns_step_up'); // relevant: voltage stepped up for the journey
    caption.value = TxCopy.twiceVoltage;
    _schedule(TxTune.ignitionHoldMs, _enterWindDown);
    notifyListeners();
  }

  void _enterWindDown() {
    phase.value = TxPhase.windDown;
    caption.value = TxCopy.unwindCoil;
    notifyListeners();
  }

  void _exitWindDown() {
    caption.value = TxCopy.stepsDown;
    _schedule(TxTune.windDownExitHoldMs, _enterWatchCore);
    notifyListeners();
  }

  void _enterWatchCore() {
    phase.value = TxPhase.watchCore;
    // One directive line; it persists through the slow-mo build-up until the kick
    // swaps it for the induction line (the animation does the teaching).
    caption.value = TxCopy.watchCore; // "Watch the Core — Nothing Moves"
    _schedule(TxTune.watchCoreMs, _enterSlowSurge);
    notifyListeners();
  }

  void _enterSlowSurge() {
    phase.value = TxPhase.slowSurge;
    _surgeClock = 0;
    _surgeKickFired = false;
    // Start the witnessed surge from rest. The scripted bloom forces _fieldBloom
    // to 0 on the first slowSurge frame; without re-seeding _prevField (which
    // still holds the ambient field's last value, 0..1), the first dField would
    // spike _fieldRate/_outputKick and flash the output limb / FlashLayer for one
    // frame. Seed the honest envelope at rest so the bloom builds cleanly.
    _fieldBloom = 0;
    _prevField = 0;
    _fieldRate = 0;
    _outputKick = 0;
    // The "Watch the Core — Nothing Moves" line persists through the build-up; the
    // single induction line lands AT the output kick (fired by the surge clock at
    // 2600 ms, hard-synced to the field's rate — NOT a wall-clock timer).
    _schedule(TxTune.slowSurgeMs, _enterDepthStop);
    notifyListeners();
  }

  void _fireSurgeKick() {
    if (_surgeKickFired) return;
    _surgeKickFired = true;
    _startFlash(1.0);
    onKick?.call(); // heavyImpact at the output kick
    // (No capture here — the 'changing_field' distractor was dropped from the EP2 set.)
    caption.value = TxCopy.induction; // the one collapsed induction line, AT the kick
    notifyListeners();
  }

  void _enterDepthStop() {
    phase.value = TxPhase.depthStop;
    caption.value = TxCopy.depthStop;
    _schedule(TxTune.depthStopMs, _enterSynthesis);
    notifyListeners();
  }

  void _enterSynthesis() {
    phase.value = TxPhase.synthesis;
    caption.value = TxCopy.synthesis;
    _rewindT = 0; // auto-rewind turns to 8 (the device returns to its grid job)
    _rewindStart = turnsOut.value;
    _schedule(TxTune.synthesisMs, _enterCliffhanger);
    notifyListeners();
  }

  void _enterCliffhanger() {
    phase.value = TxPhase.cliffhanger;
    // Cliffhanger QUESTION removed (per request) — the synthesis takeaway from
    // the previous phase persists through this hold instead of posing the
    // "what if the current were steady?" line (that belongs to 2.7). The card
    // still fires after the same hold below.
    _schedule(TxTune.cliffLine2Ms + TxTune.cliffToCardMs, () {
      phase.value = TxPhase.done;
      showCardEarn.value = true;
      notifyListeners();
    });
    notifyListeners();
  }

  void onCardCollected() {
    showCardEarn.value = false;
    // The cliffhanger line persists behind the Continue CTA (never answered here).
    caption.value = TxCopy.cliffhanger;
    showContinue.value = true;
    notifyListeners();
  }

  // --- Timers ----------------------------------------------------------------
  // A small list of independent timers so several lines can be scheduled per
  // phase without a single one cancelling another (intro/watchCore/slowSurge each
  // queue multiple lines plus the phase advance).
  final List<_Timer> _timers = [];
  void _schedule(int ms, void Function() action) {
    _timers.add(_Timer(ms.toDouble(), action));
  }

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

  static double _approach(double cur, double target, double dt, double tau) =>
      cur + (target - cur) * (1 - math.exp(-dt / tau));

  // --- The tick: sim + the silent step machine -------------------------------
  void tick(double dt) {
    if (dt <= 0) return;
    _shimmer += dt;
    final ph = phase.value;

    // 1) The always-alive input surge (the CHANGING current). In slowSurge the
    //    isolated single surge is scripted by _surgeClock; otherwise it loops.
    if (ph == TxPhase.slowSurge) {
      _surgeClock += dt; // already real-time; the *visual* dilation is the scripted shape
      _scriptSlowSurge();
    } else {
      final period = TxTune.surgePeriod;
      _surgePhase = (_surgePhase + dt / period) % 1.0;
      // A smooth breathing field that rises and falls — the rate of change is what
      // matters, so a sine (never momentarily flat except at the crest) is honest.
      final raw = 0.5 - 0.5 * math.cos(_surgePhase * 2 * math.pi);
      _fieldBloom = raw;
    }

    // 2) The honest envelope: outputKick == |d(field)/dt|, every frame. This is a
    //    HARD GATE — the output is slack exactly when the field stops changing
    //    (slack at the bloom crest, alive on the rise + fall). Normalised against
    //    the active phase's natural peak rate so the envelope reads a clean 0..1.
    final dField = (_fieldBloom - _prevField);
    _prevField = _fieldBloom;
    final rate = dt > 0 ? (dField.abs() / dt) : 0.0;
    // d/dt of the bloom shape peaks at: sine over surgePeriod (ambient), or the
    // half-cosine over slowSurgeBloomEnd (the dilated single surge).
    final maxRate = ph == TxPhase.slowSurge
        ? (math.pi / TxTune.slowSurgeBloomEnd) * 0.5
        : (2 * math.pi / TxTune.surgePeriod) * 0.5;
    _fieldRate = (rate / maxRate).clamp(0.0, 1.0);
    _outputKick = _fieldRate;

    // The output-pulse travel clock. In slowSurge it advances ∝ outputKick so the
    // pulses move on the field's rise + fall and visibly STALL at the bloom crest
    // (the honest |d(field)/dt| envelope, in MOTION not just brightness). Otherwise
    // the device is steadily sending, so it advances at a calm base speed.
    final outSpeed = ph == TxPhase.slowSurge ? 0.9 * _outputKick : 0.5;
    _outputPhase = (_outputPhase + dt * outSpeed) % 1.0;

    // 3) Loop-wrap flourish on a detent (visual only — the step itself is instant).
    _coilWindT = _approach(_coilWindT, 1, dt, 0.10);

    // 4) windUp ignition — the pulse-train sails to the horizon, then the far
    //    pylon lights (the gate resolves). Hard-timed, not eased.
    if (ph == TxPhase.windUp && _ignited && _ignitionT < 1.0) {
      _ignitionT = (_ignitionT + dt * 1000 / TxTune.ignitionMs).clamp(0.0, 1.0);
      if (_ignitionT >= 1.0) _onIgnitionComplete();
    }

    // 5) windDown — the far pylon goes DARK the frame OUT drops below 200 (hard
    //    sync, no fade tail). Re-arms if the learner winds back to max (rare).
    if (ph == TxPhase.windDown) {
      _farPylonLit = atMaxTurns;
    }

    // 6) synthesis — auto-rewind turns to 8 over 700 ms (no haptics). Steps one
    //    notch at a time from the value where windDown left off, toward max.
    if (ph == TxPhase.synthesis && turnsOut.value != TxTune.maxTurns) {
      _rewindT = (_rewindT + dt * 1000 / TxTune.synthesisRewindMs).clamp(0.0, 1.0);
      final wantTurns = (_rewindStart + ((TxTune.maxTurns - _rewindStart) * _rewindT).round())
          .clamp(TxTune.minTurns, TxTune.maxTurns);
      if (wantTurns != turnsOut.value) {
        turnsOut.value = wantTurns;
        _coilWindT = 0;
      }
      if (_rewindT >= 1.0) turnsOut.value = TxTune.maxTurns;
    }
    // From synthesis onward the device is sending stepped-up — the far pylon is lit.
    if (ph == TxPhase.synthesis || ph == TxPhase.cliffhanger || ph == TxPhase.done) {
      _farPylonLit = atMaxTurns;
    }

    // 7) Scene dim — watchCore tightens the vignette on the core; cliffhanger dims
    //    slightly so the field breathing becomes the loudest motion.
    final dimTarget = ph == TxPhase.watchCore || ph == TxPhase.slowSurge
        ? 0.30
        : (ph == TxPhase.cliffhanger || ph == TxPhase.done ? 0.18 : 0.0);
    _sceneDim = _approach(_sceneDim, dimTarget, dt, 0.45);

    // 8) Entrance reveals (intro) — slide+scale+fade in, each staggered: core
    //    first (0 ms), coils +150, lines +300, pylons +450 (PRD §6 intro).
    _coreReveal = _approach(_coreReveal, _shimmer >= 0.00 ? 1.0 : 0.0, dt, 0.45);
    _coilReveal = _approach(_coilReveal, _shimmer >= 0.15 ? 1.0 : 0.0, dt, 0.42);
    _lineReveal = _approach(_lineReveal, _shimmer >= 0.30 ? 1.0 : 0.0, dt, 0.40);
    _pylonReveal = _approach(_pylonReveal, _shimmer >= 0.45 ? 1.0 : 0.0, dt, 0.40);

    // 9) Flash envelope (kick + ignition).
    if (_flashActive) {
      _flashElapsed += dt;
      final t = (_flashElapsed / _flashSeconds).clamp(0.0, 1.0);
      _flashIntensity = (t < 0.15 ? t / 0.15 : 1.0 - (t - 0.15) / 0.85) * _flashPeak;
      if (_flashElapsed >= _flashSeconds) {
        _flashActive = false;
        _flashIntensity = 0;
      }
    }

    // 10) Drive the timers (dt in ms). A fired timer may schedule more.
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

  /// The scripted single surge during slowSurge (§6): input pulse enters
  /// (0–1.2 s), field blooms through the core (1.2–2.6 s) with the crest — where
  /// the field momentarily stops changing — at 2.6 s, then it falls. The output
  /// kick (== |d/dt|) is computed in tick from this shape, so it is slack at the
  /// crest and alive on the rise + fall. The clock loops so the phase keeps
  /// breathing, but the kick/capture fire only ON THE FIRST crest.
  void _scriptSlowSurge() {
    // Map real seconds → the dilated visual time so the shape is watchable.
    final t = _surgeClock;
    // A single half-cosine bloom: 0 at t=0, crest (1) at slowSurgeBloomEnd, then
    // it eases back down and the clock recycles to keep the field alive.
    final bloomEnd = TxTune.slowSurgeBloomEnd;
    final cycle = bloomEnd * 2; // rise to crest, then fall back over the same span
    final tc = t % cycle;
    if (tc <= bloomEnd) {
      _fieldBloom = 0.5 - 0.5 * math.cos(tc / bloomEnd * math.pi); // 0 → 1 (crest)
    } else {
      _fieldBloom = 0.5 + 0.5 * math.cos((tc - bloomEnd) / bloomEnd * math.pi); // 1 → 0
    }
    // The kick fires once, AT the crest of the first bloom (2600 ms).
    if (!_surgeKickFired && t >= bloomEnd) _fireSurgeKick();
  }

  /// Per-second display: the input surge clock (0..1) for chip shimmer sync.
  double get inChipShimmer => 0.85 + 0.15 * _fieldBloom;

  @override
  void dispose() {
    caption.dispose();
    secondaryCaption.dispose();
    phase.dispose();
    turnsOut.dispose();
    showCardEarn.dispose();
    showContinue.dispose();
    super.dispose();
  }
}

class _Timer {
  _Timer(this.remaining, this.action);
  double remaining;
  final void Function() action;
}
