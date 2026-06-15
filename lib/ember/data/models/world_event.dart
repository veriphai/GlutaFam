// Ember — data/models/world_event.dart
//
// A scheduled world event (predator, flood, storm, cold night). The sim
// schedules these deterministically (severity drawn from EmberRng), fires them
// when simNow >= scheduledForMs, and an EventResolver writes the outcome back.
// Pure value object; outcome is an untyped bag so leaves can extend it.

import '../../core/enums.dart';
import '../../core/ids.dart';

class WorldEvent {
  WorldEvent({
    required this.id,
    required this.type,
    required this.scheduledForMs,
    this.resolved = false,
    Map<String, dynamic>? payload,
    Map<String, dynamic>? outcome,
  })  : payload = payload ?? <String, dynamic>{},
        outcome = outcome ?? <String, dynamic>{};

  final EntityId id;
  final WorldEventType type;

  /// simNow (ms) at which this event becomes active.
  final int scheduledForMs;

  /// Whether a resolver has already handled it.
  final bool resolved;

  /// Pre-fire parameters (e.g. severity, target region). Untyped bag.
  final Map<String, dynamic> payload;

  /// Post-resolution results (e.g. damaged ids, comfort delta). Untyped bag.
  final Map<String, dynamic> outcome;

  /// Convenience read for severity (0..1) if a scheduler stored one.
  double get severity =>
      (payload['severity'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.5;

  bool isDue(int simNowMs) => !resolved && simNowMs >= scheduledForMs;

  WorldEvent copyWith({
    EntityId? id,
    WorldEventType? type,
    int? scheduledForMs,
    bool? resolved,
    Map<String, dynamic>? payload,
    Map<String, dynamic>? outcome,
  }) {
    return WorldEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      scheduledForMs: scheduledForMs ?? this.scheduledForMs,
      resolved: resolved ?? this.resolved,
      payload: payload ?? Map<String, dynamic>.of(this.payload),
      outcome: outcome ?? Map<String, dynamic>.of(this.outcome),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type.name,
        'scheduledForMs': scheduledForMs,
        'resolved': resolved,
        'payload': payload,
        'outcome': outcome,
      };

  factory WorldEvent.fromJson(Map<String, dynamic> j) => WorldEvent(
        id: j['id'] as String? ?? '',
        type: worldEventTypeFromName(j['type']),
        scheduledForMs: (j['scheduledForMs'] as num?)?.toInt() ?? 0,
        resolved: j['resolved'] as bool? ?? false,
        payload: (j['payload'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
        outcome: (j['outcome'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
      );

  @override
  bool operator ==(Object other) =>
      other is WorldEvent &&
      other.id == id &&
      other.type == type &&
      other.scheduledForMs == scheduledForMs &&
      other.resolved == resolved &&
      _mapEq(other.payload, payload) &&
      _mapEq(other.outcome, outcome);

  @override
  int get hashCode => Object.hash(
        id,
        type,
        scheduledForMs,
        resolved,
        _mapHash(payload),
        _mapHash(outcome),
      );
}

bool _mapEq(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (a.length != b.length) return false;
  for (final MapEntry<String, dynamic> e in a.entries) {
    if (!b.containsKey(e.key) || b[e.key] != e.value) return false;
  }
  return true;
}

int _mapHash(Map<String, dynamic> m) {
  int h = 0;
  for (final MapEntry<String, dynamic> e in m.entries) {
    h ^= Object.hash(e.key, e.value);
  }
  return h;
}
