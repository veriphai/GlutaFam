// town_simulation — the reusable WORLD object (PRD §6, "town_simulation_base"):
// a town whose lights respond to power supplied, a day cycle, a haze layer, a
// cost meter, and a pluggable source. Every later episode game extends it; the
// three persistent felt-consequence channels (lit-state, haze, cost) live here.
//
// Per-source RUN model (update spec Change 4): selecting a source resets the day
// to MORNING and the day auto-plays a brisk time-lapse to MIDNIGHT, so each
// source's catch is always witnessed. Haze + cost are derived from how far the
// DAY has progressed (a high-water mark of time reached) — NOT wall-clock runtime
// — so the scrubber's fast-forward (drag) reaches every catch, and a rewind keeps
// the haze it already earned (the smog lingers).

import '../config/source_personality_defs.dart';
import '../config/town_sim_tuning.dart';

enum TownSimMode { exploration, game }

/// Discrete lit-state — for copy + future scoring. Window brightness reads from
/// the continuous [TownSimulation.townLight]; this names the bands.
enum TownLitState { fullyLit, dim, flickering, dark }

class TownSimulation {
  TownSimulation({this.mode = TownSimMode.exploration});

  final TownSimMode mode;

  // --- Live world state ------------------------------------------------------
  double timeOfDay = TownTune.dayStart; // 0..24, the sun/sky clock
  bool playing = true; // the day auto-plays unless paused / at the end
  double pollution = 0; // 0..1 haze density (derived)
  double runningCost = 0; // cost so far (derived: build cost + day climb)
  double waterLevel = 1.0; // hydro reservoir, 0..1

  SourcePersonality? source;
  double _maxTime = TownTune.dayStart; // furthest the day has reached this run

  // For flicker detection / smoothing the readout.
  double _townLight = 0;
  double _lastSupply = 0;

  // --- Input -----------------------------------------------------------------

  /// Plug in a source: reset the day to MORNING and start the time-lapse.
  void selectSource(SourcePersonality s) {
    source = s;
    timeOfDay = TownTune.dayStart;
    _maxTime = TownTune.dayStart;
    pollution = 0;
    runningCost = s.buildCost.toDouble();
    waterLevel = 1.0;
    playing = true;
  }

  /// Scrub via the transport (0 = morning … 1 = midnight). Fast-forward / rewind.
  void scrubToFraction(double f) {
    final t = TownTune.dayStart + f.clamp(0.0, 1.0) * TownTune.dayHours;
    timeOfDay = t.clamp(TownTune.dayStart, TownTune.dayEnd);
    if (timeOfDay > _maxTime) _maxTime = timeOfDay;
  }

  void setPlaying(bool v) => playing = v;

  // --- Tick ------------------------------------------------------------------
  void tick(double dt) {
    if (dt <= 0) return;

    if (playing) {
      timeOfDay += dt * (24.0 / TownTune.dayLengthSeconds);
      if (timeOfDay >= TownTune.dayEnd) {
        // Keep running — loop back to morning instead of pausing, until another
        // source is selected. _maxTime is NOT reset, so the haze/cost a source
        // earned PERSIST across loops (the air stays filthy, the cost stays
        // spent) while the sun, the wind flicker, and solar's day↔night cycle on.
        timeOfDay = TownTune.dayStart + (timeOfDay - TownTune.dayEnd);
      }
    }
    if (timeOfDay > _maxTime) _maxTime = timeOfDay;

    final s = source;
    final supply = s == null ? 0.0 : TownTune.supplyFor(s, timeOfDay, waterLevel);
    _lastSupply = supply;
    _townLight = TownTune.townLight(supply);
    if (s == null) return;

    // Derived felt channels — driven by how much of the DAY has elapsed (high
    // water), so dragging forward thickens haze / climbs cost just like playing.
    final dayElapsed = _maxTime - TownTune.dayStart;
    pollution = (s.hazeRate * dayElapsed * TownTune.hazeScale).clamp(0.0, 1.0);
    runningCost = s.buildCost + s.costRate * dayElapsed * TownTune.costScale;
    waterLevel = (1.0 - dayElapsed / TownTune.hydroDrainHours).clamp(0.0, 1.0);
  }

  // --- Derived getters (read by the renderer + UI) ---------------------------
  double get sunAltitude => TownTune.sunAltitude(timeOfDay);
  double get sunArcX => TownTune.sunArcX(timeOfDay);
  bool get isDaylight => sunAltitude > 0.001;
  double get supply => _lastSupply;
  double get townLight => _townLight;
  double get costFraction => (runningCost / TownTune.costFullScale).clamp(0.0, 1.0);
  double get gust => TownTune.gust(timeOfDay);
  bool get hasSource => source != null;

  /// Live power output in kW (relative/tunable units) — the readout number.
  double get powerKW => (_lastSupply * TownTune.kWPerSupply).clamp(0.0, 99.0);

  /// 0 = morning … 1 = midnight (the scrubber handle position).
  double get dayProgress => ((timeOfDay - TownTune.dayStart) / TownTune.dayHours).clamp(0.0, 1.0);

  /// Day-hours elapsed at the furthest point reached (drives haze/cost catches).
  double get dayElapsed => _maxTime - TownTune.dayStart;

  TownLitState get litState {
    if (_townLight >= 0.9) return TownLitState.fullyLit;
    final s = source;
    if (s != null && s.isWind && _lastSupply > 0.12 && _lastSupply < 1.0) {
      return TownLitState.flickering;
    }
    if (_townLight <= 0.12) return TownLitState.dark;
    return TownLitState.dim;
  }
}
