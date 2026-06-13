# PRD — The Living Curve (Episode 4, beat 4.3)
### howwow electricity · registry id `demand_curve` · `DemandCurveScreen` · `lib/screens/missions/demand_curve/` · evidence episode `episode4_electricity`

Binding context: `docs/electricity/context_pack.md`, `docs/electricity/architecture_reference.md`, curriculum §1–§9 + beat 4.3, and `docs/electricity/prds/prd_make_your_case_ep4.md` (the LOCKED owner of the EP4 evidence catalog — this PRD is reconciled to it, see §9). This PRD is self-contained: every on-screen line is quoted verbatim here.

**Episode:** Episode 4 — Keeping the Lights On. **Guiding question (pinned on every board strip, all three CER screens):** *"The plant is making almost exactly what the whole city uses this very second — who decides that, and what happens at the 6pm rush?"*

**Chain inheritance (what the learner already felt):** 4.1 (`hold_the_balance`) — there is no buffer: production must equal consumption continuously, and the demand line the learner chased WOULD NOT hold still. 4.2 (`grid_frequency`) — the balance is spinning mass, read live as one number, frequency; the operator's loop is "dip seen → power in → 50 held". The word "demand" is therefore inherited vocabulary (felt in 4.1, where the learner chased it), so L1 may name it on sight — the clean handoff, exactly like "Spin the Magnet" naming the magnet revealed in 1.1.
**What this beat pins (held constant, visibly):** the SUPPLY side is out of frame entirely — no balance mechanics, no frequency chip, no flicker-from-shortage, no blackout; the city is always healthily lit according to its routine. The city itself never changes: same skyline, same buildings, both days, a weatherless sky. The ONLY thing that moves is the clock — so every change in the curve can only be people. The second day re-runs the SAME city, which is what makes "same shape, different wiggle" attributable to routine, not to scenery.
**What it loads forward:** 4.4 (`baseload_peaking`) — "demand follows human routines, so the 6pm spike is *known in advance*" is the exact knife 4.4 turns: the learner there sees the spike coming and still fails on ramp speed. The trough's "floor" line here quietly plants baseload. 4.3 is also the forecastability half of the EP4 claim ("operators forecast the human day…").

---

## 1. One-concept statement
**Demand follows human routines — predictable in shape but constantly moving.**

(If it needed an "and," it would be two activities. It does not: the predictable-shape and the never-still are two faces of one fact — a routine — and both are felt in the same curve.)

## 2. Guiding-question link + CER contribution
This beat supplies the foundation of the "who decides" half: the curve is *forecastable* (same shape every day), which is the precondition for operators forecasting it; and it makes "what happens at the 6pm rush" legible as a CAUSE (everyone home at once), which the supply-side beats (4.2 dip, 4.4 dispatch, 4.5 cascade) then pay off.
- **Relevant evidence (the one tile this beat contributes to the LOCKED EP4 catalog):** `same_shape_next_day` — captured when day two finishes tracing over day one's ghost: same shape, never the same line. This carries "operators forecast the human day" in the EP4 claim.
- **No distractor from this beat.** EP4's exactly-2 distractors (`lockstep_spin` from 4.2, `breaker_trip` from 4.5) are owned by their PRDs. The TV-kettle detail here is an *inline fact*, not a capture, precisely because it is arguably on-question (it explains a real demand spike) and would muddy the distractor set.
**Reconciliation note (binding):** the earlier draft of this PRD proposed a second capture `evening_peak_cause` at the peak climax. The EP4 CER owner DROPPED it (the 6pm rush is already carried grid-side by `rush_hour_dip`, dispatch-side by `slow_plant_late`/`fast_plant_catch`, and failure-side by `cascade_dark_map`; 4.3's irreplaceable contribution is forecastability). **The peak micro-replay KEEPS its felt discovery — `heavyImpact` + the discovery ring on the DEMAND chip — but fires NO `onCapture`.** This activity captures exactly one tile.

## 3. The felt discovery (discovery → reaction)
**Discovery 1 (the causes — found in windows, not read):** the learner scrubs/plays one day, then taps each of four pulsing, unlabeled markers on the freshly traced demand curve. **Reaction:** each tap transports time to that moment and plays a short micro-replay in the LIVING CITY where the cause is visible in the scene itself — kitchens flicking on one-by-one at dawn (kettle-steam puffs), homes going dark while offices hold at midday, a wave of warm windows + air-conditioner glow sweeping the whole city at 6:30pm, and the near-empty 3am floor (fridges, streetlights, a hospital) — while the curve cursor climbs or flattens IN THE SAME FRAMES. The cause is in the city, never in a list.
**Discovery 2 (the character — the payoff):** after all four causes are witnessed, day one dims to a ghost and TOMORROW traces itself over it. **Reaction:** the new line hugs the ghost's shape — surge, plateau, peak, trough in the same places — but never sits exactly on it; the peak lands a few minutes off, the wiggle never repeats. Predictable in shape, never still — seen, not asserted. This is also the activity's reward (it earns no card — §8).

## 4. Felt vs named vs numbered
**Felt (in the scene, never numeric):** who is awake (warm home windows), who is cooking (kitchen windows + kettle steam), who is working (cool office windows), the 6pm everyone-home wave + AC units glowing on, the 3am floor (streetlights, fridge glimmers, hospital cross), the curve being TRACED live with a visibly never-still wiggle, day two's deviation from the ghost.
**Named (a beat after felt):** "demand" is inherited from 4.1 and named on sight (L1). The four moves are named only after each is witnessed — *overnight trough, morning surge, midday plateau, evening peak* (L3–L6 + the mono micro-labels that fade under a marker only after its replay). "Forecast" is named last (L9), after same-shape-different-line is felt.
**Numbered (exactly 1 live number, relative):** `DEMAND <n>` + ↑/↓ — a mono chip riding the curve cursor; the peak of the day = 100, the trough ≈ 35; it wiggles ±2 continuously so "never stops moving" is readable in the number too. The scrubber's clock (`18:30` + period word) is transport chrome per the shipped `time_scrubber` precedent, not a quantity readout. **No ratings table; no number for brightness, occupancy, AC count, or any cause; no percentages; no absolute units (no MW, no kWh).**
**Depth-stops: none.** Per the curriculum, Episode 4 has no depth-stops — every "why" here bottoms out in human routine, fully shown. Nothing on screen says or implies "nobody knows".

## 5. On-screen text (exact, complete)
Imperatives: Bricolage Grotesque ~28 w800, Title Case, ≤5 words — they instruct, they never teach. Meaning-lines: Plus Jakarta Sans ~18 (long lines L1/L4/L6/L8/L9 render ~16.5), de-personified facts. Swap = 190 ms fade-out → swap → fade-in (never cross-fade). One voice; no mascot, no narrator, no info-cards.

| id | kind | text |
|---|---|---|
| L1 | meaning (names inherited noun) | One city, one ordinary day. The line beneath it is demand — how much electricity the city is using, second by second. |
| I1 | imperative | Watch the Day Unfold |
| L2 | meaning (after day-1 trace completes) | The curve never held still — and none of its moves were random. |
| I2 | imperative | Tap Each Move |
| L3 | meaning (trough, after its replay) | The overnight trough: the city sleeps. What stays on is the floor — fridges, streetlights, hospitals, drawing power all night. |
| L4 | meaning (surge, after its replay) | The morning surge: the city wakes within one hour — kitchens, kettles and geysers switching on together. |
| L5 | meaning (plateau, after its replay) | The midday plateau: homes go quiet and offices take over. The curve flattens — it does not fall. |
| L6 | meaning (peak, after its replay) | The evening peak: everyone comes home in the same hour. Lights, stoves and air conditioners join at once — the highest demand of the day. |
| L7 | meaning (all four witnessed) | Every move on this curve is people — the same routines, at the same hours, every day. |
| I3 | imperative | Now Watch Tomorrow |
| L8 | meaning (THE naming) | Tomorrow traces almost the same shape — never the same line. Demand is predictable in shape and never stops moving. |
| L9 | meaning (the consequence/destination) | Grid operators forecast this curve a day ahead, then chase it minute by minute — because nothing buffers the grid. |

Scene micro-labels (IBM Plex Mono ~8.5, letter-spaced, appear under a marker only AFTER it is witnessed): `TROUGH` · `SURGE` · `PLATEAU` · `PEAK`. Demand chip (mono ~12): `DEMAND <n>` + trend arrow `↑`/`↓`. Scrubber clock chrome: period word (`NIGHT` / `DAWN` / `MORNING` / `MIDDAY` / `AFTERNOON` / `DUSK` / `EVENING` / `NIGHT`) + `HH:MM`.
**Inline fact (the one allowed — glanceable, skippable, never a gate, specific + surprising, not a restatement of the lesson):** a collapsed chip (mono, dark glass) reading `TV PICKUP` with a small kettle glyph; it appears only after the peak is witnessed. Tap to expand into a dark-glass panel (PJS ~13): *When a popular TV programme ends, millions of kettles switch on in the same minute. Operators watch the TV schedule to be ready for the spike.* On expansion, a sharp needle-spike pops once on the evening shoulder of the ghost curve with a steam puff — a felt flourish, optional to ever see.
CTA: `Continue`. **No card brag** (no card — §8). No other text exists anywhere in the activity.

## 6. Beat-by-beat flow (timing in ms + gating)
**Phase `intro`** (auto, ~4.5 s):
1. 0 ms — scene entrance (slide+scale+fade ≤450 ms, staggered): sky, city at 00:00 (a few windows lit, streetlights on), empty curve panel with baseline. 700 ms — L1 (hold 3200 ms).
2. 3900 ms — I1 "Watch the Day Unfold" appears; `firstDay` starts.

**Phase `firstDay`** (auto-play ~24 s, scrubbable):
3. The clock runs 00:00 → 24:00 (`dayLengthSeconds` 24). The curve TRACES itself left→right as time advances; the cursor carries a thin vertical hairline up into the city, gluing curve-point to city-moment. City channels co-vary same-frame: pre-dawn trough → kitchen cascade ~06:00–08:00 → offices on / homes quiet by 11:00 → the 18:00–19:30 everyone-home wave + AC glow → wind-down into night. The DEMAND chip ticks (sampled ~5×/s, trend arrow).
4. Scrubber: drag pauses the clock and scrubs; release resumes (shipped `TimeScrubber` behaviour). The trace/cursor CHASES the thumb at ≤6 h/s — fast-forward and rewind sweep through intermediate states, never teleport. `selectionClick` per 3 simulated hours crossed while dragging. Rushing is allowed — the explore gate below carries the pedagogy.
5. At 24:00 — clock parks, play/pause hides. 400 ms — L2 (hold 3000 ms) → I2 "Tap Each Move"; four unlabeled gold marker rings pulse on the curve at 02:30 / 06:45 / 13:00 / 18:30. **WAIT for the learner** (no auto-advance).

**Phase `explore`** (interactive; sub-phase `causeReplay` per tap):
6. Tap a marker (forgiving hit radius ≈ 0.06 w; `selectionClick`) → eased time-transport (≤8 h/s) to the replay window's start, then the window auto-plays slowly while the world dims ~20% EXCEPT the cause group (spotlight via dim — trace_it_back's `discoveryDim` pattern):
   - **trough** [01:30→03:30 @ 1.0 h/s ≈ 2.0 s]: near-total dark; what remains lit is emphasized — streetlight cones, sparse cold fridge glimmers, the hospital cross; the cursor runs FLAT along the floor. Then L3 (hold 3400 ms).
   - **surge** [05:45→08:00 @ 1.1 h/s ≈ 2.0 s]: bottom-floor kitchen windows cascade on one-by-one with kettle-steam puffs; cursor climbs the surge in lockstep. Then L4 (hold 3400 ms).
   - **plateau** [11:30→14:30 @ 1.5 h/s ≈ 2.0 s]: home windows fade out as office windows (cool white, mid-band cluster) hold steady; cursor runs level. Then L5 (hold 3400 ms).
   - **peak** [17:30→19:15 @ 0.7 h/s ≈ 2.5 s — the showpiece]: a wave of warm windows sweeps across all bands as AC units glow on beneath them; DEMAND climbs to 100; **`heavyImpact` + the discovery ring fire on the chip as it crosses 97** — the felt climax. **No `onCapture` here** (reconciled — §9). Then L6 (hold 3600 ms); the `TV PICKUP` fact chip fades in at the curve panel's top-right.
7. After each replay the marker settles to a solid dot, its micro-label fades in (300 ms), and the caption returns to I2 if moves remain. Markers stay re-tappable (replays re-run; labels never re-fire). **Free order.**
8. **Gate:** all four witnessed → 600 ms → L7 (hold 3000 ms) → I3 "Now Watch Tomorrow" (hold 1200 ms) → `secondDay`. The scrubber locks (dimmed) from here.

**Phase `secondDay`** (auto, ~9 s):
9. Day one's curve dims to a ghost (gold → ~28% alpha, 450 ms). The clock re-runs 00:00 → 24:00 at ~2.6×; the SAME city lives its routine again in fast-forward while day two traces over the ghost — same shape, visibly never the same line (deterministic day-2 seed: peak time shifted ≤30 min, amplitude ±4, fresh wiggle).
10. At trace completion +300 ms (a clean frame: both curves glowing over the night city) — **`onCapture('same_shape_next_day')`** fires (one-way latch).

**Phase `synthesis` → `closing`:**
11. +400 ms — L8 (hold 3600 ms) → L9 (hold 3400 ms) → +400 ms `canFinish.value = true` → the gold Continue CTA appears in its fixed-height seat → tap → `Navigator.maybePop(context)`. **No card overlay** (§8).
Latches are high-water marks: nothing regresses, no capture or label re-fires. Play length: ~4.5 + 24 + (4 × ~7) + 4 + 9 + 8 ≈ 78 s scripted; 80–140 s with learner pacing — inside the 60–150 s target.

## 7. Hero & layout (portrait) + clutter caps
**The hero is the living city** — the brightest, most-alive thing on screen, occupying the upper ~half of the stage; the demand curve is its luminous trace directly beneath, visually the city's instrument needle (gold, glowing, but subordinate to the lit city). During `secondDay` the city sits mostly in night, so the two gold curves naturally take focus without ever being "brighter chrome". Everything else recedes: near-black `#070A1C` base, radial vignette darkest behind the city band, glass fills `0x14FFFFFF` / borders `0x26FFFFFF`, ≤20 ambient/steam particles at once. The one orchestrated moment is the evening-peak wave.
**Clutter caps (enumerated per phase):** `firstDay` — scrubber track (1) + play/pause (2). `explore` — scrubber (1) + 4 markers (≤5); play/pause hidden; after the peak is witnessed the fact chip joins, but at most 3 unconsumed markers can remain → ≤6. `secondDay`/`synthesis` — fact chip only (scrubber locked). **Never >6 interactive elements; exactly 1 live number (DEMAND); one current text line.** Back button, board strip, and CTA are chrome, not counted as concept elements.

## 8. Reward
**No card.** "Demand follows human routines" is NOT a row in the curriculum quick-reference table (EP4's rows are: the grid · frequency · baseload/peaking), and the context-pack expected-card list for EP4 confirms 4.3 earns none. The activity's reward IS the second-day overlay (Discovery 2) plus the felt peak climax and the one capture; the trough's "floor" line quietly seeds 4.4 (baseload), whose PRD owns that card.
**Inline fact:** exactly one — the TV-pickup kettle chip (§5): glanceable, tap-to-expand, never a gate, specific + surprising, and not a restatement of the lesson (it explains a particular spike, not "demand follows routines"). Deliberate single fact; an empty slot would also have been fine.

## 9. CER capture hook (reconciled to the LOCKED EP4 catalog)
This beat fires **exactly one capture**, matching `prd_make_your_case_ep4.md` §3.1 verbatim:
- **`same_shape_next_day`** — label: **`Same Shape Tomorrow`** (the 3-word form locked by the CER owner; not "Same Shape") · caption: *Two days traced: the demand curve repeats its shape but never its exact line — so operators forecast it, then chase it.* · **relevant: true** · accent `#E8C98A` board gold · sourceLabel `ACT 4.3` · fires **300 ms after day two's trace completes** (step 10, one-way latch), framing the curve panel (proposed `cropFactor` ≈ `Rect.fromLTRB(0.02, 0.52, 0.98, 0.92)`).
- **DROPPED:** `evening_peak_cause` (CER §3.3 item 3). The peak micro-replay keeps its `heavyImpact` + discovery ring at DEMAND ≥ 97; it makes NO `onCapture` call. Do not add a second capture.

Wiring per the shipped pattern (verbatim, copy this): wrap the background + GameWidget in `RepaintBoundary(key: _sceneKey)`; `final _board = EpisodeBoardCapture('episode4_electricity')..load();`; `controller.onCapture = _onCapture` where
```dart
void _onCapture(String id) {
  HapticFeedback.lightImpact();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final bytes = await captureScenePng(_sceneKey,
        cropFactor: evidenceByIdFor('episode4_electricity', id)?.cropFactor);
    if (!mounted) return;
    _board.capture(id, imageBytes: bytes);
  });
}
```
Show `EpisodeBoardStrip` pinned under the header with the EP4 question, gold accent. The capture is idempotent and never blocking; replaying any marker never affects it. (No `evidenceByIdFor` lookup will resolve `evening_peak_cause` — it is not in the catalog, so even a stray call would no-op; do not make one.)

## 10. Build notes
- **Flame `GameWidget`** (living scene: sky, three-depth-band city with role-typed window grid, particles, the live-traced curve) + Flutter overlay chrome — the `trace_it_back` / `source_personalities` template. GameWidget built once in `initState`; transparent `backgroundColor`; `onGameResize` → `controller.setStageSize`; `update(dt)` guards `dt > 0 && dt < 0.1` → `controller.tick(dt)`. The curve panel is a Flame layer in the SAME canvas so one `RepaintBoundary` covers the capture.
- **Reuse / adapt from `source_personalities`:** `widgets/time_scrubber.dart` (copy-adapt to a controller-generic `DayScrubber`; full 24 h window; same drag-pauses/release-resumes transport + clock readout), `game/components/town_layer.dart`'s building / window-grid construction (depth bands, wake thresholds, streetlights, town bloom) and `game/components/sky_layer.dart`'s day/night gradient + sun/moon. **Do NOT reuse** its supply-driven lit-state ladder (dim/flicker/blackout) — windows here express ROUTINE (occupancy), not power availability. Window roles assigned at build: bottom-floor warm kitchens `#FFC976`, mid-band cool offices `#CFE0FF` (clustered downtown center), upper warm homes `#FFE3A0`, cyan AC strips `#7FE7FF` under ~30% of home windows; hospital cross + fridge glimmers for the floor. The `power_readout.dart` trend-arrow chip is the precedent for the DEMAND chip (single relative number + ↑/↓).
- **Gesture stays in Flutter:** a transparent `Listener` over the GameWidget forwards taps; the controller hit-tests marker positions (explore phase only). Scrubber / play-pause are Flutter widgets below the stage. **No Forge2D**; all motion controller-driven; transports are chase-rate-limited eases, never teleports; the day clock advances directly in `tick`.
- **Sim (controller + pure functions in `day_model.dart`):** `demandShape(t)` — smooth piecewise: 48 falling at 00:00 → 35 floor 02:00–04:30 → logistic surge centered 06:45 to 72 by 09:00 → plateau 74–76 till 16:30 → climb to 100 at 18:45 → fall to 55 by 23:30; `wiggle(t, seed)` — deterministic multi-octave noise ±2.5 (the `source_personalities` gust-function precedent: suspenseful, not a tidy loop); day-2 = `demandShape` with seeded deviations (peak shift ≤30 min, amp ±4, fresh wiggle). City channels derived from `t` (kitchen/office/home/ac/streetlight/sleep envelopes), `townGlow` loosely ∝ demand (a mood, never a readout).
- **Haptics:** `selectionClick` on marker taps + per 3 h scrub detent; `heavyImpact` at the peak climax (DEMAND ≥ 97); `lightImpact` inside `_onCapture`. **Audio: silent** (shipped electricity precedent). **Persistence:** the evidence board only (no deck — no card).
- **Reduced motion** (`MediaQuery.disableAnimations`): window cascades become opacity fades, steam / AC shimmer static, marker pulse → steady glow ring, transports plain eases — but same-frame co-variance and the four felt causes are untouched (never soften the pedagogy).
- Wrap the screen in `MediaQuery(...textScaler: TextScaler.noScaling)`. Completion = `Navigator.maybePop`. **Write ONLY inside `lib/screens/missions/demand_curve/`**; registry / evidence-catalog / wowConcepts edits belong to other phases — if a shared file must change, STOP and report it. Verify: `fvm dart analyze lib/screens/missions/demand_curve` clean.

## 11. Acceptance criteria (pedagogy encoded as testable checks)
1. **Discoverable from interaction alone:** with all text ignored, scrubbing back and forth shows city and curve co-vary — windows, cursor height, and the DEMAND number move in the SAME frame as the thumb; tapping any pulsing marker produces a visible cause in the city with zero reading required.
2. **Causes live in the scene, never a list:** each micro-replay shows the named group changing (kitchens cascade / offices hold while homes dim / the everyone-home wave + AC / the 3am floor) while the cursor climbs or flattens in lockstep; no bullet list, icon legend, or cause menu exists anywhere.
3. **Felt before named:** L3–L6 and the marker micro-labels appear only AFTER their replay completes; markers are unlabeled rings until witnessed; nothing pre-announces the peak's cause before it is seen.
4. **The trace is live, never pre-drawn:** the curve exists only up to the time reached; transports sweep intermediate states at the capped rate (no teleporting cursor, no instantly-appearing curve segments).
5. **Held-constant is visible:** identical skyline and weatherless sky across both days; no supply / balance / blackout state appears anywhere (no frequency chip, no flicker-from-shortage) — the only mover is the clock.
6. **Same shape, never the same line:** day two visibly deviates (peak time shift ≤30 min; instantaneous deviation from the ghost between 1 and 8 relative units somewhere in every 3 h span) while preserving move order and approximate levels; the two-curves state is reachable ONLY after all four causes are witnessed.
7. **Exactly 1 live number** (DEMAND, relative, day-peak = 100, with trend arrow); the clock lives only inside the scrubber; no ratings table, no percentages, no cause counts, no absolute units.
8. **The trough line names what stays on (destination), not an ending:** L3 verbatim — never "demand goes away / stops". No rhyme or sing-song cadence in any line.
9. **Gates:** `secondDay` is locked until `witnessed.length == 4`; the fact chip never gates anything and is absent until the peak is witnessed; Continue appears only after L9's hold; pop completes the activity.
10. **Capture fires exactly once,** at its specified latch (day-2 trace complete +300 ms), with the board flash + light haptic; the tile appears on the board strip with label `Same Shape Tomorrow`. **The peak replay fires `heavyImpact` + the discovery ring at DEMAND ≥ 97 but makes NO `onCapture` call** (reconciliation check — §9). Replaying a marker never fires any capture or re-fires a label.
11. **Clutter caps hold in every phase** (§7 enumeration); the city is the brightest element; ≤20 particles; reduced-motion honored without weakening checks 1–4.
12. `fvm dart analyze lib/screens/missions/demand_curve` clean; small-phone portrait (≈360×640 logical) keeps city band + curve panel + scrubber all visible without shrinking markers below a usable hit size.

## 12. Anti-patterns (this activity)
- A text/icon list of causes, a legend, or labeled markers before witnessing — the city IS the explanation.
- Any supply-side leakage: frequency readouts, brownout flicker, blackout states, "the grid is straining" cues — that is 4.1 / 4.2 / 4.5's business; here the lights always follow routine.
- A pre-drawn curve image, or a curve that appears / teleports instead of tracing — kills "living".
- Day two identical to day one (kills "constantly moving") or wildly different (kills "predictable in shape").
- A second number (occupancy %, homes-on count, kWh) or absolute units — DEMAND relative is the only number.
- **Re-adding the `evening_peak_cause` capture** — the EP4 catalog dropped it; the peak stays a felt climax only.
- Making the TV-kettle fact a gate, a quiz, or auto-expanding it — it must stay glanceable and skippable.
- Weather, traffic, or seasonal cues that confound causes — the only variable is the clock.
- Smoothing / tweening the city's response so it lags the cursor — cause and curve must be glued same-frame.
- A premium fade that hides the everyone-home wave's suddenness, or markers that lock after one tap.

## 13. Open decisions
1. Day window start: proposed 00:00→24:00 (calendar day; the trough marker sits cleanly at x ≈ 0.15). Alternative 04:00→04:00 starts at the trough but crams it against the right edge — flagged, default stands.
2. Whether scrubbing stays enabled during `secondDay` (proposed: locked, dimmed — the overlay is a watched payoff) — build may unlock after L9 for free replay.
3. The kettle-spike flourish on fact expansion (proposed in; cut if the ghost-curve frame gets busy on small phones).
4. Final `cropFactor` + final tile copy: the EP4 evidence-catalog agent owns finals; the §9 value and the locked label/caption are the proposal it confirms.
5. Exact replay-window rates / durations and the DEMAND wiggle amplitude (±2.5) — tune on device so the number visibly never freezes without reading as noise.
6. Whether the peak climax keeps the discovery ring now that it captures nothing (proposed: keep — it is the felt 6pm beat and 4.3's emotional center, even though the capture moved to other beats).

## 14. State machine sketch
```dart
enum DCPhase { intro, firstDay, explore, causeReplay, secondDay, synthesis, closing }
enum DCCause { trough, surge, plateau, peak }
enum DCCaption { none, l1Demand, i1Watch, l2NotRandom, i2TapMoves, l3Trough, l4Surge,
                 l5Plateau, l6Peak, l7People, i3Tomorrow, l8SameShape, l9Forecast }
```
`DemandCurveController extends ChangeNotifier`:
- **ValueNotifiers:** `caption: ValueNotifier<DCCaption>` (copy table flags imperative vs meaning + hold ms), `phase: ValueNotifier<DCPhase>`, `witnessedCount: ValueNotifier<int>`, `factVisible: ValueNotifier<bool>`, `factExpanded: ValueNotifier<bool>`, `canFinish: ValueNotifier<bool>`.
- **Hot-path getters (read by Flame layers):** `timeOfDay` (0–24), `dayIndex` (0/1), `dayProgress`, `demandNow`, `demandDisplay` (5 Hz sampled) + `trendUp`, `traceProgress` (high-water x of the day trace), `ghostOpacity`, `day2TraceProgress`, city channels (`kitchenLevel`, `officeLevel`, `homeLevel`, `acLevel`, `streetlightOn`, `sleepDim`), `spotlightCause` / `discoveryDim`, `markerPos(DCCause)` + `markerWitnessed(DCCause)` + `markerPulse`, `cursorPos`, `hairlineTop`, `peakRingAnim`, `spikeAnim`, `flashIntensity`, entrance reveals (`skyReveal`, `cityReveal`, `panelReveal`).
- **Input:** `onScrub(double fraction)` / `onScrubStart()` / `onScrubEnd()` (pause / scrub / resume; cursor chases the thumb ≤6 h/s; detent haptic per 3 h via `onDetent`); `setPlaying(bool)`; `onTapDown(Offset local)` → marker hit-test (radius 0.06 w, explore only) → `_startReplay(cause)`; `onFactTap()`.
- **Timers (`_schedule(ms, fn)`):** intro 700 → L1 (3200) → I1 + `firstDay`; day end → 400 → L2 (3000) → I2 + `explore`; per replay: eased transport (≤8 h/s) → windowed play (trough 2.0 s · surge 2.0 s · plateau 2.0 s · peak 2.5 s) → cause line (3400–3600) → back to I2; 4th witness → 600 → L7 (3000) → I3 (1200) → `secondDay` (~9 s @ 2.6×) → capture +300 → L8 (3600) → L9 (3400) → +400 `canFinish = true`. `tick(dt)` advances the clock, traces, reveals, pulses, particles, the 97-crossing climax, and the 5 Hz number sample.
- **Latches (one-way):** `_peakClimaxed` (DEMAND ≥ 97 inside the peak replay) → `heavyImpact` + discovery ring **(NO capture)**; `_overlayCaptured` (day-2 trace complete +300 ms) → `onCapture('same_shape_next_day')`; per-cause `witnessed` set (labels / L-lines fire once; replays re-run freely).
- **Gating:** markers tappable iff `phase == explore`; `secondDay` iff all 4 witnessed; scrubber enabled in {`firstDay`, `explore`}; play/pause visible only in `firstDay`; fact chip iff peak witnessed; Continue iff `canFinish`.
- **Hooks:** `onDetent` (selectionClick), `onMarkerTap` (selectionClick), `onPeakClimax` (heavyImpact), `onCapture(String id)` (lightImpact + PNG in shell). `reducedMotion: bool` set from MediaQuery each build.

## 15. File plan (mirror `source_personalities` / `trace_it_back`)
```
lib/screens/missions/demand_curve/
├── demand_curve_screen.dart            — shell: noScaling MediaQuery, RepaintBoundary(_sceneKey) around
│     background + GameWidget, transparent Listener (marker taps), header (back; title "The Living Curve",
│     eyebrow EPISODE 4 · THE GRID), EpisodeBoardStrip (EP4 question, gold accent), _FadeSwapCaption top
│     text (fixed height, 190 ms swap), DayScrubber row, fact chip overlay, fixed-height CTA seat,
│     CaptureFlash; EpisodeBoardCapture('episode4_electricity').load(); Continue → Navigator.maybePop
│     (NO card overlay)
├── state/demand_curve_controller.dart  — ChangeNotifier per §14 (clock, traces, phase machine, latches,
│     marker hit-tests, geometry via setStageSize)
├── state/day_model.dart                — pure functions: demandShape(t), wiggle(t, seed), day-2 deviation,
│     city channel envelopes (kitchen/office/home/ac/streetlight/sleep)
├── config/demand_curve_tuning.dart     — DCTune: dayLengthSeconds 24 · day2Rate 2.6 · scrubChase 6 h/s ·
│     transport 8 h/s · replay windows+rates · marker times {2.5, 6.75, 13.0, 18.5} · hit radius 0.06 w ·
│     peakClimaxAt 97 · wiggleAmp 2.5 · day2 peakShift/ampJitter · all timer ms · anchors (§16) · particleCap 20
├── config/demand_curve_beats.dart      — DCCaption enum + verbatim copy table (§5) + isImperative + holds
├── game/demand_curve_game.dart         — FlameGame: transparent bg, layers back→front, onGameResize →
│     controller.setStageSize, update → controller.tick
├── game/components/sky_layer.dart      — weatherless day/night gradient + sun/moon arc (adapt
│     source_personalities sky_layer; NO haze/pollution)
├── game/components/city_layer.dart     — THE HERO: 3 depth bands, role-typed window grid (kitchen/office/
│     home/AC), kettle-steam puffs, streetlight cones, hospital cross, fridge glimmers, everyone-home wave,
│     spotlight dim (adapt town_layer construction; routine-driven, NOT supply-driven)
├── game/components/curve_layer.dart    — live trace + ghost + day-2 trace, cursor + hairline into the city,
│     DEMAND mono chip + trend arrow, 4 markers (pulse → dot + micro-label), peak discovery ring, kettle spike
└── widgets/
    ├── day_scrubber.dart               — adapted TimeScrubber: 24 h track gradient (night→day→dusk→night),
    │     clock + period readout, drag-pauses / release-resumes, play/pause (firstDay only), lock state
    └── energy_field_background.dart    — static dark vignette + faint circuit texture (copy-adapt)
```

## 16. Scene sketch (portrait, top → bottom; factors of stage size w × h)
1. **Header** (SafeArea): back button on glass; title "The Living Curve" (Bricolage 21 w800); mono eyebrow `EPISODE 4 · THE GRID`.
2. **EpisodeBoardStrip** — the EP4 question pinned + captured mini-tiles (gold accent); it must wrap the long question, never truncate.
3. **Top text** — fixed-height (~96) caption seat: imperatives Bricolage 28 w800 / meaning-lines PJS 18 (L1/L4/L6/L8/L9 render ~16.5).
4. **Stage (Expanded):** sky y 0–0.18 h (sun/moon arc apex y 0.05 h, tied to the clock); **city band** y 0.10–0.52 h — horizon/kerb y 0.52 h; far band rooftops from y 0.30 h, mid from 0.22 h, near from 0.14 h (reuse `town_layer` row construction: gaps 0.013–0.02 w, widths 0.045–0.12 w); the downtown office cluster centered x 0.40–0.65 w in the mid band; streetlights along the kerb every ~0.16 w; hospital cross on one mid building x ≈ 0.78 w; vignette darkest behind the city. Spotlight dim = a full-stage scrim with the cause group exempted.
5. **Curve panel** y 0.56–0.88 h: baseline y 0.86 h; demand 0→100 maps y 0.86→0.58 h; time 00:00→24:00 maps x 0.06→0.94 w; markers at x ≈ 0.152 (02:30) / 0.307 (06:45) / 0.537 (13:00) / 0.738 (18:30), micro-labels 0.012 h below; cursor = glowing dot + 1.5 px hairline rising to the kerb (y 0.52 h); the `DEMAND` chip floats 0.015 h above-right of the cursor, clamped inside the panel; ghost + day-2 traces share the panel; the fact chip is pinned top-right (right edge x 0.94 w, y 0.575 h); kettle spike on the ghost at x ≈ 0.78–0.82 w; the `same_shape_next_day` capture crop ≈ this panel (Rect.fromLTRB 0.02, 0.52, 0.98, 0.92).
6. **Scrubber row** (~48 px): clock / period readout left · 24 h gradient track center · play/pause right (firstDay only; dimmed lock state in later phases).
7. **CTA seat** (fixed 84): the gold gradient `#F5C451 → #D9A43B` Continue pill once `canFinish`.
All geometry is factor-based off `setStageSize`; nothing is fixed-pixel except hairline / stroke widths.
