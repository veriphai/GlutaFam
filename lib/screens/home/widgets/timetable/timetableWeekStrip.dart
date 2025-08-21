import 'package:flutter/material.dart';

class TimetableWeekStrip extends StatelessWidget {
  const TimetableWeekStrip({
    super.key,
    this.todayIndex, // 1=Mon ... 7=Sun
    this.height = 20,
    this.timeRailWidth = 46, // width of the time rail (Mon column spans this)
    this.edgeStrokes = true, // slightly thicker strokes on outer edges
  });

  final int? todayIndex;
  final double height;
  final double timeRailWidth;
  final bool edgeStrokes;

  static const _inkBlue = Color(0xFF1E4B7A);
  static const _trayLine = Color(0xFFCCBE9C);

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final ti = (todayIndex ?? DateTime.now().weekday); // Mon=1..Sun=7

    return SizedBox(
      height: height,
      child: Row(
        children: [
          // MONDAY — fixed width equals time rail
          _FixedCell(
            width: timeRailWidth,
            label: _labels[0],
            isToday: ti == 1,
            drawLeft: false,
            drawRight:
                true, // boundary at Mon|Tue -> aligns with vertical divider
          ),

          // TUE..SUN — 6 expanded cells
          for (int d = 2; d <= 7; d++)
            Expanded(
              child: _ExpandedCell(
                label: _labels[d - 1],
                isToday: ti == d,
                drawRight: d <
                    7, // draw right stroke on all, thicker at far right if edgeStrokes
                isFarRight: d == 7,
              ),
            ),
        ],
      ),
    );
  }
}

class _FixedCell extends StatelessWidget {
  const _FixedCell({
    required this.width,
    required this.label,
    required this.isToday,
    this.drawLeft = false,
    this.drawRight = true,
  });

  final double width;
  final String label;
  final bool isToday;
  final bool drawLeft;
  final bool drawRight;

  static const _inkBlue = Color(0xFF1E4B7A);
  static const _trayLine = Color(0xFFCCBE9C);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border(
          left: drawLeft
              ? const BorderSide(color: _trayLine, width: 1.2)
              : BorderSide.none,
          right: drawRight
              ? const BorderSide(color: _trayLine, width: 1.0)
              : BorderSide.none,
        ),
      ),
      alignment: Alignment.center,
      child: _DayLabel(label: label, isToday: false),
    );
  }
}

class _ExpandedCell extends StatelessWidget {
  const _ExpandedCell({
    required this.label,
    required this.isToday,
    this.drawRight = true,
    this.isFarRight = false,
  });

  final String label;
  final bool isToday;
  final bool drawRight;
  final bool isFarRight;

  static const _inkBlue = Color(0xFF1E4B7A);
  static const _trayLine = Color(0xFFCCBE9C);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: drawRight
              ? BorderSide(color: _trayLine, width: isFarRight ? 1.2 : 1.0)
              : BorderSide.none,
        ),
      ),
      alignment: Alignment.center,
      child: _DayLabel(label: label, isToday: false),
    );
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel({required this.label, required this.isToday});
  final String label;
  final bool isToday;
  static const _todayBg = Color(0xFFEFF9D5);
  static const _todayBr = Color(0xFF86B76B);
  static const _inkBlue = Color(0xFF1E4B7A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: isToday
          ? BoxDecoration(
              color: _todayBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _todayBr, width: 1),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
              ],
            )
          : null,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: isToday ? FontWeight.w900 : FontWeight.w800,
          color: _inkBlue,
          height: 1.0,
        ),
      ),
    );
  }
}
