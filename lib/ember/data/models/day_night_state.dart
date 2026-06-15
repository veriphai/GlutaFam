// Ember — data/models/day_night_state.dart
//
// The day/night clock-within-the-sim. `phase` (0..1) advances each tick from
// elapsed sim-time; `isNight` is DERIVED from phase via the night window in
// constants. Pure value object — the sim mutates it deterministically.

import '../../core/constants.dart';
import '../../core/enums.dart';

class DayNightState {
  const DayNightState({
    this.dayLengthMs = EmberConstants.dayLengthMs,
    this.phase = 0.0,
    this.season = Season.warm,
    this.dayCount = 0,
  });

  /// Length of one full cycle in ms.
  final int dayLengthMs;

  /// 0..1 position within the current cycle (0 = dawn).
  final double phase;

  final Season season;

  /// How many full day/night cycles have elapsed.
  final int dayCount;

  /// DERIVED: whether it is currently night, from the night window.
  bool get isNight =>
      phase >= EmberConstants.nightStartPhase &&
      phase < EmberConstants.nightEndPhase;

  /// 0..1 darkness factor for ambient lighting (peaks mid-night).
  double get darkness {
    if (!isNight) return 0.0;
    const double a = EmberConstants.nightStartPhase;
    const double b = EmberConstants.nightEndPhase;
    final double t = ((phase - a) / (b - a)).clamp(0.0, 1.0);
    // Triangle: rises to 1 at mid-night, falls back.
    return t < 0.5 ? t * 2 : (1 - t) * 2;
  }

  DayNightState copyWith({
    int? dayLengthMs,
    double? phase,
    Season? season,
    int? dayCount,
  }) {
    return DayNightState(
      dayLengthMs: dayLengthMs ?? this.dayLengthMs,
      phase: phase ?? this.phase,
      season: season ?? this.season,
      dayCount: dayCount ?? this.dayCount,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'dayLengthMs': dayLengthMs,
        'phase': phase,
        'season': season.name,
        'dayCount': dayCount,
      };

  factory DayNightState.fromJson(Map<String, dynamic> j) => DayNightState(
        dayLengthMs: (j['dayLengthMs'] as num?)?.toInt() ??
            EmberConstants.dayLengthMs,
        phase: (j['phase'] as num?)?.toDouble() ?? 0.0,
        season: seasonFromName(j['season']),
        dayCount: (j['dayCount'] as num?)?.toInt() ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      other is DayNightState &&
      other.dayLengthMs == dayLengthMs &&
      other.phase == phase &&
      other.season == season &&
      other.dayCount == dayCount;

  @override
  int get hashCode => Object.hash(dayLengthMs, phase, season, dayCount);
}
