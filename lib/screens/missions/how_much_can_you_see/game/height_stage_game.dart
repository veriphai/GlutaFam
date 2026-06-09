// The Flame stage for Scene 2 — Height Exploration.
//
// Coordinate model: components live on the game root (no camera world) and the
// background is transparent, so game coords == GameWidget logical pixels and the
// Flutter cosmic background shows through (mirrors Restore Earth).
//
// Bridge: the Flutter height rail calls controller.setLevel(); this game listens
// to the controller and, per level, crossfades the background, swaps the
// floating object (drone/airplane/satellite), and animates the environment
// overlays. All text lives in Flutter on top.
//
// NOTE: the scan cone + visible-area circle were removed per feedback — they
// veiled the scene. "You see more with height" is carried by the backgrounds
// themselves zooming out (street → neighborhood → city → region → curved Earth).
//
// LAYOUT: every position/size is a factor of the stage rect (PRD §19/§21), kept
// in `_LevelLayout` / `_overlaySpec` so a nudge = editing one number (budget a
// live tuning pass on device).

import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../config/asset_paths.dart';
import '../config/height_levels.dart';
import '../state/how_much_controller.dart';
import '../state/how_much_state.dart';
import 'components/cover_background.dart';
import 'components/drift_overlay.dart';
import 'components/floating_stage_object.dart';
import '../../../../utils/s3_assets.dart';

class HeightStageGame extends FlameGame {
  HeightStageGame({required this.controller, required this.onSound});

  final HowMuchController controller;
  final void Function(String assetFile) onSound;

  late final CoverBackground _bg;
  FloatingStageObject? _object;
  final List<DriftOverlay> _overlays = [];

  bool _ready = false;
  ViewHeightLevel? _shownLevel;

  @override
  Color backgroundColor() => const Color(0x00000000);

  Sprite _spr(String key) => Sprite(images.fromCache(HM.flame(key)));

  @override
  Future<void> onLoad() async {
    await preloadFlameImagesFromS3(images, HM.stagePreload);

    _bg = CoverBackground(stageSize: size)..priority = 0;
    add(_bg);

    final startCfg = controller.state.currentConfig;
    _bg.setInitial(_spr(startCfg.background));

    _ready = true;
    _applyLevel(startCfg, animated: false);
    controller.addListener(_onControllerChanged);
  }

  @override
  void onRemove() {
    controller.removeListener(_onControllerChanged);
    super.onRemove();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!_ready) return;
    _bg.resize(size);
  }

  // ── controller reaction ──────────────────────────────────────────────────
  void _onControllerChanged() {
    if (!_ready) return;
    final s = controller.state;
    if (s.scene != ActivityScene.heightExploration && s.scene != ActivityScene.wrongAnswerFeedback) {
      return; // stage only animates during exploration
    }
    if (s.currentLevel != _shownLevel) {
      _applyLevel(s.currentConfig, animated: true);
    }
  }

  // ── per-level composition ──────────────────────────────────────────────────
  void _applyLevel(HeightLevelConfig cfg, {required bool animated}) {
    final wasSatellite = cfg.level == ViewHeightLevel.satellite && _shownLevel != cfg.level;
    _shownLevel = cfg.level;

    // Background.
    if (animated) {
      _bg.crossfadeTo(_spr(cfg.background));
    } else {
      _bg.setInitial(_spr(cfg.background));
    }

    // Floating hero object.
    _object?.exit();
    _object = null;
    if (cfg.floatingObject != null) {
      final layout = _objectLayout(cfg.level);
      _object = FloatingStageObject(
        sprite: _spr(cfg.floatingObject!),
        home: Vector2(size.x * layout.home.dx, size.y * layout.home.dy),
        width: size.x * layout.widthFactor,
        style: layout.style,
        from: Vector2(size.x * layout.from.dx, size.y * layout.from.dy),
      );
      add(_object!);
    }

    // Environment overlays.
    for (final o in _overlays) {
      o.exit();
    }
    _overlays.clear();
    for (final key in cfg.overlays) {
      final spec = _overlaySpec(key);
      final w = size.x * spec.widthFactor;
      final o = DriftOverlay(
        sprite: _spr(key),
        center: Vector2(size.x * spec.center.dx, size.y * spec.center.dy),
        width: w,
        style: spec.style,
        targetOpacity: spec.opacity,
        amplitude: size.x * spec.amplitudeFactor,
        additive: spec.additive,
        driftPeriod: spec.driftPeriod,
      );
      _overlays.add(o);
      add(o);
    }

    if (wasSatellite) onSound(HMSounds.reveal);
  }

  // ── layout factors (tune live) ─────────────────────────────────────────────
  _ObjLayout _objectLayout(ViewHeightLevel l) => switch (l) {
        ViewHeightLevel.drone => const _ObjLayout(
            home: Offset(0.52, 0.25), widthFactor: 0.30, style: FloatStyle.bob, from: Offset(1.25, -0.10)),
        ViewHeightLevel.airplane => const _ObjLayout(
            home: Offset(0.50, 0.30), widthFactor: 0.46, style: FloatStyle.glide, from: Offset(-0.35, 0.30)),
        ViewHeightLevel.satellite => const _ObjLayout(
            home: Offset(0.62, 0.24), widthFactor: 0.34, style: FloatStyle.bob, from: Offset(1.30, -0.12)),
        _ => const _ObjLayout(
            home: Offset(0.5, 0.25), widthFactor: 0.3, style: FloatStyle.bob, from: Offset(1.2, -0.1)),
      };

  _OverlaySpec _overlaySpec(String key) {
    switch (key) {
      case HM.cloudSoft:
        return const _OverlaySpec(
            center: Offset(0.5, 0.40), widthFactor: 1.12, style: DriftStyle.drift, opacity: 0.7, amplitudeFactor: 0.05, driftPeriod: 9);
      case HM.blockedView:
        return const _OverlaySpec(
            center: Offset(0.5, 0.58), widthFactor: 1.0, style: DriftStyle.fadePulse, opacity: 0.55);
      case HM.cloudBelowAirplane:
        return const _OverlaySpec(
            center: Offset(0.5, 0.66), widthFactor: 1.18, style: DriftStyle.drift, opacity: 0.8, amplitudeFactor: 0.06, driftPeriod: 10);
      case HM.cloudGlobal:
        return const _OverlaySpec(
            center: Offset(0.5, 0.55), widthFactor: 1.18, style: DriftStyle.drift, opacity: 0.82, amplitudeFactor: 0.04, driftPeriod: 14);
      case HM.cityLights:
        return const _OverlaySpec(
            center: Offset(0.5, 0.60), widthFactor: 0.9, style: DriftStyle.fadePulse, opacity: 0.5, additive: true);
      case HM.forestPatch:
        return const _OverlaySpec(
            center: Offset(0.45, 0.62), widthFactor: 0.72, style: DriftStyle.fadePulse, opacity: 0.6);
      default:
        return const _OverlaySpec(
            center: Offset(0.5, 0.5), widthFactor: 1.0, style: DriftStyle.fadePulse, opacity: 0.6);
    }
  }
}

class _ObjLayout {
  const _ObjLayout({required this.home, required this.widthFactor, required this.style, required this.from});
  final Offset home;
  final double widthFactor;
  final FloatStyle style;
  final Offset from;
}

class _OverlaySpec {
  const _OverlaySpec({
    required this.center,
    required this.widthFactor,
    required this.style,
    required this.opacity,
    this.additive = false,
    this.amplitudeFactor = 0.05,
    this.driftPeriod = 9,
  });
  final Offset center;
  final double widthFactor;
  final DriftStyle style;
  final double opacity;
  final bool additive;
  final double amplitudeFactor;
  final double driftPeriod;
}
