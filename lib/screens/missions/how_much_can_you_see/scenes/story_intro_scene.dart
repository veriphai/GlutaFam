// Scene 0 — Story Intro / title card (PRD §10 Scene 0). The big
// "HOW MUCH / CAN YOU SEE?" title sits at the top with the tagline message right
// below it (in the Mission Control panel frame); the CTA is at the bottom.
//
// This is the start screen, so it shows only a home button — no MISSION 2 label
// / progress dots. The background is a single baked hero scene (kid + robot +
// the height ladder over Earth), fit-to-width with a black letterbox so the edge
// characters are never cropped.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../config/scene_copy.dart';
import '../state/how_much_controller.dart';
import '../widgets/cta_button.dart';
import '../../../../utils/s3_assets.dart';

class StoryIntroScene extends StatelessWidget {
  const StoryIntroScene({super.key, required this.controller, required this.onHome});

  final HowMuchController controller;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-screen cover, no stretch (this composition keeps the characters
        // inboard, so cover's small side trim doesn't clip them).
        Positioned.fill(
          child: netImageWidget(HM.flutter(HM.bgStoryIntro), fit: BoxFit.cover),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                const SizedBox(height: 6),
                // Start screen: home button only (no mission label / dots).
                Align(
                  alignment: Alignment.centerLeft,
                  child: PressableScale(
                    onTap: onHome,
                    child: GlassSurface(
                      radius: 12,
                      padding: const EdgeInsets.all(7),
                      child: const Icon(Icons.home_rounded, size: 18, color: CareerColors.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const RevealOnLoad(child: _Title()),
                const SizedBox(height: 12),
                RevealOnLoad(
                  delay: const Duration(milliseconds: 180),
                  child: const _TaglinePanel(),
                ),
                const Spacer(),
                RevealOnLoad(
                  delay: const Duration(milliseconds: 320),
                  child: CtaButton(
                    label: SceneCopy.startViewTest,
                    icon: Icons.play_arrow_rounded,
                    onTap: controller.startViewTest,
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    TextStyle base(Color color, List<Shadow> shadows) => CareerText.heroTitle.copyWith(
          fontSize: 44,
          height: 1.0,
          letterSpacing: 1.0,
          fontWeight: FontWeight.w900,
          color: color,
          shadows: shadows,
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            SceneCopy.titleTop,
            style: base(Colors.white, const [
              Shadow(color: Color(0xAA00121F), offset: Offset(0, 3), blurRadius: 5),
            ]),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            SceneCopy.titleBottom,
            style: base(const Color(0xFF8FD6FF), [
              const Shadow(color: Color(0xAA00121F), offset: Offset(0, 3), blurRadius: 5),
              Shadow(color: CareerColors.cyan.withValues(alpha: 0.6), blurRadius: 22),
            ]),
          ),
        ),
      ],
    );
  }
}

/// The tagline in the SAME frame the old bottom Mission Control text used
/// (`mission_control_message_panel.png`), with "different heights" accented.
class _TaglinePanel extends StatelessWidget {
  const _TaglinePanel();

  @override
  Widget build(BuildContext context) {
    const text = SceneCopy.introTagline;
    const accent = SceneCopy.introTaglineAccent;
    final i = text.indexOf(accent);
    final before = i >= 0 ? text.substring(0, i) : text;
    final after = i >= 0 ? text.substring(i + accent.length) : '';

    final baseStyle = CareerText.body.copyWith(
        color: Colors.white, fontSize: 13.5, height: 1.35, fontWeight: FontWeight.w600);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 88),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
      decoration: BoxDecoration(
        image: DecorationImage(image: netImage(HM.flutter(HM.msgPanel)), fit: BoxFit.fill),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(style: baseStyle, children: [
          TextSpan(text: before),
          if (i >= 0)
            TextSpan(
                text: accent,
                style: baseStyle.copyWith(color: CareerColors.cyan, fontWeight: FontWeight.w800)),
          TextSpan(text: after),
        ]),
      ),
    );
  }
}
