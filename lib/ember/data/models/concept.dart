// Ember — data/models/concept.dart
//
// A tech-tree node: a concept the player can unlock + complete. Prerequisites
// reference other ConceptIds. Pure value object.

import '../../core/enums.dart';

class Concept {
  const Concept({
    required this.id,
    required this.name,
    this.prerequisites = const <ConceptId>[],
    this.unlocked = false,
    this.completed = false,
  });

  final ConceptId id;
  final String name;

  /// Concepts that must be completed before this one unlocks.
  final List<ConceptId> prerequisites;

  /// Whether the player can access this concept's activity yet.
  final bool unlocked;

  /// Whether the player has completed this concept's activity.
  final bool completed;

  Concept copyWith({
    ConceptId? id,
    String? name,
    List<ConceptId>? prerequisites,
    bool? unlocked,
    bool? completed,
  }) {
    return Concept(
      id: id ?? this.id,
      name: name ?? this.name,
      prerequisites: prerequisites ?? this.prerequisites,
      unlocked: unlocked ?? this.unlocked,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id.name,
        'name': name,
        'prerequisites': <String>[for (final ConceptId p in prerequisites) p.name],
        'unlocked': unlocked,
        'completed': completed,
      };

  factory Concept.fromJson(Map<String, dynamic> j) => Concept(
        id: conceptIdFromName(j['id']),
        name: j['name'] as String? ?? '',
        prerequisites: <ConceptId>[
          for (final dynamic e
              in (j['prerequisites'] as List?) ?? const <dynamic>[])
            conceptIdFromName(e),
        ],
        unlocked: j['unlocked'] as bool? ?? false,
        completed: j['completed'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      other is Concept &&
      other.id == id &&
      other.name == name &&
      _listEq(other.prerequisites, prerequisites) &&
      other.unlocked == unlocked &&
      other.completed == completed;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        Object.hashAll(prerequisites),
        unlocked,
        completed,
      );
}

bool _listEq(List<ConceptId> a, List<ConceptId> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
