// Ember — concepts/tools/knapping_sim.dart
//
// The interactive BRAIN for the Knapping interact beat. It is a small, self-
// contained state machine over three phases — choose the stone, strike to flake,
// (optional) haft a spear — that emits [SimEvent]s the [BeatController] scores
// against the activity's rules. The teaching failures (wrong material, too weak,
// shattered) ARE the §3 knapping lesson, surfaced by play. Each strike's outcome
// is decided by the PURE [StrikeResolver] (material + angle + force), so the sim
// is just input plumbing + progress accounting over that single source of truth.
//
// DETERMINISM: this is presentation-layer interaction state, never fed into
// EmberWorldState, so it MAY use its own timers. It holds NO clock and NO Random —
// outcomes come from the deterministic resolver + the player's strike params — so
// a fixed input sequence is reproducible.

import 'dart:async';

import '../../activity/activity_contract.dart';
import '../../activity/activity_sim.dart';
import 'knapping_activity.dart';
import 'strike_resolver.dart';

/// The phases the player walks through inside one knapping attempt.
enum KnappingPhase { chooseStone, strike, haft, finished }

/// The drag/strike mini-game brain. One instance per interact beat; re-armed on
/// retry via [start].
class KnappingSim implements ActivitySim {
  KnappingSim({this.resolver = const StrikeResolver()});

  /// The pure strike-outcome brain (material + angle + force -> result + lesson).
  final StrikeResolver resolver;

  final StreamController<SimEvent> _events =
      StreamController<SimEvent>.broadcast();

  @override
  Stream<SimEvent> get events => _events.stream;

  // ---- Tunables (read from InteractionRules.config) ----------------------
  /// Total flake-progress (sum of clean-flake deltas) needed to finish a blade.
  double _flakeToFinish = 1.0;

  /// Whether the optional haft step is offered after the blade is shaped.
  bool _offerHaft = true;

  // ---- Live interaction state --------------------------------------------
  KnappingPhase _phase = KnappingPhase.chooseStone;
  KnappingPhase get phase => _phase;

  /// The chosen stone material (null until the player picks).
  StoneMaterial? _material;
  StoneMaterial? get material => _material;

  /// 0..1 progress toward a finished blade (sum of clean-flake deltas).
  double _flake = 0.0;
  double get flake => _flake;

  /// How many clean flakes have been struck this attempt (readability/feedback).
  int _cleanFlakes = 0;
  int get cleanFlakes => _cleanFlakes;

  /// The result of the most recent strike (null before the first strike).
  StrikeResult? _lastStrike;
  StrikeResult? get lastStrike => _lastStrike;

  /// Whether the finished tool was hafted into a spear.
  bool _hafted = false;
  bool get hafted => _hafted;

  /// Whether the player ever chose a non-knappable stone this attempt (so the
  /// activity can credit "materials understood" only on a clean, unaided run).
  bool _pickedWrongMaterial = false;
  bool get pickedWrongMaterial => _pickedWrongMaterial;

  /// Whether this attempt has already resolved (success or a fail surfaced) so
  /// further input/ticks are ignored until [start] re-arms.
  bool _resolved = false;

  @override
  void start(InteractionRules rules) {
    final Map<String, dynamic> c = rules.config;
    _flakeToFinish = _cfg(c, KnappingSignals.cfgFlakeToFinish, _flakeToFinish);
    _offerHaft = (c[KnappingSignals.cfgOfferHaft] as bool?) ?? _offerHaft;

    // Re-arm a fresh attempt.
    _phase = KnappingPhase.chooseStone;
    _material = null;
    _flake = 0.0;
    _cleanFlakes = 0;
    _lastStrike = null;
    _hafted = false;
    _pickedWrongMaterial = false;
    _resolved = false;
  }

  static double _cfg(Map<String, dynamic> c, String key, double fallback) =>
      (c[key] as num?)?.toDouble() ?? fallback;

  @override
  void onInput(SimInput input) {
    if (_resolved) return;
    switch (input.code) {
      case KnappingSignals.inChooseStone:
        _onChooseStone(input);
      case KnappingSignals.inStrike:
        _onStrike(input);
      case KnappingSignals.inHaft:
        _onHaft();
      case KnappingSignals.inSkipHaft:
        _onSkipHaft();
    }
  }

  void _onChooseStone(SimInput input) {
    if (_phase != KnappingPhase.chooseStone) return;
    final StoneMaterial m = _materialFromName(input.param<String>('material'));
    _material = m;
    _emit(StrikeSignals.stoneChosen,
        message: 'Stone chosen. Now strike it — glancing angle, steady force.',
        data: <String, dynamic>{'material': m.name});

    if (!materialIsKnappable(m)) {
      // MATERIAL lesson: a soft/non-glassy stone can never make an edge. Surface
      // the teaching failure immediately (the player learns by the wrong pick).
      _pickedWrongMaterial = true;
      final StrikeOutcome o = resolver.resolve(
        material: m,
        angleDeg: StrikeResolver.idealAngleDeg,
        force: 0.5,
      );
      _lastStrike = o.result;
      _fail(o.signal, o.lesson);
      return;
    }
    // A good stone — move to striking.
    _phase = KnappingPhase.strike;
  }

  void _onStrike(SimInput input) {
    if (_phase != KnappingPhase.strike) return;
    final StoneMaterial? m = _material;
    if (m == null) return;

    final double angle = (input.param<num>('angleDeg') ?? 90).toDouble();
    final double force = (input.param<num>('force') ?? 0).toDouble();

    final StrikeOutcome o =
        resolver.resolve(material: m, angleDeg: angle, force: force);
    _lastStrike = o.result;

    switch (o.result) {
      case StrikeResult.cleanFlake:
        _cleanFlakes += 1;
        _flake = (_flake + o.progressDelta).clamp(0.0, 1.0);
        _emit(StrikeSignals.cleanFlake,
            message: o.lesson,
            data: <String, dynamic>{
              'flake': _flake,
              'cleanFlakes': _cleanFlakes,
            });
        if (_flake >= _flakeToFinish) {
          _onBladeShaped();
        }
      case StrikeResult.shatter:
        // SHATTER lesson — too hard / wrong angle. A teaching failure (gentle,
        // instantly retryable — the FailureRule's hint teaches).
        _fail(o.signal, o.lesson);
      case StrikeResult.noFlake:
        // TOO-WEAK lesson — a soft tap. Also a teaching failure.
        _fail(o.signal, o.lesson);
    }
  }

  void _onBladeShaped() {
    if (_offerHaft) {
      _phase = KnappingPhase.haft;
      _emit(StrikeSignals.flakeProgress,
          message: 'A sharp blade! Lash it to a shaft to make a spear — '
              'or finish as-is.',
          data: <String, dynamic>{'flake': 1.0, 'bladeShaped': true});
    } else {
      _finish();
    }
  }

  void _onHaft() {
    if (_phase != KnappingPhase.haft) return;
    _hafted = true;
    _emit(StrikeSignals.hafted,
        message: 'Hafted! The point is lashed to a shaft — a spear with reach.');
    _finish();
  }

  void _onSkipHaft() {
    if (_phase != KnappingPhase.haft) return;
    _finish();
  }

  void _finish() {
    if (_resolved) return;
    _phase = KnappingPhase.finished;
    _resolved = true;
    _emit(StrikeSignals.bladeFinished,
        message: _hafted
            ? 'A hafted spear — sharper than any claw, with reach to spare!'
            : 'A finished stone blade — sharper than any claw!',
        data: <String, dynamic>{'hafted': _hafted});
  }

  @override
  void tick(double dtSeconds) {
    // Knapping is purely input-driven (no decay timers) — nothing to advance.
  }

  void _fail(String code, String message) {
    if (_resolved) return;
    _resolved = true;
    _emit(code, message: message);
  }

  void _emit(String code, {String message = '', Map<String, dynamic>? data}) {
    if (_events.isClosed) return;
    _events.add(SimEvent(code,
        message: message, data: data ?? const <String, dynamic>{}));
  }

  static StoneMaterial _materialFromName(Object? n) {
    if (n is String) {
      for (final StoneMaterial v in StoneMaterial.values) {
        if (v.name == n) return v;
      }
    }
    return StoneMaterial.flint;
  }

  @override
  void dispose() {
    if (!_events.isClosed) _events.close();
  }
}
