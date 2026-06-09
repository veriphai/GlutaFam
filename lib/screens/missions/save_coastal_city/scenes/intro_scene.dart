// Stage 0 — Mission Emergency Intro (PRD §11), title-card layout following
// the how_much_can_you_see story intro: full-bleed hero art (Earth + cyclone
// + the coastal city + satellite, feature strip baked into the composition),
// big two-line hero title + tagline at the top, then — at the bottom — the
// Orbit dialogue bubble with the press-and-HOLD "Start Final Mission" CTA
// directly below it. (The shell hides its own dialogue overlay on the intro;
// this scene embeds it so the CTA can sit underneath.)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/scc_assets.dart';
import '../config/scc_theme.dart';
import '../state/mission_stage_controller.dart';
import '../widgets/mission_dialogue_overlay.dart';
import '../widgets/scc_buttons.dart';

class IntroScene extends StatelessWidget {
  const IntroScene(
      {super.key,
      required this.controller,
      required this.onExit,
      this.onToggleSound});

  final MissionStageController controller;
  final VoidCallback onExit;
  final VoidCallback? onToggleSound;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // black base under the letterboxed art
        const Positioned.fill(child: ColoredBox(color: Colors.black)),
        // hero composition — fit to WIDTH (no cover stretch), pushed ~200px
        // down so the title block sits on clean black above the art
        Positioned.fill(
          top: 140,
          child: sccImage(
            SCC.flutter(SCC.bgIntroHero),
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
          ),
        ),
        // readability scrims behind the title + bottom cluster
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.22, 0.72, 1.0],
                  colors: [
                    SccColors.deepSpace.withValues(alpha: 0.65),
                    Colors.transparent,
                    Colors.transparent,
                    SccColors.deepSpace.withValues(alpha: 0.80),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                const SizedBox(height: 8),
                // chrome-less intro → scene carries its own close + mute
                Row(
                  children: [
                    _CircleButton(icon: Icons.close_rounded, onTap: onExit),
                    const Spacer(),
                    if (onToggleSound != null)
                      ListenableBuilder(
                        listenable: controller,
                        builder: (context, _) => _CircleButton(
                          icon: controller.state.soundOn
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                          onTap: onToggleSound!,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                const _HeroTitle(),
                const SizedBox(height: 8),
                Text(
                  'A cyclone is forming over the ocean.\nRun the full mission chain and warn the city in time.',
                  textAlign: TextAlign.center,
                  style: SccText.body.copyWith(
                    fontSize: 12.5,
                    color: SccColors.textSecondary,
                    shadows: const [
                      Shadow(color: Color(0xCC02050D), blurRadius: 6),
                    ],
                  ),
                ),
                const Spacer(),
                // Orbit + dialogue, with the CTA directly below it
                MissionDialogueOverlay(controller: controller),
                const SizedBox(height: 12),
                HoldButton(
                  label: 'START FINAL MISSION',
                  icon: Icons.rocket_launch_rounded,
                  onComplete: controller.introHoldComplete,
                ),
                const SizedBox(height: 5),
                Text('press and hold', style: SccText.label.copyWith(fontSize: 9.5)),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: SccColors.panelFill,
          border: Border.all(color: SccColors.panelBorder),
        ),
        child: Icon(icon, size: 20, color: SccColors.textSecondary),
      ),
    );
  }
}

/// Two-line hero title — white top line, glowing cyan bottom line (the
/// how_much_can_you_see title treatment, in this mission's Orbitron face).
class _HeroTitle extends StatelessWidget {
  const _HeroTitle();

  @override
  Widget build(BuildContext context) {
    TextStyle base(Color color, List<Shadow> shadows) => GoogleFonts.orbitron(
          fontSize: 34,
          height: 1.05,
          letterSpacing: 1.4,
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
            'SAVE THE',
            style: base(Colors.white, const [
              Shadow(color: Color(0xAA00121F), offset: Offset(0, 3), blurRadius: 5),
            ]),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'COASTAL CITY',
            style: base(const Color(0xFF8FD6FF), [
              const Shadow(color: Color(0xAA00121F), offset: Offset(0, 3), blurRadius: 5),
              Shadow(color: SccColors.cyan.withValues(alpha: 0.65), blurRadius: 24),
            ]),
          ),
        ),
      ],
    );
  }
}
