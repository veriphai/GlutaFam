// Mission-complete reward popup (PRD §15). Confetti (existing Lottie asset) +
// XP / skill-unlock card. Shown as an overlay when state.rewardVisible is true.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import '../../../home/career/careerTheme.dart';
import '../../../../utils/s3_assets.dart';

class RewardPopup extends StatelessWidget {
  const RewardPopup({
    super.key,
    required this.onContinue,
    this.continueEnabled = true,
  });

  final VoidCallback onContinue;

  /// When false, the Continue button is dim + non-tappable. Used while Orbit
  /// is still speaking the closing reward lines — flips true when the last
  /// reward voice clip finishes.
  final bool continueEnabled;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dim scrim.
        const Positioned.fill(child: ColoredBox(color: Color(0xCC050A1E))),
        // Confetti burst.
        Positioned.fill(
          child: IgnorePointer(
            child: Lottie.asset('lib/assets/animations/confetti.json',
                fit: BoxFit.cover, repeat: false),
          ),
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B2A66), Color(0xFF0E1640)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: CareerColors.gold.withValues(alpha: 0.7), width: 1.5),
              boxShadow: [BoxShadow(color: CareerColors.purple.withValues(alpha: 0.5), blurRadius: 30)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                netImageWidget(
                  'assets/images/restore_earth/rewards/junior_satellite_engineer_badge.png',
                  height: 120,
                  fit: BoxFit.contain,
                )
                    .animate()
                    .scaleXY(begin: 0.3, end: 1.0,
                        duration: 520.ms, curve: Curves.easeOutBack)
                    .then()
                    .shake(hz: 3, duration: 360.ms),
                const SizedBox(height: 10),
                Text('Mission Complete!',
                    style: CareerText.heroTitle.copyWith(fontSize: 22),
                    textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text('You built a working satellite.',
                    style: CareerText.body.copyWith(color: CareerColors.textSecondary, fontSize: 12.5),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                IgnorePointer(
                  ignoring: !continueEnabled,
                  child: GestureDetector(
                    onTap: continueEnabled ? onContinue : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 320),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          CareerColors.cyan
                              .withValues(alpha: continueEnabled ? 1.0 : 0.35),
                          CareerColors.purple
                              .withValues(alpha: continueEnabled ? 1.0 : 0.35),
                        ]),
                        borderRadius: BorderRadius.circular(CareerRadii.pill),
                        boxShadow: continueEnabled
                            ? [
                                BoxShadow(
                                    color: CareerColors.blue
                                        .withValues(alpha: 0.5),
                                    blurRadius: 16)
                              ]
                            : const [],
                      ),
                      child: Text('Continue',
                          style: CareerText.cta.copyWith(
                              color: Colors.white.withValues(
                                  alpha: continueEnabled ? 1.0 : 0.7),
                              fontSize: 15)),
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 280.ms)
              .scaleXY(begin: 0.8, end: 1, duration: 360.ms, curve: Curves.easeOutBack),
        ),
      ],
    );
  }
}

