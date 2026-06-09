// The dashed orbit path the satellite drifts along while waiting for range, with
// the communication-window slice highlighted brighter. Drawn programmatically so
// it matches the controller's orbit geometry exactly (same phase→point mapping).
// Fades in for the wait-for-range phase onward.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../config/signal_tuning.dart';

class OrbitPathComponent extends Component {
  OrbitPathComponent({required Vector2 stage}) : _stage = stage;

  final Vector2 _stage;
  double _opacity = 0;
  double _target = 0;

  void setVisible(bool v) => _target = v ? 1 : 0;

  Offset _pointAt(double phase) {
    final c = SRTune.orbitArcCenter;
    final a = phase * 2 * math.pi;
    final fx = c.dx + SRTune.orbitArcHalfWidth * math.sin(a);
    final fy = c.dy - SRTune.orbitArcRise * (1 - math.cos(a)) * 0.5;
    return Offset(fx * _stage.x, fy * _stage.y);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _opacity += (_target - _opacity) * (1 - math.pow(0.02, dt).toDouble());
  }

  @override
  void render(Canvas canvas) {
    if (_opacity < 0.02) return;
    const steps = 120;
    final dashPaint = Paint()
      ..color = const Color(0xFF8FB7FF).withValues(alpha: 0.5 * _opacity)
      ..strokeWidth = _stage.x * 0.006
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus;
    final winPaint = Paint()
      ..color = const Color(0xFF49E06B).withValues(alpha: 0.85 * _opacity)
      ..strokeWidth = _stage.x * 0.012
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, _stage.x * 0.006);

    for (var i = 0; i < steps; i++) {
      final p0 = i / steps;
      final p1 = (i + 0.55) / steps; // dashed (gap between segments)
      final inWindow = p0 >= SRTune.windowStart && p0 <= SRTune.windowEnd;
      canvas.drawLine(_pointAt(p0), _pointAt(p1), inWindow ? winPaint : dashPaint);
    }
  }
}
