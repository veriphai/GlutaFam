# PRD — The 6pm Rush: Baseload vs Peaking (EP4 beat 4.4)
### howwow · Episode 4 "Keeping the Lights On" · registry id `baseload_peaking` · `BaseloadPeakingScreen` · evidence episode `episode4_electricity`

Binding context: `docs/electricity/context_pack.md`, `docs/electricity/architecture_reference.md`, curriculum §4.4 + §1–§9 + §13.
This PRD is self-contained: every on-screen line is quoted verbatim here. No mascot, no Voltix, no info-cards. Fully explained — **no depth-stop in this beat** (the plant's slowness bottoms out in showable mechanism: tonnes of hot metal and steam).

---

## 1. One-concept statement

**Balancing is not just "make more" — it is make more FAST ENOUGH with the right KIND of plant.**

Inherits (already felt by the learner): 4.1 — nothing buffers the grid, supply must equal demand continuously, and running ahead of demand tips it just like falling behind; 4.2 — the balance is spinning mass, read as frequency; 4.3 — demand follows human routines, so the 6pm spike is *known in advance*. That last inheritance is the knife: the learner sees the spike coming, commands full power at the first second — **and still fails**, because foresight cannot substitute for ramp speed.
Pins (held constant, visible): **the demand day is identical in both runs** (the same curve replays, said so on screen); **the big plant's capacity visibly exceeds the spike's peak** (a capacity tick sits above the demand ridge all activity, so the failure can only read as *too slow*, never *too small*); **the controls are never the obstacle** (the lever thumb tracks the finger instantly — only the plant's output fill lags).

## 2. Guiding-question link & CER contribution

Episode question (pinned on the board strip): *"The plant is making almost exactly what the whole city uses this very second — who decides that, and what happens at the 6pm rush?"*

- **Relevant evidence:** `slow_plant_late` — the chart frozen at the brown-out: demand ridge at its peak, the big plant's supply trace still climbing far below it, the town dim. This is the "what happens at the 6pm rush" half of the question made visible: the rush outruns a slow plant.
- **Relevant evidence:** `fast_plant_catch` — the same spike fully covered, the bright peaking layer stacked on the steady baseload band, town bright. This carries the "who decides that" half: someone dispatched the right *kind* of plant for the shape, in advance.
- **No distractor proposed from this beat.** Both moments are core to the episode claim (*operators forecast the human day and dispatch the right kind of plant, every second, because nothing buffers the grid*). Recommendation to the EP4 CER owner: source the episode's exactly-2 true-but-irrelevant distractors from 4.2/4.3 detail moments (e.g. the TV-kettle spike — true, but it answers *why demand wiggles*, not *who balances it at 6pm*… actually that is arguably relevant; better candidates are mechanism trivia from 4.2 such as "generators spin in lockstep").

## 3. The felt discovery (discovery → reaction)

The interaction IS the concept: **a lever sets a plant's target output; the plant's actual output crawls toward it at the plant's own built-in pace.** The lag lives inside the control — the learner's thumb is instant, the amber fill chasing it is not.

1. **Discovery (slowness, felt safe):** the learner raises the big plant's lever to the overnight floor. **Reaction:** the thumb jumps with the finger; the output fill creeps up over several seconds; the floor is flat, so it gets there and the town lights fully. Slow — and fine. (Pre-establishes the slowness honestly, with zero hint that it will bite.)
2. **THE discovery (the felt failure):** the evening rush begins; the lever unlocks; the learner slams it to full at the first second. **Reaction:** the target thumb is at the top instantly — and the output fill climbs at the exact same crawl as before while the demand ridge rockets past it. The gap opens, the town dims **in the same frame** the gap crosses the threshold, and at the spike's peak the city is browned out with the lever already at maximum. There was no wrong move to fix. The plant is slow; the spike is fast; the rush wins.
3. **Discovery (the lateness made absurd):** the spike recedes — and *now* the big plant's trace finally tops out. **Reaction:** full power arrives just as the kitchens go quiet; the supply trace peaks visibly *after* the demand ridge, a second mountain drawn late. The learner watches their own command arrive after the need has passed.
4. **Discovery (the rematch):** a second, smaller plant slides in; the same evening replays; the learner chases the identical spike with the new lever. **Reaction:** the fill snaps with the thumb, the supply hugs the ridge, the town stays bright through the peak. Same spike, same seconds — caught. Only THEN are the two kinds named: baseload, peaking.

## 4. Felt vs named vs numbered

- **Felt:** the lag inside the lever (thumb instant, fill crawling) vs the fast lever's fill keeping pace; the demand ridge scrolling as a luminous landscape; the supply as a warm stacked fill beneath it (deep amber baseload band, bright gold peaking layer in run 2); the gap as dark space between fill and ridge; the town strip dimming the same frame the gap opens and recovering as it closes; the late second mountain of run 1; the capacity tick sitting above the spike all along.
- **Named (a beat after felt):** the failure ("The Spike Outran the Plant") only at the brown-out frame; the mechanism of slowness (hot metal and steam) only after the late arrival is seen; **baseload** and **peaking** only after both behaviors are felt, post-rematch; the trade (flexible but costlier per unit) named last, as fact.
- **Numbered (live, relative, ≤2):** `DEMAND` and `SUPPLY` mono chips, 0–100 relative scale (floor ≈ 42, peak = 92 — never megawatts), each with a trend arrow, sampled ~5×/s so the ticking is legible. The gap is *felt* on the town and *seen* in the chart geometry — the chips ride alongside, they never replace the felt thing. **No frequency gauge** (that readout belongs to 4.2/4.5; here the town IS the readout). **No cost number, no ratings table, no number for any qualitative judgment.** The small clock in the day strip is timekeeping chrome, not a quantity (flagged in §13).

## 5. On-screen text — EXACT, beat by beat

Imperatives = Bricolage Grotesque, large, Title Case, ≤5 words. Meaning-lines = Plus Jakarta Sans, de-personified facts (short ones Title Case, long ones sentence case at the smaller body size). Swap = 190 ms fade-out → swap → fade-in. Meaning-lines are state-independent (true whether or not the learner touched the lever).

| # | Phase | Register | Line (verbatim) |
|---|---|---|---|
| T1 | intro | meaning | One day of the city's demand. The floor never empties. |
| T2 | intro | meaning | At six in the evening, the whole city reaches home at once. |
| T3 | floorRaise | imperative | Raise the Big Plant |
| T4 | floorRaise, on matched | meaning | The big plant climbs slowly. The floor of the day moves slower still. |
| T5 | floorHold | meaning | Matched, hour after hour. Supply may not run ahead of the city — the plant holds the floor. |
| T6 | spikeChase1 | imperative | Chase the Spike |
| T7 | spikeChase1, brown-out frame | meaning | The Spike Outran the Plant |
| T8 | lateArrival | meaning | The big plant reached full power after the rush had passed. The town dimmed in between. |
| T9 | lateArrival | meaning | Its pace is set by tonnes of hot metal and steam — no order can hurry it. |
| T10 | rematch | meaning | A second plant arrives — smaller, built differently. |
| T11 | rematch | meaning | The same evening replays. The spike has not changed. |
| T12 | spikeChase2 | imperative | Chase the Same Spike |
| T13 | spikeChase2, fast tracking feedback | feedback | As Fast as the Lever |
| T14 | spikeChase2, catch frame | meaning | The Spike Is Caught |
| T15 | spikeChase2, retry only | imperative | Again — Catch the Spike |
| T16 | caught | meaning | The big plant was always big enough. It was never fast enough. |
| T17 | naming | meaning | The steady plant that carries the floor of the day is called baseload. |
| T18 | naming | meaning | The fast plant that chases the spikes is called peaking. |
| T19 | naming, the trade | meaning | Peaking power is flexible — and costs more for every unit it makes. |
| T20 | synthesis | meaning | Balancing is not just making more. It is making more fast enough, with the right kind of plant. |
| T21 | bridge | meaning | Before every rush, operators line up both kinds in advance — the floor covered, the fast plants ready. |
| T22 | bridge (final, persists) | meaning | And when the balance slips anyway — what breaks first? |
| G1 | run 2, oversupply guard (conditional) | meaning | More Than the City Uses — It Has Nowhere to Go |

T19 names the trade as a consequence (cost per unit) and stops there — **no bill, no 6pm price, no tariff word anywhere** (5.2 pays that off). T21 carries the "who decides" half of the episode question. T22 persists behind the card and Continue and loads 4.5 without revealing the cascade mechanism. G1 fires only if the learner holds the fast plant well above demand (4.1's rule resurfacing; it nudges, never hard-fails).
Card earn brag (overlay one-liner): `The plant that catches the 6pm spike.`

## 6. Beat-by-beat flow (timing + gating)

Text swaps 190 ms. Play length target ≈ 90–140 s. Sim values on the 0–100 relative scale; wall-clock timings in ms unless noted.

| Phase | What happens | Timing / gate |
|---|---|---|
| `intro` (auto) | Entrance reveals (chart frame 0→450 ms, demand ridge draws across 450→1400 ms, town strip +300 ms, big plant + lever +450 ms; slide+scale+fade). Day strip reads 05:00; demand floor 42, flat. Capacity tick visible at 100 from the first frame. T1 at 600 ms; T2 at 3200 ms. | auto-advance at 5400 ms → `floorRaise` |
| `floorRaise` | T3. Big lever live (grab hint pulse). Thumb tracks the finger instantly; output fill ramps at 3.5 units/s. Town brightness = coverage, live from the first frame. `selectionClick` per 10-unit detent. | gate: |supply − demand| ≤ 3 held 1200 ms → T4, lever soft-locks (MATCHED badge) → 2800 ms → `floorHold` |
| `floorHold` (auto) | T5 at 0 ms. Day fast-forwards 05:00 → 17:30 over 6500 ms (demand drifts 42 → 58 with ±2 deterministic wiggle; locked lever auto-tracks the drift — supply stays glued to demand, the 4.1 rule embodied). Dusk grades into the scene. | auto-advance at 7600 ms → `spikeChase1` |
| `spikeChase1` | Sim slows to rush-hour real time. At 0 ms the lever UNLOCKS (badge breaks, glow) + T6. Demand spikes 58 → 92 over 5000 ms, holds 92 ± 1 for 2500 ms, falls to 60 over 4500 ms. Big plant still ramps at 3.5 units/s — slamming the lever at frame 0 yields ≈ 75 at peak: a structural gap ≈ 17. Town dims proportionally from gap ≥ 8, **beginning the same frame**. At gap ≥ 15: brown-out event — T7, `heavyImpact`, brief scene-dim underline, `onCapture('slow_plant_late')`. If the lever is untouched 2500 ms in, T6 re-pulses (scale beat); lines stay true regardless. | structural — phase always plays out; at spike end → `lateArrival` |
| `lateArrival` (auto) | Demand recedes; the big plant's fill keeps climbing and tops out ≈ 1800 ms after the demand peak — the late second mountain drawn on the chart. T8 at 800 ms; T9 at 4200 ms. Big plant then auto-eases back toward the floor. | auto-advance at 7800 ms → `rematch` |
| `rematch` (auto) | T10 at 0 ms; the fast plant slides in from the right (1300 ms) with its own lever — quiet arrival, **no name label, no speed hint**. Big lever locks at the floor (LOCKED badge, 40% opacity, no hit-testing); its band stays as the steady base of the supply stack. At 3200 ms the day rewinds to 17:30 (rewind sweep 900 ms, the run-1 traces clearing) + T11. | auto-advance at 6400 ms → `spikeChase2` |
| `spikeChase2` | T12. The IDENTICAL spike replays (same curve samples). Fast lever live: range 0–40 headroom stacked on the locked base; fill ramps at 45 units/s (reads as instant). During a tracking run (fill within 4 of the ridge for ≥ 1200 ms while demand is moving) T13 shows as feedback. Oversupply guard: supply − demand ≥ 10 held 1500 ms → G1 + town glare/flicker until trimmed. **Catch gate:** gap ≤ 6 AND oversupply ≤ 10 throughout the 2500 ms peak hold → at hold end: T14, `heavyImpact`, success flash, `onCapture('fast_plant_catch')`. Miss → spike rewinds to its start over 800 ms + T15; replays until caught. | gate: catch achieved → 2600 ms → `caught` |
| `caught` (auto) | Spike tail plays out; the learner's fast layer eases down with it (auto-assist after 1500 ms so the tail never stalls). T16 at 1200 ms — the capacity-tick payoff line. | auto-advance at 5200 ms → `naming` |
| `naming` (auto) | Scene calm, both plants idling at the evening floor, stack visible. T17 at 0 ms; T18 at 3400 ms; T19 at 6800 ms. Interaction locked. | auto-advance at 10200 ms → `synthesis` |
| `synthesis` (auto) | T20 alone, full size — the one-concept landing. | auto-advance at 4200 ms → `bridge` |
| `bridge` (auto) | T21 at 0 ms; T22 at 3400 ms, PERSISTS. Scene dims slightly; the breathing town and the stacked fill stay the loudest light. | at 6200 ms → `showCardEarn = true` |
| `done` | Card overlay → "Add to your deck" → Continue CTA (gold pill) → `Navigator.maybePop`. | — |

## 7. Hero & layout (portrait, clutter caps)

- **The one hero: the chase chart** — the scrolling demand ridge with the stacked supply fill glowing beneath it (warm amber/gold, additive bloom at the fill's crest, the brightest thing on screen). The town strip directly below it is the hero's felt consequence — one scene, read together.
- **Recedes:** background near-black `#070A1C` with radial vignette darkest behind the chart; plant dock art dim and dimensional, never brighter than the fill; chips and day strip dark glass; board strip standard gold.
- **Clutter caps for this screen:** hero chart + town strip; **2 levers** (the only interactive elements besides the Continue CTA — well under the 6 cap); **exactly 2 live numbers** (DEMAND, SUPPLY); the current text line; the pinned board strip. Nothing else. No legend, no plant-stat panel, no frequency gauge, no cost meter.
- Portrait order top-to-bottom: header → board strip → top text (fixed height) → chase chart → chips row → town strip → plant dock with levers → CTA seat. Full sketch in §16.

## 8. Reward

**Card: YES** — "Steady vs fast-ramping plants → baseload / peaking" is a row in the curriculum quick-reference table, and the context pack expects an EP4 baseload/peaking card. Proposed copy (shared-infra agent assigns the number and implements the motif painter; section `grid`, accent `#B08CF7`):

- **Front — playful name:** The Floor and the Spike
- **Front — real term (mono specimen label):** `BASELOAD / PEAKING`
- **Front — one-line law:** Steady plants carry the floor of the day; fast plants chase its spikes.
- **Front — kicker:** Make more — fast enough.
- **Back — tie to what was FELT:** You ordered the big plant to full power at the rush's first second — and watched the town dim while it climbed. The fast plant caught the same spike with room to spare.
- **Back — outward reach:** A hydro dam can go from still to full power in about a minute — operators keep a hand near that valve every evening.
- **Linked card:** 03 — No Free Lunch (`energy_trade_off`): baseload/peaking is the controllability trade-off from EP1, returning in its grid costume (a flagged recurring idea, curriculum §8).
- **Motif suggestion:** a demand ridge with a two-band stacked fill — wide steady band, bright thin crest layer.

**Inline fact: none** (info-cards are removed module-wide; deliberate empty slot).

## 9. CER capture hook

`RepaintBoundary(key: _sceneKey)` wraps background + GameWidget; `controller.onCapture = _onCapture` → `captureScenePng(_sceneKey, cropFactor: evidenceByIdFor('episode4_electricity', id)?.cropFactor)` → `_board.capture(id, imageBytes: bytes)`; `EpisodeBoardStrip` pinned under the header with the episode question. Proposed tiles for the EP4 evidence catalog (ids locked here; catalog owner finalizes motifs/crops):

| id | label (≤3 words) | caption (one line) | relevant? | onCapture fires at |
|---|---|---|---|---|
| `slow_plant_late` | Spike Outruns Plant | Ordered to full power at the first second, the big plant arrived after the rush — the town dimmed. | RELEVANT | run 1, the brown-out frame (gap ≥ 15 at the spike peak, with T7) |
| `fast_plant_catch` | Fast Plant Catches | The peaking plant climbed as fast as the lever moved — the same spike, fully covered. | RELEVANT | run 2, end of the covered peak hold (with T14) |

Suggested cropFactor for both: `Rect.fromLTRB(0.04, 0.10, 0.96, 0.64)` normalized — chart + town strip, so the tile shows cause (gap / coverage) and consequence (dim / bright town) together. No distractors proposed from this beat (§2).

## 10. Build notes

- **Flame `GameWidget`** for the living scene (scrolling chart, stacked fill, town strip, plant dock, ambient motes) — this is a multi-layer animated world, the trace_it_back / source_personalities pattern. **Flutter overlay** for chrome: header, board strip, FadeSwap top text, the two `OutputLever` widgets, chips, CTA, card overlay. GameWidget built once in initState; `Color(0x00000000)` background.
- **No Forge2D.** All motion is controlled: ramps are explicit `rate × dt` integrations in `controller.tick`; the brown-out dip is a per-frame function of coverage, never a decayed value.
- Controller-owns-geometry: `BaseloadPeakingController extends ChangeNotifier` owns the day sim, both plant ramps, phase machine, and all factor-based anchors via `setStageSize`. Components are pure renderers reading getters.
- Levers are Flutter (precision control): thumb = target, follows the pointer with zero smoothing; fill = actual output from the controller. Detent haptics via `HapticFeedback.selectionClick`; `heavyImpact` at T7 and T14; `lightImpact` inside `_onCapture`.
- Demand curve: deterministic piecewise model in `dispatch_day.dart` (no randomness across runs — run 2 must replay identical samples; the wiggle is a fixed multi-octave function of dayT, source_personalities-style).
- Chips: `displayDemand` / `displaySupply` sampled at 5 Hz into ValueNotifiers (shipped legibility pattern), mono font, dark glass, trend arrows.
- Audio: **silent by default** (shipped-acceptable); optional soft BGM ≤ 0.2 via the audioplayers/mixWithOthers pattern if the integrator wants parity with hand_crank.
- Reduced motion (`MediaQuery.disableAnimations`): calm motes, no flourish on reveals, rewind sweep becomes a fade — but the same-frame brown-out dip and the ramp-lag are pedagogy and are NEVER softened.
- Persistence: none beyond the evidence board and card store (both shared infra).
- Verification: `fvm dart analyze lib/screens/missions/baseload_peaking` clean; analyze each imported shared file individually.

## 11. Acceptance criteria (pedagogy as testable checks)

1. **Discoverable from interaction alone:** with all text hidden, dragging the big lever shows the thumb instant and the fill crawling (≈ 3.5 units/s); dragging the fast lever shows the fill keeping pace (≤ 150 ms perceived lag). The two plants' natures are readable from the controls before any line is read.
2. **The run-1 failure is structural, not ergonomic:** with the lever slammed to 100 at the unlock frame, peak supply ≈ 75 vs demand 92 (gap ≥ 15) and the brown-out fires. The lever thumb itself never lags the finger (test: thumb position == pointer position every frame).
3. **Too slow, never too small:** the capacity tick at 100 is visible above the 92 spike from `intro` onward; T16 appears only after the rematch success.
4. **Same-frame consequence:** the town strip's dimming begins in the same frame `gap` crosses 8 (smoothing ≤ 120 ms, no eased delay); recovery likewise tracks coverage.
5. **The late arrival is witnessed:** in run 1 the supply trace visibly peaks AFTER the demand ridge (≥ 1.5 s later on screen), and T8 fires only after that late peak is drawn.
6. **Held-constant is visible:** run-2 demand samples are bit-identical to run 1; T11 is shown; the big lever is visibly LOCKED at the floor through run 2 and its band never moves.
7. **Name-last:** "baseload" and "peaking" appear nowhere (text, labels, badges, art) before `naming`; the fast plant arrives unlabeled and undescribed except T10.
8. **Run 2 is earned:** success requires gap ≤ 6 and oversupply ≤ 10 through the peak hold; a miss replays the identical spike (T15) until caught; `fast_plant_catch` fires exactly once, on the first success.
9. **Numbers discipline:** exactly 2 live numbers (DEMAND, SUPPLY), relative 0–100, trend arrows, 5 Hz sampling; no frequency gauge, no cost number, no ratings table, no plant stats anywhere.
10. **EP5 stays unspoiled:** no occurrence of "price", "bill", "tariff", "₹", or any cost number; the only cost reference is T19's per-unit fact.
11. **Captures:** `slow_plant_late` and `fast_plant_catch` fire at exactly the §9 moments, idempotently; board strip shows the episode question all activity.
12. **Text registers:** imperatives ≤ 5 words Title Case; meaning-lines de-personified facts, state-independent; 190 ms fade-out → swap → fade-in (never cross-fade); T22 persists behind card and CTA.
13. **Flow integrity:** completion = Continue → `Navigator.maybePop`; card overlay uses `CollectibleEarnOverlay(showMascot: false)` referencing the shared-infra card constant; `MediaQuery noScaling` wrapper present; reduced-motion respected per §10; `fvm dart analyze` clean on the activity dir.

## 12. Anti-patterns to avoid (this activity)

- **A frequency gauge or balance meter** — that readout belongs to 4.2/4.5; here the town dimming IS the readout, and a third number would breach the cap.
- **Softening the brown-out** with a premium fade or grace period — the dip is the discovery.
- **A laggy lever thumb** — if the control itself feels sticky, the struggle becomes ergonomics, not the plant. Lag lives ONLY in the output fill.
- **Pre-spoiling:** never call the big plant "slow" or the new plant "fast" before each is felt (T10 says only "smaller, built differently"); never hint run 2 will succeed.
- **Letting run 1 be winnable** by pre-ramping: the lever is matched-locked until the rush begins (itself the 4.1 rule, stated by T5) — do not "fix" this by quietly raising the ramp rate until anticipation wins.
- **Plant-stat panels, a pros/cons table, or kind labels** ("NUCLEAR", "GAS") — the two plants are characterized by behavior only; real-world examples live on the card and in 5.2.
- **Auto-winning the rematch** (animating the fast fill to the ridge without the learner tracking) — the catch must be theirs; the only assist is the post-success tail ease-down.
- **Dispatch-sim creep:** no third plant, no plant-picker, no budget — one slow plant, one fast plant, one spike.
- **Connecting cost to the evening price or the learner's bill** — that is 5.2's payoff.

## 13. Open decisions

1. **Tuning constants** (spike slope 58→92/5 s, big ramp 3.5/s, fast ramp 45/s, gap thresholds 8/15/6, oversupply 10): defaults specified; tune on device so the run-1 peak gap reads 15–20 units and run-2 first-try success rate feels earned but common.
2. **Clock readout** in the day strip (e.g. `17:45`): kept as timekeeping chrome by default; cut it if it reads as a third number on small phones.
3. **Run-1 untouched-lever handling:** default is the re-pulsing T6 only (lines are state-independent so the beat still teaches); an auto-set-to-full fallback at the spike midpoint is possible but rejected by default (the system must never move the learner's control).
4. **Oversupply guard strictness in run 2:** default is G1 + glare/flicker (nudge only); escalate to blocking success (already implied by the ≤ 10 catch condition) but never to a hard fail-state.
5. **Fast plant art:** default a compact gas-turbine hall (peaker); hydro's instant valve lives on the card back instead. Catalog owner may swap.
6. **BGM:** silent by default; optional ≤ 0.2 loop if EP4 gets episode-wide audio.

---

## 14. State machine sketch

```dart
enum BPPhase {
  intro, floorRaise, floorHold, spikeChase1, lateArrival,
  rematch, spikeChase2, caught, naming, synthesis, bridge, done,
}

enum BPLine { none, t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11,
  t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, g1 }
```

- **ValueNotifiers:** `phase: ValueNotifier<BPPhase>`; `line: ValueNotifier<BPLine>` (style flag imperative/meaning/feedback resolved in copy table); `displayDemand: ValueNotifier<int>`, `displaySupply: ValueNotifier<int>` (5 Hz sampled, with trend enums); `bigLeverState: ValueNotifier<LeverState>` (`hidden/live/matched/locked`); `fastLeverVisible: ValueNotifier<bool>`; `showCardEarn: ValueNotifier<bool>`; `showContinue: ValueNotifier<bool>`.
- **Hot-path getters** (read by Flame layers each frame): `dayT` (sim hours), `demand`, `supplyBig`, `supplyFast`, `supply` (= big + fast), `coverage`, `gap`, `townBrightness` (coverage^1.4, ≤ 120 ms smoothing), `scrollX(now-line fixed at 0.68w)`, `demandTrace`/`supplyTrace` ring buffers, entrance reveal envelopes (`chartReveal`, `townReveal`, `dockReveal`, `fastPlantReveal`), `flashIntensity`, `duskBlend`.
- **Inputs:** `onBigLeverChanged(double target01)` / `onFastLeverChanged(double target01)` — set targets only; ignored unless the lever's state is `live`. Detent crossing → `onLeverTick` → `selectionClick`.
- **Timers:** `_schedule(ms, fn)` (shipped pattern) drives every auto-advance in §6's table; spike segment timing driven by simulated `dayT` advanced in `tick(dt)` at per-phase rates (`floorHold` ≈ 1.9 h/s wall; spike window ≈ 0.0046 h/ms ≈ rush-hour real time).
- **Gating conditions:** `floorRaise → floorHold`: `(supply - demand).abs() <= 3` continuously for 1200 ms. `spikeChase1`: none (structural; plays out). Brown-out event: first frame `gap >= 15` → T7 + `heavyImpact` + `onCapture('slow_plant_late')` (latched once). `spikeChase2` catch: over the 2500 ms peak-hold window, `gap <= 6 && (supply - demand) <= 10` every sampled frame → success at window end (T14 + capture); else rewind-and-replay (T15), unlimited retries. `bridge` end → `showCardEarn = true`; card `onDone` → `showContinue = true`; Continue → `Navigator.maybePop`.
- **Hooks:** `onDiscovery` (T7/T14 heavyImpact), `onCapture(String id)`, `onLeverTick`, `reducedMotion` set from MediaQuery each build.

## 15. File plan

```
lib/screens/missions/baseload_peaking/
├── baseload_peaking_screen.dart            — shell: noScaling MediaQuery, header (title "The 6pm Rush",
│       mono eyebrow "EPISODE 4 · KEEPING THE LIGHTS ON"), EpisodeBoardStrip(episode4 question),
│       FadeSwap top text (fixed height), RepaintBoundary(_sceneKey) wrapping background + GameWidget,
│       OutputLever overlays, chips row, fixed-height CTA seat, CaptureFlash, CollectibleEarnOverlay
├── state/baseload_peaking_controller.dart  — ChangeNotifier: phase machine, _schedule timers, plant
│       ramp integration, gap/coverage/townBrightness, trace ring buffers, capture/haptic hooks
├── state/dispatch_day.dart                 — deterministic demand model: piecewise day (floor 42 →
│       drift 58 → spike 92 → fall 60) + fixed multi-octave wiggle; rewind/replay transport
├── config/bp_tuning.dart                   — BPTune: all geometry factors (§16), ramp rates, sim
│       speeds, thresholds (8/15/6/10), phase timings (§6), palette accents
├── config/bp_copy.dart                     — BPLine → verbatim strings + register flags (§5 table)
├── game/baseload_peaking_game.dart         — FlameGame: transparent bg, adds layers back→front,
│       onGameResize → controller.setStageSize, update(dt) → controller.tick(dt)
├── game/components/ambient_layer.dart      — vignette glow behind chart, ≤ 20 motes, dusk blend
├── game/components/chase_chart_layer.dart  — THE HERO: demand ridge (scrolling traces), stacked
│       supply fill (baseload band + peaking layer, additive crest bloom), now-line, capacity tick
├── game/components/town_strip_layer.dart   — building row + window grid; brightness = townBrightness
│       same-frame; brown-out and glare states
├── game/components/plant_dock_layer.dart   — big plant art (cooling stack, slow idle steam), fast
│       plant slide-in art (turbine hall), per-plant activity glow ∝ output
└── widgets/output_lever.dart               — Flutter lever: instant thumb (target), lagging fill
        (actual), detents + badges (MATCHED / LOCKED), grab hint
└── widgets/energy_field_background.dart    — static dark vignette variant (copy-adapt from shipped)
```

Registration in `activityRegistry.dart` and wowConcepts wiring are central-integration work — NOT this build. Evidence catalog entries (`slow_plant_late`, `fast_plant_catch`) and the card constant belong to shared infra; this build only calls the ids and references `k<FloorAndSpike>Card` (final name per shared infra).

## 16. Scene sketch (portrait, top-to-bottom, factor-based)

Stage = the Expanded scene area below the fixed chrome (header ≈ 56 px, board strip, top text h = 96). All anchors are factors of stage size (w, h) set in `BPTune` via `setStageSize`; no fixed pixel layouts.

```
┌──────────────────────────────────────────┐
│ header: ‹back›  THE 6PM RUSH             │  Flutter chrome (fixed)
│ EpisodeBoardStrip — EP4 question pinned  │
│ top text (imperative / meaning, h=96)    │
├──────────────────────────────────────────┤  ← stage top
│ CHASE CHART (hero)                       │  y: 0.04h–0.44h · x: 0.05w–0.95w
│   capacity tick ──────── at value 100    │  thin mono dash + tick label-less
│   demand ridge (cool white-blue crest)   │  traces scroll left; now-line at x=0.68w
│   supply fill: baseload band (amber) +   │  additive bloom at fill crest (brightest px)
│   peaking layer (bright gold, run 2)     │  day-strip clock top-right (mono, small)
├──────────────────────────────────────────┤
│ chips row: [DEMAND 92 ▲]  [SUPPLY 75 ▲]  │  y≈0.47h · two mono dark-glass chips
├──────────────────────────────────────────┤
│ TOWN STRIP                               │  y: 0.52h–0.66h · 8–9 buildings, window
│   windows brightness = coverage          │  grid; brown-out dim / glare flicker
├──────────────────────────────────────────┤
│ PLANT DOCK                               │  y: 0.70h–0.98h
│  [BIG LEVER]  big plant art   fast plant │  big plant center-left ≈ x 0.34w
│   x≈0.10w     (stack+steam)   art ≈0.78w │  fast plant slides in at `rematch`
│   w≈0.13w                    [FAST LEVER]│  fast lever x≈0.90w, hidden until run 2
│   h≈0.24h                                │  levers: instant thumb + lagging fill
├──────────────────────────────────────────┤
│ CTA seat (h=84, empty until done)        │  Flutter chrome (fixed)
└──────────────────────────────────────────┘
```

Vignette darkest behind the chart; the supply fill's crest is the single brightest element, the lit town second. Levers sit in thumb reach; on very small phones the dock compresses (`h ≥ 0.22h` floor) before the chart ever shrinks below 0.36h — the hero keeps the majority of the frame.
