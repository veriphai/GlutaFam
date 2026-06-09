// The flight trajectory drawn as a glowing dashed curve (matching the reference
// mockup's dashed-arc language). Self-draws up to [progress] as the satellite
// rides it; also used as a faint static preview while the slider moves.
//
// Drawn programmatically (the proven restore_earth route pattern) rather than
// with the path-arc sprites, so orientation/length/colour follow the live
// geometry and the dashes can animate with the satellite.

import 'dart:ui';

import 'package:flame/components.dart';

class TrajectoryComponent extends Component {
  List<Vector2> _points = const [];
  List<double> _cum = const [0]; // cumulative arc length per point
  double _total = 0;

  double progress = 0; // 0..1 of the polyline revealed
  Color color = const Color(0xFFFFFFFF);
  double opacity = 1;
  double dash = 13;
  double gap = 9;
  double coreWidth = 4.5;

  TrajectoryComponent() {
    priority = 40;
  }

  void setPath(List<Vector2> pts) {
    _points = pts;
    final cum = <double>[0];
    var total = 0.0;
    for (var i = 1; i < pts.length; i++) {
      total += pts[i].distanceTo(pts[i - 1]);
      cum.add(total);
    }
    _cum = cum;
    _total = total;
  }

  void clear() {
    _points = const [];
    _cum = const [0];
    _total = 0;
    progress = 0;
  }

  bool get hasPath => _points.length >= 2 && _total > 0;

  /// Point at fraction [f] (0..1) along the whole path — used to drive the
  /// satellite in lock-step with the revealed dashes.
  Vector2 pointAtFraction(double f) => _pointAt(_total * f.clamp(0.0, 1.0));

  Vector2 _pointAt(double s) {
    if (_points.isEmpty) return Vector2.zero();
    if (s <= 0) return _points.first;
    if (s >= _total) return _points.last;
    // binary-ish linear walk (paths are short, a few hundred pts max)
    var i = 1;
    while (i < _cum.length && _cum[i] < s) {
      i++;
    }
    final segLen = _cum[i] - _cum[i - 1];
    final f = segLen <= 0 ? 0.0 : (s - _cum[i - 1]) / segLen;
    return _points[i - 1] + (_points[i] - _points[i - 1]) * f;
  }

  @override
  void render(Canvas canvas) {
    if (!hasPath || opacity <= 0) return;
    final revealLen = (_total * progress).clamp(0.0, _total);

    final glow = Paint()
      ..blendMode = BlendMode.plus
      ..strokeCap = StrokeCap.round
      ..strokeWidth = coreWidth * 2.8
      ..color = color.withValues(alpha: 0.22 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final core = Paint()
      ..blendMode = BlendMode.plus
      ..strokeCap = StrokeCap.round
      ..strokeWidth = coreWidth
      ..color = color.withValues(alpha: 0.95 * opacity);

    final step = dash + gap;
    for (var s = 0.0; s < revealLen; s += step) {
      final a = _pointAt(s);
      final b = _pointAt((s + dash).clamp(0.0, revealLen));
      final ao = a.toOffset();
      final bo = b.toOffset();
      canvas.drawLine(ao, bo, glow);
      canvas.drawLine(ao, bo, core);
    }
  }
}
