// Ember — game/placement/placement_controller.dart
//
// The Clash-of-Clans-style placement state machine. It owns the placement MODE
// (idle / placing-new / moving-existing), the live ghost, and the gestures that
// drive them, and it emits Intents (ConfirmPlace / MovePlace / RemovePlace) into
// the GameBridge on confirm. Validity is the pure [PlacementValidator] — the
// SAME check the ghost shows and the confirm gate enforces — so a placement can
// never be confirmed while the ghost is red.
//
// Flow:
//   begin(type)         -> spawn a ghost at the camera-center cell, mode = newPlace
//   beginMove(id)       -> lift an existing placeable into a ghost, mode = move
//   pointTo(world)      -> snap the ghost to the cell under the pointer
//   rotate()            -> quarter-turn the ghost (footprint swaps)
//   confirm()           -> if valid, dispatch ConfirmPlace/MovePlace; else reject
//   cancel()            -> tear down the ghost; if a move, the original is intact
//   remove(id)          -> dispatch RemovePlace (controller-driven refund in sim)
//
// It is a plain ChangeNotifier (no Flame inheritance) so the HUD can watch
// `mode`/`canConfirm` to show a build-bar; the game wires the ghost into the
// world layer + feeds it pointer events.

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../contracts/placeable_def.dart';
import '../../core/enums.dart';
import '../../core/geometry.dart';
import '../../core/ids.dart';
import '../../data/models/placeable.dart';
import '../../state/intents.dart';
import '../game_bridge.dart';
import '../iso/iso_projection.dart';
import 'ghost_component.dart';
import 'placement_validator.dart';

/// The placement interaction mode.
enum PlacementMode { idle, newPlace, move }

/// Drives the CoC placement state machine. The game hosts it, wires its ghost
/// into the world, and forwards pointer/gesture events.
class PlacementController extends ChangeNotifier {
  PlacementController({
    required this.bridge,
    required this.onSpawnGhost,
    required this.onDespawnGhost,
    this.projection = IsoProjection.standard,
  });

  /// The sim touch-point (read state, dispatch intents).
  final GameBridge bridge;

  /// Called with a freshly-built ghost so the game can add it to the world
  /// layer (the controller doesn't know the world component directly).
  final void Function(GhostComponent ghost) onSpawnGhost;

  /// Called to remove the active ghost from the world.
  final void Function(GhostComponent ghost) onDespawnGhost;

  final IsoProjection projection;

  PlacementMode _mode = PlacementMode.idle;
  PlacementMode get mode => _mode;

  /// True while a ghost is live (placing or moving).
  bool get isPlacing => _mode != PlacementMode.idle;

  GhostComponent? _ghost;
  GhostComponent? get ghost => _ghost;

  /// The placeable being moved (move mode only).
  EntityId? _movingId;

  /// Whether the current ghost can be confirmed (valid).
  bool get canConfirm => _ghost?.isValid ?? false;

  /// The reasons the current ghost is invalid (empty when valid/idle).
  List<PlacementReason> get blockingReasons =>
      _ghost?.validity.reasons ?? const <PlacementReason>[];

  // ===========================================================================
  // Begin
  // ===========================================================================

  /// Start placing a NEW [type] at [at] (defaults to the village site). Tears
  /// down any in-flight ghost first.
  void begin(PlaceableType type, {GridCoord? at}) {
    cancel();
    final PlaceableDef? def = _defFor(type);
    final GridCoord coord = at ?? bridge.state.village.siteTile;
    final GhostComponent ghost = GhostComponent(
      type: type,
      def: def,
      projection: projection,
    )..moveTo(coord);
    _ghost = ghost;
    _movingId = null;
    _mode = PlacementMode.newPlace;
    onSpawnGhost(ghost);
    // Also surface a transient BeginPlace intent (the controller treats it as a
    // no-op, but it keeps the intent log honest about player action).
    bridge.dispatch(BeginPlace(type, coord: coord));
    notifyListeners();
  }

  /// Lift an EXISTING placeable [id] into a movable ghost.
  void beginMove(EntityId id) {
    final Placeable? p = bridge.state.placeableById(id);
    if (p == null) return;
    cancel();
    final PlaceableDef? def = _defFor(p.type);
    final GhostComponent ghost = GhostComponent(
      type: p.type,
      def: def,
      ignoreId: id,
      projection: projection,
    )..moveTo(p.coord);
    // Carry the existing rotation into the ghost.
    for (int i = 0; i < (p.rotation % 4); i++) {
      ghost.rotate();
    }
    _ghost = ghost;
    _movingId = id;
    _mode = PlacementMode.move;
    onSpawnGhost(ghost);
    notifyListeners();
  }

  // ===========================================================================
  // Drive
  // ===========================================================================

  /// Snap the ghost to the cell under world-space point [world].
  void pointTo(Vector2World world) {
    final GhostComponent? ghost = _ghost;
    if (ghost == null) return;
    final GridCoord cell = projection.screenToGrid(world.value);
    ghost.moveTo(cell);
    notifyListeners();
  }

  /// Snap the ghost directly to a grid [cell].
  void pointToCell(GridCoord cell) {
    final GhostComponent? ghost = _ghost;
    if (ghost == null) return;
    ghost.moveTo(cell);
    notifyListeners();
  }

  /// Quarter-turn the current ghost.
  void rotate() {
    _ghost?.rotate();
    notifyListeners();
  }

  // ===========================================================================
  // Resolve
  // ===========================================================================

  /// Confirm the placement. Returns true if it was valid + dispatched. When
  /// invalid, leaves the ghost live so the player can adjust.
  bool confirm() {
    final GhostComponent? ghost = _ghost;
    if (ghost == null) return false;
    if (!ghost.isValid) return false; // pure validator already rejected it.

    if (_mode == PlacementMode.move && _movingId != null) {
      bridge.dispatch(MovePlace(
        id: _movingId!,
        coord: ghost.coord,
        rotation: ghost.rotation,
      ));
    } else {
      bridge.dispatch(ConfirmPlace(
        type: ghost.type,
        coord: ghost.coord,
        rotation: ghost.rotation,
      ));
    }
    _teardown();
    notifyListeners();
    return true;
  }

  /// Cancel the in-flight placement (the moved original is untouched).
  void cancel() {
    if (_ghost == null) return;
    _teardown();
    notifyListeners();
  }

  /// Remove an existing placeable [id] (the sim applies a partial refund). If a
  /// ghost for that id is currently being moved, it is cancelled first.
  void remove(EntityId id) {
    if (_movingId == id) cancel();
    bridge.dispatch(RemovePlace(id));
    notifyListeners();
  }

  // ===========================================================================
  // Internals
  // ===========================================================================

  void _teardown() {
    final GhostComponent? ghost = _ghost;
    if (ghost != null) onDespawnGhost(ghost);
    _ghost = null;
    _movingId = null;
    _mode = PlacementMode.idle;
  }

  PlaceableDef? _defFor(PlaceableType type) {
    // The bridge exposes the world; defs come from the registry-backed
    // SimRegistry. We reach it through the controller (worldController) via the
    // bridge's dispatch path? No — we read it from the registry through the
    // ghost-less path: the validator handles null defs gracefully, but the
    // controller wants the def for footprint/cost. The game injects it.
    return defResolver?.call(type);
  }

  /// Injected by the game so the controller can fetch defs without importing the
  /// registry (keeps the dir-lock). Set once at construction time by EmberGame.
  PlaceableDef? Function(PlaceableType type)? defResolver;

  @override
  void dispose() {
    _teardown();
    super.dispose();
  }
}

/// A tiny typed wrapper so call sites pass a clearly world-space coordinate
/// (Vector2) without ambiguity with screen/widget space. The game converts a
/// pointer event to world space via the camera, then wraps it here.
class Vector2World {
  const Vector2World(this.value);
  final Vector2 value;
}
