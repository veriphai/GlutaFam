// Battery meter: a Flutter-drawn battery with a fill that greens/ambers/reds by
// level, the % as text, and a low-battery warning pip. (Sprite text is banned —
// all numbers are Flutter Text.)

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';

class BatteryMeter extends StatelessWidget {
  const BatteryMeter({super.key, required this.level, required this.warning});

  final double level; // 0..100
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final pct = level.clamp(0, 100).round();
    final fill = (level / 100).clamp(0.0, 1.0);
    final color = warning
        ? const Color(0xFFFF4D4D)
        : level < 50
            ? const Color(0xFFFFC43D)
            : const Color(0xFF49E06B);
    return GlassSurface(
      radius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // battery shell
          Container(
            width: 26,
            height: 13,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.4),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fill,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(1.5),
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 5)],
                  ),
                ),
              ),
            ),
          ),
          // battery nub
          Container(
            width: 2.5,
            height: 6,
            margin: const EdgeInsets.only(left: 1),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 7),
          Text('$pct%', style: CareerText.statValue.copyWith(fontSize: 12, color: color)),
          if (warning) ...[
            const SizedBox(width: 5),
            const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFFF4D4D)),
          ],
        ],
      ),
    );
  }
}
