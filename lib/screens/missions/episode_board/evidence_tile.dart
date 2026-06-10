// The evidence TILE — a small visual thumbnail of the moment + a ≤3-word label
// (PRD §6: the image carries it; no captioned text cards). One widget used
// everywhere: the pinned board strip (mini), the closing evidence grid (tappable),
// the "my evidence" tray, and the playback montage. Selection state is a brighter
// frame + a small check — never a ✓/✗ correctness mark (§5.4).

import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'evidence_models.dart';
import 'evidence_tile_painters.dart';

class EvidenceTileView extends StatelessWidget {
  const EvidenceTileView({
    super.key,
    required this.tile,
    this.size = 92,
    this.selected = false,
    this.showLabel = true,
    this.showSource = false,
    this.dim = false,
    this.imageBytes,
  });

  final EvidenceTile tile;
  final double size;
  final bool selected;
  final bool showLabel;
  final bool showSource; // tiny "ACT 2/3" provenance chip (closing grid)
  final bool dim; // left-behind look (e.g. unselected after a selection)

  /// The real captured scene frame (PRD §8). When present the tile shows that
  /// actual frame; when null it falls back to the drawn motif.
  final Uint8List? imageBytes;

  Widget _motifLayer(Color accent) => Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFF0B1026))),
          Positioned.fill(child: CustomPaint(painter: EvidenceMotifPainter(tile.motif, accent))),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final accent = tile.accent;
    final radius = size * 0.16;
    final labelH = showLabel ? size * 0.34 : 0.0;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: dim ? 0.45 : 1,
      child: SizedBox(
        width: size,
        height: size + labelH,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: selected ? accent : accent.withValues(alpha: 0.45),
                  width: selected ? 2.4 : 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: selected ? 0.5 : 0.22),
                    blurRadius: selected ? 16 : 8,
                    spreadRadius: selected ? 1 : 0,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // The real captured scene frame (PRD §8) when we have it; else the
                  // drawn motif over a dark base (the painter draws on top of it).
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius - 1.5),
                      child: imageBytes != null
                          ? Image.memory(
                              imageBytes!,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              errorBuilder: (_, __, ___) => _motifLayer(accent),
                            )
                          : _motifLayer(accent),
                    ),
                  ),
                  if (showSource)
                    Positioned(
                      left: 5,
                      top: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          tile.sourceLabel,
                          style: TextStyle(
                            fontSize: size * 0.085,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),
                  if (selected)
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        width: size * 0.22,
                        height: size * 0.22,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: accent.withValues(alpha: 0.6), blurRadius: 8),
                          ],
                        ),
                        child: Icon(Icons.check_rounded,
                            size: size * 0.16, color: const Color(0xFF0B1026)),
                      ),
                    ),
                ],
              ),
            ),
            if (showLabel)
              SizedBox(
                height: labelH,
                child: Padding(
                  padding: EdgeInsets.only(top: size * 0.07),
                  child: Text(
                    tile.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: size * 0.14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: Colors.white.withValues(alpha: selected ? 0.95 : 0.78),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
