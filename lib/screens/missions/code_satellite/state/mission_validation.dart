// State-based mission validation (PRD §8) — the teaching core. We do NOT simply
// compare the child's sequence against the correct array; we EXECUTE step by
// step against accumulated state dependencies, so a wrong order fails at the
// exact step whose precondition is unmet and explains WHY (PRD §22).
//
// Failure messages are transcribed VERBATIM from PRD §8/§11.

import '../models/satellite_command.dart';

class MissionState {
  bool isAwake = false;
  bool batteryChecked = false;
  bool solarPanelPointed = false;
  bool cameraPointedToEarth = false;
  bool imageCaptured = false;
  bool dataStored = false;
  bool antennaPointed = false;
  bool dataSent = false;
  bool safeModeEntered = false;
}

class MissionStepResult {
  final bool success;
  final int stepIndex;
  final SatelliteCommand command;
  final String teachingMessage;
  final String? failureMessage;

  const MissionStepResult({
    required this.success,
    required this.stepIndex,
    required this.command,
    required this.teachingMessage,
    this.failureMessage,
  });
}

MissionStepResult _ok(int i, SatelliteCommand c, String msg) =>
    MissionStepResult(success: true, stepIndex: i, command: c, teachingMessage: msg);

MissionStepResult _fail(int i, SatelliteCommand c, String msg) => MissionStepResult(
      success: false,
      stepIndex: i,
      command: c,
      teachingMessage: c.explanation,
      failureMessage: msg,
    );

/// Applies [command] to [state], mutating it on success. Returns a step result
/// carrying the teaching beat (success) or the reason it failed (PRD §8).
MissionStepResult validateAndApply({
  required SatelliteCommand command,
  required int stepIndex,
  required MissionState state,
}) {
  switch (command) {
    case SatelliteCommand.wakeUp:
      state.isAwake = true;
      return _ok(stepIndex, command, 'There it goes — the satellite is awake and ready.');

    case SatelliteCommand.checkBattery:
      if (!state.isAwake) {
        return _fail(stepIndex, command, 'The satellite is still asleep. Wake it up first.');
      }
      state.batteryChecked = true;
      return _ok(stepIndex, command, 'Power check complete. We have enough energy for the mission.');

    case SatelliteCommand.pointSolarPanelToSun:
      if (!state.isAwake) {
        return _fail(stepIndex, command, 'Wake the satellite before moving its panels.');
      }
      if (!state.batteryChecked) {
        return _fail(stepIndex, command, 'Check the battery before starting power actions.');
      }
      state.solarPanelPointed = true;
      return _ok(stepIndex, command, 'The panels are facing the Sun. The satellite is collecting sunlight.');

    case SatelliteCommand.pointCameraToEarth:
      if (!state.isAwake) {
        return _fail(stepIndex, command, 'Wake the satellite before aiming the camera.');
      }
      state.cameraPointedToEarth = true;
      return _ok(stepIndex, command, 'The camera is now aimed at Earth. It can see the cyclone.');

    case SatelliteCommand.takePicture:
      if (!state.cameraPointedToEarth) {
        return _fail(stepIndex, command, 'The camera was not looking at Earth yet. It needs to aim first, then take the picture.');
      }
      state.imageCaptured = true;
      return _ok(stepIndex, command, 'Click! The cyclone image is captured.');

    case SatelliteCommand.storeData:
      if (!state.imageCaptured) {
        return _fail(stepIndex, command, 'No image yet. Take the picture before storing data.');
      }
      state.dataStored = true;
      return _ok(stepIndex, command, 'Good. The image is stored safely in memory.');

    case SatelliteCommand.pointAntennaToGroundStation:
      if (!state.dataStored) {
        return _fail(stepIndex, command, 'Store the image before preparing to send it.');
      }
      state.antennaPointed = true;
      return _ok(stepIndex, command, 'The antenna is facing the ground station now.');

    case SatelliteCommand.sendData:
      if (!state.imageCaptured) {
        return _fail(stepIndex, command, 'See what happened? The satellite tried to send a photo, but no photo had been taken yet.');
      }
      if (!state.dataStored) {
        return _fail(stepIndex, command, 'The image is not stored yet. Store it before sending.');
      }
      if (!state.antennaPointed) {
        return _fail(stepIndex, command, 'The antenna was not facing the ground station. Without aiming it, the signal can get lost.');
      }
      state.dataSent = true;
      return _ok(stepIndex, command, 'Signal sent! The cyclone image is reaching Mission Control.');

    case SatelliteCommand.enterSafeMode:
      if (!state.dataSent) {
        return _fail(stepIndex, command, 'Safe mode makes the satellite rest. If we use it too early, the mission stops before the warning is sent.');
      }
      state.safeModeEntered = true;
      return _ok(stepIndex, command, 'Safe mode is on. The satellite can rest after a job well done.');
  }
}
