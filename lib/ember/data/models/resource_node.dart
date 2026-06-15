// Ember — data/models/resource_node.dart
//
// A gatherable node on the map (forest tree, rock, berry bush). Pure value
// object. `remaining` depletes on gather; `regrowRate` (units/sec) lets the sim
// refill food nodes deterministically.

import '../../core/constants.dart';
import '../../core/enums.dart';
import '../../core/geometry.dart';
import '../../core/ids.dart';

class ResourceNode {
  const ResourceNode({
    required this.id,
    required this.type,
    required this.coord,
    required this.remaining,
    required this.baseYield,
    this.regrowRate = 0.0,
    this.capacity,
  });

  final EntityId id;
  final ResourceType type;
  final GridCoord coord;

  /// Units left in the node.
  final double remaining;

  /// Units granted per gather action (before tool multiplier).
  final int baseYield;

  /// Regrowth in units/sec (food > 0; wood/stone usually 0).
  final double regrowRate;

  /// Max remaining the node can regrow back to. Defaults to its initial
  /// remaining when not specified (captured at construction by the seed).
  final double? capacity;

  bool get isDepleted => remaining <= 0;
  double get effectiveCapacity => capacity ?? remaining;

  ResourceNode copyWith({
    EntityId? id,
    ResourceType? type,
    GridCoord? coord,
    double? remaining,
    int? baseYield,
    double? regrowRate,
    double? capacity,
  }) {
    return ResourceNode(
      id: id ?? this.id,
      type: type ?? this.type,
      coord: coord ?? this.coord,
      remaining: remaining ?? this.remaining,
      baseYield: baseYield ?? this.baseYield,
      regrowRate: regrowRate ?? this.regrowRate,
      capacity: capacity ?? this.capacity,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type.name,
        'coord': coord.toJson(),
        'remaining': remaining,
        'baseYield': baseYield,
        'regrowRate': regrowRate,
        if (capacity != null) 'capacity': capacity,
      };

  factory ResourceNode.fromJson(Map<String, dynamic> j) => ResourceNode(
        id: j['id'] as String? ?? '',
        type: resourceTypeFromName(j['type']),
        coord: GridCoord.fromJson(
            (j['coord'] as Map).cast<String, dynamic>()),
        remaining: (j['remaining'] as num?)?.toDouble() ?? 0.0,
        baseYield: (j['baseYield'] as num?)?.toInt() ??
            EmberConstants.baseGatherYield,
        regrowRate: (j['regrowRate'] as num?)?.toDouble() ?? 0.0,
        capacity: (j['capacity'] as num?)?.toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      other is ResourceNode &&
      other.id == id &&
      other.type == type &&
      other.coord == coord &&
      other.remaining == remaining &&
      other.baseYield == baseYield &&
      other.regrowRate == regrowRate &&
      other.capacity == capacity;

  @override
  int get hashCode => Object.hash(
        id,
        type,
        coord,
        remaining,
        baseYield,
        regrowRate,
        capacity,
      );
}
