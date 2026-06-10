// What Each Source Is Actually Like (beat 1.2) — the Flutter shell.
//
// A full-bleed Flame town (the town_simulation_base world) with a Flutter chrome
// overlay: a short large INSTRUCTION at the top ("what to do now"), a glanceable
// inline fact, and the bottom dock — the live POWER/COST readouts, the source
// selector, and the time scrubber. The kid runs the whole town on one source at a
// time across a day and FEELS each trade-off as a consequence they cause (dark
// town / flicker / haze / climbing cost) — never a stat on a card (PRD §4.4).
//
// The GameWidget is built ONCE (kept out of the rebuilt subtree) so Flame is
// never re-attached; the TownGame ticks the controller, which owns the sim.

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../collectibles/collectible_earn_overlay.dart';
import '../../collectibles/collectible_models.dart';
import '../../home/career/careerCommon.dart';
import '../../home/career/careerTheme.dart';
import '../episode_board/capture_flash.dart';
import '../episode_board/episode_board_capture.dart';
import '../episode_board/episode_board_strip.dart';
import '../episode_board/evidence_models.dart';
import '../episode_board/scene_snapshot.dart';
import 'game/town_game.dart';
import 'state/source_personalities_controller.dart';
import 'widgets/cost_meter.dart';
import 'widgets/power_readout.dart';
import 'widgets/source_selector.dart';
import 'widgets/time_scrubber.dart';

class SourcePersonalitiesScreen extends StatefulWidget {
  const SourcePersonalitiesScreen({super.key});

  @override
  State<SourcePersonalitiesScreen> createState() => _SourcePersonalitiesScreenState();
}

class _SourcePersonalitiesScreenState extends State<SourcePersonalitiesScreen> {
  late final SourcePersonalitiesController _controller;
  late final TownGame _game;
  late final Widget _gameWidget; // built ONCE
  final EpisodeBoardCapture _board = EpisodeBoardCapture(kEpisode1Id);
  final GlobalKey _sceneKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final reduced =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    _board.load();
    _controller = SourcePersonalitiesController()
      ..onSelectHaptic = HapticFeedback.selectionClick
      ..onCapture = _onCapture;
    _game = TownGame(controller: _controller, reducedMotion: reduced);
    _gameWidget = GameWidget(game: _game);
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.start());
  }

  void _onCapture(String id) {
    HapticFeedback.lightImpact();
    // Snapshot the ACTUAL town at this catch (PRD §8) — the dark town / haze /
    // soaring cost the kid just felt becomes the tile. Post-frame so it's painted.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bytes = await captureScenePng(_sceneKey, cropFactor: evidenceById(id)?.cropFactor);
      if (!mounted) return;
      _board.capture(id, imageBytes: bytes);
    });
  }

  void _finish() => Navigator.of(context).maybePop();

  @override
  void dispose() {
    _controller.dispose();
    _board.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: const Color(0xFF070A1C),
        body: RepaintBoundary(
          key: _sceneKey,
          child: Stack(
          children: [
            // The living town — full-bleed bottom layer, built once.
            Positioned.fill(child: _gameWidget),

            // Top chrome — header + Voltix + inline fact, anchored to the TOP.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Header(onBack: () => Navigator.of(context).maybePop()),
                      const SizedBox(height: 10),
                      // The pinned episode board — the guiding question + the felt
                      // catches that auto-capture as the kid runs the town on each source.
                      EpisodeBoardStrip(
                        question: kEpisode1Question,
                        capturedIds: _board.capturedIds,
                        images: _board.images,
                        accent: const Color(0xFFE8C98A),
                      ),
                      const SizedBox(height: 12),
                      // Time scrubber — at the very top, above the message (gated on
                      // worldLive, height reserved so the layout never shifts).
                      ValueListenableBuilder<bool>(
                        valueListenable: _controller.worldLive,
                        builder: (context, live, child) => AnimatedOpacity(
                          opacity: live ? 1 : 0,
                          duration: const Duration(milliseconds: 360),
                          child: IgnorePointer(ignoring: !live, child: child),
                        ),
                        child: TimeScrubber(controller: _controller),
                      ),
                      const SizedBox(height: 14),
                      // The large top-text — carries instruction AND lesson (the
                      // per-source upside/catch beats). FIXED height (room for two
                      // lines) so the text swapping never shifts the layout.
                      SizedBox(
                        height: 66,
                        child: _InstructionBanner(instruction: _controller.instruction),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom dock — anchored to the BOTTOM as its own layer, fully
            // decoupled from the top chrome so it can never be pushed off-screen
            // or overflow (the old single-Column + Spacer coupling did exactly
            // that, dropping the scrubber and cramming POWER onto the chips).
            // Hidden (faded + non-interactive) until the world is live.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _controller.worldLive,
                    builder: (context, live, child) => AnimatedOpacity(
                      opacity: live ? 1 : 0,
                      duration: const Duration(milliseconds: 360),
                      child: IgnorePointer(ignoring: !live, child: child),
                    ),
                    child: _BottomDock(controller: _controller),
                  ),
                ),
              ),
            ),

            // Continue CTA — appears only after the outro lands (card collected).
            Positioned.fill(
              child: ValueListenableBuilder<bool>(
                valueListenable: _controller.canFinish,
                builder: (context, canFinish, _) => ValueListenableBuilder<bool>(
                  valueListenable: _controller.showCardEarn,
                  builder: (context, earning, __) {
                    if (!canFinish || earning) return const IgnorePointer(child: SizedBox.shrink());
                    return SafeArea(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _ContinueButton(onTap: _finish),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // The auto-capture moment — a framed catch-tile pins to the board.
            Positioned.fill(
              child: ValueListenableBuilder<EvidenceTileFlash?>(
                valueListenable: _board.flashing,
                builder: (context, flash, _) => flash == null
                    ? const IgnorePointer(child: SizedBox.shrink())
                    : CaptureFlash(
                        key: ValueKey(flash.tile.id),
                        tile: flash.tile,
                        imageBytes: flash.imageBytes,
                        onDone: _board.flashDone,
                      ),
              ),
            ),

            // The collectible earn moment (Card 03). MUST stay Positioned.fill.
            Positioned.fill(
              child: ValueListenableBuilder<bool>(
                valueListenable: _controller.showCardEarn,
                builder: (context, show, _) => show
                    ? CollectibleEarnOverlay(
                        card: kNoFreeLunchCard,
                        eyebrow: 'NEW CARD',
                        brag: 'No Free Lunch — every power source is a compromise. '
                            'Now you know the catch behind all of them.',
                        onDone: _controller.onCardCollected,
                      )
                    : const IgnorePointer(child: SizedBox.shrink()),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _BottomDock extends StatelessWidget {
  const _BottomDock({required this.controller});
  final SourcePersonalitiesController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A1126).withValues(alpha: 0.55),
            const Color(0xFF070C1E).withValues(alpha: 0.82),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Live telemetry — POWER + driver (left), COST (right) — above the
          // selector. The dock is bottom-anchored, so it never overlaps the chips.
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              if (!controller.sim.hasSource) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(left: 2, right: 2, bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PowerReadout(controller: controller),
                    CostMeter(controller: controller),
                  ],
                ),
              );
            },
          ),
          SourceSelector(controller: controller),
        ],
      ),
    );
  }
}

/// The large, short instruction at the top — "what to do now" (e.g. "Pick a
/// Source", "Try Every Source"). Swaps with a soft fade+rise; empty = hidden.
class _InstructionBanner extends StatelessWidget {
  const _InstructionBanner({required this.instruction});
  final ValueListenable<String> instruction;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: instruction,
      builder: (context, text, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 340),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(anim),
              child: child,
            ),
          ),
          child: text.isEmpty
              ? const SizedBox.shrink(key: ValueKey('empty'))
              : Align(
                  key: ValueKey(text),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.08,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PressableScale(
          onTap: onBack,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 21),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Power for a Day',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.05,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'WHAT EACH SOURCE IS LIKE',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.6,
                  color: const Color(0xFFE8C98A).withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5C451), Color(0xFFD9A43B)],
          ),
          borderRadius: BorderRadius.circular(CareerRadii.pill),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Continue',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1340),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, size: 19, color: Color(0xFF1A1340)),
          ],
        ),
      ),
    );
  }
}
