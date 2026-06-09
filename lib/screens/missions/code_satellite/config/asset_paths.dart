// Central registry of processed "Code the Satellite" sprites (Activity 10).
//
// WHERE ASSETS LIVE: cleaned, alpha-transparent PNGs under
// `assets/images/code_satellite/<subdir>/`. The kit arrived already cut out
// (real alpha, transparent corners) so it was only trimmed-to-bbox + downscaled
// — NOT flood-filled (that would have erased Orbit's white body + the white
// success glows). Only `effects/sparkle_burst.png` was re-stripped (it shipped
// on a dark checkerboard) and renders additive.
//
// Two path flavours (same convention as signal_rescue / orbit_launcher):
//  • Flame `images.load` wants the path relative to `assets/images/`
//    → `code_satellite/states/x.png`  (use `.flame`).
//  • Flutter `Image.asset` wants the full path
//    → `assets/images/code_satellite/...`  (use `.flutter`).
//
// All command-block / slot FRAMES are drawn in Flutter (the baked block sprites
// ship at mismatched sizes); only the command ICON cut-outs are used as art.

class CS {
  CS._();

  // ── characters ──────────────────────────────────────────────────────────────
  // The curious kid avatar (the "YOU" speaker in the intro) — reused from
  // how_much_can_you_see, copied into this module so it stays self-contained.
  static const kidCurious = 'characters/kid_curious.png';

  // ── satellite states (one canonical 3/4 render per command) ─────────────────
  static const satIdle = 'states/satellite_idle_hover.png';
  static const satWakeUp = 'states/satellite_wake_up_active.png';
  static const satBattery = 'states/satellite_check_battery_state.png';
  static const satSolar = 'states/satellite_panels_pointed_to_sun.png';
  static const satCamera = 'states/satellite_camera_aimed_at_earth.png';
  static const satPicture = 'states/satellite_take_picture_state.png';
  static const satStore = 'states/satellite_store_data_state.png';
  static const satAntenna = 'states/satellite_antenna_aimed_ground_station.png';
  static const satSend = 'states/satellite_send_data_state.png';
  static const satSafeMode = 'states/satellite_safe_mode_state.png';
  static const satError = 'states/satellite_error_state.png';
  static const satSuccess = 'states/satellite_success_state.png';

  // ── Orbit mascot ────────────────────────────────────────────────────────────
  static const orbitIdle = 'mascot/orbit_idle.png';
  static const orbitWave = 'mascot/orbit_welcoming_wave.png';
  static const orbitPointing = 'mascot/orbit_pointing.png';
  static const orbitExplaining = 'mascot/orbit_explaining.png';
  static const orbitAlert = 'mascot/orbit_alert.png';
  static const orbitThinking = 'mascot/orbit_thinking.png';
  static const orbitDebug = 'mascot/orbit_debug_mode.png';
  static const orbitCelebrate = 'mascot/orbit_celebrate.png';
  static const orbitSuccessJump = 'mascot/orbit_success_jump.png';

  // ── command icons (used inside Flutter-drawn blocks) ────────────────────────
  static const iconWakeUp = 'icons/icon_wake_up.png';
  static const iconCheckBattery = 'icons/icon_check_battery.png';
  static const iconSolar = 'icons/icon_point_solar_panel_to_sun.png';
  static const iconCamera = 'icons/icon_point_camera_to_earth.png';
  static const iconTakePicture = 'icons/icon_take_picture.png';
  static const iconStoreData = 'icons/icon_store_data.png';
  static const iconAntenna = 'icons/icon_point_antenna_to_ground_station.png';
  static const iconSendData = 'icons/icon_send_data.png';
  static const iconSafeMode = 'icons/icon_enter_safe_mode.png';

  // ── mission props ───────────────────────────────────────────────────────────
  static const earthGlobe = 'props/earth_globe.png';
  static const earthCyclone = 'props/earth_with_cyclone_zone.png';
  static const sun = 'props/sun_glowing.png';
  static const groundStation = 'props/ground_station_dish.png';
  static const missionControl = 'props/mission_control_screen.png';
  static const dataPacketCube = 'props/data_packet_cube.png';
  static const capturedThumb = 'props/captured_image_thumbnail_generic.png';
  static const dataStorageChip = 'props/data_storage_chip.png';

  // ── effects (additive on the dark stage) ────────────────────────────────────
  static const fxBatteryRing = 'effects/battery_scan_ring.png';
  static const fxCameraFlash = 'effects/camera_flash.png';
  static const fxCameraBeam = 'effects/camera_scan_beam.png';
  static const fxSolarParticles = 'effects/solar_energy_particles.png';
  static const fxPulseRing = 'effects/pulse_ring.png';
  static const fxSignalWaves = 'effects/signal_waves_blue.png';
  static const fxSignalLink = 'effects/signal_link_line.png';
  static const fxTransmitBeam = 'effects/data_transmission_beam.png';
  static const fxPacketTrail = 'effects/data_packet_trail.png';
  static const fxSafeShield = 'effects/safe_mode_shield_effect.png';
  static const fxThruster = 'effects/thruster_jet_blue.png';
  static const fxEnergyArc = 'effects/energy_arc.png';
  static const fxCorrectGlow = 'effects/correct_drop_glow_green.png';
  static const fxWarningGlow = 'effects/warning_glow_orange.png';
  static const fxErrorFlash = 'effects/error_flash_red.png';
  static const fxSlotGlow = 'effects/slot_glow_blue.png';
  static const fxHoverShadow = 'effects/hover_shadow_glow.png';
  static const fxExecGlow = 'effects/execution_highlight_glow.png';
  static const fxSparkle = 'effects/sparkle_burst.png';
  static const fxSuccessBurst = 'effects/success_burst.png';
  static const fxMissionComplete = 'effects/mission_complete_burst.png';
  static const fxConfetti = 'effects/mini_confetti_cluster.png';
  static const fxCompletionStamp = 'effects/completion_stamp_glow.png';

  // ── rewards / environment ─────────────────────────────────────────────────
  static const badgeSatelliteCoder = 'rewards/satellite_coder_badge.png';
  static const medalSuccess = 'rewards/mission_success_medal.png';
  static const rewardStar = 'rewards/star_reward_icon.png';
  static const rewardGem = 'rewards/gem_reward_icon.png';
  static const starsSmall = 'environment/space_star_cluster_small.png';
  static const starsLarge = 'environment/space_star_cluster_large.png';
  static const glowHaze = 'environment/space_glow_haze.png';
  static const orbitalRing = 'environment/orbital_light_ring.png';

  // ── path helpers ─────────────────────────────────────────────────────────
  static String flame(String p) => 'code_satellite/$p';
  static String flutter(String p) => 'assets/images/code_satellite/$p';

  /// Everything the Flame stage preloads in onLoad (flame-prefixed).
  static List<String> get preload => [
        // satellite states
        satIdle, satWakeUp, satBattery, satSolar, satCamera, satPicture,
        satStore, satAntenna, satSend, satSafeMode, satError, satSuccess,
        // props
        earthCyclone, sun, groundStation, dataStorageChip, dataPacketCube,
        // effects used on the stage
        fxBatteryRing, fxCameraFlash, fxCameraBeam, fxSolarParticles,
        fxPulseRing, fxSignalWaves, fxSignalLink, fxTransmitBeam, fxPacketTrail,
        fxSafeShield, fxErrorFlash, fxSparkle, fxSuccessBurst, fxMissionComplete,
        fxCorrectGlow,
        // environment
        glowHaze, orbitalRing,
      ].map(flame).toList();
}

/// Existing app SFX (declared under assets/), resolved by audioplayers AssetSource.
class CSSounds {
  CSSounds._();
  static const tap = 'jumpSound.mp3';
  static const correct = 'correct_answer.mp3';
  static const wrong = 'incorrect_answer.mp3';
  static const complete = 'levelComplete.mp3';
}
