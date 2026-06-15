// Ember — data/models/activity_progress.dart
//
// Tracks a player's run through one concept's activity: attempts, completion,
// star quality, whether its model upgrade landed, and which failure messages
// they've seen (so we don't repeat the same hint). Pure value object.

import '../../core/enums.dart';

class ActivityProgress {
  ActivityProgress({
    required this.conceptId,
    this.attempts = 0,
    this.completed = false,
    this.qualityStars = 0,
    this.modelUpgraded = false,
    Set<String>? failuresSeen,
  }) : failuresSeen = failuresSeen ?? <String>{};

  final ConceptId conceptId;
  final int attempts;
  final bool completed;

  /// 0..3 stars representing how cleanly the player succeeded.
  final int qualityStars;

  /// Whether the activity's ModelUpgrade has been applied.
  final bool modelUpgraded;

  /// Distinct failure ids/messages the player has already been shown.
  final Set<String> failuresSeen;

  ActivityProgress copyWith({
    ConceptId? conceptId,
    int? attempts,
    bool? completed,
    int? qualityStars,
    bool? modelUpgraded,
    Set<String>? failuresSeen,
  }) {
    return ActivityProgress(
      conceptId: conceptId ?? this.conceptId,
      attempts: attempts ?? this.attempts,
      completed: completed ?? this.completed,
      qualityStars: qualityStars ?? this.qualityStars,
      modelUpgraded: modelUpgraded ?? this.modelUpgraded,
      failuresSeen: failuresSeen ?? Set<String>.of(this.failuresSeen),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'conceptId': conceptId.name,
        'attempts': attempts,
        'completed': completed,
        'qualityStars': qualityStars,
        'modelUpgraded': modelUpgraded,
        // Sorted for byte-stable round-trips.
        'failuresSeen': failuresSeen.toList()..sort(),
      };

  factory ActivityProgress.fromJson(Map<String, dynamic> j) => ActivityProgress(
        conceptId: conceptIdFromName(j['conceptId']),
        attempts: (j['attempts'] as num?)?.toInt() ?? 0,
        completed: j['completed'] as bool? ?? false,
        qualityStars: (j['qualityStars'] as num?)?.toInt() ?? 0,
        modelUpgraded: j['modelUpgraded'] as bool? ?? false,
        failuresSeen: <String>{
          for (final dynamic e
              in (j['failuresSeen'] as List?) ?? const <dynamic>[])
            e as String,
        },
      );

  @override
  bool operator ==(Object other) =>
      other is ActivityProgress &&
      other.conceptId == conceptId &&
      other.attempts == attempts &&
      other.completed == completed &&
      other.qualityStars == qualityStars &&
      other.modelUpgraded == modelUpgraded &&
      _setEq(other.failuresSeen, failuresSeen);

  @override
  int get hashCode => Object.hash(
        conceptId,
        attempts,
        completed,
        qualityStars,
        modelUpgraded,
        Object.hashAllUnordered(failuresSeen),
      );
}

bool _setEq(Set<String> a, Set<String> b) {
  if (a.length != b.length) return false;
  return a.containsAll(b);
}
