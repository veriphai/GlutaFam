// A chat speech bubble with a little tail pointing toward the speaker — drawn
// as a single unioned path (rounded body + triangle tail) so the outline is
// seamless. Left-tailed bubbles "come from" a left avatar, right-tailed from a
// right avatar. Used in the intro chat between the kid and Orbit.

import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.accent,
    required this.fromRight,
    this.maxWidth = 280,
  });

  final String text;
  final Color accent;
  final bool fromRight; // tail on the right (Orbit) vs left (kid)
  final double maxWidth;

  static const double _tail = 9;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(
        fill: const Color(0xFF101B3D).withValues(alpha: 0.92),
        border: accent.withValues(alpha: 0.7),
        fromRight: fromRight,
        tail: _tail,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 14 + (fromRight ? 0 : _tail),
          right: 14 + (fromRight ? _tail : 0),
          top: 11,
          bottom: 11,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              height: 1.28,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter({
    required this.fill,
    required this.border,
    required this.fromRight,
    required this.tail,
  });

  final Color fill;
  final Color border;
  final bool fromRight;
  final double tail;

  @override
  void paint(Canvas canvas, Size size) {
    const r = 16.0;
    final bodyLeft = fromRight ? 0.0 : tail;
    final bodyRight = fromRight ? size.width - tail : size.width;
    final body = Path()
      ..addRRect(RRect.fromLTRBR(bodyLeft, 0, bodyRight, size.height, const Radius.circular(r)));

    final ty = size.height * 0.5;
    final tri = Path();
    if (fromRight) {
      tri
        ..moveTo(bodyRight - 1, ty - 9)
        ..lineTo(size.width, ty)
        ..lineTo(bodyRight - 1, ty + 9)
        ..close();
    } else {
      tri
        ..moveTo(bodyLeft + 1, ty - 9)
        ..lineTo(0, ty)
        ..lineTo(bodyLeft + 1, ty + 9)
        ..close();
    }

    final shape = Path.combine(PathOperation.union, body, tri);
    canvas.drawPath(shape, Paint()..color = fill);
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = border,
    );
  }

  @override
  bool shouldRepaint(_BubblePainter old) =>
      old.fill != fill || old.border != border || old.fromRight != fromRight || old.tail != tail;
}
