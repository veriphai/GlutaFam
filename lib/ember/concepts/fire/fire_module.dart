// Ember — concepts/fire/fire_module.dart
//
// THE fire leaf's registry entry point. [FireConceptModule] implements the frozen
// [ConceptModule] contract and returns ALL of the fire content the registry wires
// in WITHOUT touching any shared file:
//   * conceptDefinition  — the Fire tech-tree node (starting concept, no prereqs),
//   * knowledgeKeys      — every PlayerKnowledge / world flag the leaf may set,
//   * placeableDefs      — Hearth / Torch / Brazier / Cooking fire,
//   * activities         — the Make Fire activity paired with its scene builder,
//   * codexEntries       — the fire codex cards,
//   * modelUpgrades      — the myth -> evidence belief shift,
//   * gatherModifier     — null (fire does not affect gathering),
//   * eventResolvers     — the night-predator resolver (fire deters predators).
//
// onInstall(ref): the fire leaf has NO installable push-seam contribution. Its
// cross-concept output — the LightSource each fire emits — is published into the
// generic Placeable.ext bag by [FireBehavior] (under the shared kLightSourcesExtKey)
// and READ by the foundation's derived [lightSourcesProvider] / FireCoverageSystem.
// That derived provider is read-only (computed from world state), so there is
// nothing to append at install time; install is intentionally a no-op. (See the
// blockedOn note in the build report for why this is correct, not a gap.)

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activity/activity_contract.dart';
import '../../activity/activity_scene.dart';
import '../../activity/beat_controller.dart';
import '../../contracts/codex_entry.dart';
import '../../contracts/concept_module.dart';
import '../../contracts/event_resolver.dart';
import '../../contracts/gather_modifier.dart';
import '../../contracts/placeable_def.dart';
import '../../core/enums.dart';
import '../../data/models/concept.dart';
import 'fire_codex.dart';
import 'fire_knowledge.dart';
import 'fire_placeable_defs.dart';
import 'make_fire_activity.dart';
import 'make_fire_scene.dart';
import 'predator_resolver.dart';

/// The Fire concept leaf.
class FireConceptModule implements ConceptModule {
  const FireConceptModule();

  @override
  Concept get conceptDefinition => const Concept(
        id: ConceptId.fire,
        name: 'Fire',
        // The keystone discovery — no prerequisites.
        prerequisites: <ConceptId>[],
        // Fire is the starting concept: unlocked from the first night.
        unlocked: true,
        completed: false,
      );

  @override
  List<String> get knowledgeKeys => FireKnowledge.all;

  @override
  List<PlaceableDef> get placeableDefs => FirePlaceableDefs.all();

  @override
  List<ActivityRegistration> get activities => <ActivityRegistration>[
        ActivityRegistration(
          def: MakeFireActivity.build(),
          scene: _buildMakeFireScene,
        ),
      ];

  /// The [SceneBuilder] for Make Fire. The scene resolves the village site tile
  /// from the live world on load, so no extra context is needed here.
  static ActivityScene _buildMakeFireScene(
    EmberActivity a,
    BeatController c,
  ) =>
      MakeFireScene(a, c);

  @override
  List<CodexEntry> get codexEntries => FireCodex.all();

  @override
  List<ModelUpgrade> get modelUpgrades => <ModelUpgrade>[
        FireCodex.modelUpgrade(),
      ];

  /// Fire does not modify gathering.
  @override
  GatherModifier? get gatherModifier => null;

  @override
  List<EventResolver> get eventResolvers => const <EventResolver>[
        PredatorResolver(),
      ];

  @override
  void onInstall(Ref ref) {
    // No installable push-seam contribution: each fire's LightSource is published
    // into the generic Placeable.ext bag by FireBehavior and read back by the
    // foundation's derived lightSourcesProvider / FireCoverageSystem. Nothing to
    // append here. (lightSourcesProvider is a read-only derived Provider, not a
    // StateProvider list, so there is nothing to push into at install time.)
  }
}
