// Screen 3 (EP2) — the ACTIVE reasoning step: BUILD THE CHAIN. EP2's argument is
// a causal chain (each step forces the next), so there IS a right order. The kid
// assembles it by tapping the clue that comes NEXT; each correct link snaps into
// the chain with the connective that IS the reasoning ("so / but how / put it
// together"). A wrong tap nudges; the bulb gives the connective the last link
// forces. Completing it reveals the verdict, then Finish earns the card.
//
// Gated like the rest of the close: the shared CerGate runs first (the kept clues
// must be the right six before the kid can order them).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../../home/career/careerCommon.dart' show PressableScale;
import '../../episode_board/evidence_image.dart';
import '../../episode_board/evidence_models.dart';
import '../config/cer_config.dart';
import '../state/cer_controller.dart';
import 'cer_chrome.dart';

const Color _gold = Color(0xFFE0B24C);

class ReasoningChainScreen extends StatefulWidget {
  const ReasoningChainScreen({super.key, required this.controller});
  final CerController controller;

  @override
  State<ReasoningChainScreen> createState() => _ReasoningChainScreenState();
}

class _ReasoningChainScreenState extends State<ReasoningChainScreen> {
  CerController get c => widget.controller;
  final ScrollController _scroll = ScrollController();
  bool _wrong = false; // brief nudge state after a wrong "what's next" tap
  int _shakes = 0; // bumped on a wrong tap → the pool shakes

  EvidenceTile _tileOf(String id) => c.reasoningTiles.firstWhere((t) => t.id == id);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _tap(String id) {
    if (c.tapNextLink(id)) {
      if (mounted) setState(() => _wrong = false);
      HapticFeedback.selectionClick();
      if (c.chainSolved) HapticFeedback.mediumImpact();
      // Keep the newest link (and the verdict) in view as the chain grows.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
        }
      });
    } else {
      HapticFeedback.lightImpact();
      setState(() {
        _wrong = true;
        _shakes++;
      });
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _wrong = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = c.reasoning! as CerChainReasoning;
    return Column(
      children: [
        CerQuestionHeader(question: c.config.question, step: 3),
        const SizedBox(height: 14),
        Expanded(
          child: !c.caseSolved ? _gateView() : _chainScroll(r),
        ),
        if (c.caseSolved) ...[
          const SizedBox(height: 10),
          c.chainSolved
              ? CerCtaPill(label: c.config.finishCta, icon: Icons.check_rounded, onTap: c.finish)
              : _poolBar(r),
        ],
      ],
    );
  }

  // ── The evidence gate (reused) ───────────────────────────────────────────────
  Widget _gateView() {
    return Column(
      children: [
        const Spacer(),
        Icon(Icons.inventory_2_rounded, size: 40, color: Colors.white.withValues(alpha: 0.28)),
        const SizedBox(height: 14),
        Text(
          'Get your clues right first.',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.7)),
        ),
        const Spacer(),
        CerGate(controller: c),
      ],
    );
  }

  // ── The assembled chain (scrolls) ────────────────────────────────────────────
  Widget _chainScroll(CerChainReasoning r) {
    return SingleChildScrollView(
      controller: _scroll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            r.intro,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.82)),
          ),
          const SizedBox(height: 14),
          if (c.chainBuilt.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'Tap the clue that comes first ↓',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.white.withValues(alpha: 0.4)),
              ),
            ),
          for (var i = 0; i < c.chainBuilt.length; i++) _link(i, c.chainBuilt[i], r),
          if (c.chainSolved) ...[
            const SizedBox(height: 8),
            _verdict(r),
          ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _link(int i, String id, CerChainReasoning r) {
    final t = _tileOf(id);
    final link = i < r.links.length ? r.links[i] : '';
    final isLast = i == r.order.length - 1;
    return TweenAnimationBuilder<double>(
      key: ValueKey('link_$id'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: child),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: t.accent, shape: BoxShape.circle),
              child: Text('${i + 1}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0B1026))),
            ),
            const SizedBox(width: 10),
            Expanded(child: _chip(t)),
          ],
        ),
        if (!isLast && link.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 34, top: 6, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.south_rounded, size: 14, color: Colors.white.withValues(alpha: 0.4)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    link,
                    style: TextStyle(fontSize: 12, height: 1.3, fontStyle: FontStyle.italic, color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ),
              ],
            ),
          )
        else
          const SizedBox(height: 9),
      ],
      ),
    );
  }

  // ── The bottom pool — tap the clue that comes next ───────────────────────────
  Widget _poolBar(CerChainReasoning r) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          r.task,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 10),
        _Shake(
          trigger: _shakes,
          child: Wrap(
            spacing: 9,
            runSpacing: 9,
            alignment: WrapAlignment.center,
            children: [for (final t in c.chainPool) _poolChip(t)],
          ),
        ),
        if (_wrong) ...[
          const SizedBox(height: 10),
          Text(
            r.wrongNote,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.redAccent.withValues(alpha: 0.85)),
          ),
        ],
        const SizedBox(height: 10),
        _hintBulb(),
      ],
    );
  }

  Widget _poolChip(EvidenceTile t) {
    return PressableScale(onTap: () => _tap(t.id), child: _chip(t));
  }

  Widget _chip(EvidenceTile t) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B2C4C), Color(0xFF101B33)],
        ),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: t.accent.withValues(alpha: 0.8), width: 1.4),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 7, offset: const Offset(0, 3))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(width: 32, height: 32, child: evidenceImage(t, imageBytes: c.imageBytes[t.id])),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              t.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hintBulb() {
    final hint = c.chainHintText;
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

  Widget _verdict(CerChainReasoning r) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gold.withValues(alpha: 0.5)),
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
    );
  }
}

/// A brief decaying horizontal shake, fired whenever [trigger] changes (never on
/// first build) — the "nope" nudge for a wrong "what comes next" tap.
class _Shake extends StatefulWidget {
  const _Shake({required this.trigger, required this.child});
  final int trigger;
  final Widget child;

  @override
  State<_Shake> createState() => _ShakeState();
}

class _ShakeState extends State<_Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 380));

  @override
  void didUpdateWidget(_Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final dx = math.sin(_c.value * math.pi * 4) * 8 * (1 - _c.value);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}
