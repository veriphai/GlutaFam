// Orbit (the robot mascot) + a Flutter speech bubble with a conical tail
// pointing back at him — replaces the framed "MISSION CONTROL" panel during the
// mission (the intro/title screen keeps its panel frame). Pattern mirrors
// earth_detective's MascotHelperBubble; the expression comes from [MascotMood]
// via MascotRobot (idle / pointing / thumbs-up / hint / oops).

import 'package:flutter/material.dart';

import '../../../home/career/careerTheme.dart';
import '../state/how_much_state.dart';
import 'mascot_robot.dart';

class OrbitMessage extends StatelessWidget {
  const OrbitMessage({
    super.key,
    required this.mood,
    required this.message,
    this.viewLabel,
    this.problemLabel,
    this.isBest = false,
    this.mascotHeight = 86,
  });

  final MascotMood mood;
  final String message;
  final String? viewLabel; // "View: One street" (gold)
  final String? problemLabel; // "Problem: …" (orange) / "Best for: …" (green)
  final bool isBest;
  final double mascotHeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        MascotRobot(mood: mood, size: mascotHeight),
        const SizedBox(width: 2),
        Expanded(
          child: CustomPaint(
            painter: _OrbitBubblePainter(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(21, 12, 15, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
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
                  if (viewLabel != null || problemLabel != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (viewLabel != null)
                          Flexible(
                            child: Text(viewLabel!,
                                style: CareerText.label.copyWith(
                                    color: CareerColors.gold, fontSize: 9.5, letterSpacing: 0.3),
                                overflow: TextOverflow.ellipsis),
                          ),
                        if (viewLabel != null && problemLabel != null) const SizedBox(width: 10),
                        if (problemLabel != null)
                          Flexible(
                            child: Text(problemLabel!,
                                style: CareerText.label.copyWith(
                                    color: isBest ? CareerColors.green : CareerColors.orange,
                                    fontSize: 9.5,
                                    letterSpacing: 0.3),
                                overflow: TextOverflow.ellipsis),
                          ),
                      ],
                    ),
                  ],
                ],
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
