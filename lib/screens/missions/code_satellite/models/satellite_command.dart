// The 9 satellite commands — enum, per-command metadata (label / icon / the
// satellite sprite state it drives / a one-line explanation teaching beat), and
// the canonical correct order. Copy is transcribed VERBATIM from the PRD
// (§7 labels, §8 success messages, §16 teaching beats).

import '../config/asset_paths.dart';

enum SatelliteCommand {
  wakeUp,
  checkBattery,
  pointSolarPanelToSun,
  pointCameraToEarth,
  takePicture,
  storeData,
  pointAntennaToGroundStation,
  sendData,
  enterSafeMode,
}

class SatelliteCommandMeta {
  final SatelliteCommand command;
  final String label;
  final String iconAsset; // flutter path
  final String satelliteStateAsset; // flame path
  final String explanation; // teaching beat shown while the step runs

  const SatelliteCommandMeta({
    required this.command,
    required this.label,
    required this.iconAsset,
    required this.satelliteStateAsset,
    required this.explanation,
  });
}

/// The correct mission sequence (PRD §1).
const List<SatelliteCommand> kCorrectOrder = [
  SatelliteCommand.wakeUp,
  SatelliteCommand.checkBattery,
  SatelliteCommand.pointSolarPanelToSun,
  SatelliteCommand.pointCameraToEarth,
  SatelliteCommand.takePicture,
  SatelliteCommand.storeData,
  SatelliteCommand.pointAntennaToGroundStation,
  SatelliteCommand.sendData,
  SatelliteCommand.enterSafeMode,
];

const Map<SatelliteCommand, SatelliteCommandMeta> kCommandMeta = {
  SatelliteCommand.wakeUp: SatelliteCommandMeta(
    command: SatelliteCommand.wakeUp,
    label: 'Wake up',
    iconAsset: 'assets/images/code_satellite/icons/icon_wake_up.png',
    satelliteStateAsset: 'code_satellite/states/satellite_wake_up_active.png',
    explanation: 'There it goes — the satellite is awake and ready.',
  ),
  SatelliteCommand.checkBattery: SatelliteCommandMeta(
    command: SatelliteCommand.checkBattery,
    label: 'Check battery',
    iconAsset: 'assets/images/code_satellite/icons/icon_check_battery.png',
    satelliteStateAsset: 'code_satellite/states/satellite_check_battery_state.png',
    explanation: 'Power check complete. We have enough energy for the mission.',
  ),
  SatelliteCommand.pointSolarPanelToSun: SatelliteCommandMeta(
    command: SatelliteCommand.pointSolarPanelToSun,
    label: 'Point solar panel to Sun',
    iconAsset: 'assets/images/code_satellite/icons/icon_point_solar_panel_to_sun.png',
    satelliteStateAsset: 'code_satellite/states/satellite_panels_pointed_to_sun.png',
    explanation: 'The panels are facing the Sun. The satellite is collecting sunlight.',
  ),
  SatelliteCommand.pointCameraToEarth: SatelliteCommandMeta(
    command: SatelliteCommand.pointCameraToEarth,
    label: 'Point camera to Earth',
    iconAsset: 'assets/images/code_satellite/icons/icon_point_camera_to_earth.png',
    satelliteStateAsset: 'code_satellite/states/satellite_camera_aimed_at_earth.png',
    explanation: 'The camera is now aimed at Earth. It can see the cyclone.',
  ),
  SatelliteCommand.takePicture: SatelliteCommandMeta(
    command: SatelliteCommand.takePicture,
    label: 'Take picture',
    iconAsset: 'assets/images/code_satellite/icons/icon_take_picture.png',
    satelliteStateAsset: 'code_satellite/states/satellite_take_picture_state.png',
    explanation: 'Click! The cyclone image is captured.',
  ),
  SatelliteCommand.storeData: SatelliteCommandMeta(
    command: SatelliteCommand.storeData,
    label: 'Store data',
    iconAsset: 'assets/images/code_satellite/icons/icon_store_data.png',
    satelliteStateAsset: 'code_satellite/states/satellite_store_data_state.png',
    explanation: 'Good. The image is stored safely in memory.',
  ),
  SatelliteCommand.pointAntennaToGroundStation: SatelliteCommandMeta(
    command: SatelliteCommand.pointAntennaToGroundStation,
    label: 'Point antenna to ground station',
    iconAsset: 'assets/images/code_satellite/icons/icon_point_antenna_to_ground_station.png',
    satelliteStateAsset: 'code_satellite/states/satellite_antenna_aimed_ground_station.png',
    explanation: 'The antenna is facing the ground station now.',
  ),
  SatelliteCommand.sendData: SatelliteCommandMeta(
    command: SatelliteCommand.sendData,
    label: 'Send data',
    iconAsset: 'assets/images/code_satellite/icons/icon_send_data.png',
    satelliteStateAsset: 'code_satellite/states/satellite_send_data_state.png',
    explanation: 'Signal sent! The cyclone image is reaching Mission Control.',
  ),
  SatelliteCommand.enterSafeMode: SatelliteCommandMeta(
    command: SatelliteCommand.enterSafeMode,
    label: 'Enter safe mode',
    iconAsset: 'assets/images/code_satellite/icons/icon_enter_safe_mode.png',
    satelliteStateAsset: 'code_satellite/states/satellite_safe_mode_state.png',
    explanation: 'Safe mode is on. The satellite can rest after a job well done.',
  ),
};

/// Orbit's step-by-step coaching line, shown when this command is the NEXT one
/// the child should place. Guided learning, not a test — each line praises the
/// previous step and points to the next, in kid-friendly language.
const Map<SatelliteCommand, String> kCommandCoach = {
  SatelliteCommand.wakeUp:
      "First, let's wake the satellite up. It cannot follow our plan while it is asleep. Tap “Wake up”!",
  SatelliteCommand.checkBattery:
      "Nice! Now let's check the battery. I want to make sure we have enough power for the whole mission.",
  SatelliteCommand.pointSolarPanelToSun:
      "Great. Let's point the panels at the Sun. See how the satellite can keep charging while it works?",
  SatelliteCommand.pointCameraToEarth:
      "Now let's aim the camera at Earth. The camera has to face the cyclone before it can see it.",
  SatelliteCommand.takePicture:
      "Perfect, the camera is looking at the cyclone. Now let's take the picture!",
  SatelliteCommand.storeData:
      "Nice shot! Let's store the image in memory so the satellite does not lose it.",
  SatelliteCommand.pointAntennaToGroundStation:
      "Now we need to talk to Earth. Let's point the antenna at the ground station.",
  SatelliteCommand.sendData:
      "The antenna is aimed. Now we can send the cyclone photo down to Mission Control!",
  SatelliteCommand.enterSafeMode:
      "Mission work is done. Let's put the satellite into safe mode so it can rest and stay protected.",
};

/// Orbit's full "not yet" line when a wrong block is tapped, keyed by the
/// EXPECTED next command — each one teaches WHY that step comes first.
const Map<SatelliteCommand, String> kCommandWrong = {
  SatelliteCommand.wakeUp:
      "Almost! If we do that now, the satellite is not ready yet. First we need to wake it up, so it can follow our commands. Try again.",
  SatelliteCommand.checkBattery:
      "Almost! First we need to check the battery. I do not want our satellite running out of power during the mission.",
  SatelliteCommand.pointSolarPanelToSun:
      "Almost! First we need to point the panels at the Sun. See, the satellite needs energy before doing big jobs.",
  SatelliteCommand.pointCameraToEarth:
      "Almost! First we need to aim the camera at Earth. Otherwise it might take a picture of empty space.",
  SatelliteCommand.takePicture:
      "Almost! First we need to take the picture. We cannot send a photo that does not exist yet.",
  SatelliteCommand.storeData:
      "Almost! First we need to store the image. That keeps our cyclone photo safe before sending.",
  SatelliteCommand.pointAntennaToGroundStation:
      "Almost! First we need to aim the antenna at the ground station. The signal needs somewhere to go.",
  SatelliteCommand.sendData:
      "Almost! First we need to send the data. Mission Control needs the warning before we rest.",
  SatelliteCommand.enterSafeMode:
      "Almost! Safe mode is for after the mission. Let's finish the work first.",
};

extension SatelliteCommandX on SatelliteCommand {
  String get coach => kCommandCoach[this]!;
  String get wrong => kCommandWrong[this]!;
  SatelliteCommandMeta get meta => kCommandMeta[this]!;
  String get label => meta.label;
  String get iconAsset => meta.iconAsset;
  String get flameStateAsset => meta.satelliteStateAsset;
  String get explanation => meta.explanation;

  /// Flame-relative path of this command's icon (for in-stage rendering if ever
  /// needed). Derived from the flutter path.
  String get iconFlame => CS.flame(iconAsset.replaceFirst('assets/images/code_satellite/', ''));
}
