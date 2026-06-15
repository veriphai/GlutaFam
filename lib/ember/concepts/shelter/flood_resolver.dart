// Ember — concepts/shelter/flood_resolver.dart
//
// THE FLAGSHIP [EventResolver] for [WorldEventType.flood]. The river that gave the
// camp easy water + fish + fertile ground now rises — and it bites the shelters
// built too low / on flood-risk tiles. This is the §7 Pressure Template made real:
// good -> it bites -> discover coping -> upgrade & thrive, with the showpiece
// REFRAME (the river is not cursed; the flood is a predictable cycle you can plan
// around and even USE) seeded for the later Agriculture era.
//
// Damage model (PURE): for each active shelter, the water taken off its durability
// is EmberConstants.floodDamageFraction(floodRisk: tileRisk, severity: eventSev)
// SOFTENED by the dwelling's own floodResistance. A high-ground / high-resistance
// home shrugs it off; a low riverbank lean-to takes the hit. The dwelling's
// published housing capacity follows its durability (via [Dwelling.damaged]), so
// the population cap dips until the player rebuilds/relocates — the SITE lesson
// taught BY CONSEQUENCE, not by lecture.
//
// Child-safety (PRD §16): the flood is stylized + gentle. We damage STRUCTURES
// only, never show peril to characters, and the digest copy is encouraging (the
// fix, the cleverness — not fear). After it resolves we raise follow-up world
// flags so the host can surface the Elder's reframe + the "best soil next season"
// payoff that turns fear -> understanding -> mastery.
//
// DETERMINISM: offline-safe + reproducible. Any chance (a small per-tile jitter so
// repeated floods aren't identical) flows through the threaded [EmberRng], never
// DateTime/Random. Returns a NEW state with damaged dwellings + the reframe flags.

import '../../contracts/event_resolver.dart';
import '../../core/constants.dart';
import '../../core/ember_rng.dart';
import '../../core/enums.dart';
import '../../core/geometry.dart';
import '../../data/models/placeable.dart';
import '../../data/models/player_knowledge.dart';
import '../../data/models/world_event.dart';
import '../../data/models/world_state.dart';
import 'model/dwelling.dart';
import 'shelter_knowledge.dart';

/// Resolves the one flood: damages low/weak shelters, spares well-sited ones, and
/// lands the flood reframe + fertile-silt follow-up.
class FloodResolver implements EventResolver {
  const FloodResolver();

  /// Tiles at/above this risk count as "in the flood path" (the riverbank).
  static const double _floodPathRisk = 0.4;

  @override
  bool canResolve(WorldEventType type) => type == WorldEventType.flood;

  @override
  EventOutcome resolve(WorldEvent e, EmberWorldState s, EmberRng rng) {
    final double severity = e.severity; // 0..1 from the scheduler.

    final List<Placeable> nextPlaceables = <Placeable>[];
    final List<String> damagedIds = <String>[];
    int homesHeld = 0;
    int homesHit = 0;
    double comfortDelta = 0.0;
    double worstFloodTileRisk = 0.0;

    for (final Placeable p in s.placeables) {
      if (!_isShelter(p.type) || !p.isActive) {
        nextPlaceables.add(p);
        continue;
      }

      // The flood risk this dwelling actually sits in: the max over its own tile
      // and its 4-neighbours (a home one tile off the bank still gets wet feet).
      final double tileRisk = _siteFloodRisk(s, p.coord);
      if (tileRisk > worstFloodTileRisk) worstFloodTileRisk = tileRisk;

      final Dwelling dw = Dwelling.fromExt(p.type, p.ext);

      // Raw flood damage from the shared curve (sub-linear in risk).
      final double raw = EmberConstants.floodDamageFraction(
        floodRisk: tileRisk,
        severity: severity,
      );
      // The dwelling's own flood-resistance soaks up part of it; a small,
      // deterministic jitter keeps repeated floods from being identical.
      final double jitter = 0.85 + rng.nextDouble() * 0.30; // 0.85..1.15
      final double damage =
          (raw * (1.0 - dw.floodResistance) * jitter).clamp(0.0, 1.0);

      if (damage < 0.05 || tileRisk < _floodPathRisk) {
        // Well-sited / sturdy: it HELD. The player who chose high ground feels it.
        if (dw.housesAnyone) homesHeld++;
        nextPlaceables.add(p);
        continue;
      }

      // It took the hit. Lower durability + withdraw capacity proportionally.
      final Dwelling hit = dw.damaged(damage);
      final Placeable damagedPlaceable = p.copyWith(
        state: PlaceableState.damaged,
        ext: <String, dynamic>{...p.ext, ...hit.toExt()},
      );
      nextPlaceables.add(damagedPlaceable);
      damagedIds.add(p.id);
      if (dw.housesAnyone) homesHit++;
      // Comfort dips with how much shelter was lost (gentle, capped).
      comfortDelta -= 0.04 + 0.10 * damage;
    }

    // Raise the reframe + follow-up flags (offline-safe; the host surfaces the
    // Elder reframe on return). The fertile-silt payoff is set whenever the flood
    // actually touched flood-path ground — that ground becomes next season's best
    // soil (seeds the later irrigation/Agriculture beat: fear -> mastery).
    PlayerKnowledge k = s.knowledge
        .set(ShelterKnowledge.floodModelUpgraded)
        .set(ShelterKnowledge.floodAftermath);
    if (worstFloodTileRisk >= _floodPathRisk) {
      k = k.set(ShelterKnowledge.bestSoilNextSeason);
    }

    final EmberWorldState next = s.copyWith(
      placeables: nextPlaceables,
      knowledge: k,
    );

    final bool anyDamage = damagedIds.isNotEmpty;
    final String headline = anyDamage
        ? 'The river rose in the night and swept the low ground.'
        : 'The river rose — but your homes stood on safe ground.';
    final String detail = _detail(homesHeld, homesHit, anyDamage);

    return EventOutcome(
      state: next,
      type: WorldEventType.flood,
      headline: headline,
      detail: detail,
      severity: severity.clamp(0.0, 1.0),
      damagedPlaceableIds: damagedIds,
      comfortDelta: (comfortDelta).clamp(-1.0, 0.0),
      data: <String, dynamic>{
        'homesHeld': homesHeld,
        'homesHit': homesHit,
        'worstTileRisk': worstFloodTileRisk,
        // The reframe payload the host's Elder card reads.
        'reframe':
            'The river is not cursed. The flood comes in a cycle you can read — '
            'build on higher ground, and the same water that swept the low camp '
            'will lay rich soil for next season.',
        'bestSoilNextSeason': worstFloodTileRisk >= _floodPathRisk,
      },
    );
  }

  /// The flood risk a dwelling at [coord] is exposed to: the max over its own
  /// tile + 4-neighbours (so a home just off the bank still counts as low).
  double _siteFloodRisk(EmberWorldState s, GridCoord coord) {
    double risk = 0.0;
    for (final GridCoord c in <GridCoord>[coord, ...coord.neighbors4]) {
      final tile = s.tiles.at(c);
      if (tile != null && tile.floodRisk > risk) risk = tile.floodRisk;
    }
    return risk;
  }

  String _detail(int held, int hit, bool anyDamage) {
    if (!anyDamage) {
      return 'Every home was raised out of the flood path — the tribe woke dry '
          'and the morning brought rich, dark soil along the bank.';
    }
    final String heldPart = held > 0
        ? '$held ${held == 1 ? 'home on safe ground held' : 'homes on safe ground held'}; '
        : '';
    return '$heldPart$hit ${hit == 1 ? 'low home took on water' : 'low homes took on water'}. '
        'Move to higher ground or raise them on stilts — and the flooded bank '
        'will be the best soil you ever planted.';
  }

  bool _isShelter(PlaceableType t) =>
      t == PlaceableType.leanTo ||
      t == PlaceableType.hideTent ||
      t == PlaceableType.hut ||
      t == PlaceableType.palisade;
}
