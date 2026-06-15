// Ember — activity/activity_result.dart
//
// The frozen record of one activity run, produced by BeatController.buildResult()
// and consumed by ApplyReducer.apply(state, result). It carries the effects the
// activity declared (so the reducer is pure and the run can be replayed offline),
// the knowledge flags it set, the grade, and an optional placement hint for the
// world (e.g. "drop a built hearth at the village site after the fire activity").

import '../core/enums.dart';
import '../core/geometry.dart';
import 'apply_effect.dart';

/// Optional instruction to materialise a placeable in the world after an activity
/// (e.g. the fire activity hands back a built hearth at the chosen tile).
class PlaceHint {
  const PlaceHint({
    required this.type,
    required this.coord,
    this.tier = 1,
    this.built = true,
    this.ext = const <String, dynamic>{},
  });

  final PlaceableType type;
  final GridCoord coord;
  final int tier;

  /// Whether to drop it already built (true) or as a ghost to build (false).
  final bool built;

  /// Seed payload for the new placeable's ext bag.
  final Map<String, dynamic> ext;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.name,
        'coord': coord.toJson(),
        'tier': tier,
        'built': built,
        'ext': ext,
      };

  factory PlaceHint.fromJson(Map<String, dynamic> j) => PlaceHint(
        type: placeableTypeFromName(j['type']),
        coord: GridCoord.fromJson((j['coord'] as Map).cast<String, dynamic>()),
        tier: (j['tier'] as num?)?.toInt() ?? 1,
        built: j['built'] as bool? ?? true,
        ext: (j['ext'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      );

  @override
  bool operator ==(Object other) =>
      other is PlaceHint &&
      other.type == type &&
      other.coord == coord &&
      other.tier == tier &&
      other.built == built;

  @override
  int get hashCode => Object.hash(type, coord, tier, built);
}

/// The immutable outcome of running one activity.
class ActivityResult {
  const ActivityResult({
    required this.activityId,
    required this.conceptId,
    required this.completed,
    this.qualityStars = 0,
    this.attempts = 0,
    this.failuresSeen = const <String>[],
    this.effects = const <ApplyEffect>[],
    this.knowledgeFlags = const <String>[],
    this.placeHint,
  });

  final String activityId;
  final ConceptId conceptId;

  /// Whether the player satisfied the success criteria.
  final bool completed;

  /// 0..3 stars.
  final int qualityStars;

  /// Number of attempts the player made.
  final int attempts;

  /// Distinct failure ids the player saw.
  final List<String> failuresSeen;

  /// The effects to apply (from the activity's unlocks + upgrade + codex).
  final List<ApplyEffect> effects;

  /// Knowledge flags explicitly set by this run (beyond effect-driven ones).
  final List<String> knowledgeFlags;

  /// Optional placement hint for the world.
  final PlaceHint? placeHint;

  ActivityResult copyWith({
    String? activityId,
    ConceptId? conceptId,
    bool? completed,
    int? qualityStars,
    int? attempts,
    List<String>? failuresSeen,
    List<ApplyEffect>? effects,
    List<String>? knowledgeFlags,
    PlaceHint? placeHint,
  }) {
    return ActivityResult(
      activityId: activityId ?? this.activityId,
      conceptId: conceptId ?? this.conceptId,
      completed: completed ?? this.completed,
      qualityStars: qualityStars ?? this.qualityStars,
      attempts: attempts ?? this.attempts,
      failuresSeen: failuresSeen ?? this.failuresSeen,
      effects: effects ?? this.effects,
      knowledgeFlags: knowledgeFlags ?? this.knowledgeFlags,
      placeHint: placeHint ?? this.placeHint,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'activityId': activityId,
        'conceptId': conceptId.name,
        'completed': completed,
        'qualityStars': qualityStars,
        'attempts': attempts,
        'failuresSeen': List<String>.of(failuresSeen)..sort(),
        'effects': <Map<String, Object?>>[
          for (final ApplyEffect e in effects) e.toJson(),
        ],
        'knowledgeFlags': List<String>.of(knowledgeFlags)..sort(),
        if (placeHint != null) 'placeHint': placeHint!.toJson(),
      };

  factory ActivityResult.fromJson(Map<String, dynamic> j) => ActivityResult(
        activityId: j['activityId'] as String? ?? '',
        conceptId: conceptIdFromName(j['conceptId']),
        completed: j['completed'] as bool? ?? false,
        qualityStars: (j['qualityStars'] as num?)?.toInt() ?? 0,
        attempts: (j['attempts'] as num?)?.toInt() ?? 0,
        failuresSeen: <String>[
          for (final dynamic e
              in (j['failuresSeen'] as List?) ?? const <dynamic>[])
            e as String,
        ],
        effects: <ApplyEffect>[
          for (final dynamic e in (j['effects'] as List?) ?? const <dynamic>[])
            ApplyEffect.fromJson((e as Map).cast<String, dynamic>()),
        ],
        knowledgeFlags: <String>[
          for (final dynamic e
              in (j['knowledgeFlags'] as List?) ?? const <dynamic>[])
            e as String,
        ],
        placeHint: j['placeHint'] is Map
            ? PlaceHint.fromJson((j['placeHint'] as Map).cast<String, dynamic>())
            : null,
      );
}
