// Ember — concepts/shelter/shelter_knowledge.dart
//
// The shelter leaf's PlayerKnowledge / WorldFlag key namespace, declared in one
// place so the activity's ApplyEffects, the codex model upgrades, the flood
// resolver's follow-up flag, and the module's knowledgeKeys list all agree on the
// exact strings. Keys are namespaced "shelter.*" (knowledge) and "world.*"
// (world flags) by convention.

class ShelterKnowledge {
  const ShelterKnowledge._();

  /// Set true once the player has raised a shelter and the build "clicked".
  static const String shelterDiscovered = 'shelter.discovered';

  /// Set true once the STRUCTURE lesson lands (the frame carries the load, the
  /// anchor keeps it standing). Matches the structure ModelUpgrade.flag.
  static const String structureUnderstood = 'shelter.structureUnderstood';

  /// Set true once the SITE lesson lands (build out of the flood path; high
  /// ground keeps you dry). Set in the activity on success.
  static const String siteUnderstood = 'shelter.siteUnderstood';

  /// THE big reframe: the flood is not a curse, it is a predictable cycle you
  /// can plan around (and even use). Matches the flood ModelUpgrade.flag and is
  /// also set by the FloodResolver once the flood has been lived through.
  static const String floodModelUpgraded = 'shelter.floodModelUpgraded';

  /// World flag: the camp now has permanent homes (it reads like a village).
  static const String villageHoused = 'world.villageHoused';

  /// World flag the FloodResolver raises after a flood so the world can surface
  /// the Elder's reframe + the "the flooded ground is your best soil next
  /// season" follow-up (seeds the later Agriculture era). Read by the host.
  static const String floodAftermath = 'world.floodAftermath';

  /// World flag: the silt the flood laid down makes next season's ground fertile
  /// (the showpiece payoff that turns fear -> mastery). Set by the FloodResolver.
  static const String bestSoilNextSeason = 'world.bestSoilNextSeason';

  /// Every knowledge / world flag key the shelter leaf may set (for the module's
  /// knowledgeKeys contract + validation/debug).
  static const List<String> all = <String>[
    shelterDiscovered,
    structureUnderstood,
    siteUnderstood,
    floodModelUpgraded,
    villageHoused,
    floodAftermath,
    bestSoilNextSeason,
  ];
}
