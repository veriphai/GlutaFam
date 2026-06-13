// The moment's visual, resolved once for every surface that shows a clue (photo
// card, capture, node, drawer, closing): the bundled "perfect" frame (primary) →
// a live-captured frame if any → the drawn motif (fallback). One helper so the
// cascade is identical everywhere.

import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'evidence_models.dart';
import 'evidence_tile_painters.dart';

Widget evidenceImage(EvidenceTile tile, {Uint8List? imageBytes, BoxFit fit = BoxFit.cover}) {
  Widget motif() => Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF0B1026)),
          CustomPaint(painter: EvidenceMotifPainter(tile.motif, tile.accent)),
        ],
      );
  return Image.asset(
    tile.assetPath,
    fit: fit,
    gaplessPlayback: true,
    errorBuilder: (_, __, ___) => imageBytes != null
        ? Image.memory(imageBytes, fit: fit, gaplessPlayback: true, errorBuilder: (_, __, ___) => motif())
        : motif(),
  );
}
