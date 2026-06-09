// Part-specific deployment animations (PRD §5 / scenes 4–13).
//
// HOW ANIMATIONS ARE TRIGGERED: InstalledPartComponent.onLoad calls
// [playDeployment] the moment a part snaps into place. Each branch combines:
//   • effects on the part itself (scale / rotate / move), and
//   • additive glow/wave/flame bursts spawned into the game at the part centre.

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

import '../../config/asset_paths.dart';
import '../../config/part_catalog.dart';
import '../components/installed_part_component.dart';

void playDeployment(InstalledPartComponent c) {
  final g = c.game;
  final center = c.worldCenter;

  switch (c.part.deploymentKey) {
    case DeployFx.solar:
      _snapIn(c);
      // Unfold: start folded toward the body, swing out to the final angle.
      final dir = c.part.id == 'left_solar_panel' ? 1.0 : -1.0;
      final finalAngle = c.angle;
      c.angle = finalAngle + dir * 0.5;
      c.add(RotateEffect.to(finalAngle,
          EffectController(duration: 0.42, curve: Curves.easeOutBack)));
      g.spawnGlow(center, SatAssets.solarGlow,
          size: c.size * 1.1, tint: const Color(0xFF36C8FF), startDelay: 0.22, toScale: 1.2);
      g.spawnEnergyLine(center, g.bodyCenter, startDelay: 0.3);

    case DeployFx.antennaBase:
      _snapIn(c);
      // Metallic lock: a quick downward seat.
      c.add(MoveEffect.by(Vector2(0, c.size.y * 0.08),
          EffectController(duration: 0.1, alternate: true, curve: Curves.easeOut)));
      g.spawnGlow(center, SatAssets.snapFlash, size: Vector2.all(c.size.x * 1.1), duration: 0.35);

    case DeployFx.antennaDish:
      _snapIn(c);
      // Dish rotates into its pointing angle, then emits signal waves.
      final finalAngle = c.angle;
      c.angle = finalAngle - 0.6;
      c.add(RotateEffect.to(finalAngle,
          EffectController(duration: 0.5, curve: Curves.easeOut)));
      g.spawnSignalWaves(center, c.size.x * 1.4, count: 3);

    case DeployFx.camera:
      _snapIn(c);
      // Lens glow + a quick scan pulse.
      g.spawnGlow(center, SatAssets.correctSlotGlow,
          size: Vector2.all(c.size.x * 1.3), tint: const Color(0xFF18D6FF), duration: 0.5);
      g.spawnGlow(center, SatAssets.snapFlash,
          size: Vector2.all(c.size.x * 0.9), duration: 0.4, startDelay: 0.15, toScale: 1.6);

    case DeployFx.computerCore:
      _snapIn(c);
      // Central glow pulse spreading outward.
      g.spawnGlow(center, SatAssets.correctSlotGlow,
          size: Vector2.all(c.size.x * 3.0),
          tint: const Color(0xFF65FF9E),
          duration: 0.7,
          fromScale: 0.2,
          toScale: 1.0);

    case DeployFx.battery:
      // Slide up into the slot, then charge glow.
      c.position.add(Vector2(0, c.size.y * 0.5));
      _snapIn(c);
      c.add(MoveEffect.by(Vector2(0, -c.size.y * 0.5),
          EffectController(duration: 0.28, curve: Curves.easeOut)));
      g.spawnGlow(center, SatAssets.solarGlow,
          size: c.size * 1.2, tint: const Color(0xFFFFC83D), duration: 0.6, startDelay: 0.2);

    case DeployFx.thruster:
      _snapIn(c);
      // Brief flame test from the nozzle (bottom of the thruster).
      final nozzle = center + Vector2(0, c.size.y * 0.32);
      g.spawnThrusterFlame(nozzle, c.size.x * 0.55);

    case DeployFx.thermal:
      // Settle in with a fade, then a golden shimmer sweep.
      c.opacity = 0;
      c.scale = Vector2.all(1.1);
      c.add(OpacityEffect.to(1, EffectController(duration: 0.4)));
      c.add(ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.4, curve: Curves.easeOut)));
      g.spawnGlow(center, SatAssets.snapFlash,
          size: Vector2.all(c.size.x * 1.4),
          tint: const Color(0xFFFFD25E),
          duration: 0.7,
          startDelay: 0.2,
          toScale: 1.6);
  }
}

/// Shared "pop into place" with a tiny squash-and-settle.
void _snapIn(InstalledPartComponent c) {
  final base = c.scale.clone();
  c.scale = base * 1.18;
  c.add(ScaleEffect.to(base, EffectController(duration: 0.2, curve: Curves.easeOutBack)));
}
