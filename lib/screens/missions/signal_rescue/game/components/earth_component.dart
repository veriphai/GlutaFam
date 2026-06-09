// Earth: the green-island world the ground station sits on, anchored low so its
// upper surface fills the lower play area. (The separate "earth-from-space"
// horizon glow sprite was dropped — additive-blown it read as a halo behind the
// monitor, and the island already grounds the scene. Re-add as a NORMAL-alpha
// backdrop behind the satellite if a "floating above Earth" look is wanted.)

import 'package:flame/components.dart';

import '../../config/signal_tuning.dart';

class EarthComponent extends PositionComponent {
  EarthComponent({required this.globe, required Vector2 stage}) : _stage = stage;

  final Sprite globe;
  final Vector2 _stage;

  late final SpriteComponent _globe;

  @override
  Future<void> onLoad() async {
    final gw = SRTune.earthWidthFactor * _stage.x;
    _globe = SpriteComponent(
      sprite: globe,
      anchor: Anchor.center,
      size: Vector2(gw, gw * globe.srcSize.y / globe.srcSize.x),
      position: Vector2(SRTune.earthCenter.dx * _stage.x, SRTune.earthCenter.dy * _stage.y),
      priority: 1,
    );
    add(_globe);
  }
}
