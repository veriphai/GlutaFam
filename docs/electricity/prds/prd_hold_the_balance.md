# PRD — Supply Must Match Demand, Live, Every Second
### howwow · Episode 4 "Keeping the Lights On" · beat 4.1 · registry id `hold_the_balance` · `HoldTheBalanceScreen` · evidence episode `episode4_electricity`

Working title: **Hold the Balance.** Binding context: `docs/electricity/context_pack.md` (the covenant), `docs/electricity/architecture_reference.md`, curriculum §1–§9 + §13 + beat 4.1, and `prd_make_your_case_ep4.md` (the LOCKED EP4 evidence catalog — this beat is reconciled to it; see §9). No mascot, no Voltix, no info-cards. One voice = the on-screen text in two registers (short imperatives + de-personified meaning-lines).

---

## 1. One-concept statement
**There is no buffer — production and consumption must be equal continuously.** Whatever the city uses this second, the plant must make this second; over or under, it tips instantly, because nothing in the grid stores electricity. (If it needs an "and," it is two activities — this is exactly one: *no buffer → live matching.* Frequency is **why** it is this tippy and belongs to 4.2; this beat leaves the learner asking that question, not answering it.)

## 2. Guiding-question link + CER contribution
- **Episode question** (pinned on the board strip the whole activity, verbatim): **"The plant is making almost exactly what the whole city uses this very second — who decides that, and what happens at the 6pm rush?"**
- This is EP4's **opening** beat. **Inherits (state explicitly, per the chain rule):** the learner has *felt* "nothing is stored" at hand scale three times already — the crank dying the instant you release it (Prologue P.1), the still magnet making nothing (1.1 b1), the supply cutting the instant production stops. This beat **scales that same instant-death to a whole city** and converts it from a fact into a *job*: someone must hold the match, live, forever.
- **Pins (held constant, visibly — see §4):** the network itself — one plant, one wire run, one city, unchanged the entire activity; demand is autonomous (never a control); the learner's ONLY handle is production. The asymmetry "you move supply, the world moves demand" is on screen continuously.
- **Sets up 4.2:** the learner leaves asking *"why is it THIS tippy?"* The spinning-mass / frequency answer is deliberately withheld here.
- **CER contribution — ONE relevant tile (reconciled to the locked EP4 catalog).** `demand_never_still` (label *Never Holds Still*) is captured at the **let-go discovery frame** (M5): production froze, demand walked away, the city tipped. It carries the **"every second / nothing buffers the grid"** clause of the episode claim. It is **relevant**, not a distractor.
  - **Distractor flags:** this beat contributes **no distractors**. EP4's exactly-2 distractors live elsewhere (`lockstep_spin` at 4.2, `breaker_trip` at 4.5), per the EP4 CER owner doc.
  - **Reconciliation note (binding):** an earlier draft proposed a second tile, `surge_nowhere_to_go`, at the M3 surplus tip. The EP4 CER owner **DROPPED it as redundant** (the no-buffer clause needs one tile, and `demand_never_still` carries both no-buffer and continuity). **M3 keeps its meaning-line and its hard-gated surge**, but the `onCapture` call at M3 is **removed**. This activity fires **exactly one** capture: `demand_never_still` at M5.

## 3. The felt discovery (discovery → reaction)
The interaction *is* the concept: one hand holding a level that the world keeps trying to walk away from. Three felt beats, none of them told:
- **Discovery 1 — matching is possible.** The learner raises the production column → *reaction:* the plant glows, warm pulses glide up the wires, the city's lit windows settle into an even warm glow the instant MAKE meets USE. Balance has a *look*: steady warm light.
- **Discovery 2 — the tip is instant, both ways.** Demand starts wandering on its own (windows blink on and off across town). The frame the gap crosses the band: **under** → every lit window drops to a brown, unsteady dim that same frame; **over** → the town flares harsh white, streetlamp halos blow out, a stray bulb pops. **No grace period in either direction — that absence of grace IS the felt "no buffer."**
- **Discovery 3 — THE discovery: continuity (heavyImpact).** Prompted "Now Let Go," the learner releases the column. Production **freezes** where it was; demand keeps moving; within ~3–5 s the city tips. *A perfect match doesn't stay matched; nobody gets to leave.* This is the captured moment.

## 4. Felt vs named vs numbered
- **Felt:** balance = even warm town glow; deficit = same-frame brown-out deepening with the gap; surplus = same-frame harsh white surge flooding the wires and blowing streetlamp halos; demand rising = windows blinking on across town (the 6pm rush is a *visible wave* of windows + the sky deepening to evening); production = plant glow + wire-pulse rate; the let-go freeze (desaturated handle, MAKE number stuck) while USE keeps ticking.
- **Named:** **demand** and **supply** land at M4, *after* both tips are felt — the readout chips relabel `USE → DEMAND`, `MAKE → SUPPLY` in the same beat (the name lands on the felt thing). **The grid** is claimed last (M7), only after the whole connected machine has been operated. No other terms. **No frequency, no Hz, no baseload/peaking, no price** — those belong to 4.2 / 4.4 / EP5.
- **Numbered (live, relative, exactly 2):** `USE` (demand, ~35–95) and `MAKE` (supply, 0–120) on a shared relative scale (the city's quiet evening ≈ 50). Mono chips, dark glass, sampled ~5×/s so they tick legibly. **No ratings table. No number for any qualitative judgment. No clock, no third number** — evening is the sky, not a timestamp.
- **Held constant, visibly:** the plant, the wire run, and the city's buildings never change, move, or upgrade; only window lit-count (demand) and plant output (the learner) vary. Demand accepts **no** pointer input — the asymmetry is on screen the whole time, which is *how* "held constant" is shown.

## 5. On-screen text — EXACT, beat by beat
Imperatives = Bricolage Grotesque large; meaning-lines = Plus Jakarta Sans (short ones Title Case, long ones sentence case, smaller). Swap = 190 ms fade-out → swap → fade-in (never cross-fade).

| # | Register | Line (verbatim) | Trigger |
|---|---|---|---|
| T1 | imperative | `Power the City` | entry, after entrance reveals (~900 ms) |
| M1 | meaning | `Steady light — the city uses exactly what the plant makes.` | first time in band ≥ 1200 ms |
| T2 | imperative | `Hold the Balance` | 2200 ms after M1; wander begins |
| M2 | meaning | `Too little — the whole city dims this very second.` | first deficit tip sustained ≥ 500 ms |
| M3 | meaning (long) | `Too much — with nowhere to go, the extra floods the wires as a surge.` | first surplus tip sustained ≥ 500 ms |
| T3 | imperative | `The Rush — Keep Up` | rush event start (windows wave on, demand ramps hard) |
| M4 | meaning (long) | `What the city uses is demand. What the plant makes is supply.` | both M2 and M3 witnessed AND in band ≥ 1500 ms after the rush peak; chips relabel on this line |
| T4 | imperative | `Now Let Go` | 2600 ms after M4 |
| M5 | meaning | `Demand never waits — the balance must be held every second.` | the let-go tip frame (THE discovery; heavyImpact; capture fires here) |
| T5 | imperative | `Bring It Back` | 2400 ms after M5; column unlocks |
| M6 | meaning (long) | `Electricity is made and used in the same instant — nothing along the way stores it.` | re-balanced ≥ 1200 ms after T5 |
| M7 | meaning (long) | `Every plant, every line, every home — one connected machine: the grid.` | 3200 ms after M6 (synthesis) |

Rules check: every imperative ≤ 5 words ("Keep Up" is the imperative in T3; "The Rush —" names the on-screen event). **M2 names the consequence** (the city dims, now); **M3 names the destination** (floods the wires as a surge) — never a behaviour/ending; no rhyme, no narration-to-a-child. "demand"/"supply" appear in no line before M4; "the grid" appears in no line before M7. **Card earn copy:** brag (one-liner) `You held a whole city level — by hand.`; eyebrow `NEW CARD`. No other text exists anywhere in the activity.

## 6. Beat-by-beat flow (timing in ms + gating)
1. **Intro (0–900 ms):** entrance reveals — city silhouette fades up 0→450 ms, plant + wires slide in 150→600 ms, column appears 300→700 ms. Demand steady at 52; supply starts at 18 → **the city opens brown** (under-supplied — the learner's first sight is a deficit, unexplained, an invitation to fix it). Column live immediately. **T1 at 900 ms.**
2. **Power up (learner-paced):** drag the column up. Same-frame: plant glow + wire-pulse rate ∝ supply; the city steps brown → even warm the frame `|supply − demand| ≤ band` (band = ±6). In band ≥ 1200 ms → **M1** + `selectionClick`. `selectionClick` per 10-unit detent crossing of the column (all phases).
3. **The wander (T2):** 2200 ms after M1, demand begins a deterministic multi-octave wander (gentle ±5 ramping to ±12 over ~10 s; never a tidy sine). The learner chases. Tip gating: deficit beyond band ≥ 500 ms → first time fires **M2**; surplus beyond band ≥ 500 ms → first time fires **M3** (line only — **no capture**; see §9). Tips are **hard gates**: the town's light-quality state switches the same frame the band is crossed (a visible step, then depth ∝ gap).
4. **Guarantee events (scripted, demand-side — the struggle stays about the wiggle, never control ergonomics):**
   - **wander +6 s — the drop:** an industrial block's windows go out, demand steps **−14 over 1.2 s.** A learner tracking well is left over-producing → the surplus tip (M3) is guaranteed if not yet felt.
   - **wander +14 s — the rush:** **T3**; a wave of windows blinks on across the whole town, the sky deepens to evening, demand ramps **+32 over 2.6 s.** Too fast to track perfectly → the deficit tip (M2) is guaranteed. Plateau ~4 s, then relax −10 over 8 s.
5. **Naming (M4):** gate = M2 felt AND M3 felt AND in band ≥ 1500 ms after the rush peak. Chips crossfade `USE → DEMAND`, `MAKE → SUPPLY` (190 ms) with one soft pulse each.
6. **THE LET-GO (T4 → M5):** **T4 at 2600 ms after M4.** Gate: pointer released ≥ 600 ms → the handle desaturates + **locks** (production frozen; MAKE number stops moving), and demand begins a walk-away ramp: **±14 over 3.2 s** in whichever direction diverges from the frozen supply (so the tip is guaranteed either way, honestly). Out of band ≥ 400 ms → **THE DISCOVERY**: discovery flash ~700 ms envelope, `heavyImpact`, **capture `demand_never_still`** at the tip frame, **M5**. Input is ignored from walk-away start until T5 (the lock IS the lesson; it lasts < 6 s).
7. **Recovery (T5):** **2400 ms after M5** the column unlocks; the learner rebalances the city themselves (agency closure — the synthesis lands over a city they rescued). In band ≥ 1200 ms → **M6**.
8. **Synthesis → card:** **M7 at 3200 ms after M6.** 2600 ms later → `showCardEarn = true` → `CollectibleEarnOverlay` (card §8, `showMascot: false`). `onDone → onCardCollected` → `canFinish = true`, Continue CTA appears in its fixed seat. The wander continues at gentle amplitude for free play.
9. **Finish:** Continue → `Navigator.maybePop(context)` (any pop = completion; no payload).

**Reversibility / idempotence:** the column is always reversible (except the < 6 s let-go lock); phases never regress; M2 / M3 / the capture / the card fire once each. Straight-through play ≈ **90–140 s**.

## 7. Hero & layout (with clutter caps)
- **The one hero:** the living city — a window grid whose *lit count* breathes with demand and whose *light quality* (warm even `#FFE9B8` / brown dim / harsh surge white) is the entire balance readout. The brightest, most-alive thing on screen in every state except deep brown-out, where its darkness is the statement.
- **What recedes:** near-black `#070A1C` base, radial vignette darkest behind the city; dusk sky low-saturation; the plant and wires in cool grid purple-blue (clearly machinery, never outglowing the town); the production column cool glass with a warm fill core; chrome on glass `0x14FFFFFF` / borders `0x26FFFFFF`; ≤ 20 ambient motes.
- **Portrait layout (top → bottom):** header → `EpisodeBoardStrip` (EP4 question) → instruction banner (fixed h 96) → stage (sky upper third; city band centre, full width; plant bottom-left with catenary wires rising to the city; production column pinned to the right edge, large; USE/DEMAND chip upper-left of the city, MAKE/SUPPLY chip beside the column top) → fixed-height CTA seat (84).
- **Clutter caps (hard):** **1 hero**; **3 interactive elements** (production column, back button, Continue) ≤ 6 ✓; **exactly 2 live numbers**; the current text line; nothing else. **No balance needle, no meter, no tank, no battery, no clock, no score** — the town IS the readout.

## 8. Reward
**Card: YES.** This concept is a row in the curriculum quick-reference table ("The whole interconnected system → **the grid** → Ep 4"). Proposed copy for the shared-infra catalog (number / `deckTotal` assigned centrally; the build agent references the future `kTheGridCard` constant only, never defines it):
- `id: 'the_grid_no_buffer'` · **cardName: `The Tightrope`** · **realName (mono specimen label): `THE GRID`**
- **law (one line):** `Electricity is made and used in the same instant — the grid stores none of it.`
- **kicker:** `Supply must equal demand, live, every second.`
- `section: CardSection.grid` (accent `#B08CF7`) · proposed `motif: heldBalance` — a hand-held level line over a city's glow, a wandering demand trace beneath it.
- **Back — tie to what was FELT:** `You held the column against a city that never sat still — and the moment you let go, the lights tipped within seconds.`
- **Back — one outward reach:** `Real control rooms hold this same balance for a billion switches at once, around the clock — there is no pause button.`
- **Linked card:** `The Grid Is a Mix` (Card 05 — the same grid, first met as a mix of sources, now claimed as one live machine; shared infra confirms the link). The EP4 CER synthesis card (`The Control Room` / SYSTEM OPERATION) in turn links *back* to this card as "the law the operator's job exists to serve" — so this card owns "made and used in the same instant," and never restates SYSTEM OPERATION's "operators forecast and dispatch."
- **Inline fact: none** — deliberate empty slot; anything here would either restate the law or pre-spoil 4.2's "why so tippy."

## 9. CER capture hook
**Exactly ONE capture** (reconciled to the locked EP4 catalog, §3.1 of `prd_make_your_case_ep4.md`):
- `demand_never_still` · label `Never Holds Still` · caption `Production froze for four seconds — demand walked away and the city tipped.` · accent `#FFD27A` (warm energy) · sourceLabel `ACT 4.1` · **relevant: true** · **fires on the M5 discovery frame** (locked desaturated column, diverged USE/SUPPLY chips, tipped town). Suggested `cropFactor ≈ Rect.fromLTRB(0.04, 0.18, 0.98, 0.86)` (city + frozen column + both chips; final value tuned at integration — owned by the EP4 catalog).
- **Motif fallback (per the EP4 catalog, `demandNeverStill`):** a frozen, desaturated supply column beside a demand trace pulling away from it; a dimmed window-grid band beneath.
- **No second capture.** The M3 surplus surge remains a hard-gated felt consequence with its meaning-line, but does **not** call `onCapture` (the EP4 owner dropped `surge_nowhere_to_go`).
- **Wiring (verbatim pattern from `trace_it_back`):** stage wrapped in `RepaintBoundary(key: _sceneKey)` (background + GameWidget only — banner / CTA / strip excluded so the capture is clean); `controller.onCapture = _onCapture` → `HapticFeedback.lightImpact()` → in a post-frame callback `captureScenePng(_sceneKey, cropFactor: evidenceByIdFor(kEpisode4Id, id)?.cropFactor)` → `_board.capture(id, imageBytes: bytes)`. `EpisodeBoardStrip` pinned under the header with the EP4 question 100% of the activity.

## 10. Build notes
- **Rendering: Flame `GameWidget` + Flutter overlay** (the `source_personalities` pattern — this is a living town scene: window grid, sky, wire pulses, surge / brown states, motes). The single high-precision control (the supply column) is a **Flutter overlay widget** above the GameWidget, not a Flame component. **No Forge2D** — all motion is driven from the controller tick; tips are hard gates in the update path, never decay / momentum.
- **Controller-owns-geometry:** `HoldBalanceController extends ChangeNotifier`; `setStageSize` from `onGameResize`; ALL anchors = factor × stage size (`HBTune`). GameWidget built **once** in `initState`. Gesture stays in Flutter: a transparent `Listener` (or the slider widget itself) forwards the column drag to the controller.
- **Demand model (deterministic, suspenseful — never a tidy loop):** `demand(t) = 52 + 6·sin(2π·t/9.5 + φ₁) + 3.4·sin(2π·t/3.7 + φ₂) + 1.8·sin(2π·t/1.6 + φ₃)`, with an amplitude envelope 0→1 over the first 10 s of the wander, plus the scripted drop / rush / walk-away ramps layered on top (pure functions of phase-relative time in `demand_model.dart`, after the shipped multi-octave gust pattern in `town_sim_tuning.dart`). **Supply has no carryover term** — it is always the instantaneous slider value; running high then dropping banks nothing.
- **Slider:** positional, 1:1, **zero** smoothing / lag / spring — the struggle must be the wiggle, not the control. Full travel ≈ 0.55 × stage height; fat hit area (≥ 56 px wide). `selectionClick` per 10-unit detent.
- **Tip rendering:** `balanceState ∈ {balanced, brown, surge}` computed each frame from `error = supply − demand` vs band; the state **switch is a same-frame step** (window brightness multiplier drops to 0.55 / white-shift + bloom overshoot applied immediately), then `brownDepth` / `surgeDepth = clamp((|error| − band)/30)` deepens it continuously. At `surgeDepth > 0.6`, 2–3 scattered windows pop white then go dark (blown bulbs — a true consequence, polish-flagged §13). Reduced motion: calmer motes and fades elsewhere, **but the tip step stays instant**.
- **Numbers:** `displayUse` / `displayMake` sampled ~5×/s, integer; USE ticks with the lit-window count, MAKE with the plant glow (numbers ride alongside the scene, never replace it).
- **Haptics:** `selectionClick` detents / chip relabel; `heavyImpact` at the M5 discovery; `lightImpact` on the capture; medium impact lives inside the card overlay already. **Audio: silent** (matches shipped EP siblings; open decision §13).
- `MediaQuery(...textScaler: TextScaler.noScaling)` wrapper; respect `MediaQuery.disableAnimations`; instruction banner fixed h 96 with the 190 ms fade-out → swap → fade-in.
- **File-surface rule:** write ONLY inside `lib/screens/missions/hold_the_balance/`. `kEpisode4Evidence`, `kEpisode4Id` (`'episode4_electricity'`), the EP4 question constant, and `kTheGridCard` are owned by shared infra — code against the names and report in the final message if absent at build time; **never edit shared files**; the `activityRegistry.dart` entry is central integration.
- **Verify:** `fvm dart analyze lib/screens/missions/hold_the_balance` clean; `fvm dart analyze` on each imported shared file resolves; small-phone portrait sanity; reduced-motion pass.

## 11. Acceptance criteria (pedagogy as testable checks)
1. **Discoverable from interaction alone:** with top-text suppressed (debug flag), a fresh user moving the column reads the concept unaided — match → even warm city; under → instant brown; over → instant harsh surge; and the city visibly refuses to hold still.
2. **The tip is a hard gate:** from the frame `|supply − demand|` crosses the band, the town's light-quality state switches within 1 frame (≤ 50 ms), **both directions**, with NO eased onset; identical under reduced motion.
3. **No buffer exists anywhere:** production is an instantaneous value (running high then dropping leaves zero carryover); no battery, tank, charge bar, or accumulation visual exists on screen; over-production never "banks" anything for the rush.
4. **The struggle is the concept:** the column maps 1:1 with no momentum / smoothing; during the gentle wander a median adult can stay in band ≥ 80% of the time, while the drop and the rush each force a tip even for good play (tuned on device).
5. **Demand is autonomous:** no pointer input anywhere changes demand; the drop and rush fire on schedule as in-scene events (windows going out / waving on), not as text announcements; the supply column is the only interactive control besides back / Continue.
6. **Both catches guaranteed and once-only:** M2 and M3 each fire exactly once, at the first sustained tip of their direction; the scripted drop and rush guarantee both occur before M4 can gate.
7. **Let-go discovery:** after T4 + release, the handle visibly freezes (desaturated, MAKE number stuck) while USE keeps ticking; the tip arrives ≤ 5 s; `heavyImpact` + flash + the **`demand_never_still`** capture fire on the tip frame; input is dead from walk-away start until T5 and live again at T5.
8. **Numbers discipline:** exactly 2 live numbers, relative scale, co-varying with the scene; no clock, no Hz, no percent, no third number ever; no ratings table.
9. **Text exactness:** all 12 lines verbatim from §5; imperatives ≤ 5 words; M2 names the consequence, M3 the destination; "demand"/"supply" first appear at M4 (with the chip relabel); "the grid" first appears at M7; chips read USE/MAKE before M4 and DEMAND/SUPPLY after.
10. **Scope fences (no pre-spoiling adjacent beats):** no frequency / spinning-mass / Hz (4.2), no routine / TV-schedule explanation of the rush (4.3), no baseload / peaker words (4.4), no price (EP5), no cascade beyond this one city (4.5).
11. **Capture:** **exactly one**, id `demand_never_still`, at the M5 frame, idempotent; M3's surge is NOT captured; the board strip shows the EP4 question for 100% of the activity.
12. **Contract:** card overlay → Continue → `Navigator.maybePop`; `const HoldTheBalanceScreen()` constructible with no arguments; analyzer clean on the activity dir; straight-through run 90–150 s on device.

## 12. Anti-patterns (this activity)
- **A balance needle / meter** — the consequence lives in the town's light; a tilt gauge is a meter where a felt consequence belongs.
- **Any grace period at the band edge** — an eased onset or forgiveness window fakes a buffer, the exact thing this beat denies.
- **Slider physics** — lag, smoothing, momentum, or a tiny thumb make the struggle about ergonomics instead of the wiggle.
- **A storage affordance** — a battery icon, charge bar, or "save it for the rush" instantly falsifies the one concept.
- **A tidy sine for demand** — the wander must feel alive (multi-octave + events) or "never holds still" reads as a pattern to memorise.
- **Pre-spoiling 4.2** — no Hz, no spinning imagery, no "the machines slow down"; the learner must leave with the question, not the answer.
- **Score / timer / survival framing** — no "you lasted 42 s"; the system responds, it never grades.
- **A premium fade on the tip** — the same-frame step IS the felt absence of a buffer.
- **Explaining the rush in text** — the wave of windows and the evening sky carry it; naming routines is 4.3's job.
- **Symmetric surge read as "brighter is better"** — the surge must read as *damage* (harsh, blown halos, popped bulbs), never as a brighter, nicer city.
- **A second capture** — capturing the M3 surge would re-introduce the dropped `surge_nowhere_to_go`; fire only `demand_never_still`.

## 13. Open decisions
1. Band width (±6) and wander / event amplitudes — on-device tuning so criterion 4 (median adult ≥ 80% in band on the gentle wander, forced tips on drop / rush) holds.
2. Blown-bulb pops at deep surge — keep (specced, polish-flagged) or cut if it reads as clutter on small phones.
3. Chip relabel USE→DEMAND / MAKE→SUPPLY at M4 — recommended **in**; fallback is keeping USE/MAKE and letting M4 carry the naming alone.
4. Silent vs a faint city-hum bed whose texture roughens on tips (vol ≤ 0.2) — propose shipping **silent**; flagged for polish.
5. Final `cropFactor` for `demand_never_still` — owned by the EP4 evidence-catalog author; §9 value is a proposal.

---

## 14. State machine sketch
```dart
enum HBPhase { intro, powerUp, wander, rush, naming, letGo, walkAway, tipped, recover, synthesis, cardEarn, done }
enum HBCaption { none, t1PowerCity, m1Steady, t2Hold, m2TooLittle, m3TooMuch, t3Rush, m4Naming, t4LetGo, m5Discovery, t5BringBack, m6Law, m7Grid }
enum HBBalanceState { balanced, brown, surge }
```
- **ValueNotifiers (discrete UI channels):** `caption: ValueNotifier<HBCaption>` (register flag imperative/meaning resolved in `hb_captions.dart`), `phase: ValueNotifier<HBPhase>`, `named: ValueNotifier<bool>` (chip relabel), `sliderLocked: ValueNotifier<bool>`, `showCardEarn: ValueNotifier<bool>`, `canFinish: ValueNotifier<bool>`.
- **Hot-path getters (repaint via `controller` as the painter/Flame repaint listenable):** `supply`, `demand`, `error`, `balanceState`, `brownDepth`, `surgeDepth`, `litWindowFraction`, `plantGlow`, `wirePulseRate`, `skyEvening` (0→1 across the rush), `flashIntensity`, `handleY`, `displayUse`, `displayMake`, `powerTrend`, `particles`.
- **Once-only flags:** `deficitFelt`, `surplusFelt`, `m1Reached`, `captureFired` (set of ids), `cardFired`, `outroFired`.
- **Timers (all via `_schedule(ms, fn)` decremented in `_tickProgression(dtMs)`, the shipped pattern):** fixed delays from §5/§6 — 900 (T1) / 1200-dwell (M1) / 2200 (T2) / rush-relative T3 / 1500-dwell (M4) / 2600 (T4) / 2400 (T5) / 1200-dwell (M6) / 3200 (M7) / 2600 (card). Plus a **wander-relative event clock** for the drop (+6 s) and rush (+14 s); **tip-sustain accumulators** (500 ms for M2/M3 catches, 400 ms for the let-go tip); a **pointer-release accumulator** (600 ms) gating walk-away.
- **Gating conditions:** `powerUp→wander` = in-band dwell ≥ 1200 ms (M1) then +2200 ms (T2). `wander/rush→naming` = `deficitFelt && surplusFelt && inBandDwellPostRush ≥ 1500 ms`. `naming→letGo` = +2600 ms (T4). `letGo→walkAway` = pointer up ≥ 600 ms (input ignored from here; column locks + desaturates). `walkAway→tipped` = `|error| > band` ≥ 400 ms → discovery side-effects (flash, `heavyImpact`, capture `demand_never_still`, M5). `tipped→recover` = +2400 ms (T5, unlock). `recover→synthesis` = in-band dwell ≥ 1200 ms (M6) → +3200 ms (M7). `synthesis→cardEarn` = +2600 ms → `showCardEarn = true`. `cardEarn→done` = `onCardCollected` → `canFinish = true`.
- **Hard gates in `tick(dt)`:** `balanceState` recomputed every frame from `error` vs band — the visual step applies the same frame the band is crossed; during `walkAway`/`tipped` the slider input is **dropped before integration**; `supply` is always the instantaneous slider value (no carryover/accumulator term exists in the sim). `notifyListeners()` every frame.

## 15. File plan — `lib/screens/missions/hold_the_balance/`
Mirrors the shipped `source_personalities` / `trace_it_back` structure (shell / state / config / game-or-widgets):
```
hold_the_balance_screen.dart          — shell: noScaling MediaQuery, header (back + optional sound),
                                        EpisodeBoardStrip(EP4 question), instruction banner (h 96, fade-swap),
                                        RepaintBoundary(_sceneKey) around EnergyFieldBackground + GameWidget
                                        (built once in initState), supply column overlay, fixed CTA seat (84),
                                        capture wiring (_onCapture), CollectibleEarnOverlay(kTheGridCard),
                                        Navigator.maybePop on Continue
state/hold_balance_controller.dart    — ChangeNotifier: HBPhase machine, gates, _schedule timers,
                                        caption driver, tick(dt), onCapture/onDiscovery/onDetent hooks,
                                        live-number sampling, hard-gate tip logic
state/demand_model.dart               — pure deterministic wander + drop/rush/walk-away ramps
                                        (functions of phase-relative time; no mutable state)
config/hb_tuning.dart                 — HBTune: band, base demand, octave amps/periods, event times,
                                        ALL ms timings, geometry factors (city band, plant, column, chip
                                        anchors), palette constants
config/hb_captions.dart               — HBCaption enum + verbatim §5 copy + isImperative flags
game/hold_balance_game.dart           — FlameGame: backgroundColor transparent, onLoad adds layers
                                        back→front, onGameResize → controller.setStageSize,
                                        update(dt) → if (0 < dt < 0.1) controller.tick(dt)
game/components/sky_layer.dart        — dusk gradient deepening to evening across the rush (skyEvening)
game/components/town_layer.dart       — THE HERO: window grid (lit fraction = demand; light quality =
                                        balanceState + depths; same-frame step), streetlamps + halos,
                                        surge white-shift/bloom, brown flicker, blown-bulb pops, town bloom
game/components/plant_wire_layer.dart — plant (glow ∝ supply) + catenary wires with gliding warm pulses
                                        (rate ∝ supply)
game/components/ambient_layer.dart    — vignette, ≤20 motes, discovery flash envelope
widgets/supply_slider.dart            — Flutter overlay column: 1:1 positional drag (no physics), detent
                                        haptics, warm fill core, locked/desaturated state
widgets/readout_chips.dart            — two mono chips (USE/MAKE → DEMAND/SUPPLY crossfade at M4), trend
                                        ticks via 5 Hz sampling
widgets/energy_field_background.dart  — static dark vignette variant (copy-adapt from trace_it_back)
```

## 16. Scene sketch (portrait, factor-based off stage size S = w × h)
- **Sky band:** y 0 → 0.30h. Dusk gradient; `skyEvening` deepens it during/after the rush. 2–3 faint far silhouettes at the horizon line y ≈ 0.30h.
- **City band (HERO):** y 0.30h → 0.62h, x 0.04w → 0.96w. Two depth rows of buildings (far row 0.30–0.46h desaturated, near row 0.38–0.62h); window grid cell ≈ 0.018w; lit fraction tracks `litWindowFraction`; streetlamps along y ≈ 0.60h with light cones. Vignette darkest behind this band; town bloom (`BlendMode.plus`) scales with balanced warmth.
- **USE/DEMAND chip:** anchored x ≈ 0.07w, y ≈ 0.26h (above the city's left shoulder, never occluding windows).
- **Wire run:** two pylons at x ≈ 0.18w / 0.38w rising from the plant; catenary curve from plant top to the city underside (y ≈ 0.62h); gliding warm pulses spaced ∝ `wirePulseRate`.
- **Plant:** bottom-left block x 0.06w → 0.30w, y 0.70h → 0.90h; cool body, warm interior glow ∝ `plantGlow`; **no smoke/haze** (source identity is not this beat's concern — and would contradict the held-constant network).
- **Supply column (the one control):** right edge, x 0.80w → 0.94w, y 0.34h → 0.92h; glass track, warm fill from the bottom ∝ supply, fat handle; locked state desaturates fill + handle. **MAKE/SUPPLY chip** directly above it at y ≈ 0.28h.
- **Capture frame note:** the §9 `cropFactor` keeps city + both chips + the (frozen) column inside the crop; the banner / strip / CTA live **outside** the RepaintBoundary so the capture stays clean.
