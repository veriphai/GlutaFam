// Ember — game/components/player_component.dart
//
// The PLAYER AVATAR on the iso world — the headline of the exploration layer. It
// MIRRORS [NpcComponent]'s construction (an [AnimatedActor] figure, bottom-center
// anchor, contact-shadow-via-actor, fractional grid coord projected through
// IsoProjection, depthSortKey, AnimState.walk/idle) but instead of interpolating
// toward a sim-owned coord it is DRIVEN every frame by the joystick vector the
// game publishes (game.joystick): the kid's finger moves the figure in the SAME
// render frame.
//
// CRITICAL CONTRACT: the avatar is PURE PRESENTATION. It NEVER enters
// EmberWorldState — its position lives only in this component (fractional _gx/_gy)
// and is seeded from the village site once. It dispatches NO Intents and mutates
// no world state; it only READS the tile grid (through the bridge) to clamp its
// own movement to walkable ground. Determinism is untouched (no clock/random; the
// figure animates from Flame's dt loop like every other actor).
//
// Movement model (same-frame, dt-correct):
//   * the joystick vector is SCREEN-space (x right, y down, 0..1);
//   * it is mapped through the inverse iso projection to a GRID-space direction so
//     "up on the stick" walks up the diamond;
//   * the figure steps by dir * speed * dt, then each axis is independently
//     clamped so it slides along walls (water/off-map) instead of sticking;
//   * facing + walk/idle anim follow the motion magnitude.

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../animation/animated_actor.dart';
import '../../art/ember_art.dart';
import '../../art/sprite_compositor.dart';
import '../../core/enums.dart';
import '../../core/geometry.dart';
import '../../data/models/tile.dart';
import '../ember_game.dart';
import '../iso/iso_projection.dart';
import '../riverpod_flame_bridge.dart';

/// The kid's on-screen hero figure. Joystick-driven, walkable-clamped, read-only.
class PlayerComponent extends PositionComponent
    with HasGameReference<EmberGame>, BridgedComponent {
  PlayerComponent({
    this.projection = IsoProjection.standard,
    this.speedTilesPerSec = 3.2,
  }) : super(anchor: Anchor.bottomCenter);

  final IsoProjection projection;

  /// How fast the avatar walks across the grid at full stick deflection.
  final double speedTilesPerSec;

  AnimatedActor? _actor;

  /// The hero sprite cutout (resolved once at load). When non-null the avatar
  /// renders from the sprite (subtle idle/walk bob + facing flip) and the
  /// programmatic hero figure is NOT mounted. Null -> programmatic hero.
  SpriteHandle? _sprite;

  /// Free-running clock for the sprite idle/walk bob (presentation only).
  double _bobT = 0.0;

  /// Fractional grid position the figure stands at (the avatar's only "state").
  double _gx = 0;
  double _gy = 0;
  bool _seeded = false;

  /// Last non-zero facing (so the idle figure keeps looking where it walked).
  /// +1 faces screen-right, -1 faces screen-left (mirrors the figure).
  double _facing = 1.0;

  EmberArt get art => game.art;

  /// The avatar's current fractional grid coordinate (read by the proximity
  /// resolver + camera follow). Presentation-only — never written to the sim.
  double get gx => _gx;
  double get gy => _gy;
  GridCoord get cell => GridCoord(_gx.round(), _gy.round());

  /// Whether the avatar has been seeded at the village site yet (false for the
  /// frame or two before onLoad runs). The camera-follow waits for this so it
  /// doesn't lurch toward the (0,0) origin before the hero is placed.
  bool get isSeeded => _seeded;

  /// True while the stick is pushing the figure (used by the resolver to decide
  /// "stopped beside the Elder -> speak").
  bool _moving = false;
  bool get isMoving => _moving;

  @override
  Future<void> onLoad() async {
    size = Vector2(projection.tileWidth * 0.62, projection.tileHeight * 1.9);
    // SPRITE SEAM: prefer the hero cutout. If the facade serves one, render from
    // the sprite directly (subtle bob + facing flip) and SKIP mounting the
    // programmatic hero figure; else fall back to the programmatic hero.
    _sprite = art.playerSprite();
    if (_sprite == null) {
      final AnimatedActor actor =
          art.playerActor(reduceMotion: game.disableAnimations);
      _actor = actor;
      add(actor.component);
    }
    // Seed at the village site (read once; never feeds back into the sim).
    _seedAtSite();
    _applyProjection();
  }

  void _seedAtSite() {
    if (_seeded) return;
    final GridCoord site = bridge.state.village.siteTile;
    _gx = site.x.toDouble();
    _gy = site.y.toDouble();
    _seeded = true;
  }

  /// DEBUG-ONLY: warp the avatar's (presentation-only) position to [cell]. Used
  /// EXCLUSIVELY by the EMBER_TOUR self-drive to place the hero exactly beside a
  /// target before verifying a proximity seam (so the resolver surfaces the right
  /// prompt deterministically for capture). It writes ONLY this component's
  /// fractional coord — never EmberWorldState — so determinism is untouched.
  void debugWarpTo(GridCoord cell) {
    _gx = cell.x.toDouble();
    _gy = cell.y.toDouble();
    _seeded = true;
    _applyProjection();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _bobT += dt;
    if (!bridge.isReady) return;

    final Vector2 stick = game.joystick; // screen-space, y-down, 0..1
    final double mag = stick.length;
    final bool moving = mag > 0.02;

    if (moving) {
      // Map the screen-space stick direction into grid-space (inverse iso, no
      // half-cell bias — this is a DIRECTION, not a point). screenToGrid forward:
      //   sx = (gx-gy)*hw ; sy = (gx+gy)*hh  ->  invert for a delta.
      final double a = stick.x / projection.halfTileWidth;
      final double b = stick.y / projection.halfTileHeight;
      double dgx = (a + b) / 2;
      double dgy = (b - a) / 2;
      // Re-normalize the grid-space direction then scale by stick magnitude so
      // diagonal screen pushes don't walk faster than cardinal ones.
      final double gl = math.sqrt(dgx * dgx + dgy * dgy);
      if (gl > 0.0001) {
        dgx = dgx / gl * mag;
        dgy = dgy / gl * mag;
      }
      final double step = speedTilesPerSec * dt;
      _moveClamped(dgx * step, dgy * step);

      // Face by screen-x of the motion (project the grid delta back to screen).
      final double screenDx = (dgx - dgy) * projection.halfTileWidth;
      if (screenDx.abs() > 0.001) _facing = screenDx >= 0 ? 1.0 : -1.0;
    }

    _moving = moving;
    _applyAnim(moving);
    _applyProjection();
  }

  @override
  void render(Canvas canvas) {
    // SPRITE PATH: draw a contact shadow + the hero cutout at the box bottom-
    // center with a subtle idle/walk bob and a facing flip. The programmatic hero
    // child was not mounted in this mode, so super.render draws no figure.
    final SpriteHandle? sprite = _sprite;
    if (sprite != null) {
      final Paint shadow = Paint()
        ..color = const Color(0x66000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.x / 2, size.y - 1),
          width: size.x * 0.7,
          height: projection.tileHeight * 0.28,
        ),
        shadow,
      );
      final double bob = _moving
          ? (math.sin(_bobT * 9.5)).abs() * 2.4
          : (game.disableAnimations ? 0.0 : math.sin(_bobT * 1.9) * 1.3);
      canvas.save();
      canvas.translate(size.x / 2, size.y - bob);
      if (_facing < 0) canvas.scale(-1.0, 1.0);
      SpriteCompositor.drawBottomCenter(
        canvas,
        sprite,
        tileWidth: projection.tileWidth,
      );
      canvas.restore();
    }
    super.render(canvas);
  }

  /// Step each axis independently and reject the part that would land on a
  /// non-walkable cell, so the figure SLIDES along water/edges instead of
  /// jamming. Movement is fractional; we test the destination cell (rounded).
  void _moveClamped(double ddx, double ddy) {
    final double tryX = _gx + ddx;
    if (_walkable(tryX, _gy)) _gx = tryX;
    final double tryY = _gy + ddy;
    if (_walkable(_gx, tryY)) _gy = tryY;
  }

  /// A cell is walkable if it is on the (explored) grid and not deep water. The
  /// avatar is presentation-only, so it ignores placeable occupancy (it can walk
  /// up beside a hearth/tree to interact) — only terrain + bounds gate it.
  bool _walkable(double fx, double fy) {
    final GridCoord c = GridCoord(fx.round(), fy.round());
    final Tile? t = bridge.state.tiles.at(c);
    if (t == null) return false; // off-map.
    if (!t.explored) return false; // unrevealed region.
    if (t.terrain == TerrainType.water) return false; // can't wade the river.
    return true;
  }

  void _applyAnim(bool moving) {
    final AnimState desired = moving ? AnimState.walk : AnimState.idle;
    final AnimatedActor? actor = _actor;
    if (actor != null && actor.current != desired) {
      actor.play(desired);
    }
  }

  void _applyProjection() {
    final Vector2 center = projection.gridToScreenXY(_gx, _gy);
    position = Vector2(center.x, center.y + projection.halfTileHeight);
    // Mirror the figure to face its travel direction. The actor's component is a
    // PositionComponent anchored bottom-center; pinning it at the parent's
    // bottom-center and scaling x by +-1 flips it cleanly in place.
    final AnimatedActor? actor = _actor;
    if (actor != null && actor.component is PositionComponent) {
      final PositionComponent fig = actor.component as PositionComponent;
      fig.anchor = Anchor.bottomCenter;
      fig.position = Vector2(size.x / 2, size.y);
      fig.scale = Vector2(_facing, 1.0);
    }
    // Sort just above the tile the feet stand on (heightBias 1, like the NPC).
    priority = projection.depthSortKey(cell, heightBias: 1);
  }
}
