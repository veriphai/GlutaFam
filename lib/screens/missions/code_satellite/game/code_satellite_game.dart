// The Flame mission stage for Code the Satellite.
//
// Coordinate model (same as signal_rescue / orbit_launcher): components live on
// the game root (no camera world) and backgroundColor is transparent, so game
// coords == GameWidget logical pixels and the Flutter cosmic background + chrome
// layer behind/in front. The satellite + props occupy the UPPER region of the
// stage; the lower region stays transparent for the Flutter timeline + tray.
//
// This game is a COMMAND-DRIVEN renderer: it owns no gestures. The controller
// pushes playCommand/showFailure/showSuccess imperatively (via MissionStage) and
// awaits the returned Future, which completes when each animation beat finishes.
//
// Per-command animations transcribe PRD §10 literally — each command swaps the
// canonical satellite state sprite, fades in the relevant prop, and spawns the
// named additive effect(s).

import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/painting.dart' show BlendMode, Color;
import 'package:flutter/services.dart' show HapticFeedback;

import '../config/asset_paths.dart';
import '../config/code_satellite_tuning.dart';
import '../models/satellite_command.dart';
import '../state/code_satellite_controller.dart';
import 'components/stage_components.dart';
import '../../../../utils/s3_assets.dart';

class CodeSatelliteGame extends FlameGame implements MissionStage {
  CodeSatelliteGame();

  late SatelliteActor _sat;
  late PropActor _sun;
  late PropActor _earth;
  late PropActor _station;
  late PropActor _chip;
  CameraScan? _camScan;
  LinkBeam? _link;

  final Completer<void> _readyCompleter = Completer<void>();
  Future<void> get stageReady => _readyCompleter.future;
  bool _ready = false;

  @override
  Color backgroundColor() => const Color(0x00000000);

  Sprite _sprite(String flamePath) => Sprite(images.fromCache(flamePath));
  Sprite _state(String p) => _sprite(p); // p already flame-prefixed in command meta

  @override
  Future<void> onLoad() async {
    await preloadFlameImagesFromS3(images, CS.preload);
    final stage = size.clone();

    _sun = PropActor(
      sprite: _sprite(CS.flame(CS.sun)),
      stageSize: stage,
      centerFactor: CSStage.sunCenter,
      widthFactor: CSStage.sunWidth,
    )..priority = 5;
    _earth = PropActor(
      sprite: _sprite(CS.flame(CS.earthCyclone)),
      stageSize: stage,
      centerFactor: CSStage.earthCenter,
      widthFactor: CSStage.earthWidth,
    )..priority = 5;
    _station = PropActor(
      sprite: _sprite(CS.flame(CS.groundStation)),
      stageSize: stage,
      centerFactor: CSStage.stationCenter,
      widthFactor: CSStage.stationWidth,
    )..priority = 5;
    _chip = PropActor(
      sprite: _sprite(CS.flame(CS.dataStorageChip)),
      stageSize: stage,
      centerFactor: CSStage.chipCenter,
      widthFactor: CSStage.chipWidth,
    )..priority = 6;

    _sat = SatelliteActor(
      idle: _sprite(CS.flame(CS.satIdle)),
      stageSize: stage,
      centerFactor: CSStage.satelliteCenter,
      compactCenterFactor: CSStage.satelliteCompactCenter,
      widthFactor: CSStage.satelliteWidth,
      bobAmplitudeFactor: CSStage.idleBobAmplitude,
      bobPeriod: CSStage.idleBobPeriod,
    )..priority = 20;

    await addAll([_sun, _earth, _station, _chip, _sat]);

    _ready = true;
    if (!_readyCompleter.isCompleted) _readyCompleter.complete();
  }

  // ── MissionStage: stage lifecycle ───────────────────────────────────────────
  @override
  void enterStage() {
    if (!_ready) return;
    _sat.setStateSprite(_state(CS.flame(CS.satIdle)), pop: false);
    _sat.setCompact(false); // full size while building
    _sat.fadeIn();
    _hideAllProps();
  }

  @override
  void resetToIdle() {
    if (!_ready) return;
    _sat.setStateSprite(_state(CS.flame(CS.satIdle)), pop: false);
    _sat.setCompact(false);
    _sat.fadeTo(1);
    _hideAllProps();
  }

  @override
  void setCompact(bool compact) {
    if (_ready) _sat.setCompact(compact);
  }

  void _hideAllProps() {
    for (final p in [_sun, _earth, _station, _chip]) {
      p.hide(duration: 0.2);
    }
    _removeCamScan();
    _removeLink();
  }

  void _addLink() {
    if (_link != null) return;
    final link = LinkBeam(satellite: _sat, station: _station.center.clone())..priority = 11;
    _link = link;
    add(link);
  }

  void _removeLink() {
    _link?.beginExit();
    _link = null;
  }

  void _addCamScan() {
    if (_camScan != null) return;
    final scan = CameraScan(
      satellite: _sat,
      earth: _earth,
      originOffsetFactor: CSStage.cameraOffset,
      targetOffsetFactor: CSStage.cycloneOffset,
    )..priority = 12;
    _camScan = scan;
    add(scan);
  }

  void _removeCamScan() {
    _camScan?.beginExit();
    _camScan = null;
  }

  // ── MissionStage: per-command animation (PRD §10) ───────────────────────────
  @override
  Future<void> playCommand(SatelliteCommand command, {required bool capturesImage}) async {
    if (!_ready) await stageReady;
    final at = _sat.position.clone();

    switch (command) {
      case SatelliteCommand.wakeUp:
        _sat.setStateSprite(_state(command.flameStateAsset));
        _spawnEffect(CS.flame(CS.fxPulseRing), at, size.x * 0.42,
            scaleFrom: 0.5, hold: 0.25, fadeOut: 0.6);
        HapticFeedback.lightImpact();

      case SatelliteCommand.checkBattery:
        _sat.setStateSprite(_state(command.flameStateAsset));
        _spawnEffect(CS.flame(CS.fxBatteryRing), at, size.x * 0.40,
            scaleFrom: 0.7, hold: 0.4, fadeOut: 0.5);

      case SatelliteCommand.pointSolarPanelToSun:
        _sat.setCompact(true); // smooth premium zoom-out FIRST (sprite unchanged)
        // Only once it's zoomed out + parked: bring the Sun in, turn the panels
        // gold, and flow energy.
        await Future<void>.delayed(const Duration(milliseconds: 850));
        _sun.show();
        _sat.setStateSprite(_state(command.flameStateAsset)); // panels → Sun now
        final solarTarget = _sat.position.clone();
        for (var i = 0; i < 3; i++) {
          _spawnTravelDelayed(CS.flame(CS.fxSolarParticles), _sun.center, solarTarget,
              size.x * 0.12, 0.7, delay: i * 0.18);
        }

      case SatelliteCommand.pointCameraToEarth:
        _earth.show();
        _station.show(); // the ground station is already there when Earth appears
        // Keep the satellite beam-less here (its camera-aimed sprite has a baked
        // beam) — the programmatic Flutter-style cone + reticle IS the beam.
        _sat.setStateSprite(_state(CS.flame(CS.satIdle)));
        _addCamScan();

      case SatelliteCommand.takePicture:
        _sat.setStateSprite(_state(command.flameStateAsset));
        _addCamScan(); // ensure the cone is up if replaying this step directly
        _spawnEffect(CS.flame(CS.fxCameraFlash), at, size.x * 0.46,
            scaleFrom: 0.4, hold: 0.12, fadeOut: 0.4);
        HapticFeedback.mediumImpact();

      case SatelliteCommand.storeData:
        _removeCamScan();
        _sat.setStateSprite(_state(command.flameStateAsset));
        // No external storage device — the data is absorbed INTO the satellite:
        // a couple of data packets converge into its body + a soft pulse.
        _spawnEffect(CS.flame(CS.fxPulseRing), at, size.x * 0.34,
            scaleFrom: 0.5, hold: 0.25, fadeOut: 0.5);
        for (var i = 0; i < 2; i++) {
          final from = at + Vector2((i.isEven ? 1 : -1) * size.x * 0.16, -size.y * 0.06);
          _spawnTravelDelayed(CS.flame(CS.fxPacketTrail), from, at, size.x * 0.10, 0.5,
              delay: i * 0.15);
        }

      case SatelliteCommand.pointAntennaToGroundStation:
        // Station is already on Earth — just AIM + connect: a dashed uplink
        // line draws in, then turns green ("connected").
        _sat.setStateSprite(_state(command.flameStateAsset));
        _addLink();
        _spawnEffect(CS.flame(CS.fxPulseRing), _station.center, size.x * 0.24,
            scaleFrom: 0.5, hold: 0.25, fadeOut: 0.5);
        await Future<void>.delayed(const Duration(milliseconds: 600));
        _link?.connect(); // line turns green
        HapticFeedback.lightImpact();

      case SatelliteCommand.sendData:
        _sat.setStateSprite(_state(command.flameStateAsset));
        _addLink(); // ensure the (green) link is up if replaying this step
        _link?.connect();
        _spawnEffect(CS.flame(CS.fxSignalWaves), at, size.x * 0.32,
            scaleFrom: 0.6, hold: 0.4, fadeOut: 0.5);
        for (var i = 0; i < 3; i++) {
          _spawnTravelDelayed(CS.flame(CS.fxPacketTrail), at, _station.center,
              size.x * 0.12, 0.7, delay: i * 0.2);
        }
        HapticFeedback.mediumImpact();

      case SatelliteCommand.enterSafeMode:
        _sat.setStateSprite(_state(command.flameStateAsset));
        _removeLink(); // disconnect the uplink as the satellite rests
        _spawnEffect(CS.flame(CS.fxSafeShield), at, size.x * 0.50,
            scaleFrom: 0.7, hold: 0.6, fadeOut: 0.6);
        // fade the visible props slightly as the satellite rests.
        for (final p in [_sun, _earth, _station]) {
          p.show(target: 0.35, duration: 0.4);
        }
    }

    await Future<void>.delayed(
        Duration(milliseconds: (CSTiming.commandBeat * 1000).round()));
  }

  // ── MissionStage: failure ───────────────────────────────────────────────────
  @override
  Future<void> showFailure(SatelliteCommand command, {required bool serious}) async {
    if (!_ready) await stageReady;
    final at = _sat.position.clone();
    if (serious) _sat.setStateSprite(_state(CS.flame(CS.satError)));
    _spawnEffect(CS.flame(CS.fxErrorFlash), at, size.x * 0.52,
        scaleFrom: 0.6, hold: 0.4, fadeOut: 0.5);
    HapticFeedback.heavyImpact();
    await Future<void>.delayed(
        Duration(milliseconds: (CSTiming.failureBeat * 1000).round()));
  }

  // ── MissionStage: success (PRD §12) ─────────────────────────────────────────
  @override
  Future<void> showSuccess() async {
    if (!_ready) await stageReady;
    _removeCamScan();
    _removeLink();
    final at = _sat.position.clone();
    _sat.setStateSprite(_state(CS.flame(CS.satSuccess)));
    _station.show();

    // green data stream to the ground station.
    for (var i = 0; i < 4; i++) {
      _spawnTravelDelayed(CS.flame(CS.fxPacketTrail), at, _station.center,
          size.x * 0.12, 0.7, delay: i * 0.16);
    }
    // No extra burst — the success sprite already carries its own glow +
    // sparkle ring, and the green packet stream sells the win.
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(
        Duration(milliseconds: (CSTiming.successBeat * 1000).round()));
  }

  // ── effect helpers ──────────────────────────────────────────────────────────

  /// Static additive burst that scales in, holds, fades out, then removes.
  SpriteComponent _spawnEffect(
    String flamePath,
    Vector2 at,
    double width, {
    double scaleFrom = 0.7,
    double scaleTo = 1.0,
    double fadeOut = 0.4,
    double hold = 0.3,
    int priority = 40,
  }) {
    final s = _sprite(flamePath);
    final comp = SpriteComponent(
      sprite: s,
      anchor: Anchor.center,
      position: at.clone(),
      size: Vector2(width, width * (s.srcSize.y / s.srcSize.x)),
      priority: priority,
    )..paint.blendMode = BlendMode.plus;
    comp.scale = Vector2.all(scaleFrom);
    comp.add(ScaleEffect.to(Vector2.all(scaleTo),
        EffectController(duration: 0.35, curve: Curves.easeOut)));
    comp.add(OpacityEffect.fadeOut(
        EffectController(duration: fadeOut, startDelay: hold + 0.35, curve: Curves.easeIn)));
    comp.add(RemoveEffect(delay: hold + 0.35 + fadeOut + 0.05));
    add(comp);
    return comp;
  }

  void _spawnTravel(String flamePath, Vector2 from, Vector2 to, double diameter, double duration) {
    add(TravelingSprite(
      sprite: _sprite(flamePath),
      from: from,
      to: to,
      diameter: diameter,
      travelDuration: duration,
    )..priority = 45);
  }

  void _spawnTravelDelayed(
      String flamePath, Vector2 from, Vector2 to, double diameter, double duration,
      {required double delay}) {
    add(TimerComponent(
      period: delay <= 0 ? 0.001 : delay,
      removeOnFinish: true,
      onTick: () => _spawnTravel(flamePath, from, to, diameter, duration),
    ));
  }
}
