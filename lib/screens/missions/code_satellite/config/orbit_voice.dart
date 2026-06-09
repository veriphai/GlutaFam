// Orbit's 60-clip voice-over track for Code the Satellite.
//
// Files live at assets/sounds/code_satellite/orbit/orbit_NN.wav (scene-N from
// the recording session → orbit_NN at copy time; mapping verified by duration:
// the short "Running: …" status clips are the shortest files, the Mission
// Success line the longest).
//
// ⚠️ keep paths in the 'sounds/code_satellite/orbit/…' form (NOT
// 'assets/sounds/…') — audioSource (s3_audio.dart) keys its cache and S3 URL
// rewrite off that prefix; a wrong prefix 404s silently and onPlayerComplete
// never fires.
//
// Clip scheme:
//   1          kid's intro question
//   2–6        Orbit intro thread
//   7–10       mission-brief thread
//   11–19      coach lines (step 1..9)         = kClipCoachBase + i
//   20         all-nine-placed line
//   21–29      wrong-tap lines (expected 1..9) = kClipWrongBase + i
//   30, 31     run start ("uploading…", "watch closely…")
//   32+2i      "Running: <command>" status     (i = step index)
//   33+2i      execution beat after step i
//   50, 55, 56 failure: oops / engineers-debug / after-reorder
//   51–54      specific failure reasons (unreachable in guided mode)
//   57–60      success thread (57, 58, card 59, final beat 60)

import 'package:audioplayers/audioplayers.dart';

import '../../../../utils/s3_audio.dart';

import '../models/satellite_command.dart';

// ── controller-driven message constants (must match state.message EXACTLY) ──
const kMsgAllPlaced =
    "Perfect — our whole command plan is ready! Press Run Mission and let's watch the satellite follow it.";
const kMsgUpload = "Now I'm uploading our whole command plan to the satellite.";
const kMsgWatchClosely =
    'Watch closely — it will follow our commands in the exact order we placed them.';
const kMsgOops =
    'Oops, the mission paused. The satellite tried to do something before it was ready.';
const kMsgReorder = "Let's fix the command order and run it again. I know you can do it.";

// ── clip scheme ──────────────────────────────────────────────────────────────
const kClipCoachBase = 11; // + step index
const kClipWrongBase = 21; // + step index of the EXPECTED command
const kClipRunningBase = 32; // + 2 * step index
const kClipBeatBase = 33; // + 2 * step index

// kid question + 3 Orbit lines (clips 2 "I'm Orbit!" and 5 "See these command
// blocks?" intentionally skipped — not required on the intro).
const kClipsIntro = [1, 3, 4, 6];
// (clip 10 — "send a photo before taking one…" — intentionally skipped.)
const kClipsBrief = [7, 8, 9];
// bubble, bubble, final beat (clip 59 — the Mission Success card narration —
// intentionally skipped; the card is read, not spoken).
const kClipsSuccess = [57, 58, 60];

/// Measured clip lengths (seconds, via afinfo at copy time) — used for muted
/// reading-time fallbacks and voice-gate safety margins.
const Map<int, double> kOrbitClipSecs = {
  1: 4.84, 2: 3.64, 3: 6.32, 4: 7.68, 5: 9.68, 6: 3.52, 7: 5.60, 8: 6.16,
  9: 7.60, 10: 9.16, 11: 8.16, 12: 6.52, 13: 7.40, 14: 7.80, 15: 5.92,
  16: 5.92, 17: 5.64, 18: 6.44, 19: 7.08, 20: 8.40, 21: 10.80, 22: 7.96,
  23: 8.64, 24: 9.36, 25: 7.76, 26: 7.52, 27: 7.20, 28: 7.64, 29: 5.92,
  30: 4.36, 31: 6.24, 32: 2.84, 33: 4.44, 34: 2.76, 35: 4.60, 36: 3.92,
  37: 5.56, 38: 3.44, 39: 5.16, 40: 2.64, 41: 3.72, 42: 2.80, 43: 4.00,
  44: 4.08, 45: 3.60, 46: 2.64, 47: 4.96, 48: 3.12, 49: 5.76, 50: 6.56,
  51: 7.16, 52: 7.24, 53: 7.52, 54: 8.32, 55: 8.60, 56: 5.24, 57: 3.92,
  58: 6.88, 59: 11.32, 60: 9.80,
};

/// Playback source for clip [n] (1-based) — cached S3 file via audioSource.
Source orbitClipSource(int n) =>
    audioSource('sounds/code_satellite/orbit/orbit_${n.toString().padLeft(2, '0')}.wav');

/// The voice choke-point map: state.message text → clip number, for every line
/// that flows through the controller (arranging/running/failed). Intro, brief
/// and success threads are scene-owned and NOT in this map (their scenes play
/// them, so the shell player never double-fires).
final Map<String, int> kOrbitClipForMessage = _build();

Map<String, int> _build() {
  final m = <String, int>{
    kMsgAllPlaced: 20,
    kMsgUpload: 30,
    kMsgWatchClosely: 31,
    kMsgOops: 50,
    kMsgReorder: 56,
  };
  for (var i = 0; i < kCorrectOrder.length; i++) {
    final c = kCorrectOrder[i];
    m[c.coach] = kClipCoachBase + i;
    m[c.wrong] = kClipWrongBase + i;
    m['Running: ${c.label}'] = kClipRunningBase + 2 * i;
    m[c.explanation] = kClipBeatBase + 2 * i; // == validation's _ok beat text
  }
  return m;
}
