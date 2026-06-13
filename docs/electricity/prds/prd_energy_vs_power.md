# PRD — Energy, Not Power (Episode 5, beat 5.1)
### howwow electricity · registry id `energy_vs_power` · `EnergyVsPowerScreen` · `lib/screens/missions/energy_vs_power/` · evidence episode `episode5_electricity`

Binding context: `docs/electricity/context_pack.md`, `docs/electricity/architecture_reference.md`, curriculum §1–§9 + beat 5.1. This PRD is self-contained: every on-screen line is quoted verbatim here.

**What this beat inherits (already felt):** 2.5 — the fixed-area rectangle (power = voltage × current; taller means narrower when the area is pinned) and the phrase "the transmission trick"; power as a live readout quantity since 1.2 ("POWER" chips) and as a named product since 2.5. EP4 — peakers/baseload economics (NOT used here; 5.2 owns it).
**What this beat pins (held constant, visibly):** each appliance's power rating — the live rectangle's height NEVER moves while its width (time) is dragged, and the POWER chip stays frozen at the appliance's rating; the heater's finished energy — after its run it freezes as an unchanging ghost outline while the learner varies the bulb; the price of a unit of energy — flat and invisible here (no time-of-day pricing exists on this screen), so 5.2's "6pm costs more" reads later as a new variable, not a contradiction.

---

## 1. One-concept statement
**You pay for energy — power times time, the kilowatt-hour — not power alone.**

## 2. Guiding-question link + CER contribution
Episode 5 question (pinned on the board strip all activity): *"Who pays for all this — and why does 6pm cost more than 3am?"* (final phrasing owned by the finale CER PRD).
This beat supplies the "what you actually pay for" half of the episode's claim. Both its evidence tiles are **relevant** — no distractor comes from this activity (EP5's two true-but-irrelevant distractors are owned by other beats' PRDs, e.g. 5.3/5.4 candidates).
- `one_kwh_either_way` (relevant) — captured at the match: ten bulb-hours equal the heater's half hour; same area.
- `bulb_beats_heater` (relevant) — captured at the overshoot: left on all day, the small bulb out-costs the powerful heater.

## 3. The felt discovery (discovery → reaction)
**Discovery:** the learner drags the time edge of a low 100-power rectangle wider and wider, chasing the blazing tall sliver the 2000-power heater swept in its half-hour burst — and the two utterly different shapes come out EQUAL in area.
**Reaction:** at equality the system latches (snap + flash + heavy haptic) and the heater's ghost rectangle visibly reshapes — taller-or-wider, area held every frame — until it lies exactly on the bulb's strip: the 2.5 move replayed on the bill's quantities. Then the learner keeps dragging: the gold fill spills past the heater's outline — the dim little bulb has now cost more than the 2000-power monster. Along the way the meter disc made the rates felt: a slow turn for the bulb, a 20× whirl for the heater — yet the whirl bought no bigger bill than the slow turn run long enough.

## 4. Felt vs named vs numbered
**Felt (in the scene, never numeric):** power as a rate — meter-disc spin speed + wire pulse rate + appliance glow intensity (heater exactly 20× the bulb); energy as the AREA sweeping in gold; the heater's instant thermostat click-off (hard gate); equality as a geometric match + ghost morph; "costs more" as fill spilling past the HEATER outline (excess tinted hotter); the held-constant heights.
**Named (a beat after felt, except objects/arrangements named on sight):** the appliances and their printed ratings (L1, on sight — ratings are printed on real appliances); the rectangle's return (L2, on sight — a known object); height = power, the rating (L3, after the strip is swept); area = energy, what the meter counts (L4); power is a rate — how fast (L6, only after BOTH meter speeds are felt); the **kilowatt-hour** (L8, only after equality is felt); the fixed-area rhyme with the transmission trick (L9, during the morph); the law, named last (L11).
**Numbered (exactly 2, live, mono chips riding the live rectangle's edges — the same two chip positions as 2.5):** `POWER 100`/`POWER 2000` (left of the power edge) and `TIME 7.5h` (below the time edge, 0.5h precision). The chips always describe the LIVE rectangle only. Real watts live in prose (L1/L3), not on the chip. **No energy number, no cost number, no revolutions counter, no axis tick numbers, no ratings table.** The area is the energy readout; the meter and the geometry are the cost readout.
**Depth-stops: none.** Fully explainable — multiplication all the way down (curriculum: EP5 has no depth-stops).

## 5. On-screen text (exact, complete)
Imperatives: Bricolage Grotesque ~28 w800, Title Case, ≤5 words. Meaning-lines: Plus Jakarta Sans ~18 (long lines auto-shrink), de-personified facts. Swap = 190 ms fade-out → swap → fade-in.

| id | kind | text |
|---|---|---|
| L1 | meaning (cast named on sight) | A 100-watt bulb and a 2000-watt heater share one meter. Whatever the meter counts, the bill charges. |
| L2 | meaning (the return, named on sight) | The rectangle from the transmission trick is back — new sides this time. |
| I1 | imperative | Run the Bulb |
| L3 | meaning (height + the pin) | The strip's height is the bulb's power — the 100-watt rating printed on it. The height never moves; only the hours do. |
| L4 | meaning (area named, names the destination) | The width is the hours it runs. The area swept is the energy used — and the meter counts energy. |
| I2 | imperative | Fire the Heater |
| L5 | meaning (the click-off) | Half an hour and the room is warm — the heater clicks off on its own. |
| L6 | meaning (power-as-rate, after both speeds felt) | Twenty times the bulb's power, so the meter spun twenty times as fast. Power is a rate — how fast energy is drawn. |
| I3 | imperative | Match the Heater |
| L7 | meaning (THE DISCOVERY, names the consequence) | Ten hours of the bulb hold exactly as much energy as the heater's half hour. Same area — same charge on the bill. |
| L8 | meaning (the kWh named) | Energy is power times time. One kilowatt for one hour is one kilowatt-hour — the unit the bill counts. Both rectangles hold exactly one. |
| L9 | meaning (the 2.5 rhyme, during the morph) | Tall and brief or low and long — the area holds. The same fixed-area rectangle from the transmission trick now prices the bill. |
| I4 | imperative | Now Leave It On |
| L10 | meaning (the catch, names the consequence) | Past the heater's outline, the bulb has used more. Left on all day, the small appliance costs more than the powerful one used briefly. |
| L11 | meaning (the law, named last) | You pay for energy — power times time, the kilowatt-hour — not for power alone. |

Ghost label (mono, IBM Plex Mono ~11, letter-spaced): `HEATER` inside/beside the ghost outline (no numbers on it). Card-earn brag line: `You out-billed a 2000-watt heater with a 100-watt bulb.` CTA: `Continue`. No other text exists. No mascot, no info-cards, no inline fact (deliberate empty slot — L8 already carries the real-world unit and L10 the home consequence; a fact chip would crowd the discovery chain).

## 6. Beat-by-beat flow (timing + gating)
Phase **intro** (auto, ~7 s):
1. 0 ms — scene entrance (slide+scale+fade ≤450 ms, staggered ≤400 ms): appliance band (bulb · meter · heater, wired together), axes draw in below, the live rectangle appears at the origin as a glowing power edge at height 100 with width 0 (a rating, not yet a cost), POWER/TIME chips fade in (`POWER 100` · `TIME 0.0h`).
2. 900 ms — L1 (hold 3200 ms).
3. 4100 ms — L2 (hold 3000 ms).
4. 7100 ms — I1 "Run the Bulb"; the drag handle on the rectangle's right (time) edge pulses (scale 1.0→1.15 loop until first drag). **WAIT for the learner. Drag armed from this moment.**

Phase **bulbRun** (interactive):
5. Horizontal drag on the handle (generous hit zone) maps to hours, clamped 0–24. **Same-frame** updates: strip width + gold fill sweep, TIME chip, bulb glow, meter spin, wire pulses. The bulb glows and the meter turns ONLY while the area sweeps forward; on pointer-up (or reverse drag) glow/spin snap off instantly. Meter rate ∝ live power, never drag velocity (§10). `selectionClick` per 1 h detent crossed. Fully reversible — dragging left un-sweeps the area.
6. Felt-latch — cumulative forward-swept hours ≥ 2.0 (one-way): +400 ms → L3 (hold 3400 ms) → L4 (hold 3400 ms) → I2 "Fire the Heater"; the heater pulses softly (tap affordance); heater tap armed. Bulb drag stays armed.

Phase **heaterRun** (one-shot auto, ~3 s + lines):
7. Tap the heater (`selectionClick`) → bulb drag disarmed for the run → the heater blazes: chips swap to `POWER 2000` · `TIME 0.0h→0.5h`; a tall sliver sweeps from the origin over 2600 ms (full height, hairline width, additive fill); the meter whirls at exactly 20× the bulb's rate; wire pulses race; heater element glows fierce.
8. 2600 ms — **CLICK-OFF, a hard gate:** heater glow, meter whirl, and wire pulses snap to ≤2 % within 50 ms (no fade, reduced-motion included). The sliver's fill crystallizes into a cool ghost OUTLINE labeled `HEATER` (300 ms) and freezes permanently. Chips return to the live bulb rect. Heater becomes inert (dim "room is warm" state; re-taps do nothing).
9. +300 ms — L5 (hold 3000 ms) → L6 (hold 3600 ms) → I3 "Match the Heater"; bulb drag re-armed; match latch armed (if the learner is already inside tolerance when armed, it fires immediately).

Phase **match** (interactive):
10. As the bulb's area nears the ghost's, the ghost outline brightens (proximity glow, peak at equality) — a warmer/colder cue needing no text.
11. **DISCOVERY latch** — |bulb energy − heater energy| ≤ 0.04 kWh (T ∈ [9.6, 10.4] h), one-way: time snaps to exactly 10.0 h (≤120 ms ease), `heavyImpact`, drag disarmed; +180 ms → `onCapture('one_kwh_either_way')` (lightImpact + capture flash — frame holds BOTH shapes: tall ghost + wide strip, equal areas).
12. +600 ms — L7 (hold 3600 ms) → L8 (hold 4200 ms) → **the morph** (1600 ms) with L9 (hold 3800 ms): the ghost reshapes continuously — every intermediate frame preserves its area within 1 % — from tall-and-narrow down onto the bulb's exact 10 h strip, glows once, and SETTLES in the wide shape (still outlined, still labeled `HEATER`). Reduced motion: 240 ms cross-fade tall→wide with the equality glow.
13. At L9 end — drag re-armed; I4 "Now Leave It On"; overshoot latch armed.

Phase **overshoot** (interactive):
14. Dragging past 10 h, the live gold fill spills PAST the heater outline; the excess area beyond the outline tints hotter (`#FF9B42`-leaning) — "more than the heater" is read geometrically, not stated by a number.
15. **Overshoot latch** — T ≥ 20 h (one-way): `onCapture('bulb_beats_heater')` (lightImpact + flash) → +400 ms → L10 (hold 3600 ms) → L11 (hold 3400 ms).

Phase **closing**:
16. +400 ms — `showCardEarn.value = true` → `CollectibleEarnOverlay` (kWh card, eyebrow `NEW CARD`, brag above, `showMascot: false`).
17. `onCardCollected` → `canFinish.value = true` → gold Continue CTA in its fixed-height seat → tap → `Navigator.maybePop(context)`.

All gates are high-water marks: once latched, reverse dragging never regresses a beat, caption, or capture; the fill/excess always updates live in both directions. Play length: ~7 s intro + 50–110 s interaction = 60–150 s.

## 7. Hero & layout (portrait) + clutter caps
**The hero is the energy rectangle** — the brightest, largest, manipulable thing on screen: warm gold `#FFD27A` fill with soft additive bloom on a near-black `#070A1C` field, radial vignette darkest behind the rectangle zone. It is the SAME visual object as 2.5's hero (same fill, same chip layout riding the edges) wearing new sides — the rhyme is structural, not asserted. The appliance band above is the compact consequence stage: bulb, meter, heater, small and quiet, glowing only while running; the meter disc is the rate's voice. The ghost outline is cool and dim (theBill accent `#E0A96D` at low alpha); chrome recedes (glass `0x14FFFFFF`, borders `0x26FFFFFF`); ≤16 ambient motes.
**Clutter caps:** 1 hero + **2 interactive elements** (the time-edge drag handle; the one-shot heater tap — back button, read-only board strip, and end-state CTA are chrome) — under the 6-element cap; **exactly 2 live numbers** (POWER, TIME); one current text line. Nothing else.

## 8. Reward — collectible card (concept IS a quick-reference row: "Total energy used = power × time | kilowatt-hour | Ep 5 | Fully explained (same rectangle as 2.5)")
Propose (shared-infra agent finalizes number/constant; section **theBill**, accent `#E0A96D`):
- **Front** — playful name: **Pay for the Area** · real term (mono specimen label): **THE KILOWATT-HOUR** · law: *Energy is power times time — and the bill charges for energy, not power.* · kicker: *Why a bulb left on all day can out-cost a heater's burst.*
- **Back** — tie to what was FELT: *You stretched ten quiet bulb-hours until they held the heater's half-hour blaze — one kilowatt-hour, either shape.* · outward reach: *A monthly bill is a stack of these rectangles, added up.* · linked card: the 2.5 transmission-trick card ("Starve the Wire") — the fixed-area rectangle, second appearance (2.5's PRD already pre-wires this link from its side).
The card names the LAW; it does not re-narrate the activity, and it does not restate the 2.5 card's law (that card owns the fixed-power voltage/current inversion; this one owns energy = power × time and what is billed).
Inline fact: none (deliberate empty slot, §5).

## 9. CER capture hook (ids proposed for the EP5 evidence catalog — LOCK there)
- **`one_kwh_either_way`** — label: `Same Energy` · caption: *Ten hours of a 100-watt bulb equals the heater's half hour — one kilowatt-hour either way.* · **relevant** · fires at the match latch +180 ms (step 11), framing the rectangle zone with both shapes (proposed cropFactor ≈ Rect.fromLTRB(0.02, 0.36, 0.98, 0.99)).
- **`bulb_beats_heater`** — label: `Bulb Costs More` · caption: *Left on all day, the small bulb used more energy than the powerful heater's burst.* · **relevant** · fires at the overshoot latch (step 15), same rectangle-zone crop (excess tint + exceeded HEATER outline in frame).
Wiring per the shipped pattern: `RepaintBoundary(key: _sceneKey)` around background + GameWidget; `controller.onCapture = _onCapture` → `captureScenePng(_sceneKey, cropFactor: evidenceByIdFor(kEpisode5Id, id)?.cropFactor)` → `_board.capture(id, imageBytes: bytes)`; `EpisodeBoardStrip` pinned under the header with the EP5 question. Captures are idempotent and never block flow.

## 10. Build notes
- **Flame `GameWidget`** (living scene: meter disc, wire pulses, fill sweeps, ghost morph, motes) + Flutter overlay chrome — the trace_it_back/transmission_trick template. GameWidget built once in `initState`; transparent `backgroundColor`; `onGameResize` → `controller.setStageSize`; `update(dt)` guards `dt > 0 && dt < 0.1` → `controller.tick(dt)`.
- **Gesture stays in Flutter:** a transparent `Listener` above the GameWidget forwards `onPointerDown/Move/Up(Offset local)` to the controller; a down near the time handle (hit zone inflated to ≥44 px regardless of strip thinness) arms the drag; `dx → dT` (full stage-width drag ≈ full 24 h range); clamp [0, 24]; up freezes time exactly where the finger leaves it. The heater tap is a simple hit-test in `onPointerDown` while armed. **No Forge2D; no momentum.**
- **Sim (all in controller, config-tuned):** `pBulb = 100`, `pHeater = 2000`, `tMax = 24 h`, `heaterStop = 0.5 h`, energy `E = P·T` (kWh when P read as watts/1000 × hours — internal only, never displayed). Pixel mapping LINEAR on both axes (`heightPx = kP·P`, `widthPx = kT·T`) so on-screen area is mathematically ∝ energy — the equality is exact, not approximate. NO minimum-height visual floor that alters fill area; legibility of thin shapes comes from edge glow, never from area fudging.
- **Meter honesty rule (deliberate, document in code):** the disc's spin rate is ∝ the LIVE appliance's power while its area sweeps forward (bulb ≈ 0.3 rev/s, heater = exactly 20× ≈ 6 rev/s), and is NOT a function of drag velocity — otherwise a fast finger would out-whirl the heater and corrupt the felt 20× rate contrast. The meter is still (never reverses) on backward scrub.
- **Hard gates:** the heater click-off and every stop-sweep (pointer-up) snap glow/spin/pulses to ≤2 % within 50 ms — never a fade; reduced motion does not soften them.
- Haptics: `selectionClick` per 1 h detent and on the heater tap; `heavyImpact` at the match latch; `lightImpact` on captures (inside `_onCapture`).
- Audio: **silent** (matches most shipped electricity activities).
- Reduced motion (`MediaQuery.disableAnimations`): entrance reveals become fades; motes calmed; morph becomes the 240 ms cross-fade + glow; the meter's pedagogical spin and all same-frame causal updates are untouched.
- Wrap the screen in `MediaQuery(...textScaler: TextScaler.noScaling)`. Completion = `Navigator.maybePop`. Write ONLY inside `lib/screens/missions/energy_vs_power/`; reference the kWh card constant and EP5 evidence ids — never define them locally. Verify: `fvm dart analyze lib/screens/missions/energy_vs_power` clean.

## 11. Acceptance criteria (pedagogy as testable checks)
1. **Discoverable from interaction alone:** with all text ignored, dragging the pulsing handle grows the strip, lights the bulb, spins the meter, and ticks the TIME chip; tapping the pulsing heater fires its burst — the full power×time=area relationship is enacted with zero reading.
2. **Same-frame causality:** strip width/fill, TIME chip, bulb glow, meter spin, and wire pulses update in the SAME frame as the drag; the click-off and pointer-up cutoffs reach ≤2 % within 50 ms — no fade tail, reduced-motion included.
3. **Area honesty:** both axes are linear; displayed pixel area is ∝ P×T within 0.5 % at every drag position; every frame of the ghost morph preserves the ghost's pixel area within 1 %; no visual floor alters fill area.
4. **The 20× rate contrast is exact and incorruptible:** heater disc rate = 20.0× bulb disc rate; disc rate is independent of drag velocity; the disc never spins on reverse scrub.
5. **Naming order is felt-first:** L3/L4 fire only after ≥2 h swept by the learner's own drag; L6 (power-as-rate) fires only after BOTH meter speeds have been seen; L8 (kilowatt-hour) fires only after the equality latch; L11 (the law) is last.
6. **No pre-spoiling:** no text or visual before the match latch hints the areas will be equal (the ghost's proximity glow is permitted — it cues closeness, not the conclusion); nothing before the overshoot latch hints the bulb can cost more.
7. **Catch/consequence lines name consequence/destination:** L7 lands on "same charge on the bill", L10 on "costs more" — never behaviour/ending phrasing; no rhyme anywhere.
8. **Exactly 2 live numbers** (POWER, TIME chips on the live rectangle only); no energy, cost, kWh, or revolutions numeral anywhere on screen (the kWh exists only in prose L8/L11); no axis tick numbers; no ratings table.
9. **Held-constants visible:** the strip's top edge stays at the same height through the entire drag; the POWER chip never changes during an appliance's run; the ghost is frozen and labeled while the learner varies the bulb.
10. **Latches are exact and idempotent:** the match latch snaps TIME to exactly 10.0 h, fires `heavyImpact` once and `one_kwh_either_way` once with both shapes in frame; the overshoot latch at ≥20 h fires `bulb_beats_heater` once; reverse dragging never regresses captions, beats, or captures; a condition already true when its latch arms fires immediately.
11. **The rhyme is shown, not just said:** at the match, the tall ghost and wide strip coexist on the same axes; the morph passes through intermediate taller-or-wider shapes; L9 (verbatim) plays during it.
12. **Hero dominance:** the rectangle zone is the brightest, largest element; the appliance band is compact and recedes when idle; ≤2 interactive elements; ≤16 motes; reduced motion honored without weakening checks 2–4.
13. `fvm dart analyze lib/screens/missions/energy_vs_power` is clean; small-phone portrait (≈360×640 logical) keeps the handle ≥44 px, both chips legible, and the thin shapes readable via edge glow.

## 12. Anti-patterns (this activity)
- A live energy/cost/kWh counter ticking upward — a third number that demotes the area; the geometry and the meter ARE the readouts.
- Meter spin tied to drag speed — lets a fast finger "beat" the heater and falsifies the rate lesson.
- Letting the heater run for arbitrary hours — the thermostat click-off is the honest constraint that creates the fixed reference energy; without it the comparison collapses.
- A premium fade on the click-off or the pointer-up stop — instant cutoffs are hard gates.
- Pre-spoiling: any intro text or demo animation revealing the equality or the bulb-out-costs-heater twist before it is dragged into existence.
- Nonlinear/log axes, a minimum-height fill floor, or tweened "approximate" areas — if pixel area isn't exactly ∝ energy, the match and the morph are lies.
- Making the appliances or the meter the hero (detailed room art, big glows while idle) — they are a compact consequence band; the rectangle is the hero.
- A cost bar chart or side-by-side "bill comparison" panel — a ratings-table cousin; the exceeded outline carries the comparison.
- Re-deriving 2.5 here (it owns voltage × current); L9 cites the rectangle's return, nothing more.
- Addressing the learner as a child, exclamation marks, or sing-song in any meaning-line.

## 13. Open decisions
1. POWER chip units: proposed bare relative `POWER 100`/`POWER 2000` with watts carried in prose (L1/L3), mirroring 2.5's unitless chips; flip to `100 W` only if the team prefers literal ratings on the chip (the numbers are real watt ratings either way).
2. Heater proximity-glow curve for the match cue — strength/falloff tuned on device so it cues without shouting.
3. Final cropFactors and id LOCK for the two tiles (EP5 evidence-catalog agent owns; proposals in §9).
4. Card constant name (`kPayForAreaCard` proposed), number, and the link wiring to the 2.5 card — shared-infra agent owns.
5. Thin-shape legibility on small phones (bulb strip ≈ 0.025 stage-h; heater sliver ≈ 0.018 stage-w): tune edge-glow width on device — area fudging stays banned.
6. Overshoot gate at 20 h vs 24 h ("all day"): proposed 20 h so the latch fires with drag travel to spare; L10's "left on all day" stays honest at either value.

## 14. State machine sketch
```dart
enum EvpPhase { intro, bulbRun, heaterRun, match, overshoot, closing }
enum EvpCaption { none, l1Meter, l2Return, i1RunBulb, l3Height, l4Area, i2FireHeater,
                  l5ClickOff, l6Rate, i3Match, l7SameEnergy, l8Kwh, l9Rhyme,
                  i4LeaveOn, l10CostsMore, l11Law }
```
`EnergyVsPowerController extends ChangeNotifier`:
- **ValueNotifiers:** `caption: ValueNotifier<EvpCaption>` (copy table marks imperative vs meaning per id), `phase: ValueNotifier<EvpPhase>`, `showCardEarn: ValueNotifier<bool>`, `canFinish: ValueNotifier<bool>`.
- **Hot-path getters (read by Flame layers):** `bulbHours` (0–24), `heaterHours` (0–0.5 during the run), `isHeaterLive`, `livePower` (100|2000), `liveRectPx`, `ghostRectPx` (morph-aware), `ghostMode` (none/tall/morphing/wide), `morphT`, `meterAngle`, `meterRate` (∝ livePower while sweeping forward, else 0), `bulbGlow`, `heaterGlow`, `wirePulsePhase`, `matchProximity` (0–1), `excessHours` (max(0, bulbHours − 10) after match), `handlePulse` (loops until first drag), `flashIntensity`, entrance reveals (`applianceReveal`, `axesReveal`, `rectReveal`), `motes`.
- **Input:** `onPointerDown/Move/Up(Offset local)` — down inside the handle hit zone (≥44 px) arms the drag (only in bulbRun/match/overshoot and not during the heater run, the snap, or the morph); move maps `dx → dT` (full stage width ≈ 24 h); clamp [0, 24]; up freezes time, snaps glow/spin off. Down inside the heater hit zone while armed → `startHeaterRun()` (one-shot).
- **Timers:** `_schedule(ms, fn)` chain per §6 — intro 900/4100/7100 ms; post-felt-latch +400 → L3 (3400) → L4 (3400) → I2; heater run 2600 → click-off → +300 → L5 (3000) → L6 (3600) → I3; match latch → snap 120 → +180 capture → +600 → L7 (3600) → L8 (4200) → morph 1600 + L9 (3800) → I4; overshoot latch → +400 → L10 (3600) → L11 (3400) → +400 card. `tick(dt)` advances reveals, pulses, meterAngle (+= meterRate·dt), motes, morphT, the heater sweep, and latch checks.
- **Latches (one-way bools):** `_felt` (cumulative forward-swept hours ≥ 2.0); `_heaterDone` (run completes → ghost frozen); `_matched` (|E_bulb − E_heater| ≤ 0.04 kWh while armed → snap to 10.0 h, heavyImpact, `onCapture('one_kwh_either_way')`); `_overshot` (bulbHours ≥ 20 while armed → `onCapture('bulb_beats_heater')`). Arm-time check: if a latch's condition is already true when armed, fire on the arming frame.
- **Hooks:** `onDetent` (selectionClick per 1 h), `onDiscovery` (heavyImpact), `onCapture(String id)` (lightImpact + PNG in shell). `reducedMotion: bool` set from MediaQuery each build.

## 15. File plan (mirror transmission_trick / trace_it_back)
```
lib/screens/missions/energy_vs_power/
├── energy_vs_power_screen.dart           — shell: noScaling MediaQuery, RepaintBoundary(_sceneKey) around
│     background + GameWidget, transparent Listener forwarding pointers, header (back), EpisodeBoardStrip
│     (EP5 question), _FadeSwapCaption top text (fixed height ~96, 190 ms swap), fixed-height CTA seat (84),
│     CaptureFlash, CollectibleEarnOverlay; EpisodeBoardCapture('episode5_electricity').load(); maybePop
├── state/energy_vs_power_controller.dart — ChangeNotifier per §14 (sim + geometry + phase machine + latches)
├── config/evp_tuning.dart                — EvpTune: pBulb 100 · pHeater 2000 · tMaxH 24 · heaterStopH 0.5 ·
│     matchH 10 · matchTolKwh 0.04 · overshootH 20 · feltSweepH 2.0 · heaterRunMs 2600 · morphMs 1600 ·
│     snapMs 120 · detentH 1.0 · meterRevPerSecBulb 0.3 (heater = ×20) · kP/kT px factors · anchor factors
│     (§16) · all timer/hold ms · mote cap 16 · glow widths
├── config/evp_beats.dart                 — EvpCaption enum + verbatim copy table (§5) + isImperative flag +
│     hold durations
├── game/energy_vs_power_game.dart        — FlameGame: transparent bg, adds layers back→front, onGameResize →
│     controller.setStageSize, update → controller.tick
├── game/components/appliance_layer.dart  — bulb (shared paintBulb-style warm glow), heater (element bars,
│     fierce additive glow while live, instant snap-off), connecting wires with traveling pulses (rate ∝
│     livePower, only while sweeping forward)
├── game/components/meter_layer.dart      — compact meter: glass case, spinning disc (angle from controller),
│     subtle markings; the disc is the rate's voice — no counter, no numerals
├── game/components/rectangle_layer.dart  — THE HERO: axes (bare lines, no ticks), live rect (gold fill +
│     additive bloom + edge glow), POWER/TIME mono chips riding the edges (2.5 positions), time-edge drag
│     handle + pulse, excess-area hot tint past the ghost, discovery flash
├── game/components/ghost_layer.dart      — heater ghost: crystallize-from-fill (300 ms), cool `#E0A96D`-tinted
│     outline + faint fill, `HEATER` mono label, proximity glow, area-preserving morph tall→wide
└── widgets/energy_field_background.dart  — static dark vignette + faint circuit texture (copy-adapt from
      trace_it_back)
```

## 16. Scene sketch (portrait, top → bottom; factors of stage size w × h)
1. **Header** (SafeArea): back button on glass; title "Energy, Not Power" (Bricolage 21 w800); mono eyebrow `EPISODE 5 · THE BILL`.
2. **EpisodeBoardStrip** — EP5 question pinned + captured mini-tiles.
3. **Top text** — fixed-height (~96) caption seat: imperatives Bricolage 28 w800 / meaning-lines PJS 18 (L3/L8/L10 render ~16.5).
4. **Stage (Expanded), appliance band y 0.02–0.28 h:** bulb at x 0.10–0.24 w (bulb center ≈ 0.17 w, 0.15 h); meter at x 0.42–0.58 w (disc center 0.50 w, 0.14 h, radius ≈ 0.055 w); heater at x 0.74–0.92 w (body 0.74–0.92 w × 0.10–0.26 h, element bars horizontal); thin wires bulb→meter←heater along y ≈ 0.20 h carrying pulses while live. Band recedes (low alpha) when idle.
5. **Rectangle zone y 0.32–0.97 h (THE HERO):** axes origin at (0.10 w, 0.92 h); time axis → (0.94 w, 0.92 h) mapping 24 h to 0.84 w (`kT = 0.035 w/h` → heater sliver 0.0175 w, match width 0.35 w, full day 0.84 w); power axis ↑ (0.10 w, 0.40 h) mapping 2000 to 0.52 h (`kP = 0.00026 h/unit` → bulb strip 0.026 h, heater pillar 0.52 h). Live rect anchored at the origin; ghost shares the same origin (overlap is correct — same axes, same quantities). Drag handle = 0.09 w pill with right-chevron riding the live rect's right edge, vertically centered, hit zone ≥44 px. `POWER` chip left of the power edge's vertical midpoint (floats above-left of the origin when the strip is thin); `TIME` chip 0.02 h below the time edge's midpoint. `HEATER` label inside the ghost when wide, floating right of it with a pointer when tall/thin. Vignette darkest behind this zone.
6. **CTA seat** (fixed 84): gold gradient `#F5C451 → #D9A43B` Continue pill after card collection.
All geometry factor-based off `setStageSize`; nothing pixel-fixed.
