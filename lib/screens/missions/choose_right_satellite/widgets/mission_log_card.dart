// One completed-mission card in the Mission Log (PRD §17): thumbnail + green
// check + mission name + the satellite type used. Visual card, not a table row.

import 'package:flutter/material.dart';

import '../../../home/career/careerTheme.dart';
import '../models/satellite_mission.dart';
import '../models/satellite_type.dart';
import '../../../../utils/s3_assets.dart';

class MissionLogCard extends StatelessWidget {
  const MissionLogCard({super.key, required this.mission});

  final SatelliteMission mission;

  @override
  Widget build(BuildContext context) {
    final accent = mission.correctType.accent;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x3315335E), Color(0x22091428)],
        ),
        border: Border.all(color: CareerColors.green.withValues(alpha: 0.55), width: 1.3),
        boxShadow: [BoxShadow(color: CareerColors.green.withValues(alpha: 0.18), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      color: const Color(0x33000B1F),
                      padding: const EdgeInsets.all(4),
                      child: netImageWidget(mission.thumbnail, fit: BoxFit.contain),
                    ),
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0E2A22),
                      boxShadow: [BoxShadow(color: CareerColors.green.withValues(alpha: 0.6), blurRadius: 8)],
                    ),
                    padding: const EdgeInsets.all(1),
                    child: const Icon(Icons.check_circle_rounded, size: 18, color: CareerColors.green),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            mission.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: CareerText.cardTitle.copyWith(fontSize: 13, height: 1.1),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(mission.correctType.glyph, size: 13, color: accent),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  mission.correctType.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CareerText.label.copyWith(fontSize: 9.5, letterSpacing: 0.5, color: accent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
