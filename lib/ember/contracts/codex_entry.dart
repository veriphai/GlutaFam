// Ember — contracts/codex_entry.dart
//
// CodexEntry: a discoverable knowledge card (the "myth -> evidence -> science"
// payoff). ModelUpgrade: the belief shift an activity lands ("fire is a spirit"
// -> "fire is a chemical reaction needing fuel/air"). Both are declared by a leaf
// via ConceptModule; the reducer GRANTS codex entries and APPLIES model upgrades.

import '../core/enums.dart';

/// A single codex / knowledge-card entry. Pure value object; `unlocked` flips
/// when the player discovers it (the reducer rewrites the entry).
class CodexEntry {
  const CodexEntry({
    required this.id,
    required this.concept,
    required this.title,
    required this.discoveryStory,
    required this.science,
    required this.history,
    this.unlocked = false,
  });

  final String id;
  final ConceptId concept;

  /// Card title.
  final String title;

  /// The in-world "how the tribe discovered it" narrative.
  final String discoveryStory;

  /// The real science explanation (age-appropriate).
  final String science;

  /// The real-history note.
  final String history;

  /// Whether the player has unlocked this entry.
  final bool unlocked;

  CodexEntry copyWith({
    String? id,
    ConceptId? concept,
    String? title,
    String? discoveryStory,
    String? science,
    String? history,
    bool? unlocked,
  }) {
    return CodexEntry(
      id: id ?? this.id,
      concept: concept ?? this.concept,
      title: title ?? this.title,
      discoveryStory: discoveryStory ?? this.discoveryStory,
      science: science ?? this.science,
      history: history ?? this.history,
      unlocked: unlocked ?? this.unlocked,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'concept': concept.name,
        'title': title,
        'discoveryStory': discoveryStory,
        'science': science,
        'history': history,
        'unlocked': unlocked,
      };

  factory CodexEntry.fromJson(Map<String, dynamic> j) => CodexEntry(
        id: j['id'] as String? ?? '',
        concept: conceptIdFromName(j['concept']),
        title: j['title'] as String? ?? '',
        discoveryStory: j['discoveryStory'] as String? ?? '',
        science: j['science'] as String? ?? '',
        history: j['history'] as String? ?? '',
        unlocked: j['unlocked'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      other is CodexEntry &&
      other.id == id &&
      other.concept == concept &&
      other.title == title &&
      other.discoveryStory == discoveryStory &&
      other.science == science &&
      other.history == history &&
      other.unlocked == unlocked;

  @override
  int get hashCode => Object.hash(
        id,
        concept,
        title,
        discoveryStory,
        science,
        history,
        unlocked,
      );
}

/// The belief shift an activity produces: from a myth to an evidence-based model.
/// [flag] is the PlayerKnowledge key set true when [upgraded]. Declared by a leaf;
/// the reducer applies it (sets the flag + marks upgraded).
class ModelUpgrade {
  const ModelUpgrade({
    required this.concept,
    required this.mythBelief,
    required this.evidenceBelief,
    required this.flag,
    this.upgraded = false,
  });

  final ConceptId concept;

  /// What the tribe believed before (the misconception).
  final String mythBelief;

  /// What they believe after seeing the evidence (the correct model).
  final String evidenceBelief;

  /// The PlayerKnowledge flag set true once this upgrade lands.
  final String flag;

  /// Whether this upgrade has been applied.
  final bool upgraded;

  ModelUpgrade copyWith({
    ConceptId? concept,
    String? mythBelief,
    String? evidenceBelief,
    String? flag,
    bool? upgraded,
  }) {
    return ModelUpgrade(
      concept: concept ?? this.concept,
      mythBelief: mythBelief ?? this.mythBelief,
      evidenceBelief: evidenceBelief ?? this.evidenceBelief,
      flag: flag ?? this.flag,
      upgraded: upgraded ?? this.upgraded,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'concept': concept.name,
        'mythBelief': mythBelief,
        'evidenceBelief': evidenceBelief,
        'flag': flag,
        'upgraded': upgraded,
      };

  factory ModelUpgrade.fromJson(Map<String, dynamic> j) => ModelUpgrade(
        concept: conceptIdFromName(j['concept']),
        mythBelief: j['mythBelief'] as String? ?? '',
        evidenceBelief: j['evidenceBelief'] as String? ?? '',
        flag: j['flag'] as String? ?? '',
        upgraded: j['upgraded'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      other is ModelUpgrade &&
      other.concept == concept &&
      other.mythBelief == mythBelief &&
      other.evidenceBelief == evidenceBelief &&
      other.flag == flag &&
      other.upgraded == upgraded;

  @override
  int get hashCode =>
      Object.hash(concept, mythBelief, evidenceBelief, flag, upgraded);
}
