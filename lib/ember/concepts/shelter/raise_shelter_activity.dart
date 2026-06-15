// Ember — concepts/shelter/raise_shelter_activity.dart
//
// The DECLARATIVE "Raise a Shelter" activity: the 5-beat copy (Elder setup + the
// "the ground you chose decides whether you wake up dry" reframe), the
// InteractionRules (success signal + the teaching FailureRules that ARE the site +
// anchoring lessons, each taught BY FAILURE), the SuccessCriteria, and the
// ApplyEffects landed on success — unlock the four shelter placeables, raise the
// population cap, set the discovered/structure/site knowledge flags, mark the
// shelter concept done, grant the codex entries, set the village-housed world
// flag, and land the STRUCTURE myth -> evidence model upgrade. Pure data; no
// Flame/Flutter.
//
// The SimEvent codes here are the contract the [RaiseShelterSim] emits against and
// the [BeatController] scores; they live in [RaiseShelterSignals] so sim + activity
// agree. The SECOND model upgrade (the flood reframe) is landed by the flood event
// itself (FloodResolver) + exposed via the module's modelUpgrades; this activity
// carries the structure upgrade as its primary belief shift.

import '../../activity/activity_contract.dart';
import '../../activity/apply_effect.dart';
import '../../core/enums.dart';
import 'shelter_codex.dart';
import 'shelter_knowledge.dart';

/// The frozen SimEvent codes, input codes, and config keys for the Raise a
/// Shelter interaction. The sim emits these; the activity's rules match them.
class RaiseShelterSignals {
  const RaiseShelterSignals._();

  // ---- The success signal -------------------------------------------------
  /// Emitted when a sound, well-sited, well-anchored shelter survives the test.
  static const String stoodTheStorm = 'shelter.stoodTheStorm';

  // ---- Failure signals (each teaches one lesson) --------------------------
  /// SITE: the shelter was raised on a low flood-risk tile and the rain floods
  /// it (the headline site lesson, by consequence).
  static const String lowSiteFlooded = 'shelter.fail.lowSiteFlooded';

  /// STRUCTURE/ANCHOR: the cover went on without weighting/anchoring the frame,
  /// so the wind lifts it and it blows over.
  static const String poorAnchorBlownOver = 'shelter.fail.poorAnchorBlownOver';

  /// ASSEMBLE ORDER: the player tried to add the cover before raising the frame
  /// (you cannot drape hides on nothing) — a gentle ordering nudge.
  static const String coverBeforeFrame = 'shelter.fail.coverBeforeFrame';

  // ---- Ambient (non-scoring) cues the scene/UI react to -------------------
  static const String siteChosen = 'shelter.siteChosen';

  /// A material was picked + is being dragged in (the wall starts rising). Carries
  /// {'material', 'dragging'} — fired continuously as the pick/release toggles.
  static const String materialChosen = 'shelter.materialChosen';

  /// The dragged material's wall finished rising — the material is committed and
  /// the phase advances to the snap-build assemble. Carries {'material'}.
  static const String materialRaised = 'shelter.materialRaised';

  static const String stepDone = 'shelter.stepDone';
  static const String assembled = 'shelter.assembled';
  static const String testStarted = 'shelter.testStarted';

  /// A part was dragged onto the wrong (not-current) slot — a kind bounce-back
  /// nudge, NOT a scored failure (no progress destroyed). Carries {'step','want'}.
  static const String wrongPart = 'shelter.wrongPart';

  // ---- Player input codes (sent into the sim) ------------------------------
  /// data: {'risk': double 0..1, 'siteId': String}
  static const String inChooseSite = 'chooseSite';

  /// data: {'material': 'hideTent' | 'hut'}
  static const String inChooseMaterial = 'chooseMaterial';

  /// data: {'step': 'frame' | 'cover' | 'anchor' | 'smokeHole'}
  static const String inAssembleStep = 'assembleStep';

  /// Start the wind/rain test once assembled.
  static const String inRunTest = 'runTest';

  // ---- Config keys (read by RaiseShelterSim from InteractionRules.config) ---
  /// The flood-risk threshold (0..1) at/above which the chosen site floods.
  static const String cfgFloodRiskThreshold = 'floodRiskThreshold';
}

/// Builds the Raise a Shelter [EmberActivity].
class RaiseShelterActivity {
  const RaiseShelterActivity._();

  /// Stable activity id.
  static const String id = 'shelter.raise_shelter';

  /// The population headroom the first raised shelter grants immediately (the
  /// PopulationSystem then keeps the cap accurate from built dwellings' capacity).
  static const int populationCapBump = 3;

  static EmberActivity build() => EmberActivity(
        id: id,
        conceptId: ConceptId.shelter,
        title: 'Raise a Shelter',
        // Gated by the tech tree: needs Fire (the indoor hearth's warmth) AND
        // Stone Tools (to cut wood + process hides for a proper hut).
        prerequisites: const <Prerequisite>[
          ConceptCompleted(ConceptId.fire),
          ConceptCompleted(ConceptId.stoneTools),
        ],
        learningObjective:
            'A shelter works because a FRAME carries the load and an ANCHOR holds '
            'it down — and above all, WHERE you build (out of the flood path) '
            'decides whether you wake up dry. Taught by failing the site + anchor.',
        setupCopy: const SetupCopy(
          elderLine:
              'A cold storm is rolling in, little one. Tonight we do not just '
              'huddle by the fire — we raise a home. Choose the ground well, '
              'choose what to build, then put it together so it stands.',
          // One calm line — the doing is taught on the stage itself (stand on a
          // spot, drag the walls up, snap the parts on), not read off a checklist.
          prompt:
              'Read the ground, raise the walls, and stand it up before the '
              'storm rolls in.',
          // The myth this activity (and the flood) challenges.
          mythLine:
              'The old fear says the river is cursed, and a shelter is just walls '
              'thrown up against the angry spirits of the storm.',
          hintLine:
              'High ground stays dry. Frame first, then cover. Always anchor it '
              'against the wind.',
        ),
        interactionRules: const InteractionRules(
          successSignal: RaiseShelterSignals.stoodTheStorm,
          timeBudgetMs: 0,
          // Teaching failures = the site + structure lessons. None fatal: every
          // fail is gentle + instantly retryable (younger-player UX, §16).
          failureRules: <FailureRule>[
            FailureRule(
              id: 'shelter.site',
              signal: RaiseShelterSignals.lowSiteFlooded,
              hint:
                  'The rain pooled and flooded your shelter — you built on the '
                  'low river ground. SITE is everything: raise it on higher '
                  'ground, out of the water\'s path.',
            ),
            FailureRule(
              id: 'shelter.anchor',
              signal: RaiseShelterSignals.poorAnchorBlownOver,
              hint:
                  'The wind lifted your cover and the shelter blew over — you '
                  'never anchored it. A frame carries the load, but you must '
                  'WEIGHT IT DOWN so the wind cannot take it.',
            ),
            FailureRule(
              id: 'shelter.order',
              signal: RaiseShelterSignals.coverBeforeFrame,
              hint:
                  'You cannot drape the cover over nothing! Raise the FRAME '
                  'first — it carries everything else.',
            ),
          ],
          config: <String, dynamic>{
            // A site at/above 0.4 flood risk is "in the flood path".
            RaiseShelterSignals.cfgFloodRiskThreshold: 0.4,
          },
        ),
        successCriteria: const SuccessCriteria(
          threeStarMaxAttempts: 1,
          twoStarMaxAttempts: 2,
          // Seeing the site + anchor lessons is the POINT — be generous.
          threeStarMaxFailures: 1,
          twoStarMaxFailures: 3,
        ),
        clickCopy: const ClickCopy(
          revelation:
              'The storm howls all night — and your shelter holds. Inside, the '
              'tribe is warm and dry by the hearth.',
          // The Elder names the principle the moment it clicks.
          science:
              'The Elder nods: "The frame carries the weight, the cover keeps out '
              'the cold — and the ground you chose decides whether you wake up '
              'dry. That is all a home ever is. No curses. A place we build, on '
              'ground we read."',
          celebrationLine:
              'Raise your homes around the village — there is room for the tribe '
              'to grow now.',
        ),
        // Effects landed on success.
        unlocks: const <ApplyEffect>[
          UnlockPlaceable(PlaceableType.leanTo),
          UnlockPlaceable(PlaceableType.hideTent),
          UnlockPlaceable(PlaceableType.hut),
          UnlockPlaceable(PlaceableType.palisade),
          RaisePopulationCap(populationCapBump),
          SetKnowledgeFlag(ShelterKnowledge.shelterDiscovered),
          SetKnowledgeFlag(ShelterKnowledge.structureUnderstood),
          SetKnowledgeFlag(ShelterKnowledge.siteUnderstood),
          SetWorldFlag(ShelterKnowledge.villageHoused),
          MarkConceptDone(ConceptId.shelter),
        ],
        codexEntryIds: const <String>[
          ShelterCodex.entryFrameAndAnchor,
          ShelterCodex.entryMaterials,
          ShelterCodex.entryReadingTheLand,
          ShelterCodex.entryFloodCycle,
        ],
        // Primary belief shift this activity lands = STRUCTURE. The flood reframe
        // (the second upgrade) is landed by the FloodResolver + exposed via the
        // module's modelUpgrades.
        modelUpgrade: ShelterCodex.structureUpgrade(),
      );
}
