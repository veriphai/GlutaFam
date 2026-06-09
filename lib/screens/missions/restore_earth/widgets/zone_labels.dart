// Flutter pill labels over the stage (CITY / OCEAN / …) — text stays in Flutter
// (PRD rule #5). Positioned from the SAME earth-rect factors the Flame composite
// uses (earth_layout), so labels track their districts.

import 'package:flutter/material.dart';

import '../../../home/career/careerTheme.dart';
import '../config/earth_layout.dart';

class ZoneLabels extends StatelessWidget {
  const ZoneLabels({super.key, required this.stageSize});

  final Size stageSize;

  @override
  Widget build(BuildContext context) {
    // Mirror the Flame Earth rect within the stage.
    final earthW = stageSize.width * kEarthWidthOnStage;
    final earthH = earthW * kEarthAspect;
    final earthLeft = stageSize.width * kEarthCenterOnStage.dx - earthW / 2;
    final earthTop = stageSize.height * kEarthCenterOnStage.dy - earthH / 2;

    return IgnorePointer(
      child: Stack(
        children: [
          for (final z in kZoneLabels)
            Positioned(
              left: earthLeft + z.center.dx * earthW,
              top: earthTop + z.center.dy * earthH,
              child: FractionalTranslation(
                translation: const Offset(-0.5, -0.5),
                child: _pill(z.text),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xCC101B3D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CareerColors.glassBorder),
        ),
        child: Text(text,
            style: CareerText.statLabel.copyWith(
                color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
      );
}
