// Typed mission model (PRD §11). A mission's illustration is described as a
// stack of [SceneLayer]s positioned as FACTORS of the scene rect (resolution
// independent, per the playbook) — so the composite scene, the "reveal on
// success" sprites, and the animated success effect are all data, never
// hardcoded per mission in widget code (PRD §24.4).

import 'package:flutter/widgets.dart';

import 'orbit_line.dart';
import 'satellite_type.dart';

/// The animated overlay that plays on a correct dispatch (PRD §15).
enum MissionEffectType { gpsBeam, weatherScan, communicationWaves, cameraScan }

/// One sprite layer inside a mission illustration. Positions are fractions of
/// the scene rect: [centerFactor] = (0..1, 0..1), [widthFactor] = fraction of
/// scene width. [revealOnSuccess] layers (location pin, brightened Wi-Fi, lit
/// TV) start hidden and fade/scale in when the mission is solved.
class SceneLayer {
  const SceneLayer({
    required this.asset,
    required this.centerFactor,
    required this.widthFactor,
    this.idleOpacity = 1.0,
    this.revealOnSuccess = false,
    this.driftUp = false,
    this.rotateOnSuccess = false,
  });

  final String asset;
  final Offset centerFactor;
  final double widthFactor;

  /// Opacity before success (e.g. a dim Wi-Fi symbol at 0.35).
  final double idleOpacity;

  /// Hidden until the mission is solved, then animates in.
  final bool revealOnSuccess;

  /// Slowly floats upward forever (smoke).
  final bool driftUp;

  /// Gently rotates while solved (cyclone).
  final bool rotateOnSuccess;
}

/// Where the animated success effect plays, as factors of the scene rect.
class EffectPlacement {
  const EffectPlacement({
    required this.centerFactor,
    required this.widthFactor,
  });

  final Offset centerFactor;
  final double widthFactor;
}

class SatelliteMission {
  const SatelliteMission({
    required this.id,
    required this.title,
    required this.requestText,
    required this.correctType,
    required this.layers,
    required this.successLabel,
    required this.appearLines,
    required this.successLines,
    required this.hintAfterWrong,
    required this.strongerHint,
    required this.successEffect,
    required this.effectPlacement,
    this.alertLabel = 'MISSION ALERT',
    this.thumbnailAsset,
    this.beamTargetFactor,
    this.ambientSound,
    this.successSting,
  });

  final String id;
  final String title;
  final String requestText;
  final String alertLabel;
  final SatelliteType correctType;

  /// Painted back-to-front.
  final List<SceneLayer> layers;

  final String successLabel;

  /// Orbit's lines when this mission appears (the scene-setting beat).
  final List<OrbitLine> appearLines;

  /// Orbit's lines on a correct dispatch (1–2 lines, played in sequence).
  final List<OrbitLine> successLines;

  /// Orbit after the 1st wrong attempt.
  final OrbitLine hintAfterWrong;

  /// Orbit after the 2nd wrong attempt (stronger hint).
  final OrbitLine strongerHint;

  final MissionEffectType successEffect;
  final EffectPlacement effectPlacement;

  /// Iconic sprite for the mission-log thumbnail (PRD §17); defaults to the
  /// first (base) scene layer.
  final String? thumbnailAsset;
  String get thumbnail => thumbnailAsset ?? layers.first.asset;

  /// For cone-type effects (gpsBeam / cameraScan), where the beam LANDS, as a
  /// factor of the scene rect. The beam's source is the satellite dock point.
  /// Null falls back to the effect placement centre.
  final Offset? beamTargetFactor;

  /// Looping ambient bed played quietly while this mission is active.
  final String? ambientSound;

  /// One-shot sound on a correct dispatch (replaces the generic chime).
  final String? successSting;

  bool isCorrect(SatelliteType type) => type == correctType;
}
