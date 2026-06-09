// Scene 3 — "New Control Unlocked" panel introducing the Tilt Angle control.
// Mock panel 3: header + tilt icon + name/description + GOT IT! button.

import 'package:flutter/material.dart';

import '../../../home/career/careerTheme.dart';
import '../state/orbit_launcher_controller.dart';
import 'orbit_button.dart';

class TiltUnlockPanel extends StatelessWidget {
  const TiltUnlockPanel({super.key, required this.controller});

  final OrbitLauncherController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xF20A1838),
        borderRadius: BorderRadius.circular(CareerRadii.card),
        border: Border.all(color: CareerColors.cyan.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: CareerColors.cyan.withValues(alpha: 0.25), blurRadius: 18)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('New Control Unlocked!',
              style: CareerText.label.copyWith(color: CareerColors.cyan, fontSize: 12, letterSpacing: 1.3)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFF0E1C42),
                  border: Border.all(color: CareerColors.cyan.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.turn_right_rounded, size: 30, color: CareerColors.cyan),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Tilt Angle',
                        style: CareerText.cardTitleLg.copyWith(color: Colors.white, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('Tilt helps the rocket turn sideways.',
                        style: CareerText.body.copyWith(color: CareerColors.textSecondary, fontSize: 11.5, height: 1.25)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          OrbitButton(
            label: 'Got it!',
            colors: const [Color(0xFF34D17E), Color(0xFF17A95C)],
            trailingIcon: Icons.arrow_forward_rounded,
            onTap: controller.tryIt,
            fontSize: 16,
            // wait for Orbit to finish explaining before moving on
            enabled: !controller.state.voicePlaying,
          ),
        ],
      ),
    );
  }
}
