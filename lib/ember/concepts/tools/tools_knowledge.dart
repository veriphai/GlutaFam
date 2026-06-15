// Ember — concepts/tools/tools_knowledge.dart
//
// The stone-tools leaf's PlayerKnowledge / WorldFlag key namespace, declared in
// one place so the activity's ApplyEffects, the codex model upgrade, and the
// module's knowledgeKeys list all agree on the exact strings. Keys are namespaced
// "tools.*" (knowledge) and "world.*" (world flags) by convention — mirroring the
// Fire leaf's PlayerKnowledge data-model (PRD §14).

class ToolsKnowledge {
  const ToolsKnowledge._();

  /// Set true once the player has knapped a blade and discovered toolmaking.
  static const String knappingDiscovered = 'tools.knappingDiscovered';

  /// Set true once the player chooses the right (glassy) stone unaided — the
  /// "materials matter" transfer (PRD §14 materialsUnderstood / §15 metric).
  static const String materialsUnderstood = 'tools.materialsUnderstood';

  /// Set true once the myth -> evidence model upgrade lands (matches the
  /// [ModelUpgrade.flag] for tools so the reducer + upgrade agree).
  static const String toolModelUpgraded = 'tools.modelUpgraded';

  /// World flag: the tribe now equips tools — gathering + hunting are multiplied.
  static const String toolsEquipped = 'world.toolsEquipped';

  /// World flag: hide processing is unlocked (feeds Shelter & clothing later).
  static const String hideProcessingUnlocked = 'world.hideProcessingUnlocked';

  /// Every knowledge / world flag key the tools leaf may set (for the module's
  /// knowledgeKeys contract + validation/debug).
  static const List<String> all = <String>[
    knappingDiscovered,
    materialsUnderstood,
    toolModelUpgraded,
    toolsEquipped,
    hideProcessingUnlocked,
  ];
}
