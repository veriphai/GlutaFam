// Ember — state/intents.dart
//
// The closed set of player/game INTENTS the WorldController applies. The Flame
// layer (and UI) never mutate the world directly — they dispatch one of these and
// the controller folds it into a new EmberWorldState (then persists). Placement
// VALIDITY is checked by the game's PlacementValidator BEFORE a ConfirmPlace is
// dispatched; the controller trusts a confirmed intent and just applies it.
//
// These are plain value types (no serialization needed — they are transient
// commands, not persisted state).

import '../activity/activity_result.dart';
import '../core/enums.dart';
import '../core/geometry.dart';
import '../core/ids.dart';

/// Base type for every command the controller understands.
sealed class Intent {
  const Intent();
}

/// Gather one action's worth from the resource node [nodeId].
class GatherIntent extends Intent {
  const GatherIntent(this.nodeId);
  final EntityId nodeId;
}

/// Begin placing a [type] (spawns a ghost the game tracks while the player drags
/// it). The optional [coord] seeds the ghost's initial cell.
class BeginPlace extends Intent {
  const BeginPlace(this.type, {this.coord});
  final PlaceableType type;
  final GridCoord? coord;
}

/// Confirm placement of [type] at [coord] (already validated by the game). The
/// controller spends the cost, mints a ghost/built placeable, and stamps tiles.
class ConfirmPlace extends Intent {
  const ConfirmPlace({
    required this.type,
    required this.coord,
    this.rotation = 0,
    this.tier = 1,
  });
  final PlaceableType type;
  final GridCoord coord;
  final int rotation;
  final int tier;
}

/// Move an existing placeable [id] to [coord] (validated by the game first).
class MovePlace extends Intent {
  const MovePlace({required this.id, required this.coord, this.rotation});
  final EntityId id;
  final GridCoord coord;
  final int? rotation;
}

/// Remove placeable [id] from the world (frees its tiles; partial refund).
class RemovePlace extends Intent {
  const RemovePlace(this.id);
  final EntityId id;
}

/// Tend the fire placeable [id] (restores fuel). The fire leaf reads the tend via
/// the shared ext bag; the controller routes the request to the placeable.
class TendFire extends Intent {
  const TendFire(this.id);
  final EntityId id;
}

/// Assign NPC [npcId] to harvest node [nodeId] (or clear when [nodeId] is null).
class AssignNpc extends Intent {
  const AssignNpc({required this.npcId, this.nodeId});
  final EntityId npcId;
  final EntityId? nodeId;
}

/// Start the activity [activityId] (the game opens its ActivityScene). The
/// controller records the attempt-in-flight; completion arrives via
/// [CompleteActivity].
class StartActivity extends Intent {
  const StartActivity(this.activityId);
  final String activityId;
}

/// Complete an activity by folding its [result] through the ApplyReducer.
class CompleteActivity extends Intent {
  const CompleteActivity(this.result);
  final ActivityResult result;
}

/// DEBUG-only: jump sim time forward by [ms] (drives the sim review loop). Runs
/// the same WorldSimulation.advance the live/offline paths use.
class AdvanceTimeDebug extends Intent {
  const AdvanceTimeDebug(this.ms);
  final int ms;
}
