// Central registry of processed "Restore Earth" sprites.
//
// WHERE ASSETS LIVE: cleaned, alpha-transparent PNGs produced by the skill's
// strip_bg.py at `assets/images/restore_earth/<sub>/`.
//
// Two path flavours:
//  • Flame `images.load` wants the path relative to its `assets/images/` prefix
//    → `restore_earth/<sub>/x.png`  (use `.flame`).
//  • Flutter `Image.asset` wants the full path → `assets/images/restore_earth/...`
//    (use `.flutter`).
//
// NOTE: the `07_mascot/` pack files are unreliable (idle/excited are checkmarks,
// celebrate is a burst), so the mission-panel mascot reuses the SATELLITE FACE
// sprites for expressions. Route repairs (`city_route_path`,`ocean_route_path`)
// are whole-island renders, so routes are drawn programmatically — not loaded.

class RE {
  RE._();

  // ── satellite ──────────────────────────────────────────────────────────
  static const satBody = 'satellite/satellite_body.png';
  static const satPanelLeft = 'satellite/satellite_panel_left.png';
  static const satPanelRight = 'satellite/satellite_panel_right.png';
  static const satDish = 'satellite/satellite_top_dish.png';
  static const satGlow = 'satellite/satellite_glow_idle.png';
  static const satModeRing = 'satellite/satellite_mode_ring.png';
  static const faceIdle = 'satellite/satellite_face_idle.png';
  static const faceExcited = 'satellite/satellite_face_excited.png';
  static const faceHint = 'satellite/satellite_face_hint.png';
  static const faceOops = 'satellite/satellite_face_oops.png';

  // ── stage ──────────────────────────────────────────────────────────────
  static const earthBase = 'stage/earth_diorama_base.png';
  static const cityProps = 'stage/city_zone_props.png';
  static const oceanProps = 'stage/ocean_zone_props.png';
  static const farmProps = 'stage/farm_zone_props.png';
  static const villageProps = 'stage/mountain_village_zone_props.png';
  static const stormProps = 'stage/storm_zone_props.png';

  // ── problem objects ──────────────────────────────────────────────────────
  static const car = 'problems/car_city.png';
  static const glitchPin = 'problems/glitch_location_pin.png';
  static const ship = 'problems/ship_main.png';
  static const shipCompass = 'problems/ship_compass_glitch.png';
  static const stormCloud = 'problems/storm_cloud_dark.png';
  static const tvHouse = 'problems/tv_house.png';
  static const tvStatic = 'problems/tv_static_screen_icon.png';
  static const village = 'problems/village_houses_cluster.png';
  static const noSignalBars = 'problems/no_signal_bars.png';
  static const cropPatch = 'problems/farm_crop_patch_neutral.png';
  static const cropQuestion = 'problems/crop_question_icon.png';
  static const floodWater = 'problems/flood_water_overlay.png';
  static const rescueTeam = 'problems/rescue_team_icon.png';

  // ── interaction feedback ─────────────────────────────────────────────────
  static const reticle = 'feedback/target_reticle.png';
  static const reticleActive = 'feedback/target_reticle_active.png';
  static const snapRing = 'feedback/snap_ring_glow.png';
  static const pulseRing = 'feedback/problem_pulse_ring.png';
  static const locationPing = 'feedback/location_ping_wave.png';
  static const signalArcs = 'feedback/signal_wave_arcs.png';
  static const scanSweep = 'feedback/scan_grid_sweep.png';
  static const warningTriangle = 'feedback/warning_triangle_glow.png';
  static const sparkles = 'feedback/small_sparkle_cluster.png';
  static const successBurst = 'feedback/success_check_burst.png';
  // Premium success badge reused from the "How Much Can You See" activity.
  static const tickBadge = 'feedback/green_checkmark_badge.png';

  // ── beams + repair overlays ──────────────────────────────────────────────
  static const beamLocation = 'beams/beam_core_location.png';
  static const beamWeather = 'beams/beam_core_weather.png';
  static const beamSignal = 'beams/beam_core_signal.png';
  static const beamScan = 'beams/beam_core_scan.png';
  static const beamStartGlow = 'beams/beam_start_glow.png';
  static const beamEndGlow = 'beams/beam_end_glow.png';
  static const stormScanRings = 'beams/storm_scan_rings.png';
  static const broadcastWave = 'beams/broadcast_wave_restore.png';
  static const fullSignalBars = 'beams/full_signal_bars.png';
  static const cropHeatmap = 'beams/crop_health_heatmap.png';
  static const floodBoundary = 'beams/flood_boundary_map.png';

  // ── power icons ──────────────────────────────────────────────────────────
  static const iconLocation = 'powers/icon_location_power.png';
  static const iconWeather = 'powers/icon_weather_power.png';
  static const iconSignal = 'powers/icon_signal_power.png';
  static const iconScan = 'powers/icon_scan_power.png';

  // ── rewards ──────────────────────────────────────────────────────────────
  static const badge = 'rewards/junior_satellite_engineer_badge.png';
  static const badgeBackplate = 'rewards/badge_glow_backplate.png';
  static const completeBurst = 'rewards/mission_complete_burst.png';
  static const earthOnlineGlow = 'rewards/earth_fully_online_glow.png';

  // ── path helpers ─────────────────────────────────────────────────────────
  static String flame(String p) => 'restore_earth/$p';
  static String flutter(String p) => 'assets/images/restore_earth/$p';

  /// Everything the Flame game preloads in onLoad (flame-prefixed).
  static List<String> get preload => [
        satBody, satPanelLeft, satPanelRight, satDish, satGlow, satModeRing,
        faceIdle, faceExcited, faceHint, faceOops,
        earthBase, cityProps, oceanProps, farmProps, villageProps, stormProps,
        car, glitchPin, ship, shipCompass, stormCloud, tvHouse, tvStatic,
        village, noSignalBars, cropPatch, cropQuestion, floodWater, rescueTeam,
        reticle, reticleActive, snapRing, pulseRing, locationPing, signalArcs,
        scanSweep, warningTriangle, sparkles, successBurst, tickBadge,
        beamLocation, beamWeather, beamSignal, beamScan, beamStartGlow,
        beamEndGlow, stormScanRings, broadcastWave, fullSignalBars, cropHeatmap,
        floodBoundary,
        earthOnlineGlow,
      ].map(flame).toList();
}

/// Existing app SFX (declared under assets/), resolved by audioplayers AssetSource.
class RESounds {
  RESounds._();
  static const select = 'jumpSound.mp3';
  static const correct = 'correct_answer.mp3';
  static const wrong = 'incorrect_answer.mp3';
  static const complete = 'levelComplete.mp3';
}
