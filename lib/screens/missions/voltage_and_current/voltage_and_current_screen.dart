// Voltage and Current — beat 2.1 ("The Push and the Flow"). The Flutter shell
// hosting a single-precision CustomPainter stage (PRD §10: one loop, one mote
// stream, one lamp, three chips — Flame would be overhead). Guidance is the big
// instruction caption at the TOP in two registers (imperatives + meaning-lines);
// there is no mascot, no Voltix, no VO. Silent (matches most shipped electricity
// activities, PRD §10/§13).
//
// THIS BEAT OPENS the locked 2.1→2.5 chain and PINS THE WIRE (the SAME WIRE chip,
// visible 100% of the activity) — load-bearing because 2.5 flips it (wire-fixed →
// power-fixed). It captures NO evidence tiles (per the build brief): the
// EpisodeBoardStrip shows the pinned EP2 question (and any tiles captured by other
// beats) but onCapture is never called here.
//
// One clock: a single Ticker drives controller.tick(dt). Completion = card earn →
// Continue → Navigator.maybePop (any pop = completion; no payload).

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
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
import 'config/vc_copy.dart';
import 'state/vc_controller.dart';
import 'widgets/vc_stage.dart';

class VoltageAndCurrentScreen extends StatefulWidget {
  const VoltageAndCurrentScreen({super.key});

  @override
  State<VoltageAndCurrentScreen> createState() => _VoltageAndCurrentScreenState();
}

class _VoltageAndCurrentScreenState extends State<VoltageAndCurrentScreen>
    with SingleTickerProviderStateMixin {
  late final VCController _controller;
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  // The EP2 board: shows the pinned question + tiles captured so far. This is the
  // FIRST EP2 activity, so it RESETS the board (wipes captures persisted from a
  // prior run — later EP2 beats `load()` to keep what's accumulated). It also
  // captures the 2.1 distractor 'push_flow' at the push/flow line.
  final EpisodeBoardCapture _board = EpisodeBoardCapture(kEpisode2Id);
  final GlobalKey _sceneKey = GlobalKey();
  final GlobalKey _nodeKey = GlobalKey();
  bool _showDrawer = false;

  @override
  void initState() {
    super.initState();
    _board.reset();
    _controller = VCController()
      ..onDetent = () { HapticFeedback.selectionClick(); }
      ..onDiscovery = () { HapticFeedback.heavyImpact(); } // the cutoff double-death
      ..onCapture = _onCapture;
    _ticker = createTicker(_onTick);
    _ticker.start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.start());
  }

  void _onTick(Duration now) {
    final dt = _last == Duration.zero ? 0.0 : (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (dt > 0 && dt < 0.1) _controller.tick(dt);
  }

  void _onCapture(String id) {
    HapticFeedback.lightImpact();
    _board.capture(id); // pin + animate; the tile uses its bundled frame / motif
  }

  void _finish() => completeActivity(context);

  /// The case node's global centre — so a captured photo flies up to land on it.
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
        backgroundColor: CareerColors.bgMid,
        body: Stack(
          children: [
            // Looping ambient BGM bed (a distinct satellite track per beat).
            const Positioned.fill(child: ActivityBgm('sounds/build_satellite/bgm.mp3')),
            // A full-bleed background so the CHROME ZONE (behind header/board/
            // banner) reads as the same deep field. This is NOT the capture
            // target — it just paints edge-to-edge under the chrome.
            const Positioned.fill(child: ActivityDossierBackground()),
            // Chrome + the centred STAGE. The stage now lives inside the Column as
            // the Expanded child between the banner and the CTA seat, so its paint
            // `size` IS the stage area (PRD §16: "stage = w × h of the Expanded
            // area"): factor anchors like the lamp (0.16h) and CURRENT chip
            // (0.285h) map INSIDE the centre region, clear of the chrome — instead
            // of against the full screen where they collided with the banner.
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: Column(
                    children: [
                      ActivityNameHeader(
                        onBack: () => Navigator.of(context).maybePop(),
                        fallbackName: 'Voltage and Current',
                      ),
                      const SizedBox(height: 10),
                      // Fixed-height banner so the stage never resizes (PRD §15).
                      SizedBox(
                        height: 96,
                        child: _FadeSwapCaption(caption: _controller.caption),
                      ),
                      const SizedBox(height: 8),
                      // THE STAGE — the Expanded centre region. The stage paints
                      // OVER the single full-bleed EnergyFieldBackground above, so
                      // the field is seamless edge-to-edge (no separate panel behind
                      // the circuit). 2.1 captures no evidence, so the RepaintBoundary
                      // needs no background of its own. The controller's hit-test
                      // limits drag response to the voltage console.
                      Expanded(
                        child: RepaintBoundary(
                          key: _sceneKey,
                          child: VCStage(controller: _controller),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Fixed-height CTA seat (h 84) — Continue appears after the card.
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
                  question: kEpisode2Question,
                  capturedIds: _board.capturedIds,
                  images: _board.images,
                  onClose: () { if (mounted) setState(() => _showDrawer = false); },
                ),
              ),
            // The card earn overlay (PRD §6.7/§8 — kPushFlowCard).
            Positioned.fill(
              child: ValueListenableBuilder<bool>(
                valueListenable: _controller.showCardEarn,
                builder: (context, show, _) => show
                    ? CollectibleEarnOverlay(
                        card: kPushFlowCard,
                        eyebrow: VCCopy.cardEyebrow,
                        brag: VCCopy.cardBrag,
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

  Widget _ctaSeat() {
    return ValueListenableBuilder<bool>(
      valueListenable: _controller.canFinish,
      builder: (context, canFinish, _) => canFinish
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
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5, fontWeight: FontWeight.w800, color: CareerColors.onLight)),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, size: 20, color: CareerColors.onLight),
          ],
        ),
      ),
    );
  }
}

/// The top text — fades the current caption OUT, swaps, then fades the new one IN
/// (190 ms; NOT AnimatedSwitcher, which cross-fades and briefly shows both). The
/// long meaning-lines (the water analogy, the "while the wire stays the same"
/// line) stay compact so they fit; every other line is the big imperative style.
class _FadeSwapCaption extends StatefulWidget {
  const _FadeSwapCaption({required this.caption});
  final ValueListenable<VCCaption> caption;

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
  late VCCaption _shown = widget.caption.value;

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

  Widget _line(VCCaption cap) {
    if (cap.text.isEmpty) return const SizedBox.shrink();
    // The LONG meaning-lines stay compact (smaller) so they fit; every other line
    // — imperatives AND short meaning-lines — is the big display style.
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
    if (cap.meaning) {
      return Text(
        cap.text,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          height: 1.12,
          fontWeight: FontWeight.w800,
          color: Colors.white.withValues(alpha: 0.97),
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
