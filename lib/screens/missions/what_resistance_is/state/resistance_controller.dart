// The brain of "Shape the Wire" (beat 2.2). A ChangeNotifier that owns the morph
// state, the current model, the silent phase machine, every envelope, and the
// gate checks. The painter and surface are pure renderers that only read getters
// here; discrete UI channels (caption, current chip, CTA, card) are ValueNotifiers.
//
// THE PEDAGOGY, mechanised:
//  • VOLTAGE IS PINNED. There is no voltage variable to change — the chip shows a
//    frozen 100 forever, the dial accepts no input (deny shake only). The pin's
//    flight from wire → dial plays before input unlocks and cannot be skipped
//    (acceptance §3).
//  • SAME-FRAME RESPONSE. morphT is set ONLY by drag delta with no easing/inertia;
//    geometry, flow, lamp all read it the same frame; the CURRENT number resamples
//    on the next ~110 ms tick (acceptance §1). The morph HOLDS on release — no
//    spring-back — so the steady state is readable (acceptance, anti-pattern).
//  • CONSERVATION is in the geometry (width ∝ 1/sqrt(lengthFactor)).
//  • NO HEAT. Nothing here ramps a warm/red value off thinness; the choke is less
//    flow, never temperature (acceptance §8).

import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import '../config/resistance_beats.dart';
import '../config/resistance_tuning.dart';
import 'flow_particles.dart';

class ResistanceController extends ChangeNotifier {
  ResistanceController() {
    _flow = FlowField();
  }

  // ── Discrete UI channels ───────────────────────────────────────────────────
  final ValueNotifier<RPhase> phase = ValueNotifier<RPhase>(RPhase.intro);
  final ValueNotifier<RCaption> caption = ValueNotifier<RCaption>(RCaption.none);
  final ValueNotifier<RCaption> echo = ValueNotifier<RCaption>(RCaption.none);
  final ValueNotifier<int> displayCurrent = ValueNotifier<int>(100);
  final ValueNotifier<int> currentTrend = ValueNotifier<int>(0); // -1 / 0 / +1
  final ValueNotifier<bool> showContinue = ValueNotifier<bool>(false);
  final ValueNotifier<bool> showCardEarn = ValueNotifier<bool>(false);

  // ── Hot-path state (read by the painter via getters) ───────────────────────
  double morphT = RTune.morphStart; // 0 short+fat … 1 long+thin
  late final FlowField _flow;
  FlowField get flow => _flow;

  // Envelopes (0..1 unless noted), advanced in tick.
  double flowPhase = 0; // free-running animation clock for shimmer
  double pinFlight = 0; // 0 = on wire, 1 = clamped on dial
  double pinDenyShake = 0; // decaying envelope on a deny-tap
  double lampGlow = 0;
  double discoveryFlash = 0; // the one orchestrated thin-discovery flash
  double fatShimmer = 0; // brief surge shimmer at the fat moment
  double landingBlend = 0; // 0 lab → 1 the arm-thick cable cross-section
  double resistLabelFade = 0; // mono "RESISTANCE" specimen on the wire

  // Entrance reveals.
  double sourceReveal = 0;
  double wireReveal = 0;
  double lampReveal = 0;

  bool reducedMotion = false;
  bool _started = false;
  bool _inputEnabled = false;
  bool get inputEnabled => _inputEnabled;

  // ── The current model (relative; squared form is INTERNAL only) ────────────
  double _lf(double t) =>
      RTune.lengthFactorFat + (RTune.lengthFactorThin - RTune.lengthFactorFat) * t;

  double get lengthFactor => _lf(morphT);

  /// Conservation reference: strict same-metal width ∝ 1/sqrt(length) (1.0 at
  /// the mid wire). NOTE: the painter DRAMATIZES the rendered width to honour
  /// the PRD §16 anchors (fat ~0.16W / mid ~0.075W / thin ~0.018W, ~9× swing)
  /// so the choke/surge contrast reads; rendered LENGTH carries the literal
  /// conservation. This getter is the honest conservation ratio for reference.
  double get widthFactor => 1.0 / math.sqrt(lengthFactor / _lf(RTune.morphStart));

  /// Relative current normalised to the mid wire (1.0 at start). The square is
  /// drama the learner FEELS — never surfaced as text, curve, or readout.
  double get currentNorm {
    final ratio = _lf(RTune.morphStart) / lengthFactor;
    return ratio * ratio;
  }

  double get relativeCurrent => RTune.currentBaseline * currentNorm;

  // ── Hooks (wired by the shell) ─────────────────────────────────────────────
  VoidCallback? onDetent; // selectionClick per 0.125 morphT detent
  VoidCallback? onDiscovery; // heavyImpact at the thin discovery
  VoidCallback? onFatMoment; // selectionClick at the fat moment
  VoidCallback? onPinClamp; // selectionClick when the pin clamps the dial
  VoidCallback? onDeny; // light feedback on a dial deny-tap
  /// Episode-board capture hook: fired with the evidence-tile id when the
  /// "This Opposition Is Called Resistance" (m5) line lands — the RESISTANCE
  /// specimen on the wire. Captures the 2.2 distractor 'fat_wire'.
  void Function(String evidenceId)? onCapture;

  // ── Internals ──────────────────────────────────────────────────────────────
  final List<_Timer> _timers = [];
  double _clock = 0; // seconds since start (for scheduled timers)
  double _sampleAcc = 0; // current-chip resample accumulator
  int _lastDisplayed = 100;

  // drag tracking
  double? _lastPointerY;
  double _lastDetentBucket = (RTune.morphStart / RTune.detentStep).floorToDouble();

  // gate tracking
  double _thinHeld = 0; // ms morphT held ≥ thinGate
  double _fatHeld = 0; // ms morphT held ≤ fatGate
  bool _thinFired = false;
  bool _fatFired = false;
  bool _sweepVisitThin = false;
  bool _sweepVisitFat = false;
  bool _m4Fired = false;
  int _denyShownCount = 0; // d1 shows at most twice

  bool _echoArmedStretch = true; // e1 only on the first sustained stretch
  bool _echoArmedSquash = true; // e2 only on the first sustained squash

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  void start() {
    if (_started) return;
    _started = true;
    // No B0 pin-move beat (removed): the voltage is pinned from the start — the pin
    // already sits on the VOLTAGE source. The scene reveals, then we go straight to
    // B1 (stretch); there is no intro caption and no pin-flight.
    phase.value = RPhase.intro;
    pinFlight = 1.0; // pin already clamped on the source
    _schedule(RTune.introToPinMoveMs, _enterStretch);
  }

  void _enterStretch() {
    phase.value = RPhase.stretch;
    caption.value = RCopy.i1;
    _inputEnabled = true;
    notifyListeners();
  }

  // ── Input (from the WireSurface Listener) ──────────────────────────────────
  void onPointerDown(Offset local) {
    if (!_inputEnabled) return;
    _lastPointerY = local.dy;
  }

  void onPointerMove(Offset local, double stageH) {
    if (!_inputEnabled || _lastPointerY == null) return;
    final dy = local.dy - _lastPointerY!;
    _lastPointerY = local.dy;
    // Drag DOWN (positive dy) → stretch → morphT up. No easing, same frame.
    final range = stageH * RTune.dragRangeHFactor;
    if (range <= 0) return;
    final next = (morphT + dy / range).clamp(0.0, 1.0);
    if (next == morphT) return;
    morphT = next;
    _checkDetents();
    _checkBandVisits();
    notifyListeners();
  }

  void onPointerUp() {
    _lastPointerY = null; // morph HOLDS — no spring-back
  }

  void _checkDetents() {
    final bucket = (morphT / RTune.detentStep).floorToDouble();
    if (bucket != _lastDetentBucket) {
      _lastDetentBucket = bucket;
      onDetent?.call();
    }
  }

  void _checkBandVisits() {
    if (phase.value == RPhase.sweep) {
      if (morphT >= RTune.sweepBandThin) _sweepVisitThin = true;
      if (morphT <= RTune.sweepBandFat) _sweepVisitFat = true;
    }
  }

  /// The pinned voltage dial refuses input — a deny shake + glint, plus d1 (max
  /// twice). Voltage NEVER changes.
  void onDialTouched() {
    pinDenyShake = 1.0;
    onDeny?.call();
    if (_denyShownCount < 2) {
      _denyShownCount++;
      // Flash d1 as a secondary echo so it doesn't clobber the lesson caption.
      echo.value = RCopy.d1;
      _schedule(RTune.echoHideMs, () {
        if (echo.value == RCopy.d1) echo.value = RCaption.none;
      });
    }
    notifyListeners();
  }

  // ── The tick (60 Hz from the shell Ticker) ─────────────────────────────────
  void tick(double dt) {
    if (dt <= 0 || dt > 0.1) return;
    _clock += dt;
    _runTimers();

    flowPhase += dt;

    // Entrance reveals.
    sourceReveal = _toward(sourceReveal, 1, dt / (RTune.sourceRevealMs / 1000));
    wireReveal = _toward(wireReveal, 1, dt / (RTune.wireRevealMs / 1000));
    lampReveal = _toward(lampReveal, 1, dt / (RTune.lampRevealMs / 1000));

    // Pin flight advances 0→1 over the same window in both motion modes; the
    // painter (_paintPin) is what differentiates the arc flight from the
    // reduced-motion fade-out-at-wire / fade-in-at-dial off this same value.
    // After pinMove it stays clamped.
    if (phase.value == RPhase.pinMove && pinFlight < 1) {
      pinFlight = (pinFlight + dt / (RTune.pinFlightMs / 1000)).clamp(0.0, 1.0);
    } else if (phase.value.index > RPhase.pinMove.index) {
      pinFlight = 1.0;
    }

    // Deny shake decays.
    if (pinDenyShake > 0) {
      pinDenyShake = math.max(0, pinDenyShake - dt / (RTune.denyShakeMs / 1000));
    }

    // Lamp glow tracks normalized current SAME-FRAME (acceptance §1 + §4: the
    // lamp is one of the cues that must echo a morphT change with ≤1 frame of
    // latency — no easing/inertia, matching the wire bloom which reads currentNorm
    // instantly). A ≤1-frame anti-strobe smooth (factor min(1, dt*40)) keeps it
    // from flickering without ever lagging the drag.
    final lampTarget = (currentNorm / 4.0).clamp(0.0, 1.0); // fat (≈4) → full
    lampGlow += (lampTarget - lampGlow) * math.min(1, dt * 40);

    // Discovery flash + fat shimmer decay (instant-feel envelopes).
    if (discoveryFlash > 0) {
      discoveryFlash = math.max(0, discoveryFlash - dt / (RTune.discoveryFlashMs / 1000));
    }
    if (fatShimmer > 0) {
      fatShimmer = math.max(0, fatShimmer - dt / 0.6);
    }

    // RESISTANCE specimen label fades in during naming.
    if (phase.value.index >= RPhase.naming.index && phase.value != RPhase.landing) {
      resistLabelFade = _toward(resistLabelFade, 1, dt / (RTune.resistLabelFadeMs / 1000));
    }

    // Landing blend ramps in B5.
    if (phase.value == RPhase.landing) {
      final step = reducedMotion ? dt / 0.45 : dt / (RTune.landingBlendMs / 1000);
      final before = landingBlend;
      landingBlend = (landingBlend + step).clamp(0.0, 1.0);
      if (before < 1.0 && landingBlend >= 1.0) {
        // Cable reveal complete. (No capture for this beat — see class note.)
      }
    }

    // Flow field — lanes the cable affords scale with its rendered width (thin
    // forces single-file; fat opens a wide braid). Mirrors the painter geometry's
    // lanesAllowed = (halfWidth / 0.012W) = widthFracAt/2 / 0.012, so the braid
    // count never contradicts the rendered width (one source: RTune.widthFracAt).
    final lanesAfforded = (RTune.widthFracAt(morphT) / 0.024).round().clamp(1, 4);
    _flow.tick(dt, currentNorm,
        reducedMotion: reducedMotion, lanesAfforded: lanesAfforded);

    // Gate sustain tracking (only while in the relevant live phases).
    _updateGates(dt);

    // CURRENT chip resample (~9 Hz) so the number reads, not blurs.
    _sampleAcc += dt;
    if (_sampleAcc * 1000 >= RTune.currentSampleMs) {
      _sampleAcc = 0;
      final v = relativeCurrent.round();
      if (v != _lastDisplayed) {
        currentTrend.value = v > _lastDisplayed ? 1 : -1;
        _lastDisplayed = v;
        displayCurrent.value = v;
      } else {
        currentTrend.value = 0;
      }
    }

    notifyListeners();
  }

  void _updateGates(double dt) {
    final ms = dt * 1000;
    switch (phase.value) {
      case RPhase.stretch:
        // e1 on the first sustained stretch past 0.62.
        if (_echoArmedStretch && morphT >= 0.62) {
          _echoArmedStretch = false;
          echo.value = RCopy.e1;
          _schedule(RTune.echoHideMs, () {
            if (echo.value == RCopy.e1) echo.value = RCaption.none;
          });
        }
        if (morphT >= RTune.thinGate) {
          _thinHeld += ms;
          if (_thinHeld >= RTune.gateSustainMs && !_thinFired) _fireThinDiscovery();
        } else {
          _thinHeld = 0;
        }
      case RPhase.squash:
        // e2 on the first sustained squash below 0.38.
        if (_echoArmedSquash && morphT <= 0.38) {
          _echoArmedSquash = false;
          echo.value = RCopy.e2;
          _schedule(RTune.echoHideMs, () {
            if (echo.value == RCopy.e2) echo.value = RCaption.none;
          });
        }
        if (morphT <= RTune.fatGate) {
          _fatHeld += ms;
          if (_fatHeld >= RTune.gateSustainMs && !_fatFired) _fireFatMoment();
        } else {
          _fatHeld = 0;
        }
      case RPhase.sweep:
        if (!_m4Fired && _sweepVisitThin && _sweepVisitFat) _fireM4();
      default:
        break;
    }
  }

  void _fireThinDiscovery() {
    _thinFired = true;
    phase.value = RPhase.thinFound;
    discoveryFlash = 1.0;
    onDiscovery?.call(); // heavyImpact
    caption.value = RCopy.m2;
    echo.value = RCaption.none;
    // Input stays live; after the dwell, B2.
    _schedule(RTune.discoveryFlashMs, () {});
    _schedule(RTune.m2HoldMs, _enterSquash);
  }

  void _enterSquash() {
    if (phase.value != RPhase.thinFound) return;
    phase.value = RPhase.squash;
    caption.value = RCopy.i2;
    notifyListeners();
  }

  void _fireFatMoment() {
    _fatFired = true;
    phase.value = RPhase.fatFound;
    fatShimmer = 1.0; // brief surge shimmer — NO second heavy flash
    onFatMoment?.call(); // selectionClick
    caption.value = RCopy.m3;
    echo.value = RCaption.none;
    _schedule(RTune.m3HoldMs, _enterSweep);
  }

  void _enterSweep() {
    if (phase.value != RPhase.fatFound) return;
    phase.value = RPhase.sweep;
    caption.value = RCopy.i3;
    _sweepVisitThin = false;
    _sweepVisitFat = false;
    // safety: re-seed band visits from the current position
    _checkBandVisits();
    // Timeout fallback → m4 even if the learner doesn't visit both bands. The
    // timeout still required B1 + B2 gates already passed (they did, to be here).
    _schedule(RTune.sweepTimeoutMs, () {
      if (phase.value == RPhase.sweep && !_m4Fired) _fireM4();
    });
    notifyListeners();
  }

  void _fireM4() {
    _m4Fired = true;
    caption.value = RCopy.m4;
    _schedule(RTune.m4HoldMs, _enterNaming);
  }

  void _enterNaming() {
    phase.value = RPhase.naming;
    _inputEnabled = true; // input stays live through B4 (PRD §6)
    caption.value = RCopy.m5; // the naming line (names "resistance")
    onCapture?.call('fat_wire'); // 2.2 distractor — snap with the RESISTANCE specimen on screen
    // Condensed naming: the shape-law (m6) and pipe-analogy (m7) lines were dropped
    // per the updated copy — m5 holds, then the landing line (m8).
    _schedule(RTune.m5HoldMs, _enterLanding);
  }

  void _enterLanding() {
    phase.value = RPhase.landing;
    _inputEnabled = false; // input disabled at landing entry (PRD §6/§14)
    _lastPointerY = null;
    // Settle the morph to a clean medium VERTICAL cable so the receding lab body
    // sits under the fixed-geometry arm-thick reveal (the reveal no longer swells
    // whatever crooked shape was left — see _paintLandingScale).
    morphT = 0.46;
    // m8 lands after the cable reveal blend completes.
    final blendMs = reducedMotion ? 450 : RTune.landingBlendMs;
    _schedule(blendMs, () {
      caption.value = RCopy.m8;
      _schedule(RTune.m8HoldMs, _enterCard);
    });
    notifyListeners();
  }

  void _enterCard() {
    phase.value = RPhase.synthesis;
    showCardEarn.value = true;
  }

  /// Called by the card overlay's onDone → reveal the Continue CTA.
  void onCardCollected() {
    showCardEarn.value = false;
    showContinue.value = true;
    phase.value = RPhase.done;
  }

  // ── Tiny scheduler (wall-clock seconds, cancelled on dispose) ──────────────
  void _schedule(int ms, VoidCallback fn) {
    _timers.add(_Timer(_clock + ms / 1000.0, fn));
  }

  void _runTimers() {
    if (_timers.isEmpty) return;
    final due = <_Timer>[];
    _timers.removeWhere((t) {
      if (t.at <= _clock) {
        due.add(t);
        return true;
      }
      return false;
    });
    for (final t in due) {
      t.fn();
    }
  }

  static double _toward(double v, double target, double step) {
    if (v < target) return math.min(target, v + step);
    if (v > target) return math.max(target, v - step);
    return v;
  }

  @override
  void dispose() {
    _timers.clear();
    phase.dispose();
    caption.dispose();
    echo.dispose();
    displayCurrent.dispose();
    currentTrend.dispose();
    showContinue.dispose();
    showCardEarn.dispose();
    super.dispose();
  }
}

class _Timer {
  _Timer(this.at, this.fn);
  final double at;
  final VoidCallback fn;
}
