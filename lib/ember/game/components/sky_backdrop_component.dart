// Ember — game/components/sky_backdrop_component.dart
//
// The atmospheric SKY behind the iso world. Lives in the camera's static
// `backdrop` slot (screen-space, pan/zoom-independent), so it reads as a real
// sky the world sits under — not a flat fill the diamonds float on. It paints,
// from the day/night darkness factor (read live off the GameBridge):
//   * a vertical sky gradient that lerps warm-dusk -> deep-night,
//   * a soft sun/moon body + a wide warm/cool bloom near the horizon,
//   * a hazy horizon band where sky meets ground,
//   * a gentle corner vignette so the eye settles on the village.
//
// Presentation-only: it reads `game.darkness` + the palette and never mutates
// the world. Sized to the full canvas each frame (screen space).

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../art/ember_palette.dart';
import '../ember_game.dart';

/// Full-screen atmospheric sky drawn behind the world (camera backdrop slot).
class SkyBackdropComponent extends PositionComponent
    with HasGameReference<EmberGame> {
  SkyBackdropComponent() : super(position: Vector2.zero(), anchor: Anchor.topLeft);

  EmberPalette get _p => game.art.palette;

  /// Drifting phase for the soft horizon haze (presentation only).
  double _phase = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _phase = (_phase + dt * 0.12) % (math.pi * 2);
    // Match the live canvas so the sky always fills the screen.
    size = game.size.clone();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final double w = size.x;
    final double h = size.y;
    if (w <= 0 || h <= 0) return;

    final double dk = game.darkness.clamp(0.0, 1.0);
    final Rect full = Rect.fromLTWH(0, 0, w, h);

    // ---- 1) Sky gradient: warm dusk zenith -> sandy horizon, easing to a
    //         deep blue night as darkness rises. ----
    final Color zenithDay = const Color(0xFFAFCBE0); // soft hazy blue-grey
    final Color horizonDay = _p.background; // warm sandy band at the horizon
    final Color zenithNight = const Color(0xFF161B33);
    final Color horizonNight = const Color(0xFF2C2B4A);

    final Color zenith = Color.lerp(zenithDay, zenithNight, dk)!;
    final Color horizon = Color.lerp(horizonDay, horizonNight, dk)!;

    canvas.drawRect(
      full,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[zenith, Color.lerp(zenith, horizon, 0.55)!, horizon],
          stops: const <double>[0.0, 0.52, 1.0],
        ).createShader(full),
    );

    // ---- 2) The sun (day) / moon (night) body + a wide soft bloom that warms
    //         (or cools) the upper sky. Anchored upper-left to match the global
    //         key-light direction the tiles are shaded from. ----
    final Offset light = Offset(w * 0.24, h * 0.20);
    final double bloomR = math.max(w, h) * 0.62;

    final Color bloomCol = Color.lerp(
      _p.emberBright.withValues(alpha: 0.30),
      _p.cold.withValues(alpha: 0.16),
      dk,
    )!;
    canvas.drawCircle(
      light,
      bloomR,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[bloomCol, bloomCol.withValues(alpha: 0.0)],
        ).createShader(Rect.fromCircle(center: light, radius: bloomR)),
    );

    // The disc itself.
    final double discR = w * 0.05;
    final Color disc = Color.lerp(
      const Color(0xFFFFE9A8), // warm sun
      const Color(0xFFE7ECFF), // pale moon
      dk,
    )!;
    canvas.drawCircle(
      light,
      discR,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[disc, disc.withValues(alpha: 0.55)],
        ).createShader(Rect.fromCircle(center: light, radius: discR)),
    );

    // ---- 3) Horizon haze: a soft luminous band a little above mid-screen
    //         where the sky meets the iso field, drifting subtly. ----
    final double hazeY = h * (0.50 + 0.01 * math.sin(_phase));
    final double hazeH = h * 0.22;
    final Rect hazeRect = Rect.fromLTWH(0, hazeY - hazeH / 2, w, hazeH);
    final Color haze = Color.lerp(
      _p.emberBright.withValues(alpha: 0.14),
      _p.cold.withValues(alpha: 0.10),
      dk,
    )!;
    canvas.drawRect(
      hazeRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[haze.withValues(alpha: 0.0), haze, haze.withValues(alpha: 0.0)],
        ).createShader(hazeRect),
    );

    // ---- 4) Corner vignette so the frame feels composed + the eye centers on
    //         the village. Stronger at night. ----
    final double vig = 0.16 + 0.22 * dk;
    canvas.drawRect(
      full,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.95,
          colors: <Color>[
            const Color(0x00000000),
            Color.lerp(_p.night, const Color(0xFF000000), 0.3)!
                .withValues(alpha: vig),
          ],
          stops: const <double>[0.62, 1.0],
        ).createShader(full),
    );
  }
}
