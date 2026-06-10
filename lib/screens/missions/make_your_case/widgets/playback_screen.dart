// Screen 3 — Reasoning / playback ("Here's your case.", PRD §4.3). Their claim at
// top + their evidence tiles, played back as a narrated montage: the selected
// moments, in order, building to their claim. The reasoning is carried BY the
// playback — the ordered evidence IS the argument (§5.3). No drag-lines, no typed
// essay. The reward is seeing your own reasoning rendered as a coherent story —
// NOT a score, no ✓/✗ (§5.4). If the case is missing something important the
// playback FEELS incomplete and the kid can go back and add (gentle, never wrong).
//
// Per §7.3 we start with the lighter form: the tiles animate in sequence with a
// one-line capstone.

import 'package:flutter/material.dart';

import '../../episode_board/evidence_models.dart';
import '../../episode_board/evidence_tile.dart';
import '../config/cer_copy.dart';
import '../state/cer_controller.dart';
import 'cer_chrome.dart';

class PlaybackScreen extends StatefulWidget {
  const PlaybackScreen({super.key, required this.controller});
  final CerController controller;

  @override
  State<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<PlaybackScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _done = false;

  int get _n => widget.controller.keptTiles.length;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 650 * (_n + 1) + 500),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) setState(() => _done = true);
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduced = MediaQuery.of(context).disableAnimations;
      if (reduced) {
        _c.value = 1;
        setState(() => _done = true);
      } else {
        _c.forward();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String get _claimText {
    final s1 = widget.controller.slot1 ?? '…';
    final s2 = widget.controller.slot2 ?? '…';
    return 'We use $s1 different sources because no single one $s2.';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final kept = c.keptTiles;
    final segments = _n + 1; // tiles + capstone

    return Column(
      children: [
        const CerQuestionHeader(step: 3),
        const SizedBox(height: 14),
        // Their claim — the conclusion the montage builds toward.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFFF5C451).withValues(alpha: 0.18), const Color(0xFFF5C451).withValues(alpha: 0.06)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF5C451).withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              const Icon(Icons.gavel_rounded, size: 18, color: Color(0xFFFFD970)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _claimText,
                  style: const TextStyle(fontSize: 15.5, height: 1.3, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // The montage — the kept moments, in order, building the argument.
        Expanded(
          child: SingleChildScrollView(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                return Column(
                  children: [
                    for (var i = 0; i < kept.length; i++)
                      _montageRow(kept[i], i, segments),
                    if (kept.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text('No clues in your case yet.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13)),
                      ),
                    _capstone(segments),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedOpacity(
          opacity: _done ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: IgnorePointer(ignoring: !_done, child: _bottom(c)),
        ),
      ],
    );
  }

  double _segmentT(int index, int segments) {
    final start = index / segments;
    final span = 1 / segments;
    return ((_c.value - start) / span).clamp(0.0, 1.0);
  }

  Widget _montageRow(EvidenceTile tile, int i, int segments) {
    final t = _segmentT(i, segments);
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, 18 * (1 - t)),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              EvidenceTileView(tile: tile, size: 64, showLabel: false, imageBytes: widget.controller.imageBytes[tile.id]),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tile.label,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(tile.sourceLabel,
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: tile.accent.withValues(alpha: 0.85))),
                  ],
                ),
              ),
              Icon(Icons.south_rounded, size: 18, color: Colors.white.withValues(alpha: 0.25 + 0.4 * t)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _capstone(int segments) {
    final t = _segmentT(segments - 1, segments);
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, 16 * (1 - t)),
        child: Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Text(
            CerCopy.capstone,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15.5, height: 1.35, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _bottom(CerController c) {
    if (c.caseComplete) {
      return CerCtaPill(label: CerCopy.finishCta, icon: Icons.check_rounded, onTap: c.finish);
    }
    // The case feels incomplete — gentle, never "wrong" (§4.3).
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          CerCopy.incompleteNudge,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, height: 1.3, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: CerCtaPill(
                label: CerCopy.addEvidenceCta,
                icon: Icons.add_rounded,
                filled: false,
                onTap: c.addMoreEvidence,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CerCtaPill(label: CerCopy.finishAnywayCta, icon: Icons.check_rounded, onTap: c.finish),
            ),
          ],
        ),
      ],
    );
  }
}
