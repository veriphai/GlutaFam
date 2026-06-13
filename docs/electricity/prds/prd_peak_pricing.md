# PRD — Why 6pm Costs More Than 3am
### howwow · Episode 5 "Who Pays for All This?" · beat 5.2 · registry id `peak_pricing` · `PeakPricingScreen` · evidence episode `episode5_electricity`

Working title: **6pm vs 3am.** Complies with `docs/electricity/context_pack.md` (the covenant), `docs/electricity/architecture_reference.md`, and curriculum §1–§9 + §13. No mascot, no Voltix, no info-cards; one voice = the on-screen text in two registers (imperatives + meaning-lines).

---

## 1. One-concept statement
**Peak pricing is the baseload/peaking economics of Episode 4 surfacing on your bill.** (At 3am cheap steady baseload covers the small demand, so each unit is cheap; at the 6pm peak expensive fast-ramping peakers are running, and the cost of the last, hardest plant sets the price that moment — so price tracks the demand curve.)

## 2. Guiding-question link + CER contribution
- Episode question (pinned on the board strip all activity): **"Who pays for all this - and why does 6pm cost more than 3am?"** This beat IS the second half of that question, answered mechanically.
- **Inherits:** the day demand curve's shape (4.3 — trough, morning surge, midday plateau, the 6pm peak); **baseload** and **peaker** as named, felt economics (4.4 — steady-cheap-slow vs fast-ramping-pricier); "you pay per unit of energy" (5.1 — so "the price of a unit" is already meaningful; the kWh is NOT re-taught here). **Pins (held constant, visibly):** the plant fleet — exactly three plants on screen the entire activity, none added, removed, or resized (only lit/unlit); the demand curve itself — fully drawn from entry, never editable (demand is never a control); the wash block in the closing beat — identical size at 6pm and at 3am (same wash, same energy). The learner's ONLY variable is **time**. **Sets up 5.4:** the per-unit price felt here becomes a line item on the receipt.
- **CER contribution: RELEVANT evidence (2 tiles, no distractors from this beat).** `peaker_sets_price` (the 6pm frame: the costliest plant flaring, the price stepped to its top) and `cheap_at_3am` (the trough frame: baseload alone, price at its floor) are together the "because the peak runs on expensive peakers and the trough runs on cheap baseload" clause of the episode claim. Both directly answer the question's second half — neither is a distractor. Recommendation to the EP5 CER owner: draw the episode's 2 true-but-irrelevant distractors from other beats (e.g. a 4.x-flavoured "demand follows routines" moment or a 5.3 wire-clutter moment — true, but they answer *who decides* / *why one grid*, not *who pays / why 6pm*).

## 3. The felt discovery (discovery → reaction)
- **Discovery 1 (the step is glued to a plant):** the learner scrubs the familiar day curve forward from 3am → *reaction:* the moment demand climbs past what the baseload block covers (~7:30), a peaker **ignites** in the stack below — flame flare, warm glow — and in the SAME frame the PRICE chip **steps** 10 → 22 and the price-setter halo jumps to the new plant. Price didn't drift; it jumped, exactly when that plant lit.
- **Discovery 2 (THE discovery — the last plant sets the price, heavyImpact):** pushing into the evening rush, demand crosses the second threshold (~17:15) → the costliest peaker flares, the halo jumps to IT, and the chip steps 22 → 34. One plant, switched on for the rush, just repriced **every** unit. Scrubbing forward past ~20:30, that peaker dies and the price steps straight back down — felt, no text — sealing that the step belongs to the flame, not to the clock.
- **Discovery 3 (the landing — timing is money):** the learner drops a fixed wash block at 6pm (cost 34), then slides the SAME block to 3am and watches the peakers extinguish under it and the cost step down to 10. Same wash, same energy, a third the cost — the interaction is the concept: the only thing that changed hands is *when*.

## 4. Felt vs named vs numbered
- **Felt:** peaker ignition flare + extinguish snap (hard gates, both directions); the price-setter halo riding whichever plant is the most expensive one running; the gold price **staircase** drawing itself under the demand hill as the learner scrubs — ending up shaped like the curve, in steps; the panel's time-of-day tint along the x-axis (indigo night → amber dusk); the wash block riding the rail with the stack breathing beneath it.
- **Named:** **peak pricing** lands at M5, only after both extremes are felt (name-after-felt); **time-of-use** lands last at M8. Inherited names used freely from entry (already named in 4.3/4.4/5.1): *demand*, *baseload*, *peaker*, *unit*. No other terms. **No kWh re-teach, no rupees/dollars, no "marginal cost" jargon, no regulator/monopoly (5.3), no bill anatomy (5.4).**
- **Numbered (live, relative, exactly 2):** the **hour label** on the transport head (mono, hour resolution: `3 AM`, `6 PM`) and the **PRICE chip** (relative units: trough = 10, mid = 22, peak = 34; relabels to `WASH COST` in the closing beat — never both at once). Static dim axis ticks on the rail (`12 AM · 6 AM · 12 PM · 6 PM · 12 AM`) are labels, not live numbers. **No demand number** (the curve's height IS the readout), **no per-plant cost tags, no ratings table, no number for any qualitative judgment.**

## 5. On-screen text — EXACT, beat by beat
Imperatives = Bricolage Grotesque large; meaning-lines = Plus Jakarta Sans (long ones sentence case, smaller). Swap = 190 ms fade-out → swap → fade-in.

| # | Register | Line (verbatim) | Trigger |
|---|---|---|---|
| T1 | imperative | `Scrub the Day` | entry, after entrance reveals (~900 ms) |
| M1 | meaning | `Demand has climbed past the baseload plant — a peaker fires, and the price steps up.` | first up-crossing of threshold A (~07:30), same frame as the ignition |
| T2 | imperative | `Climb to the 6pm Peak` | M1 + 2400 ms |
| M2 | meaning | `The most expensive plant running sets the price for every unit, this very moment.` | second ignition (~17:15) — THE discovery; heavyImpact; capture `peaker_sets_price` |
| — | felt only | *(no line)* — scrubbing forward past ~20:30, the costly peaker dies and the price steps down 34 → 22 | witnessed absence; no text |
| T3 | imperative | `Scrub Back to 3am` | gate: M2 fired AND dayMax ≥ 20.75 h; + 800 ms |
| M3 | meaning | `At 3am the steady baseload covers the city alone — each unit is cheap.` | head within 03:00 ± 1.0 h sustained ≥ 700 ms; capture `cheap_at_3am` |
| M4 | meaning | `The price follows the demand curve — cheap in the trough, expensive at the peak.` | M3 + 2600 ms |
| M5 | meaning (long) | `Peak pricing is not a markup — it is the cost of the plants the evening rush switches on.` | M4 + 2800 ms |
| T4 | imperative | `Drop the Wash at 6pm` | M5 + 2600 ms; wash block fades in above the rail |
| M6 | meaning | `Run at the peak, the wash pays the peaker price for every unit.` | wash snapped at 18:00 + 600 ms; chip relabels `PRICE → WASH COST` on this beat |
| T5 | imperative | `Slide the Wash to 3am` | M6 + 2400 ms |
| M7 | meaning | `The same wash, the same energy — run off-peak, it costs a third as much.` | wash within 03:00 ± 1.0 h sustained ≥ 600 ms |
| M8 | meaning (long) | `Time-of-use meters charge by the hour, so running off-peak really costs less. On a flat tariff the peak cost is still there — averaged into every unit's price.` | M7 + 2800 ms |

Rules check: every imperative ≤ 5 words; M1 names the consequence (the price steps up), M8 names the destination of the peak cost (averaged into every unit's price) — never a behaviour/ending; no rhyme, no narration-to-a-child; "peak pricing" appears in no line before M5; "time-of-use" in no line before M8; no money symbol anywhere. Header title: `6pm vs 3am`; mono eyebrow: `EPISODE 5 · THE BILL`. No card, so no brag/eyebrow earn copy exists. No other text exists in the activity.

## 6. Beat-by-beat flow (timing + gating)
1. **Intro (0–900 ms):** entrance reveals — the known demand curve sweeps in left→right (0→600 ms; it is 4.3's curve returning, same silhouette), the three-plant stack slides up (200→700 ms), the transport head appears at **03:00** with the price chip reading `PRICE 10`, halo on the baseload block. T1 at 900 ms.
2. **Scrub forward (learner-paced):** dragging anywhere on the rail/stage moves the head; head follows the finger with a **max transport speed ≈ 3.5 day-hours/s** both directions (smooth lag, so every ignition is witnessed — never a teleport). The gold staircase trace draws under the head as it advances and **persists** (rewinding never erases it). A vertical now-line at the head's x runs from the curve through the price lane into the stack, gluing curve → plants → price. `selectionClick` per 2-hour detent crossed.
3. **Ignition 1 (~07:30, hard gate):** the frame demand crosses threshold A: peaker A's flame snaps on + flare burst, halo jumps baseload → peaker A, chip steps 10 → 22, `selectionClick`. M1 fires same frame (first time only). T2 at M1 + 2400 ms.
4. **Ignition 2 = THE DISCOVERY (~17:15, hard gate):** the frame demand crosses threshold B: peaker B flares, halo jumps to it, chip steps 22 → 34, discovery flash ~700 ms envelope, **heavyImpact**, **capture `peaker_sets_price`** on this frame, M2. The learner keeps scrubbing; at ~20:30 the down-crossing extinguishes peaker B same-frame (34 → 22) — felt, unannounced.
5. **Turn-around (T3):** gate = M2 fired AND `dayMax ≥ 20.75 h`; T3 at + 800 ms. The learner rewinds; both peakers die in reverse order as thresholds un-cross (hard gates, price steps down each time). Head within 03:00 ± 1.0 h sustained ≥ 700 ms → M3 + **capture `cheap_at_3am`** (trough frame: cold flames, halo on baseload, chip 10).
6. **Shape + naming:** M4 at M3 + 2600 ms (the panel now shows the hill AND its gold staircase echo for 03:00–21:00). M5 at M4 + 2800 ms (peak pricing named, after both extremes are felt).
7. **The wash — peak (T4):** at M5 + 2600 ms the wash block (fixed-size, tiny mono label `WASH`) fades in bobbing above the rail with a grab-hint ring; the scrub head fades out and rail input routes to the block. T4. Drop with magnetic snap to **18:00** (snap zone ± 1.0 h). On snap: stack shows both peakers lit under it, chip crossfades label `PRICE → WASH COST` (190 ms) reading 34, `selectionClick`. M6 at + 600 ms.
8. **The wash — off-peak (T5):** T5 at M6 + 2400 ms. Sliding the block left scrubs time live — peakers extinguish under it at the thresholds (same hard gates, cost steps 34 → 22 → 10). Block within 03:00 ± 1.0 h sustained ≥ 600 ms → M7 + `selectionClick`.
9. **Landing → done:** M8 at M7 + 2800 ms. At M8 + 2600 ms → `canFinish = true`, Continue CTA appears in its fixed seat. **No card overlay.** Free play stays live (the wash remains draggable; the stack and cost keep responding).
10. **Finish:** Continue → `Navigator.maybePop(context)` (any pop = completion; no payload).

Reversibility: scrubbing is always reversible (speed-capped both ways); phases never regress; M1/M2/M3/captures fire once (idempotent). Straight-through play ≈ 75–130 s.

## 7. Hero & layout (with clutter caps)
- **The hero:** the **day panel + plant stack as one machine** — the demand hill above, the gold price staircase drawing beneath it, and the three plants breathing below, all pierced by the now-line. Its brightest events are the ignition flares and the price step; at the 6pm discovery the flaring peaker + halo + stepped chip is the brightest thing on screen.
- **What recedes:** near-black `#070A1C` base, radial vignette darkest behind the stack; panel tinted faintly along x with time-of-day (indigo night edges, pale day middle, amber dusk at 18:00 — static, baked into the panel); chrome on glass `0x14FFFFFF` / borders `0x26FFFFFF`; demand curve cool white-cyan (the known, calm given); the staircase warm gold `#E8C98A`/`#F5C451` (the new thing, the money line); ≤ 20 ambient motes.
- **Portrait layout (top→bottom):** header → `EpisodeBoardStrip` (EP5 question) → instruction banner (fixed h 96) → stage (price chip top-right; curve panel upper; price lane under it; plant stack band; scrub rail with head/wash at the bottom) → fixed-height CTA seat (84).
- **Clutter caps (hard):** 1 hero; **4 interactive elements** (rail/head transport, wash block, back button, Continue) ≤ 6 ✓; **exactly 2 live numbers** (hour label + PRICE/WASH COST chip); the current text line; nothing else. **No demand number, no money symbol, no per-plant cost tags, no meter, no score** — the stack and the staircase ARE the readout.

## 8. Reward
**No card.** This beat's concept is not a row in the curriculum quick-reference table — the relevant row is "Steady vs fast-ramping plants → baseload / peaking (Ep 4)", whose card belongs to 4.4; EP5's table rows are the kWh (5.1) and natural monopoly (5.3). 5.2 is, by design, **4.4's law showing up on the bill** — giving it a card would restate 4.4's card, which the card rules forbid. The reward is the landing itself: the learner leaves knowing, mechanically, why the peak is expensive and when to run heavy appliances — plus two strong evidence tiles for the episode case and the grand finale.
**Inline fact: none** — deliberate empty slot. (A real-market price-spike fact was considered and cut: it either restates the lesson or pulls toward absolute money numbers this screen bans.)

## 9. CER capture hook (proposed tiles — ids locked by the EP5 evidence catalog at shared-infra time)
1. `peaker_sets_price` · label `Peakers Set Price` · caption `At the evening peak the most expensive plant running set the price for every unit.` · **relevant** · fires on the M2 discovery frame (second ignition: costliest peaker flaring, halo on it, chip at 34, staircase at its top step). Suggested cropFactor ≈ `Rect.fromLTRB(0.04, 0.06, 0.96, 0.90)` (chip + curve + lane + stack).
2. `cheap_at_3am` · label `Cheap At 3am` · caption `Overnight the steady baseload covered the city alone — each unit at the lowest price.` · **relevant** · fires on the M3 frame (head at the trough, both flames cold, halo on baseload, chip at 10). Suggested cropFactor ≈ `Rect.fromLTRB(0.04, 0.06, 0.96, 0.90)`.
Wiring: stage wrapped in `RepaintBoundary(key: _sceneKey)` (background + stage surface only — banner/strip/CTA excluded); `controller.onCapture = _onCapture` → `HapticFeedback.lightImpact()` → `captureScenePng(_sceneKey, cropFactor: evidenceByIdFor(kEpisode5Id, id)?.cropFactor)` → `_board.capture(id, imageBytes: bytes)`; `EpisodeBoardStrip` pinned under the header with the EP5 question throughout.

## 10. Build notes
- **Rendering: plain CustomPainter + Ticker** (the hand_crank_lamp pattern, not Flame). This is one precise composed panel — a curve, a staircase, three plant blocks, a rail — with no parallax world or heavy particle field; a single pure `PPStagePainter(controller)` repainting off the controller is the right tool. A small `ParticleField` (after `crank_particles.dart`) carries ignition flare bursts + flame flicker embers (≤ 26 alive).
- Controller-owns-geometry: `PeakPricingController extends ChangeNotifier`; `setStageSize(size)` in `paint()`; ALL anchors = factor × stage size (`PPTune`). Pointer enters via a `Listener` on the surface; the controller hit-tests (rail vs wash block) and maps x → day-hour with the 3.5 h/s transport cap.
- **The sim is a pure function of time:** `demand(h)` = Catmull-Rom through knots `(0,42)(3,38)(6,46)(9,62)(13,58)(16,66)(18,96)(19.5,88)(21,64)(24,42)` (relative units; trough 38, peak 96). Thresholds: A = 55 (peaker A runs while demand > 55: ~07:30–23:00... clamp knots so the down-crossing lands ~22:50), B = 78 (peaker B: ~17:15–20:30). Prices: baseload 10, peaker A 22, peaker B 34. **`price(h) = cost of the most expensive plant running` — a pure step function; no smoothing, no averaging, ever.**
- **Hard gates in `tick(dt)`:** plant on/off recomputed every frame from `demand(dayHour)` vs thresholds; flame glow and the chip value switch the SAME frame a threshold is crossed (flare/ember particles may outlive by ≤ 1.8 s as debris, but the glow + number are instant). Identical under reduced motion (calmer motes/flicker; the steps stay instant).
- Staircase trace: stored as the high-water segment list `[(h, price)]` up to `dayMax`; persists across rewinds; drawn in the price lane with a soft additive gold glow (`BlendMode.plus`).
- Chip: `displayPrice` updates on step only (it IS a step); label crossfade `PRICE → WASH COST` 190 ms at M6. Hour label: 12-hour, hour resolution (`3 AM`), mono.
- Haptics: `selectionClick` per 2-h detent + ignition 1 + wash snap/settle; `heavyImpact` at M2; `lightImpact` inside the capture handler; no card overlay (no medium). Audio: **silent** (matches EP siblings; open decision §13).
- `MediaQuery(...textScaler: TextScaler.noScaling)` wrapper; instruction banner fixed h 96 with the 190 ms fade-out → swap → fade-in; gold gradient pill Continue (h 52) in the fixed 84 seat.
- File-surface rule: write ONLY inside `lib/screens/missions/peak_pricing/`. `kEpisode5Evidence`, `kEpisode5Id`, the EP5 question constant are owned by shared infra — code against the names and report in the final message if absent; never edit shared files. Registry entry is central integration. No card constants needed.
- Verify: `fvm dart analyze lib/screens/missions/peak_pricing` clean; small-phone portrait sanity; reduced-motion pass.

## 11. Acceptance criteria (pedagogy as testable checks)
1. **Discoverable from interaction alone:** with top-text suppressed (debug flag), a fresh user scrubbing the day reads the concept: a plant ignites and the price steps in the same frame; scrubbing back and forth across a threshold toggles flame + halo + price together, every time.
2. **Price is a pure function of the running stack:** at no moment does the price chip change value without a plant igniting or extinguishing in the same frame; the price never ramps, lerps, or drifts between steps.
3. **Steps are hard gates, both directions:** flame glow + chip switch within 1 frame (≤ 50 ms) of a threshold crossing, up and down, including the forward pass at ~20:30 and the wash slide; no eased onset; identical under reduced motion.
4. **The last plant sets the price:** while two or three plants run, the chip equals the cost of the most expensive one (10/22/34, never an average), and the halo sits on exactly that plant.
5. **Held constant, visibly:** three plants on screen 100% of the activity, none added/removed/resized; the demand curve is fully drawn from entry and no input ever alters it; the wash block is pixel-identical in size at 6pm and 3am.
6. **Time is the only variable:** no input changes demand or the fleet; the transport is speed-capped ≈ 3.5 day-h/s both ways so no ignition can be skipped past unseen.
7. **Both extremes gated before naming:** M4/M5 cannot fire until the 6pm step (M2) AND the 3am trough return (M3) are both witnessed; M3 requires the learner to scrub back themselves (agency, not autoplay).
8. **The contrast lands:** trough price = 10 and peak price = 34 (≈ 3×) in every run; the wash costs 34 at 18:00 and 10 at 03:00 with the identical block.
9. **Numbers discipline:** exactly 2 live numbers (hour label + PRICE/WASH COST), relative units, no money symbol, no per-plant tags, no demand number, no ratings table; static rail ticks are dim labels only.
10. **Text exactness:** all 14 rows verbatim from §5; imperatives ≤ 5 words; "peak pricing" first appears at M5; "time-of-use" first appears at M8; the 20:30 down-step has NO line; no "greed" wording anywhere.
11. **Scope fences:** no kWh/rectangle re-teach (5.1), no regulator/monopoly (5.3), no bill breakdown (5.4), no frequency/Hz (4.2), no routine-causes narration (4.3), no blackout.
12. **Captures:** exactly two, ids exact, at the §9 moments, idempotent; board strip shows the EP5 question 100% of the activity.
13. **Contract:** `const PeakPricingScreen()` constructible with no arguments; done → Continue → `Navigator.maybePop`; no card overlay anywhere; analyzer clean on the activity dir; straight-through run 75–150 s on device.

## 12. Anti-patterns (this activity)
- **A smooth price line** — lerping the price between levels falsifies the one mechanism (the last plant sets it); the staircase IS the lesson.
- **An averaged price** — blending plant costs into a weighted mean teaches the wrong economics; the chip equals the costliest running plant, full stop.
- **Greed/villain framing** — no "they charge more", no money symbols, no red surge pricing alarm; price is a consequence of the stack, stated as fact.
- **Per-plant cost tags or a cost table** — three printed prices is a ratings table in disguise; the halo + the stepping chip carry cost, one value at a time.
- **A teleporting scrubber** — jumping past an ignition unfelt breaks discovery 1; the transport lag is load-bearing, not polish.
- **A premium fade on ignition/extinguish** — the same-frame snap is the glue between flame and price; never soften it.
- **Re-explaining inherited beats** — no text about why demand peaks (4.3's job) or what baseload/peakers are (4.4's job); the names are used, not re-taught.
- **Auto-playing the day** — the comparison must be the learner's own hand moving between 6pm and 3am; autoplay would hand them the conclusion.
- **A second unit scale for the wash** — the wash cost must reuse the same relative units as the price so 34-vs-10 is a direct read, not a conversion.
- **Pre-spoiling the step** — no text before M1 mentions price rising, peakers firing, or steps; T1 only says to scrub.
- **A clock-superstition reading** — the 20:30 forward down-step (and the wash slide) must be present so price reads as tracking the *stack*, never "6pm is magically expensive".

## 13. Open decisions
1. Exact curve knots, threshold values (55/78), and the 3.5 h/s transport cap — on-device tuning so ignitions read clearly at finger speed.
2. Whether the persisted staircase dims slightly behind the head on rewind (recommended: keep full, it is the day's receipt) — visual tuning.
3. Plant stack labels: `BASELOAD · PEAKER · PEAKER` (specced) vs distinguishing the right block (`FAST PEAKER`) — small-phone legibility call.
4. Silent (proposed) vs a faint flame/city bed ≤ 0.2 vol — polish flag.
5. Final cropFactors + tile copy — EP5 evidence-catalog owner.
6. Wash snap-zone width (± 1.0 h proposed) and whether the snap ghost-highlights 18:00 during T4 — tuning.

---

## 14. State machine sketch
```dart
enum PPPhase { intro, scrubDay, scrubBack, synthesis, washPeak, washSlide, landing, done }
enum PPCaption { none, t1Scrub, m1PeakerFires, t2Climb, m2LastPlant, t3ScrubBack, m3Trough,
                 m4FollowsCurve, m5PeakPricing, t4DropWash, m6PeakPrice, t5SlideWash,
                 m7ThirdCost, m8TimeOfUse }
```
- **ValueNotifiers:** `caption: ValueNotifier<PPCaption>` (isImperative flags in `pp_captions.dart`), `phase`, `chipMode` (`price` | `washCost`), `washVisible`, `canFinish`.
- **Hot-path getters (repaint via controller):** `dayHour`, `dayMax`, `demandNow`, `price` (step fn), `plantOn[3]`, `priceSetterIndex`, `flameGlow[3]`, `traceSegments`, `nowLineX`, `headAlpha`, `washX`, `washHeld`, `flashIntensity`, `particles`.
- **Once-only flags:** `ignition1Felt` (M1), `peakFelt` (M2), `troughReturnFelt` (M3), `washPeakFelt`, `washNightFelt`; fired-capture id set.
- **Timers (`_schedule(ms, fn)`):** 900 (T1); 2400 (M1→T2); 800 (gate→T3); 2600 (M3→M4); 2800 (M4→M5); 2600 (M5→T4); 600 (snap→M6); 2400 (M6→T5); 2800 (M7→M8); 2600 (M8→done). Dwell accumulators: trough 700 ms (M3), wash settle 600 ms (M7).
- **Gating conditions:** `scrubDay` shows T3 only when `peakFelt && dayMax >= 20.75`; `scrubBack→synthesis` when `(dayHour - 3.0).abs() <= 1.0` sustained 700 ms; `synthesis→washPeak` on the T4 timer (head fades, wash input routing on); `washPeak→washSlide` when wash snapped in 18:00 ± 1.0 h (M6); `washSlide→landing` when wash at 03:00 ± 1.0 h sustained 600 ms (M7); `landing→done` on the M8 + 2600 timer (`canFinish = true`).
- **Hard gates in `tick(dt)`:** every frame, `plantOn[i] = demand(dayHour) > threshold[i]`; `price = maxCost(plantOn)`; `flameGlow[i]` snaps 0↔1 with the boolean (flicker modulates only while on); transport integrates toward the pointer target clamped to ±3.5 h/s; `dayMax = max(dayMax, dayHour)`; trace appended only while `dayHour == dayMax`. M1/M2 side-effects fire inside the same frame as their crossing.

## 15. File plan — `lib/screens/missions/peak_pricing/`
```
peak_pricing_screen.dart            — shell: noScaling MediaQuery, header (title '6pm vs 3am',
                                      mono eyebrow), EpisodeBoardStrip (EP5 question),
                                      instruction banner (h 96), RepaintBoundary(_sceneKey)
                                      around background + PPSurface, price chip overlay,
                                      fixed CTA seat (84), capture wiring (_onCapture)
state/peak_pricing_controller.dart  — ChangeNotifier: phase machine, timers, caption driver,
                                      tick(dt), pointer routing (rail vs wash), hard gates,
                                      onCapture/onDiscovery hooks, haptic hooks
state/pp_particles.dart             — small ParticleField: ignition flare bursts, flame embers,
                                      ≤26 alive (copy-adapt crank_particles)
config/pp_tuning.dart               — PPTune: demand knots, thresholds (55/78), prices (10/22/34),
                                      transport cap, all ms timings, geometry factors (panel,
                                      lane, stack, rail, chip anchors), palette constants
config/pp_captions.dart             — PPCaption enum + verbatim §5 copy + isImperative flags
widgets/pp_surface.dart             — Listener + CustomPaint(painter: PPStagePainter(controller),
                                      repaint: controller), forwards pointer to controller
widgets/pp_stage_painter.dart       — pure renderer, back→front: vignette → panel (time-tinted) →
                                      threshold lines → demand curve → gold staircase trace →
                                      now-line → plant stack (blocks, flames, halo) → rail +
                                      ticks + head/hour label → wash block + grab hint →
                                      discovery flash → particles
widgets/price_chip.dart             — mono dark-glass chip: PRICE/WASH COST label crossfade
                                      (190 ms), stepped value, soft pulse on step
widgets/energy_field_background.dart— static dark vignette variant (copy-adapt trace_it_back)
```

## 16. Scene sketch (portrait, factor-based off stage size S = w × h)
- **Price chip:** anchored x 0.64w → 0.94w, y 0.015h → 0.085h (dark glass, mono 19; the halo's tether target).
- **Curve panel:** x 0.06w → 0.94w, y 0.10h → 0.42h. Demand curve (cool white-cyan, ~2.5 px, soft under-fill); panel background tinted along x by hour (indigo → pale → amber → indigo, static); two faint threshold hairlines at the demand-heights of 55 and 78, each tinted to its peaker and brightening only while that peaker runs.
- **Price lane:** x 0.06w → 0.94w, y 0.44h → 0.56h. The gold staircase trace (price 10/22/34 mapped to lane height), additive glow; visually the curve's echo, directly beneath it.
- **Now-line:** vertical hairline at the head's x, y 0.10h → 0.84h — piercing curve, lane, and stack.
- **Plant stack (HERO band):** y 0.60h → 0.84h. Baseload block x 0.08w → 0.42w (wide, calm cool body, steady warm interior glow — never changes all day); peaker A x 0.46w → 0.66w and peaker B x 0.70w → 0.90w (slim turbine silhouettes + exhaust stack; flame cap + warm bloom while on, cold dark while off — peaker B slightly sharper/slimmer). Dim mono labels beneath: `BASELOAD · PEAKER · PEAKER`. **Price-setter halo:** a warm ring + faint tether toward the chip, sitting on exactly one plant at all times. Vignette darkest behind this band.
- **Scrub rail:** x 0.06w → 0.94w, y 0.88h → 0.96h. Track with 5 dim ticks (`12 AM · 6 AM · 12 PM · 6 PM · 12 AM`); fat head (hit area ≥ 56 px) with mono hour label (`3 AM`) above it; head fades out when the wash takes over. **Wash block:** fixed ~0.12w × 0.05h rounded block, tiny mono `WASH`, bobbing entrance above the rail at x ≈ 0.5w, grab-hint ring until first grab; rides the rail thereafter.
- **Capture frame note:** both §9 cropFactors keep chip + panel + lane + stack inside the crop; banner/strip/CTA live outside the RepaintBoundary so captures stay clean.
