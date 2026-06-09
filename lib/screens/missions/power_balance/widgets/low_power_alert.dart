// Premium "systems shutting down" alert — pops when the battery first drops
// below the low threshold, holds for ~2s, then fades. Pure overlay, never blocks
// input. Driven by the state's lowPowerAlertToken.

import 'package:flutter/material.dart';

import '../config/asset_paths.dart';
import '../config/power_balance_tuning.dart';
import 'pb_palette.dart';

class LowPowerAlert extends StatefulWidget {
  const LowPowerAlert({super.key, required this.token});

  final int token;

  @override
  State<LowPowerAlert> createState() => _LowPowerAlertState();
}

class _LowPowerAlertState extends State<LowPowerAlert> with SingleTickerProviderStateMixin {
  // ~2s on screen: scale/fade in, hold, fade out.
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2100));

  @override
  void didUpdateWidget(covariant LowPowerAlert old) {
    super.didUpdateWidget(old);
    if (widget.token != old.token && widget.token > 0) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          if (t == 0 || t >= 1) return const SizedBox.shrink();
          final op = (t < 0.1 ? t / 0.1 : (t > 0.86 ? 1 - (t - 0.86) / 0.14 : 1.0)).clamp(0.0, 1.0);
          final scale = t < 0.12 ? 0.88 + 0.12 * Curves.easeOutBack.transform(t / 0.12) : 1.0;
          return Center(
            child: Opacity(
              opacity: op,
              child: Transform.scale(scale: scale, child: _panel()),
            ),
          );
        },
      ),
    );
  }

  Widget _panel() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xF22A0B10), Color(0xF2160609)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: PBPalette.warningRed.withValues(alpha: 0.9), width: 1.6),
          boxShadow: [
            BoxShadow(color: PBPalette.warningRed.withValues(alpha: 0.5), blurRadius: 28, spreadRadius: 1),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                pbImage(PB.flutter(PB.powerWarningBadge), width: 40, height: 40),
                const SizedBox(width: 10),
                Text(PBTune.lowPowerAlertTitle,
                    style: TextStyle(
                      color: PBPalette.warningRed,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      shadows: [Shadow(color: PBPalette.warningRed.withValues(alpha: 0.6), blurRadius: 10)],
                    )),
              ],
            ),
            const SizedBox(height: 12),
            Text(PBTune.lowPowerAlertBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12.5, height: 1.3, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
