// Floating robot helper + Flutter-rendered speech bubble (PRD §10.5). Shows the
// CURRENT OrbitLine — sequencing/pacing is owned by the controller (lineIndex
// advances on voice completion, or the screen's reading-time fallback when
// muted). Text swaps use the sequential fade-out -> swap -> fade-in primitive —
// NOT AnimatedSwitcher, whose cross-fade shows both lines at once while the
// next voice line is already speaking.

import 'package:flutter/material.dart';

import '../../../../utils/s3_assets.dart';
import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../state/choose_satellite_state.dart';

class MascotHelper extends StatelessWidget {
  const MascotHelper({
    super.key,
    required this.mood,
    required this.line,
    this.height = 92,
    this.bubbleAccent = CareerColors.cyan,
  });

  final MascotMood mood;
  final String line;
  final double height;
  final Color bubbleAccent;

  static String spriteFor(MascotMood mood) {
    switch (mood) {
      case MascotMood.welcoming:
        return CrsAssets.mascotWelcoming;
      case MascotMood.guiding:
        return CrsAssets.mascotGuiding;
      case MascotMood.thinking:
        return CrsAssets.mascotThinking;
      case MascotMood.concerned:
        return CrsAssets.mascotConcerned;
      case MascotMood.celebrating:
        return CrsAssets.mascotCelebrating;
      case MascotMood.happy:
        return CrsAssets.mascotHappy;
      case MascotMood.pointingRight:
        return CrsAssets.mascotPointingRight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sprite = spriteFor(mood);
    // House helper-card layout (same as Signal Rescue's HelperCard): robot
    // bottom-aligned beside a full-width rounded message card.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Floaty(
          amplitude: 3,
          period: const Duration(milliseconds: 3000),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
            child: netImageWidget(
              sprite,
              key: ValueKey(sprite),
              height: height,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: _bubble(line)),
      ],
    );
  }

  Widget _bubble(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1E3C).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bubbleAccent.withValues(alpha: 0.65), width: 1.4),
        boxShadow: [BoxShadow(color: bubbleAccent.withValues(alpha: 0.28), blurRadius: 14)],
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: _FadeSwapText(
          text: text,
          style: CareerText.body.copyWith(
              color: Colors.white, fontSize: 12.5, height: 1.28, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Sequential fade-out -> swap -> fade-in. The playbook's primitive for
/// voice-paced bubble text: a cross-fade would show line N and N+1 together.
class _FadeSwapText extends StatefulWidget {
  const _FadeSwapText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_FadeSwapText> createState() => _FadeSwapTextState();
}

class _FadeSwapTextState extends State<_FadeSwapText> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 170), value: 1);
  late String _shown = widget.text;

  @override
  void didUpdateWidget(covariant _FadeSwapText old) {
    super.didUpdateWidget(old);
    if (widget.text != _shown && _c.status != AnimationStatus.reverse) {
      _c.reverse().then((_) {
        if (!mounted) return;
        setState(() => _shown = widget.text); // always swap to the LATEST text
        _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _c, child: Text(_shown, style: widget.style));
  }
}
