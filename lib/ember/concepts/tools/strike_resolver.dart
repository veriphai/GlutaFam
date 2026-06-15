// Ember — concepts/tools/strike_resolver.dart
//
// The PURE strike-outcome brain for the Knapping activity. Given the chosen stone
// MATERIAL, the strike ANGLE (degrees off the ideal glancing blow) and the strike
// FORCE (0..1 normalized from drag speed / hold), it returns ONE of three
// outcomes — clean flake / shatter / no-flake — plus the teaching lesson behind
// it. This is the §3 "knapping = right angle + right force on a glassy stone"
// objective, encoded as data so the sim, tests, and any future tuner all agree.
//
// PURE + DETERMINISTIC: no clock, no Random, no world state. The mapping is a
// total function of (material, angle, force). The sim wraps it; this file holds
// the single source of truth for what counts as a good strike.

import 'model/tool.dart';

/// The stone candidates the player picks between. `glassy` materials fracture
/// into sharp edges (flint / obsidian / chert); `soft` ones crumble (PRD §3/§4).
enum StoneMaterial {
  /// Flint — hard + glassy, the reliable knapping stone. Works.
  flint,

  /// Obsidian — volcanic glass, razor sharp but brittle (tighter force window).
  obsidian,

  /// Sandstone — soft + grainy. Crumbles instead of flaking (the FUEL-equivalent
  /// material lesson: the wrong material can NEVER make an edge).
  sandstone,

  /// Granite — hard but NOT glassy: it does not fracture conchoidally, so it
  /// just chips dully and never yields a sharp flake.
  granite,
}

/// Whether a material can fracture into a sharp edge at all (the core §3 lesson).
bool materialIsKnappable(StoneMaterial m) =>
    m == StoneMaterial.flint || m == StoneMaterial.obsidian;

/// The three possible results of one strike.
enum StrikeResult {
  /// A clean, sharp flake detached — progress toward a tool.
  cleanFlake,

  /// The stone (or flake) shattered — too much force / too steep an angle.
  shatter,

  /// Nothing came off — too little force, or the stone just crumbled/chipped.
  noFlake,
}

/// The full outcome of resolving one strike: the result, the teaching lesson
/// signal code (so the activity's FailureRules + success match), and whether the
/// strike made progress.
class StrikeOutcome {
  const StrikeOutcome({
    required this.result,
    required this.signal,
    required this.lesson,
    required this.progressDelta,
  });

  /// Which of the three things happened.
  final StrikeResult result;

  /// The stable signal code emitted to the BeatController (matches a FailureRule
  /// or the success signal in knapping_activity.dart).
  final String signal;

  /// The kid-facing teaching line for this outcome.
  final String lesson;

  /// How much closer to a finished tool this strike got us (0..1 of a flake).
  final double progressDelta;

  bool get isCleanFlake => result == StrikeResult.cleanFlake;
}

/// The frozen signal codes the resolver emits + the activity scores against. Kept
/// here (not just in the activity) so the resolver is self-describing + testable.
class StrikeSignals {
  const StrikeSignals._();

  /// A good flake detached.
  static const String cleanFlake = 'tools.strike.cleanFlake';

  /// The blade is finished (enough clean flakes shaped it) — the SUCCESS signal.
  static const String bladeFinished = 'tools.bladeFinished';

  // ---- Teaching failures ---------------------------------------------------
  /// MATERIAL: a soft/non-glassy stone was chosen — it can never make an edge.
  static const String wrongMaterial = 'tools.fail.wrongMaterial';

  /// FORCE (too weak): the tap was too soft, no flake came off.
  static const String tooWeak = 'tools.fail.tooWeak';

  /// FORCE/ANGLE (too hard / too steep): the stone shattered.
  static const String shattered = 'tools.fail.shattered';

  // ---- Ambient (non-scoring) cues ------------------------------------------
  static const String stoneChosen = 'tools.stoneChosen';
  static const String flakeProgress = 'tools.flakeProgress';
  static const String hafted = 'tools.hafted';
}

/// The pure strike resolver. One [resolve] call -> one [StrikeOutcome].
class StrikeResolver {
  const StrikeResolver();

  /// The ideal strike is a glancing blow ~ this many degrees off the core face.
  /// A window around it produces a clean conchoidal flake.
  static const double idealAngleDeg = 65.0;

  /// Half-width of the "good angle" window (degrees). Inside -> angle is fine.
  static const double angleToleranceDeg = 22.0;

  /// Below this normalized force a strike is too weak to flake anything.
  static const double minForce = 0.30;

  /// Above this normalized force even a good stone shatters from over-striking.
  static const double maxForce = 0.85;

  /// Resolve one strike. [angleDeg] is the strike direction in degrees (0..180,
  /// measured off the core face); [force] is 0..1 (drag speed / hold). The window
  /// for obsidian is a touch tighter (brittle) than flint, teaching that even a
  /// good material rewards control.
  StrikeOutcome resolve({
    required StoneMaterial material,
    required double angleDeg,
    required double force,
  }) {
    final double f = force.clamp(0.0, 1.0);

    // 1) MATERIAL lesson — a non-glassy stone can NEVER make a sharp edge.
    if (!materialIsKnappable(material)) {
      final bool soft = material == StoneMaterial.sandstone;
      return StrikeOutcome(
        result: StrikeResult.noFlake,
        signal: StrikeSignals.wrongMaterial,
        lesson: soft
            ? 'The soft stone just crumbled into dust — it can\'t hold an edge. '
                'You need a hard, glassy stone.'
            : 'That stone is hard but not glassy — it chips dully instead of '
                'flaking sharp. Pick a glassy stone like flint.',
        progressDelta: 0.0,
      );
    }

    // 2) FORCE (too weak) lesson — a soft tap bounces off, no flake.
    if (f < minForce) {
      return const StrikeOutcome(
        result: StrikeResult.noFlake,
        signal: StrikeSignals.tooWeak,
        lesson: 'Too gentle — the blow just bounced off. Strike harder to '
            'knock a flake loose.',
        progressDelta: 0.0,
      );
    }

    // Obsidian is brittle: its safe force ceiling is a little lower than flint's.
    final double forceCeiling =
        material == StoneMaterial.obsidian ? maxForce - 0.10 : maxForce;

    final double angleOff = (angleDeg - idealAngleDeg).abs();
    final bool angleGood = angleOff <= angleToleranceDeg;

    // 3) SHATTER lesson — too hard, or a steep (wrong) angle drives a crack right
    //    through the core instead of popping a clean flake.
    if (f > forceCeiling || !angleGood) {
      final bool tooHard = f > forceCeiling;
      return StrikeOutcome(
        result: StrikeResult.shatter,
        signal: StrikeSignals.shattered,
        lesson: tooHard
            ? 'Too hard! The stone shattered into useless bits. Ease off — a '
                'controlled blow flakes clean.'
            : 'Wrong angle — the crack split the stone instead of flaking the '
                'edge. Strike at a glancing angle, not straight on.',
        progressDelta: 0.0,
      );
    }

    // 4) CLEAN FLAKE — right material, right force, right angle. A precise hit
    //    near the ideal makes a bigger, cleaner flake.
    final double precision =
        (1.0 - (angleOff / angleToleranceDeg)).clamp(0.0, 1.0);
    // A flake worth 0.34..0.5 of the blade so ~2-3 good strikes finish it.
    final double delta = 0.34 + 0.16 * precision;
    return StrikeOutcome(
      result: StrikeResult.cleanFlake,
      signal: StrikeSignals.cleanFlake,
      lesson: precision > 0.7
          ? 'A clean, sharp flake — that\'s the perfect glancing blow!'
          : 'A good flake came off. Keep that angle and force.',
      progressDelta: delta,
    );
  }

  /// Convenience: the tool a finished blade becomes from the chosen [material]
  /// (and whether it was [fireTreated]). Obsidian makes the sharpest blade; flint
  /// makes a sturdy hand axe by default. Hafting bumps it to a [ToolType.spear].
  Tool toolFor(
    StoneMaterial material, {
    bool hafted = false,
    bool fireTreated = false,
    int tier = 1,
  }) {
    if (hafted) {
      return Tool(
        type: ToolType.spear,
        tier: tier,
        fireTreated: fireTreated,
      );
    }
    final ToolType type =
        material == StoneMaterial.obsidian ? ToolType.blade : ToolType.handAxe;
    return Tool(type: type, tier: tier, fireTreated: fireTreated);
  }
}
