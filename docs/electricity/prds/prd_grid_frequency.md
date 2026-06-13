# PRD — Spinning Machines & Frequency (Episode 4, beat 4.2)
### howwow electricity · registry id `grid_frequency` · `GridFrequencyScreen` · `lib/screens/missions/grid_frequency/` · evidence episode `episode4_electricity`

Binding context: `docs/electricity/context_pack.md`, `docs/electricity/architecture_reference.md`, curriculum §1–§9 + beat 4.2. This PRD is self-contained: every on-screen line is quoted verbatim here.

**Chain inheritance (what the learner already felt):** 4.1 — production and consumption must stay equal continuously; mismatch tips the system fast, in either direction. The Prologue — the hand-crank lamp died the INSTANT the crank stopped (nothing stored). 2.7 — AC reverses 50 times a second (the number 50 has been met once, as the wave).
**What this beat pins:** the machine itself — one rotor, one wire, one town — never changes for the whole activity. Demand is the SYSTEM's variable (visible as the town's lit windows); input power is the LEARNER's variable (the spin gesture). In the let-go beat, demand is visibly frozen (window grid static) while input goes to zero, so the drain reads as one clean cause.
**What it loads forward:** frequency is the number 4.5's cascade trips on ("a big mismatch drags frequency too far"); "add power NOW" sets up 4.4's "fast enough, with the right kind of plant".

---

## 1. One-concept statement
**The balance is physical and instant because it is spinning mass with almost no give — and frequency is the live readout.**

## 2. Guiding-question link + CER contribution
Episode 4 question (pinned on the board strip all activity): *"The plant is making almost exactly what the whole city uses this very second — who decides that, and what happens at the 6pm rush?"*
This beat supplies the HOW-they-know half of "who decides": the balance is read instantly off one number, and the buffer behind that number is seconds deep. Both tiles are **relevant** — no distractor comes from this activity (EP4's 2 distractors are owned by other beats' PRDs; see §13.2 for an optional distractor candidate if the catalog needs one from here).
- `seconds_of_spin` (relevant) — the grid's only store is the machines' spin, and it holds seconds.
- `rush_hour_dip` (relevant) — the 6pm rush drags every generator down together; the falling number is the instant order to add power.

## 3. The felt discovery (discovery → reaction)
**Discovery 1 (the buffer, and its tininess):** the learner has spun a heavy rotor up to 50 and feels its mass (it takes seconds of real effort to get there). Told to let go — **reaction:** the town's lights STAY ON with nothing feeding them… for a few seconds, while the wheel visibly drains, the number sinking 50 → 47, the lights sagging into flicker. The spin is a store — and it is tiny. (Deliberate inversion of the Prologue's instant death: there, nothing was stored; here, a little is — and "a little" is the whole point.)
**Discovery 2 (the drag):** the learner holds the wheel at 50 with a steady effort; the town's windows sweep on (evening) — **reaction:** in the same frame, the wheel decelerates under their finger though they changed nothing. The extra energy is being dragged straight out of the spin. Demand drop reverses it: the wheel runs away above 50.
**Naming lands after both are felt:** the readout chip the learner has been staring at relabels `SPIN` → `FREQUENCY`. Then the 6pm rush makes them run the operator's loop themselves: dip seen → power in → 50 held.

## 4. Felt vs named vs numbered
**Felt (in the scene, never numeric):** the rotor's mass (slow spin-up under real effort; seconds-long drain); the drag of new load (same-frame deceleration); surplus (the wheel racing above 50, slight overspeed wobble); demand (the town's lit-window count sweeping up and down — never a number); strain (global dim + flicker below ~49, deep flicker below ~48); lockstep (ghost rotors dipping and racing in exact sync with the hero).
**Named (a beat after felt):** "the spin is the grid's only store" (L4, after the drain is felt); **frequency** (L7, chip relabel — the readout gets its name on screen at the same instant the word first appears); "lockstep" (L9, named as the ghost rotors appear — a visible arrangement, named on sight); "grid operators" (L11, after the learner has already done the job).
**Numbered (exactly 1, live, mono chip in-scene):** `SPIN 50.0` (relabels to `FREQUENCY 50.0` at L7), one decimal, sampled ~5×/s so it ticks legibly. **One number is itself the concept** — the whole balance reads off a single live figure, so the screen shows a single live figure. No demand number, no power number, no % load, no ratings table.
**Depth-stops: none.** Fully explainable — Episode 4 has no depth-stops; nothing here says or implies "nobody knows".

## 5. On-screen text (exact, complete)
Imperatives: Bricolage Grotesque ~28 w800, Title Case, ≤5 words. Meaning-lines: Plus Jakarta Sans ~18 (L8 renders ~16.5), de-personified facts. Swap = 190 ms fade-out → swap → fade-in.

| id | kind | text |
|---|---|---|
| L1 | meaning | Inside every big power plant sits tons of spinning metal. This wheel runs a town. |
| I1 | imperative | Spin It Up to 50 |
| L2 | meaning | The town below is running off this spin. |
| I2 | imperative | Hold It at 50 |
| I3 | imperative | Now Let Go |
| L3 | meaning (discovery — names where the power came from) | The lights stayed on with nothing feeding them — the town was draining the spin itself. |
| L4 | meaning (the buffer's size — names the consequence) | That spin is the grid's only store. It holds seconds, not hours. |
| I4 | imperative | Spin It Back to 50 |
| L5 | meaning (the drag — names the destination) | The town just asked for more — the extra energy is dragged straight out of the spin. |
| I5 | imperative | Spin Harder |
| L6 | meaning (surplus — names the destination) | Now the town wants less — the spare energy piles into the spin, and the wheel runs fast. |
| I6 | imperative | Ease Off |
| L7 | meaning (THE NAMING — fires with the chip relabel) | That spin speed is the grid's frequency — held at 50 hertz across all of India. |
| L8 | meaning (the readout law — the allowed-longer line) | Below 50, the country is pulling more than its plants are feeding. Above 50, the plants are feeding more than it uses. One number carries the whole balance, live. |
| L9 | meaning (lockstep, named on sight) | Every generator on the grid spins in lockstep — one shared spin, one shared number, across the whole country. |
| LR1 | meaning (rush setup) | Six o'clock. The whole city reaches home and switches on. |
| I7 | imperative | Catch the Dip |
| L10 | meaning (synthesis) | Demand moved first. The spin showed it the same instant. Power went in to answer. |
| L11 | meaning (operator mapping, outward landing) | Grid operators run this loop all day — watch the 50, add power the moment it dips. |

In-scene chip (IBM Plex Mono ~12, letter-spaced): `SPIN 50.0` → after L7 → `FREQUENCY 50.0`. Gauge has a glowing `50` notch and a calm band 49.5–50.5. Card-earn brag line: `You caught the 6pm rush at 50.` CTA: `Continue`. **The word "frequency" appears NOWHERE (chrome, title, chip, captions) before L7.** No mascot, no info-cards, no inline fact (deliberate empty slot — L11 carries the outward landing; the clock-drift fact lives on the card back).

## 6. Beat-by-beat flow (timing + gating)
Phase **intro** (auto, ~9 s):
1. 0 ms — entrance: rotor scales/fades in (450 ms), gauge arc draws around it (600 ms, +400 ms stagger), wire + town fade in (450 ms, +300 ms stagger). Rotor turns lazily at ~12 (below the band); town ~40 % windows lit, steady; chip reads `SPIN 12.4`.
2. 1200 ms — L1 (hold 3200 ms).
3. 4400 ms — I1 "Spin It Up to 50"; grab-hint pulse on the rotor; the `50` notch on the gauge glows. **Gesture enabled from this moment. WAIT for the learner.**

Phase **spinUp** (interactive): circular drag on/around the rotor → input torque (§14). Heavy: vigorous spinning takes ~4 s to climb 12 → 50 (the mass is felt). `selectionClick` each +5 crossed. **Gate:** freq ≥ 49.5 → L2 (hold 2800 ms) → I2 "Hold It at 50".
Phase **holdSteady**: **Gate:** freq within [49.0, 51.0] continuously for 3000 ms (drifting out resets the window; the band highlight shows in/out state — the struggle is the wheel's give, not slider ergonomics).

Phase **letGo**:
4. I3 "Now Let Go" (holds until obeyed; re-pulses after 6 s if the learner keeps spinning). Demand is FROZEN (window grid static) for this whole phase.
5. When no pointer input for ≥600 ms: torque is zero (hard gate, §14) and the drain runs on physics alone — freq sinks 50 → 47 in ~3.2 s, chip ticking down, wire pulses continuing (the town still drawing), lights sagging from freq ≤ 48.5 (global dim + flicker onset).
6. **DISCOVERY latch** — freq first ≤ 47.0 with no input: `heavyImpact`; fire `onCapture('seconds_of_spin')` (lightImpact + capture flash); L3 (hold 3400 ms) → L4 (hold 3200 ms). If the learner never re-feeds, the load torque tapers at low spin (§14) so the wheel crawls in deep flicker — strain, never blackout (4.5 owns failure).
7. L4 end +400 ms — I4 "Spin It Back to 50". **Gate:** freq within [49.0, 51.0] for 2000 ms.

Phase **surge** (the drag, felt):
8. +800 ms — evening: windows sweep ON over 1200 ms (demand 1.0 → 1.55). Deceleration starts the SAME frame the first new window lights. NOT pre-announced.
9. When freq ≤ 49.2: discovery ring on the chip (~700 ms); L5 (hold 3000 ms) → I5 "Spin Harder". **Gate:** freq within [49.0, 51.0] for 2500 ms at demand 1.55.

Phase **easeOff** (surplus, felt):
10. +600 ms — windows sweep OFF over 1000 ms (demand → 0.75); with the learner's effort unchanged the wheel races; when freq ≥ 50.8: slight overspeed wobble on the rotor; L6 (hold 3200 ms) → I6 "Ease Off". **Gate:** freq within [49.0, 51.0] for 2000 ms.

Phase **naming** (auto, ~10 s; a gentle governor assist holds the band so hands can rest — assist is OFF again for the rush):
11. +400 ms — chip relabel: `SPIN` crossfades to `FREQUENCY` (600 ms) with a one-time shimmer ring + `selectionClick`, synchronized with L7 (hold 3600 ms) → L8 (hold 3600 ms).
Phase **lockstep**: 12. ghost rotors fade in behind (700 ms), all turning in exact phase with the hero; L9 (hold 3400 ms).

Phase **rush** (the payoff; governor OFF):
13. +600 ms — LR1 (hold 2200 ms) while the town surges past anything before (demand → 1.85, ramped over 1000 ms). ALL rotors decelerate together. The ramp outpaces any possible input for ~1.5 s (§14 torque cap), so the dip is ALWAYS witnessed.
14. freq ≤ 49.4 → I7 "Catch the Dip". freq first ≤ 48.8 → fire `onCapture('rush_hour_dip')` (lightImpact + flash; frame shows hero + ghosts slowed, chip in the red).
15. **Gate:** freq within [49.5, 50.5] held 3000 ms while demand stays at 1.85 (the learner is now doing sustained real work — the operator's job).

Phase **closing**:
16. +500 ms — L10 (hold 3400 ms) → L11 (hold 3600 ms) → +400 ms → `showCardEarn.value = true` → `CollectibleEarnOverlay` (frequency card, eyebrow `NEW CARD`, brag per §5, `showMascot: false`).
17. `onCardCollected` → `canFinish.value = true` → gold Continue CTA in its fixed-height seat → tap → `Navigator.maybePop(context)`.

Gates are one-way latches; captures and captions never re-fire. Play length: ~9 s auto + ~60–110 s interaction ≈ 70–120 s.

## 7. Hero & layout (portrait) + clutter caps
**The hero is the spinning rotor with its gauge arc** — the brightest, most alive thing on screen: warm rim + hub glow `#FFD27A`, additive bloom scaling with |spin|, spokes giving unmistakable rotation, the gauge hugging it (the spin and its readout are physically one object — that fusion IS the lesson). The chip rides just beneath the rotor, inside the scene (so captures include it). The town recedes at the bottom — visible, warm, but dimmer than the rotor; it is the demand readout, not the hero. Ghost rotors are faint (≤35 % alpha). Background near-black `#070A1C`, radial vignette darkest behind the rotor; ≤16 ambient motes.
**Clutter caps:** 1 hero + **1 interactive element** (the rotor spin surface; back button, read-only board strip and end-state CTA are chrome) — far under the 6-element cap; **exactly 1 live number** (SPIN/FREQUENCY — under the ≤2 cap); one current text line. Nothing else.

## 8. Reward — collectible card (concept IS a quick-reference row: "Spin speed as the live balance readout | frequency | Ep 4 | Fully explained")
Propose (shared-infra agent finalizes number/constant; section **grid**, accent `#B08CF7`):
- **Front** — playful name: **The Spin Never Lies** · real term (mono specimen label): **GRID FREQUENCY** · law: *The grid's only give is the spin of its machines — demand over supply drags the frequency below 50, surplus pushes it above.* · kicker: *Why control rooms across India watch one number.*
- **Back** — tie to what was felt: *The town asked for more and the wheel slowed under your finger the same instant — the extra energy came straight out of the spin.* · outward reach: *Some ovens and bedside clocks keep time by counting the grid's cycles — in 2018 a weeks-long under-frequency dispute made clocks across Europe run six minutes late.* · linked card: the AC/DC card from 2.7 (the 50 in the socket's wave is this same spin, counted; frequency returns in 4.5 as the number the cascade trips on).
The card names the LAW; it does not re-narrate the activity, and it does not restate 4.1's no-buffer card (that card owns "made the instant it is used"; this card owns "the spin is the readout").
**Inline fact: none** — deliberate empty slot (the clock fact is the card's reach; an inline chip would crowd the rush).

## 9. CER capture hook (ids proposed for the EP4 evidence catalog)
- **`seconds_of_spin`** — label: `Seconds of Spin` · caption: *With nothing feeding it, the town ran on the wheel's stored spin — for seconds, not hours.* · **relevant** · fires at the letGo discovery latch (step 6: first freq ≤ 47.0 with no input), framing rotor + gauge + chip + sagging town top (proposed cropFactor ≈ Rect.fromLTRB(0.06, 0.05, 0.94, 0.72)).
- **`rush_hour_dip`** — label: `The 6pm Dip` · caption: *The evening rush dragged every generator down together — the falling number said add power, now.* · **relevant** · fires during the rush (step 14: first freq ≤ 48.8), framing hero + ghost rotors + chip (proposed cropFactor ≈ Rect.fromLTRB(0.02, 0.04, 0.98, 0.60)).
Wiring per the shipped pattern: `RepaintBoundary(key: _sceneKey)` around background + GameWidget; `controller.onCapture = _onCapture` → `captureScenePng(_sceneKey, cropFactor: evidenceByIdFor('episode4_electricity', id)?.cropFactor)` → `_board.capture(id, imageBytes: bytes)`; `EpisodeBoardStrip` pinned under the header with the EP4 question. Captures idempotent, never block flow.

## 10. Build notes
- **Flame `GameWidget`** (living scene: continuous rotation, particles, window grid, synced ghost rotors) + Flutter overlay chrome — the trace_it_back template. GameWidget built once in `initState`; transparent `backgroundColor`; `onGameResize` → `controller.setStageSize`; `update(dt)` guards `dt > 0 && dt < 0.1` → `controller.tick(dt)`.
- **Gesture stays in Flutter:** transparent `Listener` above the GameWidget forwards `onPointerDown/Move/Up(Offset local)`; the controller maps circular drag around the rotor center to signed finger angular velocity (the crank pattern), `inputTorque = clamp(k·|ωfinger|, 0, τmax)`. Gesture sample timeout 100 ms → torque snaps to 0 (hard gate — the INPUT cuts instantly; the WHEEL does not).
- **Momentum policy (read carefully):** this is the one activity where stored rotation is the lesson, not banned coast. The rotor integrates `dω/dt = (τin − τload − τfric)/J` in the controller's tick — hand-written, one line, **no Forge2D**. No OTHER smoothing anywhere: torque, demand steps, window sweeps, dim/flicker all apply same-frame; the rotor's J is the single, deliberate, tuned "give".
- Sim (config-tuned): `freq = 50·ω/ωn`; `τload = demand · clamp(ω/ωn, 0.3, 1.0)` (tapers at low spin → strain, never self-blackout); J tuned so zero-input decay 50 → 47 ≈ 3.2 s at demand 1.0 and spin-up 12 → 50 ≈ 4 s vigorous; τmax sized so the rush ramp outpaces max input for ~1.5 s (min freq ≈ 48.6 even with instant max effort). `displayFreq` sampled 5×/s for the chip.
- Haptics: `selectionClick` per +5 freq during spinUp and on the chip relabel; `heavyImpact` at the letGo discovery; `lightImpact` on each capture.
- Audio: **silent** (matches shipped electricity activities).
- Reduced motion: motes calmed, entrance reveals become fades, shimmer ring becomes a fade, ghost fade-in instant — but rotation, same-frame causality, the drain, the flicker onset and the chip relabel are untouched (pedagogical).
- Wrap in `MediaQuery(...textScaler: TextScaler.noScaling)`. Completion = `Navigator.maybePop`. Write ONLY inside `lib/screens/missions/grid_frequency/`; reference the card constant and EP4 evidence ids, never define them. Verify: `fvm dart analyze lib/screens/missions/grid_frequency` clean.

## 11. Acceptance criteria (pedagogy as testable checks)
1. **Discoverable from interaction alone:** with all text ignored, spinning raises the number toward the glowing 50 notch, releasing lets it sink while the town strains, and the relationship (spin ↔ number ↔ town) reads with zero reading.
2. **Same-frame causality:** input torque, demand changes, deceleration, chip value, and town dim/flicker all respond in the SAME frame; the rotor's modeled inertia J is the only lag anywhere in the system.
3. **The buffer reads as seconds:** from 50, zero input at demand 1.0 reaches 47.0 in 3.0–4.5 s; town lights persist (sagging, then flickering) through the drain — never an instant blackout and never a minutes-long coast. The mass is also felt on the way up (12 → 50 takes ≥ 3 s of vigorous gesture).
4. **Input cutoff is a hard gate:** torque reaches 0 within 100 ms of gesture stop — the wheel then drains on physics alone, with no hidden assist outside the naming phase.
5. **Felt before named:** the chip reads `SPIN` and the word "frequency" appears nowhere (title, eyebrow, chrome, captions, chip) until L7; the relabel animation fires exactly with L7.
6. **Held-constant is visible:** during letGo the window grid is frozen; during the surge the dip occurs at constant input (testable: a constant-τin harness shows demand step alone decelerates the wheel).
7. **The dip cannot be prevented:** in the rush, freq ≤ 48.8 is reached even with maximum input from the first frame of the ramp; `rush_hour_dip` always captures.
8. **Both directions witnessed:** the surge drags freq ≤ 49.2 (L5) and the demand drop pushes freq ≥ 50.8 with overspeed wobble (L6) before naming occurs.
9. **Catch lines name destination/consequence:** L3/L5 — out of the spin; L6 — into the spin; L4 — seconds, not hours. No "the power goes away", no behaviour/ending phrasing, no rhyme anywhere.
10. **Exactly 1 live number**, mono, in-scene; demand is never a number; no % load, no ratings table; strain is dim/flicker in the scene, never a stat.
11. **Lockstep is witnessed, not asserted:** ghost rotors turn in phase with the hero and dip/recover in exact sync during the rush.
12. **No failure theater:** the wheel never trips, the town never fully blacks out (load tapers at low spin into recoverable strain) — cascade belongs to 4.5. Nothing says or implies "nobody knows why".
13. Captures fire exactly once at their latches with flash + light haptic and appear on the board strip; card fires once after L11; Continue appears only after `onCardCollected`; pop completes the activity.
14. **Hero dominance:** the rotor is the brightest element; ghosts ≤ 35 % alpha; town dimmer than rotor; ≤16 motes; reduced-motion honored without weakening checks 2–5.
15. `fvm dart analyze lib/screens/missions/grid_frequency` clean; small-phone portrait (≈360×640 logical) keeps the rotor finger-operable (≥ 0.4 w diameter).

## 12. Anti-patterns (this activity)
- Copying the hand-crank's hard gate onto ω itself (wheel dying instantly on release) — that contradicts the concept; the hard gate is on INPUT TORQUE only. Equally: adding easing/tweens anywhere else, which would fake extra "give" the grid doesn't have.
- A demand number, load meter, or power bar — the town's windows ARE demand; the dim/flicker IS strain.
- Saying or showing "frequency" before L7 (including in the screen title or eyebrow), or pre-announcing the surge/rush before they are felt.
- A gauge widget detached from the rotor — the spin and its readout must read as one object.
- Letting a fast learner prevent the rush dip (kills "demand moves first; the spin shows it instantly").
- Tripping a generator or blacking out the town — 4.5 owns failure; here strain is always recoverable.
- A premium fade softening the same-frame deceleration or the flicker onset; sing-song cadence in any line.
- Re-teaching 4.1's no-buffer claim as text — here it is upgraded by feel ("the only buffer is this spin, seconds deep"), not restated.
- Explaining pole-pairs / rotor-RPM-vs-electrical-Hz — depth that adds nothing; the honest altitude is "the spin speed is the frequency".

## 13. Open decisions
1. Screen title: proposed **"The Spinning Grid"** (must not contain "frequency"); eyebrow `EPISODE 4 · THE GRID`.
2. Optional third tile `lockstep_spin` ("Lockstep Spin" — *every generator on the grid spins in phase, as one machine*) as a TRUE-but-irrelevant distractor for the EP4 question (it answers how the grid is physically one, not who decides production or what happens at 6pm) — evidence-catalog agent's call; default is the 2 tiles in §9.
3. Governor-assist strength during naming/lockstep (full auto-hold vs gentle kp assist) — tune on device.
4. Exact constants (J, τmax, demand levels 1.55/0.75/1.85, decay-to-47 time, band widths) — on-device tuning; targets in §10/§11 are the acceptance envelope.
5. Card constant name (`kSpinNeverLiesCard` proposed) and deck number — shared-infra agent owns.
6. Final cropFactors for both tiles (proposals in §9) — evidence-catalog agent owns.

## 14. State machine sketch
```dart
enum GFPhase { intro, spinUp, holdSteady, letGo, recover, surge, easeOff, naming, lockstep, rush, closing }
enum GFCaption { none, l1Machine, i1SpinUp, l2RunsOff, i2Hold, i3LetGo, l3Drain, l4SecondsDeep,
                 i4Back, l5Drag, i5Harder, l6Surplus, i6Ease, l7Frequency, l8Readout, l9Lockstep,
                 lr1Evening, i7Catch, l10Synthesis, l11Operators }
```
`GridFrequencyController extends ChangeNotifier`:
- **ValueNotifiers:** `caption: ValueNotifier<GFCaption>` (copy table in config marks imperative vs meaning + hold ms), `phase: ValueNotifier<GFPhase>`, `showCardEarn`, `canFinish`.
- **Hot-path getters (read by Flame layers):** `omega`, `freq` (50·ω/ωn), `displayFreqText` (5 Hz sampled, 1 decimal), `chipLabelBlend` (0 = SPIN, 1 = FREQUENCY, animated 600 ms at naming), `rotorAngle`, `inputTorqueNorm` (drives a subtle effort glow on the rim), `demandLevel`, `litWindowFrac` (∝ demand), `townDim`/`flickerLevel` (onset freq ≤ 48.5, deep ≤ 48.0), `wobble` (freq ≥ 50.8), `ghostReveal`, `discoveryRing`, `flashIntensity`, entrance reveals (`rotorReveal`, `gaugeReveal`, `townReveal`), `motes`.
- **Input:** `onPointerDown/Move/Up(Offset local)` — circular drag around rotor center → signed finger angular velocity (signed spins the visual; |ω| makes torque); `inputTorque = clamp(k·|ωFinger|, 0, τmax)`; 100 ms sample timeout → torque = 0 (hard gate). Enabled from I1 (`phase.index >= spinUp.index`); ignored during intro.
- **tick(dt):** `ω += (τin + τassist − τload − τfric)/J · dt` with `τload = demand·clamp(ω/ωn, 0.3, 1)`; `τassist` only in naming/lockstep (kp·(ωn−ω)); advances rotorAngle, ghost phase (identical angle — lockstep is literal in code), reveals, rings, motes, flicker envelope; runs band-hold stopwatches and latch checks; `notifyListeners()`.
- **Timers:** `_schedule(ms, fn)` chains per §6 — intro 1200/4400 ms; caption holds 2200–3600 ms; ramps: surge 1200 ms, ease 1000 ms, rush 1000 ms; relabel 600 ms; card +400 ms after L11.
- **Latches (one-way):** `_spunUp` (freq ≥ 49.5) · `_heldSteady` (band 3000 ms) · `_drained` (no input ≥600 ms ∧ freq ≤ 47.0 → heavyImpact + `onCapture('seconds_of_spin')`) · `_recovered` (band 2000 ms) · `_dragFelt` (freq ≤ 49.2 in surge) · `_surgeHeld` (band 2500 ms) · `_surplusFelt` (freq ≥ 50.8) · `_eased` (band 2000 ms) · `_rushDipped` (freq ≤ 48.8 → `onCapture('rush_hour_dip')`) · `_rushCaught` (rushBand [49.5, 50.5] held 3000 ms).
- **Hooks:** `onDetent` (selectionClick per +5 freq in spinUp), `onDiscovery` (heavyImpact), `onRelabel` (selectionClick), `onCapture(String id)` (lightImpact + PNG in shell). `reducedMotion: bool` set from MediaQuery each build.

## 15. File plan (mirror trace_it_back)
```
lib/screens/missions/grid_frequency/
├── grid_frequency_screen.dart            — shell: noScaling MediaQuery, RepaintBoundary(_sceneKey) around
│     background + GameWidget, transparent Listener forwarding pointers, header (back; title "The Spinning
│     Grid", mono eyebrow EPISODE 4 · THE GRID), EpisodeBoardStrip (EP4 question),
│     _FadeSwapCaption top text (fixed ~96 h, 190 ms swap), fixed-height CTA seat (84), CaptureFlash,
│     CollectibleEarnOverlay; EpisodeBoardCapture('episode4_electricity').load(); maybePop on Continue
├── state/grid_frequency_controller.dart  — ChangeNotifier per §14 (rotor physics + geometry + phase machine
│     + latches + governor + capture/card hooks)
├── config/grid_frequency_tuning.dart     — GFTune: omegaNominal · J (decay 50→47 ≈ 3.2 s) · tauMax ·
│     k gesture→torque · demand {base 1.0, surge 1.55, low 0.75, rush 1.85} · bands [49.0,51.0]/[49.5,50.5] ·
│     captureFreqs 47.0/48.8 · dipShowI7 49.4 · flickerOnset 48.5 · wobbleOnset 50.8 · all timer/hold ms ·
│     anchor factors (§16) · mote cap 16 · ghost alpha 0.35
├── config/grid_frequency_beats.dart      — GFCaption enum + verbatim copy table (§5) + isImperative flag +
│     hold durations
├── game/grid_frequency_game.dart         — FlameGame: transparent bg, layers back→front, onGameResize →
│     controller.setStageSize, update → controller.tick
├── game/components/ghost_rotor_layer.dart— faint synced rotors behind the hero (reveal-gated, lockstep angle)
├── game/components/rotor_layer.dart      — THE HERO: flywheel (rim, spokes, hub glow #FFD27A, additive
│     bloom ∝ |spin|, effort glow ∝ inputTorqueNorm, overspeed wobble), gauge arc hugging it (band, glowing
│     50 notch, current-speed tick), in-scene mono chip SPIN/FREQUENCY (chipLabelBlend crossfade),
│     discovery/relabel rings, grab hint
├── game/components/wire_town_layer.dart  — wire with traveling pulses (density ∝ demand), town band: window
│     grid (litWindowFrac sweeps), warm bloom, dim + flicker from controller (never brighter than the rotor)
└── widgets/energy_field_background.dart  — static dark vignette + faint circuit texture (copy-adapt from
      trace_it_back)
```

## 16. Scene sketch (portrait, top → bottom; factors of stage size w × h)
1. **Header** (SafeArea): back button on glass; title "The Spinning Grid" (Bricolage 21 w800); mono eyebrow `EPISODE 4 · THE GRID`.
2. **EpisodeBoardStrip** — EP4 question pinned + captured mini-tiles.
3. **Top text** — fixed-height (~96) caption seat: imperatives Bricolage 28 w800 / meaning-lines PJS 18 (L8 ~16.5).
4. **Stage (Expanded):** rotor center at (0.50 w, 0.30 h), radius ≈ 0.21 w (hit zone ×1.5 — finger-operable); gauge arc radius ≈ 0.30 w spanning ~150° over the rotor's top, 50 notch at apex, calm-band segment highlighted; chip centered at (0.50 w, 0.30 h + 0.27 w) just below the rotor; ghost rotors at (0.20 w, 0.22 h) and (0.80 w, 0.22 h), radius ≈ 0.10 w, ≤0.35 alpha; wire from rotor bottom (0.50 w, ~0.52 h) running down to the town feed; town band y 0.74–0.96 h full width (building cluster, window grid, warm bloom), atmospheric and dimmer than the rotor; vignette darkest behind the rotor.
5. **CTA seat** (fixed 84): gold gradient `#F5C451 → #D9A43B` Continue pill after card collection.
All geometry factor-based off `setStageSize`; nothing pixel-fixed.
