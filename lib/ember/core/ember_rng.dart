// Ember — core/ember_rng.dart
//
// The ONLY source of randomness allowed in core/ + sim/. A seeded SplitMix64
// PRNG whose entire state is a single 64-bit integer, so it serializes into the
// save and replays bit-for-bit. NEVER use dart:math Random in deterministic
// code — that is what lets live play, offline catch-up, and tests share one
// WorldSimulation.advance() tick.

/// 64-bit mask (Dart ints are 64-bit two's-complement on the VM; on web they
/// are doubles, but Ember targets mobile/desktop Flame so VM int semantics
/// hold). We mask explicitly to stay well-defined.
const int _mask64 = -1; // all bits set in two's complement == 0xFFFFFFFFFFFFFFFF

/// Deterministic SplitMix64 generator. Cheap, good distribution, trivially
/// serializable (one int). Advancing it mutates [state]; that mutation is the
/// reproducible stream.
class EmberRng {
  EmberRng(this.state);

  /// Builds an rng from a human seed by mixing it once (avoids weak low seeds).
  factory EmberRng.seed(int seed) {
    // Mix the seed through one SplitMix64 step so seed=0,1,2 don't correlate.
    final EmberRng tmp = EmberRng(seed & _mask64);
    return EmberRng(tmp._next());
  }

  /// Raw 64-bit internal state. Public so the save can round-trip it.
  int state;

  /// Core SplitMix64 step: advances [state] and returns a scrambled 64-bit word.
  int _next() {
    // state += 0x9E3779B97F4A7C15
    state = (state + 0x9E3779B97F4A7C15) & _mask64;
    int z = state;
    z = ((z ^ (z >>> 30)) * 0xBF58476D1CE4E5B9) & _mask64;
    z = ((z ^ (z >>> 27)) * 0x94D049BB133111EB) & _mask64;
    z = z ^ (z >>> 31);
    return z & _mask64;
  }

  /// Next full 64-bit value.
  int nextU64() => _next();

  /// Next unsigned 32-bit value (0 .. 2^32-1).
  int nextU32() => _next() & 0xFFFFFFFF;

  /// Next double in [0, 1) using the top 53 bits (full mantissa precision).
  double nextDouble() {
    final int bits = _next() >>> 11; // 53 bits
    return bits / 9007199254740992.0; // 2^53
  }

  /// Next int in [0, bound). Throws if bound <= 0.
  int nextInt(int bound) {
    if (bound <= 0) {
      throw ArgumentError.value(bound, 'bound', 'must be > 0');
    }
    // Rejection-free modulo bias is negligible for game-scale bounds; use the
    // double path for clean, deterministic distribution.
    return (nextDouble() * bound).floor().clamp(0, bound - 1);
  }

  /// Next int in [min, max] inclusive.
  int nextRange(int min, int max) {
    if (max < min) {
      throw ArgumentError('max ($max) must be >= min ($min)');
    }
    return min + nextInt(max - min + 1);
  }

  /// True with probability [p] (clamped to [0,1]).
  bool chance(double p) => nextDouble() < p.clamp(0.0, 1.0);

  /// A child rng deterministically derived from this one (for sub-streams that
  /// shouldn't perturb the parent's order). Consumes one value from the parent.
  EmberRng split() => EmberRng(_next());

  /// Deep value copy (same state, independent object).
  EmberRng clone() => EmberRng(state);

  Map<String, dynamic> toJson() => <String, dynamic>{'state': state};

  factory EmberRng.fromJson(Map<String, dynamic> j) =>
      EmberRng((j['state'] as num?)?.toInt() ?? 0);

  @override
  bool operator ==(Object other) => other is EmberRng && other.state == state;

  @override
  int get hashCode => state.hashCode;

  @override
  String toString() => 'EmberRng(state: $state)';
}
