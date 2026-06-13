// Screen 3 — Reasoning / playback ("Here's your case.", PRD §4.3). The kid's case,
// played back as a montage: their kept photos DROP onto the case board one by one,
// in order, each narrated by what it shows, building to the verdict (their claim) +
// the capstone. The reasoning is carried BY the playback — the ordered evidence IS
// the argument (§5.3). No drag-lines, no typed essay, NOT a score (§5.4). A missing
// clue → the case feels unfinished and can be added to (gentle, §4.3).

import 'package:flutter/material.dart';

import '../../episode_board/case_theme.dart';
import '../../episode_board/photo_card.dart';
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

  CerController get c => widget.controller;
  int get _n => c.keptTiles.length;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 820 * (_n + 1) + 900),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) setState(() => _done = true);
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations || _n == 0) {
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

  void _skip() {
    _c.stop();
    _c.value = 1;
    setState(() => _done = true);
  }

  // Per-segment progress (segment i revealed over [i/(n+1), (i+1)/(n+1)]).
  double _seg(int i) {
    final span = 1 / (_n + 1);
    return ((_c.value - i * span) / span).clamp(0.0, 1.0);
  }

  // The clue currently "landing" (drives the narration line); == n → capstone.
  int get _narrIndex => (_c.value * (_n + 1)).floor().clamp(0, _n);

  @override
  Widget build(BuildContext context) {
    final kept = c.keptTiles;
    final width = MediaQuery.of(context).size.width;
    final photo = ((width - 32 - 24) / 3).clamp(80.0, 116.0);

    return Column(
      children: [
        CerQuestionHeader(question: c.config.question, step: 3),
        const SizedBox(height: 12),
        _verdict(),
        const SizedBox(height: 14),
        Expanded(
          child: GestureDetector(
            onTap: _done ? null : _skip,
            behavior: HitTestBehavior.opaque,
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                return Stack(
                  children: [
                    // The photos dropping onto the board.
                    Positioned.fill(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 14,
                              children: [
                                for (var i = 0; i < kept.length; i++) _dropIn(i, kept[i], photo),
                              ],
                            ),
                            if (kept.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 30),
                                child: Text('No clues in your case yet.',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13)),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Skip hint (while playing).
                    if (!_done)
                      const Positioned(
                        right: 4,
                        top: 0,
                        child: _SkipHint(),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Narration → capstone.
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) => _narration(),
        ),
        const SizedBox(height: 10),
        AnimatedOpacity(
          opacity: _done ? 1 : 0,
          duration: const Duration(milliseconds: 320),
          child: IgnorePointer(ignoring: !_done, child: _bottom()),
        ),
      ],
    );
  }

  Widget _dropIn(int i, tile, double photo) {
    final t = Curves.easeOutBack.transform(_seg(i));
    final landed = _seg(i) > 0.01;
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, -46 * (1 - t)),
        child: Transform.rotate(
          angle: (i.isEven ? 1 : -1) * 0.045 * t,
          child: PhotoCard(
            tile: tile,
            size: photo,
            imageBytes: c.imageBytes[tile.id],
            kept: landed,
          ),
        ),
      ),
    );
  }

  Widget _verdict() {
    final atEnd = _narrIndex >= _n;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: CaseTheme.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CaseTheme.gold.withValues(alpha: atEnd ? 0.9 : 0.4), width: atEnd ? 1.8 : 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 6)),
          if (atEnd) BoxShadow(color: CaseTheme.gold.withValues(alpha: 0.3), blurRadius: 18, spreadRadius: 1),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.gavel_rounded, size: 18, color: Color(0xFFB07A1E)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              c.claimText,
              style: const TextStyle(fontSize: 14.5, height: 1.3, fontWeight: FontWeight.w800, color: CaseTheme.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _narration() {
    final text = _narrIndex >= _n ? c.config.capstone : c.keptTiles[_narrIndex].caption;
    final isCapstone = _narrIndex >= _n;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(text),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isCapstone ? CaseTheme.gold.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isCapstone ? CaseTheme.gold.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isCapstone ? 14.5 : 13.5,
            height: 1.35,
            fontWeight: isCapstone ? FontWeight.w800 : FontWeight.w600,
            color: Colors.white.withValues(alpha: isCapstone ? 1 : 0.85),
          ),
        ),
      ),
    );
  }

  Widget _bottom() {
    // Solved = every answering clue kept AND no distractor held → Finish unlocks.
    if (c.caseSolved) {
      return CerCtaPill(label: c.config.finishCta, icon: Icons.check_rounded, onTap: c.finish);
    }
    // GATED: a clue is missing and/or a distractor is kept. No finish-anyway —
    // the shared gate explains, offers the hint bulb, and routes back to fix it.
    return CerGate(controller: c);
  }
}

class _SkipHint extends StatelessWidget {
  const _SkipHint();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('Tap to skip', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.7))),
        const SizedBox(width: 3),
        Icon(Icons.skip_next_rounded, size: 14, color: Colors.white.withValues(alpha: 0.7)),
      ]),
    );
  }
}
