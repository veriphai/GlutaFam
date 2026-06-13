# PRD — Make Your Case: Episode 2 CER closer
### howwow · Episode 2 "The Long Way Home" · registry id `make_your_case_ep2` · thin wrapper on the shared CER engine v2 · evidence episode `episode2_electricity`

Binding context: `docs/electricity/context_pack.md` (the covenant, esp. §5), `docs/electricity/architecture_reference.md` (Part 3 — CER engine & evidence board), curriculum §7 + §13, and `prd_episode1_cer_closing.md` (the live CER pattern spec — its rules apply verbatim here). This PRD is self-contained: every on-screen line is quoted verbatim.

**What this PRD is.** `make_your_case_ep2` is NOT a new engine. It is `MakeYourCaseScreen(config: kEp2CerConfig)` — a thin registered wrapper on the shared parameterized CER engine. This PRD specifies the **CerConfig CONTENT**: the locked EP2 evidence catalog (this document is the catalog owner — beat PRDs are reconciled TO this set), the staging, the claim template, the playback, the nudge, and the episode-synthesis card. Engine mechanics (3-screen flow, preview modal, staging machinery, completeness heuristic, playback stagger, card-earn flow) are owned by the shared-infra phase and preserved from EP1 behavior.

---

## 1. One-concept statement

**We send power across distance at enormous voltage so the current stays tiny — because wire heat grows with the square of the current — and the transformer, which runs only on AC, is what makes that voltage possible.**

This is a *synthesis*, not a new concept: the learner has felt every link (2.3 → 2.8). The CER's one job is to make them **articulate the chain themselves** — pick the moments that carry it, assemble the claim, and watch their own reasoning play back.

## 2. Guiding-question link

The episode question — **LOCKED phrasing, the shared `kEpisode2Question` every EP2 activity pins on its board strip:**

> **"The plant is far away — how do we send power across that distance without losing it all on the way?"**

Posed from beat 2.1 (pinned on every activity's `EpisodeBoardStrip`), answered here.

**The answer the evidence builds toward** (for the developer; NEVER shown as text up front):
- **The problem:** sending current down a long wire bleeds energy as heat (2.3) — and the bleed grows with the *square* of the current (2.4), so current is punished hard.
- **The trick:** for fixed power, raising the voltage makes the current fall on its own — tiny current, almost no heat (2.5).
- **The enabler:** the transformer is what lifts the voltage that high (2.6), and it works only on a current that keeps reversing — AC (2.7) — which is why the power sails across on AC (2.8).

## 3. The felt discovery (discovery → reaction)

The interaction IS the synthesis:
1. **Discriminate** — on the evidence screen the learner judges *relevance*: which witnessed moments actually answer the distance question, and which are true things that answer a *different* question (what heating is; how the device works inside). Setting the two distractors aside is the reasoning.
2. **Author** — on the claim screen the learner *builds* the claim from a 2-slot template. The honest insight (tiny + square) is reachable only by assembly; it is never offered as a pre-written sentence.
3. **Witness their own argument** — the playback orders their kept moments into the causal chain and lands the capstone. The reward is seeing their reasoning rendered coherent — no score, no grade.

## 4. Felt vs named vs numbered

- **Felt:** the evidence tiles themselves — real captured PNGs of moments the learner personally caused (the bleeding wire, the fourfold leap, the self-shrinking current, the winding coil, the transformer springing alive, the city lighting). The image carries each tile; text rides as a ≤3-word label.
- **Named:** nothing new. Every term in the claim and captions (voltage, current, heat, square, transformer, AC) was named in its own beat. The CER reuses names; it never introduces one.
- **Numbered:** **zero live numbers on all three screens.** No tile count badge, no progress %, no score. (The 3 progress dots in `CerQuestionHeader` are navigation chrome, not a readout.) **No ratings table. No ✓/✗ anywhere.**

## 5. On-screen text (EXACT — the complete set)

All strings live in `kEp2CerConfig`. Engine chrome strings shared with EP1 (preview keep/remove buttons, screen-advance CTA pills, progress dots) are reused verbatim from the EP1 config and are NOT redefined here.

**Pinned question (all three screens, `CerQuestionHeader`):**
> The plant is far away — how do we send power across that distance without losing it all on the way?

**Screen 1 — Evidence · task line:**
> Which of these clues answer the question?

**Screen 2 — Claim · task line:**
> So, what's your answer?

**Screen 3 — Playback · task line:**
> Here's your case.

**The claim template (Screen 2) — verbatim, 2 tap-fill slots:**

> "We send the power at enormous voltage so the current stays **[slot 1]** — because the wire's heat grows with the **[slot 2]** of the current."

- **Slot 1 chips (3, in this order):** `steady` · `tiny` · `huge`
- **Slot 2 chips (3, in this order):** `speed` · `square` · `direction`

The honest assembled claim: *"We send the power at enormous voltage so the current stays tiny — because the wire's heat grows with the square of the current."*

Chip design notes (why these decoys are honest work, not traps): `huge` is directly contradicted by the kept evidence (Current Drops, AC Sails Across); `steady` is a 2.7 echo the learner must reject (steadiness was the transformer's problem, not the loss's cure — the grid current is the opposite of steady); `speed` is the vague-plausible filler; `direction` echoes the AC reversal but heat never cared about direction. Each decoy points at something genuinely felt in the episode; only one pair completes the honest claim. The honest chip is deliberately NOT first in either row (no tap-the-first-chip pattern across episodes). No chip is false-on-its-face wording; there is no ✓/✗ on selection.

**The capstone line (Screen 3, lands after the montage):**
> Enormous voltage, tiny current, almost nothing lost as heat — and the transformer, running on AC, is what lifts the voltage that high.

**The completeness nudge (Screen 3, shown only when the case is incomplete per the engine heuristic; gentle, non-blocking, never identifies a tile):**
> Played back, your case doesn't quite reach the far city yet.

with the two engine CTAs (EP1 pattern, unchanged): `Add a clue` · `Finish anyway`

**Card earn (fires on Finish):** eyebrow `CASE CLOSED` · brag line:
> You built the case: enormous voltage, tiny current, AC all the way.

Rules check: no imperatives needed beyond the three task lines (each ≤7 words, instructs only); the capstone names nouns and destinations ("lost as heat"), states facts, no rhyme, never addresses the reader as a child; the nudge has no score-word, no "wrong", no checkmark; nothing pre-writes the claim.

## 6. THE FINAL EVIDENCE CATALOG (LOCKED — this table is the EP2 catalog of record)

**8 tiles: 6 relevant + exactly 2 distractors.** Ids are the beat PRDs' ids, now locked. `sourceLabel` is the mono chip on the tile. Accents/motifs feed the EP2 motif-painter file (fallback art when a capture PNG is missing). CropFactors are proposals for the catalog; final values tuned on device by the shared-infra owner.

| # | id | relevant | label (≤3 words) | caption (one line) | source beat / capture moment | sourceLabel | accent | motif (fallback painter) | cropFactor (LTRB) |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `heat_leaves_wire` | **true** | Heat Leaves | Energy escaped the wire as heat before it could reach the lamp. | 2.3 `current_heats_wire`, beat C — the frame meaning-line C3 appears (current high, motes streaming, lamp lit) | `ACT 2.3` | `#FF7A2E` | sagging wire span glowing at midspan, three short heat strokes rising off it, a small dim bulb at the right end | 0.04, 0.16, 0.96, 0.62 |
| 2 | `rubbed_warm` | **false (distractor)** | Rubbing Warms | Rubbing the wire by hand made the same heat — friction. | 2.3 `current_heats_wire`, beat B — the rub gate frame (finger glow on the wire, CURRENT chip reading 0) | `ACT 2.3` | `#FF9457` | a straight wire with a finger-stroke arc above it and warm glow pooled under the stroke | 0.15, 0.20, 0.85, 0.60 |
| 3 | `heat_quadruples` | **true** | Quadruple Heat | Doubling the current made four times the wire heat. | 2.4 `squared_loss` — 650 ms after the first ×2 landing (fierce glow, HEAT 400 in frame) | `ACT 2.4` | `#FF5A24` | two ember-glow columns rising off the same wire — the second four times taller than the first | 0.05, 0.08, 0.95, 0.55 |
| 4 | `current_drops_itself` | **true** | Current Drops | Raising the sending voltage made the current fall on its own — the pinned power stayed the same. | 2.5 `transmission_trick` — the discovery latch (first V ≥ 20; rectangle zone framed) | `ACT 2.5` | `#F5C451` | a tall narrow gold rectangle with a faint squat ghost rectangle behind it — same area, new shape | 0.10, 0.42, 0.90, 0.98 |
| 5 | `turns_step_up` | **true** | Voltage Stepped Up | Winding more turns raised the sending voltage high enough for the journey. | 2.6 `the_transformer` — the windUp ignition frame (`turnsOut == 8`, far pylon lights) | `ACT 2.6` | `#FFD27A` | a ring core with dense loops on one limb and a pulse line climbing toward a tiny pylon | 0.40, 0.02, 0.98, 0.44 |
| 6 | `changing_field` | **false (distractor)** | The Changing Field | While the field through the core is changing, it induces a voltage in the second coil. | 2.6 `the_transformer` — slowSurge output-kick frame (the `heavyImpact` moment) | `ACT 2.6` | `#E8B45A` | a ring core with concentric amber field ripples radiating, one ripple mid-bloom | 0.16, 0.28, 0.78, 0.68 |
| 7 | `ac_springs_alive` | **true** | Alive on AC | A current that keeps reversing keeps the field changing — the transformer came alive. | 2.7 `ac_vs_dc` — the spring-to-life flash frame (full bulb + breathing field + wave drawn) | `ACT 2.7` | `#3FB9F5` | a sine-wave strip under a small bulb at full bloom | 0.10, 0.02, 0.90, 0.78 |
| 8 | `ac_sails_across` | **true** | AC Sails Across | Stepped up by the transformer, the current fell to a trickle — the line ran cold and the far city lit to full. | 2.8 `war_of_currents` — AC arrival +1100 ms (cold line, full-lit city, VOLTAGE 200 / CURRENT 5 in frame) | `ACT 2.8` | `#FFE9B8` | a thin cool route line crossing dark terrain to a cluster of lit windows | 0.04, 0.02, 0.96, 0.78 |

**Why these six reals:** one tile per beat 2.3 → 2.8 — the claim's exact causal chain with zero duplication: the problem (1) → the punishment (3) → the trick (4) → the enabler (5) → the enabler's fuel (7) → the end-to-end proof (8). Beats 2.1/2.2 contribute the episode's *language* (voltage, current, resistance), not tiles — their moments belong to the definitional thread, which is where distractors live, and the two cleanest distractors come from 2.3 and 2.6 instead (one per half of the episode).

**Why these two distractors (the distractor test: each answers a DIFFERENT question, never falsely):** `rubbed_warm` is true and tempting (heat is all over the claim) but answers *what kind of process heating is*, not *how distance is crossed*. `changing_field` is true and tempting (the transformer is in the claim) but answers *how the device works inside* — the exact mirror of EP1's `still_magnet`. Neither contradicts the claim, neither is trap-worded.

### Catalog deltas vs the beat PRDs (beats reconcile to THIS set)

| Dropped proposal | From | Reason |
|---|---|---|
| `voltage_drives_current` | 2.1 | As a distractor it reads *tricky*, not merely irrelevant: its surface statement ("more voltage → more current") appears to contradict the claim's inversion unless the learner re-derives the pin flip mid-CER. The covenant bans tricky. 2.1's capture hook is removed; the discovery moments and haptics stay. |
| `no_voltage_no_current` | 2.1 | Inert as evidence (a dead lamp answers *what the quantities are*); 2.1 now contributes no tiles. Capture hook removed. |
| `thin_wire_chokes` | 2.2 | Invites a false mechanism ("choke the current with a thin wire" looks like a way to cut loss) — a misleading near-answer, not a clean different-question tile. Capture hook removed. |
| `arm_thick_cable` | 2.2 | True support ("engineers also lower R") but it dilutes the single claim this CER must land (the high-voltage trick), and a static cross-section is the least *felt-moment* tile proposed. Fewer, stronger tiles. Capture hook removed; 2.2 now contributes no tiles. |
| `square_curve` | 2.4 | Duplicates `heat_quadruples` (2.4's own PRD anticipated this trim). Capture hook removed; the sweep beat itself is untouched. |
| `cold_wire_full_town` | 2.5 | Near-duplicate image of `ac_sails_across` (cold line + lit town twice on one board); `current_drops_itself` carries 2.5's distinct logical step — the inversion. Capture hook removed; the sendTop moment still plays in-activity. |
| `dc_dead_transformer` | 2.7 | Supporting contrast carried by `ac_springs_alive`'s caption (EP1 precedent: gas/hydro catch but don't capture). Capture hook removed; the witnessed-dead beat is untouched. |
| `dc_line_cooks` | 2.8 | The counterfactual is powerful in-activity, but on the board it would be the third hot-wire image and the seventh real tile. The DC run still plays in full; only its capture is removed. |
| `edison_vs_tesla` | 2.8 (optional) | Not adopted — EP2's two distractor slots are taken by stronger, cleaner tiles. |

**Confirmed flag flips:** `rubbed_warm` ships `relevant: false` (2.3 proposed it as a distractor *candidate* — confirmed). `changing_field` ships `relevant: false` (2.6's proposal — confirmed). All other kept tiles ship `relevant: true` as proposed.

**Reconciliation note for build/integration:** activities 2.1 and 2.2 retain their `EpisodeBoardStrip` (the question stays pinned from the episode's start — the board is simply empty until 2.3) and retain their discovery flashes/haptics; only `onCapture` calls for dropped ids are removed. Capture distribution across the episode: 2.3 ×2, 2.4 ×1, 2.5 ×1, 2.6 ×2, 2.7 ×1, 2.8 ×1 = 8.

## 7. Staging (Screen 1 — ≤6 visible)

Two stages of 4, mirroring the engine's EP1 two-group staging and the episode's own two-act structure. No stage titles on screen (the tiles carry it); the engine's existing stage-advance mechanism is reused unchanged.

- **Stage A — the loss chain (beats 2.3–2.5):** `heat_leaves_wire`, `rubbed_warm`, `heat_quadruples`, `current_drops_itself`
- **Stage B — the enabler chain (beats 2.6–2.8):** `turns_step_up`, `changing_field`, `ac_springs_alive`, `ac_sails_across`

One distractor per stage, so relevance judgment happens in both halves. 4 visible per stage — comfortably under the 6 cap; tiles stay comfortably sized (never shrunk to cram).

## 8. Flow — the 3 screens (timing + gating)

1. **Entry:** `EpisodeBoardCapture('episode2_electricity').load()`. Captured tiles render their real PNGs; missing captures fall back to the EP2 motif painters. If NOTHING is captured (dev entry), the engine's full-catalog fallback applies so the screen is always playable.
2. **Screen 1 — Evidence.** Pinned question + task + Stage A grid. Tap a tile → preview modal (full-size frame + caption + keep/remove — engine chrome). No correct/wrong feedback ever. Stage B per the engine's staging. Advance CTA when ≥1 tile kept.
3. **Screen 2 — Claim.** Pinned question + task + ONLY the kept tiles (compact strip; if >6 kept, the strip scrolls — never shrinks tiles to fit) + the template sentence with two empty slots + chip rows. Both slots filled → advance CTA. Chips are re-tappable (changing your mind is free); no slot is pre-filled.
4. **Screen 3 — Playback.** Pinned question + the assembled claim + the montage: kept tiles animate in one by one, **650 ms stagger (shipped EP1 timing), in the locked catalog order of §6** — never in selection order — then the capstone line lands. A kept distractor simply plays in its catalog slot (the case feels padded — that IS the gentle consequence). If the case is incomplete (engine heuristic: all 6 relevant kept AND no distractor kept = complete; EP1 semantics preserved): show the §5 nudge + `Add a clue` / `Finish anyway`. `Add a clue` returns to Screen 1 with kept state intact.
5. **Finish:** `CollectibleEarnOverlay(card: kHighRoadCard, eyebrow: 'CASE CLOSED', brag: 'You built the case: enormous voltage, tiny current, AC all the way.', showMascot: false, onDone: controller.onCardCollected)` → auto-pop via `Navigator.maybePop(context)` (any pop = completion; no payload).

**Montage order (locked):** `heat_leaves_wire` → `heat_quadruples` → `current_drops_itself` → `turns_step_up` → `ac_springs_alive` → `ac_sails_across` → capstone. (The full catalog order including distractor slots: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 per §6 numbering.)

## 9. Hero & layout (portrait; clutter caps)

- **The hero, per screen:** Screen 1 — the evidence tiles (real captured scenes, the brightest things on the dark `_CerBackground`). Screen 2 — the claim sentence under assembly. Screen 3 — the montage. Everything else recedes (glass chrome `0x14FFFFFF` / `0x26FFFFFF`, near-black field, episode-board gold `#E8C98A` accents).
- **Per screen: pinned question + ONE task + a handful of tiles — nothing else.** ≤6 tiles visible (staged); zero live numbers; no drag-lines; no tabs; tiles = thumbnail + ≤3-word label + source chip only.
- 3 sequential screens via the engine's `AnimatedSwitcher`; one task each; `MediaQuery(...textScaler: TextScaler.noScaling)`; reduced motion → montage stagger becomes fades (the playback ORDER is pedagogy and never changes).

## 10. Reward — the episode-synthesis card (full copy)

**Card: YES** — EP1 precedent (Card 05): each episode CER earns one synthesis card. This card synthesizes the EPISODE — it names the journey's law, not any single beat's. Proposed copy (shared-infra owner assigns the number, builds the motif painter, updates `deckTotal` on ALL constants; this wrapper only references the constant, proposed `kHighRoadCard`, proposed id `the_high_road`):

- **Front — playful name:** **The High Road**
- **Front — real term (mono specimen):** `HIGH-VOLTAGE AC TRANSMISSION`
- **Front — one-line law:** *Distance is crossed at enormous voltage and tiny current — and only AC could be stepped up that high.*
- **Front — kicker:** *How power beats distance.*
- **Back — tie to what was felt:** *You watched heat bleed off the wire and leap with the square — then raised the voltage, the current fell on its own, and the far city lit to full.*
- **Back — outward reach:** *Follow any pylon line on the horizon: it is running this exact case right now, at hundreds of thousands of volts.*
- **Section:** transmission, accent `#3FB9F5`. **Motif suggestion:** a tall thin gold rectangle standing over a long cold line that reaches a lit far cluster.
- **Linked card:** 2.5's *Starve the Wire* (the trick this case rests on) — the deck's recurring-thread payoff, exactly as Card 05 linked Card 03. (Shared infra may additionally note the lineage to 2.6's *The Still Machine*; single-link default.)
- **No-restatement check:** 2.5's card owns the fixed-power inversion as a law; 2.4's owns I²R; 2.7's owns the two currents. This card's law is the *episode-level* composite (distance + voltage/current trade + the AC condition) — none of the beat cards states it.

**Inline fact: none** (deliberate empty slot — the capstone is the last thing read before the card).

## 11. Build notes

- **Wrapper only.** `lib/screens/missions/make_your_case_ep2/` (or the engine's wrapper convention) exposes a `const` screen that returns `MakeYourCaseScreen(config: kEp2CerConfig)`. Registration in `activityRegistry.dart` is central-integration work — not this build.
- **CerConfig content (this PRD's deliverable — keyed to the SHIPPED `CerConfig` field names in `config/cer_config.dart`, so the shared-infra owner sets it 1:1):**

```dart
const CerConfig kEp2CerConfig = CerConfig(
  episodeId: kEpisode2Id,        // 'episode2_electricity'
  question: kEpisode2Question,   // the §5 pinned question, shared constant
  beatName: 'Make Your Case',
  tiles: kEpisode2Evidence,      // the §6 catalog: 8 EvidenceTiles, flags as locked
  stages: [
    ['heat_leaves_wire', 'rubbed_warm', 'heat_quadruples', 'current_drops_itself'],
    ['turns_step_up', 'changing_field', 'ac_springs_alive', 'ac_sails_across'],
  ],
  evidenceTask: 'Which of these clues answer the question?',
  evidenceHint: 'Tap a clue to open it, then keep the ones that fit.',
  moreCta: 'More clues',
  backCta: 'Back',
  toClaimCta: 'State your answer',
  claimTask: 'So, what\'s your answer?',
  // textParts length = slots + 1, interleaved textParts[0]·slot0·textParts[1]·slot1·textParts[2]:
  textParts: [
    'We send the power at enormous voltage so the current stays',
    '— because the wire\'s heat grows with the',
    'of the current.',
  ],
  slotOptions: [
    ['steady', 'tiny', 'huge'],
    ['speed', 'square', 'direction'],
  ],
  slotCaptions: ['The current stays…', 'Heat grows with the…'],
  slotPlaceholders: ['…', '…'],
  toPlaybackCta: 'See your case',
  capstone: 'Enormous voltage, tiny current, almost nothing lost as heat — and the '
      'transformer, running on AC, is what lifts the voltage that high.',
  incompleteNudge: 'Played back, your case doesn\'t quite reach the far city yet.',
  distractorNote: 'One of your clues is really about HOW the heat is made or HOW the '
      'transformer works inside — not how the power crosses the distance. Still a true '
      'thing you found!',
  addEvidenceCta: 'Add a clue',
  finishCta: 'Finish',
  finishAnywayCta: 'Finish anyway',
  card: kHighRoadCard,           // shared-infra defines (§10 copy); proposed constant name
  earnEyebrow: 'CASE CLOSED',
  earnBrag: 'You built the case: enormous voltage, tiny current, AC all the way.',
);
```

  Note the live engine separates `evidenceTask`/`evidenceHint` (Screen 1) from `claimTask` (Screen 2) and renders the slot sentence from `textParts` + `slotOptions` + `slotCaptions` + `slotPlaceholders`. The §5 wording above is the source of truth; the only additions the shipped shape requires beyond §5 are the `evidenceHint`, `slotCaptions`, and the engine CTA strings (`moreCta`/`backCta`/`toClaimCta`/`toPlaybackCta`/`addEvidenceCta`/`finishCta`/`finishAnywayCta`), supplied here. The kept-distractor aside is `distractorNote` (gentle, never names the tile).
- **Dependencies on shared-infra v2 fixes (report, don't edit):** `EpisodeBoardCapture` must resolve tiles via `evidenceByIdFor(episodeId, id)` (the EP1-only `evidenceById` lookup blocks EP2 captures); `kEpisode2Question` must be a shared constant all 8 beats and this config import.
- Completeness heuristic, preview modal, staging, playback stagger, `_CerBackground`, progress dots: engine, unchanged from EP1 semantics.
- Verify: `fvm dart analyze` clean on the wrapper dir + every shared file imported. Never multi-path repo-wide analyze.

## 12. Acceptance criteria (the anti-worksheet rules as testable checks)

1. **Evidence is felt moments, never text bullets:** every tile renders a captured scene PNG (or its drawn motif fallback) + ≤3-word label + source chip; no tile is a sentence card; no checkbox exists anywhere.
2. **The claim is BUILT, never selected:** Screen 2 offers no full pre-written claim; both slots must be tapped to assemble it; the honest claim string exists nowhere in the config as a single selectable unit.
3. **Reasoning is carried by the playback:** Screen 3 orders the kept tiles per §8's locked montage order (never selection order) at 650 ms stagger, then lands the §5 capstone verbatim. **No drag-lines** between evidence and claim anywhere.
4. **No score, no ✓/✗, no tabs:** selection produces no correct/wrong feedback; the three screens are sequential (engine `AnimatedSwitcher`), never tabs; nothing displays a count, percentage, or grade.
5. **Distractors are exactly 2, true-but-irrelevant:** `rubbed_warm` and `changing_field` carry `relevant: false`; both captions are true statements; no distractor's caption contradicts the claim or is trap-worded; all six other tiles carry `relevant: true`.
6. **≤6 tiles visible per screen:** Screen 1 stages 4 + 4 per §7; Screen 2's kept-strip scrolls rather than shrinking tiles when >6 are kept.
7. **The incomplete case responds gently:** with any relevant tile missing OR any distractor kept, Screen 3 shows the §5 nudge + `Add a clue` / `Finish anyway`; `Finish anyway` always works (never blocking); the nudge never names which tile is missing or kept; completeness semantics match EP1's heuristic exactly.
8. **Question fidelity:** the §5 question string is identical on all three screens AND identical to the `kEpisode2Question` pinned by all 8 beat activities.
9. **Catalog fidelity:** ids, labels, captions, flags, stage groups, chips, capstone, nudge, and card copy are verbatim from this PRD; capture ids called by the 6 contributing activities are exactly the 8 ids in §6 and no others (dropped ids appear nowhere in the EP2 catalog or any beat's capture calls).
10. **Zero live numbers** on all three screens; no ratings table; no tile ever displays a relevance hint (no dimming, badging, or ordering that leaks the distractors).
11. **Dev-entry fallback:** with nothing captured, the full catalog (motif fallbacks) loads and the flow is fully playable.
12. **Completion contract:** the card overlay fires once on Finish with eyebrow `CASE CLOSED`; `onDone` → `Navigator.maybePop`; any pop = completion. Reduced motion respected (fades for the montage; order unchanged). Analyzer clean on the wrapper dir.

## 13. Anti-patterns (this beat)

- **Worksheet drift** — the single biggest failure mode: text-bullet tiles, checkbox affordances, a "3/6 correct" readout, tabs. Any one of these kills the beat's identity.
- A pre-written claim sneaking in as a "suggested answer" or as the nudge's wording.
- Marking selection right/wrong — including subtle versions (a happy chime only on relevant tiles, distractors graying out).
- Drag-lines from tiles to the claim.
- Playback in selection order — the montage must argue, so it plays the causal chain order.
- A tricky distractor (anything whose caption must be *disbelieved* to be set aside). Both distractors are true; the work is relevance.
- Re-teaching inside the CER: no new meaning-lines re-deriving the square or the inversion; captions only restate what was already felt and named.
- The nudge as a gate, a red state, or a tile-specific hint.
- Restating a beat card's law on the synthesis card.
- This build editing shared files (engine, catalogs, cards, registry, wowConcepts) — wrapper + config content proposals only.

## 14. Open decisions

1. **Stage-B reveal mechanism** (auto-advance after Stage A interaction vs a quiet "more clues" affordance) — engine owner; whatever EP1's shipped staging does, reuse.
2. **Kept-strip behavior on Screen 2 when >6 tiles kept** — default scroll (per the UI-layout rule: scroll, don't cram); engine owner confirms.
3. **Final cropFactors** for all 8 tiles — §6 proposals; tune on device against real captures.
4. **Card number, constant name (`kHighRoadCard`), and link wiring** (default link: *Starve the Wire*) — shared-infra catalog consolidation.
5. **Chip order** — locked as §5 (honest chip mid-row) unless on-device QA finds the rows read as ranked; never sort honest-first.
6. **Whether the EP2 question string wraps to two lines cleanly** in `CerQuestionHeader` on small phones (it is longer than EP1's) — if not, the header may tighten letter-spacing/size; the wording does not change.

---

## One-line summary

End Episode 2 with the learner making the case themselves: from eight witnessed moments they keep the six that carry the chain — heat leaves the wire, leaps with the square, the current falls when the voltage rises, the transformer lifts it, AC keeps it alive, and the power sails across — set aside the two true-but-different clues (the hand-made friction heat, the inside of the transformer), assemble *"…the current stays **tiny** — because the wire's heat grows with the **square** of the current"*, and watch their own argument cross the distance — then pocket **The High Road**.
