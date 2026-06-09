// Scene — Mission play (storyboard frames 4-6, 8, 9). Hosts the cached Flame
// GameWidget (built once in the shell, never re-attached). Flutter draws the
// title + brief, the CLUE FOUND banner, the mascot bubble, and the bottom
// instruction card; Flame owns the satellite image, scanner, zoom, slider,
// overlays.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../models/earth_detective_mission.dart';
import '../state/earth_detective_controller.dart';
import '../state/earth_detective_state.dart';
import '../widgets/ed_cta_button.dart';
import '../widgets/ed_top_bar.dart';
import '../widgets/mascot_helper_bubble.dart';
import '../widgets/mission_instruction_card.dart';

class MissionPlayScene extends StatelessWidget {
  const MissionPlayScene({
    super.key,
    required this.controller,
    required this.stage,
    required this.onHome,
  });

  final EarthDetectiveController controller;
  final Widget stage; // the cached GameWidget
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final s = controller.state;
    final m = controller.mission;
    final found = s.phase == PlayPhase.found;
    final revealing = s.phase != PlayPhase.investigating;
    final isCompare = m.interactionMode == InteractionMode.compareBeforeAfter;

    return SafeArea(
      child: Column(
        children: [
          EdTopBar(
            title: 'MISSION ${s.missionIndex + 1} OF 6',
            onBack: onHome,
            showSignal: true,
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                Text(m.title, style: CareerText.cardTitleLg.copyWith(fontSize: 17)),
                const SizedBox(height: 3),
                Text(m.briefLine,
                    textAlign: TextAlign.center,
                    style: CareerText.body.copyWith(fontSize: 11.5, color: CareerColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // The Flame stage. Border drawn separately so it isn't clipped.
                    stage,
                    IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: CareerColors.cyan.withValues(alpha: 0.35), width: 1.5),
                        ),
                      ),
                    ),
                    if (isCompare) ...[
                      const Positioned(top: 10, left: 12, child: _CompareTag('BEFORE')),
                      const Positioned(top: 10, right: 12, child: _CompareTag('AFTER')),
                    ],
                    if (!isCompare)
                      Positioned.fill(
                        // centre on the IMAGE (offset past the satellite headroom
                        // band at top — must match the stage's _topHeadFactor).
                        child: LayoutBuilder(
                          builder: (context, c) => Padding(
                            padding: EdgeInsets.only(left: 12, top: c.maxWidth * 0.20),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _ZoomControls(
                                zoom: s.zoomLevel,
                                onIn: controller.zoomIn,
                                onOut: controller.zoomOut,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (revealing)
                      Positioned(
                        top: 16,
                        left: 0,
                        right: 0,
                        child: Center(child: _ClueFoundBanner(text: m.successMessage)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: MascotHelperBubble(
              pose: s.mascotPose,
              message: s.helperMessage,
              mascotHeight: 124,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: found
                ? EdCtaButton(
                    label: 'Continue',
                    icon: Icons.arrow_forward_rounded,
                    expand: true,
                    // listen-before-skip: wait out the impact line
                    enabled: !s.voicePlaying,
                    onTap: controller.continueToImpact,
                  )
                : MissionInstructionCard(
                    mission: m,
                    state: s,
                    onHint: controller.requestHint,
                    onZoom: controller.zoomIn,
                  ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({required this.zoom, required this.onIn, required this.onOut});

  final double zoom;
  final VoidCallback onIn;
  final VoidCallback onOut;

  @override
  Widget build(BuildContext context) {
    final canIn = zoom < 2.39;
    final canOut = zoom > 1.01;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(Icons.add_rounded, canIn ? onIn : null),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CareerColors.cyan.withValues(alpha: 0.4)),
          ),
          child: Text('${zoom.toStringAsFixed(1)}x',
              style: CareerText.label.copyWith(fontSize: 10, color: CareerColors.cyan)),
        ),
        const SizedBox(height: 8),
        _btn(Icons.remove_rounded, canOut ? onOut : null),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback? onTap) => PressableScale(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.4 : 1,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.5),
              border: Border.all(color: CareerColors.cyan.withValues(alpha: 0.6), width: 1.4),
              boxShadow: [BoxShadow(color: CareerColors.cyan.withValues(alpha: 0.25), blurRadius: 8)],
            ),
            child: Icon(icon, size: 22, color: CareerColors.cyan),
          ),
        ),
      );
}

class _CompareTag extends StatelessWidget {
  const _CompareTag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CareerColors.cyan.withValues(alpha: 0.5)),
      ),
      child: Text(label, style: CareerText.label.copyWith(fontSize: 10, color: CareerColors.cyan)),
    );
  }
}

class _ClueFoundBanner extends StatelessWidget {
  const _ClueFoundBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.scale(scale: 0.7 + 0.3 * t.clamp(0, 1), child: Opacity(opacity: t.clamp(0, 1), child: child)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF4CD24C), Color(0xFF2BA84A)]),
          borderRadius: BorderRadius.circular(CareerRadii.pill),
          boxShadow: [BoxShadow(color: CareerColors.green.withValues(alpha: 0.5), blurRadius: 16)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
            const SizedBox(width: 7),
            Text('CLUE FOUND!',
                style: CareerText.cta.copyWith(color: Colors.white, fontSize: 14, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}
