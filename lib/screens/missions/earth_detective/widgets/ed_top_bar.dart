// Mission-Control top bar: back button, a centred title (+ optional subtitle),
// and a trailing signal/sound indicator. All Flutter text (PRD §10.1).

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';

class EdTopBar extends StatelessWidget {
  const EdTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.titleColor,
    required this.onBack,
    this.soundOn = true,
    this.onToggleSound,
    this.showSignal = false,
  });

  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback onBack;
  final bool soundOn;
  final VoidCallback? onToggleSound;

  /// Show the decorative signal-strength bars instead of a sound toggle
  /// (used on the in-mission screens, per the storyboard).
  final bool showSignal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Row(
        children: [
          PressableScale(
            onTap: onBack,
            child: GlassSurface(
              radius: 14,
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.arrow_back_rounded, size: 20, color: CareerColors.textPrimary),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: CareerText.label.copyWith(
                    fontSize: 12,
                    color: titleColor ?? CareerColors.cyan,
                    letterSpacing: 1.1,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!,
                        textAlign: TextAlign.center,
                        style: CareerText.cardTitleLg.copyWith(fontSize: 15)),
                  ),
              ],
            ),
          ),
          PressableScale(
            onTap: onToggleSound,
            child: GlassSurface(
              radius: 14,
              padding: const EdgeInsets.all(8),
              child: showSignal
                  ? const Icon(Icons.signal_cellular_alt_rounded, size: 20, color: CareerColors.green)
                  : Icon(soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      size: 20, color: CareerColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
