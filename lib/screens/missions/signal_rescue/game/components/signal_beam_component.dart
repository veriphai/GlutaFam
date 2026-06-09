// The signal beam from the dish to the ground station. Drawn PROGRAMMATICALLY
// (the beam sprites in the pack are vertical-only) as a multi-pass additive line
// — wide soft glow + mid + bright core — tinted by signal state. weak flickers;
// noSignal is a broken, jittering dashed red. Owns its own colour easing so a
// state change crossfades rather than snaps.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../config/signal_tuning.dart';
import '../../state/signal_rescue_state.dart';

class SignalBeamComponent extends Component {
  SignalBeamComponent({required Vector2 stage}) : _stage = stage;

  final Vector2 _stage;

  final Vector2 start = Vector2.zero();
  final Vector2 end = Vector2.zero();
  SignalState _state = SignalState.noSignal;
  bool _visible = false;
  double _t = 0;
  Color _color = SRTune.beamColor(SignalState.noSignal);

  void setState(SignalState s) => _state = s;
  void setVisible(bool v) => _visible = v;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    // ease the colour toward the state colour
    final target = SRTune.beamColor(_state);
    _color = Color.lerp(_color, target, (1 - math.pow(0.0015, dt).toDouble()))!;
  }

  @override
  void render(Canvas canvas) {
    if (!_visible) return;
    if (start.distanceTo(end) < 1) return;

    final base = _stage.x;
    final flicker = switch (_state) {
      SignalState.noSignal => 0.35 + 0.45 * (math.sin(_t * 30).abs()),
      SignalState.weak => 0.55 + 0.25 * (0.5 + 0.5 * math.sin(_t * 14)),
      SignalState.strong => 0.85 + 0.1 * (0.5 + 0.5 * math.sin(_t * 6)),
      SignalState.locked => 0.95,
    };

    if (_state == SignalState.noSignal) {
      _renderBroken(canvas, base, flicker);
      return;
    }

    final core = base * (_state == SignalState.locked ? 0.018 : 0.013);
    final mid = core * 2.6;
    final glow = core * 6.0;

    // outer glow
    _stroke(canvas, glow, _color.withValues(alpha: 0.18 * flicker), blur: glow * 0.8);
    // mid
    _stroke(canvas, mid, _color.withValues(alpha: 0.40 * flicker), blur: mid * 0.5);
    // bright core
    _stroke(canvas, core, _color.withValues(alpha: 0.95 * flicker));
    // white-hot centre line for strong/locked
    if (_state == SignalState.strong || _state == SignalState.locked) {
      _stroke(canvas, core * 0.45,
          const Color(0xFFFFFFFF).withValues(alpha: 0.8 * flicker));
    }
  }

  void _stroke(Canvas canvas, double width, Color color, {double blur = 0}) {
    final p = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus;
    if (blur > 0) p.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    canvas.drawLine(Offset(start.x, start.y), Offset(end.x, end.y), p);
  }

  void _renderBroken(Canvas canvas, double base, double flicker) {
    final dir = (end - start);
    final len = dir.length;
    final n = dir.normalized();
    final perp = Vector2(-n.y, n.x);
    const dash = 16.0;
    const gap = 12.0;
    final core = base * 0.011;
    var d = 0.0;
    final rnd = math.Random(7);
    while (d < len) {
      final d2 = math.min(d + dash, len);
      final jitter = perp * (rnd.nextDouble() - 0.5) * base * 0.03 * flicker;
      final a = start + n * d + jitter;
      final b = start + n * d2 + jitter;
      final p = Paint()
        ..color = _color.withValues(alpha: 0.85 * flicker)
        ..strokeWidth = core
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.plus
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, core);
      canvas.drawLine(Offset(a.x, a.y), Offset(b.x, b.y), p);
      d += dash + gap;
    }
  }
}
