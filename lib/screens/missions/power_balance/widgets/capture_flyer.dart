// Capture animation (PRD §18 "captured thumbnail flies gently to the Images
// counter"). When a capture fires (captureToken bumps), the cyclone photo pops
// big at centre, holds for a beat, then shrinks and flies to the top-right
// IMAGES counter. Pure overlay — never blocks input.

import 'package:flutter/material.dart';

import '../config/asset_paths.dart';
import 'pb_palette.dart';
import '../../../../utils/s3_assets.dart';

class CaptureFlyer extends StatefulWidget {
  const CaptureFlyer({super.key, required this.token});

  /// The mission state's captureToken (bumps once per capture). Image index =
  /// token-1 (1st capture → photo 0).
  final int token;

  @override
  State<CaptureFlyer> createState() => _CaptureFlyerState();
}

class _CaptureFlyerState extends State<CaptureFlyer> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  int _index = 0;

  @override
  void didUpdateWidget(covariant CaptureFlyer old) {
    super.didUpdateWidget(old);
    if (widget.token != old.token && widget.token > 0) {
      _index = widget.token - 1;
      _c.forward(from: 0);
    }
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
          return LayoutBuilder(builder: (context, cons) {
            final w = cons.maxWidth, h = cons.maxHeight;
            final centre = Offset(w * 0.5, h * 0.40);
            final target = Offset(w * 0.80, h * 0.105); // the IMAGES counter
            const card = 200.0;

            double scale, opacity;
            Offset pos;
            if (t < 0.16) {
              final p = t / 0.16;
              scale = 0.6 + 0.4 * Curves.easeOutBack.transform(p);
              opacity = p.clamp(0.0, 1.0);
              pos = centre;
            } else if (t < 0.50) {
              scale = 1.0;
              opacity = 1;
              pos = centre;
            } else if (t < 0.92) {
              final e = Curves.easeInOutCubic.transform((t - 0.50) / 0.42);
              scale = 1.0 - 0.84 * e; // → 0.16
              pos = Offset.lerp(centre, target, e)!;
              opacity = 1;
            } else {
              scale = 0.16;
              pos = target;
              opacity = 1 - (t - 0.92) / 0.08;
            }

            return Stack(
              children: [
                Positioned(
                  left: pos.dx - card / 2,
                  top: pos.dy - card / 2,
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Transform.scale(scale: scale, child: _photoCard(card)),
                  ),
                ),
              ],
            );
          });
        },
      ),
    );
  }

  Widget _photoCard(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PBPalette.skyBlue.withValues(alpha: 0.9), width: 3),
        boxShadow: [BoxShadow(color: PBPalette.skyBlue.withValues(alpha: 0.55), blurRadius: 26)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            netImageWidget(PB.flutter(PB.capturedImage(_index)),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: PBPalette.deepSpace)),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                color: PBPalette.deepSpace.withValues(alpha: 0.7),
                child: Text('CYCLONE CAPTURED',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: PBPalette.skyBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
