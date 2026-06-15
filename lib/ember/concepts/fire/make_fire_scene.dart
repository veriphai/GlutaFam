// Ember — concepts/fire/make_fire_scene.dart
//
// MakeFireScene: the Flame STAGE for the Make Fire interact beat — rebuilt for
// DIRECT, ON-STAGE, SAME-FRAME manipulation. It subclasses [ActivityScene] and
// overrides the three leaf hooks: buildInteractSim() (the [MakeFireSim] brain),
// buildInteractStage() (the bespoke volumetric props, built from CraftKit so no
// new closed art key is needed), and buildInteractOverlay() (the full-screen,
// transparent gesture surface + ONE EmberCaption).
//
// The stage components are near-PURE render(Canvas) readers: the scene pushes the
// sim's live channels (heat / ember / flame / spinVel / tinderSeated / air) into
// them each update(), and pushes their screen-space anchors into the view so the
// overlay's finger drags land ON the props (the control IS the value — the
// electricity "controller owns everything" shape). The fire TRIANGLE's three
// corners fill continuously from the live felt channels (fuel seated / live heat /
// live air), not from binary events.
//
// HEAT is driven by a CRANK WHEEL (mirroring the Hand-Crank Lamp): a bigger disc
// at the top of the drill shaft that the finger rotates. The scene owns the crank
// physics — raw pointer down/move/up forwarded from the overlay, the finger's
// angle delta around the WHEEL CENTRE accumulated per render frame, then turned
// into a TRUE angular velocity (rad/s) in update(dt) with a sample-timeout HOLD
// that bridges the gaps between pointer-move callbacks. That hold is the on-device
// bug fix: a continuous crank now keeps building heat instead of reading as
// "stopped" on the many frames with no fresh pointer sample.
//
// CONTRACT: the scene NEVER mutates world state. It only sets controller.placeHint
// and calls the controller's input/retry/finish plumbing; the host folds the
// result through the reducer. Determinism: presentation-only clocks (the spindle's
// visual spin-down, flame flicker) never feed EmberWorldState.

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
import 'fire_widgets.dart';
import 'make_fire_activity.dart';
import 'make_fire_sim.dart';
import 'model/fire_object.dart';

/// The Make Fire interact stage.
class MakeFireScene extends ActivityScene {
  MakeFireScene(super.activity, super.controller, {GridCoord? siteCoord})
      : _siteCoord = siteCoord;

  /// Where the resulting Hearth should be dropped after success — the camp
  /// centre. If not supplied at construction it is resolved from the live world.
  final GridCoord? _siteCoord;

  GridCoord get siteCoord =>
      _siteCoord ??
      (isMounted ? game.bridge.state.village.siteTile : const GridCoord(0, 0));

  /// The Flutter-side view-model the host's overlay listens to.
  final FireInteractView view = FireInteractView();

  MakeFireSim? _fireSim;
  StreamSubscription<SimEvent>? _sub;

  // ---- The bespoke props (near-pure render readers) -----------------------
  _FireRig? _rig;
  _WarmthWash? _wash;
  _FireTriangleHud? _triangle;

  EmberParticles get _particles => EmberParticles(palette: _palette);
  EmberPalette get _palette => art.palette;

  // ---- Crank physics (ported 1:1 from the Hand-Crank Lamp) ----------------
  // We measure the finger's angle delta around the CRANK WHEEL CENTRE from raw
  // pointer-move events and integrate it in update(dt) into a TRUE rad/s, with a
  // sample-timeout HOLD that bridges the gaps between Flutter's pointer-move
  // callbacks. THIS is the bug fix: pointer moves don't fire on every render
  // frame during a continuous crank, so without the hold most frames read as
  // "stopped" and heat bled (~0.62/s) far faster than it built — the player got
  // stuck. Now a continuous crank keeps a steady rad/s and always out-builds the
  // idle bleed; a genuine pause (no sample for [_spinSampleTimeoutSec]) or a
  // pointer-up still zeroes it the same frame (the felt HEAT gate).
  bool _crankDown = false; // finger touching the wheel
  double _crankLastAngle = 0.0; // last finger angle around the wheel centre
  double _frameAngleDelta = 0.0; // accumulated swept angle this render frame
  bool _crankSampleThisFrame = false; // a pointer-move arrived this frame
  double _crankSampleElapsed = 0.0; // seconds since the last move sample
  double _crankAngularVel = 0.0; // the live rad/s forwarded to the sim
  double _crankAccumTurn = 0.0; // swept angle since the last quarter-turn tick

  /// Sample-timeout HOLD window — within this many seconds of the last
  /// pointer-move the velocity is held (a continuous crank stays "spinning");
  /// past it (or on pointer-up) it zeroes (the heat bleeds).
  static const double _crankSampleTimeoutSec = 0.12;

  // ===========================================================================
  // Leaf overrides
  // ===========================================================================

  @override
  ActivitySim buildInteractSim() {
    final MakeFireSim sim = MakeFireSim();
    _fireSim = sim;
    _sub?.cancel();
    _sub = sim.events.listen(_onSimEvent);
    return sim;
  }

  @override
  Future<void> buildInteractStage() async {
    // The action sits in the upper-middle band so the bottom caption never buries
    // it. world coords == screen logical px (the activity camera is centred on
    // game.size/2 at zoom 1.0), so these positions ARE the gesture anchors.
    final Vector2 stageSize = game.size.clone();
    final Vector2 base = Vector2(stageSize.x / 2, stageSize.y * 0.42);

    // A full-screen warmth wash that blooms as the fire grows (lowest priority).
    final _WarmthWash wash = _WarmthWash(palette: _palette)..priority = 1;
    _wash = wash;
    await add(wash);

    // The continuous FIRE TRIANGLE: three corners that FILL from the live felt
    // channels (fuel seated / live heat / live air), drawn around the rig.
    final _FireTriangleHud triangle = _FireTriangleHud(
      palette: _palette,
      center: Vector2(base.x, base.y - 26),
      radius: 124,
    )..priority = 70;
    _triangle = triangle;
    await add(triangle);

    // The volumetric rig: stone rocks, fireboard + notch, drill spindle, tinder
    // tuft, ember + flame — all CraftKit-lit, all reading the sim's channels.
    final _FireRig rig = _FireRig(palette: _palette, base: base)..priority = 10;
    _rig = rig;
    await add(rig);
  }

  /// The full-screen, transparent gesture overlay (direct manipulation) + the ONE
  /// EmberCaption + retry. NO panels / cards / meters / phase-title / buttons.
  @override
  Widget buildInteractOverlay(BuildContext context) {
    return FireInteractOverlay(
      view: view,
      palette: _palette,
      onSeatTinder: seatTinder,
      onCrankDown: crankDown,
      onCrankMove: crankMove,
      onCrankUp: crankUp,
      onPuff: puff,
      onCover: cover,
      onRetry: retryAttempt,
    );
  }

  // ===========================================================================
  // Input forwarding (called by the gesture overlay via the host)
  // ===========================================================================

  void seatTinder(bool dry, double seat) {
    sendInput(SimInput(MakeFireSignals.inSelectTinder, <String, dynamic>{
      'dry': dry,
      'seat': seat,
    }));
    _syncView();
  }

  // ---- Crank input (raw pointer events forwarded from the overlay) ---------
  // Ported from CrankController: the finger grabs the wheel (down), sweeps it
  // (move accumulates an unwrapped angle delta around the wheel centre + advances
  // the visual handle 1:1), and releases (up zeroes the velocity at once). The
  // delta is integrated into a true rad/s in [update] — the overlay never
  // computes velocity itself, so there is no ×60 frame-rate guess.

  /// The finger grabbed the crank wheel at screen-space [local].
  void crankDown(Offset local) {
    _crankDown = true;
    _crankLastAngle = _angleAroundWheel(local);
    _frameAngleDelta = 0.0;
    _crankSampleThisFrame = false;
    _crankSampleElapsed = 0.0;
    _crankAccumTurn = 0.0;
    HapticFeedback.selectionClick();
  }

  /// The finger swept to screen-space [local] — accumulate the angle delta around
  /// the wheel centre and turn the wheel 1:1 with the finger.
  void crankMove(Offset local) {
    if (!_crankDown) return;
    final double a = _angleAroundWheel(local);
    final double delta = _unwrapAngle(a - _crankLastAngle);
    _crankLastAngle = a;
    _frameAngleDelta += delta;
    _crankSampleThisFrame = true;
    // Drive the wheel's visual rotation 1:1 with the finger (sign + magnitude).
    _rig?.turnWheel(delta);
    // A per-quarter-turn haptic tick (keys off MOTION, like the lamp).
    _crankAccumTurn += delta.abs();
    if (_crankAccumTurn >= math.pi / 2) {
      _crankAccumTurn -= math.pi / 2;
      HapticFeedback.selectionClick();
    }
  }

  /// The finger lifted off the crank — velocity HARD-drops to 0 this frame; the
  /// notch heat bleeds NOW (the felt HEAT lesson).
  void crankUp() {
    _crankDown = false;
    _crankAngularVel = 0.0;
    _frameAngleDelta = 0.0;
    _crankSampleThisFrame = false;
    sendInput(const SimInput(MakeFireSignals.inSpin, <String, dynamic>{
      'vel': 0.0,
    }));
  }

  /// The finger's angle around the CRANK WHEEL CENTRE (the buildHeat anchor the
  /// view publishes as spindlePivot — now the wheel, not the notch).
  double _angleAroundWheel(Offset local) {
    final Offset c = view.spindlePivot;
    return math.atan2(local.dy - c.dy, local.dx - c.dx);
  }

  static double _unwrapAngle(double d) {
    while (d > math.pi) {
      d -= 2 * math.pi;
    }
    while (d <= -math.pi) {
      d += 2 * math.pi;
    }
    return d;
  }

  void puff(double strength) {
    sendInput(SimInput(MakeFireSignals.inPuff, <String, dynamic>{
      'strength': strength,
    }));
    _syncView();
    // A breath of sparks + rising embers, scaled by the swipe strength.
    final _FireRig? rig = _rig;
    final MakeFireSim? sim = _fireSim;
    if (rig != null) {
      add(_particles.build(ParticleArtKey.spark, intensity: 0.4 + 0.5 * strength)
        ..position = rig.emberWorld
        ..priority = 50);
      add(_particles.build(ParticleArtKey.ember,
          intensity: 0.3 + 0.6 * (sim?.flame ?? 0.0))
        ..position = rig.emberWorld + Vector2(0, -10)
        ..priority = 50);
      rig.puff(strength);
    }
  }

  void cover() {
    sendInput(const SimInput(MakeFireSignals.inCover));
    _syncView();
  }

  /// Re-arm after a failure.
  void retryAttempt() {
    retry();
    view.reset();
    _rig?.reset();
    _triangle?.reset();
    _wash?.setLevels(fuel: 0, heat: 0, ember: 0, flame: 0, air: 0);
  }

  // ===========================================================================
  // DEBUG-ONLY synchronous drivers (the EMBER_TOUR capture harness calls these
  // to advance the interaction deterministically in one synchronous burst with
  // no frames between calls). Normal play NEVER uses them — it drives the
  // continuous gesture channels above. They poke the sim directly (bypassing the
  // per-frame spin cadence + the controller's input counter) and run a fixed
  // tick so heat/flame integrate without waiting for the Flame loop.
  // ===========================================================================

  /// DEBUG: seat the chosen tinder fully in one call.
  void selectTinder({required bool dry}) {
    _fireSim?.onInput(SimInput(MakeFireSignals.inSelectTinder, <String, dynamic>{
      'dry': dry,
      'seat': 1.0,
    }));
    _syncView();
  }

  /// DEBUG: one stout drill — inject a strong spin frame + integrate one tick so
  /// heat climbs synchronously (the real game builds heat from a live crank).
  void drill() {
    final MakeFireSim? sim = _fireSim;
    if (sim == null) return;
    sim.onInput(const SimInput(MakeFireSignals.inSpin, <String, dynamic>{
      'vel': 18.0,
    }));
    // ~0.378 heat per call (0.07 * 18 * 0.3), so ~3 calls catch an ember and the
    // tour's 12-drill bursts overshoot safely.
    sim.tick(0.3);
    _syncView();
  }

  /// DEBUG: one full breath (a complete upward swipe's worth of puff).
  void blow() {
    _fireSim?.onInput(const SimInput(MakeFireSignals.inPuff, <String, dynamic>{
      'strength': 1.0,
    }));
    _syncView();
  }

  // ===========================================================================
  // Sim event handling -> view + canvas juice
  // ===========================================================================

  void _onSimEvent(SimEvent e) {
    switch (e.code) {
      case MakeFireSignals.ignited:
        _onIgnited();
      case MakeFireSignals.spinTick:
        // The per-quarter-turn click is fired in [crankMove]; nothing else to do.
        _syncView();
      case MakeFireSignals.emberCaught:
        HapticFeedback.heavyImpact(); // the ember is BORN.
        _rig?.bornEmber();
        _syncView();
      case MakeFireSignals.tinderChosen:
        HapticFeedback.selectionClick(); // the dry tuft seats with a click.
        _syncView();
      case MakeFireSignals.dampTinder:
        _triangle?.flashFail(_TriSide.fuel);
        _onFailure(e, smother: false, damp: true);
      case MakeFireSignals.tooSlow:
        _triangle?.flashFail(_TriSide.heat);
        _onFailure(e, smother: false, damp: false);
      case MakeFireSignals.smothered:
        _triangle?.flashFail(_TriSide.air);
        _onFailure(e, smother: true, damp: false);
      default:
        _syncView();
    }
  }

  void _onIgnited() {
    controller.placeHint = PlaceHint(
      type: PlaceableType.hearth,
      coord: siteCoord,
      tier: 1,
      built: true,
      ext: FireObject.initial(FireType.hearth).toExt(pos: siteCoord),
    );
    HapticFeedback.heavyImpact();
    _rig?.setLevels(fuel: 1, heat: 1, ember: 1, flame: 1, air: 1);
    _wash?.setLevels(fuel: 1, heat: 1, ember: 1, flame: 1, air: 1);
    _triangle?.celebrate();
    // The celebratory ignition crescendo: shockwave + screen flash + layered
    // sparks AND rising embers AND a dust puff.
    final Vector2 at = _rig?.emberWorld ?? (game.size / 2);
    _rig?.playIgnitionBurst();
    _wash?.flash();
    add(_particles.build(ParticleArtKey.spark, intensity: 1.6)
      ..position = at
      ..priority = 60);
    add(_particles.build(ParticleArtKey.ember, intensity: 1.8)
      ..position = at + Vector2(0, -8)
      ..priority = 60);
    add(_particles.build(ParticleArtKey.dust, intensity: 1.0)
      ..position = at + Vector2(0, 6)
      ..priority = 24);
    _syncView();
  }

  void _onFailure(SimEvent e, {required bool smother, required bool damp}) {
    final Vector2 at = _rig?.emberWorld ?? (game.size / 2);
    if (smother) {
      _rig?.playSmother();
      add(_particles.build(ParticleArtKey.smoke, intensity: 0.5)
        ..position = at
        ..priority = 40);
    } else if (damp) {
      _rig?.playDampSlump();
      add(_particles.build(ParticleArtKey.smoke, intensity: 0.4)
        ..position = _rig?.notchWorld ?? at
        ..priority = 40);
    } else {
      add(_particles.build(ParticleArtKey.smoke, intensity: 0.8)
        ..position = _rig?.notchWorld ?? at
        ..priority = 40);
    }
    _rig?.setLevels(fuel: 0, heat: 0, ember: 0, flame: 0, air: 0);
    _wash?.setLevels(fuel: 0, heat: 0, ember: 0, flame: 0, air: 0);
    HapticFeedback.mediumImpact();
    view.sync(_fireSim!, failed: true, failHint: e.message);
  }

  /// Push the sim's live channels into the props + the view (the props are near-
  /// pure readers; the view drives the caption + the overlay's prop anchors).
  void _syncView() {
    final MakeFireSim? sim = _fireSim;
    final _FireRig? rig = _rig;
    if (sim == null) return;
    final double fuel = sim.tinderSeated;
    final bool buildingHeat = sim.phase == MakeFirePhase.buildHeat;
    rig?.setLevels(
      fuel: fuel,
      heat: buildingHeat ? sim.heat : (sim.ember > 0 || sim.flame > 0 ? 1 : 0),
      ember: sim.ember,
      flame: sim.flame,
      air: sim.air,
    );
    rig?.setSpinVel(sim.spinVel);
    _wash?.setLevels(
      fuel: fuel,
      heat: sim.heat,
      ember: sim.ember,
      flame: sim.flame,
      air: sim.air,
    );
    // The triangle's THREE corners read continuously from the live felt channels.
    _triangle?.setLevels(
      fuel: fuel,
      heat: buildingHeat ? sim.heat : math.max(sim.ember, sim.flame),
      air: sim.air,
    );
    if (!view.failed) {
      view.sync(sim);
    }
  }

  // ===========================================================================
  // Lifecycle
  // ===========================================================================

  @override
  void update(double dt) {
    super.update(dt);
    if (controller.beat != ActivityBeat.interact) return;
    final MakeFireSim? sim = _fireSim;

    // Resolve the crank's TRUE angular velocity this frame (the lamp's tick math):
    //   * a pointer-move arrived -> angularVel = sweptAngle / dt, then reset;
    //   * else hold the last velocity until the sample-timeout (a continuous crank
    //     keeps spinning across the gaps between pointer-move callbacks);
    //   * past the timeout, or finger up -> zero (the notch heat bleeds NOW).
    if (dt > 0) {
      if (_crankSampleThisFrame) {
        _crankAngularVel = _frameAngleDelta / dt;
        _frameAngleDelta = 0.0;
        _crankSampleThisFrame = false;
        _crankSampleElapsed = 0.0;
      } else {
        _crankSampleElapsed += dt;
        if (!_crankDown || _crankSampleElapsed >= _crankSampleTimeoutSec) {
          _crankAngularVel = 0.0;
        }
      }
    }

    // Forward the live |velocity| to the sim each buildHeat frame; it integrates
    // heat from it (heat += k*|vel|*dt) and bleeds when it reads zero.
    if (sim != null && sim.phase == MakeFirePhase.buildHeat && !view.failed) {
      sendInput(SimInput(MakeFireSignals.inSpin, <String, dynamic>{
        'vel': _crankAngularVel.abs(),
      }));
    }

    if (!view.failed) {
      _syncView();
      _pushAnchors();
    }
  }

  /// Push the live screen-space anchors of the on-stage props so the overlay's
  /// finger drags map onto the props (input happens ON the prop).
  void _pushAnchors() {
    final _FireRig? rig = _rig;
    if (rig == null) return;
    Offset toScreen(Vector2 w) {
      final Vector2 s = game.worldToScreen(w);
      return Offset(s.x, s.y);
    }

    view.syncAnchors(
      // buildHeat is computed around the CRANK WHEEL the player sees + grabs, so
      // the spindlePivot anchor is the wheel centre (not the notch any more).
      spindlePivot: toScreen(rig.wheelWorld),
      emberCenter: toScreen(rig.emberWorld),
      lidRest: toScreen(rig.lidRestWorld),
      tinderStart: toScreen(rig.tinderStartWorld),
      stageScale: 1.0,
    );
  }

  @override
  void onRemove() {
    _sub?.cancel();
    _sub = null;
    view.dispose();
    super.onRemove();
  }
}

// =============================================================================
// The volumetric FIRE RIG — ONE component that owns the whole prop cluster and
// paints it from the live channels the scene pushes. Stone rocks, a CraftKit-lit
// fireboard + notch, the spinning drill spindle, the draggable tinder tuft, the
// ember core + a bloomStack flame. Near-pure: it eases its visual-only values
// (spin angle, flicker, puff lean, born/smother/slump/shock animations) in
// update(), and reads the eased CAUSAL channels (fuel/heat/ember/flame/air) the
// scene sets each frame — never softening a same-frame causal update.
// =============================================================================
class _FireRig extends PositionComponent with HasGameReference<EmberGame> {
  _FireRig({required this.palette, required Vector2 base})
      : _base = base,
        super(position: Vector2.zero(), anchor: Anchor.topLeft);

  final EmberPalette palette;
  final Vector2 _base;

  // ---- Live CAUSAL channels (set by the scene, never softened) -------------
  // The AIR channel is felt through the puff lean + the flame's bloom (driven by
  // [_puff] on each swipe) and through the fire-triangle's AIR corner the scene
  // drives directly, so the rig keeps no separate _air field.
  double _fuel = 0.0;
  double _heat = 0.0;
  double _ember = 0.0;
  double _flame = 0.0;
  double _spinVel = 0.0;

  // ---- Visual-only eased values (presentation; update() drives these) ------
  double _wheelAngle = 0.0; // crank wheel rotation (driven 1:1 by the finger)
  double _t = 0.0; // local clock for flicker/swirl
  double _press = 0.0; // drill downward bob while spinning
  double _puff = 0.0; // air-puff flame lean
  double _puffDir = 1.0;
  double _born = 0.0; // ember-born pop
  double _smother = 0.0; // AIR-fail lid
  double _slump = 0.0; // damp-tinder slump
  double _shock = 0.0; // ignition shockwave ring
  bool _reduceMotion = false;

  // ---- Local prop geometry (relative to _base) -----------------------------
  // The notch (= spindle foot) is the drill bite; the tinder tuft starts to the
  // left and is dragged INTO the notch; the ember sits at the notch; the stone
  // lid rests to the right (drag it onto the ember to cap its air). The CRANK
  // WHEEL sits at the TOP of the shaft — it is what the finger grabs + turns, and
  // its centre is the buildHeat pivot the scene publishes as spindlePivot.
  Vector2 get notchWorld => _base + Vector2(0, 44);
  Vector2 get emberWorld => _base + Vector2(0, 40);
  Vector2 get tinderStartWorld => _base + Vector2(-160, 44);
  Vector2 get lidRestWorld => _base + Vector2(160, 30);

  static const double _poleH = 112.0;
  static const double _poleW = 14.0;

  /// The crank wheel centre, at the top of the drill shaft (the rotation pivot).
  Vector2 get wheelWorld => _base + Vector2(0, 44 - _poleH);

  /// Big, finger-friendly crank wheel radius + the grab-knob on its rim.
  static const double _wheelR = 56.0;
  static const double _knobR = 18.0;

  @override
  Future<void> onLoad() async {
    _reduceMotion = game.disableAnimations;
  }

  void setLevels({
    required double fuel,
    required double heat,
    required double ember,
    required double flame,
    required double air,
  }) {
    _fuel = fuel.clamp(0.0, 1.0);
    _heat = heat.clamp(0.0, 1.0);
    _ember = ember.clamp(0.0, 1.0);
    _flame = flame.clamp(0.0, 1.0);
    // `air` is intentionally not stored — see the channels note above.
  }

  void setSpinVel(double v) => _spinVel = v.abs();

  /// Turn the crank wheel 1:1 with the finger (signed radians swept this move).
  void turnWheel(double deltaRadians) => _wheelAngle += deltaRadians;

  void puff(double strength) {
    _puff = (_puff + strength).clamp(0.0, 1.0);
    _puffDir = -_puffDir;
  }

  void bornEmber() => _born = 1.0;
  void playSmother() => _smother = 1.0;
  void playDampSlump() => _slump = 1.0;
  void playIgnitionBurst() => _shock = 1.0;

  void reset() {
    _fuel = 0;
    _heat = 0;
    _ember = 0;
    _flame = 0;
    _spinVel = 0;
    _wheelAngle = 0;
    _press = 0;
    _puff = 0;
    _born = 0;
    _smother = 0;
    _slump = 0;
    _shock = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    // The crank wheel turns 1:1 with the finger (turnWheel), NOT on a timer — so
    // it stops the instant the finger stops, same as the heat. The drill press
    // bobs while the wheel is being driven (the live spin velocity reads > 0).
    if (_spinVel > 0.01) {
      _press = (_press + dt * 6).clamp(0.0, 1.0);
    } else {
      _press = (_press - dt * 6).clamp(0.0, 1.0);
    }
    // Presentation-only eased animations.
    if (_puff > 0.0) _puff = (_puff - dt * 2.6).clamp(0.0, 1.0);
    if (_born > 0.0) _born = (_born - dt * 2.2).clamp(0.0, 1.0);
    if (_smother > 0.0) _smother = (_smother - dt * 0.9).clamp(0.0, 1.0);
    if (_slump > 0.0) _slump = (_slump - dt * 0.8).clamp(0.0, 1.0);
    if (_shock > 0.0) _shock = (_shock - dt * 1.4).clamp(0.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final Offset notch = Offset(notchWorld.x, notchWorld.y);
    final Offset boardC = Offset(_base.x, _base.y + 50);

    // 1) Two kneel rocks framing the board (volumetric, contact-shadowed).
    for (final double dx in <double>[-120, 120]) {
      CraftKit.litCylinder(
        canvas,
        base: Offset(_base.x + dx, _base.y + 66),
        w: 64,
        h: 30,
        body: palette.rock,
        shade: palette.rockDark,
        outline: palette.outline,
        radiusFactor: 0.5,
        specular: 0.35,
      );
    }

    // 2) The fireboard slab (a low lit cylinder reads as a rounded wood block).
    CraftKit.litCylinder(
      canvas,
      base: Offset(boardC.dx, boardC.dy + 16),
      w: 200,
      h: 30,
      body: palette.wood,
      shade: palette.woodDark,
      outline: palette.outline,
      radiusFactor: 0.28,
      specular: 0.4,
    );

    // 3) The notch where the spindle bites — it reddens + glows with friction
    //    heat (the live HEAT channel), so the wood visibly heats before the ember.
    _renderNotch(canvas, notch);

    // 4) The tinder tuft — slides from its start INTO the notch as fuel seats.
    _renderTinder(canvas, notch);

    // 5) The drill spindle — a CraftKit-lit cylinder that visibly SPINS at the
    //    live velocity, glowing as the notch heats.
    _renderSpindle(canvas, notch);

    // 6) Ember core + volumetric flame (bloomStack), scaled by the live channels.
    _renderFire(canvas, notch);

    // 7) The stone lid (the AIR-fail prop) resting to the right, ready to drag.
    _renderLid(canvas);

    // 8) Failure/payoff overlays: smother lid descend, ignition shockwave.
    _renderShock(canvas, notch);
    _renderSmother(canvas, Offset(emberWorld.x, emberWorld.y));
  }

  void _renderNotch(Canvas canvas, Offset at) {
    final Rect r = Rect.fromCenter(center: at, width: 30, height: 15);
    canvas.drawOval(r, Paint()..color = palette.woodDark);
    canvas.drawOval(
      r,
      Paint()
        ..color = palette.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    if (_heat <= 0.01) return;
    final double pulse = _reduceMotion ? 1.0 : 0.85 + 0.15 * math.sin(_t * 14.0);
    final Color hot = Color.lerp(palette.emberDeep, palette.emberBright, _heat)!;
    canvas.drawOval(
      r.deflate(2),
      Paint()..color = hot.withValues(alpha: (0.85 * _heat * pulse).clamp(0.0, 1.0)),
    );
    // The friction heat texture: hot dust + smoke speckle scaling with the live
    // heat (dies as it cools — the HARD-bleed reads on the wood itself).
    CraftKit.emberSpeckle(
      canvas,
      area: Rect.fromCenter(center: at.translate(0, -8), width: 34, height: 30),
      value: _heat,
      time: _t,
      maxCount: 12,
      warm: palette.ember,
      hot: palette.emberBright,
      seed: 7,
      reduceMotion: _reduceMotion,
    );
    CraftKit.bloomStack(
      canvas,
      center: at,
      radius: 24 * _heat,
      intensity: _heat,
      warm: palette.ember,
      hot: palette.spark,
    );
  }

  void _renderTinder(Canvas canvas, Offset notch) {
    // Hide the tuft once it has fully seated AND the ember is alive (it's been
    // consumed into the fire).
    if (_ember > 0.2 || _flame > 0.05) return;
    final Offset start = Offset(tinderStartWorld.x, tinderStartWorld.y);
    final Offset at = Offset.lerp(start, notch, _fuel.clamp(0.0, 1.0))!;
    // Damp slump: the tuft droops + a wet drip when the damp pick is dragged.
    final double droop = _slump * 8.0;
    final Color blade = _slump > 0.01
        ? Color.lerp(palette.grassDark, palette.cold, 0.4)!
        : palette.grass;
    final Paint p = Paint()
      ..color = blade
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    for (final double dx in <double>[-9, -3, 3, 9]) {
      final Path b = Path()
        ..moveTo(at.dx + dx, at.dy + 6)
        ..quadraticBezierTo(
          at.dx + dx + dx.sign * 4, at.dy - 6 + droop,
          at.dx + dx + dx.sign * 8, at.dy - 14 + droop * 1.5,
        );
      canvas.drawPath(b, p);
    }
    if (_slump > 0.05) {
      // A wet drip falling from the damp tuft.
      canvas.drawCircle(
        Offset(at.dx, at.dy + 8 + _slump * 6),
        2.2,
        Paint()..color = palette.cold.withValues(alpha: 0.8 * _slump),
      );
    }
  }

  void _renderSpindle(Canvas canvas, Offset notch) {
    if (_ember > 0.2 || _flame > 0.05) return; // consumed into the fire
    final double press = _press * 4.0;
    final Offset footAt = notch.translate(0, press);
    final Offset wheelAt = Offset(wheelWorld.x, wheelWorld.y + press);
    // The lit shaft, glowing up its flank as the notch heats. It runs from the
    // notch up to the crank wheel hub.
    CraftKit.litCylinder(
      canvas,
      base: footAt,
      w: _poleW,
      h: _poleH,
      body: palette.wood,
      shade: palette.woodDark,
      outline: palette.outline,
      specular: 0.7,
      glow: _heat * 0.7,
      glowColor: palette.emberBright,
      contactShadow: false,
    );
    // A bright spin streak down the shaft when whirling (motion read).
    if (_spinVel > 1.0) {
      final double a = (_spinVel / 24.0).clamp(0.0, 1.0) * 0.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(footAt.dx - 1.5, footAt.dy - _poleH, 3, _poleH),
          const Radius.circular(2),
        ),
        Paint()..color = palette.spark.withValues(alpha: a),
      );
    }
    // The BIG crank wheel at the top of the shaft — a clearly larger disc the
    // finger grabs by its rim knob and turns. Rotates 1:1 with the finger.
    _renderCrankWheel(canvas, wheelAt);
  }

  /// The bigger crank wheel: a volumetric hub disc + a grab-knob on its rim that
  /// rotates around the wheel centre by [_wheelAngle] (the finger's live sweep).
  /// Sized large + finger-friendly so it is easy to grab and turn.
  void _renderCrankWheel(Canvas canvas, Offset center) {
    // Contact shadow under the wheel.
    canvas.drawOval(
      Rect.fromCenter(
          center: center.translate(0, _wheelR * 0.46), width: _wheelR * 2.0, height: _wheelR * 0.5),
      Paint()
        ..color = palette.outline.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // The wheel rim disc (a lit, rounded hub reads as a turnable wheel).
    final Rect disc = Rect.fromCircle(center: center, radius: _wheelR);
    canvas.drawCircle(
      center,
      _wheelR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          colors: <Color>[palette.wood, palette.woodDark],
        ).createShader(disc),
    );
    canvas.drawCircle(
      center,
      _wheelR,
      Paint()
        ..color = palette.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // Heat glow up the rim as the notch warms (the wheel is in the heat loop).
    if (_heat > 0.01) {
      canvas.drawCircle(
        center,
        _wheelR,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = palette.emberBright.withValues(alpha: 0.18 * _heat),
      );
    }

    // The rotating parts: an inner spoke cross + the rim grab-knob, both turning
    // 1:1 with the finger so the wheel visibly follows the drag.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_wheelAngle);
    // Spokes (a cross) so the rotation reads clearly even on a plain disc. The
    // canvas is already rotated, so a plain H + V cross suffices.
    final Paint spoke = Paint()
      ..color = palette.woodDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    const double sp = _wheelR * 0.78;
    canvas.drawLine(const Offset(-sp, 0), const Offset(sp, 0), spoke);
    canvas.drawLine(const Offset(0, -sp), const Offset(0, sp), spoke);
    // The grab-knob on the rim (the obvious thing to put a finger on + turn).
    const Offset knobAt = Offset(_wheelR * 0.72, 0);
    canvas.drawCircle(
      knobAt,
      _knobR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: <Color>[palette.rock, palette.rockDark],
        ).createShader(Rect.fromCircle(center: knobAt, radius: _knobR)),
    );
    canvas.drawCircle(
      knobAt,
      _knobR,
      Paint()
        ..color = palette.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();

    // The hub cap (a small fixed centre boss).
    canvas.drawCircle(center, 9, Paint()..color = palette.woodDark);
    canvas.drawCircle(center, 9,
        Paint()
          ..color = palette.outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  void _renderFire(Canvas canvas, Offset notch) {
    final Offset emberAt = Offset(emberWorld.x, emberWorld.y);
    final double level = math.max(_flame, _ember);
    if (level <= 0.001) return;
    final double flicker =
        _reduceMotion ? 1.0 : 0.9 + 0.1 * math.sin(_t * 12.0);
    final double lean = _puff * 12.0 * _puffDir;
    final double bornPop = 1.0 + _born * 0.4;

    // Ember core (a glowing coal) — pops on birth.
    if (_ember > 0.0) {
      final double er = (6 + 9 * _ember) * bornPop;
      canvas.drawCircle(emberAt.translate(0, -4), er,
          Paint()..color = palette.emberDeep.withValues(alpha: (0.5 + 0.5 * _ember).clamp(0.0, 1.0)));
      canvas.drawCircle(emberAt.translate(0, -4), er * 0.55,
          Paint()..color = palette.emberBright.withValues(alpha: _ember));
    }

    // The volumetric flame: a leaning teardrop shape + a CraftKit bloomStack so
    // it truly gives off light. Flame scales with the live flame channel.
    if (_flame > 0.02) {
      final double h = (34 + 86 * _flame + 12 * _puff) * flicker;
      final double w = 20 + 26 * _flame;
      canvas.save();
      canvas.translate(emberAt.dx, emberAt.dy);
      canvas.skew(-lean / math.max(h, 1.0), 0);
      final Path outer = _flamePath(w, h);
      canvas.drawPath(outer, Paint()..color = palette.ember.withValues(alpha: 0.92));
      final Path inner = _flamePath(w * 0.55, h * 0.7);
      canvas.drawPath(inner, Paint()..color = palette.emberBright.withValues(alpha: 0.95));
      canvas.restore();
    }

    // Light bloom (additive) over the whole fire, brighter near ignition + on a
    // puff (air feeds the flame, visibly).
    CraftKit.bloomStack(
      canvas,
      center: emberAt.translate(0, -h(_flame)),
      radius: 60 + 90 * level + 24 * _puff,
      intensity: (level + 0.3 * _puff).clamp(0.0, 1.0),
      warm: palette.ember,
      hot: palette.spark,
    );

    // Rising swirling embers, denser with more fire (deterministic field).
    CraftKit.emberSpeckle(
      canvas,
      area: Rect.fromLTWH(emberAt.dx - 24, emberAt.dy - 110 * level, 48, 110 * level + 10),
      value: level,
      time: _t,
      maxCount: 16,
      warm: palette.ember,
      hot: palette.emberBright,
      seed: 3,
      reduceMotion: _reduceMotion,
    );
  }

  double h(double flame) => 17 + 43 * flame; // flame mid-height for bloom anchor

  void _renderLid(Canvas canvas) {
    // The stone lid only appears once there's an ember to (mis)cover.
    if (_ember <= 0.05 && _flame <= 0.05) return;
    if (_smother > 0.01) return; // it's busy descending on the ember
    final Offset at = Offset(lidRestWorld.x, lidRestWorld.y);
    CraftKit.litCylinder(
      canvas,
      base: at.translate(0, 8),
      w: 46,
      h: 18,
      body: palette.rock,
      shade: palette.rockDark,
      outline: palette.outline,
      radiusFactor: 0.5,
      specular: 0.4,
    );
  }

  void _renderShock(Canvas canvas, Offset at) {
    if (_shock <= 0.001) return;
    final double s = _shock.clamp(0.0, 1.0);
    final double r = 24 + (1.0 - s) * 150;
    canvas.drawCircle(
      at.translate(0, -34),
      r,
      Paint()
        ..color = palette.spark.withValues(alpha: s * 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 + 5 * s
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  void _renderSmother(Canvas canvas, Offset emberAt) {
    if (_smother <= 0.001) return;
    final double s = _smother.clamp(0.0, 1.0);
    // The lid slides in from its rest and caps the ember (cutting the air).
    final Offset rest = Offset(lidRestWorld.x, lidRestWorld.y);
    final Offset at = Offset.lerp(emberAt.translate(0, -10), rest, 1.0 - s)!;
    final Rect lid = Rect.fromCenter(center: at, width: 50, height: 20);
    canvas.drawRRect(
      RRect.fromRectAndRadius(lid, const Radius.circular(8)),
      Paint()..color = palette.rock,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lid, const Radius.circular(8)),
      Paint()
        ..color = palette.rockDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  Path _flamePath(double w, double hh) {
    return Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(w, -hh * 0.35, w * 0.25, -hh * 0.7)
      ..quadraticBezierTo(0, -hh * 0.9, 0, -hh)
      ..quadraticBezierTo(0, -hh * 0.9, -w * 0.25, -hh * 0.7)
      ..quadraticBezierTo(-w, -hh * 0.35, 0, 0)
      ..close();
  }
}

// =============================================================================
// A full-screen warmth WASH (screen-space) that blooms as the fire grows — the
// "the screen warms" lever, scaled by the live channels, with an ignition flash.
// =============================================================================
class _WarmthWash extends PositionComponent with HasGameReference<EmberGame> {
  _WarmthWash({required this.palette})
      : super(position: Vector2.zero(), anchor: Anchor.topLeft);

  final EmberPalette palette;

  double _heat = 0.0;
  double _ember = 0.0;
  double _flame = 0.0;
  double _t = 0.0;
  double _flash = 0.0;
  bool _reduceMotion = false;

  @override
  Future<void> onLoad() async {
    _reduceMotion = game.disableAnimations;
  }

  void setLevels({
    required double fuel,
    required double heat,
    required double ember,
    required double flame,
    required double air,
  }) {
    _heat = heat.clamp(0.0, 1.0);
    _ember = ember.clamp(0.0, 1.0);
    _flame = flame.clamp(0.0, 1.0);
  }

  void flash() => _flash = 1.0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    size = game.size.clone();
    if (_flash > 0.0) _flash = (_flash - dt * 1.6).clamp(0.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final double w = size.x;
    final double hgt = size.y;
    if (w <= 0 || hgt <= 0) return;
    final double warmth =
        (_heat * 0.35 + _ember * 0.55 + _flame * 1.0).clamp(0.0, 1.0);
    final double breathe =
        _reduceMotion ? 1.0 : 0.92 + 0.08 * math.sin(_t * 3.0);

    if (warmth > 0.01) {
      final Offset at = Offset(w * 0.5, hgt * 0.40);
      final double r = math.max(w, hgt) * (0.35 + 0.4 * warmth) * breathe;
      canvas.drawCircle(
        at,
        r,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(
            colors: <Color>[
              palette.ember.withValues(alpha: 0.16 * warmth),
              palette.ember.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: at, radius: r)),
      );
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, hgt),
        Paint()..color = palette.ember.withValues(alpha: 0.06 * warmth),
      );
    }

    if (_flash > 0.01) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, hgt),
        Paint()..color = palette.spark.withValues(alpha: (0.45 * _flash).clamp(0.0, 1.0)),
      );
    }
  }
}

// =============================================================================
// The continuous FIRE TRIANGLE: three corners (FUEL / HEAT / AIR) that FILL from
// the live felt channels (not binary events). Each corner glows in proportion to
// its channel, the connecting edges light with the min of their endpoints, a
// failure flashes the matching corner red, and ignition blazes all three. The
// concept is NAMED LAST in the caption, not here — this is the felt meter.
// =============================================================================
enum _TriSide { fuel, heat, air }

class _FireTriangleHud extends PositionComponent {
  _FireTriangleHud({
    required this.palette,
    required Vector2 center,
    required this.radius,
  }) : super(position: center, anchor: Anchor.center);

  final EmberPalette palette;
  final double radius;

  // The LIVE fill per side (set continuously from the channels by the scene).
  final Map<_TriSide, double> _fill = <_TriSide, double>{
    _TriSide.fuel: 0.0,
    _TriSide.heat: 0.0,
    _TriSide.air: 0.0,
  };
  final Map<_TriSide, double> _failFlash = <_TriSide, double>{
    _TriSide.fuel: 0.0,
    _TriSide.heat: 0.0,
    _TriSide.air: 0.0,
  };
  double _celebrate = 0.0;
  double _t = 0.0;

  void setLevels({required double fuel, required double heat, required double air}) {
    _fill[_TriSide.fuel] = fuel.clamp(0.0, 1.0);
    _fill[_TriSide.heat] = heat.clamp(0.0, 1.0);
    _fill[_TriSide.air] = air.clamp(0.0, 1.0);
  }

  void flashFail(_TriSide side) {
    _failFlash[side] = 1.0;
    _fill[side] = 0.0;
  }

  void celebrate() {
    _celebrate = 1.0;
    for (final _TriSide s in _TriSide.values) {
      _fill[s] = 1.0;
    }
  }

  void reset() {
    for (final _TriSide s in _TriSide.values) {
      _fill[s] = 0.0;
      _failFlash[s] = 0.0;
    }
    _celebrate = 0.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    for (final _TriSide s in _TriSide.values) {
      if (_failFlash[s]! > 0.0) {
        _failFlash[s] = (_failFlash[s]! - dt * 1.3).clamp(0.0, 1.0);
      }
    }
    if (_celebrate > 0.0) _celebrate = (_celebrate - dt * 0.6).clamp(0.0, 1.0);
  }

  Offset _vertex(_TriSide s) {
    switch (s) {
      case _TriSide.fuel:
        return Offset(-radius * 0.86, -radius * 0.5);
      case _TriSide.heat:
        return Offset(radius * 0.86, -radius * 0.5);
      case _TriSide.air:
        return Offset(0, radius * 0.7);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _edge(canvas, _TriSide.fuel, _TriSide.heat);
    _edge(canvas, _TriSide.heat, _TriSide.air);
    _edge(canvas, _TriSide.air, _TriSide.fuel);
    for (final _TriSide s in _TriSide.values) {
      _glyph(canvas, s);
    }
  }

  void _edge(Canvas canvas, _TriSide a, _TriSide b) {
    final double lit = math.min(_fill[a]!, _fill[b]!);
    if (lit <= 0.01 && _celebrate <= 0.01) return;
    final double pulse =
        _celebrate > 0.01 ? (0.7 + 0.3 * math.sin(_t * 8.0)) : 1.0;
    final double l = math.max(lit, _celebrate);
    canvas.drawLine(
      _vertex(a),
      _vertex(b),
      Paint()
        ..color = palette.ember.withValues(alpha: (0.6 * l * pulse).clamp(0.0, 1.0))
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  void _glyph(Canvas canvas, _TriSide s) {
    final Offset o = _vertex(s);
    final double lit = math.max(_fill[s]!, _celebrate);
    final double fail = _failFlash[s]!;
    final Color baseColor = fail > 0.01
        ? Color.lerp(palette.surfaceRaised, palette.danger, fail)!
        : Color.lerp(palette.surfaceRaised,
            Color.lerp(palette.ember, palette.emberBright, lit)!, lit)!;
    final double pulse =
        lit > 0.5 ? (0.92 + 0.08 * math.sin(_t * 9.0 + s.index)) : 1.0;
    const double rad = 22;

    if (lit > 0.05) {
      final double hr = rad * (1.8 + 0.4 * lit) * pulse;
      canvas.drawCircle(
        o,
        hr,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(
            colors: <Color>[
              palette.emberBright.withValues(alpha: 0.4 * lit),
              palette.ember.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: o, radius: hr)),
      );
    }
    if (fail > 0.05) {
      final double hr = rad * 2.0;
      canvas.drawCircle(
        o,
        hr,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(
            colors: <Color>[
              palette.danger.withValues(alpha: 0.45 * fail),
              palette.danger.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: o, radius: hr)),
      );
    }

    canvas.drawCircle(o, rad * pulse, Paint()..color = baseColor);
    canvas.drawCircle(
      o,
      rad * pulse,
      Paint()
        ..color = palette.outline.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final Color ink = lit > 0.05 ? palette.night : palette.inkSoft;
    _icon(canvas, s, o, ink);
  }

  void _icon(Canvas canvas, _TriSide s, Offset o, Color ink) {
    final Paint p = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    switch (s) {
      case _TriSide.fuel:
        for (final double dx in <double>[-7, 0, 7]) {
          final Path blade = Path()
            ..moveTo(o.dx + dx, o.dy + 9)
            ..quadraticBezierTo(o.dx + dx + dx.sign * 3, o.dy - 2,
                o.dx + dx + dx.sign * 6, o.dy - 9);
          canvas.drawPath(blade, p);
        }
      case _TriSide.heat:
        canvas.drawCircle(o, 4, Paint()..color = ink);
        for (int i = 0; i < 8; i++) {
          final double ang = i * math.pi / 4;
          final Offset d = Offset(math.cos(ang), math.sin(ang));
          canvas.drawLine(o + d * 7, o + d * 11, p);
        }
      case _TriSide.air:
        final Path swirl = Path()
          ..moveTo(o.dx - 9, o.dy - 2)
          ..quadraticBezierTo(o.dx, o.dy - 11, o.dx + 8, o.dy - 4)
          ..quadraticBezierTo(o.dx + 12, o.dy + 1, o.dx + 5, o.dy + 3);
        canvas.drawPath(swirl, p);
        final Path swirl2 = Path()
          ..moveTo(o.dx - 9, o.dy + 7)
          ..quadraticBezierTo(o.dx + 2, o.dy + 11, o.dx + 9, o.dy + 6);
        canvas.drawPath(swirl2, p);
    }
  }
}
