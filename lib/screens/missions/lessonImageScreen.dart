// LessonImageScreen — full-screen still image used as one stage in a
// lesson sequence. Pops itself either after [autoAdvanceAfter] (when the
// backend supplied a {@code durationSeconds}) or when the user taps the
// screen (when {@code durationSeconds} is null / 0). Self-pops return
// `true` ("finished, advance the lesson"); the system back gesture pops
// with null, which the lesson runner reads as "exit the lesson" — see
// lessonRunner.dart.
//
// Source URLs may be either:
//   • a bundled asset path (e.g. "assets/images/lessons/foo.png"),
//     loaded via AssetImage; or
//   • a network URL ("http://..." / "https://..." e.g. an S3 link),
//     loaded via NetworkImage.
// The prefix on the `source` string is the dispatch signal — no separate
// flag needed. Init failure (broken URL, missing asset) pops immediately
// so the lesson runner advances instead of stalling.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class LessonImageScreen extends StatefulWidget {
  const LessonImageScreen({
    super.key,
    required this.source,
    this.autoAdvanceAfter,
    this.caption,
    this.fit = BoxFit.cover,
  });

  /// Either a bundled asset path ("assets/...") or a network URL
  /// ("http(s)://..."). Detected by prefix.
  final String source;

  /// When non-null, the screen auto-pops after this delay. When null, the
  /// screen waits for the user to tap anywhere.
  final Duration? autoAdvanceAfter;

  /// Optional caption rendered on top of the image (bottom of the screen).
  final String? caption;

  final BoxFit fit;

  @override
  State<LessonImageScreen> createState() => _LessonImageScreenState();
}

class _LessonImageScreenState extends State<LessonImageScreen> {
  Timer? _timer;
  bool _popping = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
    final after = widget.autoAdvanceAfter;
    if (after != null && after > Duration.zero) {
      _timer = Timer(after, _safePop);
    }
  }

  void _safePop() {
    if (_popping || !mounted) return;
    _popping = true;
    // `true` = "this resource finished, advance the lesson". The system
    // back gesture bypasses this method and pops with null, which the
    // lesson runner reads as "exit the lesson".
    Navigator.of(context).maybePop(true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  ImageProvider _imageProvider() {
    final src = widget.source;
    final isNetwork = src.startsWith('http://') || src.startsWith('https://');
    return isNetwork ? NetworkImage(src) : AssetImage(src) as ImageProvider;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Tap-to-advance only when no auto-advance timer is running.
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.autoAdvanceAfter == null ? _safePop : null,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image(
                image: _imageProvider(),
                fit: widget.fit,
                errorBuilder: (_, __, ___) {
                  // Skip the resource if the image fails to load instead
                  // of leaving the user staring at a black screen.
                  WidgetsBinding.instance.addPostFrameCallback((_) => _safePop());
                  return const SizedBox.shrink();
                },
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFFFC83D)),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.caption != null && widget.caption!.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    child: Text(
                      widget.caption!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        shadows: const [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 12,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
