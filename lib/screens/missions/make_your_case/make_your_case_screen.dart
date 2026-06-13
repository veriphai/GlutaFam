// "Make Your Case" — the per-episode CER synthesis closing flow (PRD §4, §8). A
// NEW screen/flow (not a modification of an activity): three SEQUENTIAL screens,
// ONE task each — select the relevant evidence → state the claim → see the
// reasoning played back — answering the episode's guiding question with what the
// kid gathered. Sequencing is what keeps it uncluttered: never the whole CER at
// once (§4). The closing chrome is a Flutter overlay; the playback uses the lighter
// tile-sequence form (§7.3). No tabs, no drag-lines, no score (§5).
//
// Reached as the final activity resource of Episode 1 (after Act 2 & Act 3), so it
// reads the evidence captured during the episode from the shared store.

import 'package:flutter/material.dart';

import '../../collectibles/collectible_earn_overlay.dart';
import '../../home/career/careerTheme.dart';
import '../activity_header.dart';
import '../episode_board/activity_background.dart';
import '../lessonRunner.dart';
import 'config/cer_config.dart';
import 'state/cer_controller.dart';
import 'widgets/claim_build_screen.dart';
import 'widgets/evidence_preview.dart';
import 'widgets/evidence_select_screen.dart';
import 'widgets/playback_screen.dart';
import 'widgets/reasoning_chain_screen.dart';
import 'widgets/reasoning_grid_screen.dart';

class MakeYourCaseScreen extends StatefulWidget {
  const MakeYourCaseScreen({super.key, this.config = kEp1CerConfig});

  /// The episode's CER definition — catalog, staging, copy, claim template, card.
  final CerConfig config;

  @override
  State<MakeYourCaseScreen> createState() => _MakeYourCaseScreenState();
}

class _MakeYourCaseScreenState extends State<MakeYourCaseScreen> {
  late final CerController _controller;
  bool _popped = false;

  @override
  void initState() {
    super.initState();
    _controller = CerController(config: widget.config)..addListener(_onChange);
    _controller.load();
  }

  void _onChange() {
    if (_controller.finished && !_popped) {
      _popped = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // COMPLETION (card collected) → advance past the back-guard. The header
        // back stays maybePop, which the host's guard turns into the leave modal.
        if (mounted) completeActivity(context);
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: CareerColors.bgMid,
        body: Stack(
          children: [
            const Positioned.fill(child: ActivityDossierBackground()),
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                  child: ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) {
                      if (!_controller.loaded) {
                        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                      }
                      return Column(
                        children: [
                          ActivityNameHeader(
                            onBack: () => Navigator.of(context).maybePop(),
                            fallbackName: widget.config.beatName,
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 320),
                              // Expand children so each screen's inner Expanded is bounded.
                              layoutBuilder: (current, previous) => Stack(
                                fit: StackFit.expand,
                                children: [...previous, if (current != null) current],
                              ),
                              child: KeyedSubtree(
                                key: ValueKey(_controller.screen),
                                child: _screenFor(_controller.screen),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            // Tap-to-inspect evidence preview (Screen 1) — see the captured frame
            // full-size + the moment's meaning, then keep / leave the clue.
            Positioned.fill(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  final t = _controller.previewTile;
                  if (t == null) return const IgnorePointer(child: SizedBox.shrink());
                  return EvidencePreview(
                    tile: t,
                    imageBytes: _controller.imageBytes[t.id],
                    kept: _controller.kept.contains(t.id),
                    onToggle: () {
                      _controller.toggleKeep(t.id);
                      _controller.closePreview();
                    },
                    onClose: _controller.closePreview,
                  );
                },
              ),
            ),

            // The synthesis card-earn moment — the payoff is the case (then its
            // card), never a score.
            Positioned.fill(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => _controller.showCardEarn
                    ? CollectibleEarnOverlay(
                        card: widget.config.card,
                        eyebrow: widget.config.earnEyebrow,
                        brag: widget.config.earnBrag,
                        showMascot: false,
                        onDone: _controller.onCardCollected,
                      )
                    : const IgnorePointer(child: SizedBox.shrink()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _screenFor(CerScreen s) {
    switch (s) {
      case CerScreen.evidence:
        return EvidenceSelectScreen(controller: _controller);
      case CerScreen.claim:
        return ClaimBuildScreen(controller: _controller);
      case CerScreen.playback:
        // Screen 3: the active reasoning step matched to the episode's argument
        // shape — coverage grid (EP1 convergence) or build-the-chain (EP2 chain);
        // episodes with no reasoning spec keep the passive playback montage.
        final r = _controller.config.reasoning;
        if (r is CerChainReasoning) return ReasoningChainScreen(controller: _controller);
        if (r is CerCoverageReasoning) return ReasoningGridScreen(controller: _controller);
        return PlaybackScreen(controller: _controller);
    }
  }

}
