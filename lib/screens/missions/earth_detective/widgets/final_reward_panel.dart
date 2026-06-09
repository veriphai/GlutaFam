// The Earth Detective reward badge panel (storyboard frame 11): the final
// reward badge, label, and three stars.

import 'package:flutter/material.dart';

import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../config/missions.dart';
import '../../../../utils/s3_assets.dart';

class FinalRewardPanel extends StatelessWidget {
  const FinalRewardPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: BoxDecoration(
        color: CareerColors.glassFillStrong,
        borderRadius: BorderRadius.circular(CareerRadii.card),
        border: Border.all(color: CareerColors.gold.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: CareerColors.gold.withValues(alpha: 0.25), blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(EdCopy.rewardSub,
              textAlign: TextAlign.center,
              style: CareerText.body.copyWith(fontSize: 12.5, color: CareerColors.textSecondary)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              netImageWidget(edFlutter(EdAssets.badgeEarthDetective), width: 64, fit: BoxFit.contain),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(EdCopy.rewardBadgeLabel,
                      style: CareerText.heroTitle.copyWith(fontSize: 18, color: CareerColors.gold)),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(
                      3,
                      (_) => const Icon(Icons.star_rounded, size: 26, color: CareerColors.gold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
