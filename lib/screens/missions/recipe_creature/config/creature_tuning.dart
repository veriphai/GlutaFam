// Visual + motion tokens for the Prologue (PRD §9). Defined up front, reused
// module-wide. The hero is the creature — luminous on a calm dark base; chrome
// recedes. The one orchestrated splash is the rebuild; idle breathing is subtle;
// reduced-motion replaces the rebuild with a clean cut.

import 'package:flutter/widgets.dart';

class RC {
  RC._();

  // ── Colour (the Prologue accent = a warm "life" tone; 6 named hexes) ──────
  static const Color lifeGreen = Color(0xFF5FE39A); // primary life accent
  static const Color lifeAmber = Color(0xFFFFC15E); // warm secondary (CTAs, card)
  static const Color baseTop = Color(0xFF0A1020); // calm dark base (top)
  static const Color baseBottom = Color(0xFF060912); // calm dark base (bottom)
  static const Color inertGrey = Color(0xFF8B95AC); // wireframe / "dead" stroke
  static const Color photoTint = Color(0xFFC9C2B4); // desaturated frozen snapshot

  // ── Motion (seconds) ─────────────────────────────────────────────────────
  static const double extinctionSeconds = 1.05; // the creature dissolves away
  static const double rebuildSeconds = 1.35; // the one orchestrated splash
  static const double assembleSeconds = 0.55; // wireframe / photo entrance
  static const double traitFlashSeconds = 0.5; // pulse when a trait changes
  static const double breathHz = 0.22; // idle "breathing" frequency

  // ── Timing knobs handed to the bot engine (ms) ───────────────────────────
  static const int idleThresholdMs = 7000; // 0.1 idle nudge window
}
