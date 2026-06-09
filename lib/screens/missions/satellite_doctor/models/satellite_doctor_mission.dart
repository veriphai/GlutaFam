// Data models for Satellite Doctor (Activity 9).
//
// All COPY lives here / in config/missions.dart (Flutter-rendered text — PRD hard
// rule: no baked text). One SatelliteDoctorMission per fault.

import 'package:flutter/material.dart';

/// The seven satellite faults the child diagnoses and repairs.
enum SatelliteFaultType {
  batteryOverheating,
  signalLost,
  cameraOffline,
  solarPanelNotCharging,
  orbitDrifting,
  spaceDebrisNearby,
  solarPanelStuck,
}

/// The per-mission flow: alert → inspect → choose → apply → repaired.
enum MissionStep { alert, inspect, chooseRepair, applyRepair, repaired }

/// The kind of hands-on repair the child performs in the applyRepair step.
/// Drives which interaction widget + which Flame stage reaction is used.
enum RepairInteraction {
  rotateAwayFromSun, // M1: drag rotation dial (Facing Sun ↔ Away)
  alignAntenna, // M2: rotate antenna toward Earth
  holdRestart, // M3: press-and-hold restart, scan line passes
  pointPanelsToSun, // M4: drag panel alignment toward Sun
  thrusterBurn, // M5: hold thruster briefly, release in safe zone
  dodgeDebris, // M6: slide satellite to the safe orbit lane
  deployPanel, // M7: swipe/hold to deploy the stuck panel
}

/// The status chips shown in the header (4 fixed + 2 contextual).
enum ChipKind { power, signal, temperature, orbit, camera, solar }

/// One repair card choice.
class RepairOption {
  final String id;
  final String label;
  final String hint; // tiny sub-label under the card title
  final IconData icon;
  final bool isCorrect;
  const RepairOption({
    required this.id,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isCorrect,
  });
}

/// A single diagnostic clue shown during the inspect step (label + value + tone).
class DiagnosticClue {
  final String label;
  final String value;
  final bool bad; // true → red/orange value, false → neutral/good
  const DiagnosticClue(this.label, this.value, {this.bad = false});
}

class SatelliteDoctorMission {
  final int id; // 1..7
  final String title; // e.g. "Battery Overheating"
  final SatelliteFaultType faultType;
  final RepairInteraction interaction;

  // copy (all Flutter-rendered)
  final String alertTitle;
  final String alertBody;
  final String botIntro; // Orbit at alert
  final String inspectHint; // Orbit at inspect (incl. teaching beat)
  final String chooseHint; // Orbit at chooseRepair
  final String wrongHint; // Orbit after a wrong pick
  final String applyTitle; // bottom panel title in applyRepair
  final String applyInstruction; // Orbit during applyRepair
  final String fixAppliedLine; // Orbit while the fix locks in
  final String successMessage; // Orbit at repaired
  final String successHeadline; // big "SYSTEM RESTORED" subtitle

  final List<DiagnosticClue> clues;
  final List<RepairOption> repairOptions;
  final String correctRepairId;

  // status chip this fault warns on, with before/after display values
  final ChipKind warningChip;
  final String chipBeforeValue;
  final String chipAfterValue;

  // reward
  final String badgeAsset; // SD.badge*
  final String badgeName;

  const SatelliteDoctorMission({
    required this.id,
    required this.title,
    required this.faultType,
    required this.interaction,
    required this.alertTitle,
    required this.alertBody,
    required this.botIntro,
    required this.inspectHint,
    required this.chooseHint,
    required this.wrongHint,
    required this.applyTitle,
    required this.applyInstruction,
    required this.fixAppliedLine,
    required this.successMessage,
    required this.successHeadline,
    required this.clues,
    required this.repairOptions,
    required this.correctRepairId,
    required this.warningChip,
    required this.chipBeforeValue,
    required this.chipAfterValue,
    required this.badgeAsset,
    required this.badgeName,
  });

  RepairOption get correctOption =>
      repairOptions.firstWhere((o) => o.id == correctRepairId);
}
