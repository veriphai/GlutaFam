// Centralised asset registry for the "Choose the Right Satellite" activity
// (PRD §24.4 — asset paths centralised, never hardcoded in widgets). Pure
// Flutter module, so every path is the FULL `assets/images/...` path that
// `Image.asset` / `AssetImage` expect. SFX live at the project `assets/` root
// and are played via audioplayers `AssetSource`, which prefixes `assets/`.

class CrsAssets {
  CrsAssets._();

  static const _base = 'assets/images/choose_right_satellite';

  // Backgrounds
  static const missionControlBg = '$_base/backgrounds/mission_control_background.jpg';
  static const earthHologram = '$_base/backgrounds/earth_hologram.png';

  // Satellites
  static const satelliteNavigation = '$_base/satellites/satellite_navigation.png';
  static const satelliteWeather = '$_base/satellites/satellite_weather.png';
  static const satelliteCommunication = '$_base/satellites/satellite_communication.png';
  static const satelliteEarthObservation = '$_base/satellites/satellite_earth_observation.png';

  // Mission scene sprites
  static const fishermanBoat = '$_base/missions/mission_fisherman_boat.png';
  static const oceanPatch = '$_base/missions/mission_ocean_patch.png';
  static const sosBeacon = '$_base/missions/mission_sos_beacon.png';
  static const locationPin = '$_base/missions/mission_location_pin.png';
  static const cycloneStorm = '$_base/missions/mission_cyclone_storm.png';
  static const cloudOverlayWhite = '$_base/missions/mission_cloud_overlay_white.png';
  static const remoteVillage = '$_base/missions/mission_remote_village.png';
  static const wifiSymbol = '$_base/missions/mission_wifi_symbol.png';
  static const cityBroadcastScene = '$_base/missions/mission_city_broadcast_scene.png';
  static const liveTvScreen = '$_base/missions/mission_live_tv_screen.png';
  static const broadcastTower = '$_base/missions/mission_broadcast_tower.png';
  static const forestFireScene = '$_base/missions/mission_forest_fire_scene.png';
  static const smokeOverlay = '$_base/missions/mission_smoke_overlay.png';

  // Effects
  static const cameraScanCone = '$_base/effects/effect_camera_scan_cone.png';
  static const communicationWaves = '$_base/effects/effect_communication_waves.png';
  static const dispatchGlowRing = '$_base/effects/effect_dispatch_glow_ring.png';
  static const dispatchTargetPulse = '$_base/effects/effect_dispatch_target_pulse.png';
  static const dragTrail = '$_base/effects/effect_drag_trail.png';
  static const gpsBeam = '$_base/effects/effect_gps_beam.png';
  static const snapFlash = '$_base/effects/effect_snap_flash.png';
  static const successBurst = '$_base/effects/effect_success_burst.png';
  static const successGlow = '$_base/effects/effect_success_glow.png';
  static const weatherScanRings = '$_base/effects/effect_weather_scan_rings.png';
  static const wrongPulse = '$_base/effects/effect_wrong_pulse.png';

  // Mascot
  static const mascotWelcoming = '$_base/mascot/mascot_welcoming.png';
  static const mascotGuiding = '$_base/mascot/mascot_guiding.png';
  static const mascotCelebrating = '$_base/mascot/mascot_celebrating.png';
  static const mascotThinking = '$_base/mascot/mascot_thinking.png';
  static const mascotPointingRight = '$_base/mascot/mascot_pointing_right.png';
  static const mascotHappy = '$_base/mascot/mascot_happy.png';
  static const mascotConcerned = '$_base/mascot/mascot_concerned.png';

  // Icons
  static const iconNavigationPin = '$_base/icons/icon_navigation_pin.png';
  static const iconWeatherCloudRain = '$_base/icons/icon_weather_cloud_rain.png';
}

/// Intrinsic width/height aspect ratios of the processed sprites, captured at
/// asset-processing time. Used to position scene layers precisely by
/// (centerFactor, widthFactor) without decoding images at runtime. Default 1.0
/// if a path is missing.
const Map<String, double> kCrsAspect = {
  CrsAssets.satelliteNavigation: 1.013,
  CrsAssets.satelliteWeather: 1.116,
  CrsAssets.satelliteCommunication: 1.433,
  CrsAssets.satelliteEarthObservation: 1.207,
  CrsAssets.fishermanBoat: 1.026,
  CrsAssets.oceanPatch: 1.514,
  CrsAssets.sosBeacon: 0.632,
  CrsAssets.locationPin: 0.898,
  CrsAssets.cycloneStorm: 1.143,
  CrsAssets.cloudOverlayWhite: 1.547,
  CrsAssets.remoteVillage: 1.145,
  CrsAssets.wifiSymbol: 1.124,
  CrsAssets.cityBroadcastScene: 0.891,
  CrsAssets.liveTvScreen: 0.977,
  CrsAssets.broadcastTower: 0.580,
  CrsAssets.forestFireScene: 0.795,
  CrsAssets.smokeOverlay: 0.775,
  CrsAssets.cameraScanCone: 0.828,
  CrsAssets.communicationWaves: 0.775,
  CrsAssets.gpsBeam: 0.736,
  CrsAssets.weatherScanRings: 1.133,
  CrsAssets.snapFlash: 0.967,
  CrsAssets.successGlow: 0.986,
  CrsAssets.dispatchGlowRing: 1.0,
  CrsAssets.dispatchTargetPulse: 1.002,
  CrsAssets.wrongPulse: 1.002,
};

double crsAspectOf(String asset) => kCrsAspect[asset] ?? 1.0;

class CrsSounds {
  CrsSounds._();

  // Reused project SFX (no harsh buzzers — PRD §20). Paths are relative to the
  // project `assets/` root (audioplayers' AssetSource prefixes `assets/`).
  static const dragPickup = 'jumpSound.mp3';
  static const wrongSoft = 'incorrect_answer.mp3';
  static const activityComplete = 'levelComplete.mp3';

  // Synthesised, royalty-free scene sounds (assets/sounds/choose_right_satellite/).
  // Each is drop-in replaceable: keep the filename to swap in a Pixabay clip.
  static const _dir = 'sounds/choose_right_satellite';

  // Per-mission ambient loops (played quietly under each scene).
  static const ambWaves = '$_dir/amb_waves.mp3';
  static const ambStorm = '$_dir/amb_storm.mp3';
  static const ambVillage = '$_dir/amb_village.mp3';
  static const ambCity = '$_dir/amb_city.mp3';
  static const ambFire = '$_dir/amb_fire.mp3';
  static const ambControl = '$_dir/amb_control.mp3'; // Mission Control room tone

  // Per-mission success stings (one-shot on correct dispatch).
  static const stingLocate = '$_dir/sting_locate.mp3';
  static const stingRadar = '$_dir/sting_radar.mp3';
  static const stingConnect = '$_dir/sting_connect.mp3';
  static const stingBroadcast = '$_dir/sting_broadcast.mp3';
  static const stingCamera = '$_dir/sting_camera.mp3';

  // Global UI.
  static const missionAlert = '$_dir/ui_alert.mp3';
  static const finishFanfare = '$_dir/ui_finish.mp3';

  // Looping background music bed (plays for the whole activity, under
  // ambient + voice).
  static const bgm = '$_dir/bgm.mp3';

  /// Orbit voice-over clip N (1–37, master-script order; see orbit_script.dart).
  /// AssetSource path — audioplayers prefixes `assets/`.
  static String orbitClip(int n) => '$_dir/orbit/orbit_${n.toString().padLeft(2, '0')}.mp3';
}
