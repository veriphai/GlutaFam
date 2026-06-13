// The Evidence Board model — the reusable "make your case" (CER) synthesis layer
// (PRD §1). During an episode the kid's felt discoveries are AUTO-CAPTURED as
// small replayable VISUAL moment-tiles and pinned under a guiding question; at the
// episode's end they pick the clues that answer it, build a claim, and watch their
// reasoning play back. This file declares the per-episode guiding question and the
// evidence set (felt moments, never text bullets — §5.1).
//
// Episode 1's set (PRD §2.3): 6 real tiles + EXACTLY 2 true-but-irrelevant
// distractors (§5.5). Real = the convergence ("same magnet" → we CAN use many) +
// the five DISTINCT catches (dirty-fossil / expensive-nuclear / unreliable-wind /
// nightly-solar / river-bound-hydro → we MUST use many). Distractors answer
// "HOW it's made", not "WHY so many".
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
  fossilHaze, // Act 3 — the skyline chokes in haze (catch: dirty — coal + gas clubbed)
  nuclearCost, // Act 3 — the cost soars (catch: expensive)
  windDrop, // Act 3 — the town goes dark when the wind drops (catch: unreliable)
  solarNight, // Act 3 — the town goes dark every night (catch: nightly)
  hydroRiver, // Act 3 — clean + steady, but only where a dammed river runs (catch: location-bound)

  // ── Episode 2 — "The Long Way Home" (transmission) ─────────────────────────
  ep2PushFlow, // 2.1 distractor — voltage is the push, current the flow (defines the quantities)
  ep2FatWire, // 2.2 distractor — thin wire chokes, fat low-resistance wire runs (a different lever)
  ep2HeatLeavesWire, // 2.3 — the wire glows, heat streams off en route to the lamp
  ep2RubbedWarm, // 2.3 distractor — a finger-rub warms the wire (friction, not distance)
  ep2HeatQuadruples, // 2.4 — double the current, four times the heat (two glow columns)
  ep2CurrentDrops, // 2.5 — the pinned-power rectangle: taller, narrower (current falls by itself)
  ep2TurnsStepUp, // 2.6 — more secondary turns lift the sending voltage; the far pylon lights
  ep2AcAlive, // 2.7 — a reversing current keeps the field changing; the bulb springs to full
  ep2AcSailsAcross, // 2.8 — a cool trickle of current crosses to a fully lit far city
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
    required this.hint,
    required this.cropFactor,
  });

  final String id; // stable key (persisted) + the capture-hook id
  final String label; // short, readable name (the chip under the tile, §6)
  final String caption; // one-line "what this moment shows" — in the tap-to-open preview

  /// The CER closing-flow hint for THIS tile, written for its role: a relevant
  /// tile's hint is a "look for the clue where…" recall nudge (shown when it's
  /// still missing); a distractor's hint explains why it answers a DIFFERENT
  /// question (shown when it's been kept, so the kid sets it aside). The bulb
  /// composes these — see CerController.hintText.
  final String hint;
  final EvidenceMotif motif;
  final Color accent; // the tile's colour identity (frame + glow)
  final bool relevant; // bears on the guiding question? (distractors → false)
  final String sourceLabel; // tiny provenance chip (e.g. "ACT 2")

  /// The normalized sub-rect (LTRB, each 0..1 of the activity's scene
  /// RepaintBoundary) to crop the captured frame to — so the thumbnail FRAMES THE
  /// MOMENT (the coil+magnet, the hazy skyline, the soaring cost meter) instead of
  /// whatever happens to sit mid-frame. Tuned against each scene's layout factors.
  final Rect cropFactor;

  /// The pre-kept "perfect" frame for this moment, bundled under
  /// `assets/images/episode_board/evidence/<id>.png`. PRIMARY source for the photo
  /// card (reliable, perfectly framed); the drawn motif is the fallback if absent.
  String get assetPath => 'assets/images/episode_board/evidence/$id.png';
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
const Color _hydro = Color(0xFF49B6E0); // river blue — hydro's clean, steady water

/// The full Episode 1 evidence set — 6 real + 2 distractors = 8 tiles (§2.3).
/// Capture hooks in Act 2 (trace_it_back) and Act 3 (source_personalities) fire
/// these by [id]; the closing flow reads them back from the store.
const List<EvidenceTile> kEpisode1Evidence = [
  // — Real: the convergence (we CAN use many — same trick, interchangeable) —
  // Trace chain is vertical at x=0.5: coil+magnet at y≈0.44 → frame around it.
  EvidenceTile(
    id: 'same_magnet',
    label: 'Same Magnet Trick',
    caption: 'Coal, nuclear, wind, water — every source just spins the same magnet.',
    hint: 'Look for the clue where coal, nuclear, wind and water all spun the very same magnet.',
    motif: EvidenceMotif.sameMagnet,
    accent: _amber,
    relevant: true,
    sourceLabel: 'ACT 2',
    cropFactor: Rect.fromLTRB(0.14, 0.31, 0.86, 0.57),
  ),
  // — Real: the four DISTINCT catches (we MUST use many) —
  // Town: haze band y≈0.30–0.46, rooftops 0.46–0.72, dock/meters below 0.76.
  EvidenceTile(
    id: 'fossil_haze',
    label: 'Dirty Air',
    caption: 'Burn fuel — coal or gas — to power the whole town and the sky chokes with smog.',
    hint: 'Look for the clue where running the whole town on burning fuel choked the sky with smog.',
    motif: EvidenceMotif.fossilHaze,
    accent: _haze,
    relevant: true,
    sourceLabel: 'ACT 3',
    cropFactor: Rect.fromLTRB(0.0, 0.31, 1.0, 0.74),
  ),
  EvidenceTile(
    id: 'nuclear_cost',
    label: "Nuclear's Big Cost",
    caption: 'Nuclear stays clean, but the cost climbs sky-high.',
    hint: 'Look for the clue where the power stayed clean but the cost meter climbed sky-high.',
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
    hint: 'Look for the clue where the wind dropped and the town suddenly went dark.',
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
    hint: 'Look for the clue where night fell and the solar town went dark.',
    motif: EvidenceMotif.solarNight,
    accent: _moon,
    relevant: true,
    sourceLabel: 'ACT 3',
    cropFactor: Rect.fromLTRB(0.0, 0.40, 1.0, 0.74),
  ),
  EvidenceTile(
    id: 'hydro_river',
    label: 'Needs a River',
    caption: 'Hydro is clean and steady — but only runs where a dammed river does.',
    hint: 'Look for the clue where hydro ran clean and steady — but only where a river was dammed.',
    motif: EvidenceMotif.hydroRiver,
    accent: _hydro,
    relevant: true,
    sourceLabel: 'ACT 3',
    cropFactor: Rect.fromLTRB(0.0, 0.34, 1.0, 0.78),
  ),
  // — Distractors (exactly 2): TRUE-but-irrelevant — they answer HOW, not WHY —
  EvidenceTile(
    id: 'still_magnet',
    label: 'Must Keep Moving',
    caption: 'A still magnet makes nothing — it only works while it moves.',
    hint: '"Must Keep Moving" shows HOW electricity is made — not WHY we use so many sources. Leave it out.',
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
    hint: '"Turbine Spins It" shows HOW electricity is made — not WHY we use so many sources. Leave it out.',
    motif: EvidenceMotif.turbineSpin,
    accent: _blue,
    relevant: false,
    sourceLabel: 'ACT 2',
    cropFactor: Rect.fromLTRB(0.14, 0.47, 0.86, 0.74), // shaft + turbine
  ),
];

// ── Episode 2 — "The Long Way Home" (transmission) ───────────────────────────
/// The episode the EP2 board is scoped to (persistence key + closing-flow catalog).
const String kEpisode2Id = 'episode2_electricity';

/// The EP2 guiding question — posed from beat 2.1, pinned on every EP2 activity's
/// board strip throughout, answered by the EP2 CER (prd_make_your_case_ep2 §2).
const String kEpisode2Question =
    'How does power cross such a long distance without being lost?';

// EP2 tile accents — the transmission accent family (electric blue #3FB9F5 and
// warm/heat tints), per the CER PRD §6 table.
const Color _ep2PushViolet = Color(0xFF8E7BF2); // 2.1 the voltage "push" (pressure violet, distractor)
const Color _ep2WireCopper = Color(0xFFCF9B6B); // 2.2 the wire / resistance specimen (copper, distractor)
const Color _ep2Heat = Color(0xFFFF7A2E); // heat leaving the wire
const Color _ep2RubWarm = Color(0xFFFF9457); // friction warmth (distractor)
const Color _ep2HeatFierce = Color(0xFFFF5A24); // the fourfold leap
const Color _ep2Gold = Color(0xFFF5C451); // the pinned-power rectangle (gold CTA family)
const Color _ep2TurnsGold = Color(0xFFFFD27A); // warm energy — the stepped-up line
const Color _ep2AcBlue = Color(0xFF3FB9F5); // transmission electric blue — AC alive
const Color _ep2CityWarm = Color(0xFFFFE9B8); // the far city's warm bloom

/// The full Episode 2 evidence set — 6 real + 3 distractors = 9 tiles. One real
/// tile per beat 2.3→2.8 (the claim's causal chain) + three true-but-different
/// distractors: 2.1's push/flow definitions, 2.2's fat-wire/resistance (a DIFFERENT
/// lever than high voltage), and 2.3's friction warmth. The 2.6 inside-the-device
/// field tile (`changing_field`) was dropped; the dropped beat proposals
/// (square_curve, cold_wire_full_town, dc_dead_transformer, dc_line_cooks) are NOT
/// in this catalog either — their capture hooks are removed at build time.
const List<EvidenceTile> kEpisode2Evidence = [
  // — Distractor (2.1): voltage is the push, current the flow — defines the
  //   quantities the argument uses, but answers "what are they", not "how it crosses" —
  EvidenceTile(
    id: 'push_flow',
    label: 'Push and Flow',
    caption: 'Voltage is the push, current is the flow — turn one up and the other follows.',
    hint: '"Push and Flow" only names what voltage and current are — not how the power survives the trip. Leave it out.',
    motif: EvidenceMotif.ep2PushFlow,
    accent: _ep2PushViolet,
    relevant: false,
    sourceLabel: 'ACT 2.1',
    cropFactor: Rect.fromLTRB(0.08, 0.06, 0.92, 0.74),
  ),
  // — Distractor (2.2): a fat, low-resistance wire runs — a DIFFERENT loss lever
  //   (change the wire) than the episode's answer (change the voltage) —
  EvidenceTile(
    id: 'fat_wire',
    label: 'Fat Wire Runs',
    caption: 'A thin wire chokes the current; a fat, low-resistance wire lets it run.',
    hint: '"Fat Wire Runs" is about thickening the wire — a different fix from the high-voltage trick this case is built on. Leave it out.',
    motif: EvidenceMotif.ep2FatWire,
    accent: _ep2WireCopper,
    relevant: false,
    sourceLabel: 'ACT 2.2',
    cropFactor: Rect.fromLTRB(0.06, 0.10, 0.94, 0.72),
  ),
  // — Real (2.3): heat leaves the wire — the problem (loss IS heat) —
  EvidenceTile(
    id: 'heat_leaves_wire',
    label: 'Heat Leaves',
    caption: 'Energy escaped the wire as heat before it could reach the lamp.',
    hint: 'Look for the clue where heat streamed off the wire before the power reached the lamp — that loss is the whole problem.',
    motif: EvidenceMotif.ep2HeatLeavesWire,
    accent: _ep2Heat,
    relevant: true,
    sourceLabel: 'ACT 2.3',
    cropFactor: Rect.fromLTRB(0.04, 0.16, 0.96, 0.62),
  ),
  // — Distractor (2.3): rubbing warms the wire — friction, not distance —
  EvidenceTile(
    id: 'rubbed_warm',
    label: 'Rubbing Warms',
    caption: 'Rubbing the wire by hand made the same heat — friction.',
    hint: '"Rubbing Warms" is heat from friction by hand — not the heat lost over distance. Leave it out.',
    motif: EvidenceMotif.ep2RubbedWarm,
    accent: _ep2RubWarm,
    relevant: false,
    sourceLabel: 'ACT 2.3',
    cropFactor: Rect.fromLTRB(0.15, 0.20, 0.85, 0.60),
  ),
  // — Real (2.4): double the current, four times the heat — the punishment —
  EvidenceTile(
    id: 'heat_quadruples',
    label: 'Quadruple Heat',
    caption: 'Doubling the current made four times the wire heat.',
    hint: 'Look for the clue where doubling the current made four times the heat.',
    motif: EvidenceMotif.ep2HeatQuadruples,
    accent: _ep2HeatFierce,
    relevant: true,
    sourceLabel: 'ACT 2.4',
    cropFactor: Rect.fromLTRB(0.05, 0.08, 0.95, 0.55),
  ),
  // — Real (2.5): raise the voltage, the current drops by itself — the trick —
  EvidenceTile(
    id: 'current_drops_itself',
    label: 'Current Drops',
    caption: 'Raising the sending voltage made the current fall on its own — '
        'the pinned power stayed the same.',
    hint: 'Look for the clue where raising the voltage made the current fall on its own, with the power held the same.',
    motif: EvidenceMotif.ep2CurrentDrops,
    accent: _ep2Gold,
    relevant: true,
    sourceLabel: 'ACT 2.5',
    cropFactor: Rect.fromLTRB(0.10, 0.42, 0.90, 0.98),
  ),
  // — Real (2.6): more turns step the voltage up — the enabler —
  EvidenceTile(
    id: 'turns_step_up',
    label: 'Voltage Stepped Up',
    caption: 'Winding more turns raised the sending voltage high enough for '
        'the journey.',
    hint: 'Look for the clue where extra transformer turns stepped the sending voltage up high enough for the journey.',
    motif: EvidenceMotif.ep2TurnsStepUp,
    accent: _ep2TurnsGold,
    relevant: true,
    sourceLabel: 'ACT 2.6',
    cropFactor: Rect.fromLTRB(0.40, 0.02, 0.98, 0.44),
  ),
  // — Real (2.7): a reversing current wakes the transformer — the enabler's fuel —
  EvidenceTile(
    id: 'ac_springs_alive',
    label: 'Alive on AC',
    caption: 'A current that keeps reversing keeps the field changing — the '
        'transformer came alive.',
    hint: 'Look for the clue where a reversing (AC) current woke the transformer and the bulb sprang to life.',
    motif: EvidenceMotif.ep2AcAlive,
    accent: _ep2AcBlue,
    relevant: true,
    sourceLabel: 'ACT 2.7',
    cropFactor: Rect.fromLTRB(0.10, 0.02, 0.90, 0.78),
  ),
  // — Real (2.8): the power sails across to the lit city — the end-to-end proof —
  EvidenceTile(
    id: 'ac_sails_across',
    label: 'AC Sails Across',
    caption: 'Stepped up by the transformer, the current fell to a trickle — '
        'the line ran cold and the far city lit to full.',
    hint: 'Look for the clue where the line ran cold and the power sailed across to the fully lit far city.',
    motif: EvidenceMotif.ep2AcSailsAcross,
    accent: _ep2CityWarm,
    relevant: true,
    sourceLabel: 'ACT 2.8',
    cropFactor: Rect.fromLTRB(0.04, 0.02, 0.96, 0.78),
  ),
];

/// The two EP2 distractor ids — handy for the closing flow's staging/grouping.
const List<String> kEpisode2DistractorIds = ['push_flow', 'fat_wire', 'rubbed_warm'];

/// Per-episode evidence catalogs, keyed by episode id. Future episodes extend
/// this map with their own `kEpisodeNEvidence` so the capture engine + closing
/// flow resolve tiles in the right scope (an EP2 id must NOT match an EP1 tile).
final Map<String, List<EvidenceTile>> kEvidenceCatalogs = {
  kEpisode1Id: kEpisode1Evidence,
  kEpisode2Id: kEpisode2Evidence,
};

/// Episode-scoped lookup by id — resolves within the given episode's catalog.
EvidenceTile? evidenceByIdFor(String episodeId, String id) {
  for (final t in kEvidenceCatalogs[episodeId] ?? const <EvidenceTile>[]) {
    if (t.id == id) return t;
  }
  return null;
}

/// Lookup by id across ALL episode catalogs (tile ids are unique across
/// episodes). Used by the SHARED node + drawer, which don't carry an episode
/// scope — so it must resolve EP2 tiles too, not just EP1's. (Capture hooks pass
/// an id; the store persists ids.)
EvidenceTile? evidenceById(String id) {
  for (final tiles in kEvidenceCatalogs.values) {
    for (final t in tiles) {
      if (t.id == id) return t;
    }
  }
  return null;
}

/// The two distractor ids — handy for the closing flow's staging/grouping.
const List<String> kEpisode1DistractorIds = ['still_magnet', 'turbine_spin'];
