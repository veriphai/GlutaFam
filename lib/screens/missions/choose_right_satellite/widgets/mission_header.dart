// Compact top header (PRD §10.2): menu left, two-line wordmark centre, sound
// right. All Flutter text — no baked image type.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';

class MissionHeader extends StatelessWidget {
  const MissionHeader({
    super.key,
    this.title = 'CHOOSE THE RIGHT',
    this.subtitle = 'SATELLITE',
    this.leadingIcon = Icons.menu_rounded,
    this.onLeading,
    this.soundOn = true,
    this.onToggleSound,
  });

  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final VoidCallback? onLeading;
  final bool soundOn;
  final VoidCallback? onToggleSound;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      child: Row(
        children: [
          _circleBtn(leadingIcon, onLeading),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: CareerText.label.copyWith(
                        fontSize: 10, letterSpacing: 2.4, color: CareerColors.textSecondary),
                  ),
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [CareerColors.cyan, Color(0xFF8FE9FF)],
                  ).createShader(r),
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: CareerText.heroTitle.copyWith(
                        fontSize: 22, letterSpacing: 3.2, color: Colors.white, height: 1.0),
                  ),
                ),
              ],
            ),
          ),
          _circleBtn(soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded, onToggleSound),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback? onTap) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CareerColors.glassFill,
          border: Border.all(color: CareerColors.glassBorder),
        ),
        child: Icon(icon, size: 19, color: CareerColors.textPrimary),
      ),
    );
  }
}
