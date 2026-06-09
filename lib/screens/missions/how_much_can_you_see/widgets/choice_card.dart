// A cyclone-challenge option card (PRD §12, §20).
//
// The card FRAME is drawn in Flutter (uniform navy glass + rounded glowing
// border, matching the Scene 1 hologram tiles) with the object icon from
// 03_objects inside — so every card looks identical regardless of the source
// art. Feedback is Flutter too:
//   • wrong  → red/orange border + glow + a one-shot shake
//   • correct → green border + glow + a check badge
//   • hint   → the correct card pulses cyan after repeated misses

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../config/challenge_options.dart';
import '../../../../utils/s3_assets.dart';

class ChoiceCard extends StatefulWidget {
  const ChoiceCard({
    super.key,
    required this.option,
    required this.onTap,
    required this.selected,
    required this.correct,
    required this.shakeToken,
    this.hintPulse = false,
    this.locked = false,
  });

  final ChallengeOption option;
  final VoidCallback onTap;
  final bool selected; // this card is the current selection
  final bool correct; // the selection was correct (green)
  final int shakeToken; // bump to trigger a one-shot shake (wrong)
  final bool hintPulse; // pulse to hint this is the answer
  final bool locked; // disable taps after solved

  @override
  State<ChoiceCard> createState() => _ChoiceCardState();
}

class _ChoiceCardState extends State<ChoiceCard> with TickerProviderStateMixin {
  late final AnimationController _shake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didUpdateWidget(covariant ChoiceCard old) {
    super.didUpdateWidget(old);
    if (widget.shakeToken != old.shakeToken && widget.selected && !widget.correct) {
      _shake.forward(from: 0);
    }
    if (widget.hintPulse && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.hintPulse && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Color get _accent {
    if (widget.selected && widget.correct) return CareerColors.green;
    if (widget.selected && !widget.correct) return CareerColors.orange;
    return CareerColors.cyan;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;

    return AnimatedBuilder(
      animation: Listenable.merge([_shake, _pulse]),
      builder: (context, child) {
        final dx = math.sin(_shake.value * math.pi * 6) * (1 - _shake.value) * 9;
        final glow = widget.hintPulse ? (0.5 + 0.5 * math.sin(_pulse.value * 2 * math.pi)) : 0.0;
        final pulseScale = 1 + 0.035 * glow;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Transform.scale(scale: widget.hintPulse ? pulseScale : 1.0, child: child),
        );
      },
      child: PressableScale(
        onTap: widget.locked ? () {} : widget.onTap,
        pressedScale: 0.97,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF143462), Color(0xFF0B1E3C)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: accent.withValues(alpha: 0.95), width: 2.2),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: widget.hintPulse ? 0.55 : 0.35),
                blurRadius: widget.hintPulse ? 22 : 14,
                spreadRadius: widget.hintPulse ? 2 : 0,
              ),
            ],
          ),
          // StackFit.expand → the Column gets the full card width, so a NARROW
          // icon (tower) no longer makes the content hug the top-left.
          child: Stack(
            fit: StackFit.expand,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: netImageWidget(HM.flutter(widget.option.icon), fit: BoxFit.contain)),
                  const SizedBox(height: 6),
                  Text(
                    widget.option.label,
                    textAlign: TextAlign.center,
                    style: CareerText.label.copyWith(
                        fontSize: 14, color: Colors.white, letterSpacing: 0.5),
                  ),
                ],
              ),
              // Correct check badge (top-right).
              if (widget.selected && widget.correct)
                Positioned(
                  top: 0,
                  right: 0,
                  child: netImageWidget(HM.flutter(HM.checkmark), width: 34),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
