// Declarative per-stage content for Save the Coastal City: titles, progress
// rail nodes, tuning thresholds, and the Stage-1 satellite catalog + Stage-8
// command-node graph. Content lives here, logic lives in state/ — reskinning
// or retuning a stage is an edit to this file only.

import 'package:flutter/material.dart';

import 'scc_assets.dart';
import 'scc_dialogue.dart';

/// PRD §7.2 — the master stage state machine.
enum MissionStage {
  intro,
  chooseSatellite,
  placeOrbit,
  powerManagement,
  captureImage,
  sendData,
  readImage,
  repairIssue,
  uploadCommands,
  finalSuccess,
  badgeReveal,
}

/// The 8 playable stages, in progress-rail order (PRD §8).
const kPlayableStages = [
  MissionStage.chooseSatellite,
  MissionStage.placeOrbit,
  MissionStage.powerManagement,
  MissionStage.captureImage,
  MissionStage.sendData,
  MissionStage.readImage,
  MissionStage.repairIssue,
  MissionStage.uploadCommands,
];

class StageInfo {
  final String railLabel; // short label under the rail node (PRD §8)
  final String title; // stage header (storyboard frames)
  final IconData railIcon;
  final String analyticsId;
  const StageInfo(this.railLabel, this.title, this.railIcon, this.analyticsId);
}

const kStageInfo = <MissionStage, StageInfo>{
  MissionStage.chooseSatellite:
      StageInfo('Satellite', 'CHOOSE THE RIGHT SATELLITE', Icons.satellite_alt_rounded, 'choose_satellite'),
  MissionStage.placeOrbit:
      StageInfo('Orbit', 'PLACE IT IN THE RIGHT ORBIT', Icons.track_changes_rounded, 'place_orbit'),
  MissionStage.powerManagement:
      StageInfo('Power', 'KEEP IT POWERED', Icons.bolt_rounded, 'power_management'),
  MissionStage.captureImage:
      StageInfo('Image', 'CAPTURE THE CYCLONE IMAGE', Icons.photo_camera_rounded, 'capture_image'),
  MissionStage.sendData:
      StageInfo('Signal', 'SEND DATA TO EARTH', Icons.wifi_tethering_rounded, 'send_data'),
  MissionStage.readImage:
      StageInfo('Analysis', 'READ THE SATELLITE IMAGE', Icons.search_rounded, 'read_image'),
  MissionStage.repairIssue:
      StageInfo('Repair', 'FIX THE SURPRISE ISSUE', Icons.build_rounded, 'repair_issue'),
  MissionStage.uploadCommands:
      StageInfo('Commands', 'UPLOAD COMMAND SEQUENCE', Icons.code_rounded, 'upload_commands'),
};

// ─────────────────────────────────────────────────────────────────────────────
// Stage 1 · satellite catalog (PRD §12.3)
// ─────────────────────────────────────────────────────────────────────────────

enum SatKind { navigation, communication, earthScan, weather }

class SatDef {
  final SatKind kind;
  final String name;
  final String power; // one-line "what it does" revealed on scan
  final String sprite;
  final List<Line> scanLines; // Orbit explanation when scanned
  final Color glow;
  const SatDef(this.kind, this.name, this.power, this.sprite, this.scanLines, this.glow);
}

const kSatCatalog = [
  SatDef(SatKind.navigation, 'NAVIGATION SATELLITE', 'Finds position and routes.',
      SCC.holoNav, SccDialogue.s1Nav, Color(0xFF2FD9FF)),
  SatDef(SatKind.communication, 'COMMUNICATION SATELLITE', 'Sends signals and messages.',
      SCC.holoComm, SccDialogue.s1Comm, Color(0xFF35E07B)),
  SatDef(SatKind.earthScan, 'EARTH SCAN SATELLITE', 'Scans land and helps grow crops.',
      SCC.holoEarthScan, SccDialogue.s1EarthScan, Color(0xFFFFB020)),
  SatDef(SatKind.weather, 'WEATHER SATELLITE', 'Watches clouds and storms.',
      SCC.satWeatherHolo, SccDialogue.s1Weather, Color(0xFFB05CFF)),
];

// ─────────────────────────────────────────────────────────────────────────────
// Stage 2 · slingshot outcome bands (PRD §13.5–13.6, generous windows)
// ─────────────────────────────────────────────────────────────────────────────

class SlingshotTuning {
  // Release strength is the normalized pull distance 0..1.
  // Bands: < lowMax → tooLow; > farMin → tooFar; correct in between, and
  // anything within snapMargin of the band is "almost" + snapped when close.
  static const double lowMax = 0.40;
  static const double farMin = 0.78;
  static const double snapMargin = 0.07; // near-miss → "almost" hint
  static const double minPull = 0.12; // ignore accidental taps
}

// ─────────────────────────────────────────────────────────────────────────────
// Stage 3 · power thresholds (PRD §14.5 suggested logic, verbatim)
// ─────────────────────────────────────────────────────────────────────────────

class PowerTuning {
  static const double strongAlignment = 0.8; // > → strong charging
  static const double partialAlignment = 0.5; // 0.5–0.8 partial
  static const double sunAngleDeg = 38; // where the Sun sits (from vertical)
  static const double maxAllowedAngleDeg = 80; // alignment formula denominator
  static const double holdStrongSeconds = 1.6; // strong charge dwell → shadow event
  static const int shadowCountdownSeconds = 3;
  static const double leverWindowSeconds = 3.0; // on-time window after shadow hits
  static const double criticalPower = 0.25; // meter must stay above this
}

// ─────────────────────────────────────────────────────────────────────────────
// Stage 4 · camera scope (PRD §15.5)
// ─────────────────────────────────────────────────────────────────────────────

class CameraTuning {
  /// Cyclone EYE inside the pannable SCC.scopeContent image, as factors of
  /// the image rect (measured programmatically — darkest point inside the
  /// bright cloud ring).
  static const Offset cycloneCenter = Offset(0.277, 0.622);
  static const double zoomMin = 1.0;
  static const double zoomMax = 3.2;
  static const double zoomIdealMin = 1.7;
  static const double zoomIdealMax = 2.6;
  /// How close (fraction of scope size) the cyclone must be to the reticle.
  static const double centerTolerance = 0.13;
}

// ─────────────────────────────────────────────────────────────────────────────
// Stage 5 · signal tuning (PRD §16.5)
// ─────────────────────────────────────────────────────────────────────────────

class SignalTuning {
  static const double aimToleranceDeg = 9; // beam-hits-dish window (generous)
  static const double freqTarget = 0.62; // knob position 0..1 that's clean
  static const double freqTolerance = 0.09;
  static const double holdSeconds = 1.6; // both-good steady hold
}

// ─────────────────────────────────────────────────────────────────────────────
// Stage 6 · analysis circle validation (PRD §17.5 suggested logic)
// ─────────────────────────────────────────────────────────────────────────────

class AnalysisTuning {
  /// Cyclone target zone (factors of the panel AREA). The generated layers
  /// share one eye position — image (0.419, 0.511) ≈ area (0.40, 0.51) under
  /// the panel's cover-fit.
  static const Offset cycloneCenter = Offset(0.40, 0.51);
  static const double cycloneRadius = 0.30; // factor of area width
  static const double minOverlap = 0.60; // PRD: >60% overlap → success
  /// "Close" band — centre inside 1.6× radius gives the close hint.
  static const double closeFactor = 1.6;
  static const double minCirclePoints = 14; // enough of a drawn loop
}

// ─────────────────────────────────────────────────────────────────────────────
// Stage 7 · thermal repair (PRD §18.5)
// ─────────────────────────────────────────────────────────────────────────────

class RepairTuning {
  static const double startTemp = 92; // °C on the meter at alert
  static const double afterTraceTemp = 74;
  static const double afterRadiatorTemp = 55;
  static const double safeTemp = 36; // green zone after switch-off
  /// Radiator must point into the away-from-Sun half. The Sun indicator sits
  /// top-right of the board (screen angle −45° ≡ 315°), so pointing AWAY is
  /// 135° (down-left in screen coords, y-down).
  static const double radiatorTargetDeg = 135;
  static const double radiatorToleranceDeg = 40;
}

// ─────────────────────────────────────────────────────────────────────────────
// Stage 8 · command graph (PRD §19.3, §19.5)
// ─────────────────────────────────────────────────────────────────────────────

enum CommandNode { watchStorm, captureImage, sendData, checkBattery, repeatMonitoring, alertCity }

/// The single correct path (PRD §19.3).
const kCommandSequence = [
  CommandNode.watchStorm,
  CommandNode.captureImage,
  CommandNode.sendData,
  CommandNode.checkBattery,
  CommandNode.repeatMonitoring,
  CommandNode.alertCity,
];

class CommandDef {
  final CommandNode node;
  final String label;
  final String sprite;
  /// Position on the command board, factors of the board rect (mock: 2-column
  /// zig-zag circuit path — storyboard panel 8).
  final Offset anchor;
  const CommandDef(this.node, this.label, this.sprite, this.anchor);
}

const kCommandDefs = [
  CommandDef(CommandNode.watchStorm, 'WATCH\nSTORM', SCC.nodeWatchStorm, Offset(0.24, 0.14)),
  CommandDef(CommandNode.captureImage, 'CAPTURE\nIMAGE', SCC.nodeCaptureImage, Offset(0.76, 0.14)),
  CommandDef(CommandNode.sendData, 'SEND\nDATA', SCC.nodeSendData, Offset(0.24, 0.50)),
  CommandDef(CommandNode.checkBattery, 'CHECK\nBATTERY', SCC.nodeCheckBattery, Offset(0.76, 0.50)),
  CommandDef(CommandNode.repeatMonitoring, 'REPEAT\nMONITORING', SCC.nodeRepeatMonitoring, Offset(0.24, 0.86)),
  CommandDef(CommandNode.alertCity, 'ALERT\nCITY', SCC.nodeAlertCity, Offset(0.76, 0.86)),
];

/// Which conceptual mistake a wrong connection represents → hint lines
/// (PRD §19.7 — alert too early / skip battery / skip repeat). [expected] is
/// the next node the correct sequence wants, [attempted] what the child drew.
List<Line> commandMistakeLines(CommandNode expected, CommandNode attempted) {
  if (attempted == CommandNode.alertCity) {
    return expected == CommandNode.repeatMonitoring
        ? SccDialogue.s8SkipRepeat // skipped "repeat monitoring"
        : SccDialogue.s8AlertTooEarly; // warning before evidence
  }
  if (attempted == CommandNode.repeatMonitoring &&
      expected == CommandNode.checkBattery) {
    return SccDialogue.s8SkipBattery; // skipped the battery check
  }
  // Generic wrong order — restate the guiding concept (PRD §19.8).
  return [SccDialogue.s8Intro[2]];
}

class UploadTuning {
  static const double holdSeconds = 2.4; // upload hold duration (PRD §11.3 vibe)
}

/// Badge reveal order (PRD §21 — main badge first, then skills).
const kBadgeOrder = [
  ('badge_satellite_engineer', 'SATELLITE ENGINEER', SCC.badgeSatelliteEngineer),
  ('badge_orbit_master', 'ORBIT MASTER', SCC.badgeOrbitMaster),
  ('badge_signal_specialist', 'SIGNAL SPECIALIST', SCC.badgeSignalSpecialist),
  ('badge_earth_detective', 'EARTH DETECTIVE', SCC.badgeEarthDetective),
  ('badge_satellite_doctor', 'SATELLITE DOCTOR', SCC.badgeSatelliteDoctor),
  ('badge_mission_commander', 'MISSION COMMANDER', SCC.badgeMissionCommander),
];
