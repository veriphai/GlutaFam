// Ember — concepts/shelter/raise_shelter_sim.dart
//
// The interactive BRAIN + GEOMETRY for the Raise a Shelter interact beat. It is a
// small, self-contained state machine over four phases — choose SITE, choose
// MATERIAL, ASSEMBLE (frame -> cover -> anchor -> smoke hole), then the wind/rain
// TEST — that emits [SimEvent]s the [BeatController] scores against the activity's
// rules. The teaching failures (low site = the SITE lesson, no anchor = the ANCHOR
// / STRUCTURE lesson, cover-before-frame = the ordering nudge) ARE the lesson,
// surfaced by play.
//
// PHASE-2 REDESIGN: the card-then-button chrome is gone. Input is now DIRECT,
// SAME-FRAME, ON-STAGE manipulation:
//   * SITE   — the player stands on / taps one of 2-3 candidate spots laid out on
//     the iso ground; each spot carries a FELT risk read (a water-line haze level)
//     this sim publishes so the stage paints it. The control IS the choice.
//   * MATERIAL — the player drags a material onto the riser; the wall RISES per
//     course at that material's pace (fast-but-weak vs slow-but-strong), the rise
//     speed + storm-hold strength carried here.
//   * ASSEMBLE — snap-build drag-assembly: the player drags Frame -> Cover ->
//     Anchor -> Smoke-hole parts onto ghost slots. This sim owns the SLOT geometry
//     (as fractions of the stage size, resolved by the scene) + which slot is the
//     current draggable, so the stage components are near-pure render(Canvas)
//     readers (the "controller owns everything" shape).
//
// DETERMINISM: this is presentation-layer interaction state, never fed into
// EmberWorldState, so it MAY run its own timers. It holds NO clock and NO Random —
// the test outcome is a pure function of the player's choices (site risk + whether
// they anchored), so a fixed input sequence is reproducible.

import 'dart:async';
import 'dart:math' as math;

import '../../activity/activity_contract.dart';
import '../../activity/activity_sim.dart';
import 'raise_shelter_activity.dart';

/// The four phases the player walks through inside one raise attempt.
enum RaisePhase { chooseSite, chooseMaterial, assemble, test, stood }

/// The deterministic verdict the storm test is HEADING toward, known the instant
/// the test starts (it's a pure function of the player's site + anchor choices).
/// The presentation layer reads this to telegraph the outcome through the build
/// of tension — a doomed build visibly strains/leans/leaks as the gusts mount —
/// rather than springing a surprise at the end.
enum StormVerdict {
  /// High ground + anchored: the home holds, the family stays dry.
  holds,

  /// Built on the low flood path: the rain pools and floods it.
  floods,

  /// Frame + cover up but never anchored: a gust lifts it and it topples.
  blowsOver,
}

/// The material tradeoff the player picks. Each carries a FELT tradeoff: how fast
/// its wall RISES per course while building, and how hard it later HOLDS in the
/// storm (fast-but-weak hide vs slow-but-strong hut timber). These are read by the
/// stage to make the tradeoff felt, not printed.
enum ShelterMaterial {
  /// Hide-and-pole: rises fast, holds light (shudders harder in the storm).
  hideTent,

  /// Timber hut: slow to raise course by course, but rides the storm calm.
  hut,
}

/// Per-material felt tradeoff (rise pace + storm sturdiness). Pure data.
extension ShelterMaterialTradeoff on ShelterMaterial {
  /// How fast one course of wall rises when the player drags it (0..1 per second,
  /// eased by the stage). Hide snaps up; timber climbs.
  double get riseSpeed => switch (this) {
        ShelterMaterial.hideTent => 2.6,
        ShelterMaterial.hut => 1.3,
      };

  /// 0..1 storm sturdiness — how calmly the build rides a gust (scales the strain
  /// shudder DOWN). Higher = steadier. Hide is light; timber is solid.
  double get sturdiness => switch (this) {
        ShelterMaterial.hideTent => 0.45,
        ShelterMaterial.hut => 0.9,
      };
}

ShelterMaterial _materialFromName(Object? n) {
  if (n is String) {
    for (final ShelterMaterial v in ShelterMaterial.values) {
      if (v.name == n) return v;
    }
  }
  return ShelterMaterial.hideTent;
}

/// The four assemble steps, in required order.
enum AssembleStep { frame, cover, anchor, smokeHole }

AssembleStep? _stepFromName(Object? n) {
  if (n is String) {
    for (final AssembleStep v in AssembleStep.values) {
      if (v.name == n) return v;
    }
  }
  return null;
}

/// The ordered drag-assembly steps (the LEGO order). The current draggable part is
/// always the first not-yet-done step.
const List<AssembleStep> kAssembleOrder = <AssembleStep>[
  AssembleStep.frame,
  AssembleStep.cover,
  AssembleStep.anchor,
  AssembleStep.smokeHole,
];

/// The SHARED stage geometry, as fractions of the stage/screen size, so the Flame
/// stage (which renders the felt props) and the full-screen gesture overlay (which
/// hit-tests finger drags) agree on WHERE everything is WITHOUT coupling. Pure
/// data — the "controller owns the geometry" shape: both readers map these
/// fractions through the same stage size.
///
/// Layout: the iso build pad sits centred in the upper-clear band; the candidate
/// SITE spots sit on the ground around it (choose one); the part TRAY sits along
/// the bottom-clear band (the only place the caption also lives). A part's GHOST
/// SLOT is where it snaps onto the dwelling silhouette.
abstract final class ShelterStageLayout {
  /// The dwelling build anchor (bottom-centre of the rising silhouette), as a
  /// fraction of the stage size. Pulled up into the clear upper band.
  static const ({double x, double y}) buildAnchor = (x: 0.5, y: 0.5);

  /// The three candidate SITE spots on the ground, keyed by site id, as fractions.
  /// safe = centre-ish high ground; mid = a touch right; river = low-front-left.
  static const Map<String, ({double x, double y})> siteSpots =
      <String, ({double x, double y})>{
    'site.high': (x: 0.5, y: 0.52),
    'site.grass': (x: 0.72, y: 0.6),
    'site.river': (x: 0.28, y: 0.66),
  };

  /// The generous snap radius for a part drag, as a fraction of the stage WIDTH.
  static const double snapRadiusFrac = 0.18;

  /// The generous tap radius to choose a site spot, as a fraction of stage width.
  static const double siteTapRadiusFrac = 0.16;

  /// A part's GHOST SLOT centre on the dwelling silhouette, as a fraction of the
  /// stage size (where the part snaps to). Relative to [buildAnchor] visually but
  /// resolved absolutely here so the overlay can hit-test directly.
  static ({double x, double y}) slotFor(AssembleStep step) => switch (step) {
        // Frame poles meet at the apex above the anchor.
        AssembleStep.frame => (x: 0.5, y: 0.4),
        // Cover drapes the body, just below the apex.
        AssembleStep.cover => (x: 0.5, y: 0.44),
        // Anchor stones at the base corners (use the base centre for hit-test).
        AssembleStep.anchor => (x: 0.5, y: 0.5),
        // Smoke hole at the very top of the cover.
        AssembleStep.smokeHole => (x: 0.5, y: 0.36),
      };

  /// The part TRAY anchor (centre of the tray row), as a fraction of the stage
  /// size. Pulled UP into the mid band so it clears the bottom EmberCaption (the
  /// caption owns the very bottom ~88px slot; props that sit too low collide with
  /// it — see the shelter feel-loop finding).
  static const ({double x, double y}) trayAnchor = (x: 0.5, y: 0.74);

  /// The two MATERIAL choices' rest spots (left/right of tray), as fractions — the
  /// player drags one UP onto the riser to raise the walls. Sits in the mid band,
  /// clear of the bottom caption.
  static const Map<String, ({double x, double y})> materialSpots =
      <String, ({double x, double y})>{
    'hideTent': (x: 0.32, y: 0.72),
    'hut': (x: 0.68, y: 0.72),
  };
}

/// The shelter-raising mini-game brain. One instance per interact beat; re-armed
/// on retry via [start].
class RaiseShelterSim implements ActivitySim {
  RaiseShelterSim();

  final StreamController<SimEvent> _events =
      StreamController<SimEvent>.broadcast();

  @override
  Stream<SimEvent> get events => _events.stream;

  // ---- Tunables (read from InteractionRules.config) ----------------------
  double _floodRiskThreshold = 0.4;
  double get floodRiskThreshold => _floodRiskThreshold;

  // ---- Live interaction state --------------------------------------------
  RaisePhase _phase = RaisePhase.chooseSite;
  RaisePhase get phase => _phase;

  /// The chosen site's flood risk (0..1) and a readable id.
  double _siteRisk = 0.0;
  double get siteRisk => _siteRisk;
  String _siteId = '';
  String get siteId => _siteId;
  bool _siteChosen = false;
  bool get siteChosen => _siteChosen;

  /// The chosen material.
  ShelterMaterial _material = ShelterMaterial.hideTent;
  ShelterMaterial get material => _material;
  bool _materialChosen = false;
  bool get materialChosen => _materialChosen;

  /// 0..1 eased wall-rise of the courses laid as the player drags the material in
  /// — the FELT tradeoff (hide snaps up, timber climbs). Presentation pacing only,
  /// driven from the deterministic [tick] accumulator. The stage reads it to draw
  /// the wall rising course by course; once it reaches ~1 the material is committed
  /// and the phase advances to assemble.
  double _wallRise = 0.0;
  double get wallRise => _wallRise;
  bool _materialDragging = false;

  /// Which assemble steps are done (in order).
  final Set<AssembleStep> _done = <AssembleStep>{};
  Set<AssembleStep> get done => Set<AssembleStep>.unmodifiable(_done);

  /// Whether the frame + cover are up (the minimum to attempt the test) and
  /// whether it was anchored (decides the wind result).
  bool get hasFrame => _done.contains(AssembleStep.frame);
  bool get hasCover => _done.contains(AssembleStep.cover);
  bool get hasAnchor => _done.contains(AssembleStep.anchor);
  bool get hasSmokeHole => _done.contains(AssembleStep.smokeHole);

  /// The part the player can currently grab (the first step not yet placed), or
  /// null once every part is placed. ONLY this part is draggable (the stage greys
  /// the rest), so the LEGO order is enforced by the input surface, not a fail.
  AssembleStep? get currentStep {
    for (final AssembleStep s in kAssembleOrder) {
      if (!_done.contains(s)) return s;
    }
    return null;
  }

  /// 0..1 settle of the just-snapped part (slide+scale+fade in). The stage eases
  /// this to 1 after a snap so the part deploys (poles swing up, cover unrolls...).
  double _settle = 1.0;
  double get settle => _settle;
  AssembleStep? _settling;
  AssembleStep? get settling => _settling;

  /// A short bounce-back ping when a wrong part is dropped (0..1, decays). Drives
  /// the stage's "nope, this one next" nudge on the current ghost slot.
  double _nudge = 0.0;
  double get nudge => _nudge;

  /// The minimum assembly to run the test = frame + cover up.
  bool get canRunTest => hasFrame && hasCover;

  /// All four parts placed (the stage shows the storm is ready to face).
  bool get fullyAssembled =>
      hasFrame && hasCover && hasAnchor && hasSmokeHole;

  /// Whether this attempt has resolved (success or a surfaced fail) so further
  /// input/ticks are ignored until [start] re-arms.
  bool _resolved = false;
  bool get resolved => _resolved;

  /// 0..1 progress of the running wind/rain test (presentation pacing only).
  double _testProgress = 0.0;
  double get testProgress => _testProgress;

  // ---- Storm telemetry (presentation-only, deterministic) ----------------
  // The verdict is locked the instant the test starts (pure function of the
  // chosen site + whether it was anchored), so the build-up of tension can lean
  // toward the truth instead of springing a surprise. None of this feeds world
  // state; the gust curve is driven off the deterministic [_testProgress]
  // accumulator (NO clock, NO Random), so a fixed input sequence is reproducible.

  /// How long the storm test runs, in presentation seconds. Slow enough that the
  /// gusts mount and the tension reads, but inside the review-tour's 3s storm dwell
  /// so the resolution still lands before discover.
  static const double _testDurationSec = 2.6;

  /// The locked verdict for the running/just-run test (null before it starts).
  StormVerdict? _verdict;
  StormVerdict? get verdict => _verdict;

  /// Instantaneous gust force 0..1 — a deterministic mounting-gust curve over the
  /// test (rises toward the climax, with lashing oscillation on top). The UI/scene
  /// lash the rain + shake the frame by this.
  double _gust = 0.0;
  double get gust => _gust;

  /// How hard THIS build is straining 0..1 — the gust scaled by the build's
  /// weakness (an unanchored or low-sited build strains far harder, telegraphing
  /// its doom). A holding build barely strains; a sturdy MATERIAL shudders less.
  double _strain = 0.0;
  double get strain => _strain;

  /// 0..1 how close the doomed build is to its breaking moment (floods rising /
  /// the topple). 0 for a holding build. Drives the lean + the rising water.
  double _failProgress = 0.0;
  double get failProgress => _failProgress;

  /// The fraction of the test at which the doomed build visibly gives way (the
  /// gust that takes an unanchored build / the water cresting a low site). Before
  /// this the build strains but holds on; after it, it is going.
  static const double _breakPoint = 0.62;

  @override
  void start(InteractionRules rules) {
    final Map<String, dynamic> c = rules.config;
    _floodRiskThreshold = (c[RaiseShelterSignals.cfgFloodRiskThreshold] as num?)
            ?.toDouble() ??
        _floodRiskThreshold;

    // Re-arm a fresh attempt.
    _phase = RaisePhase.chooseSite;
    _siteRisk = 0.0;
    _siteId = '';
    _siteChosen = false;
    _material = ShelterMaterial.hideTent;
    _materialChosen = false;
    _wallRise = 0.0;
    _materialDragging = false;
    _done.clear();
    _settle = 1.0;
    _settling = null;
    _nudge = 0.0;
    _resolved = false;
    _testProgress = 0.0;
    _verdict = null;
    _gust = 0.0;
    _strain = 0.0;
    _failProgress = 0.0;
  }

  /// The deterministic verdict a test would reach RIGHT NOW given the choices so
  /// far. Pure function of (site risk, anchored?) — the same logic [_resolveTest]
  /// scores, exposed so the test can lock + telegraph it the moment it starts.
  StormVerdict _predictVerdict() {
    if (_siteRisk >= _floodRiskThreshold) return StormVerdict.floods;
    if (!hasAnchor) return StormVerdict.blowsOver;
    return StormVerdict.holds;
  }

  @override
  void onInput(SimInput input) {
    if (_resolved) return;
    switch (input.code) {
      case RaiseShelterSignals.inChooseSite:
        _onChooseSite(input);
      case RaiseShelterSignals.inChooseMaterial:
        _onChooseMaterial(input);
      case RaiseShelterSignals.inAssembleStep:
        _onAssembleStep(input);
      case RaiseShelterSignals.inRunTest:
        _onRunTest();
    }
  }

  void _onChooseSite(SimInput input) {
    if (_phase != RaisePhase.chooseSite) return;
    _siteRisk = (input.param<num>('risk'))?.toDouble().clamp(0.0, 1.0) ?? 0.0;
    _siteId = input.param<String>('siteId') ?? '';
    _siteChosen = true;
    _phase = RaisePhase.chooseMaterial;
    _emit(RaiseShelterSignals.siteChosen, data: <String, dynamic>{
      'risk': _siteRisk,
      'siteId': _siteId,
      // The SITE lesson is taught at the TEST, not here — but flag the risk so the
      // stage can keep the low spot's water-line haze visible (telegraphed for 7-9).
      'lowGround': _siteRisk >= _floodRiskThreshold,
    });
  }

  void _onChooseMaterial(SimInput input) {
    if (_phase != RaisePhase.chooseMaterial) return;
    // The material picks register the choice; the WALL then rises while the finger
    // holds (the felt tradeoff). The 'dragging' flag drives the rise in tick();
    // once the rise tops out the phase commits to assemble.
    final ShelterMaterial picked =
        _materialFromName(input.param<String>('material'));
    final bool dragging = input.param<bool>('dragging') ?? true;
    // 'commit' = a one-shot full raise (the public chooseMaterial convenience +
    // the review tour use this so they don't have to hold the drag across ticks).
    final bool commit = input.param<bool>('commit') ?? false;
    if (picked != _material) {
      // Switched material mid-pick: restart the rise at the new pace.
      _wallRise = 0.0;
    }
    _material = picked;
    _materialDragging = dragging;
    if (commit) {
      _wallRise = 1.0;
      if (!_materialChosen) {
        _materialChosen = true;
        _phase = RaisePhase.assemble;
        _emit(RaiseShelterSignals.materialRaised, data: <String, dynamic>{
          'material': _material.name,
        });
      }
      return;
    }
    _emit(RaiseShelterSignals.materialChosen, data: <String, dynamic>{
      'material': _material.name,
      'dragging': dragging,
    });
  }

  void _onAssembleStep(SimInput input) {
    if (_phase != RaisePhase.assemble) return;
    final AssembleStep? step = _stepFromName(input.param<String>('step'));
    if (step == null) return;

    // The input surface only lets the player grab the CURRENT step, so an
    // out-of-order drop is impossible from the stage. But keep a kind bounce-back
    // nudge for anything that slips through (no destroyed progress, no fail event).
    if (step != currentStep || _done.contains(step)) {
      _nudge = 1.0;
      _emit(RaiseShelterSignals.wrongPart, data: <String, dynamic>{
        'step': step.name,
        'want': currentStep?.name,
      });
      return;
    }

    _done.add(step);
    // Deploy: ease this part in (poles swing up, cover unrolls, stones thunk...).
    _settling = step;
    _settle = 0.0;
    _emit(RaiseShelterSignals.stepDone, data: <String, dynamic>{
      'step': step.name,
      'frame': hasFrame,
      'cover': hasCover,
      'anchor': hasAnchor,
      'smokeHole': hasSmokeHole,
    });

    // Once frame + cover are up, the shelter is assembled enough to test.
    if (canRunTest && _done.length >= 2) {
      _emit(RaiseShelterSignals.assembled, data: <String, dynamic>{
        'anchor': hasAnchor,
        'smokeHole': hasSmokeHole,
      });
    }
  }

  void _onRunTest() {
    if (_phase != RaisePhase.assemble) return;
    if (!canRunTest) return; // need at least frame + cover.
    _phase = RaisePhase.test;
    _testProgress = 0.0;
    _gust = 0.0;
    _strain = 0.0;
    _failProgress = 0.0;
    // Lock the (deterministic) verdict NOW so the build-up can lean toward it.
    _verdict = _predictVerdict();
    _emit(RaiseShelterSignals.testStarted, data: <String, dynamic>{
      'risk': _siteRisk,
      'anchor': hasAnchor,
      'verdict': _verdict!.name,
    });
  }

  @override
  void tick(double dtSeconds) {
    if (_resolved || dtSeconds <= 0) return;

    // Decay the wrong-part nudge ping wherever we are.
    if (_nudge > 0) {
      _nudge = (_nudge - dtSeconds * 3.0).clamp(0.0, 1.0);
    }
    // Ease the just-snapped part's deploy settle toward 1.
    if (_settle < 1.0) {
      _settle = (_settle + dtSeconds / 0.32).clamp(0.0, 1.0);
      if (_settle >= 1.0) _settling = null;
    }

    if (_phase == RaisePhase.chooseMaterial) {
      _tickMaterialRise(dtSeconds);
      return;
    }
    if (_phase != RaisePhase.test) return;

    // Run the wind/rain test over [_testDurationSec] of presentation time, mounting
    // the gusts as it goes, then resolve it as a PURE function of the player's
    // choices (deterministic given the choices). The gust/strain/fail curves below
    // are all derived from the deterministic [_testProgress] accumulator — no clock,
    // no Random — so a fixed input sequence reproduces frame-for-frame.
    _testProgress =
        (_testProgress + dtSeconds / _testDurationSec).clamp(0.0, 1.0);
    _updateStormCurves();

    if (_testProgress < 1.0) return;
    _resolveTest();
  }

  /// While the player holds the dragged material in, RAISE the wall course by
  /// course at the material's pace (the felt tradeoff). When the finger releases
  /// before it tops out the rise settles back a touch (the courses sag) so the
  /// player feels they must commit; once it reaches the top the material is locked
  /// in and we advance to the snap-build assemble phase.
  void _tickMaterialRise(double dt) {
    if (_materialDragging) {
      _wallRise = (_wallRise + dt * _material.riseSpeed * 0.5).clamp(0.0, 1.0);
    } else if (_wallRise > 0 && _wallRise < 1.0) {
      // Released early: the half-laid courses ease back down a little.
      _wallRise = (_wallRise - dt * 0.8).clamp(0.0, 1.0);
    }
    if (_wallRise >= 1.0 && !_materialChosen) {
      _materialChosen = true;
      _phase = RaisePhase.assemble;
      _emit(RaiseShelterSignals.materialRaised, data: <String, dynamic>{
        'material': _material.name,
      });
    }
  }

  /// Recompute the gust / strain / fail telemetry from [_testProgress]. The storm
  /// builds: gusts mount toward a climax near the end, lashing on top. A doomed
  /// build strains far harder and visibly starts to give way past [_breakPoint];
  /// a sound build rides it out with only a light shudder, and a sturdy MATERIAL
  /// shudders even less (the felt tradeoff carried into the storm).
  void _updateStormCurves() {
    final double p = _testProgress;
    // Rising envelope (eased) + a lashing oscillation that quickens as it builds.
    final double envelope = p * p * (3 - 2 * p); // smoothstep ramp-up
    final double lash =
        0.5 + 0.5 * math.sin(p * math.pi * 9.0) * (0.35 + 0.65 * p);
    _gust = (0.25 + 0.75 * envelope * lash).clamp(0.0, 1.0);

    // A sturdy material rides the gust calmer (scales the strain shudder down).
    final double steadiness = 0.55 + 0.45 * _material.sturdiness;

    final StormVerdict v = _verdict ?? StormVerdict.holds;
    if (v == StormVerdict.holds) {
      // A sound build barely strains — a brave little shudder, no fail arc.
      _strain = (_gust * 0.32 * steadiness).clamp(0.0, 1.0);
      _failProgress = 0.0;
    } else {
      // A doomed build strains hard and, past the break point, begins to go.
      _strain = ((0.35 + 0.65 * _gust) * steadiness).clamp(0.0, 1.0);
      _failProgress = p <= _breakPoint
          ? 0.0
          : ((p - _breakPoint) / (1.0 - _breakPoint)).clamp(0.0, 1.0);
    }
  }

  /// The deterministic verdict: a low SITE floods first (the headline lesson);
  /// otherwise a missing ANCHOR lets the wind take it; otherwise it STANDS.
  void _resolveTest() {
    if (_resolved) return;

    // 1) SITE — built on low flood-risk ground: the rain pools and floods it.
    if (_siteRisk >= _floodRiskThreshold) {
      _fail(RaiseShelterSignals.lowSiteFlooded,
          'The rain pooled around the low ground and flooded the shelter.');
      return;
    }

    // 2) ANCHOR — frame + cover up but never weighted: the wind lifts it.
    if (!hasAnchor) {
      _fail(RaiseShelterSignals.poorAnchorBlownOver,
          'A gust caught the unanchored cover and the shelter blew over.');
      return;
    }

    // 3) It STANDS — high ground + anchored. Success.
    _phase = RaisePhase.stood;
    _resolved = true;
    _emit(RaiseShelterSignals.stoodTheStorm,
        message: 'The shelter holds through the storm — warm and dry!',
        data: <String, dynamic>{
          'material': _material.name,
          'smokeHole': hasSmokeHole,
          'siteRisk': _siteRisk,
        });
  }

  void _fail(String code, String message) {
    if (_resolved) return;
    _resolved = true;
    // A failed test snaps the phase back so the chrome shows the wreck + retry.
    if (_phase == RaisePhase.test) _phase = RaisePhase.assemble;
    _emit(code, message: message);
  }

  void _emit(String code, {String message = '', Map<String, dynamic>? data}) {
    if (_events.isClosed) return;
    _events.add(SimEvent(code,
        message: message, data: data ?? const <String, dynamic>{}));
  }

  @override
  void dispose() {
    if (!_events.isClosed) _events.close();
  }
}
