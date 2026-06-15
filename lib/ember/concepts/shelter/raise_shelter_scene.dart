// Ember — concepts/shelter/raise_shelter_scene.dart
//
// RaiseShelterScene: the Flame STAGE for the Raise a Shelter interact beat. It
// subclasses [ActivityScene] and overrides ONLY the leaf hooks — buildInteractSim()
// (the [RaiseShelterSim] brain), buildInteractStage() (the bespoke VOLUMETRIC props
// built from CraftKit so the build reads hot/solid + lit), and buildInteractOverlay()
// (the full-screen transparent gesture surface + the ONE EmberCaption + retry).
//
// PHASE-2 REDESIGN — the cards-and-buttons are gone; the interaction is DIRECT,
// SAME-FRAME, ON-STAGE:
//   * SITE      — 2-3 candidate spots sit on the iso ground, each with a FELT risk
//                 read (a low/riverbank spot has a faint water-line haze, high
//                 ground is dry). The overlay's tap forwards [chooseSite]; the
//                 chosen-spot's stage component answers that frame.
//   * MATERIAL  — the wall RISES course by course as the player drags the material
//                 in (read off [sim.wallRise]); the pace IS the tradeoff (hide snaps
//                 up, timber climbs). The dwelling visual reads that to lay courses.
//   * ASSEMBLE  — snap-build: each placed part DEPLOYS (frame poles swing up
//                 easeOutBack, cover unrolls, anchor stones thunk, smoke-hole cuts),
//                 eased off [sim.settle]; pulsing dashed ghost slots show the next
//                 part; the overlay handles the generous-radius snap + the kind
//                 wrong-drop bounce. Built from CraftKit.litCylinder (posts) +
//                 woundLashing (lashings) + groundContactEllipse.
//   * TEST      — the storm plays out ON this stage (driving rain, gusts, lightning,
//                 strain, collapse-vs-cozy hard gate) — KEPT from the prior visceral
//                 build, integrated. The verdict is locked at start so the tension
//                 leans true; on success the placement hint is stamped on the SAFE
//                 site coord.
//
// The stage reads the SHARED [ShelterStageLayout] fractions so its props line up
// with the overlay's hit-tests WITHOUT coupling (the "controller owns the geometry"
// shape). It NEVER mutates world state — only sets controller.placeHint + drives the
// input/retry/finish plumbing; the host folds the result through the reducer.

import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../activity/activity_result.dart';
import '../../activity/activity_scene.dart';
import '../../activity/activity_sim.dart';
import '../../art/art_keys.dart';
import '../../art/craft_kit.dart';
import '../../art/ember_art.dart';
import '../../art/ember_palette.dart';
import '../../art/ember_particles.dart';
import '../../core/enums.dart';
import '../../core/geometry.dart';
import '../../data/models/tile.dart';
import '../../data/models/world_state.dart';
import '../../game/ember_game.dart';
import 'model/dwelling.dart';
import 'raise_shelter_activity.dart';
import 'raise_shelter_sim.dart';
import 'shelter_widgets.dart';

/// The Raise a Shelter interact stage.
class RaiseShelterScene extends ActivityScene {
  RaiseShelterScene(super.activity, super.controller);

  /// The Flutter-side view-model the host's overlay listens to.
  final ShelterInteractView view = ShelterInteractView();

  /// The resolved site options (high/safe, mid, low/river) — built on load from
  /// the live world so the chosen safe site maps to a real drop coord.
  List<SiteOption> _sites = const <SiteOption>[];

  /// The resolved offered site options (populated once the interact stage builds).
  /// Exposed read-only so the review tour can replay a real site choice.
  List<SiteOption> get sites => _sites;

  /// The drop coord for each offered site id (resolved from the world).
  final Map<String, GridCoord> _siteCoords = <String, GridCoord>{};

  /// The chosen safe drop coord (set when the player picks a site that holds).
  GridCoord? _chosenSafeCoord;

  RaiseShelterSim? _shelterSim;
  StreamSubscription<SimEvent>? _sub;

  /// The candidate SITE-spot components (felt risk read on the ground).
  final Map<String, _SiteSpotComponent> _spots = <String, _SiteSpotComponent>{};

  /// The on-canvas volumetric build visual that grows with assembly.
  _ShelterStageVisual? _visual;

  /// The pulsing dashed ghost-slot for the current assemble part.
  _GhostSlotComponent? _ghost;

  EmberPalette get _palette => art.palette;
  EmberParticles get _particles => EmberParticles(palette: _palette);

  // ===========================================================================
  // Leaf overrides
  // ===========================================================================

  @override
  ActivitySim buildInteractSim() {
    final RaiseShelterSim sim = RaiseShelterSim();
    _shelterSim = sim;
    _sub?.cancel();
    _sub = sim.events.listen(_onSimEvent);
    return sim;
  }

  @override
  Future<void> buildInteractStage() async {
    _resolveSites();

    final Vector2 stage = game.size.clone();
    Vector2 frac(({double x, double y}) f) =>
        Vector2(f.x * stage.x, f.y * stage.y);

    // The packed-earth build pad under the action (centred on the build anchor).
    final Vector2 buildAt = frac(ShelterStageLayout.buildAnchor);
    final PositionComponent pad = art.shape(
      PrimitiveShape.roundedRect,
      size: Vector2(220, 40),
      fill: _palette.highGround,
      outline: _palette.highGroundDark,
    )
      ..anchor = Anchor.center
      ..position = Vector2(buildAt.x, buildAt.y + 18)
      ..priority = 4;
    await add(pad);

    // The candidate SITE spots on the ground — each paints its FELT risk read (a
    // dry high-ground patch, or a low patch with a rising water-line haze).
    for (final SiteOption s in _sites) {
      final ({double x, double y})? f = ShelterStageLayout.siteSpots[s.id];
      if (f == null) continue;
      final _SiteSpotComponent spot = _SiteSpotComponent(
        palette: _palette,
        risk: s.risk,
        threshold: _floodRiskThreshold,
        position: frac(f),
      )..priority = 6;
      _spots[s.id] = spot;
      await add(spot);
    }

    // The pulsing dashed ghost-slot for the current assemble part (hidden until
    // the assemble phase; positioned per-part from the shared layout).
    final _GhostSlotComponent ghost = _GhostSlotComponent(palette: _palette)
      ..priority = 28;
    _ghost = ghost;
    await add(ghost);

    // The live volumetric build-up shelter visual sits on the pad.
    final _ShelterStageVisual visual = _ShelterStageVisual(
      palette: _palette,
      position: Vector2(buildAt.x, buildAt.y + 14),
    )..priority = 30;
    _visual = visual;
    await add(visual);
  }

  /// The full-screen transparent gesture surface + caption + retry.
  @override
  Widget buildInteractOverlay(BuildContext context) {
    return ShelterInteractPanel(
      view: view,
      palette: _palette,
      sites: _sites,
      floodRiskThreshold: _floodRiskThreshold,
      onChooseSite: chooseSite,
      onMaterialDrag: materialDrag,
      onAssembleStep: assembleStep,
      onRunTest: runTest,
      onRetry: retryAttempt,
    );
  }

  double get _floodRiskThreshold =>
      (activity.interactionRules.config[
                  RaiseShelterSignals.cfgFloodRiskThreshold] as num?)
              ?.toDouble() ??
          0.4;

  // ===========================================================================
  // Site resolution (from the live world)
  // ===========================================================================

  /// Resolve three offered sites near the village: a safe high-ground tile, a
  /// middling grass tile, and a flood-risk riverbank tile. Falls back to sensible
  /// synthetic options if the world isn't mounted.
  void _resolveSites() {
    final List<SiteOption> sites = <SiteOption>[];
    _siteCoords.clear();

    GridCoord? safe;
    GridCoord? mid;
    GridCoord? risky;

    if (isMounted) {
      final EmberWorldState s = game.bridge.state;
      final GridCoord site = s.village.siteTile;
      double bestSafeScore = -1;
      double bestRisky = -1;
      for (int dx = -5; dx <= 5; dx++) {
        for (int dy = -5; dy <= 5; dy++) {
          if (dx == 0 && dy == 0) continue;
          final GridCoord c = site.translate(dx, dy);
          final Tile? t = s.tiles.at(c);
          if (t == null || !t.buildable) continue;
          final double safeScore =
              (t.terrain == TerrainType.highGround ? 1.0 : 0.0) +
                  (1.0 - t.floodRisk);
          if (t.floodRisk < _floodRiskThreshold && safeScore > bestSafeScore) {
            bestSafeScore = safeScore;
            safe = c;
          }
          if (t.floodRisk >= _floodRiskThreshold && t.floodRisk > bestRisky) {
            bestRisky = t.floodRisk;
            risky = c;
          }
          mid ??= (t.floodRisk < _floodRiskThreshold &&
                  t.terrain == TerrainType.grass)
              ? c
              : mid;
        }
      }
    }

    safe ??= const GridCoord(2, 2);
    mid ??= safe.translate(1, 0);
    risky ??= safe.translate(0, 3);

    _siteCoords['site.high'] = safe;
    _siteCoords['site.grass'] = mid;
    _siteCoords['site.river'] = risky;

    sites.add(const SiteOption(
      id: 'site.high',
      label: 'High ground',
      blurb: 'Dry rise above the bank, near water and food.',
      risk: 0.05,
      icon: Icons.terrain,
    ));
    sites.add(const SiteOption(
      id: 'site.grass',
      label: 'Open meadow',
      blurb: 'Flat grass, a little back from the river.',
      risk: 0.2,
      icon: Icons.grass,
    ));
    sites.add(const SiteOption(
      id: 'site.river',
      label: 'River bank',
      blurb: 'Right by the water — easiest fishing, but it sits low.',
      risk: 0.8,
      icon: Icons.water,
    ));

    _sites = sites;
  }

  // ===========================================================================
  // Input forwarding (called by the overlay surface / the review tour)
  // ===========================================================================

  void chooseSite(SiteOption site) {
    sendInput(SimInput(RaiseShelterSignals.inChooseSite, <String, dynamic>{
      'risk': site.risk,
      'siteId': site.id,
    }));
    // The chosen spot blooms in; the others fade back.
    for (final MapEntry<String, _SiteSpotComponent> e in _spots.entries) {
      e.value.setChosen(e.key == site.id);
    }
    _syncView();
  }

  /// The public one-shot material commit (the review tour + any programmatic
  /// driver use this — it fully raises the wall in one call). The felt drag path
  /// goes through [materialDrag].
  void chooseMaterial(ShelterMaterial material) {
    sendInput(SimInput(RaiseShelterSignals.inChooseMaterial, <String, dynamic>{
      'material': material.name,
      'dragging': true,
      'commit': true,
    }));
    _syncView();
  }

  /// The FELT material drag: while [dragging] the wall rises course by course at
  /// the material's pace; release stops it (and a topped-out wall commits).
  void materialDrag(ShelterMaterial material, bool dragging) {
    sendInput(SimInput(RaiseShelterSignals.inChooseMaterial, <String, dynamic>{
      'material': material.name,
      'dragging': dragging,
    }));
    _syncView();
  }

  void assembleStep(AssembleStep step) {
    sendInput(SimInput(RaiseShelterSignals.inAssembleStep, <String, dynamic>{
      'step': step.name,
    }));
    _syncView();
    // A small dust kick on each placed piece for tactile feedback.
    final _ShelterStageVisual? v = _visual;
    if (v != null) {
      add(_particles.build(ParticleArtKey.dust, intensity: 0.5)
        ..position = v.position.clone()
        ..priority = 50);
    }
  }

  void runTest() {
    sendInput(const SimInput(RaiseShelterSignals.inRunTest));
    _syncView();
    _rainBurstClock = 999; // force an immediate first rain burst next frame.
    final _ShelterStageVisual? v = _visual;
    if (v != null) {
      add(_particles.build(ParticleArtKey.rain, intensity: 0.8)
        ..position = Vector2(v.position.x, v.position.y - 130)
        ..priority = 45);
    }
  }

  /// Re-arm after a failure (clears the view + on-canvas visual + site spots).
  void retryAttempt() {
    retry();
    view.reset();
    _visual?.reset();
    for (final _SiteSpotComponent spot in _spots.values) {
      spot.setChosen(false);
    }
  }

  // ===========================================================================
  // Sim event handling -> view + canvas
  // ===========================================================================

  void _onSimEvent(SimEvent e) {
    switch (e.code) {
      case RaiseShelterSignals.stoodTheStorm:
        _onStood(e);
      case RaiseShelterSignals.lowSiteFlooded:
        _onFloodFail(e);
      case RaiseShelterSignals.poorAnchorBlownOver:
      case RaiseShelterSignals.coverBeforeFrame:
        _onWindFail(e);
      case RaiseShelterSignals.siteChosen:
        _syncView();
      case RaiseShelterSignals.stepDone:
        _visual?.setFromSteps(
          frame: (e.data['frame'] as bool?) ?? false,
          cover: (e.data['cover'] as bool?) ?? false,
          anchor: (e.data['anchor'] as bool?) ?? false,
          smokeHole: (e.data['smokeHole'] as bool?) ?? false,
        );
        // Thunk dust on an anchor; a soft puff otherwise.
        final String? step = e.data['step'] as String?;
        final _ShelterStageVisual? v = _visual;
        if (v != null) {
          add(_particles.build(ParticleArtKey.dust,
              intensity: step == AssembleStep.anchor.name ? 1.0 : 0.5)
            ..position = v.position.clone()
            ..priority = 50);
        }
        _syncView();
      case RaiseShelterSignals.wrongPart:
        _ghost?.bounce();
        _syncView();
      default:
        _syncView(hint: e.message.isEmpty ? null : e.message);
    }
  }

  void _onStood(SimEvent e) {
    final GridCoord coord =
        _chosenSafeCoord ?? _siteCoords['site.high'] ?? const GridCoord(2, 2);
    final DwellingType type =
        (e.data['material'] as String?) == ShelterMaterial.hut.name
            ? DwellingType.hut
            : DwellingType.hideTent;
    controller.placeHint = PlaceHint(
      type: placeableTypeForDwelling(type),
      coord: coord,
      tier: 1,
      built: true,
      ext: Dwelling.initial(type).toExt(),
    );
    _visual?.setStood();
    final Vector2 at = _visual?.position.clone() ?? (game.size / 2);
    add(_particles.build(ParticleArtKey.dust, intensity: 1.0)
      ..position = at
      ..priority = 60);
    _syncView();
  }

  void _onFloodFail(SimEvent e) {
    final Vector2 at = _visual?.position.clone() ?? (game.size / 2);
    add(_particles.build(ParticleArtKey.splash, intensity: 1.0)
      ..position = at
      ..priority = 55);
    _visual?.setFlooded();
    _syncView(hint: e.message, failed: true);
  }

  void _onWindFail(SimEvent e) {
    final Vector2 at = _visual?.position.clone() ?? (game.size / 2);
    add(_particles.build(ParticleArtKey.dust, intensity: 1.0)
      ..position = at
      ..priority = 55);
    _visual?.setBlownOver();
    _syncView(hint: e.message, failed: true);
  }

  void _syncView({String? hint, bool? failed}) {
    final RaiseShelterSim? sim = _shelterSim;
    if (sim == null) return;
    if (sim.siteChosen && sim.siteRisk < _floodRiskThreshold) {
      _chosenSafeCoord = _siteCoords[sim.siteId] ?? _chosenSafeCoord;
    }
    view.sync(sim, hint: hint, failed: failed);
  }

  // ===========================================================================
  // Lifecycle
  // ===========================================================================

  double _rainBurstClock = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    final RaiseShelterSim? sim = _shelterSim;
    if (sim == null) return;

    // Keep the view tracking the sim's live pacing (material rise, settle, storm).
    if (controller.beat == ActivityBeat.interact && !view.failed) {
      _syncView();
    }

    // Once the player leaves the site-selection step, fade out ALL candidate
    // site spots so the build/assemble stages show only the active site + frame —
    // no orphaned ovals (with their haze) lingering into the next interaction.
    final bool pickingSite = sim.phase == RaisePhase.chooseSite;
    for (final _SiteSpotComponent spot in _spots.values) {
      pickingSite ? spot.revive() : spot.dismiss();
    }

    // Push the live build state into the volumetric visual every frame so the
    // wall-rise + part-settle deploy animate same-frame (the prop IS the meter).
    _visual?.setLive(
      wallRise: sim.wallRise,
      material: sim.material,
      settle: sim.settle,
      settling: sim.settling,
      currentStep: sim.currentStep,
    );

    // Position + show/hide the pulsing ghost slot for the current part.
    final _GhostSlotComponent? ghost = _ghost;
    if (ghost != null) {
      if (sim.phase == RaisePhase.assemble && sim.currentStep != null) {
        final ({double x, double y}) slot =
            ShelterStageLayout.slotFor(sim.currentStep!);
        ghost.position =
            Vector2(slot.x * game.size.x, slot.y * game.size.y);
        ghost.setStep(sim.currentStep!, nudge: sim.nudge);
        ghost.show = true;
      } else {
        ghost.show = false;
      }
    }

    // While the storm test runs, drive the on-canvas shelter's strain + lash the
    // rain harder as the gusts mount.
    if (sim.phase == RaisePhase.test) {
      _visual?.setStorm(
        gust: sim.gust,
        strain: sim.strain,
        failProgress: sim.failProgress,
        verdict: sim.verdict,
      );
      _rainBurstClock += dt;
      final double interval = 0.5 - 0.32 * sim.gust;
      if (_rainBurstClock >= interval) {
        _rainBurstClock = 0.0;
        final _ShelterStageVisual? v = _visual;
        if (v != null) {
          add(_particles.build(ParticleArtKey.rain,
              intensity: 0.6 + sim.gust)
            ..position = Vector2(v.position.x, v.position.y - 130)
            ..priority = 45);
        }
      }
    } else {
      _rainBurstClock = 0.0;
    }
  }

  @override
  void onRemove() {
    _sub?.cancel();
    _sub = null;
    view.dispose();
    super.onRemove();
  }
}

/// A candidate SITE spot drawn on the iso ground with a FELT risk read: a dry,
/// firm high-ground patch, or a LOW patch with a faint rising water-line haze + a
/// cool sheen (so the player SEES the riverbank is wet before they choose). Pure
/// presentation; the small shimmer uses the Flame loop, never world state.
class _SiteSpotComponent extends PositionComponent
    with HasGameReference<EmberGame> {
  _SiteSpotComponent({
    required this.palette,
    required this.risk,
    required this.threshold,
    required Vector2 position,
  }) : super(position: position, anchor: Anchor.center);

  final EmberPalette palette;
  final double risk;
  final double threshold;

  double _t = 0.0;
  double _chosen = 0.0; // 0 unchosen .. 1 chosen (eased)
  bool _isChosen = false;
  double _visible = 1.0; // 1 shown .. 0 fully faded out (post site-choice)
  bool _dismissed = false;

  bool get _risky => risk >= threshold;

  void setChosen(bool chosen) => _isChosen = chosen;

  /// Fade this spot OUT (and keep it gone). Called for the UNCHOSEN spots the
  /// moment the player leaves the site-selection step, so the candidate ovals +
  /// their haze never linger as orphaned scenery into the build stages.
  void dismiss() => _dismissed = true;

  /// Re-show on retry (the site step replays).
  void revive() => _dismissed = false;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final double target = _isChosen ? 1.0 : 0.0;
    _chosen += (target - _chosen) * (1 - math.exp(-dt / 0.18));
    final double visTarget = _dismissed ? 0.0 : 1.0;
    _visible += (visTarget - _visible) * (1 - math.exp(-dt / 0.16));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_visible <= 0.01) return;
    // Fade the WHOLE spot (patch + haze + ring) together as it dismisses, so an
    // unchosen candidate never lingers as an orphaned oval into the build stages.
    final bool fading = _visible < 0.995;
    if (fading) {
      canvas.saveLayer(
        null,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: _visible),
      );
    } else {
      canvas.save();
    }
    canvas.translate(0, (1 - _visible) * 8); // a tiny settle as it fades
    const double w = 116;
    const double h = 56;
    final Rect oval = Rect.fromCenter(
        center: Offset.zero, width: w * (0.92 + 0.08 * _chosen), height: h);

    // The ground patch: dry warm earth for high ground; cool damp earth for low.
    final Color dry = palette.highGround;
    final Color damp = Color.lerp(palette.highGroundDark, palette.waterDeep,
            (risk * 0.5).clamp(0.0, 0.5)) ??
        palette.highGroundDark;
    canvas.drawOval(
      oval,
      Paint()..color = (_risky ? damp : dry).withValues(alpha: 0.9),
    );
    canvas.drawOval(
      oval,
      Paint()
        ..color = palette.highGroundDark.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    if (_risky) {
      // FELT risk: a rising water-line haze pooling over the low patch, with a
      // gentle shimmer (telegraphs "the water reaches here"). Stronger with risk.
      final double pool = (0.3 + 0.5 * risk).clamp(0.0, 0.85);
      final Rect water = Rect.fromCenter(
        center: const Offset(0, 6),
        width: w * 0.86,
        height: h * 0.62 * pool,
      );
      canvas.drawOval(
        water,
        Paint()
          ..color = palette.water.withValues(alpha: 0.32 + 0.12 * pool)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // A few shimmer glints on the haze.
      final Paint glint = Paint()
        ..color = palette.water.withValues(alpha: 0.5);
      for (int i = 0; i < 3; i++) {
        final double gx = (i - 1) * w * 0.22;
        final double gy = 6 + math.sin(_t * 2.2 + i) * 2.0;
        canvas.drawCircle(Offset(gx, gy), 2.0, glint);
      }
    } else {
      // High & dry: a faint warm sheen + a couple of dry grass tufts.
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(-6, -6), width: w * 0.5, height: h * 0.4),
        Paint()
          ..color = palette.spark.withValues(alpha: 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // The chosen ring + an unchosen breathing prompt ring.
    final Color ring = _risky ? palette.warning : palette.success;
    final double pulse = 0.5 + 0.5 * math.sin(_t * 3.0);
    final double ringA = _isChosen ? 0.95 : (0.35 + 0.4 * pulse);
    canvas.drawOval(
      oval.inflate(3 + 3 * _chosen),
      Paint()
        ..color = ring.withValues(alpha: ringA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + 1.5 * _chosen,
    );

    canvas.restore();
  }
}

/// The pulsing DASHED ghost-slot marking where the current part snaps to. Shows
/// only during the assemble phase; bounces (a quick flash) on a wrong drop.
class _GhostSlotComponent extends PositionComponent
    with HasGameReference<EmberGame> {
  _GhostSlotComponent({required this.palette})
      : super(anchor: Anchor.center);

  final EmberPalette palette;

  bool show = false;
  AssembleStep _step = AssembleStep.frame;
  double _t = 0.0;
  double _bounce = 0.0;
  double _nudge = 0.0;

  void setStep(AssembleStep step, {double nudge = 0.0}) {
    _step = step;
    _nudge = nudge;
  }

  void bounce() => _bounce = 1.0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_bounce > 0) _bounce = (_bounce - dt * 3.0).clamp(0.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!show) return;
    final bool warn = _bounce > 0.05 || _nudge > 0.05;
    final Color c = warn ? palette.warning : palette.ember;
    final double pulse = 0.5 + 0.5 * math.sin(_t * 4.0);
    final double a = (warn ? 0.9 : 0.4 + 0.45 * pulse).clamp(0.0, 1.0);
    final double r = 30.0 + 4.0 * pulse + 6.0 * _bounce;

    // A dashed ring (approximated as short arc segments).
    final Paint dash = Paint()
      ..color = c.withValues(alpha: a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    const int segs = 12;
    for (int i = 0; i < segs; i++) {
      final double a0 = (i / segs) * math.pi * 2 + _t * 0.6;
      final double a1 = a0 + (math.pi * 2 / segs) * 0.55;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r),
        a0,
        a1 - a0,
        false,
        dash,
      );
    }
    // A faint per-part glyph hint at the centre (so the slot says WHAT goes here).
    _paintStepHint(canvas, c.withValues(alpha: a * 0.85));
  }

  /// A minimal line-glyph hinting the current part: a peaked frame, a draped cover,
  /// stacked anchor dots, or a smoke-hole ring.
  void _paintStepHint(Canvas canvas, Color c) {
    final Paint g = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    switch (_step) {
      case AssembleStep.frame:
        canvas.drawLine(const Offset(-9, 8), const Offset(0, -9), g);
        canvas.drawLine(const Offset(9, 8), const Offset(0, -9), g);
      case AssembleStep.cover:
        final Path p = Path()
          ..moveTo(0, -9)
          ..lineTo(10, 8)
          ..lineTo(-10, 8)
          ..close();
        canvas.drawPath(p, g);
      case AssembleStep.anchor:
        canvas.drawCircle(const Offset(-7, 4), 4, g);
        canvas.drawCircle(const Offset(7, 4), 4, g);
      case AssembleStep.smokeHole:
        canvas.drawCircle(Offset.zero, 7, g);
        canvas.drawLine(const Offset(0, -7), const Offset(0, -14), g);
    }
  }
}

/// The growing VOLUMETRIC build-up visual: site pad -> rising material walls ->
/// frame poles (litCylinder) lashed (woundLashing) -> cover -> anchor stones ->
/// smoke hole -> the storm reaction. Drawn from CraftKit so the build reads
/// hot/solid + lit. Pure presentation: the values it animates are pushed each
/// frame from the sim (the scene owns them); only the small sway/clock are local.
class _ShelterStageVisual extends PositionComponent
    with HasGameReference<EmberGame> {
  _ShelterStageVisual({required this.palette, required Vector2 position})
      : super(position: position, anchor: Anchor.bottomCenter);

  final EmberPalette palette;

  // Placed-part booleans (from stepDone events).
  bool _frame = false;
  bool _cover = false;
  bool _anchor = false;
  bool _smokeHole = false;
  bool _stood = false;
  bool _flooded = false;
  bool _blownOver = false;
  double _t = 0.0;

  // Live pre-assemble state pushed each frame (material rise + part deploy).
  double _wallRise = 0.0;
  ShelterMaterial _material = ShelterMaterial.hideTent;
  double _settle = 1.0;
  AssembleStep? _settling;

  // Live storm telemetry pushed from the scene during the test (0 when calm).
  double _gust = 0.0;
  double _strain = 0.0;
  double _failProgress = 0.0;
  StormVerdict? _verdict;

  void setFromSteps({
    required bool frame,
    required bool cover,
    required bool anchor,
    required bool smokeHole,
  }) {
    _frame = frame;
    _cover = cover;
    _anchor = anchor;
    _smokeHole = smokeHole;
  }

  /// Push the live pre-storm build state every frame so the wall RISES + the
  /// just-placed part DEPLOYS same-frame.
  void setLive({
    required double wallRise,
    required ShelterMaterial material,
    required double settle,
    required AssembleStep? settling,
    required AssembleStep? currentStep,
  }) {
    _wallRise = wallRise;
    _material = material;
    _settle = settle;
    _settling = settling;
  }

  void setStorm({
    required double gust,
    required double strain,
    required double failProgress,
    required StormVerdict? verdict,
  }) {
    _gust = gust;
    _strain = strain;
    _failProgress = failProgress;
    _verdict = verdict;
    if (verdict == StormVerdict.floods) _flooded = failProgress > 0;
  }

  void setStood() {
    _stood = true;
    _flooded = false;
    _blownOver = false;
    _gust = 0.0;
    _strain = 0.0;
    _failProgress = 0.0;
  }

  void setFlooded() => _flooded = true;
  void setBlownOver() => _blownOver = true;

  void reset() {
    _frame = false;
    _cover = false;
    _anchor = false;
    _smokeHole = false;
    _stood = false;
    _flooded = false;
    _blownOver = false;
    _wallRise = 0.0;
    _settle = 1.0;
    _settling = null;
    _gust = 0.0;
    _strain = 0.0;
    _failProgress = 0.0;
    _verdict = null;
  }

  /// easeOutBack — the frame poles' overshoot swing-up.
  double _easeOutBack(double t) {
    const double c1 = 1.70158;
    const double c3 = c1 + 1;
    final double x = t - 1;
    return 1 + c3 * x * x * x + c1 * x * x;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Bottom-centre origin; draw upward (-y).
    const double w = 140;
    const double h = 110;

    // The lean/shake telemetry (storm) or the gentle unanchored sway (calm).
    final bool storming = _gust > 0 && !_stood;
    double lean;
    if (_blownOver) {
      lean = 1.05;
    } else if (storming && _verdict == StormVerdict.blowsOver) {
      lean = math.sin(_t * 22.0) * 0.05 * _strain + 1.05 * _failProgress;
    } else if (storming) {
      lean = math.sin(_t * 22.0) * 0.06 * _strain;
    } else {
      lean = (_anchor || _stood) ? 0.0 : math.sin(_t * 6.0) * 0.04;
    }

    // A grounding contact ellipse under the whole build (nothing floats).
    CraftKit.groundContactEllipse(canvas,
        center: const Offset(0, 2), width: w * 1.1, strength: 0.9);

    canvas.save();
    if (lean != 0.0) canvas.rotate(lean);

    // --- Rising MATERIAL walls (pre-frame): courses climb as the player drags ---
    // The felt tradeoff: hide rises as a light hide-skirt; timber as stacked logs.
    if (!_frame && _wallRise > 0.01) {
      _paintRisingWalls(canvas, w, h, _wallRise);
    }

    // --- The FRAME (two lit cylinder poles + a ridge), deploying easeOutBack ---
    if (_frame) {
      final double dep = _settling == AssembleStep.frame
          ? _easeOutBack(_settle.clamp(0.0, 1.0))
          : 1.0;
      _paintFrame(canvas, w, h, dep);
    }

    // --- The COVER (a hide/thatch sheet), unrolling down from the ridge ---------
    if (_cover) {
      final double unroll = _settling == AssembleStep.cover
          ? _settle.clamp(0.0, 1.0)
          : 1.0;
      _paintCover(canvas, w, h, unroll, storming);
    }

    // --- ANCHOR stones at the base corners, thunking down --------------------
    if (_anchor) {
      final double thunk = _settling == AssembleStep.anchor
          ? _settle.clamp(0.0, 1.0)
          : 1.0;
      _paintAnchors(canvas, w, thunk);
    }

    // --- SMOKE HOLE + a cozy wisp once it stands warm ------------------------
    if (_smokeHole && _stood) {
      _paintSmokeWisp(canvas, h);
    }

    canvas.restore();

    // --- Rising flood water at the base (upright, not swayed) ---------------
    if (_flooded || (_verdict == StormVerdict.floods && _failProgress > 0)) {
      _paintFlood(canvas, w, h);
    }

    // --- The relief payoff: a warm dry glow under the standing home ---------
    if (_stood) {
      CraftKit.bloomStack(canvas,
          center: const Offset(0, -h * 0.45),
          radius: h * 0.7,
          intensity: 0.5,
          warm: palette.ember,
          hot: palette.emberBright);
    }
  }

  void _paintRisingWalls(Canvas canvas, double w, double h, double rise) {
    final double topY = -h * 0.62 * rise; // how high the courses have climbed
    if (_material == ShelterMaterial.hut) {
      // Stacked timber logs climbing course by course.
      final int courses = (rise * 5).ceil().clamp(0, 5);
      const double courseH = 14;
      for (int i = 0; i < courses; i++) {
        final double y = -6 - i * courseH;
        if (y < topY - courseH) break;
        final Rect log =
            Rect.fromLTWH(-w * 0.34, y - courseH * 0.7, w * 0.68, courseH * 0.8);
        canvas.drawRRect(
          RRect.fromRectAndRadius(log, const Radius.circular(5)),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[palette.wood, palette.woodDark],
            ).createShader(log),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(log, const Radius.circular(5)),
          Paint()
            ..color = palette.outline.withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
    } else {
      // A light hide skirt rising quickly.
      final Rect skirt = Rect.fromLTWH(-w * 0.32, topY, w * 0.64, -topY);
      canvas.drawRRect(
        RRect.fromRectAndRadius(skirt, const Radius.circular(8)),
        Paint()..color = palette.hide.withValues(alpha: 0.9),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(skirt, const Radius.circular(8)),
        Paint()
          ..color = palette.outline.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  void _paintFrame(Canvas canvas, double w, double h, double dep) {
    // The two poles swing up to the apex; dep eases the apex height (overshoot).
    final double apexY = -h * dep;
    final Offset apex = Offset(0, apexY);
    // Volumetric lit cylinder poles, each from a base corner up toward the apex.
    // We approximate the angled pole with a thin litCylinder rotated to the apex.
    for (final double sx in <double>[-w * 0.35, w * 0.35]) {
      final Offset basePt = Offset(sx, 0);
      final double dx = apex.dx - basePt.dx;
      final double dy = apex.dy - basePt.dy;
      final double len = math.sqrt(dx * dx + dy * dy);
      final double ang = math.atan2(dy, dx) + math.pi / 2; // align cylinder up
      canvas.save();
      canvas.translate(basePt.dx, basePt.dy);
      canvas.rotate(ang);
      CraftKit.litCylinder(
        canvas,
        base: Offset.zero,
        w: 9,
        h: len,
        body: palette.wood,
        outline: palette.woodDark,
        specular: 0.5,
        contactShadow: false,
      );
      canvas.restore();
    }
    // The ridge stub + a lashing binding the poles at the apex.
    CraftKit.woundLashing(
      canvas,
      center: Offset(apex.dx, apex.dy + 10),
      w: 22,
      height: 18,
      turns: 2,
      cord: palette.hideDark,
      opacity: dep,
    );
  }

  void _paintCover(Canvas canvas, double w, double h, double unroll, bool storming) {
    final double wet = storming ? (0.25 + 0.35 * _gust).clamp(0.0, 0.6) : 0.0;
    final Color hideWet =
        Color.lerp(palette.hide, palette.hideDark, wet) ?? palette.hide;
    // Unroll: the cover clips down from the ridge by `unroll`.
    final double coverBottom = -h * (1 - unroll) * 0.0; // bottom stays at base
    final double apexY = -h;
    final double drawTo = apexY + (0 - apexY) * unroll; // grows from apex down
    final Path tent = Path()
      ..moveTo(0, apexY)
      ..lineTo(w * 0.4 * unroll, drawTo + coverBottom)
      ..lineTo(-w * 0.4 * unroll, drawTo + coverBottom)
      ..close();
    canvas.drawPath(tent, Paint()..color = hideWet.withValues(alpha: 0.95));
    // Shaded right half for form.
    final Path shade = Path()
      ..moveTo(0, apexY)
      ..lineTo(w * 0.4 * unroll, drawTo)
      ..lineTo(0, drawTo)
      ..close();
    canvas.drawPath(
        shade, Paint()..color = palette.hideDark.withValues(alpha: 0.9));
    canvas.drawPath(
      tent,
      Paint()
        ..color = palette.outline
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  void _paintAnchors(Canvas canvas, double w, double thunk) {
    // The stones drop the last few px into place (thunk) + a contact shadow.
    final double drop = (1 - thunk) * -12;
    for (final double dx in <double>[-w * 0.38, w * 0.38]) {
      final Offset c = Offset(dx, -6 + drop);
      CraftKit.groundContactEllipse(canvas,
          center: Offset(dx, -2), width: 22, strength: thunk);
      canvas.drawCircle(c, 9, Paint()..color = palette.rock);
      canvas.drawCircle(
          c,
          9,
          Paint()
            ..color = palette.rockDark
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke);
      // A lit upper-left highlight.
      canvas.drawCircle(c.translate(-2.5, -2.5), 2.5,
          Paint()..color = palette.stoneChip.withValues(alpha: 0.8));
    }
  }

  void _paintSmokeWisp(Canvas canvas, double h) {
    final Paint smoke = Paint()
      ..color = palette.inkSoft.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    for (int i = 0; i < 3; i++) {
      final double phase = _t * 1.5 + i;
      canvas.drawCircle(
          Offset(math.sin(phase) * 4, -h - (phase % 2) * 16), 3.0, smoke);
    }
  }

  void _paintFlood(Canvas canvas, double w, double h) {
    final double rise = _failProgress > 0 ? _failProgress : 1.0;
    final double bandH = (h * 0.16 + h * 0.34 * rise);
    final Paint water = Paint()
      ..color = palette.waterDeep.withValues(alpha: 0.5);
    canvas.drawRect(Rect.fromLTWH(-w * 0.55, -bandH, w * 1.1, bandH), water);
    final Paint surf = Paint()
      ..color = palette.water
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final Path wave = Path()..moveTo(-w * 0.55, -bandH);
    for (double x = -w * 0.55; x <= w * 0.55; x += 12) {
      wave.lineTo(x, -bandH + math.sin(x * 0.25 + _t * 9) * 2.0);
    }
    canvas.drawPath(wave, surf);
  }
}
