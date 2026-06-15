// Ember — concepts/tools/knapping_activity.dart
//
// The DECLARATIVE "Knapping" activity: the 5-beat copy (Elder setup + the myth
// line, the "it clicks" reframe), the InteractionRules (success signal + the
// THREE teaching FailureRules that ARE the §3 lesson — material, force, angle —
// each taught BY FAILURE), the SuccessCriteria, and the ApplyEffects landed on
// success: unlock the two tools placeables, set knapping-discovered +
// materials-understood + tools-equipped + hide-processing flags, mark the
// stoneTools concept done, grant the codex entries, and land the myth -> evidence
// model upgrade. Pure data; no Flame/Flutter.
//
// PREREQUISITE: Stone Tools needs Fire (heat-treating stone / fire-hardening the
// haft) — PRD §2 + the tech tree — so the activity gates on ConceptCompleted(fire).
//
// The success / failure SimEvent codes are owned by [StrikeSignals] (so the pure
// resolver + the sim + this activity agree); the interaction config keys + the
// player input verbs live in [KnappingSignals] below.

import '../../activity/activity_contract.dart';
import '../../activity/apply_effect.dart';
import '../../core/enums.dart';
import 'strike_resolver.dart';
import 'tools_codex.dart';
import 'tools_knowledge.dart';

/// The config keys (read by [KnappingSim] from InteractionRules.config) + the
/// player-input verb codes (sent into the sim). The outcome SIGNAL codes live in
/// [StrikeSignals] (strike_resolver.dart) so the resolver is self-describing.
class KnappingSignals {
  const KnappingSignals._();

  // ---- Config keys --------------------------------------------------------
  /// Total clean-flake progress (0..1 sum) needed to shape a finished blade.
  static const String cfgFlakeToFinish = 'flakeToFinish';

  /// Whether to offer the optional haft (spear) step after the blade is shaped.
  static const String cfgOfferHaft = 'offerHaft';

  // ---- Player input verbs (sent into the sim) -----------------------------
  static const String inChooseStone = 'chooseStone';
  static const String inStrike = 'strike';
  static const String inHaft = 'haft';
  static const String inSkipHaft = 'skipHaft';
}

/// Builds the Knapping [EmberActivity].
class KnappingActivity {
  const KnappingActivity._();

  /// Stable activity id.
  static const String id = 'tools.knapping';

  static EmberActivity build() => EmberActivity(
        id: id,
        conceptId: ConceptId.stoneTools,
        title: 'Knapping',
        // Stone Tools needs Fire first (heat-treatment link — PRD §2/§4).
        prerequisites: const <Prerequisite>[
          ConceptCompleted(ConceptId.fire),
        ],
        learningObjective:
            'A made edge does what hands and teeth can\'t. Striking a hard, '
            'glassy stone at the right angle and force flakes off sharp pieces — '
            'taught by failing on the wrong material, too little force, and the '
            'wrong angle.',
        setupCopy: const SetupCopy(
          elderLine:
              'Come, little one. Your hands are strong, but a claw is sharper. '
              'So we will make something sharper still. Here are some stones and '
              'a hammerstone — but not every stone will do.',
          prompt:
              'Choose a stone, then strike it — aim a glancing angle and control '
              'your force — until a clean, sharp flake comes free.',
          // The myth this activity challenges (myth -> evidence).
          mythLine:
              'The old belief says some stones are simply lucky — a few magic '
              'rocks happen to cut, and most do not.',
          hintLine:
              'Pick a hard, glassy stone. Strike at a slant, not straight on. '
              'Not too soft, not too hard.',
        ),
        interactionRules: const InteractionRules(
          successSignal: StrikeSignals.bladeFinished,
          // Untimed: the lesson is precision, not speed (kid-friendly).
          timeBudgetMs: 0,
          // Three teaching failures = the three things a good knap needs. None
          // are fatal: every fail is gentle + instantly retryable.
          failureRules: <FailureRule>[
            FailureRule(
              id: 'tools.material',
              signal: StrikeSignals.wrongMaterial,
              hint:
                  'That stone can\'t make an edge — soft stone crumbles and dull '
                  'stone just chips. You need a HARD, GLASSY stone like flint or '
                  'obsidian. The MATERIAL is what matters.',
            ),
            FailureRule(
              id: 'tools.force.weak',
              signal: StrikeSignals.tooWeak,
              hint:
                  'Too gentle — the blow bounced off and nothing flaked. Strike '
                  'harder to knock a flake loose (but not SO hard it shatters).',
            ),
            FailureRule(
              id: 'tools.strike',
              signal: StrikeSignals.shattered,
              hint:
                  'It shattered! Too much force, or you hit it straight on. '
                  'Strike at a glancing ANGLE with a controlled FORCE — that '
                  'pops a clean flake instead of breaking the stone.',
            ),
          ],
          // Tuning the sim reads. ~2-3 clean flakes finish a blade; haft offered.
          config: <String, dynamic>{
            KnappingSignals.cfgFlakeToFinish: 1.0,
            KnappingSignals.cfgOfferHaft: true,
          },
        ),
        successCriteria: const SuccessCriteria(
          threeStarMaxAttempts: 1,
          twoStarMaxAttempts: 2,
          // Seeing the lessons is the POINT — be generous on failures.
          threeStarMaxFailures: 1,
          twoStarMaxFailures: 3,
        ),
        clickCopy: const ClickCopy(
          revelation:
              'The flake springs free with a sharp "tck" — a glassy edge keener '
              'than any claw or tooth, made by your own hands!',
          // The Elder names the principle the moment it clicks.
          science:
              'The Elder turns the blade in the light: "There was never any luck '
              'in it. Hard, glassy stone breaks into sharp edges because of WHAT '
              'IT IS — strike it right and it gives you a blade. We do not just '
              'use the world, little one. We shape it."',
          celebrationLine:
              'Place a Knapping Station. Now the tribe works with edges — '
              'gathering and hunting will never be the same.',
        ),
        // Effects landed on success.
        unlocks: const <ApplyEffect>[
          UnlockPlaceable(PlaceableType.knappingStation),
          UnlockPlaceable(PlaceableType.toolRack),
          SetKnowledgeFlag(ToolsKnowledge.knappingDiscovered),
          SetKnowledgeFlag(ToolsKnowledge.materialsUnderstood),
          MarkConceptDone(ConceptId.stoneTools),
          SetWorldFlag(ToolsKnowledge.toolsEquipped),
          SetWorldFlag(ToolsKnowledge.hideProcessingUnlocked),
        ],
        codexEntryIds: const <String>[
          ToolsCodex.entryKnapping,
          ToolsCodex.entryMaterials,
          ToolsCodex.entryHafting,
        ],
        modelUpgrade: ToolsCodex.modelUpgrade(),
      );
}
