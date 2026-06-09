// Small framed "downlink" thumbnail shown beside the stage during a run: "No
// image available" (icon + label) until the picture is taken, then the captured
// cyclone image (mockup 2's placeholder → mockup 3's real image). State is never
// colour-only — it swaps icon + copy too (PRD §19).

import 'package:flutter/material.dart';

import '../config/asset_paths.dart';
import '../config/code_satellite_tuning.dart';
import '../../../../utils/s3_assets.dart';

class CapturedThumbnail extends StatelessWidget {
  const CapturedThumbnail({super.key, required this.hasImage, this.size = 78});

  final bool hasImage;
  final double size;

  @override
  Widget build(BuildContext context) {
    final accent = hasImage ? CSColors.teal : CSColors.gray;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1633).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.7), width: 1.4),
        boxShadow: hasImage
            ? [BoxShadow(color: CSColors.teal.withValues(alpha: 0.4), blurRadius: 12)]
            : null,
      ),
      child: hasImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: netImageWidget(CS.flutter(CS.capturedThumb), fit: BoxFit.cover),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported_rounded, size: 22, color: accent),
                const SizedBox(height: 4),
                Text('No image\nyet',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: accent, fontSize: 9.5, height: 1.1, fontWeight: FontWeight.w600)),
              ],
            ),
    );
  }
}
