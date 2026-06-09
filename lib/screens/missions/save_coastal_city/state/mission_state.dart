// Immutable state for Save the Coastal City. One [MissionState] object owned
// by MissionStageController; scenes/games rebuild off it via Listenable.
// Per-stage sub-states keep the 8-mechanic union navigable. One-shot FX use
// bump-token ints (never bools that need resetting — playbook rule).

import '../config/scc_dialogue.dart';
import '../config/scc_stage_configs.dart';

export '../config/scc_stage_configs.dart' show MissionStage;

// ── Stage 1 · scanner ────────────────────────────────────────────────────────

class ScannerSub {
  final Set<SatKind> discovered;
  final SatKind? lastScanned; // most recently scanned → bound to the deploy CTA
  final bool deployed;
  const ScannerSub({this.discovered = const {}, this.lastScanned, this.deployed = false});

  ScannerSub copyWith({Set<SatKind>? discovered, SatKind? lastScanned, bool? deployed}) =>
      ScannerSub(
        discovered: discovered ?? this.discovered,
        lastScanned: lastScanned ?? this.lastScanned,
        deployed: deployed ?? this.deployed,
      );
}

// ── Stage 2 · orbit slingshot ────────────────────────────────────────────────

enum SlingPhase { aiming, flying, locked }

enum SlingOutcome { none, tooLow, tooFar, almost, locked }

class OrbitSub {
  final SlingPhase phase;
  final SlingOutcome outcome; // outcome of the CURRENT flight (valid when flying)
  final double strength; // normalized release strength of the current flight
  final int flightToken; // bump → the game launches one flight
  const OrbitSub({
    this.phase = SlingPhase.aiming,
    this.outcome = SlingOutcome.none,
    this.strength = 0,
    this.flightToken = 0,
  });

  OrbitSub copyWith({SlingPhase? phase, SlingOutcome? outcome, double? strength, int? flightToken}) =>
      OrbitSub(
        phase: phase ?? this.phase,
        outcome: outcome ?? this.outcome,
        strength: strength ?? this.strength,
        flightToken: flightToken ?? this.flightToken,
      );
}

// ── Stage 3 · power ──────────────────────────────────────────────────────────

enum PowerPhase {
  aligning, // rotate the dial toward the Sun
  shadowWarning, // strong charge held → warning lines
  countdown, // 3…2…1
  shadow, // in shadow — lever window open
  stabilized, // lever pulled in time, power stable
  done,
}

class PowerSub {
  final PowerPhase phase;
  final double panelAngleDeg; // dial-controlled panel tilt
  final double power; // 0..1 meter
  final int countdown; // 3..1 during PowerPhase.countdown
  final bool leverPulled;
  final bool leverEarly; // pulled before shadow — forgiven, slightly drained
  const PowerSub({
    this.phase = PowerPhase.aligning,
    this.panelAngleDeg = 110,
    this.power = 0.18,
    this.countdown = 3,
    this.leverPulled = false,
    this.leverEarly = false,
  });

  PowerSub copyWith(
          {PowerPhase? phase,
          double? panelAngleDeg,
          double? power,
          int? countdown,
          bool? leverPulled,
          bool? leverEarly}) =>
      PowerSub(
        phase: phase ?? this.phase,
        panelAngleDeg: panelAngleDeg ?? this.panelAngleDeg,
        power: power ?? this.power,
        countdown: countdown ?? this.countdown,
        leverPulled: leverPulled ?? this.leverPulled,
        leverEarly: leverEarly ?? this.leverEarly,
      );
}

// ── Stage 4 · camera scope ───────────────────────────────────────────────────

enum CameraPhase { exploring, locked, captured }

/// What's wrong right now (drives which PRD hint plays).
enum CameraAimState { notCentered, tooZoomedIn, tooZoomedOut, locked }

class CameraSub {
  final CameraPhase phase;
  final CameraAimState aim;
  final int flashToken; // bump → scanline + white flash plays
  const CameraSub({
    this.phase = CameraPhase.exploring,
    this.aim = CameraAimState.notCentered,
    this.flashToken = 0,
  });

  CameraSub copyWith({CameraPhase? phase, CameraAimState? aim, int? flashToken}) => CameraSub(
        phase: phase ?? this.phase,
        aim: aim ?? this.aim,
        flashToken: flashToken ?? this.flashToken,
      );
}

// ── Stage 5 · signal ─────────────────────────────────────────────────────────

enum SignalPhase { tuning, locked, sending, done }

class SignalSub {
  final SignalPhase phase;
  final double aimDeg; // antenna beam angle (degrees, stage-local convention)
  final double freq; // tuner knob 0..1
  final double holdProgress; // 0..1 of the steady-hold timer
  final int packetToken; // bump → packet stream animation
  const SignalSub({
    this.phase = SignalPhase.tuning,
    this.aimDeg = 18,
    this.freq = 0.18,
    this.holdProgress = 0,
    this.packetToken = 0,
  });

  SignalSub copyWith(
          {SignalPhase? phase, double? aimDeg, double? freq, double? holdProgress, int? packetToken}) =>
      SignalSub(
        phase: phase ?? this.phase,
        aimDeg: aimDeg ?? this.aimDeg,
        freq: freq ?? this.freq,
        holdProgress: holdProgress ?? this.holdProgress,
        packetToken: packetToken ?? this.packetToken,
      );
}

// ── Stage 6 · analysis ───────────────────────────────────────────────────────

enum AnalysisPhase { exploring, found }

class AnalysisSub {
  final AnalysisPhase phase;
  final int layer; // 0 cloud · 1 rain/heat · 2 wind
  final Set<int> visitedLayers;
  final int wrongToken; // bump → drawn-circle rejected shake
  const AnalysisSub({
    this.phase = AnalysisPhase.exploring,
    this.layer = 0,
    this.visitedLayers = const {0},
    this.wrongToken = 0,
  });

  AnalysisSub copyWith({AnalysisPhase? phase, int? layer, Set<int>? visitedLayers, int? wrongToken}) =>
      AnalysisSub(
        phase: phase ?? this.phase,
        layer: layer ?? this.layer,
        visitedLayers: visitedLayers ?? this.visitedLayers,
        wrongToken: wrongToken ?? this.wrongToken,
      );
}

// ── Stage 7 · thermal repair ─────────────────────────────────────────────────

enum RepairStep { trace, radiator, switchOff, done }

class RepairSub {
  final RepairStep step;
  final double temp; // °C on the meter
  final double radiatorDeg; // current ring rotation
  final bool boostOn;
  final int sparkToken; // bump → wrong-trace spark
  const RepairSub({
    this.step = RepairStep.trace,
    this.temp = 92,
    this.radiatorDeg = 40,
    this.boostOn = true,
    this.sparkToken = 0,
  });

  RepairSub copyWith({RepairStep? step, double? temp, double? radiatorDeg, bool? boostOn, int? sparkToken}) =>
      RepairSub(
        step: step ?? this.step,
        temp: temp ?? this.temp,
        radiatorDeg: radiatorDeg ?? this.radiatorDeg,
        boostOn: boostOn ?? this.boostOn,
        sparkToken: sparkToken ?? this.sparkToken,
      );
}

// ── Stage 8 · command upload ─────────────────────────────────────────────────

enum CommandPhase { connecting, readyToUpload, uploading, done }

class CommandSub {
  final CommandPhase phase;
  /// Only CORRECT connections persist, so the path is always a prefix of
  /// [kCommandSequence] — this count fully describes it.
  final int connected;
  final double uploadProgress; // 0..1 during the hold
  final int wrongToken; // bump → red spark on the rejected line
  final CommandNode? wrongTarget; // which node the rejected line aimed at
  const CommandSub({
    this.phase = CommandPhase.connecting,
    this.connected = 0,
    this.uploadProgress = 0,
    this.wrongToken = 0,
    this.wrongTarget,
  });

  CommandSub copyWith(
          {CommandPhase? phase,
          int? connected,
          double? uploadProgress,
          int? wrongToken,
          CommandNode? wrongTarget}) =>
      CommandSub(
        phase: phase ?? this.phase,
        connected: connected ?? this.connected,
        uploadProgress: uploadProgress ?? this.uploadProgress,
        wrongToken: wrongToken ?? this.wrongToken,
        wrongTarget: wrongTarget ?? this.wrongTarget,
      );
}

// ── Finale (mission-complete card screen) ────────────────────────────────────

class FinaleSub {
  /// Continue lights up after the mission-control payoff lines have had
  /// reading time (listen-before-skip).
  final bool continueEnabled;
  const FinaleSub({this.continueEnabled = false});
  FinaleSub copyWith({bool? continueEnabled}) =>
      FinaleSub(continueEnabled: continueEnabled ?? this.continueEnabled);
}

// ── Badge reveal ─────────────────────────────────────────────────────────────

class BadgeSub {
  final int revealed; // how many of kBadgeOrder are visible
  final bool continueEnabled;
  const BadgeSub({this.revealed = 0, this.continueEnabled = false});
  BadgeSub copyWith({int? revealed, bool? continueEnabled}) =>
      BadgeSub(revealed: revealed ?? this.revealed, continueEnabled: continueEnabled ?? this.continueEnabled);
}

// ── Root state ───────────────────────────────────────────────────────────────

class MissionState {
  final MissionStage stage;
  final Set<MissionStage> completed;
  /// "Warning readiness" narrative meter, 0..100 (PRD §23.3 — stakes without
  /// anxiety; rises as stages complete, never falls, no real timer).
  final int readiness;

  // Orbit dialogue (rendered by MissionDialogueOverlay).
  final String dialogueText;
  final OrbitFace face;
  final int dialogueToken; // bumps per line → bubble swap animation
  final int? voiceClip; // VO hook — always null in the text-only build
  final int voiceToken;

  final ScannerSub scanner;
  final OrbitSub orbit;
  final PowerSub power;
  final CameraSub camera;
  final SignalSub signal;
  final AnalysisSub analysis;
  final RepairSub repair;
  final CommandSub command;
  final FinaleSub finale;
  final BadgeSub badges;

  final bool soundOn;

  const MissionState({
    this.stage = MissionStage.intro,
    this.completed = const {},
    this.readiness = 5,
    this.dialogueText = '',
    this.face = OrbitFace.neutral,
    this.dialogueToken = 0,
    this.voiceClip,
    this.voiceToken = 0,
    this.scanner = const ScannerSub(),
    this.orbit = const OrbitSub(),
    this.power = const PowerSub(),
    this.camera = const CameraSub(),
    this.signal = const SignalSub(),
    this.analysis = const AnalysisSub(),
    this.repair = const RepairSub(),
    this.command = const CommandSub(),
    this.finale = const FinaleSub(),
    this.badges = const BadgeSub(),
    this.soundOn = true,
  });

  MissionState copyWith({
    MissionStage? stage,
    Set<MissionStage>? completed,
    int? readiness,
    String? dialogueText,
    OrbitFace? face,
    int? dialogueToken,
    int? voiceClip,
    int? voiceToken,
    ScannerSub? scanner,
    OrbitSub? orbit,
    PowerSub? power,
    CameraSub? camera,
    SignalSub? signal,
    AnalysisSub? analysis,
    RepairSub? repair,
    CommandSub? command,
    FinaleSub? finale,
    BadgeSub? badges,
    bool? soundOn,
  }) {
    return MissionState(
      stage: stage ?? this.stage,
      completed: completed ?? this.completed,
      readiness: readiness ?? this.readiness,
      dialogueText: dialogueText ?? this.dialogueText,
      face: face ?? this.face,
      dialogueToken: dialogueToken ?? this.dialogueToken,
      voiceClip: voiceClip ?? this.voiceClip,
      voiceToken: voiceToken ?? this.voiceToken,
      scanner: scanner ?? this.scanner,
      orbit: orbit ?? this.orbit,
      power: power ?? this.power,
      camera: camera ?? this.camera,
      signal: signal ?? this.signal,
      analysis: analysis ?? this.analysis,
      repair: repair ?? this.repair,
      command: command ?? this.command,
      finale: finale ?? this.finale,
      badges: badges ?? this.badges,
      soundOn: soundOn ?? this.soundOn,
    );
  }
}
