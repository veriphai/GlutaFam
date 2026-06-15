// Ember — concepts/tools/tool_gather_modifier.dart
//
// The stone-tools leaf's [GatherModifier] — the CORE, felt benefit of the whole
// concept (PRD §7: "tools as a multiplier"). It reads the best tool the village
// has actually BUILT (off the knapping-station / tool-rack ext bags, via
// [Tool.bestEquipped]) and returns that tool's yield + speed multipliers for the
// resource being gathered. No built tool -> x1.0 (the no-tools baseline).
//
// Consumption path (verified against the foundation, NOT guessed):
//   * SimRegistry.gatherModifier is the COMPOSED modifier ConceptRegistry builds
//     from every module's ConceptModule.gatherModifier (registry composes; the
//     sim's ResourceSystem reads registry.gatherModifier in gather()/speedFor()).
//     So ToolsConceptModule.gatherModifier returning THIS is the real seam the
//     sim consumes — exactly how Fire wires its read-back path.
//   * In addition, the leaf PUSHES this same instance into the seams.dart
//     toolMultiplierProvider in onInstall(ref) so the UI-facing derived
//     effectiveGatherModifierProvider reflects tools too (documented tools seam).
//
// PURE + DETERMINISTIC: it only reads [EmberWorldState] (placeables' ext bags).
// No clock, no random.

import '../../contracts/gather_modifier.dart';
import '../../core/enums.dart';
import '../../data/models/world_state.dart';
import 'model/tool.dart';

/// Multiplies gather yield + speed by the village's best built tool.
class ToolGatherModifier implements GatherModifier {
  const ToolGatherModifier();

  @override
  double yieldMultiplier(ResourceType type, EmberWorldState state) {
    final Tool? best = Tool.bestEquipped(state.placeables);
    if (best == null) return 1.0;
    return best.yieldMultiplier(type);
  }

  @override
  double speedMultiplier(ResourceType type, EmberWorldState state) {
    final Tool? best = Tool.bestEquipped(state.placeables);
    if (best == null) return 1.0;
    return best.speedMultiplier(type);
  }
}
