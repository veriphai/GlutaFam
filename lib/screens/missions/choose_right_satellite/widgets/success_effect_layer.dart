// The per-mission success effect (PRD §15), driven by a single 0..1 progress
// value. Each effect is the type's sprite animated with the exact beats the PRD
// names — fade in, hold, fade out, plus type-specific scale/rotate/wave.
//
// Compositing is NORMAL alpha (not additive): the mission illustrations are
// bright (fire, ocean, daylight village), and the playbook warns BlendMode.plus
// over bright art blows glows out to white. The sprites are clean cut-outs, so
// alpha compositing reads as a glowing overlay without the blowout.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/asset_paths.dart';
import '../models/satellite_mission.dart';
import '../../../../utils/s3_assets.dart';

class SuccessEffectLayer extends StatelessWidget {
  const SuccessEffectLayer({super.key, required this.type, required this.t});

  final MissionEffectType type;

  /// 0..1 progress over the success effect's lifetime.
  final double t;

  /// Sprite path for the effect (so the caller can size the Positioned by aspect).
  static String spriteFor(MissionEffectType type) {
    switch (type) {
      case MissionEffectType.gpsBeam:
        return CrsAssets.gpsBeam;
      case MissionEffectType.weatherScan:
        return CrsAssets.weatherScanRings;
      case MissionEffectType.communicationWaves:
        return CrsAssets.communicationWaves;
      case MissionEffectType.cameraScan:
        return CrsAssets.cameraScanCone;
    }
  }

  // Envelope: fade in 0->0.18, hold, fade out 0.82->1.
  double get _envelope {
    if (t < 0.14) return (t / 0.14).clamp(0.0, 1.0);
    if (t > 0.9) return (1 - (t - 0.9) / 0.1).clamp(0.0, 1.0);
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final sprite = spriteFor(type);
    final env = _envelope;
    final twoPi = 2 * math.pi;

    switch (type) {
      case MissionEffectType.gpsBeam:
        // Fade in, gentle downward settle, opacity pulse (PRD §9.5 / §15.1).
        final pulse = 0.78 + 0.22 * math.sin(t * twoPi * 2);
        return Opacity(
          opacity: env * pulse,
          child: Transform.translate(
            offset: Offset(0, -6 + 10 * Curves.easeOut.transform(t.clamp(0, 1))),
            child: Transform.scale(
              scale: 0.92 + 0.08 * Curves.easeOut.transform(t.clamp(0, 1)),
              alignment: Alignment.topCenter,
              child: netImageWidget(sprite, fit: BoxFit.contain),
            ),
          ),
        );

      case MissionEffectType.weatherScan:
        // Scale 0.8 -> 1.15, slow rotate, opacity pulse (PRD §15.2 / §9.5.2).
        final scale = 0.8 + 0.35 * Curves.easeOut.transform(t.clamp(0, 1));
        final pulse = 0.8 + 0.2 * math.sin(t * twoPi * 2.2);
        return Opacity(
          opacity: env * pulse,
          child: Transform.rotate(
            angle: t * twoPi * 0.45,
            child: Transform.scale(scale: scale, child: netImageWidget(sprite, fit: BoxFit.contain)),
          ),
        );

      case MissionEffectType.communicationWaves:
        // Two staggered waves travelling outward (PRD §15.3/§9.5.3): each grows
        // and fades, the second offset by half a cycle.
        return Opacity(
          opacity: env,
          child: Stack(
            alignment: Alignment.center,
            children: [for (final phase in const [0.0, 0.5]) _wave(sprite, (t + phase) % 1.0)],
          ),
        );

      case MissionEffectType.cameraScan:
        // Cone sweeps left->right across the forest while fading (PRD §15.5).
        final sweep = (t * 2) % 1.0;
        final pulse = 0.82 + 0.18 * math.sin(t * twoPi * 3);
        return Opacity(
          opacity: env * pulse,
          child: Transform.translate(
            offset: Offset((sweep - 0.5) * 36, 0),
            child: Transform.scale(
              scale: 0.96 + 0.06 * math.sin(t * twoPi * 2),
              alignment: Alignment.topCenter,
              child: netImageWidget(sprite, fit: BoxFit.contain),
            ),
          ),
        );
    }
  }

  Widget _wave(String sprite, double p) {
    // p in 0..1 -> scale up & fade out as it travels.
    final scale = 0.55 + 0.65 * p;
    final opacity = (1 - p).clamp(0.0, 1.0);
    return Opacity(
      opacity: opacity * opacity,
      child: Transform.scale(scale: scale, child: netImageWidget(sprite, fit: BoxFit.contain)),
    );
  }
}
