// Scene 0 + 1 (PRD §16): Mission Control arrival. The Earth hologram scales in
// and pulses, the mascot welcomes, the four satellite cards glow in as a
// preview, then a CTA begins the missions.

import 'package:flutter/material.dart';

import '../../../../utils/s3_assets.dart';
import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../state/choose_satellite_controller.dart';
import '../widgets/cta_button.dart';
import '../widgets/mascot_helper.dart';
import '../widgets/satellite_tray.dart';

class IntroScene extends StatefulWidget {
  const IntroScene({
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
  State<IntroScene> createState() => _IntroSceneState();
}

class _IntroSceneState extends State<IntroScene> with SingleTickerProviderStateMixin {
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return SafeArea(
      child: Column(
        children: [
          // Start-page header: buttons row, then the BIG two-line title below
          // (matches the How Much Can You See start page: 44px w900 + glow).
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                _circleBtn(Icons.menu_rounded, widget.onHome),
                const Spacer(),
                _circleBtn(
                  widget.soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  widget.onToggleSound,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const RevealOnLoad(child: _BigTitle()),
          Expanded(
            child: AnimatedBuilder(
              animation: _intro,
              builder: (context, _) {
                final t = Curves.easeOutCubic.transform(_intro.value);
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Opacity(
                      opacity: t,
                      child: Transform.scale(
                        scale: 0.94 + 0.06 * t,
                        child: netImageWidget(CrsAssets.earthHologram, height: 400, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: MascotHelper(mood: c.mascotMood, line: c.currentLine.text, height: 84),
          ),
          const SizedBox(height: 8),
          // Tray preview — cards glow in but aren't draggable yet.
          AnimatedBuilder(
            animation: _intro,
            builder: (context, _) => SatelliteTray(
              activeDragType: null,
              pulseHintType: null,
              canDrag: (_) => false,
              onDragStart: (_) {},
              onDragEnd: () {},
              introRevealT: _intro.value,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: CrsCtaButton(
              label: 'BEGIN DISPATCH',
              icon: Icons.rocket_launch_rounded,
              enabled: !c.state.voicePlaying,
              onTap: c.beginMissions,
            ),
          ),
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

/// Big two-line start-page title — same type treatment as the How Much Can You
/// See start page (44px w900, white top line, glowing cyan bottom line).
class _BigTitle extends StatelessWidget {
  const _BigTitle();

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'CHOOSE THE RIGHT',
              style: base(Colors.white, const [
                Shadow(color: Color(0xAA00121F), offset: Offset(0, 3), blurRadius: 5),
              ]),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'SATELLITE',
              style: base(const Color(0xFF8FD6FF), [
                const Shadow(color: Color(0xAA00121F), offset: Offset(0, 3), blurRadius: 5),
                Shadow(color: CareerColors.cyan.withValues(alpha: 0.6), blurRadius: 22),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
