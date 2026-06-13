// AC vs DC (EP2 · beat 2.7) — the Flutter shell hosting the Flame stage. No
// mascot, no dialogue, no VO: guidance is a big two-register caption at the TOP
// (bold imperatives + softer meaning-lines), and the single gesture is a tap on
// the source dock (connect → flip → flip fast); everything else auto-plays.
//
// Layout (portrait, top→bottom): a full-bleed Stack — energy-field background →
// the Flame GameWidget (built ONCE, both wrapped in RepaintBoundary so captures
// snapshot the real scene) → a transparent Listener forwarding dock taps → a
// SafeArea overlay (back → EpisodeBoardStrip → top-text → CTA seat) → the
// capture-flash + Card 12 ("The Two Currents") earn overlay.
//
// One clock: only the Flame game ticks the controller (game.update → tick).
//
// SCOPE NOTE: the shared EP2 evidence catalog (frozen) carries ONLY
// 'ac_springs_alive' for this beat — the proposed 'dc_dead_transformer' tile was
// dropped at catalog time. So this activity fires exactly one capture; the dead
// state still lands its heavyImpact + scene-dim, just without a capture.

import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:google_fonts/google_fonts.dart';

import '../../collectibles/collectible_earn_overlay.dart';
import '../lessonRunner.dart';
import '../activity_bgm.dart';
import '../../collectibles/collectible_models.dart';
import '../../home/career/careerCommon.dart';
import '../../home/career/careerTheme.dart';
import '../activity_header.dart';
import '../episode_board/activity_background.dart';
import '../episode_board/case_node.dart';
import '../episode_board/episode_board_capture.dart';
import '../episode_board/evidence_board_drawer.dart';
import '../episode_board/evidence_models.dart';
import '../episode_board/photo_capture_flash.dart';
import 'config/acdc_copy.dart';
import 'game/acdc_game.dart';
import 'state/acdc_controller.dart';

class AcVsDcScreen extends StatefulWidget {
  const AcVsDcScreen({super.key});

  @override
  State<AcVsDcScreen> createState() => _AcVsDcScreenState();
}

class _AcVsDcScreenState extends State<AcVsDcScreen> {
  late final AcdcController _controller;
  late final AcdcGame _game;
  late final Widget _gameWidget;
  final EpisodeBoardCapture _board = EpisodeBoardCapture(kEpisode2Id);
  final GlobalKey _sceneKey = GlobalKey();
  final GlobalKey _nodeKey = GlobalKey();
  bool _showDrawer = false;

  @override
  void initState() {
    super.initState();
    _board.load();
    _controller = AcdcController()
      ..onFlip = _hapticTick
      ..onDiscovery = _hapticDiscovery
      ..onCapture = _onCapture;
    _game = AcdcGame(controller: _controller);
    _gameWidget = GameWidget(game: _game); // built ONCE — never inside a rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.start());
  }

  void _hapticTick() => HapticFeedback.selectionClick();
  void _hapticDiscovery() => HapticFeedback.heavyImpact();

  void _onCapture(String id) {
    HapticFeedback.lightImpact();
    // Snapshot the ACTUAL scene at this discovery beat → the tile shows the real
    // frame the learner saw. Post-frame so the beat's visual is painted.
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
        backgroundColor: CareerColors.bgMid,
        body: Stack(
          children: [
            // Looping ambient BGM bed (a distinct satellite track per beat).
            const Positioned.fill(child: ActivityBgm('sounds/power_balance/bgm.mp3')),
            // The scene layer, wrapped so we can snapshot the real frame on capture.
            Positioned.fill(
              child: RepaintBoundary(
                key: _sceneKey,
                child: Stack(
                  children: [
                    const Positioned.fill(child: ActivityDossierBackground()),
                    Positioned.fill(child: _gameWidget),
                  ],
                ),
              ),
            ),
            // The one gesture — a tap on the source dock. The controller ignores
            // taps outside the dock rect and outside the connect/flip phases. The
            // overlay above owns the back button + Continue, so those taps win.
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) => _controller.onTapDown(e.localPosition),
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: Column(
                    children: [
                      ActivityNameHeader(
                        onBack: () => Navigator.of(context).maybePop(),
                        fallbackName: 'AC and DC',
                      ),
                      const SizedBox(height: 10),
                      // Two de-personified registers: bold imperatives (what to do)
                      // + softer meaning-lines (the lesson). Fixed height so the
                      // stage never resizes.
                      SizedBox(height: 96, child: _TopText(caption: _controller.caption)),
                      // The living transformer scene fills this transparent center.
                      const Expanded(child: SizedBox.shrink()),
                      // Fixed-height CTA seat (only the post-card Continue).
                      SizedBox(height: 84, child: _bottomControls()),
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
            // Card 12 — "The Two Currents" — the earn overlay.
            Positioned.fill(
              child: ValueListenableBuilder<bool>(
                valueListenable: _controller.showCardEarn,
                builder: (context, show, _) => show
                    ? CollectibleEarnOverlay(
                        card: kTwoCurrentsCard,
                        eyebrow: 'NEW CARD',
                        brag: AcdcCopy.cardBrag,
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

  Widget _bottomControls() {
    return ValueListenableBuilder<bool>(
      valueListenable: _controller.showContinue,
      builder: (context, show, _) => show
          ? Center(child: _pillButton('Continue', _finish))
          : const SizedBox.shrink(),
    );
  }

  Widget _pillButton(String label, VoidCallback onTap) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 54,
        constraints: const BoxConstraints(minWidth: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          gradient: CareerGradients.gold,
          borderRadius: BorderRadius.circular(CareerRadii.pill),
          boxShadow: [
            BoxShadow(
                color: CareerColors.gold.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: CareerText.cta.copyWith(color: CareerColors.onLight, fontSize: 15)),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, size: 20, color: CareerColors.onLight),
          ],
        ),
      ),
    );
  }
}

/// The top text — two registers (bold imperative vs softer meaning-line), fading
/// between lines with the shipped 190 ms fade-out → swap → fade-in.
class _TopText extends StatelessWidget {
  const _TopText({required this.caption});
  final ValueListenable<AcdcCaption> caption;

  @override
  Widget build(BuildContext context) {
    return Center(child: _FadeSwapCaption(caption: caption));
  }
}

/// Fades the current caption OUT, swaps the text, then fades the new one IN — so
/// the two lines never overlap (an AnimatedSwitcher cross-fade would).
class _FadeSwapCaption extends StatefulWidget {
  const _FadeSwapCaption({required this.caption});
  final ValueListenable<AcdcCaption> caption;

  @override
  State<_FadeSwapCaption> createState() => _FadeSwapCaptionState();
}

class _FadeSwapCaptionState extends State<_FadeSwapCaption> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 190), value: 1);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.18),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  late AcdcCaption _shown = widget.caption.value;

  @override
  void initState() {
    super.initState();
    widget.caption.addListener(_onChange);
  }

  void _onChange() {
    final next = widget.caption.value;
    if (next.sameAs(_shown)) return;
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
        child: SlideTransition(position: _slide, child: _line(_shown)),
      ),
    );
  }

  Widget _line(AcdcCaption cap) {
    if (cap.text.isEmpty) return const SizedBox.shrink();
    // Only the LONG meaning-lines (fifty-hertz, the bridge) step down to fit; every
    // other line — imperatives AND the short meaning-lines — is the big display
    // style (matches 2.3 / 2.4).
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
