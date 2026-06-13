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

import 'package:audioplayers/audioplayers.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../collectibles/collectible_earn_overlay.dart';
import '../lessonRunner.dart';
import '../../collectibles/collectible_models.dart';
import '../../home/career/careerCommon.dart';
import '../../home/career/careerTheme.dart';
import '../activity_header.dart';
import '../episode_board/photo_capture_flash.dart';
import '../episode_board/case_node.dart';
import '../episode_board/episode_board_capture.dart';
import '../episode_board/evidence_board_drawer.dart';
import '../episode_board/evidence_models.dart';
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
  final GlobalKey _nodeKey = GlobalKey(); // the case node, for an accurate fly target
  bool _showDrawer = false; // the peek drawer (the question was already posed in Act 2)

  // Looping ambient music bed — the SAME track as the Prologue (hand_crank_lamp),
  // reused directly (already bundled) so the opening beats share one mood.
  final AudioPlayer _bgm = AudioPlayer();
  static const double _bgmVol = 0.18;

  /// The case node's global centre — so a captured photo flies to land on it.
  Offset? _nodeCenter() {
    final box = _nodeKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  Widget _node() => CaseNode(
        key: _nodeKey,
        capturedIds: _board.capturedIds,
        images: _board.images,
        onTap: () => setState(() => _showDrawer = true),
      );

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
    _bgm.setReleaseMode(ReleaseMode.loop);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAudio();
      _controller.start();
    });
  }

  /// PER-PLAYER audio-context (AndroidAudioFocus.none / iOS mixWithOthers) so the
  /// bed mixes with any other app audio rather than grabbing focus, then loop it.
  Future<void> _startAudio() async {
    final mix = AudioContext(
      android: AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {AVAudioSessionOptions.mixWithOthers},
      ),
    );
    await _bgm.setAudioContext(mix).catchError((_) {});
    if (!mounted) return;
    _bgm
        .play(AssetSource('sounds/hand_crank_lamp/bgm.mp3'), volume: _bgmVol)
        .catchError((_) {});
  }

  void _onCapture(String id) {
    HapticFeedback.lightImpact();
    // Pin the catch + play the capture animation. The tile shows the pre-kept
    // "perfect" frame (assets/images/episode_board/evidence/<id>.png) — no live,
    // timing-fragile screenshot; the catch still FEELS captured.
    _board.capture(id);
  }

  void _finish() => completeActivity(context);

  @override
  void dispose() {
    _bgm.stop().catchError((_) {});
    _bgm.dispose();
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ActivityNameHeader(
                              onBack: () => Navigator.of(context).maybePop(),
                              fallbackName: 'Why No Source Is Perfect',
                            ),
                          ),
                          const SizedBox(width: 8),
                          _node(),
                        ],
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
            // The auto-capture moment — a photo snaps + flies up to the node.
            Positioned.fill(
              child: ValueListenableBuilder<EvidenceTileFlash?>(
                valueListenable: _board.flashing,
                builder: (context, flash, _) => flash == null
                    ? const IgnorePointer(child: SizedBox.shrink())
                    : PhotoCaptureFlash(
                        key: ValueKey(flash.tile.id),
                        tile: flash.tile,
                        imageBytes: flash.imageBytes,
                        dockTarget: _nodeCenter(),
                        onDone: _board.flashDone,
                      ),
              ),
            ),
            // The peek drawer (the case board), opened from the node.
            if (_showDrawer)
              Positioned.fill(
                child: EvidenceBoardDrawer(
                  question: kEpisode1Question,
                  capturedIds: _board.capturedIds,
                  images: _board.images,
                  onClose: () { if (mounted) setState(() => _showDrawer = false); },
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
                        onDone: _finish,
                        onReplay: () => replayCurrentActivity(context),
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
