import 'package:flutter/material.dart';

class RightEdgeBookmark extends StatelessWidget {
  const RightEdgeBookmark({
    super.key,
    required this.icon,
    required this.cardFill, // color of the continue-learning card
    this.selected = false,
    this.fill = const Color(0xFFD6E6F7), // e.g., physics (blue)
    this.border = const Color(0xFF7FA8CF),
    this.size = const Size(30, 56), // tall semi-circle
  });

  final IconData icon;
  final bool selected;
  final Color fill;
  final Color border;
  final Color cardFill;
  final Size size;

  @override
  Widget build(BuildContext context) {
    // We draw the bookmark slightly overlapping the card edge.
    // When selected, we "merge" by covering the card border under the overlap.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (selected)
          // Mask to hide the card’s right border under the bookmark so it "merges".
          Positioned(
            left: -3,
            top: 0,
            bottom: 0,
            child: Container(width: 6, color: cardFill),
          ),
        Container(
          width: size.width,
          height: size.height,
          margin: const EdgeInsets.only(left: 2), // overlap card by 2px
          decoration: BoxDecoration(
            color: selected ? cardFill : fill,
            borderRadius: BorderRadius.circular(size.width), // pill
            border: selected ? null : Border.all(color: border, width: 1),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF1E4B7A)),
        ),
      ],
    );
  }
}
