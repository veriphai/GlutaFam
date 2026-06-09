// Data model for one Earth Detective mini-mission. Everything that differs
// between the six missions lives here as declarative config; the Flame stage,
// scanner, and scenes are generic and read this. Add a seventh satellite-image
// mission by appending one [EarthDetectiveMission] to the missions list.
//
// Hit zones are in NORMALISED image coordinates (0..1 over the displayed
// satellite image rect) so they stay responsive across devices and survive
// zoom/pan (PRD §15).

import 'package:flutter/widgets.dart';

/// How the child investigates this mission's image.
enum InteractionMode { scanAndTap, zoomAndTap, followTrail, compareBeforeAfter }

/// How a revealed clue overlay animates in.
enum OverlayAnim {
  /// Scale + opacity breathe (ring around the clue).
  pulse,

  /// Fades in then gently pulses opacity (spiral / stress wash).
  fadePulse,

  /// Drops in from above and settles (location / coordinate pin).
  pinDrop,

  /// A band sweeps across the clue once (change detection).
  sweep,
}

/// One clue-reveal overlay placed by normalised centre + width fraction.
class MissionOverlayConfig {
  const MissionOverlayConfig({
    required this.asset,
    required this.centerNorm,
    required this.widthFactor,
    this.anim = OverlayAnim.pulse,
    this.additive = false,
    this.delay = Duration.zero,
  });

  /// Flame-relative sprite path (see [EdAssets]).
  final String asset;

  /// Centre of the overlay in normalised image coords (0..1).
  final Offset centerNorm;

  /// Overlay width as a fraction of the displayed image width.
  final double widthFactor;

  final OverlayAnim anim;

  /// Render with [BlendMode.plus]. Only safe over dark image regions; the
  /// satellite scenes are bright, so most overlays use normal alpha.
  final bool additive;

  /// Stagger after the reveal starts.
  final Duration delay;
}

class EarthDetectiveMission {
  const EarthDetectiveMission({
    required this.id,
    required this.title,
    required this.briefLine,
    required this.sceneAsset,
    this.secondarySceneAsset,
    required this.badgeAsset,
    required this.interactionMode,
    required this.clueHitZone,
    required this.clueProximityZone,
    required this.openLines,
    required this.instructionText,
    required this.hints,
    required this.successMessage,
    required this.impactExplanation,
    required this.overlays,
  });

  /// Stable id (e.g. `cyclone_eye`) — also the analytics key.
  final String id;

  /// Short mission title, e.g. "Find the Cyclone Eye".
  final String title;

  /// One-line set-up shown under the title on the play screen
  /// (storyboard frame 4), e.g. "There is a big storm over the ocean…".
  final String briefLine;

  /// Flame-relative scene image. For [InteractionMode.compareBeforeAfter] this
  /// is the BEFORE image; [secondarySceneAsset] is the AFTER image.
  final String sceneAsset;
  final String? secondarySceneAsset;

  /// Full Flutter asset path for the badge (rendered in Flutter widgets).
  final String badgeAsset;

  final InteractionMode interactionMode;

  /// Exact clue area (normalised). A tap inside → correct.
  final Rect clueHitZone;

  /// Looser region (normalised). Scanner switches to "near clue" inside it.
  final Rect clueProximityZone;

  /// Orbit's mission-open monologue — the bubble auto-advances through these
  /// until the child starts scanning.
  final List<String> openLines;

  /// The task line, e.g. "Find the cyclone eye." (bottom instruction card).
  final String instructionText;

  /// Two escalating hints (PRD §14.4).
  final List<String> hints;

  /// Short on-stage success line (CLUE FOUND banner area).
  final String successMessage;

  /// Why it matters (impact screen).
  final String impactExplanation;

  /// Clue-reveal overlays composited on success.
  final List<MissionOverlayConfig> overlays;

  /// Convenience centre of the hit zone.
  Offset get clueCenter => clueHitZone.center;
}
