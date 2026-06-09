// The six Earth Detective missions. Copy is taken VERBATIM from the PRD (§9).
// Hit / proximity zones are normalised (0..1) estimates read off the actual
// scene art — the PRD (§16) explicitly expects these to be fine-tuned on device
// after the first prototype. Tune by editing one number here; nothing else
// depends on pixels.

import 'package:flutter/widgets.dart';

import '../models/earth_detective_mission.dart';
import 'asset_paths.dart';

/// Non-mission Mission-Control copy (intro / tutorial / finale).
class EdCopy {
  EdCopy._();

  static const episodeLabel = 'EPISODE 8';
  static const title = 'Earth Detective';
  static const introQuestion = 'What can we learn\nfrom satellite images?';
  static const startCta = 'Start Mission';

  /// Orbit's intro monologue — the bubble auto-advances through these.
  static const introLines = [
    'Hey detective! I just got new pictures from our satellite.',
    'Satellites see Earth from high above, so they can spot big clues we might miss on the ground.',
    'See these clouds, rivers, fields, smoke, and colors? They all tell us something about Earth.',
    'Come on — help me read the clues!',
  ];

  static const tutorialTitle = 'Mission Tutorial';
  static const tutorialLine1 = 'This is our scanner. Drag it around the picture with your finger.';
  static const tutorialLine2 = 'When it starts glowing, we are getting close to an important clue.';
  static const tutorialLine3 = 'When we are right on the clue, tap to lock it!';
  static const tutorialLines = [tutorialLine1, tutorialLine2, tutorialLine3];
  static const tutorialCta = 'Got It!';

  static const selectTitle = 'EARTH DETECTIVE MISSION';
  static const selectProgressLabel = 'DETECTIVE PROGRESS';
  static const selectMascot = 'Each clue you find helps protect people!';

  static const wrongGeneric = "Good try! Let's look again for the strongest clue in the picture.";
  static const wrongRepeated =
      "No worries. I'll help — try scanning near the area that looks most different.";
  static const dragPrompt = 'Drag Scanner';
  static const scanHint = "Move the scanner around. I'll glow when we get close!";
  static const nearPrompt = "Ooh, we're getting warmer! Keep scanning this area.";
  static const lockPrompt = "Yes! We're right on it. Tap to lock the clue!";

  static const summaryTitle = 'Mission Complete!';
  static const summaryHeadline = 'You found all 6 clues!';

  /// Orbit's summary monologue — the bubble auto-advances through these.
  static const summaryLines = [
    'You did it! You found storms, floods, dry farms, fires, ships, and forest changes from satellite images.',
    'Because of you, the warning can be sent early.',
    'You are an amazing Earth Detective!',
  ];

  static const rewardTitle = 'Mission Accomplished';
  static const rewardHeadline = 'Because of you,\nthe warning can be sent early.';
  static const rewardSub = 'You used satellite images to protect Earth!';
  static const rewardBadgeLabel = 'EARTH DETECTIVE';
  static const completeBanner = 'Earth Detective Mission Complete';
  static const backToMapCta = 'Back to Map';
}

final List<EarthDetectiveMission> kMissions = [
  // ── Mission 1 — Cyclone ────────────────────────────────────────────────
  EarthDetectiveMission(
    id: 'cyclone_eye',
    title: 'Find the Cyclone Eye',
    briefLine: 'There is a big storm over the ocean.\nFind the calm center (eye) of the cyclone.',
    sceneAsset: EdAssets.sceneCyclone,
    badgeAsset: edFlutter(EdAssets.badgeCyclone),
    interactionMode: InteractionMode.scanAndTap,
    clueHitZone: const Rect.fromLTWH(0.375, 0.365, 0.13, 0.17),
    clueProximityZone: const Rect.fromLTWH(0.27, 0.25, 0.34, 0.40),
    openLines: [
      'Whoa, look at that huge spinning storm over the ocean!',
      'That calm round center is called the eye of the cyclone.',
      'Can you help me find the cyclone eye?',
    ],
    instructionText: 'Find the cyclone eye.',
    hints: [
      'Look near the middle of the spinning clouds.',
      'The eye usually looks rounder and clearer than the cloudy storm around it.',
    ],
    successMessage: 'Yes! You found the cyclone eye!',
    impactExplanation:
        'Great catch. Now coastal teams can prepare early before the storm reaches people.',
    overlays: [
      MissionOverlayConfig(
        asset: EdAssets.ovCycloneRing,
        centerNorm: const Offset(0.44, 0.45),
        widthFactor: 0.24,
        anim: OverlayAnim.pulse,
      ),
      MissionOverlayConfig(
        asset: EdAssets.ovCyclonePulse,
        centerNorm: const Offset(0.44, 0.45),
        widthFactor: 0.52,
        anim: OverlayAnim.fadePulse,
        delay: Duration(milliseconds: 180),
      ),
    ],
  ),

  // ── Mission 2 — Flood ──────────────────────────────────────────────────
  EarthDetectiveMission(
    id: 'flooded_village',
    title: 'Spot the Flooded Village',
    briefLine: 'Heavy rain has caused flooding.\nFind the village that needs help.',
    sceneAsset: EdAssets.sceneFlood,
    badgeAsset: edFlutter(EdAssets.badgeFlood),
    interactionMode: InteractionMode.scanAndTap,
    // village roof-cluster measured at norm (0.54, 0.51) in the v2 scene
    clueHitZone: const Rect.fromLTWH(0.43, 0.43, 0.20, 0.20),
    clueProximityZone: const Rect.fromLTWH(0.32, 0.32, 0.42, 0.42),
    openLines: [
      'Oh no, look at that river. It has overflowed after heavy rain.',
      'Some roads, homes, and fields may be covered by floodwater.',
      'Can you help me find the flooded village?',
    ],
    instructionText: 'Spot the flooded village.',
    hints: [
      'Scan near the muddy river water.',
      'Look for houses that are surrounded by water.',
    ],
    successMessage: 'You found the flooded village!',
    impactExplanation:
        'Now rescue teams know which village needs help, so they can go to the right place.',
    overlays: [
      MissionOverlayConfig(
        asset: EdAssets.ovFloodArea,
        centerNorm: const Offset(0.53, 0.53),
        widthFactor: 0.52,
        anim: OverlayAnim.fadePulse,
      ),
      MissionOverlayConfig(
        asset: EdAssets.ovFloodMarker,
        centerNorm: const Offset(0.53, 0.50),
        widthFactor: 0.13,
        anim: OverlayAnim.pinDrop,
        delay: Duration(milliseconds: 220),
      ),
    ],
  ),

  // ── Mission 3 — Dry farm ───────────────────────────────────────────────
  EarthDetectiveMission(
    id: 'dry_farm',
    title: 'Find the Dry Farm',
    briefLine: 'Some fields are healthy and green.\nFind the field that has gone dry.',
    sceneAsset: EdAssets.sceneDryFarm,
    badgeAsset: edFlutter(EdAssets.badgeDrought),
    interactionMode: InteractionMode.scanAndTap,
    clueHitZone: const Rect.fromLTWH(0.42, 0.38, 0.16, 0.18),
    clueProximityZone: const Rect.fromLTWH(0.31, 0.27, 0.38, 0.40),
    openLines: [
      'Look at these farms from above. Some fields are green, but one looks dry.',
      'Healthy crops often look greener. Dry fields can look brown, pale, or cracked.',
      'Can you find the dry farm?',
    ],
    instructionText: 'Find the dry farm.',
    hints: [
      'Compare the colors of the fields.',
      'The dry field looks much browner than the healthy green fields.',
    ],
    successMessage: 'Nice! You found the dry farm!',
    impactExplanation:
        'That helps farmers know where crops may need water before it is too late.',
    overlays: [
      MissionOverlayConfig(
        asset: EdAssets.ovDryOutline,
        centerNorm: const Offset(0.50, 0.46),
        widthFactor: 0.30,
        anim: OverlayAnim.pulse,
      ),
      MissionOverlayConfig(
        asset: EdAssets.ovCropStress,
        centerNorm: const Offset(0.50, 0.46),
        widthFactor: 0.30,
        anim: OverlayAnim.fadePulse,
        delay: Duration(milliseconds: 200),
      ),
    ],
  ),

  // ── Mission 4 — Forest fire (follow the smoke trail) ───────────────────
  EarthDetectiveMission(
    id: 'forest_fire',
    title: 'Find the Forest Fire',
    briefLine: 'Smoke is rising from the forest.\nFollow it back to the fire source.',
    sceneAsset: EdAssets.sceneForestFire,
    badgeAsset: edFlutter(EdAssets.badgeFire),
    interactionMode: InteractionMode.followTrail,
    clueHitZone: const Rect.fromLTWH(0.33, 0.52, 0.15, 0.17),
    clueProximityZone: const Rect.fromLTWH(0.24, 0.42, 0.36, 0.38),
    openLines: [
      // bridge beat after Mission 3
      "You're getting really good at this. You're reading Earth patterns — shapes, colors, water, and smoke can all tell a story.",
      'Uh-oh, I see smoke over the forest.',
      'Satellites can spot smoke and heat from space, even before a fire spreads too far.',
      'Can you find where the fire started?',
    ],
    instructionText: 'Follow the smoke and find the fire source.',
    hints: [
      "Don't tap the biggest smoke cloud. Follow the smoke back to where it begins.",
      'The fire source is near the start of the smoke trail.',
    ],
    successMessage: 'Fire source found!',
    impactExplanation:
        'Now firefighters can reach the right area faster and stop the fire from spreading.',
    overlays: [
      MissionOverlayConfig(
        asset: EdAssets.ovFireHeat,
        centerNorm: const Offset(0.405, 0.605),
        widthFactor: 0.24,
        anim: OverlayAnim.fadePulse,
      ),
      MissionOverlayConfig(
        asset: EdAssets.ovSmokeRing,
        centerNorm: const Offset(0.405, 0.605),
        widthFactor: 0.28,
        anim: OverlayAnim.pulse,
        delay: Duration(milliseconds: 200),
      ),
    ],
  ),

  // ── Mission 5 — Ship (zoom + tap) ──────────────────────────────────────
  EarthDetectiveMission(
    id: 'ship_ocean',
    title: 'Find the Ship in the Ocean',
    briefLine: 'The ocean is huge.\nZoom in and find the tiny ship.',
    sceneAsset: EdAssets.sceneShip,
    badgeAsset: edFlutter(EdAssets.badgeShip),
    interactionMode: InteractionMode.zoomAndTap,
    // ship + wake measured at norm (0.52, 0.53) via bright-streak detection
    clueHitZone: const Rect.fromLTWH(0.455, 0.465, 0.13, 0.13),
    clueProximityZone: const Rect.fromLTWH(0.35, 0.36, 0.34, 0.34),
    openLines: [
      "Look at this giant ocean. It's so big that a ship can look tiny from space.",
      'But satellites can still spot ships and their white trails.',
      'Can you find the ship?',
    ],
    instructionText: 'Find the ship in the ocean.',
    hints: [
      'Use the scanner and look for a tiny shape with a white trail behind it.',
      'That white trail is called a wake. Ships leave it behind as they move through water.',
    ],
    successMessage: 'Ship located!',
    impactExplanation:
        'Great work. Satellites can help track boats across huge oceans where there are no roads or signs.',
    overlays: [
      MissionOverlayConfig(
        asset: EdAssets.ovShipWake,
        centerNorm: const Offset(0.525, 0.545),
        widthFactor: 0.20,
        anim: OverlayAnim.fadePulse,
      ),
      MissionOverlayConfig(
        asset: EdAssets.ovShipMarker,
        centerNorm: const Offset(0.52, 0.53),
        widthFactor: 0.11,
        anim: OverlayAnim.pulse,
        delay: Duration(milliseconds: 160),
      ),
      MissionOverlayConfig(
        asset: EdAssets.ovCoordPin,
        centerNorm: const Offset(0.52, 0.455),
        widthFactor: 0.10,
        anim: OverlayAnim.pinDrop,
        delay: Duration(milliseconds: 340),
      ),
    ],
  ),

  // ── Mission 6 — Before/After forest change ─────────────────────────────
  EarthDetectiveMission(
    id: 'forest_change',
    title: 'Compare Before / After',
    briefLine: 'Slide the bar to compare the images.\nFind where the forest has disappeared.',
    sceneAsset: EdAssets.sceneForestBefore,
    secondarySceneAsset: EdAssets.sceneForestAfter,
    badgeAsset: edFlutter(EdAssets.badgeForestChange),
    interactionMode: InteractionMode.compareBeforeAfter,
    // brown clearing in the v2 after-image measured at norm (0.68, 0.58)
    clueHitZone: const Rect.fromLTWH(0.56, 0.46, 0.24, 0.24),
    clueProximityZone: const Rect.fromLTWH(0.46, 0.36, 0.44, 0.44),
    openLines: [
      "Now let's do a real detective comparison.",
      'This is the same forest seen at two different times.',
      'Move the divider and look for what changed.',
    ],
    instructionText: 'Slide to compare, then tap where the forest disappeared.',
    hints: [
      'Slide slowly and watch for brown patches replacing green forest.',
      'The changed area is where thick trees became open brown land.',
    ],
    successMessage: 'You found the forest change!',
    impactExplanation:
        'Now forest protection teams know where trees disappeared, because the satellite compared the same place over time.',
    overlays: [
      MissionOverlayConfig(
        asset: EdAssets.ovDeforestation,
        centerNorm: const Offset(0.68, 0.58),
        widthFactor: 0.38,
        anim: OverlayAnim.sweep,
      ),
    ],
  ),
];

/// Orbit voice clips, keyed by the EXACT dialogue text (choke-point voicing —
/// the controller stamps `voiceClip` whenever `helperMessage` changes to a
/// mapped line). Built from the same constants the UI renders, in the master
/// recording order (`orbit_01..58.wav`), so text and audio can never drift
/// apart silently — but if a line is reworded WITHOUT re-recording, it simply
/// loses its voice (re-record + keep this order).
final Map<String, int> orbitClipFor = _buildClipMap();

Map<String, int> _buildClipMap() {
  final m = <String, int>{};
  var n = 1;
  void add(String s) => m[s] = n++;
  EdCopy.introLines.forEach(add); // 1-4
  EdCopy.tutorialLines.forEach(add); // 5-7
  add(EdCopy.scanHint); // 8
  add(EdCopy.nearPrompt); // 9
  add(EdCopy.lockPrompt); // 10
  add(EdCopy.wrongGeneric); // 11
  add(EdCopy.wrongRepeated); // 12
  for (final mi in kMissions) {
    // 13..55: openLines…, hint1, hint2, success, impact — per mission
    mi.openLines.forEach(add);
    mi.hints.forEach(add);
    add(mi.successMessage);
    add(mi.impactExplanation);
  }
  EdCopy.summaryLines.forEach(add); // 56-58
  assert(n - 1 == 58, 'orbit clip map expects 58 lines, got ${n - 1}');
  return m;
}
