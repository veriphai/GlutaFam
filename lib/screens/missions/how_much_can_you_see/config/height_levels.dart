// The six height levels and their per-level content (PRD §8, §9, §17).
//
// Everything the rail, the Flame stage, and the mission panel need for a level
// lives here as declarative data, so re-skinning = editing this map. Positions
// are normalized factors (0..1), NOT pixels (PRD §19/§21).

import 'asset_paths.dart';

enum ViewHeightLevel { ground, tower, mountain, drone, airplane, satellite }

/// Which visible-area glow circle a level shows (PRD §11.2).
enum VisibleArea { small, medium, large, huge }

class HeightLevelConfig {
  const HeightLevelConfig({
    required this.level,
    required this.label,
    required this.railLabel,
    required this.viewLabel,
    required this.missionText,
    required this.background,
    required this.area,
    required this.railNormY,
    required this.voiceClip,
    this.problemLabel,
    this.isBest = false,
    this.scanCone,
    this.floatingObject,
    this.overlays = const [],
  });

  final ViewHeightLevel level;
  final String label; // big header label e.g. "Ground Level"
  final String railLabel; // short rail node label e.g. "Ground"
  final String viewLabel; // "View: One street"
  final String? problemLabel; // "Problem: Blocked view" (null on ground/tower)
  final bool isBest; // satellite → render the label green ("Best for: …")
  final String missionText; // Mission Control line (PRD §9/§17)

  /// HM.* asset keys (un-prefixed; the game/widgets apply flame()/flutter()).
  final String background;
  final VisibleArea area;
  final String? scanCone; // HM cone key or null (satellite has none)
  final String? floatingObject; // HM object key (drone/airplane/satellite) or null
  final List<String> overlays; // HM overlay keys, back-to-front

  /// Normalized Y on the rail (0 = top/satellite, 1 = bottom/ground) — PRD §10.
  final double railNormY;

  /// Orbit voice-over clip index for this level's line (HMSounds.orbitVoice).
  final int voiceClip;
}

/// Rail order from top (space) to bottom (earth) — PRD §10 height rail layout.
const List<ViewHeightLevel> kRailOrderTopToBottom = [
  ViewHeightLevel.satellite,
  ViewHeightLevel.airplane,
  ViewHeightLevel.mountain,
  ViewHeightLevel.drone, // a drone flies low — below the mountain
  ViewHeightLevel.tower,
  ViewHeightLevel.ground,
];

/// Ascending order of "height" (ground → satellite), used for progress.
const List<ViewHeightLevel> kClimbOrder = [
  ViewHeightLevel.ground,
  ViewHeightLevel.tower,
  ViewHeightLevel.drone, // drone is below the mountain
  ViewHeightLevel.mountain,
  ViewHeightLevel.airplane,
  ViewHeightLevel.satellite,
];

const Map<ViewHeightLevel, HeightLevelConfig> kHeightLevels = {
  ViewHeightLevel.ground: HeightLevelConfig(
    level: ViewHeightLevel.ground,
    label: 'Ground Level',
    railLabel: 'Ground',
    viewLabel: 'View: One street',
    missionText: 'Look around us. From down here, we can only see this one street. Pretty tiny view, right?',
    background: HM.bgGround,
    area: VisibleArea.small,
    scanCone: HM.coneSmall,
    railNormY: 0.88,
    voiceClip: 2,
  ),
  ViewHeightLevel.tower: HeightLevelConfig(
    level: ViewHeightLevel.tower,
    label: 'Tower',
    railLabel: 'Tower',
    viewLabel: 'View: Neighborhood',
    problemLabel: 'Still small',
    missionText: 'Nice, we’re higher now. See? More houses and roads appear. But this is still just a neighborhood.',
    background: HM.bgNeighborhood,
    area: VisibleArea.medium,
    scanCone: HM.coneMedium,
    railNormY: 0.72,
    voiceClip: 3,
  ),
  // Drone flies low → sits BELOW the mountain on the rail (railNormY 0.56).
  ViewHeightLevel.drone: HeightLevelConfig(
    level: ViewHeightLevel.drone,
    label: 'Drone',
    railLabel: 'Drone',
    viewLabel: 'View: Local area',
    problemLabel: 'Problem: Limited battery',
    missionText: 'Now the drone gives us a better look from above. But uh-oh — see that battery? It can’t keep watching for too long.',
    background: HM.bgDrone,
    area: VisibleArea.medium,
    scanCone: HM.coneMedium,
    floatingObject: HM.droneIcon,
    railNormY: 0.56,
    voiceClip: 4,
  ),
  ViewHeightLevel.mountain: HeightLevelConfig(
    level: ViewHeightLevel.mountain,
    label: 'Mountain',
    railLabel: 'Mountain',
    viewLabel: 'View: City',
    problemLabel: 'Problem: Blocked view',
    missionText: 'Whoa, the mountain gives us a bigger view. But look — clouds and hills are hiding some places from us.',
    background: HM.bgMountain,
    area: VisibleArea.large,
    scanCone: HM.coneMedium,
    overlays: [HM.cloudSoft, HM.blockedView],
    railNormY: 0.40,
    voiceClip: 5,
  ),
  ViewHeightLevel.airplane: HeightLevelConfig(
    level: ViewHeightLevel.airplane,
    label: 'Airplane',
    railLabel: 'Airplane',
    viewLabel: 'View: Large region',
    problemLabel: 'Problem: Must come down',
    missionText: 'Now we’re flying high! We can see a huge region… but this airplane can’t stay up forever. It has to come back down.',
    background: HM.bgAirplane,
    area: VisibleArea.large,
    scanCone: HM.coneLarge,
    floatingObject: HM.airplaneIcon,
    overlays: [HM.cloudBelowAirplane],
    railNormY: 0.24,
    voiceClip: 6,
  ),
  ViewHeightLevel.satellite: HeightLevelConfig(
    level: ViewHeightLevel.satellite,
    label: 'Satellite',
    railLabel: 'Satellite',
    viewLabel: 'View: Huge Earth area',
    problemLabel: 'Best for: Weather, oceans, forests, cities',
    isBest: true,
    missionText:
        'Now look at that! From space, we can see oceans, clouds, forests, cities, and even storms — all in one huge view.',
    // Same dramatic ocean-cyclone view used at the success ending. It's already
    // detailed, so no extra cloud/city/forest overlays here.
    background: HM.bgOceanCyclone,
    area: VisibleArea.huge,
    floatingObject: HM.satelliteIcon,
    railNormY: 0.08,
    voiceClip: 7,
  ),
};

/// Returns the height level whose rail position is nearest to [normY] (PRD §10).
ViewHeightLevel nearestLevelForNormY(double normY) {
  ViewHeightLevel best = ViewHeightLevel.ground;
  double bestD = double.infinity;
  for (final cfg in kHeightLevels.values) {
    final d = (cfg.railNormY - normY).abs();
    if (d < bestD) {
      bestD = d;
      best = cfg.level;
    }
  }
  return best;
}
