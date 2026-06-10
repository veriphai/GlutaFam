// The creature's data model — the primitive this vertical slice establishes
// (PRD §5). The creature is the READOUT of a [Genome]: four illustrative
// "instruction" genes → a parametrically drawn body. One InstructionControl
// binds to exactly one field, so moving one control changes only its one trait
// (acceptance criterion 1).
//
// IMPORTANT: the A/T/C/G strings are ILLUSTRATIVE ONLY — not a real genetic
// code, no base-pairing rules (PRD §2 non-goals). They exist to make "the
// instructions are written in a four-letter code" felt, nothing more.

/// The four instruction genes. One [InstructionControl] binds to one field.
enum GeneField { size, limbs, colour, pattern }

extension GeneFieldInfo on GeneField {
  /// Neutral label in 0.1 ("size · limbs · colour · pattern", PRD §6).
  String get label {
    switch (this) {
      case GeneField.size:
        return 'Size';
      case GeneField.limbs:
        return 'Limbs';
      case GeneField.colour:
        return 'Colour';
      case GeneField.pattern:
        return 'Pattern';
    }
  }
}

/// The creature is the readout of this. Immutable + [withValue] so a control
/// drag produces a fresh genome the painter renders next frame.
class Genome {
  const Genome({
    this.size = 0.58,
    this.limbLength = 0.5,
    this.hue = 138, // a warm "life" green to start
    this.patternDensity = 0.42,
  });

  final double size; // 0..1   → overall scale
  final double limbLength; // 0..1   → appendage length
  final double hue; // 0..360 → body colour
  final double patternDensity; // 0..1   → spots amount

  /// Normalised 0..1 reading of a field (colour folded to 0..1 for the slider).
  double value(GeneField f) {
    switch (f) {
      case GeneField.size:
        return size;
      case GeneField.limbs:
        return limbLength;
      case GeneField.colour:
        return hue / 360.0;
      case GeneField.pattern:
        return patternDensity;
    }
  }

  Genome withValue(GeneField f, double v) {
    final c = v.clamp(0.0, 1.0);
    switch (f) {
      case GeneField.size:
        return copyWith(size: c);
      case GeneField.limbs:
        return copyWith(limbLength: c);
      case GeneField.colour:
        return copyWith(hue: c * 360.0);
      case GeneField.pattern:
        return copyWith(patternDensity: c);
    }
  }

  Genome copyWith({double? size, double? limbLength, double? hue, double? patternDensity}) =>
      Genome(
        size: size ?? this.size,
        limbLength: limbLength ?? this.limbLength,
        hue: hue ?? this.hue,
        patternDensity: patternDensity ?? this.patternDensity,
      );

  /// A torn / garbled copy — one half of the recipe lost (stubbed limbs + the
  /// pattern gone) → the `broken` render. Illustrative of "half the recipe, half
  /// a creature" (PRD §6 Beat 0.3, the A4 foreshadow).
  Genome get torn => copyWith(limbLength: 0.06, patternDensity: 0.0);

  /// An ILLUSTRATIVE A/T/C/G read-out of one gene (NOT a real genetic code): the
  /// value seeds a deterministic four-letter string so it reads as "a long
  /// string of four repeating letters" and shifts as the kid scrubs. Shown only
  /// on the 0.2 peek.
  String encodeForDisplay(GeneField f, {int length = 48}) {
    const letters = 'ATCG';
    final seed = (value(f).clamp(0.0, 1.0) * 9973).round() + 7;
    final sb = StringBuffer();
    var x = seed | 1;
    for (var i = 0; i < length; i++) {
      // A tiny LCG → a stable pseudo-random letter run per value. Use the HIGH
      // bits (the low bits of a classic LCG are near-degenerate → all-'A' runs).
      x = (x * 1103515245 + 12345) & 0x7fffffff;
      sb.write(letters[(x >> 24) & 3]);
    }
    return sb.toString();
  }
}

/// How the creature is drawn (PRD §5).
/// • live      — full colour + subtle idle motion; obeys the controls.
/// • wireframe — grey inert outline (the skeleton result): no colour, no motion.
/// • photo     — flat, desaturated, frozen snapshot; not interactive.
/// • broken    — live, but with one trait missing/garbled (the torn-recipe result).
enum CreatureRenderMode { live, wireframe, photo, broken }
