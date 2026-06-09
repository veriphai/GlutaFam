// Scene 11 — Next Mission Teaser (PRD §15). Poses the orbit question ("why
// doesn't it fall back down?") and unlocks the next mission. CTA → NEXT.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../config/scene_copy.dart';
import '../state/how_much_controller.dart';
import '../widgets/cta_button.dart';
import '../../../../utils/s3_assets.dart';

class TeaserScene extends StatefulWidget {
  const TeaserScene({super.key, required this.controller, required this.onNext});

  final HowMuchController controller;
  final VoidCallback onNext;

  @override
  State<TeaserScene> createState() => _TeaserSceneState();
}

class _TeaserSceneState extends State<TeaserScene> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  bool _unlocked = false;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _unlocked = true);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _next() {
    widget.controller.finishAndAdvance();
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        netImageWidget(HM.flutter(HM.bgEarthCurve), fit: BoxFit.cover),
        const DecoratedBox(decoration: BoxDecoration(color: Color(0x7707162F))),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                const SizedBox(height: 22),
                Text(
                  SceneCopy.teaserQuestion,
                  textAlign: TextAlign.center,
                  style: CareerText.body.copyWith(
                      color: Colors.white, fontSize: 16, height: 1.35, fontWeight: FontWeight.w700),
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Orbit hint arc behind the satellite (revealed with unlock).
                      AnimatedOpacity(
                        opacity: _unlocked ? 0.9 : 0,
                        duration: const Duration(milliseconds: 600),
                        child: netImageWidget(HM.flutter(HM.orbitArrow), width: 280),
                      ),
                      // Satellite, dipping slightly toward Earth.
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, child) =>
                            Transform.translate(offset: Offset(0, 6 * _pulse.value), child: child),
                        child: Floaty(child: netImageWidget(HM.flutter(HM.satelliteIcon), height: 130)),
                      ),
                      // Down arrow glow, pulsing.
                      Align(
                        alignment: const Alignment(0, 0.5),
                        child: AnimatedBuilder(
                          animation: _pulse,
                          builder: (_, child) => Opacity(
                            opacity: 0.55 + 0.45 * _pulse.value,
                            child: Transform.scale(scale: 0.9 + 0.15 * _pulse.value, child: child),
                          ),
                          child: netImageWidget(HM.flutter(HM.downArrow), width: 70),
                        ),
                      ),
                    ],
                  ),
                ),
                // Unlock card.
                AnimatedSlide(
                  offset: _unlocked ? Offset.zero : const Offset(0, 0.4),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  child: AnimatedOpacity(
                    opacity: _unlocked ? 1 : 0,
                    duration: const Duration(milliseconds: 400),
                    child: _UnlockCard(),
                  ),
                ),
                const SizedBox(height: 14),
                CtaButton(
                  label: SceneCopy.next,
                  gradient: CareerGradients.passport,
                  icon: Icons.arrow_forward_rounded,
                  onTap: _next,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UnlockCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Purple glow behind the card.
        Container(
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: CareerColors.purple.withValues(alpha: 0.7), blurRadius: 30, spreadRadius: 4)],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF3B2A78), Color(0xFF5A3AB0)]),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: CareerColors.pink.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              netImageWidget(HM.flutter(HM.unlockIcon), height: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(SceneCopy.nextMissionUnlocked,
                        style: CareerText.label.copyWith(color: CareerColors.gold, fontSize: 9, letterSpacing: 1)),
                    const SizedBox(height: 3),
                    Text(SceneCopy.nextMissionTitle,
                        style: CareerText.cardTitleLg.copyWith(fontSize: 14, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
