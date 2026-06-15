// Ember — concepts/fire/fire_codex.dart
//
// The discoverable knowledge cards for fire (discovery story / science / history)
// plus the myth -> evidence model upgrade the Make Fire activity lands. These are
// pure value objects the registry collects and the reducer grants/applies. Copy is
// written for a 7-14 audience: accessible, never falsely precise about prehistory
// dates, and child-safe (cold + predators are stylized, never graphic).

import '../../contracts/codex_entry.dart';
import '../../core/enums.dart';
import 'fire_knowledge.dart';

/// The fire leaf's codex content + model upgrade.
class FireCodex {
  const FireCodex._();

  /// Stable codex entry ids (referenced by the activity's codexEntryIds).
  static const String entryFireTriangle = 'fire.codex.triangle';
  static const String entryKeepingFire = 'fire.codex.keeping_fire';
  static const String entryWhyAir = 'fire.codex.why_air';

  /// Every codex entry this leaf contributes.
  static List<CodexEntry> all() => <CodexEntry>[
        fireTriangle(),
        keepingFire(),
        whyAir(),
      ];

  /// The headline card: the fire triangle (granted on completing Make Fire).
  static CodexEntry fireTriangle() => const CodexEntry(
        id: entryFireTriangle,
        concept: ConceptId.fire,
        title: 'The Fire Triangle',
        discoveryStory:
            'On a freezing night the Elder knelt over a little bundle of dry '
            'grass, spun a stick fast and steady, and breathed on a tiny glowing '
            'speck until it leapt into flame. The whole camp gathered close to '
            'the first fire they had ever made themselves.',
        science:
            'Fire needs three things at once: something to burn (fuel), enough '
            'heat to get it started, and air to breathe. Take any one away and '
            'the fire dies — damp fuel will not catch, a cold spark fizzles, and '
            'cover it up and it smothers.',
        history:
            'Hundreds of thousands of years ago, people first captured fire from '
            'lightning and wildfires. Much later they learned to MAKE it on '
            'demand by rubbing wood together or striking sparks from stone.',
      );

  /// Depth card: how people kept fire alive before they could make it.
  static CodexEntry keepingFire() => const CodexEntry(
        id: entryKeepingFire,
        concept: ConceptId.fire,
        title: 'Keeping the Ember Alive',
        discoveryStory:
            'Long before anyone could spark a flame, the tribe guarded a glowing '
            'ember like treasure — carrying it carefully, feeding it scraps of '
            'dry wood, never letting it go cold on the journey.',
        science:
            'A glowing ember is fire that is just barely fed: a little fuel and a '
            'little air keep it smouldering. Add dry tinder and breathe gently '
            'and it grows back into flame.',
        history:
            'Tending and carrying fire came first; making fire from scratch came '
            'later. Losing your fire could mean a cold, dangerous night.',
      );

  /// Optional older-kid depth: why fire needs air (the "why" behind the triangle).
  static CodexEntry whyAir() => const CodexEntry(
        id: entryWhyAir,
        concept: ConceptId.fire,
        title: 'Why Does Fire Need Air?',
        discoveryStory:
            'When the Elder cupped a hand over the new flame it shrank and '
            'sputtered — but a soft puff of breath made it stand tall and bright '
            'again. Air, it turned out, was food for fire.',
        science:
            'Burning is a chemical reaction between fuel and the oxygen in air. '
            'Without fresh air the reaction starves and stops — which is exactly '
            'why blowing gently feeds a flame and smothering it puts it out.',
        history:
            'People understood "fire needs air" by doing long before they had the '
            'word oxygen — they fanned fires and built airflow into their hearths.',
      );

  /// The belief shift: dark holds angry spirits -> fire is a tool we control.
  static ModelUpgrade modelUpgrade() => const ModelUpgrade(
        concept: ConceptId.fire,
        mythBelief:
            'The dark holds angry spirits, and fire is a gift only the spirits '
            'can give.',
        evidenceBelief:
            'Fire is a tool we make and control ourselves — give it fuel, heat, '
            'and air and it lives; the dark is just the dark.',
        flag: FireKnowledge.fireModelUpgraded,
      );
}
