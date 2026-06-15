// Ember — contracts/event_resolver.dart
//
// The seam a leaf implements to RESOLVE a WorldEvent (the flagship flood lives in
// the shelter leaf; a default predator/storm/cold resolver lives in foundation).
// The event system collects resolvers via SimRegistry.resolversFor(type) and runs
// the first one that canResolve — so the sim never imports a leaf.
//
// resolve() is PURE + DETERMINISTIC: it gets the EmberRng so any chance it needs
// (severity rolls, which placeables get hit) is reproducible across live/offline/
// tests. It returns a NEW state plus an [EventOutcome] that feeds the AwayDigest.

import '../core/ember_rng.dart';
import '../core/enums.dart';
import '../data/models/world_event.dart';
import '../data/models/world_state.dart';

/// The result of resolving one [WorldEvent]: the mutated world plus a
/// human-readable digest line and structured deltas for the away-summary.
class EventOutcome {
  const EventOutcome({
    required this.state,
    required this.type,
    required this.headline,
    this.detail = '',
    this.severity = 0.0,
    this.damagedPlaceableIds = const <String>[],
    this.comfortDelta = 0.0,
    this.data = const <String, dynamic>{},
  });

  /// The world AFTER the event resolved.
  final EmberWorldState state;

  /// Which event this outcome describes.
  final WorldEventType type;

  /// One-line summary for the digest (e.g. "A flood swept the riverbank").
  final String headline;

  /// Optional longer line (e.g. "2 huts damaged; high-ground homes held").
  final String detail;

  /// 0..1 how bad it was (for sorting/iconography in the digest).
  final double severity;

  /// Ids of placeables damaged/destroyed by the event.
  final List<String> damagedPlaceableIds;

  /// Net change to village comfort caused by the event.
  final double comfortDelta;

  /// Extra structured payload for leaves/UI (kept untyped so the seam is open).
  final Map<String, dynamic> data;

  EventOutcome copyWith({
    EmberWorldState? state,
    WorldEventType? type,
    String? headline,
    String? detail,
    double? severity,
    List<String>? damagedPlaceableIds,
    double? comfortDelta,
    Map<String, dynamic>? data,
  }) {
    return EventOutcome(
      state: state ?? this.state,
      type: type ?? this.type,
      headline: headline ?? this.headline,
      detail: detail ?? this.detail,
      severity: severity ?? this.severity,
      damagedPlaceableIds: damagedPlaceableIds ?? this.damagedPlaceableIds,
      comfortDelta: comfortDelta ?? this.comfortDelta,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.name,
        'headline': headline,
        'detail': detail,
        'severity': severity,
        'damagedPlaceableIds': List<String>.of(damagedPlaceableIds)..sort(),
        'comfortDelta': comfortDelta,
        'data': data,
      };
}

/// Implemented by a leaf (or foundation default) to handle a [WorldEventType].
abstract interface class EventResolver {
  /// Whether this resolver handles [type].
  bool canResolve(WorldEventType type);

  /// Resolves [e] against [s], using [rng] for any chance. Returns a new state
  /// wrapped in an [EventOutcome]. MUST NOT touch DateTime/Random/Stopwatch.
  EventOutcome resolve(WorldEvent e, EmberWorldState s, EmberRng rng);
}
