# PRD — Squared Loss (Episode 2, beat 2.4)
### howwow electricity · registry id `squared_loss` · `SquaredLossScreen` · `lib/screens/missions/squared_loss/` · evidence episode `episode2_electricity`

Binding context: `docs/electricity/context_pack.md` + `docs/electricity/architecture_reference.md` + curriculum beat 2.4. This PRD is self-contained for the build agent; every on-screen line is quoted verbatim here.

---

## 1. One-concept statement

**Transmission heat-loss grows with the square of the current — current is punished hard.** (Double the current, quadruple the waste. Felt first; derived in two clean steps; named I²R last.)

**Chain position (binding):** inherits from 2.1 (voltage drives, current flows), 2.2 (resistance is the wire's opposition, set by its shape — Ohm: current and voltage move in step through a fixed wire), 2.3 (current through resistance turns energy to heat, and that heat IS the lost energy). **Pins:** the WIRE — one wire, fixed resistance, visibly unchanged for the whole activity. The only variable in the learner's hand is the current. Power delivered is NOT pinned here (that flip is 2.5's twist — nothing in this activity may imply the town's delivered power is fixed, which is why no town appears in the scene).

## 2. Guiding-question link + CER contribution

Episode 2 question (pinned on the evidence board strip): **"The plant is far away — how do we send power across that distance without losing it all on the way?"**

This beat supplies the *reason current must be kept tiny* — the punishment term. Without it, 2.5's high-voltage trick is arbitrary; with it, "send at huge voltage so the current stays small" becomes inevitable.

CER contribution: **2 relevant evidence tiles, 0 distractors.**
- `heat_quadruples` (relevant) — the wire glowing fierce at ×2 current with HEAT reading 400. The core clue.
- `square_curve` (relevant, secondary) — the learner's own hand-drawn heat-vs-current curve bending upward. The EP2 CER spec may trim this tile (EP1 precedent: gas/hydro catch but don't capture); both are proposed so the CER owner can choose.
EP2's two true-but-irrelevant distractors should come from other beats (e.g. 2.7's 50 Hz cycle count, 2.8's War-of-the-Currents history) — nothing in this activity is irrelevant to the question, so it proposes none.

## 3. The felt discovery (discovery → reaction)

**Discovery:** the learner drags a current handle from ×1 to ×2 — a small, ordinary nudge. **Reaction:** the wire's heat does not double, it *leaps* — the glow jumps from dull warmth to fierce orange, ember particles thicken, shimmer columns rise, and the HEAT number rolls 100 → 400 while CURRENT only reads ×2.0. The disproportion is the concept. A second nudge to ×3 lands 900. Then the learner *sweeps* the handle and personally draws the heat-vs-current curve — the square's bending SHAPE appears under their own finger. Only after all of that is felt does the activity walk the two-step derivation (volts lost along the wire ∝ current; heat = lost volts × current), each step confirmed by the learner's own nudge, and only then is the law named I²R.

The interaction IS the concept: the learner's hand supplies the linear input; the scene returns the squared output.

## 4. Felt vs named vs numbered

- **Felt:** the wire's glow leaping disproportionately (color lerp dull copper → heat orange → near-white); ember particles and heat-shimmer thickening with the square; the curve bending upward under the learner's sweep; the contrast against a faint straight ghost line.
- **Named (a beat after felt):** "volts lost along the wire" (named when its chip appears, after two felt heat-jumps); **I²R** (named only after the multiplication is felt in the derivation, phase `named`).
- **Numbered (live, relative, ≤2 at any time):** `CURRENT ×N.N` (multiplier, base ×1.0) and EITHER `HEAT 100…1600` (base 100 at ×1) OR `LOST VOLTS 100…200` (base 100 at ×1) — the right-hand chip is exclusive-swap, never both. All numbers are relative (base = 100), never absolute watts/volts.
- **No ratings table anywhere. No number for any qualitative judgment** — "how violent the heat is" stays felt (glow, embers, shimmer), the number only carries the genuine quantity.

## 5. On-screen text (exact, beat by beat)

Imperatives = Bricolage Grotesque, large, Title Case, ≤5 words. Meaning-lines = Plus Jakarta Sans, de-personified facts. Secondary lines = small mono hint under the imperative. Swap via 190 ms fade-out → swap → fade-in.

| # | Beat | Register | Line (verbatim) |
|---|---|---|---|
| T1 | Enter | meaning | `One long transmission wire. The wire is fixed — only the current changes.` |
| T2 | Enter→firstPush | imperative | `Push the Current Up` (secondary: `TAKE IT TO ×2`) |
| T3 | ×2 lands (DISCOVERY) | meaning | `Double the current — four times the heat.` |
| T4 | secondPush | imperative | `Push It Again` (secondary: `TAKE IT TO ×3`) |
| T5 | ×3 lands | meaning | `Triple the current — nine times the heat.` |
| T6 | +2400 ms | meaning | `The heat grows far faster than the current that causes it.` |
| T7 | sweep | imperative | `Sweep the Current` (secondary: `SLOWLY, END TO END`) |
| T8 | sweep complete | meaning | `Your sweep drew the curve — it bends upward, steeper with every step.` |
| T9 | +3000 ms (ghost line fades in) | meaning | `If heat only kept pace with current, it would follow the straight line. It doesn't.` |
| T10 | voltsStep intro | meaning | `Why the square? The wire has its own small resistance — some voltage is used up just crossing it.` |
| T11 | voltsStep | imperative | `Double the Current` (LOST VOLTS chip live) |
| T12 | ×2 lands | meaning | `Twice the current, twice the volts lost along the wire — exactly in step.` |
| T13 | multiplyIntro | meaning | `And the wasted power is those lost volts × the current flowing through them.` |
| T14 | multiplyPush | imperative | `Double It Once More` (HEAT chip back) |
| T15 | ×2 lands | meaning | `Twice the volts × twice the current — four times the heat. Current × current.` |
| T16 | named | meaning | `Engineers write that waste as I²R — current squared, times the wire's resistance.` |
| T17 | closing (after card, stays with Continue) | meaning | `The far town still needs its full power — and the wire punishes current. So how do you send big power with a tiny current?` |

Static scene label (mono, 9 px, pinned at the wire's left anchor, present from entry to exit): `SAME WIRE · FIXED RESISTANCE`. Chip labels (mono): `CURRENT`, `HEAT`, `LOST VOLTS`. CTA: `Continue`. No other text. No mascot, no info-cards. T17 is a cliffhanger question posing 2.5 — it names the tension, never the answer (no mention of voltage-raising).

## 6. Beat-by-beat flow (timing + gating)

1. **enter (0–2600 ms).** Scene reveals (pylons + wire slide/fade in, 450 ms, `lbReveal`-style). Wire at ×1: faint warm glow (2.3 inheritance — current already heats it a little). T1 holds 2600 ms → T2. Chips fade in: CURRENT ×1.0 + HEAT 100. Slider unlocks, range [×1, ×2], detents.
2. **firstPush.** Waits for the learner (no timeout-advance; the handle pulses gently after 7000 ms idle as the only nudge). Gate: handle reaches the ×2 detent (snap + `selectionClick`). On landing: glow/embers respond same-frame; HEAT rolls 100→400 over 600 ms; discovery flash (~700 ms envelope) + `HapticFeedback.heavyImpact` at landing; **capture `heat_quadruples`** fires 650 ms after landing (post-roll, so the tile shows the fierce wire + HEAT 400). T3 swaps in at landing. Hold 2600 ms → 3.
3. **secondPush.** T4; range extends to [×1, ×3]. Reversible (learner may drag back down; numbers track continuously). Gate: ×3 detent → T5; +2400 ms → T6; +2800 ms → 4.
4. **sweep.** T7. Graph panel slides up (reveal 450 ms, occupies lower stage); slider becomes continuous, range [×1, ×4]; detent ticks fade out. As the handle moves, a glowing dot trail plots (current, heat) on the panel — drawn ONLY where the learner's handle has actually been (24 coverage buckets across the range). Gate: ≥21/24 buckets visited. On completion: trail closes into a continuous curve with a 500 ms glow pulse; **capture `square_curve`** fires 600 ms after completion; T8 swaps in; +3000 ms → faint straight ghost line (origin→(×4, 400-equivalent)) fades in 400 ms under the curve + T9; +3400 ms → 5.
5. **voltsStep.** T10 (allowed-longer line) holds 3400 ms. Right chip fade-swaps (190 ms) HEAT → LOST VOLTS 100; handle auto-eases back to ×1 over 800 ms (visible glide — a reset, not a cutoff); range relocks [×1, ×2] detents; graph panel dims to 35 % opacity (stays visible, recedes). T11. Gate: ×2 detent → LOST VOLTS rolls 100→200 (400 ms) → T12; hold 3000 ms → 6.
6. **multiplyIntro → multiplyPush.** T13 holds 2800 ms; chip swaps back to HEAT 100; handle eases to ×1 (800 ms); T14. Gate: ×2 detent → HEAT rolls 100→400 + `heavyImpact` (the derivation's payoff lands physically too) → T15; hold 3400 ms → 7.
7. **named.** T16 holds 4200 ms. Wire stays live at ×2 (still glowing — the law is named over the felt thing).
8. **card earn.** `showCardEarn = true` → `CollectibleEarnOverlay` (Card: The Square Tax, §8). On collect → 9.
9. **closing/done.** T17 swaps in and STAYS; `done = true`; Continue CTA appears in its fixed seat. Continue → `Navigator.maybePop(context)`.

Reversibility: within any push/sweep phase the handle may move freely inside its unlocked range and all live values track continuously (no high-water-mark). Phases only advance forward. Total play length ~90–130 s.

## 7. Hero & layout

**The hero is the WIRE — its heat glow is the brightest, most alive thing on screen.** At ×3+ it outshines everything (near-white-orange core, additive bloom, embers). Everything else recedes: near-black `#070A1C` field, quiet glass chrome (`0x14FFFFFF` fills, `0x26FFFFFF` borders), pylons as dim silhouettes, graph panel dark glass, no town, no plant, no clouds.

Portrait layout (top→bottom): header → EpisodeBoardStrip (EP2 question) → top-text (fixed height 96, never resizes the stage) → stage (Expanded; wire upper third, chips mid, graph panel lower — §16) → current slider → fixed-height CTA seat (84).

**Clutter caps (binding):** one hero (the wire); interactive elements = current slider + Continue CTA + header back + optional sound toggle = **4 ≤ 6**; **≤2 live numbers** at any instant (CURRENT + exclusive right chip); one current text line (+ optional mono secondary); the static `SAME WIRE · FIXED RESISTANCE` tag; nothing else. No town (wrong physics for this pin), no plant art, no voltage control, no extra meters.

## 8. Reward

**Card: YES** — the concept is a quick-reference-table row ("Loss grows with current squared | I²R | Ep 2 | Fully explained (two steps)"). Proposed copy (shared-infra agent consolidates; build agent only references the eventual `kSquareTaxCard` constant):

- **Playful name:** The Square Tax
- **Real term (mono specimen label):** `JOULE HEATING · I²R`
- **One-line law:** Wasted heat grows with the square of the current — double the current, quadruple the loss.
- **Kicker:** Current is punished hard.
- **Back — tie to what was felt:** You nudged the dial from ×1 to ×2 and the wire's heat leapt fourfold. Volts lost along the wire grow with the current — and the heat is those volts times the current again. Current × current.
- **Back — outward reach:** The same square is why a phone fast-charger raises voltage instead of pushing more current.
- **Linked card:** the 2.3 current→heat card (the "loss = heat" recurring thread; id assigned by shared infra). Section: transmission, accent `#3FB9F5`. Motif suggestion: a steep parabola rising off a glowing wire.
- Earn invocation: `CollectibleEarnOverlay(card: kSquareTaxCard, eyebrow: 'NEW CARD', brag: 'Double the current, quadruple the waste — you felt the square.', showMascot: false, onDone: controller.onCardCollected)`.

**Inline fact: none** (deliberate empty slot — the closing cliffhanger T17 must be the last thing read).

## 9. CER capture hook

RepaintBoundary wraps background + stage + chips (chips INSIDE the snapshot so HEAT 400 appears on the tile); text, slider, chrome outside.

| id | label (≤3 words) | caption (one line) | relevant | onCapture moment | suggested crop |
|---|---|---|---|---|---|
| `heat_quadruples` | `Quadruple Heat` | `Doubling the current made four times the wire heat.` | relevant | 650 ms after the first ×2 landing (flow step 2), post number-roll | wire band + chips (≈ LTRB 0.05, 0.08, 0.95, 0.55 of scene) |
| `square_curve` | `The Bending Curve` | `Heat versus current bends upward — the square, drawn by hand.` | relevant | 600 ms after sweep coverage completes (flow step 4), before ghost line | graph panel (≈ LTRB 0.08, 0.45, 0.92, 0.85) |

Wiring is the shipped pattern verbatim: `controller.onCapture = _onCapture` → `lightImpact` → `captureScenePng(_sceneKey, cropFactor: evidenceByIdFor('episode2_electricity', id)?.cropFactor)` → `_board.capture(id, imageBytes: bytes)`. Exact ids and cropFactors are finalized in the shared EP2 evidence catalog — call exactly these ids at exactly these moments.

## 10. Build notes

- **Rendering: plain Flutter `CustomPainter` + `Ticker` (the hand_crank_lamp pattern). NOT Flame.** Rationale: one hero widget (wire + particles) + one precision graph + one slider; no parallax layers, no swappable front-ends. hand_crank_lamp already proved glow/particles/discovery-flash in a plain painter. **No Forge2D** (banned; all motion is direct-driven).
- Controller-owns-geometry: `SquaredLossController extends ChangeNotifier` owns the sim (current, heat, volts, particle field, coverage buckets), the phase machine with `_schedule(ms, fn)` timers, and all factor-based geometry from `setStageSize(size)` (set once per paint). Painters are pure renderers reading getters; `CustomPaint(painter: …, repaint: controller)`.
- Physics (relative units): `heat = 100 * I*I`, `lostVolts = 100 * I`, `wireGlow = (I/4)^2` clamped; displayed numbers roll toward targets over 400–600 ms (number-roll only — **glow/embers/shimmer respond same-frame**, no easing on the felt channel). Handle has zero momentum: position = clamped finger x; release leaves it exactly where it is.
- Slider: custom widget (Listener on a track), detent snap within 6 % of a tick + `selectionClick`; per-phase range lock and detent/continuous mode from the controller.
- Particles: adapt `crank_particles.dart` → embers (heat `#FF7A2E`, additive `BlendMode.plus`, upward drift, lifetime ~1.4 s, spawn rate ∝ heat, cap 48) + ≤20 ambient cool motes. Shimmer = 3–5 refracting columns above the wire, amplitude ∝ heat.
- Haptics: `selectionClick` per detent; `heavyImpact` at the ×2 discovery landing AND the multiplyPush ×2 landing; `lightImpact` on each capture (inside `_onCapture`).
- Audio: **silent** (no BGM, no SFX) — matches most shipped electricity activities; open decision §13 if a low heat-sizzle is wanted later.
- Shell: `MediaQuery(textScaler: TextScaler.noScaling)`; `MediaQuery.disableAnimations` → calm embers/shimmer, reveals become fades, number rolls become steps — pedagogical mappings unchanged.
- Persistence: none beyond the shared evidence board + collectible store (both shared infra). No local prefs.
- File-surface rule: write ONLY inside `lib/screens/missions/squared_loss/`. Registry, EP2 evidence catalog, card constants, wowConcepts are other phases' files — if a change there seems needed, STOP and report.
- Verify: `fvm dart analyze lib/screens/missions/squared_loss` clean (repo has ~468 pre-existing errors elsewhere — not yours; never multi-path analyze).

## 11. Acceptance criteria (pedagogy as testable checks)

1. **Discoverable from interaction alone:** with all text hidden, dragging ×1→×2 produces a visibly disproportionate jump in wire glow + ember density (4×, not 2×). The disproportion reads before any line is read.
2. **The numbers square exactly:** at detents, HEAT = 100·I² (100/400/900/1600) and LOST VOLTS = 100·I (100/200/300/400). Verified at every detent.
3. **Held-constant is visible:** the wire's thickness, length, and the `SAME WIRE · FIXED RESISTANCE` tag never change from entry to exit; no control on screen can alter the wire.
4. **≤2 live numbers at any instant:** the right chip is an exclusive swap (HEAT xor LOST VOLTS); CURRENT + HEAT + LOST VOLTS never co-visible, including mid-fade.
5. **The curve is learner-drawn:** the graph shows trail only where the handle has actually been; an incomplete sweep leaves visible gaps; the phase gates on ≥21/24 coverage; no pre-drawn curve ever appears.
6. **Name-last:** the string `I²R` appears nowhere (text, chips, labels) before T16; "lost volts" appears nowhere before T10/T11.
7. **Derivation is mandatory and two-step:** T10–T12 (volts ∝ current, confirmed by a learner nudge with the LOST VOLTS chip live) and T13–T15 (heat = volts × current, confirmed by a learner nudge with the HEAT chip live) both land before naming. The curve alone never ships the lesson (honesty guardrail: this is fully explainable, NOT a depth-stop — no "nobody knows why" anywhere).
8. **Felt channel is instant:** glow/embers/shimmer track the handle in the same frame (≤1 frame lag); only the printed numbers roll (≤600 ms); the handle has no momentum/coast after release.
9. **Discovery moment is orchestrated once:** flash + heavyImpact at the first ×2 landing only; `heat_quadruples` captures 650 ms after it with HEAT reading 400 in-frame.
10. **Captures:** exactly ids `heat_quadruples` and `square_curve`, at the moments in §9, idempotent, with `lightImpact`, board strip updating live.
11. **No ratings table; no qualitative number:** heat violence is conveyed by glow/embers/shimmer only; no town, no delivered-power readout, no efficiency %.
12. **Hero brightness:** at ×2+, the wire is measurably the brightest element on screen; chrome stays glass-quiet.
13. **Catch lines name consequence/destination:** T3/T5/T15 name *heat* (the destination from 2.3), never "the wire acts up" or behaviour-words; no rhyme in any line.
14. **Cliffhanger does not pre-spoil 2.5:** T17 poses the question; the words "voltage", "raise", "transformer" do not appear in it.
15. **Flow + chrome:** card overlay fires once after T16 and before Continue; Continue calls `Navigator.maybePop`; reduced-motion path works; small-phone portrait (≈360×640 logical) shows hero + slider + text without overflow.
16. `fvm dart analyze lib/screens/missions/squared_loss` is clean; play length 60–150 s in normal use.

## 12. Anti-patterns (this activity)

- **A heat meter/bar where the felt wire belongs.** The wire IS the readout; the number rides alongside, smaller than the glow.
- **A town or delivered-power readout.** Pushing current up here also delivers more power — showing a town would either lie or teach 2.5's pin early. Cut.
- **Pre-spoiling the square:** no curve, no "squared", no ×4 promise visible before the first ×2 landing. The graph panel does not exist until phase `sweep`.
- **Easing the jump:** a slow tween on glow at the discovery kills "nudge a little → jumps a LOT". Glow is same-frame; only digits roll, fast.
- **Three numbers in the derivation** (the "LOST VOLTS × CURRENT = HEAT equation chip" trap). The words carry the multiplication; the chips stay ≤2.
- **A scientific graph:** numeric axes, gridlines, units on the panel are clutter — the panel is shape-first (trail + ghost line only).
- **"Nobody knows why" / mystery framing.** This beat is fully explainable in two steps; the derivation is the point.
- **Slider physics:** fling/momentum/snap-back animations on the handle (except the scripted 800 ms phase resets) break the one-variable hand-feel.
- **Imperatives that explain** ("Push current to see squared heat") — imperatives ≤5 words, instruction only; meaning-lines teach.
- **Premium fade on phase resets disguising them as physics** — the auto-ease back to ×1 must read as the handle being reset (the glide is visible and the glow tracks it down honestly).

## 13. Open decisions

1. **Sweep top range:** ×4 (heat 1600, more dramatic parabola) vs ×3 (less glow saturation headroom needed). Recommend ×4; build agent may pull to ×3 if the glow ceiling clips.
2. **Ghost straight line (T9):** recommended in; may be cut if the panel reads cluttered on small phones (then T9 is also cut).
3. **Auto-ease handle resets** between derivation steps vs asking the learner to drag back to ×1. Recommend auto-ease (less friction, scripted-reset honest).
4. **`square_curve` tile survival** in the EP2 CER evidence set — CER spec owner's call.
5. **Linked-card target** ("loss = heat" thread → the 2.3 card vs the orphaned Card 04) — shared-infra agent resolves at catalog consolidation.
6. **Audio:** silent (default) vs a faint heat-sizzle loop tied to heat level (vol ≤0.2) added later.

## 14. State machine sketch

```dart
enum SLPhase { enter, firstPush, secondPush, sweep, voltsStep, multiplyIntro, multiplyPush, named, cardEarn, closing }
enum SLChip { heat, volts }
enum SLCaption { t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17 } // copy table §5; each flagged imperative|meaning + optional secondary
```

`SquaredLossController extends ChangeNotifier`:
- **ValueNotifiers:** `caption: ValueNotifier<SLCaption>`, `phase: ValueNotifier<SLPhase>`, `chip: ValueNotifier<SLChip>`, `showCardEarn: ValueNotifier<bool>`, `done: ValueNotifier<bool>`.
- **Hot-path getters (painter reads):** `current` (1.0–4.0), `heat` (=100·I²), `lostVolts` (=100·I), `displayHeat`/`displayVolts` (rolled), `wireGlow`, `shimmerPhase`, `particles`, `flashIntensity`, `graphReveal` (0–1), `ghostReveal`, `curveTrail: List<Offset>` (normalized), `coverageCount`, `handleX` (normalized slider pos), `handleEase` (scripted reset tween value), `revealT` (entrance).
- **Input:** `onHandleDown/Move/Up(double localX)` → normalized → clamped to phase range → detent snap (detent mode) or raw (sweep mode); `onHandleTick` → `selectionClick` per detent crossing.
- **Hooks:** `onDiscovery` (→ heavyImpact, screen flash), `onCapture(String id)`, `onCardCollected` (→ phase closing, done=true), `reducedMotion: bool` set each build.
- **Timers** (all `_schedule(ms, fn)`, cancelled on dispose): enter→T2 2600; T3 hold 2600; T5→T6 2400; T6→sweep 2800; T8→T9 3000; T9→voltsStep 3400; T10 hold 3400; T12→multiplyIntro 3000; T13 hold 2800; T15→named 3400; T16→cardEarn 4200; resets 800 (handle ease); rolls 400–600; reveal 450; text swap 190; idle handle-pulse 7000.
- **Gates:** firstPush: `current snapped == 2.0` (range lock [1,2]); secondPush: `== 3.0` (lock [1,3]); sweep: `coverageCount >= 21` of 24 buckets (lock [1,4], continuous); voltsStep & multiplyPush: `== 2.0` (lock [1,2]); cardEarn: overlay onDone; closing: Continue tap → `Navigator.maybePop`.
- **tick(double dt)** (Ticker in shell, 60 fps): advance shimmer/particles/flash envelopes/number rolls/reveal tweens/handle ease; spawn embers ∝ heat; in sweep mode append `curveTrail` point + mark bucket when handle moves; `notifyListeners()`.

## 15. File plan

```
lib/screens/missions/squared_loss/
├── squared_loss_screen.dart            — shell: noScaling MediaQuery, Ticker, header (back + title
│       'The Squared Loss', mono eyebrow 'EPISODE 2 · THE LONG WAY HOME'), EpisodeBoardStrip
│       (EP2 question, _board), fixed-96 top-text (_FadeSwapCaption 190 ms), Expanded stage in
│       RepaintBoundary(_sceneKey), CurrentSlider, fixed-84 CTA seat, CaptureFlash +
│       CollectibleEarnOverlay layers, _onCapture wiring (architecture_reference verbatim pattern)
├── state/squared_loss_controller.dart  — everything in §14
├── state/heat_particles.dart           — ember + mote ParticleField (adapted from crank_particles.dart)
├── config/squared_loss_tuning.dart     — SLTune: geometry factors (§16), detents, ranges per phase,
│       timing constants (§14), color tokens (heat #FF7A2E, energy #FFD27A, ink #0B1026), caps
│       (48 embers, 20 motes, 24 buckets / 21 gate), roll durations
├── config/squared_loss_copy.dart       — SLCaption enum + SLCopy lookup: text §5 verbatim, register
│       flag (imperative|meaning), optional secondary string
└── widgets/
    ├── wire_stage.dart                 — Listener-free CustomPaint(painter: WireStagePainter(c), repaint: c)
    ├── wire_stage_painter.dart         — pure renderer: vignette → pylon silhouettes → wire core +
    │       additive bloom (∝ wireGlow) → shimmer columns → embers → SAME WIRE tag → readout chips
    │       (mono, dark glass, drawn in-painter so they're inside the snapshot) → discovery flash
    ├── heat_curve_panel.dart           — graph CustomPainter: dark glass panel, learner trail (warm,
    │       additive glow), gaps honest, ghost straight line (ghostReveal), no axes/units
    ├── current_slider.dart             — track + glowing handle; detent ticks (fade in sweep mode);
    │       pointer → controller.onHandleDown/Move/Up; zero momentum
    └── energy_field_background.dart    — static dark vignette variant (copy-adapt from trace_it_back)
```

No edits outside this directory. Card constant `kSquareTaxCard` and EP2 evidence ids are referenced, never defined here.

## 16. Scene sketch (portrait, factors of stage size S = w×h of the Expanded stage)

Top → bottom:
- **Above stage (Flutter column):** header (~48) → EpisodeBoardStrip → top-text fixed 96 → stage.
- **Wire band (hero):** pylon silhouettes anchored at x = 0.07·w and 0.93·w, crossarms at y = 0.14·h; catenary wire sagging to y = 0.26·h at midspan; wire stroke ~0.012·w core + bloom radius up to 0.10·w at max glow; ember spawn along the span, drifting up and dying by y ≈ 0.04·h; shimmer columns 0.18→0.04·h. Vignette darkest behind midspan.
- **Tag:** `SAME WIRE · FIXED RESISTANCE` mono 9 px at (0.10·w, 0.33·h).
- **Readout chips:** CURRENT at (0.27·w center, 0.42·h), right chip (HEAT/LOST VOLTS) at (0.73·w center, 0.42·h); chip height ~0.055·h, mono 15–17 px digits, trend arrow on the right chip.
- **Graph panel:** rect (0.08·w, 0.50·h) → (0.92·w, 0.86·h); hidden until `sweep` (slides up from +0.06·h, 450 ms); dims to 35 % opacity from `voltsStep` on; trail plotted with x = (I−1)/3, y = 1−(heat/1600), inside 0.06-padded panel space.
- **Below stage (Flutter column):** CurrentSlider — track from 0.10·w to 0.90·w, height ~56 logical, detent ticks at ×1/×2/×3/×4 positions, handle Ø ~40 with warm glow when touched → CTA seat 84 (gold gradient pill `#F5C451 → #D9A43B`, h 52).
- Small-phone check: with the graph revealed, wire band + chips + panel must coexist; if h is tight, the wire band compresses to 0.10–0.30·h before the panel shrinks (hero is protected last).
