// The Transformer (EP2 · beat 2.6) — the Flutter shell hosting the Flame stage.
// No mascot, no dialogue, no VO: guidance is a big top caption (imperatives +
// meaning-lines). The learner winds the secondary coil with a vertical drag; the
// auto phases (watch the core → the slow-motion surge → the depth-stop → the
// cliffhanger) are witnessed, not skippable.
//
// Layout (portrait, top→bottom): header back → EpisodeBoardStrip (the EP2 question)
// → top-text (fixed height) → the Flame scene (Expanded) → fixed-height CTA seat.
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
import 'config/transformer_copy.dart';
import 'game/transformer_game.dart';
import 'state/transformer_controller.dart';

class TheTransformerScreen extends StatefulWidget {
  const TheTransformerScreen({super.key});

  @override
  State<TheTransformerScreen> createState() => _TheTransformerScreenState();
}

class _TheTransformerScreenState extends State<TheTransformerScreen> {
  late final TransformerController _controller;
  late final TransformerGame _game;
  late final Widget _gameWidget;
  final EpisodeBoardCapture _board = EpisodeBoardCapture(kEpisode2Id);
  final GlobalKey _sceneKey = GlobalKey();
  final GlobalKey _nodeKey = GlobalKey();
  bool _showDrawer = false;

  @override
  void initState() {
    super.initState();
    _board.load();
    _controller = TransformerController()
      ..onDetent = _hapticDetent
      ..onKick = _hapticKick
      ..onCapture = _onCapture;
    _game = TransformerGame(controller: _controller);
    _gameWidget = GameWidget(game: _game); // built ONCE — never inside a rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.start());
  }

  void _hapticDetent() => HapticFeedback.selectionClick();
  void _hapticKick() => HapticFeedback.heavyImpact();

  void _onCapture(String id) {
    HapticFeedback.lightImpact();
    // Snapshot the ACTUAL scene at this beat → the tile shows the real frame the
    // learner saw. Post-frame so the beat's visual is painted first.
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
            const Positioned.fill(child: ActivityBgm('sounds/orbit_launcher/bgm.mp3')),
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
            // The in-stage wind gesture — a transparent forwarder. The controller
            // ignores it outside windUp/windDown and off the secondary limb; the
            // overlay above owns the back button + Continue, so those taps win.
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) => _controller.onPointerDown(e.localPosition),
                onPointerMove: (e) => _controller.onPointerMove(e.localPosition),
                onPointerUp: (e) => _controller.onPointerUp(),
                onPointerCancel: (e) => _controller.onPointerUp(),
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
                        fallbackName: 'The Transformer',
                      ),
                      const SizedBox(height: 26), // extra top padding — caption sits lower
                      _TopText(
                        caption: _controller.caption,
                        secondary: _controller.secondaryCaption,
                      ),
                      const Expanded(child: SizedBox.shrink()),
                      SizedBox(height: 84, child: _ctaSeat()),
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
            // The card earn — fires only after line 18 has held (cliffhanger → done).
            Positioned.fill(
              child: ValueListenableBuilder<bool>(
                valueListenable: _controller.showCardEarn,
                builder: (context, show, _) => show
                    ? CollectibleEarnOverlay(
                        card: kStillMachineCard,
                        eyebrow: 'NEW CARD',
                        brag: TxCopy.cardBrag,
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

  /// The CTA seat — the Continue pill appears only after the card is collected
  /// (line 18 persists behind it; the cliffhanger is never answered here).
  Widget _ctaSeat() {
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
        height: 52,
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
            Text(label,
                style: CareerText.cta.copyWith(color: CareerColors.onLight, fontSize: 15)),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, size: 20, color: CareerColors.onLight),
          ],
        ),
      ),
    );
  }
}

/// The top text — a big imperative (Bricolage) or meaning-line (Plus Jakarta
/// Sans), fading between lines, with a small secondary line below (the intro hook).
class _TopText extends StatelessWidget {
  const _TopText({required this.caption, required this.secondary});

  final ValueListenable<TxCaption> caption;
  final ValueListenable<TxCaption?> secondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 78, child: _FadeSwapCaption(caption: caption)),
        ValueListenableBuilder<TxCaption?>(
          valueListenable: secondary,
          builder: (context, s, _) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: s == null || s.text.isEmpty
                ? const SizedBox(height: 0, key: ValueKey('no-secondary'))
                : Padding(
                    key: ValueKey(s.text),
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      s.text,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        height: 1.28,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Fades the current caption OUT, swaps the text, then fades the new one IN (the
/// shipped 190 ms fade-out → swap → fade-in; never a cross-fade).
class _FadeSwapCaption extends StatefulWidget {
  const _FadeSwapCaption({required this.caption});
  final ValueListenable<TxCaption> caption;

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
  late TxCaption _shown = widget.caption.value;

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

  Widget _line(TxCaption cap) {
    if (cap.text.isEmpty) return const SizedBox.shrink();
    // The long meaning-lines (depth-stop, callback, synthesis) stay compact so
    // they fit; imperatives + short meaning-lines use the big bold style.
    if (cap.meaning && cap.long) {
      return Text(
        cap.text,
        textAlign: TextAlign.center,
        maxLines: 3,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          height: 1.22,
          fontWeight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.95),
        ),
      );
    }
    if (cap.meaning) {
      return Text(
        cap.text,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 21,
          height: 1.18,
          fontWeight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.96),
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
        shadows: [
          Shadow(color: CareerColors.gold.withValues(alpha: 0.35), blurRadius: 18),
        ],
      ),
    );
  }
}
