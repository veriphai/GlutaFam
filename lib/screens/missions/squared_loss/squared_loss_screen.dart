// Squared Loss (Episode 2, beat 2.4) — the Flutter shell. Plain Flutter: a single
// Ticker pumps controller.tick(dt); the controller owns the sim + geometry + the
// silent phase machine; pure CustomPainters render the hero wire, the graph panel,
// and the slider. No Flame, no Forge2D (PRD §10).
//
// Guidance is the big top-text caption (imperatives + meaning-lines), the EP2
// evidence board pins the felt moment (`heat_quadruples`), and the close earns
// the Square Tax card → a cliffhanger meaning-line → Continue → Navigator.maybePop.
//
// Layout (top→bottom): header → EpisodeBoardStrip → fixed-96 top-text → Expanded
// stage (in a RepaintBoundary so a capture snapshots the real frame) → current
// slider → fixed-84 CTA seat. Capture-flash + card-earn overlays sit on top.

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../collectibles/collectible_earn_overlay.dart';
import '../activity_header.dart';
import '../lessonRunner.dart';
import '../activity_bgm.dart';
import '../../collectibles/collectible_models.dart';
import '../../home/career/careerCommon.dart';
import '../../home/career/careerTheme.dart';
import '../episode_board/activity_background.dart';
import '../episode_board/case_node.dart';
import '../episode_board/episode_board_capture.dart';
import '../episode_board/evidence_board_drawer.dart';
import '../episode_board/evidence_models.dart';
import '../episode_board/photo_capture_flash.dart';
import 'config/squared_loss_copy.dart';
import 'state/squared_loss_controller.dart';
import 'widgets/current_slider.dart';
import 'widgets/wire_stage.dart';

class SquaredLossScreen extends StatefulWidget {
  const SquaredLossScreen({super.key});

  @override
  State<SquaredLossScreen> createState() => _SquaredLossScreenState();
}

class _SquaredLossScreenState extends State<SquaredLossScreen>
    with SingleTickerProviderStateMixin {
  late final SquaredLossController _controller;
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  final EpisodeBoardCapture _board = EpisodeBoardCapture(kEpisode2Id);
  final GlobalKey _sceneKey = GlobalKey();
  final GlobalKey _nodeKey = GlobalKey();
  bool _showDrawer = false;

  @override
  void initState() {
    super.initState();
    _board.load();
    _controller = SquaredLossController()
      ..onDetent = (() => HapticFeedback.selectionClick())
      ..onDiscovery = (() => HapticFeedback.heavyImpact())
      ..onCapture = _onCapture;
    _ticker = createTicker(_onTick);
    _ticker.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.start();
    });
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt > 0 && dt < 0.1) _controller.tick(dt);
  }

  void _onCapture(String id) {
    HapticFeedback.lightImpact();
    // Snapshot the ACTUAL scene at this beat (PRD §9) → the tile shows the real
    // frame the learner saw (the fierce wire + HEAT 400). Post-frame so the
    // number-roll has landed in the painted frame.
    _board.capture(id); // pin + animate; tile uses its bundled frame / motif
  }

  void _finish() => completeActivity(context);

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
  void dispose() {
    _ticker.dispose();
    _controller.dispose();
    _board.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controller.reducedMotion = MediaQuery.of(context).disableAnimations;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: const Color(0xFF070A1C),
        body: Stack(
          children: [
            // Looping ambient BGM bed (a distinct satellite track per beat).
            const Positioned.fill(child: ActivityBgm('sounds/earth_detective/bgm.mp3')),
            const Positioned.fill(child: ActivityDossierBackground()),
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: Column(
                    children: [
                      ActivityNameHeader(
                        onBack: () => Navigator.of(context).maybePop(),
                        fallbackName: 'Why Loss Grows with Current',
                      ),
                      const SizedBox(height: 36), // extra top padding — caption sits lower
                      // The pinned EP2 evidence board — the guiding question + the
                      // felt moment that auto-captures as the wire leaps.
                      // The big top instruction — fixed height so the stage below
                      // never resizes as the text swaps (190 ms fade-out→swap→in).
                      SizedBox(
                        height: 96,
                        child: _TopText(
                          caption: _controller.caption,
                          controller: _controller,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // The hero stage — wrapped so a capture snapshots the real
                      // frame (background + wire + chips + panel, chrome outside).
                      Expanded(
                        child: RepaintBoundary(
                          key: _sceneKey,
                          child: Stack(
                            children: [
                              const Positioned.fill(child: ActivityDossierBackground()),
                              Positioned.fill(child: WireStage(controller: _controller)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // The current slider — the only variable in the hand.
                      CurrentSlider(controller: _controller),
                      const SizedBox(height: 6),
                      // The done-state CTA — appears only after the card is added.
                      SizedBox(
                        height: 84,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _controller.done,
                          builder: (context, done, _) => AnimatedSwitcher(
                            duration: const Duration(milliseconds: 380),
                            child: done
                                ? Align(
                                    key: const ValueKey('continue'),
                                    alignment: Alignment.bottomCenter,
                                    child: _ContinueButton(onTap: _finish),
                                  )
                                : const SizedBox.shrink(key: ValueKey('empty')),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // The corner case node — the photo-detective evidence board.
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: _node(),
            ),
            // The auto-capture moment — a framed moment-tile pins to the board.
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
            if (_showDrawer)
              Positioned.fill(
                child: EvidenceBoardDrawer(
                  question: kEpisode2Question,
                  capturedIds: _board.capturedIds,
                  images: _board.images,
                  onClose: () { if (mounted) setState(() => _showDrawer = false); },
                ),
              ),
            // The card earn moment (after the law is named, before Continue).
            Positioned.fill(
              child: ValueListenableBuilder<bool>(
                valueListenable: _controller.showCardEarn,
                builder: (context, show, _) => show
                    ? CollectibleEarnOverlay(
                        card: kSquareTaxCard,
                        eyebrow: 'NEW CARD',
                        brag: SLCopy.cardBrag,
                        showMascot: false,
                        onDone: _finish,
                        onReplay: () => replayCurrentActivity(context),
                      )
                    : const IgnorePointer(child: SizedBox.shrink()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The top text — an imperative or a meaning-line (de-personified fact), fading
/// between lines, with a small mono secondary hint under imperatives.
class _TopText extends StatelessWidget {
  const _TopText({required this.caption, required this.controller});
  final ValueListenable<SLCaption> caption;
  final SquaredLossController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 74, child: _FadeSwapCaption(caption: caption)),
        // The mono secondary hint (only on imperatives that carry one).
        ValueListenableBuilder<SLCaption>(
          valueListenable: caption,
          builder: (context, cap, _) {
            final s = SLCopy.of(cap).secondary;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: s.isEmpty
                  ? const SizedBox(height: 0, key: ValueKey('no-secondary'))
                  : Padding(
                      key: ValueKey(s),
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        s,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
            );
          },
        ),
      ],
    );
  }
}

/// Fades the current caption OUT, swaps the text, then fades the new one IN — so the
/// two lines never overlap (190 ms each way). Interrupting changes restart the cycle.
class _FadeSwapCaption extends StatefulWidget {
  const _FadeSwapCaption({required this.caption});
  final ValueListenable<SLCaption> caption;

  @override
  State<_FadeSwapCaption> createState() => _FadeSwapCaptionState();
}

class _FadeSwapCaptionState extends State<_FadeSwapCaption>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 190), value: 1);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.18),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  late SLCaption _shown = widget.caption.value;

  @override
  void initState() {
    super.initState();
    widget.caption.addListener(_onChange);
  }

  void _onChange() {
    if (widget.caption.value == _shown) return;
    if (_c.status == AnimationStatus.reverse) return; // a swap is already running
    _c.reverse().then((_) {
      if (!mounted) return;
      setState(() => _shown = widget.caption.value); // pick up the latest
      _c.forward();
    });
  }

  @override
  void dispose() {
    widget.caption.removeListener(_onChange);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _c,
        child: SlideTransition(position: _slide, child: _line(SLCopy.of(_shown))),
      ),
    );
  }

  Widget _line(SLLine cap) {
    if (cap.text.isEmpty) return const SizedBox.shrink();
    // Only the LONG meaning-line (the hand-off) steps down to fit the slot; every
    // other line — imperatives AND the short discovery/naming meaning-lines — is the
    // big display style (matches 2.3).
    if (cap.meaning && cap.long) {
      return Text(
        cap.text,
        textAlign: TextAlign.center,
        maxLines: 3,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          height: 1.22,
          fontWeight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.95),
        ),
      );
    }
    return Text(
      cap.text,
      textAlign: TextAlign.center,
      maxLines: 2,
      style: GoogleFonts.bricolageGrotesque(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -0.3,
        color: Colors.white,
        shadows: [Shadow(color: CareerColors.gold.withValues(alpha: 0.35), blurRadius: 18)],
      ),
    );
  }
}

/// The done-state CTA — calm gold gradient pill, full-width bottom button.
class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 52,
        width: double.infinity,
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
              SLCopy.cta,
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
