// The Transmission Trick — the activity controller (controller-owns-geometry). It
// owns the sim, the geometry (pixels = factors × stage size), the phase machine, the
// silent timer chain, the one-way latches, and the vertical-drag → voltage mapping.
// The Flame game reports the stage size once, forwards pointer events, and ticks the
// controller each frame; every layer is a near-pure renderer reading getters here.
//
// THE PEDAGOGY (PRD §3, the STAR of the module): the power is PINNED. The learner
// drags the rectangle's top edge UP → voltage rises → current falls BY ITSELF (the
// pinned area: taller means narrower) → the wire cools (heat ∝ I², 2.4's payoff) →
// the far town brightens. The 2.1 inversion flipped: more voltage now means LESS
// current, because the pinned quantity flipped from the wire to the power.
//
// SAME-FRAME CAUSALITY (PRD criterion 2): every drag updates rect height/width, both
// number chips, wire heat/motes/pulses, and town brightness in the SAME frame — no
// tween lag between cause and effect; voltage holds exactly where the finger leaves
// it (no inertia, PRD §10).

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Offset, Size;

import '../config/transmission_beats.dart';
import '../config/transmission_tuning.dart';

enum TTPhase { intro, raise, lightTown, sendTop, closing }

class TransmissionController extends ChangeNotifier {
  TransmissionController();

  // ── Discrete UI channels (rebuild only on change) ─────────────────────
  /// The big top caption — an imperative or a meaning-line; the [TTCaption] flags
  /// drive the style. We expose the resolved caption (not just the id) so the
  /// fade-swap widget reads .text/.meaning/.long directly.
  final ValueNotifier<TTCaption> caption =
      ValueNotifier(TTCopy.of(TTCaptionId.none));
  final ValueNotifier<TTPhase> phase = ValueNotifier(TTPhase.intro);
  final ValueNotifier<bool> showCardEarn = ValueNotifier(false);
  final ValueNotifier<bool> canFinish = ValueNotifier(false);

  // ── Polish hooks (haptics + capture) ──────────────────────────────────
  void Function()? onDetent; // selectionClick per +detentV crossing
  void Function()? onDiscovery; // heavyImpact at the discovery latch
  void Function(String evidenceId)? onCapture; // lightImpact + PNG in the shell

  /// Reduced motion (MediaQuery.disableAnimations): static heat gradient, calmed
  /// motes, fast window fade, fades for entrances — but NEVER softens a same-frame
  /// causal update (rect/numbers/heat/town) (PRD §10).
  bool reducedMotion = false;

  // ── Geometry (the diagonal-span stage box) ────────────────────────────
  // The DIAGONAL SPAN (plant → wire → town) lives in the boxed Flame stage. The
  // POWER/VOLTAGE/CURRENT readouts + the VOLTAGE slider are plain Flutter widgets in
  // their own bands below it (the column layout), so nothing can overlap.
  Size _stageSize = Size.zero; // the diagonal-span box (Flame)
  Size get stageSize => _stageSize;
  void setStageSize(Size s) => _stageSize = s;

  Offset _f(Offset factor) => TTTune.f(factor, _stageSize);

  // Diagonal-span anchors (factors of the STAGE box).
  Offset get plantBase => _f(TTTune.plantBaseFactor);
  double get plantWidth => TTTune.plantWidthFactor * _stageSize.width;
  Offset get wireStart => _f(TTTune.wireStartFactor);
  Offset get wireEnd => _f(TTTune.wireEndFactor);
  /// The single intermediate pylon sits ON the catenary, so the wire rests on its
  /// insulators (apex = the wire point at its fraction along the span).
  Offset get pylon1 => wirePoint(TTTune.pylon1Frac);
  double get wireSag => TTTune.wireSagFactor * _stageSize.height;
  Offset get townBase => _f(TTTune.townBaseFactor);
  double get townWidth => TTTune.townWidthFactor * _stageSize.width;

  /// The DIAGONAL GROUND line — element feet climb from the bottom-left (the
  /// powerhouse, lowest) up to the upper-right (the town, highest), so the whole
  /// scene steps up the diagonal and fills the space instead of standing on a flat
  /// floor. [xFactor] is 0..1 across the stage width; returns the foot y in pixels.
  double groundY(double xFactor) {
    final t = xFactor.clamp(0.0, 1.0);
    final f = TTTune.groundLeftYFactor +
        (TTTune.groundRightYFactor - TTTune.groundLeftYFactor) * t;
    return f * _stageSize.height;
  }

  /// Voluminous cable body width (the held-constant stroke; only its heat varies).
  double get wireStroke => TTTune.wireStrokeFactor * _stageSize.height;

  /// A point at fraction [t] (0..1) along the diagonal catenary span (plant terminal
  /// → town feed), with a parabolic sag dipping below the straight diagonal so the
  /// thick cable reads as real weight. The DRAWN GEOMETRY is identical every frame
  /// (the held-constant) — only the heat glow/haze/motes vary. Renderers sample this
  /// evenly (like the 2.3/2.4 hot-wire path) for a smooth voluminous cable.
  Offset wirePoint(double t) {
    final s = wireStart, e = wireEnd;
    final x = s.dx + (e.dx - s.dx) * t;
    final yLine = s.dy + (e.dy - s.dy) * t;
    final sag = 4 * wireSag * t * (1 - t); // parabolic, 0 at ends, max at midspan
    return Offset(x, yLine + sag);
  }

  /// A slowly-scrolling phase for the heat-haze shimmer band (time-based motion).
  double get hazePhase => _shimmer * TTTune.hazeSpeed;

  // ── The sim (hot path) ────────────────────────────────────────────────
  double _voltage = TTTune.vMin;
  double get voltage => _voltage;
  double get current => TTTune.currentFor(_voltage);
  double get wireHeat => TTTune.wireHeat(current); // 0..1, ∝ I²
  double get delivered => TTTune.delivered(current); // 0..1
  /// Town brightness — a high-water mark once the town is lit (it never dims below
  /// the latched bloom), but tracks `delivered` while still climbing (so dragging
  /// down before the lit latch reheats AND dims, the relationship felt both ways).
  double get townLit => _townLitLatched ? 1.0 : delivered;

  /// Relative integer numbers for the chips. VOLTAGE and CURRENT move (opposite);
  /// POWER is their product — PINNED, the same value at every voltage (the lesson:
  /// you trade voltage for current, but the power delivered never changes).
  int get voltageNumber => _voltage.round();
  int get currentNumber => current.round();
  int get powerNumber => TTTune.viProduct.round(); // always 1000 — the pinned product

  /// Gauge value-norms (0..1) for the instrument needle/glow — read SAME-FRAME from
  /// the live voltage/current (the needle never lags the drag; only printed digits
  /// could roll, and we keep them exact for guaranteed same-frame causality).
  double get voltageNorm => TTTune.voltageNorm(_voltage);
  double get currentNorm => TTTune.currentNorm(current);

  /// Momentary trend of the last drag step: +1 rising, −1 falling, 0 steady. Drives
  /// the ↑/↓ trend glyphs on the gauges; decays to 0 after a short idle so a held
  /// finger reads "steady". VOLTAGE and CURRENT always move opposite (the pin).
  int _voltTrend = 0;
  double _trendHold = 0;
  int get voltageTrend => _voltTrend;
  int get currentTrend => -_voltTrend; // current moves opposite voltage

  /// Traveling-pulse count on the wire (∝ current — fewer as voltage rises).
  int get pulseCount => TTTune.pulseCountFor(current);

  // ── Entrance reveals + discovery ring (premium motion) ─────────────────
  double _plantReveal = 0;
  double _wireReveal = 0;
  double _townReveal = 0;
  double get plantReveal => _plantReveal;
  double get wireReveal => _wireReveal;
  double get townReveal => _townReveal;

  double _shimmer = 0;
  double get shimmer => _shimmer;
  double _pulsePhase = 0;
  double get pulsePhase => _pulsePhase;

  /// The discovery ring envelope around the CURRENT chip (~0.7s).
  bool _ringActive = false;
  double _ringElapsed = 0;
  double get discoveryRing {
    if (!_ringActive) return 0;
    final t = (_ringElapsed / TTTune.discoveryRingSeconds).clamp(0.0, 1.0);
    return t < 0.15 ? t / 0.15 : 1.0 - (t - 0.15) / 0.85;
  }

  /// The town's full-lit sweep (0→1 over ~0.8s when _townLit latches). The windows
  /// already warm at the latch stay solid; the remaining ones ease in by this value.
  double _townSweep = 0;
  double get townSweep => _townSweep;
  bool get townSweepActive => _townLitLatched && _townSweep < 0.999;

  /// Delivered fraction captured at the instant the town latched — the windows below
  /// this were already warm (solid); above it, they sweep in (PRD §6 step 9).
  double _deliveredAtLatch = 0;
  double get deliveredAtLatch => _deliveredAtLatch;

  // ── Phase / latch bookkeeping ─────────────────────────────────────────
  bool _started = false;
  bool _discovered = false; // V ≥ discoveryV (one-way)
  bool _townLitLatched = false; // delivered ≥ gate (one-way)
  bool _topped = false; // V ≥ topV held topHoldSeconds (one-way)
  double _topHeldElapsed = 0;

  // ── Timer chain ───────────────────────────────────────────────────────
  double _step = -1; // ms countdown for the next scheduled action
  void Function()? _stepAction;

  void _schedule(int ms, void Function() action) {
    _step = ms.toDouble();
    _stepAction = action;
  }

  void _setCaption(TTCaptionId id) => caption.value = TTCopy.of(id);

  // ── Lifecycle ─────────────────────────────────────────────────────────
  /// Start the intro chain (called from the shell's first post-frame).
  void start() {
    if (_started) return;
    _started = true;
    // Entrance happens via reveal getters; I1 lands after the entrance (no preamble).
    _schedule(TTCopy.introToI1Ms, () {
      _setCaption(TTCaptionId.i1Raise);
      phase.value = TTPhase.raise; // the VOLTAGE slider goes live here
      notifyListeners();
    });
    notifyListeners();
  }

  // ── VOLTAGE slider → voltage (the simple, familiar control, like 2.3/2.4). A
  // normalized 0..1 slider value maps linearly to V ∈ [vMin, vMax]; same-frame, no
  // smoothing, no inertia (PRD §10). The rectangle morphs as a readout; the wire
  // cools and the town lights, all in the same frame the slider moves.
  double _lastDetent = TTTune.vMin;

  /// The control is live once the intro reaches the raise phase (PRD §6).
  bool get controlEnabled => phase.value.index >= TTPhase.raise.index;

  /// The slider's current normalized position (0 at vMin, 1 at vMax) — so the slider
  /// reflects the clamped voltage exactly.
  double get sliderNorm => TTTune.voltageNorm(_voltage);

  void onSliderChanged(double norm01) {
    if (!controlEnabled) return;
    final v = TTTune.vMin + norm01.clamp(0.0, 1.0) * (TTTune.vMax - TTTune.vMin);
    _setVoltage(v);
  }

  void _setVoltage(double v) {
    final clamped = v.clamp(TTTune.vMin, TTTune.vMax);
    if (clamped == _voltage) return;
    // Detent haptic each +detentV crossing (both directions).
    final crossed = (clamped / TTTune.detentV).floor() != (_lastDetent / TTTune.detentV).floor();
    // Momentary trend for the gauge ↑/↓ glyphs (decays in tick).
    _voltTrend = clamped > _voltage ? 1 : -1;
    _trendHold = 0.35;
    _voltage = clamped;
    if (crossed) {
      _lastDetent = clamped;
      onDetent?.call();
    }
    _checkLatches();
    notifyListeners();
  }

  // ── Latches (one-way; never regress on drag-down) ─────────────────────
  void _checkLatches() {
    // Discovery — first time V ≥ discoveryV (PRD §6 step 7).
    if (!_discovered && phase.value == TTPhase.raise && _voltage >= TTTune.discoveryV) {
      _discovered = true;
      _ringActive = true;
      _ringElapsed = 0;
      onDiscovery?.call(); // heavyImpact
      onCapture?.call('current_drops_itself'); // lightImpact + capture flash (shell)
      // +600ms → "The Current Falls on Its Own" → "Voltage Up, Current Down" → I2.
      _schedule(TTCopy.discoveryToCurrentFallsMs, () {
        _setCaption(TTCaptionId.currentFalls);
        _schedule(TTCopy.currentFallsHoldMs, () {
          _setCaption(TTCaptionId.voltageUpCurrentDown);
          _schedule(TTCopy.voltageUpDownHoldMs, () {
            _setCaption(TTCaptionId.i2LightTown);
            phase.value = TTPhase.lightTown;
            notifyListeners();
          });
        });
      });
    }

    // Light the whole town — delivered ≥ gate, only in lightTown phase (step 9).
    if (!_townLitLatched &&
        phase.value == TTPhase.lightTown &&
        delivered >= TTTune.townDeliveredGate) {
      _townLitLatched = true;
      _deliveredAtLatch = delivered; // windows below this were already warm
      _townSweep = 0; // animates 0→1 in tick (the 800ms bloom)
      // (No capture fires here — the second tile is a dropped id; see _enterClosing.)
      // +500ms → "Less Current, Less Heat Lost", then I3 (send it to the top).
      _schedule(TTCopy.townLitToLessHeatMs, () {
        _setCaption(TTCaptionId.lessHeatLost);
        _schedule(TTCopy.lessHeatHoldMs, () {
          _setCaption(TTCaptionId.i3SendTop);
          phase.value = TTPhase.sendTop;
          _topHeldElapsed = 0;
          notifyListeners();
        });
      });
    }
  }

  // ── The tick: same-frame causal sim already lives in getters; here we ──
  //     advance time-based motion, the sendTop steadiness window, reveals.
  void tick(double dt) {
    if (dt <= 0) return;
    _shimmer += dt;

    // Decay the gauge trend so a held (idle) finger reads "steady" after a beat.
    if (_trendHold > 0) {
      _trendHold -= dt;
      if (_trendHold <= 0) _voltTrend = 0;
    }

    // Re-check the discovery / town-lit latches here too (not only on drag) so a gate
    // that only becomes active on a phase flip (e.g. the town gate when L6's timer
    // sets phase=lightTown) still fires if the learner is already holding a high
    // voltage and not actively dragging.
    _checkLatches();

    // Current pulses + heat-shimmer advance with time (motion, not causality).
    if (!reducedMotion) {
      _pulsePhase = (_pulsePhase + dt * TTTune.pulseSpeed) % 1.0;
    }

    // Discovery ring envelope.
    if (_ringActive) {
      _ringElapsed += dt;
      if (_ringElapsed >= TTTune.discoveryRingSeconds) _ringActive = false;
    }

    // Town full-lit sweep (0→1). Fast fade under reduced motion.
    if (_townLitLatched && _townSweep < 1) {
      final rate = reducedMotion ? 4.0 : (1 / 0.8);
      _townSweep = (_townSweep + dt * rate).clamp(0.0, 1.0);
    }

    // sendTop steadiness window — V ≥ topV held continuously topHoldSeconds (step 11).
    if (!_topped && phase.value == TTPhase.sendTop) {
      if (_voltage >= TTTune.topV) {
        _topHeldElapsed += dt;
        if (_topHeldElapsed >= TTTune.topHoldSeconds) {
          _topped = true;
          // PRD §9's second capture id ('cold_wire_full_town') is a DROPPED id absent
          // from the EP2 catalog — firing it would be a bug (guardrails). The felt
          // win + the card still land; no capture fires here.
          _enterClosing();
        }
      } else {
        _topHeldElapsed = 0; // must be held CONTINUOUSLY
      }
    }

    // Entrance reveals (intro → 1; fades under reduced motion are still 0→1 here).
    _plantReveal = _approach(_plantReveal, 1, dt, TTTune.plantRevealTau);
    _wireReveal = _approach(_wireReveal, 1, dt, TTTune.wireRevealTau);
    _townReveal = _approach(_townReveal, 1, dt, TTTune.townRevealTau);

    // Scheduled transition timer.
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

  void _enterClosing() {
    phase.value = TTPhase.closing;
    // +400ms → "The Transmission Trick" (named last) → "Real lines..." → card.
    _schedule(TTCopy.toppedToTrickMs, () {
      _setCaption(TTCaptionId.theTrick);
      _schedule(TTCopy.trickHoldMs, () {
        _setCaption(TTCaptionId.realLines);
        _schedule(TTCopy.realLinesToCardMs, () {
          showCardEarn.value = true;
          notifyListeners();
        });
      });
    });
    notifyListeners();
  }

  void onCardCollected() {
    showCardEarn.value = false;
    _setCaption(TTCaptionId.none);
    canFinish.value = true;
    notifyListeners();
  }

  static double _approach(double cur, double target, double dt, double tau) =>
      cur + (target - cur) * (1 - math.exp(-dt / tau));

  @override
  void dispose() {
    caption.dispose();
    phase.dispose();
    showCardEarn.dispose();
    canFinish.dispose();
    super.dispose();
  }
}
