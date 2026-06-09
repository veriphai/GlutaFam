// The Earth diorama: bare terrain base + the 5 zone-prop "districts" composited
// on top at the tuned factors in earth_layout.dart, with a slow idle scale
// pulse. Children are placed in this component's local space (top-left origin),
// so they ride the pulse together.

import 'dart:math' as math;

import 'package:flame/components.dart';

import '../../config/asset_paths.dart';
import '../../config/earth_layout.dart';
import '../restore_earth_game.dart';

class EarthStageComponent extends PositionComponent
    with HasGameReference<RestoreEarthGame> {
  EarthStageComponent({required Vector2 size, required Vector2 center})
      : super(size: size, position: center, anchor: Anchor.center);

  double _t = 0;

  @override
  Future<void> onLoad() async {
    // Base terrain fills the component.
    add(SpriteComponent(
        sprite: game.sprite(RE.flame(RE.earthBase)), size: size.clone(), anchor: Anchor.topLeft));

    // District props overlaid at tuned positions (PRD §11.2 / earth_layout).
    for (final z in kZoneProps) {
      final sprite = game.sprite(z.asset); // earth_layout stores full flame paths
      final w = z.width * size.x;
      final h = w * (sprite.srcSize.y / sprite.srcSize.x);
      add(SpriteComponent(
        sprite: sprite,
        size: Vector2(w, h),
        position: Vector2(z.center.dx * size.x, z.center.dy * size.y),
        anchor: Anchor.center,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    // Static Earth with a slow 1.0 → 1.01 idle breathing pulse (PRD §11.3).
    scale = Vector2.all(1.0 + 0.01 * (math.sin(_t * 0.9) + 1) / 2);
  }

  double get worldWidth => size.x * scale.x;

  /// Fade the Earth itself (base + district sprites) without touching the cosmic
  /// background. Used to recede the Earth while a zone is focused.
  void setDim(double opacity) {
    for (final c in children.whereType<SpriteComponent>()) {
      c.opacity = opacity;
    }
  }

  /// Game-space position of a zone factor (0..1 of the Earth rect) on the static
  /// Earth — used for the completion beams to every district.
  Vector2 hotspotWorld(double xf, double yf) =>
      position + Vector2((xf - 0.5) * size.x * scale.x, (yf - 0.5) * size.y * scale.y);
}
