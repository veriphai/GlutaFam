// The large top instruction — a short "what to do now" line (3–4 words) that
// guides the kid through the sequential flow ("Spin the Handle", "Now the Fan",
// "No Spin, No Light", …). Replaces the old Voltix mascot + speech bubble.
//
// Transitions are SEQUENTIAL (fade-out → swap text → fade-in), never a
// cross-fade — so the old and new lines never overlap on screen for a frame.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../state/crank_controller.dart';

class InstructionBanner extends StatefulWidget {
  const InstructionBanner({super.key, required this.controller});

  final CrankController controller;

  @override
  State<InstructionBanner> createState() => _InstructionBannerState();
}

class _InstructionBannerState extends State<InstructionBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 190));
  late String _shown; // the text currently painted
  String? _pending; // a newer text waiting for the fade-out to finish

  @override
  void initState() {
    super.initState();
    _shown = widget.controller.instruction.value;
    _ac.value = 1.0; // start fully visible
    _ac.addStatusListener(_onStatus);
    widget.controller.instruction.addListener(_onText);
  }

  void _onText() {
    final next = widget.controller.instruction.value;
    if (next == _shown) {
      _pending = null;
      return;
    }
    _pending = next;
    // Begin fading the OLD line out (if it isn't already on its way out).
    if (_ac.status == AnimationStatus.completed || _ac.status == AnimationStatus.forward) {
      _ac.reverse();
    }
  }

  void _onStatus(AnimationStatus status) {
    // Old line fully gone → swap to the pending text and fade it in.
    if (status == AnimationStatus.dismissed && _pending != null) {
      setState(() {
        _shown = _pending!;
        _pending = null;
      });
      _ac.forward();
    }
  }

  @override
  void dispose() {
    widget.controller.instruction.removeListener(_onText);
    _ac.removeStatusListener(_onStatus);
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    final slide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: Text(
              _shown,
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: 2,
              style: GoogleFonts.bricolageGrotesque(
                // Shrink the long synthesis line so it stays on ≤2 lines.
                fontSize: _shown.length > 22 ? 23 : 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.1,
                color: Colors.white,
                shadows: [
                  Shadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 3)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _StepDots(controller: widget.controller),
      ],
    );
  }
}

/// Small progress dots — one per device, the current one highlighted.
class _StepDots extends StatelessWidget {
  const _StepDots({required this.controller});
  final CrankController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.done,
      builder: (context, done, _) => ValueListenableBuilder<int>(
        valueListenable: controller.stepIndex,
        builder: (context, step, __) {
          final current = done ? 4 : step; // all filled when done
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 4; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == current ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i <= current
                        ? const Color(0xFFFFD970).withValues(alpha: i == current ? 1 : 0.7)
                        : Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
