import 'package:flutter/material.dart';

/// NotebookScaffold
/// - Paper cream background
/// - Ruled blue horizontal lines (customizable spacing)
/// - Red left margin line (customizable x-offset)
/// - Optional subtle grain overlay (pass an ImageProvider)
/// - Wrap YOUR content (e.g., CustomScrollView) inside [child]
class NotebookScaffold extends StatelessWidget {
  const NotebookScaffold({
    super.key,
    required this.child,
    this.paperColor = const Color.fromRGBO(255, 249, 221, 1), // Paper Cream
    this.ruleColor = const Color.fromRGBO(127, 198, 237, 1), // Ruled Blue
    this.marginColor = const Color.fromRGBO(251, 183, 159, 1), // Margin Red
    this.lineSpacing = 36.0, // distance between ruled lines
    this.marginX = 24.0, // red margin distance from left
    this.ruleStroke = 1.0,
    this.marginStroke = 1.2,
    this.grainImage, // e.g., AssetImage('assets/noise.png')
    this.grainOpacity = 0.06,
  });

  final Widget child;

  // Visual tuning
  final Color paperColor;
  final Color ruleColor;
  final Color marginColor;
  final double lineSpacing;
  final double marginX;
  final double ruleStroke;
  final double marginStroke;

  // Optional grain overlay
  final ImageProvider? grainImage;
  final double grainOpacity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paperColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ruled lines + red margin
          RepaintBoundary(
            child: CustomPaint(
              painter: _RuledPaperPainter(
                ruleColor: ruleColor,
                marginColor: marginColor,
                lineSpacing: lineSpacing,
                marginX: marginX,
                ruleStroke: ruleStroke,
                marginStroke: marginStroke,
              ),
            ),
          ),

          // Optional subtle grain / paper texture
          if (grainImage != null)
            IgnorePointer(
              child: Opacity(
                opacity: grainOpacity.clamp(0, 1),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: grainImage!,
                      fit: BoxFit.cover,
                      repeat: ImageRepeat.repeat,
                    ),
                  ),
                ),
              ),
            ),

          // Your content
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class _RuledPaperPainter extends CustomPainter {
  _RuledPaperPainter({
    required this.ruleColor,
    required this.marginColor,
    required this.lineSpacing,
    required this.marginX,
    required this.ruleStroke,
    required this.marginStroke,
  });

  final Color ruleColor;
  final Color marginColor;
  final double lineSpacing;
  final double marginX;
  final double ruleStroke;
  final double marginStroke;

  @override
  void paint(Canvas canvas, Size size) {
    final paintRule = Paint()
      ..color = ruleColor.withOpacity(0.65)
      ..strokeWidth = ruleStroke;

    // final paintMargin = Paint()
    //   ..color = marginColor.withOpacity(0.85)
    //   ..strokeWidth = marginStroke;

    // Horizontal ruled lines (start below status bar area naturally)
    // Add small offset so the first line isn't glued to the top edge.
    const double topOffset = 100.0;
    for (double y = topOffset; y < size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintRule);
    }

    // Vertical red margin line
    // canvas.drawLine(
    //     Offset(marginX, 0), Offset(marginX, size.height), paintMargin);
  }

  @override
  bool shouldRepaint(covariant _RuledPaperPainter old) {
    return ruleColor != old.ruleColor ||
        marginColor != old.marginColor ||
        lineSpacing != old.lineSpacing ||
        marginX != old.marginX ||
        ruleStroke != old.ruleStroke ||
        marginStroke != old.marginStroke;
  }
}
