import 'package:eureka_app/screens/home/models/discussion.dart';
import 'package:flutter/material.dart';

class DiscussionRowCard extends StatelessWidget {
  const DiscussionRowCard({
    super.key,
    required this.item,
    required this.onTapExpand,
    required this.onStart,
  });

  final Discussion item;
  final VoidCallback onTapExpand;
  final VoidCallback onStart;

  // palette tuned to OG
  static const _rowFill = Color(0xFFFFF7E3);
  static const _rowLine = Color(0xFFCCBE9C);
  static const _inkBlue = Color(0xFF1E4B7A);
  static const _muted = Color.fromRGBO(48, 52, 47, 1);

  @override
  Widget build(BuildContext context) {
    final badge = item.badges.isNotEmpty ? item.badges.first : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTapExpand,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
          decoration: BoxDecoration(
            color: _rowFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _rowLine, width: 1),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left icon sticker (placeholder)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3EEF7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _rowLine, width: 1),
                ),
                child: const Icon(Icons.science_outlined,
                    size: 18, color: _inkBlue),
              ),
              const SizedBox(width: 6),

              // Title + subtitle (left block)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top line (path/title compact)
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Right block: badge top, then time + Start aligned right
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (badge != null) _BadgeChip(label: badge),
                      if (badge != null) const SizedBox(height: 6),
                      Text(
                        "${item.durationMin} min",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _muted,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  SizedBox(
                    width: 6,
                  ),
                  _StartMini(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.label});
  final String label;

  static const _pillFill = Color.fromRGBO(253, 233, 137, 1); // gold
  static const _pillLine = Color.fromRGBO(228, 204, 109, 1);

  @override
  Widget build(BuildContext context) {
    final bg = switch (label) {
      "IN CLASS" => _pillFill,
      "TEST TUE" => _pillFill,
      "GAP HIGH" => _pillFill,
      _ => const Color(0xFFEDE7D3),
    };
    final br = switch (label) {
      "IN CLASS" => _pillLine,
      "TEST TUE" => _pillLine,
      "GAP HIGH" => _pillLine,
      _ => const Color(0xFFB7A987),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: br, width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: DiscussionRowCard._muted,
        ),
      ),
    );
  }
}

class _StartMini extends StatelessWidget {
  const _StartMini();

  static const _pillFill = Color.fromRGBO(253, 233, 137, 1); // gold
  static const _pillLine = Color.fromRGBO(228, 204, 109, 1); // gold border
  @override
  Widget build(BuildContext context) {
    const r = 12.0; // <-- your corner radius

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(r),
      side: const BorderSide(color: _pillLine, width: 1.2),
    );
    return Material(
      color: _pillFill,
      shape: shape,
      child: InkWell(
        onTap: () {}, // parent handles onStart via row tap if needed
        customBorder: const StadiumBorder(),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(
            "Start >",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3B2F2A),
            ),
          ),
        ),
      ),
    );
  }
}
