// Ember — data/models/placeable.dart
//
// THE dir-lock linchpin. A generic placed-object document. Every concept leaf
// stores its bespoke state inside the untyped `ext` bag and reads it back via a
// typed view (e.g. FireObject.fromPlaceable). LEAVES NEVER EDIT THIS FILE — the
// engine, sim, and renderer only ever see this generic shape.

import '../../core/enums.dart';
import '../../core/geometry.dart';
import '../../core/ids.dart';

class Placeable {
  Placeable({
    required this.id,
    required this.type,
    this.tier = 1,
    required this.coord,
    this.rotation = 0,
    this.state = PlaceableState.ghost,
    this.buildProgress = 0.0,
    Map<String, dynamic>? ext,
  }) : ext = ext ?? <String, dynamic>{};

  final EntityId id;
  final PlaceableType type;

  /// Upgrade tier (1 = base). Leaf model upgrades bump this.
  int tier;

  /// Grid position (top-left anchor of the footprint).
  GridCoord coord;

  /// Rotation in quarter-turns (0..3).
  int rotation;

  PlaceableState state;

  /// 0..1 construction progress; 1.0 once `built`.
  double buildProgress;

  /// Untyped per-leaf payload. The ONLY place a concept stores custom state.
  Map<String, dynamic> ext;

  bool get isBuilt => state == PlaceableState.built;
  bool get isActive =>
      state == PlaceableState.built || state == PlaceableState.damaged;

  Placeable copyWith({
    EntityId? id,
    PlaceableType? type,
    int? tier,
    GridCoord? coord,
    int? rotation,
    PlaceableState? state,
    double? buildProgress,
    Map<String, dynamic>? ext,
  }) {
    return Placeable(
      id: id ?? this.id,
      type: type ?? this.type,
      tier: tier ?? this.tier,
      coord: coord ?? this.coord,
      rotation: rotation ?? this.rotation,
      state: state ?? this.state,
      buildProgress: buildProgress ?? this.buildProgress,
      // Deep-ish copy: clone the map so callers can't alias internal state.
      ext: ext ?? Map<String, dynamic>.of(this.ext),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type.name,
        'tier': tier,
        'coord': coord.toJson(),
        'rotation': rotation,
        'state': state.name,
        'buildProgress': buildProgress,
        'ext': ext,
      };

  factory Placeable.fromJson(Map<String, dynamic> j) => Placeable(
        id: j['id'] as String? ?? '',
        type: placeableTypeFromName(j['type']),
        tier: (j['tier'] as num?)?.toInt() ?? 1,
        coord: GridCoord.fromJson(
            (j['coord'] as Map).cast<String, dynamic>()),
        rotation: (j['rotation'] as num?)?.toInt() ?? 0,
        state: placeableStateFromName(j['state']),
        buildProgress: (j['buildProgress'] as num?)?.toDouble() ?? 0.0,
        ext: (j['ext'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
      );

  @override
  bool operator ==(Object other) =>
      other is Placeable &&
      other.id == id &&
      other.type == type &&
      other.tier == tier &&
      other.coord == coord &&
      other.rotation == rotation &&
      other.state == state &&
      other.buildProgress == buildProgress &&
      _mapEq(other.ext, ext);

  @override
  int get hashCode => Object.hash(
        id,
        type,
        tier,
        coord,
        rotation,
        state,
        buildProgress,
        _mapHash(ext),
      );
}

bool _mapEq(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (a.length != b.length) return false;
  for (final MapEntry<String, dynamic> e in a.entries) {
    if (!b.containsKey(e.key)) return false;
    if (b[e.key] != e.value) return false;
  }
  return true;
}

int _mapHash(Map<String, dynamic> m) {
  // Order-independent hash over entries.
  int h = 0;
  for (final MapEntry<String, dynamic> e in m.entries) {
    h ^= Object.hash(e.key, e.value);
  }
  return h;
}
