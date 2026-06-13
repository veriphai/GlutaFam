// Screen 3 (EP1) — the ACTIVE reasoning step: a COVERAGE GRID. EP1's argument is
// a convergence (not a chain), so there's no "right order" — instead the kid drags
// each kept catch-clue onto the one town-NEED that source can't give. Every need
// ends up a gap for someone, no single source covers all four, and solving it
// reveals the verdict (+ the same-magnet "they're all swappable" closer).
//
// Gated like the rest of the close: the shared CerGate runs first (the evidence
// must be right before the kid can reason with it); a wrong drop bounces back with
// a soft note; an optional bulb gives the first unplaced clue's hint. Solving →
// the reveal → Finish earns the card.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../episode_board/case_theme.dart';
import '../../episode_board/evidence_image.dart';
import '../../episode_board/evidence_models.dart';
import '../config/cer_config.dart';
import '../state/cer_controller.dart';
import 'cer_chrome.dart';

const Color _gold = Color(0xFFE0B24C);

class ReasoningGridScreen extends StatefulWidget {
  const ReasoningGridScreen({super.key, required this.controller});
  final CerController controller;

  @override
  State<ReasoningGridScreen> createState() => _ReasoningGridScreenState();
}

class _ReasoningGridScreenState extends State<ReasoningGridScreen> {
  CerController get c => widget.controller;

  bool _revealed = false;
  String? _wrongSlotId; // the slot a clue was wrongly dropped on (flash red briefly)

  void _tryDrop(String tileId, String slotId) {
    if (c.placeOnSlot(tileId, slotId)) {
      HapticFeedback.selectionClick();
      if (mounted) setState(() => _wrongSlotId = null);
      if (c.gridSolved) {
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 480), () {
          if (mounted) setState(() => _revealed = true);
        });
      }
    } else {
      HapticFeedback.lightImpact();
      setState(() => _wrongSlotId = slotId);
      Future.delayed(const Duration(milliseconds: 750), () {
        if (mounted && _wrongSlotId == slotId) setState(() => _wrongSlotId = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = c.reasoning! as CerCoverageReasoning;
    return Column(
      children: [
        CerQuestionHeader(question: c.config.question, step: 3),
        const SizedBox(height: 14),
        Expanded(
          child: !c.caseSolved
              ? _gateView()
              : (_revealed ? _revealView(r) : _gridView(r)),
        ),
      ],
    );
  }

  // ── The evidence gate (reused) — shown if the kept clues aren't right yet.
  //     Shows what the kid HAS collected so the screen isn't empty + gives context.
  Widget _gateView() {
    final kept = c.keptTiles;
    return Column(
      children: [
        const SizedBox(height: 2),
        Text(
          'YOUR CLUES SO FAR',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Colors.white.withValues(alpha: 0.55)),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: kept.isEmpty
              ? Center(
                  child: Text(
                    'No clues kept yet.',
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.4)),
                  ),
                )
              : SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [for (final t in kept) _chip(t)],
                  ),
                ),
        ),
        const SizedBox(height: 10),
        CerGate(controller: c),
      ],
    );
  }

  // ── The grid ─────────────────────────────────────────────────────────────────
  Widget _gridView(CerCoverageReasoning r) {
    final wrongNote = _wrongSlotId != null;
    return SingleChildScrollView(
      child: Column(
        children: [
          Text(
            r.intro,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.82)),
          ),
          const SizedBox(height: 12),
          for (final slot in r.slots) ...[
            _needRow(slot),
            const SizedBox(height: 9),
          ],
          const SizedBox(height: 6),
          Text(
            r.task,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, height: 1.3, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 12),
          // The tray of clues still to place.
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [for (final t in c.unplacedTiles) _draggableChip(t)],
          ),
          if (wrongNote) ...[
            const SizedBox(height: 12),
            Text(
              r.wrongDropNote,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.redAccent.withValues(alpha: 0.85)),
            ),
          ],
          const SizedBox(height: 14),
          _hintBulb(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _needRow(CerReasonSlot slot) {
    final here = c.reasoningTiles.where((t) => c.placed[t.id] == slot.id).toList();
    final wrong = _wrongSlotId == slot.id;
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) => _tryDrop(d.data, slot.id),
      builder: (context, cand, rej) {
        final hovering = cand.isNotEmpty;
        final border = wrong
            ? Colors.redAccent
            : hovering
                ? _gold
                : Colors.white.withValues(alpha: 0.18);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: hovering ? Colors.white.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: hovering || wrong ? 2 : 1.2),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 92,
                child: Text(
                  slot.label.toUpperCase(),
                  style: const TextStyle(fontSize: 12.5, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: 0.4, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: here.isEmpty
                    ? Text(
                        'drop here',
                        style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Colors.white.withValues(alpha: 0.28)),
                      )
                    : Wrap(spacing: 6, runSpacing: 6, children: [for (final t in here) _placedChip(t)]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _draggableChip(EvidenceTile t) {
    // Default (child) anchor: the chip stays under the finger where it was
    // grabbed — natural. Feedback scales up + glows so it reads as "lifted".
    return Draggable<String>(
      data: t.id,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(scale: 1.08, child: _chip(t, dragging: true)),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: _chip(t)),
      child: _chip(t),
    );
  }

  /// A placed chip that pops in (settle-bounce) when it first lands in a slot.
  Widget _placedChip(EvidenceTile t) => TweenAnimationBuilder<double>(
        key: ValueKey(t.id),
        tween: Tween(begin: 0.5, end: 1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: _chip(t, small: true),
      );

  Widget _chip(EvidenceTile t, {bool small = false, bool dragging = false}) {
    final h = small ? 30.0 : 40.0;
    final thumb = h - (small ? 12 : 14);
    return Container(
      height: h,
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B2C4C), Color(0xFF101B33)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.accent.withValues(alpha: dragging ? 1 : 0.75), width: 1.4),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: dragging ? 16 : 6, offset: Offset(0, dragging ? 7 : 3)),
          if (dragging) BoxShadow(color: t.accent.withValues(alpha: 0.45), blurRadius: 16),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(width: thumb, height: thumb, child: evidenceImage(t, imageBytes: c.imageBytes[t.id])),
          ),
          SizedBox(width: small ? 5 : 7),
          Text(
            t.label,
            style: TextStyle(fontSize: small ? 10.5 : 12.5, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _hintBulb() {
    final hint = c.gridHintText;
    if (hint == null) return const SizedBox.shrink();
    return Column(
      children: [
        CerCtaPill(
          label: c.hintRevealed ? 'Hide hint' : 'Need a hint?',
          icon: Icons.lightbulb_outline_rounded,
          filled: false,
          onTap: c.toggleHint,
        ),
        if (c.hintRevealed) ...[
          const SizedBox(height: 10),
          CerHintBanner(text: hint),
        ],
      ],
    );
  }

  // ── The reveal — closer card + verdict + Finish ──────────────────────────────
  Widget _revealView(CerReasoning r) {
    final closer = c.reasoningCloser;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 6),
                if (closer != null && r.closerLine != null) ...[
                  _closerCard(closer, r.closerLine!),
                  const SizedBox(height: 16),
                ],
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CaseTheme.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: CaseTheme.gold.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified_rounded, size: 20, color: _gold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          r.verdict,
                          style: const TextStyle(fontSize: 14.5, height: 1.4, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        CerCtaPill(label: c.config.finishCta, icon: Icons.check_rounded, onTap: c.finish),
      ],
    );
  }

  Widget _closerCard(EvidenceTile t, String line) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(width: 56, height: 56, child: evidenceImage(t, imageBytes: c.imageBytes[t.id])),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              line,
              style: TextStyle(fontSize: 13, height: 1.35, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }
}
