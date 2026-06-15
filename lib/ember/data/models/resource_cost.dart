// Ember — data/models/resource_cost.dart
//
// A cost/bundle of resources: Map<ResourceType,int> with arithmetic + a refund
// helper for removing placeables. Immutable; ops return new instances.

import '../../core/enums.dart';

class ResourceCost {
  ResourceCost(Map<ResourceType, int> amounts)
      : _amounts = Map<ResourceType, int>.unmodifiable(
          <ResourceType, int>{
            for (final MapEntry<ResourceType, int> e in amounts.entries)
              if (e.value != 0) e.key: e.value,
          },
        );

  const ResourceCost._raw(this._amounts);

  static const ResourceCost empty = ResourceCost._raw(<ResourceType, int>{});

  final Map<ResourceType, int> _amounts;

  Map<ResourceType, int> get amounts => _amounts;
  bool get isEmpty => _amounts.isEmpty;

  int amountOf(ResourceType t) => _amounts[t] ?? 0;

  ResourceCost operator +(ResourceCost o) {
    final Map<ResourceType, int> next = Map<ResourceType, int>.of(_amounts);
    for (final MapEntry<ResourceType, int> e in o._amounts.entries) {
      next[e.key] = (next[e.key] ?? 0) + e.value;
    }
    return ResourceCost(next);
  }

  ResourceCost operator -(ResourceCost o) {
    final Map<ResourceType, int> next = Map<ResourceType, int>.of(_amounts);
    for (final MapEntry<ResourceType, int> e in o._amounts.entries) {
      next[e.key] = (next[e.key] ?? 0) - e.value;
    }
    return ResourceCost(next);
  }

  ResourceCost scaled(double factor) => ResourceCost(<ResourceType, int>{
        for (final MapEntry<ResourceType, int> e in _amounts.entries)
          e.key: (e.value * factor).round(),
      });

  /// Returns a [fraction] (0..1) of this cost back, rounded down — used when a
  /// placeable is removed/refunded.
  ResourceCost refund(double fraction) {
    final double f = fraction.clamp(0.0, 1.0);
    return ResourceCost(<ResourceType, int>{
      for (final MapEntry<ResourceType, int> e in _amounts.entries)
        e.key: (e.value * f).floor(),
    });
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        for (final MapEntry<ResourceType, int> e in _amounts.entries)
          e.key.name: e.value,
      };

  factory ResourceCost.fromJson(Map<String, dynamic> j) =>
      ResourceCost(<ResourceType, int>{
        for (final MapEntry<String, dynamic> e in j.entries)
          resourceTypeFromName(e.key): (e.value as num).toInt(),
      });

  @override
  bool operator ==(Object other) =>
      other is ResourceCost && _mapEq(other._amounts, _amounts);

  @override
  int get hashCode {
    int h = 0;
    for (final MapEntry<ResourceType, int> e in _amounts.entries) {
      h ^= Object.hash(e.key, e.value);
    }
    return h;
  }

  @override
  String toString() => 'ResourceCost($_amounts)';
}

bool _mapEq(Map<ResourceType, int> a, Map<ResourceType, int> b) {
  if (a.length != b.length) return false;
  for (final MapEntry<ResourceType, int> e in a.entries) {
    if (b[e.key] != e.value) return false;
  }
  return true;
}
