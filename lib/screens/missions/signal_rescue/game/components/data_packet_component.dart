// A single glowing data packet that flies from the dish to the ground station
// along a gentle bowed path, leaving a fading trail, then fires onArrive (where
// the game plays the impact splash + advances transmission progress).

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

class DataPacketComponent extends PositionComponent {
  DataPacketComponent({
    required this.packetSprite,
    required this.trailSprite,
    required this.start,
    required this.end,
    required this.duration,
    required this.diameter,
    required this.onArrive,
  });

  final Sprite packetSprite;
  final Sprite trailSprite;
  final Vector2 start;
  final Vector2 end;
  final double duration;
  final double diameter;
  final void Function(Vector2 at) onArrive;

  late final SpriteComponent _packet;
  double _t = 0;
  double _lastTrail = 0;
  bool _done = false;

  // a single control point bowing the path slightly off the straight line
  late final Vector2 _ctrl;

  @override
  Future<void> onLoad() async {
    final mid = (start + end) / 2;
    final dir = (end - start);
    final perp = Vector2(-dir.y, dir.x).normalized();
    _ctrl = mid + perp * dir.length * 0.12;

    _packet = SpriteComponent(
      sprite: packetSprite,
      anchor: Anchor.center,
      size: Vector2.all(diameter),
      position: start.clone(),
      priority: 60,
    )..paint.blendMode = BlendMode.plus;
    add(_packet);
  }

  Vector2 _pointAt(double f) {
    final u = 1 - f;
    return start * (u * u) + _ctrl * (2 * u * f) + end * (f * f);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_done) return;
    _t += dt;
    final f = (_t / duration).clamp(0.0, 1.0);
    final pos = _pointAt(f);
    _packet.position = pos;
    _packet.angle += dt * 6; // spin
    _packet.scale = Vector2.all(0.85 + 0.15 * math.sin(_t * 12));

    if (f - _lastTrail > 0.06) {
      _lastTrail = f;
      _spawnTrail(pos);
    }
    if (f >= 1.0) {
      _done = true;
      onArrive(end.clone());
      _packet.removeFromParent();
      removeFromParent();
    }
  }

  void _spawnTrail(Vector2 at) {
    final t = SpriteComponent(
      sprite: trailSprite,
      anchor: Anchor.center,
      size: Vector2(diameter * 1.1, diameter * 0.5),
      position: at.clone(),
      priority: 59,
    )..paint.blendMode = BlendMode.plus;
    t.opacity = 0.7;
    parent?.add(t);
    // fade + shrink, then remove
    t.add(_TrailFade());
  }
}

/// Fades and removes a trail puff over ~0.4s.
class _TrailFade extends Component {
  double _t = 0;
  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final p = parent;
    if (p is SpriteComponent) {
      p.opacity = (0.7 * (1 - _t / 0.4)).clamp(0.0, 0.7);
      p.scale = Vector2.all((1 - _t / 0.4 * 0.5).clamp(0.5, 1.0));
      if (_t >= 0.4) p.removeFromParent();
    }
  }
}
