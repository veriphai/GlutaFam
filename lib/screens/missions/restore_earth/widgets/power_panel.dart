// The 2×2 power grid (PRD §12). Wires each PowerButton to the controller and
// derives per-button state from the controller.

import 'package:flutter/material.dart';

import '../config/powers.dart';
import '../state/restore_earth_controller.dart';
import '../state/restore_earth_state.dart';
import 'power_button.dart';

class PowerPanel extends StatelessWidget {
  const PowerPanel({super.key, required this.controller});

  final RestoreEarthController controller;

  @override
  Widget build(BuildContext context) {
    final s = controller.state;
    final enabled = s.phase == ActivityPhase.playing;

    Widget btn(PowerId id) {
      return Expanded(
        child: PowerButton(
          def: power(id),
          selected: s.selectedPower == id,
          dimmed: s.selectedPower != null && s.selectedPower != id,
          hintPulse: s.hintPulsePower == id,
          enabled: enabled,
          wrongShakeToken: s.wrongShakePower == id ? s.wrongShakeToken : 0,
          onTap: () => controller.selectPower(id),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Row(children: [
            btn(kPowerGridOrder[0]),
            const SizedBox(width: 12),
            btn(kPowerGridOrder[1]),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(children: [
            btn(kPowerGridOrder[2]),
            const SizedBox(width: 12),
            btn(kPowerGridOrder[3]),
          ]),
        ),
      ],
    );
  }
}
