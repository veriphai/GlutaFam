// Voltix — the companion mascot + message box. Mirrors the satellite-engineer
// activities' MascotHelper (Floaty avatar beside a rounded accent bubble), but
// driven by the bot engine's current BotUtterance (text + mood). The avatar
// swaps sprite by mood; the bubble swaps text with the sequential
// fade-out → swap → fade-in primitive (a cross-fade would show two lines at
// once). The same Voltix sprites are reused across every electricity episode.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../engine/bot_beat_engine.dart';
import '../state/crank_controller.dart';

class VoltixHelper extends StatelessWidget {
  const VoltixHelper({super.key, required this.controller, this.avatarHeight = 104});

  final CrankController controller;
  final double avatarHeight;

  /// VoltixMood → bundled sprite (shared across all episodes).
  static String spriteFor(VoltixMood mood) {
    switch (mood) {
      case VoltixMood.wave:
        return 'assets/images/voltix/voltix_wave.png';
      case VoltixMood.thinking:
        return 'assets/images/voltix/voltix_thinking.png';
      case VoltixMood.idea:
        return 'assets/images/voltix/voltix_idea.png';
      case VoltixMood.celebrating:
        return 'assets/images/voltix/voltix_celebrating.png';
      case VoltixMood.confused:
        return 'assets/images/voltix/voltix_confused.png';
      case VoltixMood.confident:
        return 'assets/images/voltix/voltix_confident.png';
      case VoltixMood.thumbsUp:
        return 'assets/images/voltix/voltix_thumbs_up.png';
      case VoltixMood.surprised:
        return 'assets/images/voltix/voltix_surprised.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BotUtterance?>(
      valueListenable: controller.botLine,
      builder: (context, line, _) {
        final mood = line?.mood ?? VoltixMood.wave;
        final sprite = spriteFor(mood);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Floaty(
              amplitude: 3,
              period: const Duration(milliseconds: 3000),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
                child: SizedBox(
                  key: ValueKey(sprite),
                  height: avatarHeight,
                  child: Image.asset(
                    sprite,
                    height: avatarHeight,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _bubble(line?.text ?? '')),
          ],
        );
      },
    );
  }

  Widget _bubble(String text) {
    return CustomPaint(
      painter: _VoltixBubblePainter(
        fill: const Color(0xFF0E1E3C).withValues(alpha: 0.95),
        border: CareerColors.gold.withValues(alpha: 0.7),
      ),
      // Left padding clears the tail; the tail width is _VoltixBubblePainter._tail.
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 11, 14, 11),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _FadeSwapText(
            text: text,
            style: CareerText.body.copyWith(
              color: Colors.white,
              fontSize: 12.5,
              height: 1.28,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Dark + gold speech bubble with a tail on the LEFT pointing at Voltix. Traced
/// as ONE continuous outline (the tail is folded into the left edge) so the
/// gold border strokes cleanly with no seam where the tail meets the body.
class _VoltixBubblePainter extends CustomPainter {
  _VoltixBubblePainter({required this.fill, required this.border});

  final Color fill;
  final Color border;

  static const double _tail = 12; // tail length (also the body's left inset)
  static const double _tailHalf = 9; // half-height of the tail mouth
  static const double _r = 16; // corner radius

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cy = h * 0.44; // point slightly above centre, toward Voltix's face
    final p = Path()
      ..moveTo(_tail + _r, 0)
      ..lineTo(w - _r, 0)
      ..arcToPoint(Offset(w, _r), radius: const Radius.circular(_r))
      ..lineTo(w, h - _r)
      ..arcToPoint(Offset(w - _r, h), radius: const Radius.circular(_r))
      ..lineTo(_tail + _r, h)
      ..arcToPoint(Offset(_tail, h - _r), radius: const Radius.circular(_r))
      ..lineTo(_tail, cy + _tailHalf)
      ..lineTo(0, cy) // tail tip → points at the mascot
      ..lineTo(_tail, cy - _tailHalf)
      ..lineTo(_tail, _r)
      ..arcToPoint(Offset(_tail + _r, 0), radius: const Radius.circular(_r))
      ..close();

    canvas.drawShadow(p, Colors.black.withValues(alpha: 0.5), 5, false);
    canvas.drawPath(p, Paint()..color = fill);
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = border,
    );
  }

  @override
  bool shouldRepaint(_VoltixBubblePainter old) => old.fill != fill || old.border != border;
}

/// Sequential fade-out → swap → fade-in (the playbook's voice-paced text
/// primitive — a cross-fade would show line N and N+1 together).
class _FadeSwapText extends StatefulWidget {
  const _FadeSwapText({required this.text, required this.style});
  final String text;
  final TextStyle style;

  @override
  State<_FadeSwapText> createState() => _FadeSwapTextState();
}

class _FadeSwapTextState extends State<_FadeSwapText> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 170), value: 1);
  late String _shown = widget.text;

  @override
  void didUpdateWidget(covariant _FadeSwapText old) {
    super.didUpdateWidget(old);
    if (widget.text != _shown && _c.status != AnimationStatus.reverse) {
      _c.reverse().then((_) {
        if (!mounted) return;
        setState(() => _shown = widget.text);
        _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: Text(_shown, style: widget.style, maxLines: 6, overflow: TextOverflow.ellipsis),
    );
  }
}
