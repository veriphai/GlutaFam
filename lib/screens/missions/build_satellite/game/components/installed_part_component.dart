// A part that has been locked into its slot. Sized + anchored from SlotConfig,
// added as a child of the body so it hovers with it. On mount it plays its
// part-specific deployment animation.

import 'dart:math' as math;

import 'package:flame/components.dart';

import '../../config/part_catalog.dart';
import '../../config/slot_config.dart';
import '../build_satellite_game.dart';
import '../effects/deployment_animations.dart';

class InstalledPartComponent extends SpriteComponent
    with HasGameReference<BuildSatelliteGame> {
  InstalledPartComponent({
    required this.part,
    required this.slot,
    required this.bodySize,
    required Sprite sprite,
    required Vector2 localPosition,
  }) : super(
          sprite: sprite,
          position: localPosition,
          anchor: Anchor(slot.partAnchor.dx, slot.partAnchor.dy),
          angle: slot.finalAngleDeg * math.pi / 180.0,
        ) {
    // WHERE PART SIZE IS DERIVED: width is a fraction of the body width; height
    // preserves the sprite's native aspect ratio.
    final aspect = sprite.srcSize.y / sprite.srcSize.x;
    final w = slot.widthFactor * bodySize.x;
    size = Vector2(w, w * aspect);
  }

  final SatellitePart part;
  final SlotConfig slot;
  final Vector2 bodySize;

  /// Game-space centre of this part (used to anchor deployment effects).
  Vector2 get worldCenter => absoluteCenter;

  @override
  Future<void> onLoad() async {
    // HOW ANIMATIONS ARE TRIGGERED: each installed part kicks off its own
    // deployment sequence as soon as it is mounted.
    playDeployment(this);
  }
}
