// The Flame build stage for Restore Earth.
//
// Coordinate model: components live on the game root (no camera world) and the
// game background is transparent, so game coords == GameWidget logical pixels
// and the Flutter cosmic background shows through.
//
// Bridge: the Flutter power buttons call controller.selectPower(); this game
// listens to the controller to spawn problems, show the reticle, and tint the
// satellite. Aiming (reticle drag) is handled natively here via PanDetector; on
// release the game asks the controller for the outcome and plays the visuals.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show IconData;

import '../config/asset_paths.dart';
import '../config/earth_layout.dart';
import '../config/powers.dart';
import '../state/restore_earth_controller.dart';
import '../state/restore_earth_state.dart';
import 'components/beam_component.dart';
import 'components/earth_stage_component.dart';
import 'components/icon_fx.dart';
import 'components/problem_component.dart';
import 'components/reticle_component.dart';
import 'components/satellite_component.dart';
import 'effects/completion_controller.dart';
import 'effects/repair_effects.dart';
import '../../../../utils/s3_assets.dart';

class RestoreEarthGame extends FlameGame {
  RestoreEarthGame({required this.controller, required this.onSound});

  final RestoreEarthController controller;
  final void Function(String assetFile) onSound;

  late EarthStageComponent earth;
  late SatelliteComponent satellite;
  late BeamComponent beam;
  ReticleComponent? _reticle;
  SpriteComponent? _snapRing;
  ProblemComponent? _problem;
  _TargetRing? _targetRing;
  SpriteComponent? _zoneFocus; // the active zone shown enlarged + centred

  /// Where the active problem is presented (centred close-up). Hit detection +
  /// reticle target this point.
  Vector2 get _focusCenter => Vector2(size.x * 0.5, size.y * 0.70);

  bool _ready = false;
  bool _completionPlayed = false;
  bool _firing = false; // ignore input during beam/repair

  @override
  Color backgroundColor() => const Color(0x00000000);

  Sprite sprite(String flamePath) => Sprite(images.fromCache(flamePath));

  // ── load + layout ──────────────────────────────────────────────────────
  @override
  Future<void> onLoad() async {
    await preloadFlameImagesFromS3(images, RE.preload);
    _layout();
    add(_AimLayer()..priority = 100); // top-most gesture catcher for aiming
    controller.addListener(_onControllerChanged);
    // Hand the controller a cleanup-then-advance hook. It calls back here
    // ONLY after Orbit's learning line finishes — so the next scenario can
    // never spawn over a still-speaking voice line.
    controller.onAdvanceReady = _cleanupAndAdvance;
    _ready = true;
  }

  @override
  void onRemove() {
    controller.removeListener(_onControllerChanged);
    controller.onAdvanceReady = null;
    super.onRemove();
  }

  void _cleanupAndAdvance() {
    _problem?.removeFromParent();
    _problem = null;
    _firing = false;
    controller.advanceToNext();
  }

  void _layout() {
    final baseSprite = sprite(RE.flame(RE.earthBase));
    final earthW = size.x * kEarthWidthOnStage;
    final earthH = earthW * (baseSprite.srcSize.y / baseSprite.srcSize.x);
    earth = EarthStageComponent(
      size: Vector2(earthW, earthH),
      center: Vector2(size.x * kEarthCenterOnStage.dx, size.y * kEarthCenterOnStage.dy),
    )..priority = 10;
    add(earth);

    beam = BeamComponent();
    add(beam);

    satellite = SatelliteComponent(
      bodyWidth: size.x * 0.18,
      center: Vector2(size.x * 0.5, size.y * 0.22),
    )..priority = 90;
    add(satellite);
  }

  // Screen-space hit radius from the BASE earth width (constant regardless of
  // the zoom), so the target stays a sensible size.
  double get _hotspotRadius => earth.size.x * controllerScenarioRadius();

  double controllerScenarioRadius() => controller.currentScenario.hitRadiusFactor;

  // The problem is presented centred at _focusCenter, but the target sits a touch
  // ABOVE it — problem sprites carry a little ground/shadow below their middle,
  // so the sprite centre lands low; this nudges the ring onto the object body.
  // Tune `_targetBiasUp` if the ring sits off the problem.
  static const double _targetBiasUp = 0.06; // fraction of base width, upward
  Vector2 get _activeHotspot => _focusCenter - Vector2(0, size.x * _targetBiasUp);

  // ── controller reactions ─────────────────────────────────────────────────
  void _onControllerChanged() {
    if (!_ready) return;
    final s = controller.state;

    // Spawn / swap the active problem.
    if (s.phase == ActivityPhase.playing &&
        (_problem == null || _problem!.scenario.id != controller.currentScenario.id)) {
      _spawnProblem();
    }

    // Reticle + satellite mode follow the selected power.
    if (s.reticleVisible && s.selectedPower != null) {
      _ensureReticle();
      final p = power(s.selectedPower!);
      satellite.setMode(p.beamColor);
      beam.color = p.beamColor;
    } else if (!_firing) {
      _removeReticle();
      beam.hide();
      satellite.setMode(null);
    }

    satellite.setFace(_faceFor(s));

    if (s.phase == ActivityPhase.complete && !_completionPlayed) {
      _completionPlayed = true;
      _clearFocus(); // reveal the full Earth for the finale
      CompletionController(this).play();
    }
  }

  SatFace _faceFor(RestoreEarthState s) {
    if (s.mascot == MascotMood.excited || s.mascot == MascotMood.celebrate) return SatFace.excited;
    if (s.mascot == MascotMood.oops) return SatFace.oops;
    if (s.selectedPower != null && s.phase == ActivityPhase.playing) return SatFace.hint;
    return SatFace.idle;
  }

  void _spawnProblem() {
    final s = controller.currentScenario;
    final fc = _focusCenter;

    // Recede the Earth (fade its own sprites) so the focused area stands out —
    // the cosmic background is untouched.
    earth.setDim(0.4);

    // Premium transition: the zone + problem EMERGE from their spot on the Earth
    // (small) and zoom up to the focus centre (full size).
    final fromPos = earth.hotspotWorld(s.hotspot.dx, s.hotspot.dy);
    const fromScale = 0.42;
    const dur = 0.6;
    EffectController ctrlOut() => EffectController(duration: dur, curve: Curves.easeOutCubic);
    EffectController ctrlScale() => EffectController(duration: dur, curve: Curves.easeOutBack);

    // The active zone, enlarged (the "zoomed-in area"; car size is unchanged).
    _zoneFocus?.removeFromParent();
    final zp = sprite(_zonePropFor(s.zoneLabel));
    final zw = size.x * 0.84;
    _zoneFocus = SpriteComponent(
      sprite: zp,
      anchor: Anchor.center,
      position: fromPos.clone(),
      size: Vector2(zw, zw * (zp.srcSize.y / zp.srcSize.x)),
      priority: 45,
    )
      ..scale = Vector2.all(fromScale)
      ..opacity = 0
      ..add(MoveEffect.to(fc, ctrlOut()))
      ..add(ScaleEffect.to(Vector2.all(1), ctrlScale()))
      ..add(OpacityEffect.to(1, EffectController(duration: 0.35)));
    add(_zoneFocus!);

    // The problem itself, riding the same emerge-and-zoom.
    _problem?.removeFromParent();
    _problem = ProblemComponent(scenario: s, localCenter: fromPos, baseWidth: size.x * 0.16)
      ..priority = 47
      ..scale = Vector2.all(fromScale)
      ..add(MoveEffect.to(fc, ctrlOut()))
      ..add(ScaleEffect.to(Vector2.all(1), ctrlScale()));
    add(_problem!);

    _targetRing?.removeFromParent();
    _targetRing = _TargetRing(this)..priority = 64;
    add(_targetRing!);
  }

  /// Remove the focused-zone presentation and un-dim the Earth (e.g. at finish).
  void _clearFocus() {
    for (final c in [_zoneFocus, _problem, _targetRing, _reticle, _snapRing]) {
      c?.removeFromParent();
    }
    _zoneFocus = null;
    _problem = null;
    _targetRing = null;
    _reticle = null;
    _snapRing = null;
    earth.setDim(1.0);
  }

  String _zonePropFor(String zoneLabel) => switch (zoneLabel) {
        'CITY' => RE.flame(RE.cityProps),
        'OCEAN' => RE.flame(RE.oceanProps),
        'FARM' => RE.flame(RE.farmProps),
        'MOUNTAIN VILLAGE' => RE.flame(RE.villageProps),
        _ => RE.flame(RE.stormProps), // STORM AREA + fallback
      };

  /// Calls [fn] once after [seconds] (used by repair/completion timelines).
  void runLater(double seconds, VoidCallback fn) => add(_DelayedCall(seconds, fn));

  /// Spawn a crisp Material-icon effect at a world point (replaces poor sprites).
  void spawnIcon(
    IconData icon,
    Vector2 world,
    double glyphSize, {
    Color color = const Color(0xFFFFFFFF),
    Color? glowColor,
    double startDelay = 0,
    double lifetime = 0.9,
    bool persist = false,
    double scaleFrom = 0.4,
    double scaleTo = 1.15,
    int priority = 80,
  }) {
    add(IconFx(
      icon: icon,
      color: color,
      glowColor: glowColor,
      glyphSize: glyphSize,
      position: world.clone(),
      startDelay: startDelay,
      lifetime: lifetime,
      persist: persist,
      scaleFrom: scaleFrom,
      scaleTo: scaleTo,
    )..priority = priority);
  }

  void _ensureReticle() {
    if (_reticle != null) return;
    // Spawn the reticle a random distance AWAY from the target so the child has
    // to aim it onto the problem (drag, or tap the problem directly).
    final hotspot = _activeHotspot;
    final rnd = math.Random();
    final ang = rnd.nextDouble() * 2 * math.pi;
    final dist = earth.size.x * (0.30 + rnd.nextDouble() * 0.12); // ~0.30–0.42 of base width
    var start = hotspot + Vector2(math.cos(ang), math.sin(ang)) * dist;
    start = Vector2(
      start.x.clamp(size.x * 0.12, size.x * 0.88),
      start.y.clamp(size.y * 0.20, size.y * 0.80),
    );
    final r = ReticleComponent(diameter: earth.size.x * 0.16)
      ..priority = 70
      ..position = start;
    _reticle = r;
    add(r);
  }

  void _removeReticle() {
    _reticle?.removeFromParent();
    _reticle = null;
    _snapRing?.removeFromParent();
    _snapRing = null;
  }

  // ── aiming (PanDetector) ──────────────────────────────────────────────────
  bool get _canAim => _ready && !_firing && controller.state.reticleVisible;

  // Gestures arrive from the full-stage _AimLayer (TapCallbacks + DragCallbacks).
  // Tap = aim+fire at the point; drag = aim continuously then fire on release.
  void beginAim(Vector2 p) {
    if (!_canAim) return;
    _ensureReticle();
    _aimAt(p);
  }

  void updateAim(Vector2 p) {
    if (!_canAim || _reticle == null) return;
    _aimAt(p);
  }

  void endAim() {
    if (!_canAim || _reticle == null) return;
    _release();
  }

  void tapAim(Vector2 p) {
    if (!_canAim) return;
    _ensureReticle();
    _aimAt(p);
    _release();
  }

  void _aimAt(Vector2 target) {
    final r = _reticle!;
    // Clamp inside the earth rect.
    final half = earth.size / 2 * earth.scale.x;
    final tl = earth.position - half;
    final br = earth.position + half;
    var pos = Vector2(target.x.clamp(tl.x, br.x), target.y.clamp(tl.y, br.y));

    // Magnetic ease toward the hotspot within snap radius (PRD §13.3).
    final hotspot = _activeHotspot;
    final d = pos.distanceTo(hotspot);
    final snap = _hotspotRadius;
    final near = d <= snap;
    if (near) {
      pos = pos + (hotspot - pos) * 0.35; // gentle pull
      _showSnapRing(hotspot);
    } else {
      _snapRing?.removeFromParent();
      _snapRing = null;
    }
    r.position = pos;
    r.setActive(near);

    final p = power(controller.state.selectedPower!);
    beam.aim(satellite.emitPoint, r.position, p.beamColor, i: 0.45);
  }

  void _showSnapRing(Vector2 hotspot) {
    if (_snapRing != null) {
      _snapRing!.position = hotspot;
      return;
    }
    final ring = sprite(RE.flame(RE.snapRing));
    _snapRing = SpriteComponent(
      sprite: ring,
      anchor: Anchor.center,
      position: hotspot,
      size: Vector2.all(earth.size.x * 0.18),
      priority: 65,
    )..paint = (Paint()..blendMode = BlendMode.plus);
    add(_snapRing!);
  }

  void _release() {
    // Capture the aim point BEFORE notifying the controller: a correct hit flips
    // the phase to `repairing`, whose listener removes the reticle synchronously
    // — so `_reticle` may be null by the time we fire.
    final aimPos = _reticle!.position.clone();
    final dist = aimPos.distanceTo(_activeHotspot);
    final targetHit = dist <= _hotspotRadius;
    final p = power(controller.state.selectedPower ?? PowerId.location);
    final outcome = controller.onBeamReleased(targetHit);

    switch (outcome) {
      case BeamOutcome.miss:
        _fizzle(aimPos, p.beamColor);
      case BeamOutcome.wrong:
        onSound(RESounds.wrong);
        HapticFeedback.lightImpact();
        _fizzle(aimPos, p.beamColor);
      case BeamOutcome.correct:
        _fireAndRepair(p, aimPos);
    }
  }

  // Faint beam that flickers and fizzles out (PRD §28.6). No harsh failure.
  void _fizzle(Vector2 at, Color color) {
    beam.aim(satellite.emitPoint, at, color, i: 0.5);
    var t = 0.0;
    final ticker = _Ticker((dt) {
      t += dt;
      beam.intensity = (0.5 * (1 - t / 0.35)).clamp(0.0, 0.5) * (0.6 + 0.4 * (t * 40 % 1));
      if (t >= 0.35) {
        beam.hide();
        return true;
      }
      return false;
    });
    add(ticker);
  }

  // Full beam + endpoint glows, then the scenario repair timeline (PRD §16/§28.5).
  void _fireAndRepair(PowerDef p, Vector2 to) {
    _firing = true;
    final from = satellite.emitPoint;
    onSound(RESounds.correct);
    HapticFeedback.mediumImpact();

    beam.aim(from, to, p.beamColor, i: 1.0);
    spawnEffect(RE.flame(RE.beamStartGlow), from, earth.worldWidth * 0.12, tint: p.beamColor, hold: 0.4, fadeOut: 0.5);
    spawnEffect(RE.flame(RE.beamEndGlow), to, earth.worldWidth * 0.14, tint: p.beamColor, startDelay: 0.12, hold: 0.4, fadeOut: 0.6);

    _removeReticleSoon();

    // Fade the beam out after the strike, then run the repair.
    beam.add(_DelayedCall(0.45, () => beam.hide()));
    RepairEffects.play(this, _problem!, controller.currentScenario, onComplete: () {
      // From here the controller drives timing. It plays the success line,
      // then the learning line, then calls our onAdvanceReady hook to clean
      // up the problem and spawn the next scenario.
      controller.onRepairComplete();
    });
  }

  void _removeReticleSoon() {
    final r = _reticle;
    final sr = _snapRing;
    _reticle = null;
    _snapRing = null;
    r?.add(OpacityEffect.fadeOut(EffectController(duration: 0.2)));
    r?.add(RemoveEffect(delay: 0.25));
    sr?.add(RemoveEffect(delay: 0.25));
  }

  // ── generic effect spawner (used by repair + completion) ───────────────────
  SpriteComponent spawnEffect(
    String flamePath,
    Vector2 world,
    double width, {
    bool additive = true,
    double scaleFrom = 0.6,
    double scaleTo = 1.0,
    double fadeOut = 0.4,
    double hold = 0.3,
    double startDelay = 0,
    double rotateTurns = 0,
    Color? tint,
    bool persist = false,
    int priority = 80,
  }) {
    final s = sprite(flamePath);
    final comp = SpriteComponent(
      sprite: s,
      anchor: Anchor.center,
      position: world.clone(),
      size: Vector2(width, width * (s.srcSize.y / s.srcSize.x)),
      priority: priority,
    )..paint = (additive ? (Paint()..blendMode = BlendMode.plus) : Paint());
    if (tint != null) {
      comp.paint.colorFilter = ColorFilter.mode(tint, BlendMode.modulate);
    }
    comp.scale = Vector2.all(scaleFrom);
    comp.add(ScaleEffect.to(Vector2.all(scaleTo),
        EffectController(duration: 0.35, startDelay: startDelay, curve: Curves.easeOut)));
    if (rotateTurns != 0) {
      comp.add(RotateEffect.by(rotateTurns * 6.28318,
          EffectController(duration: 0.6, startDelay: startDelay, curve: Curves.easeInOut)));
    }
    if (!persist) {
      comp.add(OpacityEffect.fadeOut(
          EffectController(duration: fadeOut, startDelay: startDelay + hold + 0.35, curve: Curves.easeIn)));
      comp.add(RemoveEffect(delay: startDelay + hold + 0.35 + fadeOut + 0.05));
    }
    add(comp);
    return comp;
  }
}

/// Runs [tick] every frame until it returns true, then removes itself.
class _Ticker extends Component {
  _Ticker(this.tick);
  final bool Function(double dt) tick;
  @override
  void update(double dt) {
    if (tick(dt)) removeFromParent();
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

/// Full-stage, invisible gesture catcher. Component-level TapCallbacks +
/// DragCallbacks are the modern (non-deprecated) gesture API and work reliably
/// for both mouse (web) and touch. `containsLocalPoint => true` makes it catch
/// gestures anywhere on the canvas regardless of size.
class _AimLayer extends PositionComponent
    with TapCallbacks, DragCallbacks, HasGameReference<RestoreEarthGame> {
  final Vector2 _p = Vector2.zero();

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    game.tapAim(event.canvasPosition);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _p.setFrom(event.canvasPosition);
    game.beginAim(_p);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    _p.add(event.localDelta);
    game.updateAim(_p);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    game.endAim();
  }
}

/// Pulsing ring at the active hotspot so the aim target is obvious (and to
/// visually confirm the hotspot lines up with the problem). TEMP-ish — keep as a
/// gentle "aim here" indicator or remove once tuned.
class _TargetRing extends Component {
  _TargetRing(this.game);
  final RestoreEarthGame game;
  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final c = game._activeHotspot.toOffset();
    final r = game._hotspotRadius * 0.5; // visual ring ~50% of the (forgiving) hit radius
    final pulse = (math.sin(_t * 3) + 1) / 2;
    final ring = Paint()
      ..blendMode = BlendMode.plus
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFF39D8FF).withValues(alpha: 0.5 + 0.4 * pulse);
    canvas.drawCircle(c, r * (0.92 + 0.06 * pulse), ring);
    canvas.drawCircle(
        c, 4, Paint()..blendMode = BlendMode.plus..color = const Color(0xFFFFFFFF));
  }
}
