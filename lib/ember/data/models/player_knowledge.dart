// Ember — data/models/player_knowledge.dart
//
// One flat Map<String,bool> bag of knowledge flags that EVERY concept shares
// (e.g. "fire.needs_fuel", "shelter.high_ground_safe"). Leaves declare their
// keys via ConceptModule.knowledgeKeys; the reducer sets them. Pure value object.

class PlayerKnowledge {
  PlayerKnowledge([Map<String, bool>? flags])
      : _flags = Map<String, bool>.of(flags ?? const <String, bool>{});

  final Map<String, bool> _flags;

  /// Read-only view of all flags.
  Map<String, bool> get flags => Map<String, bool>.unmodifiable(_flags);

  bool get(String key) => _flags[key] ?? false;
  bool has(String key) => _flags.containsKey(key);

  /// Returns a NEW PlayerKnowledge with [key] set to [value].
  PlayerKnowledge set(String key, [bool value = true]) {
    final Map<String, bool> next = Map<String, bool>.of(_flags);
    next[key] = value;
    return PlayerKnowledge(next);
  }

  /// Returns a NEW PlayerKnowledge with all [keys] set true.
  PlayerKnowledge setAll(Iterable<String> keys, [bool value = true]) {
    final Map<String, bool> next = Map<String, bool>.of(_flags);
    for (final String k in keys) {
      next[k] = value;
    }
    return PlayerKnowledge(next);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        // Keys sorted for byte-stable round-trips.
        for (final String k in _flags.keys.toList()..sort()) k: _flags[k],
      };

  factory PlayerKnowledge.fromJson(Map<String, dynamic> j) =>
      PlayerKnowledge(<String, bool>{
        for (final MapEntry<String, dynamic> e in j.entries)
          e.key: e.value as bool? ?? false,
      });

  @override
  bool operator ==(Object other) =>
      other is PlayerKnowledge && _mapEq(other._flags, _flags);

  @override
  int get hashCode {
    int h = 0;
    for (final MapEntry<String, bool> e in _flags.entries) {
      h ^= Object.hash(e.key, e.value);
    }
    return h;
  }
}

bool _mapEq(Map<String, bool> a, Map<String, bool> b) {
  if (a.length != b.length) return false;
  for (final MapEntry<String, bool> e in a.entries) {
    if (b[e.key] != e.value) return false;
  }
  return true;
}
