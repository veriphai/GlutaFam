// The shared premium CTA pill used across Orbit Launcher (LAUNCH, TEST LAUNCH,
// TRY AGAIN, CONTINUE, LET'S BUILD IT). Gradient fill + coloured glow + a gentle
// idle pulse when enabled; greys out + stops pulsing when disabled.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';

class OrbitButton extends StatelessWidget {
  const OrbitButton({
    super.key,
    required this.label,
    required this.colors,
    required this.onTap,
    this.leadingIcon,
    this.trailingIcon,
    this.enabled = true,
    this.pulse = true,
    this.fontSize = 17,
  });

  final String label;
  final List<Color> colors;
  final VoidCallback onTap;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool enabled;
  final bool pulse;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    // Disabled = a bleached, translucent version of the button's OWN colours —
    // stays in-family with the panel instead of a clashing grey slab.
    final cols = enabled
        ? colors
        : [for (final c in colors) Color.lerp(c, Colors.white, 0.32)!.withValues(alpha: 0.55)];
    Widget w = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: cols),
        borderRadius: BorderRadius.circular(CareerRadii.pill),
        boxShadow: enabled
            ? [BoxShadow(color: cols.last.withValues(alpha: 0.55), blurRadius: 18, offset: const Offset(0, 6))]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: fontSize + 3, color: Colors.white.withValues(alpha: enabled ? 1 : 0.8)),
            const SizedBox(width: 9),
          ],
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CareerText.cta.copyWith(
                    color: Colors.white.withValues(alpha: enabled ? 1 : 0.8),
                    fontSize: fontSize,
                    letterSpacing: 0.6)),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 9),
            Icon(trailingIcon, size: fontSize + 3, color: Colors.white.withValues(alpha: enabled ? 1 : 0.8)),
          ],
        ],
      ),
    );

    if (enabled && pulse) {
      w = w.animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.03, duration: 950.ms, curve: Curves.easeInOut);
    }
    return PressableScale(onTap: enabled ? onTap : null, pressedScale: 0.97, child: w);
  }
}
