// Ember — game/exploration/proximity_resolver.dart
//
// The PROXIMITY RESOLVER: each frame it finds the nearest INTERACTABLE within ~1
// tile of the player avatar (an NPC, a resource node, or a discovery node) and
// publishes it as a [ProximityTarget] on a plain [ValueNotifier] the Flutter
// world_screen watches. The screen renders a floating prompt over the target and
// resolves it through the EXISTING seams:
//   * NPC       -> ElderDialogue.show (Flutter-owned). Also auto-opens once when
//                  the avatar STOPS beside the NPC (they walk up, then "speak").
//   * resource  -> dispatch GatherIntent (reuses the resource node's +N pop).
//   * discovery -> host.launch(activityId) (the prereq cascade is re-checked).
// Taps on the entities still work as a fallback (unchanged component TapCallbacks).
//
// WHY a notifier (not direct calls): dialogue + host.launch are Flutter-side and
// owned by world_screen; the resolver lives in the Flame game. So it only computes
// "nearest + type + world anchor" and lets world_screen react — exactly the wiring
// the brief asks for. It dispatches GatherIntent itself (that IS a game-side seam,
// like the resource component's own tap), but never opens UI.
//
// Determinism: read-only over the world snapshot + the avatar's presentation-only
// position; no clock/random; the avatar never enters EmberWorldState.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../core/enums.dart';
import '../../core/geometry.dart';
import '../../data/models/npc.dart';
import '../../data/models/resource_node.dart';
import '../../state/intents.dart';
import '../components/discovery_node_component.dart';
import '../components/player_component.dart';
import '../game_bridge.dart';

/// What kind of thing the avatar is standing next to.
enum ProximityKind { npc, resource, discovery }

/// A resolved nearest-interactable the world_screen reacts to.
@immutable
class ProximityTarget {
  const ProximityTarget({
    required this.kind,
    required this.entityId,
    required this.worldX,
    required this.worldY,
    required this.label,
    this.dialogueId,
    this.activityId,
  });

  final ProximityKind kind;

  /// The entity id (node/npc id, or activityId for a discovery).
  final String entityId;

  /// The target's WORLD-space anchor (so the screen can place a prompt over it).
  final double worldX;
  final double worldY;

  /// The short imperative the prompt shows ("Talk", "Gather wood", "Make Fire").
  final String label;

  /// For NPC targets: the dialogue tree to open.
  final String? dialogueId;

  /// For discovery targets: the activity to launch.
  final String? activityId;

  bool sameAs(ProximityTarget? o) =>
      o != null && o.kind == kind && o.entityId == entityId;
}

/// Computes + publishes the nearest interactable to the avatar each frame.
class ProximityResolver {
  ProximityResolver({
    required this.bridge,
    required this.player,
    required this.discoveryNodesProvider,
  });

  final GameBridge bridge;
  final PlayerComponent player;

  /// Reads the live discovery node components each frame. Passed as a getter (not
  /// a captured list) because the iso world populates them in its own onLoad,
  /// AFTER this resolver is constructed in the game's onLoad.
  final List<DiscoveryNodeComponent> Function() discoveryNodesProvider;

  /// Interact radius in tiles (euclidean, fractional avatar coord -> entity cell).
  static const double _rangeTiles = 1.25;

  /// The current nearest target (null when nothing is in range). The world_screen
  /// watches this to show/hide the floating prompt.
  final ValueNotifier<ProximityTarget?> target =
      ValueNotifier<ProximityTarget?>(null);

  /// A one-shot signal: the id of an NPC the avatar JUST stopped beside (so
  /// world_screen auto-opens its dialogue exactly once). Cleared after read.
  final ValueNotifier<ProximityTarget?> autoTalk =
      ValueNotifier<ProximityTarget?>(null);

  /// Tracks whether the avatar was moving last frame (to detect a fresh stop).
  bool _wasMoving = true;

  /// The NPC id we last auto-opened for, so we don't re-open every still frame.
  String? _lastAutoTalkId;

  /// Recompute the nearest interactable. Call once per frame from game.update.
  void update() {
    if (!bridge.isReady) {
      _publish(null);
      return;
    }
    final double px = player.gx;
    final double py = player.gy;

    ProximityTarget? best;
    double bestDist = double.infinity;

    // ---- Discovery nodes (highest priority: the headline interaction) ----
    DiscoveryNodeComponent? bestDiscovery;
    for (final DiscoveryNodeComponent d in discoveryNodesProvider()) {
      d.focused = false; // reset; re-set below for the chosen one.
      if (!d.isMounted) continue;
      final GridCoord c = d.cell;
      // Only consider AVAILABLE nodes (component hides itself otherwise; we
      // re-check via the concept gate so a hidden ring is never a target).
      final concept = bridge.state.conceptById(d.def.concept);
      final bool available =
          (concept?.unlocked ?? false) && !(concept?.completed ?? false);
      if (!available) continue;
      final double dist = _dist(px, py, c);
      if (dist <= _rangeTiles && dist < bestDist) {
        bestDist = dist;
        bestDiscovery = d;
        best = _discoveryTarget(d, c);
      }
    }
    if (bestDiscovery != null) bestDiscovery.focused = true;

    // ---- NPCs ----
    for (final Npc n in bridge.state.npcs) {
      final double dist = _dist(px, py, n.coord);
      if (dist <= _rangeTiles && dist < bestDist) {
        // NPCs without a dialogue tree are not interactable targets.
        if (n.dialogueId == null) continue;
        bestDist = dist;
        best = _npcTarget(n);
      }
    }

    // ---- Resource nodes (skip depleted) ----
    for (final ResourceNode r in bridge.state.nodes) {
      if (r.isDepleted) continue;
      final double dist = _dist(px, py, r.coord);
      if (dist <= _rangeTiles && dist < bestDist) {
        bestDist = dist;
        best = _resourceTarget(r);
      }
    }

    _publish(best);
    _maybeAutoTalk(best);
  }

  /// Resolve the CURRENT target by its native seam. Called by world_screen when
  /// the floating prompt (or a tap fallback) is confirmed for a GATHER target —
  /// dialogue + launch are handled Flutter-side by world_screen itself.
  void confirmGather() {
    final ProximityTarget? t = target.value;
    if (t == null || t.kind != ProximityKind.resource) return;
    bridge.dispatch(GatherIntent(t.entityId));
  }

  // ---- target builders -------------------------------------------------

  ProximityTarget _discoveryTarget(DiscoveryNodeComponent d, GridCoord c) {
    return ProximityTarget(
      kind: ProximityKind.discovery,
      entityId: d.def.activityId,
      worldX: d.position.x,
      worldY: d.position.y - 60, // above the ring/glyph.
      label: d.def.shortLabel,
      activityId: d.def.activityId,
    );
  }

  ProximityTarget _npcTarget(Npc n) {
    final double wx = (n.coord.x - n.coord.y) * _hw;
    final double wy = (n.coord.x + n.coord.y) * _hh;
    final String label = n.role == NpcRole.elder ? 'Talk to Elder' : 'Talk';
    return ProximityTarget(
      kind: ProximityKind.npc,
      entityId: n.id,
      worldX: wx,
      worldY: wy - 70,
      label: label,
      dialogueId: n.dialogueId,
    );
  }

  ProximityTarget _resourceTarget(ResourceNode r) {
    final double wx = (r.coord.x - r.coord.y) * _hw;
    final double wy = (r.coord.x + r.coord.y) * _hh;
    final String label = switch (r.type) {
      ResourceType.wood => 'Gather wood',
      ResourceType.stone => 'Gather stone',
      ResourceType.food => 'Gather food',
      ResourceType.hide => 'Gather hide',
    };
    return ProximityTarget(
      kind: ProximityKind.resource,
      entityId: r.id,
      worldX: wx,
      worldY: wy - 56,
      label: label,
    );
  }

  // ---- internals -------------------------------------------------------

  void _publish(ProximityTarget? next) {
    final ProximityTarget? cur = target.value;
    final bool changed = next == null
        ? cur != null
        : !next.sameAs(cur) ||
            cur == null ||
            // also republish if the anchor moved noticeably (entity walked).
            (next.worldX - cur.worldX).abs() > 1 ||
            (next.worldY - cur.worldY).abs() > 1;
    if (changed) target.value = next;
  }

  /// When the avatar STOPS this frame beside an NPC target, fire the one-shot so
  /// world_screen opens that NPC's dialogue once (the "walk up, then speak" beat).
  void _maybeAutoTalk(ProximityTarget? best) {
    final bool moving = player.isMoving;
    final bool justStopped = _wasMoving && !moving;
    _wasMoving = moving;

    if (best != null && best.kind == ProximityKind.npc) {
      if (justStopped && _lastAutoTalkId != best.entityId) {
        _lastAutoTalkId = best.entityId;
        autoTalk.value = best;
      }
    } else {
      // Left the NPC's side -> allow a future auto-open next time we walk back.
      _lastAutoTalkId = null;
    }
  }

  /// Marks the auto-talk one-shot consumed (called by world_screen after it opens
  /// the dialogue, so the same signal isn't re-handled).
  void consumeAutoTalk() => autoTalk.value = null;

  double get _hw => player.projection.halfTileWidth;
  double get _hh => player.projection.halfTileHeight;

  double _dist(double px, double py, GridCoord c) {
    final double dx = px - c.x;
    final double dy = py - c.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  void dispose() {
    target.dispose();
    autoTalk.dispose();
  }
}
