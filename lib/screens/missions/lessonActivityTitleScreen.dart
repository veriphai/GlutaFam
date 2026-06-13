// A brief "chapter title" card the lesson runner shows BEFORE a named activity
// (a resource whose `caption` carries the activity's human title, e.g.
// "How Electricity Is Made"). It surfaces the name, then auto-advances into the
// activity — so a multi-activity episode reads as a sequence of named beats
// instead of activities silently blurring into each other.
//
// Pop protocol (matches the runner's expectations):
//   • true  — proceed into the activity (auto-advance after [hold], or a tap)
//   • false — system back → the runner treats it as leaving the lesson
//
// It is NOT a lesson resource: the runner injects it between resources and does
// not write any progress for it, so it never shifts the resume index.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home/career/careerTheme.dart';

class LessonActivityTitleScreen extends StatefulWidget {
  const LessonActivityTitleScreen({
    super.key,
    required this.title,
    this.eyebrow = 'NEXT UP',
    this.accent = CareerColors.gold,
    this.hold = const Duration(milliseconds: 1800),
  });

  final String title;
  final String eyebrow;
  final Color accent;
  final Duration hold;

  @override
  State<LessonActivityTitleScreen> createState() =>
      _LessonActivityTitleScreenState();
}

class _LessonActivityTitleScreenState extends State<LessonActivityTitleScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520))
        ..forward();
  Timer? _timer;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.hold, _advance);
  }

  void _advance() {
    if (_left) return;
    _left = true;
    _timer?.cancel();
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _in, curve: Curves.easeOut);
    final rise = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _in, curve: Curves.easeOutCubic));
    return PopScope(
      // System back → leave the lesson: pop `false` so the runner stops.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_left && mounted) {
          _left = true;
          _timer?.cancel();
          Navigator.of(context).pop(false);
        }
      },
      child: GestureDetector(
        onTap: _advance,
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          backgroundColor: const Color(0xFF0B1028),
          body: Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF141C44), Color(0xFF0B1028)],
                    ),
                  ),
                ),
              ),
              Center(
                child: FadeTransition(
                  opacity: fade,
                  child: SlideTransition(
                    position: rise,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 34),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.eyebrow,
                            style: GoogleFonts.poppins(
                              color: widget.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: 34,
                            height: 3,
                            decoration: BoxDecoration(
                              color: widget.accent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 40,
                child: Center(
                  child: FadeTransition(
                    opacity: fade,
                    child: Text(
                      'tap to continue',
                      style: GoogleFonts.poppins(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
