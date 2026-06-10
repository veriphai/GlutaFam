// The Sankey value model — pure arithmetic, no Flutter, no rendering.
//
// 100 units enter; each stage keeps a fraction (its efficiency) and leaks the
// rest as heat:  out_i = in_i * eff_i ;  leak_i = in_i * (1 - eff_i).
// The final `output` (~38 for coal) is the survivor that lights the bulb; the
// rest (~62) is what became heat. Efficiencies are FIXED (no plugging / fixing in
// this demonstration) — the point is that the loss happens, not tuning it away.

import '../config/leaky_chain_defs.dart';

/// One computed link in the chain — what the renderer and the number chips read.
class LeakySegment {
  LeakySegment({
    required this.kind,
    required this.inValue,
    required this.outValue,
    required this.leak,
    required this.dramatic,
  });

  final LeakStepKind kind;
  final double inValue; // energy entering this stage
  final double outValue; // energy leaving (= inValue * eff)
  final double leak; // energy lost here as heat
  final bool dramatic; // the big leak (the turbine)
}

class LeakyModel {
  LeakyModel({LeakySource source = LeakySource.coal}) {
    setSource(source);
  }

  static const double input = 100;

  late LeakySourceDef _def;
  LeakySourceDef get def => _def;
  LeakySource get source => _def.source;

  void setSource(LeakySource source) => _def = kLeakySources[source]!;

  double effOf(LeakStepKind k) => _def.steps.firstWhere((s) => s.kind == k).defaultEff;

  /// The chain computed top→bottom.
  List<LeakySegment> get segments {
    final out = <LeakySegment>[];
    var flowing = input;
    for (final s in _def.steps) {
      final leaving = flowing * s.defaultEff;
      out.add(LeakySegment(
        kind: s.kind,
        inValue: flowing,
        outValue: leaving,
        leak: flowing - leaving,
        dramatic: s.dramatic,
      ));
      flowing = leaving;
    }
    return out;
  }

  /// The survivor that reaches the bulb (≈38 for coal).
  double get output {
    var flowing = input;
    for (final s in _def.steps) {
      flowing *= s.defaultEff;
    }
    return flowing;
  }

  /// What became heat along the way (≈62 for coal) — input minus the survivor.
  double get totalHeat => input - output;

  /// 0..1 — bulb brightness from the output. Kept linear: the dimness IS the lesson.
  double get bulbBrightness => (output / input).clamp(0.0, 1.0);
}
