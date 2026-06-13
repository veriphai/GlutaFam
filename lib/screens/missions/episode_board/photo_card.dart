// The PHOTO CARD — a warm polaroid of a captured moment, the unit of the
// photo-detective aesthetic. A cream paper frame with a thick bottom strip for a
// handwritten label, a soft drop shadow, a slight pinned tilt, and an optional
// "develop" reveal (for the capture beat). Kept clues glow gold. Used everywhere a
// clue is shown: the corner node, the capture, the peek drawer, the closing flow.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'case_theme.dart';
import 'evidence_image.dart';
import 'evidence_models.dart';

class PhotoCard extends StatelessWidget {
  const PhotoCard({
    super.key,
    required this.tile,
    required this.size, // the inner PHOTO width; the card is larger (paper border)
    this.imageBytes,
    this.kept = false,
    this.tilt = 0,
    this.showLabel = true,
    this.develop = 1, // 0 = undeveloped (blank paper) … 1 = fully shown
    this.dim = false,
    this.labelFactor = 0.12, // label font size as a fraction of [size]
  });

  final EvidenceTile tile;
  final double size;
  final Uint8List? imageBytes;
  final bool kept;
  final double tilt; // radians; a small pinned-photo lean
  final bool showLabel;
  final double develop;
  final bool dim;

  /// The handwritten label's font size as a fraction of the photo [size]. The
  /// brief capture-flash snap passes a smaller value than the boards/grids.
  final double labelFactor;

  double get cardWidth => size + 2 * (size * 0.055);
  double get cardHeight => size + size * 0.055 + (showLabel ? size * 0.24 : size * 0.055);

  @override
  Widget build(BuildContext context) {
    final side = size * 0.055;
    final photoR = size * 0.02;
    return Transform.rotate(
      angle: tilt,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: dim ? 0.5 : 1,
        child: Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            color: CaseTheme.paper,
            borderRadius: BorderRadius.circular(size * 0.03),
            border: kept ? Border.all(color: CaseTheme.gold, width: 2) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: kept ? 22 : 14,
                spreadRadius: kept ? 1 : 0,
                offset: const Offset(0, 8),
              ),
              if (kept)
                BoxShadow(color: CaseTheme.gold.withValues(alpha: 0.4), blurRadius: 22, spreadRadius: 1),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(side, side, side, 0),
                child: SizedBox(
                  width: size,
                  height: size,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(photoR),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        evidenceImage(tile, imageBytes: imageBytes),
                        // Inner edge shadow so the photo sits IN the paper.
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(photoR),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4, spreadRadius: -2),
                            ],
                          ),
                        ),
                        // "Develop" reveal — milky paper clearing to the image.
                        if (develop < 1)
                          Opacity(
                            opacity: (1 - develop).clamp(0.0, 1.0),
                            child: const ColoredBox(color: CaseTheme.paper),
                          ),
                        if (kept)
                          Positioned(
                            right: 5,
                            top: 5,
                            child: _keptStamp(size),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (showLabel)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: side * 0.5),
                      child: Text(
                        tile.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.caveat(
                          fontSize: size * labelFactor,
                          fontWeight: FontWeight.w700,
                          color: CaseTheme.ink,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _keptStamp(double size) {
    return Container(
      width: size * 0.2,
      height: size * 0.2,
      decoration: BoxDecoration(
        color: CaseTheme.gold,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: CaseTheme.gold.withValues(alpha: 0.6), blurRadius: 8)],
      ),
      child: Icon(Icons.check_rounded, size: size * 0.14, color: CaseTheme.deskTop),
    );
  }
}
