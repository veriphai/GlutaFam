// The V2 backdrop + geometry source of truth.
//
// Two regimes that crossfade:
//   • GROUND — NASA launchpad (cover-fit) + two parallax cloud layers that
//     scroll DOWN as the rocket climbs (setAscent).
//   • SPACE  — atmosphere→space gradient + full Earth globe (centred), used for
//     the high-altitude outcomes + orbit success.
//
// The game reads globeCenter / globeRadius / orbitRadius / rocketPad off this.

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

import '../../config/asset_paths.dart';
import '../../config/orbit_tuning.dart';

class StageBackdrop extends PositionComponent {
  StageBackdrop({required this.stage, required this.spriteOf});

  final Vector2 stage;
  final Sprite Function(String flamePath) spriteOf;

  late final SpriteComponent _launchpad;
  late final SpriteComponent _space;
  late final SpriteComponent _cloudFar;
  late final SpriteComponent _cloudNear;
  late final SpriteComponent _globe;

  bool _inSpace = false;
  bool get inSpace => _inSpace;

  // ── geometry ────────────────────────────────────────────────────────────────
  Vector2 get globeCenter => Vector2(stage.x * OT.globeCenter.dx, stage.y * OT.globeCenter.dy);
  double get globeRadius => stage.x * OT.globeRadiusFactor;
  double get orbitRadius => globeRadius * OT.orbitRadiusMul;
  Vector2 get rocketPad => Vector2(stage.x * OT.rocketPadCenter.dx, stage.y * OT.rocketPadCenter.dy);
  Vector2 get straightApex => Vector2(stage.x * OT.straightApex.dx, stage.y * OT.straightApex.dy);

  // cover-fit a sprite to the stage
  Vector2 _cover(Sprite s) {
    final scale = (stage.x / s.srcSize.x) > (stage.y / s.srcSize.y)
        ? stage.x / s.srcSize.x
        : stage.y / s.srcSize.y;
    return Vector2(s.srcSize.x * scale, s.srcSize.y * scale);
  }

  @override
  Future<void> onLoad() async {
    final pad = spriteOf(OL.flame(OL.bgLaunchpad));
    _launchpad = SpriteComponent(
      sprite: pad,
      anchor: Anchor.center,
      size: _cover(pad),
      position: stage / 2,
      priority: 0,
    );
    add(_launchpad);

    final space = spriteOf(OL.flame(OL.bgSpace));
    _space = SpriteComponent(
      sprite: space,
      anchor: Anchor.center,
      size: _cover(space),
      position: stage / 2,
      priority: 1,
    )..opacity = 0;
    add(_space);

    final globe = spriteOf(OL.flame(OL.earthGlobe));
    final gd = globeRadius * 2;
    _globe = SpriteComponent(
      sprite: globe,
      anchor: Anchor.center,
      size: Vector2(gd, gd * (globe.srcSize.y / globe.srcSize.x)),
      position: globeCenter,
      priority: 2,
    )..opacity = 0;
    add(_globe);

    _cloudFar = _cloudLayer(OL.cloudFar, OT.cloudFarWidthFactor, OT.cloudFarRestY, priority: 6);
    _cloudNear = _cloudLayer(OL.cloudNear, OT.cloudNearWidthFactor, OT.cloudNearRestY, priority: 8);
    add(_cloudFar);
    add(_cloudNear);
  }

  SpriteComponent _cloudLayer(String path, double widthFactor, double restY, {required int priority}) {
    final s = spriteOf(OL.flame(path));
    final w = stage.x * widthFactor;
    return SpriteComponent(
      sprite: s,
      anchor: Anchor.center,
      size: Vector2(w, w * (s.srcSize.y / s.srcSize.x)),
      position: Vector2(stage.x * 0.5, stage.y * restY),
      priority: priority,
    );
  }

  /// Parallax scroll for the ground climb: clouds slide DOWN (near faster),
  /// launchpad drifts down slowly. [a] = ascent progress 0..1.
  void setAscent(double a) {
    _cloudFar.position = Vector2(stage.x * 0.5, stage.y * (OT.cloudFarRestY + a * OT.cloudFarScroll));
    _cloudNear.position = Vector2(stage.x * 0.5, stage.y * (OT.cloudNearRestY + a * OT.cloudNearScroll));
    _launchpad.position = Vector2(stage.x * 0.5, stage.y * (0.5 + a * 0.25));
  }

  void resetGround({bool animate = true}) {
    _inSpace = false;
    final d = animate ? 0.4 : 0.0;
    setAscent(0);
    _fade(_launchpad, 1, d);
    _fade(_cloudFar, 1, d);
    _fade(_cloudNear, 1, d);
    _fade(_space, 0, d);
    _fade(_globe, 0, d);
  }

  /// Crossfade to the space regime (atmosphere + globe). [showGlobe] false keeps
  /// just the gradient (used for low fails that stay near the sky).
  void toSpace({bool showGlobe = true, bool animate = true}) {
    _inSpace = true;
    final d = animate ? OT.spaceCrossfade : 0.0;
    _fade(_launchpad, 0, d);
    _fade(_cloudFar, 0, d);
    _fade(_cloudNear, 0, d);
    _fade(_space, 1, d);
    _fade(_globe, showGlobe ? 1 : 0, d);
    if (showGlobe) {
      _globe.scale = Vector2.all(0.92);
      _globe.add(ScaleEffect.to(Vector2.all(1), EffectController(duration: d, curve: Curves.easeOutCubic)));
    }
  }

  void _fade(SpriteComponent c, double to, double d) {
    if (d <= 0) {
      c.opacity = to;
      return;
    }
    c.add(OpacityEffect.to(to, EffectController(duration: d, curve: Curves.easeInOut)));
  }
}
