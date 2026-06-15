// Ember — activity/beat_controller.dart
//
// The reusable 5-beat state machine every activity walks: setup -> interact ->
// discover -> itClicks -> apply. It subscribes to an ActivitySim's event stream,
// scores those events against the activity's InteractionRules/SuccessCriteria,
// tracks attempts / failuresSeen / qualityStars, and finally buildResult() →
// ActivityResult for the reducer. ChangeNotifier (flutter/foundation) ONLY — no
// Flame, no Riverpod, no clock/random. The host UI listens and renders each beat;
// the ActivityScene (F4) wires this to its visuals.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/enums.dart';
import 'activity_contract.dart';
import 'activity_result.dart';
import 'activity_sim.dart';
import 'apply_effect.dart';

/// Drives one activity's 5-beat arc and grades the run.
class BeatController extends ChangeNotifier {
  BeatController(this.activity);

  /// The activity being played.
  final EmberActivity activity;

  // ---- Beat state --------------------------------------------------------
  ActivityBeat _beat = ActivityBeat.setup;
  ActivityBeat get beat => _beat;

  // ---- Run tracking ------------------------------------------------------
  int _attempts = 0;
  int get attempts => _attempts;

  final Set<String> _failuresSeen = <String>{};
  Set<String> get failuresSeen => Set<String>.unmodifiable(_failuresSeen);

  int _inputsUsed = 0;
  int get inputsUsed => _inputsUsed;

  bool _succeeded = false;
  bool get succeeded => _succeeded;

  int _qualityStars = 0;
  int get qualityStars => _qualityStars;

  /// The latest failure hint to surface (null if none pending).
  String? _activeHint;
  String? get activeHint => _activeHint;

  /// The most recent event message (for ambient feedback in the scene).
  String _lastMessage = '';
  String get lastMessage => _lastMessage;

  /// Optional placement hint a scene can set before completion.
  PlaceHint? placeHint;

  // ---- Wiring to the interact sim ----------------------------------------
  ActivitySim? _sim;
  StreamSubscription<SimEvent>? _sub;

  /// True once the interact sim is attached + started.
  bool get isInteractive => _sim != null;

  // ---- Beat transitions --------------------------------------------------

  /// Advance from setup -> interact, attaching [sim] and starting it with the
  /// activity's rules. The controller now scores [sim]'s events.
  void beginInteract(ActivitySim sim) {
    _sim = sim;
    _sub?.cancel();
    _sub = sim.events.listen(_onSimEvent);
    sim.start(activity.interactionRules);
    _attempts += 1; // entering the interaction is the first attempt
    _setBeat(ActivityBeat.interact);
  }

  /// Forward a player input to the interact sim, enforcing maxInputs.
  void sendInput(SimInput input) {
    final ActivitySim? sim = _sim;
    if (sim == null || _beat != ActivityBeat.interact) return;
    final int cap = activity.interactionRules.maxInputs;
    if (cap > 0 && _inputsUsed >= cap) {
      _registerFailure(
        const FailureRule(
          id: 'out_of_inputs',
          signal: '_synthetic_',
          hint: 'You are out of tries for this attempt.',
        ),
      );
      return;
    }
    _inputsUsed += 1;
    sim.onInput(input);
  }

  /// Tick the interact sim (called each frame by the scene).
  void tick(double dtSeconds) {
    if (_beat == ActivityBeat.interact) {
      _sim?.tick(dtSeconds);
    }
  }

  /// Start a fresh attempt after a non-fatal failure (re-arms inputs).
  void retry() {
    if (_beat != ActivityBeat.interact) return;
    _attempts += 1;
    _inputsUsed = 0;
    _activeHint = null;
    _sim?.start(activity.interactionRules);
    notifyListeners();
  }

  /// Manually move from discover -> itClicks (the "ohh!" reveal pacing is UI-led).
  void revealClick() {
    if (_beat == ActivityBeat.discover) {
      _setBeat(ActivityBeat.itClicks);
    }
  }

  /// Move from itClicks -> apply (the final beat, where effects land).
  void proceedToApply() {
    if (_beat == ActivityBeat.itClicks) {
      _setBeat(ActivityBeat.apply);
    }
  }

  // ---- Event scoring -----------------------------------------------------

  void _onSimEvent(SimEvent e) {
    _lastMessage = e.message;
    final InteractionRules rules = activity.interactionRules;

    // Success first: if the success signal fires we win the interaction.
    if (e.code == rules.successSignal) {
      _onSuccess();
      return;
    }

    // Then failure rules.
    for (final FailureRule r in rules.failureRules) {
      if (r.signal == e.code) {
        _registerFailure(r);
        return;
      }
    }

    // Otherwise it's an ambient event — just refresh listeners.
    notifyListeners();
  }

  void _onSuccess() {
    _succeeded = true;
    _qualityStars = _grade();
    // Detach the sim's stream; the interaction is over.
    _sub?.cancel();
    _sub = null;
    _setBeat(ActivityBeat.discover);
  }

  void _registerFailure(FailureRule r) {
    _failuresSeen.add(r.id);
    _activeHint = r.hint;
    if (r.fatal) {
      // Fatal failure ends the attempt; UI offers retry.
      _inputsUsed = activity.interactionRules.maxInputs;
    }
    notifyListeners();
  }

  /// Grades the run 0..3 stars against SuccessCriteria.
  int _grade() {
    final SuccessCriteria c = activity.successCriteria;
    if (c.requireSuccessSignal && !_succeeded) return 0;
    final int f = _failuresSeen.length;
    if (_attempts <= c.threeStarMaxAttempts && f <= c.threeStarMaxFailures) {
      return 3;
    }
    if (_attempts <= c.twoStarMaxAttempts && f <= c.twoStarMaxFailures) {
      return 2;
    }
    return 1;
  }

  void _setBeat(ActivityBeat b) {
    if (_beat == b) return;
    _beat = b;
    notifyListeners();
  }

  // ---- Debug-only deterministic advance ----------------------------------

  /// DEBUG-ONLY: synthesize the interaction's success WITHOUT replaying the sim,
  /// so the self-driving tour (EMBER_TOUR) can advance setup/interact -> discover
  /// deterministically for automated capture. It runs the SAME success path the
  /// real `successSignal` would (`_onSuccess`: mark succeeded, grade, detach the
  /// sim stream, move to discover). It never touches the world and is only ever
  /// called from the debug tour — normal play is unchanged (no caller exists).
  ///
  /// No-op unless currently in setup or interact (so it can't skip the payoff
  /// beats). When called from setup it counts the entry as the first attempt so
  /// grading still yields a sensible star result.
  void debugForceSuccess() {
    if (_beat != ActivityBeat.setup && _beat != ActivityBeat.interact) return;
    if (_attempts == 0) _attempts = 1; // grading expects >=1 attempt.
    _onSuccess();
  }

  // ---- Result ------------------------------------------------------------

  /// Builds the immutable [ActivityResult] for the reducer. Includes the
  /// activity's declared effects (+ a model-upgrade effect + codex grants +
  /// mark-done) so the reducer is a pure dispatch over ApplyEffect.
  ActivityResult buildResult() {
    final List<ApplyEffect> effects = <ApplyEffect>[
      ...activity.unlocks,
      for (final String entryId in activity.codexEntryIds)
        GrantCodexEntry(entryId),
      if (activity.modelUpgrade != null) UpgradeModel(activity.conceptId),
      if (_succeeded) MarkConceptDone(activity.conceptId),
    ];
    final List<String> flags = <String>[
      for (final ApplyEffect e in effects)
        if (e is SetKnowledgeFlag && e.value) e.flag,
      if (activity.modelUpgrade != null) activity.modelUpgrade!.flag,
    ];
    return ActivityResult(
      activityId: activity.id,
      conceptId: activity.conceptId,
      completed: _succeeded,
      qualityStars: _qualityStars,
      attempts: _attempts,
      failuresSeen: _failuresSeen.toList()..sort(),
      effects: effects,
      knowledgeFlags: flags,
      placeHint: placeHint,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _sub = null;
    _sim?.dispose();
    _sim = null;
    super.dispose();
  }
}
