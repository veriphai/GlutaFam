// Ember — game/world/world_root.dart
//
// The Flame [World] that composes the whole iso scene from the world snapshot:
//   * the ground (IsoTileMapComponent),
//   * one ResourceNodeComponent per node, one PlaceableComponent per placeable,
//     one NpcComponent per npc (reconciled against the snapshot — added when a
//     doc appears, auto-removed by the component when its doc vanishes),
//   * the night scrim, flood overlay, and predator (env feedback),
//   * a slot the placement controller drops its ghost into.
//
// Depth sorting: every entity component sets its own `priority` from
// IsoProjection.depthSortKey(coord), so Flame's component ordering paints the iso
// scene back-to-front without manual z juggling. The root only reconciles the
// SET of components; each component owns its own position/priority/repaint.
//
// It subscribes to the GameBridge world snapshot (the single sim touch-point);
// it never mutates state. Leaf-supplied placeable subclasses are injected via a
// `placeableFactory` so the fire/tools/shelter leaves can render bespoke visuals
// without the root importing them (dir-lock preserved).

import 'package:flame/components.dart';

import '../../core/ids.dart';
import '../../data/models/npc.dart';
import '../../data/models/placeable.dart';
import '../../data/models/resource_node.dart';
import '../components/discovery_node_component.dart';
import '../components/flood_overlay_component.dart';
import '../components/night_overlay_component.dart';
import '../components/npc_component.dart';
import '../components/placeable_component.dart';
import '../components/player_component.dart';
import '../components/predator_component.dart';
import '../components/resource_node_component.dart';
import '../ember_game.dart';
import '../exploration/discovery_nodes.dart';
import '../iso/iso_projection.dart';
import '../iso/iso_tile_map_component.dart';
import '../riverpod_flame_bridge.dart';

/// A leaf-supplied builder for a placeable's on-screen component, so leaves can
/// subclass [PlaceableComponent] for bespoke visuals. Returns null to fall back
/// to the generic base component.
typedef PlaceableComponentFactory = PlaceableComponent? Function(
  Placeable doc,
  IsoProjection projection,
);

/// The iso world root.
class WorldRoot extends World
    with HasGameReference<EmberGame>, BridgedComponent {
  WorldRoot({
    this.projection = IsoProjection.standard,
    this.placeableFactory,
    this.onPlaceableTapped,
    this.onNpcTapped,
  });

  final IsoProjection projection;

  /// Optional leaf factory for bespoke placeable visuals (dir-lock seam).
  final PlaceableComponentFactory? placeableFactory;

  /// Routed when a placeable is tapped (e.g. open info / tend / begin move).
  final void Function(Placeable doc)? onPlaceableTapped;

  /// Routed when an NPC is tapped (e.g. open dialogue).
  final void Function(Npc doc)? onNpcTapped;

  // Live component registries keyed by entity id.
  final Map<EntityId, PlaceableComponent> _placeables =
      <EntityId, PlaceableComponent>{};
  final Map<EntityId, ResourceNodeComponent> _nodes =
      <EntityId, ResourceNodeComponent>{};
  final Map<EntityId, NpcComponent> _npcs = <EntityId, NpcComponent>{};

  late final IsoTileMapComponent _tileMap =
      IsoTileMapComponent(projection: projection);

  /// The player avatar (the exploration hero). Mounted once; the game drives it
  /// from the joystick + reads its position for camera-follow + proximity.
  late final PlayerComponent _player = PlayerComponent(projection: projection);

  /// The three walk-up discovery node markers (each self-hides until its concept
  /// unlocks). Exposed so the game's ProximityResolver can target/focus them.
  final List<DiscoveryNodeComponent> _discoveries = <DiscoveryNodeComponent>[];

  @override
  Future<void> onLoad() async {
    await add(_tileMap);
    await add(FloodOverlayComponent(projection: projection));
    await add(NightOverlayComponent(projection: projection));
    await add(PredatorComponent(projection: projection));

    // The walk-up discovery nodes (added before the avatar so the avatar's
    // priority-sorted figure can pass in front of a far ring naturally).
    for (final DiscoveryNodeDef def in kDiscoveryNodes) {
      final DiscoveryNodeComponent c =
          DiscoveryNodeComponent(def: def, projection: projection);
      _discoveries.add(c);
      await add(c);
    }

    // The player avatar — the headline of the exploration layer.
    await add(_player);

    // Reconcile entity components whenever the snapshot changes.
    listenWorld(_reconcile, fireImmediately: true);
  }

  /// The tile map (exposed so the placement controller can drive its highlight
  /// sets directly when desired).
  IsoTileMapComponent get tileMap => _tileMap;

  /// The player avatar component (the game reads its position + drives it).
  PlayerComponent get player => _player;

  /// The live discovery node components (for the proximity resolver).
  List<DiscoveryNodeComponent> get discoveries =>
      List<DiscoveryNodeComponent>.unmodifiable(_discoveries);

  // ===========================================================================
  // Reconciliation
  // ===========================================================================

  void _reconcile() {
    final dynamic s = bridge.state;
    _reconcileNodes(s.nodes as List<ResourceNode>);
    _reconcilePlaceables(s.placeables as List<Placeable>);
    _reconcileNpcs(s.npcs as List<Npc>);
  }

  void _reconcileNodes(List<ResourceNode> nodes) {
    final Set<EntityId> live = <EntityId>{};
    for (final ResourceNode n in nodes) {
      live.add(n.id);
      if (_nodes.containsKey(n.id)) continue;
      final ResourceNodeComponent c =
          ResourceNodeComponent(nodeId: n.id, projection: projection);
      _nodes[n.id] = c;
      add(c);
    }
    _pruneMissing(_nodes, live);
  }

  void _reconcilePlaceables(List<Placeable> placeables) {
    final Set<EntityId> live = <EntityId>{};
    for (final Placeable p in placeables) {
      live.add(p.id);
      if (_placeables.containsKey(p.id)) continue;
      final PlaceableComponent c =
          placeableFactory?.call(p, projection) ??
              PlaceableComponent(placeableId: p.id, projection: projection);
      c.onTapped = onPlaceableTapped;
      _placeables[p.id] = c;
      add(c);
    }
    _pruneMissing(_placeables, live);
  }

  void _reconcileNpcs(List<Npc> npcs) {
    final Set<EntityId> live = <EntityId>{};
    for (final Npc n in npcs) {
      live.add(n.id);
      if (_npcs.containsKey(n.id)) continue;
      final NpcComponent c = NpcComponent(npcId: n.id, projection: projection)
        ..onTapped = onNpcTapped;
      _npcs[n.id] = c;
      add(c);
    }
    _pruneMissing(_npcs, live);
  }

  /// Removes registry entries whose docs are gone (the components self-remove
  /// on their next sync, but we drop the map entry now to avoid leaks).
  void _pruneMissing<T extends Component>(
    Map<EntityId, T> registry,
    Set<EntityId> live,
  ) {
    final List<EntityId> dead = <EntityId>[
      for (final EntityId id in registry.keys)
        if (!live.contains(id)) id,
    ];
    for (final EntityId id in dead) {
      registry.remove(id)?.removeFromParent();
    }
  }
}
