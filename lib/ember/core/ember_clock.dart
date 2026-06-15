// Ember — core/ember_clock.dart
//
// The ONLY source of wall-clock time in the module. core/, data/models, sim/,
// contracts/, activity/ must never call DateTime.now() directly — they receive
// time through an [EmberClock]. state/ + repository/ may construct a
// [SystemClock]; tests use [FakeClock].

/// Abstract clock. Returns "now" as epoch milliseconds.
abstract interface class EmberClock {
  /// Current time in milliseconds since the Unix epoch (UTC).
  int nowMs();
}

/// Real clock backed by the platform. Only state/ + repository/ should build it.
class SystemClock implements EmberClock {
  const SystemClock();

  @override
  int nowMs() => DateTime.now().millisecondsSinceEpoch;
}

/// Deterministic clock for tests/preview. Time only moves when you move it.
class FakeClock implements EmberClock {
  FakeClock([this._nowMs = 0]);

  int _nowMs;

  @override
  int nowMs() => _nowMs;

  /// Jumps the clock forward by [ms] (must be >= 0).
  void advance(int ms) {
    assert(ms >= 0, 'FakeClock cannot move backwards');
    _nowMs += ms;
  }

  /// Hard-sets the clock to [ms].
  void setTo(int ms) => _nowMs = ms;
}
