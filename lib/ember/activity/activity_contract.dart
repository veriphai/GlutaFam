// Ember — activity/activity_contract.dart
//
// The DECLARATIVE description of an activity (the "what", not the "how"). A leaf
// builds one [EmberActivity] per concept: prerequisites to start it, the learning
// objective, the 5-beat copy (setup / it-clicks), the interaction rules + success
// criteria the BeatController scores against, and the ApplyEffects/ModelUpgrade it
// lands on success. The interactive brain (ActivitySim) + visuals (ActivityScene)
// are separate seams; this file is pure data (no Flame/Flutter).

import '../contracts/codex_entry.dart';
import '../core/enums.dart';
import 'apply_effect.dart';

/// A gate that must be satisfied before an activity becomes startable.
sealed class Prerequisite {
  const Prerequisite();

  String get kind;
  Map<String, dynamic> toJson();

  factory Prerequisite.fromJson(Map<String, dynamic> j) {
    final String k = j['kind'] as String? ?? '';
    switch (k) {
      case 'conceptCompleted':
        return ConceptCompleted(conceptIdFromName(j['concept']));
      case 'knowledgeFlag':
        return KnowledgeFlagSet(j['flag'] as String? ?? '');
      case 'placeableBuilt':
        return PlaceableBuilt(placeableTypeFromName(j['type']));
      default:
        return const NoPrerequisite();
    }
  }
}

/// No gate — always startable.
class NoPrerequisite extends Prerequisite {
  const NoPrerequisite();
  @override
  String get kind => 'none';
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{'kind': kind};
}

/// Requires another concept to be completed.
class ConceptCompleted extends Prerequisite {
  const ConceptCompleted(this.concept);
  final ConceptId concept;
  @override
  String get kind => 'conceptCompleted';
  @override
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'kind': kind, 'concept': concept.name};
}

/// Requires a knowledge flag to be set.
class KnowledgeFlagSet extends Prerequisite {
  const KnowledgeFlagSet(this.flag);
  final String flag;
  @override
  String get kind => 'knowledgeFlag';
  @override
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'kind': kind, 'flag': flag};
}

/// Requires at least one of a placeable type to be built.
class PlaceableBuilt extends Prerequisite {
  const PlaceableBuilt(this.type);
  final PlaceableType type;
  @override
  String get kind => 'placeableBuilt';
  @override
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'kind': kind, 'type': type.name};
}

/// A failure pattern the BeatController watches for, with the hint to show.
/// [signal] is matched against SimEvent.code; when it fires, [hint] is surfaced
/// once (tracked in failuresSeen) and counts toward attempts.
class FailureRule {
  const FailureRule({
    required this.id,
    required this.signal,
    required this.hint,
    this.fatal = false,
  });

  /// Stable id recorded in failuresSeen.
  final String id;

  /// SimEvent code that triggers this failure.
  final String signal;

  /// The teaching hint shown to the player.
  final String hint;

  /// Whether hitting this rule ends the attempt immediately.
  final bool fatal;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'signal': signal,
        'hint': hint,
        'fatal': fatal,
      };

  factory FailureRule.fromJson(Map<String, dynamic> j) => FailureRule(
        id: j['id'] as String? ?? '',
        signal: j['signal'] as String? ?? '',
        hint: j['hint'] as String? ?? '',
        fatal: j['fatal'] as bool? ?? false,
      );
}

/// The rules governing the interact beat: which SimEvent code signals success,
/// how many discrete inputs are allowed, the failure patterns, and an optional
/// time budget (ms of activity time, not wall clock).
class InteractionRules {
  const InteractionRules({
    required this.successSignal,
    this.maxInputs = 0,
    this.failureRules = const <FailureRule>[],
    this.timeBudgetMs = 0,
    this.config = const <String, dynamic>{},
  });

  /// SimEvent code that marks the interaction solved.
  final String successSignal;

  /// Max distinct inputs the player may make (0 = unlimited).
  final int maxInputs;

  /// Failure patterns to watch + teach.
  final List<FailureRule> failureRules;

  /// Activity-time budget in ms (0 = untimed).
  final int timeBudgetMs;

  /// Free-form per-activity tuning the leaf's ActivitySim reads.
  final Map<String, dynamic> config;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'successSignal': successSignal,
        'maxInputs': maxInputs,
        'failureRules': <Map<String, dynamic>>[
          for (final FailureRule r in failureRules) r.toJson(),
        ],
        'timeBudgetMs': timeBudgetMs,
        'config': config,
      };

  factory InteractionRules.fromJson(Map<String, dynamic> j) => InteractionRules(
        successSignal: j['successSignal'] as String? ?? '',
        maxInputs: (j['maxInputs'] as num?)?.toInt() ?? 0,
        failureRules: <FailureRule>[
          for (final dynamic e
              in (j['failureRules'] as List?) ?? const <dynamic>[])
            FailureRule.fromJson((e as Map).cast<String, dynamic>()),
        ],
        timeBudgetMs: (j['timeBudgetMs'] as num?)?.toInt() ?? 0,
        config: (j['config'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      );
}

/// How success quality (0..3 stars) is graded against the recorded run.
class SuccessCriteria {
  const SuccessCriteria({
    this.requireSuccessSignal = true,
    this.threeStarMaxAttempts = 1,
    this.twoStarMaxAttempts = 2,
    this.threeStarMaxFailures = 0,
    this.twoStarMaxFailures = 1,
  });

  /// Whether the success signal must fire to complete at all.
  final bool requireSuccessSignal;

  /// At most this many attempts to earn 3 stars.
  final int threeStarMaxAttempts;

  /// At most this many attempts to earn 2 stars (else 1).
  final int twoStarMaxAttempts;

  /// At most this many distinct failures seen to earn 3 stars.
  final int threeStarMaxFailures;

  /// At most this many distinct failures seen to earn 2 stars.
  final int twoStarMaxFailures;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'requireSuccessSignal': requireSuccessSignal,
        'threeStarMaxAttempts': threeStarMaxAttempts,
        'twoStarMaxAttempts': twoStarMaxAttempts,
        'threeStarMaxFailures': threeStarMaxFailures,
        'twoStarMaxFailures': twoStarMaxFailures,
      };

  factory SuccessCriteria.fromJson(Map<String, dynamic> j) => SuccessCriteria(
        requireSuccessSignal: j['requireSuccessSignal'] as bool? ?? true,
        threeStarMaxAttempts: (j['threeStarMaxAttempts'] as num?)?.toInt() ?? 1,
        twoStarMaxAttempts: (j['twoStarMaxAttempts'] as num?)?.toInt() ?? 2,
        threeStarMaxFailures:
            (j['threeStarMaxFailures'] as num?)?.toInt() ?? 0,
        twoStarMaxFailures: (j['twoStarMaxFailures'] as num?)?.toInt() ?? 1,
      );
}

/// Copy for the setup beat (frames the problem before interaction).
class SetupCopy {
  const SetupCopy({
    required this.elderLine,
    required this.prompt,
    this.mythLine = '',
    this.hintLine = '',
  });

  /// What the Elder says to set the scene.
  final String elderLine;

  /// The call-to-action prompt for the interaction.
  final String prompt;

  /// The current (wrong) belief being challenged.
  final String mythLine;

  /// An optional nudge.
  final String hintLine;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'elderLine': elderLine,
        'prompt': prompt,
        'mythLine': mythLine,
        'hintLine': hintLine,
      };

  factory SetupCopy.fromJson(Map<String, dynamic> j) => SetupCopy(
        elderLine: j['elderLine'] as String? ?? '',
        prompt: j['prompt'] as String? ?? '',
        mythLine: j['mythLine'] as String? ?? '',
        hintLine: j['hintLine'] as String? ?? '',
      );
}

/// Copy for the discover + it-clicks beats (the payoff).
class ClickCopy {
  const ClickCopy({
    required this.revelation,
    required this.science,
    this.celebrationLine = '',
  });

  /// The "ohh!" moment line.
  final String revelation;

  /// The age-appropriate science explanation.
  final String science;

  /// Optional celebratory line on apply.
  final String celebrationLine;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'revelation': revelation,
        'science': science,
        'celebrationLine': celebrationLine,
      };

  factory ClickCopy.fromJson(Map<String, dynamic> j) => ClickCopy(
        revelation: j['revelation'] as String? ?? '',
        science: j['science'] as String? ?? '',
        celebrationLine: j['celebrationLine'] as String? ?? '',
      );
}

/// The full declarative definition of one activity. Built by a leaf, consumed by
/// the BeatController (rules/criteria/copy) and the reducer (unlocks/upgrade).
class EmberActivity {
  const EmberActivity({
    required this.id,
    required this.conceptId,
    required this.title,
    this.prerequisites = const <Prerequisite>[],
    required this.learningObjective,
    required this.setupCopy,
    required this.interactionRules,
    this.successCriteria = const SuccessCriteria(),
    required this.clickCopy,
    this.unlocks = const <ApplyEffect>[],
    this.codexEntryIds = const <String>[],
    this.modelUpgrade,
  });

  /// Stable activity id.
  final String id;

  /// The concept this activity teaches.
  final ConceptId conceptId;

  /// Display title.
  final String title;

  /// Gates required before it can start.
  final List<Prerequisite> prerequisites;

  /// One-line learning objective (designer/teacher facing).
  final String learningObjective;

  /// Setup-beat copy.
  final SetupCopy setupCopy;

  /// Interaction rules the BeatController scores against.
  final InteractionRules interactionRules;

  /// Quality grading.
  final SuccessCriteria successCriteria;

  /// Discover/it-clicks copy.
  final ClickCopy clickCopy;

  /// Effects applied on completion.
  final List<ApplyEffect> unlocks;

  /// Codex entries granted on completion.
  final List<String> codexEntryIds;

  /// The model upgrade landed on completion, if any.
  final ModelUpgrade? modelUpgrade;

  EmberActivity copyWith({
    String? id,
    ConceptId? conceptId,
    String? title,
    List<Prerequisite>? prerequisites,
    String? learningObjective,
    SetupCopy? setupCopy,
    InteractionRules? interactionRules,
    SuccessCriteria? successCriteria,
    ClickCopy? clickCopy,
    List<ApplyEffect>? unlocks,
    List<String>? codexEntryIds,
    ModelUpgrade? modelUpgrade,
  }) {
    return EmberActivity(
      id: id ?? this.id,
      conceptId: conceptId ?? this.conceptId,
      title: title ?? this.title,
      prerequisites: prerequisites ?? this.prerequisites,
      learningObjective: learningObjective ?? this.learningObjective,
      setupCopy: setupCopy ?? this.setupCopy,
      interactionRules: interactionRules ?? this.interactionRules,
      successCriteria: successCriteria ?? this.successCriteria,
      clickCopy: clickCopy ?? this.clickCopy,
      unlocks: unlocks ?? this.unlocks,
      codexEntryIds: codexEntryIds ?? this.codexEntryIds,
      modelUpgrade: modelUpgrade ?? this.modelUpgrade,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'conceptId': conceptId.name,
        'title': title,
        'prerequisites': <Map<String, dynamic>>[
          for (final Prerequisite p in prerequisites) p.toJson(),
        ],
        'learningObjective': learningObjective,
        'setupCopy': setupCopy.toJson(),
        'interactionRules': interactionRules.toJson(),
        'successCriteria': successCriteria.toJson(),
        'clickCopy': clickCopy.toJson(),
        'unlocks': <Map<String, Object?>>[
          for (final ApplyEffect e in unlocks) e.toJson(),
        ],
        'codexEntryIds': List<String>.of(codexEntryIds),
        if (modelUpgrade != null) 'modelUpgrade': modelUpgrade!.toJson(),
      };

  factory EmberActivity.fromJson(Map<String, dynamic> j) => EmberActivity(
        id: j['id'] as String? ?? '',
        conceptId: conceptIdFromName(j['conceptId']),
        title: j['title'] as String? ?? '',
        prerequisites: <Prerequisite>[
          for (final dynamic e
              in (j['prerequisites'] as List?) ?? const <dynamic>[])
            Prerequisite.fromJson((e as Map).cast<String, dynamic>()),
        ],
        learningObjective: j['learningObjective'] as String? ?? '',
        setupCopy: SetupCopy.fromJson(
            (j['setupCopy'] as Map?)?.cast<String, dynamic>() ??
                const <String, dynamic>{}),
        interactionRules: InteractionRules.fromJson(
            (j['interactionRules'] as Map?)?.cast<String, dynamic>() ??
                const <String, dynamic>{}),
        successCriteria: SuccessCriteria.fromJson(
            (j['successCriteria'] as Map?)?.cast<String, dynamic>() ??
                const <String, dynamic>{}),
        clickCopy: ClickCopy.fromJson(
            (j['clickCopy'] as Map?)?.cast<String, dynamic>() ??
                const <String, dynamic>{}),
        unlocks: <ApplyEffect>[
          for (final dynamic e in (j['unlocks'] as List?) ?? const <dynamic>[])
            ApplyEffect.fromJson((e as Map).cast<String, dynamic>()),
        ],
        codexEntryIds: <String>[
          for (final dynamic e
              in (j['codexEntryIds'] as List?) ?? const <dynamic>[])
            e as String,
        ],
        modelUpgrade: j['modelUpgrade'] is Map
            ? ModelUpgrade.fromJson(
                (j['modelUpgrade'] as Map).cast<String, dynamic>())
            : null,
      );
}
