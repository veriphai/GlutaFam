// Per-scenario repair timelines (PRD §16–22). Each `RepairKind` plays its
// distinct payoff using the standalone effect sprites (and a PROGRAMMATIC route
// for navigation, since the route sprites are whole islands). Calls [onComplete]
// when the payoff finishes so the game can advance.

import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart' show Icons;

import '../../config/asset_paths.dart';
import '../../config/scenarios.dart';
import '../components/problem_component.dart';
import '../restore_earth_game.dart';

class RepairEffects {
  RepairEffects._();

  static void play(
    RestoreEarthGame game,
    ProblemComponent problem,
    ScenarioDef scenario, {
    required VoidCallback onComplete,
  }) {
    problem.stopAlerts();
    final center = problem.absoluteCenter; // world space
    final ew = game.earth.worldWidth;

    switch (scenario.repairKind) {
      case RepairKind.route:
        _route(game, problem, center, ew, onComplete);
      case RepairKind.stormScan:
        game.spawnIcon(Icons.thunderstorm, center, ew * 0.22,
            color: const Color(0xFFB39BFF), lifetime: 0.9, scaleTo: 1.25);
        _burst(game, ew, delay: 0.6);
        game.runLater(1.2, onComplete);
      case RepairKind.broadcast:
        game.spawnIcon(Icons.wifi, center, ew * 0.22,
            color: const Color(0xFF8FE0FF), lifetime: 0.85, scaleTo: 1.25);
        _burst(game, ew, delay: 0.7);
        game.runLater(1.1, onComplete);
      case RepairKind.signalBars:
        game.spawnIcon(Icons.signal_cellular_alt_rounded, center, ew * 0.22,
            color: const Color(0xFF8FE0FF), lifetime: 0.85, scaleTo: 1.25);
        _burst(game, ew, delay: 0.7);
        game.runLater(1.1, onComplete);
      case RepairKind.cropScan:
        game.spawnIcon(Icons.eco_rounded, center, ew * 0.22,
            color: const Color(0xFF8BFF7A), lifetime: 0.9, scaleTo: 1.25);
        _burst(game, ew, delay: 0.7);
        game.runLater(1.1, onComplete);
      case RepairKind.floodScan:
        game.spawnIcon(Icons.water_rounded, center, ew * 0.22,
            color: const Color(0xFF6FB8FF), lifetime: 0.9, scaleTo: 1.25);
        _burst(game, ew, delay: 0.8);
        game.runLater(1.3, onComplete);
    }
  }

  // Location: ping wave → draw a glowing route → the vehicle turns and drives
  // visibly along it.
  static void _route(RestoreEarthGame game, ProblemComponent problem, Vector2 center,
      double ew, VoidCallback onComplete) {
    // Crisp location-pin icon instead of the generated GPS-rings sprite.
    game.spawnIcon(Icons.location_on, center, ew * 0.20,
        color: const Color(0xFF39D8FF), lifetime: 0.8, scaleTo: 1.25);

    // A clearly visible route up-and-inward across the zone.
    final end = center + Vector2(-ew * 0.13, -ew * 0.22);
    game.add(_RouteLine(start: center, end: end)..priority = 50);

    // Car turns toward the route (after it draws), then drives most of the way.
    final delta = (end - center) * 0.8;
    problem.object
      ..add(RotateEffect.to(-0.2, EffectController(duration: 0.3, startDelay: 0.45, curve: Curves.easeOut)))
      ..add(MoveEffect.by(delta,
          EffectController(duration: 0.85, startDelay: 0.6, curve: Curves.easeInOutCubic)));

    _burst(game, ew, delay: 1.2);
    game.runLater(1.7, onComplete);
  }

  // Green check, shown on the SIDE of the stage (upper-right) so it doesn't
  // clutter the object being repaired.
  static void _burst(RestoreEarthGame game, double ew, {double delay = 0}) {
    final at = Vector2(game.size.x * 0.84, game.size.y * 0.16);
    // Premium green-check badge sprite (reused from How Much Can You See).
    game.spawnEffect(RE.flame(RE.tickBadge), at, ew * 0.34,
        additive: false, scaleFrom: 0.5, scaleTo: 1.0, startDelay: delay, hold: 0.6, fadeOut: 0.4);
  }
}

/// A glowing path that draws itself in (progress 0→1) with an arrow head.
class _RouteLine extends PositionComponent {
  _RouteLine({required this.start, required this.end});

  final Vector2 start;
  final Vector2 end;
  double _progress = 0;

  @override
  Future<void> onLoad() async {
    add(_ProgressEffect(0.5, 0.1, (v) => _progress = v));
    add(RemoveEffect(delay: 3.0)); // route lingers, then clears
  }

  @override
  void render(Canvas canvas) {
    if (_progress <= 0.01) return;
    final p = Offset.lerp(start.toOffset(), end.toOffset(), _progress)!;
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start.toOffset(), p,
        paint..color = const Color(0xFF39D8FF).withValues(alpha: 0.30)..strokeWidth = 16);
    canvas.drawLine(start.toOffset(), p,
        paint..color = const Color(0xFFBDF0FF).withValues(alpha: 0.9)..strokeWidth = 5);
    // Arrow head at the leading point.
    canvas.drawCircle(p, 7, Paint()..blendMode = BlendMode.plus..color = const Color(0xFFFFFFFF));
  }
}

/// Drives a 0→1 value over [duration] after [delay] (no visual of its own).
class _ProgressEffect extends Component {
  _ProgressEffect(this.duration, this.delay, this.apply);
  final double duration;
  double delay;
  final void Function(double) apply;
  double _t = 0;
  @override
  void update(double dt) {
    if (delay > 0) {
      delay -= dt;
      return;
    }
    _t += dt;
    apply((_t / duration).clamp(0.0, 1.0));
    if (_t >= duration) removeFromParent();
  }
}
