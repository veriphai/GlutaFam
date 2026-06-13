# PRD — Make Your Case (Episode 4 CER closer)
### howwow electricity · registry id `make_your_case_ep4` · thin wrapper on the shared CER engine · evidence episode `episode4_electricity` · Episode 4 — Keeping the Lights On

Binding context: `docs/electricity/context_pack.md` (§5, §6), `docs/electricity/architecture_reference.md` (PART 3), curriculum §7 + §13, and `prd_episode1_cer_closing.md` (the live CER pattern spec — its rules apply verbatim here). This PRD specifies the **`CerConfig` CONTENT for Episode 4** — not a new engine. The shipped engine (`MakeYourCaseScreen` + `CerController` + `CerConfig`, see `lib/screens/missions/make_your_case/`) is reused as-is; `make_your_case_ep4` registers `MakeYourCaseScreen(config: kEp4CerConfig)`.

**This document is the owner of the EP4 evidence catalog.** The tile ids below are LOCKED; the five beat PRDs (4.1–4.5) are reconciled to this set (deltas in §3.3).

---

## 1. One-concept statement
**The grid is run, not stored: operators forecast the human day and dispatch the right kind of plant, every second, because nothing buffers the grid.**

This is the episode synthesis the learner must ASSEMBLE — never read pre-written. The five beats are its clauses: no buffer (4.1) → the balance is spinning mass read as frequency (4.2) → demand follows human routines (4.3) → baseload covers the floor, peakers chase the spikes (4.4) → and when balance fails it cascades (4.5).

## 2. Guiding question + the answer
### 2.1 Guiding question (locked — pinned on every beat's board strip and on all three CER screens)
> **"The plant is making almost exactly what the whole city uses this very second — who decides that, and what happens at the 6pm rush?"**

(All five beat PRDs pin this exact phrasing; the CER header renders it at the strip's smaller wrap size — it is longer than EP1's question and must wrap, never truncate.)

### 2.2 The answer (developer-facing — NEVER shown as text up front)
Two halves, mirroring the question:
- **Who decides:** people — operators. They can decide because demand is *forecastable* (same shape every day — 4.3) and the balance is *readable live* off one number (the frequency dip — 4.2); they decide by dispatching the right *kind* of plant for the shape (4.4: the big plant was big enough but never fast enough; the fast plant caught the same spike).
- **What happens at the 6pm rush:** the whole grid feels it the same instant (the dip), and the match must be re-made continuously — because nothing buffers the grid (4.1), and a missed match races dark in seconds (4.5 — the stakes behind "every second").

## 3. Final evidence catalog (LOCKED ids)
**6 real tiles + EXACTLY 2 distractors = 8 tiles.** Felt moments captured as replayable tiles, never text bullets. Distractors are TRUE-but-irrelevant, never false/tricky — both answer the episode's *other* thread ("how the machinery behaves") rather than the question ("who runs the balancing act, and what happens at 6pm") — the exact EP1 how-vs-why split in grid costume.

### 3.1 Real evidence (relevant: true)

| id | label (≤3 words) | caption (one line, shown in preview + playback) | accent | source | captured at |
|---|---|---|---|---|---|
| `demand_never_still` | Never Holds Still | Production froze for four seconds — demand walked away and the city tipped. | `#FFD27A` warm energy | `ACT 4.1` (`hold_the_balance`) | 4.1 M5 let-go discovery frame (frozen desaturated column, diverged chips, tipped town) |
| `rush_hour_dip` | The 6pm Dip | The evening rush dragged every generator down together — the falling number said add power, now. | `#B08CF7` grid violet | `ACT 4.2` (`grid_frequency`) | 4.2 rush, first freq ≤ 48.8 (hero + ghost rotors slowed, chip in the red) |
| `same_shape_next_day` | Same Shape Tomorrow | Two days traced: the demand curve repeats its shape but never its exact line — so operators forecast it, then chase it. | `#E8C98A` board gold | `ACT 4.3` (`demand_curve`) | 4.3 day-2 trace complete +300 ms (both gold curves over the night city) |
| `slow_plant_late` | Spike Outruns Plant | Ordered to full power at the first second, the big plant arrived after the rush — the town dimmed. | `#FF7A2E` heat orange | `ACT 4.4` (`baseload_peaking`) | 4.4 run-1 brown-out frame (gap ≥ 15 at the spike peak, with T7) |
| `fast_plant_catch` | Fast Plant Catches | The peaking plant climbed as fast as the lever moved — the same spike, fully covered. | `#F5C451` bright gold | `ACT 4.4` (`baseload_peaking`) | 4.4 run-2 end of covered peak hold (with T14) |
| `cascade_dark_map` | Dark in Seconds | One overloaded plant tripped — its load overloaded the rest, and the whole map went dark in seconds. | `#8FA6FF` moon-cool | `ACT 4.5` (`cascading_blackout`) | 4.5 Act-1 full dark + 400 ms (dark map, emergency outlines, dead `— Hz` chip) |

What each carries in the claim: `demand_never_still` = "every second / nothing buffers"; `rush_hour_dip` = "how operators know" (the live readout) + the 6pm rush grid-side; `same_shape_next_day` = "operators forecast the human day"; `slow_plant_late` + `fast_plant_catch` = "dispatch the right KIND of plant" (the pair is one argument: big enough ≠ fast enough); `cascade_dark_map` = the stakes (why "every second" is not a figure of speech).

### 3.2 Distractors (relevant: false — exactly 2)

| id | label | caption | accent | source | captured at | why it is a GOOD distractor |
|---|---|---|---|---|---|---|
| `lockstep_spin` | One Shared Spin | Every generator on the grid spins in phase — one shared spin, one machine, across the country. | `#3FB9F5` mechanism blue | `ACT 4.2` (`grid_frequency`) | 4.2 lockstep phase: ghost rotors fully revealed in sync with the hero (with L9) | True and witnessed — but it answers *how the grid is physically one machine*, not *who decides production or what happens at 6pm*. (Adopts 4.2 PRD §13.2's optional tile.) |
| `breaker_trip` | Built to Trip | Pushed past its limit, a plant trips itself offline — the breaker saves the machine from burning out. | `#3FB9F5` mechanism blue | `ACT 4.5` (`cascading_blackout`) | 4.5 Act-2 G3 trip frame (step 14, ~150 ms after the snap) — NOT Act 1, so the silent Act-1 cascade stays unobstructed | True and witnessed dramatically — but it answers *how one machine protects itself*. Discriminating it from `cascade_dark_map` (the propagation, which IS on-question) is real reasoning. |

Both distractors share the mechanism-blue accent (EP1 precedent: both distractors blue). `kEpisode4DistractorIds = ['lockstep_spin', 'breaker_trip']`.

**The distractor test applied (the brief's bar — "answers a DIFFERENT question than the episode's"):** the episode question is *"who decides production this second, and what happens at 6pm?"* `lockstep_spin` answers *"how is the grid physically one machine?"*; `breaker_trip` answers *"how does a single machine protect itself?"*. Both are TRUE and were genuinely witnessed; neither is false, tricky, or trap-worded; each answers a demonstrably different question. ✓ This is the exact EP1 how-vs-why split (still-magnet / turbine answered "how it's made," not "why so many") in grid costume — relevance, not trap-spotting, is the reasoning.

### 3.3 Catalog deltas vs the beat PRDs (the beat PRDs are reconciled to this list)
1. **DROPPED `surge_nowhere_to_go` (4.1).** Redundant: the no-buffer clause needs one tile and `demand_never_still` carries it plus the "every second" continuity. 4.1's M3 moment keeps its line and hard-gate surge; the `onCapture` call at M3 is removed.
2. **DROPPED `seconds_of_spin` (4.2).** A second no-buffer tile; its refinement ("the only store is seconds of spin") survives as a claim chip (§5) and on 4.2's own card back. The letGo discovery keeps its flash + heavyImpact; the capture is removed.
3. **DROPPED `evening_peak_cause` (4.3).** The 6pm rush is already carried grid-side (`rush_hour_dip`), dispatch-side (`slow_plant_late`/`fast_plant_catch`) and failure-side (`cascade_dark_map`); 4.3's irreplaceable contribution is forecastability (`same_shape_next_day` — label adjusted from "Same Shape" to "Same Shape Tomorrow"). The peak replay keeps its heavyImpact + discovery ring; the capture at DEMAND ≥ 97 is removed.
4. **DROPPED `reserve_holds_line` (4.5).** Neither clean evidence (reserve margins are adjacent to, not part of, "forecast + dispatch every second") nor a safe distractor (too close to relevance — operators lining up reserves IS part of dispatch). The Act-2 hold keeps its heavyImpact; the capture is removed.
5. **ADDED `lockstep_spin` (4.2, distractor).** 4.2's §13.2 optional capture becomes official: fires once at the lockstep reveal (L9), one-way latch, lightImpact + flash per the standard hook.
6. **ADDED `breaker_trip` (4.5, distractor).** New capture at the **Act-2** G3 trip frame (step 14) — placed in Act 2 deliberately so no flash chrome intrudes on Act 1's caption-suppressed cascade. Idempotent across Act-2 retries (fires on the first Act-2 trip only).

Every tile auto-captures on a complete episode run (all eight moments are gated, witnessed beats) — discovery and capture are one act; nothing is missable.

**Build-action summary (the complete, closed set of `onCapture` calls across EP4 — no beat fires any id not in this list):**
```
4.1 hold_the_balance   → onCapture('demand_never_still')
4.2 grid_frequency     → onCapture('rush_hour_dip')        ← KEEP
                         onCapture('lockstep_spin')        ← ADD (was 4.2 §13.2 "optional"; now locked)
                         (NO onCapture('seconds_of_spin')  ← the letGo flash + L3/L4 stay; only the capture is removed)
4.3 demand_curve       → onCapture('same_shape_next_day')
4.4 baseload_peaking   → onCapture('slow_plant_late'); onCapture('fast_plant_catch')
4.5 cascading_blackout → onCapture('cascade_dark_map'); onCapture('breaker_trip')  ← breaker_trip on the Act-2 trip
```
The only build action that differs from a beat PRD's own §9 as-written is on 4.2: it must add the `lockstep_spin` capture at L9 and ensure `seconds_of_spin` fires NO capture (its felt discovery — `heavyImpact` + L3/L4 — is untouched). Every other beat already calls exactly the ids above.

### 3.4 Motifs (fallback painters, per-episode painter file)
| motif (suggested enum name) | fallback drawing |
|---|---|
| `demandNeverStill` | a frozen, desaturated supply column beside a demand trace pulling away from it; a dimmed window-grid band beneath |
| `rushHourDip` | a heavy flywheel with its gauge arc, the speed tick sagging below a glowing 50 notch; two faint synced ghost rotors behind |
| `sameShapeNextDay` | two near-identical gold day-curves overlaid — one ghosted, one bright — peaks slightly offset, over a tiny night skyline |
| `slowPlantLate` | a demand ridge with a low amber fill far beneath its peak; a darkened window strip below the chart |
| `fastPlantCatch` | the same ridge with a stacked fill hugging it — wide deep-amber band + thin bright-gold crest; warm window strip |
| `cascadeDarkMap` | a dark district map with faint emergency outlines, one dead plant glyph with a `TRIPPED` tag, a radiating wavefront ring |
| `lockstepSpin` | three rotors in a row, spokes frozen at the identical angle, linked by one thin shared line |
| `breakerTrip` | a single plant glyph, load ring filled past its limit notch, snapped dark, small `TRIPPED` tag |

cropFactors: keep the beat PRDs' proposals for the six retained tiles; `lockstep_spin` ≈ `Rect.fromLTRB(0.02, 0.04, 0.98, 0.55)` (hero rotor + ghosts band); `breaker_trip` ≈ `Rect.fromLTRB(0.26, 0.02, 0.74, 0.30)` (G3 + neighbouring rings). Final values tuned at integration against the shipped scenes.

## 4. Staging (Screen 1 — ≤6 visible per stage)
Two stages of 4, mirroring the episode's halves, **one distractor seeded into each stage** so the relevance judgment is live on both screens (EP1 put both in one stage; with 8 tiles the split reads cleaner):

```dart
stages: [
  ['demand_never_still', 'rush_hour_dip', 'same_shape_next_day', 'lockstep_spin'],   // the balance & the day
  ['slow_plant_late', 'fast_plant_catch', 'cascade_dark_map', 'breaker_trip'],       // the dispatch & the stakes
],
```
Catalog (= display = playback) order: the six reals in beat order, then the two distractors last — `demand_never_still, rush_hour_dip, same_shape_next_day, slow_plant_late, fast_plant_catch, cascade_dark_map, lockstep_spin, breaker_trip`. (The engine renders stage tiles and plays kept tiles in catalog order, so this list IS the montage order.)

## 5. Claim build (Screen 2 — built, never selected)
2-slot template. The scaffolding gives the actor and the reason's shape; the two slots carry the episode's two live discriminations — the **kind** of plant and the **cadence** — each adjudicated by kept evidence, none false/tricky.

```dart
textParts: [
  "Operators forecast the city's day and chase its spikes with",
  ', holding the match',
  '— because nothing buffers the grid.',
],
slotOptions: [
  ['the fast plants', 'the biggest plant', 'every plant at once'],
  ['every second', 'at the evening rush', 'once each morning'],
],
slotCaptions: ['With which plants?', 'How often?'],
slotPlaceholders: ['?', '…'],
```

Assembled honest claim (reachable ONLY by assembly — never pre-written anywhere):
> **"Operators forecast the city's day and chase its spikes with the fast plants, holding the match every second — because nothing buffers the grid."**

Why these chips: slot 1's "the biggest plant" is the exact misconception `slow_plant_late` dismantles (big enough, never fast enough); "every plant at once" is killed by the over-supply tip (`demand_never_still`'s episode: running ahead tips it too). Slot 2's "at the evening rush" and "once each morning" are killed by the wander that never held still and the dip that demanded power *now*. All six chips are grammatical in the sentence; no chip is a trap — the evidence does the adjudicating in the learner's head.

(Engine check: `', holding the match'` leads with `,` so it attaches to slot 1 without a space; `'— because…'` takes a space — the assembled string renders exactly as above.)

## 6. Playback (Screen 3 — the reasoning, carried by the montage)
- **Montage order** (kept tiles, catalog order — the argument): `demand_never_still` (the city never holds still and nothing buffers it) → `rush_hour_dip` (the rush hits every generator the same instant; the falling number orders power in) → `same_shape_next_day` (but the day repeats its shape — it can be forecast) → `slow_plant_late` (foresight is not speed: the spike outran the big plant) → `fast_plant_catch` (the fast plant caught the same spike) → `cascade_dark_map` (and when the match slips, a region goes dark in seconds) → capstone. Full-bleed Ken-Burns frames of the learner's own captures, 2.5 s dwell, tap-to-advance, skippable (shipped engine behaviour).
- **Capstone (verbatim):**
> **…so keeping a city lit is not a thing built once — it is a balance held live, every second of every day.**
- The capstone resolves the montage without parroting the claim's tail; claim banner (the learner's assembled sentence) glows above it, emphasised at the finale.

## 7. On-screen text — EXACT (all three screens, the complete config copy)
No mascot, no info-cards, no score, no ✓/✗ anywhere. One voice. All strings verbatim:

| config field | text |
|---|---|
| `question` (pinned, all 3 screens) | The plant is making almost exactly what the whole city uses this very second — who decides that, and what happens at the 6pm rush? |
| `beatName` | Make Your Case |
| **Screen 1** `evidenceTask` | Which clues answer the question? |
| `evidenceHint` | Tap a clue to open it, then keep the ones that fit. |
| `moreCta` / `backCta` | More clues / Back |
| `toClaimCta` | State your answer |
| **Screen 2** `claimTask` | So — what's your answer? |
| `textParts` + `slotOptions` + `slotCaptions` + `slotPlaceholders` | as §5, verbatim |
| `toPlaybackCta` | See your case |
| **Screen 3** `capstone` | …so keeping a city lit is not a thing built once — it is a balance held live, every second of every day. |
| `incompleteNudge` (gentle, no score, no checkmarks) | Your case feels unfinished — a moment that answers the question is still missing. Want to add it? |
| `distractorNote` (gentle aside, never blocking) | One of your clues is really about how the machinery works — not who keeps the city matched. Still a true thing you found! |
| `addEvidenceCta` / `finishCta` / `finishAnywayCta` | Add a clue / Finish / Finish anyway |
| `earnEyebrow` | CASE CLOSED |
| `earnBrag` | You made your case — nothing stores it, people match it. The city runs on a balance held every second. |

Tile labels and captions (which appear under tiles, in the preview modal, and on the playback frames) are locked in §3.1/§3.2. No other text exists in this flow.

## 8. Reward — the EP4 synthesis card
**Card: YES** (episode-CER synthesis card, EP1 precedent — Card 05). Proposed copy for the shared-infra catalog (number + `deckTotal` assigned centrally; this flow references the constant only — proposed `kControlRoomCard`):

- `id: 'grid_balanced_live'` · **cardName: `The Control Room`** · realName (mono specimen label): **`SYSTEM OPERATION`**
- **Law:** A grid is run, not stored — operators forecast the human day and dispatch the right kind of plant to hold the match, every second.
- **Kicker:** The lights stay on because someone is keeping them on.
- `section: CardSection.grid` (accent `#B08CF7`) · motif: two traces locked together over a lit city silhouette — a demand curve and the supply line holding it, a small 50-notch tick above.
- **Back — tie to what was FELT (the episode, not one beat):** You let go for four seconds and the city tipped; you watched the 6pm rush drag the spin down, the slow plant arrive late, the fast one catch the spike — and one missed match black out the map.
- **Back — outward reach:** India's grid is matched this way around the clock from national and state load despatch centres — rooms of people watching one number, dispatching plants minute by minute.
- **Linked card:** The Tightrope (4.1's THE GRID card) — the law this job exists to serve. (Shared infra confirms link; "SYSTEM OPERATION" also pre-links the EP5 bill slice of the same name, curriculum 5.4.)

It synthesizes the episode and restates no beat card's law: 4.1's card owns "made and used in the same instant"; 4.2's owns "the spin is the readout"; 4.4's owns "floor vs spikes" — this card owns *the human job those three facts create*. **Inline fact: none** (deliberate empty slot — the reach lives on the card back).

## 9. Felt / named / numbered + hero & layout (engine-inherited)
- **Felt:** the evidence is the learner's own captured frames (real PNGs of moments they caused), replayed full-bleed; relevance is judged by recall of the felt moment, not by reading rules. **Named:** nothing new is named here — every term in the copy (demand, frequency, operators, peaking by behaviour) was named in its beat. **Numbered:** none — no live numbers, no score, no progress percent; the only numerals on screen ride inside captured frames.
- **Hero per screen:** Screen 1 — the staged tile grid (the learner's own evidence); Screen 2 — the claim sentence under assembly; Screen 3 — the full-bleed montage. One task per screen; pinned question + task + tiles and **nothing else**; ≤6 tiles visible (staged 4+4); ≤6 interactive elements; **no tabs, no drag-lines, no checkboxes** (shipped engine already complies).

## 10. Build notes (shared-infra + integration surface)
- **Engine: unchanged.** New content only: `kEp4CerConfig` (a `const CerConfig`, fields per §4–§8), `kEpisode4Evidence` + `kEpisode4Id = 'episode4_electricity'` + `kEpisode4Question` + `kEpisode4DistractorIds` in `evidence_models_ep4.dart`, registered into `kEvidenceCatalogs`; 8 motif painters in a per-episode painter file; the card constant in `collectible_models.dart` (+ painter + dispatch case + `deckTotal` bump on ALL constants — single-owner files, shared-infra agent only).
- **Wrapper:** registry id `make_your_case_ep4` → `MakeYourCaseScreen(config: kEp4CerConfig)` in `activityRegistry.dart` (central integration, not a build-agent edit). Completion = card earn → auto-pop (`Navigator.maybePop`), engine behaviour.
- **Capture wiring** lives in the five activities (already specced there); they call exactly these ids at exactly the §3 moments via `evidenceByIdFor('episode4_electricity', id)`. Captured tiles accumulate on each activity's `EpisodeBoardStrip` under the pinned question all episode.
- **Fallbacks (engine-inherited):** uncaptured tiles fall back to motif painters; a dev entry with nothing captured seeds the full catalog; `caseComplete` is scoped to `available`, so a learner who skipped an activity can still complete an honest, smaller case.
- Long `question` and long `textParts[0]`: verify wrap (no ellipsis) on a ≈360×640 logical portrait phone.
- Verify: `fvm dart analyze` clean on `make_your_case`, `episode_board`, and the new per-episode files.

## 11. Acceptance criteria (anti-worksheet rules as testable checks)
1. **Evidence is felt moments, never text bullets:** every tile renders the learner's real captured PNG (motif fallback only when uncaptured); no tile is a sentence-card.
2. **Exactly 2 distractors, true-but-irrelevant, never false/tricky:** `lockstep_spin` and `breaker_trip` are both true, witnessed moments; each answers a machinery question, not the episode question; selecting them produces **no correct/wrong feedback** — only the optional gentle `distractorNote` on playback.
3. **The claim is BUILT, never selected whole:** the full claim sentence appears nowhere in copy, chips, or chrome; it exists only after the learner fills both slots; all 6 chips are grammatical in the sentence.
4. **Reasoning is carried by the playback:** kept tiles replay in catalog (argument) order with their captions, resolving into the capstone; **no drag-lines, no typed essay**.
5. **No score, no ✓/✗, no tabs anywhere:** 3 sequential screens, one task each; progress dots are positional, not evaluative; an incomplete case *feels* incomplete (the nudge) and can be added to or finished anyway — never blocked, never graded.
6. **≤6 tiles visible per screen:** stages are 4+4; the claim screen shows only kept tiles; clutter caps of §9 hold.
7. **Completeness semantics:** the nudge fires only when a *relevant captured* tile is missing from the kept set; keeping a distractor never makes the case "incomplete" and never blocks Finish.
8. **The capstone and claim land the locked synthesis** (§1) — and neither is shown before assembly.
9. **Card:** `CASE CLOSED` earn fires once on Finish with the §8 card; collected persists; pop completes the activity.
10. **Catalog integrity:** all 8 ids resolve via `evidenceByIdFor('episode4_electricity', …)`; every relevant tile appears in a stage group; the six reals' capture sites match the (reconciled) beat PRDs; both added captures (`lockstep_spin` at 4.2 L9, `breaker_trip` at 4.5 Act-2 trip) fire once, idempotently.
11. The question is pinned verbatim at the top of all three screens; no screen shows the answer, a hint chip, or a "correct evidence" highlight.

## 12. Anti-patterns (this flow)
- A tile becoming a text bullet ("☐ Plants are slow") — the instant that happens it's a worksheet.
- Marking distractors visually (different frame, dimming, a warning) — relevance must be the learner's judgment.
- A pre-written claim option, or chips so lopsided the slot is a quiz ("the fast plants" vs two absurdities — the wrong-ish chips must be honest misconceptions).
- Score, stars, streaks, "2/6 correct", or a completeness percentage — the only feedback is the played-back case and the gentle nudge.
- Re-teaching in CER copy (explaining frequency or baseload in captions) — captions recall the felt moment; the beats did the teaching.
- A third distractor, or zero — exactly 2 (zero makes select-everything win; three reads as a test).
- Letting the EP4 card restate The Tightrope / The Spin Never Lies / The Floor and the Spike — this card owns the human job only.
- Tabs, checkboxes, drag-lines, or showing all three tasks at once.

## 13. Open decisions
1. `sourceLabel` format — default `ACT 4.1`…`ACT 4.5` (EP1's `ACT 2/3` convention scoped to the episode); alternative is beat names. Catalog implementer's call at integration.
2. `breaker_trip` capture placement — default Act-2 trip (keeps Act 1's silent cascade pristine); may move to the Act-1 trip frame iff the build defers the board flash until post-dark.
3. Final cropFactors (§3.4 proposals) — tuned against the shipped scenes on device.
4. Card constant name (`kControlRoomCard` proposed), deck number, and the linked-card choice (The Tightrope vs The Grid Is a Mix) — shared-infra agent owns.
5. "Same Shape Tomorrow" vs "Same Shape" label — default the 3-word form (clearer at tile size).
6. Whether the very long pinned question needs a reduced font tier in `CerQuestionHeader` on small phones — visual QA at integration.
