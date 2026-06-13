# PRD — Cascading Blackout (Episode 4, beat 4.5) · THE DRAMATIC PAYOFF
### howwow electricity · registry id `cascading_blackout` · `CascadingBlackoutScreen` · `lib/screens/missions/cascading_blackout/` · evidence episode `episode4_electricity`

Binding context: `docs/electricity/context_pack.md`, `docs/electricity/architecture_reference.md`, curriculum §1–§9 + beat 4.5. This PRD is self-contained: every on-screen line is quoted verbatim here. Evidence captures are reconciled to the **locked EP4 CER catalog** (`prd_make_your_case_ep4.md`, §3): this beat supplies `cascade_dark_map` (relevant, Act-1 dark) and `breaker_trip` (the episode's distractor, Act-2 trip). The earlier `reserve_holds_line` tile is **dropped** by the CER owner (the Act-2 hold keeps its drama; no capture fires there).

**Episode inheritance (what the learner already felt):** 4.1 — supply must equal demand continuously; there is no buffer; mismatch tips. 4.2 — the grid's only cushion is the shared spin of heavy machines; frequency (50 Hz) is the live balance readout; demand above supply drags rotors slower. 4.3 — demand follows human routines; the 6pm rush is the day's biggest spike. 4.4 — steady baseload covers the floor; fast peakers chase spikes.
**What this beat pins (held constant, visibly):** the same five plants with the same limits, the same city, the same evening peak (a ghost marker is burned onto the demand track at the value where the grid broke in Act 1, and the DEMAND number reaches the same value in Act 2), and the same first failure (the weakest plant trips in BOTH acts — deliberately scripted constant). **The only thing the learner changes between acts is the reserve.** The lesson is about whether a local failure PROPAGATES, not whether it happens.

---

## 1. One-concept statement
**A tightly-coupled system with no buffer can fail catastrophically and fast — local failures propagate.**

## 2. Guiding-question link + CER contribution
Episode 4 question (pinned on the board strip all activity): *"The plant is making almost exactly what the whole city uses this very second — who decides that, and what happens at the 6pm rush?"*
This beat answers the question's second half — what happens at the 6pm rush when the balance fails — and supplies the WHY behind "every second": the price of a missed second is a region dark in seconds.
This activity contributes **exactly two tiles to the locked EP4 catalog — one relevant, one distractor** (the EP4 catalog seeds one distractor into each of its two stages; this beat owns the second one):
- `cascade_dark_map` (**relevant**) — captured at Act-1 full dark: one trip raced outward and blacked out the map in seconds. Carries "the stakes" — *why "every second" is not a figure of speech*.
- `breaker_trip` (**distractor — TRUE but irrelevant**) — captured at the Act-2 G3 trip frame: a single plant, pushed past its limit, trips ITSELF offline to save the machine. It is true and witnessed, but it answers *how one machine protects itself*, not *who keeps the city matched / what happens at 6pm*. Discriminating it from `cascade_dark_map` (the propagation, which IS on-question) is the real reasoning the CER asks for. (EP4's other locked distractor is `lockstep_spin`, owned by 4.2.)

The Act-2 reserve hold remains a full felt payoff (the redemption), but **no tile is captured there** — per the EP4 owner, reserve margins are adjacent to, not part of, "forecast + dispatch every second," and a reserve tile sits too close to relevance to be a clean distractor.

## 3. The felt discovery (discovery → reaction)
**Act 1 discovery:** the learner drags the EVENING PEAK lever up — their own hand causes the rush. Rotors slow together, frequency sags, every load ring creeps toward its limit; the weakest plant SNAPS offline to save itself. **Reaction:** its load lands on the others in the SAME frame — their rings jump — they trip one after another, faster and faster, and the city blacks out district by district in a racing wave, ~2.5 seconds from first trip to total dark. The learner pushed ONE plant past its limit; the system took down the rest by itself. The dark map is the consequence; no score, no meter.
**Act 2 discovery (the redemption):** the grid restarts; the learner drags a RESERVE lever — every ring visibly retracts from its limit and a cold standby plant spins up to a ready idle — then pushes the SAME peak. The same plant trips again (and the breaker self-protection is now visible and capturable in isolation). **Reaction:** this time the landing load falls into visible headroom; the other rotors strain, the standby surges, frequency dips and claws back to 50, and the city stays lit. The cascade stops at one. Too little reserve → it breaks through again (honest failure about margin size), fast rebuild, try again.

## 4. Felt vs named vs numbered
**Felt (in the scene, never numeric):** plant load as a filling ring with a limit notch; headroom as the visible gap the reserve opens on every ring; rotor speed (all in lockstep, slowing as frequency sags — the 4.2 callback); the trip as an instant snap-to-dark with a `TRIPPED` tag; the cascade as a racing spatial wave of district blackouts; the standby plant cold vs spinning; the recovery as rotors steadying and the city holding; darkness itself as the only fail state.
**Named (a beat after felt, except setup arrangements named on sight):** the limit + protective trip (L2, setup — a breaker is a visible device, named immediately); the propagation (L4, after the dark is felt); the speed (L5); **"the reserve"** (L8, named last, only after the hold is felt). No depth-stops: everything here bottoms out in showable mechanism and human decisions (curriculum: no depth-stops in Episode 4).
**Numbered (exactly 2, live, mono chips):** `FREQUENCY` (50.0 Hz, the absolute readout deliberately kept from 4.2 — the curriculum names 50 Hz in India and 4.2 established it; re-scaling it would orphan the callback; it reads `—` when the grid is dead) and `DEMAND` (relative, 100 = this evening's normal, peaks at 140). **No number for reserve** (its readout is the headroom gaps + the spinning standby), no loss %, no "grid health" meter, no score, **no ratings table**.

## 5. On-screen text (exact, complete)
Imperatives: Bricolage Grotesque ~28 w800, Title Case, ≤5 words. Meaning-lines: Plus Jakarta Sans ~18 (long lines render ~16.5), de-personified facts. Swap = 190 ms fade-out → swap → fade-in.

| id | kind | text |
|---|---|---|
| L1 | meaning (scene set) | Almost 6pm. Five plants carry the whole city, and the evening rush is coming. |
| L2 | meaning (the limit, named on sight) | Each plant has a limit — the end of its ring. Cross it and a breaker trips the plant offline, saving the machine from burning out. |
| I1 | imperative | Push the Evening Peak |
| L3 | meaning (4.2 callback, fires at frequency ≤ 49.5) | Every rotor on the grid slows together — the rush is dragging energy out of the shared spin. |
| — | *(the cascade plays in total silence — no caption from first trip until after full dark)* | |
| L4 | meaning (post-dark, names the destination) | One plant tripped. Its whole load landed on the rest in the same instant — and pushed them past their limits too. |
| L5 | meaning | The failure raced outward faster than any operator could react. Nobody switched the city off — each plant cut out to save itself. |
| L6 | meaning (rebuild transition) | The grid restarts, plant by plant. The same evening rush is coming again. |
| I2 | imperative | Hold Some Power Back |
| I3 | imperative | Push the Peak Again |
| R1 | meaning (only after a failed Act-2 hold) | Too little held back — the landing load still broke through. |
| L7 | meaning (post-hold) | The same plant tripped. This time its load landed on spare headroom — every other plant strained, and none crossed its limit. |
| L8 | meaning (named last) | That already-spinning spare capacity is the reserve. Grids pay plants to run below their limits all day — mostly unused — for exactly this second. |
| L9 | meaning (outward landing) | In July 2012, one overloaded link in India's grid cascaded into a blackout across 620 million people — half the country — within minutes. |

In-scene mono labels (IBM Plex Mono, letter-spaced, small): chips `FREQUENCY 50.0 Hz` and `DEMAND 100`; lever labels `EVENING PEAK` and `RESERVE`; tag `TRIPPED` on each dead plant; tag `STANDBY` on the sixth plant while cold (tag disappears once it spins). Header title: `When Balance Fails`; mono eyebrow: `EPISODE 4 · THE GRID`. CTA: `Continue`. **No other text exists.** No mascot, no info-cards, no inline fact (deliberate empty slot — L9 already carries the outward reach).

## 6. Beat-by-beat flow (timing + gating)
Phase **intro** (auto, ~11 s):
1. 0 ms — entrance: city map fades in (450 ms), districts already warm-lit; five plants reveal one by one (120 ms stagger), rings filling to ~78–86 % of limit; standby plant reveals last, dark, `STANDBY` tag; network lines draw with gliding pulses; `FREQUENCY 50.0 Hz` chip settles in the plant band; rotors all spin in lockstep.
2. 1200 ms — L1 (hold 3000 ms).
3. 4200 ms — L2 (hold 3600 ms); as it shows, every ring's limit notch pulses once (`selectionClick`).
4. 7800 ms — I1 "Push the Evening Peak"; EVENING PEAK lever slides in with `DEMAND 100` chip; handle pulses (scale 1.0→1.15 loop). **WAIT for the learner. Drag enabled from this moment.**

Phase **push** (interactive):
5. Horizontal drag maps to demand 100→140, fully reversible until the first trip. **Same-frame** updates: every ring fills proportionally, rotors slow, frequency slides 50.0→48.9, city windows brighten (the rush IS people switching on), line pulses thicken. `selectionClick` per +5 demand detent.
6. First time frequency ≤ 49.5 — L3 (hold 3000 ms). Backing the lever off recovers frequency honestly (nothing latches yet).

Phase **cascade** (auto, scripted by the load model the moment demand ≥ 132):
7. Weakest plant (G3, smallest capacity) crosses its limit: ring tip flashes + rotor judders for 600 ms → **TRIP**: rotor freezes and plant light snaps off in the SAME frame (hard gate, ≤50 ms, never a fade), `TRIPPED` tag, `heavyImpact`. Lever freezes (one-way latch — lowering demand cannot untrip anything). **No capture fires in Act 1's trip** (the silent cascade stays visually unobstructed; the distractor tile is captured later, in Act 2).
8. Its load redistributes to the remaining plants in the SAME frame — rings JUMP. Then the wave, accelerating: next plant overloads 350 ms → trips; next 300 ms; next 260 ms; last 240 ms (`selectionClick` per trip). Each trip snaps its fed districts dark 80–140 ms later, spreading spatially outward from G3. Frequency plunges, then the chip reads `— Hz`. Total first-trip → full-dark ≈ 2.4 s. **All captions suppressed throughout.**
9. Full dark + 400 ms — `heavyImpact`; faint emergency outlines glow in the dead districts (so the tile is legible); fire `onCapture('cascade_dark_map')` (lightImpact + capture flash). This is the FIRST and only Act-1 capture — placed after the silent cascade so no flash chrome intrudes on it.
10. Hold the darkness in silence 1400 ms → L4 (hold 3400 ms) → L5 (hold 3400 ms).

Phase **rebuild** (auto, ~5 s):
11. L6 (hold 3000 ms); plants relight one by one (200 ms stagger), districts re-warm, frequency chip returns to 50.0, demand resets to 100, rings back to evening level. A faint **ghost marker is now burned onto the EVENING PEAK track at 132** — where it broke — and stays for the rest of the activity.

Phase **reserveSet** (interactive):
12. I2 "Hold Some Power Back"; RESERVE lever slides in above the peak lever, handle pulsing. Dragging it (0→1, no number) visibly: retracts every ring from its limit (headroom rendered as a pale gap segment up to the notch) and spins the standby plant up to a ready idle (rotor turning, low ring, `STANDBY` tag fades out). Fully reversible. `selectionClick` per 0.1 detent.
13. **Gate:** once reserve > 0.05, I3 "Push the Peak Again" appears and the EVENING PEAK lever re-arms (reserve stays adjustable until the first Act-2 trip).

Phase **pushAgain** (interactive):
14. The learner pushes the same ramp toward the ghost marker. At demand ≥ 132, G3 trips again — identical staging to step 7 (600 ms strain → snap, `heavyImpact`). Both levers freeze. **~150 ms after the snap, fire `onCapture('breaker_trip')`** (lightImpact + capture flash) — a clean frame of the single G3 glyph, its ring filled past the limit notch, snapped dark with the `TRIPPED` tag (the self-protective trip, in isolation, before propagation/containment resolves). This is the EP4 distractor tile; placed in Act 2 so Act 1's caption-suppressed cascade carries no flash chrome. Idempotent across Act-2 retries (fires on the FIRST Act-2 trip only).
15. Load lands on the others in the same frame. **Outcome computed from reserve r:** r < 0.5 → the wave breaks through again (same staggered trips, full dark ~2.4 s, or a shortened ~1.8 s retry wave per tuning) → 1000 ms dark → R1 (hold 2800 ms) → fast rebuild (~1.6 s, no L6, reserve lever keeps its value) → back to step 12 with I2 swapped to the same "Hold Some Power Back". r ≥ 0.5 → rings surge INTO the headroom but not past the notches; the standby's ring fills fast (the surge); rotors strain visibly; frequency dips to ~49.3 then claws back over ~1.5 s; one district flickers once and holds; city stays lit.
16. **Hold-success latch:** demand ≥ 138 AND frequency ≥ 49.8 sustained 800 ms AND G3 dark AND ≥95 % districts lit → `heavyImpact`. **No capture fires here** (the EP4 catalog dropped `reserve_holds_line`); the hold keeps its full felt payoff and haptic only.

Phase **closing**:
17. +500 ms — L7 (hold 3600 ms) → L8 (hold 3800 ms) → L9 (hold 3800 ms).
18. +400 ms — `canFinish.value = true` → gold Continue CTA in its fixed-height seat → tap → `Navigator.maybePop(context)`. **No card** (§8).

Latches are one-way high-water marks. Captures fire exactly once each: `cascade_dark_map` at Act-1 full dark (step 9), `breaker_trip` on the first Act-2 trip (step 14). Play length: ~11 s intro + ~10 s push/cascade + ~12 s dark/rebuild + ~10 s reserve + ~10 s hold + ~12 s closing ≈ 65 s clean run; each failed hold adds ~12 s. Within 60–150 s.

## 7. Hero & layout (portrait) + clutter caps
**The hero is the lit city map** — the warmest, most-alive thing on screen (warm window grids `#FFE9B8`, district blooms, gliding line pulses); its going dark IS the consequence and its holding IS the reward. The plant band (rings, rotors, standby) is the mid-band cause layer — visible and legible but cooler and dimmer than the city. Levers and chips are chrome (glass fills `0x14FFFFFF`, borders `0x26FFFFFF`); background near-black `#070A1C`, radial vignette darkest behind the city; ≤20 ambient motes; the one orchestrated moment is the racing blackout wave (and its mirror, the hold).
**Clutter caps:** 1 hero; **≤2 interactive elements ever** (EVENING PEAK lever; RESERVE lever from Act 2) — back button, board strip, and end-state CTA are chrome; **exactly 2 live numbers** (FREQUENCY, DEMAND); one current text line. Nothing else.

## 8. Reward — **No card**, and why
"Cascading failure" is **not a row in the curriculum quick-reference table** — the EP4 rows are the grid (object, no card), frequency (4.2's card), and baseload/peaking (4.4's card); the context pack's expected EP4 set (no-buffer, frequency, baseload/peaking, CER synthesis) excludes 4.5. The cascade is the *consequence* of 4.1's no-buffer law and 4.2's thin-spin cushion, not a new law; minting a card here would restate theirs. The reward is the redemptive hold itself, the evidence tiles, and L9's true outward landing (the 2012 India blackout). The EP4 CER synthesis card (`kControlRoomCard`, owned by the CER PRD) owns the episode's completed idea. No inline fact either (deliberate empty slot).

## 9. CER capture hook (ids locked by the EP4 evidence catalog)
- **`cascade_dark_map`** — label: `Dark in Seconds` · caption: *One overloaded plant tripped — its load overloaded the rest, and the whole map went dark in seconds.* · accent `#8FA6FF` (moon-cool) · sourceLabel `ACT 4.5` · **relevant** · fires at Act-1 full dark + 400 ms (step 9), framing the city map with the dead plant band above — emergency outlines, dead `— Hz` chip, a radiating wavefront ring keep the dark tile legible (proposed cropFactor ≈ `Rect.fromLTRB(0.04, 0.06, 0.96, 0.80)`; CER owner's catalog value governs).
- **`breaker_trip`** — label: `Built to Trip` · caption: *Pushed past its limit, a plant trips itself offline — the breaker saves the machine from burning out.* · accent `#3FB9F5` (mechanism blue, the EP4-distractor accent) · sourceLabel `ACT 4.5` · **distractor (relevant: false)** · fires ~150 ms after the Act-2 G3 trip snap (step 14), framing the single G3 glyph + neighbouring rings with G3's ring filled past its limit notch, snapped dark, `TRIPPED` tag (CER owner's cropFactor ≈ `Rect.fromLTRB(0.26, 0.02, 0.74, 0.30)` — G3 + neighbours; final value tuned at integration).
Wiring per the shipped pattern: `RepaintBoundary(key: _sceneKey)` around background + GameWidget ONLY (levers/chrome outside, so tiles show the map/plants, not controls); `controller.onCapture = _onCapture` → `captureScenePng(_sceneKey, cropFactor: evidenceByIdFor('episode4_electricity', id)?.cropFactor)` → `_board.capture(id, imageBytes: bytes)`; `EpisodeBoardStrip` pinned under the header with the EP4 question. Captures idempotent, never block flow. **The Act-2 hold success fires no capture** (the EP4 owner dropped `reserve_holds_line`).

## 10. Build notes
- **Flame `GameWidget`** for the living network/cascade scene (mandated; this is the multi-component beat Flame was kept for) + Flutter overlay chrome — the trace_it_back template. GameWidget built once in `initState`; transparent `backgroundColor`; `onGameResize` → `controller.setStageSize`; `update(dt)` guards `dt > 0 && dt < 0.1` → `controller.tick(dt)`.
- **Levers are Flutter widgets** (the time_scrubber precedent): horizontal drag tracks with glowing handles, outside the RepaintBoundary. **No Forge2D.** All motion is controlled; **trips are hard gates in the update loop** (light + rotor + pulses snap to zero the same frame), never decay.
- Sim (`state/grid_sim.dart`, deterministic, config-tuned): 5 plants, relative capacities ≈ {1.00, 1.05, 0.78 (G3), 1.00, 0.95}; base evening load fills rings to ~78–86 %; demand d ∈ [100, 140] scales loads; reserve r shifts load onto the standby (up to ~15 %) and proportionally off the five, opening headroom; on trip, the dead plant's load redistributes to survivors proportional to remaining capacity in the same tick; a plant whose load exceeds capacity trips after its staggered strain delay (600/350/300/260/240 ms); frequency `f = 50 − k·max(0, demandServedGap)` with collapse → `—` at full trip; recovery ramps the standby surge. Act-2's G3 trip at d ≥ 132 is **scripted-constant** (config flag) so the trigger is held constant across acts.
- Haptics: `selectionClick` per lever detent and per subsequent trip; `heavyImpact` at first trip, at full dark, and at the hold latch; `lightImpact` on captures.
- Audio: **silent** (the silent dark IS the drama; matches most shipped electricity activities).
- Reduced motion (`MediaQuery.disableAnimations`): motes calmed, entrance reveals become fades, rotor judder becomes a static strain tint — but trip snaps, same-frame redistribution, and the staggered wave timing are **untouched** (pedagogical cutoffs are never softened).
- Wrap the screen in `MediaQuery(...textScaler: TextScaler.noScaling)`. Completion = `Navigator.maybePop` from the Continue CTA. Write ONLY inside `lib/screens/missions/cascading_blackout/`; evidence ids/cropFactors are finalized by the catalog agent; reference `evidenceByIdFor('episode4_electricity', …)` — no registry/wowConcepts/card/evidence-catalog edits.
- Verify: `fvm dart analyze lib/screens/missions/cascading_blackout` clean.

## 11. Acceptance criteria (pedagogy as testable checks)
1. **Discoverable from interaction alone:** with all text ignored, dragging the pulsing lever up produces rings filling → rotors slowing → frequency falling → trip → racing blackout, with zero reading required.
2. **The learner causes it:** no trip can occur before the learner's own drag reaches demand ≥ 132; the cascade never auto-triggers.
3. **Trips are hard gates:** a tripping plant's light, rotor, and line pulses reach ≤2 % within 50 ms — no fade tail — including under reduced motion.
4. **Propagation is visible and same-frame:** at each trip, survivors' rings JUMP in the same frame the plant dies; district blackouts spread spatially outward from G3; the full wave (first trip → total dark) completes in 2.0–3.0 s with accelerating stagger.
5. **Silence during the cascade:** no caption appears between the first trip and 1400 ms after full dark; L4/L5 appear only after the darkness is felt; **no capture flash intrudes on Act-1's cascade** (the relevant tile fires only after full dark; the distractor tile fires in Act 2).
6. **The dark map is the consequence:** no score, no "grid health" meter, no % anywhere; the only fail readout is the dark city (with emergency outlines) and the dead `— Hz` chip.
7. **Held-constant is visible:** the ghost marker sits at 132 on the peak track from rebuild onward; Act 2 reaches the same DEMAND value; the same plant (G3) trips in both acts with identical staging.
8. **Reserve is felt before it is named:** dragging RESERVE visibly opens headroom gaps on every ring and spins the standby to ready idle; the word "reserve" appears nowhere (text or labels other than the lever's mono label `RESERVE`) until L8 — and L8 fires only after a successful hold. *(The lever label is an object name on a control; the LAW is still named last.)*
9. **The redemption is honest:** with r ≥ 0.5 the same trip lands, rings surge into headroom but not past notches, frequency dips to ~49.3 and recovers to ≥49.8, and ≥95 % of the city stays lit; with r < 0.5 the cascade genuinely recurs and R1 names the consequence; retry loop ≤ ~12 s with the reserve lever keeping its value.
10. **Catch lines name destinations:** L4 ("landed on the rest"), R1 ("broke through"), L5 ("each plant cut out to save itself") — no behaviour/ending phrasing ("it just failed"), no rhyme anywhere.
11. **Exactly 2 live numbers** (FREQUENCY in Hz, DEMAND relative), mono chips; no number for reserve, load, or lit-fraction; no ratings table.
12. **Captures match the locked EP4 catalog:** `cascade_dark_map` fires once at step 9 (Act-1 dark, relevant) and `breaker_trip` fires once on the first Act-2 G3 trip (step 14, distractor); each appears on the board strip with flash + light haptic; **no capture fires at the Act-2 hold success**; both resolve via `evidenceByIdFor('episode4_electricity', …)`.
13. **No card overlay exists;** Continue appears only after L9 completes; pop completes the activity.
14. **Hero dominance:** the city is the brightest element lit, and the screen reads near-black at full dark; ≤2 interactive elements; ≤20 motes; chrome recedes.
15. `fvm dart analyze lib/screens/missions/cascading_blackout` is clean; small-phone portrait (≈360×640 logical) shows plant band, city, and levers without overlap.

## 12. Anti-patterns (this activity)
- **A canned blackout video** — the wave must propagate from the load model (per-plant overload → staggered trip → redistribution), so partial reserves produce honestly different runs. (Only the FIRST trip's trigger is scripted-constant.)
- **A premium fade on any trip or district blackout** — every cutoff snaps; the racing wave is a sequence of hard snaps.
- **Explaining during the cascade** — any caption between first trip and post-dark kills the witnessed drama.
- **A capture flash during Act-1's cascade** — the relevant tile fires only after full dark; the distractor fires in Act 2, so nothing strobes over the silent wave.
- **Pre-spoiling propagation** — no setup text or visual may hint that one trip will overload the others (L2 names only the self-protective trip).
- **Act 2 preventing the first trip** — if reserve stops G3 from tripping, the lesson collapses into "avoid faults" instead of "contain them"; the same local failure must happen and be CONTAINED.
- **A "grid health" / stability meter or a score for holding** — the lit city is the readout; the dark map is the consequence.
- **A reserve number** — headroom is felt geometry (ring gaps + the spinning standby), not a third live number.
- **Marking the distractor as wrong** — `breaker_trip` is captured like any tile, with no warning/dim/different frame; relevance is the learner's judgment in the CER, not flagged here.
- **Frustration loops about ergonomics** — the only Act-2 failure mode is margin size (the concept), never fiddly lever precision; detents are generous.
- Making the plant band brighter than the city; more than 2 levers; mesh clutter (>10 line segments).

## 13. Open decisions
1. **Scripted-constant G3 trip in both acts** (recommended, per §6 steps 7/14) vs letting it emerge from the load model — emergent risks no-trip-at-high-reserve, which breaks both the held-constant trigger AND the `breaker_trip` capture (which depends on the Act-2 trip happening). Build agent keeps the config flag; reviewer may flip after device play.
2. **`breaker_trip` capture placement:** default Act-2 trip frame (step 14) — keeps Act-1's silent cascade pristine. The EP4 owner notes it *may* move to the Act-1 trip frame ONLY IF the build defers the board flash until post-dark. Default: Act 2.
3. **Binary hold threshold (r ≥ 0.5)** vs a graded middle tier (partial cascade: two plants lost, brownout, then collapse) — graded is richer but longer; default binary.
4. Exact relative ranges (demand 100–140, trip at 132, capacities, stagger times) — tune on device; values here are the contract's starting point.
5. `FREQUENCY` chip shows `Hz` (recommended — 4.2 precedent and the curriculum's "50 Hz in India") — confirm against the shipped `grid_frequency` display format at integration.
6. Whether the failed-hold dark state shows a shortened wave (~1.8 s) to keep retries brisk — recommended, flag in tuning.
7. Final cropFactors and tile motif art are owned by the EP4 evidence-catalog agent; §9 carries the catalog's current values.

## 14. State machine sketch
```dart
enum CBPhase { intro, push, cascade, darkness, rebuild, reserveSet, pushAgain, held, closing }
enum CBCaption { none, l1Evening, l2Limit, i1Push, l3Spin, l4Landed, l5Raced, l6Restart,
                 i2Hold, i3PushAgain, r1Broke, l7Held, l8Reserve, l9India }
```
`CascadeController extends ChangeNotifier`:
- **ValueNotifiers:** `caption: ValueNotifier<CBCaption>` (copy table marks imperative vs meaning per id), `phase: ValueNotifier<CBPhase>`, `canFinish: ValueNotifier<bool>`.
- **Hot-path getters (read by Flame layers):** `plants` (per plant: `loadFrac`, `limitFrac`, `headroomFrac`, `tripped`, `strain`, `rotorAngle`, `reveal`), `standbySpinning`, `standbyLoad`, `districtLit` (list 0–1 with flicker/emergency state), `wavefrontRadius`, `demand`, `frequency` (`double?` — null renders `—`), `reserve`, `pulsePhase`, `flashIntensity`, `cityBloom`, `motes`, `ghostMarkerVisible`.
- **Input:** `onPeakDragStart/Update/End(double dx)` → demand 100–140 (disabled outside push/pushAgain; frozen after a trip latch); `onReserveDragUpdate(double dx)` → reserve 0–1 (enabled in reserveSet/pushAgain until the Act-2 trip). Detent hooks → `selectionClick`. No momentum: values hold exactly where the finger leaves them.
- **Timers:** `_schedule(ms, fn)` chains per §6 — intro 1200/4200/7800 ms; strain delays 600/350/300/260/240 ms; district snaps +80–140 ms; dark hold 1400 ms; caption holds 2800–3800 ms; rebuild stagger 200 ms; breaker-capture +150 ms after Act-2 trip; hold-latch sustain window 800 ms (checked in `tick`).
- **Latches (one-way):** `_tripped1` (demand ≥ 132 in push) → cascade chain + lever freeze; `_fullDark` → capture `cascade_dark_map` + L4/L5 chain; `_rearmed` (reserve > 0.05) → I3; `_tripped2` (demand ≥ 132 in pushAgain) → capture `breaker_trip` (+150 ms, first Act-2 trip only) + outcome branch on `reserve`; `_heldOk` (demand ≥ 138 ∧ frequency ≥ 49.8 for 800 ms ∧ ≥95 % lit) → heavyImpact + closing chain (NO capture); failed holds reset only `_tripped2` (fast rebuild path) — `_capturedBreaker` stays latched so the distractor never re-fires.
- **Hooks:** `onDetent` (selectionClick), `onTrip(int plantIndex)` (heavy for first, selection for rest), `onFullDark` (heavyImpact), `onHold` (heavyImpact), `onCapture(String id)` (lightImpact + PNG in shell). `reducedMotion: bool` set from MediaQuery each build.

## 15. File plan (mirror trace_it_back / source_personalities)
```
lib/screens/missions/cascading_blackout/
├── cascading_blackout_screen.dart      — shell: noScaling MediaQuery, RepaintBoundary(_sceneKey) around
│     background + GameWidget, header (back), EpisodeBoardStrip (EP4 question), _FadeSwapCaption top text
│     (fixed height, 190 ms swap), lever widgets BELOW the stage (outside the boundary), fixed-height CTA
│     seat, CaptureFlash; EpisodeBoardCapture('episode4_electricity').load(); maybePop on Continue
├── state/cascade_controller.dart       — ChangeNotifier per §14 (phase machine, latches, caption chains)
├── state/grid_sim.dart                 — deterministic load-flow toy: capacities, shares, redistribution,
│     staggered trip queue, frequency model, reserve/standby shift, recovery ramp (per §10)
├── config/cascade_tuning.dart          — CBTune: demand range/detents · tripDemand 132 · holdDemand 138 ·
│     reserveGate 0.05 · holdReserve 0.5 · strain/stagger ms · darkHold 1400 · breakerCaptureDelay 150 ·
│     all caption holds · capacities · freq constants (49.5 callback · 49.3 dip · 49.8 recover) ·
│     anchor factors (§16) · mote cap 20 · retry wave 1800 ms
├── config/cascade_beats.dart           — CBCaption enum + verbatim copy table (§5) + isImperative flag +
│     hold durations
├── game/cascade_game.dart              — FlameGame: transparent bg, layers back→front, onGameResize →
│     controller.setStageSize, update → controller.tick
├── game/components/plant_layer.dart    — 5 plants + standby: housing glyph, rotor ring (spin ∝ frequency),
│     load ring + limit notch + headroom gap segment, strain judder/tint, trip snap + TRIPPED mono tag,
│     STANDBY tag, FREQUENCY chip anchor, reveal/relight staggers
├── game/components/network_layer.dart  — ≤10 catenary/mesh segments plant→district, traveling pulses
│     (count/thickness ∝ load, additive), dead-line instant grey-out per feeder
├── game/components/city_layer.dart     — THE HERO: 6 districts of window grids + warm blooms, brightness ∝
│     demand, per-district hard snap to dark with emergency outlines, spatial wave ordering from G3,
│     one-flicker-and-hold on Act-2 surge, moon-cool rim light for dark-state legibility
└── widgets/
    ├── control_levers.dart             — EVENING PEAK + RESERVE drag tracks (glass, glowing handles,
    │     pulse hint, DEMAND chip riding the peak handle, ghost marker at 132, freeze states)
    └── energy_field_background.dart     — static dark vignette + faint circuit texture (copy-adapt)
```

## 16. Scene sketch (portrait, top → bottom; factors of stage size w × h)
1. **Header** (SafeArea): back button on glass; title "When Balance Fails" (Bricolage 21 w800); mono eyebrow `EPISODE 4 · THE GRID`.
2. **EpisodeBoardStrip** — EP4 question pinned + captured mini-tiles.
3. **Top text** — fixed-height (~96) caption seat: imperatives Bricolage 28 w800 / meaning-lines PJS 18 (L2/L8/L9 render ~16.5).
4. **Stage (Expanded), plant band y 0.02–0.26 h:** five plants in a shallow arc, centers at x ≈ {0.12, 0.31, 0.50, 0.69, 0.88} w, y ≈ 0.10–0.14 h (G3 = center, x 0.50 w); each plant glyph ~0.11 w wide with rotor ring Ø ~0.085 w and load ring Ø ~0.13 w; standby plant smaller (~0.08 w) tucked at x 0.88 w, y 0.235 h, dark with `STANDBY` tag; `FREQUENCY` chip centered at x 0.50 w, y 0.015 h (above G3 — the readout belongs to the spin). The `breaker_trip` tile crop frames G3 + its two neighbours (x ≈ 0.31–0.69 w, top band).
5. **Network band y 0.26–0.36 h:** feeder lines fan from each plant down to its districts; two inter-tie segments across; pulses glide downward.
6. **City map y 0.36–0.78 h (THE HERO):** six districts in a 3×2 organic cluster, centers ≈ {(0.18, 0.45), (0.50, 0.42), (0.82, 0.46), (0.22, 0.64), (0.55, 0.66), (0.84, 0.63)} (w, h factors); each ~0.26 w wide window-grid cluster + warm bloom; vignette darkest here; ≤20 motes drifting above the rooftops; blackout wave radiates from the district under G3. The `cascade_dark_map` tile crop frames this whole map + the dead plant band.
7. **Control band y 0.80–0.98 h (Flutter, outside RepaintBoundary):** RESERVE track (appears Act 2) at y ≈ 0.82 h, x 0.10–0.90 w; EVENING PEAK track at y ≈ 0.91 h, x 0.10–0.90 w, `DEMAND` chip riding its handle, ghost marker burned at the 132 position from rebuild onward.
8. **CTA seat** (fixed 84): gold gradient `#F5C451 → #D9A43B` Continue pill after L9.
All geometry factor-based off `setStageSize`; nothing pixel-fixed.
