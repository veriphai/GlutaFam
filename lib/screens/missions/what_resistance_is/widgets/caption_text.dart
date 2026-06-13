// The top caption seat (fixed height so the stage never resizes). Two registers
// from a single channel: imperatives (Bricolage Grotesque, big, bold, Title Case)
// vs meaning-lines (Plus Jakarta Sans, now BIG too — 24px, wrapping to 2 lines),
// with a small mono ECHO line below (e1/e2 + the dial-guard d1).
//
// Swaps are sequential fade-out 190 → swap → fade-in (NEVER a cross-fade that
// shows both lines at once) — the trace_it_back _FadeSwapCaption pattern.

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/resistance_beats.dart';

class CaptionText extends StatelessWidget {
  const CaptionText({super.key, required this.caption, required this.echo});

  final ValueListenable<RCaption> caption;
  final ValueListenable<RCaption> echo;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 70, child: _FadeSwapCaption(caption: caption)),
        ValueListenableBuilder<RCaption>(
          valueListenable: echo,
          builder: (context, e, _) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 230),
            child: e.text.isEmpty
                ? const SizedBox(height: 14, key: ValueKey('no-echo'))
                : Padding(
                    key: ValueKey(e.text),
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      e.text,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 11.5,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.58),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _FadeSwapCaption extends StatefulWidget {
  const _FadeSwapCaption({required this.caption});
  final ValueListenable<RCaption> caption;

  @override
  State<_FadeSwapCaption> createState() => _FadeSwapCaptionState();
}

class _FadeSwapCaptionState extends State<_FadeSwapCaption>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 190), value: 1);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.16),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  late RCaption _shown = widget.caption.value;

  @override
  void initState() {
    super.initState();
    widget.caption.addListener(_onChange);
  }

  void _onChange() {
    final next = widget.caption.value;
    if (next.text == _shown.text) return;
    if (_c.status == AnimationStatus.reverse) return;
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

  Widget _line(RCaption cap) {
    if (cap.text.isEmpty) return const SizedBox.shrink();
    if (cap.imperative) {
      return Text(
        cap.text,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: GoogleFonts.bricolageGrotesque(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          height: 1.04,
          letterSpacing: -0.3,
          color: Colors.white,
          shadows: [Shadow(color: const Color(0xFFF5C451).withValues(alpha: 0.35), blurRadius: 18)],
        ),
      );
    }
    // Meaning-line — Plus Jakarta Sans, big like the imperatives (there's plenty
    // of room); wraps to 2 lines when it overflows.
    return Text(
      cap.text,
      textAlign: TextAlign.center,
      maxLines: 2,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: Colors.white.withValues(alpha: 0.95),
      ),
    );
  }
}
