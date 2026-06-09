// Detective-progress widgets: the segmented "DETECTIVE PROGRESS x / 6" bar and
// a collected-badge row. Both are Flutter-rendered (badge art comes from the
// asset pack; counts/labels are Flutter text — PRD §13.1).

import 'package:flutter/material.dart';

import '../../../home/career/careerTheme.dart';
import '../config/missions.dart';
import '../../../../utils/s3_assets.dart';

class DetectiveProgressBar extends StatelessWidget {
  const DetectiveProgressBar({super.key, required this.solved, this.total = 6});

  final int solved;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(EdCopy.selectProgressLabel,
            style: CareerText.label.copyWith(color: CareerColors.textSecondary, fontSize: 9.5, letterSpacing: 1.4)),
        const SizedBox(height: 4),
        Text('$solved / $total',
            style: CareerText.heroTitle.copyWith(fontSize: 22, color: CareerColors.green)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(total, (i) {
            final filled = i < solved;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i == total - 1 ? 0 : 5),
                height: 8,
                decoration: BoxDecoration(
                  color: filled ? CareerColors.green : CareerColors.glassFillStrong,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: filled
                      ? [BoxShadow(color: CareerColors.green.withValues(alpha: 0.5), blurRadius: 7)]
                      : null,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// A row of the six clue badges; solved ones show the badge art, the rest are
/// dim locked slots.
class BadgeRow extends StatelessWidget {
  const BadgeRow({super.key, required this.solvedIndices, this.size = 40});

  final Set<int> solvedIndices;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(kMissions.length, (i) {
        final solved = solvedIndices.contains(i);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: SizedBox(
            width: size,
            height: size,
            child: solved
                ? netImageWidget(kMissions[i].badgeAsset, fit: BoxFit.contain, gaplessPlayback: true)
                : Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: CareerColors.glassFill,
                      border: Border.all(color: CareerColors.glassBorder),
                    ),
                    child: Icon(Icons.lock_rounded, size: size * 0.4, color: CareerColors.textMuted),
                  ),
          ),
        );
      }),
    );
  }
}
