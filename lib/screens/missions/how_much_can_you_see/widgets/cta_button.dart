// The primary gold CTA used across scenes (START VIEW TEST / BEGIN / TAKE
// CHALLENGE / CONTINUE / NEXT) — PRD §7 typography, gently pulsing to draw the
// eye (PRD §10/§18).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';

class CtaButton extends StatefulWidget {
  const CtaButton({
    super.key,
    required this.label,
    required this.onTap,
    this.gradient,
    this.icon,
    this.pulse = true,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final LinearGradient? gradient;
  final IconData? icon;
  final bool pulse;

  /// While false the button dims AND blocks taps (dim alone is a UX trap —
  /// skill rule). Used to gate primary CTAs while Orbit is speaking.
  final bool enabled;

  @override
  State<CtaButton> createState() => _CtaButtonState();
}

class _CtaButtonState extends State<CtaButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.gradient ?? CareerGradients.gold;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final p = (widget.pulse && widget.enabled)
            ? (0.5 + 0.5 * math.sin(_c.value * 2 * math.pi))
            : 0.0;
        return IgnorePointer(
          ignoring: !widget.enabled,
          child: AnimatedOpacity(
            opacity: widget.enabled ? 1 : 0.45,
            duration: const Duration(milliseconds: 250),
            child: Transform.scale(scale: 1 + 0.018 * p, child: child),
          ),
        );
      },
      child: PressableScale(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: g,
            borderRadius: BorderRadius.circular(CareerRadii.pill),
            boxShadow: [
              BoxShadow(color: g.colors.last.withValues(alpha: 0.5), blurRadius: 18, offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: CareerColors.onLight),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: CareerText.cta.copyWith(
                    color: CareerColors.onLight, fontSize: 14, letterSpacing: 1.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
