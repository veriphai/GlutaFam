// Ember — concepts/tools/tools_behavior.dart
//
// The runtime brain the sim ticks for the tools leaf's placeables. A knapping
// station / tool rack is mostly inert (it holds a [Tool] in its ext bag that the
// gather modifier reads back), so this behavior's only job is to make sure a
// freshly-built station/rack that was dropped WITHOUT a tool payload (e.g. built
// straight from the menu rather than handed over by the Knapping activity) seeds
// a sensible base tool so the village immediately gets the felt multiplier.
//
// It mutates ONLY the placeable's generic `ext` bag (via the typed [Tool] view) —
// never the shared model, never world state at large. PURE + DETERMINISTIC: it
// advances solely by inputs (no clock/random), so live play, offline catch-up,
// and tests all converge. Durability tick-down is intentionally OFF by default
// (PRD §16: durability off for younger players) — onTick is a no-op.

import '../../contracts/placeable_behavior.dart';
import '../../core/enums.dart';
import '../../data/models/placeable.dart';
import '../../data/models/world_state.dart';
import 'model/tool.dart';

/// Seeds a base tool on a station/rack built without one; otherwise inert.
class ToolsBehavior extends PlaceableBehavior {
  const ToolsBehavior();

  @override
  void onBuilt(Placeable p, EmberWorldState state) {
    // If the activity (or a save) already stamped a tool, leave it untouched.
    if (Tool.fromPlaceable(p) != null) return;
    // Otherwise seed the base tool for this placeable type so building one from
    // the menu still grants the felt multiplier (the station makes a hand axe;
    // the rack stores a chopper baseline).
    final Tool seed = _baseToolFor(p.type, p.tier);
    final Map<String, dynamic> ext = seed.toExt();
    for (final MapEntry<String, dynamic> e in ext.entries) {
      p.ext[e.key] = e.value;
    }
    if (p.type == PlaceableType.toolRack) {
      p.ext[ToolExtKeys.stored] = 1;
    }
  }

  @override
  void onTick(Placeable p, EmberWorldState state, double dtSeconds) {
    // Durability loop is deferred (PRD §17). Nothing to advance per tick.
  }

  static Tool _baseToolFor(PlaceableType type, int tier) {
    switch (type) {
      case PlaceableType.knappingStation:
        // A working station defaults to the all-purpose hand axe.
        return Tool(type: ToolType.handAxe, tier: tier);
      case PlaceableType.toolRack:
        // A rack holds a basic chopper until better tools are knapped.
        return Tool(type: ToolType.chopper, tier: tier);
      default:
        return Tool(type: ToolType.chopper, tier: tier);
    }
  }
}
