// Ember — sim/systems/resource_system.dart
//
// Two responsibilities, both pure + deterministic:
//   1) PASSIVE (per tick): regrow nodes by regrowRate*dt (clamped to capacity).
//   2) INPUT-DRIVEN: gather() pulls from a node into the stockpile, scaled by the
//      effective GatherModifier read through SimRegistry (tools PUSH the multiplier
//      up; default x1.0). Caps clamp the stock; surplus is derived on the stock.
//
// No clock/random in regrow; gather takes no chance either (yield is multiplied
// deterministically). The registry is the ONLY seam to leaf-supplied tool boosts.

import '../../contracts/gather_modifier.dart';
import '../../contracts/sim_registry.dart';
import '../../core/enums.dart';
import '../../core/ids.dart';
import '../../core/result.dart';
import '../../data/models/resource_node.dart';
import '../../data/models/resource_stock.dart';
import '../../data/models/world_state.dart';

class ResourceSystem {
  const ResourceSystem(this.registry);

  final SimRegistry registry;

  /// PASSIVE regrow: advances every node's `remaining` toward its capacity by
  /// regrowRate*dt. Returns the same state object when nothing regrows (cheap).
  EmberWorldState regrow(EmberWorldState s, double dtSeconds) {
    if (dtSeconds <= 0) return s;
    bool changed = false;
    final List<ResourceNode> next = <ResourceNode>[];
    for (final ResourceNode n in s.nodes) {
      if (n.regrowRate <= 0) {
        next.add(n);
        continue;
      }
      final double cap = n.effectiveCapacity;
      if (n.remaining >= cap) {
        next.add(n);
        continue;
      }
      final double grown =
          (n.remaining + n.regrowRate * dtSeconds).clamp(0.0, cap);
      if (grown != n.remaining) {
        changed = true;
        next.add(n.copyWith(remaining: grown));
      } else {
        next.add(n);
      }
    }
    return changed ? s.copyWith(nodes: next) : s;
  }

  /// INPUT-DRIVEN gather: pulls one gather action's worth from node [nodeId] into
  /// the stock, scaled by the effective yield multiplier. Returns the new state
  /// on success, or a Failure if the node is missing/depleted.
  Result<EmberWorldState> gather(EmberWorldState s, EntityId nodeId) {
    final ResourceNode? node = s.nodeById(nodeId);
    if (node == null) {
      return const Result<EmberWorldState>.err(
        Failure('node_missing', 'No resource node with that id.'),
      );
    }
    if (node.isDepleted) {
      return const Result<EmberWorldState>.err(
        Failure('node_depleted', 'This node is exhausted.'),
      );
    }

    final GatherModifier mod = registry.gatherModifier;
    final double yieldMul = mod.yieldMultiplier(node.type, s);
    // How much the node can actually give this action.
    final int want = (node.baseYield * yieldMul).round();
    final int take = want.clamp(0, node.remaining.floor());
    if (take <= 0) {
      return const Result<EmberWorldState>.err(
        Failure('node_depleted', 'This node is exhausted.'),
      );
    }

    final ResourceNode pulled =
        node.copyWith(remaining: (node.remaining - take).clamp(0.0, node.remaining));
    final List<ResourceNode> nextNodes = <ResourceNode>[
      for (final ResourceNode n in s.nodes) n.id == node.id ? pulled : n,
    ];
    final ResourceStock nextStock = s.stock.add(node.type, take);

    return Result<EmberWorldState>.ok(
      s.copyWith(nodes: nextNodes, stock: nextStock),
    );
  }

  /// Effective gather speed multiplier for [type] (tools push this; default 1.0).
  /// The controller uses it to pace how often a worker can gather.
  double speedFor(ResourceType type, EmberWorldState s) =>
      registry.gatherModifier.speedMultiplier(type, s);
}
