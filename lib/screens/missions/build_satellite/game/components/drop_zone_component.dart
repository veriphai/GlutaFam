// A slot's visual drop target. Lives as a child of the body at the slot's local
// position. Shows a pulsing cyan ring while its part is the active one, glows
// brighter on hover, flashes on a correct snap, and flashes red on a wrong drop.
//
// All effect sprites are drawn with additive blending (BlendMode.plus) so the
// faint prototype-art residue disappears against the dark space stage.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

import '../../config/asset_paths.dart';
import '../build_satellite_game.dart';

class DropZoneComponent extends PositionComponent
    with HasGameReference<BuildSatelliteGame> {
  DropZoneComponent({
    required this.slotId,
    required Vector2 position,
    required double ringWidth,
  }) : super(
          position: position,
          size: Vector2(ringWidth, ringWidth * 0.62),
          anchor: Anchor.center,
        );

  final String slotId;

  bool _active = false;
  bool _hovering = false;
  bool _filled = false;
  double _t = 0;

  late final Sprite _ring = game.sprite(SatAssets.dropZoneRing);
  late final Sprite _glow = game.sprite(SatAssets.correctSlotGlow);

  final Paint _additive = Paint()..blendMode = BlendMode.plus;

  void setActive(bool v) {
    _active = v && !_filled;
  }

  void setHovering(bool v) => _hovering = v && _active;

  void markFilled() {
    _filled = true;
    _active = false;
    _hovering = false;
  }

  bool get isActive => _active;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    if (!_active) return;
    final pulse = (math.sin(_t * 3) + 1) / 2; // 0..1

    // Base pulsing ring.
    _additive.color = const Color(0xFF18D6FF).withValues(alpha: 0.45 + pulse * 0.4);
    final s = 1.0 + pulse * 0.06 + (_hovering ? 0.12 : 0.0);
    final w = size.x * s, h = size.y * s;
    _ring.render(canvas,
        position: Vector2((size.x - w) / 2, (size.y - h) / 2),
        size: Vector2(w, h),
        overridePaint: _additive);

    // Stronger glow when the correct part hovers nearby.
    if (_hovering) {
      _additive.color = const Color(0xFF7CFFEA).withValues(alpha: 0.5);
      final gw = size.x * 1.1, gh = size.y * 1.1;
      _glow.render(canvas,
          position: Vector2((size.x - gw) / 2, (size.y - gh) / 2),
          size: Vector2(gw, gh),
          overridePaint: _additive);
    }
  }

  /// Bright snap flash on a correct placement.
  void flashCorrect() {
    _spawnFlash(SatAssets.snapFlash, const Color(0xFFFFFFFF), 0.45, 1.5);
  }

  /// Red warning pulse on a wrong drop.
  void flashWrong() {
    _spawnFlash(SatAssets.wrongSlotWarning, const Color(0xFFFF5470), 0.5, 1.3);
  }

  void _spawnFlash(String file, Color tint, double duration, double toScale) {
    final flash = SpriteComponent(
      sprite: game.sprite(file),
      anchor: Anchor.center,
      position: size / 2,
      size: Vector2.all(size.x * 0.9),
    )..paint = (Paint()
      ..blendMode = BlendMode.plus
      ..colorFilter = ColorFilter.mode(tint, BlendMode.modulate));
    flash.scale = Vector2.all(0.6);
    flash.add(ScaleEffect.to(
        Vector2.all(toScale), EffectController(duration: duration, curve: Curves.easeOut)));
    flash.add(OpacityEffect.fadeOut(
      EffectController(duration: duration, curve: Curves.easeIn),
      onComplete: flash.removeFromParent,
    ));
    add(flash);
  }
}
