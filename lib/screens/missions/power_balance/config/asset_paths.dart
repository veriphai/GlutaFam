// Central registry of processed "Keep the Satellite Alive / Power Balance
// Challenge" sprites (Episode 6).
//
// WHERE ASSETS LIVE: cleaned, alpha-transparent PNGs (+ 3 full-bleed JPEG
// backgrounds) produced by the skill's strip_bg.py at
// `assets/images/power_balance/` — a FLAT folder, so each constant carries its
// own extension.
//
// Two path flavours (same convention as signal_rescue / orbit_launcher):
//  • Flame `images.load` wants the path relative to `assets/images/`
//    → `power_balance/x.png`  (use `.flame`).
//  • Flutter `Image.asset` wants the full path → `assets/images/power_balance/...`
//    (use `.flutter`).
//
// Every sprite was eyeballed in intake. Glow / beam / wave / burst / particle
// overlays render additive (BlendMode.plus) on the dark space stage. Three baked-
// checkerboard overlays (earth_shadow_overlay, shadow_dark_vignette,
// power_down_overlay) were dropped in favour of programmatic shadow/failure
// darkening.

class PB {
  PB._();

  // ── world / backgrounds ──────────────────────────────────────────────────
  static const spaceBg = 'space_bg_starry.jpg'; // full-bleed JPEG
  static const earthDay = 'earth_curve_day.png'; // realistic Earth horizon (space-keyed)
  static const introBg = 'intro_bg.jpg'; // Scene-0 start-page background (Flutter)

  // ── world objects ───────────────────────────────────────────────────────
  static const sun = 'sun_glow_orb.png';
  static const orbitArc = 'orbit_path_arc.png';
  static const cyclone = 'cyclone_target.png';
  static const groundStation = 'ground_station_dish.png';
  static const dataPacketCube = 'data_packet_cube.png';
  static const dataPacketStream = 'data_packet_stream.png';

  // ── satellite full-state sprites (V1 uses these, per PRD §15.2) ───────────
  static const satNormal = 'satellite_state_normal.png';
  static const satCharging = 'satellite_state_charging.png';
  static const satLowPower = 'satellite_state_low_power.png';
  static const satCritical = 'satellite_state_critical_power.png';
  static const satPoweredDown = 'satellite_state_powered_down.png';
  static const satSuccess = 'satellite_state_success_glow.png';
  static const satWarning = 'satellite_state_warning_blink.png';

  // ── interaction FX ───────────────────────────────────────────────────────
  static const cameraScanBeam = 'camera_scan_beam.png';
  static const cameraFlash = 'camera_flash_burst.png';
  static const antennaWave = 'antenna_signal_wave.png';
  static const solarParticles = 'solar_energy_particles.png';
  static const batteryChargeBurst = 'battery_charge_burst.png';
  static const lowPowerGlow = 'low_power_warning_glow.png';
  static const alertSign = 'alert_warning_sign.png'; // small red warning triangle
  static const thrusterFlame = 'thruster_flame_small.png';
  static const confetti = 'success_confetti.png';
  static const starBurst = 'success_star_burst.png';
  static const chargingGlow = 'charging_status_glow.png';
  static const solarPanelGlow = 'solar_panel_glow_overlay.png';

  // ── control icons (active / inactive pairs) ──────────────────────────────
  static const iconSolarActive = 'icon_solar_align_active.png';
  static const iconSolarInactive = 'icon_solar_align_inactive.png';
  static const iconCameraActive = 'icon_camera_active.png';
  static const iconCameraInactive = 'icon_camera_inactive.png';
  static const iconAntennaActive = 'icon_antenna_active.png';
  static const iconAntennaInactive = 'icon_antenna_inactive.png';
  static const iconThrusterActive = 'icon_thruster_active.png';
  static const iconThrusterInactive = 'icon_thruster_inactive.png';

  // ── mascot — "Orbit" the bot (bright pose set, copied from earth_detective
  // so the module stays self-contained; mood-mapped for the helper panel) ────
  static const orbitWelcoming = 'orbit_welcoming.png'; // intro
  static const orbitGuiding = 'orbit_guiding.png'; // neutral / info
  static const orbitThinking = 'orbit_thinking.png'; // thinking / curious
  static const orbitConcerned = 'orbit_concerned.png'; // warning / supportive
  static const orbitCelebrating = 'orbit_celebrating.png'; // excited / found
  static const orbitHappy = 'orbit_happy.png'; // success / proud

  // ── mission control avatars (mood-mapped) ────────────────────────────────
  static const avatarNeutral = 'mission_control_avatar_neutral.png';
  static const avatarThinking = 'mission_control_avatar_thinking.png';
  static const avatarExcited = 'mission_control_avatar_excited.png';
  static const avatarWarning = 'mission_control_avatar_warning.png';
  static const avatarSuccess = 'mission_control_avatar_success.png';

  // ── battery + power UI icons ─────────────────────────────────────────────
  static const batFull = 'battery_icon_full.png';
  static const batHigh = 'battery_icon_high.png';
  static const batMedium = 'battery_icon_medium.png';
  static const batLow = 'battery_icon_low.png';
  static const batCritical = 'battery_icon_critical.png';
  static const batCharging = 'battery_icon_charging.png';
  static const batEmpty = 'battery_icon_empty.png';
  static const powerWarningBadge = 'power_warning_badge.png';

  // ── progress + feedback badges ───────────────────────────────────────────
  static const imageCapturedBadge = 'image_captured_badge.png';
  static const dataSentBadge = 'data_sent_badge.png';
  static const shadowWarningBadge = 'shadow_warning_badge.png';
  static const sunlightBadge = 'sunlight_mode_badge.png';
  static const missionCompleteBadge = 'mission_complete_badge.png';
  static const missionFailedBadge = 'mission_failed_badge.png';
  static const objectiveCheck = 'objective_complete_check.png';
  static const objectivePending = 'objective_pending_dot.png';
  static const objectiveLocked = 'objective_locked_badge.png';
  static const retryBadge = 'retry_mission_badge.png';

  // ── data capture + transmission ──────────────────────────────────────────
  static const capturedCard = 'captured_image_card.png';
  static const cycloneThumb = 'captured_image_thumbnail_cyclone.png';

  /// 3 distinct cyclone photos, one per capture (shown in the fly animation +
  /// the gallery). [capturedImage] returns the n-th (0-based, clamped).
  static const cycloneCaptures = [
    'cyclone_capture_1.png',
    'cyclone_capture_2.png',
    'cyclone_capture_3.png',
  ];
  static String capturedImage(int index) =>
      cycloneCaptures[index.clamp(0, cycloneCaptures.length - 1)];
  static const packetSentGlow = 'data_packet_sent_glow.png';
  static const dataSuccessBurst = 'data_transfer_success_burst.png';
  static const targetLock = 'camera_target_lock_overlay.png';
  static const cycloneScanFrame = 'cyclone_scan_frame.png';
  static const signalLinkBadge = 'signal_link_established_badge.png';

  // ── path helpers ─────────────────────────────────────────────────────────
  static String flame(String p) => 'power_balance/$p';
  static String flutter(String p) => 'assets/images/power_balance/$p';

  /// Everything the Flame game preloads in onLoad (flame-prefixed).
  static List<String> get preload => [
        spaceBg, earthDay,
        sun, cyclone, groundStation, dataPacketCube,
        satNormal, satCharging, satLowPower, satCritical,
        satPoweredDown, satSuccess, satWarning,
        cameraScanBeam, cameraFlash, antennaWave, solarParticles,
        batteryChargeBurst, thrusterFlame, confetti, starBurst,
        chargingGlow, targetLock, alertSign, dataSuccessBurst,
      ].map(flame).toList();
}

/// App SFX + Orbit's voice clips, resolved by audioplayers AssetSource.
/// NOTE: AssetSource paths are relative to `assets/` (the plugin prefixes it) —
/// a file at assets/sounds/power_balance/orbit/orbit_01.wav loads as
/// audioSource('sounds/power_balance/orbit/orbit_01.wav') — see s3_audio.dart.
class PBSounds {
  PBSounds._();
  static const tap = 'jumpSound.mp3';
  static const correct = 'correct_answer.mp3';
  static const wrong = 'incorrect_answer.mp3';
  static const complete = 'levelComplete.mp3';

  /// Looping background bed (ducked while Orbit speaks).
  static const bgm = 'sounds/power_balance/bgm.mp3';

  /// Orbit voice clip n (1..54) — one wav per dialogue line, numbered to match
  /// the `// orbit_NN` comments in [PBTune]'s dialogue library.
  static String orbit(int n) =>
      'sounds/power_balance/orbit/orbit_${n.toString().padLeft(2, '0')}.wav';
}
