// Ember — sim/systems/npc_system.dart
//
// Drives NPC mood + worker animation + visitor arrivals. Mood is a pure function
// of (warm? sheltered? fed? night?); workers assigned to a node show the `work`
// anim while it has resources; visitors may arrive (rng chance) when comfort is
// high. The ONLY randomness is the world EmberRng (visitor roll), so the result is
// reproducible live/offline/tests. No clock — "night" comes from DayNightState.

import '../../core/ember_rng.dart';
import '../../core/enums.dart';
import '../../core/geometry.dart';
import '../../core/ids.dart';
import '../../data/models/npc.dart';
import '../../data/models/resource_node.dart';
import '../../data/models/world_state.dart';
import 'fire_coverage.dart';

class NpcSystem {
  const NpcSystem();

  /// Per-tick chance a visitor arrives when the village is comfortable + at cap
  /// headroom. Scaled by dt so cadence is frame-rate independent at the sim step.
  static const double _visitorChancePerSec = 0.002;

  /// Recomputes mood + anim for every NPC and rolls for visitor arrivals.
  EmberWorldState advance(EmberWorldState s, double dtSeconds, EmberRng rng) {
    final bool night = s.dayNight.isNight;

    final List<Npc> next = <Npc>[
      for (final Npc n in s.npcs) _updateNpc(n, s, night),
    ];

    EmberWorldState out = s.copyWith(npcs: next);
    out = _maybeArriveVisitor(out, dtSeconds, rng);
    return out;
  }

  Npc _updateNpc(Npc n, EmberWorldState s, bool night) {
    // Coverage is recomputed locally so this system stays self-contained.
    final FireCoverage cov = const FireCoverageSystem().compute(s);
    final bool warm = cov.isWarm(n.coord);
    final bool fed =
        s.stock.amountOf(ResourceType.food) > s.stock.lineOf(ResourceType.food).threshold;

    // Worker animation: an assigned NPC whose node still has resources is working.
    AnimState anim = n.state;
    if (n.isAssigned) {
      final ResourceNode? node = s.nodeById(n.assignedNodeId!);
      anim = (node != null && !node.isDepleted) ? AnimState.work : AnimState.idle;
    } else if (night) {
      anim = AnimState.idle;
    }

    final NpcMood mood = _moodFor(night: night, warm: warm, fed: fed);
    if (mood == n.mood && anim == n.state) return n;
    return n.copyWith(mood: mood, state: anim);
  }

  NpcMood _moodFor({
    required bool night,
    required bool warm,
    required bool fed,
  }) {
    if (night && !warm) return NpcMood.cold;
    if (!fed) return NpcMood.uneasy;
    if (warm && fed) return NpcMood.happy;
    return NpcMood.content;
  }

  /// Assigns an NPC to a resource node (returns new state). Used by the
  /// controller's AssignNpc intent; pure.
  EmberWorldState assign(EmberWorldState s, EntityId npcId, EntityId nodeId) {
    final List<Npc> next = <Npc>[
      for (final Npc n in s.npcs)
        n.id == npcId ? n.copyWith(assignedNodeId: nodeId) : n,
    ];
    return s.copyWith(npcs: next);
  }

  /// Clears an NPC's node assignment.
  EmberWorldState unassign(EmberWorldState s, EntityId npcId) {
    final List<Npc> next = <Npc>[
      for (final Npc n in s.npcs)
        n.id == npcId ? n.copyWith(clearAssignment: true) : n,
    ];
    return s.copyWith(npcs: next);
  }

  EmberWorldState _maybeArriveVisitor(
    EmberWorldState s,
    double dtSeconds,
    EmberRng rng,
  ) {
    // Only welcome visitors when comfortable and there's room under the cap.
    final bool comfortable = s.village.comfortIndex >= 0.6;
    final bool hasRoom = s.npcs.length < s.village.populationCap;
    if (!comfortable || !hasRoom) return s;

    final double p = (_visitorChancePerSec * dtSeconds).clamp(0.0, 1.0);
    if (!rng.chance(p)) return s;

    // Spawn a visitor near the village site.
    final GridCoord site = s.village.siteTile;
    final GridCoord visitorCoord =
        site.translate(rng.nextRange(-2, 2), rng.nextRange(-2, 2));
    final EntityId id = ids.mint('npc-visitor', rng);
    final Npc visitor = Npc(
      id: id,
      role: NpcRole.visitor,
      coord: visitorCoord,
      mood: NpcMood.content,
      name: 'Visitor',
    );
    return s.copyWith(npcs: <Npc>[...s.npcs, visitor]);
  }
}
