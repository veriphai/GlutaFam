// Orbit helper panel — the bright Orbit bot (pose mapped to mood) + a cream
// speech bubble with a tail pointing at him, matching the other activities
// (earth_detective's MascotHelperBubble look). Replaces the old dark
// "MISSION CONTROL" avatar card.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../models/power_balance_models.dart';
import 'pb_palette.dart';

class MissionControlCard extends StatelessWidget {
  const MissionControlCard({super.key, required this.mood, required this.message});

  final MascotMood mood;
  final String message;

  String get _pose => switch (mood) {
        MascotMood.neutral => PB.orbitGuiding,
        MascotMood.thinking => PB.orbitThinking,
        MascotMood.excited => PB.orbitCelebrating,
        MascotMood.warning => PB.orbitConcerned,
        MascotMood.success => PB.orbitHappy,
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Floaty(
          amplitude: 4,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: pbImage(PB.flutter(_pose),
                key: ValueKey(_pose), width: 74, height: 96),
          ),
        ),
        Expanded(
          child: CustomPaint(
            painter: _BubblePainter(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 14, 12),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (c, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position:
                        Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(a),
                    child: c,
                  ),
                ),
                child: Text(
                  message,
                  key: ValueKey(message),
                  style: CareerText.body.copyWith(
                      color: CareerColors.onLight,
                      fontSize: 12.5,
                      height: 1.25,
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

/// Cream speech bubble with a tail on the left pointing toward Orbit.
class _BubblePainter extends CustomPainter {
  static const _fill = Color(0xFFF2ECDA);
  static const _tail = 11.0;
  static const _radius = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height * 0.5;
    final path = Path()
      ..addRRect(
          RRect.fromLTRBR(_tail, 0, size.width, size.height, const Radius.circular(_radius)))
      ..moveTo(_tail, cy - 11)
      ..lineTo(0, cy)
      ..lineTo(_tail, cy + 11)
      ..close();
    canvas.drawShadow(path, Colors.black, 5, false);
    canvas.drawPath(path, Paint()..color = _fill);
  }

  @override
  bool shouldRepaint(_BubblePainter old) => false;
}
