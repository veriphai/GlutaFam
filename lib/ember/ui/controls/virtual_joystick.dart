// Ember — ui/controls/virtual_joystick.dart
//
// A self-rolled analog VIRTUAL JOYSTICK (no pub package): a draggable knob inside
// a fixed ring, docked bottom-left over the transparent GameWidget. While the
// player's finger is down inside the ring it emits a continuous 0..1 direction
// vector ([onChanged]) every frame the finger moves; on release it eases the knob
// back to center (floaty return) and emits Vector2.zero.
//
// SAME-FRAME drive (the quality bar): the vector is reported on every pointer
// move, so the PlayerComponent it feeds answers in the same render frame the
// finger drives — the knob IS the value. The visual polish (pressable scale +
// floaty spring-back) is decorative ONLY: it never lags the reported vector (we
// report the RAW finger offset, not the eased knob position), so control stays
// 1:1 even while the knob animates home.
//
// Pure presentation/input: it owns no world state, dispatches no Intents — it
// hands a normalized vector to its owner (world_screen), which routes it into the
// game. disableAnimations stills the spring-back (the knob snaps home) — never the
// live drive.
//
// Coordinate space: the emitted vector is SCREEN-space (x right, y DOWN, the
// Flutter convention), magnitude 0..1. The game maps it through the iso
// projection so "up on the stick" walks up-screen on the diamond grid.

import 'dart:math' as math;

import 'package:flame/components.dart' show Vector2;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;

import '../../art/ember_palette.dart';

/// A draggable analog joystick. Reports a normalized [Vector2] (screen-space, y
/// down) in 0..1 magnitude while dragged; Vector2.zero when released.
class VirtualJoystick extends StatefulWidget {
  const VirtualJoystick({
    super.key,
    required this.onChanged,
    required this.palette,
    this.size = 132.0,
    this.knobSize = 56.0,
  });

  /// Called every time the direction vector changes (including the zero on
  /// release). Screen-space, y-down, magnitude clamped to 0..1.
  final void Function(Vector2 direction) onChanged;

  final EmberPalette palette;

  /// Diameter of the outer ring (the draggable field).
  final double size;

  /// Diameter of the knob.
  final double knobSize;

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick>
    with SingleTickerProviderStateMixin {
  /// The knob's current visual offset from center (px), used for drawing. The
  /// REPORTED vector uses the raw finger offset, so drawing easing never lags it.
  ///
  /// DEFECT B FIX: knob + active state are published to the painter through a
  /// [ValueNotifier] (the painter repaints by listening to it), NOT through
  /// setState. setState would markNeedsBuild on every pointer-move + every
  /// spring-back tick — and because this widget is now kept MOUNTED across the
  /// activity transition (Offstage, not if-removal, defect A), a stray nudge
  /// while an activity is mid-build was firing the "setState()/markNeedsBuild()
  /// called during build" storm. Repainting a CustomPaint via a Listenable
  /// `repaint` never schedules a build, so it is build-phase-safe.
  final ValueNotifier<_KnobState> _paint =
      ValueNotifier<_KnobState>(const _KnobState(Offset.zero, false));

  /// Mirror of [_paint] for the gesture math (cheap local read; the notifier is
  /// the source of truth the painter watches).
  Offset _knob = Offset.zero;
  bool _active = false;

  /// Spring-back ticker (eases [_knob] -> zero on release; the reported vector is
  /// already zero by then, so this is purely cosmetic floaty return).
  ///
  /// DEFECT A FIX: the ticker is constructed EAGERLY in [initState] (not via a
  /// `late final` lazy initializer). A lazy initializer would run
  /// `createTicker(...)` on FIRST access — and the first access could be from
  /// [dispose] (if no finger ever touched the stick), which constructs a Ticker
  /// → does a TickerMode InheritedWidget ancestor lookup on an already-
  /// deactivated element → "Looking up a deactivated widget's ancestor is
  /// unsafe". Eager construction guarantees the ticker already exists by the time
  /// dispose runs, so dispose only ever TEARS DOWN — it never CONSTRUCTS.
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  /// True once [dispose] has run. A pointer event (e.g. a PointerCancel synthesised
  /// during teardown / a navigation away from the world) can still be dispatched to
  /// this widget's [Listener] AFTER the State is disposed — those handlers must not
  /// touch the now-disposed [_paint] notifier. Guarding on this flag turns that race
  /// into a no-op instead of a "ValueNotifier used after being disposed" throw.
  bool _disposed = false;

  /// Max travel of the knob from center.
  double get _radius => (widget.size - widget.knobSize) / 2;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker.dispose();
    _paint.dispose();
    super.dispose();
  }

  /// Push the current knob/active state to the painter notifier. Pure repaint —
  /// never schedules a build. No-op once disposed (a late pointer event could call
  /// in after teardown).
  void _repaint() {
    if (_disposed) return;
    _paint.value = _KnobState(_knob, _active);
  }

  void _onTick(Duration elapsed) {
    final double dt =
        ((elapsed - _lastTick).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastTick = elapsed;
    // Exp approach home (tau ~90ms) — the floaty return.
    final double k = 1 - math.exp(-dt / 0.09);
    final Offset next = Offset.lerp(_knob, Offset.zero, k) ?? Offset.zero;
    _knob = next;
    if (next.distance < 0.5) {
      _knob = Offset.zero;
      _ticker.stop();
    }
    _repaint();
  }

  /// Convert a local pointer position (relative to the ring's top-left) to a
  /// clamped knob offset from center, and report the normalized direction.
  void _drive(Offset local) {
    final Offset center = Offset(widget.size / 2, widget.size / 2);
    Offset delta = local - center;
    final double dist = delta.distance;
    if (dist > _radius) {
      delta = delta * (_radius / dist); // clamp travel to the ring.
    }
    _knob = delta;
    // Report the RAW (pre-clamp-normalized) direction at 0..1 magnitude, so the
    // drive is 1:1 with the finger even while the knob is pinned at the rim. The
    // vector is pushed straight to the owner (which sets a plain game field) in
    // this GESTURE callback — never during build (defect B).
    final double mag = (dist / _radius).clamp(0.0, 1.0);
    final Vector2 dir = dist <= 0.0001
        ? Vector2.zero()
        : (Vector2(delta.dx, delta.dy)..normalize()) * mag;
    widget.onChanged(dir);
    _repaint();
  }

  void _onStart(Offset local) {
    if (_disposed) return;
    _ticker.stop();
    _active = true;
    _drive(local);
  }

  void _onUpdate(Offset local) {
    if (_disposed || !_active) return;
    _drive(local);
  }

  void _onEnd() {
    if (_disposed) return;
    _active = false;
    widget.onChanged(Vector2.zero());
    // Floaty spring-back unless the platform asks for reduced motion.
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _knob = Offset.zero;
      _repaint();
    } else {
      _lastTick = Duration.zero;
      _repaint(); // reflect the released (inactive) state immediately.
      _ticker.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final EmberPalette p = widget.palette;

    // The press-scale + knob repaint are both driven off [_paint] via the
    // AnimatedBuilder, so a finger drive / spring-back tick repaints WITHOUT
    // marking this element (or its ancestors) for a build (defect B).
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (PointerDownEvent e) => _onStart(e.localPosition),
      onPointerMove: (PointerMoveEvent e) => _onUpdate(e.localPosition),
      onPointerUp: (PointerUpEvent e) => _onEnd(),
      onPointerCancel: (PointerCancelEvent e) => _onEnd(),
      child: ValueListenableBuilder<_KnobState>(
        valueListenable: _paint,
        builder: (BuildContext context, _KnobState s, Widget? _) {
          return AnimatedScale(
            scale: s.active ? 1.06 : 1.0,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _JoystickPainter(
                knob: s.knob,
                knobSize: widget.knobSize,
                active: s.active,
                palette: p,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The painter inputs the joystick publishes per frame (knob offset + driven
/// flag). An immutable value so the [ValueNotifier] only fires on real changes.
@immutable
class _KnobState {
  const _KnobState(this.knob, this.active);
  final Offset knob;
  final bool active;

  @override
  bool operator ==(Object other) =>
      other is _KnobState && other.knob == knob && other.active == active;

  @override
  int get hashCode => Object.hash(knob, active);
}

class _JoystickPainter extends CustomPainter {
  _JoystickPainter({
    required this.knob,
    required this.knobSize,
    required this.active,
    required this.palette,
  });

  final Offset knob;
  final double knobSize;
  final bool active;
  final EmberPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double ringR = size.width / 2;

    // Outer ring: a soft sunken field.
    canvas.drawCircle(
      center,
      ringR,
      Paint()..color = palette.surface.withValues(alpha: active ? 0.55 : 0.40),
    );
    canvas.drawCircle(
      center,
      ringR,
      Paint()
        ..color = palette.outline.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Faint directional ticks (N/E/S/W) so the affordance reads as a stick.
    final Paint tick = Paint()
      ..color = palette.inkSoft.withValues(alpha: 0.45)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const double tin = 0.74;
    const double tout = 0.92;
    for (final double a in <double>[0, math.pi / 2, math.pi, 3 * math.pi / 2]) {
      final Offset d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(center + d * (ringR * tin), center + d * (ringR * tout), tick);
    }

    // Knob: a lit ember disc that brightens while driven.
    final Offset kc = center + knob;
    final double kr = knobSize / 2;
    if (active) {
      // A soft glow under the knob while driving (the live-feel).
      canvas.drawCircle(
        kc,
        kr * 1.5,
        Paint()
          ..color = palette.ember.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    canvas.drawCircle(
      kc,
      kr,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Color.lerp(palette.emberBright, const Color(0xFFFFFFFF), 0.25)!,
            palette.ember,
            palette.emberDeep,
          ],
          stops: const <double>[0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: kc, radius: kr)),
    );
    canvas.drawCircle(
      kc,
      kr,
      Paint()
        ..color = palette.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Specular pip (upper-left key light).
    canvas.drawCircle(
      kc + Offset(-kr * 0.3, -kr * 0.3),
      kr * 0.28,
      Paint()..color = palette.spark.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(_JoystickPainter old) =>
      old.knob != knob || old.active != active || old.palette != palette;
}
