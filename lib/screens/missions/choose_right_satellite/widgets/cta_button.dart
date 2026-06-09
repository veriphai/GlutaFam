// Primary CTA used on the intro, log, and bridge scenes. Gold gradient, gently
// pulsing to draw the eye (PRD §19). Mirrors the house CtaButton pattern.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';

class CrsCtaButton extends StatefulWidget {
  const CrsCtaButton({
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

  /// Gated while Orbit speaks (voicePlaying). Dim + IgnorePointer — a dimmed
  /// button that still fires onTap is a UX trap.
  final bool enabled;

  @override
  State<CrsCtaButton> createState() => _CrsCtaButtonState();
}

class _CrsCtaButtonState extends State<CrsCtaButton> with SingleTickerProviderStateMixin {
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
            duration: const Duration(milliseconds: 200),
            opacity: widget.enabled ? 1 : 0.45,
            child: Transform.scale(scale: 1 + 0.02 * p, child: child),
          ),
        );
      },
      child: PressableScale(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
          decoration: BoxDecoration(
            gradient: g,
            borderRadius: BorderRadius.circular(CareerRadii.pill),
            boxShadow: [
              BoxShadow(
                  color: g.colors.last.withValues(alpha: 0.5),
                  blurRadius: 18,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: CareerText.cta
                    .copyWith(color: CareerColors.onLight, fontSize: 14, letterSpacing: 0.8),
              ),
              if (widget.icon != null) ...[
                const SizedBox(width: 8),
                Icon(widget.icon, size: 20, color: CareerColors.onLight),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
