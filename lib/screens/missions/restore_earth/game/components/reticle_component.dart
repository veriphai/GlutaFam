// The aiming reticle. Follows the drag; swaps to the "active" sprite when near
// the live hotspot (PRD §13.3). The snap-ring + magnetic ease are handled by the
// game (it owns the hotspot position).

import 'package:flame/components.dart';

import '../../config/asset_paths.dart';
import '../restore_earth_game.dart';

class ReticleComponent extends SpriteComponent with HasGameReference<RestoreEarthGame> {
  ReticleComponent({required double diameter})
      : super(size: Vector2.all(diameter), anchor: Anchor.center);

  bool _active = false;

  @override
  Future<void> onLoad() async {
    sprite = game.sprite(RE.flame(RE.reticle));
  }

  void setActive(bool v) {
    if (v == _active) return;
    _active = v;
    sprite = game.sprite(RE.flame(v ? RE.reticleActive : RE.reticle));
  }
}
