// Orbit's master script — the shared (non-mission-specific) dialogue sequences,
// with stable clip numbers in script order (mission-specific lines live in
// choose_satellite_missions.dart; clips 7–33). The full numbering:
//   1–4   intro · 5–6 instruction · 7–10 M1 · 11–15 M2 · 16–21 M3 ·
//   22–27 M4 · 28–33 M5 · 34–37 mission log.

import '../models/orbit_line.dart';

/// Scene 0 — Activity intro / Mission Control alert (clips 1–4).
const List<OrbitLine> kIntroLines = [
  OrbitLine('Whoa — Mission Control is lighting up! Earth is sending us emergency requests.', 1),
  OrbitLine("But here's the tricky part: we can't use the same satellite for every problem.", 2),
  OrbitLine('Some satellites help with location, some watch weather, some carry signals, and some take pictures of Earth.', 3),
  OrbitLine("I'll show you the problem. You help me dispatch the right satellite.", 4),
];

/// Scene 1 — Gameplay instruction (clips 5–6), prepended to Mission 1's lines.
const List<OrbitLine> kInstructionLines = [
  OrbitLine('Drag the satellite you think can solve this mission.', 5),
  OrbitLine('First look at what Earth needs, then choose the satellite with the right tool.', 6),
];

/// 3rd wrong attempt nudge (text-only; no VO clip in the script).
const OrbitLine kStrongNudge = OrbitLine('Try this one — it matches the mission.');

/// Scene 22 — Mission Log / final summary (clips 34–37).
const List<OrbitLine> kLogLines = [
  OrbitLine('That was awesome, Engineer. You matched every Earth problem with the right satellite.', 34),
  OrbitLine("Now you know the secret: don't choose a satellite by its look. Choose it by its job.", 35),
  OrbitLine('If Earth needs location, use navigation. If Earth needs storm tracking, use weather.', 36),
  OrbitLine('If Earth needs internet or TV, use communication. If Earth needs pictures of land, use Earth observation.', 37),
];

/// Bridge scene (currently disabled; text-only).
const OrbitLine kBridgeLine = OrbitLine(
    'Great choice. But now we must actually use the satellite. First problem — it needs power.');
