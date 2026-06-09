// The Flame stage for the Power Balance Challenge.
//
// Coordinate model (same as signal_rescue): components live on the game root (no
// camera world) and the background is transparent-by-default but we paint a
// full-bleed starry sprite, so game coords == GameWidget logical pixels.
//
// Division of labour: the controller owns ALL logic + geometry; this game is a
// pure renderer + clock. Each frame it ticks the controller, lays out the scene
// from controller getters, and fires one-shot FX by DIFFING transient tokens on
// the state (capture/send/charge/thruster/warn) — it owns no gestures (every
// control is a Flutter dock button).

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart' show Curves;

import '../config/asset_paths.dart';
import '../config/power_balance_tuning.dart';
import '../models/power_balance_models.dart';
import '../state/power_balance_controller.dart';
import '../state/power_balance_state.dart';
import 'components/scene_components.dart';
import '../../../../utils/s3_assets.dart';

class PowerBalanceGame extends FlameGame {
  PowerBalanceGame({required this.controller});

  final PowerBalanceController controller;

  late final SpriteComponent _backdrop;
  late final EarthCurve _earth;
  late final SpriteComponent _sun;
  late final OrbitEllipse _orbit;
  late final SpriteComponent _cyclone;
  late final SpriteComponent _ground;
  late final SatelliteSprite _sat;
  late final SpriteComponent _chargeRing;
  late final ShadowScrim _scrim;

  bool _ready = false;
  MissionPhase? _lastPhase;
  double _pulseT = 0;

  // cached transient tokens (fire-on-change)
  int _capTok = 0, _sendTok = 0, _chargeTok = 0, _thrustTok = 0, _warnTok = 0;
  double _chargeStreamT = 0;

  @override
  Color backgroundColor() => const Color(0x00000000);

  Sprite _sprite(String p) => Sprite(images.fromCache(PB.flame(p)));

  @override
  Future<void> onLoad() async {
    await preloadFlameImagesFromS3(images, PB.preload);
    final stage = size.clone();
    controller.setStageSize(stage.x, stage.y);

    // full-bleed starry backdrop (cover)
    final bg = _sprite(PB.spaceBg);
    _backdrop = SpriteComponent(sprite: bg, anchor: Anchor.center, priority: 0)
      ..position = stage / 2
      ..size = _coverSize(bg, stage);

    _earth = EarthCurve(day: _sprite(PB.earthDay))..priority = 2;
    _sun = SpriteComponent(sprite: _sprite(PB.sun), anchor: Anchor.center, priority: 3)
      ..paint.blendMode = BlendMode.plus; // additive hides the strip's matte fringe
    _orbit = OrbitEllipse()..priority = 4;
    _cyclone = SpriteComponent(sprite: _sprite(PB.cyclone), anchor: Anchor.center, priority: 6);
    _ground = SpriteComponent(sprite: _sprite(PB.groundStation), anchor: Anchor.center, priority: 6);

    _sat = SatelliteSprite(sprites: {
      SatVisual.normal: _sprite(PB.satNormal),
      SatVisual.charging: _sprite(PB.satCharging),
      SatVisual.lowPower: _sprite(PB.satLowPower),
      SatVisual.critical: _sprite(PB.satCritical),
      SatVisual.warning: _sprite(PB.satWarning),
      SatVisual.poweredDown: _sprite(PB.satPoweredDown),
      SatVisual.success: _sprite(PB.satSuccess),
    })
      ..priority = 20;

    // charging halo behind the satellite (additive), shown only while charging
    _chargeRing = SpriteComponent(sprite: _sprite(PB.chargingGlow), anchor: Anchor.center, priority: 19)
      ..paint.blendMode = BlendMode.plus
      ..paint.color = _alpha(0);

    _scrim = ShadowScrim()
      ..priority = 24
      ..setStage(stage);

    await addAll([_backdrop, _earth, _orbit, _sun, _ground, _chargeRing, _cyclone, _sat, _scrim]);
    _ready = true;
    _lastPhase = MissionPhase.intro;
    _syncScene(controller.state); // place everything before the first frame
  }

  Vector2 _coverSize(Sprite s, Vector2 stage) {
    final ar = s.srcSize.x / s.srcSize.y;
    final stageAr = stage.x / stage.y;
    return ar > stageAr
        ? Vector2(stage.y * ar, stage.y)
        : Vector2(stage.x, stage.x / ar);
  }

  // ── per-frame sync ─────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    if (!_ready) return;
    _pulseT += dt;
    controller.tick(dt);
    final s = controller.state;
    _syncScene(s);
    _fireTokens(s);
    _handlePhaseChange(s.phase);

    // continuous solar particle stream while charging
    if (s.isCharging) {
      _chargeStreamT += dt;
      if (_chargeStreamT >= 0.5) {
        _chargeStreamT = 0;
        _spawnSolarParticle();
      }
    }
  }

  void _syncScene(PowerBalanceState s) {
    layoutSprite(_sun, controller.sunCenterPx, controller.sunWidthPx);
    _orbit.setEllipse(controller.orbitCenterPx, controller.orbitRadiusXPx, controller.orbitRadiusYPx);
    layoutSprite(_cyclone, controller.cycloneCenterPx, controller.cycloneWidthPx);
    layoutSprite(_ground, controller.groundStationCenterPx, controller.groundStationWidthPx);
    _earth.setLayout(controller.earthBottomCenterPx, controller.earthWidthPx);

    // satellite position (orbital drift from the controller) + state sprite
    _sat
      ..position = Vector2(controller.satelliteCenterPx.dx, controller.satelliteCenterPx.dy)
      ..setVisual(_visualFor(s))
      ..setWidth(controller.satelliteWidthPx);

    // charging halo: a small tight glow on the satellite, pulse while charging
    layoutSprite(_chargeRing, controller.satelliteCenterPx, controller.satelliteWidthPx * 0.92);
    _chargeRing.paint.color =
        _alpha(s.isCharging ? 0.45 + 0.22 * math.sin(_pulseT * 4.5) : 0.0);

    // fades
    _sun.paint.color = _alpha(controller.sunPresence);
    _cyclone.paint.color = _alpha(controller.cyclonePresence);
    _ground.paint.color = _alpha(controller.groundPresence * (s.currentZone == OrbitZone.groundStationRange ? 1.0 : 0.85));
    _earth.setShadow(controller.shadowFactor);
    _scrim.setFactor(controller.shadowFactor);
  }

  Color _alpha(double a) => Color.fromRGBO(255, 255, 255, a.clamp(0.0, 1.0));

  SatVisual _visualFor(PowerBalanceState s) {
    if (s.phase == MissionPhase.success) return SatVisual.success;
    if (s.phase == MissionPhase.failure) return SatVisual.poweredDown;
    if (s.isCharging) return SatVisual.charging;
    if (s.batteryPercent <= PBTune.criticalThreshold) return SatVisual.critical;
    if (controller.shadowFactor > 0.5 && s.batteryPercent <= PBTune.lowThreshold) {
      return SatVisual.warning;
    }
    if (s.batteryPercent <= PBTune.lowThreshold) return SatVisual.lowPower;
    return SatVisual.normal;
  }

  // ── transient FX by token diff ───────────────────────────────────────────
  void _fireTokens(PowerBalanceState s) {
    if (s.captureToken != _capTok) {
      _capTok = s.captureToken;
      _playCapture();
    }
    if (s.sendToken != _sendTok) {
      _sendTok = s.sendToken;
      _playSend();
    }
    if (s.chargeBurstToken != _chargeTok) {
      _chargeTok = s.chargeBurstToken;
      _spawnFx(PB.batteryChargeBurst, _satPos, controller.satelliteWidthPx * 0.9,
          hold: 0.2, fadeOut: 0.5, scaleFrom: 0.4, priority: 30);
    }
    if (s.thrusterToken != _thrustTok) {
      _thrustTok = s.thrusterToken;
      _playThruster();
    }
    if (s.warnToken != _warnTok) {
      _warnTok = s.warnToken;
      // a small red warning-triangle sign that pops ABOVE the satellite (not a
      // big halo over it). Normal blend — it's a solid sign, not a glow.
      final at = _satPos - Vector2(0, controller.satelliteWidthPx * 0.42);
      _spawnFx(PB.alertSign, at, controller.satelliteWidthPx * 0.34,
          hold: 0.5, fadeOut: 0.45, scaleFrom: 0.4, blend: BlendMode.srcOver, priority: 30);
    }
  }

  Vector2 get _satPos =>
      Vector2(controller.satelliteCenterPx.dx, controller.satelliteCenterPx.dy);

  void _playCapture() {
    final sat = _satPos;
    final cyc = Vector2(controller.cycloneCenterPx.dx, controller.cycloneCenterPx.dy);
    // target lock reticle pops on the cyclone
    _spawnFx(PB.targetLock, cyc, controller.cycloneWidthPx * 1.4,
        hold: PBTune.captureBeat, fadeOut: 0.35, scaleFrom: 1.4, scaleTo: 1.0,
        blend: BlendMode.srcOver, priority: 7);
    // scan beam from satellite down to the cyclone
    _spawnBeam(PB.cameraScanBeam, sat, cyc, width: controller.satelliteWidthPx * 0.5);
    // flash on the cyclone partway through the beat
    _spawnFx(PB.cameraFlash, cyc, controller.cycloneWidthPx * 1.8,
        hold: 0.15, fadeOut: 0.45, scaleFrom: 0.4, startDelay: PBTune.captureBeat * 0.55,
        priority: 40);
  }

  // Transmission visuals (green beam + packets + "Data Sent/Received" pills) are
  // drawn in Flutter now (TransmissionFx) — the Flame side does nothing.
  void _playSend() {}

  void _playThruster() {
    // flame just below the satellite, brief
    final p = _satPos + Vector2(0, controller.satelliteWidthPx * 0.28);
    _spawnFx(PB.thrusterFlame, p, controller.satelliteWidthPx * 0.4,
        hold: 0.18, fadeOut: 0.3, scaleFrom: 0.5, priority: 18);
  }

  void _spawnSolarParticle() {
    final from = Vector2(controller.sunCenterPx.dx, controller.sunCenterPx.dy);
    final to = _satPos;
    final s = _sprite(PB.solarParticles);
    final w = controller.satelliteWidthPx * 0.5;
    final comp = SpriteComponent(
      sprite: s,
      anchor: Anchor.center,
      position: from.clone(),
      size: Vector2(w, w * s.srcSize.y / s.srcSize.x),
      priority: 19,
    )..paint.blendMode = BlendMode.plus;
    comp.paint.color = _alpha(0.0);
    comp.add(MoveEffect.to(to, EffectController(duration: 0.9, curve: Curves.easeIn)));
    comp.add(OpacityEffect.to(1.0, EffectController(duration: 0.3)));
    comp.add(OpacityEffect.to(0.0, EffectController(duration: 0.4, startDelay: 0.5)));
    comp.add(RemoveEffect(delay: 1.0));
    add(comp);
  }

  // ── phase change one-shots ───────────────────────────────────────────────
  void _handlePhaseChange(MissionPhase phase) {
    if (phase == _lastPhase) return;
    _lastPhase = phase;
    if (phase == MissionPhase.success) _celebrate();
  }

  void _celebrate() {
    final at = _satPos - Vector2(0, controller.satelliteWidthPx * 0.55);
    _spawnFx(PB.starBurst, at, size.x * 0.7,
        hold: 0.8, fadeOut: 1.0, scaleFrom: 0.3, priority: 60);
    _spawnFx(PB.confetti, Vector2(size.x * 0.5, size.y * 0.30), size.x * 1.0,
        hold: 1.0, fadeOut: 1.2, scaleFrom: 0.5, priority: 61);
  }

  // ── effect helpers ───────────────────────────────────────────────────────
  /// Generic one-shot effect: scale-in, hold, fade-out, self-remove.
  SpriteComponent _spawnFx(
    String flamePath,
    Vector2 at,
    double width, {
    double scaleFrom = 0.7,
    double scaleTo = 1.0,
    double fadeOut = 0.4,
    double hold = 0.3,
    double startDelay = 0,
    int priority = 50,
    BlendMode blend = BlendMode.plus,
  }) {
    final s = _sprite(flamePath);
    final comp = SpriteComponent(
      sprite: s,
      anchor: Anchor.center,
      position: at.clone(),
      size: Vector2(width, width * s.srcSize.y / s.srcSize.x),
      priority: priority,
    )..paint.blendMode = blend;
    comp.scale = Vector2.all(scaleFrom);
    comp.add(ScaleEffect.to(Vector2.all(scaleTo),
        EffectController(duration: 0.35, startDelay: startDelay, curve: Curves.easeOut)));
    if (startDelay > 0) {
      comp.paint.color = _alpha(0);
      comp.add(OpacityEffect.to(1.0, EffectController(duration: 0.12, startDelay: startDelay)));
    }
    comp.add(OpacityEffect.to(0.0,
        EffectController(duration: fadeOut, startDelay: startDelay + hold + 0.35, curve: Curves.easeIn)));
    comp.add(RemoveEffect(delay: startDelay + hold + 0.35 + fadeOut + 0.05));
    add(comp);
    return comp;
  }

  /// A beam sprite stretched + rotated from [from] to [to] (anchor top-centre at
  /// the origin), used for the camera scan beam (vertical-only cone sprite).
  void _spawnBeam(String flamePath, Vector2 from, Vector2 to, {required double width}) {
    final s = _sprite(flamePath);
    final dist = (to - from).length;
    final angle = math.atan2(to.y - from.y, to.x - from.x) - math.pi / 2;
    final comp = SpriteComponent(
      sprite: s,
      anchor: Anchor.topCenter,
      position: from.clone(),
      size: Vector2(width, dist),
      angle: angle,
      priority: 8,
    )..paint.blendMode = BlendMode.plus;
    comp.paint.color = _alpha(0);
    comp.add(OpacityEffect.to(0.85, EffectController(duration: 0.2)));
    comp.add(OpacityEffect.to(0.0, EffectController(duration: 0.4, startDelay: PBTune.captureBeat * 0.6)));
    comp.add(RemoveEffect(delay: PBTune.captureBeat + 0.1));
    add(comp);
  }
}
