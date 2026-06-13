// Shape the Wire — Episode 2, beat 2.2 (registry id `what_resistance_is`). The
// Flutter shell hosting the CustomPainter stage. One voice (the captions); no
// mascot, no narrator, no info-cards. The wire itself is the control: drag it long
// and thin to choke the current, squash it short and fat to let it run — while the
// VOLTAGE chip sits frozen under its pin the whole time. Resistance is named only
// after both extremes are felt.
//
// Layout (a full-bleed Stack): the energy-field background → the painter stage,
// both wrapped in a RepaintBoundary so the scene can be snapshotted → a SafeArea
// overlay (back + pinned EpisodeBoardStrip + fixed-96 caption seat + Expanded
// WireSurface + fixed-84 CTA seat) → the Card 07 earn overlay.
//
// EVIDENCE: this beat captures the 2.2 distractor 'fat_wire' when the "…Called
// Resistance" line lands (the RESISTANCE specimen on the wire). The pinned
// question strip shows throughout (the episode spine).
//
// One clock: a single Ticker drives controller.tick.

import 'dart:async'; // TEMP-PREVIEW

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
import '../episode_board/evidence_models.dart' show kEpisode2Question, kEpisode2Id;
import '../episode_board/photo_capture_flash.dart';
import 'config/resistance_beats.dart';
import 'state/resistance_controller.dart';
import 'widgets/caption_text.dart';
import 'widgets/wire_surface.dart';

class WhatResistanceIsScreen extends StatefulWidget {
  const WhatResistanceIsScreen({super.key});

  @override
  State<WhatResistanceIsScreen> createState() => _WhatResistanceIsScreenState();
}

class _WhatResistanceIsScreenState extends State<WhatResistanceIsScreen>
    with SingleTickerProviderStateMixin {
  late final ResistanceController _controller;
  late final Ticker _ticker;
  final GlobalKey _sceneKey = GlobalKey();
  final GlobalKey _nodeKey = GlobalKey();
  bool _showDrawer = false;
  Timer? _previewTimer; // TEMP-PREVIEW

  // The EP2 board: the pinned question + tiles captured so far. This beat pins
  // the 2.2 distractor 'fat_wire' at the "…Called Resistance" line.
  final EpisodeBoardCapture _board = EpisodeBoardCapture(kEpisode2Id);

  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _board.load();
    _controller = ResistanceController()
      ..onDetent = _selectionClick
      ..onDiscovery = _heavyImpact
      ..onFatMoment = _selectionClick
      ..onPinClamp = _selectionClick
      ..onDeny = _lightImpact
      ..onCapture = _onCapture;
    _ticker = createTicker(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _previewTimer = Timer.periodic(const Duration(milliseconds: 16), (_) { if (mounted) _controller.tick(0.016); }); // TEMP-PREVIEW
      _controller.start();
    });
  }

  void _selectionClick() => HapticFeedback.selectionClick();
  void _heavyImpact() => HapticFeedback.heavyImpact();
  void _lightImpact() => HapticFeedback.lightImpact();

  void _onTick(Duration now) {
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (dt > 0) _controller.tick(dt);
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
    _previewTimer?.cancel(); // TEMP-PREVIEW
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
            const Positioned.fill(child: ActivityBgm('sounds/choose_right_satellite/bgm.mp3')),
            // Full-bleed shared dossier background (same as the other activities).
            const Positioned.fill(child: ActivityDossierBackground()),
            // The chrome column: header → pinned board → fixed caption seat →
            // the STAGE (Expanded) → fixed CTA seat. The interactive WireSurface
            // lives INSIDE the stage so its painter factors are stage-relative
            // (PRD §16) and the source bar / dial / chips never hide under chrome.
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: Column(
                    children: [
                      ActivityNameHeader(
                        onBack: () => Navigator.of(context).maybePop(),
                        fallbackName: 'Resistance',
                      ),
                      const SizedBox(height: 30), // breathing room above the caption messages
                      // Fixed caption seat so the stage never resizes.
                      SizedBox(
                        height: 96,
                        child: CaptionText(
                          caption: _controller.caption,
                          echo: _controller.echo,
                        ),
                      ),
                      // The stage — wrapped in a RepaintBoundary so the scene is
                      // snapshot-ready (kept for parity with the capture pattern
                      // even though this beat pins no evidence tiles).
                      Expanded(
                        child: RepaintBoundary(
                          key: _sceneKey,
                          child: WireSurface(controller: _controller),
                        ),
                      ),
                      // Fixed CTA seat — the gold pill appears only at the end.
                      SizedBox(
                        height: 84,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _controller.showContinue,
                          builder: (context, show, _) => show
                              ? Center(child: _ContinuePill(onTap: _finish))
                              : const SizedBox.shrink(),
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
            // The Card 07 earn moment.
            Positioned.fill(
              child: ValueListenableBuilder<bool>(
                valueListenable: _controller.showCardEarn,
                builder: (context, show, _) => show
                    ? CollectibleEarnOverlay(
                        card: kNarrowPipeCard,
                        eyebrow: RCopy.cardEyebrow,
                        brag: RCopy.cardBrag,
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

class _ContinuePill extends StatelessWidget {
  const _ContinuePill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 52,
        constraints: const BoxConstraints(minWidth: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5C451), Color(0xFFD9A43B)],
          ),
          borderRadius: BorderRadius.circular(CareerRadii.pill),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF5C451).withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              RCopy.cta,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1340),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, size: 20, color: Color(0xFF1A1340)),
          ],
        ),
      ),
    );
  }
}
