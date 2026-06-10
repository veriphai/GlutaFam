// The energy-field background (polish spec §1). Replaces the generic starfield:
// a calm, deep cool dark that RECEDES so the hero's warm light blooms against
// it. The darkest point sits right where the device's light appears, and a
// whisper-faint circuit texture (the same vernacular as the card guilloché)
// ties the screen to the deck. Optionally lifts a touch warmer where the hero
// glows while current flows.
//
// The boldness is spent on the hero, not here — this layer's whole job is to be
// quiet. Reduced motion → the motes hold still.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/crank_controller.dart';

const Color _ink900 = Color(0xFF0B1026); // edges
const Color _heroDark = Color(0xFF070A1C); // near-black behind the hero
const Color _indigo = Color(0xFF161D3A); // faint lift up top

/// Screen-space focal point of the hero's light (≈ the device), as a factor of
/// the full screen — the vignette darkens here and the warm response blooms here.
const Alignment _heroFocus = Alignment(0.32, 0.18);

class EnergyFieldBackground extends StatefulWidget {
  const EnergyFieldBackground({super.key, required this.controller});

  final CrankController controller;

  @override
  State<EnergyFieldBackground> createState() => _EnergyFieldBackgroundState();
}

class _EnergyFieldBackgroundState extends State<EnergyFieldBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift =
      AnimationController(vsync: this, duration: const Duration(seconds: 24));

  bool get _reduced => MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_reduced && !_drift.isAnimating) {
      _drift.repeat();
    } else if (_reduced && _drift.isAnimating) {
      _drift.stop();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1) Base: indigo lift up top → ink-900 body.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_indigo, _ink900, _ink900],
                stops: [0, 0.55, 1],
              ),
            ),
          ),
        ),
        // 2) Vignette toward the hero — the darkest point is where light appears.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: _heroFocus,
                radius: 1.1,
                colors: [_heroDark, Color(0x00070A1C)],
                stops: [0, 0.6],
              ),
            ),
          ),
        ),
        // 3) Whisper-faint circuit texture + dim drifting motes.
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _drift,
            builder: (context, _) => CustomPaint(
              painter: _FieldPainter(drift: _reduced ? 0 : _drift.value),
            ),
          ),
        ),
        // 4) Warm response — the hero's bloom faintly spills into the field
        //    while current flows (gated on brightness; snaps off on stop).
        Positioned.fill(
          child: AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) {
              final b = widget.controller.brightness;
              if (b <= 0.01) return const SizedBox.shrink();
              return IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: _heroFocus,
                      radius: 1.0,
                      colors: [
                        const Color(0xFFFFE9B8).withValues(alpha: 0.16 * b),
                        const Color(0x00FFE9B8),
                      ],
                      stops: const [0, 0.75],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Faint PCB-like field lines + node dots + a few dim motes — texture, not
/// pattern (~5% opacity). Cool, far below the hero in brightness.
class _FieldPainter extends CustomPainter {
  _FieldPainter({required this.drift});
  final double drift; // 0..1 slow phase for mote drift

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Field lines: a sparse grid of right-angle traces with solder nodes.
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF3A4A78).withValues(alpha: 0.07);
    final node = Paint()..color = const Color(0xFF4A5C92).withValues(alpha: 0.09);
    final rnd = math.Random(7);
    for (var i = 0; i < 9; i++) {
      final y = h * (0.08 + 0.1 * i) + rnd.nextDouble() * 14;
      final x0 = w * rnd.nextDouble() * 0.5;
      final x1 = x0 + w * (0.25 + rnd.nextDouble() * 0.4);
      final bend = x0 + (x1 - x0) * (0.4 + rnd.nextDouble() * 0.2);
      final dy = (rnd.nextBool() ? 1 : -1) * h * 0.05;
      final path = Path()
        ..moveTo(x0, y)
        ..lineTo(bend, y)
        ..lineTo(bend, y + dy)
        ..lineTo(x1, y + dy);
      canvas.drawPath(path, line);
      canvas.drawCircle(Offset(x0, y), 2, node);
      canvas.drawCircle(Offset(x1, y + dy), 2, node);
    }

    // Dim energy motes — sparse, dim, barely drifting.
    final mote = Paint();
    final mr = math.Random(31);
    for (var i = 0; i < 18; i++) {
      final bx = mr.nextDouble();
      final by = (mr.nextDouble() + drift * (0.2 + mr.nextDouble() * 0.3)) % 1.0;
      final warm = i.isEven;
      final c = warm ? const Color(0xFFE8C98A) : const Color(0xFF8FA8E0);
      final a = 0.05 + 0.06 * mr.nextDouble();
      canvas.drawCircle(Offset(bx * w, by * h), 1.0 + mr.nextDouble() * 1.1,
          mote..color = c.withValues(alpha: a));
    }
  }

  @override
  bool shouldRepaint(_FieldPainter old) => old.drift != drift;
}
