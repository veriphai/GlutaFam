// War of the Currents — the activity controller (controller-owns-geometry). The
// Flame game reports the stage size once and ticks this each frame; every layer is
// a pure renderer reading these getters. This file owns the phase machine, the
// per-run scripts (a list of cancel-on-dispose Timers — PRD §14), the held-constant
// geometry, the two live numbers, and the HARD GATES.
//
// THE PEDAGOGY, made mechanical:
//   • The transformer core blooms ONLY on AC — `coreBloom` is forced to 0 for the
//     ENTIRE DC run (a hard absence, every frame — criterion 4).
//   • The DC failure is a HARD GATE: the frame `_failed` latches, the reach-front
//     stops, the pulses past it are killed, the flare fires once, the city flicker
//     is FORCED to 0 in the same frame (no fade tail) — reduced-motion changes
//     nothing about the cutoff (criterion 5).
//   • Both runs launch identically (same plant bloom, same feed pulses, same
//     VOLTAGE 10 / CURRENT 100) — the first divergent frame is at the transformer.
//
// No Forge2D: all motion is scripted/eased in tick(). Only free choice is run order.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Offset, Size;

import '../config/woc_copy.dart';
import '../config/woc_tuning.dart';

enum WocPhase { intro, choose, sending, interlude, war, done }

enum WocRun { dc, ac }

class WocController extends ChangeNotifier {
  WocController();

  // ── Discrete UI channels (rebuild only on change) ──────────────────────────
  final ValueNotifier<WocPhase> phase = ValueNotifier(WocPhase.intro);
  final ValueNotifier<WocLine> caption = ValueNotifier(WocLine.none);
  final ValueNotifier<WocRun?> activeRun = ValueNotifier(null);
  final ValueNotifier<bool> ranDc = ValueNotifier(false);
  final ValueNotifier<bool> ranAc = ValueNotifier(false);
  final ValueNotifier<bool> showContinue = ValueNotifier(false);
  final ValueNotifier<bool> showCardEarn = ValueNotifier(false);

  // ── Polish hooks (haptics + capture) ───────────────────────────────────────
  void Function()? onChipTap; // selectionClick per chip / fact chip
  void Function()? onFailure; // heavyImpact at the DC failure frame
  void Function(String id)? onCapture; // lightImpact + PNG in the shell

  /// Reduced motion (MediaQuery.disableAnimations): calm motes, entrance reveals
  /// become fades, the flare becomes a brief glow step. The same-frame city-dark
  /// gate, the V/I roll sync, and the dead-core absence stay EXACT.
  bool reducedMotion = false;

  // ── Geometry (pixels = factors × stage size) ───────────────────────────────
  Size _stage = Size.zero;
  Size get stageSize => _stage;
  void setStageSize(Size s) => _stage = s;
  Offset _f(Offset factor) => Offset(factor.dx * _stage.width, factor.dy * _stage.height);

  Offset get cityCenter => _f(WocTune.cityFactor);
  double get cityWidth => WocTune.cityWidthFactor * _stage.width;
  double get cityBaseY => WocTune.cityBaseFactor * _stage.height;
  Offset get transformerCenter => _f(WocTune.transformerFactor);
  double get transformerRadius => WocTune.transformerRadiusFactor * _stage.width;
  // Mini iron-core window dims (ported activity 6/7 transformer, kept small).
  double get miniCoreW => WocTune.miniCoreWFactor * _stage.width;
  double get miniCoreH => WocTune.miniCoreHFactor * _stage.height;
  double get miniLimb => WocTune.miniLimbFactor * _stage.width;
  Offset get plantCenter => _f(WocTune.plantFactor);
  double get plantWidth => WocTune.plantWidthFactor * _stage.width;
  double get plantBaseY => WocTune.plantBaseFactor * _stage.height;
  Offset get voltageChipPos => _f(WocTune.voltageChipFactor);
  Offset get currentChipPos => _f(WocTune.currentChipFactor);
  Offset get feedStart => _f(WocTune.feedStartFactor);
  Offset get feedEnd => _f(WocTune.feedEndFactor);

  /// The route polyline in pixels (index 0 = city/arrival end, last = transformer).
  List<Offset> get routePoints => WocTune.routeFactors.map(_f).toList(growable: false);

  // ── Entrance reveals (0..1) — set in tick() during intro ───────────────────
  double mapReveal = 0;
  double routeReveal = 0;
  double stationReveal = 0;
  double cityReveal = 0;

  // ── Run-time hot path (advanced in tick(); read by the Flame layers) ────────
  double launchBloom = 0; // plant pulse, identical both runs
  double feedPulseT = 0; // plant→transformer feed phase (loops while sending)
  double coreBloom = 0; // transformer field; HARD 0 for the ENTIRE DC run
  double vignetteTighten = 0; // 0..1 — the vignette pulls onto the transformer
  double dispVoltage = 0; // shown only during runs
  double dispCurrent = 0;
  bool showNumbers = false;
  double reachFront = 0; // 0..1 along route; DC stalls, AC reaches 1.0
  double pulsePhase = 0; // travelling-pulse animation phase (loops)
  double flareIntensity = 0; // 700ms envelope at the failure frame
  double cityLit = 0; // 0 / feeble flicker / sweep→1.0; HARD 0 at fail frame
  double citySweep = 0; // 0..1 the AC window-sweep progress
  // The transformer's PRESENCE (1 = there, 0 = gone). It DISAPPEARS on DC (there is
  // no working transformer) and MATERIALISES back on AC. PERSISTS across the runs (it
  // is NOT reset between them), so DC leaves it gone and AC brings it back.
  double transformerPresence = 1;

  // sceneDim is kept (every layer reads `1 - sceneDim`); it now stays 0 — the scene
  // never dims, since the bridge phase (which used to dim the map) was removed.
  double sceneDim = 0;

  // war crossfade (DC last → crossfade scene to the AC end-state)
  double warCrossfade = 0; // 0 = current end-state, 1 = AC end-state shown
  bool _warShowsAcEndState = false;
  bool get warShowsAcEndState => _warShowsAcEndState;

  WocRun? get _run => activeRun.value;
  bool get isDcRun => _run == WocRun.dc;
  bool get isAcRun => _run == WocRun.ac;

  // ── Internal run/animation state ───────────────────────────────────────────
  final List<Timer> _timers = [];
  double _t = 0; // wall clock (s) for loop phases
  bool _disposed = false;

  // DC failure latch — fires once per DC run; gates the cutoff (criterion 5).
  bool _failed = false;
  double _flareElapsed = 0; // s since the failure frame
  bool get failed => _failed;

  // V/I roll
  double _viRollStartMs = 0; // run-clock ms when the V/I roll began (AC)
  bool _viRolling = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  void start() {
    // No intro caption now — the scene just reveals (eased in tick), then the choice.
    _schedule(WocTune.introToChooseMs, _enterChoose);
  }

  void _enterChoose() {
    phase.value = WocPhase.choose;
    _setCaption(WocLine.i1Choose);
    notifyListeners();
  }

  // ── The free choice: tap a current ─────────────────────────────────────────
  /// Ignored unless we're waiting (choose / interlude) AND this run isn't done.
  void chooseRun(WocRun r) {
    final p = phase.value;
    if (p != WocPhase.choose && p != WocPhase.interlude) return;
    if (r == WocRun.dc && ranDc.value) return;
    if (r == WocRun.ac && ranAc.value) return;
    onChipTap?.call();
    activeRun.value = r;
    ranAcRanLast = r == WocRun.ac; // the LAST run chosen (drives the war crossfade)
    phase.value = WocPhase.sending;
    _runClock
      ..reset()
      ..start();
    _resetRunState();
    if (r == WocRun.dc) {
      _scriptDcRun();
    } else {
      _scriptAcRun();
    }
    notifyListeners();
  }

  void _resetRunState() {
    launchBloom = 0;
    feedPulseT = 0;
    coreBloom = 0;
    vignetteTighten = 0;
    reachFront = 0;
    flareIntensity = 0;
    cityLit = 0;
    citySweep = 0;
    _failed = false;
    _flareElapsed = 0;
    _viRolling = false;
    dispVoltage = WocTune.vLaunch;
    dispCurrent = WocTune.iLaunch;
    showNumbers = false;
  }

  // ── The common launch (identical both runs) ────────────────────────────────
  void _commonLaunch() {
    // +300ms: plant bloom pulse + the VOLTAGE/CURRENT chips fade in at 10 / 100.
    _schedule(WocTune.launchBloomMs, () {
      showNumbers = true;
      dispVoltage = WocTune.vLaunch;
      dispCurrent = WocTune.iLaunch;
      notifyListeners();
    });
    // +1200ms: the vignette tightens slightly on the transformer.
    _schedule(WocTune.launchVignetteMs, () {/* eased in tick via _vignetteTarget */});
  }

  // ── DC run script (the witnessed failure) ──────────────────────────────────
  void _scriptDcRun() {
    _commonLaunch();
    // Core NEVER blooms (enforced by the hard gate in tick()).
    _schedule(WocTune.dcSentMs, () => _setCaption(WocLine.dSent)); // dead transformer, low V
    _schedule(WocTune.dcJourneyMs, () {/* journey starts; reachFront eased in tick */});
    // THE FAILURE — hard gate. The result line lands just after, on the cooked line.
    _schedule(WocTune.dcFailureMs, _triggerFailure);
    _schedule(WocTune.dcResultMs, () => _setCaption(WocLine.dResult)); // the line cooks + dies
    // (No capture fires on DC — `dc_line_cooks` is not in the EP2 catalog.)
    _schedule(WocTune.dcRunEndMs, _endRun);
  }

  void _triggerFailure() {
    if (_failed) return;
    _failed = true;
    _flareElapsed = 0;
    flareIntensity = 1.0; // peak now; the envelope decays in tick()
    cityLit = 0; // HARD 0 in this same frame — no fade tail
    onFailure?.call(); // heavyImpact (once)
    notifyListeners();
  }

  // ── AC run script (the full solution) ──────────────────────────────────────
  void _scriptAcRun() {
    _commonLaunch();
    // +1200ms: the core blooms alive + the V/I roll begins (in sync, same window).
    _schedule(WocTune.acBloomMs, () {
      _viRolling = true;
      _viRollStartMs = _runElapsedMs();
      notifyListeners();
    });
    _schedule(WocTune.acSentMs, () => _setCaption(WocLine.aSent)); // transformer alive, V up
    _schedule(WocTune.acJourneyMs, () {/* pulses sail; reachFront eased in tick */});
    // ARRIVAL — the orchestrated payoff (window sweep eased in tick).
    _schedule(WocTune.acArrivalMs, () => notifyListeners());
    // Capture the full-lit frame (the ONLY valid id for this beat).
    _schedule(WocTune.acCaptureMs, () => onCapture?.call(WocTune.evAcSailsAcross));
    _schedule(WocTune.acResultMs, () => _setCaption(WocLine.aResult)); // line cold, sailed across
    _schedule(WocTune.acRunEndMs, _endRun);
  }

  // ── A run ends → interlude (other run left) or the war (both done) ──────────
  void _endRun() {
    if (isDcRun) {
      ranDc.value = true;
    } else {
      ranAc.value = true;
    }
    if (ranDc.value && ranAc.value) {
      _enterWar();
    } else {
      _enterInterlude();
    }
  }

  void _enterInterlude() {
    phase.value = WocPhase.interlude;
    // Visible reset: the wire cools / city dims to the start state over 800ms (eased
    // in tick via _interludeReset). Numbers fade out; the remaining chip pulses.
    showNumbers = false;
    activeRun.value = null;
    _schedule(WocTune.interludeResetMs, () {
      _setCaption(WocLine.i2Other);
      notifyListeners();
    });
    notifyListeners();
  }

  // ── The war — strictly after BOTH runs (name-last) ─────────────────────────
  void _enterWar() {
    phase.value = WocPhase.war;
    activeRun.value = null;
    showNumbers = false;
    // If DC ran last, crossfade the scene to the AC end-state (cold line, lit city —
    // the world where AC won) over ~700ms: leave the failed visuals where they are
    // and let _tickWar ease them up. If AC ran last, we're already there — snap.
    _warShowsAcEndState = !ranAcRanLast;
    warCrossfade = ranAcRanLast ? 1 : 0;
    _failed = false; // stop the DC hard-gate so the scene can heal to the AC world
    flareIntensity = 0;
    citySweep = 1; // the war city is fully lit (no per-window sweep here)
    if (ranAcRanLast) {
      coreBloom = 1;
      reachFront = 1;
      cityLit = 1;
    }
    // The ONE verdict line — it persists behind the Continue CTA (the activity ENDS
    // on the war; the EP3 bridge vignette was cut).
    _setCaption(WocLine.verdict);
    _schedule(WocTune.warToDoneMs, _enterDone);
    notifyListeners();
  }

  // Which run ran last (drives the war crossfade). True if AC ran last.
  bool ranAcRanLast = false;

  void _enterDone() {
    phase.value = WocPhase.done;
    // The EP2 finale card (the S3 closing line sits behind it). Its own Continue
    // → next activity; a separate Continue pill is no longer shown.
    showCardEarn.value = true;
    notifyListeners();
  }

  // ── The frame loop — advances reveals/pulses/front; enforces hard gates ─────
  void tick(double dt) {
    if (_disposed) return;
    _t += dt;
    final p = phase.value;

    // Entrance reveals (intro). Under reduced motion the entrance is an INSTANT
    // fade — the reveals snap to 1 so there is no animated ramp (PRD §6 "entrance
    // reveals become fades"); the layers express reveal as alpha only, so this
    // reads as a calm cut-in, not a slide. Normal motion eases toward 1.
    // (This is a presentation-only reveal — the load-bearing gates below, the DC
    // failure / dead-core / V/I roll, are untouched and stay exact.)
    if (p == WocPhase.intro || mapReveal < 1) {
      if (reducedMotion) {
        mapReveal = 1;
        routeReveal = 1;
        stationReveal = 1;
        cityReveal = 1;
      } else {
        mapReveal = _approach(mapReveal, 1, dt, 0.28);
        routeReveal = _approach(routeReveal, 1, dt, 0.34);
        stationReveal = _approach(stationReveal, 1, dt, 0.32);
        cityReveal = _approach(cityReveal, 1, dt, 0.36);
      }
    }

    // Ambient pulse phases always advance (calm under reduced motion).
    final spd = reducedMotion ? 0.3 : 1.0;
    pulsePhase += dt * spd;
    feedPulseT = (feedPulseT + dt * 1.2 * spd) % 1.0;

    _tickSending(dt, p);
    _tickInterlude(dt, p);
    _tickWar(dt, p);

    notifyListeners();
  }

  void _tickSending(double dt, WocPhase p) {
    if (p != WocPhase.sending) return;
    final elapsedMs = _runElapsedMs();

    // Plant bloom — identical both runs, blooms in over ~launchBloomMs.
    launchBloom = _approach(launchBloom, elapsedMs > WocTune.launchBloomMs ? 1 : 0, dt, 0.14);

    // The vignette tightens on the transformer after launchVignetteMs.
    final vigTarget = elapsedMs > WocTune.launchVignetteMs ? 1.0 : 0.0;
    vignetteTighten = _approach(vignetteTighten, vigTarget, dt, 0.26);

    if (isDcRun) {
      _tickDcSending(dt, elapsedMs);
    } else {
      _tickAcSending(dt, elapsedMs);
    }
  }

  void _tickDcSending(double dt, double elapsedMs) {
    // THE DEAD CORE — hard absence, every frame of the DC run.
    coreBloom = 0;
    dispVoltage = WocTune.vLaunch; // never steps up
    dispCurrent = WocTune.iLaunch;
    // The transformer DISAPPEARS the instant DC is chosen (no transformer on DC) —
    // it fades + shrinks away right away, from the first frame of the run.
    transformerPresence = _approach(transformerPresence, 0, dt, 0.16);

    if (_failed) {
      // HARD GATE: the reach-front is FROZEN at the stall, pulses past it die, the
      // city stays 0. Only the flare envelope decays (visual afterglow).
      reachFront = WocTune.dcStallS;
      cityLit = 0;
      _flareElapsed += dt;
      final env = (1 - _flareElapsed / (WocTune.flareEnvelopeMs / 1000)).clamp(0.0, 1.0);
      // Reduced motion: a brief glow STEP, not a soft fade — still snaps off.
      flareIntensity = reducedMotion ? (env > 0.2 ? 1.0 : 0.0) : env;
      return;
    }

    // The journey: the reach-front advances toward the stall and stops there.
    if (elapsedMs > WocTune.dcJourneyMs) {
      final journeyT =
          ((elapsedMs - WocTune.dcJourneyMs) / (WocTune.dcFailureMs - WocTune.dcJourneyMs))
              .clamp(0.0, 1.0);
      reachFront = WocTune.dcStallS * _easeOut(journeyT);
      // A feeble city flicker before the fail (never reaching the city).
      cityLit = 0.06 + 0.05 * math.sin(_t * 7.0);
    }
  }

  void _tickAcSending(double dt, double elapsedMs) {
    // The transformer MATERIALISES back (fades + grows in, if it was gone after a
    // prior DC run) — then comes alive.
    transformerPresence = _approach(transformerPresence, 1, dt, 0.16);
    // The core blooms alive (700ms) once the bloom timer fires.
    final bloomTarget = elapsedMs > WocTune.acBloomMs ? 1.0 : 0.0;
    coreBloom = _approach(coreBloom, bloomTarget, dt, 0.18);

    // V/I roll — 10→200 / 100→5 over viRollMs, in sync with the bloom.
    if (_viRolling) {
      final r = ((_runElapsedMs() - _viRollStartMs) / WocTune.viRollMs).clamp(0.0, 1.0);
      final e = _easeInOut(r);
      dispVoltage = _lerp(WocTune.vLaunch, WocTune.vStepped, e);
      dispCurrent = _lerp(WocTune.iLaunch, WocTune.iStepped, e);
    }

    // The thin fast pulses sail the FULL route; the wire shows zero heat.
    if (elapsedMs > WocTune.acJourneyMs) {
      final journeyT =
          ((elapsedMs - WocTune.acJourneyMs) / (WocTune.acArrivalMs - WocTune.acJourneyMs))
              .clamp(0.0, 1.0);
      reachFront = _easeOut(journeyT);
    }

    // ARRIVAL — the city window sweep (900ms) + warm bloom.
    if (elapsedMs > WocTune.acArrivalMs) {
      final sweepT = ((elapsedMs - WocTune.acArrivalMs) / 900).clamp(0.0, 1.0);
      citySweep = sweepT;
      cityLit = _easeOut(sweepT);
    }
  }

  void _tickInterlude(double dt, WocPhase p) {
    if (p != WocPhase.interlude) return;
    // Visible reset: cool the wire / dim the city to the start state.
    reachFront = _approach(reachFront, 0, dt, 0.20);
    cityLit = _approach(cityLit, 0, dt, 0.20);
    coreBloom = _approach(coreBloom, 0, dt, 0.20);
    launchBloom = _approach(launchBloom, 0, dt, 0.20);
    vignetteTighten = _approach(vignetteTighten, 0, dt, 0.20);
    flareIntensity = _approach(flareIntensity, 0, dt, 0.20);
    citySweep = 0;
  }

  void _tickWar(double dt, WocPhase p) {
    if (p != WocPhase.war) return;
    // Crossfade to the AC end-state if DC ran last (cold line, lit city). Ease the
    // failed visuals up to the AC world over ~700ms; if AC ran last they're already
    // at 1 (snapped in _enterWar) so the ease is a no-op.
    final tau = WocTune.warCrossfadeMs / 1000 / 3;
    warCrossfade = _approach(warCrossfade, 1, dt, tau);
    coreBloom = _approach(coreBloom, 1, dt, tau);
    cityLit = _approach(cityLit, 1, dt, tau);
    reachFront = _approach(reachFront, 1, dt, tau);
    // The AC-won world has the transformer back (it returns if DC ran last).
    transformerPresence = _approach(transformerPresence, 1, dt, tau);
  }

  // ── Run clock (ms since the run began) — WALL-CLOCK, not the frame-summed _t.
  //    The AC run's flow + city-lighting are threshold-based on this; using the real
  //    clock makes them robust to dropped/heavy frames (the order-dependent AC-first
  //    stall). Captions/phase transitions already run on wall-clock Timers, so this
  //    keeps the visuals in lock-step with them. ──────────────────────────────────
  final Stopwatch _runClock = Stopwatch();
  double _runElapsedMs() => _runClock.elapsedMilliseconds.toDouble();

  // ── Timer scheduling (cancel-on-dispose) ───────────────────────────────────
  void _schedule(int ms, void Function() action) {
    if (_disposed) return;
    final timer = Timer(Duration(milliseconds: ms), () {
      if (!_disposed) action();
    });
    _timers.add(timer);
  }

  void _setCaption(WocLine line) {
    caption.value = line;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  static double _approach(double cur, double target, double dt, double tau) =>
      cur + (target - cur) * (1 - math.exp(-dt / tau));
  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  // Tiny local easings (no flutter/animation import needed in the controller).
  static double _easeOut(double t) {
    final u = 1 - t.clamp(0.0, 1.0);
    return 1 - u * u * u;
  }

  static double _easeInOut(double t) {
    final x = t.clamp(0.0, 1.0);
    return x < 0.5 ? 4 * x * x * x : 1 - math.pow(-2 * x + 2, 3) / 2;
  }

  @override
  void dispose() {
    _disposed = true;
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    phase.dispose();
    caption.dispose();
    activeRun.dispose();
    ranDc.dispose();
    ranAc.dispose();
    showContinue.dispose();
    showCardEarn.dispose();
    super.dispose();
  }
}
