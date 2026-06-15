// Ember — game/placement/placement_validator.dart
//
// PURE placement validity. This is the single source of truth the placement
// state machine uses for BOTH the live ghost tint (preview) and the final
// ConfirmPlace gate — so what the player sees (green/red) is exactly what the
// controller will accept. No Flame, no Riverpod, no clock/random: it is a pure
// function of (world snapshot, placeable def, target coord, rotation, ignoreId).
//
// A placement is valid iff EVERY rule passes across the whole footprint:
//   * in-bounds        — all footprint cells exist on the grid,
//   * explored region  — all footprint cells are in an unlocked/explored region,
//   * terrain          — every cell's terrain is in the def's allowedTerrain,
//   * buildable        — every cell's `buildable` flag is true,
//   * unoccupied       — no cell is occupied by ANOTHER placeable,
//   * affordable       — the player can afford the def's cost (skipped on move).
// Failures accumulate into [reasons] so the UI can explain WHY it's red.

import '../../contracts/placeable_def.dart';
import '../../core/geometry.dart';
import '../../core/ids.dart';
import '../../data/models/tile.dart';
import '../../data/models/world_state.dart';

/// A closed set of placement failure reasons (stable codes + human messages).
enum PlacementReason {
  outOfBounds,
  notExplored,
  wrongTerrain,
  notBuildable,
  occupied,
  unaffordable,
  noDef;

  /// A short, kid-readable explanation for the HUD.
  String get message => switch (this) {
        PlacementReason.outOfBounds => 'Off the map',
        PlacementReason.notExplored => 'Not explored yet',
        PlacementReason.wrongTerrain => 'Wrong ground here',
        PlacementReason.notBuildable => "Can't build here",
        PlacementReason.occupied => 'Something is already here',
        PlacementReason.unaffordable => 'Not enough resources',
        PlacementReason.noDef => 'Unknown structure',
      };
}

/// The outcome of a validity check: a boolean + the reasons it failed.
class PlacementValidity {
  const PlacementValidity({required this.ok, required this.reasons});

  /// Whether the placement is allowed.
  final bool ok;

  /// Distinct reasons it failed (empty when [ok]).
  final List<PlacementReason> reasons;

  /// A valid result.
  static const PlacementValidity valid =
      PlacementValidity(ok: true, reasons: <PlacementReason>[]);

  /// The footprint cells the renderer should tint (set by the validator so the
  /// ghost can show per-cell validity). Not part of equality.
  String get summary =>
      ok ? 'OK' : reasons.map((PlacementReason r) => r.message).join(' · ');
}

/// Pure validity checker. Stateless + const.
class PlacementValidator {
  const PlacementValidator();

  /// Validates placing [def] at [coord]. When [ignoreId] is non-null (a MOVE),
  /// tiles occupied by THAT placeable don't count as occupied, and the cost
  /// check is skipped (moving is free). [checkAffordability] lets a preview for
  /// a brand-new placement still show "unaffordable" before confirm.
  PlacementValidity validate(
    EmberWorldState s,
    PlaceableDef? def,
    GridCoord coord, {
    int rotation = 0,
    EntityId? ignoreId,
    bool checkAffordability = true,
  }) {
    final Set<PlacementReason> reasons = <PlacementReason>{};

    if (def == null) {
      return const PlacementValidity(
        ok: false,
        reasons: <PlacementReason>[PlacementReason.noDef],
      );
    }

    final (int w, int h) = footprintFor(def, rotation);
    final List<GridCoord> cells = coord.footprint(w, h);

    for (final GridCoord c in cells) {
      final Tile? tile = s.tiles.at(c);
      if (tile == null) {
        reasons.add(PlacementReason.outOfBounds);
        continue; // nothing else to check on an off-map cell.
      }
      if (!tile.explored) reasons.add(PlacementReason.notExplored);
      if (!def.allowsTerrain(tile.terrain)) {
        reasons.add(PlacementReason.wrongTerrain);
      }
      if (!tile.buildable) reasons.add(PlacementReason.notBuildable);
      final EntityId? occ = tile.occupantId;
      if (occ != null && occ != ignoreId) {
        reasons.add(PlacementReason.occupied);
      }
    }

    // Affordability (skip when moving an existing placeable).
    if (checkAffordability && ignoreId == null && !s.stock.canAfford(def.cost)) {
      reasons.add(PlacementReason.unaffordable);
    }

    if (reasons.isEmpty) return PlacementValidity.valid;
    return PlacementValidity(ok: false, reasons: reasons.toList());
  }

  /// Per-cell validity for the ghost tint: returns the subset of footprint cells
  /// that are individually INVALID (out of bounds / wrong terrain / occupied /
  /// not buildable). The ghost paints these red and the rest green. Affordability
  /// is a whole-placement concern, not per-cell, so it is not reflected here.
  Set<GridCoord> invalidCells(
    EmberWorldState s,
    PlaceableDef? def,
    GridCoord coord, {
    int rotation = 0,
    EntityId? ignoreId,
  }) {
    if (def == null) return <GridCoord>{};
    final (int w, int h) = footprintFor(def, rotation);
    final Set<GridCoord> bad = <GridCoord>{};
    for (final GridCoord c in coord.footprint(w, h)) {
      final Tile? tile = s.tiles.at(c);
      if (tile == null ||
          !tile.explored ||
          !def.allowsTerrain(tile.terrain) ||
          !tile.buildable ||
          (tile.occupantId != null && tile.occupantId != ignoreId)) {
        bad.add(c);
      }
    }
    return bad;
  }

  /// The effective footprint (w,h) of [def] after [rotation] quarter-turns. Odd
  /// rotations swap width/height so a 2x1 lean-to can be turned.
  (int, int) footprintFor(PlaceableDef def, int rotation) {
    final int w = def.footprint.width;
    final int h = def.footprint.height;
    return (rotation % 2 == 0) ? (w, h) : (h, w);
  }
}
