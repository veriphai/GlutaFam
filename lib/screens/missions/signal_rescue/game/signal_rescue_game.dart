// The Flame stage for Signal Rescue.
//
// Coordinate model (same as orbit_launcher / restore_earth): components live on
// the game root (no camera world) and the background is transparent, so game
// coords == GameWidget logical pixels and the Flutter cosmic background + chrome
// show through / layer on top.
//
// Division of labour: the controller owns logic + geometry; this game RENDERS
// from controller state each frame, drives the orbit/transmission clocks via
// `controller.tick`, detects the align-dwell graduation, spawns data packets,
// and feeds back ONLY the antenna drag (`aimAt`).

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/services.dart' show HapticFeedback;

import '../config/asset_paths.dart';
import '../config/signal_tuning.dart';
import '../state/signal_rescue_controller.dart';
import '../state/signal_rescue_state.dart';
import 'components/antenna_component.dart';
import 'components/data_packet_component.dart';
import 'components/earth_component.dart';
import 'components/gesture_catcher.dart';
import 'components/ground_station_component.dart';
import 'components/orbit_path_component.dart';
import 'components/satellite_component.dart';
import 'components/signal_beam_component.dart';
import '../../../../utils/s3_assets.dart';

class SignalRescueGame extends FlameGame {
  SignalRescueGame({required this.controller});

  final SignalRescueController controller;

  late final EarthComponent _earth;
  late final SatelliteComponent _sat;
  late final GroundStationComponent _station;
  late final SignalBeamComponent _beam;
  late final OrbitPathComponent _orbit;

  bool _ready = false;
  MissionPhase? _lastPhase;
  double _alignDwell = 0;

  // transmission clock
  double _txT = 0;
  double _lastPacketAt = 0;

  @override
  Color backgroundColor() => const Color(0x00000000);

  Sprite _sprite(String p) => Sprite(images.fromCache(SR.flame(p)));

  @override
  Future<void> onLoad() async {
    await preloadFlameImagesFromS3(images, SR.preload);
    final stage = size.clone();
    controller.setStageSize(stage.x, stage.y);

    _earth = EarthComponent(
      globe: _sprite(SR.earthBase),
      stage: stage,
    )..priority = 2;

    final antenna = AntennaComponent(
      dishSprite: _sprite(SR.antennaDish),
      mountSprite: _sprite(SR.antennaMount),
      stage: stage,
    );
    _sat = SatelliteComponent(
      bodySprite: _sprite(SR.satelliteBody),
      glowBodySprite: _sprite(SR.satelliteGlowBody),
      antenna: antenna,
      stage: stage,
    )..priority = 20;

    _station = GroundStationComponent(
      inactive: _sprite(SR.groundInactive),
      active: _sprite(SR.groundActive),
      alert: _sprite(SR.groundAlert),
      stage: stage,
    )
      ..priority = 10
      ..position = Vector2(controller.stationCenterPx.dx, controller.stationCenterPx.dy);

    _beam = SignalBeamComponent(stage: stage)..priority = 8;
    _orbit = OrbitPathComponent(stage: stage)..priority = 6;

    await add(_earth);
    await add(_orbit);
    await add(_beam);
    await add(_station);
    await add(_sat);
    add(GestureCatcher()..priority = 1000);

    _ready = true;
    _lastPhase = MissionPhase.intro;
  }

  // ── antenna aim from the in-stage drag ───────────────────────────────────────
  void aimAt(Vector2 canvasPos) {
    if (!_ready) return;
    final pivot = _sat.beamOrigin;
    final deg = math.atan2(canvasPos.y - pivot.y, canvasPos.x - pivot.x) * 180 / math.pi;
    controller.setAntennaAngle(deg);
  }

  // ── per-frame sync ───────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    if (!_ready) return;

    controller.tick(dt);
    final s = controller.state;

    // satellite + antenna
    _sat.base
      ..x = controller.satelliteCenterPx.dx
      ..y = controller.satelliteCenterPx.dy;
    // tell the controller the dish's real world pivot so aim == drawn dish
    controller.setAntennaPivot(_sat.beamOrigin.x, _sat.beamOrigin.y);
    (_sat.antenna).setAimAngleDeg(s.antennaAngle);
    _sat.antenna.showGuide(s.phase == MissionPhase.alignAntenna);

    // beam
    _beam.start.setFrom(_sat.beamOrigin);
    _beam.end
      ..x = controller.stationAimPx.dx
      ..y = controller.stationAimPx.dy;
    _beam.setState(s.signalState);
    _beam.setVisible(true); // shown from the start — the wrong-aim red beam IS the problem reveal

    // station visual + range
    _station.setInRange(s.isGroundStationInRange);
    _station.setVisual(_stationVisualFor(s));

    // orbit path visibility (range hunt → lock)
    _orbit.setVisible(s.phase == MissionPhase.waitForRange ||
        s.phase == MissionPhase.checkPower ||
        s.phase == MissionPhase.dataLocked);

    // align-dwell graduation
    if (s.phase == MissionPhase.alignAntenna) {
      if (s.angleDifference <= SRTune.alignAdvanceDiff) {
        _alignDwell += dt;
        if (_alignDwell >= SRTune.alignDwell) controller.onAlignDwellComplete();
      } else {
        _alignDwell = math.max(0, _alignDwell - dt * 2);
      }
    }

    _handlePhaseChange(s.phase);

    // drive transmission
    if (s.phase == MissionPhase.transmitting) _tickTransmission(dt);
  }

  StationVisual _stationVisualFor(SignalRescueState s) {
    if (s.phase == MissionPhase.transmitting || s.phase == MissionPhase.success) {
      return StationVisual.active;
    }
    if (s.isGroundStationInRange || s.signalState == SignalState.strong || s.signalState == SignalState.locked) {
      return StationVisual.active;
    }
    if (s.phase == MissionPhase.waitForRange && s.signalState == SignalState.noSignal) {
      return StationVisual.alert;
    }
    return StationVisual.inactive;
  }

  void _handlePhaseChange(MissionPhase phase) {
    if (phase == _lastPhase) return;
    _lastPhase = phase;
    switch (phase) {
      case MissionPhase.transmitting:
        _txT = 0;
        _lastPacketAt = -SRTune.packetInterval;
        _sat.setTransmitting(true);
        HapticFeedback.selectionClick();
        _spawnEffect(SR.beamPortal,
            Vector2(controller.stationCenterPx.dx, controller.stationCenterPx.dy - size.y * 0.01),
            size.x * 0.30,
            hold: SRTune.transmitDuration, fadeOut: 0.6, priority: 7);
      case MissionPhase.dataLocked:
        _spawnEffect(SR.lockRing, _sat.beamOrigin, size.x * 0.26,
            hold: 0.3, fadeOut: 0.6, scaleFrom: 0.5, priority: 30);
        HapticFeedback.lightImpact();
      case MissionPhase.success:
        _sat.setTransmitting(false);
        _celebrate();
        HapticFeedback.mediumImpact();
      default:
        break;
    }
  }

  void _tickTransmission(double dt) {
    _txT += dt;
    final progress = (_txT / SRTune.transmitDuration).clamp(0.0, 1.0);
    if (progress < 1.0 && _txT - _lastPacketAt >= SRTune.packetInterval) {
      _lastPacketAt = _txT;
      _spawnPacket();
    }
    controller.updateTransmission(progress);
  }

  void _spawnPacket() {
    final start = _sat.beamOrigin.clone();
    final end = Vector2(controller.stationAimPx.dx, controller.stationAimPx.dy);
    add(DataPacketComponent(
      packetSprite: _sprite(SR.dataPacket),
      trailSprite: _sprite(SR.packetTrail),
      start: start,
      end: end,
      duration: 0.9,
      diameter: size.x * 0.07,
      onArrive: (at) {
        _spawnEffect(SR.packetSplash, at, size.x * 0.18,
            hold: 0.1, fadeOut: 0.4, scaleFrom: 0.5, priority: 62);
      },
    ));
  }

  void _celebrate() {
    final at = Vector2(size.x * 0.5, size.y * 0.20);
    _spawnEffect(SR.successBurst, at, size.x * 0.7,
        hold: 0.7, fadeOut: 1.0, scaleFrom: 0.4, priority: 70);
    for (var i = 0; i < 5; i++) {
      _spawnEffect(SR.sparkle,
          Vector2(size.x * (0.3 + 0.1 * i), size.y * (0.16 + 0.02 * (i % 2))),
          size.x * 0.12,
          hold: 0.4 + 0.1 * i, fadeOut: 0.6, scaleFrom: 0.4, priority: 71);
    }
  }

  // generic additive effect spawner (mirrors orbit_launcher's helper)
  SpriteComponent _spawnEffect(
    String flamePath,
    Vector2 at,
    double width, {
    double scaleFrom = 0.7,
    double scaleTo = 1.0,
    double fadeOut = 0.4,
    double hold = 0.3,
    int priority = 80,
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
}
