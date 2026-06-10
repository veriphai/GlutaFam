// Helix + his tailed speech bubble — docked low, just above the controls (PRD
// §10), so the reaction and the thing it reacts to are both in view. The bubble
// shows the current line from the controller and the avatar wears the line's
// mood. The reaction and the visual it reacts to fire together (the controller
// emits the line at the physical moment).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/creature_tuning.dart';
import '../engine/helix_beat_engine.dart';
import '../state/recipe_creature_controller.dart';
import 'helix_avatar.dart';

class HelixHelper extends StatelessWidget {
  const HelixHelper({super.key, required this.controller});
  final RecipeCreatureController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HelixUtterance?>(
      valueListenable: controller.botLine,
      builder: (context, line, _) {
        final mood = line?.mood ?? Mood.curious;
        final accent = _moodAccent(mood);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            HelixAvatar(mood: mood, size: 68),
            const SizedBox(width: 6),
            Expanded(
              child: CustomPaint(
                painter: _TailBubblePainter(
                  fill: const Color(0xFF0E1A30).withValues(alpha: 0.95),
                  border: accent.withValues(alpha: 0.6),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 11, 14, 11),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    layoutBuilder: (cur, prev) => Stack(
                      alignment: Alignment.centerLeft,
                      children: [...prev, if (cur != null) cur],
                    ),
                    child: Text(
                      line?.text ?? '',
                      key: ValueKey(line?.token ?? 0),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _moodAccent(Mood m) {
    switch (m) {
      case Mood.surprised:
      case Mood.idea:
        return RC.lifeAmber;
      case Mood.celebrating:
      case Mood.curious:
        return RC.lifeGreen;
      case Mood.confused:
        return const Color(0xFF9AA6C8);
    }
  }
}

/// Dark bubble with a left tail pointing at Helix — one continuous outline so
/// the border has no seam (mirrors the collectible earn bubble's language).
class _TailBubblePainter extends CustomPainter {
  _TailBubblePainter({required this.fill, required this.border});
  final Color fill;
  final Color border;

  static const double _tail = 12;
  static const double _tailHalf = 9;
  static const double _r = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cy = h * 0.5;
    final p = Path()
      ..moveTo(_tail + _r, 0)
      ..lineTo(w - _r, 0)
      ..arcToPoint(Offset(w, _r), radius: const Radius.circular(_r))
      ..lineTo(w, h - _r)
      ..arcToPoint(Offset(w - _r, h), radius: const Radius.circular(_r))
      ..lineTo(_tail + _r, h)
      ..arcToPoint(Offset(_tail, h - _r), radius: const Radius.circular(_r))
      ..lineTo(_tail, cy + _tailHalf)
      ..lineTo(0, cy)
      ..lineTo(_tail, cy - _tailHalf)
      ..lineTo(_tail, _r)
      ..arcToPoint(Offset(_tail + _r, 0), radius: const Radius.circular(_r))
      ..close();
    canvas.drawShadow(p, Colors.black.withValues(alpha: 0.5), 5, false);
    // Mood-tinted glow.
    canvas.drawPath(
      p,
      Paint()
        ..color = border.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    // Gradient fill for depth.
    canvas.drawPath(
      p,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fill, const Color(0xFF0A1424).withValues(alpha: 0.96)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = border,
    );
  }

  @override
  bool shouldRepaint(_TailBubblePainter old) => old.fill != fill || old.border != border;
}
