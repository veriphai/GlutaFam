// Ember — concepts/fire/make_fire_sim.dart
//
// The interactive BRAIN for the Make Fire interact beat — rebuilt for DIRECT,
// SAME-FRAME manipulation. It is a small, self-contained state machine over four
// phases — seat tinder, drill heat, catch the ember, give it air — driven by
// CONTINUOUS hero channels the finger sets each frame (not +per-tap):
//
//   * TINDER  — a drag seats a grass tuft in the notch. Dry seats (FUEL ok);
//     damp can never seat (the FUEL lesson, felt, not read).
//   * HEAT    — a raw rotational drag sets the spindle's angular velocity; the
//     sim turns |velocity| straight into friction heat THIS frame. HARD-GATE:
//     the instant the finger stops, velocity -> 0 and the notch heat bleeds down
//     immediately ("stop spinning and it cools" = the HEAT lesson).
//   * AIR     — an upward swipe puffs the ember (puff strength = flame growth,
//     same frame); a stone-lid drag cuts its air (the AIR lesson).
//
// The three teaching failures (damp tinder = FUEL, stalled drilling = HEAT,
// smother = AIR) ARE the fire triangle, surfaced by play. The FailureRules +
// the success signal contract are UNCHANGED so the BeatController scores exactly
// as before.
//
// DETERMINISM: this is presentation-layer interaction state, never fed into
// EmberWorldState, so it MAY use its own dt-driven decay. It holds NO clock and
// NO Random — every channel advances purely from player input + the dt the
// controller passes — so a fixed input sequence is reproducible. The scene reads
// the live channels (heat / ember / flame / spinVel / tinderSeated / air) so its
// stage components stay near-pure render(Canvas) readers (controller-owns-all).

import 'dart:async';
import 'dart:math' as math;

import '../../activity/activity_contract.dart';
import '../../activity/activity_sim.dart';
import 'make_fire_activity.dart';

/// The four phases the player walks through inside one ignition attempt.
enum MakeFirePhase { gatherTinder, buildHeat, catchEmber, giveAir, ignited }

/// The drillable mini-game brain. One instance per interact beat; re-armed on
/// retry via [start].
class MakeFireSim implements ActivitySim {
  MakeFireSim();

  final StreamController<SimEvent> _events =
      StreamController<SimEvent>.broadcast();

  @override
  Stream<SimEvent> get events => _events.stream;

  // ---- Tunables (read from InteractionRules.config) ----------------------
  /// How fast heat builds per unit of drive (the finger's rub speed) per second.
  /// Friction heat is integrated each frame: heat += k*drive*dt. Tuned so a brisk
  /// rub (drive ~18-28) catches an ember in well under a second, and a gentle rub
  /// (drive ~7) in ~2s — it MUST out-build the idle bleed below so sustained
  /// rubbing always wins (the old 0.028 lost to the 0.62 bleed and never lit).
  double _heatPerSpin = 0.07;

  /// How fast the notch cools while NOT being driven (the HARD-GATE bleed: felt
  /// when the finger truly stops). Kept BELOW the rub gain so any real rubbing
  /// nets positive; only a genuine pause cools it down.
  double _heatDecayPerSec = 0.40;

  double _heatToEmber = 1.0;
  double _emberDecayPerSec = 0.10;

  /// Flame growth per unit of puff strength (an upward swipe's length, 0..1).
  double _flamePerPuff = 0.34;
  double _flameToIgnite = 1.0;
  double _emberWindowSec = 6.0;

  /// Crank speed below this reads as "the finger stopped" — heat HARD-bleeds and a
  /// sustained stall with progress surfaces the HEAT lesson. Low so any real crank
  /// counts; the scene's sample-timeout HOLD (ported from the Hand-Crank Lamp) keeps
  /// a CONTINUOUS crank's true rad/s above it across the gaps between pointer-move
  /// samples, so sustained cranking always out-builds the idle bleed.
  double _spinStallThreshold = 0.8;

  // ---- Live interaction state --------------------------------------------
  MakeFirePhase _phase = MakeFirePhase.gatherTinder;
  MakeFirePhase get phase => _phase;

  /// 0..1 how seated the tuft is in the notch (the FUEL channel the stage reads).
  double _tinderSeated = 0.0;
  double get tinderSeated => _tinderSeated;

  /// 0..1 friction heat at the notch; built by spin, HARD-bleeds when idle.
  double _heat = 0.0;
  double get heat => _heat;

  /// The spindle's live |angular velocity| (rad/s, the finger sets it each frame).
  double _spinVel = 0.0;
  double get spinVel => _spinVel;

  /// 0..1 ember brightness; appears after enough heat, fades without air.
  double _ember = 0.0;
  double get ember => _ember;

  /// 0..1 flame strength; grown by puffing once the ember is caught.
  double _flame = 0.0;
  double get flame => _flame;

  /// 0..1 live AIR channel — eases up on each puff, decays between (the third
  /// fire-triangle corner the stage fills from a live felt channel, not a flag).
  double _air = 0.0;
  double get air => _air;

  /// Seconds remaining in the ember window before it dies (the AIR pressure).
  double _emberTimeLeft = 0.0;
  double get emberTimeLeft => _emberTimeLeft;

  /// Whether this attempt has already resolved (success or a fail surfaced) so
  /// further input/ticks are ignored until [start] re-arms.
  bool _resolved = false;

  /// How long the player has been stalled (no real spin) WHILE some heat exists
  /// during buildHeat — a sustained stall surfaces the HEAT lesson once it has
  /// also bled the progress away, so "too slow" is felt before it's named.
  double _stallAccum = 0.0;

  @override
  void start(InteractionRules rules) {
    final Map<String, dynamic> c = rules.config;
    _heatPerSpin = _cfg(c, MakeFireSignals.cfgHeatPerSpin, _heatPerSpin);
    _heatDecayPerSec =
        _cfg(c, MakeFireSignals.cfgHeatDecayPerSec, _heatDecayPerSec);
    _heatToEmber = _cfg(c, MakeFireSignals.cfgHeatToEmber, _heatToEmber);
    _emberDecayPerSec =
        _cfg(c, MakeFireSignals.cfgEmberDecayPerSec, _emberDecayPerSec);
    _flamePerPuff = _cfg(c, MakeFireSignals.cfgFlamePerPuff, _flamePerPuff);
    _flameToIgnite = _cfg(c, MakeFireSignals.cfgFlameToIgnite, _flameToIgnite);
    _emberWindowSec =
        _cfg(c, MakeFireSignals.cfgEmberWindowSec, _emberWindowSec);
    _spinStallThreshold =
        _cfg(c, MakeFireSignals.cfgSpinStallThreshold, _spinStallThreshold);

    // Re-arm a fresh attempt.
    _phase = MakeFirePhase.gatherTinder;
    _tinderSeated = 0.0;
    _heat = 0.0;
    _spinVel = 0.0;
    _ember = 0.0;
    _flame = 0.0;
    _air = 0.0;
    _emberTimeLeft = 0.0;
    _stallAccum = 0.0;
    _resolved = false;
  }

  static double _cfg(Map<String, dynamic> c, String key, double fallback) =>
      (c[key] as num?)?.toDouble() ?? fallback;

  @override
  void onInput(SimInput input) {
    if (_resolved) return;
    switch (input.code) {
      case MakeFireSignals.inSelectTinder:
        _onSelectTinder(input);
      case MakeFireSignals.inSpin:
        _onSpin(input);
      case MakeFireSignals.inPuff:
        _onPuff(input);
      case MakeFireSignals.inCover:
        _onCover();
    }
  }

  // ---- TINDER: a drag seats a tuft. Dry seats; damp can never seat. --------
  void _onSelectTinder(SimInput input) {
    if (_phase != MakeFirePhase.gatherTinder) return;
    final bool dry = input.param<bool>('dry') ?? true;
    // 0..1 how far the tuft has been dragged toward the notch this frame.
    final double seat = (input.param<num>('seat')?.toDouble() ?? 1.0).clamp(0.0, 1.0);
    if (!dry) {
      // FUEL lesson: damp grass drips + slumps — it can never seat. It refuses
      // at the brink (the stage shows the slump), then the fail surfaces.
      _tinderSeated = math.min(seat, 0.55);
      if (seat >= 0.5) {
        _fail(MakeFireSignals.dampTinder,
            'The grass is damp — it slumps and will not catch.');
      }
      return;
    }
    // Dry: the tuft seats as the finger pushes it home.
    _tinderSeated = seat;
    if (seat >= 0.98 && _phase == MakeFirePhase.gatherTinder) {
      _phase = MakeFirePhase.buildHeat;
      _emit(MakeFireSignals.tinderChosen,
          message: 'Dry tinder seated. Now spin the drill.');
    }
  }

  // ---- HEAT: a rotational drag sets spin; spin -> friction heat same frame. -
  void _onSpin(SimInput input) {
    if (_phase != MakeFirePhase.buildHeat) return;
    if (_tinderSeated < 0.98) return;
    // The finger SETS the live angular velocity each frame (rad/s). Heat is
    // integrated from |vel| in tick() so it is continuous + same-frame, never
    // a discrete +per-tap. We also fire a quarter-turn tick signal for haptics.
    _spinVel = (input.param<num>('vel')?.toDouble() ?? 0.0).abs();
    if (input.param<bool>('quarterTurn') == true) {
      _emit(MakeFireSignals.spinTick);
    }
  }

  // ---- AIR: an upward swipe puffs the ember; strength = flame growth. -------
  void _onPuff(SimInput input) {
    if (_resolved) return;
    if (_phase != MakeFirePhase.catchEmber && _phase != MakeFirePhase.giveAir) {
      return;
    }
    // Swipe length (0..1) is the puff strength — flame leans + grows same-frame.
    final double strength =
        (input.param<num>('strength')?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    if (strength <= 0.02) return;
    _phase = MakeFirePhase.giveAir;
    _air = (_air + strength).clamp(0.0, 1.0);
    _ember = (_ember + 0.10 * strength).clamp(0.0, 1.0);
    _emberTimeLeft = _emberWindowSec; // a good breath refreshes the window.
    _flame = (_flame + _flamePerPuff * strength).clamp(0.0, 1.0);
    _emit(MakeFireSignals.flameGrowing,
        data: <String, dynamic>{'flame': _flame});

    if (_flame >= _flameToIgnite) {
      _phase = MakeFirePhase.ignited;
      _resolved = true;
      _emit(MakeFireSignals.ignited,
          message: 'It catches — FIRE!', data: <String, dynamic>{'flame': 1.0});
    }
  }

  // ---- AIR fail: a stone lid dragged over the ember cuts its air. -----------
  void _onCover() {
    if (_resolved) return;
    if (_phase == MakeFirePhase.catchEmber || _phase == MakeFirePhase.giveAir) {
      _fail(MakeFireSignals.smothered,
          'You capped it — no air. The ember went dark.');
    }
  }

  @override
  void tick(double dtSeconds) {
    if (_resolved || dtSeconds <= 0) return;
    switch (_phase) {
      case MakeFirePhase.buildHeat:
        _tickHeat(dtSeconds);
      case MakeFirePhase.catchEmber:
      case MakeFirePhase.giveAir:
        _tickEmber(dtSeconds);
      case MakeFirePhase.gatherTinder:
      case MakeFirePhase.ignited:
        break;
    }
  }

  void _tickHeat(double dt) {
    // The finger sets _spinVel each frame; if no inSpin arrived this frame the
    // scene pushes vel 0, so a STOPPED finger immediately reads as no spin.
    final bool spinning = _spinVel >= _spinStallThreshold;
    if (spinning) {
      // Friction: heat builds straight from the live spin, this frame.
      _heat = (_heat + _heatPerSpin * _spinVel * dt).clamp(0.0, 1.0);
      _stallAccum = 0.0;
      _emit(MakeFireSignals.heatProgress,
          data: <String, dynamic>{'heat': _heat});
      if (_heat >= _heatToEmber) {
        // Enough heat — the board smoulders; an ember is born.
        _phase = MakeFirePhase.catchEmber;
        _spinVel = 0.0;
        _ember = 0.55; // a freshly-caught ember starts mid-bright.
        _emberTimeLeft = _emberWindowSec;
        _emit(MakeFireSignals.emberCaught,
            message: 'An ember! Breathe life into it.');
      }
    } else {
      // HARD-GATE: the instant the finger stops, the notch cools NOW.
      _heat = (_heat - _heatDecayPerSec * dt).clamp(0.0, 1.0);
      // HEAT lesson: a sustained stall after some progress surfaces "too slow"
      // (felt as the bleed first, then named). Generous for younger players.
      if (_heat > 0.0) {
        _stallAccum += dt;
        if (_stallAccum >= 2.0) {
          _fail(MakeFireSignals.tooSlow,
              'The board cooled — keep the crank turning to hold the heat.');
        }
      }
    }
  }

  void _tickEmber(double dt) {
    // The ember + air both fade without breath. Let the window run out and the
    // ember dies (the AIR lesson — it needed air sooner).
    _ember = (_ember - _emberDecayPerSec * dt).clamp(0.0, 1.0);
    _air = (_air - 0.55 * dt).clamp(0.0, 1.0);
    _emberTimeLeft -= dt;
    if (_emberTimeLeft <= 0.0 || _ember <= 0.0) {
      _fail(MakeFireSignals.smothered,
          'The ember faded — it needed air sooner.');
    }
  }

  void _fail(String code, String message) {
    if (_resolved) return;
    _resolved = true;
    _spinVel = 0.0;
    _emit(code, message: message);
  }

  void _emit(String code, {String message = '', Map<String, dynamic>? data}) {
    if (_events.isClosed) return;
    _events.add(SimEvent(code,
        message: message, data: data ?? const <String, dynamic>{}));
  }

  @override
  void dispose() {
    if (!_events.isClosed) _events.close();
  }
}
