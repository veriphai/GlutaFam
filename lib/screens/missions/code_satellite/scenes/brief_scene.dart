// Mission Brief: the cyclone-warning objective + Orbit's VOICED four-line
// brief (clips 7–10) spoken through ONE bubble that swaps per line (each
// message replaces the previous — VoicedBubble), then "Build Sequence" →
// arranging. Disposing the scene stops the thread.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../config/asset_paths.dart';
import '../config/code_satellite_tuning.dart';
import '../config/orbit_voice.dart';
import '../widgets/cta_button.dart';
import '../widgets/orbit_voice_thread.dart';
import '../widgets/voiced_bubble.dart';
import '../../../../utils/s3_assets.dart';

const _kBriefLines = [
  'Look down at Earth — a cyclone is forming over the ocean.',
  'We need our satellite to take a picture and send it to Mission Control.',
  'But the satellite follows commands one by one, so we have to put them in the right order.',
];

class BriefScene extends StatefulWidget {
  const BriefScene({super.key, required this.onBuild, required this.onBack});

  final VoidCallback onBuild;
  final VoidCallback onBack;

  @override
  State<BriefScene> createState() => _BriefSceneState();
}

class _BriefSceneState extends State<BriefScene> {
  late final OrbitVoiceThread _thread = OrbitVoiceThread(clips: kClipsBrief);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _thread.start();
      });
    });
  }

  @override
  void dispose() {
    _thread.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            Row(
              children: [
                PressableScale(
                  onTap: widget.onBack,
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 20, color: Colors.white),
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text('Mission Brief',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 38), // balance the back button so the title is centered
              ],
            ),
            // BIG cyclone Earth + the satellite watching it — fills all the
            // space above the mission card.
            Expanded(
              child: Stack(
                children: [
                  Align(
                    alignment: const Alignment(0, 0.36),
                    child: netImageWidget(CS.flutter(CS.earthCyclone), height: 410, fit: BoxFit.contain),
                  ),
                  Align(
                    alignment: const Alignment(1.0, -0.92),
                    child: Floaty(
                      amplitude: 9,
                      phase: 1.4,
                      child: netImageWidget(
                        CS.flutter(CS.satIdle),
                        width: 124,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // MISSION card at the bottom, above Orbit's bubble + CTA.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF14223F), Color(0xFF0E1633)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: CSColors.cyan.withValues(alpha: 0.55), width: 1.4),
                boxShadow: [BoxShadow(color: CSColors.cyan.withValues(alpha: 0.2), blurRadius: 18)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flag_rounded, size: 16, color: CSColors.orange),
                      const SizedBox(width: 6),
                      Text('MISSION',
                          style: TextStyle(
                              color: CSColors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A cyclone is forming near the coast. Build the command sequence to capture and send a warning image.',
                    style: TextStyle(
                        color: Colors.white, fontSize: 16, height: 1.3, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Orbit briefs the mission — pinned at the BOTTOM, just above the
            // CTA; one swapping bubble, min-height keeps the layout steady.
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Floaty(
                  amplitude: 4,
                  child: netImageWidget(CS.flutter(CS.orbitExplaining),
                      width: 64, height: 64, fit: BoxFit.contain),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: VoicedBubble(
                    index: _thread.current,
                    lines: _kBriefLines,
                    accents: const [
                      CSColors.cyan,
                      CSColors.cyan,
                      CSColors.teal,
                    ],
                    fromRight: false,
                    maxWidth: 2000,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Listen-before-skip: lights up once Orbit finishes the brief.
            ValueListenableBuilder<bool>(
              valueListenable: _thread.done,
              builder: (context, done, _) => CtaButton(
                label: 'Build Sequence',
                icon: Icons.tune_rounded,
                enabled: done,
                onTap: widget.onBuild,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
