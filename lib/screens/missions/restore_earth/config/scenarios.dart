// The 7 problem scenarios (PRD §15–22), in play order (§30.3). This is the
// content spec transcribed from the PRD — copy, correct power, assets, and the
// hotspot (where the problem sits + how forgiving the hit is). Swap this file +
// powers + earth_layout to reskin the activity for a future episode.

import 'dart:ui' show Offset;

import 'asset_paths.dart';
import 'powers.dart';

/// Selects the per-scenario repair timeline in `effects/repair_effects.dart`.
enum RepairKind { route, stormScan, broadcast, signalBars, cropScan, floodScan }

class ScenarioCopy {
  final String spawn; // problem appears
  final String success; // after repair
  final String learning; // optional teaching line after success
  final String wrong1; // conceptual hint
  final String wrong2; // pulse-button hint
  final String wrong3; // direct instruction
  const ScenarioCopy({
    required this.spawn,
    required this.success,
    required this.learning,
    required this.wrong1,
    required this.wrong2,
    required this.wrong3,
  });
}

class ScenarioDef {
  final String id;
  final String name;
  final String zoneLabel; // CITY / OCEAN / ...
  final PowerId correctPower;
  final int round; // 1 training, 2 mission, 3 rescue
  final String problemAsset; // main hotspot sprite (flame path)
  final String? markerAsset; // glitch pin / static / question / no-signal (flame path)
  final RepairKind repairKind;

  // Hotspot as a factor of the Earth diorama rect (0..1) + forgiving radius
  // as a factor of the Earth width. Tuned live against the art.
  final Offset hotspot;
  final double hitRadiusFactor;

  final ScenarioCopy copy;

  /// Orbit voice-clip base — spawn lives at `voiceBase + 0`, wrong1..3 at +1..+3,
  /// success at +4, learning at +5. Lets the controller derive the right clip
  /// without a switch.
  final int voiceBase;

  const ScenarioDef({
    required this.id,
    required this.name,
    required this.zoneLabel,
    required this.correctPower,
    required this.round,
    required this.problemAsset,
    this.markerAsset,
    required this.repairKind,
    required this.hotspot,
    this.hitRadiusFactor = 0.16,
    required this.copy,
    required this.voiceBase,
  });
}

const List<ScenarioDef> kScenarios = [
  // 1 ── Lost Car (City, Location) ─────────────────────────────────────────
  ScenarioDef(
    id: 'lost_car',
    name: 'Lost Car',
    zoneLabel: 'CITY',
    correctPower: PowerId.location,
    round: 1,
    problemAsset: 'restore_earth/${RE.car}',
    markerAsset: 'restore_earth/${RE.glitchPin}',
    repairKind: RepairKind.route,
    hotspot: Offset(0.34, 0.46),
    voiceBase: 9,
    copy: ScenarioCopy(
      spawn: 'See that car? It’s going in circles. It doesn’t know where it is. Let’s help it find a route.',
      success: 'Yes! The route is back.',
      learning: 'You just used satellite navigation. GPS satellites help phones and vehicles find their position on Earth.',
      wrong1: 'Hmm, that didn’t help. This car needs to know its location.',
      wrong2: 'Try the power that helps find position and routes.',
      wrong3: 'Use Location here. That’s the power for lost things.',
    ),
  ),
  // 2 ── TV Signal Lost (City, Signal) ─────────────────────────────────────
  ScenarioDef(
    id: 'tv_signal',
    name: 'TV Signal Lost',
    zoneLabel: 'CITY',
    correctPower: PowerId.signal,
    round: 1,
    problemAsset: 'restore_earth/${RE.tvHouse}',
    markerAsset: 'restore_earth/${RE.tvStatic}',
    repairKind: RepairKind.broadcast,
    hotspot: Offset(0.30, 0.60),
    voiceBase: 15,
    copy: ScenarioCopy(
      spawn: 'Look at that TV — only static! It’s not getting a signal. Let’s send one from space.',
      success: 'Nice! The broadcast is back.',
      learning: 'Satellites can help send TV signals across huge distances.',
      wrong1: 'Not quite. The TV doesn’t need a map or weather. It needs a signal.',
      wrong2: 'Try the power that sends information across long distances.',
      wrong3: 'Use Signal here. That’s how we bring the broadcast back.',
    ),
  ),
  // 3 ── Storm Detection (Storm, Weather) ──────────────────────────────────
  ScenarioDef(
    id: 'storm_detection',
    name: 'Storm Detection',
    zoneLabel: 'STORM AREA',
    correctPower: PowerId.weather,
    round: 2,
    problemAsset: 'restore_earth/${RE.stormCloud}',
    markerAsset: 'restore_earth/${RE.warningTriangle}',
    repairKind: RepairKind.stormScan,
    hotspot: Offset(0.56, 0.72),
    voiceBase: 21,
    copy: ScenarioCopy(
      spawn: 'Whoa, see those clouds? A storm is forming. We need to look at it from above.',
      success: 'Storm spotted!',
      learning: 'Weather satellites watch clouds and storms from space, so warnings can come earlier.',
      wrong1: 'That power won’t show us the storm clearly. We need weather eyes.',
      wrong2: 'Try the power that watches clouds and storms.',
      wrong3: 'Use Weather here. It helps us see what the clouds are doing.',
    ),
  ),
  // 4 ── Lost Ship (Ocean, Location) ───────────────────────────────────────
  ScenarioDef(
    id: 'lost_ship',
    name: 'Lost Ship',
    zoneLabel: 'OCEAN',
    correctPower: PowerId.location,
    round: 2,
    problemAsset: 'restore_earth/${RE.ship}',
    markerAsset: 'restore_earth/${RE.shipCompass}',
    repairKind: RepairKind.route,
    hotspot: Offset(0.60, 0.40),
    voiceBase: 27,
    copy: ScenarioCopy(
      spawn: 'See that ship out in the ocean? There are no road signs out there. Let’s help it find the way.',
      success: 'Navigation restored!',
      learning: 'Ships use satellites to navigate across oceans.',
      wrong1: 'Hmm, the ship still doesn’t know where to go. It needs navigation.',
      wrong2: 'Try the power that finds position and routes.',
      wrong3: 'Use Location here. Ships need it when they’re far out at sea.',
    ),
  ),
  // 5 ── Remote Village Offline (Mountain Village, Signal) ──────────────────
  ScenarioDef(
    id: 'remote_village',
    name: 'Remote Village Offline',
    zoneLabel: 'MOUNTAIN VILLAGE',
    correctPower: PowerId.signal,
    round: 2,
    problemAsset: 'restore_earth/${RE.village}',
    markerAsset: 'restore_earth/${RE.noSignalBars}',
    repairKind: RepairKind.signalBars,
    hotspot: Offset(0.28, 0.74),
    voiceBase: 33,
    copy: ScenarioCopy(
      spawn: 'Look at that mountain village. It’s far from towers and cables. Let’s connect it from space.',
      success: 'Connection restored!',
      learning: 'Satellites can help connect remote places where towers or cables are hard to build.',
      wrong1: 'That didn’t connect the village. This place needs a signal.',
      wrong2: 'Try the power that sends signals across long distances.',
      wrong3: 'Use Signal here. It can connect faraway places.',
    ),
  ),
  // 6 ── Farm Monitoring (Farm, Scan) ──────────────────────────────────────
  ScenarioDef(
    id: 'farm_monitoring',
    name: 'Farm Monitoring',
    zoneLabel: 'FARM',
    correctPower: PowerId.scan,
    round: 3,
    problemAsset: 'restore_earth/${RE.cropPatch}',
    markerAsset: 'restore_earth/${RE.cropQuestion}',
    repairKind: RepairKind.cropScan,
    hotspot: Offset(0.74, 0.58),
    voiceBase: 39,
    copy: ScenarioCopy(
      spawn: 'See this farm? The farmer can’t check every field at once. Let’s scan it from above.',
      success: 'Farm scan complete!',
      learning: 'Satellites can scan farms from above to help monitor crops and land.',
      wrong1: 'That won’t show the whole field. We need to look at the land.',
      wrong2: 'Try the power that scans Earth’s surface.',
      wrong3: 'Use Scan here. It gives us a big view from above.',
    ),
  ),
  // 7 ── Flood Rescue (Storm/Flood, Scan) ──────────────────────────────────
  ScenarioDef(
    id: 'flood_rescue',
    name: 'Flood Rescue',
    zoneLabel: 'STORM AREA',
    correctPower: PowerId.scan,
    round: 3,
    problemAsset: 'restore_earth/${RE.floodWater}',
    markerAsset: 'restore_earth/${RE.rescueTeam}',
    repairKind: RepairKind.floodScan,
    hotspot: Offset(0.52, 0.80),
    voiceBase: 45,
    copy: ScenarioCopy(
      spawn: 'Oh no, the flood is spreading. The rescue team needs to see the whole area from above.',
      success: 'Flood map revealed!',
      learning: 'Satellites help rescue teams see large disaster areas from above.',
      wrong1: 'A route is not enough yet. First, we need to see where the flood has spread.',
      wrong2: 'Try the power that scans large areas.',
      wrong3: 'Use Scan here. It can reveal the flood map.',
    ),
  ),
];

const int kScenarioCount = 7;
