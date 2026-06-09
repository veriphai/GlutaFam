// The five dispatch missions, centralised here. Orbit's dialogue follows the
// v2 master script — every line carries its VO clip number (see
// orbit_script.dart for the numbering map; shared intro/instruction/log lines
// live there). Scene-layer anchors are factors of the scene rect, tuned live.

import 'package:flutter/widgets.dart';

import '../config/asset_paths.dart';
import '../models/orbit_line.dart';
import '../models/satellite_mission.dart';
import '../models/satellite_type.dart';

const List<SatelliteMission> kChooseSatelliteMissions = [
  // ---- Mission 1: Lost Fisherman -> Navigation (clips 7–10) ---------------
  SatelliteMission(
    id: 'lost_fisherman',
    title: 'Lost Fisherman',
    requestText: 'A fisherman is lost at sea. We need to know his location.',
    correctType: SatelliteType.navigation,
    layers: [
      SceneLayer(asset: CrsAssets.oceanPatch, centerFactor: Offset(0.5, 0.78), widthFactor: 0.96),
      SceneLayer(asset: CrsAssets.fishermanBoat, centerFactor: Offset(0.5, 0.58), widthFactor: 0.62),
      SceneLayer(asset: CrsAssets.sosBeacon, centerFactor: Offset(0.78, 0.5), widthFactor: 0.18),
      SceneLayer(
        asset: CrsAssets.locationPin,
        centerFactor: Offset(0.5, 0.22),
        widthFactor: 0.34,
        revealOnSuccess: true,
      ),
    ],
    successLabel: 'Located!',
    appearLines: [
      OrbitLine(
          'See that boat out in the ocean? The fisherman is lost. We need to help him know where he is.',
          7),
    ],
    hintAfterWrong: OrbitLine(
        'Hmm, this satellite can help with other jobs, but this problem is about location.', 8),
    strongerHint:
        OrbitLine('Look for the satellite that helps maps, phones, and boats find directions.', 9),
    successLines: [
      OrbitLine(
          "Yes! That's the navigation satellite. It helps boats and maps figure out exact location, even at sea.",
          10),
    ],
    successEffect: MissionEffectType.gpsBeam,
    thumbnailAsset: CrsAssets.fishermanBoat,
    ambientSound: CrsSounds.ambWaves,
    successSting: CrsSounds.stingLocate,
    effectPlacement: EffectPlacement(centerFactor: Offset(0.5, 0.38), widthFactor: 0.5),
    // Programmatic GPS beam: from the docked satellite down to the fisherman.
    beamTargetFactor: Offset(0.45, 0.5),
  ),

  // ---- Mission 2: Cyclone Alert -> Weather (clips 11–15) ------------------
  SatelliteMission(
    id: 'cyclone_alert',
    title: 'Cyclone Alert',
    requestText: 'A cyclone is forming. We need to track the storm.',
    correctType: SatelliteType.weather,
    layers: [
      SceneLayer(
        asset: CrsAssets.cycloneStorm,
        centerFactor: Offset(0.5, 0.55),
        widthFactor: 0.86,
        rotateOnSuccess: true,
      ),
      SceneLayer(
        asset: CrsAssets.cloudOverlayWhite,
        centerFactor: Offset(0.34, 0.74),
        widthFactor: 0.6,
        idleOpacity: 0.55,
      ),
    ],
    successLabel: 'Storm Tracked!',
    appearLines: [
      OrbitLine('Look at those spinning clouds! A cyclone may be forming over the ocean.', 11),
      OrbitLine('We need a satellite that can watch clouds and storms from space.', 12),
    ],
    hintAfterWrong: OrbitLine(
        'Not quite. This mission is not mainly about sending signals. We need to watch the weather.',
        13),
    strongerHint:
        OrbitLine('Choose the satellite that tracks clouds, rain, storms, and cyclones.', 14),
    successLines: [
      OrbitLine(
          "Perfect! That's the weather satellite. It can watch the storm from above and help people prepare early.",
          15),
    ],
    successEffect: MissionEffectType.weatherScan,
    thumbnailAsset: CrsAssets.cycloneStorm,
    ambientSound: CrsSounds.ambStorm,
    successSting: CrsSounds.stingRadar,
    effectPlacement: EffectPlacement(centerFactor: Offset(0.5, 0.55), widthFactor: 0.9),
  ),

  // ---- Mission 3: Remote Village Internet -> Communication (clips 16–21) --
  SatelliteMission(
    id: 'remote_village_internet',
    title: 'Village Internet',
    requestText: 'A remote village needs internet for school and video calls.',
    correctType: SatelliteType.communication,
    layers: [
      SceneLayer(asset: CrsAssets.remoteVillage, centerFactor: Offset(0.5, 0.62), widthFactor: 0.92),
      SceneLayer(
        asset: CrsAssets.wifiSymbol,
        centerFactor: Offset(0.5, 0.24),
        widthFactor: 0.42,
        idleOpacity: 0.28,
        revealOnSuccess: true,
      ),
    ],
    successLabel: 'Connected!',
    appearLines: [
      OrbitLine('See that village far away from the city? Their internet is not reaching properly.',
          16),
      OrbitLine('We need a satellite that can carry signals across long distances.', 17),
    ],
    hintAfterWrong: OrbitLine(
        'Almost, but this village does not need storm tracking or pictures right now. It needs connection.',
        18),
    strongerHint: OrbitLine('Find the satellite that carries internet, phone, and TV signals.', 19),
    successLines: [
      OrbitLine(
          "Nice! That's the communication satellite. It works like a signal bridge between faraway places.",
          20),
      OrbitLine('Now the village can connect for school, calls, and messages.', 21),
    ],
    successEffect: MissionEffectType.communicationWaves,
    thumbnailAsset: CrsAssets.remoteVillage,
    ambientSound: CrsSounds.ambVillage,
    successSting: CrsSounds.stingConnect,
    effectPlacement: EffectPlacement(centerFactor: Offset(0.5, 0.4), widthFactor: 0.5),
  ),

  // ---- Mission 4: Live TV Broadcast -> Communication (clips 22–27) --------
  SatelliteMission(
    id: 'live_tv_broadcast',
    title: 'Live TV Broadcast',
    requestText: 'A city needs a live TV broadcast.',
    correctType: SatelliteType.communication,
    layers: [
      SceneLayer(asset: CrsAssets.cityBroadcastScene, centerFactor: Offset(0.5, 0.64), widthFactor: 0.94),
      SceneLayer(
        asset: CrsAssets.liveTvScreen,
        centerFactor: Offset(0.5, 0.34),
        widthFactor: 0.46,
        idleOpacity: 0.4,
        revealOnSuccess: true,
      ),
    ],
    successLabel: 'Broadcast Live!',
    appearLines: [
      OrbitLine('See the city event? They need to send the live TV signal to lots of homes.', 22),
      OrbitLine('This mission also needs a satellite that carries signals.', 23),
    ],
    hintAfterWrong: OrbitLine(
        'Not this one. A TV broadcast does not need a weather watcher or Earth camera.', 24),
    strongerHint: OrbitLine(
        'Choose the satellite that sends communication signals over long distances.', 25),
    successLines: [
      OrbitLine('Correct! Communication satellites can send TV signals across long distances.', 26),
      OrbitLine('Same satellite family, different mission. Internet and TV both need signals.', 27),
    ],
    successEffect: MissionEffectType.communicationWaves,
    thumbnailAsset: CrsAssets.liveTvScreen,
    ambientSound: CrsSounds.ambCity,
    successSting: CrsSounds.stingBroadcast,
    effectPlacement: EffectPlacement(centerFactor: Offset(0.5, 0.42), widthFactor: 0.5),
  ),

  // ---- Mission 5: Forest Fire Watch -> Earth Observation (clips 28–33) ----
  SatelliteMission(
    id: 'forest_fire_watch',
    title: 'Forest Fire Watch',
    requestText: 'A forest fire may be spreading. We need pictures from above.',
    correctType: SatelliteType.earthObservation,
    layers: [
      SceneLayer(asset: CrsAssets.forestFireScene, centerFactor: Offset(0.5, 0.64), widthFactor: 0.82),
      SceneLayer(
        asset: CrsAssets.smokeOverlay,
        centerFactor: Offset(0.56, 0.34),
        widthFactor: 0.5,
        idleOpacity: 0.75,
        driftUp: true,
      ),
    ],
    successLabel: 'Fire Spotted!',
    appearLines: [
      OrbitLine('Look at that forest. I can see smoke spreading between the trees.', 28),
      OrbitLine(
          'We need pictures from above so the rescue team can see where the fire is moving.', 29),
    ],
    hintAfterWrong:
        OrbitLine('Not quite. This is not about directions, weather, or TV signals.', 30),
    strongerHint:
        OrbitLine("Choose the satellite with a camera that observes Earth's surface.", 31),
    successLines: [
      OrbitLine(
          "Exactly! That's the Earth observation satellite. It takes pictures of forests, farms, rivers, and cities.",
          32),
      OrbitLine(
          'With that view from above, we can spot changes on the ground — like fire, floods, or damaged forests.',
          33),
    ],
    successEffect: MissionEffectType.cameraScan,
    thumbnailAsset: CrsAssets.forestFireScene,
    ambientSound: CrsSounds.ambFire,
    successSting: CrsSounds.stingCamera,
    effectPlacement: EffectPlacement(centerFactor: Offset(0.5, 0.45), widthFactor: 0.85),
    // Programmatic camera-scan cone: from the docked satellite down to the fire.
    beamTargetFactor: Offset(0.48, 0.58),
  ),
];
