// Ember — ui/controls/speech_bubble.dart
//
// The NON-BLOCKING walk-up SPEECH BUBBLE: a small, tasteful comic-style bubble
// that floats over an NPC when the avatar stops beside them and says their
// opening line ("Welcome, young one..."). It is the kid-friendly "walk up, they
// say something" beat — and crucially it NEVER blocks the game: it is just an
// overlay child the world_screen anchors over the NPC (like the proximity
// prompt), so it appears/disappears purely by being added/removed from the
// build. When the avatar walks out of range the world_screen drops it; when an
// activity launches the exploration overlays are gated out, so it can never
// persist over an activity or a later screen (the old modal bottom sheet did).
//
// The branching choices are still reachable: the proximity prompt's "Talk"
// pill (rendered alongside this bubble) opens the full ElderDialogue tree on a
// deliberate tap. This bubble is the gentle default; the tap is the opt-in.
//
// Pure presentation: it renders a rounded panel + a little down-tail + a soft
// fade/rise in. It owns no world state and dispatches nothing.

import 'package:flutter/material.dart';

import '../../art/ember_palette.dart';

/// A floating, non-blocking speech bubble showing [line] from [speakerName].
class SpeechBubble extends StatefulWidget {
  const SpeechBubble({
    super.key,
    required this.speakerName,
    required this.line,
    required this.palette,
    this.maxWidth = 240.0,
  });

  final String speakerName;
  final String line;
  final EmberPalette palette;

  /// Cap on the bubble width so a long line wraps tidily over the NPC.
  final double maxWidth;

  @override
  State<SpeechBubble> createState() => _SpeechBubbleState();
}

class _SpeechBubbleState extends State<SpeechBubble>
    with SingleTickerProviderStateMixin {
  // EAGER (initState), not a `late final` lazy initializer — same deactivation
  // hazard as the joystick/prompt tickers: a lazily-built AnimationController
  // could be constructed from dispose() (TickerMode ancestor lookup on a
  // deactivated element). Eager construction means dispose() only tears down.
  late final AnimationController _c;
  late final Animation<double> _in;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..forward();
    _in = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EmberPalette p = widget.palette;
    return FadeTransition(
      opacity: _c,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1.0).animate(_in),
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: widget.maxWidth),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: p.surfaceRaised,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.outline, width: 2),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.speakerName,
                      style: TextStyle(
                        color: p.ember,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.line,
                      style: TextStyle(
                        color: p.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // A little tail so the bubble reads as coming from the NPC below.
            CustomPaint(
              size: const Size(16, 9),
              painter: _BubbleTail(
                fill: p.surfaceRaised,
                stroke: p.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A downward triangle tail with the panel's fill + a matching outline.
class _BubbleTail extends CustomPainter {
  _BubbleTail({required this.fill, required this.stroke});
  final Color fill;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final Path tri = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(tri, Paint()..color = fill);
    // Stroke only the two slanted edges (the top edge sits flush under the
    // panel's own border, so leave it open).
    final Paint edge = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, Offset(size.width / 2, size.height), edge);
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width / 2, size.height),
      edge,
    );
  }

  @override
  bool shouldRepaint(_BubbleTail old) => old.fill != fill || old.stroke != stroke;
}
