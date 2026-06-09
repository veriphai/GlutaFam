// All non-level Flutter text for the activity (PRD §17). Centralised so copy
// edits never touch widget code. Level mission lines live in height_levels.dart.

class SceneCopy {
  SceneCopy._();

  static const missionTag = 'MISSION 2';
  static const activityTitle = 'How Much Can You See?';

  // Scene 0 — Story intro (title card)
  static const titleTop = 'HOW MUCH';
  static const titleBottom = 'CAN YOU SEE?';
  static const introTagline =
      'We’re testing how much of Earth we can see from different heights. Let’s find out!';
  static const introTaglineAccent = 'different heights';
  static const kidQuestion = 'Why don’t we just build a giant tower?';
  static const introMissionControl =
      'Great question. Let’s test how much each camera can actually see.';
  static const startViewTest = 'START VIEW TEST';

  // Scene 1 — Mission Control test intro
  static const testMissionControl =
      'Okay, junior engineer — each of these can carry a camera. Let’s see which one can actually watch enough of Earth.';
  static const robotLetsFindOut = 'Let’s find out.';
  static const begin = 'BEGIN';

  // Scene 2 — Height exploration
  static const dragHint = 'Drag the camera upward to see more.';
  static const takeChallenge = 'TAKE CHALLENGE';

  // Scene 8 — Cyclone challenge
  static const challengeTitle = 'CHALLENGE';
  static const challengeQuestion =
      'A cyclone is forming over the ocean.\nWhere should we place our camera to watch it?';
  static const challengeHelper =
      'Mission alert! A cyclone is forming over the ocean. Which camera spot should we choose to watch the biggest area for the longest time?';
  static const hint2Wrong = 'Tiny hint from Orbit: highest view, biggest view!';

  // Scene 9 — Correct answer success
  static const perfect = 'PERFECT!';
  static const successMissionControl =
      'Yes! Satellite is the one. From way above Earth, it can watch huge ocean storms as they form.';
  static const earthViewMastered = 'EARTH VIEW MASTERED!';
  static const cont = 'CONTINUE';

  // Scene 10 — Success story beat
  static const bridgeLine = 'Perfect. A satellite can see a huge part of Earth.';
  static const bridgeProblem = 'But there’s a problem...';

  // Scene 11 — Next mission teaser
  static const teaserQuestion = 'If we put it in space...\nwhy doesn’t it just fall back down?';
  static const nextMissionUnlocked = 'NEXT MISSION UNLOCKED';
  static const nextMissionTitle = 'How Does a Satellite Stay Up?';
  static const next = 'NEXT';
}
