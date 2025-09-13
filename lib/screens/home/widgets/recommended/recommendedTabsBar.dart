import 'dart:math' as math;
import 'package:eureka_app/screens/home/models/recommendedTab.dart';
import 'package:eureka_app/screens/home/widgets/recommended/stickyTab.dart';
import 'package:flutter/material.dart';

class RecommendedTabsBar extends StatelessWidget {
  const RecommendedTabsBar({
    super.key,
    required this.tabs,
    required this.selectedId,
    required this.onSelect,
    this.tabHeight = 60,
    this.overlapPx = 12, // visual overlap between neighbors
    this.maxTiltDeg = 4.0, // +/- tilt for all tabs (incl. selected)
    this.maxJitterY = 3.0, // +/- vertical jitter
    this.horizontalPadding = 8, // MUST match StickyTab's horizontal padding
    this.labelStyle = const TextStyle(
        fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E4B7A)),
    this.selectedScale = 1.06, // visual only; layout uses unselected width
  });

  final List<RecommendedTab> tabs;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  final double tabHeight;
  final double overlapPx;
  final double maxTiltDeg;
  final double maxJitterY;
  final double horizontalPadding;
  final TextStyle labelStyle;
  final double selectedScale;

  // stable pseudo-random in [0,1) based on id
  double _hash01(String s) {
    var h = 0x811C9DC5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return (h / 0xFFFFFFFF);
  }

  double _tiltFor(String id) {
    final r = _hash01('tilt:$id') * 2 - 1; // [-1,1)
    return r * maxTiltDeg;
  }

  double _jitterFor(String id) {
    final r = _hash01('jit:$id') * 2 - 1; // [-1,1)
    return r * maxJitterY;
  }

  double _measureTabWidth(BuildContext context, String label) {
    final tp = TextPainter(
      text: TextSpan(text: label, style: labelStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    // width = text + left/right padding + a hair for border/tilt
    return tp.width + horizontalPadding * 2 + 6;
  }

  @override
  Widget build(BuildContext context) {
    // Measure each tab's width
    final widths = tabs.map((t) => _measureTabWidth(context, t.label)).toList();

    // Compute left offsets with overlap
    final lefts = <double>[];
    double acc = 0;
    for (int i = 0; i < widths.length; i++) {
      lefts.add(acc);
      acc += widths[i] - overlapPx;
    }
    final totalWidth = acc + overlapPx; // add back the last removed overlap
    final baseTop = maxJitterY; // headroom for negative jitter

    final selIndex = tabs.indexWhere((t) => t.id == selectedId);

    return SizedBox(
      width: totalWidth,
      height: tabHeight + maxJitterY * 2 + 8, // space for lift/shadow
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Unselected in original order (keeps natural order stable)
          for (int i = 0; i < tabs.length; i++)
            if (i != selIndex) _buildPos(tabs[i], lefts[i], false),

          // Selected painted last (on top), stays at its original position
          if (selIndex != -1) _buildPos(tabs[selIndex], lefts[selIndex], true),
        ],
      ),
    );
  }

  Widget _buildPos(RecommendedTab t, double left, bool selected) {
    final dy = _jitterFor(t.id);
    final tilt = _tiltFor(t.id) * math.pi / 180.0;

    return Positioned(
      left: left,
      top: maxJitterY + dy,
      child: Transform.rotate(
        angle: tilt, // selected stays tilted too
        child: StickyTab(
          tab: t,
          selected: selected,
          height: tabHeight,
          seed: Object.hash(t.id, 'scribble-v1'),
          // width is NOT set so it matches your auto-size Container
          onTap: () => onSelect(t.id),
        ),
      ),
    );
  }
}
