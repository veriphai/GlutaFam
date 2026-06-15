// Ember — concepts/tools/model/tool.dart
//
// The TYPED VIEW over a generic [Placeable]'s untyped `ext` bag for the stone-
// tools leaf. A knapping station / tool rack stores the BEST tool it has produced
// (its type, tier, durability, the felt yield/speed multipliers, and whether it
// was fire-treated) inside Placeable.ext under stable string keys; this file reads
// it back as a strongly-typed [Tool] and exposes the cross-village "best equipped
// tool" calc the gather modifier consumes.
//
// It NEVER edits the shared Placeable model — it only ever round-trips through the
// open `ext` bag, which is the dir-lock contract. Pure value type: no Flame/
// Flutter, no clock/random. The model upgrade (lucky-stones -> material-fractures)
// lives in the codex; this file is just the data + the best-tool selection.

import '../../../core/enums.dart';
import '../../../data/models/placeable.dart';

/// The closed family of stone tools, in ascending capability order. Stored as
/// `.name` in the ext bag so it round-trips with the save.
///
/// PRD §7 tier chain: Chopper -> Hand axe -> Hafted spear -> finer Blades.
enum ToolType { chopper, handAxe, spear, blade }

/// Maps a [ToolType] to its position in the tier chain (1..4) — bigger = better.
int toolRank(ToolType t) => switch (t) {
      ToolType.chopper => 1,
      ToolType.handAxe => 2,
      ToolType.spear => 3,
      ToolType.blade => 4,
    };

ToolType _toolTypeFromName(Object? n) {
  if (n is String) {
    for (final ToolType v in ToolType.values) {
      if (v.name == n) return v;
    }
  }
  return ToolType.chopper;
}

/// Stable ext-bag keys the tools leaf owns. Frozen so the activity placeHint, the
/// behavior, the component, and this view all agree.
class ToolExtKeys {
  const ToolExtKeys._();

  /// The kind of the best tool this station/rack holds (a [ToolType] `.name`).
  static const String toolType = 'toolType';

  /// The tool's tier (mirrors the placeable tier; 1 = base flake/chopper).
  static const String toolTier = 'toolTier';

  /// 0..1 remaining sharpness/durability (optional depth; 1.0 = freshly knapped).
  static const String durability = 'toolDurability';

  /// Whether the tool was fire-treated (heat-treated stone / fire-hardened tip).
  static const String fireTreated = 'fireTreated';

  /// How many tools the rack currently stores (the small capacity gate).
  static const String stored = 'toolsStored';

  /// Whether this station/rack actually holds a usable tool yet.
  static const String hasTool = 'hasTool';
}

/// A strongly-typed view over a tool stored in a [Placeable]'s ext payload.
class Tool {
  const Tool({
    required this.type,
    required this.tier,
    this.durability = 1.0,
    this.fireTreated = false,
  });

  /// Which tool this is.
  final ToolType type;

  /// Upgrade tier (1 = base). Higher tiers give bigger multipliers.
  final int tier;

  /// 0..1 remaining sharpness. Tools wear with use; re-knapping restores it.
  /// (Durability is OFF by default for younger players — see PRD §16 — so the
  /// default 1.0 means "always sharp" unless a caller ticks it down.)
  final double durability;

  /// Whether fire-treatment was applied (heat-treated stone / fire-hardened
  /// haft). The explicit link back to the Fire concept (PRD §4) — it bumps the
  /// felt multipliers a little.
  final bool fireTreated;

  /// Position in the tier chain (1..4) — drives the base multiplier strength.
  int get rank => toolRank(type);

  /// Whether the tool is still sharp enough to give its full benefit. Below this
  /// the multipliers fall off toward the no-tool baseline.
  bool get isSharp => durability > 0.15;

  /// The YIELD multiplier this tool grants when gathering [resource]. A made
  /// edge multiplies what the hands can pull (PRD §7: "tools as a multiplier").
  ///
  /// Pure: depends only on the tool's own fields + the resource it's used on.
  /// A spear helps food/hide most (hunting + butchering); a hand axe helps wood
  /// + stone (chopping + working); a fine blade helps everything a little more.
  double yieldMultiplier(ResourceType resource) {
    // Base climbs with the tier-chain rank: chopper x1.25 ... blade x2.0.
    final double base = 1.0 + 0.25 * rank;
    // Tool-vs-resource affinity: the right tool for the job adds a touch more.
    final double affinity = _affinity(resource);
    // Fire-treatment is a small, explicit reward for the Fire dependency.
    final double fire = fireTreated ? 1.1 : 1.0;
    // A dull tool slides back toward the no-tool baseline (durability depth).
    final double wear = isSharp ? 1.0 : 0.5;
    final double raw = base * affinity * fire;
    // Lerp toward 1.0 (no benefit) as the tool dulls.
    return (1.0 + (raw - 1.0) * wear);
  }

  /// The SPEED multiplier this tool grants for [resource] (how much faster a
  /// worker can gather). A flatter curve than yield — tools mostly multiply
  /// HOW MUCH, and speed a bit less.
  double speedMultiplier(ResourceType resource) {
    final double base = 1.0 + 0.12 * rank;
    final double affinity = 1.0 + (_affinity(resource) - 1.0) * 0.5;
    final double fire = fireTreated ? 1.05 : 1.0;
    final double wear = isSharp ? 1.0 : 0.6;
    final double raw = base * affinity * fire;
    return (1.0 + (raw - 1.0) * wear);
  }

  /// Tool-vs-resource affinity (>= 1.0). The "right tool for the job" bonus.
  double _affinity(ResourceType resource) {
    switch (type) {
      case ToolType.chopper:
        // A rough chopper helps wood a little.
        return resource == ResourceType.wood ? 1.15 : 1.0;
      case ToolType.handAxe:
        // The all-purpose hand axe shines on wood + stone working.
        return (resource == ResourceType.wood || resource == ResourceType.stone)
            ? 1.2
            : 1.05;
      case ToolType.spear:
        // The hafted spear is the hunt: food + hide.
        return (resource == ResourceType.food || resource == ResourceType.hide)
            ? 1.3
            : 1.0;
      case ToolType.blade:
        // A fine blade cuts everything well (butchering, scraping, shaping).
        return 1.2;
    }
  }

  Tool copyWith({
    ToolType? type,
    int? tier,
    double? durability,
    bool? fireTreated,
  }) {
    return Tool(
      type: type ?? this.type,
      tier: tier ?? this.tier,
      durability: durability ?? this.durability,
      fireTreated: fireTreated ?? this.fireTreated,
    );
  }

  /// Serializes this tool back into a flat ext map (merged onto a station/rack).
  Map<String, dynamic> toExt() => <String, dynamic>{
        ToolExtKeys.toolType: type.name,
        ToolExtKeys.toolTier: tier,
        ToolExtKeys.durability: durability,
        ToolExtKeys.fireTreated: fireTreated,
        ToolExtKeys.hasTool: true,
      };

  /// Reads the [Tool] stored on a placeable's ext bag, or null if it holds none.
  static Tool? fromPlaceable(Placeable p) {
    final Map<String, dynamic> e = p.ext;
    if (e[ToolExtKeys.hasTool] != true) return null;
    if (!e.containsKey(ToolExtKeys.toolType)) return null;
    return Tool(
      type: _toolTypeFromName(e[ToolExtKeys.toolType]),
      tier: (e[ToolExtKeys.toolTier] as num?)?.toInt() ?? p.tier,
      durability: (e[ToolExtKeys.durability] as num?)?.toDouble() ?? 1.0,
      fireTreated: e[ToolExtKeys.fireTreated] as bool? ?? false,
    );
  }

  /// The best (highest-rank, then highest-tier, then sharpest) tool held by ANY
  /// built tool-bearing placeable in [placeables]. This is the world-readable
  /// "best equipped tool" the gather modifier reads — only BUILT stations/racks
  /// count (a ghost or half-built one grants nothing). Returns null if none.
  static Tool? bestEquipped(Iterable<Placeable> placeables) {
    Tool? best;
    for (final Placeable p in placeables) {
      if (!p.isBuilt) continue;
      if (p.type != PlaceableType.knappingStation &&
          p.type != PlaceableType.toolRack) {
        continue;
      }
      final Tool? t = Tool.fromPlaceable(p);
      if (t == null) continue;
      if (best == null || t._betterThan(best)) best = t;
    }
    return best;
  }

  /// Strict "is this tool better than [other]" ordering: rank, then tier, then
  /// durability, then fire-treatment. Pure + total.
  bool _betterThan(Tool other) {
    if (rank != other.rank) return rank > other.rank;
    if (tier != other.tier) return tier > other.tier;
    if (durability != other.durability) return durability > other.durability;
    return fireTreated && !other.fireTreated;
  }

  @override
  bool operator ==(Object other) =>
      other is Tool &&
      other.type == type &&
      other.tier == tier &&
      other.durability == durability &&
      other.fireTreated == fireTreated;

  @override
  int get hashCode => Object.hash(type, tier, durability, fireTreated);

  @override
  String toString() =>
      'Tool(${type.name} t$tier dur=${durability.toStringAsFixed(2)}'
      '${fireTreated ? ' fire' : ''})';
}
