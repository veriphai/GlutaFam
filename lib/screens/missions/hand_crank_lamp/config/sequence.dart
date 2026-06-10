// The sequential flow — the kid is guided through the four outputs one at a
// time (no chooser). Each step shows a short, large top instruction (the
// `prompt`). The lamp additionally shows a brief `diesText` the moment it dies
// (the instant-cutoff lesson) before advancing; the other devices just advance.

import 'output_defs.dart';

class StepDef {
  const StepDef({required this.device, required this.prompt, this.diesText});

  final ActiveOutput device;
  final String prompt; // the "do this now" line

  /// Shown briefly when the device dies on release (the lesson). Null → advance
  /// immediately with no held message (fan/heater/speaker).
  final String? diesText;
}

const List<StepDef> kSequence = [
  StepDef(device: ActiveOutput.lamp, prompt: 'Spin the Handle', diesText: 'No Spin, No Light'),
  StepDef(device: ActiveOutput.fan, prompt: 'Now the Fan'),
  StepDef(device: ActiveOutput.heater, prompt: 'Now the Heater'),
  StepDef(device: ActiveOutput.speaker, prompt: 'Now the Speaker'),
];

/// Shown once every device has been driven (the synthesis / Continue moment).
const String kDoneText = 'One Handle — Light, Motion, Heat, Sound';
