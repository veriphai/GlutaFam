import 'package:eureka_app/screens/home/models/discussion.dart';
import 'package:flutter/material.dart';

class FeaturedDiscussionCard extends StatelessWidget {
  const FeaturedDiscussionCard({
    super.key,
    required this.item,
    required this.onStart,
  });

  final Discussion item;
  final VoidCallback onStart;

  // palette tuned to OG
  static const _panelFill = Color.fromRGBO(255, 249, 221, 1); // light paper
  static const _panelLine = Color(0xFFCCBE9C); // beige stroke
  static const _inkBlue = Color(0xFF1E4B7A); // headings
  static const _muted = Color.fromRGBO(48, 52, 47, 1); // meta
  static const _hintFill = Color(0xFFDDF3E3); // mint hint bg
  static const _hintLine = Color(0xFF9FD0B6); // mint hint border

  static const _ruleLine = Color(0xFFCCBE9C);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: _panelFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _panelLine, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Start pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                    color: _muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Container(height: 1, color: _ruleLine.withOpacity(0.6)),

          const SizedBox(height: 6),

          // Path line
          Text(
            item.path,
            style: const TextStyle(
              fontSize: 18,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: _muted,
            ),
          ),

          const SizedBox(height: 6),

          // Green hint bubble
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "You might be studying this in school",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color.fromRGBO(51, 97, 53, 1),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StartPill(onTap: onStart),
            ],
          ),

          const SizedBox(height: 6),

          Container(height: 1, color: _ruleLine.withOpacity(0.6)),

          const SizedBox(height: 6),
          // Duration
          Row(
            children: [
              Icon(
                Icons.watch_later_outlined,
                size: 20,
                color: _muted,
              ),
              const SizedBox(width: 6),
              Text(
                "${item.durationMin} min",
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: _muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StartPill extends StatelessWidget {
  const _StartPill({required this.onTap});
  final VoidCallback onTap;
  static const _pillFill = Color.fromRGBO(253, 233, 137, 1); // gold
  static const _pillLine = Color.fromRGBO(228, 204, 109, 1); // gold border

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _pillFill,
      shape: StadiumBorder(side: BorderSide(color: _pillLine, width: 1.2)),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            "Start >",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: FeaturedDiscussionCard._muted),
          ),
        ),
      ),
    );
  }
}

class _TapePiece extends StatelessWidget {
  const _TapePiece({required this.angle});
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 46,
        height: 16,
        decoration: BoxDecoration(
          color: const Color(0xFFE6D4A6).withOpacity(0.9),
          borderRadius: BorderRadius.circular(3),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
      ),
    );
  }
}
