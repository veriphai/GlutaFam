// The complete Orbit dialogue script for Save the Coastal City —
// first-person mission style (v2). One line per entry (PRD §22.1). Dialogue
// stays in config — never hard-coded inside scenes or Flame components.
//
// Each Line carries its VOICE CLIP number — the third positional arg — which
// maps to assets/sounds/save_coastal_city/orbit_<NNN>.mp3 (116 clips, named
// in script order at copy time). The controller bumps voiceToken whenever a
// line with a clip is shown; the shell's voice lane plays it.

import 'scc_assets.dart';

enum OrbitFace { neutral, explaining, scanning, excited, celebrating, alert, worried, thinking }

extension OrbitFaceSprite on OrbitFace {
  String get sprite => switch (this) {
        OrbitFace.neutral => SCC.orbitNeutral,
        OrbitFace.explaining => SCC.orbitExplaining,
        OrbitFace.scanning => SCC.orbitScanning,
        OrbitFace.excited => SCC.orbitExcited,
        OrbitFace.celebrating => SCC.orbitCelebrating,
        OrbitFace.alert => SCC.orbitAlert,
        OrbitFace.worried => SCC.orbitWorried,
        OrbitFace.thinking => SCC.orbitThinking,
      };
}

class Line {
  final String text;
  final OrbitFace face;
  final int? clip; // 1-based index into orbit_<NNN>.mp3
  const Line(this.text, [this.face = OrbitFace.neutral, this.clip]);
}

class SccDialogue {
  SccDialogue._();

  // ── Intro (clips 1–5) ─────────────────────────────────────────────────────
  static const intro = [
    Line('Whoa… look at that spiral over the ocean.', OrbitFace.alert, 1),
    Line('That storm is forming close to the coast.', OrbitFace.worried, 2),
    Line('See that city below? If we warn them early, people can move to safety.', OrbitFace.explaining, 3),
    Line('You’ve learned every satellite skill. I need you as lead engineer now.', OrbitFace.excited, 4),
    Line('Come on — let’s run the full mission chain and save the city.', OrbitFace.excited, 5),
  ];

  // ── Stage 1 · Choose the Right Satellite (clips 6–19) ─────────────────────
  static const s1Intro = [
    Line('See these satellites? Each one has a different job.', OrbitFace.explaining, 6),
    Line('Let’s scan them and find the one that can watch storms.', OrbitFace.scanning, 7),
  ];
  static const s1Nav = [
    Line('This one helps cars and ships find where they are.', OrbitFace.scanning, 8),
    Line('Useful, but this cyclone doesn’t need directions.', OrbitFace.thinking, 9),
  ];
  static const s1Comm = [
    Line('This one sends signals across huge distances.', OrbitFace.scanning, 10),
    Line('Great for connection, but it can’t show us the storm shape.', OrbitFace.thinking, 11),
  ];
  static const s1EarthScan = [
    Line('This one gives us a big view of land, farms, and floods.', OrbitFace.scanning, 12),
    Line('Helpful, but this storm is over the ocean. We need weather eyes.', OrbitFace.thinking, 13),
  ];
  static const s1Weather = [
    Line('Yes — that’s the one.', OrbitFace.excited, 14),
    Line('This satellite can watch clouds, storms, and cyclones from space.', OrbitFace.explaining, 15),
  ];
  static const s1WrongDeploy = [
    Line('Almost. That satellite is useful, but not for watching this storm.', OrbitFace.thinking, 16),
    Line('Try the one with weather eyes.', OrbitFace.explaining, 17),
  ];
  static const s1Success = [
    Line('Perfect. Weather satellite selected.', OrbitFace.celebrating, 18),
    Line('Now we can actually see what the cyclone is doing.', OrbitFace.explaining, 19),
  ];

  // ── Stage 2 · Place It in the Right Orbit (clips 20–29) ───────────────────
  static const s2Intro = [
    Line('Look at the storm and the city. We need both in view.', OrbitFace.explaining, 20),
    Line('Pull, aim, and launch the satellite into the glowing watch ring.', OrbitFace.excited, 21),
  ];
  static const s2TooLow = [
    Line('Oof, we’re too close.', OrbitFace.thinking, 22),
    Line('See that? We can only watch a small patch, not the whole storm.', OrbitFace.explaining, 23),
  ];
  static const s2TooFar = [
    Line('Whoa, that’s too far.', OrbitFace.alert, 24),
    Line('We can see more Earth, but the storm details are getting weak.', OrbitFace.explaining, 25),
  ];
  static const s2Almost = [
    Line('Almost. Aim for the glowing watch ring.', OrbitFace.thinking, 26),
    Line('That spot gives us a wide view and clear storm detail.', OrbitFace.explaining, 27),
  ];
  static const s2Success = [
    Line('Orbit locked!', OrbitFace.celebrating, 28),
    Line('Nice. From here, we can watch the cyclone and the city together.', OrbitFace.explaining, 29),
  ];

  // ── Stage 3 · Keep It Powered (clips 30–39) ───────────────────────────────
  static const s3Intro = [
    Line('Our satellite is in position, but it needs power to stay alive.', OrbitFace.explaining, 30),
    Line('See the Sun beam? Turn the panels toward it.', OrbitFace.explaining, 31),
  ];
  static const s3WrongAngle = [
    Line('Not enough sunlight yet. Keep turning the panels.', OrbitFace.thinking, 32),
  ];
  static const s3Perfect =
      Line('There! The panels are catching strong sunlight.', OrbitFace.excited, 33);
  static const s3ShadowWarning = [
    Line('Uh-oh, Earth is about to block the Sun.', OrbitFace.alert, 34),
    Line('See that dark zone? The satellite will need battery power there.', OrbitFace.explaining, 35),
  ];
  static const s3BatteryPrompt =
      Line('Pull the battery reserve now.', OrbitFace.alert, 36);
  static const s3BatteryEarly = [
    Line('A little early. Let’s save reserve power for the shadow.', OrbitFace.thinking, 37),
  ];
  static const s3BatteryLate =
      Line('Power is dropping. Pull the reserve!', OrbitFace.alert, 38);
  static const s3Success = [
    Line('Nice save. Power is stable, and the mission is still alive.', OrbitFace.celebrating, 39),
  ];

  // ── Stage 4 · Capture the Cyclone Image (clips 40–51) ─────────────────────
  static const s4Intro = [
    Line('Now let’s use the satellite camera.', OrbitFace.explaining, 40),
    Line('See the cyclone moving below us? Bring it into the camera view.', OrbitFace.scanning, 41),
  ];
  static const s4NotCentered = [
    Line('I can see clouds, but not the full storm yet.', OrbitFace.thinking, 42),
    Line('Move the camera until the storm sits inside the target.', OrbitFace.explaining, 43),
  ];
  static const s4TooZoomedIn = [
    Line('Too close. We’re only seeing one part of the cloud.', OrbitFace.thinking, 44),
    Line('Zoom out so we can see the full pattern.', OrbitFace.explaining, 45),
  ];
  static const s4TooZoomedOut = [
    Line('Too wide. The storm is getting too tiny.', OrbitFace.thinking, 46),
    Line('Zoom in until the pattern becomes clear.', OrbitFace.explaining, 47),
  ];
  static const s4Locked = [
    Line('Target locked. The cyclone is clear.', OrbitFace.excited, 48),
    Line('Capture it now.', OrbitFace.excited, 49),
  ];
  static const s4Success = [
    Line('Image captured!', OrbitFace.celebrating, 50),
    Line('Great view. That’s the data Earth needs.', OrbitFace.explaining, 51),
  ];

  // ── Stage 5 · Send Data to Earth (clips 52–64) ────────────────────────────
  static const s5Intro = [
    Line('We have the image, but the people on Earth can’t use it yet.', OrbitFace.explaining, 52),
    Line('See that ground station? Aim the antenna at it.', OrbitFace.explaining, 53),
    Line('Now tune the signal until the wave becomes clean.', OrbitFace.explaining, 54),
  ];
  static const s5WrongAim = [
    Line('The beam is missing the dish.', OrbitFace.thinking, 55),
    Line('Turn the antenna until the signal touches the ground station.', OrbitFace.explaining, 56),
  ];
  static const s5Noisy = [
    Line('Hear that static? The data may break.', OrbitFace.thinking, 57),
    Line('Tune slowly until the wave clears.', OrbitFace.explaining, 58),
  ];
  static const s5WeakClose = [
    Line('Almost. The station can hear us, but the signal is weak.', OrbitFace.thinking, 59),
    Line('Hold steady and fine-tune.', OrbitFace.explaining, 60),
  ];
  static const s5Locked = [
    Line('Clean signal locked.', OrbitFace.excited, 61),
    Line('Send the image down.', OrbitFace.excited, 62),
  ];
  static const s5Success = [
    Line('Data downlinked!', OrbitFace.celebrating, 63),
    Line('Now the ground team has the storm image.', OrbitFace.explaining, 64),
  ];

  // ── Stage 6 · Read the Satellite Image (clips 65–79) ──────────────────────
  static const s6Intro = [
    Line('Now we become Earth detectives.', OrbitFace.excited, 65),
    Line('See this satellite image? The warning depends on reading it correctly.', OrbitFace.explaining, 66),
  ];
  static const s6CloudLayer = [
    Line('Start with the cloud view.', OrbitFace.scanning, 67),
    Line('Look for clouds curving around a center, not random white patches.', OrbitFace.explaining, 68),
  ];
  static const s6HeatLayer = [
    Line('Slide to the weather layer.', OrbitFace.scanning, 69),
    Line('See the stronger colors? That’s where the storm is more active.', OrbitFace.explaining, 70),
  ];
  static const s6WindLayer = [
    Line('Now check the wind layer.', OrbitFace.scanning, 71),
    Line('See those curved arrows? They show the air rotating.', OrbitFace.explaining, 72),
  ];
  static const s6CircleNow =
      Line('Now circle the cyclone pattern.', OrbitFace.excited, 73);
  static const s6ViewAllNudge =
      Line('Wait — check the layers first. Each one gives us a clue.', OrbitFace.explaining, 74);
  static const s6WrongPatch = [
    Line('That’s a cloud patch, but it isn’t rotating like the cyclone.', OrbitFace.thinking, 75),
    Line('Look near the ocean for the curved cloud arms.', OrbitFace.explaining, 76),
  ];
  static const s6Close =
      Line('You’re close. Follow the curved arms inward.', OrbitFace.thinking, 77);
  static const s6Success = [
    Line('There it is — cyclone pattern identified!', OrbitFace.celebrating, 78),
    Line('We have the evidence we need for the warning.', OrbitFace.explaining, 79),
  ];

  // ── Stage 7 · Fix the Surprise Issue (clips 80–96) ────────────────────────
  static const s7Alert = [
    Line('Uh-oh. Thermal alert!', OrbitFace.alert, 80),
    Line('See the battery glowing red? It’s getting too hot.', OrbitFace.worried, 81),
    Line('If it overheats, the satellite may stop watching the cyclone.', OrbitFace.worried, 82),
  ];
  static const s7BeforeRepair = [
    Line('Don’t panic. We’ll fix it like satellite doctors.', OrbitFace.explaining, 83),
    Line('First, guide the heat away from the battery and toward the radiator.', OrbitFace.explaining, 84),
  ];
  static const s7WrongTrace = [
    Line('That sends heat the wrong way.', OrbitFace.worried, 85),
    Line('Trace it toward the cooling panel.', OrbitFace.explaining, 86),
  ];
  static const s7AfterTrace =
      Line('Good. Heat is moving to the radiator.', OrbitFace.excited, 87);
  static const s7RadiatorStep = [
    Line('Now look at the radiator. It needs to face cold space, not the Sun.', OrbitFace.explaining, 88),
    Line('Rotate it away from sunlight.', OrbitFace.explaining, 89),
  ];
  static const s7WrongRadiator = [
    Line('It’s still facing the Sun.', OrbitFace.thinking, 90),
    Line('Turn it toward deep space.', OrbitFace.explaining, 91),
  ];
  static const s7AfterRadiator =
      Line('Yes. The radiator can release heat now.', OrbitFace.excited, 92);
  static const s7SwitchStep = [
    Line('One more thing — switch off extra camera boost.', OrbitFace.explaining, 93),
    Line('Less power means less heat.', OrbitFace.explaining, 94),
  ];
  static const s7Success = [
    Line('Temperature falling… battery safe.', OrbitFace.celebrating, 95),
    Line('Nice repair. Thermal control saved the mission.', OrbitFace.explaining, 96),
  ];

  // ── Stage 8 · Upload Command Sequence (clips 97–110) ──────────────────────
  static const s8Intro = [
    Line('The city needs updates again and again, not just one image.', OrbitFace.explaining, 97),
    Line('Let’s build a mission loop for the satellite.', OrbitFace.explaining, 98),
    Line('Connect the commands: watch, capture, send, check, repeat.', OrbitFace.explaining, 99),
  ];
  static const s8AlertTooEarly = [
    Line('Not yet. The city needs evidence before the warning.', OrbitFace.thinking, 100),
    Line('Send the storm data first.', OrbitFace.explaining, 101),
  ];
  static const s8SkipBattery = [
    Line('Add a battery check.', OrbitFace.thinking, 102),
    Line('The satellite has to protect itself while it works.', OrbitFace.explaining, 103),
  ];
  static const s8SkipRepeat = [
    Line('Add repeat monitoring.', OrbitFace.thinking, 104),
    Line('The cyclone is still moving, so one image is not enough.', OrbitFace.explaining, 105),
  ];
  static const s8PathComplete = [
    Line('Command path complete.', OrbitFace.excited, 106),
    Line('Hold to upload the mission loop.', OrbitFace.excited, 107),
  ];
  static const s8Uploading = [
    Line('Uploading mission loop…', OrbitFace.scanning, 108),
  ];
  static const s8Success = [
    Line('Autonomous monitoring online!', OrbitFace.celebrating, 109),
    Line('Now the satellite can keep watching and sending updates on its own.', OrbitFace.explaining, 110),
  ];

  // ── Mission Complete (clips 111–116) ──────────────────────────────────────
  static const finale = [
    Line('Live cyclone data received.', OrbitFace.excited, 111),
    Line('The warning is going to the coastal city.', OrbitFace.excited, 112),
    Line('Schools, hospitals, ships, and rescue teams now know what’s coming.', OrbitFace.explaining, 113),
    Line('You did it. The city has time to prepare.', OrbitFace.celebrating, 114),
  ];
  static const missionControl = 'Warning sent. Coastal City is safe. Mission successful.';
  static const finaleEmotional = [
    Line('Today, you didn’t just learn about satellites.', OrbitFace.excited, 115),
    Line('You became the engineer Earth was waiting for.', OrbitFace.celebrating, 116),
  ];

  // ── Badge reveal (tap-to-reveal one-liners, unvoiced) ─────────────────────
  static const badgeLines = {
    'badge_satellite_engineer': 'You completed a full Earth rescue mission from space.',
    'badge_orbit_master': 'You placed the satellite where it could watch the storm clearly.',
    'badge_signal_specialist': 'You sent critical data from space to Earth.',
    'badge_earth_detective': 'You read the satellite image and found the cyclone spiral.',
    'badge_satellite_doctor': 'You diagnosed overheating and saved the satellite.',
    'badge_mission_commander': 'You uploaded commands so the satellite could keep protecting the city.',
  };
}
