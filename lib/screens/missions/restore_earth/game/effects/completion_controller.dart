// Mission-complete choreography: coloured beams draw from the satellite to every
// zone (Earth fully connected) and stay lit, a burst blooms, and the Junior
// Satellite Engineer badge reveals over the diorama. The mission-panel celebrate
// text + Next Mission CTA are handled by the Flutter shell.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

import '../../config/asset_paths.dart';
import '../../config/earth_layout.dart';
import '../restore_earth_game.dart';

// One colour per zone beam.
const List<Color> _beamColors = [
  Color(0xFF39D8FF), // cyan
  Color(0xFF8B5CFF), // purple
  Color(0xFFFFB23D), // orange
  Color(0xFF6BFF45), // green
  Color(0xFF35C6FF), // blue
];

class CompletionController {
  CompletionController(this.game);
  final RestoreEarthGame game;

  void play() {
    final center = Vector2(
        game.size.x * kEarthCenterOnStage.dx, game.size.y * kEarthCenterOnStage.dy);
    final ew = game.earth.size.x;

    // Coloured beams draw from the satellite to each zone and stay connected.
    var delay = 0.2;
    for (var i = 0; i < kZoneLabels.length; i++) {
      final z = kZoneLabels[i];
      final zoneWorld = game.earth.hotspotWorld(z.center.dx, z.center.dy);
      game.add(_ZoneBeam(
        from: game.satellite.emitPoint,
        to: zoneWorld,
        color: _beamColors[i % _beamColors.length],
        startDelay: delay,
      )..priority = 55);
      delay += 0.14;
    }

    // Burst + badge over the diorama.
    game.spawnEffect(RE.flame(RE.completeBurst), center, ew * 0.7,
        scaleFrom: 0.4, scaleTo: 1.25, startDelay: 0.9, hold: 0.8, fadeOut: 0.8);
    game.spawnEffect(RE.flame(RE.badgeBackplate), center, ew * 0.6,
        scaleFrom: 0.5, scaleTo: 1.0, startDelay: 1.1, persist: true, priority: 82);
    final badge = game.spawnEffect(RE.flame(RE.badge), center, ew * 0.5,
        additive: false, scaleFrom: 0.3, scaleTo: 1.0, startDelay: 1.3, persist: true, priority: 83);
    badge.add(ScaleEffect.to(Vector2.all(1.0),
        EffectController(duration: 0.4, startDelay: 1.3, curve: Curves.easeOutBack)));
  }
}

/// A coloured beam that draws in from [from] to [to], then stays lit + gently
/// pulses — used to show the Earth fully connected at completion.
class _ZoneBeam extends Component {
  _ZoneBeam({required this.from, required this.to, required this.color, this.startDelay = 0});
  final Vector2 from;
  final Vector2 to;
  final Color color;
  double startDelay;
  double _draw = 0; // 0..1 draw-in progress
  double _t = 0;
  static const _drawDur = 0.4;

  @override
  void update(double dt) {
    if (startDelay > 0) {
      startDelay -= dt;
      return;
    }
    _t += dt;
    if (_draw < 1) _draw = (_draw + dt / _drawDur).clamp(0.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    if (startDelay > 0 || _draw <= 0.01) return;
    final a = from.toOffset();
    final b = Offset.lerp(a, to.toOffset(), _draw)!;
    final pulse = 0.8 + 0.2 * (math.sin(_t * 4) + 1) / 2; // gentle once connected
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(a, b, paint..color = color.withValues(alpha: 0.28 * pulse)..strokeWidth = 12);
    canvas.drawLine(a, b, paint..color = color.withValues(alpha: 0.55 * pulse)..strokeWidth = 5);
    canvas.drawLine(a, b, paint..color = const Color(0xFFFFFFFF).withValues(alpha: 0.7 * pulse)..strokeWidth = 2);
    // Bright node at the connected end.
    if (_draw >= 1) {
      canvas.drawCircle(b, 5, Paint()..blendMode = BlendMode.plus..color = color.withValues(alpha: 0.9));
    }
  }
}
