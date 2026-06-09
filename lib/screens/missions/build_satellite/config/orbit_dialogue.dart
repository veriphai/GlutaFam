// Single source of truth for every Orbit voice line in Build Your Satellite.
//
// Each [OrbitLine] is `(clip, text, mood)`. The clip number maps 1:1 to a wav
// file at `assets/sounds/build_satellite/orbit/orbit_NN.wav` (zero-padded).
//
// Controller fetches these in the order the gameplay calls for; the screen
// plays the matching wav. Generate audio in the exact order below — clip 1
// first, clip 73 last — so the numbering stays aligned.
//
// Total = 73. The two idle hints expand to 8 variants each because they
// embed the active part name ("Try dragging the **Solar Panel** to the
// glowing slot.") — one wav per part name to avoid a "{part name}" gap.

import '../state/build_satellite_state.dart';

class OrbitLine {
  final int clip;
  final String text;
  final MascotMood mood;
  const OrbitLine(this.clip, this.text, this.mood);
}

class Bs {
  Bs._();

  // ── 1 · Cover-art intro ─────────────────────────────────────────────────
  static const cover = OrbitLine(
      1, 'Ready to build your first satellite?', MascotMood.welcoming);

  // ── 2-4 · Activity opens (in-game) ──────────────────────────────────────
  static const open1 = OrbitLine(
      2,
      'Mission Control needs us. This satellite is just an empty space box right now.',
      MascotMood.welcoming);
  static const open2 = OrbitLine(
      3,
      'Let’s turn it into a working satellite — one system at a time.',
      MascotMood.guiding);
  static const open3 = OrbitLine(
      4,
      'Think of it like a tiny robot in space. It needs power, eyes, a brain, a voice, movement, and protection.',
      MascotMood.guiding);

  // ── 5-6 · Wrong-slot drop (two-line sequence) ───────────────────────────
  static const wrongA = OrbitLine(
      5, 'Oops, not there. That part needs a different slot.', MascotMood.concerned);
  static const wrongB = OrbitLine(
      6,
      'Look for the glowing outline — that’s where this part wants to go.',
      MascotMood.concerned);

  // ── 7-14 · Idle 1 @ 6s — "Try dragging the {part} to the glowing slot." ─
  static const idle1SolarPanel = OrbitLine(
      7,
      'Try dragging the Solar Panel to the glowing slot.',
      MascotMood.thinking);
  static const idle1AntennaBase = OrbitLine(
      8,
      'Try dragging the Antenna Base to the glowing slot.',
      MascotMood.thinking);
  static const idle1AntennaDish = OrbitLine(
      9,
      'Try dragging the Antenna Dish to the glowing slot.',
      MascotMood.thinking);
  static const idle1Camera = OrbitLine(
      10, 'Try dragging the Camera to the glowing slot.', MascotMood.thinking);
  static const idle1ComputerCore = OrbitLine(
      11,
      'Try dragging the Computer Core to the glowing slot.',
      MascotMood.thinking);
  static const idle1Battery = OrbitLine(
      12, 'Try dragging the Battery to the glowing slot.', MascotMood.thinking);
  static const idle1Thruster = OrbitLine(
      13, 'Try dragging the Thruster to the glowing slot.', MascotMood.thinking);
  static const idle1ThermalBlanket = OrbitLine(
      14,
      'Try dragging the Thermal Blanket to the glowing slot.',
      MascotMood.thinking);

  // ── 15-22 · Idle 2 @ 12s — "See the glowing area? Let's place the {part} there."
  static const idle2SolarPanel = OrbitLine(
      15,
      'See the glowing area? Let’s place the Solar Panel there.',
      MascotMood.thinking);
  static const idle2AntennaBase = OrbitLine(
      16,
      'See the glowing area? Let’s place the Antenna Base there.',
      MascotMood.thinking);
  static const idle2AntennaDish = OrbitLine(
      17,
      'See the glowing area? Let’s place the Antenna Dish there.',
      MascotMood.thinking);
  static const idle2Camera = OrbitLine(
      18,
      'See the glowing area? Let’s place the Camera there.',
      MascotMood.thinking);
  static const idle2ComputerCore = OrbitLine(
      19,
      'See the glowing area? Let’s place the Computer Core there.',
      MascotMood.thinking);
  static const idle2Battery = OrbitLine(
      20,
      'See the glowing area? Let’s place the Battery there.',
      MascotMood.thinking);
  static const idle2Thruster = OrbitLine(
      21,
      'See the glowing area? Let’s place the Thruster there.',
      MascotMood.thinking);
  static const idle2ThermalBlanket = OrbitLine(
      22,
      'See the glowing area? Let’s place the Thermal Blanket there.',
      MascotMood.thinking);

  /// Look up the idle-1 variant for the currently-highlighted part. The two
  /// solar panel ids share the same line.
  static OrbitLine idle1For(String partId) => switch (partId) {
        'left_solar_panel' || 'right_solar_panel' => idle1SolarPanel,
        'antenna_base' => idle1AntennaBase,
        'antenna_dish' => idle1AntennaDish,
        'camera_module' => idle1Camera,
        'computer_core_chip' => idle1ComputerCore,
        'battery_module' => idle1Battery,
        'thruster' => idle1Thruster,
        'thermal_blanket' => idle1ThermalBlanket,
        _ => idle1SolarPanel,
      };

  /// Look up the idle-2 variant.
  static OrbitLine idle2For(String partId) => switch (partId) {
        'left_solar_panel' || 'right_solar_panel' => idle2SolarPanel,
        'antenna_base' => idle2AntennaBase,
        'antenna_dish' => idle2AntennaDish,
        'camera_module' => idle2Camera,
        'computer_core_chip' => idle2ComputerCore,
        'battery_module' => idle2Battery,
        'thruster' => idle2Thruster,
        'thermal_blanket' => idle2ThermalBlanket,
        _ => idle2SolarPanel,
      };

  // ── 23 · Launch Preview tapped (immediate) ──────────────────────────────
  static const launchTap = OrbitLine(
      23, 'Okay, running our system check…', MascotMood.thinking);

  // ── Step 1 · Power (Solar Panels) — clips 24-30 ─────────────────────────
  static const s1Intro = OrbitLine(
      24,
      'First, our satellite needs power. See those solar panels? Let’s attach them on the sides.',
      MascotMood.guiding);
  static const s1P1Pickup = OrbitLine(
      25,
      'Nice, you picked up a solar panel. Let’s line it up with the side slot.',
      MascotMood.guiding);
  static const s1P1NearSlot = OrbitLine(
      26, 'Yes, that’s the spot. Drop it there.', MascotMood.happy);
  static const s1P1Placed = OrbitLine(
      27,
      'Good! This panel can catch sunlight and turn it into electricity.',
      MascotMood.happy);
  static const s1P1Followup = OrbitLine(
      28,
      'Without power, our satellite can’t run its camera, antenna, or computer.',
      MascotMood.happy);
  static const s1P2Intro = OrbitLine(
      29,
      'One panel is good, but two panels give our satellite more power. Let’s add the other one.',
      MascotMood.guiding);
  static const s1Complete = OrbitLine(
      30,
      'Power system online! Now our satellite can start waking up.',
      MascotMood.celebrating);

  // ── Step 2 · Antenna — clips 31-36 ──────────────────────────────────────
  static const s2Intro = OrbitLine(
      31,
      'Now our satellite needs a voice. Let’s add the antenna so it can talk to Earth.',
      MascotMood.guiding);
  static const s2P1Pickup = OrbitLine(
      32, 'That’s the antenna base. Let’s lock it on top first.', MascotMood.guiding);
  static const s2P1Placed = OrbitLine(
      33,
      'Great. The base will keep the antenna steady while the satellite moves in space.',
      MascotMood.happy);
  static const s2P2Intro = OrbitLine(
      34,
      'Now add the dish. That’s the part that sends and receives signals.',
      MascotMood.guiding);
  static const s2Complete = OrbitLine(
      35,
      'Signal system online! Now our satellite can send data to Earth and receive commands from Mission Control.',
      MascotMood.celebrating);
  static const s2More = OrbitLine(
      36,
      'Like when a weather satellite sends storm pictures back to people on Earth.',
      MascotMood.happy);

  // ── Step 3 · Camera — clips 37-42 ───────────────────────────────────────
  static const s3Intro = OrbitLine(
      37,
      'Time to give our satellite eyes. See that hollow front bay? The camera goes there.',
      MascotMood.guiding);
  static const s3Pickup = OrbitLine(
      38,
      'You’ve got the camera. Let’s place it into the empty front socket.',
      MascotMood.guiding);
  static const s3NearSlot = OrbitLine(
      39, 'Yes, right there — into the hollow camera bay.', MascotMood.happy);
  static const s3Complete = OrbitLine(
      40,
      'Vision system online! Now our satellite can see Earth from space.',
      MascotMood.celebrating);
  static const s3Followup = OrbitLine(
      41,
      'It can look for clouds, storms, forests, oceans, cities, and changes on the ground.',
      MascotMood.happy);
  static const s3More = OrbitLine(
      42,
      'See Earth below us? With this camera, our satellite can spot things happening far away.',
      MascotMood.happy);

  // ── Step 4 · Computer Core — clips 43-47 ────────────────────────────────
  static const s4Intro = OrbitLine(
      43,
      'Now we need the brain. A satellite can’t just float around cluelessly.',
      MascotMood.guiding);
  static const s4Pickup = OrbitLine(
      44,
      'That chip is the computer core. Let’s put the brain inside.',
      MascotMood.guiding);
  static const s4Complete = OrbitLine(
      45,
      'Brain system online! Now our satellite can follow instructions.',
      MascotMood.celebrating);
  static const s4Followup = OrbitLine(
      46,
      'It can check sensors, store data, and tell each part what to do next.',
      MascotMood.happy);
  static const s4More = OrbitLine(
      47,
      'Now it knows when to take pictures, when to send data, and when to save power.',
      MascotMood.happy);

  // ── Step 5 · Battery — clips 48-52 ──────────────────────────────────────
  static const s5Intro = OrbitLine(
      48,
      'Our satellite has power now, but it also needs backup power. Let’s add the battery.',
      MascotMood.guiding);
  static const s5Pickup = OrbitLine(
      49,
      'That battery is like a power lunchbox. It stores energy for later.',
      MascotMood.guiding);
  static const s5Complete = OrbitLine(
      50,
      'Battery online! Now our satellite can keep working even when sunlight disappears.',
      MascotMood.celebrating);
  static const s5Followup = OrbitLine(
      51,
      'When our satellite moves into Earth’s shadow, the solar panels stop charging. The battery keeps it alive.',
      MascotMood.happy);
  static const s5More = OrbitLine(
      52,
      'See Earth below? Sometimes Earth blocks sunlight. That’s when the battery saves the mission.',
      MascotMood.happy);

  // ── Step 6 · Thruster — clips 53-57 ─────────────────────────────────────
  static const s6Intro = OrbitLine(
      53,
      'Now let’s add the thruster. Not for flying around wildly — just tiny careful pushes.',
      MascotMood.guiding);
  static const s6Pickup = OrbitLine(
      54, 'That’s the thruster. Let’s attach it underneath.', MascotMood.guiding);
  static const s6Complete = OrbitLine(
      55,
      'Movement system online! Now our satellite can make small position corrections.',
      MascotMood.celebrating);
  static const s6Followup = OrbitLine(
      56,
      'A satellite doesn’t burn fuel all the time. It mostly keeps falling around Earth — thrusters only help adjust it.',
      MascotMood.happy);
  static const s6More = OrbitLine(
      57,
      'Think of it like a tiny space nudge, not a rocket race.',
      MascotMood.happy);

  // ── Step 7 · Thermal Blanket — clips 58-63 ──────────────────────────────
  static const s7Intro = OrbitLine(
      58,
      'One last thing. Space is rough, so our satellite needs protection.',
      MascotMood.guiding);
  static const s7Pickup = OrbitLine(
      59,
      'That golden blanket is not for sleeping. It protects the satellite.',
      MascotMood.guiding);
  static const s7Placed = OrbitLine(
      60,
      'Protection system online! Space can be super hot in sunlight and freezing cold in shadow.',
      MascotMood.celebrating);
  static const s7Followup = OrbitLine(
      61,
      'This blanket helps keep the satellite’s instruments safe.',
      MascotMood.happy);
  static const s7FinalComplete = OrbitLine(
      62, 'You did it! Our satellite is fully assembled.', MascotMood.celebrating);
  static const s7Summary = OrbitLine(
      63,
      'Power, eyes, brain, voice, movement, and protection — all systems are online.',
      MascotMood.celebrating);

  // ── Launch Preview sequence — clips 64-71 ───────────────────────────────
  // The visual subsystem reveal fires WHEN the matching spoken line starts.
  static const launchOpen = OrbitLine(
      64, 'Let’s check everything before launch preview.', MascotMood.thinking);
  static const checkPower = OrbitLine(
      65, 'Power check… solar panels are working.', MascotMood.happy);
  static const checkSignal = OrbitLine(
      66, 'Signal check… antenna is ready.', MascotMood.happy);
  static const checkVision = OrbitLine(
      67, 'Vision check… camera is online.', MascotMood.happy);
  static const checkBrain = OrbitLine(
      68, 'Brain check… computer core is awake.', MascotMood.happy);
  static const checkBattery = OrbitLine(
      69, 'Backup power check… battery is charged.', MascotMood.happy);
  static const checkMovement = OrbitLine(
      70,
      'Movement check… thruster is ready for tiny corrections.',
      MascotMood.happy);
  static const checkProtection = OrbitLine(
      71, 'Protection check… thermal blanket is secure.', MascotMood.happy);

  // ── Reward — clips 72-73 ────────────────────────────────────────────────
  static const rewardMain = OrbitLine(
      72, 'Mission complete! You built a working satellite.', MascotMood.celebrating);
  static const rewardSkill = OrbitLine(
      73,
      'Satellite Engineer skill unlocked: Satellite Systems.',
      MascotMood.celebrating);
}
