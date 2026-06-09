// All tunable numbers + Mission Control copy for the Power Balance Challenge,
// in ONE place so difficulty/feel/text are trivial to retune (PRD §11, §16,
// §19). Battery values are verbatim from the PRD's recommended tuning.

import 'dart:ui' show Offset;

class PBTune {
  PBTune._();

  // ── battery simulation (PRD §11.1, per second unless noted) ──────────────
  static const double startBattery = 18.0;
  static const double maxBattery = 100.0;
  static const double lowThreshold = 25.0;
  static const double criticalThreshold = 10.0;

  static const double baseDrainPerSec = 0.85; // satellite always uses power — drains noticeably so the child must re-charge several times
  static const double solarAlignedChargePerSec = 5.0;
  // Below base drain ON PURPOSE: when panels are NOT aligned the battery must
  // never rise — it only goes UP when the child actively aligns (taps Solar).
  static const double solarMisalignedChargePerSec = 0.25;
  static const double cameraDrainPerSec = 1.5;
  static const double antennaDrainPerSec = 1.2;
  static const double thrusterCost = 8.0; // instant, per tap
  // a thruster tap briefly speeds the satellite along its orbit (visible boost)
  static const double thrustBoostFactor = 4.5; // ×orbit speed during the burst
  static const double thrustBoostDuration = 1.4; // seconds the burst lasts

  /// Battery level the solar tutorial charges up to before moving on (PRD §12 Scene 2).
  static const double solarTutorialTarget = 55.0;

  /// How long one Solar-Align tap keeps the panels aligned (PRD §11.2: "a few
  /// seconds"). After this, charging falls back to the misaligned trickle.
  static const double solarAlignHold = 6.0;

  // ── orbit + zones (PRD §11.3) ────────────────────────────────────────────
  /// Seconds for one full orbit lap in the free loop.
  static const double orbitPeriod = 26.0;
  static const double tutorialOrbitPeriod = 20.0; // slightly slower while guided

  /// Zone boundaries as orbit-progress fractions (0..1).
  static const double sunlightEnd = 0.25;
  static const double targetEnd = 0.40;
  static const double groundEnd = 0.55;
  static const double shadowEnd = 0.75; // 0.75..1.0 is sunlight again

  /// Progress points the guided orbit HOLDS at until the child acts.
  static const double holdSunlight = 0.12; // low-battery crisis / solar tutorial
  static const double holdTarget = 0.33; // first capture
  static const double holdGround = 0.48; // first transmission

  // ── mission goals ────────────────────────────────────────────────────────
  static const int imagesNeeded = 3;
  static const int dataNeeded = 3;

  // ── scene geometry — factor anchors of the full stage (eyeball-tuned) ─────
  // FULL-TRAVERSE orbit: the satellite sweeps a wide, always-visible ellipse
  // (full width, never hidden, loops cleanly). Progress 0..1 = one lap; the
  // capture beam + data packets connect to the cyclone/dish DYNAMICALLY, so the
  // satellite only has to be in the right ZONE, not exactly above them.
  // Path: pos = orbitCenter + (radiusX·sin(2π·p), −radiusY·cos(2π·p))
  //   p≈0 top (sunlight) → 0.25 right (target) → 0.5 bottom (ground/shadow) →
  //   0.75 left → back to top. Bottom stays above the Earth limb + dock.
  // Orbit sits in the UPPER space region; the satellite never dips onto Earth.
  static const Offset orbitCenter = Offset(0.50, 0.31);
  static const double orbitRadiusX = 0.40; // → x spans 0.10..0.90 (full width)
  static const double orbitRadiusY = 0.13; // → y spans 0.18..0.44 (above the Earth limb)
  static const double satelliteWidthFactor = 0.34; // of stage width

  static const Offset sunCenter = Offset(0.16, 0.15);
  static const double sunWidthFactor = 0.30;

  // Earth = a PROMINENT curved horizon across the bottom of the play area (mock).
  // [earthBottomCenter] is the sprite's BOTTOM-centre (Earth's lower half runs off
  // the screen); the atmosphere limb is the top edge → shows ~y0.57 and curves
  // down behind the dock. The cyclone/dish sit ON this limb so they never float.
  // Earth sprite is a wide horizon cutout (aspect ~3.25). bottom-anchored at the
  // screen bottom; ~2.8× width → a gentle curve, limb showing ~y0.61.
  // Earth bottom-anchored at the screen bottom; sized to fill the lower portion.
  static const Offset earthBottomCenter = Offset(0.50, 1.0);
  static const double earthWidthFactor = 3.6;

  static const Offset cycloneCenter = Offset(0.58, 0.60); // ON the Earth
  static const double cycloneWidthFactor = 0.26;

  static const Offset groundStationCenter = Offset(0.40, 0.63); // ON the Earth
  static const double groundStationWidthFactor = 0.24;

  // ── feedback / timing ────────────────────────────────────────────────────
  static const double captureBeat = 1.3; // scan→flash→thumbnail duration
  static const double sendBeat = 1.5; // packet flight duration
  static const double idleHintAfter = 7.0;
  static const double crisisBeat = 2.4; // gap between the sequenced crisis lines
  static const double messageHold = 2.4; // event copy persists before ambient nudges resume

  /// Pre-shadow teachable beat: the orbit holds just before the shadow while
  /// Orbit says "Shadow ahead… charge now", giving the child a moment to top up.
  static const double holdPreShadow = 0.525;
  static const double preShadowBeat = 6.0; // how long the pre-shadow hold lasts
  static const double shadowSaveAfter = 3.5; // s in shadow w/ systems off → praise
  static const double thrusterSpamWindow = 5.0; // a re-fire within this = spam
  static const double lowExitBattery = 15.0; // exit shadow below this → "that was close"

  // ── Orbit's dialogue library ──────────────────────────────────────────────
  // Each line is numbered for the future voice-over files: record one clip per
  // line as assets/sounds/power_balance/orbit/orbit_NN.(wav|mp3).
  static const introTitle = 'Keep the Satellite Alive';
  static const introSubtitle = 'Your satellite is losing power. Can you save the mission?';

  // Intro / Start (cycled in the start-screen bubble)  orbit_01..03
  static const intro1 =
      'See our satellite up there? It needs power to run its camera, antenna, and computer.'; // orbit_01
  static const intro2 =
      'I’ll help you keep it alive. Every system uses energy, so we’ll choose carefully.'; // orbit_02
  static const intro3 =
      'Our job is simple: save power, capture cyclone images, and send them to Earth.'; // orbit_03
  static const introLines = [intro1, intro2, intro3];

  // Crisis (sequenced)  orbit_04..07
  static const crisis1 = 'Uh-oh. Look at that battery — only 18% left.'; // orbit_04
  static const crisis2 =
      'The camera is shutting down. The satellite doesn’t have enough power to work.'; // orbit_05
  static const crisis3 =
      'There are no plug points in space, so we’ll have to use sunlight.'; // orbit_06
  static const crisis4 = 'See the Sun on the side? That’s our charger.'; // orbit_07
  static const crisisLines = [crisis1, crisis2, crisis3, crisis4];

  // Solar charging  orbit_08..13
  static const solarPrompt = 'Turn the panels toward the Sun. They need to face the light.'; // orbit_08
  static const solarCharging = 'Nice! See them glow? The panels are collecting sunlight.'; // orbit_09
  static const solarFact = 'That sunlight is becoming electrical power for the satellite.'; // orbit_10
  static const solarStoring = 'The battery is filling up. We’ll need that stored power when things get dark.'; // orbit_11
  static const solarMisaligned = 'Oops, the panels aren’t facing the Sun properly. Let’s align them.'; // orbit_12
  static const solarKeepGoing = 'Keep charging for a little longer. A stronger battery gives us more mission time.'; // orbit_13

  // Camera  orbit_14..20
  static const cameraComing = 'Look below — a cyclone is coming into view.'; // orbit_14
  static const cameraGetReady = 'Get ready. We only turn the camera on when there’s something important to see.'; // orbit_15
  static const cameraPrompt = 'Now! The cyclone is right below us. Turn the camera on.'; // orbit_16
  static const cameraCaptured = 'Image captured! See? From space, satellites can watch huge storms at once.'; // orbit_17
  static const cameraWrong = 'Careful — the camera is still on, but there’s no target below.'; // orbit_18
  static const cameraTurnOff = 'Let’s turn it off. A camera is useful, but it eats power fast.'; // orbit_19
  static const cameraLowBattery = 'Battery is too low for the camera. Let’s charge first.'; // orbit_20

  // Antenna / sending data  orbit_21..27
  static const antennaHaveImage = 'We’ve got an image. Now we need to send it to Earth.'; // orbit_21
  static const antennaComing = 'See that ground station coming up? That’s where Earth can receive our signal.'; // orbit_22
  static const antennaPrompt = 'Ground station in view! Turn the antenna on.'; // orbit_23
  static const antennaSent = 'Data sent! The image has reached Earth.'; // orbit_24
  static const antennaWrong = 'No ground station nearby yet. If we send now, we’ll waste power.'; // orbit_25
  static const antennaWaitEarth = 'Let’s wait until Earth can hear us properly.'; // orbit_26
  static const antennaEdu = 'A satellite is only useful if it can send back what it sees.'; // orbit_27

  // Earth shadow  orbit_28..34
  static const shadowAhead = 'Shadow ahead. See that darker part of the orbit?'; // orbit_28
  static const shadowChargeNow = 'Charge now. Solar panels won’t help once we enter Earth’s shadow.'; // orbit_29
  static const shadowEnter = 'We’re in shadow now. No sunlight here.'; // orbit_30
  static const shadowOnBattery = 'Now the satellite has to survive on battery power.'; // orbit_31
  static const shadowDraining = 'Turn off the camera and antenna. They drain power too fast in the dark.'; // orbit_32
  static const shadowSaving = 'Good save. In shadow, we keep only the important systems running.'; // orbit_33
  static const shadowExit = 'Sunlight is back! Let’s point the panels to the Sun and recharge.'; // orbit_34

  // Free play / zone nudges  orbit_35..41
  static const loopSunlight = 'Sunlight again. Good time to charge.'; // orbit_35
  static const loopTarget = 'Target coming up. Get the camera ready.'; // orbit_36
  static const loopGround = 'Ground station soon. Keep the antenna ready.'; // orbit_37
  static const loopShadow = 'Shadow ahead. Save power before it gets dark.'; // orbit_38
  static const loopLowBattery = 'Battery is low. Let’s switch off anything we don’t need.'; // orbit_39
  static const freeThink = 'Think like a satellite engineer: spend power only when it helps the mission.'; // orbit_40
  static const freePraise = 'Nice timing. That’s how engineers keep satellites working.'; // orbit_41

  // Thruster  orbit_42..45
  static const thrusterTip = 'See the thruster? It can help us adjust, but it uses a lot of power.'; // orbit_42
  static const thrusterOnlyWhenNeeded = 'Use thrusters only when we really need them.'; // orbit_43
  static const thrusterSpam = 'Too much thrust wastes battery. Tiny corrections are smarter.'; // orbit_44
  static const thrusterGoodChoice = 'Good choice. Saving fuel and power is part of the mission.'; // orbit_45

  // Mistake recovery  orbit_46..49
  static const recoverAlive = 'No worries. The satellite is still alive — let’s fix the power.'; // orbit_46
  static const recoverWrongTime = 'We used power at the wrong time. Let’s charge and try again.'; // orbit_47
  static const recoverClose = 'That was close. Next time, we’ll switch systems off before shadow.'; // orbit_48
  static const recoverGoodCatch = 'Good catch. You saved power before it became a problem.'; // orbit_49

  // Success / failure  orbit_50..54
  static const successLine = 'Mission complete! You kept the satellite alive.'; // orbit_50
  static const success2 = 'We captured the cyclone images and sent the data to Earth.'; // orbit_51
  static const success3 = 'You just balanced power like a real satellite engineer.'; // orbit_52
  static const failureLine = 'Power lost. The satellite can’t run its camera, antenna, or computer now.'; // orbit_53
  static const failureHint = 'Let’s try again. Charge in sunlight, save power in shadow, and use systems only when needed.'; // orbit_54

  // Not voiced (state nudge kept from the old script):
  static const antennaNoData = 'Capture an image first, then send it to Earth.';

  // Low-power systems alert (premium popup, ~2s — system UI, not Orbit)
  static const lowPowerAlertTitle = 'POWER CRITICAL';
  static const lowPowerAlertBody = 'Shutting down extra systems. Only critical systems running.';

  /// Orbit line → voice clip number (orbit_NN.wav). The controller stamps the
  /// clip + bumps voiceToken whenever helperMessage changes to one of these —
  /// ONE choke point instead of 30 call sites. Lines not in the map (e.g.
  /// [antennaNoData]) change text silently. Intro 01..03 + success 51/52 +
  /// failure 54 are chained by the SCREEN (they never pass through
  /// helperMessage).
  static const Map<String, int> orbitClipFor = {
    intro1: 1, intro2: 2, intro3: 3,
    crisis1: 4, crisis2: 5, crisis3: 6, crisis4: 7,
    solarPrompt: 8, solarCharging: 9, solarFact: 10, solarStoring: 11,
    solarMisaligned: 12, solarKeepGoing: 13,
    cameraComing: 14, cameraGetReady: 15, cameraPrompt: 16, cameraCaptured: 17,
    cameraWrong: 18, cameraTurnOff: 19, cameraLowBattery: 20,
    antennaHaveImage: 21, antennaComing: 22, antennaPrompt: 23, antennaSent: 24,
    antennaWrong: 25, antennaWaitEarth: 26, antennaEdu: 27,
    shadowAhead: 28, shadowChargeNow: 29, shadowEnter: 30, shadowOnBattery: 31,
    shadowDraining: 32, shadowSaving: 33, shadowExit: 34,
    loopSunlight: 35, loopTarget: 36, loopGround: 37, loopShadow: 38,
    loopLowBattery: 39, freeThink: 40, freePraise: 41,
    thrusterTip: 42, thrusterOnlyWhenNeeded: 43, thrusterSpam: 44,
    thrusterGoodChoice: 45,
    recoverAlive: 46, recoverWrongTime: 47, recoverClose: 48, recoverGoodCatch: 49,
    // success 50..52 intentionally NOT voiced — the panel + jingle carry the
    // moment; the child reads the recap. (Clips stay bundled if ever wanted.)
    failureLine: 53, failureHint: 54,
  };
}
