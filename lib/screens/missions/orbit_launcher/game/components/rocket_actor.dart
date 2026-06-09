// The rocket. One sprite component that swaps among the V2 rocket art and
// supports two driving modes:
//   • idle  — sits steady on the pad
//   • driven — the game sets position/angle each frame (ascent / arc / tilt)

import 'package:flame/components.dart';

import '../../config/asset_paths.dart';
import '../../config/orbit_tuning.dart';

enum RocketVisual { pad, vertical, tilted, falling, release }

class RocketActor extends SpriteComponent with HasGameReference {
  RocketActor({required this.stage}) : super(anchor: Anchor.center, priority: 60);

  final Vector2 stage;

  final Map<RocketVisual, Sprite> _sprites = {};
  RocketVisual _visual = RocketVisual.pad;

  Vector2 restPosition = Vector2.zero();
  bool idle = true;

  @override
  Future<void> onLoad() async {
    Sprite s(String p) => Sprite(game.images.fromCache(OL.flame(p)));
    _sprites[RocketVisual.pad] = s(OL.rocketPad);
    _sprites[RocketVisual.vertical] = s(OL.rocketVertical);
    _sprites[RocketVisual.tilted] = s(OL.rocketTilted);
    _sprites[RocketVisual.falling] = s(OL.rocketFalling);
    _sprites[RocketVisual.release] = s(OL.rocketRelease);
    setVisual(RocketVisual.pad);
  }

  void setVisual(RocketVisual v) {
    _visual = v;
    final next = _sprites[v];
    if (next == null) return;
    sprite = next;
    final w = stage.x * OT.rocketWidthFactor;
    size = Vector2(w, w * (next.srcSize.y / next.srcSize.x));
  }

  RocketVisual get visual => _visual;

  /// Snap to a resting spot and resume a gentle idle bob.
  void rest(Vector2 at) {
    restPosition = at.clone();
    position = at.clone();
    idle = true;
    angle = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    // The rocket sits steady on the pad (no bob) — PRD wants only a subtle glow.
    if (idle) position = restPosition;
  }
}
