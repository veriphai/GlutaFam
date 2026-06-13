// The tap-to-inspect EVIDENCE PREVIEW (Screen 1). Tapping a clue OPENS it here:
// the actual captured frame full-size + the moment's one-line meaning, and the
// keep/leave decision. Seeing the real moment before deciding is the reasoning —
// still no correct/wrong (§5.4); the kid just chooses whether this clue bears on
// the question.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../../episode_board/evidence_models.dart';
import '../../episode_board/photo_card.dart';

class EvidencePreview extends StatelessWidget {
  const EvidencePreview({
    super.key,
    required this.tile,
    required this.imageBytes,
    required this.kept,
    required this.onToggle,
    required this.onClose,
  });

  final EvidenceTile tile;
  final Uint8List? imageBytes;
  final bool kept;
  final VoidCallback onToggle; // keep / leave this clue (then close)
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final imgSize = (media.size.width * 0.74).clamp(220.0, 360.0);
    return Stack(
      children: [
        // Scrim — tap anywhere outside to close (no change).
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            child: ColoredBox(color: const Color(0xFF05070F).withValues(alpha: 0.82)),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The captured moment as a polaroid (the real frame or motif).
                  PhotoCard(
                    tile: tile,
                    size: imgSize * 0.82,
                    kept: kept,
                    imageBytes: imageBytes,
                    tilt: -0.02,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tile.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tile.caption,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: 22),
                  // Keep / leave this clue.
                  PressableScale(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onToggle();
                    },
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 26),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: kept ? null : CareerGradients.gold,
                        color: kept ? Colors.white.withValues(alpha: 0.06) : null,
                        borderRadius: BorderRadius.circular(CareerRadii.pill),
                        border: kept ? Border.all(color: Colors.white.withValues(alpha: 0.3)) : null,
                        boxShadow: kept
                            ? null
                            : [BoxShadow(color: CareerColors.gold.withValues(alpha: 0.45), blurRadius: 16, offset: const Offset(0, 5))],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(kept ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded,
                              size: 20, color: kept ? Colors.white : CareerColors.onLight),
                          const SizedBox(width: 8),
                          Text(
                            kept ? 'Remove from my case' : 'Add to my case',
                            style: CareerText.cta.copyWith(
                              color: kept ? Colors.white : CareerColors.onLight,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: onClose,
                    child: Text('Close',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.6))),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
