// Captured-images gallery — a side panel that slides in from the right when the
// child taps the IMAGES counter, showing the cyclone photos taken so far. Tap
// the scrim or the close button to dismiss.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import 'pb_palette.dart';
import '../../../../utils/s3_assets.dart';

class CaptureGallery extends StatelessWidget {
  const CaptureGallery({super.key, required this.count, required this.onClose});

  /// How many cyclone images have been captured (0..3).
  final int count;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // tap-to-close scrim
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ),
        // right side panel, slides in
        Align(
          alignment: Alignment.centerRight,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: 0),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            builder: (context, slide, child) =>
                Transform.translate(offset: Offset(slide * 320, 0), child: child),
            child: _panel(context),
          ),
        ),
      ],
    );
  }

  Widget _panel(BuildContext context) {
    return SafeArea(
      child: Container(
        width: 280,
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xF20B1E3A), Color(0xF2070F22)],
          ),
          borderRadius: BorderRadius.circular(CareerRadii.card),
          border: Border.all(color: PBPalette.skyBlue.withValues(alpha: 0.5), width: 1.4),
          boxShadow: [BoxShadow(color: PBPalette.skyBlue.withValues(alpha: 0.3), blurRadius: 22)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_library_rounded, size: 18, color: PBPalette.skyBlue),
                const SizedBox(width: 8),
                Text('CAPTURED IMAGES',
                    style: CareerText.label.copyWith(color: PBPalette.skyBlue, fontSize: 11)),
                const Spacer(),
                PressableScale(
                  onTap: onClose,
                  child: const Icon(Icons.close_rounded, size: 20, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('$count of 3 cyclones',
                style: CareerText.body.copyWith(color: Colors.white60, fontSize: 11)),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: count,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _shot(i),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shot(int i) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PBPalette.skyBlue.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [BoxShadow(color: PBPalette.skyBlue.withValues(alpha: 0.25), blurRadius: 12)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.5),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 1.2,
              child: netImageWidget(PB.flutter(PB.capturedImage(i)),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: PBPalette.deepSpace)),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: PBPalette.deepSpace.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Cyclone ${i + 1}',
                    style: CareerText.label.copyWith(color: Colors.white, fontSize: 10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
