// The four energy-driven outputs (PRD §3.3, §4.7). All consume the SAME
// `energyInput`/brightness interface so "same input, different output" is
// literally true in code — and so the instant-cutoff rule (§4.4) applies
// uniformly to every one of them.
//
// Visual-only metadata (accent colour, label, icon) lives here; the per-output
// RENDERING (how brightness becomes a glow / spin / waves) lives in the painter.

import 'package:flutter/material.dart';

import '../../../home/career/careerTheme.dart';

/// `activeOutput` (PRD §4.2). `lamp` until the generalisation unlocks the swap.
enum ActiveOutput { lamp, fan, heater, speaker }

@immutable
class OutputDef {
  const OutputDef({
    required this.output,
    required this.label,
    required this.icon,
    required this.accent,
  });

  final ActiveOutput output;
  final String label;
  final IconData icon;

  /// Drives the device's lit colour (lamp warm-white, heater orange, etc.).
  final Color accent;
}

const Map<ActiveOutput, OutputDef> kOutputDefs = {
  ActiveOutput.lamp: OutputDef(
    output: ActiveOutput.lamp,
    label: 'Lamp',
    icon: Icons.lightbulb_rounded,
    accent: Color(0xFFFFE9A8), // warm LED white
  ),
  ActiveOutput.fan: OutputDef(
    output: ActiveOutput.fan,
    label: 'Fan',
    icon: Icons.mode_fan_off_rounded,
    accent: CareerColors.cyan,
  ),
  ActiveOutput.heater: OutputDef(
    output: ActiveOutput.heater,
    label: 'Heater',
    icon: Icons.local_fire_department_rounded,
    accent: CareerColors.orange,
  ),
  ActiveOutput.speaker: OutputDef(
    output: ActiveOutput.speaker,
    label: 'Speaker',
    icon: Icons.volume_up_rounded,
    accent: CareerColors.green,
  ),
};

/// Swap-tray order (lamp first — it's the one already on screen at discovery).
const List<ActiveOutput> kOutputOrder = [
  ActiveOutput.lamp,
  ActiveOutput.fan,
  ActiveOutput.heater,
  ActiveOutput.speaker,
];
