// Tunable constants for Code the Satellite — palette (from the styleboard),
// Flame stage anchors (factors of the stage rect, eyeballed → expect a live
// on-device tuning pass), and animation beat timings.
//
// Keep ALL feel knobs here so a nudge is a one-number edit.

import 'package:flutter/material.dart';

/// Debug-only knobs. With [stepThrough] OFF (ship mode) the run advances
/// automatically once Orbit's narration for each step completes. Flip it back
/// ON to get the Replay / Next Step buttons for inspecting beats one at a time.
class CSDebug {
  CSDebug._();
  static const bool stepThrough = false;
}

/// Palette transcribed from `00_reference/styleboard_code_satellite.png`.
class CSColors {
  CSColors._();
  static const navy = Color(0xFF0B0D2A); // deep space navy
  static const cyan = Color(0xFF36C5F0); // electric cyan — active/interactive
  static const blue = Color(0xFF2D6FF7); // satellite blue
  static const teal = Color(0xFF00E0C6); // slow teal — correct/success
  static const orange = Color(0xFFFF8A3D); // warning orange
  static const yellow = Color(0xFFFFD23F); // energy yellow — CTA
  static const white = Color(0xFFEAF2FF); // soft white
  static const gray = Color(0xFFA6B0C3); // metallic gray

  static const green = Color(0xFF49E08B); // correct-state green
  static const red = Color(0xFFFF5A4D); // error red
}

/// Stage geometry — anchors are FACTORS of the full Flame stage rect (which is
/// the whole screen; the satellite/props live in the upper region, leaving the
/// lower region transparent for the Flutter timeline + tray overlay).
class CSStage {
  CSStage._();

  // satellite hovers in the upper-middle (full size, steps 1–2), then zooms out
  // and reframes to the top-left for the rest of the run.
  static const satelliteCenter = Offset(0.5, 0.30);
  static const satelliteCompactCenter = Offset(0.33, 0.15);
  static const satelliteWidth = 0.9; // fraction of stage width

  // props fade in around the satellite as their command runs.
  static const sunCenter = Offset(0.84, 0.13);
  static const sunWidth = 0.26;

  // Big Earth on the RIGHT — the right limb runs off-screen; only the cyclone
  // red-zone needs to stay visible.
  static const earthCenter = Offset(0.82, 0.46);
  static const earthWidth = 0.62;
  // Where the cyclone sits relative to the Earth centre (factor of earth size)
  // — the camera-scan reticle targets here.
  static const cycloneOffset = Offset(0.12, -0.05);
  // Where the satellite camera lens sits relative to the satellite centre
  // (points right, toward the Earth on the right).
  static const cameraOffset = Offset(0.16, 0.04);

  // Ground station planted ON the Earth's visible (left) surface, upper-left of
  // the globe — the satellite (upper-left) beams across to it.
  static const stationCenter = Offset(0.62, 0.40);
  static const stationWidth = 0.20;

  // Storage chip center-right — clear of the top-left satellite.
  static const chipCenter = Offset(0.62, 0.30);
  static const chipWidth = 0.16;

  // idle bob.
  static const idleBobAmplitude = 0.012; // of stage height
  static const idleBobPeriod = 3.0; // seconds
}

/// Animation beat timings (seconds).
class CSTiming {
  CSTiming._();
  static const commandBeat = 1.25; // how long each command's animation holds
  static const betweenSteps = 0.30; // PRD §9 inter-step pause
  static const failureBeat = 1.0;
  static const successBeat = 2.2;
  static const propFadeIn = 0.45;
}
