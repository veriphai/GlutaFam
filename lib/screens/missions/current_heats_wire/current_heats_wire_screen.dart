// The Hot Wire (Episode 2 · beat 2.3) — the Flutter shell.
//
// Pure Flutter: one CustomPainter stage (catenary wire + heat glow + pulses +
// motes), driven by a Ticker that pumps controller.tick(dt). The controller
// owns the sim, the geometry, and the SILENT phase machine (raise → discover →
// drop → rub → friction → raise again → loss → synthesis → card). The painter is a
// pure renderer.
//
// This is the module's first full teaching of loss = heat. Two registers of
// top-text (imperatives + meaning-lines), the EP2 evidence board pinned under the
// header, two live numbers (CURRENT | HEAT), one slider, one gold Continue CTA.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
import 'config/heat_wire_beats.dart';
import 'state/heat_wire_controller.dart';
import 'widgets/current_slider.dart';
import 'widgets/readout_chips.dart';
import 'widgets/wire_stage.dart';

class CurrentHeatsWireScreen extends StatefulWidget {
  const CurrentHeatsWireScreen({super.key});

  @override
  State<CurrentHeatsWireScreen> createState() => _CurrentHeatsWireScreenState();
}

class _CurrentHeatsWireScreenState extends State<CurrentHeatsWireScreen>
    with SingleTickerProviderStateMixin {
  late final HeatWireController _controller;
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
    _controller = HeatWireController()
      ..onSliderTick = () { HapticFeedback.selectionClick(); }
      ..onRubStroke = () { HapticFeedback.selectionClick(); }
      ..onDiscovery = () { HapticFeedback.heavyImpact(); }
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

  // Capture the ACTUAL scene at the discovery beat (PRD §9) → the tile shows the
  // real frame the learner saw. Post-frame so the beat's visual is painted first.
  void _onCapture(String id) {
    HapticFeedback.lightImpact();
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
            const Positioned.fill(child: ActivityBgm('sounds/code_satellite/bgm.mp3')),
            const Positioned.fill(child: ActivityDossierBackground()),
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: Column(
                    children: [
                      ActivityNameHeader(
                        onBack: () => Navigator.of(context).maybePop(),
                        fallbackName: 'Why Current Heats the Wire',
                      ),
                      const SizedBox(height: 26), // +16px top padding — caption sits a little lower
                      // The pinned EP2 board — the guiding question + the felt
                      // moments that auto-capture as the learner works.
                      // Top-text seat — fixed height so the stage never resizes as
                      // the lines swap (190 ms fade-out → swap → fade-in).
                      SizedBox(
                        height: 96,
                        child: _TopText(controller: _controller),
                      ),
                      const SizedBox(height: 4),
                      // The stage (the hero) — wrapped in the RepaintBoundary so we
                      // snapshot the REAL frame on capture.
                      Expanded(
                        child: RepaintBoundary(
                          key: _sceneKey,
                          child: WireStage(controller: _controller),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ReadoutChips(controller: _controller),
                      const SizedBox(height: 10),
                      CurrentSlider(controller: _controller),
                      const SizedBox(height: 6),
                      // CTA seat — Continue only in the done state (fixed height).
                      SizedBox(
                        height: 84,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _controller.showContinue,
                          builder: (context, show, _) => AnimatedSwitcher(
                            duration: const Duration(milliseconds: 380),
                            child: show
                                ? Align(
                                    key: const ValueKey('continue'),
                                    alignment: Alignment.bottomCenter,
                                    child: _ContinueButton(onTap: _controller.onContinue),
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
            // The collectible earn moment (after Continue).
            Positioned.fill(
              child: ValueListenableBuilder<bool>(
                valueListenable: _controller.showCardEarn,
                builder: (context, show, _) => show
                    ? CollectibleEarnOverlay(
                        card: kElectricFrictionCard,
                        eyebrow: HWCopy.cardEyebrow,
                        brag: HWCopy.cardBrag,
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

/// The top text — a bold imperative OR a softer meaning-line, fading between lines
/// (190 ms out → swap → in), with a small secondary line beneath. The longest
/// meaning-lines step down so they stay on ≤3 lines.
class _TopText extends StatelessWidget {
  const _TopText({required this.controller});
  final HeatWireController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 70, child: _FadeSwapCaption(caption: controller.caption)),
        ValueListenableBuilder<HWCaption?>(
          valueListenable: controller.secondary,
          builder: (context, s, _) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: (s == null || s.text.isEmpty)
                ? const SizedBox(height: 0, key: ValueKey('no-secondary'))
                : Padding(
                    key: ValueKey(s.text),
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      s.text,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: const Color(0xFFFFD27A).withValues(alpha: 0.8),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Fades the current caption OUT, swaps the text, then fades the new one IN — so
/// the two lines never overlap (never a cross-fade). Interrupting changes restart
/// the cycle from the current opacity.
class _FadeSwapCaption extends StatefulWidget {
  const _FadeSwapCaption({required this.caption});
  final ValueNotifier<HWCaption> caption;

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
  late HWCaption _shown = widget.caption.value;

  @override
  void initState() {
    super.initState();
    widget.caption.addListener(_onChange);
  }

  void _onChange() {
    final next = widget.caption.value;
    if (next.text == _shown.text) return;
    if (_c.status == AnimationStatus.reverse) return; // a swap is already running
    _c.reverse().then((_) {
      if (!mounted) return;
      setState(() => _shown = widget.caption.value);
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

  Widget _line(HWCaption cap) {
    if (cap.text.isEmpty) return const SizedBox.shrink();
    // Big hero style for imperatives AND the short discovery meaning-lines (e.g.
    // 'More Current, Hotter Wire', 'Rubbing Makes Heat Too') — only the LONG meaning-
    // lines step down so they stay on ≤3 lines.
    if (cap.imperative || !cap.long) {
      return Text(
        cap.text,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: GoogleFonts.bricolageGrotesque(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          height: 1.05,
          letterSpacing: -0.4,
          color: Colors.white,
          shadows: [
            Shadow(color: CareerColors.gold.withValues(alpha: 0.3), blurRadius: 16),
          ],
        ),
      );
    }
    // long meaning-line: Plus Jakarta Sans, stepped down to stay on ≤3 lines.
    return Text(
      cap.text,
      textAlign: TextAlign.center,
      maxLines: 3,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16.5,
        height: 1.22,
        fontWeight: FontWeight.w700,
        color: Colors.white.withValues(alpha: 0.95),
      ),
    );
  }
}

/// The done-state CTA — calm gold, full-width bottom pill.
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
              HWCopy.ctaContinue,
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
