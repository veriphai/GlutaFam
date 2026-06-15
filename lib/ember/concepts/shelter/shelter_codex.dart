// Ember — concepts/shelter/shelter_codex.dart
//
// The discoverable knowledge cards for shelter (discovery story / science /
// history) plus the TWO myth -> evidence model upgrades the Raise a Shelter
// activity + the flood land:
//   1. STRUCTURE — "a shelter just needs walls" -> "a FRAME carries the load and
//      the ANCHOR keeps it standing in the wind" (a first, gentle intro to load &
//      support the arch pays off in a later era).
//   2. SITE / FLOOD (the showpiece reframe) — "the river is cursed by angry
//      spirits" -> "the flood is a predictable CYCLE you can plan around and even
//      use" (seeds the later Egypt/irrigation beat: fear -> understanding ->
//      mastery).
//
// Pure value objects the registry collects and the reducer grants/applies. Copy is
// written for a 7-14 audience: accessible, never falsely precise about prehistory
// dates, and child-safe (the flood is preparation + cleverness, never fear).

import '../../contracts/codex_entry.dart';
import '../../core/enums.dart';
import 'shelter_knowledge.dart';

/// The shelter leaf's codex content + model upgrades.
class ShelterCodex {
  const ShelterCodex._();

  /// Stable codex entry ids (referenced by the activity's codexEntryIds).
  static const String entryFrameAndAnchor = 'shelter.codex.frame_anchor';
  static const String entryMaterials = 'shelter.codex.materials';
  static const String entryReadingTheLand = 'shelter.codex.reading_land';
  static const String entryFloodCycle = 'shelter.codex.flood_cycle';

  /// Every codex entry this leaf contributes.
  static List<CodexEntry> all() => <CodexEntry>[
        frameAndAnchor(),
        materials(),
        readingTheLand(),
        floodCycle(),
      ];

  /// The headline structure card (granted on completing Raise a Shelter).
  static CodexEntry frameAndAnchor() => const CodexEntry(
        id: entryFrameAndAnchor,
        concept: ConceptId.shelter,
        title: 'The Frame and the Anchor',
        discoveryStory:
            'The first cover the tribe leaned up blew flat in the night wind. '
            'Then the Elder set a strong frame of poles first — and lashed it '
            'down with stones — before laying the hides over it. This time, when '
            'the wind came, the shelter stood.',
        science:
            'A shelter works in two parts. The FRAME carries the weight of the '
            'cover and the load of wind and rain, passing it down to the ground. '
            'Anchoring or weighting it down stops the wind from lifting it. Walls '
            'alone are not enough — without a frame to carry the load, a shelter '
            'folds.',
        history:
            'Ice Age hunters raised tents on wooden frames and famously built '
            'huts from mammoth bones and tusks, covered with hides and weighted '
            'with heavy stones around the base to hold them against the wind.',
      );

  /// Depth card: materials + their tradeoffs (and insulation against cold).
  static CodexEntry materials() => const CodexEntry(
        id: entryMaterials,
        concept: ConceptId.shelter,
        title: 'Choosing Your Materials',
        discoveryStory:
            'A hide tent went up fast and could be carried to the next camp — but '
            'it was cold and thin. A hut of wood and thatch took far longer and '
            'cost much more, yet it held the warmth and stood for seasons. Each '
            'choice traded something away.',
        science:
            'Every material is a tradeoff. Hides over a frame are light and quick '
            'but let cold through. Wood, thatch, and packed earth insulate far '
            'better — they trap warm air and shed rain — but cost more work and '
            'resources. A trapped layer of still air is what keeps a shelter '
            'warm.',
        history:
            'People built lean-tos, brush huts, hide tents, pit-houses, and '
            'mammoth-bone huts — picking materials for the climate, what was '
            'nearby, and whether they meant to move on or stay put.',
      );

  /// The SITE card: reading the land (and out of the flood path).
  static CodexEntry readingTheLand() => const CodexEntry(
        id: entryReadingTheLand,
        concept: ConceptId.shelter,
        title: 'Reading the Land',
        discoveryStory:
            'Water and fish were easiest right by the river — so that is where '
            'the first homes went up. The Elder frowned and pointed to the higher '
            'ground a little back from the bank, where the old driftwood lay: '
            '"The water has been this high before. It will be again."',
        science:
            'Where you build decides whether you wake up dry. The best site is '
            'near water and food, defensible, on well-drained HIGHER ground — out '
            'of the low path the water takes when it rises. Reading the land '
            '(old waterlines, driftwood, the lie of the slope) tells you where '
            'the water will go.',
        history:
            'Across the world, lasting settlements clustered on terraces and '
            'mounds above the floodplain — close enough to use the river, high '
            'enough to stay above it.',
      );

  /// The showpiece reframe card: the flood as a predictable cycle (and a gift).
  static CodexEntry floodCycle() => const CodexEntry(
        id: entryFloodCycle,
        concept: ConceptId.shelter,
        title: 'The Flood Is a Cycle',
        discoveryStory:
            'When the river swept the low camp, it felt like a curse. But the '
            'Elder had seen it before, and would see it again — it came with the '
            'wet season, every year. And when the water drew back, it left behind '
            'the darkest, richest soil along the bank.',
        science:
            'A flood is not a punishment — it is part of a CYCLE you can predict. '
            'Rivers rise and fall with the seasons. Once you can forecast it, you '
            'stop fearing it: you build above the high-water line, and you use the '
            'fertile silt the water leaves to grow food. Fear becomes mastery.',
        history:
            'Later peoples turned this knowledge into civilization: along rivers '
            'like the Nile, the yearly flood was tracked and welcomed because the '
            'silt it laid down made the fields rich — the seed of farming and '
            'irrigation.',
      );

  /// Upgrade 1 — STRUCTURE: walls alone -> a frame carries the load.
  static ModelUpgrade structureUpgrade() => const ModelUpgrade(
        concept: ConceptId.shelter,
        mythBelief:
            'A shelter is just walls thrown up against the weather — pile enough '
            'up and it will hold.',
        evidenceBelief:
            'A shelter is a FRAME that carries the load and an ANCHOR that holds '
            'it down — build those first and the cover does the rest.',
        flag: ShelterKnowledge.structureUnderstood,
      );

  /// Upgrade 2 — SITE / FLOOD (the showpiece): the river is cursed -> the flood
  /// is a predictable cycle you can plan around and even use.
  static ModelUpgrade floodUpgrade() => const ModelUpgrade(
        concept: ConceptId.shelter,
        mythBelief:
            'The river is cursed — the flood is angry spirits sweeping away the '
            'camp without warning.',
        evidenceBelief:
            'The flood is a CYCLE I can read and plan around — build above the '
            'water and the silt it leaves becomes my richest soil.',
        flag: ShelterKnowledge.floodModelUpgraded,
      );
}
