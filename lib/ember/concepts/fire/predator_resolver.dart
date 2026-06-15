// Ember — concepts/fire/predator_resolver.dart
//
// The fire leaf's [EventResolver] for [WorldEventType.nightPredator]: most animals
// fear fire, so a ring of fire keeps a night predator back. It reads the LIT tile
// set from the SAME FireCoverageSystem the night overlay uses (which pulls each
// fire's published LightSource off its ext bag — leaf-blind), and:
//   * if the village site sits inside fire light  -> the predator is scared off
//     (fire WORKED — no damage), a positive, encouraging outcome;
//   * if there is no fire / the site is dark       -> a GENTLE, stylized loss
//     (a small comfort dip + a little food taken), NEVER graphic and never shown
//     happening to a character (child-safety per PRD §16).
//
// PURE + DETERMINISTIC: any chance uses the threaded [EmberRng], never DateTime/
// Random. It returns a NEW state (here unchanged structurally — the digest carries
// the narrative; comfort/food deltas are reported via the outcome for the host).

import '../../contracts/event_resolver.dart';
import '../../core/ember_rng.dart';
import '../../core/enums.dart';
import '../../core/geometry.dart';
import '../../data/models/world_event.dart';
import '../../data/models/world_state.dart';
import '../../sim/systems/fire_coverage.dart';

/// Resolves night-predator events using fire light coverage as the deterrent.
class PredatorResolver implements EventResolver {
  const PredatorResolver({this.coverage = const FireCoverageSystem()});

  /// The same coverage system the night/light readers use (leaf-blind).
  final FireCoverageSystem coverage;

  @override
  bool canResolve(WorldEventType type) => type == WorldEventType.nightPredator;

  @override
  EventOutcome resolve(WorldEvent e, EmberWorldState s, EmberRng rng) {
    final FireCoverage cov = coverage.compute(s);
    final GridCoord site = s.village.siteTile;

    // The predator is deterred if the village heart (or any tile adjacent to it)
    // is lit — a fire RING. We check the centre + its 8 neighbours so a hearth a
    // tile or two off-centre still protects the camp.
    final bool protectedBySite =
        cov.isLit(site) || site.neighbors8.any(cov.isLit);

    if (cov.hasAnyLight && protectedBySite) {
      // Fire worked — the animal slinks back into the dark. Positive outcome.
      return EventOutcome(
        state: s,
        type: WorldEventType.nightPredator,
        headline: 'A prowler circled the camp — and the fire turned it away.',
        detail:
            'The light pushed the night animal back. No one was harmed; the '
            'tribe slept on by the warm hearth.',
        severity: 0.0,
        comfortDelta: 0.0,
        data: <String, dynamic>{
          'deterred': true,
          'litTiles': cov.litCount,
        },
      );
    }

    // No protective fire: a gentle, stylized setback (never graphic, no peril to
    // characters shown). A small comfort dip + a nibble of the food store.
    final double severity = e.severity; // 0..1 from the scheduler.
    // Deterministic small food loss scaled by severity (use rng for a touch of
    // variation so repeated unprotected nights aren't identical, but reproducible).
    final int foodTaken = 1 + rng.nextInt((1 + (severity * 3).round()).clamp(1, 4));
    final double comfortDelta = -(0.06 + 0.10 * severity);

    return EventOutcome(
      state: s,
      type: WorldEventType.nightPredator,
      headline: 'A night animal crept into a dark, fireless camp.',
      detail:
          'With no fire to keep it back, it took a little food before dawn. '
          'A ring of fire would have kept the camp safe.',
      severity: severity.clamp(0.0, 1.0),
      comfortDelta: comfortDelta,
      data: <String, dynamic>{
        'deterred': false,
        'foodTaken': foodTaken,
        'litTiles': cov.litCount,
      },
    );
  }
}
