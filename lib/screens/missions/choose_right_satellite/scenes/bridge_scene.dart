// Scene 8 (PRD §16): the bridge to the next activity (power management). The
// last dispatched satellite stays on stage with a flickering "POWER LOW"
// warning; the mascot delivers the hand-off line and the CTA leads to
// "Power Up the Satellite".

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../models/satellite_type.dart';
import '../state/choose_satellite_controller.dart';
import '../widgets/cta_button.dart';
import '../widgets/mascot_helper.dart';
import '../widgets/mission_header.dart';
import '../../../../utils/s3_assets.dart';

class BridgeScene extends StatefulWidget {
  const BridgeScene({
    super.key,
    required this.controller,
    required this.onNext,
    this.onHome,
    this.soundOn = true,
    this.onToggleSound,
  });

  final ChooseSatelliteController controller;
  final VoidCallback onNext;
  final VoidCallback? onHome;
  final bool soundOn;
  final VoidCallback? onToggleSound;

  @override
  State<BridgeScene> createState() => _BridgeSceneState();
}

class _BridgeSceneState extends State<BridgeScene> with SingleTickerProviderStateMixin {
  late final AnimationController _flicker =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _flicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    // The satellite from the final mission stays visible (PRD §16 Scene 8).
    final lastSat = c.missions.last.correctType.sprite;
    return SafeArea(
      child: Column(
        children: [
          MissionHeader(
            title: 'EPISODE 5',
            subtitle: 'NEXT MISSION',
            leadingIcon: Icons.arrow_back_rounded,
            onLeading: widget.onHome,
            soundOn: widget.soundOn,
            onToggleSound: widget.onToggleSound,
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Floaty(
                    amplitude: 6,
                    child: netImageWidget(lastSat, height: 150, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 14),
                  AnimatedBuilder(
                    animation: _flicker,
                    builder: (context, _) {
                      // Flickering low-power warning.
                      final on = math.sin(_flicker.value * 2 * math.pi) > -0.3;
                      return Opacity(
                        opacity: on ? 1 : 0.35,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xCC2A0E0E),
                            borderRadius: BorderRadius.circular(CareerRadii.pill),
                            border: Border.all(color: CareerColors.orange.withValues(alpha: 0.85)),
                            boxShadow: on
                                ? [BoxShadow(color: CareerColors.orange.withValues(alpha: 0.5), blurRadius: 12)]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.battery_alert_rounded, size: 16, color: CareerColors.orange),
                              const SizedBox(width: 6),
                              Text('POWER LOW',
                                  style: CareerText.label
                                      .copyWith(fontSize: 11, letterSpacing: 1.2, color: CareerColors.orange)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: MascotHelper(mood: c.mascotMood, line: c.currentLine.text, height: 88),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: CrsCtaButton(
              label: 'NEXT MISSION: POWER UP THE SATELLITE',
              icon: Icons.bolt_rounded,
              enabled: !c.state.voicePlaying,
              onTap: widget.onNext,
            ),
          ),
        ],
      ),
    );
  }
}
