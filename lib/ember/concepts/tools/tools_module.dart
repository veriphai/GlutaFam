// Ember — concepts/tools/tools_module.dart
//
// THE tools leaf's registry entry point. [ToolsConceptModule] implements the
// frozen [ConceptModule] contract and returns ALL of the stone-tools content the
// registry wires in WITHOUT touching any shared file:
//   * conceptDefinition  — the Stone Tools tech-tree node (prerequisite: Fire),
//   * knowledgeKeys      — every PlayerKnowledge / world flag the leaf may set,
//   * placeableDefs      — Knapping Station + Tool Rack,
//   * activities         — the Knapping activity paired with its scene builder,
//   * codexEntries       — the tools codex cards,
//   * modelUpgrades      — the lucky-stones -> material-fractures belief shift,
//   * gatherModifier     — the tool multiplier (the felt benefit),
//   * eventResolvers     — the stylized spear-hunt resolver.
//
// onInstall(ref): the gather modifier is consumed by the sim through TWO seams,
// and this leaf supplies BOTH the way the foundation actually reads them (verified
// against resource_system.dart + concept_registry.dart + seams.dart, not guessed):
//   1. SimRegistry.gatherModifier — ConceptRegistry COMPOSES every module's
//      `gatherModifier` getter; the sim's ResourceSystem reads
//      registry.gatherModifier in gather()/speedFor(). Returning our
//      [ToolGatherModifier] from the getter IS the sim-side seam.
//   2. seams.dart `toolMultiplierProvider` — a StateProvider<List<GatherModifier>>
//      the docs name as the tools push-seam; the UI-facing derived
//      `effectiveGatherModifierProvider` reads it back. We APPEND our modifier
//      here so the HUD/selectors reflect tools too. (This is the documented push;
//      unlike fire's light source — which is a read-only DERIVED provider with
//      nothing to push into — tools DO have an installable list to append to.)

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
import '../../state/seams.dart';
import 'hunt_resolver.dart';
import 'knapping_activity.dart';
import 'knapping_scene.dart';
import 'tool_gather_modifier.dart';
import 'tools_codex.dart';
import 'tools_knowledge.dart';
import 'tools_placeable_defs.dart';

/// The Stone Tools concept leaf.
class ToolsConceptModule implements ConceptModule {
  const ToolsConceptModule();

  /// The single gather modifier instance this leaf supplies to BOTH seams (the
  /// composed SimRegistry one and the pushed toolMultiplierProvider one) so the
  /// sim + the UI read the same felt benefit.
  static const ToolGatherModifier _modifier = ToolGatherModifier();

  @override
  Concept get conceptDefinition => const Concept(
        id: ConceptId.stoneTools,
        name: 'Stone Tools',
        // Tools need Fire first (heat-treating stone / fire-hardening the haft).
        prerequisites: <ConceptId>[ConceptId.fire],
        // Locked until Fire completes (cascade-unlocked by the reducer).
        unlocked: false,
        completed: false,
      );

  @override
  List<String> get knowledgeKeys => ToolsKnowledge.all;

  @override
  List<PlaceableDef> get placeableDefs => ToolsPlaceableDefs.all();

  @override
  List<ActivityRegistration> get activities => <ActivityRegistration>[
        ActivityRegistration(
          def: KnappingActivity.build(),
          scene: _buildKnappingScene,
        ),
      ];

  /// The [SceneBuilder] for Knapping. The scene resolves the drop site from the
  /// live world on load, so no extra context is needed here.
  static ActivityScene _buildKnappingScene(
    EmberActivity a,
    BeatController c,
  ) =>
      KnappingScene(a, c);

  @override
  List<CodexEntry> get codexEntries => ToolsCodex.all();

  @override
  List<ModelUpgrade> get modelUpgrades => <ModelUpgrade>[
        ToolsCodex.modelUpgrade(),
      ];

  /// The tool multiplier — composed into SimRegistry.gatherModifier and read by
  /// the sim's ResourceSystem. This is the core, felt benefit (PRD §7).
  @override
  GatherModifier? get gatherModifier => _modifier;

  @override
  List<EventResolver> get eventResolvers => const <EventResolver>[
        HuntResolver(),
      ];

  @override
  void onInstall(Ref ref) {
    // Push our gather modifier into the documented tools push-seam so the
    // UI-facing effectiveGatherModifierProvider reflects tools too. (The sim
    // reads the COMPOSED SimRegistry.gatherModifier via the getter above — this
    // append covers the read-only derived provider the HUD/selectors watch.)
    final StateController<List<GatherModifier>> controller =
        ref.read(toolMultiplierProvider.notifier);
    final List<GatherModifier> current = controller.state;
    if (!current.contains(_modifier)) {
      controller.state = <GatherModifier>[...current, _modifier];
    }
  }
}
