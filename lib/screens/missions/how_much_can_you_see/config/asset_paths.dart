// Central registry of processed "How Much Can You See?" sprites (Activity 2).
//
// WHERE ASSETS LIVE: cleaned PNGs (+ JPEG backgrounds) under
// `assets/images/how_much_can_you_see/<sub>/`, produced by the skill's
// strip_bg.py (flood-fill-from-border) + a JPEG pass on the full-bleed
// backgrounds.
//
// Two path flavours:
//  • Flame `images.load` wants the path relative to `assets/images/`
//    → `how_much_can_you_see/<sub>/x.png`  (use `.flame`).
//  • Flutter `Image.asset` wants the full path → `assets/images/...`
//    (use `.flutter`).
//
// GLOW NOTE: the height-rail glow UI (marker, rail, nodes, visible-area circles,
// scan cones) keeps a faint pale matte fringe from the stripped checkerboard.
// Render those with BlendMode.plus (additive) on the dark stage and the fringe
// vanishes while the neon pops. Backgrounds are opaque .jpg (no transparency).

class HM {
  HM._();
  static const _root = 'how_much_can_you_see';

  // ── backgrounds (.jpg, full-bleed scenes) ───────────────────────────────
  static const bgMissionControl = 'backgrounds/mission_control_room_bg.jpg';
  // Story-intro hero: kid + robot + the height ladder over Earth, baked in.
  static const bgStoryIntro = 'backgrounds/story_intro_bg.jpg';
  static const bgGround = 'backgrounds/earth_ground_street_view.jpg';
  static const bgNeighborhood = 'backgrounds/earth_neighborhood_view.jpg';
  static const bgMountain = 'backgrounds/earth_city_mountain_view.jpg';
  static const bgDrone = 'backgrounds/earth_drone_farm_view.jpg';
  static const bgAirplane = 'backgrounds/earth_airplane_region_view.jpg';
  static const bgSatellite = 'backgrounds/earth_satellite_curved_view.jpg';
  static const bgOceanCyclone = 'backgrounds/ocean_cyclone_view.jpg';
  static const bgStarry = 'backgrounds/starry_space_bg.jpg';
  static const bgEarthCurve = 'backgrounds/earth_curve_space_bg.jpg';

  // ── characters ──────────────────────────────────────────────────────────
  static const kidCurious = 'characters/kid_curious_pose.png';
  static const robotIdle = 'characters/robot_helper_idle.png';
  static const robotPointing = 'characters/robot_pointing_pose.png';
  static const robotThumbsUp = 'characters/robot_thumbs_up_pose.png';

  // ── objects (icons + floating stage objects) ─────────────────────────────
  static const towerIcon = 'objects/tower_icon.png';
  static const mountainIcon = 'objects/mountain_icon.png';
  static const droneIcon = 'objects/drone_icon.png';
  static const airplaneIcon = 'objects/airplane_icon.png';
  static const satelliteIcon = 'objects/satellite_icon.png';
  static const cameraIconFront = 'objects/camera_icon_front.png';
  static const cameraMarkerOrb = 'objects/camera_marker_orb.png';

  // ── earth overlays ───────────────────────────────────────────────────────
  static const cloudSoft = 'overlays/cloud_layer_soft.png';
  static const cloudGlobal = 'overlays/cloud_layer_global.png';
  static const cloudBelowAirplane = 'overlays/cloud_layer_below_airplane.png';
  static const cycloneSpiral = 'overlays/cyclone_spiral_overlay.png';
  static const cityLights = 'overlays/city_lights_overlay.png';
  static const forestPatch = 'overlays/forest_patch_overlay.png';
  static const blockedView = 'overlays/blocked_view_overlay.png';
  static const oceanCyclone = 'overlays/ocean_cyclone_overlay.png';
  static const earthGlow = 'overlays/earth_glow_overlay.png';
  static const mapGrid = 'overlays/map_grid_overlay.png';

  // ── height interaction UI ────────────────────────────────────────────────
  static const rail = 'height_ui/height_rail_vertical.png';
  static const nodeActive = 'height_ui/height_node_active.png';
  static const nodeInactive = 'height_ui/height_node_inactive.png';
  static const nodeCompleted = 'height_ui/height_node_completed.png';
  static const markerIdle = 'height_ui/camera_marker_idle.png';
  static const markerDragging = 'height_ui/camera_marker_dragging.png';
  static const markerGlow = 'height_ui/camera_marker_glow.png';
  static const areaSmall = 'height_ui/small_visible_area_circle.png';
  static const areaMedium = 'height_ui/medium_visible_area_circle.png';
  static const areaLarge = 'height_ui/large_visible_area_circle.png';
  static const areaHuge = 'height_ui/huge_visible_area_circle.png';
  static const coneSmall = 'height_ui/scan_cone_small.png';
  static const coneMedium = 'height_ui/scan_cone_medium.png';
  static const coneLarge = 'height_ui/scan_cone_large.png';

  // ── challenge + mission UI ───────────────────────────────────────────────
  static const msgPanel = 'challenge_ui/mission_control_message_panel.png';
  static const hologramPanel = 'challenge_ui/mission_control_hologram_panel.png';
  static const challengePanel = 'challenge_ui/challenge_panel_bg.png';
  static const towerCard = 'challenge_ui/tower_choice_card.png';
  static const droneCard = 'challenge_ui/drone_choice_card.png';
  static const airplaneCard = 'challenge_ui/airplane_choice_card.png';
  static const satelliteCard = 'challenge_ui/satellite_choice_card.png';
  static const correctGlow = 'challenge_ui/choice_card_correct_glow.png';
  static const wrongGlow = 'challenge_ui/choice_card_wrong_glow.png';
  static const masteredBadge = 'challenge_ui/earth_view_mastered_badge.png';

  // ── success + teaser effects ─────────────────────────────────────────────
  static const checkmark = 'effects/green_checkmark_badge.png';
  static const sparkles = 'effects/success_sparkles.png';
  static const downArrow = 'effects/down_arrow_glow.png';
  static const orbitArrow = 'effects/orbit_path_arrow_hint.png';
  static const unlockIcon = 'effects/unlock_icon.png';
  static const purpleGlow = 'effects/purple_unlock_glow.png';
  static const questionBubble = 'effects/question_bubble_icon.png';

  // ── path helpers ─────────────────────────────────────────────────────────
  static String flame(String p) => '$_root/$p';
  static String flutter(String p) => 'assets/images/$_root/$p';

  /// Stage assets the Flame [HeightStageGame] preloads in onLoad (flame-prefixed).
  static List<String> get stagePreload => [
        bgGround, bgNeighborhood, bgMountain, bgDrone, bgAirplane, bgOceanCyclone,
        cloudSoft, cloudBelowAirplane, blockedView,
        droneIcon, airplaneIcon, satelliteIcon,
      ].map(flame).toList();
}

/// Existing app SFX (declared under assets/), resolved by audioplayers AssetSource.
class HMSounds {
  HMSounds._();
  static const tap = 'jumpSound.mp3';
  static const snap = 'jumpSound.mp3';
  static const reveal = 'levelComplete.mp3';
  static const correct = 'correct_answer.mp3';
  static const wrong = 'incorrect_answer.mp3';
  static const unlock = 'levelComplete.mp3';

  /// Looping background-music bed for the whole activity (ducked under voice).
  static const bgm = 'sounds/how_much_can_you_see/bgm.mp3';

  // ── Orbit voice-over (13 numbered clips, bundled locally) ────────────────
  // NOTE: audioplayers' AssetSource prefixes `assets/` itself — the file at
  // assets/sounds/how_much_can_you_see/orbit_01.mp3 loads as
  // audioSource('sounds/how_much_can_you_see/orbit_01.mp3') — see s3_audio.dart.
  static String orbitVoice(int clip) =>
      'sounds/how_much_can_you_see/orbit_${clip.toString().padLeft(2, '0')}.mp3';

  // Scene-level clip indices (level + wrong-option clips live in their configs).
  static const vcTestIntro = 1; // Scene 1 — "Okay, junior engineer…"
  static const vcChallenge = 8; // Scene 8 — "Mission alert!…"
  static const vcHint = 12; // after 2+ wrong — "Tiny hint from Orbit…"
  static const vcSuccess = 13; // Scene 9 — "Yes! Satellite is the one…"
}
