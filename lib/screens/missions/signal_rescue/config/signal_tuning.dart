// All Signal Rescue tuning in one place — spatial anchors (as FACTORS of the
// Flame stage size, never pixels), signal thresholds (verbatim from the PRD
// §10.3), timings, and helper copy. A nudge to layout/feel = editing one number
// here. Budget a live on-device tuning pass for the anchors (per the playbook).

import 'package:flutter/material.dart';

import '../state/signal_rescue_state.dart';

class SRTune {
  SRTune._();

  // ── stage anchors (factor of stage w/h) ─────────────────────────────────────
  // All Flame action lives in the upper ~58% of the screen; the lower part is
  // overlaid by the Flutter monitor / helper / controls.
  static const double playBottom = 0.58; // fraction of height the scene occupies

  // Earth globe (the green island): centre anchor, raised + sized so its built-in
  // circular landing-pad marking (asset centre) lands at mid-lower screen, where
  // the ground station is seated ON it.
  static const Offset earthCenter = Offset(0.51, 0.66); // centre anchor
  static const double earthWidthFactor = 1.6; // × stage width

  // Satellite: upper area, gently bobbing.
  static const Offset satelliteCenter = Offset(0.40, 0.20);
  static const double satelliteWidthFactor = 0.46; // × stage width (BODY only; hinge/dish are independent)

  // Antenna pivot sits on top of the satellite body.
  static const Offset antennaPivotOffset = Offset(0.0, -0.085); // rel. to sat centre (frac of stage h)
  static const double dishWidthFactor = 0.20;
  static const double mountWidthFactor = 0.075; // small hinge
  // Dish sprite faces "up" naturally; nudge if its art points elsewhere (tune on device).
  static const double dishAngleOffset = 0.0;
  // Rotation hint ring radius, × dish width (smaller = tighter around the dish).
  static const double rotationRingRadiusFactor = 0.58;

  // The cyclone swirl on the Earth's ocean (Flutter overlay over the stage —
  // the storm the satellite photographed). Highlighted during briefing lines
  // 1 (whole storm) and 2 (its eye).
  static const Offset cycloneCenter = Offset(0.105, 0.49);
  static const double cycloneWidthFactor = 0.20; // × stage width

  // Ground station: bottomCenter base seated on the island's landing pad. The
  // BEAM/aim target is lifted to the dish (base − stationAimRise·h), not the base.
  static const Offset groundStationCenter = Offset(0.5, 0.64);
  static const double groundStationWidthFactor = 0.22;
  static const double rangeRingRadiusFactor = 0.16; // green range ring radius, × stage width
  static const double stationAimRise = 0.085; // dish height above the base (frac of h)

  // Orbit drift: the satellite glides horizontally along a shallow arc during
  // wait-for-range. Expressed as the centre + half-extents (factor of stage).
  static const Offset orbitArcCenter = Offset(0.42, 0.165);
  static const double orbitArcHalfWidth = 0.12; // ± in x (gentle, so aim stays valid)
  static const double orbitArcRise = 0.05; // arc bow height
  // The communication window = the slice of the orbit phase where the satellite
  // is "over" the station and inRange is true. Phase runs 0..1 looping. Centred
  // on phase 0.5, where the satellite returns to its aligned x — so a good aim
  // naturally locks mid-window (the "catch the window" beat) and kids get a
  // forgiving ~2.7s pass each loop.
  static const double windowStart = 0.34;
  static const double windowEnd = 0.66;
  static const double orbitPeriod = 8.5; // seconds for a full drift loop

  // ── signal thresholds (PRD §10.3) ───────────────────────────────────────────
  static const double maxAllowedDiff = 45.0; // degrees, for angleAccuracy
  static const double weakMaxDiff = 45.0;
  static const double strongMaxDiff = 20.0;
  static const double lockMaxDiff = 8.0;
  static const double outOfRangeWeakDiff = 20.0; // aligned-but-no-range ⇒ weak under this
  static const double minBatteryToTransmit = 30.0;

  // The child counts as "aligned enough" to advance from align→range search.
  static const double alignAdvanceDiff = 18.0;
  static const double alignDwell = 0.9; // s held under alignAdvanceDiff to advance

  // Magnetic easing: pull the dish toward the target when within this band so
  // young users can settle on a lock (assist, never auto-solve).
  static const double magnetBand = 14.0; // degrees
  static const double magnetStrength = 0.30; // 0..1 pull per applied drag

  // ── battery ─────────────────────────────────────────────────────────────────
  static const double startBattery = 85.0;
  static const double searchDrainPerSec = 0.6; // gentle drain while searching
  static const double transmitDrain = 7.0; // total dip across transmission

  // ── timings ───────────────────────────────────────────────────────────────
  static const double introDwell = 2.4; // s before auto-advancing intro (or Start)
  static const double explainStepDur = 2.6; // s per briefing line when MUTED (voice paces it otherwise)
  static const double transmitDuration = 27.5; // s — sized so the 4 narration clips (~25s) fit their windows
  static const double packetInterval = 1.1; // s between launched packets
  static const double idleHintAfter = 7.0; // s of inactivity → nudge

  // storm timer (built but OFF in the flagship mission — forgiving)
  static const bool stormEnabledDefault = false;
  static const double stormDuration = 45.0;

  // ── beam colours by signal state ─────────────────────────────────────────────
  static Color beamColor(SignalState s) => switch (s) {
        SignalState.noSignal => const Color(0xFFFF4D4D),
        SignalState.weak => const Color(0xFFFFC43D),
        SignalState.strong => const Color(0xFF49E06B),
        SignalState.locked => const Color(0xFF35B6FF),
      };

  // ── copy (Orbit speaks in first person) ─────────────────────────────────────
  // Every line is a NAMED const so it can key [orbitClipFor] (const-map keys
  // can't index a const list). Multi-line lists auto-advance one line every
  // [seqLineDur] while their state holds — and the sequencer FREEZES while the
  // line's voice clip plays (voice-paced), releasing ~0.35s after completion.
  static const double seqLineDur = 2.8;

  static const String introLine =
      "Uh-oh! I captured a cyclone image, but Mission Control can't see it yet. "
      "Can you help me send it to Earth?";

  // Briefing once the mission STARTS: the cyclone + its eye first (no part
  // highlighted), then the antenna + ground station tour. Data packets are
  // explained later, while they're actually flying.
  static const String explainLine1 =
      "See that giant swirl in the ocean? That's a cyclone — a huge spinning storm.";
  static const String explainLine2 =
      'Look closely at the middle. That calm circle is called the eye of the cyclone.';
  static const String explainLine3 = 'See my antenna? I use it to talk to Earth.';
  static const String explainLine4 =
      "And see that dish on the ground? That's the ground station. It listens for my signal.";
  static const String explainLine5 =
      'My antenna and the ground station need to face each other — almost like two walkie-talkies!';
  static const List<String> explainLines = [
    explainLine1, explainLine2, explainLine3, explainLine4, explainLine5,
  ];
  // Which PartCallouts index is active per briefing step (-1 = none).
  static const List<int> explainCalloutStep = [-1, -1, 0, 1, 1];

  // align antenna (three coaching bands by aim error)
  static const String alignLine = 'Can you turn my antenna toward the ground station?';
  static const String alignCoachLine =
      'Try lining it up more carefully. The straighter the aim, the stronger the signal!';
  static const String weakLine =
      "Nice! You're getting closer… but my signal is still a little weak.";

  // waiting for the pass (sequence while aim is held out of range)
  static const String waitLine1 = "Great aim! But I'm still a bit too far from the station.";
  static const String waitLine2 =
      'I keep moving around Earth, so the station can only hear me during a short pass.';
  static const String waitLine3 = 'Wait for me to move into the glowing range zone.';
  static const List<String> waitLines = [waitLine1, waitLine2, waitLine3];
  static const String inRangeLine = "Now! I'm in range. Point my antenna right at the station!";

  static const String strongLine1 = 'Yes! The signal is strong now.';
  static const String strongLine2 =
      'My battery looks good too. Sending data uses power, so we always check before sending.';
  static const List<String> strongLines = [strongLine1, strongLine2];

  static const String lockedLine1 = 'Data locked! That means my connection to Earth is steady.';
  static const String lockedLine2 = 'Quick — tap send so I can send the cyclone image!';
  static const List<String> lockedLines = [lockedLine1, lockedLine2];

  // transmission — advanced by PROGRESS at [transmitLineFracs] (windows sized to
  // each clip's length so lines aren't cut mid-word)
  static const String transmitLine1 = "There it goes! I'm sending the image as tiny data packets.";
  static const String transmitLine2 = 'Each packet carries a small piece of the picture.';
  static const String transmitLine3 =
      'See the cyclone appearing on the screen? The packets are rebuilding the image on Earth!';
  static const String transmitLine4 =
      "Look at the calm dot in the middle — that's the cyclone's eye.";
  static const List<String> transmitLines = [
    transmitLine1, transmitLine2, transmitLine3, transmitLine4,
  ];
  static const List<double> transmitLineFracs = [0.22, 0.40, 0.735];

  static const String successLine = 'Mission complete! Earth received my cyclone image!';
  // Why it matters + the impact (the success wrap-up card shows both; the voice
  // chain plays them as two clips after the success line).
  static const String successWrap1 = "Now scientists can see where the storm's center is.";
  static const String successWrap2 =
      'Because we sent it in time, people near the coast can prepare and get to safety.';
  static const String wrapUpLine = '$successWrap1 $successWrap2';

  // failed-send reasons (friendly, never punishing — PRD §11.3)
  static const String reasonRange = "Not yet! Wait until I'm closer to the ground station.";
  static const String reasonAim = "I can't send yet — my antenna isn't aimed at the station.";
  static const String reasonBattery = 'Oops, my battery is too low to send right now.';
  static const String reasonWeak = 'The signal is still weak. Try lining up my antenna a little closer.';
  static const String reasonAlmost =
      'Almost! Keep the antenna pointed at the station until the signal locks.';

  // ── Orbit voice clips (assets/sounds/signal_rescue/orbit/orbit_NN.wav) ──────
  // The choke point: every helper line maps to its clip number; the controller
  // stamps voiceClip + bumps voiceToken in _set() whenever helperMessage changes
  // to a mapped line. Repeated identical text deliberately does NOT re-voice.
  static const Map<String, int> orbitClipFor = {
    introLine: 1,
    explainLine1: 2,
    explainLine2: 3,
    explainLine3: 4,
    explainLine4: 5,
    explainLine5: 6,
    alignLine: 7,
    weakLine: 8,
    alignCoachLine: 9,
    waitLine1: 10,
    waitLine2: 11,
    waitLine3: 12,
    inRangeLine: 13,
    strongLine1: 14,
    strongLine2: 15,
    lockedLine1: 16,
    lockedLine2: 17,
    transmitLine1: 18,
    transmitLine2: 19,
    transmitLine3: 20,
    transmitLine4: 21,
    successLine: 22,
    successWrap1: 23,
    successWrap2: 24,
    reasonRange: 25,
    reasonAim: 26,
    reasonBattery: 27,
    reasonWeak: 28,
    reasonAlmost: 29,
  };
}
