// Immutable state for Code the Satellite. The controller replaces this object
// wholesale and notifies; the UI rebuilds via AnimatedBuilder. Lists are copied
// on write so a held reference never mutates underneath a frame.

import '../config/asset_paths.dart';
import '../models/satellite_command.dart';

/// High-level activity phase (PRD §17).
enum Activity10Phase {
  storyIntro,
  missionBrief,
  arranging,
  running,
  failed,
  success,
}

/// Which scene "group" a phase belongs to, for the AnimatedSwitcher key.
/// arranging + running + failed all share the `play` scene (failure is an
/// overlay over the puzzle, not a remount) — per the playbook's scene-key rule.
enum SceneGroup { intro, brief, play, success }

extension Activity10PhaseX on Activity10Phase {
  SceneGroup get sceneGroup {
    switch (this) {
      case Activity10Phase.storyIntro:
        return SceneGroup.intro;
      case Activity10Phase.missionBrief:
        return SceneGroup.brief;
      case Activity10Phase.arranging:
      case Activity10Phase.running:
      case Activity10Phase.failed:
        return SceneGroup.play;
      case Activity10Phase.success:
        return SceneGroup.success;
    }
  }
}

/// Orbit's expression. Each maps to one mascot sprite.
enum OrbitMood {
  idle,
  welcoming,
  pointing,
  explaining,
  alert,
  thinking,
  debug,
  celebrate,
  successJump,
}

extension OrbitMoodX on OrbitMood {
  String get asset {
    switch (this) {
      case OrbitMood.idle:
        return CS.orbitIdle;
      case OrbitMood.welcoming:
        return CS.orbitWave;
      case OrbitMood.pointing:
        return CS.orbitPointing;
      case OrbitMood.explaining:
        return CS.orbitExplaining;
      case OrbitMood.alert:
        return CS.orbitAlert;
      case OrbitMood.thinking:
        return CS.orbitThinking;
      case OrbitMood.debug:
        return CS.orbitDebug;
      case OrbitMood.celebrate:
        return CS.orbitCelebrate;
      case OrbitMood.successJump:
        return CS.orbitSuccessJump;
    }
  }
}

class CodeSatelliteState {
  final Activity10Phase phase;

  /// The 9 ordered slots being built (null = empty).
  final List<SatelliteCommand?> slots;

  /// Commands not yet placed, in display order.
  final List<SatelliteCommand> tray;

  /// The step currently executing (highlight), or null.
  final int? activeStepIndex;

  /// The step that failed validation (error state), or null.
  final int? failedStepIndex;

  /// Slots proven correct so far (green) — also the placed-in-order steps while
  /// arranging.
  final Set<int> correctSteps;

  /// Slot currently flashing red because a wrong command was dropped on it
  /// (guided arranging). Cleared after a short delay.
  final int? wrongSlotIndex;

  final String? failureMessage;

  /// Orbit dialogue.
  final OrbitMood mascot;
  final String message;

  /// True once the picture is taken during a run (drives the captured-image
  /// thumbnail overlay; "No image available" until then — see mockup 2).
  final bool imageCaptured;

  /// Debug step-through: the run is paused after a command, waiting for a
  /// "Next Step" tap (only when CSDebug.stepThrough is on).
  final bool awaitingNextStep;

  /// Bumped each time the picture is taken — triggers the capture cinematic
  /// (big photo → fly to the thumbnail). Survives replays.
  final int photoToken;

  /// Orbit voice-over: the clip to play for the current [message] (stamped by
  /// the controller's choke point) + a token bumped on every stamp so repeated
  /// identical lines still re-trigger. The shell plays when the token changes.
  final int? voiceClip;
  final int voiceToken;

  /// True while a voice line is in flight (gates primary CTAs).
  final bool voicePlaying;

  const CodeSatelliteState({
    required this.phase,
    required this.slots,
    required this.tray,
    this.activeStepIndex,
    this.failedStepIndex,
    this.correctSteps = const {},
    this.wrongSlotIndex,
    this.failureMessage,
    this.mascot = OrbitMood.idle,
    this.message = '',
    this.imageCaptured = false,
    this.awaitingNextStep = false,
    this.photoToken = 0,
    this.voiceClip,
    this.voiceToken = 0,
    this.voicePlaying = false,
  });

  bool get allSlotsFilled => slots.every((c) => c != null);
  int get filledCount => slots.where((c) => c != null).length;
  bool get isRunning => phase == Activity10Phase.running;
  bool get canRun => phase == Activity10Phase.arranging && allSlotsFilled;

  /// In guided arranging, the next slot to fill (left-to-right). Null if full
  /// or not arranging.
  int? get activeSlotIndex {
    if (phase != Activity10Phase.arranging) return null;
    final i = filledCount;
    return i < slots.length ? i : null;
  }

  CodeSatelliteState copyWith({
    Activity10Phase? phase,
    List<SatelliteCommand?>? slots,
    List<SatelliteCommand>? tray,
    int? activeStepIndex,
    int? failedStepIndex,
    Set<int>? correctSteps,
    int? wrongSlotIndex,
    String? failureMessage,
    OrbitMood? mascot,
    String? message,
    bool? imageCaptured,
    bool? awaitingNextStep,
    int? photoToken,
    int? voiceClip,
    int? voiceToken,
    bool? voicePlaying,
    bool clearActive = false,
    bool clearFailed = false,
    bool clearWrong = false,
    bool clearFailureMessage = false,
  }) {
    return CodeSatelliteState(
      phase: phase ?? this.phase,
      slots: slots ?? this.slots,
      tray: tray ?? this.tray,
      activeStepIndex: clearActive ? null : (activeStepIndex ?? this.activeStepIndex),
      failedStepIndex: clearFailed ? null : (failedStepIndex ?? this.failedStepIndex),
      correctSteps: correctSteps ?? this.correctSteps,
      wrongSlotIndex: clearWrong ? null : (wrongSlotIndex ?? this.wrongSlotIndex),
      failureMessage: clearFailureMessage ? null : (failureMessage ?? this.failureMessage),
      mascot: mascot ?? this.mascot,
      message: message ?? this.message,
      imageCaptured: imageCaptured ?? this.imageCaptured,
      awaitingNextStep: awaitingNextStep ?? this.awaitingNextStep,
      photoToken: photoToken ?? this.photoToken,
      voiceClip: voiceClip ?? this.voiceClip,
      voiceToken: voiceToken ?? this.voiceToken,
      voicePlaying: voicePlaying ?? this.voicePlaying,
    );
  }
}
