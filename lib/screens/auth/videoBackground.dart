// Full-bleed background that plays an embedded asset video on a loop.
//
// Default config matches the howwow login-screen brief: muted, autoplay, and
// looped over the first 3.9 seconds only (the source clip is 8s but only the
// opening 3.9s reads cleanly as a background). The loop is implemented as a
// position listener that seeks back to zero when the playhead crosses the
// loop-end mark — `controller.setLooping(true)` alone would loop the entire
// clip, which isn't what we want here.
//
// Renders a black background as a placeholder until the controller is ready
// so the screen never flashes a white frame on cold launch.

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBackground extends StatefulWidget {
  const VideoBackground({
    super.key,
    this.asset = 'assets/videos/intro_loop.mp4',
    this.placeholderAsset,
    this.loopEnd = const Duration(milliseconds: 3900),
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  /// Path to the video asset (declared under `flutter > assets` in pubspec).
  final String asset;

  /// Optional still-image asset shown while the video is initializing —
  /// typically the video's first frame. Eliminates the brief "black flash"
  /// that otherwise appears between mount and first decoded frame. Rendered
  /// with the same [fit] and [alignment] as the video so the swap is
  /// imperceptible.
  final String? placeholderAsset;

  /// Loop back to the start when the playhead reaches this point. Use
  /// [Duration.zero] (or a value >= clip duration) to play the full clip.
  final Duration loopEnd;

  /// How the video fits its parent bounds. `cover` (default) crops to fill;
  /// `fitWidth` or `contain` show the full frame with empty space on the
  /// unfilled axis (caller's background colour shows through).
  final BoxFit fit;

  /// Where the scaled video sits within the parent bounds. Only meaningful
  /// when [fit] doesn't fill both axes (e.g. `fitWidth` on a phone taller
  /// than the video's aspect ratio).
  final Alignment alignment;

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final c = VideoPlayerController.asset(widget.asset);
    try {
      await c.initialize();
      await c.setVolume(0); // muted background — no surprise audio on launch
      await c.setLooping(false); // we do our own loop via the position listener
      c.addListener(_onTick);
      if (!mounted) {
        c.dispose();
        return;
      }
      _controller = c;
      _ready = true;
      await c.play();
      setState(() {});
    } catch (e) {
      // Failed to initialize (corrupt asset, decoder issue, etc.) — silently
      // fall through to the black placeholder. Don't crash the login screen.
      c.dispose();
    }
  }

  void _onTick() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (widget.loopEnd > Duration.zero && c.value.position >= widget.loopEnd) {
      c.seekTo(Duration.zero);
    }
  }

  @override
  void dispose() {
    final c = _controller;
    if (c != null) {
      c.removeListener(_onTick);
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _controller == null) {
      // While the video initializes, render the first-frame still if the
      // caller supplied one. Same fit + alignment as the video so the swap
      // is imperceptible. Falls back to a solid colour if no placeholder
      // is provided — transparent here so the Scaffold's background colour
      // shows through (typically the same blue as the video).
      if (widget.placeholderAsset != null) {
        return Image.asset(
          widget.placeholderAsset!,
          fit: widget.fit,
          alignment: widget.alignment,
        );
      }
      return const SizedBox.expand();
    }
    final c = _controller!;
    // FittedBox + SizedBox sized to the video's intrinsic resolution makes
    // BoxFit.cover behave correctly inside a Positioned.fill ancestor.
    return ClipRect(
      child: FittedBox(
        fit: widget.fit,
        alignment: widget.alignment,
        child: SizedBox(
          width: c.value.size.width,
          height: c.value.size.height,
          child: VideoPlayer(c),
        ),
      ),
    );
  }
}
