import 'package:flutter/material.dart';

class SubjectTabSpec {
  final String id;
  final IconData icon;
  final Color fill; // unselected fill (e.g., blue/beige)
  final Color border; // unselected border
  const SubjectTabSpec({
    required this.id,
    required this.icon,
    required this.fill,
    required this.border,
  });
}

class RightEdgeSubjectTabs extends StatelessWidget {
  const RightEdgeSubjectTabs({
    super.key,
    required this.tabs,
    required this.cardFill,
    this.selectedId,
    this.onSelect,
    this.spacing = 5,
    this.size = const Size(64, 64),
    this.outset = 16, // how far outside the card the semi-circle sits
  });

  final List<SubjectTabSpec> tabs;
  final String? selectedId;
  final Color cardFill;
  final ValueChanged<String>? onSelect;
  final double spacing;
  final Size size;
  final double outset;

  @override
  Widget build(BuildContext context) {
    // Column centered vertically, pushed slightly outside the right edge
    return Align(
      alignment: Alignment.topRight,
      child: Transform.translate(
        offset: Offset(outset, 0),
        child: Padding(
            padding: EdgeInsets.only(top: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final t in tabs) ...[
                  _SubjectBookmarkButton(
                    spec: t,
                    selected: t.id == selectedId,
                    cardFill: cardFill,
                    size: size,
                    onTap: onSelect == null ? null : () => onSelect!(t.id),
                  ),
                  SizedBox(height: spacing),
                ],
              ],
            )),
      ),
    );
  }
}

class _SubjectBookmarkButton extends StatelessWidget {
  const _SubjectBookmarkButton({
    required this.spec,
    required this.selected,
    required this.cardFill,
    required this.size,
    this.onTap,
  });

  final SubjectTabSpec spec;
  final bool selected;
  final Color cardFill;
  final Size size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // When selected we cover the card's border so it "merges."
    // When NOT selected we do NOT cover it, so the card border stays visible.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (selected)
          Positioned(
            left: -4,
            top: 0,
            bottom: 0,
            child: Container(width: 8, color: cardFill),
          ),

        // Shadow under the pill (kept separate from the custom paint)
        Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size.width),
            // boxShadow: const [
            //   BoxShadow(
            //       color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
            // ],
          ),
        ),

        // The pill itself: fill + OUTER stroke only (inner stroke hidden)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(size.width),
            child: CustomPaint(
              size: size,
              painter: _BookmarkPainter(
                // fill: selected ? cardFill : spec.fill,
                fill: cardFill,
                stroke: spec.border, // visible only on the outer half
                radius: size.width, // big radius → more oval
                strokeWidth: 1.5,
              ),
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                      padding: EdgeInsets.only(right: 2),
                      child: Icon(
                        spec.icon,
                        size: 18,
                        color: const Color(0xFF1E4B7A),
                      )),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BookmarkPainter extends CustomPainter {
  _BookmarkPainter({
    required this.fill,
    required this.stroke,
    required this.radius,
    this.strokeWidth = 1.0,
  });

  final Color fill;
  final Color stroke;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    // Fill the capsule
    final pFill = Paint()
      ..color = fill
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, pFill);

    // Draw stroke ONLY on the OUTER (right) half
    final pStroke = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.save();
    // Clip to right half (with padding so the curved ends render cleanly)
    canvas.clipRect(
        Rect.fromLTWH(size.width * 0.5, -4, size.width, size.height + 8));
    canvas.drawRRect(rrect, pStroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BookmarkPainter old) {
    return old.fill != fill ||
        old.stroke != stroke ||
        old.radius != radius ||
        old.strokeWidth != strokeWidth;
  }
}
