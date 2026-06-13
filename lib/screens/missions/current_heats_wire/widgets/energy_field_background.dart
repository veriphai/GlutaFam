// The Hot Wire — local energy-field background (the shipped house style, copied
// in-module per convention so the activity stays self-contained). A calm deep cool
// dark that RECEDES so the wire's warm glow blooms against it; the darkest point
// sits behind the wire midspan, and a whisper-faint circuit texture ties the
// screen to the deck. A faint warm response spills into the field while the wire
// is hot — gated on wireTemp; it eases off with the real thermal decay, never a
// gimmick fade.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/heat_wire_controller.dart';

const Color _ink900 = Color(0xFF0B1026); // edges
const Color _heroDark = Color(0xFF070A1C); // near-black behind the wire midspan
const Color _indigo = Color(0xFF161D3A); // faint lift up top

/// The wire midspan (diagonal sag), in screen-space alignment — the vignette
/// darkens here and the warm response blooms here. With the diagonal span the sag
/// sits just below screen centre (≈0.51·H → alignment.y ≈ 0.02).
const Alignment _heroFocus = Alignment(0.0, 0.02);

class EnergyFieldBackground extends StatefulWidget {
  const EnergyFieldBackground({super.key, required this.controller});

  final HeatWireController controller;

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
        // Deep vignette — darkest right behind the diagonal midspan so the hot
        // wire blooms against the near-black. A second tighter well deepens the core.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: _heroFocus,
                radius: 1.15,
                colors: [_heroDark, Color(0x00070A1C)],
                stops: [0, 0.62],
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: _heroFocus,
                radius: 0.62,
                colors: [Color(0xCC04060E), Color(0x0004060E)],
                stops: [0, 1],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _drift,
            builder: (context, _) => CustomPaint(
              painter: _FieldPainter(drift: _reduced ? 0 : _drift.value),
            ),
          ),
        ),
        // Warm response — the wire's heat faintly spills into the field while it
        // is hot. Gated on wireTemp; eases off with the real thermal decay.
        Positioned.fill(
          child: AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) {
              final t = widget.controller.wireTemp;
              if (t <= 0.01) return const SizedBox.shrink();
              return IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: _heroFocus,
                      radius: 1.0,
                      colors: [
                        const Color(0xFFFF7A2E).withValues(alpha: 0.13 * t),
                        const Color(0x00FF7A2E),
                      ],
                      stops: const [0, 0.7],
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
/// pattern (~5–9% opacity). Cool, far below the hero in brightness.
class _FieldPainter extends CustomPainter {
  _FieldPainter({required this.drift});
  final double drift;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

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
