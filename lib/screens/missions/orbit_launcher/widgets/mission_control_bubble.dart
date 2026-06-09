// Orbit's in-game speech bubble (top-right): a navy-glass chat bubble with a
// cyan border and a tail pointing right at the Orbit avatar + "ORBIT" tag. Same
// bubble style as the mission-goal screen. Appears only when there's a line.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../state/orbit_launcher_state.dart';
import '../../../../utils/s3_assets.dart';

class MissionControlBubble extends StatelessWidget {
  const MissionControlBubble({super.key, required this.mood, required this.text});

  final McMood mood;
  final String text;

  String get _avatar => OL.flutter(switch (mood) {
        McMood.happy => OL.orbitBotHappy,
        McMood.thinking => OL.orbitBotThinking,
        McMood.celebrating => OL.orbitBotCelebrating,
      });

  @override
  Widget build(BuildContext context) {
    final accent = mood == McMood.celebrating ? CareerColors.gold : CareerColors.cyan;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (text.isNotEmpty)
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              transitionBuilder: (c, a) => FadeTransition(
                opacity: a,
                child: ScaleTransition(scale: a, alignment: Alignment.topRight, child: c),
              ),
              child: Container(
                key: ValueKey(text),
                margin: const EdgeInsets.only(top: 10),
                constraints: const BoxConstraints(maxWidth: 210),
                child: CustomPaint(
                  painter: _OrbitBubblePainter(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 10, 22, 10),
                    child: Text(
                      text,
                      style: CareerText.body.copyWith(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, height: 1.25),
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Floaty(
              amplitude: 3,
              child: Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0C1740),
                  border: Border.all(color: accent.withValues(alpha: 0.7), width: 2),
                  boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.45), blurRadius: 14)],
                ),
                child: ClipOval(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: netImageWidget(_avatar, key: ValueKey(mood), fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xCC0C1740),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: CareerColors.glassBorder),
              ),
              child: Text('ORBIT',
                  style: CareerText.label.copyWith(fontSize: 7.5, color: Colors.white, letterSpacing: 1.5)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Navy-glass chat bubble with a cyan border and a tail on the RIGHT edge
/// pointing at the Orbit avatar. Body + tail merged into one union outline so
/// the border has no internal seam.
class _OrbitBubblePainter extends CustomPainter {
  static const _fill = Color(0xF20A1838);
  static const _tailW = 12.0;
  static const _tailSpan = 20.0;
  static const _radius = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width - _tailW, size.height),
        const Radius.circular(_radius),
      ));
    final tailY = size.height * 0.42;
    final tail = Path()
      ..moveTo(size.width - _tailW - 1, tailY - _tailSpan * 0.5)
      ..lineTo(size.width, tailY)
      ..lineTo(size.width - _tailW - 1, tailY + _tailSpan * 0.5)
      ..close();
    final merged = Path.combine(PathOperation.union, body, tail);

    canvas.drawShadow(merged, Colors.black.withValues(alpha: 0.5), 8, false);
    canvas.drawPath(merged, Paint()..color = _fill);
    canvas.drawPath(
        merged,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = CareerColors.cyan.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(_OrbitBubblePainter oldDelegate) => false;
}
