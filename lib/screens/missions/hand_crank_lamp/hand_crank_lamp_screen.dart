// Hand-Crank LED Lamp (beat P.1) — the Flutter shell.
//
// Pure Flutter: a single CustomPainter canvas (crank, wire, pulse, the four
// outputs, the discovery ring) driven by a Ticker. The shell owns the frame
// clock and pumps `controller.tick(dt)`; the controller owns all physics +
// geometry; the painter is a pure renderer (repaint: controller).
//
// Layout is a Stack of Positioned.fill layers (cosmic background + content) so
// the content Column is height-bounded and the bottom swap-tray never gets
// pushed off-screen on tall phones (the playbook shell gotcha).
//
// Audio/haptics are HOOKS only (PRD §6, §8): a light haptic tick per crank
// rotation is wired live; the generating-tone hook is a documented stub (no
// asset is required to ship this slice). Both respect the instant stop and key
// off `isGenerating`, never contact.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../collectibles/collectible_earn_overlay.dart';
import '../../collectibles/collectible_models.dart';
import '../../home/career/careerCommon.dart';
import '../../home/career/careerTheme.dart';
import '../../home/career/cosmicBackground.dart';
import 'state/crank_controller.dart';
import 'widgets/crank_surface.dart';
import 'widgets/output_swap_tray.dart';
import 'widgets/voltix_helper.dart';

class HandCrankLampScreen extends StatefulWidget {
  const HandCrankLampScreen({super.key});

  @override
  State<HandCrankLampScreen> createState() => _HandCrankLampScreenState();
}

class _HandCrankLampScreenState extends State<HandCrankLampScreen>
    with SingleTickerProviderStateMixin {
  late final CrankController _controller;
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _controller = CrankController()
      ..onCrankTick = _hapticTick
      ..onGeneratingChanged = _onGeneratingChanged;
    _ticker = createTicker(_onTick);
    _ticker.start();
    // Fire `beforeLine` once the widget is attached.
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.start());
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    // Guard against a huge first/background-resume delta.
    if (dt > 0 && dt < 0.1) _controller.tick(dt);
  }

  // --- Polish hooks (PRD §6) -------------------------------------------------
  void _hapticTick() => HapticFeedback.selectionClick();

  void _onGeneratingChanged(bool generating) {
    // STUB: a soft tone whose presence tracks `isGenerating` would start/stop
    // here. Left as a no-op so the slice ships without a sound asset; the hook
    // already cuts WITH the light on stop (it's called the frame generation
    // ceases), so wiring a real tone later needs no logic change.
  }

  /// Finish the beat → pop the activity. Inside a lesson, an activity pop counts
  /// as completion (lessonRunner advances to the next resource / back to the
  /// concept timeline).
  void _finish() => Navigator.of(context).maybePop();

  @override
  void dispose() {
    _ticker.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: CareerColors.bgMid,
        body: Stack(
          children: [
            const Positioned.fill(child: CosmicBackground()),
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: Column(
                    children: [
                      const SubpageAppBar(
                        title: 'Hand-Crank Lamp',
                        emoji: '🔦',
                        subtitle: 'Make the light yourself',
                      ),
                      const SizedBox(height: 10),
                      // Voltix + message box. FIXED height so the bubble growing
                      // and shrinking with each line never resizes the stage
                      // below (which would rescale the crank/lamp on every line).
                      SizedBox(
                        height: 118,
                        child: VoltixHelper(controller: _controller),
                      ),
                      const SizedBox(height: 6),
                      // The canvas takes all remaining height; the tray below
                      // keeps a reserved slot so the stage size never changes.
                      Expanded(child: CrankSurface(controller: _controller)),
                      const SizedBox(height: 10),
                      OutputSwapTray(controller: _controller),
                    ],
                  ),
                ),
              ),
            ),
            // The collectible earn moment — Voltix's outro lands, then the
            // "Conservation of Energy" card flies in. Adding it to the deck
            // completes the lesson resource (pops back to the concept timeline).
            //
            // MUST stay Positioned.fill: a non-positioned Stack child (e.g. a
            // bare SizedBox.shrink while hidden) makes the Stack size to THAT
            // child (0×0) under the Scaffold body's loose constraints, collapsing
            // every other Positioned.fill layer to nothing → a black screen.
            Positioned.fill(
              child: ValueListenableBuilder<bool>(
                valueListenable: _controller.canFinish,
                builder: (context, show, _) => show
                    ? CollectibleEarnOverlay(card: kConservationCard, onDone: _finish)
                    : const IgnorePointer(child: SizedBox.shrink()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
