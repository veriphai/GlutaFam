// Ember — registry/concept_registry.dart
//
// Collects a flat list of [ConceptModule]s into the read-only [SimRegistry] the
// simulation consumes. It is the ONLY thing that bridges the leaf contract
// ([ConceptModule], from contracts/) to the sim seam ([SimRegistry], from
// contracts/) — and it takes its modules as a plain `List<ConceptModule>`, so it
// NEVER imports a concept leaf itself. registry/ember_registry.dart (written
// last, in the final wiring stage) constructs the leaves and passes them here.
//
// Everything is precomputed in the constructor (def index, behavior index,
// composed gather modifier, flattened resolvers/activities/codex) so the per-tick
// lookups the sim makes are O(1)/cheap and PURE (no clock/random).

import '../contracts/codex_entry.dart';
import '../contracts/concept_module.dart';
import '../contracts/event_resolver.dart';
import '../contracts/gather_modifier.dart';
import '../contracts/placeable_behavior.dart';
import '../contracts/placeable_def.dart';
import '../contracts/sim_registry.dart';
import '../core/enums.dart';
import '../data/models/concept.dart';

/// The concrete [SimRegistry]: folds many [ConceptModule]s into one queryable
/// surface for the sim, plus the flattened content (defs, activities, codex,
/// concepts, knowledge keys) the state/registry/UI layers read.
class ConceptRegistry implements SimRegistry {
  /// Builds the registry from [modules] and precomputes all indices.
  ConceptRegistry(List<ConceptModule> modules)
      : modules = List<ConceptModule>.unmodifiable(modules),
        _defsByType = _indexDefs(modules),
        _resolvers = _flattenResolvers(modules),
        _gatherModifier = _composeGather(modules),
        placeableDefs = _flattenDefs(modules),
        activities = _flattenActivities(modules),
        codexEntries = _flattenCodex(modules),
        conceptDefinitions = _flattenConcepts(modules),
        knowledgeKeys = _flattenKnowledgeKeys(modules);

  /// The installed concept modules, in install order.
  final List<ConceptModule> modules;

  /// Every placeable def across all modules (build menu / catalogue).
  final List<PlaceableDef> placeableDefs;

  /// Every activity registration across all modules.
  final List<ActivityRegistration> activities;

  /// Every codex entry across all modules.
  final List<CodexEntry> codexEntries;

  /// Every concept definition across all modules (tech-tree seed).
  final List<Concept> conceptDefinitions;

  /// Every knowledge key declared by any module (validation / debug).
  final List<String> knowledgeKeys;

  final Map<PlaceableType, PlaceableDef> _defsByType;
  final List<EventResolver> _resolvers;
  final GatherModifier _gatherModifier;

  // ---- SimRegistry ------------------------------------------------------

  @override
  GatherModifier get gatherModifier => _gatherModifier;

  @override
  PlaceableBehavior? behaviorFor(PlaceableType type) =>
      _defsByType[type]?.behavior;

  @override
  List<EventResolver> resolversFor(WorldEventType type) => <EventResolver>[
        for (final EventResolver r in _resolvers)
          if (r.canResolve(type)) r,
      ];

  @override
  PlaceableDef? defFor(PlaceableType type) => _defsByType[type];

  // ---- Extra lookups the state/UI layers use ----------------------------

  /// The activity registration for activity [id], or null.
  ActivityRegistration? activityById(String id) {
    for (final ActivityRegistration a in activities) {
      if (a.def.id == id) return a;
    }
    return null;
  }

  /// The activity registration for the (single) activity of [conceptId], or null.
  ActivityRegistration? activityForConcept(ConceptId conceptId) {
    for (final ActivityRegistration a in activities) {
      if (a.def.conceptId == conceptId) return a;
    }
    return null;
  }

  /// The codex entry for [id], or null.
  CodexEntry? codexById(String id) {
    for (final CodexEntry e in codexEntries) {
      if (e.id == id) return e;
    }
    return null;
  }

  // ---- Precompute helpers (pure) ----------------------------------------

  static Map<PlaceableType, PlaceableDef> _indexDefs(
    List<ConceptModule> modules,
  ) {
    final Map<PlaceableType, PlaceableDef> out =
        <PlaceableType, PlaceableDef>{};
    for (final ConceptModule m in modules) {
      for (final PlaceableDef d in m.placeableDefs) {
        // Last writer wins; modules own disjoint placeable types by design, so
        // collisions only happen on a misconfiguration (then the later one wins
        // deterministically).
        out[d.kind] = d;
      }
    }
    return Map<PlaceableType, PlaceableDef>.unmodifiable(out);
  }

  static List<EventResolver> _flattenResolvers(List<ConceptModule> modules) {
    return List<EventResolver>.unmodifiable(<EventResolver>[
      for (final ConceptModule m in modules) ...m.eventResolvers,
    ]);
  }

  static GatherModifier _composeGather(List<ConceptModule> modules) {
    final List<GatherModifier> parts = <GatherModifier>[
      for (final ConceptModule m in modules)
        if (m.gatherModifier != null) m.gatherModifier!,
    ];
    if (parts.isEmpty) return const DefaultGatherModifier();
    if (parts.length == 1) return parts.first;
    return CompositeGatherModifier(parts);
  }

  static List<PlaceableDef> _flattenDefs(List<ConceptModule> modules) {
    return List<PlaceableDef>.unmodifiable(<PlaceableDef>[
      for (final ConceptModule m in modules) ...m.placeableDefs,
    ]);
  }

  static List<ActivityRegistration> _flattenActivities(
    List<ConceptModule> modules,
  ) {
    return List<ActivityRegistration>.unmodifiable(<ActivityRegistration>[
      for (final ConceptModule m in modules) ...m.activities,
    ]);
  }

  static List<CodexEntry> _flattenCodex(List<ConceptModule> modules) {
    return List<CodexEntry>.unmodifiable(<CodexEntry>[
      for (final ConceptModule m in modules) ...m.codexEntries,
    ]);
  }

  static List<Concept> _flattenConcepts(List<ConceptModule> modules) {
    return List<Concept>.unmodifiable(<Concept>[
      for (final ConceptModule m in modules) m.conceptDefinition,
    ]);
  }

  static List<String> _flattenKnowledgeKeys(List<ConceptModule> modules) {
    final Set<String> seen = <String>{};
    final List<String> out = <String>[];
    for (final ConceptModule m in modules) {
      for (final String k in m.knowledgeKeys) {
        if (seen.add(k)) out.add(k);
      }
    }
    return List<String>.unmodifiable(out);
  }
}
