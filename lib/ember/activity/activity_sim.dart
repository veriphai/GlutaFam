// Ember — activity/activity_sim.dart
//
// The BEAT-2 (interact) brain a leaf implements. The BeatController drives it:
// start(rules) when the interact beat opens, onInput(i) as the player acts,
// tick(dt) each frame; the sim emits SimEvents the controller scores against the
// InteractionRules. This is a self-contained mini-simulation for ONE activity —
// it is NOT the WorldSimulation. It may hold local mutable state but must stay
// reproducible given the same input sequence (no DateTime/Random; if it needs
// chance it should be fed a seed via rules.config and use an EmberRng).

import 'activity_contract.dart';

/// A discrete player action delivered to the [ActivitySim]. [code] is a stable
/// verb ("strike", "addFuel", "selectTile"); [data] carries parameters.
class SimInput {
  const SimInput(this.code, [this.data = const <String, dynamic>{}]);

  final String code;
  final Map<String, dynamic> data;

  T? param<T>(String key) => data[key] as T?;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'code': code, 'data': data};

  factory SimInput.fromJson(Map<String, dynamic> j) => SimInput(
        j['code'] as String? ?? '',
        (j['data'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      );

  @override
  bool operator ==(Object other) =>
      other is SimInput && other.code == code && _mapEq(other.data, data);

  @override
  int get hashCode {
    int h = code.hashCode;
    for (final MapEntry<String, dynamic> e in data.entries) {
      h ^= Object.hash(e.key, e.value);
    }
    return h;
  }
}

/// An event emitted by the [ActivitySim] for the controller to score. [code] is
/// matched against InteractionRules.successSignal and FailureRule.signal.
class SimEvent {
  const SimEvent(this.code, {this.message = '', this.data = const <String, dynamic>{}});

  /// Stable event code (e.g. "ignited", "fuelStarved", "windBlewOut").
  final String code;

  /// Optional human-readable message (feedback/animation cue).
  final String message;

  /// Optional structured payload.
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'code': code, 'message': message, 'data': data};

  factory SimEvent.fromJson(Map<String, dynamic> j) => SimEvent(
        j['code'] as String? ?? '',
        message: j['message'] as String? ?? '',
        data: (j['data'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      );

  @override
  String toString() => 'SimEvent($code${message.isEmpty ? '' : ': $message'})';
}

/// The interactive brain for one activity's interact beat. Implemented by a leaf.
abstract interface class ActivitySim {
  /// Begin the interaction with the activity's [rules].
  void start(InteractionRules rules);

  /// Feed a discrete player [input].
  void onInput(SimInput input);

  /// Advance internal state by [dtSeconds].
  void tick(double dtSeconds);

  /// Stream of events the controller scores. Single-subscription is fine.
  Stream<SimEvent> get events;

  /// Release resources (close the event stream).
  void dispose();
}

bool _mapEq(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (a.length != b.length) return false;
  for (final MapEntry<String, dynamic> e in a.entries) {
    if (b[e.key] != e.value) return false;
  }
  return true;
}
