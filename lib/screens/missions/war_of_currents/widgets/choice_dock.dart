// CHOICE DOCK — the DC / AC choice, as two PREMIUM instrument buttons (the simple,
// familiar tap; just refined). Each is a dark-navy glass card with a gold hairline,
// a recessed oscilloscope-style glyph display (the 2.7 flat-line / sine trace), a
// bold label + mono sub-label, and a gentle breathing glow while it's the live
// choice. NEUTRAL throughout — no red/green, no winner hint (a hard rule: nothing
// pre-spoils that DC fails). A run that's done dims its button + shows a small
// neutral dot (no ✓/✗).
//
// Below it shares the seat with the fact chip '140 YEARS LATER' (war/bridge/done) and
// the F1 glass panel it tap-reveals — the one inline fact (skippable, never gates).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../home/career/careerCommon.dart';
import '../config/woc_copy.dart';
import '../config/woc_tuning.dart';
import '../state/woc_controller.dart';

class ChoiceDock extends StatelessWidget {
  const ChoiceDock({super.key, required this.controller});
  final WocController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WocPhase>(
      valueListenable: controller.phase,
      builder: (context, phase, _) {
        final choosing =
            phase == WocPhase.choose || phase == WocPhase.interlude;
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 280),
          opacity: choosing ? 1 : 0,
          child: IgnorePointer(
            ignoring: !choosing,
            child: ValueListenableBuilder<bool>(
              valueListenable: controller.ranDc,
              builder: (context, ranDc, __) => ValueListenableBuilder<bool>(
                valueListenable: controller.ranAc,
                builder: (context, ranAc, ___) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CurrentButton(
                      label: WocCopy.dcGlyphLabel,
                      sub: WocCopy.dcSubLabel,
                      glyph: _GlyphKind.flat,
                      done: ranDc,
                      ready: !ranDc,
                      onTap: () => controller.chooseRun(WocRun.dc),
                    ),
                    const SizedBox(width: 14),
                    _CurrentButton(
                      label: WocCopy.acGlyphLabel,
                      sub: WocCopy.acSubLabel,
                      glyph: _GlyphKind.sine,
                      done: ranAc,
                      ready: !ranAc,
                      onTap: () => controller.chooseRun(WocRun.ac),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _GlyphKind { flat, sine }

/// One premium current button — tap to send that current. A breathing gold glow
/// invites the live choice; the done state dims + shows a neutral dot.
class _CurrentButton extends StatefulWidget {
  const _CurrentButton({
    required this.label,
    required this.sub,
    required this.glyph,
    required this.done,
    required this.ready,
    required this.onTap,
  });
  final String label;
  final String sub;
  final _GlyphKind glyph;
  final bool done;
  final bool ready; // the live (not-yet-run) choice — breathes a gentle glow
  final VoidCallback onTap;

  @override
  State<_CurrentButton> createState() => _CurrentButtonState();
}

class _CurrentButtonState extends State<_CurrentButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1700))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final breathe = widget.ready && !widget.done && !reduced;
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        final pulse =
            breathe ? (0.5 + 0.5 * math.sin(_glow.value * math.pi * 2)) : 0.0;
        return PressableScale(
          onTap: widget.done ? () {} : widget.onTap,
          child: Opacity(
            opacity: widget.done ? 0.45 : 1.0,
            child: Container(
              width: 152,
              decoration: BoxDecoration(
                // Glossy top → dark base so the face reads as a 3D button surface.
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF313E68),
                    Color(0xFF1A2447),
                    Color(0xFF090F24)
                  ],
                  stops: [0.0, 0.42, 1.0],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: WocTune.gold.withValues(alpha: 0.45 + 0.38 * pulse),
                  width: 1.3,
                ),
                boxShadow: [
                  // Raised: a soft drop shadow + a tight contact shadow so the button
                  // floats above the map (reads as pressable, not a static panel).
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.34),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                  if (pulse > 0)
                    BoxShadow(
                      color: WocTune.gold.withValues(alpha: 0.22 * pulse),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    // Glossy top sheen — the glass catch-light that sells "button".
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 17,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.18),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(13, 11, 14, 11),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // The recessed oscilloscope-style glyph display (the 2.7 trace).
                          Container(
                            width: 34,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF05091B)
                                  .withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 5),
                              child: CustomPaint(
                                painter: _GlyphPainter(
                                    widget.glyph, const Color(0xFFD6E2FF)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 11),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.label,
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 19,
                                  height: 1.0,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.done) ...[
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.5),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                  ],
                                  Text(
                                    widget.sub,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.4,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.kind, this.color);
  final _GlyphKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final path = Path();
    if (kind == _GlyphKind.flat) {
      // DC — a steady flat line (recalls 2.7's steady-current graph trace).
      path.moveTo(0, midY);
      path.lineTo(size.width, midY);
    } else {
      // AC — two cycles of a sine reversing about the mid line (2.7's AC graph).
      const steps = 28;
      for (var i = 0; i <= steps; i++) {
        final x = size.width * i / steps;
        final y =
            midY - (size.height * 0.42) * math.sin(i / steps * 2 * math.pi * 2);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
    }
    // A soft glow under the trace (the lit instrument display), then a crisp stroke.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2)
        ..color = color.withValues(alpha: 0.32),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.kind != kind || old.color != color;
}
