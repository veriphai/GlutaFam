// The mission dispatch console — the emotional centre (PRD §10.4). Composites:
//   • the mission illustration (config-driven SceneLayers, back-to-front)
//   • reveal-on-success layers (location pin, brightened Wi-Fi, lit TV)
//   • the glowing dispatch zone (idle/hover) -> docked satellite + snap flash
//   • the per-mission success effect (SuccessEffectLayer)
//   • a soft wrong pulse + card shake (gentle, never a harsh red X)
//   • the success label chip ("Located!", "Storm Tracked!", …)
//
// All animation is driven by plain 0..1 values passed from MissionPlayScene, so
// this widget is stateless w.r.t. timing — the scene owns the controllers.

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../home/career/careerCommon.dart';
import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';
import '../models/satellite_mission.dart';
import '../models/satellite_type.dart';
import 'beam_painter.dart';
import 'dispatch_zone.dart';
import 'idle_motion.dart';
import 'scene_positioning.dart';
import 'success_effect_layer.dart';
import '../../../../utils/s3_assets.dart';

class MissionCard extends StatelessWidget {
  const MissionCard({
    super.key,
    required this.mission,
    required this.enterT,
    required this.snapT,
    required this.effectT,
    required this.wrongT,
    required this.hovering,
    required this.resolving,
    required this.solved,
  });

  final SatelliteMission mission;
  final double enterT; // entrance 0..1
  final double snapT; // snap flash + dock 0..1
  final double effectT; // success effect 0..1
  final double wrongT; // wrong pulse 0..1
  final bool hovering;
  final bool resolving;
  final bool solved;

  // Shared dispatch geometry (factors of the scene rect) — top-right, beside
  // the mission text, with the scene art below (matches the design mockup).
  static const Offset _zoneCenter = Offset(0.80, 0.13);
  static const double _zoneWidthFactor = 0.30;
  static const double _dockWidthFactor = 0.28;

  @override
  Widget build(BuildContext context) {
    final success = resolving || solved;
    final wrongActive = wrongT > 0.001 && wrongT < 1.0;
    final enter = Curves.easeOutCubic.transform(enterT.clamp(0, 1));

    // Border / glow colour by state, nudged toward a soft warm tone on a wrong.
    Color edge = success
        ? CareerColors.green
        : (hovering ? CareerColors.cyan : CareerColors.orange);
    if (wrongActive) {
      edge = Color.lerp(edge, const Color(0xFFFF7A6B), math.sin(wrongT * math.pi))!;
    }
    final shakeX = wrongActive ? math.sin(wrongT * math.pi * 4) * 7 * (1 - wrongT) : 0.0;

    return Opacity(
      opacity: enter,
      child: Transform.translate(
        offset: Offset(shakeX, (1 - enter) * 26),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xF2102448), Color(0xF20A1730)],
            ),
            border: Border.all(color: edge.withValues(alpha: 0.9), width: 2),
            boxShadow: [
              BoxShadow(color: edge.withValues(alpha: 0.40), blurRadius: 22, spreadRadius: 1),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LayoutBuilder(
              builder: (context, c) {
                final scene = Size(c.maxWidth, c.maxHeight);
                return Stack(
                  children: [
                    ..._sceneLayers(scene),
                    if (effectT > 0.001) _effect(scene),
                    if (snapT > 0.001) _dockedSatellite(scene),
                    if (snapT > 0.001 && snapT < 1.0) _snapFlash(scene),
                    if (!success) _dispatchZone(scene),
                    if (wrongActive) _wrongPulse(scene),
                    _textBand(),
                    _successLabel(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // --- Scene composite ------------------------------------------------------

  List<Widget> _sceneLayers(Size scene) {
    final revealT = solved ? 1.0 : effectT;
    final revealCurve = Curves.easeOutBack.transform(revealT.clamp(0, 1));
    return [
      for (final layer in mission.layers)
        crsLayer(
          scene: scene,
          centerFactor: layer.centerFactor,
          widthFactor: layer.widthFactor,
          aspect: crsAspectOf(layer.asset),
          child: _layerChild(layer, scene, revealT, revealCurve),
        ),
    ];
  }

  Widget _layerChild(SceneLayer layer, Size scene, double revealT, double revealCurve) {
    Widget img = netImageWidget(layer.asset, fit: BoxFit.contain);

    if (layer.rotateOnSuccess) {
      img = Spinning(active: solved, period: const Duration(seconds: 16), child: img);
    }
    if (layer.driftUp) {
      img = Floaty(amplitude: scene.height * 0.018, period: const Duration(milliseconds: 3600), child: img);
    }

    double opacity = layer.idleOpacity;
    if (layer.revealOnSuccess) {
      opacity = lerpDouble(layer.idleOpacity, 1.0, Curves.easeOut.transform(revealT.clamp(0, 1)))!;
      if (layer.idleOpacity == 0) {
        // Hidden until success, then pops in (e.g. the location pin).
        img = Transform.scale(scale: 0.55 + 0.45 * revealCurve.clamp(0, 1), child: img);
      }
    }
    return Opacity(opacity: opacity.clamp(0, 1), child: img);
  }

  Widget _effect(Size scene) {
    // Cone-type effects (GPS beam, camera scan) are drawn programmatically as a
    // cone from the docked satellite (top-right) down to the target, instead of
    // a floating sprite.
    final isCone = mission.successEffect == MissionEffectType.gpsBeam ||
        mission.successEffect == MissionEffectType.cameraScan;
    if (isCone) {
      final src = Offset(_zoneCenter.dx * scene.width, _zoneCenter.dy * scene.height);
      final tf = mission.beamTargetFactor ?? mission.effectPlacement.centerFactor;
      final tgt = Offset(tf.dx * scene.width, tf.dy * scene.height);
      final beamColor = mission.successEffect == MissionEffectType.gpsBeam
          ? CareerColors.cyan
          : CareerColors.green; // camera scan = Earth-observation green
      return Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: BeamConePainter(
              source: src,
              target: tgt,
              progress: effectT.clamp(0, 1),
              color: beamColor,
              targetHalfWidth: scene.width * 0.16,
            ),
          ),
        ),
      );
    }

    final p = mission.effectPlacement;
    return crsLayer(
      scene: scene,
      centerFactor: p.centerFactor,
      widthFactor: p.widthFactor,
      aspect: crsAspectOf(SuccessEffectLayer.spriteFor(mission.successEffect)),
      child: SuccessEffectLayer(type: mission.successEffect, t: effectT.clamp(0, 1)),
    );
  }

  // --- Dispatch zone / dock / flash ----------------------------------------

  Widget _dispatchZone(Size scene) {
    final d = scene.width * _zoneWidthFactor;
    return crsLayer(
      scene: scene,
      centerFactor: _zoneCenter,
      widthFactor: _zoneWidthFactor,
      aspect: 1.0,
      child: Opacity(
        opacity: (1 - snapT).clamp(0, 1),
        child: DispatchZone(hovering: hovering, diameter: d),
      ),
    );
  }

  Widget _dockedSatellite(Size scene) {
    final t = snapT.clamp(0.0, 1.0);
    final scale = lerpDouble(0.5, 1.0, Curves.easeOutBack.transform(t))!;
    Widget sat = netImageWidget(mission.correctType.sprite, fit: BoxFit.contain);
    if (solved) {
      sat = Floaty(amplitude: 3, period: const Duration(milliseconds: 2800), child: sat);
    }
    return crsLayer(
      scene: scene,
      centerFactor: _zoneCenter,
      widthFactor: _dockWidthFactor,
      aspect: crsAspectOf(mission.correctType.sprite),
      child: Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.scale(scale: scale, child: sat),
      ),
    );
  }

  Widget _snapFlash(Size scene) {
    final t = snapT.clamp(0.0, 1.0);
    return crsLayer(
      scene: scene,
      centerFactor: _zoneCenter,
      widthFactor: 0.5,
      aspect: crsAspectOf(CrsAssets.snapFlash),
      child: Opacity(
        opacity: (1 - t).clamp(0, 1),
        child: Transform.scale(
          scale: lerpDouble(0.7, 1.3, t)!,
          child: netImageWidget(CrsAssets.snapFlash, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _wrongPulse(Size scene) {
    final t = wrongT.clamp(0.0, 1.0);
    return crsLayer(
      scene: scene,
      centerFactor: _zoneCenter,
      widthFactor: 0.5,
      aspect: crsAspectOf(CrsAssets.wrongPulse),
      child: Opacity(
        opacity: math.sin(t * math.pi) * 0.9,
        child: Transform.scale(
          scale: 0.7 + 0.5 * t,
          child: netImageWidget(CrsAssets.wrongPulse, fit: BoxFit.contain),
        ),
      ),
    );
  }

  // --- Text + labels --------------------------------------------------------

  Widget _textBand() {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xCC0A1730), Color(0x000A1730)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _alertRow(),
            const SizedBox(height: 6),
            Text(mission.title,
                style: CareerText.heroTitle.copyWith(fontSize: 17, color: Colors.white)),
            const SizedBox(height: 3),
            SizedBox(
              width: 210,
              child: Text(mission.requestText,
                  style: CareerText.body.copyWith(fontSize: 11.5, color: CareerColors.textSecondary, height: 1.25)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertRow() {
    final done = solved;
    final color = done ? CareerColors.green : CareerColors.orange;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(done ? Icons.check_circle_rounded : Icons.warning_amber_rounded, size: 16, color: color),
        const SizedBox(width: 5),
        Text(done ? 'MISSION COMPLETE' : mission.alertLabel,
            style: CareerText.label.copyWith(fontSize: 10.5, letterSpacing: 1.4, color: color)),
      ],
    );
  }

  Widget _successLabel() {
    final show = solved || (resolving && effectT > 0.45);
    return Positioned(
      left: 0,
      right: 0,
      bottom: 12,
      child: Center(
        child: AnimatedScale(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          scale: show ? 1 : 0.6,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 260),
            opacity: show ? 1 : 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xE60E2A22),
                borderRadius: BorderRadius.circular(CareerRadii.pill),
                border: Border.all(color: CareerColors.green, width: 1.4),
                boxShadow: [BoxShadow(color: CareerColors.green.withValues(alpha: 0.45), blurRadius: 14)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 17, color: CareerColors.green),
                  const SizedBox(width: 6),
                  Text(mission.successLabel,
                      style: CareerText.cta.copyWith(fontSize: 13, color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
