// The Evidence Board model — the reusable "make your case" (CER) synthesis layer
// (PRD §1). During an episode the kid's felt discoveries are AUTO-CAPTURED as
// small replayable VISUAL moment-tiles and pinned under a guiding question; at the
// episode's end they pick the clues that answer it, build a claim, and watch their
// reasoning play back. This file declares the per-episode guiding question and the
// evidence set (felt moments, never text bullets — §5.1).
//
// Episode 1's set (PRD §2.3): 5 real tiles + EXACTLY 2 true-but-irrelevant
// distractors (§5.5). Real = the convergence ("same magnet" → we CAN use many) +
// the four DISTINCT catches (dirty / expensive / unreliable-wind / nightly-solar →
// we MUST use many). Distractors answer "HOW it's made", not "WHY so many".
//
// Tiles carry a [motif] (a small CustomPainter, not a screenshot — the felt moment
// re-drawn) and a ≤3-word [label] (§6). Nothing here re-narrates the lesson as a
// sentence; the image carries it.

import 'package:flutter/material.dart';

/// Which replayable moment a tile re-draws (its own painter — see
/// evidence_tile_painters.dart). One per felt moment in the episode.
enum EvidenceMotif {
  sameMagnet, // Act 2 — every source spins the SAME magnet (the convergence)
  stillMagnet, // Act 2 — a still magnet does nothing (distractor: how it's made)
  turbineSpin, // Act 2 — a turbine spins the magnet (distractor: how it's made)
  coalHaze, // Act 3 — the skyline chokes in haze (catch: dirty)
  nuclearCost, // Act 3 — the cost soars (catch: expensive)
  windDrop, // Act 3 — the town goes dark when the wind drops (catch: unreliable)
  solarNight, // Act 3 — the town goes dark every night (catch: nightly)
}

/// One captured felt-moment tile. [relevant] marks whether it bears on the
/// episode's guiding question — used ONLY to let the closing playback feel
/// complete/incomplete (§4.3), NEVER to score or mark a selection right/wrong
/// (§5.4). The distractors are [relevant] == false: TRUE things the kid really
/// witnessed, but answering a DIFFERENT question (§5.5).
@immutable
class EvidenceTile {
  const EvidenceTile({
    required this.id,
    required this.label,
    required this.motif,
    required this.accent,
    required this.relevant,
    required this.sourceLabel,
    required this.caption,
    required this.cropFactor,
  });

  final String id; // stable key (persisted) + the capture-hook id
  final String label; // short, readable name (the chip under the tile, §6)
  final String caption; // one-line "what this moment shows" — in the tap-to-open preview
  final EvidenceMotif motif;
  final Color accent; // the tile's colour identity (frame + glow)
  final bool relevant; // bears on the guiding question? (distractors → false)
  final String sourceLabel; // tiny provenance chip (e.g. "ACT 2")

  /// The normalized sub-rect (LTRB, each 0..1 of the activity's scene
  /// RepaintBoundary) to crop the captured frame to — so the thumbnail FRAMES THE
  /// MOMENT (the coil+magnet, the hazy skyline, the soaring cost meter) instead of
  /// whatever happens to sit mid-frame. Tuned against each scene's layout factors.
  final Rect cropFactor;
}

// ── Episode 1 — "Where Power Is Born" ────────────────────────────────────────
/// The episode the board is scoped to (the persistence key + the closing flow's
/// catalog). Future episodes add their own id + catalog + question.
const String kEpisode1Id = 'episode1_electricity';

/// The guiding question — posed early, pinned at the top of the board throughout,
/// answered at the end (PRD §2.1, locked).
const String kEpisode1Question =
    'Why do we make electricity from so many different sources?';

// Tile accents (read from the deck's section palette so the board feels part of
// the same world — amber generation / electric blue / etc.).
const Color _amber = Color(0xFFFF9B42);
const Color _blue = Color(0xFF3FB9F5);
const Color _haze = Color(0xFF9AA0A6);
const Color _violet = Color(0xFFB08CF7);
const Color _wind = Color(0xFF6FE0C8);
const Color _moon = Color(0xFF8FA6FF);

/// The full Episode 1 evidence set — 5 real + 2 distractors = 7 tiles (§2.3).
/// Capture hooks in Act 2 (trace_it_back) and Act 3 (source_personalities) fire
/// these by [id]; the closing flow reads them back from the store.
const List<EvidenceTile> kEpisode1Evidence = [
  // — Real: the convergence (we CAN use many — same trick, interchangeable) —
  // Trace chain is vertical at x=0.5: coil+magnet at y≈0.44 → frame around it.
  EvidenceTile(
    id: 'same_magnet',
    label: 'Same Magnet Trick',
    caption: 'Coal, nuclear, wind, water — every source just spins the same magnet.',
    motif: EvidenceMotif.sameMagnet,
    accent: _amber,
    relevant: true,
    sourceLabel: 'ACT 2',
    cropFactor: Rect.fromLTRB(0.14, 0.31, 0.86, 0.57),
  ),
  // — Real: the four DISTINCT catches (we MUST use many) —
  // Town: haze band y≈0.30–0.46, rooftops 0.46–0.72, dock/meters below 0.76.
  EvidenceTile(
    id: 'coal_haze',
    label: "Coal's Dirty Air",
    caption: 'Run the whole town on coal and the sky chokes with smog.',
    motif: EvidenceMotif.coalHaze,
    accent: _haze,
    relevant: true,
    sourceLabel: 'ACT 3',
    cropFactor: Rect.fromLTRB(0.0, 0.31, 1.0, 0.74),
  ),
  EvidenceTile(
    id: 'nuclear_cost',
    label: "Nuclear's Big Cost",
    caption: 'Nuclear stays clean, but the cost climbs sky-high.',
    motif: EvidenceMotif.nuclearCost,
    accent: _violet,
    relevant: true,
    sourceLabel: 'ACT 3',
    cropFactor: Rect.fromLTRB(0.40, 0.77, 1.0, 0.88), // the soaring cost meter
  ),
  EvidenceTile(
    id: 'wind_drop',
    label: 'Wind Can Stop',
    caption: 'When the wind drops, the town suddenly goes dark.',
    motif: EvidenceMotif.windDrop,
    accent: _wind,
    relevant: true,
    sourceLabel: 'ACT 3',
    cropFactor: Rect.fromLTRB(0.0, 0.40, 1.0, 0.74),
  ),
  EvidenceTile(
    id: 'solar_night',
    label: 'Dark Every Night',
    caption: 'Every night the sun sets and solar power goes dark.',
    motif: EvidenceMotif.solarNight,
    accent: _moon,
    relevant: true,
    sourceLabel: 'ACT 3',
    cropFactor: Rect.fromLTRB(0.0, 0.40, 1.0, 0.74),
  ),
  // — Distractors (exactly 2): TRUE-but-irrelevant — they answer HOW, not WHY —
  EvidenceTile(
    id: 'still_magnet',
    label: 'Must Keep Moving',
    caption: 'A still magnet makes nothing — it only works while it moves.',
    motif: EvidenceMotif.stillMagnet,
    accent: _blue,
    relevant: false,
    sourceLabel: 'ACT 2',
    cropFactor: Rect.fromLTRB(0.14, 0.20, 0.86, 0.52), // dark bulb + still coil/magnet
  ),
  EvidenceTile(
    id: 'turbine_spin',
    label: 'Turbine Spins It',
    caption: 'A spinning turbine is what turns the magnet for you.',
    motif: EvidenceMotif.turbineSpin,
    accent: _blue,
    relevant: false,
    sourceLabel: 'ACT 2',
    cropFactor: Rect.fromLTRB(0.14, 0.47, 0.86, 0.74), // shaft + turbine
  ),
];

/// Lookup by id (capture hooks pass an id; the store persists ids).
EvidenceTile? evidenceById(String id) {
  for (final t in kEpisode1Evidence) {
    if (t.id == id) return t;
  }
  return null;
}

/// The two distractor ids — handy for the closing flow's staging/grouping.
const List<String> kEpisode1DistractorIds = ['still_magnet', 'turbine_spin'];
