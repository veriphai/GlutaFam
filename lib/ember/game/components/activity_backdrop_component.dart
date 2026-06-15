// Ember — game/components/activity_backdrop_component.dart
//
// The warm atmospheric backdrop behind an ACTIVITY STAGE. It lives in the
// activity camera's static `backdrop` slot (screen-space, pan/zoom-independent),
// so the bespoke interact props (e.g. Fire's fireboard + spindle + flame) sit in
// front of a believable cold-night-by-the-fire scene rather than a flat tan
// Scaffold fill. It paints:
//   * a vertical night-sky gradient (deep blue zenith -> warm amber horizon),
//   * a soft ember-warm bloom low-centre (the heat the player is making),
//   * a hazy ground band, and a gentle vignette so the eye settles on the stage.
//
// Presentation-only: it reads the palette + a free clock for a faint flicker and
// never touches world state. Sized to the full canvas each frame (screen space).
// Generic to ALL activities — no leaf coupling — so every activity gets a warm,
// non-dead backdrop for free.

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../art/ember_palette.dart';
import '../ember_game.dart';

/// Full-screen warm night backdrop drawn behind an activity stage (camera
/// backdrop slot). The amber low-bloom subtly breathes to feel alive.
class ActivityBackdropComponent extends PositionComponent
    with HasGameReference<EmberGame> {
  ActivityBackdropComponent()
      : super(position: Vector2.zero(), anchor: Anchor.topLeft);

  EmberPalette get _p => game.art.palette;

  /// Free-running phase for the gentle bloom breathing (presentation only).
  double _t = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    // Keep the backdrop filling the live canvas.
    size = game.size.clone();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final double w = size.x;
    final double h = size.y;
    if (w <= 0 || h <= 0) return;
    final Rect full = Rect.fromLTWH(0, 0, w, h);

    // ---- 1) Night-sky gradient: deep-blue zenith easing to a warm amber band
    //         at the horizon (the firelight glow on the cold night the Elder
    //         describes). ----
    const Color zenith = Color(0xFF1B2347); // cold deep night above
    final Color mid = Color.lerp(zenith, _p.emberDeep, 0.28)!;
    final Color horizon = Color.lerp(_p.emberDeep, _p.ember, 0.35)!;
    canvas.drawRect(
      full,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[zenith, mid, horizon],
          stops: const <double>[0.0, 0.62, 1.0],
        ).createShader(full),
    );

    // ---- 2) A warm ember bloom low-centre — the heat the player is coaxing up,
    //         breathing gently so the scene feels alive (not a dead scrim). ----
    final double breathe = 0.9 + 0.1 * math.sin(_t * 1.6);
    final Offset glowAt = Offset(w * 0.5, h * 0.62);
    final double bloomR = math.max(w, h) * 0.55 * breathe;
    final Color bloom = _p.ember.withValues(alpha: 0.22 * breathe);
    canvas.drawCircle(
      glowAt,
      bloomR,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[bloom, bloom.withValues(alpha: 0.0)],
        ).createShader(Rect.fromCircle(center: glowAt, radius: bloomR)),
    );

    // ---- 3) Hazy ground band where the firelight pools on the earth. ----
    final double bandY = h * 0.72;
    final Rect band = Rect.fromLTWH(0, bandY, w, h - bandY);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            _p.emberDeep.withValues(alpha: 0.0),
            _p.emberDeep.withValues(alpha: 0.30),
          ],
        ).createShader(band),
    );

    // ---- 4) A soft vignette so the frame composes around the stage. ----
    canvas.drawRect(
      full,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.95,
          colors: <Color>[
            const Color(0x00000000),
            const Color(0xFF000000).withValues(alpha: 0.34),
          ],
          stops: const <double>[0.55, 1.0],
        ).createShader(full),
    );
  }
}
