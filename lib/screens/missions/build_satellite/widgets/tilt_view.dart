// Fake-3D tilt for a flat sprite stage.
//
// The satellite art is a single-angle 2D render, so we can't truly orbit it.
// This applies a subtle perspective transform (idle sway + drag-to-tilt that
// springs back) to make it FEEL like a solid object floating in space.
//
// Kept deliberately small (~±10°): the child is the Flame GameWidget, and drop
// coordinates are mapped through this transform, so a gentle tilt keeps slot
// detection accurate (the generous hit radius absorbs the minor offset).
//
// Reusable: drop any widget in as [child].

import 'dart:math' as math;

import 'package:flutter/material.dart';

class TiltView extends StatefulWidget {
  const TiltView({
    super.key,
    required this.child,
    this.maxTilt = 0.18, // radians (~10°) for drag
    this.idleAmplitude = 0.028, // radians (~1.6°) idle sway
    this.sensitivity = 0.005, // radians per logical px dragged
  });

  final Widget child;
  final double maxTilt;
  final double idleAmplitude;
  final double sensitivity;

  @override
  State<TiltView> createState() => _TiltViewState();
}

class _TiltViewState extends State<TiltView> with SingleTickerProviderStateMixin {
  // Always-running driver: rebuilds only the Transform (the child is passed
  // through AnimatedBuilder and never rebuilt — important: don't re-create the
  // Flame GameWidget every frame).
  late final AnimationController _driver =
      AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat();

  Offset _drag = Offset.zero; // drag-induced tilt (radians): dx=yaw, dy=pitch
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    // Spring the drag tilt back to neutral each frame when not dragging.
    _driver.addListener(() {
      if (!_dragging && _drag != Offset.zero) {
        _drag = Offset.lerp(_drag, Offset.zero, 0.10)!;
        if (_drag.distance < 0.0008) _drag = Offset.zero;
      }
    });
  }

  @override
  void dispose() {
    _driver.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails _) => _dragging = true;

  void _onPanUpdate(DragUpdateDetails d) {
    _drag = Offset(
      (_drag.dx + d.delta.dx * widget.sensitivity).clamp(-widget.maxTilt, widget.maxTilt),
      (_drag.dy + d.delta.dy * widget.sensitivity).clamp(-widget.maxTilt, widget.maxTilt),
    );
  }

  void _onPanEnd(DragEndDetails _) => _dragging = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: () => _dragging = false,
      child: AnimatedBuilder(
        animation: _driver,
        child: widget.child,
        builder: (context, child) {
          final t = _driver.value * 2 * math.pi;
          // Gentle figure-eight idle sway.
          final idleYaw = math.sin(t) * widget.idleAmplitude;
          final idlePitch = math.cos(t * 0.8) * widget.idleAmplitude * 0.6;

          final yaw = (idleYaw + _drag.dx).clamp(-widget.maxTilt, widget.maxTilt);
          final pitch = (idlePitch - _drag.dy).clamp(-widget.maxTilt, widget.maxTilt);

          final m = Matrix4.identity()
            ..setEntry(3, 2, 0.0012) // perspective depth
            ..rotateX(pitch)
            ..rotateY(yaw);
          return Transform(
            alignment: Alignment.center,
            transform: m,
            child: child,
          );
        },
      ),
    );
  }
}
