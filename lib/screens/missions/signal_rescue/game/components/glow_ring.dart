// A clean, canvas-drawn glowing ring (no sprite). Reused for both the antenna
// rotation hint (cyan, with rotating chevrons) and the ground-station range ring
// (green, pulsing, no chevrons). Fades in/out via show().

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

class GlowRing extends PositionComponent {
  GlowRing({
    required this.radius,
    required this.color,
    this.chevrons = false,
    this.pulse = false,
    this.spinSpeed = 0.7,
  });

  final double radius;
  final Color color;
  final bool chevrons;
  final bool pulse;
  final double spinSpeed;

  double _opacity = 0;
  double _target = 0;
  double _spin = 0;
  double _t = 0;

  void show(bool v) => _target = v ? 1 : 0;

  @override
  void update(double dt) {
    super.update(dt);
    _opacity += (_target - _opacity) * (1 - math.pow(0.02, dt).toDouble());
    _spin += dt * spinSpeed;
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    if (_opacity < 0.02) return;
    final pulseF = pulse ? (0.5 + 0.5 * math.sin(_t * 4.5)) : 1.0;
    final r = pulse ? radius * (0.95 + 0.06 * pulseF) : radius;
    final op = _opacity * (pulse ? (0.72 + 0.28 * pulseF) : 1.0);

    // soft outer glow
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.10
        ..color = color.withValues(alpha: 0.30 * op)
        ..blendMode = BlendMode.plus
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.08),
    );
    // crisp inner ring
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.035
        ..color = color.withValues(alpha: 0.85 * op)
        ..blendMode = BlendMode.plus,
    );

    if (chevrons) {
      for (var i = 0; i < 3; i++) {
        _chevron(canvas, _spin + i * (2 * math.pi / 3), r, op);
      }
    }
  }

  void _chevron(Canvas canvas, double a, double r, double op) {
    final p = Offset(r * math.cos(a), r * math.sin(a));
    final tangent = Offset(-math.sin(a), math.cos(a)); // CW direction
    final normal = Offset(math.cos(a), math.sin(a));
    final s = r * 0.18;
    final tip = p + tangent * s;
    final w1 = p - tangent * (s * 0.2) + normal * (s * 0.7);
    final w2 = p - tangent * (s * 0.2) - normal * (s * 0.7);
    canvas.drawPath(
      Path()
        ..moveTo(w1.dx, w1.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(w2.dx, w2.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.06
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.95 * op)
        ..blendMode = BlendMode.plus,
    );
  }
}
