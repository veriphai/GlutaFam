# PRD — The Receipt: The Bill Pays for the Whole Journey (EP5 beat 5.4)
### howwow · Episode 5 "Who Pays for All This?" · registry id `the_bill_receipt` · `TheBillReceiptScreen` · evidence episode `episode5_electricity`

Binding context: `docs/electricity/context_pack.md`, `docs/electricity/architecture_reference.md`, curriculum §5.4 + §1–§9 + §13.
This PRD is self-contained: every on-screen line is quoted verbatim here. No mascot, no Voltix, no info-cards. **No depth-stop** — every "why" here bottoms out in arithmetic or a human decision, all showable. THE CAPSTONE BEAT: it teaches no new law; it pays off every episode at once. **EP5 has no separate episode CER — its closer is the grand finale CER (separate PRD); this activity feeds it directly.**

---

## 1. One-concept statement

**The bill is an itemised payment for the exact end-to-end machine the learner now understands.**

Inherits (already felt): the whole machine, episode by episode — the spinning magnet (EP1), the high-voltage trick over long lines (EP2), the staged step-down and the safe socket (EP3), the live every-second balancing (EP4) — plus 5.1 (the bill charges energy, the kWh rectangle), 5.2 (peak units cost more because peakers are expensive), 5.3 (one shared network, price approved by a regulator). Nothing in this activity is new; every reaction is a recognition.
Pins (held constant, visible): **the total** — the bill enters as one number, 100; every tear decrements it by exactly the slice's share; the restack counts it back to exactly 100 ("the same hundred"). **The machine** — the full journey strip (plant → pylons → pole → house, dial above) is on screen, dark, from the first frame; paying never builds or resizes it, it only lights what was already there. The decomposition changes nothing but understanding.

## 2. Guiding-question link & CER contribution

Episode question (pinned on the board strip all activity): *"Who pays for all this — and why does 6pm cost more than 3am?"*

- **Relevant evidence:** `receipt_whole_journey` — the final frame: the itemised receipt stacked back to 100 above the fully-alive machine, every slice glowing over the stage it pays for. This is the "who pays for all this" half answered in one image: the customer pays, itemised, for every stage from magnet to socket.
- **Distractor (true-but-irrelevant):** `magnet_in_the_bill` — the generation slice docked, the miniature magnet+coil from EP1 visibly spinning behind it. TRUE (generation is still the spinning magnet) but it answers *how electricity is made* (EP1's question), not *who pays or why 6pm costs more*. A clean relevance judgment for the learner.
- **Note to the finale-CER owner:** both tiles are prime candidates for the finale catalog ("how does electricity reach your home?"). If `magnet_in_the_bill` is promoted there, its relevance FLIPS (the spinning magnet is core to the finale question) — re-flag it in the finale config, not here. `receipt_whole_journey` is arguably the single strongest closing tile of the whole module.
- EP5 needs exactly 2 distractors across the episode; this beat supplies one. The other should come from 5.1–5.3 (catalog owner's pick).

## 3. The felt discovery (discovery → reaction)

The interaction IS the concept: **the bill is physically pulled apart, and each piece of money wakes the piece of the machine it pays for.**

1. **Discovery (the number has parts):** the learner grabs the bill — a mute card reading 100. **Reaction:** perforation lines shimmer into existence under the finger; the top band tears free and follows the drag; on release it flies down, and the bill's number drops by exactly that slice's share. The bill was never one thing.
2. **Discovery (money maps to machine):** the slice docks beneath the dark plant. **Reaction:** the plant wakes — the same magnet+coil from Episode 1 spins, the turbine turns, warm pulses set off and die at the still-dark pylons. The pattern repeats: transmission slice → pylons light, pulses glide the span; distribution slice → the pole transformer steps them down, the house lights. Four pulls, one converging pattern: *a slice of money, a stage of the journey.*
3. **Discovery (paying for steadiness):** after distribution the path plant→socket is complete — but the house light WAVERS, and the small dial above the strip wanders. Something is still unpaid. **Reaction:** the operation slice docks → the dial settles, the light holds steady in the same beat. Operation isn't a wire or a tower — it's the balancing, and it is on the bill.
4. **The record-scratch (witnessed absence):** the fifth slice tears and docks at the strip's empty end. **Reaction:** nothing on the journey lights. A held beat of stillness — then the line names it: taxes buy no part of the machine; they go to the government. (Same technique as solar's "No Spinning Here": four repetitions establish the pattern, the fifth breaks it.)
5. **Synthesis (the receipt):** the learner drags any docked slice upward. **Reaction:** all five fly back in journey order, stacking into an itemised bar as the number counts back to 100, the whole machine alive end-to-end beneath it. The bill re-forms — but now it is a receipt, and every line of it is legible.

## 4. Felt vs named vs numbered

- **Felt:** the dark silhouette of the whole machine waiting under the bill; the perforation shimmer; tear resistance and release; each miniature waking as a recognizable callback (magnet+coil spinning; pulses gliding the catenary span; the pole transformer stepping them down; the digitless dial settling); the flicker before operation is paid and the steadying after; the taxes slice lighting nothing; the end-to-end glow; the restack assembling.
- **Named (a beat after felt):** slice names appear only as each slice tears/docks (mono dock labels: GENERATION · TRANSMISSION · DISTRIBUTION · OPERATION · TAXES & LEVIES) — at intro the bill shows NO itemisation; "itemised" lands at SY1; "receipt" lands only at SY2, the one-concept line. Every other term in the copy (high voltage, pole transformer, operators, regulator) is a callback already named in its own episode — nothing is named here for the first time except the reading of the bill itself.
- **Numbered (live, relative, ≤2):** the `BILL` mono chip on the card (starts 100; decrements per tear: 100 → 52 → 41 → 17 → 13 → 0; counts 0 → 100 during restack) and the active slice's share (printed on the band only while tearing/flying: 48 / 11 / 24 / 4 / 13; fades to name-only on dock). Relative throughout — **no ₹, no $, no kWh digits, no Hz, no absolute tariff numbers anywhere**; the dial face has a needle and a center mark, no digits (a number there would be a third live number AND EP4's readout — here steadiness is felt). The final assembled receipt prints the five shares as static receipt text — artwork of the payoff, not live readouts (flagged in §13). **No ratings table; no number for any qualitative judgment.**

## 5. On-screen text — EXACT, beat by beat

Imperatives = Bricolage Grotesque, large, Title Case, ≤5 words. Meaning-lines = Plus Jakarta Sans, de-personified facts. Swap = 190 ms fade-out → swap → fade-in. Meaning-lines are state-independent facts.

| # | Phase | Register | Line (verbatim) |
|---|---|---|---|
| T1 | intro | meaning | A month of electricity arrives as one number. |
| T2 | intro | meaning | The machine that made it sits dark underneath. |
| T3 | pull (slice 1) | imperative | Pull the Bill Apart |
| S1 | dock 1 (generation lit) | meaning | The biggest slice pays the plant — the fuel, and the spinning magnet that makes every unit. |
| T4 | pull (slices 2–5, reshown each) | imperative | Pull the Next Slice |
| S2 | dock 2 (pylons lit) | meaning | This slice pays the long lines — and the high voltage that keeps the losses small. |
| S3 | dock 3 (house lit, wavering) | meaning | This slice pays the last mile — the pole transformer stepping it down to the socket. |
| S4 | dock 4 (dial settled, light steady) | meaning | The smallest slice pays the operators balancing supply and demand every second — the light holds steady. |
| S5 | dock 5 (after the absence beat) | meaning | Taxes and levies — the one slice that buys no part of the machine. It goes to the government. |
| T5 | restackPrompt | imperative | Stack It Back |
| SY1 | restack lands on 100 | meaning | The same hundred — now itemised. |
| SY2 | synthesis (the one-concept landing) | meaning | The bill is a receipt for the whole journey: generation, transmission, distribution, operation — from the spinning magnet to the socket. |
| SY3 | synthesis (5.3 callback) | meaning | Every line of it is approved by the regulator. |
| B1 | bridge (final, persists) | meaning | One question is left, and every clue is on the board: how does electricity reach your home? |

S3's flicker is deliberately NOT named in text — it is felt, and S4 resolves it (never explain what they can see). S5 names the destination ("goes to the government"), never the behaviour. B1 poses the finale question and gestures at the evidence board the learner has filled all module; final phrasing of the finale's pinned question is owned by the finale-CER PRD — keep B1's wording matching it at integration. **No card earn → no brag line.**

## 6. Beat-by-beat flow (timing + gating)

Text swaps 190 ms. Play length target ≈ 70–110 s. Slice order is FIXED journey order: generation(48) → transmission(11) → distribution(24) → operation(4) → taxes(13). Timings in ms.

| Phase | What happens | Timing / gate |
|---|---|---|
| `intro` (auto) | Entrance reveals (bill card slides+scales in 0→500; journey silhouettes fade in left→right 400→1500, DARK; board strip standard). `BILL 100` chip visible. T1 at 700; T2 at 3100. | auto-advance at 5200 → `pull(0)` |
| `pull(i)` | T3 (i=0) / T4 (i≥1). Only the bill's top band hit-tests; grab-hint pulse on its edge (i=0 only, until first touch). On grab: perforations shimmer in (i=0; 300 ms), the band follows the drag exactly; its share prints on it (mono). tearProgress = dragDistance / 0.22w; `selectionClick` at progress = 1. Release < 1 → spring back 180 ms (controlled ease, no momentum). | gate: release with tearProgress ≥ 1 → `fly(i)` |
| `fly(i)` | The slice detaches (small tear flash), flies a bezier arc to its dock (650 ms); `BILL` chip decrements by the share in the same beat the tear completes (count-down ticks over 400 ms). | auto → `dock(i)` |
| `dock(i)` i=0..2 | Dock thunk (`selectionClick`); share fades, name label remains. Segment light-up begins ≤ 120 ms after thunk (700 ms bloom): i=0 plant wakes (magnet+coil spin, turbine turns, pulses die at dark pylons) + at +700 `onCapture('magnet_in_the_bill')`; i=1 pylons light, pulses glide the span and stop at the dark pole; i=2 pole steps pulses down, the house bulb lights but visibly wavers (gentle ≤3 Hz luminance waver) and the dial above wanders. Meaning line (S1/S2/S3) at +400. | auto-advance at +2600 → `pull(i+1)` |
| `dock(3)` | Operation slice docks under the dial. The dial needle settles to center and the house light snaps steady **in the same beat** (≤ 120 ms; the steadying is a hard gate, not a slow ease). S4 at +500. | auto-advance at +2800 → `pull(4)` |
| `dock(4)` | Taxes slice docks in the empty end-frame past the house. **Nothing on the journey lights.** Stillness held 900 ms (no text, no motion but the living machine). Then S5. | auto-advance at +3500 → `restackPrompt` |
| `restackPrompt` | T5. An empty receipt outline fades in where the bill card was (400 ms); upward grab-hint on the docked slices. All five docked slices accept an upward drag ≥ 0.08h. | gate: upward drag on any docked slice → `restacking` |
| `restacking` (auto) | All five slices fly back in journey order (280 ms stagger, 1900 ms total), stacking bottom-up into an itemised bar inside the outline (gen at base, taxes on top); `BILL` chip counts 0 → 100 in sync. On landing 100: `heavyImpact`, soft glow burst on the receipt, machine fully alive beneath, SY1, `onCapture('receipt_whole_journey')`. | auto-advance at 1900+2400 → `synthesis` |
| `synthesis` (auto) | SY2 at 0 (the one-concept line, full size). SY3 at 3400. Receipt prints its five lines (static mono text: name + share per slice, TOTAL 100) during SY2's beat. Interaction locked. | auto-advance at 6400 → `bridge` |
| `bridge` (auto) | B1 at 0, PERSISTS. Scene dims slightly; the receipt and the lit journey stay the loudest light. | at 1600 → `showContinue = true` → `done` |
| `done` | Continue CTA (gold pill) → `Navigator.maybePop`. **No card overlay.** | — |

If the learner idles ≥ 4000 ms in any `pull` phase, the imperative re-pulses (scale beat) — lines are state-independent so nothing breaks. Tears are not reversible (a paid slice stays docked); the restack is the only recomposition.

## 7. Hero & layout (portrait, clutter caps)

- **The one hero: the bill-becoming-receipt** — the paper object at the top of the stage. It is the brightest thing on screen at intro (warm paper-white card on near-black) and at the close (the glowing itemised stack); during the middle, the active gold slice in flight is the brightest pixel. The journey strip below is the hero's felt consequence — one scene, read together (the chart+town pattern from EP4).
- **Recedes:** background near-black `#070A1C`, radial vignette darkest behind the bill; the journey silhouettes are dim ink until paid, and even lit they stay one step below the active slice; dock labels small mono; board strip standard gold.
- **Clutter caps for this screen:** hero bill/receipt + journey strip; **at most 1 interactive element at any time** (the active tear band, then the restack drag — far under the 6 cap) besides the Continue CTA; **≤2 live numbers** (`BILL` chip + active slice share); the current text line; the pinned board strip. No legend, no pie chart, no price meter, no demand curve, no digits on the dial.
- Portrait order top-to-bottom: header → board strip → top text (fixed h=96) → bill card → fly space → journey strip with dial → dock row → CTA seat. Full sketch in §16.

## 8. Reward

**No card.** "The bill is a receipt" is not a row in the curriculum quick-reference table — EP5's table rows are the kilowatt-hour (5.1) and natural monopoly/regulation (5.3), and the synthesis this beat performs belongs to the finale CER's "The Whole Machine" card (context pack §6). A card here would restate that card's law one screen early and dilute the finale's earn. The reward IS the orchestrated moment: the restack landing on 100 over the fully-alive machine, with `heavyImpact` and the capture flash — the one place this activity spends its boldness.

**Inline fact: none** (info-cards are removed module-wide; deliberate empty slot).

## 9. CER capture hook

`RepaintBoundary(key: _sceneKey)` wraps background + GameWidget; `controller.onCapture = _onCapture` → `captureScenePng(_sceneKey, cropFactor: evidenceByIdFor('episode5_electricity', id)?.cropFactor)` → `_board.capture(id, imageBytes: bytes)`; `EpisodeBoardStrip` pinned under the header with the EP5 question. Proposed tiles for the EP5 evidence catalog (ids locked here; catalog owner finalizes motifs/crops):

| id | label (≤3 words) | caption (one line) | relevant? | onCapture fires at |
|---|---|---|---|---|
| `receipt_whole_journey` | The Whole Receipt | Stacked back to the same hundred — every slice pays a stage of the journey, magnet to socket. | RELEVANT | `restacking`, the frame the count lands on 100 (with SY1 + heavyImpact) |
| `magnet_in_the_bill` | Same Spinning Magnet | Behind the bill's biggest slice, the same magnet from Episode 1 — still making every unit. | DISTRACTOR (true; answers *how it's made*, not *who pays*) | `dock(0)`, +700 ms after the thunk, magnet visibly spinning |

Suggested cropFactors (normalized LTRB): `receipt_whole_journey` `Rect.fromLTRB(0.06, 0.02, 0.94, 0.86)` (stack + lit machine together); `magnet_in_the_bill` `Rect.fromLTRB(0.0, 0.40, 0.38, 0.92)` (plant miniature + its docked slice).

## 10. Build notes

- **Flame `GameWidget`** for the living scene (bill card + tearing slices, four animated miniatures, gliding pulses, ambient motes, the restack montage) — a multi-layer living world, the trace_it_back pattern. **Flutter overlay** for chrome only: header (title "The Receipt", mono eyebrow "EPISODE 5 · WHO PAYS FOR ALL THIS?"), board strip, FadeSwap top text, CTA seat. GameWidget built once in initState; transparent `Color(0x00000000)` background.
- **Gesture stays in Flutter:** a transparent `Listener` above the GameWidget forwards pointers to the controller (`onPointerDown/Move/Up(Offset local)`); the controller maps drags to tearProgress / restack drag. **No Forge2D** — the tear spring-back is an explicit 180 ms ease, flights are bezier lerps integrated in `tick(dt)`, the dial settle and house steadying are hard-gated state flips, never decayed values.
- Controller-owns-geometry: `BillReceiptController extends ChangeNotifier` owns the phase machine, `_schedule(ms, fn)` timers, slice flight paths, all factor anchors via `setStageSize`. Components are pure renderers reading getters.
- **Miniatures are callbacks, not clip-art:** plant = magnet bar + coil arcs + turbine wheel echoing trace_it_back's core; pylons + catenary with gliding warm pulses echoing source_personalities' source_visual_layer; pole transformer + house echoing the stepping_down/house style; dial = round face, needle, center tick, digitless, echoing grid_frequency. Reuse the shared `paintBulb` for the house bulb if importable; otherwise match its look.
- Haptics: `selectionClick` at tear-threshold and each dock thunk; `heavyImpact` once, at the restack landing on 100; `lightImpact` inside `_onCapture`. Audio: **silent by default** (shipped-acceptable); optional BGM ≤ 0.2 via the audioplayers/mixWithOthers pattern only if EP5 gets episode-wide audio.
- Reduced motion (`MediaQuery.disableAnimations`): flights become fades, motes calm, glow burst becomes a simple bloom — but the same-beat dock reactions, the hard-gated steadying, and the taxes stillness beat are pedagogy and are NEVER softened. House waver stays ≤ 3 Hz gentle luminance (photosensitivity-safe), amplitude reduced further under reduced motion, never removed.
- Persistence: none beyond the evidence board (shared infra). No card store interaction.
- Verification: `fvm dart analyze lib/screens/missions/the_bill_receipt` clean; analyze each imported shared file individually.

## 11. Acceptance criteria (pedagogy as testable checks)

1. **Discoverable from interaction alone:** with all text hidden, grabbing the bill tears a band, the number drops, the slice docks, and the plant's magnet spins — "the bill pays for the plant" is readable wordlessly before any line is read.
2. **The itemisation is discovered, not announced:** at `intro` the bill shows ONE number and no slice names, shares, or perforation lines; perforations first appear under the learner's grab.
3. **Tear mechanics never become the struggle:** the band tracks the finger exactly every frame; release below threshold springs back in ≤ 180 ms with no momentum; release at/above threshold always docks. No aim, no target-matching, no fail-state.
4. **Fixed journey order:** slices tear gen → trans → dist → ops → taxes; only the active band hit-tests; docked slices are inert until `restackPrompt`.
5. **Same-beat reactions:** each segment's light-up begins ≤ 120 ms after its dock thunk; each miniature is a recognizable callback per §10 (spinning magnet+coil; pulses gliding the span; pole stepping them down; digitless dial).
6. **The steadiness gate:** the house lights at `dock(2)` but visibly wavers, and the dial wanders; both snap steady ONLY at `dock(3)`, in the same beat (≤ 120 ms), and S4 appears only after the steadying is visible.
7. **Witnessed absence:** the taxes dock lights nothing on the journey; ≥ 800 ms of stillness precedes S5; no earlier text, label, or visual hints that the fifth slice differs.
8. **Sum discipline (the pin):** the `BILL` chip decrements by exactly the torn share (100 → 52 → 41 → 17 → 13 → 0); the restack counts back to exactly 100; SY1 fires only on 100; the journey silhouettes never change size or shape when paid — they only light.
9. **Numbers discipline:** at most 2 live numbers ever on screen (`BILL` chip + active slice share); all values relative; no ₹/$/kWh/Hz digits anywhere; the dial face is digitless; docked slices show name only; the five shares appear together only as static print on the final receipt.
10. **No new law:** every meaning-line names what the money buys or restates an idea already named in its own episode; no term is introduced for the first time except the reading of the bill (itemised / receipt); no peak-pricing math, no regulator mechanics re-taught.
11. **Captures:** `magnet_in_the_bill` fires exactly once at `dock(0)`+700; `receipt_whole_journey` fires exactly once at the count-100 frame; board strip shows the EP5 question all activity; capture is idempotent.
12. **Text registers:** imperatives ≤ 5 words Title Case; meaning-lines de-personified facts, state-independent; 190 ms fade-out → swap → fade-in (never cross-fade); B1 persists behind the Continue CTA.
13. **No card:** no `CollectibleEarnOverlay` anywhere in this activity; completion = Continue → `Navigator.maybePop`; `MediaQuery noScaling` wrapper present; reduced motion respected per §10; `fvm dart analyze` clean on the activity dir.
14. **Hero discipline:** bill/receipt + journey strip occupy the majority of the frame; the brightest pixel is always the hero (paper card → flying slice → glowing receipt); at most 1 interactive element at a time plus the CTA.

## 12. Anti-patterns to avoid (this activity)

- **A pie chart, bar graph, or legend** — the bill must stay a paper object torn by hand, never a data visualization with a key.
- **Pre-printing the itemisation** (slice names/amounts visible at intro, or a "5 parts" hint) — kills discovery #1.
- **A mapping quiz** (drag the slice to the *correct* segment, wrong answers bounce) — the mapping is revealed by the system's reaction, never tested; there is no wrong move in this activity.
- **Currency symbols or absolute tariff numbers** — ₹/$/paise-per-unit would date the activity and break the relative-numbers rule; 100 is the only scale.
- **Teaching new content** — peak pricing (5.2), monopoly/regulation (5.3), kWh mechanics (5.1) are upstream; this beat synthesises. If a line explains rather than recalls, cut it.
- **Digits on the dial** (e.g. "50 Hz") — a third number, and EP4 owns that readout; here steadiness is felt.
- **Softening the taxes record-scratch** — no civic glow, no consolation animation on the journey; the absence is the lesson. (The slice itself may glow in its dock; the *machine* stays unchanged.)
- **Celebration clutter at the restack** (confetti, badges) — one orchestrated moment: heavyImpact + glow burst + the living machine. Restraint everywhere else.
- **Generic clip-art miniatures** — if the magnet/pylons/pole/dial don't visually echo the activities the learner played, the callbacks (and the whole capstone) don't land.
- **A premium ease on the steadying** — the flicker→steady flip at `dock(3)` is a hard gate; a slow soothing fade would blur cause and effect.

## 13. Open decisions

1. **Slice shares** (48 / 11 / 24 / 4 / 13): defaults reflect realistic Indian tariff proportions (power purchase dominates; operation tiny; duty ~13). Tunable, but must keep generation the biggest, operation the smallest, sum exactly 100, and S1/S4's "biggest/smallest" wording true.
2. **Final receipt printing all five shares** (static mono print at SY2): default YES — a receipt without amounts isn't a receipt, and SY1's "same hundred" deserves the visible sum. Fallback if it reads cluttered on small phones: print names + TOTAL 100 only.
3. **SY3 (regulator callback):** default KEEP (one line, closes 5.3's civic loop on the actual bill). Cut if the synthesis beat feels crowded on device.
4. **Restack gesture:** default drag-any-docked-slice-up; alternative tap on the receipt outline. Decide on feel; the drag is more "assemble", the tap more discoverable.
5. **Taxes dock visual:** default an empty end-frame on the strip past the house (its emptiness IS the point); alternative a slot floating below the strip's end.
6. **B1 phrasing lock:** must match the finale CER's pinned question verbatim at integration time (finale PRD owns the final wording).
7. **BGM:** silent by default; revisit only if EP5 ships episode-wide audio.

---

## 14. State machine sketch

```dart
enum BRPhase { intro, pull, fly, dock, restackPrompt, restacking, synthesis, bridge, done }

enum BRLine { none, t1, t2, t3, t4, s1, s2, s3, s4, s5, t5, sy1, sy2, sy3, b1 }
```

- **ValueNotifiers:** `phase: ValueNotifier<BRPhase>`; `line: ValueNotifier<BRLine>` (register flag imperative/meaning resolved in the copy table); `sliceIndex: ValueNotifier<int>` (0..4, the active slice); `billDisplay: ValueNotifier<int>` (the BILL chip, count-tweened over 400 ms on change); `showContinue: ValueNotifier<bool>`.
- **Hot-path getters** (read by Flame layers each frame): `tearProgress` (0..1 active band), `perforationReveal`, `slicePose(i)` (position/rotation/scale through tear→fly→dock→restack, bezier lerps), `segmentLit[4]` envelopes (plant/pylons/pole+house/dial), `taxDocked`, `magnetAngle`, `turbineAngle`, `pulseT` (per-span packet phase, gated on segmentLit of its span AND all upstream spans), `houseGlow`, `houseWaver` (active only between dock(2) and dock(3); ≤ 3 Hz), `dialAngle` + `dialSettled` (hard flip), `stackProgress`, `receiptPrintReveal`, entrance envelopes (`billReveal`, `stripReveal`), `flashIntensity`, `glowBurst`.
- **Inputs:** `onPointerDown/Move/Up(Offset local)` — in `pull`: hit-test the active band only; drag → tearProgress; release ≥ 1 → `fly`. In `restackPrompt`: upward drag ≥ 0.08h on any docked slice → `restacking`. All other phases ignore pointers.
- **Timers:** `_schedule(ms, fn)` (shipped pattern) drives the §6 table: intro 5200; per-dock meaning line +400/+500; next pull +2600/+2800; taxes stillness 900 then S5, advance +3500; restack stagger 280 × 5 = 1900, then +2400 → synthesis; SY2 0 / SY3 3400, advance 6400; bridge B1 0, `showContinue` at 1600.
- **Gating conditions:** `pull(i)` → `fly(i)`: release with tearProgress ≥ 1 (else spring-back 180 ms). `dock(3)`: `dialSettled = true` and `houseWaver = 0` set in the same frame the dock thunk lands (hard gate). `restackPrompt` reachable only with all 5 docked. `receipt_whole_journey` capture + `heavyImpact` latched once at `billDisplay == 100` during `restacking`. `magnet_in_the_bill` latched once at dock(0)+700. Continue → `Navigator.maybePop` (any pop = completion; no result payload).
- **Hooks:** `onCapture(String id)` (→ lightImpact + scene PNG), `onTearTick`/`onDockThunk` (→ selectionClick), `onSynthesisLand` (→ heavyImpact), `reducedMotion` set from MediaQuery each build.

## 15. File plan

```
lib/screens/missions/the_bill_receipt/
├── the_bill_receipt_screen.dart          — shell: noScaling MediaQuery, header (title "The Receipt",
│       mono eyebrow "EPISODE 5 · WHO PAYS FOR ALL THIS?"), EpisodeBoardStrip(EP5 question),
│       FadeSwap top text (fixed h=96), RepaintBoundary(_sceneKey) wrapping background + GameWidget,
│       transparent Listener forwarding pointers, fixed-height CTA seat, CaptureFlash overlay.
│       NO CollectibleEarnOverlay (no card, §8).
├── state/bill_receipt_controller.dart    — ChangeNotifier: phase machine, _schedule timers, tear/
│       fly/dock/restack kinematics, billDisplay tween, segment envelopes, hard gates, hooks
├── config/br_tuning.dart                 — BRTune: all geometry factors (§16), tear threshold 0.22w,
│       spring-back 180 ms, flight 650 ms, stagger 280 ms, phase timings (§6), palette accents
├── config/br_copy.dart                   — BRLine → verbatim strings + register flags (§5 table)
├── config/slice_defs.dart                — 5 × SliceDef { id, label, share, dockXFactor, accent,
│       segment } : generation 48 · transmission 11 · distribution 24 · operation 4 · taxes 13
├── game/bill_receipt_game.dart           — FlameGame: transparent bg, adds layers back→front,
│       onGameResize → controller.setStageSize, update(dt) → controller.tick(dt)
├── game/components/ambient_layer.dart    — vignette glow behind the bill, ≤ 18 motes
├── game/components/journey_layer.dart    — the strip silhouettes (plant/pylons/pole/house/tax frame)
│       + dock row slots; lit-state blooms (BlendMode.plus), atmospheric depth
├── game/components/miniature_layer.dart  — the living callbacks: magnet+coil+turbine spin, catenary
│       pulse packets, pole step-down, house bulb (waver/steady), digitless dial (wander/settle)
├── game/components/bill_layer.dart       — bill card + BILL chip, perforations, active tear band,
│       flying slices, docked labels, restack bar + static receipt print, glow burst
└── widgets/energy_field_background.dart  — static dark vignette variant (copy-adapt from shipped)
```

Registration in `activityRegistry.dart` and wowConcepts wiring are central-integration work — NOT this build. Evidence catalog entries (`receipt_whole_journey`, `magnet_in_the_bill`) belong to shared infra; this build only calls those ids at the §9 moments. No card constants are referenced.

## 16. Scene sketch (portrait, top-to-bottom, factor-based)

Stage = the Expanded scene area below fixed chrome (header ≈ 56 px, board strip, top text h = 96). All anchors are factors of stage size (w, h) set in `BRTune` via `setStageSize`; no fixed pixel layouts.

```
┌──────────────────────────────────────────┐
│ header: ‹back›  THE RECEIPT              │  Flutter chrome (fixed)
│ EpisodeBoardStrip — EP5 question pinned  │
│ top text (imperative / meaning, h=96)    │
├──────────────────────────────────────────┤  ← stage top
│ BILL CARD (hero)                         │  y: 0.03h–0.36h · x: 0.16w–0.84w
│   [BILL 100] mono chip, top-right        │  warm paper-white on near-black; vignette
│   5 hidden bands (perforations appear    │  brightest behind the card; active band
│   on grab); active band = top band       │  follows the finger; share prints on tear
│   → restack: receipt outline → itemised  │  final: 5 static print lines + TOTAL 100
│     stacked bar (gen base … taxes top)   │
├──────────────────────────────────────────┤
│ fly space                                │  y: 0.36h–0.46h · bezier arcs pass here
├──────────────────────────────────────────┤
│ JOURNEY STRIP (felt consequence)         │  y: 0.48h–0.80h
│  plant      pylons        pole   house ▢ │  plant ≈ x 0.10w (magnet+coil+turbine)
│  (magnet)  (catenary ×2) (xfmr) (bulb)   │  pylons span 0.24w–0.48w; pole ≈ 0.60w
│        digitless DIAL above ≈ x 0.70w    │  house ≈ 0.80w; tax frame ▢ ≈ 0.93w
│                                          │  dial y ≈ 0.44h, small, wired to strip
├──────────────────────────────────────────┤
│ DOCK ROW — 5 slice slots                 │  y: 0.84h–0.92h · x ≈ 0.10/0.36/0.60/
│  [GEN][TRANS][DIST][OPS][TAX]            │  0.72/0.93 w · name labels mono, small
├──────────────────────────────────────────┤
│ CTA seat (h=84, empty until done)        │  Flutter chrome (fixed)
└──────────────────────────────────────────┘
```

Vignette darkest behind the bill card; lit segments bloom warm (`#FFD27A`) one step below the hero; the flying slice is gold (`#F5C451`) and the brightest pixel while airborne. On very small phones the dock row merges into the strip's base (slots at y 0.78h–0.84h) before the bill card ever shrinks below 0.30h — the hero keeps the majority of the frame.
