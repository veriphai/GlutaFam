// Sky — the day/night cycle as a first-class visual (PRD §7), premium pass:
// a richer multi-stop gradient (dawn → noon → dusk → night), atmospheric
// scattering glow around a low sun, the sun REDDENING + dimming as the town's
// haze thickens (the dirty-source consequence reaching the sky), and a DIEGETIC
// starfield + crescent moon at night (do NOT remove the stars — it is actually
// night in the sim; that note is in the PRD).

import 'dart:math' as math;

import 'package:flame/components.dart' show Component;
import 'package:flutter/material.dart';

import '../../config/town_sim_tuning.dart';
import '../../state/source_personalities_controller.dart';

class SkyLayer extends Component {
  SkyLayer(this.c, {this.reducedMotion = false});
  final SourcePersonalitiesController c;
  final bool reducedMotion;

  double _clock = 0;
  late final List<_Star> _stars = _makeStars();

  List<_Star> _makeStars() {
    final rng = math.Random(31);
    return List.generate(70, (i) {
      return _Star(rng.nextDouble(), rng.nextDouble() * 0.62, 0.5 + rng.nextDouble() * 0.95,
          rng.nextDouble() * math.pi * 2);
    });
  }

  @override
  void update(double dt) {
    if (!reducedMotion) _clock += dt;
  }

  @override
  void render(Canvas canvas) {
    final size = c.stageSize;
    if (size.isEmpty) return;
    final w = size.width, h = size.height;
    final alt = c.sunAltitude;
    final t = c.timeOfDay;
    final twilight = _twilight(t, alt);
    final pollution = c.pollution.clamp(0.0, 1.0);

    // --- Sky gradient (3-stop) ----------------------------------------------
    final topDay = Color.lerp(TownTune.skyNightTop, TownTune.skyDayTop, alt)!;
    final midDay = Color.lerp(const Color(0xFF101A36), const Color(0xFF6CA6DE), alt)!;
    final botDay = Color.lerp(TownTune.skyNightBottom, TownTune.skyDayBottom, alt)!;
    var top = Color.lerp(topDay, TownTune.skyDuskTop, twilight * 0.6)!;
    var mid = Color.lerp(midDay, const Color(0xFFE08A4D), twilight * 0.55)!;
    var bottom = Color.lerp(botDay, TownTune.skyDuskBottom, twilight)!;
    // Haze desaturates + warms the lower sky (smog tint), but ONLY low down — the
    // upper sky stays clean so clean-vs-dirty contrast reads.
    if (pollution > 0.02) {
      bottom = Color.lerp(bottom, const Color(0xFF8A7B5E), pollution * 0.5)!;
      mid = Color.lerp(mid, const Color(0xFF9A8A66), pollution * 0.30)!;
      // A faint sickly cast reaches even the high sky when the air is filthy.
      top = Color.lerp(top, const Color(0xFF6B6656), pollution * 0.12)!;
    }

    final rect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, mid, bottom],
          stops: const [0.0, 0.52, 1.0],
        ).createShader(rect),
    );

    // --- Stars (night only, fading through twilight) ------------------------
    final starFade = (1 - alt / 0.16).clamp(0.0, 1.0) * (1 - twilight * 0.7) * (1 - pollution * 0.5);
    if (starFade > 0.02) {
      final horizon = c.horizonY;
      for (final s in _stars) {
        final tw = reducedMotion ? 1.0 : 0.55 + 0.45 * math.sin(_clock * 1.7 + s.phase);
        final a = starFade * s.mag.clamp(0.0, 1.0) * tw * 0.9;
        if (a <= 0.02) continue;
        canvas.drawCircle(Offset(s.x * w, s.y * horizon), s.mag * 1.1,
            Paint()..color = Colors.white.withValues(alpha: a));
      }
    }

    // --- Sun, with scattering glow + haze reddening -------------------------
    if (alt > 0.001) {
      final arc = c.sunArcX.clamp(0.0, 1.0);
      final sunX = (0.12 + arc * 0.76) * w;
      final sunY = c.horizonY - alt * (c.horizonY * 0.84);
      final golden = 1 - (alt * 1.6).clamp(0.0, 1.0);
      // Clear-air sun colour, then redden + dim through haze.
      var sunColor = Color.lerp(const Color(0xFFFFC36B), const Color(0xFFFFF6D2), alt)!;
      sunColor = Color.lerp(sunColor, const Color(0xFFE8703A), pollution * 0.7)!;
      final r = w * (0.05 + 0.012 * golden);

      // Wide atmospheric scattering halo — bigger and warmer at golden hour / haze.
      final haloR = r * (3.0 + 3.5 * golden + 2.0 * pollution);
      canvas.drawCircle(
        Offset(sunX, sunY), haloR,
        Paint()
          ..blendMode = pollution > 0.4 ? BlendMode.srcOver : BlendMode.plus
          ..shader = RadialGradient(colors: [
            sunColor.withValues(alpha: (0.5 - 0.2 * pollution).clamp(0.1, 0.5)),
            sunColor.withValues(alpha: 0),
          ]).createShader(Rect.fromCircle(center: Offset(sunX, sunY), radius: haloR)),
      );
      // The disc — softened (hazy) when pollution high.
      if (pollution > 0.35) {
        canvas.drawCircle(Offset(sunX, sunY), r * 1.25,
            Paint()..color = sunColor.withValues(alpha: 0.5)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5 * pollution));
      }
      canvas.drawCircle(Offset(sunX, sunY), r, Paint()..color = sunColor);
    } else {
      _moon(canvas, w, t);
    }
  }

  void _moon(Canvas canvas, double w, double t) {
    final nightFrac = (t < TownTune.sunrise) ? t + (24 - TownTune.sunset) : t - TownTune.sunset;
    final span = 24 - (TownTune.sunset - TownTune.sunrise);
    final mn = (nightFrac / span).clamp(0.0, 1.0);
    final moonX = (0.18 + mn * 0.64) * w;
    final moonY = c.horizonY * (0.32 + 0.16 * math.sin(mn * math.pi));
    final r = w * 0.04;
    canvas.drawCircle(Offset(moonX, moonY), r * 2.6,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFFBFC9E8).withValues(alpha: 0.34),
            const Color(0xFFBFC9E8).withValues(alpha: 0),
          ]).createShader(Rect.fromCircle(center: Offset(moonX, moonY), radius: r * 2.6)));
    canvas.drawCircle(Offset(moonX, moonY), r, Paint()..color = const Color(0xFFE7ECFA));
    canvas.drawCircle(Offset(moonX + r * 0.42, moonY - r * 0.18), r * 0.92,
        Paint()..color = Color.lerp(TownTune.skyNightTop, TownTune.skyNightBottom, 0.4)!);
  }

  double _twilight(double t, double alt) {
    final d = math.min((t - TownTune.sunrise).abs(), (t - TownTune.sunset).abs());
    final near = (1 - d / 1.7).clamp(0.0, 1.0);
    return near * (1 - (alt * 1.4).clamp(0.0, 1.0));
  }
}

class _Star {
  _Star(this.x, this.y, this.mag, this.phase);
  final double x, y, mag, phase;
}
