// Ember — sim/systems/pressure_system.dart
//
// The PRESSURE TEMPLATE: the sim's tension director. It SCHEDULES WorldEvents (it
// does not resolve them — that's the event system + leaf resolvers). Two pressures:
//
//   * nightPredator — when night falls and the village has UNLIT EDGES (perimeter
//     tiles fire doesn't cover), roll predatorBaseChance (scaled by how exposed the
//     edges are) to schedule a predator strike that same night.
//   * flood (the ONE flood) — once the player has BUILT SHELTER near WATER and the
//     game is past floodEarliestMs, schedule a single flood. A world flag ensures
//     it is scheduled at most once.
//   * hunt — once STONE TOOLS is learned, roll huntBaseChance once per DAY (during
//     daylight) to send the tribe out on a stylized spear hunt. The tools leaf's
//     HuntResolver decides the payoff (a spear brings home food + hide; without one
//     the hunt comes up short). A per-day world flag ensures one roll per day.
//
// All chance flows through the world EmberRng (reproducible). No clock/random.

import '../../core/constants.dart';
import '../../core/ember_rng.dart';
import '../../core/enums.dart';
import '../../core/geometry.dart';
import '../../core/ids.dart';
import '../../data/models/concept.dart';
import '../../data/models/placeable.dart';
import '../../data/models/world_event.dart';
import '../../data/models/world_state.dart';
import 'fire_coverage.dart';

class PressureSystem {
  const PressureSystem();

  /// World flag (in PlayerKnowledge) marking the one flood as already scheduled.
  static const String kFloodScheduledFlag = 'world.flood_scheduled';

  /// World flag marking that a predator is already scheduled for the current day.
  static const String kPredatorDayFlagPrefix = 'world.predator_day.';

  /// World flag marking that the hunt roll has already happened for the current day.
  static const String kHuntDayFlagPrefix = 'world.hunt_day.';

  /// Lead time (ms) between scheduling a predator and it striking (mid-night).
  static const int _predatorLeadMs = 5000;

  /// Lead time (ms) between scheduling the flood and it hitting.
  static const int _floodLeadMs = 8000;

  /// Lead time (ms) between sending the tribe out and the hunt returning.
  static const int _huntLeadMs = 6000;

  /// Runs the scheduler against [s], returning a new state with any newly-queued
  /// events appended. [coverage] is this tick's fire coverage.
  EmberWorldState schedule(EmberWorldState s, FireCoverage coverage, EmberRng rng) {
    EmberWorldState out = s;
    out = _maybeSchedulePredator(out, coverage, rng);
    out = _maybeScheduleFlood(out, rng);
    out = _maybeScheduleHunt(out, rng);
    return out;
  }

  // ---- Predator pressure -------------------------------------------------

  EmberWorldState _maybeSchedulePredator(
    EmberWorldState s,
    FireCoverage coverage,
    EmberRng rng,
  ) {
    if (!s.dayNight.isNight) return s;

    final String dayFlag = '$kPredatorDayFlagPrefix${s.dayNight.dayCount}';
    if (s.knowledge.get(dayFlag)) return s; // already rolled this night.

    // Find unlit perimeter tiles around the village site.
    final List<GridCoord> exposed = _unlitEdges(s, coverage);
    if (exposed.isEmpty) {
      // Fully lit perimeter — no predator, but mark the night rolled.
      return s.copyWith(knowledge: s.knowledge.set(dayFlag));
    }

    // Exposure scales the base chance (more dark edges => more likely).
    final double exposure = (exposed.length / _perimeterCount(s)).clamp(0.0, 1.0);
    final double seasonMul =
        EmberConstants.coldSeasonMultiplier(s.dayNight.season).clamp(0.0, 2.0);
    final double chance =
        (EmberConstants.predatorBaseChance * (0.5 + exposure) * (0.5 + seasonMul * 0.25))
            .clamp(0.0, 0.95);

    final EmberWorldState marked = s.copyWith(knowledge: s.knowledge.set(dayFlag));
    if (!rng.chance(chance)) return marked;

    final double severity = rng.nextDouble();
    // Target a random exposed edge tile.
    final GridCoord target = exposed[rng.nextInt(exposed.length)];
    final WorldEvent ev = WorldEvent(
      id: ids.mint('event-predator', rng),
      type: WorldEventType.nightPredator,
      scheduledForMs: s.simNowMs + _predatorLeadMs,
      payload: <String, dynamic>{
        'severity': severity,
        'targetX': target.x,
        'targetY': target.y,
        'exposedEdges': exposed.length,
      },
    );
    return marked.copyWith(events: <WorldEvent>[...marked.events, ev]);
  }

  /// Perimeter tiles of the buildable region around the village that have NO fire
  /// warmth coverage.
  List<GridCoord> _unlitEdges(EmberWorldState s, FireCoverage coverage) {
    final GridCoord site = s.village.siteTile;
    const int ring = 4; // how far out the "edge" perimeter sits.
    final List<GridCoord> edges = <GridCoord>[];
    for (int dx = -ring; dx <= ring; dx++) {
      for (final int dy in <int>[-ring, ring]) {
        edges.add(site.translate(dx, dy));
      }
    }
    for (int dy = -ring + 1; dy <= ring - 1; dy++) {
      for (final int dx in <int>[-ring, ring]) {
        edges.add(site.translate(dx, dy));
      }
    }
    return <GridCoord>[
      for (final GridCoord c in edges)
        if (s.tiles.inBounds(c) && !coverage.isWarm(c)) c,
    ];
  }

  int _perimeterCount(EmberWorldState s) {
    const int ring = 4;
    // 8*ring tiles on the square perimeter.
    return 8 * ring;
  }

  // ---- Hunt pressure (tools leaf) ----------------------------------------

  /// Once Stone Tools is learned, roll a stylized spear hunt once per DAY (during
  /// daylight). The tools leaf's HuntResolver owns the payoff. Keying this here
  /// keeps the pressure director the single source of scheduled events; the leaf
  /// stays a pure resolver. Deterministic: the roll uses the world rng.
  EmberWorldState _maybeScheduleHunt(EmberWorldState s, EmberRng rng) {
    // Hunting only makes sense after the tribe learns to make tools.
    final Concept? tools = s.conceptById(ConceptId.stoneTools);
    if (tools == null || !tools.completed) return s;

    // One roll per day, during daylight (the tribe sets out in the morning).
    if (s.dayNight.isNight) return s;

    final String dayFlag = '$kHuntDayFlagPrefix${s.dayNight.dayCount}';
    if (s.knowledge.get(dayFlag)) return s; // already rolled this day.

    final EmberWorldState marked = s.copyWith(knowledge: s.knowledge.set(dayFlag));
    if (!rng.chance(EmberConstants.huntBaseChance)) return marked;

    final WorldEvent hunt = WorldEvent(
      id: ids.mint('event-hunt', rng),
      type: WorldEventType.hunt,
      scheduledForMs: s.simNowMs + _huntLeadMs,
      payload: <String, dynamic>{
        'day': s.dayNight.dayCount,
      },
    );
    return marked.copyWith(events: <WorldEvent>[...marked.events, hunt]);
  }

  // ---- Flood pressure (the ONE flood) ------------------------------------

  EmberWorldState _maybeScheduleFlood(EmberWorldState s, EmberRng rng) {
    if (s.knowledge.get(kFloodScheduledFlag)) return s; // only ever once.
    if (s.simNowMs < EmberConstants.floodEarliestMs) return s;

    // Conditions: a built dwelling/shelter exists AND something is near water.
    if (!_hasShelterNearWater(s)) return s;

    final double seasonMul =
        EmberConstants.floodSeasonMultiplier(s.dayNight.season).clamp(0.0, 2.0);
    final double severity = (0.5 + rng.nextDouble() * 0.5 * seasonMul).clamp(0.0, 1.0);

    final WorldEvent flood = WorldEvent(
      id: ids.mint('event-flood', rng),
      type: WorldEventType.flood,
      scheduledForMs: s.simNowMs + _floodLeadMs,
      payload: <String, dynamic>{
        'severity': severity,
        'season': s.dayNight.season.name,
      },
    );
    return s.copyWith(
      events: <WorldEvent>[...s.events, flood],
      knowledge: s.knowledge.set(kFloodScheduledFlag),
    );
  }

  /// True iff a built shelter-type placeable sits adjacent to (or on) a flood-risk
  /// tile (riverbank). We treat any tile with floodRisk >= 0.4 as "near water".
  bool _hasShelterNearWater(EmberWorldState s) {
    bool anyShelter = false;
    bool nearWater = false;
    for (final Placeable p in s.placeables) {
      if (!p.isActive) continue;
      if (_isShelter(p.type)) {
        anyShelter = true;
        // Check the placeable's own tile + 4-neighbours for flood risk.
        for (final GridCoord c in <GridCoord>[p.coord, ...p.coord.neighbors4]) {
          final tile = s.tiles.at(c);
          if (tile != null && tile.floodRisk >= 0.4) {
            nearWater = true;
            break;
          }
        }
      }
      if (anyShelter && nearWater) return true;
    }
    return anyShelter && nearWater;
  }

  bool _isShelter(PlaceableType t) =>
      t == PlaceableType.leanTo ||
      t == PlaceableType.hideTent ||
      t == PlaceableType.hut ||
      t == PlaceableType.palisade;
}
