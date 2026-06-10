// Time scrubber — the reusable Curve Scrubber primitive (PRD §2.3): drag a cursor
// across a 24h track to set the time of day, which drives the sun, the sky, the
// ambient light, AND the source's output (solar follows the sun; wind follows the
// gusts). One control, coherent world response. (Reused later for Ep4's demand
// curve and Ep5's price curve — keep it generic: a track + a draggable cursor.)
//
// Auto-plays the day so consequences unfold on their own; grabbing the cursor
// pauses the clock while scrubbing, then it resumes.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../home/career/careerCommon.dart';
import '../state/source_personalities_controller.dart';

class TimeScrubber extends StatefulWidget {
  const TimeScrubber({super.key, required this.controller});
  final SourcePersonalitiesController controller;

  @override
  State<TimeScrubber> createState() => _TimeScrubberState();
}

class _TimeScrubberState extends State<TimeScrubber> {
  bool _dragging = false;

  void _setFromDx(double dx, double width) {
    widget.controller.scrubToFraction((dx / width).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Row(
      children: [
        // Clock readout — time period + clock + sun/moon (LEFT).
        AnimatedBuilder(
          animation: c,
          builder: (context, _) {
            final h = c.timeOfDay.floor();
            final m = ((c.timeOfDay - h) * 60).floor();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _period(c.timeOfDay),
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: const Color(0xFFE8C98A).withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(c.isDaylight ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                        size: 13, color: c.isDaylight ? const Color(0xFFFFC857) : const Color(0xFFB9C4E6)),
                    const SizedBox(width: 5),
                    SizedBox(
                      width: 42,
                      child: Text(
                        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(width: 10),
        // Track.
        Expanded(
          child: LayoutBuilder(
            builder: (context, cons) {
              final width = cons.maxWidth;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) {
                  c.setPlaying(false);
                  _setFromDx(d.localPosition.dx, width);
                },
                onTapUp: (_) => c.setPlaying(true),
                onHorizontalDragStart: (d) {
                  setState(() => _dragging = true);
                  c.setPlaying(false);
                  _setFromDx(d.localPosition.dx, width);
                },
                onHorizontalDragUpdate: (d) => _setFromDx(d.localPosition.dx, width),
                onHorizontalDragEnd: (_) {
                  setState(() => _dragging = false);
                  c.setPlaying(true);
                },
                child: SizedBox(
                  height: 40,
                  child: AnimatedBuilder(
                    animation: c,
                    builder: (context, _) => CustomPaint(
                      painter: _TrackPainter(
                        fraction: c.dayProgress,
                        sunAltitude: c.sunAltitude,
                        dragging: _dragging,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        // Play / pause (RIGHT).
        AnimatedBuilder(
          animation: c,
          builder: (context, _) => PressableScale(
            onTap: () => c.setPlaying(!c.playing),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Icon(
                c.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _period(double t) {
  if (t < 5.5) return 'NIGHT';
  if (t < 8) return 'DAWN';
  if (t < 11) return 'MORNING';
  if (t < 14.5) return 'MIDDAY';
  if (t < 17.5) return 'AFTERNOON';
  if (t < 19.5) return 'DUSK';
  return 'NIGHT';
}

class _TrackPainter extends CustomPainter {
  _TrackPainter({required this.fraction, required this.sunAltitude, required this.dragging});
  final double fraction;
  final double sunAltitude;
  final bool dragging;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final left = 4.0, right = size.width - 4;
    final span = right - left;
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(left, cy - 4, right, cy + 4),
      const Radius.circular(4),
    );
    // Base track: morning → noon → dusk → night (the run is dayStart→midnight).
    canvas.drawRRect(
      trackRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF35527F), // morning
            Color(0xFF3E78C8), // noon — bright day
            Color(0xFFC9743F), // dusk
            Color(0xFF101736), // midnight
          ],
          stops: [0.0, 0.29, 0.68, 1.0],
        ).createShader(Rect.fromLTRB(left, 0, right, size.height)),
    );

    // Tick marks at noon (0.29) and dusk (0.68) of the run.
    final tick = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 1.5;
    for (final frac in const [0.29, 0.68]) {
      final x = left + span * frac;
      canvas.drawLine(Offset(x, cy - 7), Offset(x, cy + 7), tick);
    }

    // Filled portion up to the cursor.
    final cx = left + span * fraction.clamp(0.0, 1.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(left, cy - 4, cx, cy + 4), const Radius.circular(4)),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );

    // Thumb — a sun/moon coloured knob.
    final knobColor = Color.lerp(const Color(0xFFB9C4E6), const Color(0xFFFFD46B), sunAltitude)!;
    final knobR = dragging ? 11.0 : 9.0;
    canvas.drawCircle(Offset(cx, cy), knobR + 3,
        Paint()..color = knobColor.withValues(alpha: 0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(Offset(cx, cy), knobR, Paint()..color = knobColor);
    canvas.drawCircle(Offset(cx, cy), knobR,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = Colors.white.withValues(alpha: 0.85));
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.fraction != fraction || old.sunAltitude != sunAltitude || old.dragging != dragging;
}
