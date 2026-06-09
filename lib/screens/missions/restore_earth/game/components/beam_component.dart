// The aiming/firing beam, drawn programmatically (the vertical beam sprites
// don't rotate/scale cleanly to arbitrary angles — PRD §14.1 sanctions a
// programmatic beam). Faint while aiming (intensity ~0.45), bright on fire.
// Endpoint glow sprites are spawned separately by the game on fire.

import 'dart:ui';

import 'package:flame/components.dart';

class BeamComponent extends PositionComponent {
  BeamComponent() : super(priority: 60); // beamEffects z-index (PRD §8.2)

  Vector2 start = Vector2.zero();
  Vector2 end = Vector2.zero();
  Color color = const Color(0xFF39D8FF);
  double intensity = 0; // 0 = hidden, ~0.45 = preview, 1 = fired

  void aim(Vector2 from, Vector2 to, Color c, {double i = 0.45}) {
    start = from;
    end = to;
    color = c;
    intensity = i;
  }

  void hide() => intensity = 0;

  @override
  void render(Canvas canvas) {
    if (intensity <= 0.01) return;
    final a = start.toOffset();
    final b = end.toOffset();
    final base = Paint()
      ..blendMode = BlendMode.plus
      ..strokeCap = StrokeCap.round;

    // Outer glow → mid → bright core.
    canvas.drawLine(a, b, base..color = color.withValues(alpha: 0.22 * intensity)..strokeWidth = 22 * intensity);
    canvas.drawLine(a, b, base..color = color.withValues(alpha: 0.45 * intensity)..strokeWidth = 10 * intensity);
    canvas.drawLine(
        a, b, base..color = const Color(0xFFFFFFFF).withValues(alpha: 0.85 * intensity)..strokeWidth = 3.0 * intensity);
  }
}
