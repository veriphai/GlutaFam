// Small always-on idle motions used inside mission scenes. Each owns its own
// ticker so motion continues even when no other animation is running. (Floaty,
// the up/down bob, is reused from careerCommon.)

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Continuously rotates [child] at [period] per turn. Used for the tracked
/// cyclone (PRD §15.2). When [active] is false the child is returned untouched.
class Spinning extends StatefulWidget {
  const Spinning({
    super.key,
    required this.child,
    this.active = true,
    this.period = const Duration(seconds: 14),
    this.clockwise = true,
  });

  final Widget child;
  final bool active;
  final Duration period;
  final bool clockwise;

  @override
  State<Spinning> createState() => _SpinningState();
}

class _SpinningState extends State<Spinning> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.rotate(
        angle: _c.value * 2 * math.pi * (widget.clockwise ? 1 : -1),
        child: child,
      ),
      child: widget.child,
    );
  }
}
