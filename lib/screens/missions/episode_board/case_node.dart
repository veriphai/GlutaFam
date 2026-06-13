// The corner CASE NODE — the entire persistent footprint of evidence collection
// (replaces the old top strip). A small floating stack of photos with a count
// badge and a soft gold glow; it RECEIVES the flying capture and pulses, and a tap
// opens the peek drawer. An overlay element (not in the activity's layout), so it
// never eats scene space.

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import 'case_theme.dart';
import 'evidence_image.dart';
import 'evidence_models.dart';

/// Where the node sits + where the capture/question fly to dock. Screen-space
/// alignment (top-right), shared by CaseNode placement and the fly animations.
const Alignment kCaseNodeAlignment = Alignment(0.8, -0.82);

class CaseNode extends StatelessWidget {
  const CaseNode({
    super.key,
    required this.capturedIds,
    required this.images,
    required this.onTap,
  });

  final ValueListenable<List<String>> capturedIds;
  final ValueListenable<Map<String, Uint8List>> images;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: capturedIds,
      builder: (context, ids, _) => ValueListenableBuilder<Map<String, Uint8List>>(
        valueListenable: images,
        builder: (context, imgs, __) => _Node(ids: ids, images: imgs, onTap: onTap),
      ),
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.ids, required this.images, required this.onTap});
  final List<String> ids;
  final Map<String, Uint8List> images;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = ids.length;
    final recentId = ids.isNotEmpty ? ids.last : null;
    final recentTile = recentId == null ? null : evidenceById(recentId);
    // Pulse whenever the count changes (a fresh capture just landed).
    return TweenAnimationBuilder<double>(
      key: ValueKey(count),
      tween: Tween(begin: count == 0 ? 1 : 1.35, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.elasticOut,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 74,
          height: 76,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Two cream "photo backs" fanned behind for a stack feel.
              Transform.rotate(angle: -0.14, child: _paperBack(54)),
              Transform.rotate(angle: 0.12, child: _paperBack(54)),
              // Front photo (most recent) or an empty case slot.
              Transform.rotate(
                angle: 0.02,
                child: Container(
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: CaseTheme.paper,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 10, offset: const Offset(0, 4)),
                      BoxShadow(color: CaseTheme.gold.withValues(alpha: count == 0 ? 0.1 : 0.28), blurRadius: 14),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: recentTile == null
                        ? const ColoredBox(
                            color: Color(0xFF0B1026),
                            child: Icon(Icons.photo_camera_rounded, size: 22, color: Color(0x66FFFFFF)),
                          )
                        : evidenceImage(recentTile, imageBytes: images[recentId]),
                  ),
                ),
              ),
              // Count badge.
              if (count > 0)
                Positioned(
                  right: 2,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: CaseTheme.gold,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: CaseTheme.gold.withValues(alpha: 0.5), blurRadius: 8)],
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: CaseTheme.deskTop),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paperBack(double s) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          color: CaseTheme.paperEdge,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 3))],
        ),
      );
}
