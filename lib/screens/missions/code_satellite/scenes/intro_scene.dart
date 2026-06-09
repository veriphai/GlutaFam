// Story intro. Earth as a side-view sphere bleeding off the right edge, the
// idle-satellite hero, then a VOICED exchange: the kid's question stays pinned,
// and Orbit speaks through ONE bubble that swaps its line in lock-step with
// clips 2–6 (each message replaces the previous — VoicedBubble). Disposing the
// scene stops the thread so lines never leak into the next screen.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../config/code_satellite_tuning.dart';
import '../config/orbit_voice.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/cta_button.dart';
import '../widgets/orbit_voice_thread.dart';
import '../widgets/voiced_bubble.dart';
import '../../../../utils/s3_assets.dart';

const _titleGold = Color(0xFFF3E2A6);

const _kIntroOrbitLines = [
  'Great question. No one is pressing every button every second.',
  'Satellites are far away in space, so engineers send them a plan made of commands.',
  "Let's build the satellite's plan together.",
];

class IntroScene extends StatefulWidget {
  const IntroScene({super.key, required this.onStart, required this.onBack});

  final VoidCallback onStart;
  final VoidCallback onBack;

  @override
  State<IntroScene> createState() => _IntroSceneState();
}

class _IntroSceneState extends State<IntroScene> {
  late final OrbitVoiceThread _thread = OrbitVoiceThread(clips: kClipsIntro);

  @override
  void initState() {
    super.initState();
    // start after mount (+ a beat to sync with the scene fade-in).
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
    final size = MediaQuery.sizeOf(context);
    return Stack(
      children: [
        // Earth side-view bleeding off the right edge. Behind everything.
        Positioned(
          top: size.height * 0.04,
          right: -size.width * 0.60,
          child: IgnorePointer(
            child: netImageWidget(
              CS.flutter(CS.earthGlobe),
              width: size.width * 1.4,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
        // Soft dark scrim across the top so the heading stays legible.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: size.height * 0.34,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    CSColors.navy.withValues(alpha: 0.78),
                    CSColors.navy.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
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
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 2),
                RevealOnLoad(
                  child: Column(
                    children: [
                      Text(
                        'CODE THE SATELLITE',
                        textAlign: TextAlign.center,
                        style: CareerText.heroTitle.copyWith(
                          fontSize: 32,
                          height: 1.0,
                          letterSpacing: 1.4,
                          color: _titleGold,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 12),
                            Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'How does a satellite know what to do?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: CSColors.cyan,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 10),
                            Shadow(color: Colors.black, blurRadius: 3, offset: Offset(0, 1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Upper region: the satellite hero floats in the leftover space.
                Expanded(
                  child: Align(
                    alignment: const Alignment(-0.6, -0.1),
                    child: FractionallySizedBox(
                      widthFactor: 0.62,
                      child: Floaty(
                        amplitude: 7,
                        child: netImageWidget(CS.flutter(CS.satIdle), fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
                // Chat pinned at the BOTTOM, just above Start Mission: the kid's
                // question stays put; Orbit's single bubble swaps per clip.
                RevealOnLoad(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 74,
                        height: 104,
                        child: netImageWidget(
                          CS.flutter(CS.kidCurious),
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: ChatBubble(
                          text: 'Is someone controlling every button all the time?',
                          accent: CSColors.yellow,
                          fromRight: false,
                          maxWidth: size.width * 0.56,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: VoicedBubble(
                          index: _thread.current,
                          lines: [null, ..._kIntroOrbitLines],
                          accents: const [
                            null,
                            CSColors.teal,
                            CSColors.cyan,
                            CSColors.teal,
                          ],
                          fromRight: true,
                          maxWidth: size.width * 0.66,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Floaty(
                      amplitude: 4,
                      child: netImageWidget(CS.flutter(CS.orbitWave),
                          width: 72, height: 72, fit: BoxFit.contain),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Listen-before-skip: lights up once Orbit finishes the intro.
                ValueListenableBuilder<bool>(
                  valueListenable: _thread.done,
                  builder: (context, done, _) => CtaButton(
                    label: 'Start Mission',
                    icon: Icons.rocket_launch_rounded,
                    enabled: done,
                    onTap: widget.onStart,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
