// The satellite parts the child installs, and how each one contributes to the
// Power / Signal / Stability meters.
//
// This is intentionally a flat, declarative catalog: a future mission ("Build a
// Rocket", "Fix an AI Robot") swaps THIS file + slot_config + mission_steps and
// reuses all the generic game/widget code.

import 'asset_paths.dart';

/// A draggable part. `deploymentKey` selects the part-specific install
/// animation in `game/effects/deployment_animations.dart`.
class SatellitePart {
  final String id;
  final String displayName;
  final String spriteFile; // SatAssets.* filename
  final String slotId; // SlotConfig key it belongs in
  final int stepNumber; // 1..7
  final String explanation; // mascot success copy after install
  final String deploymentKey; // which deployment animation to play

  // Meter contributions applied on successful install (0..100 scale).
  final double powerDelta;
  final double signalDelta;
  final double stabilityDelta;

  const SatellitePart({
    required this.id,
    required this.displayName,
    required this.spriteFile,
    required this.slotId,
    required this.stepNumber,
    required this.explanation,
    required this.deploymentKey,
    this.powerDelta = 0,
    this.signalDelta = 0,
    this.stabilityDelta = 0,
  });

  String get spriteFlutter => SatAssets.flutter(spriteFile);
  String get spriteFlame => SatAssets.flame(spriteFile);
}

/// Stable deployment-animation keys (kept as constants to avoid typos).
class DeployFx {
  DeployFx._();
  static const solar = 'solar';
  static const antennaBase = 'antenna_base';
  static const antennaDish = 'antenna_dish';
  static const camera = 'camera';
  static const computerCore = 'computer_core';
  static const battery = 'battery';
  static const thruster = 'thruster';
  static const thermal = 'thermal';
}

const List<SatellitePart> kSatelliteParts = [
  // ── Step 1: Power ──────────────────────────────────────────────────────
  SatellitePart(
    id: 'left_solar_panel',
    displayName: 'Solar Panel',
    spriteFile: SatAssets.solarLeft,
    slotId: 'left_solar_panel_slot',
    stepNumber: 1,
    explanation: 'Solar panels collect sunlight and turn it into power.',
    deploymentKey: DeployFx.solar,
    powerDelta: 25,
  ),
  SatellitePart(
    id: 'right_solar_panel',
    displayName: 'Solar Panel',
    spriteFile: SatAssets.solarRight,
    slotId: 'right_solar_panel_slot',
    stepNumber: 1,
    explanation: 'Power system online! Both panels are feeding the satellite.',
    deploymentKey: DeployFx.solar,
    powerDelta: 25,
  ),
  // ── Step 2: Communicate ────────────────────────────────────────────────
  SatellitePart(
    id: 'antenna_base',
    displayName: 'Antenna Base',
    spriteFile: SatAssets.antennaBase,
    slotId: 'antenna_base_slot',
    stepNumber: 2,
    explanation: 'This base holds the antenna steady.',
    deploymentKey: DeployFx.antennaBase,
    signalDelta: 15,
  ),
  SatellitePart(
    id: 'antenna_dish',
    displayName: 'Antenna Dish',
    spriteFile: SatAssets.antennaDish,
    slotId: 'antenna_dish_slot',
    stepNumber: 2,
    explanation: 'Now the satellite can send and receive signals from Earth!',
    deploymentKey: DeployFx.antennaDish,
    signalDelta: 45,
  ),
  // ── Step 3: Vision ─────────────────────────────────────────────────────
  SatellitePart(
    id: 'camera_module',
    displayName: 'Camera',
    spriteFile: SatAssets.camera,
    slotId: 'camera_slot',
    stepNumber: 3,
    explanation: 'Great! The camera helps the satellite observe Earth.',
    deploymentKey: DeployFx.camera,
    signalDelta: 20,
  ),
  // ── Step 4: Brain ──────────────────────────────────────────────────────
  SatellitePart(
    id: 'computer_core_chip',
    displayName: 'Computer Core',
    spriteFile: SatAssets.computerCore,
    slotId: 'computer_core_slot',
    stepNumber: 4,
    explanation: "This is the satellite's brain. It controls everything.",
    deploymentKey: DeployFx.computerCore,
    stabilityDelta: 30,
  ),
  // ── Step 5: Battery ────────────────────────────────────────────────────
  SatellitePart(
    id: 'battery_module',
    displayName: 'Battery',
    spriteFile: SatAssets.battery,
    slotId: 'battery_slot',
    stepNumber: 5,
    explanation: "The battery stores power for when sunlight isn't available.",
    deploymentKey: DeployFx.battery,
    powerDelta: 40,
    stabilityDelta: 10,
  ),
  // ── Step 6: Movement ───────────────────────────────────────────────────
  SatellitePart(
    id: 'thruster',
    displayName: 'Thruster',
    spriteFile: SatAssets.thruster,
    slotId: 'thruster_slot',
    stepNumber: 6,
    explanation: 'Thrusters help the satellite adjust its position.',
    deploymentKey: DeployFx.thruster,
    stabilityDelta: 30,
  ),
  // ── Step 7: Protection ─────────────────────────────────────────────────
  SatellitePart(
    id: 'thermal_blanket',
    displayName: 'Thermal Blanket',
    spriteFile: SatAssets.thermalBlanket,
    slotId: 'thermal_blanket_slot',
    stepNumber: 7,
    explanation: 'The thermal blanket protects it from extreme heat and cold.',
    deploymentKey: DeployFx.thermal,
    stabilityDelta: 30,
  ),
];

SatellitePart partById(String id) =>
    kSatelliteParts.firstWhere((p) => p.id == id);

List<SatellitePart> partsForStep(int step) =>
    kSatelliteParts.where((p) => p.stepNumber == step).toList();
