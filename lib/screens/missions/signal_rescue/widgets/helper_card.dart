// Orbit (the helper robot) + his speech bubble — the same navy sci-fi message
// box with a conical tail pointing back at him that the other activities use
// (pattern mirrors how_much_can_you_see's OrbitMessage / earth_detective's
// MascotHelperBubble). The mascot sprite swaps by mood; text is Flutter.

import 'package:flutter/material.dart';

import '../../../../utils/s3_assets.dart';
import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../state/signal_rescue_state.dart';

class HelperCard extends StatelessWidget {
  const HelperCard({super.key, required this.mood, required this.message});

  final MascotMood mood;
  final String message;

  String get _asset => SR.flutter(switch (mood) {
        MascotMood.idle => SR.mascotIdle,
        MascotMood.explaining => SR.mascotExplaining,
        MascotMood.alert => SR.mascotAlert,
        MascotMood.happy => SR.mascotHappy,
        MascotMood.celebrate => SR.mascotCelebrate,
      });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 64,
          height: 84,
          child: netImageWidget(_asset, fit: BoxFit.contain, alignment: Alignment.bottomCenter),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: CustomPaint(
            painter: _OrbitBubblePainter(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(21, 12, 15, 12),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: Text(
                  message,
                  key: ValueKey(message),
                  style: CareerText.body.copyWith(
                      color: Colors.white,
                      fontSize: 12.5,
                      height: 1.28,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Navy sci-fi bubble (fill + cyan stroke) with a tail on the LEFT pointing at
/// Orbit. Body + tail are unioned into one path so the stroke has no inner seam.
class _OrbitBubblePainter extends CustomPainter {
  static const _tail = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height * 0.5;
    final body = Path()
      ..addRRect(RRect.fromLTRBR(_tail, 0, size.width, size.height, const Radius.circular(16)));
    final tail = Path()
      ..moveTo(_tail, cy - 10)
      ..lineTo(0, cy)
      ..lineTo(_tail, cy + 10)
      ..close();
    final shape = Path.combine(PathOperation.union, body, tail);
    canvas.drawPath(shape, Paint()..color = const Color(0xD80B2550));
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = CareerColors.cyan.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
