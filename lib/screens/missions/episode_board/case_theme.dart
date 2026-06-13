// The photo-detective "case board" visual language — the warm palette + the desk
// surface shared by the capture moment, the corner node, the peek drawer, and the
// closing flow. Warm cream photo paper on a deep desk, gold "case" accent, twine
// + tape. Keeps the whole CER feeling like ONE intentional artifact.

import 'package:flutter/material.dart';

class CaseTheme {
  CaseTheme._();

  // Photo paper.
  static const Color paper = Color(0xFFF4EFE3); // warm off-white polaroid
  static const Color paperEdge = Color(0xFFE6DFCF); // subtle paper edge/shadow line
  static const Color ink = Color(0xFF2A2722); // handwriting / label
  static const Color inkSoft = Color(0xFF6B6458);

  // The desk / board.
  static const Color deskTop = Color(0xFF221C16); // warm charcoal
  static const Color deskBottom = Color(0xFF12100C);
  static const Color felt = Color(0xFF1A2A22); // optional green-felt variant

  // Case accent + fixings.
  static const Color gold = Color(0xFFF5C451);
  static const Color goldBright = Color(0xFFFFD970);
  static const Color tape = Color(0x33FFFFFF); // translucent tape
  static const Color twine = Color(0xFFB9893E); // string between clues
  static const Color pin = Color(0xFFE0533B); // red pushpin
}

/// The desk surface behind the case board (drawer + closing). A deep warm gradient
/// with a soft top spotlight + a faint vignette — premium, not busy.
class CaseBoardBackground extends StatelessWidget {
  const CaseBoardBackground({super.key, this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [CaseTheme.deskTop, CaseTheme.deskBottom],
        ),
      ),
      child: CustomPaint(
        painter: _DeskPainter(),
        child: child,
      ),
    );
  }
}

class _DeskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Soft warm spotlight from the top.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.7),
          radius: 1.1,
          colors: [CaseTheme.gold.withValues(alpha: 0.06), Colors.transparent],
        ).createShader(Offset.zero & size),
    );
    // Vignette.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
          stops: const [0.6, 1.0],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_DeskPainter old) => false;
}
