// Orbit the mascot + a speech bubble — the teaching-beat system's face (PRD §16).
// The mascot floats on the left and "speaks" a tailed chat bubble (tail points
// to Orbit); the bubble cross-fades its text as the message changes. No label.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../config/asset_paths.dart';
import '../config/code_satellite_tuning.dart';
import '../state/code_satellite_state.dart';
import 'chat_bubble.dart';
import '../../../../utils/s3_assets.dart';

class OrbitDialogue extends StatelessWidget {
  const OrbitDialogue({
    super.key,
    required this.mood,
    required this.message,
    this.mascotSize = 86,
    this.accent = CSColors.cyan,
  });

  final OrbitMood mood;
  final String message;
  final double mascotSize;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Floaty(
          amplitude: 4,
          child: netImageWidget(
            CS.flutter(mood.asset),
            width: mascotSize,
            height: mascotSize,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            // Default layoutBuilder centres children in its Stack — short lines
            // would drift away from the bot. Pin the bubble to the left, next
            // to Orbit.
            layoutBuilder: (currentChild, previousChildren) => Stack(
              alignment: Alignment.centerLeft,
              children: [...previousChildren, if (currentChild != null) currentChild],
            ),
            child: ChatBubble(
              key: ValueKey(message),
              text: message,
              accent: accent,
              fromRight: false,
              maxWidth: 2000, // fill the available width
            ),
          ),
        ),
      ],
    );
  }
}
