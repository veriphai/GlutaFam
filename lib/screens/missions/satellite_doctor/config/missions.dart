// The Satellite Doctor missions — all copy + repair options + clues.
// Copy follows the updated Orbit dialogue script (short mission-style beats):
// alert → inspect (incl. the teaching beat) → choose → wrong-pick hint →
// apply → fix-applied → success.

import 'package:flutter/material.dart';

import '../models/satellite_doctor_mission.dart';
import 'asset_paths.dart';

const List<SatelliteDoctorMission> kMissions = [
  // ── Mission 1: Battery Overheating ────────────────────────────────────────
  SatelliteDoctorMission(
    id: 1,
    title: 'Battery Overheating',
    faultType: SatelliteFaultType.batteryOverheating,
    interaction: RepairInteraction.rotateAwayFromSun,
    alertTitle: 'Battery Overheating',
    alertBody:
        'High temperature detected at the battery module. Let’s cool it down before it causes damage!',
    botIntro: 'Uh-oh, look at the battery! It’s getting way too hot.',
    inspectHint:
        'See that red glow? That tells me the battery temperature is too high. Space has no air to cool it down, so we have to help the satellite manage heat.',
    chooseHint: 'What should we do to cool it safely?',
    wrongHint:
        'Hmm, that helps another part. But this battery is too hot — what fix would reduce the heat?',
    applyTitle: 'Turn Away From Sun',
    applyInstruction: 'Let’s rotate the satellite away from direct sunlight.',
    fixAppliedLine: 'Nice, hold it there… I can see the heat dropping.',
    successMessage: 'Yes! The battery is back to a safe temperature.',
    successHeadline: 'Battery Temperature Safe',
    clues: [
      DiagnosticClue('Battery Temp', 'High', bad: true),
      DiagnosticClue('Sun Exposure', 'Too Much', bad: true),
      DiagnosticClue('Cooling Status', 'Low', bad: true),
    ],
    repairOptions: [
      RepairOption(
        id: 'rotate_sun',
        label: 'Rotate Away From Sun',
        hint: 'Turn the satellite to reduce heat.',
        icon: Icons.wb_sunny_outlined,
        isCorrect: true,
      ),
      RepairOption(
        id: 'restart_camera',
        label: 'Restart Camera',
        hint: 'Restart the camera system.',
        icon: Icons.photo_camera_outlined,
        isCorrect: false,
      ),
      RepairOption(
        id: 'boost_signal',
        label: 'Boost Antenna Signal',
        hint: 'Increase signal power.',
        icon: Icons.settings_input_antenna,
        isCorrect: false,
      ),
    ],
    correctRepairId: 'rotate_sun',
    warningChip: ChipKind.temperature,
    chipBeforeValue: '36°C',
    chipAfterValue: '24°C',
    badgeAsset: SD.badgePowerRestored,
    badgeName: 'Power Protector Badge',
  ),

  // ── Mission 2: Signal Lost ────────────────────────────────────────────────
  SatelliteDoctorMission(
    id: 2,
    title: 'Signal Lost',
    faultType: SatelliteFaultType.signalLost,
    interaction: RepairInteraction.alignAntenna,
    alertTitle: 'Signal Lost',
    alertBody:
        'Mission Control cannot hear the satellite. The antenna may not be facing Earth.',
    botIntro: 'Oh no, I can’t hear the satellite clearly. We lost the signal!',
    inspectHint:
        'Look at the antenna — it’s not facing Earth properly. The antenna is like the satellite’s voice and ears. It needs to point the right way to talk to us.',
    chooseHint: 'How can we help it talk to Earth again?',
    wrongHint:
        'Not that one. That fix helps another system. We need to help the antenna reconnect.',
    applyTitle: 'Aim the Antenna at Earth',
    applyInstruction: 'Rotate the antenna until it points toward Earth.',
    fixAppliedLine: 'Great, keep turning… the signal bars are coming back!',
    successMessage: 'Perfect! I can hear the satellite again.',
    successHeadline: 'Signal Restored',
    clues: [
      DiagnosticClue('Antenna Direction', 'Off Target', bad: true),
      DiagnosticClue('Earth Link', 'Weak', bad: true),
      DiagnosticClue('Signal Strength', 'Low', bad: true),
    ],
    repairOptions: [
      RepairOption(
        id: 'rotate_antenna',
        label: 'Rotate Antenna to Earth',
        hint: 'Point the antenna at Earth.',
        icon: Icons.settings_input_antenna,
        isCorrect: true,
      ),
      RepairOption(
        id: 'fire_thrusters',
        label: 'Fire Thrusters',
        hint: 'Push the satellite forward.',
        icon: Icons.rocket_launch_outlined,
        isCorrect: false,
      ),
      RepairOption(
        id: 'cool_battery',
        label: 'Cool Battery',
        hint: 'Lower the battery heat.',
        icon: Icons.ac_unit,
        isCorrect: false,
      ),
    ],
    correctRepairId: 'rotate_antenna',
    warningChip: ChipKind.signal,
    chipBeforeValue: 'Lost',
    chipAfterValue: 'Strong',
    badgeAsset: SD.badgeSignalRestored,
    badgeName: 'Signal Keeper Badge',
  ),

  // ── Mission 3: Camera Offline ─────────────────────────────────────────────
  SatelliteDoctorMission(
    id: 3,
    title: 'Camera Offline',
    faultType: SatelliteFaultType.cameraOffline,
    interaction: RepairInteraction.holdRestart,
    alertTitle: 'Camera Offline',
    alertBody:
        'The camera stopped sending images. Let’s safely restart the camera system.',
    botIntro: 'Uh-oh, the camera feed just went dark.',
    inspectHint:
        'See the dark lens and static? I think the camera system has frozen. Satellites carry tools like cameras and sensors. Sometimes we can wake them up with a restart from Earth.',
    chooseHint: 'What should we do to wake up the camera?',
    wrongHint: 'Hmm, that won’t wake the camera. This instrument needs a restart.',
    applyTitle: 'Restart the Camera',
    applyInstruction: 'Press and hold while I run the camera restart.',
    fixAppliedLine: 'Good job… the camera is rebooting now.',
    successMessage: 'Yes! Camera online. Our satellite can see Earth again.',
    successHeadline: 'Camera Online',
    clues: [
      DiagnosticClue('Camera Feed', 'Static', bad: true),
      DiagnosticClue('Lens Power', 'Off', bad: true),
      DiagnosticClue('Last Image', 'None', bad: true),
    ],
    repairOptions: [
      RepairOption(
        id: 'restart_camera',
        label: 'Restart Camera System',
        hint: 'Reboot the camera.',
        icon: Icons.restart_alt,
        isCorrect: true,
      ),
      RepairOption(
        id: 'rotate_solar',
        label: 'Rotate Solar Panels',
        hint: 'Turn the panels.',
        icon: Icons.solar_power_outlined,
        isCorrect: false,
      ),
      RepairOption(
        id: 'activate_thrusters',
        label: 'Activate Thrusters',
        hint: 'Fire the thrusters.',
        icon: Icons.rocket_launch_outlined,
        isCorrect: false,
      ),
    ],
    correctRepairId: 'restart_camera',
    warningChip: ChipKind.camera,
    chipBeforeValue: 'Offline',
    chipAfterValue: 'Online',
    badgeAsset: SD.badgeCameraOnline,
    badgeName: 'Camera Medic Badge',
  ),

  // ── Mission 4: Solar Panel Not Charging ───────────────────────────────────
  SatelliteDoctorMission(
    id: 4,
    title: 'Solar Panel Not Charging',
    faultType: SatelliteFaultType.solarPanelNotCharging,
    interaction: RepairInteraction.pointPanelsToSun,
    alertTitle: 'Solar Panel Not Charging',
    alertBody:
        'The panels are not collecting enough sunlight. Power is dropping.',
    botIntro: 'Wait, the battery isn’t charging. Let’s check the solar panels.',
    inspectHint:
        'See how the panels look dim? They’re not facing the Sun properly. Solar panels drink in sunlight and turn it into power for the satellite.',
    chooseHint: 'How can we help the panels catch more sunlight?',
    wrongHint:
        'That fix helps another system. For this one, we need more sunlight on the panels.',
    applyTitle: 'Point Panels to the Sun',
    applyInstruction: 'Drag the panels toward the Sun until they light up.',
    fixAppliedLine: 'Nice! I can see energy flowing in.',
    successMessage: 'Power restored! The panels are charging the satellite again.',
    successHeadline: 'Power Restored',
    clues: [
      DiagnosticClue('Sun Alignment', 'Off', bad: true),
      DiagnosticClue('Power Flow', 'Weak', bad: true),
      DiagnosticClue('Charge Rate', 'Low', bad: true),
    ],
    repairOptions: [
      RepairOption(
        id: 'point_sun',
        label: 'Point Panels to Sun',
        hint: 'Aim the panels at sunlight.',
        icon: Icons.solar_power,
        isCorrect: true,
      ),
      RepairOption(
        id: 'restart_camera',
        label: 'Restart Camera',
        hint: 'Reboot the camera.',
        icon: Icons.photo_camera_outlined,
        isCorrect: false,
      ),
      RepairOption(
        id: 'rotate_antenna',
        label: 'Rotate Antenna',
        hint: 'Turn the antenna.',
        icon: Icons.settings_input_antenna,
        isCorrect: false,
      ),
    ],
    correctRepairId: 'point_sun',
    warningChip: ChipKind.power,
    chipBeforeValue: '24%',
    chipAfterValue: '100%',
    badgeAsset: SD.badgePowerRestored,
    badgeName: 'Sun Catcher Badge',
  ),

  // ── Mission 5 (was 6): Space Debris Nearby ────────────────────────────────
  SatelliteDoctorMission(
    id: 6,
    title: 'Space Debris Nearby',
    faultType: SatelliteFaultType.spaceDebrisNearby,
    interaction: RepairInteraction.dodgeDebris,
    alertTitle: 'Space Debris Nearby',
    alertBody:
        'A piece of debris is heading toward the satellite on a danger path. Move aside!',
    botIntro: 'Careful! I’m spotting space debris close to our satellite.',
    inspectHint:
        'See those chunks drifting toward us? Even tiny space debris can be dangerous because it moves super fast.',
    chooseHint: 'How can we move our satellite out of that danger path?',
    wrongHint: 'That fix won’t move us away. We need to shift the satellite’s path.',
    applyTitle: 'Move to a Safe Lane',
    applyInstruction: 'Slide the satellite away from the debris.',
    fixAppliedLine: 'Good move… the debris is passing by.',
    successMessage: 'We’re safe! The debris missed the satellite.',
    successHeadline: 'Collision Avoided',
    clues: [
      DiagnosticClue('Debris Range', 'Close', bad: true),
      DiagnosticClue('Collision Risk', 'High', bad: true),
      DiagnosticClue('Safe Lane', 'Available'),
    ],
    repairOptions: [
      RepairOption(
        id: 'orbit_adjust',
        label: 'Make Small Orbit Adjustment',
        hint: 'Shift to a safe lane.',
        icon: Icons.swap_horiz,
        isCorrect: true,
      ),
      RepairOption(
        id: 'thermal_shield',
        label: 'Deploy Thermal Shield',
        hint: 'Raise the heat shield.',
        icon: Icons.shield_outlined,
        isCorrect: false,
      ),
      RepairOption(
        id: 'restart_computer',
        label: 'Restart Computer',
        hint: 'Reboot the system.',
        icon: Icons.memory,
        isCorrect: false,
      ),
    ],
    correctRepairId: 'orbit_adjust',
    warningChip: ChipKind.orbit,
    chipBeforeValue: 'Danger',
    chipAfterValue: 'Safe',
    badgeAsset: SD.badgeDebrisAvoided,
    badgeName: 'Debris Dodger Badge',
  ),

  // ── Mission 6 (was 7): Solar Panel Stuck ──────────────────────────────────
  SatelliteDoctorMission(
    id: 7,
    title: 'Solar Panel Stuck',
    faultType: SatelliteFaultType.solarPanelStuck,
    interaction: RepairInteraction.deployPanel,
    alertTitle: 'Solar Panel Stuck',
    alertBody:
        'One solar panel did not open fully. The hinge mechanism looks jammed.',
    botIntro: 'Uh-oh, one solar panel is stuck half-open.',
    inspectHint:
        'Look at the hinge — it’s jammed, so the panel can’t unfold. Some satellite parts have to open after launch. If they get stuck, we send a deploy command.',
    chooseHint: 'How can we help this panel open all the way?',
    wrongHint: 'That fix helps another part. This panel needs its deploy mechanism.',
    applyTitle: 'Deploy the Panel',
    applyInstruction: 'Hold the deploy command until the panel locks open.',
    fixAppliedLine: 'Keep holding… the hinge is moving!',
    successMessage: 'Yes! Panel deployed. Now it can collect more sunlight.',
    successHeadline: 'Panel Deployed',
    clues: [
      DiagnosticClue('Panel State', 'Half Open', bad: true),
      DiagnosticClue('Hinge', 'Jammed', bad: true),
      DiagnosticClue('Power Gain', 'Reduced', bad: true),
    ],
    repairOptions: [
      RepairOption(
        id: 'deploy_panel',
        label: 'Deploy Panel Mechanism',
        hint: 'Send the deploy command.',
        icon: Icons.unfold_more,
        isCorrect: true,
      ),
      RepairOption(
        id: 'rotate_antenna',
        label: 'Rotate Antenna',
        hint: 'Turn the antenna.',
        icon: Icons.settings_input_antenna,
        isCorrect: false,
      ),
      RepairOption(
        id: 'cool_battery',
        label: 'Cool Battery',
        hint: 'Lower the battery heat.',
        icon: Icons.ac_unit,
        isCorrect: false,
      ),
    ],
    correctRepairId: 'deploy_panel',
    warningChip: ChipKind.solar,
    chipBeforeValue: 'Stuck',
    chipAfterValue: 'Deployed',
    badgeAsset: SD.badgePanelDeployed,
    badgeName: 'Deploy Master Badge',
  ),

  // ── Orbit Drifting — DISABLED per request (copy updated, restore by
  //    uncommenting; would play as the final "Mission 7"). ───────────────────
  /*
  SatelliteDoctorMission(
    id: 5,
    title: 'Orbit Drifting',
    faultType: SatelliteFaultType.orbitDrifting,
    interaction: RepairInteraction.thrusterBurn,
    alertTitle: 'Orbit Drifting',
    alertBody:
        'The satellite is moving away from its safe orbit path. A small correction is needed.',
    botIntro: 'Uh-oh, our satellite is drifting away from its orbit path!',
    inspectHint:
        'See that safe orbit line? Our satellite is sliding away from it. We can use a tiny thruster push to guide it back — but only a tiny one.',
    chooseHint: 'How do we guide it back carefully?',
    wrongHint: 'That fix helps another system. This one needs a small orbit correction.',
    applyTitle: 'Small Thruster Correction',
    applyInstruction: 'Hold the thruster gently. Stop when the orbit line turns green.',
    fixAppliedLine: 'Careful… careful… nice, it’s moving back!',
    successMessage: 'Orbit stable! You used just the right amount of thrust.',
    successHeadline: 'Orbit Stable',
    clues: [
      DiagnosticClue('Orbit Path', 'Drifting', bad: true),
      DiagnosticClue('Off Target', '120 km', bad: true),
      DiagnosticClue('Drift Rate', 'Rising', bad: true),
    ],
    repairOptions: [
      RepairOption(
        id: 'thruster',
        label: 'Use Small Thruster Correction',
        hint: 'A gentle thruster push.',
        icon: Icons.rocket_launch,
        isCorrect: true,
      ),
      RepairOption(
        id: 'restart_camera',
        label: 'Restart Camera',
        hint: 'Reboot the camera.',
        icon: Icons.photo_camera_outlined,
        isCorrect: false,
      ),
      RepairOption(
        id: 'boost_signal',
        label: 'Boost Signal',
        hint: 'Increase signal power.',
        icon: Icons.settings_input_antenna,
        isCorrect: false,
      ),
    ],
    correctRepairId: 'thruster',
    warningChip: ChipKind.orbit,
    chipBeforeValue: 'Drifting',
    chipAfterValue: 'Stable',
    badgeAsset: SD.badgeOrbitStable,
    badgeName: 'Orbit Pilot Badge',
  ),
  */
];
