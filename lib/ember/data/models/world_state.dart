// Ember — data/models/world_state.dart
//
// THE SINGLE SOURCE OF TRUTH. A plain value aggregate with NO Flame/Flutter
// imports. Riverpod owns one of these; the Flame layer observes it; the sim
// transforms it. toJson <-> fromJson MUST round-trip byte-stable (every nested
// model sorts its maps/sets), so the Hive save is one deterministic document.

import '../../core/ember_rng.dart';
import 'activity_progress.dart';
import 'concept.dart';
import 'day_night_state.dart';
import 'era_state.dart';
import 'npc.dart';
import 'placeable.dart';
import 'player_knowledge.dart';
import 'resource_node.dart';
import 'resource_stock.dart';
import 'tile_grid.dart';
import 'village.dart';
import 'world_event.dart';

class EmberWorldState {
  EmberWorldState({
    required this.village,
    required this.tiles,
    required this.placeables,
    required this.nodes,
    required this.stock,
    required this.npcs,
    required this.concepts,
    required this.activityProgress,
    required this.era,
    required this.events,
    required this.knowledge,
    required this.dayNight,
    required this.rng,
    required this.simNowMs,
    required this.lastSeenMs,
  });

  final Village village;
  final TileGrid tiles;
  final List<Placeable> placeables;
  final List<ResourceNode> nodes;
  final ResourceStock stock;
  final List<Npc> npcs;
  final List<Concept> concepts;
  final List<ActivityProgress> activityProgress;
  final EraState era;
  final List<WorldEvent> events;
  final PlayerKnowledge knowledge;
  final DayNightState dayNight;

  /// Seeded RNG — the ONLY entropy source for the sim, serialized here.
  final EmberRng rng;

  /// Authoritative in-sim time (ms). Advanced by WorldSimulation, never by a
  /// real clock directly.
  int simNowMs;

  /// Wall-clock ms (from EmberClock) of the last time the player was present —
  /// used to compute the offline catch-up window.
  int lastSeenMs;

  // ---- Convenience lookups (pure) ----------------------------------------

  Placeable? placeableById(String id) {
    for (final Placeable p in placeables) {
      if (p.id == id) return p;
    }
    return null;
  }

  ResourceNode? nodeById(String id) {
    for (final ResourceNode n in nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  Npc? npcById(String id) {
    for (final Npc n in npcs) {
      if (n.id == id) return n;
    }
    return null;
  }

  Concept? conceptById(Object id) {
    for (final Concept c in concepts) {
      if (c.id == id) return c;
    }
    return null;
  }

  ActivityProgress? progressFor(Object conceptId) {
    for (final ActivityProgress a in activityProgress) {
      if (a.conceptId == conceptId) return a;
    }
    return null;
  }

  EmberWorldState copyWith({
    Village? village,
    TileGrid? tiles,
    List<Placeable>? placeables,
    List<ResourceNode>? nodes,
    ResourceStock? stock,
    List<Npc>? npcs,
    List<Concept>? concepts,
    List<ActivityProgress>? activityProgress,
    EraState? era,
    List<WorldEvent>? events,
    PlayerKnowledge? knowledge,
    DayNightState? dayNight,
    EmberRng? rng,
    int? simNowMs,
    int? lastSeenMs,
  }) {
    return EmberWorldState(
      village: village ?? this.village,
      tiles: tiles ?? this.tiles,
      placeables: placeables ?? this.placeables,
      nodes: nodes ?? this.nodes,
      stock: stock ?? this.stock,
      npcs: npcs ?? this.npcs,
      concepts: concepts ?? this.concepts,
      activityProgress: activityProgress ?? this.activityProgress,
      era: era ?? this.era,
      events: events ?? this.events,
      knowledge: knowledge ?? this.knowledge,
      dayNight: dayNight ?? this.dayNight,
      rng: rng ?? this.rng,
      simNowMs: simNowMs ?? this.simNowMs,
      lastSeenMs: lastSeenMs ?? this.lastSeenMs,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'village': village.toJson(),
        'tiles': tiles.toJson(),
        'placeables': <Map<String, dynamic>>[
          for (final Placeable p in placeables) p.toJson(),
        ],
        'nodes': <Map<String, dynamic>>[
          for (final ResourceNode n in nodes) n.toJson(),
        ],
        'stock': stock.toJson(),
        'npcs': <Map<String, dynamic>>[for (final Npc n in npcs) n.toJson()],
        'concepts': <Map<String, dynamic>>[
          for (final Concept c in concepts) c.toJson(),
        ],
        'activityProgress': <Map<String, dynamic>>[
          for (final ActivityProgress a in activityProgress) a.toJson(),
        ],
        'era': era.toJson(),
        'events': <Map<String, dynamic>>[
          for (final WorldEvent e in events) e.toJson(),
        ],
        'knowledge': knowledge.toJson(),
        'dayNight': dayNight.toJson(),
        'rng': rng.toJson(),
        'simNowMs': simNowMs,
        'lastSeenMs': lastSeenMs,
      };

  factory EmberWorldState.fromJson(Map<String, dynamic> j) => EmberWorldState(
        village: Village.fromJson(
            (j['village'] as Map).cast<String, dynamic>()),
        tiles: TileGrid.fromJson((j['tiles'] as Map).cast<String, dynamic>()),
        placeables: <Placeable>[
          for (final dynamic e in (j['placeables'] as List?) ?? const <dynamic>[])
            Placeable.fromJson((e as Map).cast<String, dynamic>()),
        ],
        nodes: <ResourceNode>[
          for (final dynamic e in (j['nodes'] as List?) ?? const <dynamic>[])
            ResourceNode.fromJson((e as Map).cast<String, dynamic>()),
        ],
        stock:
            ResourceStock.fromJson((j['stock'] as Map).cast<String, dynamic>()),
        npcs: <Npc>[
          for (final dynamic e in (j['npcs'] as List?) ?? const <dynamic>[])
            Npc.fromJson((e as Map).cast<String, dynamic>()),
        ],
        concepts: <Concept>[
          for (final dynamic e in (j['concepts'] as List?) ?? const <dynamic>[])
            Concept.fromJson((e as Map).cast<String, dynamic>()),
        ],
        activityProgress: <ActivityProgress>[
          for (final dynamic e
              in (j['activityProgress'] as List?) ?? const <dynamic>[])
            ActivityProgress.fromJson((e as Map).cast<String, dynamic>()),
        ],
        era: EraState.fromJson((j['era'] as Map).cast<String, dynamic>()),
        events: <WorldEvent>[
          for (final dynamic e in (j['events'] as List?) ?? const <dynamic>[])
            WorldEvent.fromJson((e as Map).cast<String, dynamic>()),
        ],
        knowledge: PlayerKnowledge.fromJson(
            (j['knowledge'] as Map).cast<String, dynamic>()),
        dayNight: DayNightState.fromJson(
            (j['dayNight'] as Map).cast<String, dynamic>()),
        rng: EmberRng.fromJson((j['rng'] as Map).cast<String, dynamic>()),
        simNowMs: (j['simNowMs'] as num?)?.toInt() ?? 0,
        lastSeenMs: (j['lastSeenMs'] as num?)?.toInt() ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      other is EmberWorldState &&
      other.village == village &&
      other.tiles == tiles &&
      _listEq(other.placeables, placeables) &&
      _listEq(other.nodes, nodes) &&
      other.stock == stock &&
      _listEq(other.npcs, npcs) &&
      _listEq(other.concepts, concepts) &&
      _listEq(other.activityProgress, activityProgress) &&
      other.era == era &&
      _listEq(other.events, events) &&
      other.knowledge == knowledge &&
      other.dayNight == dayNight &&
      other.rng == rng &&
      other.simNowMs == simNowMs &&
      other.lastSeenMs == lastSeenMs;

  @override
  int get hashCode => Object.hash(
        village,
        tiles,
        Object.hashAll(placeables),
        Object.hashAll(nodes),
        stock,
        Object.hashAll(npcs),
        Object.hashAll(concepts),
        Object.hashAll(activityProgress),
        era,
        Object.hashAll(events),
        knowledge,
        dayNight,
        rng,
        Object.hash(simNowMs, lastSeenMs),
      );
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
