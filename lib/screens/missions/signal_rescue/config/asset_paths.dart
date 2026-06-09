// Central registry of processed "Signal Rescue Mission" sprites (Activity 7).
//
// WHERE ASSETS LIVE: cleaned, alpha-transparent PNGs (+ a few full-bleed JPEGs)
// produced by the skill's strip_bg.py at `assets/images/signal_rescue/` — a FLAT
// folder (no sub-dirs), so each constant carries its own extension.
//
// Two path flavours (same convention as orbit_launcher / restore_earth):
//  • Flame `images.load` wants the path relative to the `assets/images/` prefix
//    → `signal_rescue/x.png`  (use `.flame`).
//  • Flutter `Image.asset` wants the full path → `assets/images/signal_rescue/...`
//    (use `.flutter`).
//
// Every sprite was eyeballed in intake (the mascot pack is genuine here, unlike
// restore_earth). Glow / ring / beam / packet / burst overlays render additive
// (BlendMode.plus) on the dark space stage; the cyclone photo + static fill are
// JPEG and render with normal blend inside the (Flutter) monitor.

class SR {
  SR._();

  // ── core scene ─────────────────────────────────────────────────────────────
  static const introPoster = 'intro_poster.jpg'; // full-bleed story-intro hero
  static const earthBase = 'earth_mini_world_base.png';
  static const earthHorizon = 'earth_horizon_glow.png';
  static const satelliteBody = 'satellite_body_no_dish.png'; // dish is separate
  static const satelliteBodyFull = 'satellite_body_main.png'; // fallback (with dish)
  static const satelliteGlowBody = 'satellite_body_transmitting_glow.png';
  static const antennaMount = 'antenna_mount_base.png';
  static const antennaDish = 'antenna_dish_rotatable.png';
  static const groundInactive = 'ground_station_inactive.png';
  static const groundActive = 'ground_station_active.png';
  static const groundAlert = 'ground_station_alert.png';

  // the live storm on the Earth's ocean (top-down swirl cutout, reused from
  // choose_right_satellite per the copy-into-own-folder rule)
  static const cycloneStorm = 'cyclone_storm.png';

  // monitor imagery (Flutter-rendered panel)
  static const cycloneFull = 'cyclone_image_full.jpg';
  static const cycloneThumb = 'cyclone_image_thumbnail.png';
  static const monitorStatic = 'mission_control_static_overlay.jpg';
  static const monitorScan = 'monitor_image_reveal_mask_fx.png';

  // ── mascot ────────────────────────────────────────────────────────────────
  static const mascotIdle = 'mascot_idle.png';
  static const mascotExplaining = 'mascot_explaining.png';
  static const mascotAlert = 'mascot_alert.png';
  static const mascotHappy = 'mascot_happy.png';
  static const mascotCelebrate = 'mascot_celebrate.png';

  // ── signal fx ───────────────────────────────────────────────────────────────
  static const dataPacket = 'data_packet.png';
  static const packetTrail = 'data_packet_trail_glow.png';
  static const packetSplash = 'data_packet_impact_splash.png';
  static const lockRing = 'lock_glow_ring.png';
  static const reticle = 'target_lock_reticle.png';
  static const rangeRing = 'range_ring_soft.png';
  static const warningRing = 'warning_pulse_ring.png';
  static const signalLoss = 'signal_loss_sparks.png';
  static const beaconDot = 'tiny_ground_station_beacon_dot.png';

  // ── ui fx ────────────────────────────────────────────────────────────────
  static const rotationGuide = 'antenna_rotation_guide.png';
  static const orbitDashed = 'orbit_path_dashed.png';
  static const commWindowArc = 'communication_window_arc.png';
  static const satelliteIdleGlow = 'satellite_idle_glow.png';
  static const lockHighlight = 'satellite_lock_highlight.png';
  static const sendButtonGlow = 'send_button_energy_overlay.png';
  static const lowBatteryIcon = 'low_battery_warning_icon.png';
  static const lowBatteryFx = 'low_battery_warning_fx.png';

  // ── environment / reward ────────────────────────────────────────────────────
  static const sparkle = 'sparkle_particle.png';
  static const successBurst = 'success_burst.png';
  static const beamPortal = 'ground_station_beam_portal.png';
  static const successBadge = 'success_badge_art.png';
  static const stormWarning = 'cyclone_timer_warning_fx.png';

  // ── path helpers ─────────────────────────────────────────────────────────
  static String flame(String p) => 'signal_rescue/$p';
  static String flutter(String p) => 'assets/images/signal_rescue/$p';

  /// Everything the Flame game preloads in onLoad (flame-prefixed).
  static List<String> get preload => [
        earthBase,
        satelliteBody, satelliteGlowBody, antennaMount, antennaDish,
        groundInactive, groundActive, groundAlert,
        dataPacket, packetTrail, packetSplash,
        lockRing, reticle, warningRing, signalLoss, beaconDot,
        orbitDashed, commWindowArc,
        lockHighlight, sparkle, successBurst, beamPortal,
      ].map(flame).toList();
}

/// Sounds, resolved by audioplayers AssetSource — paths are relative to
/// `assets/` (the plugin prefixes it; including "assets/" 404s silently).
class SRSounds {
  SRSounds._();
  // shared app SFX
  static const tap = 'jumpSound.mp3';
  static const correct = 'correct_answer.mp3';
  static const wrong = 'incorrect_answer.mp3';
  static const complete = 'levelComplete.mp3';
  // signal_rescue audio (bundled locally, never S3 — voice needs <100ms)
  static const bgm = 'sounds/signal_rescue/bgm.mp3';
  static String orbitVoice(int clip) =>
      'sounds/signal_rescue/orbit/orbit_${clip.toString().padLeft(2, '0')}.wav';
}
