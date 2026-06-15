// Ember — activity/apply_effect.dart
//
// The CLOSED set of effects an activity can apply to the world on success. The
// reducer (apply_reducer.dart) switches over this sealed hierarchy exhaustively —
// add a variant here and the analyzer forces every reducer site to handle it. A
// leaf never edits the reducer; it only ever emits these effects from its activity
// definition. Every variant round-trips to/from JSON (effects are stored on the
// ActivityResult and may be replayed offline).

import '../core/enums.dart';
import '../data/models/resource_cost.dart';

/// One declarative change to the world produced by completing an activity.
sealed class ApplyEffect {
  const ApplyEffect();

  /// Stable discriminator stored in JSON.
  String get kind;

  Map<String, Object?> toJson();

  /// Rebuilds the concrete effect from its JSON map (defensive; unknown kinds
  /// fall back to a no-op [SetWorldFlag] toggle that is harmless).
  factory ApplyEffect.fromJson(Map<String, dynamic> j) {
    final String k = j['kind'] as String? ?? '';
    switch (k) {
      case 'unlockPlaceable':
        return UnlockPlaceable(placeableTypeFromName(j['type']));
      case 'setKnowledgeFlag':
        return SetKnowledgeFlag(
          j['flag'] as String? ?? '',
          value: j['value'] as bool? ?? true,
        );
      case 'markConceptDone':
        return MarkConceptDone(conceptIdFromName(j['concept']));
      case 'grantCodexEntry':
        return GrantCodexEntry(j['entryId'] as String? ?? '');
      case 'upgradeModel':
        return UpgradeModel(conceptIdFromName(j['concept']));
      case 'grantResources':
        return GrantResources(
          ResourceCost.fromJson(
            (j['resources'] as Map?)?.cast<String, dynamic>() ??
                const <String, dynamic>{},
          ),
        );
      case 'setWorldFlag':
        return SetWorldFlag(
          j['flag'] as String? ?? '',
          value: j['value'] as bool? ?? true,
        );
      case 'enableActivity':
        return EnableActivity(j['activityId'] as String? ?? '');
      case 'raisePopulationCap':
        return RaisePopulationCap((j['by'] as num?)?.toInt() ?? 0);
      default:
        // Unknown legacy kind: harmless no-op flag.
        return const SetWorldFlag('unknown.effect', value: false);
    }
  }
}

/// Unlock a placeable type in the build menu.
class UnlockPlaceable extends ApplyEffect {
  const UnlockPlaceable(this.type);
  final PlaceableType type;

  @override
  String get kind => 'unlockPlaceable';

  @override
  Map<String, Object?> toJson() =>
      <String, Object?>{'kind': kind, 'type': type.name};

  @override
  bool operator ==(Object other) =>
      other is UnlockPlaceable && other.type == type;
  @override
  int get hashCode => Object.hash(kind, type);
}

/// Set a PlayerKnowledge flag.
class SetKnowledgeFlag extends ApplyEffect {
  const SetKnowledgeFlag(this.flag, {this.value = true});
  final String flag;
  final bool value;

  @override
  String get kind => 'setKnowledgeFlag';

  @override
  Map<String, Object?> toJson() =>
      <String, Object?>{'kind': kind, 'flag': flag, 'value': value};

  @override
  bool operator ==(Object other) =>
      other is SetKnowledgeFlag && other.flag == flag && other.value == value;
  @override
  int get hashCode => Object.hash(kind, flag, value);
}

/// Mark a concept completed (and cascade-unlock its dependents).
class MarkConceptDone extends ApplyEffect {
  const MarkConceptDone(this.concept);
  final ConceptId concept;

  @override
  String get kind => 'markConceptDone';

  @override
  Map<String, Object?> toJson() =>
      <String, Object?>{'kind': kind, 'concept': concept.name};

  @override
  bool operator ==(Object other) =>
      other is MarkConceptDone && other.concept == concept;
  @override
  int get hashCode => Object.hash(kind, concept);
}

/// Unlock a codex entry by id.
class GrantCodexEntry extends ApplyEffect {
  const GrantCodexEntry(this.entryId);
  final String entryId;

  @override
  String get kind => 'grantCodexEntry';

  @override
  Map<String, Object?> toJson() =>
      <String, Object?>{'kind': kind, 'entryId': entryId};

  @override
  bool operator ==(Object other) =>
      other is GrantCodexEntry && other.entryId == entryId;
  @override
  int get hashCode => Object.hash(kind, entryId);
}

/// Apply a concept's ModelUpgrade (myth -> evidence belief shift).
class UpgradeModel extends ApplyEffect {
  const UpgradeModel(this.concept);
  final ConceptId concept;

  @override
  String get kind => 'upgradeModel';

  @override
  Map<String, Object?> toJson() =>
      <String, Object?>{'kind': kind, 'concept': concept.name};

  @override
  bool operator ==(Object other) =>
      other is UpgradeModel && other.concept == concept;
  @override
  int get hashCode => Object.hash(kind, concept);
}

/// Grant a resource bundle to the stockpile.
class GrantResources extends ApplyEffect {
  const GrantResources(this.resources);
  final ResourceCost resources;

  @override
  String get kind => 'grantResources';

  @override
  Map<String, Object?> toJson() =>
      <String, Object?>{'kind': kind, 'resources': resources.toJson()};

  @override
  bool operator ==(Object other) =>
      other is GrantResources && other.resources == resources;
  @override
  int get hashCode => Object.hash(kind, resources);
}

/// Set an arbitrary world flag in PlayerKnowledge's flag space (namespaced
/// "world.*" by convention, but stored in the same flag bag).
class SetWorldFlag extends ApplyEffect {
  const SetWorldFlag(this.flag, {this.value = true});
  final String flag;
  final bool value;

  @override
  String get kind => 'setWorldFlag';

  @override
  Map<String, Object?> toJson() =>
      <String, Object?>{'kind': kind, 'flag': flag, 'value': value};

  @override
  bool operator ==(Object other) =>
      other is SetWorldFlag && other.flag == flag && other.value == value;
  @override
  int get hashCode => Object.hash(kind, flag, value);
}

/// Enable another activity by id (e.g. a follow-up activity).
class EnableActivity extends ApplyEffect {
  const EnableActivity(this.activityId);
  final String activityId;

  @override
  String get kind => 'enableActivity';

  @override
  Map<String, Object?> toJson() =>
      <String, Object?>{'kind': kind, 'activityId': activityId};

  @override
  bool operator ==(Object other) =>
      other is EnableActivity && other.activityId == activityId;
  @override
  int get hashCode => Object.hash(kind, activityId);
}

/// Raise the village population cap by [by].
class RaisePopulationCap extends ApplyEffect {
  const RaisePopulationCap(this.by);
  final int by;

  @override
  String get kind => 'raisePopulationCap';

  @override
  Map<String, Object?> toJson() =>
      <String, Object?>{'kind': kind, 'by': by};

  @override
  bool operator ==(Object other) =>
      other is RaisePopulationCap && other.by == by;
  @override
  int get hashCode => Object.hash(kind, by);
}
