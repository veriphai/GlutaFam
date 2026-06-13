// The Transmission Trick (Episode 2 · beat 2.5) · THE STAR — the Flutter shell
// hosting the Flame stage. No Voltix, no dialogue, no VO: guidance is the big
// imperative/meaning caption at the TOP, and the kid drives the whole lesson by
// dragging the HERO rectangle's top edge up (raise the voltage → the current falls
// by itself → the wire cools → the far town lights). Silent (most shipped
// electricity activities are — PRD §10).
//
// Layout: a full-bleed Stack — energy-field background → the Flame GameWidget (built
// ONCE) → a transparent Listener forwarding pointers to the controller (the rectangle
// drag) → a SafeArea overlay (back + EP2 board strip + caption + fixed CTA seat) →
// the capture-flash + Card 10 ("Starve the Wire") earn overlay.
//
// One clock: only the Flame game ticks the controller (game.update → controller.tick).

import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
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
import 'config/transmission_beats.dart';
import 'game/transmission_game.dart';
import 'state/transmission_controller.dart';
import 'widgets/readout_panel.dart';
import 'widgets/voltage_slider.dart';

class TransmissionTrickScreen extends StatefulWidget {
  const TransmissionTrickScreen({super.key});

  @override
  State<TransmissionTrickScreen> createState() => _TransmissionTrickScreenState();
}

class _TransmissionTrickScreenState extends State<TransmissionTrickScreen> {
  late final TransmissionController _controller;
  late final TransmissionGame _game;
  late final Widget _gameWidget;
  final EpisodeBoardCapture _board = EpisodeBoardCapture(kEpisode2Id);
  final GlobalKey _sceneKey = GlobalKey();
  final GlobalKey _nodeKey = GlobalKey();
  bool _showDrawer = false;

  @override
  void initState() {
    super.initState();
    _board.load();
    _controller = TransmissionController()
      ..onDetent = (() {
        HapticFeedback.selectionClick();
      })
      ..onDiscovery = (() {
        HapticFeedback.heavyImpact(); // the inversion lands
      })
      ..onCapture = _onCapture;
    _game = TransmissionGame(controller: _controller);
    _gameWidget = GameWidget(game: _game); // built ONCE — never inside a rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.start());
  }

  void _onCapture(String id) {
    HapticFeedback.lightImpact();
    // Snapshot the ACTUAL scene at the discovery beat (PRD §9) → the tile shows the
    // real frame the kid saw. Post-frame so the beat's visual is painted, then crop
    // to the evidence catalog's framing for this id.
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
            const Positioned.fill(child: ActivityBgm('sounds/how_much_can_you_see/bgm.mp3')),
            // The dossier background — full-bleed behind the whole column.
            const Positioned.fill(child: ActivityDossierBackground()),
            // The activity-3 COLUMN: header → caption → boxed diagonal stage → the
            // hero rectangle in its OWN seat → V/I readouts → CTA. Each lives in its
            // own band, so nothing can overlap anything (the old full-bleed bug).
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: Column(
                    children: [
                      ActivityNameHeader(
                        onBack: () => Navigator.of(context).maybePop(),
                        fallbackName: 'Why Power Lines Use High Voltage',
                      ),
                      const SizedBox(height: 36), // extra top padding — caption sits lower
                      // The big top caption — imperatives (Bricolage) + meaning-lines
                      // (PJS); fades out → swaps → fades in (never cross-fades).
                      _TopText(caption: _controller.caption),
                      const SizedBox(height: 8),
                      // The boxed diagonal stage (plant → steel pylons → hot wire →
                      // climbing town). Now takes ALL the leftover height — the morphing
                      // rectangle is gone; the pinned POWER is a fixed card below.
                      // Transparent Flame bg → the dossier shows through.
                      Expanded(
                        child: RepaintBoundary(key: _sceneKey, child: _gameWidget),
                      ),
                      const SizedBox(height: 12),
                      // POWER (PINNED, fixed = 1000) + VOLTAGE | CURRENT (the two that
                      // move, opposite each other).
                      ReadoutPanel(controller: _controller),
                      const SizedBox(height: 12),
                      // The control — a simple VOLTAGE slider (like 2.3/2.4).
                      VoltageSlider(controller: _controller),
                      const SizedBox(height: 10),
                      // Fixed-height CTA seat — Continue appears after the card.
                      SizedBox(height: 70, child: _bottomControls()),
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
            // The earn moment — Card 10 "Starve the Wire" (the STAR's reward).
            Positioned.fill(
              child: ValueListenableBuilder<bool>(
                valueListenable: _controller.showCardEarn,
                builder: (context, show, _) => show
                    ? CollectibleEarnOverlay(
                        card: kStarveTheWireCard,
                        eyebrow: 'NEW CARD',
                        brag: TTCopy.cardBrag,
                        showMascot: false, // no Voltix in this activity
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
      valueListenable: _controller.canFinish,
      builder: (context, canFinish, _) => canFinish
          ? Center(child: _continueButton())
          : const SizedBox.shrink(),
    );
  }

  Widget _continueButton() {
    return PressableScale(
      onTap: _finish,
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
            Text('Continue',
                style: CareerText.cta.copyWith(color: CareerColors.onLight, fontSize: 15)),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, size: 20, color: CareerColors.onLight),
          ],
        ),
      ),
    );
  }
}

/// The top text — one register at a time (bold imperative vs softer meaning-line),
/// fading OUT → swap → IN so the two lines never overlap (NOT AnimatedSwitcher, which
/// cross-fades). Meaning-lines now render at the SAME size as imperatives (28px).
class _TopText extends StatelessWidget {
  const _TopText({required this.caption});

  final ValueListenable<TTCaption> caption;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 96, child: _FadeSwapCaption(caption: caption));
  }
}

class _FadeSwapCaption extends StatefulWidget {
  const _FadeSwapCaption({required this.caption});
  final ValueListenable<TTCaption> caption;

  @override
  State<_FadeSwapCaption> createState() => _FadeSwapCaptionState();
}

class _FadeSwapCaptionState extends State<_FadeSwapCaption>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 190), value: 1);
  late final Animation<Offset> _slide = Tween<Offset>(
          begin: const Offset(0, 0.18), end: Offset.zero)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  late TTCaption _shown = widget.caption.value;

  @override
  void initState() {
    super.initState();
    widget.caption.addListener(_onChange);
  }

  void _onChange() {
    final next = widget.caption.value;
    if (next.text == _shown.text && next.meaning == _shown.meaning) return;
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

  Widget _line(TTCaption cap) {
    if (cap.text.isEmpty) return const SizedBox.shrink();
    // Meaning-lines are now AS BIG as the imperatives (28px) — they're all short,
    // so they fit on 1–2 lines in the 96px seat; wraps to 2 if it overflows.
    if (cap.meaning) {
      return Text(
        cap.text,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          height: 1.1,
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
