// Scene 7 (PRD §16/§17): the Mission Log. Five completed cards (thumbnail +
// satellite type + green check), the mascot's closing line, and a CTA into the
// power bridge.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../state/choose_satellite_controller.dart';
import '../widgets/cta_button.dart';
import '../widgets/mascot_helper.dart';
import '../widgets/mission_header.dart';
import '../widgets/mission_log_card.dart';

class MissionLogScene extends StatelessWidget {
  const MissionLogScene({
    super.key,
    required this.controller,
    this.onHome,
    this.soundOn = true,
    this.onToggleSound,
  });

  final ChooseSatelliteController controller;
  final VoidCallback? onHome;
  final bool soundOn;
  final VoidCallback? onToggleSound;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return SafeArea(
      child: Column(
        children: [
          MissionHeader(
            title: '',
            subtitle: 'MISSION LOG',
            leadingIcon: Icons.arrow_back_rounded,
            onLeading: onHome,
            soundOn: soundOn,
            onToggleSound: onToggleSound,
          ),
          const SizedBox(height: 6),
          // Two cards per row, centred. A Wrap sized off the available width
          // keeps the last (odd) card centred, and the scroll view means three
          // rows never overflow on shorter phones.
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 48, 14, 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 12.0;
                  final cardW = (constraints.maxWidth - spacing) / 2;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    alignment: WrapAlignment.center,
                    children: [
                      for (var i = 0; i < c.missions.length; i++)
                        SizedBox(
                          width: cardW,
                          height: 196,
                          child: RevealOnLoad(
                            delay: Duration(milliseconds: 80 * i),
                            child: MissionLogCard(mission: c.missions[i]),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: MascotHelper(
                mood: c.mascotMood, line: c.currentLine.text, height: 80, bubbleAccent: CareerColors.green),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            // The activity COMPLETES at the Mission Log for now. The bridge to the
            // next activity ("Power Up the Satellite") is disabled — to restore it,
            // swap onTap back to `c.toBridge` and re-enable the bridge scene in the
            // shell (see choose_right_satellite_screen.dart).
            child: CrsCtaButton(
              label: 'CONTINUE',
              icon: Icons.arrow_forward_rounded,
              gradient: const LinearGradient(colors: [CareerColors.green, Color(0xFF36B36A)]),
              enabled: !c.state.voicePlaying,
              onTap: onHome ?? () {},
              // onTap: c.toBridge, // -> bridge / next-activity teaser (disabled)
            ),
          ),
        ],
      ),
    );
  }
}
