// Ember — sim/systems/time_system.dart
//
// Advances the in-sim day/night clock from elapsed sim-time. `phase` (0..1) wraps
// each dayLengthMs; each wrap bumps dayCount and may rotate the season. `isNight`
// is DERIVED on DayNightState from the night window, so this system only moves
// phase/dayCount/season. Pure + deterministic + offline-safe (a multi-day dt is
// reduced correctly via modulo). No clock/random.

import '../../core/enums.dart';
import '../../data/models/day_night_state.dart';
import '../../data/models/world_state.dart';

class TimeSystem {
  const TimeSystem();

  /// How many full days complete one season cycle (warm -> wet -> cold -> ...).
  static const int _daysPerSeason = 3;

  /// Advances the day/night state by [dtSeconds]. Handles arbitrarily large dt
  /// (offline catch-up) by accumulating whole-day rollovers.
  EmberWorldState advance(EmberWorldState s, double dtSeconds) {
    if (dtSeconds <= 0) return s;
    final DayNightState dn = s.dayNight;
    final int dayMs = dn.dayLengthMs <= 0 ? 1 : dn.dayLengthMs;

    final double advancedMs = dtSeconds * 1000.0;
    // Absolute position (ms) within the day, plus how many cycles elapsed.
    final double startMs = dn.phase * dayMs;
    final double totalMs = startMs + advancedMs;
    final int cyclesElapsed = (totalMs / dayMs).floor();
    final double newPhase = (totalMs % dayMs) / dayMs;

    final int newDayCount = dn.dayCount + cyclesElapsed;
    final Season newSeason = cyclesElapsed > 0
        ? _seasonForDay(newDayCount)
        : dn.season;

    final DayNightState next = dn.copyWith(
      phase: newPhase.clamp(0.0, 0.999999),
      dayCount: newDayCount,
      season: newSeason,
    );
    return s.copyWith(dayNight: next);
  }

  /// Season as a pure function of dayCount so it is reproducible.
  Season _seasonForDay(int dayCount) {
    final int idx = (dayCount ~/ _daysPerSeason) % Season.values.length;
    return Season.values[idx];
  }
}
