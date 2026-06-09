// Story intro / title card for Signal Rescue — a full-bleed poster background
// (satellite + broken beam + mission control + cyclone), the hero title at the
// top, and the helper bot + message + START MISSION pinned at the bottom.
// Mirrors how_much_can_you_see's StoryIntroScene pattern: home button only at
// the top (no progress dots), content inside SafeArea, poster behind everything.

import 'package:flutter/material.dart';

import '../../../../utils/s3_assets.dart';
import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../state/signal_rescue_state.dart';
import 'helper_card.dart';

class MissionIntroScene extends StatelessWidget {
  const MissionIntroScene({
    super.key,
    required this.mood,
    required this.message,
    required this.onHome,
    required this.onStart,
    this.startEnabled = true,
  });

  final MascotMood mood;
  final String message;
  final VoidCallback onHome;
  final VoidCallback onStart;

  /// Gated while Orbit's intro line plays (dim + IgnorePointer — dim alone
  /// would still take taps).
  final bool startEnabled;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Solid black letterbox above/below the poster (blends with its dark sky).
        const Positioned.fill(child: ColoredBox(color: Colors.black)),
        // Poster at full width (never cropped), centred vertically.
        Positioned.fill(
          child: Center(
            child: netImageWidget(
              SR.flutter(SR.introPoster),
              fit: BoxFit.fitWidth,
              width: double.infinity,
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                const SizedBox(height: 6),
                // Start screen: home button only.
                Align(
                  alignment: Alignment.centerLeft,
                  child: PressableScale(
                    onTap: onHome,
                    child: GlassSurface(
                      radius: 12,
                      padding: const EdgeInsets.all(7),
                      child: const Icon(Icons.home_rounded,
                          size: 18, color: CareerColors.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const RevealOnLoad(child: _Title()),
                const Spacer(),
                RevealOnLoad(
                  delay: const Duration(milliseconds: 180),
                  child: HelperCard(mood: mood, message: message),
                ),
                const SizedBox(height: 12),
                RevealOnLoad(
                  delay: const Duration(milliseconds: 320),
                  child: IgnorePointer(
                    ignoring: !startEnabled,
                    child: AnimatedOpacity(
                      opacity: startEnabled ? 1.0 : 0.55,
                      duration: const Duration(milliseconds: 250),
                      child: PressableScale(
                    onTap: onStart,
                    child: Container(
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF34D17E), Color(0xFF17A95C)]),
                        borderRadius: BorderRadius.circular(CareerRadii.pill),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.4),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF17A95C).withValues(alpha: 0.5),
                              blurRadius: 16),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_arrow_rounded, size: 20, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('START MISSION',
                              style: CareerText.cta.copyWith(color: Colors.white, fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
          fontSize: 40,
          height: 1.02,
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
            'SIGNAL RESCUE',
            style: base(Colors.white, const [
              Shadow(color: Color(0xAA00121F), offset: Offset(0, 3), blurRadius: 5),
            ]),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'MISSION',
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
