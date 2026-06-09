// Scene 10 — Success Story Beat (PRD §14). The bridge from "height matters" to
// the orbit question: the satellite floats calmly, then begins to wobble while a
// question bubble appears. Auto-shows CONTINUE after the beat.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../config/scene_copy.dart';
import '../state/how_much_controller.dart';
import '../widgets/cta_button.dart';
import '../../../../utils/s3_assets.dart';

class StoryBridgeScene extends StatefulWidget {
  const StoryBridgeScene({super.key, required this.controller});

  final HowMuchController controller;

  @override
  State<StoryBridgeScene> createState() => _StoryBridgeSceneState();
}

class _StoryBridgeSceneState extends State<StoryBridgeScene> with SingleTickerProviderStateMixin {
  late final AnimationController _wobble =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
  bool _problem = false; // "But there's a problem..." + wobble begins
  bool _showCta = false;

  Timer? _t1, _t2;

  @override
  void initState() {
    super.initState();
    _t1 = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _problem = true);
    });
    _t2 = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _showCta = true);
    });
  }

  @override
  void dispose() {
    _t1?.cancel();
    _t2?.cancel();
    _wobble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        netImageWidget(HM.flutter(HM.bgStarry), fit: BoxFit.cover),
        const DecoratedBox(decoration: BoxDecoration(color: Color(0x8807162F))),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _problem ? SceneCopy.bridgeProblem : SceneCopy.bridgeLine,
                    key: ValueKey(_problem),
                    textAlign: TextAlign.center,
                    style: CareerText.body.copyWith(
                        color: Colors.white, fontSize: 16, height: 1.35, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _wobble,
                        builder: (_, child) {
                          final a = _problem ? math.sin(_wobble.value * math.pi * 2) * 0.10 : 0.0;
                          return Transform.rotate(angle: a, child: child);
                        },
                        child: Floaty(child: netImageWidget(HM.flutter(HM.satelliteIcon), height: 150)),
                      ),
                      if (_problem)
                        Align(
                          alignment: const Alignment(0.55, -0.55),
                          child: RevealOnLoad(
                            child: netImageWidget(HM.flutter(HM.questionBubble), height: 64),
                          ),
                        ),
                    ],
                  ),
                ),
                // Robot thumbs up cheering the win.
                Align(
                  alignment: Alignment.centerLeft,
                  child: netImageWidget(HM.flutter(HM.robotThumbsUp), height: 96),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: AnimatedOpacity(
                    opacity: _showCta ? 1 : 0,
                    duration: const Duration(milliseconds: 350),
                    child: _showCta
                        ? CtaButton(label: SceneCopy.cont, onTap: widget.controller.continueFromBridge)
                        : const SizedBox.shrink(),
                  ),
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
