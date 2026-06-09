// The Mission Control robot helper. Picks a character sprite for the mood and
// idles with a gentle bob (PRD §2 characters, §18 motion). Verified sprites:
// robot_helper_idle / robot_pointing_pose / robot_thumbs_up_pose are all the
// blue robot (unlike the Restore Earth pack, these are correctly labelled).

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../config/asset_paths.dart';
import '../state/how_much_state.dart';
import '../../../../utils/s3_assets.dart';

class MascotRobot extends StatelessWidget {
  const MascotRobot({super.key, required this.mood, this.size = 96, this.float = true});

  final MascotMood mood;
  final double size;
  final bool float;

  String get _asset => switch (mood) {
        MascotMood.pointing => HM.robotPointing,
        MascotMood.thumbsUp => HM.robotThumbsUp,
        // idle / hint / oops reuse the idle pose (the panel text carries the tone)
        _ => HM.robotIdle,
      };

  @override
  Widget build(BuildContext context) {
    Widget sprite = netImageWidget(
      HM.flutter(_asset),
      height: size,
      fit: BoxFit.contain,
    );
    // The pointing sprite points LEFT, but Orbit's speech bubble always sits to
    // his RIGHT — mirror it so he points at what he's saying.
    if (mood == MascotMood.pointing) {
      sprite = Transform.flip(flipX: true, child: sprite);
    }
    final img = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: KeyedSubtree(key: ValueKey(_asset), child: sprite),
    );
    if (!float) return img;
    return Floaty(amplitude: 4, period: const Duration(milliseconds: 2600), child: img);
  }
}
