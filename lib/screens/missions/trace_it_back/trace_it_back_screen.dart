// Trace It Back — the Flutter shell hosting the Flame stage. No Voltix, no
// dialogue, no VO: guidance is a big instruction caption at the TOP, and Beat 3
// walks the kid through the power sources ONE BY ONE via a "Next →" button (no
// selector). BGM stays as an ambient bed.
//
// Layout: a full-bleed Stack — energy-field background → the Flame GameWidget
// (built ONCE) → an in-stage turning gesture surface (spin the magnet / turn the
// turbine) → a SafeArea overlay (back + big instruction caption + bottom Next /
// Continue) → the Card 02 earn overlay.
//
// One clock: only the Flame game ticks the controller (game.update → controller.tick).

import 'package:audioplayers/audioplayers.dart';
import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:google_fonts/google_fonts.dart';

import '../../collectibles/collectible_earn_overlay.dart';
import '../activity_header.dart';
import '../lessonRunner.dart';
import '../../collectibles/collectible_models.dart';
import '../../home/career/careerCommon.dart';
import '../../home/career/careerTheme.dart';
import '../episode_board/photo_capture_flash.dart';
import '../episode_board/case_node.dart';
import '../episode_board/episode_board_capture.dart';
import '../episode_board/evidence_board_drawer.dart';
import '../episode_board/evidence_models.dart';
import '../episode_board/activity_background.dart';
import 'config/trace_back_beats.dart';
import 'game/trace_back_game.dart';
import 'state/trace_back_controller.dart';

class TraceItBackScreen extends StatefulWidget {
  const TraceItBackScreen({super.key});

  @override
  State<TraceItBackScreen> createState() => _TraceItBackScreenState();
}

class _TraceItBackScreenState extends State<TraceItBackScreen> {
  late final TraceBackController _controller;
  late final TraceBackGame _game;
  late final Widget _gameWidget;
  final EpisodeBoardCapture _board = EpisodeBoardCapture(kEpisode1Id);
  final GlobalKey _sceneKey = GlobalKey();
  final GlobalKey _nodeKey = GlobalKey(); // the case node, for an accurate fly target

  // Episode-board overlays (zero layout footprint): the corner node + peek drawer.
  // (The guiding question is posed by the case-briefing intro screen, not here.)
  bool _showDrawer = false;

  final AudioPlayer _bgm = AudioPlayer(); // ambient music bed (no VO)
  static const double _bgmVol = 0.16;

  @override
  void initState() {
    super.initState();
    // Act 2 is the episode's FIRST activity → start the evidence board fresh, so
    // each new run collects evidence again (Act 3 + the closing then accumulate it).
    _board.reset();
    _controller = TraceBackController()
      ..onCrankTick = _hapticTick
      ..onDiscovery = () { HapticFeedback.heavyImpact(); } // the "it died" beat
      ..onSourceStep = () { HapticFeedback.selectionClick(); }
      ..onCapture = _onCapture;
    _bgm.setReleaseMode(ReleaseMode.loop);
    _game = TraceBackGame(controller: _controller);
    _gameWidget = GameWidget(game: _game); // built ONCE — never inside a rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAudioThenBeat());
  }

  Future<void> _startAudioThenBeat() async {
    final mix = AudioContext(
      android: AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {AVAudioSessionOptions.mixWithOthers},
      ),
    );
    await _bgm.setAudioContext(mix).catchError((_) {});
    if (!mounted) return;
    _bgm.play(AssetSource('sounds/trace_it_back/bgm.mp3'), volume: _bgmVol).catchError((_) {});
    _controller.start();
  }

  void _hapticTick() => HapticFeedback.selectionClick();

  void _onCapture(String id) {
    HapticFeedback.lightImpact();
    // Pin the moment + play the capture animation. The tile shows the pre-kept
    // "perfect" frame (assets/images/episode_board/evidence/<id>.png) — no live,
    // timing-fragile screenshot; the discovery still FEELS captured.
    _board.capture(id);
  }

  void _finish() => completeActivity(context);

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
  void dispose() {
    _bgm.stop().catchError((_) {});
    _bgm.dispose();
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
            // In-stage turning gesture — the hand is on the chain (the controller
            // ignores it outside the magnet/turbine beats). The overlay above owns
            // the back button + the bottom Next/Continue, so those taps win there.
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
                      // Standard activity header: back + name, with the case
                      // node kept as the right-side control.
                      ActivityNameHeader(
                        onBack: () => Navigator.of(context).maybePop(),
                        fallbackName: 'How Electricity Is Made',
                        trailing: _node(),
                      ),
                      const SizedBox(height: 4),
                      // Two de-personified registers: bold imperatives (what to do)
                      // + softer meaning-lines (the lesson), plus the solar hook.
                      _TopText(caption: _controller.caption, secondary: _controller.secondary),
                      // The glowing vertical chain fills this transparent center.
                      const Expanded(child: SizedBox.shrink()),
                      // Bottom slot: Next (sources) / Continue (end).
                      SizedBox(height: 70, child: _bottomControls()),
                    ],
                  ),
                ),
              ),
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
                  question: kEpisode1Question,
                  capturedIds: _board.capturedIds,
                  images: _board.images,
                  onClose: () { if (mounted) setState(() => _showDrawer = false); },
                ),
              ),
            Positioned.fill(
              child: ValueListenableBuilder<bool>(
                valueListenable: _controller.showCardEarn,
                builder: (context, show, _) => show
                    ? CollectibleEarnOverlay(
                        card: kMagnetTrickCard,
                        eyebrow: 'NEW CARD',
                        brag: TBCopy.cardBrag,
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
      builder: (context, canFinish, _) {
        if (canFinish) return Center(child: _pillButton('Continue', _finish));
        return ValueListenableBuilder<bool>(
          valueListenable: _controller.showNext,
          builder: (context, showNext, __) => showNext
              ? Center(child: _pillButton('Next', _controller.nextSource))
              : const SizedBox.shrink(),
        );
      },
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
            BoxShadow(color: CareerColors.gold.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 6)),
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
/// between lines, with a small secondary line below (the solar depth-stop hook).
class _TopText extends StatelessWidget {
  const _TopText({required this.caption, required this.secondary});

  final ValueListenable<TBCaption> caption;
  final ValueListenable<String> secondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sequential fade-out → swap → fade-in (NOT AnimatedSwitcher, which
        // cross-fades and briefly shows both lines overlapping).
        SizedBox(height: 78, child: _FadeSwapCaption(caption: caption)),
        ValueListenableBuilder<String>(
          valueListenable: secondary,
          builder: (context, s, _) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: s.isEmpty
                ? const SizedBox(height: 0, key: ValueKey('no-secondary'))
                : Padding(
                    key: ValueKey(s),
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      s,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.55),
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
/// the two lines never overlap (the AnimatedSwitcher cross-fade did). Interrupting
/// changes restart the cycle from the current opacity.
class _FadeSwapCaption extends StatefulWidget {
  const _FadeSwapCaption({required this.caption});
  final ValueListenable<TBCaption> caption;

  @override
  State<_FadeSwapCaption> createState() => _FadeSwapCaptionState();
}

class _FadeSwapCaptionState extends State<_FadeSwapCaption> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 190), value: 1);
  late final Animation<Offset> _slide =
      Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  late TBCaption _shown = widget.caption.value;

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

  Widget _line(TBCaption cap) {
    if (cap.text.isEmpty) return const SizedBox.shrink();
    // The one LONG meaning-line (the depth-stop) stays compact so it fits; every
    // other line — imperatives AND short meaning-lines — is the same big style.
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
