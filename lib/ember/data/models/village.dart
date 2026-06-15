// Ember — data/models/village.dart
//
// The village meta: who/where it is, its caps and comfort. Pure value object.

import '../../core/geometry.dart';
import '../../core/ids.dart';

class Village {
  const Village({
    required this.id,
    required this.eraId,
    required this.populationCap,
    required this.populationCurrent,
    required this.comfortIndex,
    required this.unlockedRegions,
    required this.siteTile,
  });

  final EntityId id;
  final String eraId;

  /// Max population the village can sustain (shelter PUSHes this up).
  final int populationCap;

  /// Current population.
  final int populationCurrent;

  /// 0..1 aggregate comfort (warmth + shelter + safety + food).
  final double comfortIndex;

  /// Region ids the player has unlocked.
  final List<int> unlockedRegions;

  /// The central tile the village is anchored on (camera home / Elder spot).
  final GridCoord siteTile;

  Village copyWith({
    EntityId? id,
    String? eraId,
    int? populationCap,
    int? populationCurrent,
    double? comfortIndex,
    List<int>? unlockedRegions,
    GridCoord? siteTile,
  }) {
    return Village(
      id: id ?? this.id,
      eraId: eraId ?? this.eraId,
      populationCap: populationCap ?? this.populationCap,
      populationCurrent: populationCurrent ?? this.populationCurrent,
      comfortIndex: comfortIndex ?? this.comfortIndex,
      unlockedRegions: unlockedRegions ?? this.unlockedRegions,
      siteTile: siteTile ?? this.siteTile,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'eraId': eraId,
        'populationCap': populationCap,
        'populationCurrent': populationCurrent,
        'comfortIndex': comfortIndex,
        'unlockedRegions': unlockedRegions,
        'siteTile': siteTile.toJson(),
      };

  factory Village.fromJson(Map<String, dynamic> j) => Village(
        id: j['id'] as String? ?? 'village',
        eraId: j['eraId'] as String? ?? 'stone_age',
        populationCap: (j['populationCap'] as num?)?.toInt() ?? 0,
        populationCurrent: (j['populationCurrent'] as num?)?.toInt() ?? 0,
        comfortIndex: (j['comfortIndex'] as num?)?.toDouble() ?? 0.0,
        unlockedRegions: <int>[
          for (final dynamic e in (j['unlockedRegions'] as List?) ??
              const <dynamic>[])
            (e as num).toInt(),
        ],
        siteTile: GridCoord.fromJson(
            (j['siteTile'] as Map).cast<String, dynamic>()),
      );

  @override
  bool operator ==(Object other) =>
      other is Village &&
      other.id == id &&
      other.eraId == eraId &&
      other.populationCap == populationCap &&
      other.populationCurrent == populationCurrent &&
      other.comfortIndex == comfortIndex &&
      _listEq(other.unlockedRegions, unlockedRegions) &&
      other.siteTile == siteTile;

  @override
  int get hashCode => Object.hash(
        id,
        eraId,
        populationCap,
        populationCurrent,
        comfortIndex,
        Object.hashAll(unlockedRegions),
        siteTile,
      );
}

bool _listEq(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
