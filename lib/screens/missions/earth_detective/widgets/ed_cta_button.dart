// Primary call-to-action pill (gold reward accent) and a secondary cyan variant
// used across the Earth Detective scenes.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';

class EdCtaButton extends StatelessWidget {
  const EdCtaButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.gold = true,
    this.expand = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool gold;
  final bool expand;

  /// Gated CTAs (e.g. while Orbit is speaking) render dim AND block taps —
  /// dim-only is a UX trap (VO playbook).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final gradient = gold ? CareerGradients.gold : CareerGradients.heroBorder;
    final fg = gold ? CareerColors.onLight : Colors.white;
    return IgnorePointer(
      ignoring: !enabled,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1 : 0.55,
        child: _body(gradient, fg),
      ),
    );
  }

  Widget _body(Gradient gradient, Color fg) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(CareerRadii.pill),
          boxShadow: [
            BoxShadow(
              color: (gold ? CareerColors.gold : CareerColors.blue).withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
            ],
            Text(label, style: CareerText.cta.copyWith(color: fg, fontSize: 14, letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }
}
