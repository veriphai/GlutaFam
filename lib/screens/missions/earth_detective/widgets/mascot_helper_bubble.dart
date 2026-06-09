// Robo mascot pose + Flutter speech bubble with a conical tail pointing at the
// robot. The pose maps to the situation (info / scanning / supportive / found /
// proud) using the bright robo set; bubble copy is always Flutter (PRD §13.1).

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../state/earth_detective_state.dart';
import '../../../../utils/s3_assets.dart';

String mascotAssetFor(MascotPose pose) {
  switch (pose) {
    case MascotPose.explaining:
      return edFlutter(EdAssets.mascotGuiding);
    case MascotPose.curious:
      return edFlutter(EdAssets.mascotThinking);
    case MascotPose.supportive:
      return edFlutter(EdAssets.mascotConcerned);
    case MascotPose.celebrating:
      return edFlutter(EdAssets.mascotCelebrate);
    case MascotPose.proud:
      return edFlutter(EdAssets.mascotHappy);
  }
}

class MascotHelperBubble extends StatelessWidget {
  const MascotHelperBubble({
    super.key,
    required this.pose,
    this.message,
    this.mascotHeight = 92,
    this.bubbleColor = const Color(0xFFF2ECDA),
  });

  final MascotPose pose;
  final String? message;
  final double mascotHeight;
  final Color bubbleColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Floaty(
          amplitude: 4,
          child: netImageWidget(
            mascotAssetFor(pose),
            height: mascotHeight,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        ),
        if (message != null && message!.isNotEmpty)
          Expanded(
            child: CustomPaint(
              painter: _BubblePainter(bubbleColor),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 14, 12),
                child: Text(
                  message!,
                  style: CareerText.body.copyWith(
                      color: CareerColors.onLight, fontSize: 12.5, height: 1.25, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Speech bubble with a tail on the left pointing toward the mascot.
class _BubblePainter extends CustomPainter {
  _BubblePainter(this.color);

  final Color color;
  static const _tail = 11.0;
  static const _radius = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height * 0.5;
    final path = Path()
      ..addRRect(RRect.fromLTRBR(_tail, 0, size.width, size.height, const Radius.circular(_radius)))
      ..moveTo(_tail, cy - 11)
      ..lineTo(0, cy)
      ..lineTo(_tail, cy + 11)
      ..close();
    canvas.drawShadow(path, Colors.black, 5, false);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.color != color;
}
