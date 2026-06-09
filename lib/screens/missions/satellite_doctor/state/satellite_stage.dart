// Interface the controller uses to drive the Flame stage (controller → game,
// one-directional, declared in state/ so state/ never imports game/ → no cycle).
// The SatelliteDoctorGame `implements` this; attach via controller.attachStage().

import '../models/satellite_doctor_mission.dart';

abstract class SatelliteStage {
  /// Compose the satellite + environment + this mission's FAULT visual (alert).
  void loadMission(int index, SatelliteFaultType fault);

  /// Scanner brackets + ring sweep over the faulty part (inspect step).
  void enterInspect(SatelliteFaultType fault);

  /// Remove scanner overlays.
  void exitInspect();

  /// Show the props the apply-interaction needs (Sun, target ring, debris path…).
  void beginApply(RepairInteraction kind);

  /// Live reaction to the child's interaction, progress 0..1.
  void updateApply(RepairInteraction kind, double progress);

  /// Snap the part to its restored state + success glow (repaired step).
  void finishRepair(SatelliteFaultType fault);

  /// All parts healthy + celebration burst (final completion).
  void celebrateFinal();

  /// True once the Flame game has finished onLoad (sprites ready).
  bool get stageReady;
}
