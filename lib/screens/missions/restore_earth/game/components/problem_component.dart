// The active problem at a scenario's hotspot: the main problem object (with a
// "confused" wiggle) and a floating marker (glitch pin / static / question /
// no-signal). RepairEffects animates [object]/[marker] on a correct hit;
// `stopAlerts()` clears the marker.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../../config/scenarios.dart';
import '../restore_earth_game.dart';

class ProblemComponent extends PositionComponent with HasGameReference<RestoreEarthGame> {
  ProblemComponent({
    required this.scenario,
    required Vector2 localCenter,
    required this.baseWidth,
  }) : super(position: localCenter, anchor: Anchor.center);

  final ScenarioDef scenario;
  final double baseWidth; // main object display width

  late final SpriteComponent object;
  SpriteComponent? marker;
  double _t = 0;

  @override
  Future<void> onLoad() async {
    final objSprite = game.sprite(scenario.problemAsset);
    object = SpriteComponent(
      sprite: objSprite,
      anchor: Anchor.center,
      size: Vector2(baseWidth, baseWidth * (objSprite.srcSize.y / objSprite.srcSize.x)),
    );
    add(object);

    if (scenario.markerAsset != null) {
      final mSprite = game.sprite(scenario.markerAsset!);
      marker = SpriteComponent(
        sprite: mSprite,
        anchor: Anchor.bottomCenter,
        size: Vector2(baseWidth * 0.5, baseWidth * 0.5 * (mSprite.srcSize.y / mSprite.srcSize.x)),
        position: Vector2(baseWidth * 0.28, -baseWidth * 0.34),
      )..paint = (Paint()..blendMode = BlendMode.plus);
      add(marker!);
    }
    // Note: the spawn scale-in is driven by the game's "emerge from Earth"
    // transition, so no entry pop here.
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final w = _t * 2 * math.pi;
    // Confused wiggle.
    object.angle = math.sin(w * 0.9) * 0.06;
    // Marker bobs.
    marker?.position.y = -baseWidth * 0.34 + math.sin(w * 1.1) * 4;
  }

  /// Remove the marker (called when a correct repair starts).
  void stopAlerts() {
    marker?.add(OpacityEffect.fadeOut(EffectController(duration: 0.3)));
    marker?.add(RemoveEffect(delay: 0.35));
  }
}
