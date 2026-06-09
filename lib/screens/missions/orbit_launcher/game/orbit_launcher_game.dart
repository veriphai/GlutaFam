// The Flame stage for Orbit Launcher V2.
//
// Coordinate model: components on the game root, transparent background, so game
// coords == GameWidget logical pixels. The backdrop (launchpad / clouds / space
// / globe) is rendered IN Flame; the Flutter shell draws only UI chrome on top.
//
// The game owns NO input — LAUNCH / sliders / LAUNCH MISSION / card buttons are
// Flutter widgets that call the controller. This game LISTENS to the controller
// and plays each scene's visuals, calling back at beats (straightLaunchDone,
// missionResolved) to advance the state machine.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/services.dart';

import '../config/asset_paths.dart';
import '../config/orbit_tuning.dart';
import '../state/orbit_launcher_controller.dart';
import '../state/orbit_launcher_state.dart';
import 'components/rocket_actor.dart';
import 'components/stage_backdrop.dart';
import 'components/trajectory_component.dart';
import '../../../../utils/s3_assets.dart';

double _rad(double deg) => deg * math.pi / 180;

class OrbitLauncherGame extends FlameGame {
  OrbitLauncherGame({required this.controller, required this.onSound});

  final OrbitLauncherController controller;
  final void Function(String assetFile) onSound;

  late final StageBackdrop _backdrop;
  late final RocketActor _rocket;
  late final TrajectoryComponent _traj;
  SpriteComponent? _satellite;
  _OrbitRunner? _orbitRunner;

  bool _ready = false;
  OrbitActivityState? _lastScene;

  @override
  Color backgroundColor() => const Color(0xFF05102A);

  Sprite _sprite(String flamePath) => Sprite(images.fromCache(flamePath));

  @override
  Future<void> onLoad() async {
    await preloadFlameImagesFromS3(images, OL.preload);
    final stage = size.clone();

    _backdrop = StageBackdrop(stage: stage, spriteOf: _sprite);
    _traj = TrajectoryComponent()..priority = 40;
    _rocket = RocketActor(stage: stage);

    await add(_backdrop);
    add(_traj);
    await add(_rocket);

    controller.addListener(_onControllerChanged);
    _ready = true;
    _lastScene = OrbitActivityState.missionBrief;
    _enterLaunchpad(); // ready behind the start-screen overlay
  }

  @override
  void onRemove() {
    controller.removeListener(_onControllerChanged);
    super.onRemove();
  }

  // ── geometry shortcuts ───────────────────────────────────────────────────
  Vector2 get _pad => _backdrop.rocketPad;
  Vector2 get _globeC => _backdrop.globeCenter;
  double get _globeR => _backdrop.globeRadius;
  double get _orbitR => _backdrop.orbitRadius;
  Vector2 get _spaceEntry => Vector2(size.x * 0.5, size.y * 0.22);

  // ── controller reactions ───────────────────────────────────────────────────
  void _onControllerChanged() {
    if (!_ready) return;
    final scene = controller.state.scene;
    if (scene == _lastScene) return;
    _lastScene = scene;

    switch (scene) {
      case OrbitActivityState.missionBrief:
        break; // start-screen overlay (Flutter); launchpad already staged
      case OrbitActivityState.missionGoal:
      case OrbitActivityState.launchpadIntro:
      case OrbitActivityState.tiltUnlocked:
      case OrbitActivityState.challengeReady:
        _enterLaunchpad();
      case OrbitActivityState.straightLaunchAnimating:
        _playStraightLaunch();
      case OrbitActivityState.missionLaunching:
        _playMission();
      case OrbitActivityState.straightLaunchFailed:
      case OrbitActivityState.notEnoughPower:
      case OrbitActivityState.tooStraight:
      case OrbitActivityState.tooMuchTilt:
      case OrbitActivityState.tooFast:
      case OrbitActivityState.almost:
      case OrbitActivityState.orbitLocked:
        break; // visuals were played by the launch; rest in place
      case OrbitActivityState.nextActivityBridge:
        _enterBridge();
    }
  }

  // ── scene: launchpad (intro / tilt-unlock / challenge) ──────────────────────
  void _enterLaunchpad() {
    _clearFlight();
    _removeOrbit();
    _backdrop.resetGround();
    _rocket
      ..setVisual(RocketVisual.pad)
      ..rest(_pad);
  }

  // ── scene: straight-up launch (forced fail) ─────────────────────────────────
  // A real vertical projectile at a fixed moderate power: rises, slows, falls.
  void _playStraightLaunch() {
    _clearFlight();
    onSound(OLSounds.tap);
    HapticFeedback.lightImpact();
    _runBallistic(
      power: OT.straightPower,
      tilt: 0,
      color: OT.colAscend,
      onLand: (pos) {
        _crash(pos, OT.colNotEnoughPower);
        _rocket
          ..angle = 0
          ..setVisual(RocketVisual.pad)
          ..rest(_pad);
        controller.straightLaunchDone();
      },
    );
  }

  // ── scene: a real mission launch ────────────────────────────────────────────
  void _playMission() {
    _clearFlight();
    onSound(OLSounds.tap);
    HapticFeedback.lightImpact();

    final outcome = controller.launchingOutcome;
    switch (outcome) {
      case OrbitOutcome.notEnoughPower:
      case OrbitOutcome.tooStraight:
      case OrbitOutcome.tooMuchTilt:
        // Ballistic fails — height + flight time scale with power; tilt curves
        // the arc sideways. All happen in the GROUND/sky framing.
        _runBallistic(
          power: controller.state.launchPower,
          tilt: controller.state.tiltAngle,
          color: OT.trajColor(outcome),
          onLand: (pos) {
            _crash(pos, OT.trajColor(outcome));
            _rocket.angle = 0;
            controller.missionResolved();
          },
        );
      case OrbitOutcome.tooFast:
        _playTooFast();
      case OrbitOutcome.almost:
        _playAlmost();
      case OrbitOutcome.orbitLocked:
        _playOrbit();
    }
  }

  // Real projectile motion: launch speed from [power], launch angle from [tilt],
  // gravity integrated each frame. Rises (decelerating), arcs, and falls back —
  // higher power ⇒ higher apex AND longer flight. Clouds parallax with height.
  void _runBallistic({
    required double power,
    required double tilt,
    required Color color,
    required void Function(Vector2 landPos) onLand,
  }) {
    final pad = _pad.clone();
    final apexFrac = OT.apexFracLow + (OT.apexFracHigh - OT.apexFracLow) * (power.clamp(0, 100) / 100);
    final g = OT.gFactor * size.y;
    final vy0 = math.sqrt(2 * g * apexFrac * size.y); // upward px/s
    final vx = OT.vxFactor * (tilt / 100) * vy0; // rightward px/s
    final lean = (OT.maxTiltRad * (tilt / 100) * 0.5).clamp(0.0, 0.6);

    final exhaust = _spawnExhaust(pad);
    _rocket
      ..idle = false
      ..angle = 0
      ..setVisual(RocketVisual.vertical);
    final trail = <Vector2>[];
    var lastSmoke = -1.0;
    _traj
      ..clear()
      ..color = color
      ..opacity = 0.9
      ..progress = 1;
    var killedExhaust = false;

    add(_BallisticRunner(
      start: pad,
      vx: vx,
      vy0: vy0,
      g: g,
      groundY: pad.y,
      onStep: (pos, vyNow, t) {
        _rocket.position = pos;
        trail.add(pos.clone());
        if (trail.length >= 2) _traj.setPath(trail);
        _backdrop.setAscent(((pad.y - pos.y) / size.y).clamp(0.0, 1.0));
        if (vyNow > 0) {
          _rocket
            ..setVisual(tilt > 55 ? RocketVisual.tilted : RocketVisual.vertical)
            ..angle = lean;
          _followExhaust(exhaust, pos, t);
          if (t - lastSmoke > 0.12) {
            lastSmoke = t;
            _spawnEffect(OL.crashPuff, pos + Vector2(0, _rocket.size.y * 0.4), size.x * 0.22,
                additive: false, hold: 0.1, fadeOut: 0.8, scaleFrom: 0.4, scaleTo: 0.95, priority: 50);
          }
        } else {
          if (!killedExhaust) {
            killedExhaust = true;
            _killExhaust(exhaust);
            _rocket.setVisual(RocketVisual.falling);
          }
          _rocket.angle = lean + math.sin(t * 16) * 0.08;
        }
      },
      onLand: (pos) {
        _backdrop.setAscent(0);
        onLand(pos);
      },
    ));
  }

  // Shared GROUND→SPACE powered climb for the high-altitude outcomes — a long
  // cinematic ascent through the clouds whose duration scales with power — then
  // [onSpace] runs the space arc.
  void _liftToSpace(void Function() onSpace, {bool showGlobe = true}) {
    final exhaust = _spawnExhaust(_pad);
    _rocket
      ..idle = false
      ..angle = 0
      ..setVisual(RocketVisual.vertical);
    _traj
      ..clear()
      ..setPath([_pad.clone(), _spaceEntry.clone()])
      ..color = OT.colAscend
      ..opacity = 0.85
      ..progress = 0;
    var lastSmoke = 0.0;
    add(_FlightRunner(
      duration: OT.ascentDurForPower(controller.state.launchPower),
      curve: Curves.easeInOutCubic,
      onStep: (e) {
        _traj.progress = e;
        final pos = _traj.pointAtFraction(e);
        _rocket.position = pos;
        _followExhaust(exhaust, pos, e * 8);
        _backdrop.setAscent(e);
        lastSmoke = _maybeSmoke(pos, e, lastSmoke);
        if (e > 0.6 && !_backdrop.inSpace) _backdrop.toSpace(showGlobe: showGlobe);
      },
      onDone: () {
        _killExhaust(exhaust);
        _traj.clear();
        onSpace();
      },
    ));
  }

  void _playTooFast() {
    _liftToSpace(() {
      // Tilts, accelerates and escapes off the top-right.
      final escapeEnd = Vector2(size.x * 1.15, -size.y * 0.2);
      final pts = _bezier(_spaceEntry, Vector2(size.x * 0.7, size.y * 0.10),
          Vector2(size.x * 0.95, size.y * 0.0), escapeEnd, n: 50);
      _rocket.setVisual(RocketVisual.tilted);
      _runArc(pts, OT.colTooFast, OT.escapeFlight, tiltLean: 0.6, trail: true, onDone: () {
        onSound(OLSounds.wrong);
        controller.missionResolved();
      });
    });
  }

  void _playAlmost() {
    _liftToSpace(() {
      // Curves most of the way around the globe (the path "started curving"), but
      // can't complete the loop — it spirals inward and drifts off near the start.
      final c = _globeC;
      final arc = _arc(c, _orbitR, 90, 90 - 300, n: 80); // clockwise ~300°
      final decay = <Vector2>[];
      for (var i = 1; i <= 16; i++) {
        final f = i / 16;
        final a = (90 - 300) - 30 * f;
        final r = _orbitR + (_globeR * 1.02 - _orbitR) * f; // dip toward the surface
        decay.add(c + Vector2(math.cos(a * math.pi / 180), -math.sin(a * math.pi / 180)) * r);
      }
      _rocket.setVisual(RocketVisual.tilted);
      _runArc([...arc, ...decay], OT.colAlmost, OT.arcFlight + 0.4, tiltLean: 0.5, fallSwap: 0.85,
          onDone: () {
        _crash(decay.last, OT.colAlmost);
        controller.missionResolved();
      });
    });
  }

  void _playOrbit() {
    _liftToSpace(() {
      // Lead-in onto the top of the orbit, separate the satellite, then loop.
      final orbitTop = _globeC + Vector2(0, -_orbitR);
      final pts = _bezier(_spaceEntry, Vector2(size.x * 0.6, size.y * 0.14), orbitTop + Vector2(size.x * 0.1, 0), orbitTop, n: 48);
      _rocket.setVisual(RocketVisual.release);
      _runArc(pts, OT.colOrbit, OT.orbitEntry, tiltLean: 0.5, onDone: () {
        // separation flash → hand the orbit to a satellite (the burst masks the
        // rocket parking off-screen)
        _spawnEffect(OL.sparkles, orbitTop, size.x * 0.34, hold: 0.2, fadeOut: 0.5, priority: 70);
        _rocket.position = Vector2(-size.x, -size.y); // park off-screen

        _spawnSatellite(orbitTop);
        // full green orbit ellipse + continuous clockwise loop from the top
        _traj
          ..clear()
          ..setPath(_arc(_globeC, _orbitR, 90, 90 - 360, n: 96))
          ..color = OT.colOrbit
          ..opacity = 1
          ..progress = 1;
        _orbitRunner = _OrbitRunner(
          target: _satellite!,
          center: _globeC,
          radius: _orbitR,
          speed: -2 * math.pi / OT.orbitPeriod,
          startAngle: _rad(90),
        );
        add(_orbitRunner!);

        onSound(OLSounds.correct);
        HapticFeedback.mediumImpact();
        _celebrate(_globeC);
        controller.missionResolved();
      });
    });
  }

  // ── scene: bridge ────────────────────────────────────────────────────────
  void _enterBridge() {
    _backdrop.toSpace(showGlobe: true);
    onSound(OLSounds.complete);
    if (_satellite == null) {
      // arriving without having just orbited (defensive) — set up the loop
      _spawnSatellite(_globeC + Vector2(0, -_orbitR), empty: true);
      _traj
        ..clear()
        ..setPath(_arc(_globeC, _orbitR, 90, 90 - 360, n: 96))
        ..color = OT.colOrbit
        ..opacity = 1
        ..progress = 1;
      _orbitRunner = _OrbitRunner(
        target: _satellite!,
        center: _globeC,
        radius: _orbitR,
        speed: -2 * math.pi / OT.orbitPeriod,
        startAngle: _rad(90),
      );
      add(_orbitRunner!);
    } else {
      _swapSatelliteSprite(OL.satEmpty);
    }
  }

  // ── satellite (post-separation orbit) ───────────────────────────────────────
  void _spawnSatellite(Vector2 at, {bool empty = false}) {
    _satellite?.removeFromParent();
    final s = _sprite(OL.flame(empty ? OL.satEmpty : OL.satAngled));
    final w = size.x * OT.satWidthFactor;
    _satellite = SpriteComponent(
      sprite: s,
      anchor: Anchor.center,
      position: at.clone(),
      size: Vector2(w, w * (s.srcSize.y / s.srcSize.x)),
      priority: 62,
    );
    add(_satellite!);
  }

  void _swapSatelliteSprite(String path) {
    final sat = _satellite;
    if (sat == null) return;
    final s = _sprite(OL.flame(path));
    sat.sprite = s;
    final w = size.x * OT.satWidthFactor;
    sat.size = Vector2(w, w * (s.srcSize.y / s.srcSize.x));
  }

  // ── arc helper (rocket follows a curve, optional tilt + trail + fall swap) ───
  void _runArc(
    List<Vector2> pts,
    Color color,
    double dur, {
    required VoidCallback onDone,
    double tiltLean = 0, // radians of constant lean
    double fallSwap = 2, // fraction >1 ⇒ never swaps to the falling sprite
    bool trail = false,
  }) {
    _traj
      ..clear()
      ..setPath(pts)
      ..color = color
      ..opacity = 1
      ..progress = 0;
    var lastTrail = 0.0;
    add(_FlightRunner(
      duration: dur,
      curve: Curves.easeInOut,
      onStep: (e) {
        _traj.progress = e;
        _rocket.position = _traj.pointAtFraction(e);
        _rocket.angle = tiltLean;
        if (e >= fallSwap && _rocket.visual != RocketVisual.falling) {
          _rocket.setVisual(RocketVisual.falling);
        }
        if (trail && e - lastTrail > 0.05) {
          lastTrail = e;
          _spawnEffect(OL.escapeTrail, _rocket.position, size.x * 0.2,
              hold: 0, fadeOut: 0.35, scaleFrom: 0.7, scaleTo: 0.7, priority: 45);
        }
      },
      onDone: onDone,
    ));
  }

  void _crash(Vector2 at, Color tint) {
    onSound(OLSounds.wrong);
    HapticFeedback.lightImpact();
    _spawnEffect(OL.crashPuff, at, size.x * 0.42,
        additive: false, hold: 0.3, fadeOut: 0.6, scaleFrom: 0.5, priority: 58);
    _spawnEffect(OL.warningGlow, at, size.x * 0.30,
        additive: true, tint: tint, hold: 0.25, fadeOut: 0.5, scaleFrom: 0.6, priority: 57);
  }

  void _celebrate(Vector2 c) {
    final burstAt = Vector2(c.x, c.y - _globeR - size.y * 0.03);
    _spawnEffect(OL.sparkles, burstAt, _globeR * 1.0, hold: 0.7, fadeOut: 0.9, scaleFrom: 0.5, priority: 70);
    _spawnEffect(OL.confetti, burstAt, size.x * 0.55,
        additive: false, hold: 0.9, fadeOut: 1.0, scaleFrom: 0.4, priority: 72);
  }

  // ── exhaust plume (grows under the rocket during powered flight) ─────────────
  SpriteComponent _spawnExhaust(Vector2 base) {
    final s = _sprite(OL.flame(OL.rocketPlume));
    final comp = SpriteComponent(
      sprite: s,
      anchor: Anchor.topCenter,
      position: base.clone(),
      size: Vector2(size.x * 0.16, size.x * 0.16 * (s.srcSize.y / s.srcSize.x)),
      priority: 55,
    )..paint = (Paint()..blendMode = BlendMode.plus);
    comp.opacity = 0;
    comp.add(OpacityEffect.to(0.9, EffectController(duration: 0.2)));
    add(comp);
    return comp;
  }

  void _followExhaust(SpriteComponent exhaust, Vector2 rocketPos, double e) {
    // sits at the rocket's tail (top-anchored just below the body)
    exhaust.position = rocketPos + Vector2(0, _rocket.size.y * 0.32);
    final h = size.x * (0.18 + 0.10 * math.sin(e * 30).abs());
    exhaust.size = Vector2(size.x * 0.14, h);
  }

  void _killExhaust(SpriteComponent exhaust) {
    exhaust.add(OpacityEffect.to(0, EffectController(duration: 0.2)));
    exhaust.add(RemoveEffect(delay: 0.25));
  }

  double _maybeSmoke(Vector2 pos, double e, double last) {
    if (e - last < 0.07) return last;
    _spawnEffect(OL.crashPuff, pos + Vector2(0, _rocket.size.y * 0.4), size.x * 0.22,
        additive: false, hold: 0.1, fadeOut: 0.7, scaleFrom: 0.4, scaleTo: 0.9, priority: 50);
    return e;
  }

  // ── teardown ─────────────────────────────────────────────────────────────
  void _clearFlight() {
    _traj.clear();
    children.whereType<_FlightRunner>().toList().forEach((c) => c.removeFromParent());
    children.whereType<_BallisticRunner>().toList().forEach((c) => c.removeFromParent());
    children.whereType<_DelayedCall>().toList().forEach((c) => c.removeFromParent());
  }

  void _removeOrbit() {
    _orbitRunner?.removeFromParent();
    _orbitRunner = null;
    _satellite?.removeFromParent();
    _satellite = null;
  }

  // ── generic effect spawner ───────────────────────────────────────────────
  SpriteComponent _spawnEffect(
    String flameAsset,
    Vector2 at,
    double width, {
    bool additive = true,
    double scaleFrom = 0.6,
    double scaleTo = 1.0,
    double fadeOut = 0.4,
    double hold = 0.3,
    Color? tint,
    int priority = 80,
  }) {
    final s = _sprite(OL.flame(flameAsset));
    final comp = SpriteComponent(
      sprite: s,
      anchor: Anchor.center,
      position: at.clone(),
      size: Vector2(width, width * (s.srcSize.y / s.srcSize.x)),
      priority: priority,
    )..paint = (additive ? (Paint()..blendMode = BlendMode.plus) : Paint());
    if (tint != null) comp.paint.colorFilter = ColorFilter.mode(tint, BlendMode.modulate);
    comp.scale = Vector2.all(scaleFrom);
    comp.add(ScaleEffect.to(Vector2.all(scaleTo), EffectController(duration: 0.35, curve: Curves.easeOut)));
    comp.add(OpacityEffect.fadeOut(
        EffectController(duration: fadeOut, startDelay: hold + 0.35, curve: Curves.easeIn)));
    comp.add(RemoveEffect(delay: hold + 0.35 + fadeOut + 0.05));
    add(comp);
    return comp;
  }

  // ── curve builders ─────────────────────────────────────────────────────────
  List<Vector2> _bezier(Vector2 p0, Vector2 p1, Vector2 p2, Vector2 p3, {int n = 40}) {
    final out = <Vector2>[];
    for (var i = 0; i <= n; i++) {
      final t = i / n, u = 1 - t;
      out.add(p0 * (u * u * u) + p1 * (3 * u * u * t) + p2 * (3 * u * t * t) + p3 * (t * t * t));
    }
    return out;
  }

  List<Vector2> _arc(Vector2 c, double r, double aStartDeg, double aEndDeg, {int n = 60}) {
    final out = <Vector2>[];
    for (var i = 0; i <= n; i++) {
      final a = _rad(aStartDeg + (aEndDeg - aStartDeg) * i / n);
      out.add(c + Vector2(math.cos(a), -math.sin(a)) * r);
    }
    return out;
  }
}

/// Drives 0..1 over [duration] through [curve], calling [onStep] each frame and
/// [onDone] once at the end.
class _FlightRunner extends Component {
  _FlightRunner({required this.duration, required this.curve, required this.onStep, this.onDone});
  final double duration;
  final Curve curve;
  final void Function(double eased) onStep;
  final VoidCallback? onDone;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    final p = (_t / duration).clamp(0.0, 1.0);
    onStep(curve.transform(p));
    if (p >= 1) {
      onDone?.call();
      removeFromParent();
    }
  }
}

/// Real projectile integrator: position under constant gravity. [vy0] is the
/// upward launch speed (px/s), [vx] the sideways speed, [g] gravity (px/s²).
/// Calls [onStep] each frame and [onLand] once the projectile returns to
/// [groundY] after passing its apex.
class _BallisticRunner extends Component {
  _BallisticRunner({
    required this.start,
    required this.vx,
    required this.vy0,
    required this.g,
    required this.groundY,
    required this.onStep,
    required this.onLand,
  });
  final Vector2 start;
  final double vx;
  final double vy0;
  final double g;
  final double groundY;
  final void Function(Vector2 pos, double vyNow, double t) onStep;
  final void Function(Vector2 pos) onLand;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    final y = start.y - (vy0 * _t - 0.5 * g * _t * _t);
    final x = start.x + vx * _t;
    final vyNow = vy0 - g * _t;
    final pos = Vector2(x, y);
    onStep(pos, vyNow, _t);
    if (vyNow < 0 && y >= groundY) {
      onLand(Vector2(x, groundY));
      removeFromParent();
    }
  }
}

/// Continuously sweeps a component around an orbit ellipse.
class _OrbitRunner extends Component {
  _OrbitRunner({
    required this.target,
    required this.center,
    required this.radius,
    required this.speed,
    required this.startAngle,
  }) : _a = startAngle;
  final PositionComponent target;
  final Vector2 center;
  final double radius;
  final double speed;
  final double startAngle;
  double _a;

  @override
  void update(double dt) {
    _a += speed * dt;
    target.position = center + Vector2(math.cos(_a), -math.sin(_a)) * radius;
  }
}

/// Calls [action] once after [delay] seconds, then removes itself.
class _DelayedCall extends Component {
  _DelayedCall(this.delay, this.action);
  double delay;
  final void Function() action;
  @override
  void update(double dt) {
    delay -= dt;
    if (delay <= 0) {
      action();
      removeFromParent();
    }
  }
}
