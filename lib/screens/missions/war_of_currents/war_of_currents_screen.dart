// War of the Currents (EP2 · beat 2.8) — the Flutter shell hosting the Flame map.
// No mascot, no narrator: guidance is the big top caption; the only input is tapping
// DC or AC. On an 1880s map the learner sends the same power, down the same line, to
// the same far city — choosing the kind of current. DC: no transformer → enormous
// current → the wire cooks → the power dies as heat before arriving (witnessed
// failure, captured-as-felt only). AC: stepped up → trickle current → sails across
// to a fully-lit city (captured: 'ac_sails_across'). Only AFTER both runs is the
// War of the Currents named. NO CARD — end on the discovery + capture, then a gold
// Continue CTA → Navigator.maybePop. The bridge lands into EP3 (wall AC; DC made
// inside gadgets; the charger brick warms).
//
// One clock: only the Flame game ticks the controller (game.update → controller.tick).

import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:google_fonts/google_fonts.dart';

import '../../collectibles/collectible_earn_overlay.dart';
import '../../collectibles/collectible_models.dart';
import '../../home/career/careerCommon.dart';
import '../../home/career/careerTheme.dart';
import '../episode_board/activity_background.dart';
import '../episode_board/case_node.dart';
import '../episode_board/episode_board_capture.dart';
import '../episode_board/evidence_board_drawer.dart';
import '../episode_board/evidence_models.dart';
import '../episode_board/photo_capture_flash.dart';
import '../activity_header.dart';
import '../lessonRunner.dart';
import '../activity_bgm.dart';
import 'config/woc_copy.dart';
import 'game/woc_game.dart';
import 'state/woc_controller.dart';
import 'widgets/choice_dock.dart';

class WarOfCurrentsScreen extends StatefulWidget {
  const WarOfCurrentsScreen({super.key});

  @override
  State<WarOfCurrentsScreen> createState() => _WarOfCurrentsScreenState();
}

class _WarOfCurrentsScreenState extends State<WarOfCurrentsScreen> {
  late final WocController _controller;
  late final WocGame _game;
  late final Widget _gameWidget;
  final EpisodeBoardCapture _board = EpisodeBoardCapture(kEpisode2Id);
  final GlobalKey _sceneKey = GlobalKey();
  final GlobalKey _nodeKey = GlobalKey();
  bool _showDrawer = false;

  @override
  void initState() {
    super.initState();
    _board.load();
    _controller = WocController()
      ..onChipTap = _hapticSelect
      ..onFailure = _hapticHeavy // the DC failure frame
      ..onCapture = _onCapture;
    _game = WocGame(controller: _controller);
    _gameWidget = GameWidget(game: _game); // built ONCE — never inside a rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.start();
    });
  }

  void _hapticSelect() => HapticFeedback.selectionClick();
  void _hapticHeavy() => HapticFeedback.heavyImpact();

  void _onCapture(String id) {
    HapticFeedback.lightImpact();
    // Snapshot the ACTUAL scene at the discovery beat (PRD §9) so the tile is the
    // real frame the kid saw. Post-frame so the beat's visual is painted.
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
            const Positioned.fill(child: ActivityBgm('sounds/satellite_doctor/bgm.mp3')),
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
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: Column(
                    children: [
                      ActivityNameHeader(
                        onBack: () => Navigator.of(context).maybePop(),
                        fallbackName: 'Why the Grid Is AC',
                      ),
                      const SizedBox(height: 10),
                      // The pinned episode board — the EP2 question + captured tiles.
                      // The top caption — imperatives (big/bold) vs meaning-lines.
                      SizedBox(height: 96, child: _TopText(caption: _controller.caption)),
                      // The living map fills this transparent center.
                      const Expanded(child: SizedBox.shrink()),
                      // ONE bottom seat shared by the DC/AC buttons and the Continue
                      // CTA (mutually exclusive in time) — pushed to the very bottom so
                      // the buttons clear the power plant in the lower-left.
                      SizedBox(
                        height: 88,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _dockSeat(),
                            _ctaSeat(),
                          ],
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
            // The card earn — kHighRoadCard, the EP2 finale (the grid is AC).
            // Its Continue → next activity; Replay → redo. The last screen.
            Positioned.fill(
              child: ValueListenableBuilder<bool>(
                valueListenable: _controller.showCardEarn,
                builder: (context, show, _) => show
                    ? CollectibleEarnOverlay(
                        card: kHighRoadCard,
                        eyebrow: 'NEW CARD',
                        brag:
                            'AC wins the grid — only it can ride the transformer up to the '
                            "voltage that crosses a whole country. That's why the grid is AC.",
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

  // The dock seat — the DC/AC current buttons (live only when a choice is open).
  Widget _dockSeat() => Center(child: ChoiceDock(controller: _controller));

  Widget _ctaSeat() {
    return ValueListenableBuilder<bool>(
      valueListenable: _controller.showContinue,
      builder: (context, show, _) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: show
            ? Center(child: _continueButton())
            : const SizedBox.shrink(),
      ),
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
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              WocCopy.ctaLabel,
              style: CareerText.cta.copyWith(color: CareerColors.onLight, fontSize: 15),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, size: 20, color: CareerColors.onLight),
          ],
        ),
      ),
    );
  }
}

/// The top text — fades the current caption OUT (190ms), swaps, fades IN, so two
/// lines never overlap (AnimatedSwitcher cross-fades). Imperatives render big/bold
/// (Bricolage 28 w800); meaning-lines render Plus Jakarta Sans (long lines smaller).
class _TopText extends StatelessWidget {
  const _TopText({required this.caption});
  final ValueListenable<WocLine> caption;

  @override
  Widget build(BuildContext context) {
    // _FadeSwapCaption already centers its content, so no outer Center is needed.
    return _FadeSwapCaption(caption: caption);
  }
}

class _FadeSwapCaption extends StatefulWidget {
  const _FadeSwapCaption({required this.caption});
  final ValueListenable<WocLine> caption;

  @override
  State<_FadeSwapCaption> createState() => _FadeSwapCaptionState();
}

class _FadeSwapCaptionState extends State<_FadeSwapCaption>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 190),
    value: 1,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.18),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  late WocLine _shown = widget.caption.value;

  @override
  void initState() {
    super.initState();
    widget.caption.addListener(_onChange);
  }

  void _onChange() {
    final next = widget.caption.value;
    if (next == _shown) return;
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
        child: SlideTransition(position: _slide, child: _line(WocCopy.cap(_shown))),
      ),
    );
  }

  Widget _line(WocCaption cap) {
    if (cap.text.isEmpty) return const SizedBox.shrink();
    // Long meaning-lines stay compact so they fit; imperatives + short meaning-lines
    // use the same big display style.
    if (cap.meaning && cap.long) {
      return Text(
        cap.text,
        textAlign: TextAlign.center,
        maxLines: 3,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16.5,
          height: 1.24,
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
          fontSize: 18,
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
