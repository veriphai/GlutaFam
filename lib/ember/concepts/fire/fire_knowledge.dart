// Ember — concepts/fire/fire_knowledge.dart
//
// The fire leaf's PlayerKnowledge / WorldFlag key namespace, declared in one
// place so the activity's ApplyEffects, the codex model upgrade, and the module's
// knowledgeKeys list all agree on the exact strings. Keys are namespaced "fire.*"
// (knowledge) and "world.*" (world flags) by convention.

class FireKnowledge {
  const FireKnowledge._();

  /// Set true once the player has made fire and the triangle "clicked".
  static const String fireTriangleUnderstood = 'fire.triangleUnderstood';

  /// Set true once fire has been discovered at all (the activity completed).
  static const String fireDiscovered = 'fire.discovered';

  /// Set true once the myth -> evidence model upgrade lands (matches the
  /// [ModelUpgrade.flag] for fire so the reducer + upgrade agree).
  static const String fireModelUpgraded = 'fire.modelUpgraded';

  /// World flag: night is now survivable (a hearth lights + warms the camp).
  static const String nightSurvivable = 'world.nightSurvivable';

  /// Every knowledge / world flag key the fire leaf may set (for the module's
  /// knowledgeKeys contract + validation/debug).
  static const List<String> all = <String>[
    fireTriangleUnderstood,
    fireDiscovered,
    fireModelUpgraded,
    nightSurvivable,
  ];
}
