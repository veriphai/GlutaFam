// Ember — concepts/fire/make_fire_activity.dart
//
// The DECLARATIVE "Make Fire" activity: the 5-beat copy (Elder setup + myth line,
// the "it clicks" reframe), the InteractionRules (success signal + the THREE
// teaching FailureRules that ARE the fire triangle, each taught BY FAILURE), the
// SuccessCriteria, and the ApplyEffects landed on success — unlock the three fire
// placeables, set the triangle-understood + discovered knowledge flags, mark the
// fire concept done, grant the codex entries, set the night-survivable world flag,
// and land the myth -> evidence model upgrade. Pure data; no Flame/Flutter.
//
// The SimEvent codes here are the contract the [MakeFireSim] emits against and the
// [BeatController] scores; they live in [MakeFireSignals] so sim + activity agree.

import '../../activity/activity_contract.dart';
import '../../activity/apply_effect.dart';
import '../../core/enums.dart';
import 'fire_codex.dart';
import 'fire_knowledge.dart';

/// The frozen SimEvent codes + config keys for the Make Fire interaction. The
/// sim emits these; the activity's rules match against them.
class MakeFireSignals {
  const MakeFireSignals._();

  // ---- The success signal -------------------------------------------------
  /// Emitted when the tinder bundle bursts into a steady flame.
  static const String ignited = 'fire.ignited';

  // ---- Failure signals (each teaches one side of the fire triangle) -------
  /// FUEL: the player chose damp tinder, so it never catches.
  static const String dampTinder = 'fire.fail.dampTinder';

  /// HEAT: drilling was too slow, so the board never gets hot enough.
  static const String tooSlow = 'fire.fail.tooSlow';

  /// AIR: the ember was smothered (covered) or left until it died — no oxygen.
  static const String smothered = 'fire.fail.smothered';

  // ---- Ambient (non-scoring) cues the scene/UI react to -------------------
  static const String tinderChosen = 'fire.tinderChosen';
  static const String heatProgress = 'fire.heatProgress';
  static const String emberCaught = 'fire.emberCaught';
  static const String flameGrowing = 'fire.flameGrowing';

  /// A quarter-turn of the bow-drill landed — the scene fires a selectionClick.
  static const String spinTick = 'fire.spinTick';

  // ---- Config keys (read by MakeFireSim from InteractionRules.config) ------
  /// Heat gained per unit of |angular velocity| per second (friction = spin).
  static const String cfgHeatPerSpin = 'heatPerSpin';

  /// How fast the notch cools while NOT being driven (the HARD-GATE bleed).
  static const String cfgHeatDecayPerSec = 'heatDecayPerSec';
  static const String cfgHeatToEmber = 'heatToEmber';
  static const String cfgEmberDecayPerSec = 'emberDecayPerSec';

  /// Flame growth per unit of puff strength (an upward swipe's length, 0..1).
  static const String cfgFlamePerPuff = 'flamePerPuff';
  static const String cfgFlameToIgnite = 'flameToIgnite';
  static const String cfgEmberWindowSec = 'emberWindowSec';

  /// |angular velocity| below this reads as "the finger stopped" (heat bleeds).
  static const String cfgSpinStallThreshold = 'spinStallThreshold';

  // ---- Player input codes (sent into the sim) ------------------------------
  static const String inSelectTinder = 'selectTinder';

  /// A rotational-drag frame: sets the live spindle angular velocity ('vel').
  static const String inSpin = 'spin';

  /// An upward-swipe frame: puffs the ember with a 'strength' (0..1).
  static const String inPuff = 'puff';

  /// A stone-lid drag over the ember: cuts its air (the AIR fail).
  static const String inCover = 'cover';
}

/// Builds the Make Fire [EmberActivity].
class MakeFireActivity {
  const MakeFireActivity._();

  /// Stable activity id.
  static const String id = 'fire.make_fire';

  static EmberActivity build() => EmberActivity(
        id: id,
        conceptId: ConceptId.fire,
        title: 'Make Fire',
        // Starting concept — no gate.
        prerequisites: const <Prerequisite>[NoPrerequisite()],
        learningObjective:
            'Fire needs three things at once — fuel, heat, and air. Remove any '
            'one and it dies (the fire triangle), taught by failing each.',
        setupCopy: const SetupCopy(
          elderLine:
              'The cold bites hard tonight, little one. Kneel with me. We have '
              'dry grass, a spindle, and a board — and we will not wait for the '
              'sky to send us fire. We will make it.',
          prompt:
              'Pick dry tinder, spin the drill to build heat, catch the ember, '
              'then breathe life into the flame.',
          // The myth this activity challenges (myth -> evidence).
          mythLine:
              'The old fear says the dark holds angry spirits, and only they can '
              'grant fire.',
          hintLine: 'Dry tinder catches. Spin steady and fast. Blow gently.',
        ),
        interactionRules: const InteractionRules(
          successSignal: MakeFireSignals.ignited,
          // Untimed at the sim level — the ember window is enforced inside the sim
          // (the AIR lesson) rather than as a hard activity time budget.
          timeBudgetMs: 0,
          // Three teaching failures = the three sides of the triangle. None are
          // fatal: every fail is gentle + instantly retryable (younger-player UX).
          failureRules: <FailureRule>[
            FailureRule(
              id: 'fire.fuel',
              signal: MakeFireSignals.dampTinder,
              hint:
                  'Damp tinder will not catch — fire needs something dry to burn. '
                  'That is FUEL, the first thing fire wants.',
            ),
            FailureRule(
              id: 'fire.heat',
              signal: MakeFireSignals.tooSlow,
              hint:
                  'Too slow! Rubbing gently never gets hot enough. Spin fast and '
                  'steady to build HEAT — the second thing fire wants.',
            ),
            FailureRule(
              id: 'fire.air',
              signal: MakeFireSignals.smothered,
              hint:
                  'The ember went dark — it could not breathe. Fire needs AIR. '
                  'Blow on it gently instead of covering it up.',
            ),
          ],
          // Tuning the sim reads (these OVERRIDE the sim's defaults, so they must
          // match them). The drive is now a TRUE angular velocity (rad/s) from the
          // CRANK WHEEL (mirroring the Hand-Crank Lamp): the scene measures the
          // finger's angle delta around the wheel centre and integrates it, with a
          // sample-timeout hold that bridges the gaps between pointer-move samples.
          // |angular velocity| is integrated straight into friction heat
          // (heatPerSpin * |vel| * dt): a vigorous crank (~10-20 rad/s) -> ~0.7-1.4
          // heat/s, so an ember catches in ~1-2s of steady cranking. The instant
          // the finger stops (or the hold expires), heat HARD-bleeds at 0.40/s, and
          // after ~2s of a stall with progress the HEAT lesson surfaces (the felt
          // "keep it turning"). A full upward swipe (strength 1) grows the flame
          // ~0.34, so ~3 strong puffs ignite (the AIR lesson).
          config: <String, dynamic>{
            MakeFireSignals.cfgHeatPerSpin: 0.07,
            MakeFireSignals.cfgHeatDecayPerSec: 0.40,
            MakeFireSignals.cfgSpinStallThreshold: 0.8,
            MakeFireSignals.cfgHeatToEmber: 1.0,
            MakeFireSignals.cfgEmberDecayPerSec: 0.10,
            MakeFireSignals.cfgFlamePerPuff: 0.34,
            MakeFireSignals.cfgFlameToIgnite: 1.0,
            MakeFireSignals.cfgEmberWindowSec: 6.0,
          },
        ),
        successCriteria: const SuccessCriteria(
          threeStarMaxAttempts: 1,
          twoStarMaxAttempts: 2,
          // Seeing the triangle's lessons is the POINT — be generous on failures.
          threeStarMaxFailures: 1,
          twoStarMaxFailures: 3,
        ),
        clickCopy: const ClickCopy(
          revelation:
              'The bundle blazes up — the camp\'s very first fire, made by your '
              'own hands!',
          // The Elder names the principle the moment it clicks.
          science:
              'The Elder smiles: "Fire wants three things — something to burn, '
              'enough heat to start it, and air to breathe. You gave it all '
              'three. That is all fire ever is. No spirits. A tool we control."',
          celebrationLine:
              'Place the first Hearth at the camp\'s heart. Night just became '
              'survivable.',
        ),
        // Effects landed on success.
        unlocks: const <ApplyEffect>[
          UnlockPlaceable(PlaceableType.hearth),
          UnlockPlaceable(PlaceableType.torch),
          UnlockPlaceable(PlaceableType.cookingFire),
          SetKnowledgeFlag(FireKnowledge.fireTriangleUnderstood),
          SetKnowledgeFlag(FireKnowledge.fireDiscovered),
          MarkConceptDone(ConceptId.fire),
          SetWorldFlag(FireKnowledge.nightSurvivable),
        ],
        codexEntryIds: const <String>[
          FireCodex.entryFireTriangle,
          FireCodex.entryKeepingFire,
          FireCodex.entryWhyAir,
        ],
        modelUpgrade: FireCodex.modelUpgrade(),
      );
}
