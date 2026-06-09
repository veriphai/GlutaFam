// The Earth hologram ringed by the six collected clue badges (each with a green
// check). Shared by the summary and reward scenes.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../../../../utils/s3_assets.dart';
import '../config/asset_paths.dart';
import '../config/missions.dart';

class BadgesAroundEarth extends StatelessWidget {
  const BadgesAroundEarth({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final d = math.min(c.maxWidth, c.maxHeight);
        final center = Offset(c.maxWidth / 2, c.maxHeight / 2);
        final radius = d * 0.43;
        const badge = 84.0;
        return Stack(
          children: [
            Positioned(
              left: center.dx - d * 0.30,
              top: center.dy - d * 0.30,
              child: Floaty(
                amplitude: 6,
                period: const Duration(milliseconds: 4200),
                child: netImageWidget(edFlutter(EdAssets.earthHologram), width: d * 0.6, fit: BoxFit.contain),
              ),
            ),
            for (int i = 0; i < kMissions.length; i++)
              Builder(builder: (_) {
                final a = -math.pi / 2 + i * (2 * math.pi / kMissions.length);
                final p = center + Offset(math.cos(a), math.sin(a)) * radius;
                return Positioned(
                  left: p.dx - badge / 2,
                  top: p.dy - badge / 2,
                  child: RevealOnLoad(
                    delay: Duration(milliseconds: 120 + i * 110),
                    child: SizedBox(
                      width: badge,
                      height: badge,
                      child: Stack(
                        children: [
                          netImageWidget(kMissions[i].badgeAsset, fit: BoxFit.contain),
                          const Positioned(
                            right: 0,
                            bottom: 0,
                            child: Icon(Icons.check_circle_rounded, size: 26, color: CareerColors.green),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
