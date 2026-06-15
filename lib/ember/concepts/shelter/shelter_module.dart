// Ember — concepts/shelter/shelter_module.dart
//
// THE shelter leaf's registry entry point. [ShelterConceptModule] implements the
// frozen [ConceptModule] contract and returns ALL of the shelter content the
// registry wires in WITHOUT touching any shared file:
//   * conceptDefinition  — the Shelter tech-tree node, gated behind Fire + Stone
//     Tools (ConceptCompleted prerequisites),
//   * knowledgeKeys      — every PlayerKnowledge / world flag the leaf may set,
//   * placeableDefs      — Lean-to / Hide tent / Hut / Palisade,
//   * activities         — the Raise a Shelter activity paired with its scene
//     builder,
//   * codexEntries       — the shelter codex cards,
//   * modelUpgrades      — TWO belief shifts: STRUCTURE (frame carries load) +
//     the FLOOD reframe (the river is cursed -> a predictable cycle),
//   * gatherModifier     — null (shelter does not affect gathering),
//   * eventResolvers     — the FLAGSHIP [FloodResolver] for WorldEventType.flood.
//
// onInstall(ref): INTENTIONAL NO-OP (see population_source.dart for the precise
// reasoning). Shelter's cross-concept output — housing CAPACITY — is published into
// the generic Placeable.ext bag by [DwellingBehavior] under the FROZEN foundation
// key kDwellingCapacityExtKey and SUMMED by the foundation's PopulationSystem onto
// the village cap (exactly the read-back path Fire uses for LightSource). Pushing a
// PopulationCapSource as well would DOUBLE-COUNT against `populationCapProvider`, so
// install pushes nothing. This is correct, not a gap.

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
import 'flood_resolver.dart';
import 'raise_shelter_activity.dart';
import 'raise_shelter_scene.dart';
import 'shelter_codex.dart';
import 'shelter_knowledge.dart';
import 'shelter_placeable_defs.dart';

/// The Shelter concept leaf.
class ShelterConceptModule implements ConceptModule {
  const ShelterConceptModule();

  @override
  Concept get conceptDefinition => const Concept(
        id: ConceptId.shelter,
        name: 'Shelter',
        // Per the tech tree: needs Fire (indoor hearth warmth) + Stone Tools (to
        // cut wood + process hides). Unlocks via the reducer's cascade once both
        // are completed.
        prerequisites: <ConceptId>[ConceptId.fire, ConceptId.stoneTools],
        unlocked: false,
        completed: false,
      );

  @override
  List<String> get knowledgeKeys => ShelterKnowledge.all;

  @override
  List<PlaceableDef> get placeableDefs => ShelterPlaceableDefs.all();

  @override
  List<ActivityRegistration> get activities => <ActivityRegistration>[
        ActivityRegistration(
          def: RaiseShelterActivity.build(),
          scene: _buildRaiseShelterScene,
        ),
      ];

  /// The [SceneBuilder] for Raise a Shelter. The scene resolves its site options
  /// from the live world on load, so no extra context is needed here.
  static ActivityScene _buildRaiseShelterScene(
    EmberActivity a,
    BeatController c,
  ) =>
      RaiseShelterScene(a, c);

  @override
  List<CodexEntry> get codexEntries => ShelterCodex.all();

  @override
  List<ModelUpgrade> get modelUpgrades => <ModelUpgrade>[
        // 1) STRUCTURE — landed by the Raise a Shelter activity.
        ShelterCodex.structureUpgrade(),
        // 2) FLOOD reframe — landed when the flagship flood is lived through.
        ShelterCodex.floodUpgrade(),
      ];

  /// Shelter does not modify gathering.
  @override
  GatherModifier? get gatherModifier => null;

  @override
  List<EventResolver> get eventResolvers => const <EventResolver>[
        FloodResolver(),
      ];

  @override
  void onInstall(Ref ref) {
    // Intentional no-op: housing capacity is published into Placeable.ext under
    // the frozen kDwellingCapacityExtKey by DwellingBehavior and summed by the
    // foundation's PopulationSystem (the read-back path, like Fire's LightSource).
    // Pushing a PopulationCapSource here would double-count via
    // populationCapProvider. See population_source.dart for the full reasoning.
  }
}
