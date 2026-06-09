// Centralised asset registry for the "Earth Detective Mission" activity
// (Episode 8, Satellite Engineer). Paths are stored in the FLAME-relative form
// (what `game.images.load(...)` expects — relative to the `assets/images/`
// prefix). Use [edFlutter] to get the full `assets/images/...` path that
// `Image.asset` / `AssetImage` need in Flutter widgets.
//
// Never hardcode a sprite filename anywhere else — add it here.

/// Full Flutter asset path from a Flame-relative path.
String edFlutter(String flameRelative) => 'assets/images/$flameRelative';

class EdAssets {
  EdAssets._();

  static const _base = 'earth_detective';

  // Scenes (opaque JPEG, 4:3) — rendered on the Flame stage.
  static const sceneCyclone = '$_base/scenes/satellite_scene_cyclone_ocean.jpg';
  // _v2: replaced art (S3 objects are cached immutable for 1 year — renaming
  // is the only safe way to ship a changed image).
  static const sceneFlood = '$_base/scenes/satellite_scene_flooded_village_v2.jpg';
  static const sceneDryFarm = '$_base/scenes/satellite_scene_dry_farm.jpg';
  static const sceneForestFire = '$_base/scenes/satellite_scene_forest_fire.jpg';
  static const sceneShip = '$_base/scenes/satellite_scene_ship_ocean.jpg';
  static const sceneForestBefore = '$_base/scenes/satellite_scene_forest_before.jpg';
  // _v2: replaced art (rename rule — see sceneFlood note above).
  static const sceneForestAfter = '$_base/scenes/satellite_scene_forest_after_v2.jpg';

  // Scanner states.
  static const scannerIdle = '$_base/scanner/scanner_lens_idle.png';
  static const scannerNear = '$_base/scanner/scanner_lens_near_clue.png';
  static const scannerLock = '$_base/scanner/scanner_lens_lock_on.png';
  static const scannerFlash = '$_base/scanner/scanner_success_flash.png';
  static const scannerSweep = '$_base/scanner/scanner_sweep_line.png';

  // Overlays (clue reveals).
  static const ovCycloneRing = '$_base/overlays/overlay_cyclone_eye_ring.png';
  static const ovCyclonePulse = '$_base/overlays/overlay_cyclone_spiral_pulse.png';
  static const ovFloodArea = '$_base/overlays/overlay_flood_blue_area.png';
  static const ovFloodMarker = '$_base/overlays/overlay_flood_village_marker.png';
  static const ovDryOutline = '$_base/overlays/overlay_dry_field_amber_outline.png';
  static const ovCropStress = '$_base/overlays/overlay_crop_stress_pulse.png';
  static const ovFireHeat = '$_base/overlays/overlay_fire_heat_zone.png';
  static const ovSmokeRing = '$_base/overlays/overlay_smoke_source_ring.png';
  static const ovShipMarker = '$_base/overlays/overlay_ship_lock_marker.png';
  static const ovShipWake = '$_base/overlays/overlay_ship_wake_highlight.png';
  static const ovCoordPin = '$_base/overlays/overlay_coordinate_pin.png';
  static const ovDeforestation = '$_base/overlays/overlay_deforestation_red_boundary.png';

  // Backgrounds.
  static const bgMissionControl = '$_base/backgrounds/bg_mission_control_earth_observation.jpg';
  static const bgSpace = '$_base/backgrounds/bg_space_soft_stars.jpg';
  static const earthHologram = '$_base/backgrounds/earth_hologram_orb.png';
  static const satelliteTiny = '$_base/backgrounds/satellite_orbit_tiny.png';
  static const signalBeam = '$_base/backgrounds/satellite_signal_beam.png';

  // Mascot poses (bright robo set — mapped to the situation).
  static const mascotWelcoming = '$_base/mascot/mascot_welcoming.png'; // intro
  static const mascotPointingRight = '$_base/mascot/mascot_pointing_right.png'; // tutorial
  static const mascotGuiding = '$_base/mascot/mascot_guiding.png'; // explaining / info
  static const mascotThinking = '$_base/mascot/mascot_thinking.png'; // curious / scanning
  static const mascotConcerned = '$_base/mascot/mascot_concerned.png'; // supportive / wrong tap
  static const mascotCelebrate = '$_base/mascot/mascot_celebrating.png'; // clue found
  static const mascotHappy = '$_base/mascot/mascot_happy.png'; // proud / finale
  static const mascotExplaining = '$_base/mascot/robo_explaining.png';
  static const mascotCurious = '$_base/mascot/robo_curious.png';
  static const mascotSupportive = '$_base/mascot/robo_supportive.png';
  static const mascotCelebrating = '$_base/mascot/robo_celebrating.png';
  static const mascotProud = '$_base/mascot/robo_proud_final.png';

  // Badges (shown in Flutter — rail, summary, reward).
  static const badgeCyclone = '$_base/badges/badge_icon_cyclone.png';
  static const badgeFlood = '$_base/badges/badge_icon_flood.png';
  static const badgeDrought = '$_base/badges/badge_icon_drought.png';
  static const badgeFire = '$_base/badges/badge_icon_fire.png';
  static const badgeShip = '$_base/badges/badge_icon_ship.png';
  static const badgeForestChange = '$_base/badges/badge_icon_forest_change.png';
  static const badgeEarthDetective = '$_base/badges/badge_earth_detective_icon.png';

  // Comparison (before/after slider).
  static const cmpHandle = '$_base/comparison/before_after_slider_handle.png';
  static const cmpDivider = '$_base/comparison/comparison_divider_glow.png';
  static const cmpRevealEdge = '$_base/comparison/comparison_reveal_edge_glow.png';
  static const cmpSweep = '$_base/comparison/change_detection_sweep_band.png';

  // Effects.
  static const fxDataStream = '$_base/effects/effect_data_stream_particles.png';
  static const fxScanGrid = '$_base/effects/effect_scan_grid_overlay.png';
  static const fxAlertPulse = '$_base/effects/effect_alert_pulse_ring.png';
  static const fxSuccessGlow = '$_base/effects/effect_success_glow_ring.png';
  static const fxWarningWave = '$_base/effects/effect_warning_sent_wave.png';
  static const fxIncomingBeam = '$_base/effects/effect_new_image_incoming_beam.png';
  static const fxCompleteBurst = '$_base/effects/effect_mission_complete_burst.png';

  /// Sprites the Flame stage preloads up-front (scenes are loaded lazily per
  /// mission to keep startup light).
  static const stagePreload = <String>[
    scannerIdle, scannerNear, scannerLock, scannerFlash, scannerSweep,
    fxSuccessGlow, fxAlertPulse,
    cmpHandle, cmpDivider, cmpRevealEdge, cmpSweep,
  ];
}

/// Intrinsic width/height aspect ratios of the processed sprites, captured at
/// asset-processing time. Lets the stage place overlays by (centre, widthFactor)
/// without decoding images at runtime. Defaults to 1.0 if a path is missing.
const Map<String, double> kEdAspect = {
  EdAssets.scannerIdle: 0.9906,
  EdAssets.scannerNear: 0.9297,
  EdAssets.scannerLock: 1.0079,
  EdAssets.scannerFlash: 1.0031,
  EdAssets.scannerSweep: 0.9889,
  EdAssets.ovCycloneRing: 1.0047,
  EdAssets.ovCyclonePulse: 1.024,
  EdAssets.ovFloodArea: 1.2355,
  EdAssets.ovFloodMarker: 0.6891,
  EdAssets.ovDryOutline: 1.3278,
  EdAssets.ovCropStress: 1.1015,
  EdAssets.ovFireHeat: 1.0191,
  EdAssets.ovSmokeRing: 1.0031,
  EdAssets.ovShipMarker: 0.9889,
  EdAssets.ovShipWake: 0.4656,
  EdAssets.ovCoordPin: 0.7078,
  EdAssets.ovDeforestation: 1.0922,
  EdAssets.earthHologram: 0.9646,
  EdAssets.satelliteTiny: 1.317,
  EdAssets.signalBeam: 0.649,
  EdAssets.fxSuccessGlow: 1.0535,
  EdAssets.fxAlertPulse: 0.9948,
  EdAssets.fxWarningWave: 4.7117,
  EdAssets.fxIncomingBeam: 0.3307,
  EdAssets.fxCompleteBurst: 1.0336,
  EdAssets.cmpHandle: 0.207,
  EdAssets.cmpDivider: 0.1419,
  EdAssets.cmpRevealEdge: 0.1237,
  EdAssets.cmpSweep: 0.3229,
};

double edAspectOf(String asset) => kEdAspect[asset] ?? 1.0;

class EdSounds {
  EdSounds._();

  // Reused project SFX (light + warm — PRD §17, no harsh buzzers).
  static const imagePing = 'jumpSound.mp3';
  static const scannerPickup = 'jumpSound.mp3';
  static const lockOn = 'jumpSound.mp3';
  static const correct = 'correct_answer.mp3';
  static const wrongSoft = 'incorrect_answer.mp3';
  static const complete = 'levelComplete.mp3';

  // Looping ambient bed (AssetSource is relative to assets/ — no prefix).
  static const bgm = 'sounds/earth_detective/bgm.mp3';

  /// Orbit voice clip path for clip number 1..58.
  static String orbitClip(int n) =>
      'sounds/earth_detective/orbit/orbit_${n.toString().padLeft(2, '0')}.wav';
}
