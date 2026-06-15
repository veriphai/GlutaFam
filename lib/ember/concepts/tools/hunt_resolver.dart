// Ember — concepts/tools/hunt_resolver.dart
//
// The tools leaf's [EventResolver] for a stylized spear HUNT. Tools — and the
// hafted spear in particular — unlock a simple hunt that brings home Food + Hide
// (PRD §7 "hunting payoff"; §16 child-safety). It reads whether the village has a
// spear-or-better tool built (via [Tool.bestEquipped]) and:
//   * with a spear  -> a successful hunt: Food + Hide added to the stock, scaled
//     by the tool's tier + a little reproducible variation from [EmberRng];
//   * without one    -> the hunt comes up short (a small, gentle setback), with a
//     hint that a hafted spear gives the reach to actually bring something home.
//
// CHILD-SAFETY (PRD §16): the hunt is ABSTRACT + STYLIZED. The outcome describes
// the tribe "bringing home food and hides" — never an animal being harmed, never
// graphic, never peril to a character. Emphasis is on the TOOL + the skill.
//
// PURE + DETERMINISTIC: any chance uses the threaded [EmberRng], never DateTime/
// Random. It returns a NEW state with the granted resources folded into the stock.

import '../../contracts/event_resolver.dart';
import '../../core/ember_rng.dart';
import '../../core/enums.dart';
import '../../data/models/resource_stock.dart';
import '../../data/models/world_event.dart';
import '../../data/models/world_state.dart';
import 'model/tool.dart';

/// Resolves a stylized hunt: a spear brings home Food + Hide; no spear, it comes
/// up short. The hunt has its OWN [WorldEventType.hunt] slot (added centrally), so
/// it never collides with the fire leaf's predator resolver — [canResolve] keys
/// off that dedicated member and the pressure system schedules the hunt directly.
class HuntResolver implements EventResolver {
  const HuntResolver();

  @override
  bool canResolve(WorldEventType type) => type == WorldEventType.hunt;

  @override
  EventOutcome resolve(WorldEvent e, EmberWorldState s, EmberRng rng) {
    final Tool? best = Tool.bestEquipped(s.placeables);
    final bool hasSpear = best != null && best.rank >= toolRank(ToolType.spear);

    if (!hasSpear) {
      // No reach: the hunt comes up short. A gentle, encouraging nudge toward
      // hafting a spear — NOT a punishment.
      return EventOutcome(
        state: s,
        type: WorldEventType.hunt,
        headline: 'The hunt came home empty-handed.',
        detail:
            'Without a spear there was no way to reach the game from a safe '
            'distance. Haft a sharp point onto a shaft and the next hunt can '
            'bring home food and hides.',
        severity: 0.0,
        data: const <String, dynamic>{
          'hunt': true,
          'success': false,
        },
      );
    }

    // A successful, stylized hunt. Yield scales with the spear's tier + a small
    // reproducible roll. Kept modest so it complements gathering, not replaces it.
    final int tierBonus = (best.tier - 1).clamp(0, 3);
    final int food = 3 + tierBonus + rng.nextInt(3); // 3..5 (+tier)
    final int hide = 1 + (tierBonus ~/ 2) + rng.nextInt(2); // 1..2 (+tier)

    final ResourceStock nextStock =
        s.stock.add(ResourceType.food, food).add(ResourceType.hide, hide);

    return EventOutcome(
      state: s.copyWith(stock: nextStock),
      type: WorldEventType.hunt,
      headline: 'The hunting party returned with food and hides.',
      detail:
          'The hafted spear gave the hunters reach. They brought back '
          '$food food and $hide hide — the hides can be scraped and dried for '
          'shelter and clothing.',
      severity: 0.0,
      data: <String, dynamic>{
        'hunt': true,
        'success': true,
        'foodGained': food,
        'hideGained': hide,
        'tool': best.type.name,
      },
    );
  }
}
