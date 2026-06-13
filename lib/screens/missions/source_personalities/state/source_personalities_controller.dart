// Source Personalities — the activity controller. Owns the town SIMULATION, the
// stage geometry, AND the progression. The only "voice" is the large top-text:
// each source shows its UPSIDE on arrival (Beat 1) and its CATCH once the day
// reveals it (Beat 2). A source counts as EXPLORED only when its catch fires; the
// synthesis ("Every Source Is a Trade-Off") + Card 03 fire only once EVERY
// source's catch has been witnessed (update spec Changes 2–5).
//
// Notifies EVERY frame (the game reads getters); discrete UI is pushed to
// dedicated ValueNotifiers so overlays rebuild only on real changes.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Offset, Size;

import '../config/source_personality_defs.dart';
import '../config/town_sim_tuning.dart';
import 'town_simulation.dart';

/// The activity's phases: [intro] (brief, before reveal), [exploring] (running
/// sources), [closing] (all catches seen → synthesis → card).
enum SPPhase { intro, exploring, closing }

class SourcePersonalitiesController extends ChangeNotifier {
  SourcePersonalitiesController();

  final TownSimulation sim = TownSimulation();

  // --- Discrete UI channels (rebuild only on change) -------------------------
  /// The large top-text — carries BOTH the instruction and the lesson.
  final ValueNotifier<String> instruction = ValueNotifier('Power the Town');
  final ValueNotifier<SPPhase> phase = ValueNotifier(SPPhase.intro);
  final ValueNotifier<SourceKind?> activeSource = ValueNotifier(null);

  /// The world is interactive (selector + scrubber live) once it has revealed.
  final ValueNotifier<bool> worldLive = ValueNotifier(false);

  /// Sources whose CATCH has been witnessed — drives the green check on each chip
  /// + gates the synthesis on ALL of them (the kid must feel every catch).
  final ValueNotifier<Set<SourceKind>> explored = ValueNotifier(const {});
  final Set<SourceKind> _explored = {};

  /// True once all catches are seen and Card 03 should be earned.
  final ValueNotifier<bool> showCardEarn = ValueNotifier(false);

  /// True once the card is collected — reveal the Continue CTA to finish.
  final ValueNotifier<bool> canFinish = ValueNotifier(false);

  // --- Polish hooks ----------------------------------------------------------
  void Function()? onSelectHaptic;

  /// Episode-board capture hook (PRD §8): fired when a source's CATCH lands, with
  /// the evidence-tile id to auto-capture. All 6 sources the kid runs leave a
  /// trace: coal AND gas club to ONE 'fossil_haze' tile (same catch — dirty),
  /// while nuclear/wind/solar/hydro each pin their own distinct catch.
  void Function(String evidenceId)? onCapture;

  static const Map<SourceKind, String> _captureFor = {
    SourceKind.coal: 'fossil_haze',
    SourceKind.gas: 'fossil_haze', // clubbed with coal (burning fuel = dirty)
    SourceKind.nuclear: 'nuclear_cost',
    SourceKind.wind: 'wind_drop',
    SourceKind.solar: 'solar_night',
    SourceKind.hydro: 'hydro_river',
  };

  // --- Geometry (pixels = factors × stage size) ------------------------------
  Size _stage = Size.zero;
  Size get stageSize => _stage;
  void setStageSize(Size s) => _stage = s;

  Offset get sourceAnchor =>
      Offset(TownTune.sourceAnchorFactor.dx * _stage.width, TownTune.sourceAnchorFactor.dy * _stage.height);
  double get horizonY => TownTune.horizonFactor * _stage.height;
  double get townTopY => TownTune.townTopFactor * _stage.height;
  double get hazeBandTopY => TownTune.hazeBandTopFactor * _stage.height;

  // --- Sim read-through (renderer convenience) -------------------------------
  double get timeOfDay => sim.timeOfDay;
  double get sunAltitude => sim.sunAltitude;
  double get sunArcX => sim.sunArcX;
  double get townLight => sim.townLight;
  double get pollution => sim.pollution;
  double get costFraction => sim.costFraction;
  double get waterLevel => sim.waterLevel;
  double get gust => sim.gust;
  double get dayProgress => sim.dayProgress;
  bool get isDaylight => sim.isDaylight;
  SourcePersonality? get source => sim.source;
  bool get playing => sim.playing;

  // --- Live readouts (throttled so the numbers are readable as they bounce) ---
  double displayPowerKW = 0;
  int powerTrend = 0; // -1 falling, 0 steady, +1 rising
  String? driverLabel;
  String? driverValue;
  double _sampleAccum = 0;

  // --- Catch tracking (per active source) ------------------------------------
  bool _catchFired = false;
  bool _solarWasLit = false;

  // --- Progression timers (ms remaining; -1 = inactive) ----------------------
  bool _started = false;
  bool _revealed = false;
  bool _synthesisStarted = false;
  bool _cardFired = false;
  bool _outroFired = false;
  double _revealPending = -1;
  double _synthesisPending = -1;
  double _cardPending = -1;

  // --- Lifecycle -------------------------------------------------------------
  void start() {
    if (_started) return;
    _started = true;
    _revealPending = TownTune.revealDelayMs.toDouble();
  }

  // --- Input -----------------------------------------------------------------
  void selectSource(SourceKind k) {
    if (!worldLive.value || _synthesisStarted) return;
    if (activeSource.value == k) return;
    final s = sourceOf(k);
    sim.selectSource(s); // resets the day to morning; auto-play begins
    activeSource.value = k;
    instruction.value = s.upside; // Beat 1 — the upside, on arrival
    _catchFired = false;
    _solarWasLit = false;
    _sampleAccum = 1; // force an immediate readout refresh on the next tick
    onSelectHaptic?.call();
    notifyListeners();
  }

  /// Scrub the day (0 = morning … 1 = midnight) — a transport: progress handle +
  /// fast-forward + rewind. The catch still fires when its moment is reached.
  void scrubToFraction(double f) {
    sim.scrubToFraction(f);
    notifyListeners();
  }

  void setPlaying(bool v) {
    sim.setPlaying(v);
    notifyListeners();
  }

  /// The kid added Card 03 to the deck — dismiss the earn overlay and finish.
  void onCardCollected() {
    showCardEarn.value = false;
    if (!_outroFired) {
      _outroFired = true;
      canFinish.value = true;
    }
  }

  // --- Tick ------------------------------------------------------------------
  void tick(double dt) {
    if (dt <= 0) return;
    sim.tick(dt);

    // Live readouts — sampled ~5×/s so a bouncing wind number stays readable.
    _sampleAccum += dt;
    if (_sampleAccum >= 0.18 && sim.hasSource) {
      _sampleAccum = 0;
      final p = sim.powerKW;
      powerTrend = (p - displayPowerKW).abs() < 0.12 ? 0 : (p > displayPowerKW ? 1 : -1);
      displayPowerKW = p;
      _refreshDriver();
    }

    // Catch detection — Beat 2 fires once the day reveals this source's catch.
    final s = sim.source;
    if (s != null && !_catchFired && !_synthesisStarted) {
      if (s.isSolar && sim.powerKW > 1.0) _solarWasLit = true;
      if (_catchReached(s)) {
        _catchFired = true;
        _onCatch(s);
      }
    }

    _tickProgression(dt * 1000);
    notifyListeners();
  }

  /// Has the day revealed this source's catch yet? Solar/wind are vivid in-day
  /// failures; coal/gas are the thickening haze; nuclear/hydro are stated
  /// qualifiers reached by mid-day (cost climbed / a condition).
  bool _catchReached(SourcePersonality s) {
    switch (s.kind) {
      case SourceKind.solar:
        return _solarWasLit && sim.timeOfDay >= TownTune.sunset; // nightfall
      case SourceKind.wind:
        return (sim.gust <= TownTune.windLull && sim.dayElapsed >= TownTune.windMinElapsedH) ||
            sim.dayElapsed >= TownTune.windFallbackElapsedH; // a lull
      case SourceKind.coal:
        return sim.pollution >= TownTune.coalHazeCatch;
      case SourceKind.gas:
        return sim.pollution >= TownTune.gasHazeCatch;
      case SourceKind.nuclear:
        return sim.costFraction >= TownTune.nuclearCostCatch ||
            sim.dayElapsed >= TownTune.nuclearFallbackElapsedH;
      case SourceKind.hydro:
        return sim.dayElapsed >= TownTune.hydroElapsedCatch;
    }
  }

  void _onCatch(SourcePersonality s) {
    instruction.value = s.catchLine; // Beat 2 — the catch, named now it's felt
    final captureId = _captureFor[s.kind];
    if (captureId != null) onCapture?.call(captureId); // auto-pin the felt catch
    if (_explored.add(s.kind)) explored.value = Set.unmodifiable(_explored);
    if (_explored.length >= kSources.length && !_synthesisStarted) {
      _synthesisStarted = true;
      _synthesisPending = TownTune.synthesisDelayMs.toDouble(); // let Beat 2 read first
    }
  }

  void _tickProgression(double dtMs) {
    if (_revealPending > 0) {
      _revealPending -= dtMs;
      if (_revealPending <= 0) {
        _revealPending = -1;
        if (!_revealed) {
          _revealed = true;
          worldLive.value = true;
          phase.value = SPPhase.exploring;
          instruction.value = 'Pick a Source';
        }
      }
    }

    if (_synthesisPending > 0) {
      _synthesisPending -= dtMs;
      if (_synthesisPending <= 0) {
        _synthesisPending = -1;
        phase.value = SPPhase.closing;
        instruction.value = 'Every Source Is a Trade-Off';
        _cardPending = TownTune.synthesisToCardMs.toDouble();
      }
    }

    if (_cardPending > 0) {
      _cardPending -= dtMs;
      if (_cardPending <= 0) {
        _cardPending = -1;
        if (!_cardFired) {
          _cardFired = true;
          showCardEarn.value = true;
        }
      }
    }
  }

  /// The variable source's DRIVER as a live number, so the kid watches it rise
  /// and fall in lockstep with the power number (update spec — live numbers).
  void _refreshDriver() {
    final s = sim.source;
    if (s == null) {
      driverLabel = null;
      driverValue = null;
      return;
    }
    switch (s.kind) {
      case SourceKind.solar:
        driverLabel = 'SUNLIGHT';
        driverValue = '${(sim.sunAltitude * 100).round()}%';
      case SourceKind.wind:
        driverLabel = 'WIND';
        driverValue = '${(sim.gust * TownTune.windKmh).round()} km/h';
      case SourceKind.hydro:
        driverLabel = 'WATER';
        driverValue = '${(sim.waterLevel * 100).round()}%';
      case SourceKind.coal:
      case SourceKind.gas:
      case SourceKind.nuclear:
        driverLabel = null;
        driverValue = null;
    }
  }

  @override
  void dispose() {
    instruction.dispose();
    phase.dispose();
    activeSource.dispose();
    worldLive.dispose();
    explored.dispose();
    showCardEarn.dispose();
    canFinish.dispose();
    super.dispose();
  }
}
