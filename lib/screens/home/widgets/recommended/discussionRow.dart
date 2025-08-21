import 'package:eureka_app/screens/home/models/discussion.dart';
import 'package:flutter/material.dart';

class DiscussionRow extends StatelessWidget {
  const DiscussionRow({
    super.key,
    required this.item,
    required this.onTapExpand,
    required this.onStart,
  });

  final Discussion item;
  final VoidCallback onTapExpand;
  final VoidCallback onStart;

  static const _inkBlue = Color(0xFF1E4B7A);
  static const _muted = Color(0xFF4D5B6A);
  static const _rule = Color(0xFFCCBE9C);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTapExpand,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 12),
        child: Column(
          children: [
            Row(
              children: [
                // left icon sticker (placeholder circle)
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3EEF7),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: const Color(0xFFB7A987), width: 1),
                  ),
                  child: const Icon(Icons.push_pin_outlined,
                      size: 18, color: _inkBlue),
                ),
                const SizedBox(width: 10),
                // title & subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: _inkBlue,
                          )),
                      const SizedBox(height: 2),
                      Text(item.path,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _inkBlue,
                          )),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // right: badges + start
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children:
                          item.badges.map((b) => _Badge(label: b)).toList(),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("• ${item.durationMin} min",
                            style: const TextStyle(
                                fontSize: 12,
                                color: _muted,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        _StartMini(onTap: onStart),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(height: 1, color: _rule.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final bg = switch (label) {
      "IN CLASS" => const Color(0xFFD7F2E6),
      "TEST TUE" => const Color(0xFFE4ECF7),
      "GAP HIGH" => const Color(0xFFF7D77A),
      _ => const Color(0xFFEDE7D3),
    };
    final br = switch (label) {
      "IN CLASS" => const Color(0xFF94C8B5),
      "TEST TUE" => const Color(0xFF9FB7D7),
      "GAP HIGH" => const Color(0xFFC4A941),
      _ => const Color(0xFFB7A987),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: br, width: 1),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3B2F2A))),
    );
  }
}

class _StartMini extends StatelessWidget {
  const _StartMini({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7D77A),
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text("Start >",
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3B2F2A))),
        ),
      ),
    );
  }
}
