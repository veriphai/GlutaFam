// Ember — game/exploration/discovery_nodes.dart
//
// The data for the three DISCOVERY NODES — the walk-up spots that replace the
// concept-tracker-as-launcher. Each node sits at a fixed, believable place on the
// seeded 16x16 map (relative to the village site), is GATED on its concept being
// unlocked (the prereq cascade: Fire is open from the start; Tools unlocks once
// Fire is learned; Shelter once Tools is learned), and carries the activityId the
// proximity ring launches via the existing host.launch seam.
//
// These are PRESENTATION placement only — the gating + launch authority still live
// in the world state + ActivityHost (which re-checks prerequisites). This file
// just says WHERE each discovery sits and WHICH activity/concept it represents, so
// the world can show the right glowing ring at the right spot.
//
// Pure data + a couple of pure lookups; no Flame, no Riverpod, no clock/random.

import '../../core/enums.dart';
import '../../core/geometry.dart';

/// A walk-up discovery spot on the map.
class DiscoveryNodeDef {
  const DiscoveryNodeDef({
    required this.activityId,
    required this.concept,
    required this.offsetFromSite,
    required this.shortLabel,
    required this.glyph,
  });

  /// The activity the proximity ring launches (host.launch(activityId)).
  final String activityId;

  /// The concept that gates this node — it is shown only once this concept is
  /// UNLOCKED (and hidden again once COMPLETED, so the spot stops nagging).
  final ConceptId concept;

  /// Where the node sits relative to the village site tile.
  final GridCoord offsetFromSite;

  /// A short imperative the floating prompt + journal hint show ("Make Fire").
  final String shortLabel;

  /// A glyph hint for the prompt ring (rendered by the component).
  final DiscoveryGlyph glyph;

  /// The node's absolute coord on the map for a given village [site].
  GridCoord coordFor(GridCoord site) =>
      GridCoord(site.x + offsetFromSite.x, site.y + offsetFromSite.y);
}

/// Closed set of icon hints the discovery ring can stamp (no font dependency).
enum DiscoveryGlyph { fire, knap, shelter }

/// The three discovery nodes, placed in believable terrain on the seeded map:
///   * FIRE   — a dry-grass + firebow spot SE of camp, open grass (10, 9),
///   * TOOLS  — a knapping outcrop on the rocky south-east block (12, 11),
///   * SHELTER— a sheltered high-ground ledge in the NE corner (13, 3).
/// (Site is (8,8); offsets keep them on walkable, on-theme ground.)
const List<DiscoveryNodeDef> kDiscoveryNodes = <DiscoveryNodeDef>[
  DiscoveryNodeDef(
    activityId: 'fire.make_fire',
    concept: ConceptId.fire,
    offsetFromSite: GridCoord(2, 1),
    shortLabel: 'Make Fire',
    glyph: DiscoveryGlyph.fire,
  ),
  DiscoveryNodeDef(
    activityId: 'tools.knapping',
    concept: ConceptId.stoneTools,
    offsetFromSite: GridCoord(4, 3),
    shortLabel: 'Shape a Tool',
    glyph: DiscoveryGlyph.knap,
  ),
  DiscoveryNodeDef(
    activityId: 'shelter.raise_shelter',
    concept: ConceptId.shelter,
    offsetFromSite: GridCoord(5, -5),
    shortLabel: 'Raise a Shelter',
    glyph: DiscoveryGlyph.shelter,
  ),
];

/// The discovery def for [activityId], or null if none.
DiscoveryNodeDef? discoveryForActivity(String activityId) {
  for (final DiscoveryNodeDef d in kDiscoveryNodes) {
    if (d.activityId == activityId) return d;
  }
  return null;
}
