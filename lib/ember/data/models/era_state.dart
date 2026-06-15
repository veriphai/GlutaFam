// Ember — data/models/era_state.dart
//
// Tracks which era the village is in + which milestones it has met. Pure value
// object. Milestones are stable string ids (e.g. "fire_tamed", "flood_survived").

class EraState {
  EraState({
    this.currentEraId = 'stone_age',
    List<String>? milestonesMet,
  }) : milestonesMet = milestonesMet ?? <String>[];

  final String currentEraId;
  final List<String> milestonesMet;

  bool hasMilestone(String id) => milestonesMet.contains(id);

  /// Returns a NEW EraState with [id] recorded (no duplicates).
  EraState withMilestone(String id) {
    if (milestonesMet.contains(id)) return this;
    return copyWith(milestonesMet: <String>[...milestonesMet, id]);
  }

  EraState copyWith({
    String? currentEraId,
    List<String>? milestonesMet,
  }) {
    return EraState(
      currentEraId: currentEraId ?? this.currentEraId,
      milestonesMet: milestonesMet ?? List<String>.of(this.milestonesMet),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'currentEraId': currentEraId,
        // Sorted for byte-stable round-trips.
        'milestonesMet': List<String>.of(milestonesMet)..sort(),
      };

  factory EraState.fromJson(Map<String, dynamic> j) => EraState(
        currentEraId: j['currentEraId'] as String? ?? 'stone_age',
        milestonesMet: <String>[
          for (final dynamic e
              in (j['milestonesMet'] as List?) ?? const <dynamic>[])
            e as String,
        ],
      );

  @override
  bool operator ==(Object other) =>
      other is EraState &&
      other.currentEraId == currentEraId &&
      _setEq(other.milestonesMet, milestonesMet);

  @override
  int get hashCode =>
      Object.hash(currentEraId, Object.hashAllUnordered(milestonesMet));
}

bool _setEq(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  return a.toSet().containsAll(b);
}
