// Scene 8 — Final summary (storyboard frame 10). Earth hologram ringed by the
// six collected badges, mascot proud, "You found all 6 clues!".

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/missions.dart';
import '../state/earth_detective_controller.dart';
import '../state/earth_detective_state.dart';
import '../widgets/badges_around_earth.dart';
import '../widgets/ed_cta_button.dart';
import '../widgets/ed_top_bar.dart';
import '../widgets/mascot_helper_bubble.dart';

class SummaryScene extends StatelessWidget {
  const SummaryScene({super.key, required this.controller, required this.onHome});

  final EarthDetectiveController controller;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final s = controller.state;
    return SafeArea(
      child: Column(
        children: [
          EdTopBar(title: EdCopy.summaryTitle.toUpperCase(), onBack: onHome, showSignal: true),
          const SizedBox(height: 10),
          RevealOnLoad(
            child: Text(EdCopy.summaryHeadline,
                textAlign: TextAlign.center,
                style: CareerText.heroTitle.copyWith(fontSize: 24)),
          ),
          const Expanded(child: BadgesAroundEarth()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            // voice-paced by the controller's monologue driver
            child: MascotHelperBubble(
              pose: MascotPose.celebrating,
              message: s.helperMessage ?? EdCopy.summaryLines.first,
              mascotHeight: 92,
            ),
          ),
          const SizedBox(height: 16),
          EdCtaButton(
            label: 'Continue',
            icon: Icons.auto_awesome_rounded,
            enabled: !s.voicePlaying,
            onTap: controller.continueFromSummary,
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}
