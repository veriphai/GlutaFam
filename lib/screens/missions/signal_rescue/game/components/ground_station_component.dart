// The ground station on Earth: a dish that swaps inactive / active / alert art,
// with a clean programmatic green range ring (GlowRing, no chevrons) that is
// HIDDEN out of range and blooms + pulses green when the satellite is in the
// communication window — so "in range!" is a clear event, not a stray halo.

import 'dart:ui';

import 'package:flame/components.dart';

import '../../config/signal_tuning.dart';
import 'glow_ring.dart';

enum StationVisual { inactive, active, alert }

class GroundStationComponent extends PositionComponent {
  GroundStationComponent({
    required this.inactive,
    required this.active,
    required this.alert,
    required Vector2 stage,
  }) : _stage = stage;

  final Sprite inactive;
  final Sprite active;
  final Sprite alert;
  final Vector2 _stage;

  late final SpriteComponent _dish;
  late final GlowRing _ring;

  StationVisual _visual = StationVisual.inactive;

  @override
  Future<void> onLoad() async {
    final w = SRTune.groundStationWidthFactor * _stage.x;
    size = Vector2(w, w * inactive.srcSize.y / inactive.srcSize.x);
    anchor = Anchor.bottomCenter;

    _ring = GlowRing(
      radius: SRTune.rangeRingRadiusFactor * _stage.x,
      color: const Color(0xFF49E06B),
      pulse: true,
    )
      ..position = Vector2(size.x / 2, size.y * 0.86)
      ..priority = 0;

    _dish = SpriteComponent(
      sprite: inactive,
      anchor: Anchor.bottomCenter,
      size: size.clone(),
      position: Vector2(size.x / 2, size.y),
      priority: 1,
    );

    add(_ring);
    add(_dish);
  }

  void setVisual(StationVisual v) {
    if (v == _visual) return;
    _visual = v;
    _dish.sprite = switch (v) {
      StationVisual.inactive => inactive,
      StationVisual.active => active,
      StationVisual.alert => alert,
    };
  }

  void setInRange(bool inRange) => _ring.show(inRange);
}
