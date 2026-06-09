// Central registry of the processed "Build Your Satellite" sprite assets.
//
// WHERE ASSETS LIVE: the cleaned, alpha-transparent PNGs are produced by
// `tools/process_satellite_sprites.py` and written to
// `assets/images/build_satellite/`.
//
// Two path flavours are needed:
//  • Flame  loads through `Images` whose default prefix is `assets/images/`,
//    so it wants the path RELATIVE to that prefix (e.g. `build_satellite/x.png`).
//  • Flutter widgets (Image.asset / DecorationImage) want the FULL asset path
//    (e.g. `assets/images/build_satellite/x.png`).
//
// Keep every filename here so the rest of the feature never hardcodes strings.

class SatAssets {
  SatAssets._();

  // Body + structural parts
  static const body = 'satellite_body_empty.png';
  static const solarLeft = 'solar_panel_left.png';
  static const solarRight = 'solar_panel_right.png';
  static const solarGlow = 'solar_panel_glow_overlay.png';
  static const leftHinge = 'left_hinge.png';
  static const rightHinge = 'right_hinge.png';
  static const antennaBase = 'antenna_base.png';
  static const antennaDish = 'antenna_dish.png';
  static const camera = 'camera_module.png';
  static const computerCore = 'computer_core_chip.png';
  static const battery = 'battery_module.png';
  static const thruster = 'thruster.png';
  static const thermalBlanket = 'thermal_blanket.png';

  // Effect overlays (rendered additively on the dark stage)
  static const dropZoneRing = 'drop_zone_ring.png';
  static const correctSlotGlow = 'correct_slot_glow.png';
  static const wrongSlotWarning = 'wrong_slot_warning.png';
  static const snapFlash = 'snap_flash.png';
  static const signalWave = 'signal_wave_effect.png';
  static const energyFlowLine = 'energy_flow_line.png';
  static const thrusterFlame = 'thruster_flame.png';
  static const energyParticle = 'energy_particle.png';

  static const String _flameDir = 'build_satellite';
  static const String _flutterDir = 'assets/images/build_satellite';

  /// Path for `game.images.load(...)` (prefix `assets/images/` is implicit).
  static String flame(String file) => '$_flameDir/$file';

  /// Path for Flutter `Image.asset` / `DecorationImage`.
  static String flutter(String file) => '$_flutterDir/$file';

  /// Every sprite Flame should preload in `onLoad`.
  static const List<String> all = [
    body,
    solarLeft, solarRight, solarGlow, leftHinge, rightHinge,
    antennaBase, antennaDish, camera, computerCore, battery, thruster,
    thermalBlanket,
    dropZoneRing, correctSlotGlow, wrongSlotWarning, snapFlash,
    signalWave, energyFlowLine, thrusterFlame, energyParticle,
  ];

  static List<String> get allFlamePaths => all.map(flame).toList();
}

/// Existing app sound effects reused for tactile feedback.
/// (Declared in pubspec under the `assets/` root; audioplayers `AssetSource`
/// resolves relative to that root.)
class SatSounds {
  SatSounds._();
  static const pickup = 'jumpSound.mp3';
  static const correct = 'correct_answer.mp3';
  static const wrong = 'incorrect_answer.mp3';
  static const complete = 'levelComplete.mp3';
}
