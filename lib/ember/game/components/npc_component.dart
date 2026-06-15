// Ember — game/components/npc_component.dart
//
// An on-screen tribe member (Elder + tribe). It owns an [AnimatedActor] (the
// programmatic figure by default) and drives its [AnimState] from the bound
// [Npc] doc's state, while smoothly walking the figure toward the doc's grid
// coord (so a re-assigned NPC strolls over rather than teleporting). Mood tints
// a small chip above the head. On tap it reports via [onTapped] so the world
// layer can open dialogue — the base never mutates the sim.
//
// Pathing here is PRESENTATION-only interpolation toward the doc's authoritative
// coord; it does NOT feed back into world state (the sim owns where NPCs are).
// Read-only + tap-report only.

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

import '../../animation/animated_actor.dart';
import '../../art/ember_art.dart';
import '../../art/ember_palette.dart';
import '../../art/sprite_compositor.dart';
import '../../core/enums.dart';
import '../../core/geometry.dart';
import '../../core/ids.dart';
import '../../data/models/npc.dart';
import '../ember_game.dart';
import '../iso/iso_projection.dart';
import '../riverpod_flame_bridge.dart';

/// On-screen NPC bound to an [Npc] doc by id.
class NpcComponent extends PositionComponent
    with HasGameReference<EmberGame>, BridgedComponent, TapCallbacks {
  NpcComponent({
    required this.npcId,
    this.projection = IsoProjection.standard,
  }) : super(anchor: Anchor.bottomCenter);

  final EntityId npcId;
  final IsoProjection projection;

  Npc? _doc;
  AnimatedActor? _actor;

  /// The sprite cutout for this NPC (resolved once at load). When non-null the
  /// figure renders from the sprite (with a subtle idle/walk bob) and the
  /// programmatic [AnimatedActor] is NOT mounted. Null -> programmatic figure.
  SpriteHandle? _sprite;

  /// Facing: +1 faces screen-right, -1 left (sprite is flipped to face travel).
  double _facing = 1.0;

  /// Free-running clock for the sprite idle/walk bob (presentation only).
  double _bobT = 0.0;

  /// Walk-speed in tiles/sec used by the presentation-only interpolation.
  static const double _walkTilesPerSec = 1.6;

  /// Current fractional grid position the figure is standing at (interpolated).
  double _gx = 0;
  double _gy = 0;
  bool _placed = false;

  /// Tap callback the world layer wires (open dialogue). Base never mutates.
  void Function(Npc doc)? onTapped;

  EmberArt get art => game.art;
  EmberPalette get palette => art.palette;

  Npc? get doc => _doc;

  @override
  Future<void> onLoad() async {
    final ActorKind kind =
        (bridge.state.npcById(npcId)?.role == NpcRole.elder)
            ? ActorKind.elder
            : ActorKind.tribe;
    // SPRITE SEAM: prefer a sprite cutout (elder = its sage; tribe = a per-id
    // variety cutout). If the facade serves one, render from the sprite directly
    // and SKIP mounting the programmatic actor. Otherwise fall back to the
    // tweened programmatic figure (e.g. placeholder art, or an unmapped slot).
    _sprite = art.actorSprite(kind, varietyKey: spriteVarietyKey(npcId));
    if (_sprite == null) {
      final AnimatedActor actor = art.actor(kind);
      _actor = actor;
      add(actor.component);
    }
    listenWorld(_sync, fireImmediately: true);
  }

  void _sync() {
    final Npc? next = bridge.state.npcById(npcId);
    if (next == null) {
      removeFromParent();
      return;
    }
    _doc = next;
    if (!_placed) {
      _gx = next.coord.x.toDouble();
      _gy = next.coord.y.toDouble();
      _placed = true;
    }
    _applyAnim(next);
    size = Vector2(projection.tileWidth * 0.6, projection.tileHeight * 1.8);
  }

  void _applyAnim(Npc npc) {
    // While the figure is still walking toward its target we force a walk anim;
    // otherwise mirror the doc's state.
    final bool atTarget = (npc.coord.x - _gx).abs() < 0.02 &&
        (npc.coord.y - _gy).abs() < 0.02;
    final AnimState desired = atTarget ? npc.state : AnimState.walk;
    final AnimatedActor? actor = _actor;
    if (actor != null && actor.current != desired) {
      actor.play(desired,
          loop: desired != AnimState.celebrate && desired != AnimState.fail);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _bobT += dt;
    final Npc? npc = _doc;
    if (npc == null) return;

    // Interpolate fractional grid position toward the authoritative coord.
    final double tx = npc.coord.x.toDouble();
    final double ty = npc.coord.y.toDouble();
    final double dx = tx - _gx;
    final double dy = ty - _gy;
    final double dist = math.sqrt(dx * dx + dy * dy);
    if (dist > 0.001) {
      final double step = _walkTilesPerSec * dt;
      if (step >= dist) {
        _gx = tx;
        _gy = ty;
        _applyAnim(npc); // settle to doc state on arrival.
      } else {
        _gx += dx / dist * step;
        _gy += dy / dist * step;
      }
      // Face the travel direction (project the grid delta to screen-x).
      final double screenDx = (dx - dy) * projection.halfTileWidth;
      if (screenDx.abs() > 0.001) _facing = screenDx >= 0 ? 1.0 : -1.0;
    }

    final Vector2 center = projection.gridToScreenXY(_gx, _gy);
    position = Vector2(center.x, center.y + projection.halfTileHeight);
    priority = projection.depthSortKey(GridCoord(_gx.round(), _gy.round()),
        heightBias: 1);
  }

  /// Whether the figure is still walking toward its target (drives the bob).
  bool get _isWalking {
    final Npc? npc = _doc;
    if (npc == null) return false;
    return (npc.coord.x - _gx).abs() > 0.02 || (npc.coord.y - _gy).abs() > 0.02;
  }

  @override
  void render(Canvas canvas) {
    // Contact shadow FIRST (under the figure) so the NPC reads as standing on
    // the iso grid rather than floating between tiles. Drawn as a flat iso
    // ellipse at the figure's feet (component is bottom-center anchored).
    _drawContactShadow(canvas);
    // SPRITE PATH: draw the cutout at the box bottom-center with a subtle idle/
    // walk bob + facing flip (single static cutout, so anim = a programmatic
    // transform over the one pose, per the brief). The programmatic actor child
    // was not mounted in this mode, so super.render draws no figure.
    final SpriteHandle? sprite = _sprite;
    if (sprite != null) {
      final bool walking = _isWalking;
      final double bob = walking
          ? (math.sin(_bobT * 9.0)).abs() * 2.2
          : math.sin(_bobT * 1.8) * 1.2;
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
    final Npc? npc = _doc;
    if (npc == null) return;
    _drawMoodChip(canvas, npc);
  }

  void _drawContactShadow(Canvas canvas) {
    final double w = size.x;
    final Paint shadow = Paint()
      ..color = palette.shadow.withValues(alpha: 0.40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, size.y - 1),
        width: w * 0.78,
        height: projection.tileHeight * 0.30,
      ),
      shadow,
    );
  }

  void _drawMoodChip(Canvas canvas, Npc npc) {
    final (Color color, String glyph) = switch (npc.mood) {
      NpcMood.happy => (palette.success, '☺'),
      NpcMood.content => (palette.inkSoft, ''),
      NpcMood.uneasy => (palette.warning, '!'),
      NpcMood.cold => (palette.cold, '❄'),
    };
    if (glyph.isEmpty) return; // content = no chip (reduce clutter).
    final double cy = -size.y - 6;
    canvas.drawCircle(Offset(0, cy), 8, Paint()..color = color);
    canvas.drawCircle(
      Offset(0, cy),
      8,
      Paint()
        ..color = palette.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(color: palette.surface, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, cy - tp.height / 2));
  }

  @override
  void onTapDown(TapDownEvent event) {
    final Npc? npc = _doc;
    if (npc == null) return;
    onTapped?.call(npc);
  }
}
