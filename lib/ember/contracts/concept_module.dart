// Ember — contracts/concept_module.dart
//
// THE FREEZE POINT. ConceptModule is the single contract every concept leaf
// (fire / stone tools / shelter) implements. Once this file is frozen the three
// leaves can be built in parallel against it WITHOUT touching any shared file —
// each leaf returns its content (placeable defs, the activity + its scene, codex,
// model upgrade, event resolvers, an optional gather modifier) and publishes any
// cross-concept contribution in onInstall(ref). The registry (written last)
// collects the modules; nothing here imports a leaf.
//
// FROZEN DECISIONS encoded by this file:
//   * onInstall takes the LEGACY Riverpod `Ref` (flutter_riverpod ^2.x), handed
//     the bootstrap ProviderContainer-backed Ref — NOT a widget-tree WidgetRef.
//     This matches state/providers.dart, state/seams.dart and lifecycle_observer.
//   * SceneBuilder builds a leaf's [ActivityScene] from the [EmberActivity] +
//     [BeatController]. ActivityScene is a Flame World, so this is the one place
//     the leaf contract reaches into the activity-host layer.
//   * ActivityRegistration pairs the declarative [EmberActivity] def with its
//     [SceneBuilder] so the host can route + score it generically.
//
// Presentation note: importing the activity host (activity_scene/beat_controller)
// pulls flame in here. That is intentional — ConceptModule is the leaf contract,
// and leaves are full presentation modules. The pure data contract lives in
// activity/activity_contract.dart; this is the wiring contract on top of it.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../activity/activity_contract.dart';
import '../activity/activity_scene.dart';
import '../activity/beat_controller.dart';
import '../data/models/concept.dart';
import 'codex_entry.dart';
import 'event_resolver.dart';
import 'gather_modifier.dart';
import 'placeable_def.dart';

/// Builds a leaf's [ActivityScene] for one play of [a], driven by [c]. The host
/// calls this once it has resolved prerequisites + created the [BeatController].
typedef SceneBuilder = ActivityScene Function(EmberActivity a, BeatController c);

/// Pairs a declarative [EmberActivity] with the [SceneBuilder] that renders +
/// drives its interact beat. A leaf returns one (or more) of these from
/// [ConceptModule.activities]; the registry flattens them and the
/// ActivityHost resolves an id to one of these to launch.
class ActivityRegistration {
  const ActivityRegistration({required this.def, required this.scene});

  /// The pure, declarative activity definition (copy / rules / unlocks).
  final EmberActivity def;

  /// The builder for this activity's Flame scene.
  final SceneBuilder scene;
}

/// THE leaf contract. A concept leaf implements this once and the registry wires
/// it in. Default-method members let a leaf opt out of seams it does not use
/// (e.g. a concept with no gather modifier returns null).
abstract interface class ConceptModule {
  /// The tech-tree node this concept defines (id / name / prerequisites). The
  /// registry seeds the concept list from these.
  Concept get conceptDefinition;

  /// Every PlayerKnowledge flag key this concept may set (for validation/debug).
  List<String> get knowledgeKeys;

  /// The static catalogue entries for every placeable type this concept owns.
  List<PlaceableDef> get placeableDefs;

  /// The activity registration(s) this concept ships (def + scene builder).
  List<ActivityRegistration> get activities;

  /// The codex / knowledge-card entries this concept contributes.
  List<CodexEntry> get codexEntries;

  /// The myth -> evidence model upgrade(s) this concept lands.
  List<ModelUpgrade> get modelUpgrades;

  /// An optional gather modifier this concept pushes (tools speed gathering).
  /// Null means this concept does not affect gathering (default x1.0 composes).
  GatherModifier? get gatherModifier;

  /// The event resolvers this concept provides (the flagship flood lives in the
  /// shelter leaf; others may add predator/storm/cold handlers).
  List<EventResolver> get eventResolvers;

  /// Called ONCE at bootstrap with the root [ref] (the ProviderContainer-backed
  /// Ref the game also runs against). A leaf PUSHES cross-concept contributions
  /// here — e.g. tools append their GatherModifier to [toolMultiplierProvider],
  /// shelter appends a PopulationCapSource. Default = no-op so a leaf that needs
  /// no push can omit it.
  void onInstall(Ref ref) {}
}
