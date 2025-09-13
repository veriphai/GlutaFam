import 'package:eureka_app/screens/home/widgets/continueLearning/rightEdgeBookmark.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/lesson.dart';

class BookmarkSpec {
  final IconData icon;
  final bool selected;
  final Color fill;
  final Color border;
  const BookmarkSpec({
    required this.icon,
    this.selected = false,
    this.fill = const Color(0xFFF1E2B5),
    this.border = const Color(0xFFB7A987),
  });
}

class LessonItemLarge extends StatelessWidget {
  const LessonItemLarge({
    super.key,
    required this.lesson,
    this.onTap,
    this.showDivider = true,
    this.bookmark,
    required this.cardFill, // pass the card color to blend when selected
  });

  final Lesson lesson;
  final VoidCallback? onTap;
  final bool showDivider;
  final BookmarkSpec? bookmark;
  final Color cardFill;

  static const _inkBlue = Color(0xFF1E4B7A);
  static const _muted = Color.fromRGBO(48, 52, 47, 1);
  static const _ruleLine = Color(0xFFCCBE9C);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main tappable content
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                16, 12, 16 /* extra room for bookmark */, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        lesson.title,
                        style: GoogleFonts.kalam(
                          fontSize: 26,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                          color: _muted,
                        ),
                      ),
                    ),
                    // const SizedBox(width: 8),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    // mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                          child: Text(
                        lesson.path,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          // height: 1.25,
                          color: _muted,
                          fontWeight: FontWeight.w500,
                        ),
                      )),
                      Text(
                        "${lesson.durationMin} min",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: _muted,
                        ),
                      ),
                    ]),
                const SizedBox(height: 6),
                SizedBox(
                  height: 8,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                          height: 2,
                          margin: const EdgeInsets.only(right: 0),
                          color: _ruleLine.withOpacity(0.6)),
                      FractionallySizedBox(
                        widthFactor: lesson.progress.clamp(0.0, 1.0),
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3D79B3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (showDivider) ...[
                  const SizedBox(height: 12),
                  Container(height: 1, color: _ruleLine.withOpacity(0.6)),
                ],
              ],
            ),
          ),
        ),

        // Right-edge bookmark (half outside the card)
        if (bookmark != null)
          Align(
            alignment: Alignment.centerRight,
            child: Transform.translate(
              offset: const Offset(
                  16, 0), // push out so it looks like a semi-circle
              child: RightEdgeBookmark(
                icon: bookmark!.icon,
                selected: bookmark!.selected,
                fill: bookmark!.fill,
                border: bookmark!.border,
                cardFill: cardFill,
              ),
            ),
          ),
      ],
    );
  }
}
