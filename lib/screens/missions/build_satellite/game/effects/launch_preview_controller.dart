// Launch Preview choreography (PRD §15 / scene 15).
//
// Voice-driven now: the controller queues spoken check lines, and the game
// calls one of the [reveal*] methods below when each spoken line starts.
// This lock-steps the visual with what Orbit is saying, regardless of voice
// length. Only [liftOnly] runs immediately on launch start; everything else
// is on-demand.

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

import '../../config/asset_paths.dart';
import '../build_satellite_game.dart';

class LaunchPreviewController {
  LaunchPreviewController(this.game);

  final BuildSatelliteGame game;

  /// Initial action: float the satellite up and scale it slightly. The
  /// subsystem reveals are triggered later by the spoken-line stream.
  void liftOnly() {
    final body = game.body;
    body.hoverEnabled = false;
    body.add(MoveEffect.by(
        Vector2(0, -game.size.y * 0.045),
        EffectController(duration: 0.7, curve: Curves.easeInOut)));
    body.add(ScaleEffect.to(
        Vector2.all(1.03), EffectController(duration: 0.7, curve: Curves.easeInOut)));
  }

  // ── Per-subsystem reveal beats (fired by the game on voice clip play) ──
  void revealPower() {
    _glow('left_solar_panel', const Color(0xFF36C8FF), 1.2);
    _glow('right_solar_panel', const Color(0xFF36C8FF), 1.2);
  }

  void revealSignal() => _signalFromAntenna();

  void revealVision() => _glow('camera_module', const Color(0xFF18D6FF), 1.4);

  void revealBrain() => _glow('computer_core_chip', const Color(0xFF65FF9E), 2.4);

  void revealBattery() => _glow('battery_module', const Color(0xFFFFC83D), 1.4);

  void revealMovement() => _thrusterFire();

  void revealProtection() => _glow('thermal_blanket', const Color(0xFFFFD25E), 1.3);

  // ── Internals (kept private; revealers are the only entry points) ──────
  void _glow(String partId, Color tint, double scale) {
    final c = game.installedComponents[partId];
    if (c == null) return;
    game.spawnGlow(c.worldCenter, SatAssets.correctSlotGlow,
        size: c.size * scale, tint: tint, duration: 0.8, fromScale: 0.4, toScale: 1.1);
  }

  void _signalFromAntenna() {
    final c = game.installedComponents['antenna_dish'];
    if (c == null) return;
    game.spawnSignalWaves(c.worldCenter, c.size.x * 1.5, count: 3);
  }

  void _thrusterFire() {
    final c = game.installedComponents['thruster'];
    if (c == null) return;
    game.spawnThrusterFlame(c.worldCenter + Vector2(0, c.size.y * 0.32), c.size.x * 0.6);
  }
}
