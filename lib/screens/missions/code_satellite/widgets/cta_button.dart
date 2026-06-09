// Reusable CTA pill (Start Mission / Run Mission / Reorder / Play Again / Next).
// Gold energy gradient by default; pass colors to recolour. Disabled state dims
// and ignores taps.

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../config/code_satellite_tuning.dart';

class CtaButton extends StatelessWidget {
  const CtaButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.colors = const [Color(0xFFFFD25E), Color(0xFFFFB020)],
    this.enabled = true,
    this.dark = true,
    this.height = 58,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final List<Color> colors;
  final bool enabled;
  final bool dark; // dark text (on gold) vs white text
  final double height;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? const Color(0xFF1A1340) : Colors.white;
    final body = Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Container(
        height: height,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.4),
          boxShadow: enabled
              ? [BoxShadow(color: colors.last.withValues(alpha: 0.5), blurRadius: 18, spreadRadius: 0.5)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    color: fg, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
            const SizedBox(width: 10),
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dark ? const Color(0xFF1A1340) : Colors.white.withValues(alpha: 0.2),
              ),
              child: Icon(icon, size: 19, color: dark ? CSColors.yellow : Colors.white),
            ),
          ],
        ),
      ),
    );
    return PressableScale(onTap: enabled ? onTap : null, child: body);
  }
}
