// Scene 8 — Cyclone Challenge (PRD §12, §20). The child picks where to place the
// camera to watch an ocean cyclone. Satellite is correct. Wrong picks shake the
// card, flash the red glow, and show a limitation line; the satellite card
// pulses after repeated misses. Correct flashes green, then advances.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../config/challenge_options.dart';
import '../config/scene_copy.dart';
import '../state/how_much_controller.dart';
import '../widgets/choice_card.dart';
import '../widgets/mission_header.dart';
import '../widgets/orbit_message.dart';
import '../../../../utils/s3_assets.dart';

class CycloneChallengeScene extends StatefulWidget {
  const CycloneChallengeScene({
    super.key,
    required this.controller,
    required this.onHome,
    required this.onSound,
  });

  final HowMuchController controller;
  final VoidCallback onHome;
  final void Function(String assetFile) onSound;

  @override
  State<CycloneChallengeScene> createState() => _CycloneChallengeSceneState();
}

class _CycloneChallengeSceneState extends State<CycloneChallengeScene> {
  bool _locked = false;
  Timer? _advance;

  @override
  void dispose() {
    _advance?.cancel();
    super.dispose();
  }

  void _tap(ChallengeOptionId id) {
    if (_locked) return;
    final outcome = widget.controller.selectChallengeOption(id);
    if (outcome == ChallengeOutcome.correct) {
      _locked = true;
      widget.onSound(HMSounds.correct);
      HapticFeedback.mediumImpact();
      _advance = Timer(const Duration(milliseconds: 950), widget.controller.confirmCorrect);
    } else {
      widget.onSound(HMSounds.wrong);
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.controller.state;
    final showFeedback = s.wrongAttempts > 0;
    final feedback = s.wrongAttempts >= 2
        ? SceneCopy.hint2Wrong
        : s.missionControlMessage;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Darkened cyclone background with a slowly rotating spiral.
        netImageWidget(HM.flutter(HM.bgOceanCyclone), fit: BoxFit.cover),
        const DecoratedBox(decoration: BoxDecoration(color: Color(0xC807162F))),
        Center(
          child: Opacity(
            opacity: 0.5,
            child: _Spin(
              seconds: 16,
              child: netImageWidget(HM.flutter(HM.cycloneSpiral), width: 360),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 6),
                MissionHeader(visited: s.visitedLevels, onHome: widget.onHome),
                const SizedBox(height: 10),
                Text(SceneCopy.challengeTitle,
                    style: CareerText.heroTitle.copyWith(
                        color: CareerColors.gold, fontSize: 22, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text(
                  SceneCopy.challengeQuestion,
                  textAlign: TextAlign.center,
                  style: CareerText.body.copyWith(
                      color: Colors.white, fontSize: 13, height: 1.3, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.92,
                        children: [
                          for (final opt in kChallengeOptions)
                            ChoiceCard(
                              option: opt,
                              onTap: () => _tap(opt.id),
                              selected: s.selectedChallengeOption == opt.id,
                              correct: s.challengeCompleted && opt.id == kCorrectChallengeOption,
                              shakeToken: s.wrongShakeToken,
                              hintPulse: s.hintPulseSatellite &&
                                  opt.id == kCorrectChallengeOption &&
                                  !s.challengeCompleted,
                              locked: _locked,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Orbit speaks the helper / wrong-feedback line in his bubble.
                OrbitMessage(
                  mood: s.mascot,
                  message: showFeedback ? feedback : SceneCopy.challengeHelper,
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

/// Continuously rotates its child (cyclone spiral).
class _Spin extends StatefulWidget {
  const _Spin({required this.child, required this.seconds});
  final Widget child;
  final double seconds;

  @override
  State<_Spin> createState() => _SpinState();
}

class _SpinState extends State<_Spin> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: Duration(milliseconds: (widget.seconds * 1000).round()))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.rotate(angle: _c.value * 2 * math.pi, child: child),
      child: widget.child,
    );
  }
}
