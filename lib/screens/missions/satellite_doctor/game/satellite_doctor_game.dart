// The Flame stage for Satellite Doctor.
//
// Responsibilities (PRD §13 Flame side): ASSEMBLE the satellite from separate
// part renders (body cube + antenna on top + a solar panel each side + thruster
// below — the kit has no full hero, see styleboard), show the active mission's
// FAULT visual at the right part, run the scanner during inspect, react live to
// the child's repair, and play the per-mission RESTORE beat (signal waves turn
// green, solar particles flow, thruster burns, orbit path goes stable, hinge
// deploys, heat fades) + a green success pulse.
//
// It owns NO mission logic — the controller drives it through the SatelliteStage
// interface (controller → game, one-directional, attached in the shell).
//
// Animation rule (playbook): each field is owned by ONE driver. We drive
// transforms from update() with lerped targets — no Flame Effects on the same
// fields — so nothing fights.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:http/http.dart' as http;

import '../config/asset_paths.dart';
import '../config/sd_tuning.dart';
import '../models/satellite_doctor_mission.dart';
import '../state/satellite_stage.dart';

class SatelliteDoctorGame extends FlameGame implements SatelliteStage {
  final Map<String, Sprite> _cache = {};
  bool _ready = false;
  @override
  bool get stageReady => _ready;

  late Vector2 _stage;
  SpriteComponent? _earth;

  // the assembled satellite rig + its parts (so each can animate independently)
  late PositionComponent _sat;
  SpriteComponent? _body, _antenna, _solarL, _solarR;

  final List<_Fx> _faults = []; // active fault overlays
  final List<Component> _scanner = []; // scanner ring/brackets
  final List<Component> _props = []; // sun / orbit path / debris / etc
  final List<Component> _restoreFx = []; // finishRepair glows/pulses (cleared next mission)

  double _idle = 0;

  // lerped reaction state
  double _satAngle = 0, _satAngleTarget = 0;
  double _satDx = 0, _satDxTarget = 0;
  double _antennaAngle = 0, _antennaAngleTarget = 0;
  double _panelAngle = 0, _panelAngleTarget = 0;

  @override
  Color backgroundColor() => const Color(0x00000000);

  static final List<String> _preload = [
    // core parts
    SD.body, SD.antennaDish, SD.solarLeft, SD.solarRight, SD.thrusterModule,
    SD.solarStuckHalf, SD.solarDeploying,
    // environment
    SD.envEarthHorizon, SD.envSunOrb,
    // fault overlays
    SD.overheatHeatGlow, SD.overheatSmoke, SD.overheatWarningIcon,
    SD.antennaWarningArc,
    SD.cameraStaticOverlay, SD.cameraOfflineRedMarker, SD.cameraScanReboot,
    SD.orbitPathStable,
    SD.debrisMedium, SD.debrisSmall1, SD.debrisSmall3,
    SD.hingeJammed,
    // good-state fx
    SD.fxSignalWaveGreen, SD.fxSignalWaveBlue, SD.fxSolarParticles, SD.fxChargingGlow,
    SD.thrusterSmallBurn, SD.fxThrusterTrail, SD.thermalCoolingGlow, SD.solarRestoredGlow,
    // success (scanner reticle is drawn in-canvas, no sprite needed)
    SD.fxGreenCheck, SD.fxSuccessBurst, SD.fxSmallSparkle,
  ];

  @override
  Future<void> onLoad() async {
    _stage = size.clone();
    // All sprites live on S3 (see SD.s3). Fan out the fetches in parallel
    // so total wall-clock is bound by the slowest download, not the sum —
    // ~30 small PNGs over a warm 4G link is sub-second this way.
    await Future.wait(_preload.map((p) async {
      try {
        final response = await http.get(Uri.parse(SD.s3(p)));
        if (response.statusCode != 200) return;
        final codec = await instantiateImageCodec(response.bodyBytes);
        final frame = await codec.getNextFrame();
        _cache[p] = Sprite(frame.image);
      } catch (_) {
        // Tolerate a single missing/failed asset rather than crash the stage.
      }
    }));
    _buildEnvironment();
    _buildSatellite();
    _ready = true;
  }

  Sprite? _spr(String p) => _cache[p];

  // ── assembly ────────────────────────────────────────────────────────────────
  void _buildEnvironment() {
    final earth = _spr(SD.envEarthHorizon);
    if (earth != null) {
      final w = _stage.x * SDTune.earthWidthFactor;
      _earth = SpriteComponent(
        sprite: earth,
        anchor: Anchor.center,
        size: Vector2(w, w * earth.srcSize.y / earth.srcSize.x),
        position: Vector2(_stage.x * 0.5, _stage.y * SDTune.earthCenterY),
        priority: -20,
      );
      add(_earth!);
    }
  }

  /// A child sprite of the rig, sized by width-factor-of-stage, centred at an
  /// offset (in stage-width units) from the rig centre.
  SpriteComponent? _part(String path, double widthFactor, double dx, double dy,
      {int priority = 0}) {
    final s = _spr(path);
    if (s == null) return null;
    final w = _stage.x * widthFactor;
    final c = SpriteComponent(
      sprite: s,
      anchor: Anchor.center,
      size: Vector2(w, w * s.srcSize.y / s.srcSize.x),
      position: _sat.size / 2 + Vector2(dx * _stage.x, dy * _stage.x),
      priority: priority,
    );
    _sat.add(c);
    return c;
  }

  void _buildSatellite() {
    _sat = PositionComponent(
      anchor: Anchor.center,
      size: Vector2(_stage.x, _stage.x),
      position: Vector2(_stage.x * SDTune.satCenterX, _stage.y * SDTune.satCenterY),
    );
    add(_sat);
    // back-to-front: panels + antenna + thruster behind, body on top
    _solarL = _part(SD.solarLeft, SDTune.panelWidthFactor, -SDTune.panelOffsetX,
        SDTune.panelOffsetY, priority: 1);
    _solarR = _part(SD.solarRight, SDTune.panelWidthFactor, SDTune.panelOffsetX,
        SDTune.panelOffsetY, priority: 1);
    _antenna = _part(SD.antennaDish, SDTune.antennaWidthFactor, SDTune.antennaOffsetX,
        SDTune.antennaOffsetY, priority: 2);
    _part(SD.thrusterModule, SDTune.thrusterWidthFactor,
        SDTune.thrusterOffsetX, SDTune.thrusterOffsetY, priority: 2); // visible part
    _body = _part(SD.body, SDTune.bodyWidthFactor, 0, 0, priority: 5);
  }

  double get _bodyW => _body?.size.x ?? _stage.x * SDTune.bodyWidthFactor;

  /// Local position of a part's centre inside the rig (rig-local coords).
  Vector2 _partCenter(SpriteComponent? part) =>
      part?.position.clone() ?? _sat.size / 2;

  // ── fault overlay helpers ────────────────────────────────────────────────────
  void _addFaultAt(String path, Vector2 localPos, double widthFactorOfBody,
      {bool additive = false, bool pulse = false, int priority = 8}) {
    final s = _spr(path);
    if (s == null) return;
    final w = _bodyW * widthFactorOfBody;
    final ov = _Fx(
      sprite: s,
      anchor: Anchor.center,
      size: Vector2(w, w * s.srcSize.y / s.srcSize.x),
      position: localPos,
      pulse: pulse,
    )..priority = priority;
    if (additive) ov.paint.blendMode = BlendMode.plus;
    _faults.add(ov);
    _sat.add(ov);
  }

  void _addProp(String path, double cx, double cy, double widthFactor,
      {bool additive = false, int priority = 0}) {
    final s = _spr(path);
    if (s == null) return;
    final w = _stage.x * widthFactor;
    final p = SpriteComponent(
      sprite: s,
      anchor: Anchor.center,
      size: Vector2(w, w * s.srcSize.y / s.srcSize.x),
      position: Vector2(_stage.x * cx, _stage.y * cy),
      priority: priority,
    );
    if (additive) p.paint.blendMode = BlendMode.plus;
    _props.add(p);
    add(p);
  }

  void _clear(List<Component> list) {
    for (final c in list) {
      c.removeFromParent();
    }
    list.clear();
  }

  // Sun is circle-masked (no ragged corona) → render with NORMAL alpha, not
  // additive, so it doesn't blow out into a poor halo on the dark sky.
  void _addSun() => _addProp(SD.envSunOrb, SDTune.sunCenterX, SDTune.sunCenterY,
      SDTune.sunWidthFactor,
      priority: -8);

  Vector2 get _batteryPos =>
      _partCenter(_body) + Vector2(SDTune.batteryDx * _bodyW, SDTune.batteryDy * _bodyW);
  Vector2 get _cameraPos =>
      _partCenter(_body) + Vector2(SDTune.cameraDx * _bodyW, SDTune.cameraDy * _bodyW);

  // ── SatelliteStage ──────────────────────────────────────────────────────────
  @override
  void loadMission(int index, SatelliteFaultType fault) {
    if (!_ready) return;
    _satAngle = _satAngleTarget = 0;
    _satDx = _satDxTarget = 0;
    _antennaAngle = _antennaAngleTarget = 0;
    _panelAngle = _panelAngleTarget = 0;
    _antenna?.angle = 0;
    _solarL?.angle = 0;
    _solarR?.angle = 0;
    _clear(_faults);
    _clear(_scanner);
    _clear(_props);
    _clear(_restoreFx);
    // restore the stuck panel back to a normal right panel by default
    _restoreSolarRightSprite();
    _dimPanels(0); // clear any leftover dimming

    switch (fault) {
      case SatelliteFaultType.batteryOverheating:
        _addSun();
        // smaller, tighter heat glow on the battery (was 1.4× — too big a cloud)
        _addFaultAt(SD.overheatHeatGlow, _batteryPos, 0.8, additive: true, pulse: true, priority: 6);
        _addFaultAt(SD.overheatSmoke, _batteryPos + Vector2(0, -_bodyW * 0.22), 0.6,
            additive: true, priority: 7);
        _addFaultAt(SD.overheatWarningIcon, _batteryPos, 0.5, pulse: true, priority: 9);
      case SatelliteFaultType.signalLost:
        // just the clean orange warning arc on the dish (dropped the messy
        // broken-waves swirl AND the Earth-✗ badge — both read as clutter)
        _addFaultAt(SD.antennaWarningArc, _partCenter(_antenna), 1.0, pulse: true, priority: 9);
      case SatelliteFaultType.cameraOffline:
        _addFaultAt(SD.cameraStaticOverlay, _cameraPos, 0.55, additive: true, pulse: true);
        _addFaultAt(SD.cameraOfflineRedMarker, _cameraPos, 0.4, pulse: true, priority: 9);
      case SatelliteFaultType.solarPanelNotCharging:
        _addSun();
        // darken the actual panels (no overlay sprite, no curved-arrow prop)
        _dimPanels(1);
      case SatelliteFaultType.orbitDrifting:
        // drifting-path sprite removed (read as a poor red arrow) — the ORBIT
        // status chip conveys the fault; repair still shows the stable path.
        break;
      case SatelliteFaultType.spaceDebrisNearby:
        // no red path / no HUD alert marker — a small cluster of debris drifts
        // in together from the top-left toward the satellite, each tagged with a
        // crisp warning triangle (drawn in-canvas, no halo).
        final aim = Vector2(_stage.x * 0.5, _stage.y * SDTune.satCenterY);
        final cluster = [
          (SD.debrisMedium, const Offset(-0.30, -0.34), 0.17),
          (SD.debrisSmall1, const Offset(-0.46, -0.20), 0.11),
          (SD.debrisSmall3, const Offset(-0.20, -0.50), 0.10),
        ];
        for (var i = 0; i < cluster.length; i++) {
          final (asset, off, wf) = cluster[i];
          final d = _DebrisRunner(
            sprite: _spr(asset),
            start: Vector2(aim.x + _stage.x * off.dx * 2.0, aim.y + _stage.x * off.dy * 2.0),
            // each settles a little short of the satellite, fanned out
            target: aim + Vector2(_stage.x * off.dx * 0.6, _stage.x * off.dy * 0.6),
            diameter: _stage.x * wf,
            phase: i * 0.45,
          )..priority = 6;
          _props.add(d);
          add(d);
          final tri = _WarningGlyph(size: _stage.x * wf * 0.66)..priority = 7;
          _props.add(tri);
          add(tri);
          d.attachTag(tri);
        }
      case SatelliteFaultType.solarPanelStuck:
        // just swap to the half-open panel sprite — no arrow hint, no glow halo
        // (the half-open panel + SOLAR status chip convey the fault).
        _setSolarRightSprite(SD.solarStuckHalf);
    }
  }

  void _setSolarRightSprite(String path) {
    final s = _spr(path);
    if (s != null && _solarR != null) {
      _solarR!.sprite = s;
      final w = _stage.x * SDTune.panelWidthFactor;
      _solarR!.size = Vector2(w, w * s.srcSize.y / s.srcSize.x);
    }
  }

  void _restoreSolarRightSprite() => _setSolarRightSprite(SD.solarRight);

  /// Darken the solar panels by [amount] 0..1 (0 = full colour/healthy,
  /// 1 = darkest "not charging") via a black src-atop colour filter on the
  /// sprite paint — no overlay sprite needed.
  void _dimPanels(double amount) {
    final a = amount.clamp(0.0, 1.0);
    final filter = a <= 0.001
        ? null
        : ColorFilter.mode(
            const Color(0xFF0A1018).withValues(alpha: 0.62 * a), BlendMode.srcATop);
    _solarL?.paint.colorFilter = filter;
    _solarR?.paint.colorFilter = filter;
  }


  @override
  void enterInspect(SatelliteFaultType fault) {
    if (!_ready) return;
    // Programmatic reticle (NOT the AI scanner sprite, which is an opaque white
    // blob that hides the part). Drawn in-canvas: corner brackets + concentric
    // rings + rotating sweep + translucent centre so the part shows through.
    // Parented to the rig so it tracks the satellite's idle bob/sway.
    final local = _faultLocalPos(fault);
    final reticle = _ScannerReticle(diameter: _bodyW * 1.45)
      ..position = local
      ..anchor = Anchor.center
      ..priority = 30;
    _scanner.add(reticle);
    _sat.add(reticle);
  }

  @override
  void exitInspect() => _clear(_scanner);

  @override
  void beginApply(RepairInteraction kind) {
    if (!_ready) return;
    _clear(_scanner);
  }

  @override
  void updateApply(RepairInteraction kind, double progress) {
    final t = progress.clamp(0.0, 1.0);
    switch (kind) {
      case RepairInteraction.rotateAwayFromSun:
        _satAngleTarget = -SDTune.rotateAwayMaxDeg * t * math.pi / 180;
        _fadeFaults(1 - t);
      case RepairInteraction.alignAntenna:
        _antennaAngleTarget = -SDTune.antennaTurnMaxDeg * t * math.pi / 180;
        _fadeFaults(1 - t);
      case RepairInteraction.pointPanelsToSun:
        _panelAngleTarget = SDTune.panelTurnMaxDeg * t * math.pi / 180;
        _dimPanels(1 - t); // panels brighten back to full colour as they aim at the Sun
        _fadeFaults(1 - t);
      case RepairInteraction.dodgeDebris:
        _satDxTarget = SDTune.dodgeShiftFactor * _stage.x * t;
      case RepairInteraction.holdRestart:
      case RepairInteraction.thrusterBurn:
      case RepairInteraction.deployPanel:
        _fadeFaults(1 - 0.6 * t);
    }
  }

  void _fadeFaults(double target) {
    final t = target.clamp(0.0, 1.0);
    for (final f in _faults) {
      f.targetOpacity = t;
    }
  }

  @override
  void finishRepair(SatelliteFaultType fault) {
    if (!_ready) return;
    _fadeFaults(0);
    _clear(_props);

    // Restore beats are kept MINIMAL + TRANSIENT: only clean overlay FX or
    // off-body props (never the kit's full-module "restored" renders, which
    // are whole satellites and just blob over the body). Each fades itself out.
    switch (fault) {
      case SatelliteFaultType.batteryOverheating:
        // fault heat simply fades — the green check is the celebration
        break;
      case SatelliteFaultType.signalLost:
        // clean green signal waves above the antenna (overlay sprite)
        _addRigFx(SD.fxSignalWaveGreen, _partCenter(_antenna) + Vector2(0, -_bodyW * 0.2), 1.1);
      case SatelliteFaultType.cameraOffline:
        // reboot scan-line sweeps the lens once, then removes itself
        final scan = _ScanLine(
          sprite: _spr(SD.cameraScanReboot),
          anchor: Anchor.center,
          size: Vector2(_bodyW * 0.6, _bodyW * 0.6),
          position: _cameraPos,
        )..priority = 12;
        _restoreFx.add(scan);
        _sat.add(scan);
      case SatelliteFaultType.solarPanelNotCharging:
        // panels simply return to their normal healthy colour — no overlay,
        // no tint, no motes. The green check is the celebration.
        _dimPanels(0);
      case SatelliteFaultType.orbitDrifting:
        // the stable orbit path is an off-body prop (drawn below the satellite)
        _addProp(SD.orbitPathStable, 0.5, 0.72, 0.92, additive: true, priority: -5);
      case SatelliteFaultType.spaceDebrisNearby:
        // satellite already shifted to the safe lane; nothing extra
        break;
      case SatelliteFaultType.solarPanelStuck:
        _setSolarRightSprite(SD.solarRight); // panel swaps to fully deployed
    }

    // A crisp green check-mark badge that pops in, holds briefly, then fades —
    // the single, clean success celebration.
    final badge = _spr(SD.fxGreenCheck);
    if (badge != null) {
      final w = _bodyW * 0.72;
      final check = _CheckBadge(
        sprite: badge,
        anchor: Anchor.center,
        size: Vector2(w, w * badge.srcSize.y / badge.srcSize.x),
        position: _partCenter(_body),
      )..priority = 20;
      _restoreFx.add(check);
      _sat.add(check);
    }
  }

  /// A transient restore-beat FX: fades in, holds, then fades out + removes
  /// itself after ~[life] seconds, so nothing lingers as a blob over the body.
  void _addRigFx(String path, Vector2 localPos, double widthFactorOfBody,
      {double life = 1.8}) {
    final s = _spr(path);
    if (s == null) return;
    final w = _bodyW * widthFactorOfBody;
    final fx = _Fx(
      sprite: s,
      anchor: Anchor.center,
      size: Vector2(w, w * s.srcSize.y / s.srcSize.x),
      position: localPos,
      fadeIn: true,
      life: life,
    )
      ..priority = 11
      ..paint.blendMode = BlendMode.plus;
    _restoreFx.add(fx); // tracked → cleared when the next mission loads
    _sat.add(fx);
  }

  @override
  void celebrateFinal() {
    if (!_ready) return;
    // No giant burst sprite (it read as an ugly halo). The final screen shows a
    // proper completion card; the stage just settles to a calm healthy satellite.
    _clear(_faults);
    _clear(_props);
    _clear(_restoreFx);
    _satAngleTarget = 0;
    _satDxTarget = 0;
    _antennaAngleTarget = 0;
    _panelAngleTarget = 0;
  }

  // ── helpers ──────────────────────────────────────────────────────────────────
  /// Rig-local position of the faulty part for scanner/restore.
  Vector2 _faultLocalPos(SatelliteFaultType f) {
    switch (f) {
      case SatelliteFaultType.batteryOverheating:
        return _batteryPos;
      case SatelliteFaultType.signalLost:
        return _partCenter(_antenna);
      case SatelliteFaultType.cameraOffline:
        return _cameraPos;
      case SatelliteFaultType.solarPanelNotCharging:
        return _partCenter(_solarL);
      case SatelliteFaultType.solarPanelStuck:
        return _partCenter(_solarR);
      case SatelliteFaultType.orbitDrifting:
      case SatelliteFaultType.spaceDebrisNearby:
        return _partCenter(_body);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_ready) return;
    _idle += dt;
    final k = 1 - math.exp(-8 * dt);
    _satAngle += (_satAngleTarget - _satAngle) * k;
    _satDx += (_satDxTarget - _satDx) * k;
    _antennaAngle += (_antennaAngleTarget - _antennaAngle) * k;
    _panelAngle += (_panelAngleTarget - _panelAngle) * k;

    final bob = math.sin(_idle * 2 * math.pi / SDTune.idleBobSeconds) * SDTune.idleBobPx;
    final sway = math.sin(_idle * 2 * math.pi / (SDTune.idleBobSeconds * 1.7)) *
        SDTune.idleTiltDeg *
        math.pi /
        180;
    _sat.position
      ..x = _stage.x * SDTune.satCenterX + _satDx
      ..y = _stage.y * SDTune.satCenterY + bob;
    _sat.angle = _satAngle + sway;
    _antenna?.angle = _antennaAngle;
    _solarL?.angle = -_panelAngle;
    _solarR?.angle = _panelAngle;
  }
}

// ── components ─────────────────────────────────────────────────────────────────

/// Dual-purpose overlay:
///  • Fault overlay (default): optionally pulses, eases toward [targetOpacity];
///    removes itself when faded to 0 (driven externally via _fadeFaults).
///  • Transient restore FX ([life] > 0): fade-in → hold → fade-out → remove on
///    its own timeline, so it never lingers as a blob over the body.
class _Fx extends SpriteComponent {
  _Fx({
    required super.sprite,
    required super.anchor,
    required super.size,
    required super.position,
    this.pulse = false,
    this.fadeIn = false,
    this.life = 0,
  }) {
    if (fadeIn) opacity = 0;
  }
  final bool pulse;
  final bool fadeIn;
  final double life; // >0 → self-timed transient
  double targetOpacity = 1;
  double _clock = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _clock += dt;

    if (life > 0) {
      // self-timed envelope: 18% fade-in, hold, last 30% fade-out
      final p = _clock / life;
      final env = p < 0.18
          ? p / 0.18
          : p < 0.70
              ? 1.0
              : (1 - (p - 0.70) / 0.30);
      opacity = env.clamp(0.0, 1.0);
      if (p >= 1) removeFromParent();
      return;
    }

    var target = targetOpacity;
    if (pulse) target *= 0.6 + 0.4 * (0.5 + 0.5 * math.sin(_clock * 4.2));
    opacity += (target - opacity) * (1 - math.exp(-9 * dt));
    if (targetOpacity == 0 && opacity < 0.01) removeFromParent();
  }
}

/// Programmatic scanner reticle (Flame canvas): four cyan corner brackets, two
/// concentric rings, a rotating sweep tick, tick marks, and a TRANSLUCENT centre
/// (low-alpha fill) so the part underneath shows through. Crisp + state-tintable
/// (pass a colour) — replaces the opaque AI scanner sprite. (Playbook pattern.)
class _ScannerReticle extends PositionComponent {
  _ScannerReticle({required double diameter})
      : super(size: Vector2.all(diameter));
  static const color = Color(0xFF7FE8FF);
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final s = size.x;
    final c = Offset(s / 2, s / 2);
    final breathe = 0.85 + 0.15 * (0.5 + 0.5 * math.sin(_t * 3.2));
    final glow = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // faint translucent centre wash (lets the part show through)
    canvas.drawCircle(c, s * 0.30,
        Paint()..color = color.withValues(alpha: 0.06));

    // outer + inner rings
    for (final spec in [
      [s * 0.46, 0.55, 3.0],
      [s * 0.34, 0.85, 2.0],
    ]) {
      canvas.drawCircle(
        c, spec[0] * breathe,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = spec[2]
          ..color = color.withValues(alpha: spec[1].toDouble()),
      );
    }

    // tick marks around the inner ring
    const ticks = 36;
    final tickPaint = Paint()
      ..strokeWidth = 1.5
      ..color = color.withValues(alpha: 0.5);
    for (var i = 0; i < ticks; i++) {
      final a = i / ticks * 2 * math.pi;
      final r1 = s * 0.34 * breathe;
      final r2 = r1 + (i % 3 == 0 ? s * 0.03 : s * 0.015);
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * r1,
        c + Offset(math.cos(a), math.sin(a)) * r2,
        tickPaint,
      );
    }

    // rotating sweep tick (a brighter radial line)
    final sweepA = _t * 1.8;
    canvas.drawLine(
      c,
      c + Offset(math.cos(sweepA), math.sin(sweepA)) * s * 0.44,
      Paint()
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..shader = Gradient.radial(c, s * 0.44, [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.8),
        ]),
    );

    // four corner brackets (the signature scanner frame)
    final ext = s * 0.46; // half-extent of the bracket square
    final len = s * 0.16; // arm length
    final bp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    for (final sx in [-1.0, 1.0]) {
      for (final sy in [-1.0, 1.0]) {
        final corner = c + Offset(sx * ext, sy * ext);
        final path = Path()
          ..moveTo(corner.dx - sx * len, corner.dy)
          ..lineTo(corner.dx, corner.dy)
          ..lineTo(corner.dx, corner.dy - sy * len);
        canvas.drawPath(path, glow);
        canvas.drawPath(path, bp);
      }
    }
  }
}

/// Camera reboot scan-line: sweeps top→bottom across the lens once, then fades.
class _ScanLine extends SpriteComponent {
  _ScanLine({
    required super.sprite,
    required super.anchor,
    required super.size,
    required super.position,
  }) {
    _y0 = position.y;
    paint.blendMode = BlendMode.plus;
  }
  late final double _y0;
  double _t = 0;
  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = (_t / 1.1).clamp(0.0, 1.0);
    position.y = _y0 + (p - 0.5) * size.y;
    opacity = math.sin(p * math.pi);
    if (p >= 1) removeFromParent();
  }
}

/// Green check badge: pops in with an overshoot, holds briefly, then fades out
/// and removes itself (so it doesn't block the satellite like the old glow).
class _CheckBadge extends SpriteComponent {
  _CheckBadge({
    required super.sprite,
    required super.anchor,
    required Vector2 size,
    required super.position,
  })  : _base = size.clone(),
        super(size: size) {
    opacity = 0;
  }
  final Vector2 _base;
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    // pop-in (0–0.32s, overshoot), hold (–1.3s), fade-out (–1.7s)
    double op, sc;
    if (_t < 0.32) {
      final p = _t / 0.32;
      sc = 0.4 + 0.7 * p; // up to 1.1
      op = p;
    } else if (_t < 0.5) {
      sc = 1.1 - 0.1 * ((_t - 0.32) / 0.18); // settle to 1.0
      op = 1;
    } else if (_t < 1.3) {
      sc = 1.0;
      op = 1;
    } else if (_t < 1.7) {
      sc = 1.0 + 0.15 * ((_t - 1.3) / 0.4);
      op = 1 - (_t - 1.3) / 0.4;
    } else {
      removeFromParent();
      return;
    }
    size
      ..x = _base.x * sc
      ..y = _base.y * sc;
    opacity = op.clamp(0.0, 1.0);
  }
}

/// A debris chunk that drifts slowly from [start] toward [target] (and gently
/// loops back so the threat hovers), tumbling as it goes. Carries an optional
/// warning-triangle tag that tracks just above it.
class _DebrisRunner extends SpriteComponent {
  _DebrisRunner({
    required super.sprite,
    required Vector2 start,
    required Vector2 target,
    required double diameter,
    this.phase = 0,
  })  : _start = start,
        _target = target,
        super(anchor: Anchor.center, size: Vector2.all(diameter), position: start);
  final Vector2 _start, _target;
  final double phase;
  double _t = 0;
  _WarningGlyph? _tag;

  void attachTag(_WarningGlyph tag) => _tag = tag;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    // ease in over ~2.6s to a near-satellite hover, then a slow in/out breathe
    final approach = ((_t - phase) / 2.6).clamp(0.0, 1.0);
    final e = approach * approach * (3 - 2 * approach); // smoothstep
    final hover = 0.92 + 0.08 * math.sin((_t - phase) * 1.6);
    position
      ..x = _start.x + (_target.x - _start.x) * e * hover
      ..y = _start.y + (_target.y - _start.y) * e * hover;
    angle = (_t + phase) * 0.7;
    final tag = _tag;
    if (tag != null) {
      tag.position.setValues(position.x, position.y - size.y * 0.75);
    }
  }
}

/// Crisp warning triangle drawn in-canvas (no halo / no baked glow): amber
/// rounded triangle + exclamation, gently pulsing. Used to tag debris chunks.
class _WarningGlyph extends PositionComponent {
  _WarningGlyph({required double size}) : super(size: Vector2.all(size), anchor: Anchor.center);
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final a = 0.8 + 0.2 * (0.5 + 0.5 * math.sin(_t * 4.5));
    final s = size.x;
    final cx = s / 2;
    final tri = Path()
      ..moveTo(cx, s * 0.10)
      ..lineTo(s * 0.90, s * 0.86)
      ..lineTo(s * 0.10, s * 0.86)
      ..close();
    const amber = Color(0xFFFFB02E);
    // dark fill for contrast against bright/varied backdrops
    canvas.drawPath(tri, Paint()..color = const Color(0xFF2A1605).withValues(alpha: 0.9 * a));
    canvas.drawPath(
      tri,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.08
        ..strokeJoin = StrokeJoin.round
        ..color = amber.withValues(alpha: a),
    );
    final bar = Paint()
      ..color = amber.withValues(alpha: a)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.09;
    canvas.drawLine(Offset(cx, s * 0.38), Offset(cx, s * 0.62), bar);
    canvas.drawCircle(Offset(cx, s * 0.74), s * 0.055, Paint()..color = amber.withValues(alpha: a));
  }
}
