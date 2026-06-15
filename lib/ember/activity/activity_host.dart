// Ember — activity/activity_host.dart
//
// The orchestrator that runs ONE activity end-to-end:
//   launch(id) -> resolve prerequisites (against the live world)
//             -> look up the leaf's ActivityRegistration in the registry
//             -> build a BeatController + the leaf's ActivityScene
//             -> route the scene into the Flame game (enterActivity)
//             -> the Flutter ActivityPhaseOverlay frames the 5 beats
//             -> on the scene's finishWithResult: dispatch CompleteActivity
//                (ApplyReducer folds the effects), exit the scene, and — if the
//                activity handed back a PlaceHint as a GHOST — kick off the
//                placement tutorial so the player drops the new structure.
//
// It is a [ChangeNotifier] the world screen watches: the screen renders the
// ActivityPhaseOverlay for [activeScene] and clears it when the host finishes.
// The host reaches the world ONLY through Riverpod (read the world for prereqs,
// dispatch CompleteActivity) and the game (enter/exit the scene). It never
// imports a leaf — scenes arrive via the registry's SceneBuilder.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contracts/concept_module.dart';
import '../core/enums.dart';
import '../data/models/world_state.dart';
import '../game/ember_game.dart';
import '../game/placement/placement_controller.dart';
import '../registry/concept_registry.dart';
import '../state/intents.dart';
import '../state/providers.dart';
import '../state/world_controller.dart';
import 'activity_contract.dart';
import 'activity_result.dart';
import 'activity_scene.dart';
import 'beat_controller.dart';

/// Why a launch was refused (so the UI can explain it).
enum ActivityLaunchRefusal { unknownActivity, prerequisitesUnmet, alreadyRunning }

/// The result of attempting to launch an activity.
class ActivityLaunchResult {
  const ActivityLaunchResult.ok()
      : refusal = null,
        unmet = const <Prerequisite>[];
  const ActivityLaunchResult.refused(this.refusal,
      {this.unmet = const <Prerequisite>[]});

  final ActivityLaunchRefusal? refusal;
  final List<Prerequisite> unmet;

  bool get launched => refusal == null;
}

/// Drives one activity's full lifecycle on top of the game + world.
class ActivityHost extends ChangeNotifier {
  ActivityHost({
    required this.container,
    required this.game,
    required this.placement,
  });

  /// The module's ProviderContainer (read the world for prereqs, dispatch the
  /// result, read the registry) — the SAME one the game + bootstrap use.
  final ProviderContainer container;

  /// The Flame game the scene is routed into.
  final EmberGame game;

  /// The placement controller used to run the post-activity build tutorial.
  final PlacementController placement;

  ActivityScene? _activeScene;

  /// The scene currently routed in (the world screen renders its overlay), or
  /// null when no activity is running.
  ActivityScene? get activeScene => _activeScene;

  bool get isRunning => _activeScene != null;

  // ===========================================================================
  // Launch
  // ===========================================================================

  /// Attempts to launch activity [activityId]. Resolves prerequisites against
  /// the live world, builds the scene, and routes it in. Returns whether it
  /// launched (and why not, if refused).
  ActivityLaunchResult launch(String activityId) {
    if (isRunning) {
      return const ActivityLaunchResult.refused(
          ActivityLaunchRefusal.alreadyRunning);
    }

    final ConceptRegistry registry = container.read(registryProvider);
    final ActivityRegistration? reg = registry.activityById(activityId);
    if (reg == null) {
      return const ActivityLaunchResult.refused(
          ActivityLaunchRefusal.unknownActivity);
    }

    final EmberWorldState world = container.read(worldControllerProvider);
    final List<Prerequisite> unmet = _unmetPrerequisites(reg.def, world);
    if (unmet.isNotEmpty) {
      return ActivityLaunchResult.refused(
        ActivityLaunchRefusal.prerequisitesUnmet,
        unmet: unmet,
      );
    }

    final BeatController controller = BeatController(reg.def);
    final ActivityScene scene = reg.scene(reg.def, controller)
      ..onFinished = _onSceneFinished;
    _activeScene = scene;

    // Route the scene into the game's world. enterActivity accepts a builder so
    // the game never imports ActivityScene; we already built it, so return it.
    game.enterActivity((EmberGame g) => scene);
    notifyListeners();
    return const ActivityLaunchResult.ok();
  }

  // ===========================================================================
  // Completion
  // ===========================================================================

  void _onSceneFinished(ActivityResult result) {
    // 1) Fold the result into the world (reducer) via the controller.
    container
        .read(worldControllerProvider.notifier)
        .dispatch(CompleteActivity(result));

    // 2) Tear down the scene + restore the iso world.
    final ActivityScene? scene = _activeScene;
    _activeScene = null;
    game.exitActivity();
    scene?.controller.dispose();
    notifyListeners();

    // 3) If the activity returned a GHOST placement hint, run the build tutorial
    //    so the player chooses where the new structure goes. A `built` hint was
    //    already materialised by the reducer, so only ghosts need this.
    final PlaceHint? hint = result.placeHint;
    if (hint != null && !hint.built) {
      placement.begin(hint.type, at: hint.coord);
    }
  }

  /// Force-cancel a running activity without applying its result (e.g. the user
  /// backs out). Restores the iso world.
  void cancel() {
    final ActivityScene? scene = _activeScene;
    if (scene == null) return;
    _activeScene = null;
    game.exitActivity();
    scene.controller.dispose();
    notifyListeners();
  }

  // ===========================================================================
  // Prerequisites
  // ===========================================================================

  /// The prerequisites of [def] that are NOT currently satisfied by [world].
  List<Prerequisite> _unmetPrerequisites(
    EmberActivity def,
    EmberWorldState world,
  ) {
    return <Prerequisite>[
      for (final Prerequisite p in def.prerequisites)
        if (!_isSatisfied(p, world)) p,
    ];
  }

  bool _isSatisfied(Prerequisite p, EmberWorldState world) {
    switch (p) {
      case NoPrerequisite():
        return true;
      case ConceptCompleted():
        final concept = world.conceptById(p.concept);
        return concept?.completed ?? false;
      case KnowledgeFlagSet():
        return world.knowledge.get(p.flag);
      case PlaceableBuilt():
        for (final placeable in world.placeables) {
          if (placeable.type == p.type &&
              placeable.state == PlaceableState.built) {
            return true;
          }
        }
        return false;
    }
  }

  @override
  void dispose() {
    cancel();
    super.dispose();
  }
}
