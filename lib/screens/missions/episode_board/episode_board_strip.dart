// The pinned EPISODE BOARD strip (PRD §3). A slim bar that sits at the top of each
// capture-bearing activity: the guiding question on the left (the spine the kid is
// always working toward), and the captured moment-tiles on the right that VISIBLY
// FILL as discoveries land. No "tap to collect" — capture is automatic (§3); this
// strip is the place the tiles pin into. Kept compact so it never crowds the
// activity's own chrome.

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import 'evidence_models.dart';
import 'evidence_tile.dart';

class EpisodeBoardStrip extends StatelessWidget {
  const EpisodeBoardStrip({
    super.key,
    required this.question,
    required this.capturedIds,
    required this.images,
    this.accent = const Color(0xFFF5C451),
  });

  /// The guiding question (pinned throughout the episode).
  final String question;

  /// Captured tile ids, in capture order — the board fills as this grows.
  final ValueListenable<List<String>> capturedIds;

  /// id → captured scene frame (the real moment).
  final ValueListenable<Map<String, Uint8List>> images;

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 8, 9, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1330).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.travel_explore_rounded, size: 18, color: accent.withValues(alpha: 0.9)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'EVIDENCE BOARD',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: accent.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  question,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<List<String>>(
            valueListenable: capturedIds,
            builder: (context, ids, _) => ValueListenableBuilder<Map<String, Uint8List>>(
              valueListenable: images,
              builder: (context, imgs, __) => _CapturedRow(ids: ids, images: imgs),
            ),
          ),
        ],
      ),
    );
  }
}

/// The captured mini-tiles row — grows as moments pin in. Shows up to 5 then a
/// "+k" so the width stays bounded no matter how many are collected.
class _CapturedRow extends StatelessWidget {
  const _CapturedRow({required this.ids, required this.images});
  final List<String> ids;
  final Map<String, Uint8List> images;

  static const int _maxShown = 5;

  @override
  Widget build(BuildContext context) {
    if (ids.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Text(
          'collecting…',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      );
    }
    final shown = ids.length > _maxShown ? ids.sublist(ids.length - _maxShown) : ids;
    final extra = ids.length - shown.length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final id in shown)
          if (evidenceById(id) != null)
            Padding(
              padding: const EdgeInsets.only(left: 3),
              child: TweenAnimationBuilder<double>(
                key: ValueKey(id),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutBack,
                builder: (context, t, child) =>
                    Transform.scale(scale: 0.6 + 0.4 * t, child: Opacity(opacity: t.clamp(0, 1), child: child)),
                child: EvidenceTileView(
                    tile: evidenceById(id)!, size: 30, showLabel: false, imageBytes: images[id]),
              ),
            ),
        if (extra > 0)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text('+$extra',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white70)),
          ),
      ],
    );
  }
}
