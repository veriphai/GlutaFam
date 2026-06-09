// Scene 9 — Emotional impact reward (storyboard frame 11, PRD §19 Scene 9).
// The badge-ringed Earth carries over from the summary, the final message
// lands, the Earth Detective reward badge appears, "Continue".

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/missions.dart';
import '../state/analytics.dart';
import '../state/earth_detective_controller.dart';
import '../widgets/badges_around_earth.dart';
import '../widgets/ed_cta_button.dart';
import '../widgets/ed_top_bar.dart';
import '../widgets/final_reward_panel.dart';

class RewardScene extends StatelessWidget {
  const RewardScene({super.key, required this.controller, required this.onHome});

  final EarthDetectiveController controller;
  final VoidCallback onHome;

  void _continue() {
    EdAnalytics.backToMap();
    onHome();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          EdTopBar(title: EdCopy.rewardTitle.toUpperCase(), onBack: _continue, showSignal: true),
          const SizedBox(height: 8),
          RevealOnLoad(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                EdCopy.rewardHeadline,
                textAlign: TextAlign.center,
                style: CareerText.heroTitle.copyWith(fontSize: 25, height: 1.15),
              ),
            ),
          ),
          const Expanded(child: BadgesAroundEarth()),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22),
            child: FinalRewardPanel(),
          ),
          const SizedBox(height: 12),
          Text(EdCopy.completeBanner,
              textAlign: TextAlign.center,
              style: CareerText.label.copyWith(color: CareerColors.cyan, fontSize: 11, letterSpacing: 0.8)),
          const SizedBox(height: 12),
          EdCtaButton(label: 'Continue', icon: Icons.arrow_forward_rounded, onTap: _continue),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}
