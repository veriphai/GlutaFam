// Ember — concepts/tools/knapping_scene.dart
//
// KnappingScene: the Flame STAGE for the Knapping interact beat — PHASE-2 redesign
// to the "direct, same-frame, on-stage manipulation" quality bar. The interaction
// is no longer "read a card then tap a button"; the kid manipulates the rendered
// stone DIRECTLY:
//
//   * STONE PICK — three candidate stones sit ON the slab. Drag one onto the core
//     socket. A glassy stone (flint / obsidian) SEATS with a snap; a soft / dull
//     stone (sandstone / granite) CRUMBLES into a dull puff right where you drop it
//     (the MATERIAL lesson, felt — the wrong stone never even becomes a core).
//   * STRIKE — drag DIRECTLY on the seated core to pull the hammerstone back. The
//     pull's slant off the core face is the ANGLE, its length the FORCE; a live
//     good-angle WEDGE on the core glows green / amber / red so the kid self-
//     corrects BEFORE releasing. On release the hammerstone swings down and lands
//     ON the stone they see crack: a clean flake springs free, or it shatters, or
//     it dully bounces — each with distinct visuals + graded haptics. The core's
//     knapped edge literally SHARPENS (a BlendMode.plus glint brightens) as flake-
//     progress climbs.
//   * HAFT (optional) — drag the wooden shaft up onto the finished blade; it snaps
//     into place and a woundLashing winding flourish binds it into a spear.
//
// The scene subclasses [ActivityScene] and overrides the three leaf hooks:
//   * buildInteractSim()     — the [KnappingSim] brain (unchanged frozen logic),
//   * buildInteractStage()   — the bespoke Flame props (slab + candidates + core +
//                              hammerstone + shaft), all geometry derived from
//                              game.size so the components are near-pure render()
//                              readers (the electricity "controller owns geometry"
//                              shape),
//   * buildInteractOverlay() — the thin full-screen [KnappingStageOverlay] (a
//                              transparent drag surface + ONE EmberCaption + retry).
//
// CONTRACT: the scene NEVER mutates world state. It only sets controller.placeHint
// and calls the controller's input/retry/finish plumbing; the host folds the
// result through the reducer. Determinism is preserved (no clock/Random feeds the
// sim; the stage's own animation clocks are presentation-only).

import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../activity/activity_result.dart';
import '../../activity/activity_scene.dart';
import '../../activity/activity_sim.dart';
import '../../art/art_keys.dart';
import '../../art/craft_kit.dart';
import '../../art/ember_palette.dart';
import '../../art/ember_particles.dart';
import '../../core/enums.dart';
import '../../core/geometry.dart';
import '../../game/ember_game.dart';
import '../../ui/widgets/ember_caption.dart';
import 'knapping_activity.dart';
import 'knapping_sim.dart';
import 'model/tool.dart';
import 'strike_resolver.dart';
import 'tools_widgets.dart';

/// The Knapping interact stage.
class KnappingScene extends ActivityScene {
  KnappingScene(super.activity, super.controller, {GridCoord? siteCoord})
      : _siteCoord = siteCoord;

  /// Where the resulting Knapping Station should be dropped after success — near
  /// the camp centre. If not supplied it is resolved from the live world (the
  /// village site tile, nudged one tile so it doesn't sit on the hearth).
  final GridCoord? _siteCoord;

  /// The resolved drop site (one tile east of the village site, or a fallback).
  GridCoord get siteCoord {
    if (_siteCoord != null) return _siteCoord;
    if (isMounted) {
      final GridCoord site = game.bridge.state.village.siteTile;
      return GridCoord(site.x + 1, site.y);
    }
    return const GridCoord(1, 0);
  }

  /// The Flutter-side view-model the full-screen overlay listens to.
  final KnappingInteractView view = KnappingInteractView();

  KnappingSim? _knapSim;
  StreamSubscription<SimEvent>? _sub;

  /// The on-canvas slab rig: candidate stones, the core socket, the hammerstone,
  /// and the haft shaft — one component so all the props share a frame + the drag
  /// resolves against one geometry source.
  _KnapRig? _rig;

  EmberParticles get _particles => EmberParticles(palette: _palette);
  EmberPalette get _palette => art.palette;

  // ===========================================================================
  // Leaf overrides
  // ===========================================================================

  @override
  ActivitySim buildInteractSim() {
    final KnappingSim sim = KnappingSim();
    _knapSim = sim;
    _sub?.cancel();
    _sub = sim.events.listen(_onSimEvent);
    return sim;
  }

  @override
  Future<void> buildInteractStage() async {
    final Vector2 stageSize = game.size.clone();
    // The action lives in the upper-middle band so the bottom caption never
    // covers the core. The rig derives every prop position from this anchor +
    // the stage width so components stay near-pure render() readers.
    final Vector2 anchor = Vector2(stageSize.x / 2, stageSize.y * 0.42);

    final _KnapRig rig = _KnapRig(
      palette: _palette,
      actionAt: anchor,
      stageWidth: stageSize.x,
      reduceMotion: _reduceMotion,
    )..priority = 20;
    _rig = rig;
    await add(rig);
  }

  bool get _reduceMotion {
    if (!isMounted) return false;
    return game.disableAnimations;
  }

  /// The full-screen interact chrome: a transparent drag surface + ONE caption +
  /// retry. The host mounts this Positioned.fill over the Flame stage; its drags
  /// are forwarded to [_onDrag*] which map them onto the on-stage props.
  @override
  Widget buildInteractOverlay(BuildContext context) {
    return KnappingStageOverlay(
      view: view,
      palette: _palette,
      onDragStart: _onDragStart,
      onDragUpdate: _onDragUpdate,
      onDragEnd: _onDragEnd,
      onSkipHaft: skipHaft,
      onRetry: retryAttempt,
    );
  }

  // ===========================================================================
  // Drag routing — the heart of the on-stage manipulation. A screen-local point
  // maps 1:1 to a stage point (activity camera is centred, zoom 1.0), so we hand
  // the rig the raw local Offset as a stage coordinate and let it resolve which
  // prop is grabbed for the CURRENT phase.
  // ===========================================================================

  void _onDragStart(Offset local) {
    if (view.failed) return; // gestures are dead until retry clears the failure.
    final Vector2 at = Vector2(local.dx, local.dy);
    _rig?.onDragStart(at, _knapSim?.phase ?? KnappingPhase.chooseStone);
  }

  void _onDragUpdate(Offset local) {
    if (view.failed) return;
    final Vector2 at = Vector2(local.dx, local.dy);
    _rig?.onDragUpdate(at);
  }

  void _onDragEnd(Offset local) {
    if (view.failed) {
      _rig?.cancelDrag();
      return;
    }
    final _DragResolution? r = _rig?.onDragEnd();
    if (r == null) return;
    switch (r.kind) {
      case _DragKind.seatStone:
        chooseStone(r.material!);
      case _DragKind.strike:
        strike(r.angleDeg!, r.force!);
      case _DragKind.haft:
        haft();
      case _DragKind.none:
        break;
    }
  }

  // ===========================================================================
  // Input forwarding (called by the drag router via the rig's resolution)
  // ===========================================================================

  void chooseStone(StoneMaterial material) {
    sendInput(SimInput(KnappingSignals.inChooseStone, <String, dynamic>{
      'material': material.name,
    }));
    _syncView();
  }

  void strike(double angleDeg, double force) {
    // The hammerstone has already swung down on release (the rig drives the swing
    // visual). The contact recoil + a faint dust puff sell the hit BEFORE the
    // resolver decides; the OUTCOME visuals (crack / shatter / dull) are added by
    // the event handlers once the resolver returns, so each result reads distinct.
    _rig?.playStrikeImpact(force);
    final _KnapRig? rig = _rig;
    if (rig != null) {
      add(_particles.build(ParticleArtKey.dust,
          intensity: (0.2 + 0.3 * force).clamp(0.2, 0.6))
        ..position = rig.coreWorld
        ..priority = 48);
    }
    sendInput(SimInput(KnappingSignals.inStrike, <String, dynamic>{
      'angleDeg': angleDeg,
      'force': force,
    }));
    _syncView();
  }

  void haft() {
    sendInput(const SimInput(KnappingSignals.inHaft));
    _syncView();
  }

  void skipHaft() {
    sendInput(const SimInput(KnappingSignals.inSkipHaft));
    _syncView();
  }

  /// Re-arm after a failure (clears the view + the on-canvas rig).
  void retryAttempt() {
    retry();
    view.reset();
    _rig?.reset();
  }

  // ===========================================================================
  // Sim event handling -> view + canvas
  // ===========================================================================

  void _onSimEvent(SimEvent e) {
    switch (e.code) {
      case StrikeSignals.bladeFinished:
        _onFinished(e);
      case StrikeSignals.cleanFlake:
        _onCleanFlake(e);
      case StrikeSignals.wrongMaterial:
        _onWrongMaterial(e);
      case StrikeSignals.tooWeak:
        _onFailure(e, hard: false);
      case StrikeSignals.shattered:
        _onFailure(e, hard: true);
      case StrikeSignals.stoneChosen:
        // A glassy stone seated successfully — the rig already snapped it into the
        // socket on the resolved drag; now move the caption to the strike phase.
        _rig?.setCoreMaterial(_knapSim?.material);
        _syncView();
      case StrikeSignals.flakeProgress:
        // The blade is shaped — offer the haft. The rig reveals the shaft to drag.
        _rig?.revealShaft();
        _syncView(
          imperative: 'Drag the shaft onto the blade',
          meaning: 'Lash a point to a shaft for a',
          concept: 'spear',
        );
      default:
        _syncView();
    }
  }

  /// A clean flake detached (blade not finished yet): SEE the crack snap across the
  /// core + a chip fly off, and FEEL a crisp medium tap.
  void _onCleanFlake(SimEvent e) {
    HapticFeedback.mediumImpact();
    _rig?.playCleanFlake();
    final Vector2 chipAt = (_rig?.coreWorld.clone() ?? game.size / 2)..y -= 26;
    add(_particles.build(ParticleArtKey.chip, intensity: 1.1)
      ..position = chipAt
      ..priority = 55);
    _syncView(
      imperative: 'Again — same angle',
      meaning: 'Each clean flake hones the',
      concept: 'edge',
    );
  }

  void _onFinished(SimEvent e) {
    // Build the made tool from the chosen material + whether it was hafted, then
    // stamp where the first Knapping Station lands (carrying that tool's ext) so
    // the village immediately gets the felt multiplier.
    final KnappingSim? sim = _knapSim;
    final StoneMaterial material = sim?.material ?? StoneMaterial.flint;
    final bool hafted = sim?.hafted ?? false;
    final Tool tool = const StrikeResolver()
        .toolFor(material, hafted: hafted, fireTreated: false, tier: 1);

    controller.placeHint = PlaceHint(
      type: PlaceableType.knappingStation,
      coord: siteCoord,
      tier: 1,
      built: true,
      ext: tool.toExt(),
    );

    _rig?.finishSharp(hafted: hafted);
    // A satisfying double-tap: the last clean flake, then the "it's sharp" ping.
    HapticFeedback.mediumImpact();
    Future<void>.delayed(const Duration(milliseconds: 90),
        () => HapticFeedback.lightImpact());
    final Vector2 at = _rig?.coreWorld.clone() ?? (game.size / 2);
    add(_particles.build(ParticleArtKey.spark, intensity: 1.4)
      ..position = (at.clone()..y -= 30)
      ..priority = 60);
    add(_particles.build(ParticleArtKey.chip, intensity: 1.2)
      ..position = at
      ..priority = 60);
    _syncView(
      imperative: 'Sharp!',
      meaning: hafted
          ? 'A hafted point with reach — a'
          : 'A made edge does what hands',
      concept: hafted ? 'spear' : "can't",
      tone: EmberCaptionTone.win,
    );
  }

  /// The MATERIAL teaching failure: a soft / dull stone was dragged in. It never
  /// became a core — it CRUMBLES where it was dropped (a dull puff), so the kid
  /// sees the wrong stone refuse the job, not just read about it.
  void _onWrongMaterial(SimEvent e) {
    HapticFeedback.selectionClick();
    _rig?.crumbleStone();
    final Vector2 at = _rig?.lastDropWorld.clone() ?? (game.size / 2);
    add(_particles.build(ParticleArtKey.dust, intensity: 0.9)
      ..position = at
      ..priority = 42);
    _syncView(
      imperative: 'It crumbled — pick glassy',
      meaning: e.message,
      tone: EmberCaptionTone.warn,
      failed: true,
    );
  }

  /// A strike teaching failure: a soft tap that did nothing (hard==false), or an
  /// over-strike that SHATTERED the core (hard==true). The visual + haptic differ
  /// so the body learns "too hard" from "too soft", not just the text.
  void _onFailure(SimEvent e, {required bool hard}) {
    final Vector2 at = _rig?.coreWorld.clone() ?? (game.size / 2);
    if (hard) {
      HapticFeedback.heavyImpact();
      _rig?.shatter();
      add(_particles.build(ParticleArtKey.chip, intensity: 1.3)
        ..position = (at.clone()..y -= 20)
        ..priority = 55);
      add(_particles.build(ParticleArtKey.dust, intensity: 1.0)
        ..position = at
        ..priority = 40);
      _syncView(
        imperative: 'Shattered — ease off',
        meaning: e.message,
        tone: EmberCaptionTone.warn,
        failed: true,
      );
    } else {
      HapticFeedback.selectionClick();
      _rig?.dullBounce();
      add(_particles.build(ParticleArtKey.dust, intensity: 0.7)
        ..position = at
        ..priority = 40);
      _syncView(
        imperative: 'Too soft — pull harder',
        meaning: e.message,
        tone: EmberCaptionTone.warn,
        failed: true,
      );
    }
  }

  void _syncView({
    String? imperative,
    String? meaning,
    String? concept,
    EmberCaptionTone? tone,
    bool? failed,
  }) {
    final KnappingSim? sim = _knapSim;
    if (sim == null) return;
    view.sync(
      sim,
      imperative: imperative,
      meaning: meaning,
      concept: concept,
      tone: tone,
      failed: failed,
    );
    _rig?.setFlake(sim.flake);
    _rig?.setPhase(sim.phase);
  }

  // ===========================================================================
  // Lifecycle
  // ===========================================================================

  @override
  void onRemove() {
    _sub?.cancel();
    _sub = null;
    view.dispose();
    super.onRemove();
  }
}

// =============================================================================
// Drag resolution — what a finished drag MEANS for the current phase.
// =============================================================================

enum _DragKind { none, seatStone, strike, haft }

class _DragResolution {
  const _DragResolution.none()
      : kind = _DragKind.none,
        material = null,
        angleDeg = null,
        force = null;
  const _DragResolution.seat(this.material)
      : kind = _DragKind.seatStone,
        angleDeg = null,
        force = null;
  const _DragResolution.strike(this.angleDeg, this.force)
      : kind = _DragKind.strike,
        material = null;
  const _DragResolution.haft()
      : kind = _DragKind.haft,
        material = null,
        angleDeg = null,
        force = null;

  final _DragKind kind;
  final StoneMaterial? material;
  final double? angleDeg;
  final double? force;
}

/// One candidate stone resting on the slab, draggable onto the core socket.
class _Candidate {
  _Candidate({
    required this.material,
    required this.home,
    required this.glassy,
    required this.color,
  }) : pos = home.clone();

  final StoneMaterial material;
  final Vector2 home; // resting spot on the slab (stage coords)
  final bool glassy;
  final Color color;

  /// Live position (follows the finger while grabbed, eases home otherwise).
  Vector2 pos;

  /// True once consumed (seated as the core or crumbled) — hidden thereafter.
  bool gone = false;
}

// =============================================================================
// _KnapRig — the on-stage prop rig. Owns ALL geometry (derived from the anchor +
// stage width) so it is the single source the drag resolves against, and renders
// the slab, candidate stones, the seated core (volumetric via CraftKit), the
// hammerstone swing-arm + live good-angle wedge, the haft shaft, and every
// per-outcome reaction. Pure presentation: its clocks drive only visuals, never
// world state, so the scored sim stays deterministic.
// =============================================================================

class _KnapRig extends PositionComponent with HasGameReference<EmberGame> {
  _KnapRig({
    required this.palette,
    required this.actionAt,
    required this.stageWidth,
    required this.reduceMotion,
  }) : super(position: Vector2.zero(), anchor: Anchor.topLeft);

  final EmberPalette palette;

  /// The action anchor (the core sits a little above it on the slab).
  final Vector2 actionAt;
  final double stageWidth;
  final bool reduceMotion;

  // ---- Geometry (all derived from actionAt + stageWidth) -----------------
  late final Vector2 _coreAt = Vector2(actionAt.x, actionAt.y);
  late final double _slabW = math.min(320, stageWidth * 0.82);
  late final Vector2 _slabAt = Vector2(actionAt.x, actionAt.y + 54);
  static const double _coreR = 30.0;

  /// The candidate stones laid out on the slab (resolved on load).
  final List<_Candidate> _candidates = <_Candidate>[];

  // ---- Live phase + level -------------------------------------------------
  KnappingPhase _phase = KnappingPhase.chooseStone;
  double _flake = 0.0;
  StoneMaterial? _coreMaterial; // null until a glassy stone seats.

  // ---- Drag state ---------------------------------------------------------
  _Candidate? _grabbed; // the stone currently being dragged (pick phase)
  Vector2? _strikeDrag; // the live strike pull vector (strike phase), or null
  Vector2? _haftDrag; // the live haft drag offset (haft phase), or null
  Vector2 _lastDrop = Vector2.zero(); // where the last grab was released

  // ---- The haft shaft -----------------------------------------------------
  bool _shaftRevealed = false;
  bool _hafted = false;
  Vector2 get _shaftHome =>
      Vector2(actionAt.x + _slabW * 0.36, actionAt.y + 18);
  Vector2 _shaftPos = Vector2.zero();

  // ---- Transient reaction clocks (seconds remaining; 0 = idle) -----------
  double _t = 0.0;
  double _impact = 0.0; // squash recoil after a strike lands
  double _swing = 0.0; // hammerstone swing-down arc on release
  Vector2 _swingFrom = Vector2.zero(); // where the hammerstone swung from
  double _swingForce = 0.0;
  double _crack = 0.0; // crack snap + flake fly
  double _shatter = 0.0; // shards drift
  double _dull = 0.0; // dead wobble
  double _finish = 0.0; // edge-glint celebration
  double _crumble = 0.0; // wrong-material crumble puff
  double _seatPop = 0.0; // a good stone snapping into the socket
  double _lashing = 0.0; // haft binding flourish

  static const double _impactDur = 0.16;
  static const double _swingDur = 0.18;
  static const double _crackDur = 0.55;
  static const double _shatterDur = 0.9;
  static const double _dullDur = 0.3;
  static const double _finishDur = 1.2;
  static const double _crumbleDur = 0.6;
  static const double _seatDur = 0.34;
  static const double _lashDur = 0.9;

  /// The core's stage-space position (for particle spawns by the scene).
  Vector2 get coreWorld => _coreAt.clone();

  /// Where the last stone was dropped (for the crumble puff spawn).
  Vector2 get lastDropWorld => _lastDrop.clone();

  @override
  Future<void> onLoad() async {
    _layoutCandidates();
    _shaftPos = _shaftHome.clone();
  }

  /// Three candidate stones across the slab: a glassy flint + glassy obsidian +
  /// one soft/dull decoy (sandstone). Granite is folded out to keep three clean
  /// drag targets on a small stage; the soft sandstone teaches the MATERIAL fail.
  void _layoutCandidates() {
    final List<({StoneMaterial m, bool glassy, Color c})> defs =
        <({StoneMaterial m, bool glassy, Color c})>[
      (m: StoneMaterial.flint, glassy: true, c: palette.stoneChip),
      (m: StoneMaterial.sandstone, glassy: false, c: palette.highGround),
      (m: StoneMaterial.obsidian, glassy: true, c: palette.night),
    ];
    final double spread = _slabW * 0.62;
    for (int i = 0; i < defs.length; i++) {
      final double fx = defs.length == 1 ? 0.5 : i / (defs.length - 1);
      final Vector2 home = Vector2(
        _slabAt.x - spread / 2 + spread * fx,
        _slabAt.y - 4,
      );
      _candidates.add(_Candidate(
        material: defs[i].m,
        home: home,
        glassy: defs[i].glassy,
        color: defs[i].c,
      ));
    }
  }

  // ---- State setters (pushed by the scene) -------------------------------
  void setPhase(KnappingPhase p) => _phase = p;
  void setFlake(double v) => _flake = v.clamp(0.0, 1.0);
  void setCoreMaterial(StoneMaterial? m) {
    _coreMaterial = m;
    _seatPop = _seatDur; // the seated core pops into the socket.
  }

  void revealShaft() => _shaftRevealed = true;

  // ---- Reaction triggers (called by the scene's event handlers) ----------
  void playStrikeImpact(double force) {
    _impact = _impactDur;
    _swing = _swingDur;
    _swingForce = force;
    _swingFrom = _strikeDrag != null
        ? (_coreAt + _strikeDrag!)
        : Vector2(_coreAt.x, _coreAt.y - 70);
    _strikeDrag = null;
  }

  void playCleanFlake() {
    _crack = _crackDur;
    _shatter = 0.0;
    _dull = 0.0;
  }

  void shatter() => _shatter = _shatterDur;
  void dullBounce() => _dull = _dullDur;
  void crumbleStone() => _crumble = _crumbleDur;

  void finishSharp({required bool hafted}) {
    _finish = _finishDur;
    if (hafted) {
      _hafted = true;
      _lashing = _lashDur;
      _haftDrag = null;
    }
  }

  void reset() {
    _phase = KnappingPhase.chooseStone;
    _flake = 0.0;
    _coreMaterial = null;
    _grabbed = null;
    _strikeDrag = null;
    _haftDrag = null;
    _shaftRevealed = false;
    _hafted = false;
    _shaftPos = _shaftHome.clone();
    _impact = _swing = _crack = _shatter = _dull = _finish = 0.0;
    _crumble = _seatPop = _lashing = 0.0;
    for (final _Candidate c in _candidates) {
      c.gone = false;
      c.pos = c.home.clone();
    }
  }

  void cancelDrag() {
    _grabbed = null;
    _strikeDrag = null;
    _haftDrag = null;
  }

  // ===========================================================================
  // Drag handling — resolves the grab against the live geometry for the phase.
  // ===========================================================================

  void onDragStart(Vector2 at, KnappingPhase phase) {
    _phase = phase;
    switch (phase) {
      case KnappingPhase.chooseStone:
        _grabbed = _nearestCandidate(at);
      case KnappingPhase.strike:
        // Begin a strike pull only if the finger lands on/near the core.
        if (at.distanceTo(_coreAt) <= _coreR * 2.4) {
          _strikeDrag = at - _coreAt;
          HapticFeedback.selectionClick();
        }
      case KnappingPhase.haft:
        if (_shaftRevealed && at.distanceTo(_shaftPos) <= 46) {
          _haftDrag = at - _shaftPos;
          HapticFeedback.selectionClick();
        }
      case KnappingPhase.finished:
        break;
    }
  }

  void onDragUpdate(Vector2 at) {
    switch (_phase) {
      case KnappingPhase.chooseStone:
        if (_grabbed != null) _grabbed!.pos = at.clone();
      case KnappingPhase.strike:
        if (_strikeDrag != null) _strikeDrag = at - _coreAt;
      case KnappingPhase.haft:
        if (_haftDrag != null) _shaftPos = at - _haftDrag!;
      case KnappingPhase.finished:
        break;
    }
  }

  /// Resolve the release into a scene action. Returns null if nothing actionable
  /// (e.g. a stone dropped short of the core just eases home).
  _DragResolution? onDragEnd() {
    switch (_phase) {
      case KnappingPhase.chooseStone:
        final _Candidate? g = _grabbed;
        _grabbed = null;
        if (g == null) return null;
        _lastDrop = g.pos.clone();
        // Only counts as a choice if dropped ONTO the core socket.
        if (g.pos.distanceTo(_coreAt) <= _coreR * 1.7) {
          g.gone = true; // it leaves the slab (becomes the core, or crumbles).
          return _DragResolution.seat(g.material);
        }
        g.pos = g.home.clone(); // dropped short — slide back home.
        return const _DragResolution.none();

      case KnappingPhase.strike:
        final Vector2? d = _strikeDrag;
        if (d == null) return null;
        final (double angleDeg, double force) = _toStrike(d);
        HapticFeedback.lightImpact();
        return _DragResolution.strike(angleDeg, force);

      case KnappingPhase.haft:
        final Vector2? h = _haftDrag;
        _haftDrag = null;
        if (h == null) return null;
        // Snap onto the blade if the shaft tip reached the core.
        if (_shaftPos.distanceTo(_coreAt) <= _coreR * 2.2) {
          return const _DragResolution.haft();
        }
        _shaftPos = _shaftHome.clone();
        return const _DragResolution.none();

      case KnappingPhase.finished:
        return null;
    }
  }

  _Candidate? _nearestCandidate(Vector2 at) {
    _Candidate? best;
    double bestD = 52.0; // grab radius
    for (final _Candidate c in _candidates) {
      if (c.gone) continue;
      final double d = at.distanceTo(c.pos);
      if (d < bestD) {
        bestD = d;
        best = c;
      }
    }
    return best;
  }

  /// Maps a strike pull vector (from the core) to (angleDeg off the face, force).
  /// Mirrors the old aim-pad math so the resolver thresholds still line up.
  (double, double) _toStrike(Vector2 d) {
    final double len = d.length;
    final double force = (len / 118.0).clamp(0.0, 1.0);
    final double up = -d.y; // upward is negative-y in screen/stage space
    final double horiz = d.x.abs();
    final double effUp = up <= 1 ? 1 : up;
    final double angleDeg = math.atan2(horiz, effUp) * 180.0 / math.pi;
    return (angleDeg.clamp(0.0, 180.0), force);
  }

  // ---- The live strike verdict (colours the wedge while pulling) ----------
  _Verdict get _verdict {
    final Vector2? d = _strikeDrag;
    if (d == null) return _Verdict.idle;
    final (double angle, double force) = _toStrike(d);
    final bool angleOk = (angle - StrikeResolver.idealAngleDeg).abs() <=
        StrikeResolver.angleToleranceDeg;
    if (force < StrikeResolver.minForce) return _Verdict.tooSoft;
    if (force > StrikeResolver.maxForce) return _Verdict.tooHard;
    if (!angleOk) return _Verdict.offAngle;
    return _Verdict.good;
  }

  // ===========================================================================
  // Update + render
  // ===========================================================================

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _impact = math.max(0.0, _impact - dt);
    _swing = math.max(0.0, _swing - dt);
    _crack = math.max(0.0, _crack - dt);
    _shatter = math.max(0.0, _shatter - dt);
    _dull = math.max(0.0, _dull - dt);
    _finish = math.max(0.0, _finish - dt);
    _crumble = math.max(0.0, _crumble - dt);
    _seatPop = math.max(0.0, _seatPop - dt);
    _lashing = math.max(0.0, _lashing - dt);

    // Idle candidates ease home (snap-back after a short drop).
    for (final _Candidate c in _candidates) {
      if (c.gone || identical(c, _grabbed)) continue;
      final Vector2 want = c.home;
      c.pos += (want - c.pos) * (1.0 - math.exp(-dt / 0.09));
    }
    // The shaft eases home when not grabbed + not yet hafted.
    if (_haftDrag == null && !_hafted) {
      _shaftPos += (_shaftHome - _shaftPos) * (1.0 - math.exp(-dt / 0.1));
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _drawSlab(canvas);

    // The candidate stones resting on / being dragged across the slab.
    if (_phase == KnappingPhase.chooseStone) {
      for (final _Candidate c in _candidates) {
        if (c.gone) continue;
        _drawCandidate(canvas, c);
      }
    }

    // The seated core + its growing edge + reactions (once a stone is seated).
    if (_coreMaterial != null || _shatter > 0 || _crumble > 0) {
      _drawCore(canvas);
    }

    // The crumble puff sits where the wrong stone was dropped.
    if (_crumble > 0) _drawCrumble(canvas);

    // The strike phase: the live good-angle wedge on the core + the pull arm.
    if (_phase == KnappingPhase.strike) {
      _drawWedge(canvas);
      _drawPull(canvas);
    }
    // The hammerstone swing-down on release.
    if (_swing > 0) _drawSwing(canvas);

    // The haft phase: the shaft to drag onto the blade + the binding flourish.
    if (_phase == KnappingPhase.haft || _hafted) {
      _drawShaft(canvas);
    }
  }

  // ---- Slab ---------------------------------------------------------------
  void _drawSlab(Canvas canvas) {
    final Rect slab = Rect.fromCenter(
      center: Offset(_slabAt.x, _slabAt.y),
      width: _slabW,
      height: 46,
    );
    CraftKit.groundContactEllipse(canvas,
        center: Offset(_slabAt.x, _slabAt.y + 22), width: _slabW * 0.96);
    final RRect r = RRect.fromRectAndRadius(slab, const Radius.circular(12));
    canvas.drawRRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[palette.rock, palette.rockDark],
        ).createShader(slab),
    );
    canvas.drawRRect(
      r,
      Paint()
        ..color = palette.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  // ---- A candidate stone (glassy = sheen swatch; soft = matte grainy) ------
  void _drawCandidate(Canvas canvas, _Candidate c) {
    final bool grabbed = identical(c, _grabbed);
    final Offset o = Offset(c.pos.x, c.pos.y);
    const double rad = 19;
    CraftKit.groundContactEllipse(canvas,
        center: o + const Offset(0, 14),
        width: rad * (grabbed ? 2.6 : 2.2),
        strength: grabbed ? 1.0 : 0.7);

    // A faceted lump.
    final Path lump = Path()
      ..moveTo(o.dx - rad, o.dy + 4)
      ..lineTo(o.dx - rad * 0.6, o.dy - rad * 0.7)
      ..lineTo(o.dx + rad * 0.1, o.dy - rad)
      ..lineTo(o.dx + rad * 0.8, o.dy - rad * 0.4)
      ..lineTo(o.dx + rad * 0.7, o.dy + rad * 0.4)
      ..close();
    canvas.drawPath(lump, Paint()..color = c.color);

    if (c.glassy) {
      // A bright specular sheen streak = "glassy" (the tell it can flake).
      canvas.drawLine(
        Offset(o.dx - rad * 0.5, o.dy + 2),
        Offset(o.dx + rad * 0.1, o.dy - rad * 0.7),
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.55)
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6),
      );
    } else {
      // Grainy matte speckle = "soft" (deterministic, no Random).
      for (int i = 0; i < 7; i++) {
        final double hx = ((i * 37) % 100) / 100.0;
        final double hy = ((i * 53) % 100) / 100.0;
        canvas.drawCircle(
          Offset(o.dx - rad * 0.7 + rad * 1.4 * hx, o.dy - rad * 0.7 + rad * hy),
          i.isEven ? 1.2 : 0.9,
          Paint()
            ..color = (i % 3 == 0
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xFF000000))
                .withValues(alpha: 0.4),
        );
      }
    }
    canvas.drawPath(
      lump,
      Paint()
        ..color = palette.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    // The grabbed stone gets a soft lift ring so it reads as "in hand".
    if (grabbed) {
      canvas.drawCircle(
        o,
        rad + 6,
        Paint()
          ..color = palette.ember.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }

  // ---- The seated core: volumetric, faceted, with a sharpening edge --------
  void _drawCore(Canvas canvas) {
    final double r = _coreR;
    final Offset c = Offset(_coreAt.x, _coreAt.y);

    // Recoil squash on a strike-land + a dead wobble on a dull tap + a seat-pop
    // squash-stretch when a stone first lands in the socket.
    final double imp = _impact / _impactDur; // 1 -> 0
    final double wobble = _dull > 0
        ? math.sin((_dullDur - _dull) * 38.0) * 0.05 * (_dull / _dullDur)
        : 0.0;
    final double pop = _seatPop / _seatDur; // 1 -> 0
    final double squashY = (1.0 - 0.12 * imp) * (1.0 - 0.18 * pop);
    final double squashX = (1.0 + 0.06 * imp) * (1.0 + 0.12 * pop);

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(wobble);
    canvas.scale(squashX, squashY);
    canvas.translate(-c.dx, -c.dy);

    final double splitGate = _shatter > 0 ? (1.0 - _shatter / _shatterDur) : 0.0;

    if (_shatter > 0) {
      final double splitX = 20.0 * splitGate;
      final double splitDrop = 16.0 * splitGate * splitGate;
      final double splitRot = 0.55 * splitGate;
      _drawCoreHalf(canvas, c, r,
          left: true, dx: -splitX, dy: splitDrop, rot: -splitRot);
      _drawCoreHalf(canvas, c, r,
          left: false, dx: splitX, dy: splitDrop, rot: splitRot);
    } else if (_coreMaterial != null) {
      // The volumetric body via CraftKit.litCylinder (a faceted glassy chunk).
      CraftKit.litCylinder(
        canvas,
        base: Offset(c.dx, c.dy + r * 0.85),
        w: r * 2.0,
        h: r * 1.7,
        body: _coreColor,
        outline: palette.outline,
        specular: 0.7,
        radiusFactor: 0.5,
      );
    }

    // The knapped edge — a faceted sharp side that GROWS with flake-progress.
    final double h = 10 + 30 * _flake;
    if (_flake > 0.02 && _shatter <= 0) {
      final Path edge = Path()
        ..moveTo(c.dx - r * 0.6, c.dy - r * 0.4)
        ..lineTo(c.dx + r * 0.2, c.dy - r - h)
        ..lineTo(c.dx + r * 0.6, c.dy - r * 0.4)
        ..close();
      canvas.drawPath(edge, Paint()..color = palette.stoneChip);
      canvas.drawPath(
        edge,
        Paint()
          ..color = palette.outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    // A fresh crack snapping across the core on a clean flake + a chip flying off.
    if (_crack > 0) {
      final double grow = (1.0 - _crack / _crackDur).clamp(0.0, 1.0);
      final Paint crackP = Paint()
        ..color = palette.background.withValues(alpha: 0.85 * (_crack / _crackDur))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      final Offset a0 = Offset(c.dx - r * 0.5, c.dy - r * 0.3);
      final Offset a1 = Offset(c.dx + r * 0.1, c.dy - r - h * 0.3);
      canvas.drawLine(a0, Offset.lerp(a0, a1, grow)!, crackP);
      final double fly = grow;
      final Offset flakeAt = Offset(
        c.dx + r * 0.2 + 28 * fly,
        c.dy - r - h - 30 * fly + 40 * fly * fly,
      );
      final Path flake = Path()
        ..moveTo(flakeAt.dx, flakeAt.dy)
        ..lineTo(flakeAt.dx + 11, flakeAt.dy + 4)
        ..lineTo(flakeAt.dx + 3, flakeAt.dy + 14)
        ..close();
      canvas.drawPath(
          flake,
          Paint()
            ..color = palette.stoneChip
                .withValues(alpha: (1.0 - fly * 0.6).clamp(0.0, 1.0)));
    }

    canvas.restore();

    // The edge GLINT + halo (drawn unsquashed). A BlendMode.plus bar races the
    // edge — brightening as flake-progress climbs (the edge literally sharpens) —
    // and a single bright sweep + a star ping on the finish celebration.
    if (_flake > 0.02 && _shatter <= 0) {
      _drawEdgeGlint(canvas, c, r, h);
    }
  }

  Color get _coreColor {
    switch (_coreMaterial) {
      case StoneMaterial.obsidian:
        return palette.night;
      case StoneMaterial.sandstone:
        return palette.highGround;
      case StoneMaterial.granite:
        return palette.rockDark;
      case StoneMaterial.flint:
      case null:
        return palette.stoneChip;
    }
  }

  void _drawEdgeGlint(Canvas canvas, Offset c, double r, double h) {
    final bool celebrating = _finish > 0;
    final double phase = celebrating
        ? (1.0 - _finish / _finishDur)
        : (reduceMotion ? 0.5 : (_t * 1.1) % 1.0);
    final double gy = c.dy + (-r * 0.4) - phase * (r + h - r * 0.4) - r;
    final double gx = c.dx - r * 0.6 + phase * (r * 0.8);
    final double baseA = (1.0 - (phase - 0.5).abs() * 2.0).clamp(0.0, 1.0);
    // Idle glint strength CLIMBS with flake-progress — the sharper the edge, the
    // brighter it catches the light.
    final double a = baseA * (celebrating ? 1.0 : _flake * 0.8);
    if (a > 0.02) {
      canvas.drawCircle(
        Offset(gx, gy),
        celebrating ? 4.4 : 2.6 + 1.6 * _flake,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = palette.spark.withValues(alpha: a)
          ..maskFilter =
              MaskFilter.blur(BlurStyle.normal, celebrating ? 2.4 : 1.4),
      );
      if (celebrating) _drawStar(canvas, Offset(gx, gy), 7.0 * baseA, a);
    }

    final double hr = (30 + 34 * _flake) * (celebrating ? 1.0 + 0.4 * baseA : 1.0);
    final Offset haloAt = Offset(c.dx, c.dy - r * 1.4);
    canvas.drawCircle(
      haloAt,
      hr,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: <Color>[
            palette.emberBright.withValues(
                alpha: (celebrating ? 0.22 : 0.10) * _flake +
                    (celebrating ? 0.1 * baseA : 0)),
            palette.ember.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: haloAt, radius: hr)),
    );
  }

  void _drawCoreHalf(Canvas canvas, Offset c, double r,
      {required bool left,
      required double dx,
      required double dy,
      required double rot}) {
    canvas.save();
    canvas.translate(c.dx + dx, c.dy + dy);
    canvas.rotate(rot);
    final Rect full = Rect.fromCenter(
        center: Offset.zero, width: r * 2.0, height: r * 1.7);
    final Rect half = left
        ? Rect.fromLTRB(-full.width / 2, -full.height / 2, 0, full.height / 2)
        : Rect.fromLTRB(0, -full.height / 2, full.width / 2, full.height / 2);
    final Path p = Path()..addOval(half);
    canvas.drawPath(p, Paint()..color = _coreColor);
    canvas.drawPath(
      p,
      Paint()
        ..color = palette.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    canvas.restore();
  }

  // ---- The wrong-material crumble: a dull collapsing puff of grit ----------
  void _drawCrumble(Canvas canvas) {
    final double g = 1.0 - _crumble / _crumbleDur; // 0 -> 1
    final Offset at = Offset(_lastDrop.x, _lastDrop.y);
    final double fade = (1.0 - g).clamp(0.0, 1.0);
    for (int i = 0; i < 8; i++) {
      final double ang = i * math.pi / 4;
      final double spread = 6 + 20 * g;
      final Offset p = at +
          Offset(math.cos(ang) * spread, math.sin(ang) * spread * 0.5 + 8 * g * g);
      canvas.drawCircle(
        p,
        (2.4 - 1.4 * g).clamp(0.4, 2.4),
        Paint()
          ..color = palette.highGroundDark.withValues(alpha: 0.55 * fade),
      );
    }
  }

  // ---- The live good-angle WEDGE on the core (green/amber/red) -------------
  void _drawWedge(Canvas canvas) {
    if (_coreMaterial == null) return;
    // Measured + drawn from the core centre so the live arm + wedge agree with
    // the angle/force the resolver scores on release.
    final Offset coreAt = Offset(_coreAt.x, _coreAt.y);
    const double ideal = StrikeResolver.idealAngleDeg;
    const double tol = StrikeResolver.angleToleranceDeg;
    final double wedgeLen = 96;
    final bool live = _verdict == _Verdict.good;
    for (final double sign in <double>[-1, 1]) {
      _wedge(canvas, coreAt, sign, ideal - tol, ideal + tol, wedgeLen,
          palette.success.withValues(alpha: live ? 0.24 : 0.12));
      for (final double a in <double>[ideal - tol, ideal + tol]) {
        _ray(canvas, coreAt, sign * a, wedgeLen,
            palette.success.withValues(alpha: live ? 0.85 : 0.42),
            live ? 2.6 : 2.0);
      }
    }
  }

  // ---- The strike pull arm + hammerstone held at the finger ----------------
  void _drawPull(Canvas canvas) {
    final Vector2? d = _strikeDrag;
    if (d == null) return;
    final Offset coreAt = Offset(_coreAt.x, _coreAt.y);
    final Color c = switch (_verdict) {
      _Verdict.good => palette.success,
      _Verdict.tooSoft => palette.warning,
      _Verdict.tooHard => palette.danger,
      _Verdict.offAngle => palette.danger,
      _Verdict.idle => palette.ember,
    };
    final Offset tip = Offset(_coreAt.x + d.x, _coreAt.y + d.y);
    canvas.drawLine(
      coreAt,
      tip,
      Paint()
        ..color = c.withValues(alpha: 0.9)
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(tip, 14, Paint()..color = palette.rock);
    canvas.drawCircle(
      tip,
      14,
      Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    canvas.drawCircle(tip + const Offset(-4, -4), 3.4,
        Paint()..color = palette.stoneChip.withValues(alpha: 0.8));
  }

  // ---- The hammerstone swing-down on release (lands ON the core) -----------
  void _drawSwing(Canvas canvas) {
    final double s = 1.0 - _swing / _swingDur; // 0 -> 1
    final Offset from = Offset(_swingFrom.x, _swingFrom.y);
    final Offset to = Offset(_coreAt.x, _coreAt.y);
    final Offset at = Offset.lerp(from, to, Curves.easeIn.transform(s))!;
    final double rad = 13 + 4 * _swingForce;
    canvas.drawCircle(at, rad, Paint()..color = palette.rock);
    canvas.drawCircle(
      at,
      rad,
      Paint()
        ..color = palette.rockDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    // A faint motion streak behind the swing.
    canvas.drawLine(
      from,
      at,
      Paint()
        ..color = palette.stoneChip.withValues(alpha: 0.3 * (1.0 - s))
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  // ---- The haft shaft + the binding lashing flourish -----------------------
  void _drawShaft(Canvas canvas) {
    if (!_shaftRevealed && !_hafted) return;
    // When hafted, the shaft rests under the blade (core); otherwise it sits at
    // its home / follows the drag.
    final Offset base = _hafted
        ? Offset(_coreAt.x, _coreAt.y + 70)
        : Offset(_shaftPos.x, _shaftPos.y + 34);
    final double shaftH = _hafted ? 78 : 64;

    CraftKit.litCylinder(
      canvas,
      base: base,
      w: 12,
      h: shaftH,
      body: palette.wood,
      shade: palette.woodDark,
      outline: palette.outline,
      specular: 0.4,
      contactShadow: !_hafted,
    );

    // The lashing binds the shaft to the blade with a winding flourish that draws
    // ON over its duration (turns appear as the bind completes).
    if (_hafted) {
      final double prog = (1.0 - _lashing / _lashDur).clamp(0.0, 1.0);
      final int turns = (1 + (prog * 3).floor()).clamp(1, 3);
      CraftKit.woundLashing(
        canvas,
        center: Offset(_coreAt.x, _coreAt.y + 6),
        w: 26,
        height: 22,
        turns: turns,
        cord: palette.hideDark,
      );
    } else {
      // A "drag me up" hint pulse on the shaft top while it waits.
      final double pulse =
          reduceMotion ? 0.6 : 0.4 + 0.4 * (0.5 + 0.5 * math.sin(_t * 4.0));
      canvas.drawCircle(
        Offset(_shaftPos.x, _shaftPos.y - 28),
        6,
        Paint()
          ..color = palette.ember.withValues(alpha: 0.5 * pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }

  // ---- Small drawing helpers ----------------------------------------------
  void _ray(Canvas canvas, Offset from, double angleDeg, double len, Color color,
      double w) {
    final double rad = angleDeg * math.pi / 180.0;
    final Offset dir = Offset(math.sin(rad), -math.cos(rad));
    canvas.drawLine(
      from,
      from + dir * len,
      Paint()
        ..color = color
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round,
    );
  }

  void _wedge(Canvas canvas, Offset from, double sign, double a0, double a1,
      double len, Color fill) {
    final double r0 = sign * a0 * math.pi / 180.0;
    final double r1 = sign * a1 * math.pi / 180.0;
    final Path p = Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(from.dx + math.sin(r0) * len, from.dy - math.cos(r0) * len)
      ..lineTo(from.dx + math.sin(r1) * len, from.dy - math.cos(r1) * len)
      ..close();
    canvas.drawPath(p, Paint()..color = fill);
  }

  void _drawStar(Canvas canvas, Offset at, double rad, double alpha) {
    final Paint p = Paint()
      ..color = palette.spark.withValues(alpha: alpha)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(at - Offset(rad, 0), at + Offset(rad, 0), p);
    canvas.drawLine(at - Offset(0, rad), at + Offset(0, rad), p);
    final double d = rad * 0.5;
    canvas.drawLine(at - Offset(d, d), at + Offset(d, d),
        p..color = palette.spark.withValues(alpha: alpha * 0.6));
    canvas.drawLine(at - Offset(d, -d), at + Offset(d, -d), p);
  }
}

/// The live strike verdict — drives the wedge/arm colour so the kid self-corrects
/// BEFORE releasing.
enum _Verdict { idle, tooSoft, good, tooHard, offAngle }
