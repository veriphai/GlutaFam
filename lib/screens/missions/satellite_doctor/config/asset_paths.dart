// Central registry of processed "Satellite Doctor" sprites (Activity 9).
//
// WHERE ASSETS LIVE: cleaned PNGs under `assets/images/satellite_doctor/<subdir>/`,
// mirroring the source kit's folder numbering.
//
// PROCESSING (see tools/process_satellite_doctor_assets.py): the whole kit shipped
// FLATTENED (hasAlpha:no) — almost everything on flat WHITE (a probe showed
// br~247, corners ~248), including the FX glows. So nearly all sprites get a
// border flood-fill (white→alpha) + trim + downscale 512. Two exceptions:
//   • space_starfield_bg.png → opaque BASE layer (kept opaque, 1024).
//   • solar_panel_restored_glow.png → on flat BLACK (kept opaque; additive).
// Env layers downscale to 768. 164 MB → ~34 MB.
//
// Two path flavours (same convention as code_satellite / signal_rescue):
//  • Flame `images.load` wants the path relative to `assets/images/` → `.flame()`.
//  • Flutter `Image.asset` wants the full path → `.flutter()`.
//
// All TEXT (titles, labels, alert copy, stat values, card labels) is rendered in
// Flutter — these assets are sprites/containers/FX/icons only (PRD hard rule).

class SD {
  SD._();

  // ── 01 satellite core (layered parts of the assembled satellite) ────────────
  static const body = '01_satellite_core/satellite_body_base.png';
  static const antennaDish = '01_satellite_core/antenna_dish.png';
  static const solarLeft = '01_satellite_core/solar_panel_left.png';
  static const solarRight = '01_satellite_core/solar_panel_right.png';
  static const cameraModule = '01_satellite_core/camera_module.png';
  static const batteryModule = '01_satellite_core/battery_module.png';
  static const thrusterModule = '01_satellite_core/thruster_module.png';
  static const thermalShieldModule = '01_satellite_core/thermal_shield_module.png';

  // ── 02 part states ──────────────────────────────────────────────────────────
  static const antennaHealthy = '02_part_states/antenna/antenna_healthy.png';
  static const antennaMisaligned = '02_part_states/antenna/antenna_misaligned.png';
  static const antennaRotating = '02_part_states/antenna/antenna_rotating_pose.png';
  static const antennaRestored = '02_part_states/antenna/antenna_restored.png';

  static const batteryNormal = '02_part_states/battery/battery_normal.png';
  static const batteryOverheating = '02_part_states/battery/battery_overheating.png';
  static const batteryCooled = '02_part_states/battery/battery_cooled.png';
  static const batteryWarningPanel = '02_part_states/battery/battery_warning_panel.png';

  static const cameraHealthy = '02_part_states/camera/camera_healthy.png';
  static const cameraOfflineDark = '02_part_states/camera/camera_offline_dark.png';
  static const cameraStaticGlitch = '02_part_states/camera/camera_static_glitch.png';
  static const cameraRestarting = '02_part_states/camera/camera_restarting.png';
  static const cameraRestored = '02_part_states/camera/camera_restored.png';

  static const solarHealthy = '02_part_states/solar_panel/solar_panel_healthy.png';
  static const solarDim = '02_part_states/solar_panel/solar_panel_dim_not_charging.png';
  static const solarStuckHalf = '02_part_states/solar_panel/solar_panel_stuck_half_open.png';
  static const solarDeploying = '02_part_states/solar_panel/solar_panel_deploying.png';
  static const solarRestoredGlow = '02_part_states/solar_panel/solar_panel_restored_glow.png';

  static const thermalOff = '02_part_states/thermal_shield/thermal_shield_off.png';
  static const thermalActive = '02_part_states/thermal_shield/thermal_shield_active.png';
  static const thermalCoolingGlow = '02_part_states/thermal_shield/thermal_shield_cooling_glow.png';

  static const thrusterIdle = '02_part_states/thruster/thruster_idle.png';
  static const thrusterSmallBurn = '02_part_states/thruster/thruster_small_burn.png';
  static const thrusterStrongBurn = '02_part_states/thruster/thruster_strong_burn.png';
  static const thrusterRestoredIdle = '02_part_states/thruster/thruster_restored_idle.png';

  // ── 03 fault overlays ───────────────────────────────────────────────────────
  static const overheatHeatGlow = '03_fault_overlays/overheating/overheat_heat_glow_overlay.png';
  static const overheatSmoke = '03_fault_overlays/overheating/overheat_smoke_overlay.png';
  static const overheatWarningIcon = '03_fault_overlays/overheating/overheat_warning_icon_overlay.png';

  static const brokenSignalWaves = '03_fault_overlays/signal/broken_signal_waves.png';
  static const antennaWarningArc = '03_fault_overlays/signal/antenna_warning_arc.png';
  static const groundLinkX = '03_fault_overlays/signal/ground_link_x_marker.png';

  static const cameraStaticOverlay = '03_fault_overlays/camera/camera_static_overlay.png';
  static const cameraScanReboot = '03_fault_overlays/camera/camera_scan_reboot_line.png';
  static const cameraOfflineRedMarker = '03_fault_overlays/camera/camera_offline_red_marker.png';

  static const powerFlowOff = '03_fault_overlays/solar_power/power_flow_off_overlay.png';
  static const dimPanelOverlay = '03_fault_overlays/solar_power/dim_panel_overlay.png';
  static const sunAlignmentArc = '03_fault_overlays/solar_power/sun_alignment_hint_arc.png';

  static const orbitPathStable = '03_fault_overlays/orbit/orbit_path_stable.png';
  static const orbitPathDrifting = '03_fault_overlays/orbit/orbit_path_drifting.png';
  static const orbitTargetMarker = '03_fault_overlays/orbit/orbit_target_marker.png';
  static const orbitCorrectionPath = '03_fault_overlays/orbit/orbit_correction_path.png';

  static const debrisSmall1 = '03_fault_overlays/debris/space_debris_small_1.png';
  static const debrisSmall2 = '03_fault_overlays/debris/space_debris_small_2.png';
  static const debrisSmall3 = '03_fault_overlays/debris/space_debris_small_3.png';
  static const debrisMedium = '03_fault_overlays/debris/space_debris_medium.png';
  static const debrisWarningPath = '03_fault_overlays/debris/debris_warning_path.png';
  static const collisionAlertMarker = '03_fault_overlays/debris/collision_alert_marker.png';

  static const hingeClosed = '03_fault_overlays/solar_panel_stuck/hinge_mechanism_closed.png';
  static const hingeHalfOpen = '03_fault_overlays/solar_panel_stuck/hinge_mechanism_half_open.png';
  static const hingeJammed = '03_fault_overlays/solar_panel_stuck/hinge_mechanism_jammed.png';
  static const deployArrowHint = '03_fault_overlays/solar_panel_stuck/deploy_arrow_hint.png';
  static const deploySuccessState = '03_fault_overlays/solar_panel_stuck/deploy_success_state.png';

  // ── 04 MediBot (poses mapped to situation) ──────────────────────────────────
  static const botIdle = '04_medibot/medibot_idle.png';
  static const botWorried = '04_medibot/medibot_worried.png';
  static const botThinking = '04_medibot/medibot_thinking.png';
  static const botPointing = '04_medibot/medibot_pointing.png';
  static const botHappy = '04_medibot/medibot_happy.png';
  static const botCelebrating = '04_medibot/medibot_celebrating.png';
  // Kid avatar (the "you" engineer) — copied from code_satellite → self-contained.
  static const kidAvatar = '04_medibot/kid_curious.png';

  // ── 05 UI graphics ──────────────────────────────────────────────────────────
  static const cardDefault = '05_ui_graphics/cards/repair_choice_card_default.png';
  static const cardSelected = '05_ui_graphics/cards/repair_choice_card_selected.png';
  static const cardCorrect = '05_ui_graphics/cards/repair_choice_card_correct.png';
  static const cardWrong = '05_ui_graphics/cards/repair_choice_card_wrong.png';
  static const speechBubble = '05_ui_graphics/cards/speech_bubble_bg.png';
  static const warningCard = '05_ui_graphics/cards/warning_card_bg.png';
  static const diagnosticCard = '05_ui_graphics/cards/diagnostic_card_bg.png';
  static const progressDotsStrip = '05_ui_graphics/progress/progress_dots_strip_bg.png';

  static const chipPower = '05_ui_graphics/status_icons/status_chip_power_icon.png';
  static const chipSignal = '05_ui_graphics/status_icons/status_chip_signal_icon.png';
  static const chipTemperature = '05_ui_graphics/status_icons/status_chip_temperature_icon.png';
  static const chipOrbit = '05_ui_graphics/status_icons/status_chip_orbit_icon.png';
  static const chipCamera = '05_ui_graphics/status_icons/status_chip_camera_icon.png';
  static const chipSolar = '05_ui_graphics/status_icons/status_chip_solar_icon.png';

  // ── 06 rewards / badges ─────────────────────────────────────────────────────
  static const badgeSystemRestored = '06_rewards/badge_system_restored.png';
  static const badgePowerRestored = '06_rewards/badge_power_restored.png';
  static const badgeSignalRestored = '06_rewards/badge_signal_restored.png';
  static const badgeCameraOnline = '06_rewards/badge_camera_online.png';
  static const badgeOrbitStable = '06_rewards/badge_orbit_stable.png';
  static const badgeDebrisAvoided = '06_rewards/badge_debris_avoided.png';
  static const badgePanelDeployed = '06_rewards/badge_panel_deployed.png';
  static const badgeMissionComplete = '06_rewards/badge_mission_complete.png';
  static const finalMedal = '06_rewards/final_success_medal.png';
  static const rewardStar = '06_rewards/reward_star_icon.png';

  // ── 07 FX — most are LIGHT-bg flood-filled; render ADDITIVE on the dark stage ─
  static const fxScannerRing = '07_fx/scanner/scanner_ring.png';
  static const fxScannerBrackets = '07_fx/scanner/scanner_brackets.png';
  static const fxHoloGrid = '07_fx/scanner/holo_grid_overlay.png';
  static const fxGreenPulse = '07_fx/green_success_pulse.png';
  static const fxSuccessBurst = '07_fx/success_burst_fx.png';
  static const fxSignalWaveBlue = '07_fx/signal_wave_blue.png';
  static const fxSignalWaveGreen = '07_fx/signal_wave_green.png';
  static const fxThrusterTrail = '07_fx/thruster_burst_trail.png';
  static const fxSolarParticles = '07_fx/solar_energy_particles.png';
  static const fxChargingGlow = '07_fx/charging_glow_fx.png';
  static const fxMotionArc = '07_fx/motion_arc_fx.png';
  static const fxSmallSparkle = '07_fx/small_sparkle_fx.png';
  static const fxSystemRestoredGlow = '07_fx/system_restored_glow.png';
  // Reused green-check badge (copied from how_much_can_you_see → self-contained).
  static const fxGreenCheck = '07_fx/green_checkmark_badge.png';

  // ── 00 intro hero background (full-bleed JPEG) ──────────────────────────────
  static const introBg = '00_intro/intro_bg.jpg';

  // ── 08 environment (full-bleed layers) ──────────────────────────────────────
  static const envStarfield = '08_environment/space_starfield_bg.png';
  static const envNebula = '08_environment/soft_nebula_overlay.png';
  static const envStarCluster = '08_environment/distant_star_cluster.png';
  static const envAmbientParticles = '08_environment/ambient_space_particles.png';
  static const envEarthHorizon = '08_environment/earth_horizon_bg.png';
  static const envSunOrb = '08_environment/sun_glow_orb.png';

  // ── path helpers ────────────────────────────────────────────────────────────
  //
  // The activity's images live on S3 (the howwow-prod bucket, public-read)
  // — only the manifests + the dart code itself ship inside the APK. There
  // are three flavours of "give me a path":
  //
  //   • flame(p)   — kept for back-compat. Returns the path Flame's image
  //                  cache would have used when assets were bundled. No
  //                  caller in this activity should reach for it any more;
  //                  the Flame stage loads sprites via {@link s3(p)} +
  //                  http + decodeImageFromList.
  //   • flutter(p) — same idea for Flutter's Image.asset. Replaced
  //                  across the codebase by netImageWidget(SD.flutter(p)),
  //                  which routes through lib/utils/s3_assets.dart and
  //                  rewrites the path to its S3 URL.
  //   • s3(p)      — the canonical fully-resolved S3 URL.
  static String flame(String p) => 'satellite_doctor/$p';
  static String flutter(String p) => 'assets/images/satellite_doctor/$p';
  static String s3(String p) =>
      'https://the-how-wow-prod.s3.ap-south-1.amazonaws.com/activities/satellite_doctor/$p';
}

/// Sounds. NOTE: audioplayers' AssetSource prefixes `assets/` itself — a file at
/// assets/sounds/satellite_doctor/orbit/orbit_01.wav loads as
/// audioSource('sounds/satellite_doctor/orbit/orbit_01.wav') — see s3_audio.dart.
class SDSounds {
  SDSounds._();
  // shared app SFX (at assets/ root)
  static const tap = 'jumpSound.mp3';
  static const correct = 'correct_answer.mp3';
  static const wrong = 'incorrect_answer.mp3';
  static const complete = 'levelComplete.mp3';
  // activity audio
  static const bgm = 'sounds/satellite_doctor/bgm.mp3';
  static String orbit(int n) =>
      'sounds/satellite_doctor/orbit/orbit_${n.toString().padLeft(2, '0')}.wav';
}
