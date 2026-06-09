// The two lower cards: "Today's Job Challenge" (quick daily activity) and
// "Career Passport" (long-term progress). Side by side on wide screens,
// stacked on phones.

import 'package:flutter/material.dart';
import '../../../utils/howwowEventLogger.dart';
import '../../../utils/howwowEventNames.dart';
import 'careerCommon.dart';
import 'careerTheme.dart';

class CareerBottomRow extends StatelessWidget {
  const CareerBottomRow({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= 460) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                Expanded(child: DailyChallengeCard()),
                SizedBox(width: 14),
                Expanded(child: CareerPassportCard()),
              ],
            ),
          );
        }
        return Column(
          children: const [
            DailyChallengeCard(),
            SizedBox(height: 14),
            CareerPassportCard(),
          ],
        );
      },
    );
  }
}

// ───────────────────────────────────────────────────────── challenge ──

class DailyChallengeCard extends StatelessWidget {
  const DailyChallengeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () {
        HowwowEventLogger.instance.log(HowwowEvents.dailyChallengeTapped);
        debugPrint('tap: daily challenge');
      },
      pressedScale: 0.98,
      child: Container(
        decoration: BoxDecoration(
          gradient: CareerGradients.challenge,
          borderRadius: BorderRadius.circular(CareerRadii.smallCard),
          boxShadow: [BoxShadow(color: CareerColors.orange.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Stack(
          children: [
            Positioned(
              right: 10,
              bottom: 10,
              child: Floaty(amplitude: 4, child: const _ChallengeRobot()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 84, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    const Text('🏆', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text("Today's Job Challenge",
                          style: CareerText.cardTitle.copyWith(color: CareerColors.onLight),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Text('Can you think like an AI Engineer?',
                      style: CareerText.cardTitleLg.copyWith(color: CareerColors.onLight, fontSize: 14, height: 1.15),
                      maxLines: 2),
                  const SizedBox(height: 6),
                  Text('Solve a fun mini challenge and earn XP!',
                      style: CareerText.body.copyWith(color: CareerColors.onLight.withValues(alpha: 0.8)),
                      maxLines: 2),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: CareerColors.onLight.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(CareerRadii.pill),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('Reward: ',
                              style: CareerText.chip.copyWith(color: CareerColors.onLight)),
                          const Text('⭐', style: TextStyle(fontSize: 13)),
                          Text(' 50 XP',
                              style: CareerText.chip.copyWith(color: CareerColors.onLight, fontWeight: FontWeight.w800)),
                        ]),
                      ),
                      _StartButton(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () => debugPrint('tap: start challenge'),
      pressedScale: 0.94,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: CareerGradients.challengeCta,
          borderRadius: BorderRadius.circular(CareerRadii.pill),
          boxShadow: [BoxShadow(color: const Color(0xFFFF4D6D).withValues(alpha: 0.4), blurRadius: 12)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('Start Challenge', style: CareerText.cta.copyWith(color: Colors.white, fontSize: 13.5)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
        ]),
      ),
    );
  }
}

class _ChallengeRobot extends StatelessWidget {
  const _ChallengeRobot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF0FF), Color(0xFF9AA6CC)],
        ),
        boxShadow: [BoxShadow(color: CareerColors.cyan.withValues(alpha: 0.45), blurRadius: 14)],
      ),
      child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF12143A), size: 34),
    );
  }
}

// ───────────────────────────────────────────────────────── passport ──

class CareerPassportCard extends StatelessWidget {
  const CareerPassportCard({super.key});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () {
        HowwowEventLogger.instance.log(HowwowEvents.careerPassportTapped);
        debugPrint('tap: career passport');
      },
      pressedScale: 0.98,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: CareerGradients.passport,
          borderRadius: BorderRadius.circular(CareerRadii.smallCard),
          boxShadow: [BoxShadow(color: CareerColors.purple.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              const Text('📘', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Flexible(
                child: Text('Career Passport',
                    style: CareerText.cardTitle.copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: const [
                        Expanded(child: _PassportStat(label: 'Jobs\nExplored', icon: Icons.star_rounded, value: 12, accent: CareerColors.gold)),
                        SizedBox(width: 8),
                        Expanded(child: _PassportStat(label: 'Badges\nEarned', icon: Icons.shield_rounded, value: 12, accent: Colors.white)),
                        SizedBox(width: 8),
                        Expanded(child: _PassportStat(label: 'Tools\nCollected', icon: Icons.build_rounded, value: 18, accent: CareerColors.cyan)),
                      ]),
                      const SizedBox(height: 14),
                      _OpenButton(),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const _PassportBook(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PassportStat extends StatelessWidget {
  const _PassportStat({required this.label, required this.icon, required this.value, required this.accent});

  final String label;
  final IconData icon;
  final int value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label,
              textAlign: TextAlign.center,
              style: CareerText.statLabel.copyWith(color: Colors.white, height: 1.05, fontSize: 9)),
          const SizedBox(height: 5),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 15, color: accent),
            const SizedBox(width: 3),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOut,
              builder: (context, v, _) => Text('${v.round()}',
                  style: CareerText.statValue.copyWith(color: Colors.white, fontSize: 14)),
            ),
          ]),
        ],
      ),
    );
  }
}

class _OpenButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () => debugPrint('tap: open passport'),
      pressedScale: 0.95,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(CareerRadii.pill),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Open Passport', style: CareerText.cta.copyWith(color: Colors.white, fontSize: 13.5)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
        ]),
      ),
    );
  }
}

class _PassportBook extends StatelessWidget {
  const _PassportBook();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 84,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF101B3D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CareerColors.gold.withValues(alpha: 0.8), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('CAREER\nPASSPORT',
              textAlign: TextAlign.center,
              style: CareerText.statLabel.copyWith(color: CareerColors.gold, fontSize: 7, height: 1.1, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Icon(Icons.public_rounded, color: CareerColors.gold.withValues(alpha: 0.9), size: 26),
        ],
      ),
    );
  }
}
