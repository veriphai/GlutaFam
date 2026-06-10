// The Leaky Bucket — every tunable number in one place (anchors as FACTORS of
// the stage rect so the layout is resolution-independent, plus the beat timings).
// A tight build-and-watch-it-leak DEMONSTRATION (no puzzle, no plugging): snap
// the machines in → Power It Up → heat leaks stage-by-stage → dim bulb → meaning
// lines → Card 04 → transmission hand-off.

class LBTune {
  LBTune._();

  // ── Vertical layout (factors of the stage height) ─────────────────────
  static const double inputY = 0.165; // the coal feed
  static const double chainTopY = 0.30; // first machine slot
  static const double chainBottomY = 0.66; // last machine slot
  static const double bulbY = 0.83; // the bulb
  static const double columnX = 0.5; // the chain runs down the centre

  // Sizes as factors of the SHORTER stage side.
  static const double inputRadiusF = 0.085;
  static const double bulbRadiusF = 0.13;
  static const double nodeRadiusF = 0.052;
  static const double streamMaxWidthF = 0.085;
  static const double leakMaxWidthF = 0.060;

  // ── Snap-build (Beat 1a) ──────────────────────────────────────────────
  static const int pieceSnapMs = 320; // a machine pops/settles into its slot
  static const double ghostPulseHz = 1.4; // the empty-slot target ring pulse

  // ── Turbine spin (auto, only when alive — no flick) ───────────────────
  static const double turbineMaxSpinAV = 7.0; // rad/s at full throughput
  static const double turbineSpinOutDiv = 60.0; // outValue → baseline fraction

  // ── Power-up sweep (Beat 1b) — the per-stage leak reveal ──────────────
  static const double powerSweepSpeed = 0.34; // progress / s (input→bulb ≈ 3s)

  // ── Beat timings (ms) ─────────────────────────────────────────────────
  static const int poweredToSurpriseMs = 700; // bulb lands dim → "So Much Fuel…"
  static const int surpriseToRealizeMs = 2800; // → "The 'Lost' Energy Became Heat"
  static const int realizeToBoundedMs = 3200; // → "Every Step Leaks Some…"
  static const int boundedToCardMs = 3000; // → Card 04 earn
}
