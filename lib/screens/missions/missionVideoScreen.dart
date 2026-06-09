// MissionVideoScreen — a one-shot, full-screen narrative video used as the
// intro / outro cutscene for a "lesson" (see lessonRunner.dart).
//
// Source URLs may be either:
//   • a bundled asset path (e.g. "assets/videos/missions/restore_earth/intro.mp4"),
//     which we load via VideoPlayerController.asset(); or
//   • a network URL ("http://..." / "https://..." e.g. an S3 link), which we
//     load via VideoPlayerController.networkUrl(...).
// The prefix on the `source` string is the dispatch signal — no separate
// flag needed.
//
// Behaviour:
//   • Auto-plays with audio.
//   • BoxFit.cover so a 9:16 source fills the screen edge-to-edge on
//     20:9 phones; a small slice of horizontal padding may crop. Tap the
//     Skip button (top-right, surfaces after `skipDelay`) to leave early.
//   • When the video reaches its end, the screen pops itself WITH result
//     `true` so the lesson runner advances to the next stage. Skip and
//     init-failure pops also return `true` (both mean "move on").
//   • Any init failure (corrupt asset, decoder issue, broken URL) pops
//     immediately — the runner treats the missing cutscene as "skip
//     directly to the next stage" instead of blocking the user.
//   • System back / hardware back gesture PAUSES the video and raises the
//     leave-lesson confirm modal (leaveLessonDialog.dart). "Keep Going"
//     resumes playback exactly where it paused; "Leave Mission" pops with
//     result `false` — the runner reads that as "user wants OUT of the
//     lesson" and stops pushing further resources (see lessonRunner.dart).

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../../utils/howwowEventLogger.dart';
import '../../utils/howwowEventNames.dart';
import 'leaveLessonDialog.dart';

class MissionVideoScreen extends StatefulWidget {
  const MissionVideoScreen({
    super.key,
    required this.source,
    this.skipDelay = const Duration(milliseconds: 1500),
    this.fit = BoxFit.cover,
    this.lessonId,
    this.resourceIndex,
  });

  /// Either a bundled asset path (e.g. {@code "assets/videos/.../intro.mp4"})
  /// or a network URL ({@code "http(s)://..."}). Detected by prefix.
  final String source;

  /// How long after playback starts before the Skip button surfaces. Keeps
  /// users from accidentally tapping it before they realise the video has
  /// even started, and ensures the first beat of the cutscene plays.
  final Duration skipDelay;

  final BoxFit fit;

  /// Lesson context, for the {@code resource_skipped} analytics event
  /// fired when the user taps Skip. Both nullable so non-lesson uses
  /// (e.g. a standalone trailer) still work without a fake id.
  final String? lessonId;

  final int? resourceIndex;

  @override
  State<MissionVideoScreen> createState() => _MissionVideoScreenState();
}

class _MissionVideoScreenState extends State<MissionVideoScreen> {
  /// Foreground player — the primary video (and the only audio source).
  VideoPlayerController? _controller;

  /// Backdrop player — a SECOND controller pointing at the same source,
  /// muted, used for the blurred edge-to-edge backdrop layer. Required
  /// because a single VideoPlayerController's underlying texture can only
  /// be rendered by ONE VideoPlayer widget at a time; rendering the
  /// foreground controller twice leaves one of the layers blank (which is
  /// the bug we shipped just before this — the foreground went black).
  ///
  /// WEB ONLY. On Android/iOS two simultaneous hardware decoders of the
  /// same HD stream compete for codec instances and one silently stops
  /// rendering — on test devices the backdrop won and the FOREGROUND went
  /// black. (It also doubles cellular bandwidth.) Mobile renders the
  /// letterbox area as plain black instead; browsers decode two <video>
  /// elements cheaply, so web keeps the frosted-glass treat.
  VideoPlayerController? _backdrop;

  bool _ready = false;
  bool _showSkip = false;
  bool _popping = false;

  /// True while the leave-confirm modal is up — guards against a second
  /// back press spawning a second dialog before the first resolves.
  bool _confirmingLeave = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
    _init();
  }

  Future<void> _init() async {
    final src = widget.source;
    final isNetwork = src.startsWith('http://') || src.startsWith('https://');
    // Pin both controllers to TextureView (the default already, but
    // explicit — PlatformView mode does NOT respect ImageFiltered blur,
    // and the default can change between video_player versions /
    // platforms).
    VideoPlayerController make() => isNetwork
        ? VideoPlayerController.networkUrl(Uri.parse(src),
            viewType: VideoViewType.textureView)
        : VideoPlayerController.asset(src,
            viewType: VideoViewType.textureView);
    final c = make();
    // Backdrop decode is web-only — see the _backdrop field doc.
    final bg = kIsWeb ? make() : null;
    try {
      // Init in parallel — they hit the same URL so the OS / CDN edge
      // serves the second request from cache after the first.
      await Future.wait([c.initialize(), if (bg != null) bg.initialize()]);
      // Backdrop is silent (the foreground owns audio). Subtle but
      // critical: setVolume must come BEFORE play() so the first audio
      // frame is already muted.
      await bg?.setVolume(0.0);
      c.addListener(_onTick);
      if (!mounted) {
        c.dispose();
        bg?.dispose();
        return;
      }
      _controller = c;
      _backdrop = bg;
      _ready = true;
      // Play (both, on web). They may drift by a few hundred ms over the
      // length of the clip due to independent decoding pipelines, but the
      // heavy blur on the backdrop makes the drift visually invisible.
      await Future.wait([c.play(), if (bg != null) bg.play()]);
      setState(() {});
      Future.delayed(widget.skipDelay, () {
        if (mounted) setState(() => _showSkip = true);
      });
    } catch (e) {
      // ignore: avoid_print
      print('MissionVideoScreen: init failed for ${widget.source}: $e');
      c.dispose();
      bg?.dispose();
      if (mounted) _safePop();
    }
  }

  void _onTick() {
    final c = _controller;
    if (c == null || _popping) return;
    final v = c.value;
    // Playback error AFTER a successful init (decoder killed mid-stream,
    // network drop, codec eviction) — same graceful-skip treatment as an
    // init failure, instead of a frozen frame the user can't escape.
    // Skipping while the leave dialog is up would pop the screen under
    // the dialog, so hold off until it resolves.
    if (v.hasError && !_confirmingLeave) {
      // ignore: avoid_print
      print('MissionVideoScreen: playback error for ${widget.source}: '
          '${v.errorDescription}');
      _safePop();
      return;
    }
    if (!v.isInitialized) return;
    if (v.position >= v.duration && v.duration > Duration.zero) {
      _safePop();
    }
  }

  void _safePop() {
    if (_popping || !mounted) return;
    _popping = true;
    // `true` = "this resource finished, advance the lesson".
    //
    // MUST be a direct pop, NOT maybePop: this route carries
    // PopScope(canPop: false) for the leave-confirm flow, and maybePop
    // respects it — so it never popped, it just re-invoked the back
    // handler (which then no-op'd because _popping was already latched).
    // Net effect was a screen you could neither finish nor back out of.
    Navigator.of(context).pop(true);
  }

  /// System-back handler (via the PopScope around the Scaffold): pause
  /// the video, raise the leave-lesson confirm modal, then either resume
  /// playback (Keep Going — the forgiving default, also reached by
  /// tap-outside / back-again) or pop with `false` so the lesson runner
  /// records a back-out instead of a completion.
  ///
  /// Pausing BEFORE the modal matters twice over: the cutscene shouldn't
  /// narrate over the dialog, and a paused position can't cross the
  /// natural-end threshold in _onTick mid-prompt (which would pop `true`
  /// — "finished" — under the user's feet).
  Future<void> _onBackPressed() async {
    if (_popping || _confirmingLeave) return;
    _confirmingLeave = true;
    try {
      final c = _controller;
      final bg = _backdrop;
      final wasPlaying =
          c != null && c.value.isInitialized && c.value.isPlaying;
      // pause/play can throw a PlatformException when a controller is in
      // an errored state (e.g. the decoder died mid-stream on Android) —
      // never let that strand the back handler, or back goes dead.
      if (wasPlaying) {
        try {
          await Future.wait([c.pause(), if (bg != null) bg.pause()]);
        } catch (_) {}
      }
      if (!mounted) return;
      final leave = await showLeaveLessonDialog(
        context,
        lessonId: widget.lessonId,
        resourceIndex: widget.resourceIndex,
        resourceType: 'video',
      );
      if (!mounted) return;
      if (leave) {
        _popping = true;
        Navigator.of(context).pop(false);
        return;
      }
      if (wasPlaying && !_popping) {
        try {
          await Future.wait([c.play(), if (bg != null) bg.play()]);
        } catch (_) {}
      }
    } finally {
      _confirmingLeave = false;
    }
  }

  /// Skip-button handler — distinct from natural-end pop so we can fire
  /// resource_skipped with the position the user bailed at. Falls
  /// through to _safePop for the actual navigation.
  void _skipTapped() {
    final c = _controller;
    int? atSec;
    if (c != null && c.value.isInitialized) {
      atSec = c.value.position.inSeconds;
    }
    HowwowEventLogger.instance.logImmediate(
      HowwowEvents.resourceSkipped,
      props: {
        'lesson_id': widget.lessonId,
        'resource_index': widget.resourceIndex,
        'type': 'video',
        'at_seconds': atSec,
      },
    );
    _safePop();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    _backdrop?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Self-pops (natural end / Skip / init failure) call Navigator.pop
      // directly and bypass PopScope; only the system back gesture lands
      // in _onBackPressed.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBackPressed();
      },
      child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_ready && _controller != null) ...[
            // Frosted-glass backdrop — WEB ONLY (see _backdrop field doc).
            // Mobile keeps the Scaffold's plain black behind the letterbox.
            if (_backdrop != null) ...[
              // Layer 1 — Backdrop video, cover-fit, muted. Plays the
              // same source as the foreground from a second
              // VideoPlayerController; sync drift between the two
              // controllers is tolerated because Layer 2 obscures
              // recognisable shapes anyway.
              Positioned.fill(
                child: ClipRect(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _backdrop!.value.size.width,
                      height: _backdrop!.value.size.height,
                      child: VideoPlayer(_backdrop!),
                    ),
                  ),
                ),
              ),
              // Layer 2a — translucent white tint. Plain alpha wash, just
              // the "milky" quality of glass. Kept LOW (0.20–0.30) so
              // the backdrop's colour shifts still bleed through; the
              // perception of "glass" comes from the noise layer above.
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
              ),
              // Layer 2b — noise grain. The key ingredient — real frosted
              // glass scatters light through microscopic surface roughness,
              // and the eye registers fine-grain texture as "scatter" /
              // "frosted". The tint above gives the milky colour; this
              // layer gives the glass FEEL. Procedurally painted with a
              // fixed RNG seed so it draws once + caches.
              //
              // Drop in a 256×256 PNG at assets/images/frosted_noise.png
              // and replace this CustomPaint with `Image.asset(...)
              // .image` tiled via DecorationImage to swap in a higher-
              // quality grain — the surrounding layers stay the same.
              const Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _FrostedNoisePainter(
                        density: 0.45,
                        grainSize: 1.4,
                        grainAlpha: 0.18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            // Foreground — the actual video at its natural aspect.
            Positioned.fill(
              child: ClipRect(
                child: FittedBox(
                  fit: widget.fit,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              ),
            ),
          ] else
            const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC83D)),
                ),
              ),
            ),
          if (_showSkip)
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 16),
                  child: _SkipButton(onTap: _skipTapped),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Skip',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.skip_next_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

/// Procedural noise grain — the "frost" texture that, combined with a
/// translucent white tint below it, makes the eye perceive a glass
/// surface instead of a flat fog. Real frosted glass scatters light
/// through microscopic surface roughness; fine-grain dots reproduce
/// that perceptual cue cheaply.
///
/// Fixed seed → identical pattern every paint → const constructor +
/// shouldRepaint() returning false means we draw once per screen size
/// and the GPU caches the result inside the RepaintBoundary wrapper.
/// No per-frame cost.
///
/// Tune knobs:
///   • density    — fraction of pixels covered (0–1). Higher = denser
///                  frost. ~0.4–0.6 reads as fine "frosty" texture;
///                  >0.7 starts looking like static noise.
///   • grainSize  — side length of each dot in pixels. 1.0–1.8 reads as
///                  glass; > 2.5 starts looking grainy/photographic.
///   • grainAlpha — opacity per dot. 0.15–0.25 is the sweet spot; higher
///                  whites out the backdrop entirely.
class _FrostedNoisePainter extends CustomPainter {
  const _FrostedNoisePainter({
    required this.density,
    required this.grainSize,
    required this.grainAlpha,
  });

  final double density;
  final double grainSize;
  final double grainAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    // Fixed seed: the noise looks identical every paint, the
    // RepaintBoundary parent caches the resulting raster, so this is
    // effectively a one-shot cost despite being procedurally generated.
    final rng = math.Random(0x1F057ED);
    final count = (size.width * size.height * density / 100).round();
    final paint = Paint();
    for (int i = 0; i < count; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      // Slight grey jitter per dot for organic feel — pure-white dots
      // look digital, off-white reads as real frost.
      final tone = 0.78 + rng.nextDouble() * 0.22;
      final channel = (tone * 255).round();
      paint.color = Color.fromRGBO(channel, channel, channel, grainAlpha);
      canvas.drawRect(
        Rect.fromLTWH(x, y, grainSize, grainSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_FrostedNoisePainter oldDelegate) =>
      oldDelegate.density != density ||
      oldDelegate.grainSize != grainSize ||
      oldDelegate.grainAlpha != grainAlpha;
}
