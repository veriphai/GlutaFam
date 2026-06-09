// Central registry of processed "Orbit Launcher" sprites (Activity 3 — V2).
//
// V2 launches a real ROCKET from a NASA-style launchpad and adds parallax
// cloud/sky backgrounds. Core (earth/satellite/mission-control), effects, and
// parts are reused from V1 (same source art, already stripped). New for V2:
// the `rocket/` sprites and the `backgrounds/` layers.
//
// Two path flavours (same convention as before):
//  • Flame `images.load` → `orbit_launcher/<sub>/x.png`  (use `.flame`).
//  • Flutter `Image.asset` → `assets/images/orbit_launcher/<sub>/...` (use `.flutter`).
//
// Full-bleed opaque backgrounds are JPEG (no alpha); everything else is PNG.
// Glow/ring/sparkle/trail/beam/plume overlays render additive (BlendMode.plus);
// crash_puff (smoke) + confetti render normal blend.

class OL {
  OL._();

  // ── core (reused from V1) ──────────────────────────────────────────────────
  static const earthHorizon = 'core/earth_curved_horizon.png';
  static const earthGlobe = 'core/earth_full_globe.png';
  static const satNeutral = 'core/satellite_neutral_front.png';
  static const satAngled = 'core/satellite_angled_orbiting.png';
  static const satWobble = 'core/satellite_wobbling_falling.png';
  static const satEmpty = 'core/satellite_empty_box_orbit.png';
  static const mcHappy = 'core/mission_control_happy.png';
  static const mcThinking = 'core/mission_control_thinking.png';
  static const mcCelebrating = 'core/mission_control_celebrating.png';
  // "Orbit" the bot — the narrator/guide (reused from Choose-the-Right-Satellite).
  static const robotPointing = 'core/robot_pointing.png'; // start-screen pose
  static const orbitBotHappy = 'core/orbit_bot_happy.png';
  static const orbitBotThinking = 'core/orbit_bot_thinking.png';
  static const orbitBotCelebrating = 'core/orbit_bot_celebrating.png';

  // ── rocket (new in V2) ─────────────────────────────────────────────────────
  static const rocketPad = 'rocket/rocket_on_launchpad.png';
  static const rocketVertical = 'rocket/rocket_vertical_flying.png';
  static const rocketTilted = 'rocket/rocket_tilted_flying.png';
  static const rocketFalling = 'rocket/rocket_falling_back.png';
  static const rocketRelease = 'rocket/satellite_release_from_rocket.png';
  static const rocketPlume = 'rocket/rocket_exhaust_plume.png';

  // ── backgrounds (new in V2) ────────────────────────────────────────────────
  static const bgLaunchpad = 'backgrounds/nasa_launchpad.jpg'; // full-bleed JPEG
  static const bgSpace = 'backgrounds/atmosphere_to_space.jpg'; // full-bleed JPEG
  static const bgMissionWindow = 'backgrounds/mission_window.jpg'; // start-screen (Flutter overlay)
  static const cloudNear = 'backgrounds/sky_cloud_layer_near.png';
  static const cloudFar = 'backgrounds/sky_cloud_layer_far.png';

  // ── effects (reused from V1) ───────────────────────────────────────────────
  static const crashPuff = 'effects/crash_puff.png';
  static const orbitRing = 'effects/orbit_ring_glow.png';
  static const escapeTrail = 'effects/escape_trail.png';
  static const sparkles = 'effects/success_sparkles.png';
  static const confetti = 'effects/confetti_burst.png';
  static const warningGlow = 'effects/warning_glow.png';

  // ── parts (bridge screen icons) ────────────────────────────────────────────
  static const partSolar = 'parts/solar_panel_icon.png';
  static const partCamera = 'parts/camera_icon.png';
  static const partAntenna = 'parts/antenna_icon.png';
  static const partBattery = 'parts/battery_icon.png';
  static const partChip = 'parts/computer_chip_icon.png';
  static const partThruster = 'parts/thruster_icon.png';
  static const buildCtaGlow = 'parts/build_it_cta_glow.png';

  // ── path helpers ─────────────────────────────────────────────────────────
  static String flame(String p) => 'orbit_launcher/$p';
  static String flutter(String p) => 'assets/images/orbit_launcher/$p';

  /// Everything the Flame game preloads in onLoad (flame-prefixed).
  static List<String> get preload => [
        earthHorizon, earthGlobe,
        satAngled, satEmpty,
        rocketPad, rocketVertical, rocketTilted, rocketFalling, rocketRelease, rocketPlume,
        bgLaunchpad, bgSpace, cloudNear, cloudFar,
        crashPuff, orbitRing, escapeTrail, sparkles, confetti, warningGlow,
      ].map(flame).toList();
}

/// Orbit's voice-over lines (bundled mp3s under assets/sounds/orbit_launcher/),
/// resolved by audioplayers AssetSource. One file per dialogue, recorded against
/// the exact bubble copy — re-record if the copy changes.
class OLVoice {
  OLVoice._();
  static const _dir = 'sounds/orbit_launcher';
  static const brief = '$_dir/vo_brief.mp3';
  static const goal1 = '$_dir/vo_goal_1.mp3';
  static const goal2 = '$_dir/vo_goal_2.mp3';
  static const launchpad = '$_dir/vo_launchpad.mp3';
  static const upItGoes = '$_dir/vo_up_it_goes.mp3';
  static const fellBack1 = '$_dir/vo_fell_back_1.mp3';
  static const fellBack2 = '$_dir/vo_fell_back_2.mp3';
  static const tiltUnlocked = '$_dir/vo_tilt_unlocked.mp3';
  static const challenge = '$_dir/vo_challenge.mp3';
  static const notEnoughPower = '$_dir/vo_not_enough_power.mp3';
  static const tooStraight = '$_dir/vo_too_straight.mp3';
  static const tooMuchTilt = '$_dir/vo_too_much_tilt.mp3';
  static const tooFast = '$_dir/vo_too_fast.mp3';
  static const almost = '$_dir/vo_almost.mp3';
  static const orbitLocked = '$_dir/vo_orbit_locked.mp3';
}

/// Existing app SFX (declared under assets/), resolved by audioplayers AssetSource.
class OLSounds {
  OLSounds._();
  static const bgm = 'sounds/orbit_launcher/bgm.mp3'; // looping ambient bed
  static const tap = 'jumpSound.mp3';
  static const correct = 'correct_answer.mp3';
  static const wrong = 'incorrect_answer.mp3';
  static const complete = 'levelComplete.mp3';
}
