// The Flame build stage.
//
// Coordinate model: components are added directly to the game root (not to a
// camera world), so game coordinates == the GameWidget's logical pixels. That
// makes the Flutter→Flame drop hand-off trivial: the screen converts a global
// drop offset to a local offset inside the GameWidget and passes it straight to
// [tryPlace].
//
// HOW DRAG/DROP WORKS (the Flame half):
//  • The Flutter inventory tray is the drag source (a Draggable).
//  • While dragging, the screen feeds the pointer position to [updateHover] so
//    the matching slot's ring lights up.
//  • On release the screen calls [tryPlace]; this does the spatial slot
//    detection, plays correct/wrong feedback, spawns the installed part, and
//    tells the controller to update mission state.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/services.dart';

import '../config/asset_paths.dart';
import '../config/part_catalog.dart';
import '../config/slot_config.dart';
import '../state/build_satellite_controller.dart';
import 'components/drop_zone_component.dart';
import 'components/installed_part_component.dart';
import 'components/satellite_body_component.dart';
import 'effects/launch_preview_controller.dart';
import '../../../../utils/s3_assets.dart';

class BuildSatelliteGame extends FlameGame {
  BuildSatelliteGame({required this.controller, required this.onSound});

  final BuildSatelliteController controller;
  final void Function(String assetFile) onSound;

  late SatelliteBodyComponent body;
  final Map<String, DropZoneComponent> _dropZones = {};
  final Map<String, InstalledPartComponent> installedComponents = {};

  bool _ready = false;
  bool _launchStarted = false;
  LaunchPreviewController? _launchCtrl;

  /// Tracks which part is currently inside its correct-slot radius — used to
  /// fire `controller.onPartNearCorrectSlot` ONCE per hover-enter, not every
  /// frame.
  String? _nearCorrectFor;

  // Tunable layout: body width as a fraction of the stage, and its centre.
  static const double _bodyWidthFactor = 0.50;
  static const double _bodyCenterYFactor = 0.46;

  // Let the Flutter shell's cosmic background show through the GameWidget.
  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    // WHERE ASSETS ARE LOADED: every cleaned sprite is preloaded once here.
    await preloadFlameImagesFromS3(images, SatAssets.allFlamePaths);
    _layout();
    controller.addListener(_onControllerChanged);
    controller.onLaunchClipPlayed = _onLaunchClipPlayed;
    _ready = true;
  }

  @override
  void onRemove() {
    controller.removeListener(_onControllerChanged);
    controller.onLaunchClipPlayed = null;
    super.onRemove();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_ready) _relayout();
  }

  // ── Layout ───────────────────────────────────────────────────────────
  void _layout() {
    final bodyW = size.x * _bodyWidthFactor;
    final bodySprite = sprite(SatAssets.body);
    final aspect = bodySprite.srcSize.y / bodySprite.srcSize.x;
    final bodySize = Vector2(bodyW, bodyW * aspect);
    final center = Vector2(size.x / 2, size.y * _bodyCenterYFactor);

    body = SatelliteBodyComponent(
      bodySprite: bodySprite,
      size: bodySize,
      center: center,
    );
    add(body);

    // WHERE DROP ZONES ARE CREATED: one per slot, positioned from SlotConfig.
    for (final slot in kSlotConfigs.values) {
      final dz = DropZoneComponent(
        slotId: slot.id,
        position: body.slotLocal(slot),
        ringWidth: bodySize.x * (0.30 + slot.widthFactor * 0.25),
      );
      _dropZones[slot.id] = dz;
      body.add(dz);
    }
    _refreshActiveSlots();
  }

  void _relayout() {
    // Rebuild from scratch on a real size change (rare: the stage box is fixed-
    // aspect). Re-place installed parts at their slots.
    for (final dz in _dropZones.values) {
      dz.removeFromParent();
    }
    _dropZones.clear();
    body.removeFromParent();
    final installed = controller.state.installedParts.toList();
    installedComponents.clear();
    _layout();
    for (final id in installed) {
      _addInstalledPart(partById(id), animate: false);
      _dropZones[partById(id).slotId]?.markFilled();
    }
    _refreshActiveSlots();
  }

  // ── Controller reactions ───────────────────────────────────────────────
  void _onControllerChanged() {
    _refreshActiveSlots();
    if (controller.state.launching && !_launchStarted) {
      _launchStarted = true;
      _launchCtrl = LaunchPreviewController(this)..liftOnly();
    }
  }

  /// Wired in onLoad: each spoken launch-check line triggers its matching
  /// subsystem visual at the moment the voice starts playing (sync 1:1 with
  /// the dialogue script).
  void _onLaunchClipPlayed(int clip) {
    final ctrl = _launchCtrl;
    if (ctrl == null) return;
    switch (clip) {
      case 65: ctrl.revealPower();      // Power check
      case 66: ctrl.revealSignal();     // Signal check
      case 67: ctrl.revealVision();     // Vision check
      case 68: ctrl.revealBrain();      // Brain check
      case 69: ctrl.revealBattery();    // Backup power check
      case 70: ctrl.revealMovement();   // Movement check
      case 71: ctrl.revealProtection(); // Protection check
    }
  }

  void _refreshActiveSlots() {
    final active = controller.activeSlotIds;
    _dropZones.forEach((id, dz) => dz.setActive(active.contains(id)));
  }

  // ── Drag hover + drop (called by the screen) ───────────────────────────
  void updateHover(String partId, Vector2 worldPos) {
    if (!_ready) return;
    final radius = body.size.x * 0.22;
    // Light any active slot the pointer is near (visual).
    _dropZones.forEach((id, dz) {
      if (!dz.isActive) return;
      final slot = slotConfig(id);
      final near = (worldPos - body.slotWorld(slot)).length <= radius;
      dz.setHovering(near);
    });
    // Fire the controller's "near correct slot" voice cue ONCE per
    // hover-enter on the part's OWN correct slot.
    if (!controller.isActive(partId)) return;
    final correctSlotId = partById(partId).slotId;
    final correctSlot = slotConfig(correctSlotId);
    final nearCorrect =
        (worldPos - body.slotWorld(correctSlot)).length <= radius;
    if (nearCorrect && _nearCorrectFor != partId) {
      _nearCorrectFor = partId;
      controller.onPartNearCorrectSlot(partId);
    } else if (!nearCorrect && _nearCorrectFor == partId) {
      _nearCorrectFor = null;
    }
  }

  void clearHover() {
    for (final dz in _dropZones.values) {
      dz.setHovering(false);
    }
    _nearCorrectFor = null;
  }

  /// Returns true if [partId] snapped into its slot.
  bool tryPlace(String partId, Vector2 worldPos) {
    if (!_ready || controller.state.launching || controller.state.isComplete) {
      return false;
    }
    if (!controller.isActive(partId)) return false;

    final part = partById(partId);
    final slot = slotConfig(part.slotId);
    final dz = _dropZones[slot.id]!;
    final dist = (worldPos - body.slotWorld(slot)).length;
    final radius = body.size.x * 0.18;

    clearHover();
    if (dist <= radius) {
      // CORRECT: snap, flash, install, update state.
      dz.flashCorrect();
      dz.markFilled();
      _addInstalledPart(part);
      onSound(SatSounds.correct);
      HapticFeedback.mediumImpact();
      controller.installPart(part);
      return true;
    }

    // WRONG: red warning on the intended slot, gentle correction. The tray card
    // never left the tray, so it stays available — effectively a bounce-back.
    dz.flashWrong();
    onSound(SatSounds.wrong);
    HapticFeedback.lightImpact();
    controller.registerWrongDrop();
    return false;
  }

  void _addInstalledPart(SatellitePart part, {bool animate = true}) {
    final slot = slotConfig(part.slotId);
    final comp = InstalledPartComponent(
      part: part,
      slot: slot,
      bodySize: body.size,
      sprite: sprite(part.spriteFile),
      localPosition: body.slotLocal(slot),
    );
    installedComponents[part.id] = comp;
    body.add(comp);
  }

  // ── Sprite + effect helpers (used by deployment + launch animations) ────
  Sprite sprite(String file) => Sprite(images.fromCache(SatAssets.flame(file)));

  Vector2 get bodyCenter => body.position.clone();

  /// Additive glow burst that scales up + fades out, then removes itself.
  void spawnGlow(
    Vector2 worldPos,
    String file, {
    required Vector2 size,
    double duration = 0.6,
    double fromScale = 0.5,
    double toScale = 1.4,
    Color? tint,
    double startDelay = 0,
  }) {
    final paint = Paint()..blendMode = BlendMode.plus;
    if (tint != null) {
      paint.colorFilter = ColorFilter.mode(tint, BlendMode.modulate);
    }
    final comp = SpriteComponent(
      sprite: sprite(file),
      anchor: Anchor.center,
      position: worldPos.clone(),
      size: size,
    )..paint = paint;
    comp.scale = Vector2.all(fromScale);
    comp.add(ScaleEffect.to(Vector2.all(toScale),
        EffectController(duration: duration, startDelay: startDelay, curve: Curves.easeOut)));
    comp.add(OpacityEffect.fadeOut(
        EffectController(duration: duration, startDelay: startDelay, curve: Curves.easeIn)));
    comp.add(RemoveEffect(delay: startDelay + duration + 0.02));
    add(comp);
  }

  /// Expanding signal rings from a point (antenna / launch).
  void spawnSignalWaves(Vector2 worldPos, double baseSize, {int count = 3}) {
    for (var i = 0; i < count; i++) {
      spawnGlow(worldPos, SatAssets.signalWave,
          size: Vector2.all(baseSize),
          duration: 0.9,
          fromScale: 0.3,
          toScale: 1.8,
          tint: const Color(0xFF18D6FF),
          startDelay: i * 0.22);
    }
  }

  /// A glowing beam from [from] to [to] (energy flowing into the body).
  void spawnEnergyLine(Vector2 from, Vector2 to, {double startDelay = 0}) {
    final delta = to - from;
    final len = delta.length;
    final comp = SpriteComponent(
      sprite: sprite(SatAssets.energyFlowLine),
      anchor: Anchor.centerLeft,
      position: from.clone(),
      size: Vector2(len, len * 0.16),
      angle: math.atan2(delta.y, delta.x),
    )..paint = (Paint()
      ..blendMode = BlendMode.plus
      ..colorFilter = const ColorFilter.mode(Color(0xFF36C8FF), BlendMode.modulate));
    comp.add(OpacityEffect.fadeOut(
        EffectController(duration: 0.6, startDelay: startDelay, curve: Curves.easeIn)));
    comp.add(RemoveEffect(delay: startDelay + 0.7));
    add(comp);

    // A bright spark travelling along the beam sells the "flow".
    final spark = SpriteComponent(
      sprite: sprite(SatAssets.energyParticle),
      anchor: Anchor.center,
      position: from.clone(),
      size: Vector2.all(len * 0.14),
    )..paint = (Paint()..blendMode = BlendMode.plus);
    spark.add(MoveEffect.to(to.clone(),
        EffectController(duration: 0.5, startDelay: startDelay, curve: Curves.easeIn)));
    spark.add(RemoveEffect(delay: startDelay + 0.55));
    add(spark);
  }

  /// Brief thruster flame test + a few exhaust sparks streaming downward.
  void spawnThrusterFlame(Vector2 topCenterWorld, double width) {
    final flameSprite = sprite(SatAssets.thrusterFlame);
    final aspect = flameSprite.srcSize.y / flameSprite.srcSize.x;
    final comp = SpriteComponent(
      sprite: flameSprite,
      anchor: Anchor.topCenter,
      position: topCenterWorld.clone(),
      size: Vector2(width, width * aspect),
    )..paint = (Paint()..blendMode = BlendMode.plus);
    comp.scale = Vector2(1, 0.2);
    comp.add(ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.18, curve: Curves.easeOut)));
    comp.add(OpacityEffect.fadeOut(EffectController(duration: 0.5, startDelay: 0.4)));
    comp.add(RemoveEffect(delay: 1.0));
    add(comp);

    final rnd = math.Random();
    for (var i = 0; i < 6; i++) {
      final spark = SpriteComponent(
        sprite: sprite(SatAssets.energyParticle),
        anchor: Anchor.center,
        position: topCenterWorld + Vector2((rnd.nextDouble() - 0.5) * width * 0.4, width * 0.2),
        size: Vector2.all(width * 0.12),
      )..paint = (Paint()..blendMode = BlendMode.plus);
      spark.add(MoveEffect.by(Vector2((rnd.nextDouble() - 0.5) * width * 0.3, width * 0.9),
          EffectController(duration: 0.5 + rnd.nextDouble() * 0.3, startDelay: i * 0.04)));
      spark.add(OpacityEffect.fadeOut(EffectController(duration: 0.6, startDelay: i * 0.04)));
      spark.add(RemoveEffect(delay: 1.0));
      add(spark);
    }
  }
}
