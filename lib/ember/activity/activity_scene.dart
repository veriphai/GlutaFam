// Ember — activity/activity_scene.dart
//
// The reusable ACTIVITY HOST as a Flame World. EmberGame.enterActivity() swaps
// its `world` to one of these; the scene owns the interact beat's visuals + sim
// and drives the [BeatController]. The shared chrome for the non-interactive
// beats (Setup / Discover / ItClicks / Apply) is Flutter (activity_phase_overlay
// .dart) — this Flame world is the STAGE the interact beat plays on.
//
// A concept LEAF subclasses this and overrides ONLY:
//   * buildInteractSim()   — the [ActivitySim] brain (BEAT-2 logic), and
//   * buildInteractStage() — the bespoke Flame props for the interaction.
// Everything else (wiring the sim into the controller, ticking it, the art
// toolkit handle, the success/finish plumbing) lives here so leaves stay tiny.
//
// CONTRACT: the scene NEVER mutates the world. On completion it calls
// finishWithResult(controller.buildResult()), which the host (ActivityHost)
// folds through the ApplyReducer via a CompleteActivity intent. The optional
// PlaceHint is attached by setting `controller.placeHint` before the success
// signal (a leaf does this from its sim/stage when it knows where to drop, e.g.
// "the new hearth goes on the chosen tile").

import 'package:flame/components.dart';
import 'package:flutter/widgets.dart' show BuildContext, Widget;

import '../art/ember_art.dart';
import '../game/ember_game.dart';
import 'activity_contract.dart';
import 'activity_result.dart';
import 'activity_sim.dart';
import 'beat_controller.dart';

/// The base activity stage. Leaves override [buildInteractSim] +
/// [buildInteractStage]; the host drives the rest.
abstract class ActivityScene extends World with HasGameReference<EmberGame> {
  ActivityScene(this.activity, this.controller);

  /// The declarative activity being played (copy / rules / unlocks).
  final EmberActivity activity;

  /// The 5-beat state machine the scene reports into + scores against.
  final BeatController controller;

  /// The art facade (placeholder toolkit for bespoke props). Resolved on load.
  late final EmberArt art;

  /// The live interact-beat sim (created when the interact beat begins).
  ActivitySim? _sim;
  ActivitySim? get sim => _sim;

  /// Set by the host once finishWithResult has fired (so we don't double-finish).
  bool _finished = false;
  bool get isFinished => _finished;

  /// Callback the host installs to receive the completed result. Set by
  /// ActivityHost.launch before the scene is routed in.
  void Function(ActivityResult result)? onFinished;

  // ===========================================================================
  // Flame lifecycle
  // ===========================================================================

  @override
  Future<void> onLoad() async {
    art = game.art;
    await buildInteractStage();
  }

  /// Drives the interact sim while the interact beat is live. The host's overlay
  /// drives setup/discover/itClicks/apply pacing; only the interaction ticks.
  @override
  void update(double dt) {
    super.update(dt);
    controller.tick(dt);
  }

  // ===========================================================================
  // Beat wiring (called by the host / overlay)
  // ===========================================================================

  /// Transition from Setup -> Interact: build the leaf's sim, attach it to the
  /// controller (which starts it + begins scoring), and let the stage react.
  void beginInteract() {
    if (_sim != null) return;
    final ActivitySim sim = buildInteractSim();
    _sim = sim;
    controller.beginInteract(sim);
    onInteractStarted();
  }

  /// Forward a discrete player input into the controller (which enforces
  /// maxInputs + routes it to the sim). Stages call this from their props.
  void sendInput(SimInput input) => controller.sendInput(input);

  /// Re-arm a fresh attempt after a non-fatal failure.
  void retry() {
    controller.retry();
    onRetry();
  }

  // ===========================================================================
  // Completion
  // ===========================================================================

  /// Build the immutable result and hand it to the host exactly once. The host
  /// dispatches CompleteActivity (reducer) + exits the scene.
  void finishWithResult(ActivityResult result) {
    if (_finished) return;
    _finished = true;
    onFinished?.call(result);
  }

  /// Convenience: build the result straight from the controller's recorded run.
  void finish() => finishWithResult(controller.buildResult());

  // ===========================================================================
  // Leaf overrides — the ONLY methods a concept scene implements.
  // ===========================================================================

  /// The interact-beat brain. Called once when the interaction begins.
  ActivitySim buildInteractSim();

  /// Build the bespoke Flame props for the interaction (uses [art]'s primitive
  /// toolkit so no new closed art key is ever needed). Called from onLoad. Build
  /// stage props centred on game.size/2 — the host frames the activity camera
  /// there (see [EmberGame.enterActivity]) so the stage sits centred on screen.
  Future<void> buildInteractStage();

  // ---- Optional lifecycle hooks (no-op defaults) -------------------------

  /// Called right after the interact sim has started (stage can animate in).
  void onInteractStarted() {}

  /// Called when the player retries after a failure (stage can reset props).
  void onRetry() {}

  /// Optional bespoke Flutter chrome for the INTERACT beat, mounted FULL-SCREEN
  /// (Positioned.fill) over the Flame stage by the host's [ActivityPhaseOverlay].
  /// Because it owns the whole screen — and world pan/zoom is disabled during an
  /// activity (EmberGame.onScaleUpdate early-returns when inActivity) — the leaf
  /// can lay a TRANSPARENT full-area gesture surface that maps finger drags
  /// straight onto its on-stage Flame props (one finger drives one hero variable,
  /// the prop answers that frame), and WITHIN that same layer anchor its own
  /// bottom EmberCaption + any small non-physical controls + retry. The leaf is
  /// fully responsible for its layout (e.g. wrap chrome in Align(bottomCenter) +
  /// SafeArea); the host adds no padding, constraints, or alignment of its own.
  ///
  /// Return null to let the Flame stage own the interaction entirely (inputs via
  /// in-canvas props + the host's thin bottom hint strip).
  Widget? buildInteractOverlay(BuildContext context) => null;

  @override
  void onRemove() {
    // NOTE: the sim's lifecycle is owned by the [BeatController] (it disposes the
    // sim it was attached in beginInteract). The host disposes the controller
    // when the activity ends, so we DON'T dispose here — that would double-close
    // the leaf's event stream. We only drop our reference.
    _sim = null;
    super.onRemove();
  }
}
