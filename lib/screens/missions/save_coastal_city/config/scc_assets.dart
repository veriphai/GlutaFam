// Central registry of processed "Save the Coastal City" sprites (Episode 11 —
// Satellite Engineer FINAL BOSS).
//
// WHERE ASSETS LIVE: cleaned, alpha-transparent PNGs (+ 6 full-bleed JPEG
// backgrounds) produced by the skill's strip_bg.py at
// `assets/images/save_coastal_city/` — a FLAT folder, so each constant
// carries its own extension. Like the other Satellite Engineer activities the
// images are NOT bundled: they're served from S3 (see lib/utils/s3_assets.dart)
// and precached at lesson start via assets/manifests/save_coastal_city.json.
//
// Two path flavours (same convention as power_balance / signal_rescue):
//  • Flame `images` cache key → `save_coastal_city/x.png`        (use `.flame`).
//  • Flutter `netImage*`      → `assets/images/save_coastal_city/...` (`.flutter`).
//
// Every sprite was eyeballed in intake (contact sheets + dark-bg previews).
// Glow / beam / ring / burst FX render additive (BlendMode.plus) over the dark
// stage. Two junk renders were dropped at prep time (camera_scope_frame,
// command_node_panel_frame — both replaced by Flutter-drawn chrome) and 8
// exact duplicate files were deduped to one canonical copy each.

class SCC {
  SCC._();

  // ── full-bleed backgrounds (JPEG, BoxFit.cover) ───────────────────────────
  static const bgEmergency = 'bg_mission_control_emergency_9x16.jpg';
  /// Intro title-card hero: Earth + cyclone + coastal city + satellite with
  /// the 8-STEP/FINAL BOSS/BADGES/SAVE THE CITY feature strip baked in.
  static const bgIntroHero = 'bg_intro_hero_9x16.jpg';
  static const bgHoloConsole = 'bg_holographic_console_9x16.jpg';
  static const bgStarfield = 'bg_space_starfield_9x16.jpg';
  static const bgCoastalStorm = 'bg_coastal_city_storm_9x16.jpg';
  static const bgCitySafe = 'bg_final_city_safe_9x16.jpg';
  /// Square Earth-from-space photo with the storm + coastline — doubles as the
  /// pannable camera-scope content in Stage 4.
  static const bgEarthStormView = 'bg_earth_coastal_city_storm_view.jpg';

  // ── Orbit mascot expressions (PRD §22.3) ──────────────────────────────────
  static const orbitNeutral = 'orbit_neutral.png';
  static const orbitExplaining = 'orbit_explaining_point.png';
  static const orbitScanning = 'orbit_scanning.png';
  static const orbitExcited = 'orbit_excited.png';
  static const orbitCelebrating = 'orbit_celebrating.png';
  static const orbitAlert = 'orbit_alert.png';
  static const orbitWorried = 'orbit_worried.png';
  static const orbitThinking = 'orbit_thinking.png';

  // ── satellite core states ─────────────────────────────────────────────────
  static const satWeatherHolo = 'sat_weather_hologram.png';
  static const satWeatherHoloStyle = 'sat_weather_hologram_style.png';
  static const satWeatherIdle = 'sat_weather_idle.png';
  static const satWeatherOrbiting = 'sat_weather_orbiting.png';
  static const satWeatherPowerMode = 'sat_weather_power_mode.png';
  static const satWeatherCameraMode = 'sat_weather_camera_mode.png';
  static const satWeatherOverheating = 'sat_weather_overheating.png';
  static const satWeatherScanningEarth = 'sat_weather_scanning_earth.png';
  static const satWeatherCloseup = 'sat_weather_closeup_modules.png';

  // ── satellite modules ─────────────────────────────────────────────────────
  static const modAntennaDish = 'sat_antenna_dish.png';
  static const modAntennaDishActive = 'sat_antenna_dish_active.png';
  static const modBatteryWarning = 'sat_battery_module_warning.png';
  static const modCameraLens = 'sat_camera_lens.png';
  static const modRadiator = 'sat_radiator_panel.png';
  static const modSolarSingle = 'sat_solar_panel_single.png';
  static const modSolarArray = 'sat_solar_panel_array.png';

  // ── stage 1 · scanner ─────────────────────────────────────────────────────
  static const holoNav = 'sat_nav_hologram.png';
  static const holoComm = 'sat_comm_hologram.png';
  static const holoEarthScan = 'sat_earthscan_hologram.png';
  static const scannerSweepLine = 'scanner_sweep_line.png';
  static const scannerDevice = 'scanner_device_icon.png';
  static const iconWeatherCloudPanel = 'icon_weather_cloud_panel.png';

  // ── stage 2 · orbit slingshot ─────────────────────────────────────────────
  static const earthCycloneCity = 'earth_cyclone_city_marker.png';
  static const slingshotBase = 'orbit_slingshot_base.png';
  static const slingshotSling = 'orbit_slingshot_energy_sling.png';
  static const launcherPlatform = 'orbit_launcher_platform.png';
  static const earthShadowArc = 'earth_shadow_orbit_arc.png';

  // ── stage 3 · power ───────────────────────────────────────────────────────
  static const sunGlow = 'sun_large_glow.png';
  static const sunBeams = 'sunlight_beams_gold.png';
  static const solarDial = 'control_solar_tilt_dial.png';
  static const batteryLever = 'control_battery_lever.png';
  static const powerMeterFrame = 'power_meter_frame.png';
  static const powerMeterFill = 'power_meter_fill_green.png';
  static const iconPowerSuccess = 'icon_power_success.png';

  // ── stage 4 · camera ──────────────────────────────────────────────────────
  /// Pannable scope content — Earth globe (with the cyclone) composited over
  /// a starfield crop at prep time (the raw "storm view" bg shipped a baked
  /// checkerboard, and the scope-view render has its UI chrome baked in).
  static const scopeContent = 'scope_content.jpg';
  /// "Photo" of the captured cyclone (scope crop around the eye) + the
  /// static-noise fill — both for the signal-rescue-style bottom-up reveal
  /// after capture. Static copied from signal_rescue (self-contained rule).
  static const capturePhoto = 'capture_photo.jpg';
  static const monitorStatic = 'monitor_static.jpg';
  static const reticleGreen = 'camera_reticle_green.png';
  static const targetLockBadge = 'camera_target_lock_badge.png';
  static const captureButtonIcon = 'button_capture_camera_icon.png';
  static const cycloneSpiral = 'cyclone_spiral_clear.png';
  static const scopeCycloneView = 'camera_scope_cyclone_target_view.png';

  // ── stage 5 · signal ──────────────────────────────────────────────────────
  static const groundStationScene = 'earth_ground_station_scene.png';
  static const dishIdle = 'ground_station_dish_idle.png';
  static const dishGlowing = 'ground_station_dish_glowing.png';
  static const tunerKnob = 'control_tuner_knob.png';
  static const dataPacketsStream = 'signal_data_packets_stream.png';
  static const monitorNoisy = 'signal_monitor_frame_noisy.png';
  static const monitorClean = 'signal_waveform_clean_panel.png';

  // ── stage 6 · analysis ────────────────────────────────────────────────────
  /// All three layers are generated from the Stage-4 captured photo (story
  /// continuity + the cyclone sits at the SAME spot in every layer): the raw
  /// photo, a thermal gradient-map, and a cyan duotone with spiral wind
  /// arrows. The original AI layer renders shipped mismatched baked frames.
  static const layerCloud = 'analysis_cloud_clean.jpg';
  static const layerRainHeat = 'analysis_heat_clean.jpg';
  static const layerWindRadar = 'analysis_wind_clean.jpg';
  static const cycloneHighlight = 'analysis_cyclone_highlight.png';
  static const tabCloudIcon = 'analysis_layer_tab_cloud_icon.png';
  static const tabHeatIcon = 'analysis_layer_tab_heat_icon.png';
  static const windFlowIcon = 'analysis_wind_flow_icon.png';
  static const scannerLens = 'analysis_scanner_lens.png';

  // ── stage 7 · thermal repair ──────────────────────────────────────────────
  /// Purpose-built rotate-the-radiator sprites (generated to spec): top-down
  /// finned panel whose canvas is CENTERED ON ITS HINGE HUB (panel extends
  /// right at 0°, so Transform.rotate pivots correctly) + a radially
  /// symmetric gimbal ring with a transparent hub hole.
  static const radiatorPanel = 'radiator_panel_topdown.png';
  static const gimbalRing = 'radiator_gimbal_ring.png';
  static const rotateRing = 'control_satellite_rotate_ring.png';
  static const powerSwitch = 'control_power_switch_base.png';
  static const tempMeter = 'thermal_temp_meter_safe_green.png';
  static const thermometer = 'energy_meter_indicator.png';

  // ── stage 8 · command upload ──────────────────────────────────────────────
  static const commandBoard = 'command_board_background.png';
  static const nodeEmpty = 'command_node_empty.png';
  static const nodeRing = 'command_connection_node_ring.png';
  static const nodeWatchStorm = 'command_node_watch_storm_icon.png';
  static const nodeCaptureImage = 'command_node_capture_image_icon.png';
  static const nodeSendData = 'command_node_send_data_icon.png';
  static const nodeCheckBattery = 'command_node_check_battery_icon.png';
  static const nodeRepeatMonitoring = 'command_node_repeat_monitoring_icon.png';
  static const nodeAlertCity = 'command_node_alert_city_icon.png';
  static const uploadButton = 'upload_button_base.png';
  static const uploadProgressBar = 'upload_progress_bar.png';
  static const uploadReceiveBeam = 'upload_satellite_receive_beam.png';

  // ── badges (PRD §21) ──────────────────────────────────────────────────────
  static const badgeSatelliteEngineer = 'badge_satellite_engineer.png';
  static const badgeOrbitMaster = 'badge_orbit_master.png';
  static const badgeSignalSpecialist = 'badge_signal_specialist.png';
  static const badgeEarthDetective = 'badge_earth_detective.png';
  static const badgeSatelliteDoctor = 'badge_satellite_doctor.png';
  static const badgeMissionCommander = 'badge_mission_commander.png';

  // ── global FX (additive over dark stage) ──────────────────────────────────
  static const fxCyanScanBeam = 'fx_cyan_scan_beam.png';
  static const fxCyanHudRing = 'fx_cyan_hud_ring.png';
  static const fxCyanPortalAura = 'fx_cyan_portal_aura.png';
  static const fxHologramPad = 'fx_hologram_pad.png';
  static const fxHologramRingPlatform = 'fx_hologram_ring_platform.png';
  static const fxHologramBeam = 'fx_hologram_beam_vertical.png';
  static const fxGreenSuccessPulse = 'fx_green_success_pulse.png';
  static const fxGreenSuccessRing = 'fx_green_success_ring_effect.png';
  static const fxGreenEnergyRing = 'fx_green_energy_ring.png';
  static const fxLockSuccessHud = 'fx_lock_success_hud.png';
  static const fxRedAlertPulse = 'fx_red_alert_pulse.png';
  static const fxErrorGlitch = 'fx_error_glitch_burst.png';
  static const fxBlueEnergyBurst = 'fx_blue_energy_burst.png';
  static const fxBlueEnergyOrb = 'fx_blue_energy_orb.png';
  static const fxAmberArrowTrail = 'fx_amber_motion_arrow_trail.png';
  static const fxUploadColumn = 'fx_upload_energy_column.png';
  static const fxWhiteCircleTrail = 'fx_white_circle_trail.png';
  static const fxBeamImpact = 'fx_neon_energy_beam_impact.png';
  static const glassPanel = 'ui_glass_panel_large.png';

  // ── path helpers ──────────────────────────────────────────────────────────
  static String flame(String p) => 'save_coastal_city/$p';
  static String flutter(String p) => 'assets/images/save_coastal_city/$p';

  /// Everything the Flame stage needs, fetched from S3 in onLoad
  /// (flame-flavoured keys for `images.fromCache`). Only the sprites used by
  /// the Flame-rendered stages (2 slingshot, 5 signal, finale) — Flutter
  /// scenes resolve their images through netImage* + the manifest precache.
  static List<String> get flamePreload => [
        satWeatherIdle, satWeatherOrbiting, satWeatherScanningEarth,
        earthCycloneCity, slingshotBase, slingshotSling,
        groundStationScene, dishIdle, dishGlowing,
        fxGreenSuccessPulse, fxLockSuccessHud, fxBlueEnergyBurst,
        fxBlueEnergyOrb, fxCyanPortalAura,
      ].map(flame).toList();
}

/// Existing app SFX (at assets/ root), resolved by audioplayers AssetSource.
/// NOTE audioplayers prefixes `assets/` itself — keep these paths bare.
class SCCSounds {
  SCCSounds._();
  static const tap = 'jumpSound.mp3';
  static const correct = 'correct_answer.mp3';
  static const wrong = 'incorrect_answer.mp3';
  static const complete = 'levelComplete.mp3';
}
