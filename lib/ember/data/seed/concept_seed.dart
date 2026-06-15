// Ember — data/seed/concept_seed.dart
//
// The concept dependency tree as data: fire -> stoneTools -> shelter. Fire is
// unlocked from the start; each subsequent concept unlocks once its prereqs are
// completed. Pure data; no clock/random. The reducer/sim flips unlocked/completed.

import '../../core/enums.dart';
import '../models/concept.dart';

class ConceptSeed {
  const ConceptSeed._();

  /// The initial tech-tree state for a brand-new game.
  ///
  /// Linear gating: fire (open) -> stoneTools (needs fire) -> shelter (needs
  /// stoneTools). Each concept starts not-completed; only fire starts unlocked.
  static List<Concept> initialConcepts() => <Concept>[
        const Concept(
          id: ConceptId.fire,
          name: 'Fire',
          prerequisites: <ConceptId>[],
          unlocked: true,
          completed: false,
        ),
        const Concept(
          id: ConceptId.stoneTools,
          name: 'Stone Tools',
          prerequisites: <ConceptId>[ConceptId.fire],
          unlocked: false,
          completed: false,
        ),
        const Concept(
          id: ConceptId.shelter,
          name: 'Shelter',
          prerequisites: <ConceptId>[ConceptId.stoneTools],
          unlocked: false,
          completed: false,
        ),
      ];

  /// Fresh per-concept progress rows (one per concept).
  static List<ActivityProgressSeed> get progressIds =>
      const <ActivityProgressSeed>[
        ActivityProgressSeed(ConceptId.fire),
        ActivityProgressSeed(ConceptId.stoneTools),
        ActivityProgressSeed(ConceptId.shelter),
      ];
}

/// Tiny marker pairing a concept with its (yet-empty) progress, so the world
/// seed can build matching ActivityProgress rows without importing the progress
/// model here (kept dependency-light).
class ActivityProgressSeed {
  const ActivityProgressSeed(this.conceptId);
  final ConceptId conceptId;
}
