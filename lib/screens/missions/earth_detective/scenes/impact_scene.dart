// Scene — Mission impact / "why it matters" (storyboard frame 7, PRD §5.3).
// The earned badge blooms, Mission Control explains the real-world impact, and
// "Next Mission" returns to the select list (or to the summary after the last).

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../state/earth_detective_controller.dart';
import '../widgets/ed_cta_button.dart';
import '../widgets/ed_top_bar.dart';
import '../../../../utils/s3_assets.dart';

class ImpactScene extends StatelessWidget {
  const ImpactScene({super.key, required this.controller, required this.onHome});

  final EarthDetectiveController controller;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final m = controller.mission;
    final last = controller.state.allSolved;
    return SafeArea(
      child: Column(
        children: [
          EdTopBar(
            title: m.title.toUpperCase(),
            titleColor: CareerColors.textMuted,
            onBack: onHome,
            showSignal: true,
          ),
          Expanded(
            child: Center(
              child: RevealOnLoad(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 22),
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 26),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF0E3A6E), Color(0xFF0A1E45)],
                    ),
                    borderRadius: BorderRadius.circular(CareerRadii.card),
                    border: Border.all(color: CareerColors.cyan.withValues(alpha: 0.4)),
                    boxShadow: [BoxShadow(color: CareerColors.blue.withValues(alpha: 0.3), blurRadius: 24)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('MISSION CONTROL',
                          style: CareerText.label.copyWith(color: CareerColors.cyan, fontSize: 12, letterSpacing: 1.4)),
                      const SizedBox(height: 18),
                      Floaty(
                        amplitude: 5,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.5, end: 1),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutBack,
                          builder: (context, t, child) => Transform.scale(scale: t, child: child),
                          child: netImageWidget(m.badgeAsset, width: 190, fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        m.impactExplanation,
                        textAlign: TextAlign.center,
                        style: CareerText.body.copyWith(fontSize: 14, color: Colors.white, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          EdCtaButton(
            label: last ? 'See Results' : 'Next Mission',
            icon: Icons.arrow_forward_rounded,
            enabled: !controller.state.voicePlaying,
            onTap: controller.nextFromImpact,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
