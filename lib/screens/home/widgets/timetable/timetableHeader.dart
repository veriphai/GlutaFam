import 'package:eureka_app/screens/home/widgets/common/scribbleborderPainter.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Paper tray + "Timetable" header block:
/// - Optional masking tape on top
/// - Title
/// - "This week" label + "Today Wed" pill
/// - Beige rule under the header
///
/// Next steps (we’ll add later): weekday strip, periods, footer.
class TimetableHeaderCard extends StatelessWidget {
  const TimetableHeaderCard({
    super.key,
    this.today,
    this.showTape = true,
    this.padding = const EdgeInsets.fromLTRB(6, 28, 6, 10),
    this.belowHeader,
    this.body,
  });

  final DateTime? today;
  final bool showTape;
  final EdgeInsets padding;
  final Widget? belowHeader;
  final Widget? body;

  // palette (kept aligned with the rest of the app)
  static const _trayFill = Color.fromRGBO(255, 249, 221, 1); // cream
  static const _trayLine = Color(0xFFCCBE9C); // beige stroke
  static const _inkBlue = Color(0xFF1E4B7A); // headings
  static const _blueText = Color(0xFF1F63C3); // "This week"
  static const _pillFill = Color(0xFFE9F6C9); // light green pill bg
  static const _pillLine = Color(0xFF86B76B); // pill border
  static const _muted = Color.fromRGBO(48, 52, 47, 1);

  String _weekday3(DateTime d) {
    const w = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    // DateTime.weekday: Mon=1..Sun=7
    return w[(d.weekday - 1) % 7];
  }

  @override
  Widget build(BuildContext context) {
    final d = today ?? DateTime.now();
    final todayLabel = "Today ${_weekday3(d)}";

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Paper tray
        Container(
          decoration: BoxDecoration(
            color: _trayFill,
            // border: Border.all(color: _trayLine, width: 1),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title
                const Text(
                  "Timetable",
                  style: TextStyle(
                    fontSize: 30,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 6),

                // "This week" + Today pill
                if (belowHeader != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "This week",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _muted,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _TodayChip(text: todayLabel),
                    ],
                  ),
                if (belowHeader != null) const SizedBox(height: 10),

                // Beige rule under header
                if (belowHeader != null)
                  Container(height: 1, color: _trayLine.withOpacity(0.9)),

// Week strip goes here (if provided), then another rule below it
                if (belowHeader != null) ...[
                  const SizedBox(height: 6),
                  belowHeader!,
                  // const SizedBox(height: 6),
                  Container(height: 1, color: _trayLine.withOpacity(0.9)),
                ],

                if (body != null) ...[
                  // const SizedBox(height: 8),
                  body!,
                ],
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _NotebookBorderPainter(
                color: _trayLine,
                radius: 18,
                strokeWidth: 2.0,
                dash: 32.0,
                gap: 8.0,
                doTop: true,
                doLeft: true,
                doRight: true,
                doBottomSolid: true,
                doCornerArcs: true,
              ),
            ),
          ),
        ),
        if (showTape)
          const Positioned(
            top: -10,
            left: 0,
            right: 0,
            child: Center(child: _TapePiece(width: 120, height: 24)),
          ),
      ],
    );
  }
}

class _TodayChip extends StatelessWidget {
  const _TodayChip({required this.text});
  final String text;

  static const _pillFill = Color.fromRGBO(255, 240, 102, 1);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      color: _pillFill,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          height: 1.0,
          fontWeight: FontWeight.w500,
          color: TimetableHeaderCard._muted,
        ),
      ),
    );
  }
}

class _TapePiece extends StatelessWidget {
  const _TapePiece({
    this.width = 72,
    this.height = 16,
    this.seed,
    this.borderWidth = 2.0,
  });

  final double width;
  final double height;
  final int? seed;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    const tapeFill = Color.fromRGBO(247, 232, 182, 1);

    return Transform.rotate(
      angle: -0.05, // tiny skew like real tape
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            // Tape body + SOLID top/bottom borders
            Container(
              decoration: BoxDecoration(
                color: tapeFill.withOpacity(0.30),
                borderRadius: BorderRadius.zero,
                border: Border(
                  top: BorderSide(
                      color: TimetableHeaderCard._trayLine, width: borderWidth),
                  bottom: BorderSide(
                      color: TimetableHeaderCard._trayLine, width: borderWidth),
                ),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2)),
                ],
              ),
            ),

            // JITTERED left/right borders painted on top
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: ScribbleBorderPainter(
                    color: TimetableHeaderCard._trayLine,
                    radius: 2, // small so edges aren't harsh
                    strokeWidth: borderWidth, // match solid edges thickness
                    step: 6, // segment length
                    jitter: 1.2, // wobble amount
                    seed: seed ??
                        Object.hash(width.round(), height.round(), 'tape-v2'),
                    drawTop: false,
                    drawBottom: false,
                    drawLeft: true,
                    drawRight: true,
                    doubleStroke: true, // pencil-y feel
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dashed top/left/right, solid rounded corner arcs, solid bottom.
class _NotebookBorderPainter extends CustomPainter {
  const _NotebookBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dash,
    required this.gap,
    this.doTop = true,
    this.doLeft = true,
    this.doRight = true,
    this.doBottomSolid = true,
    this.doCornerArcs = true,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;

  // renamed flags (avoid any collisions)
  final bool doTop;
  final bool doLeft;
  final bool doRight;
  final bool doBottomSolid;
  final bool doCornerArcs;

  @override
  void paint(Canvas canvas, Size size) {
    final half = strokeWidth / 2;
    final p = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // dashed line helper from A -> B
    void dashed(Offset a, Offset b) {
      final dx = b.dx - a.dx, dy = b.dy - a.dy;
      final len = math.sqrt(dx * dx + dy * dy);
      if (len <= 0) return;
      final ux = dx / len, uy = dy / len;
      double d = 0;
      while (d < len) {
        final seg = math.min(dash, len - d);
        final p1 = Offset(a.dx + ux * d, a.dy + uy * d);
        final p2 = Offset(a.dx + ux * (d + seg), a.dy + uy * (d + seg));
        canvas.drawLine(p1, p2, p);
        d += dash + gap;
      }
    }

    final leftX = half;
    final rightX = size.width - half;
    final topY = half;
    final bottomY = size.height - half;

    // solid corner arcs (quarter-circles)
    if (doCornerArcs) {
      final tl = Rect.fromLTWH(leftX, topY, radius * 2, radius * 2);
      final tr =
          Rect.fromLTWH(rightX - radius * 2, topY, radius * 2, radius * 2);
      final br = Rect.fromLTWH(
          rightX - radius * 2, bottomY - radius * 2, radius * 2, radius * 2);
      final bl =
          Rect.fromLTWH(leftX, bottomY - radius * 2, radius * 2, radius * 2);

      // TL: 180°→270°, TR: 270°→360°, BR: 0°→90°, BL: 90°→180°
      canvas.drawArc(tl, math.pi, math.pi / 2, false, p);
      canvas.drawArc(tr, 3 * math.pi / 2, math.pi / 2, false, p);
      canvas.drawArc(br, 0, math.pi / 2, false, p);
      canvas.drawArc(bl, math.pi / 2, math.pi / 2, false, p);
    }

    // dashed sides (skip the rounded corners by radius)
    if (doTop) {
      dashed(Offset(radius, topY), Offset(size.width - radius, topY));
    }
    if (doLeft) {
      dashed(Offset(leftX, radius), Offset(leftX, size.height - radius));
    }
    if (doRight) {
      dashed(Offset(rightX, radius), Offset(rightX, size.height - radius));
    }

    // solid bottom
    if (doBottomSolid) {
      canvas.drawLine(
        Offset(radius, bottomY),
        Offset(size.width - radius, bottomY),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NotebookBorderPainter old) {
    return old.color != color ||
        old.radius != radius ||
        old.strokeWidth != strokeWidth ||
        old.dash != dash ||
        old.gap != gap ||
        old.doTop != doTop ||
        old.doLeft != doLeft ||
        old.doRight != doRight ||
        old.doBottomSolid != doBottomSolid ||
        old.doCornerArcs != doCornerArcs;
  }
}
