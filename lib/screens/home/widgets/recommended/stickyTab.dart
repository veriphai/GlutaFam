import 'package:eureka_app/screens/home/models/recommendedTab.dart';
import 'package:eureka_app/screens/home/widgets/common/scribbleborderPainter.dart';
import 'package:flutter/material.dart';

class StickyTab extends StatelessWidget {
  const StickyTab({
    super.key,
    required this.tab,
    required this.selected,
    this.onTap,
    this.height = 42,
    this.width, // NEW: fixed width for layout in Stack
    this.borderRadius = 4,
    this.mergeWithCardEdge =
        false, // set true to hide inner (left) edge if needed
    this.seed,
  });

  final RecommendedTab tab;
  final bool selected;
  final VoidCallback? onTap;
  final double height;
  final double? width; // NEW
  final double borderRadius;
  final bool mergeWithCardEdge;
  final int? seed;

  @override
  Widget build(BuildContext context) {
    final scale = selected ? 1.06 : 1.0;
    final liftY = selected ? -2.0 : 0.0;
    final shadow = selected
        ? const BoxShadow(
            color: Colors.black26, blurRadius: 10, offset: Offset(0, 3))
        : const BoxShadow(
            color: Colors.black12, blurRadius: 6, offset: Offset(0, 2));

    // optional: expose via constructor if you like
    final bool mergeWithCardEdge = false; // hide left edge to "merge" with tray
    final int seed =
        tab.label.hashCode ^ (selected ? 7 : 0); // stable wobble per tab

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    );

    return Transform.translate(
      offset: Offset(0, liftY),
      child: Transform.scale(
        scale: scale,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: shape, // ripple clips to rounded rect
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // FILL + SHADOW (no solid border here)
                Ink(
                  height: height,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: ShapeDecoration(
                    color: tab.fill,
                    shape: shape,
                    shadows: [shadow],
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      tab.label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color.fromRGBO(48, 52, 47, 1),
                      ),
                    ),
                  ),
                ),

                // SCRIBBLY BORDER OVERLAY
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: ScribbleBorderPainter(
                        color: tab.border,
                        radius: borderRadius,
                        strokeWidth:
                            selected ? 1.6 : 1.2, // thicker when selected
                        step: 10, // segment length (larger = fewer kinks)
                        jitter: 0.5, // wobble amount
                        seed: seed, // stable per tab
                        drawTop: true,
                        drawRight: true,
                        drawBottom: true,
                        drawLeft:
                            !mergeWithCardEdge, // hide inner edge if merging with card
                        doubleStroke: true, // pencil-y double pass
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
