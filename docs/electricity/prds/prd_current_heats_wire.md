# PRD — The Hot Wire (current_heats_wire)
### howwow · Episode 2 "The Long Way Home" · beat 2.3 — Why current heats the wire
### Registry id `current_heats_wire` · dir `lib/screens/missions/current_heats_wire/` · class `CurrentHeatsWireScreen` · evidence episode `episode2_electricity`

Binding context: `docs/electricity/context_pack.md`, `docs/electricity/architecture_reference.md`, curriculum §1–§9, §13 and beat 2.3. This PRD is self-contained: every on-screen line is quoted verbatim below. **This is the module's first full teaching of loss = heat** (the leaky bucket is gone) — it carries foundational weight.

---

## 1. One-concept statement

**Current through resistance produces heat — and that heat IS the "lost" energy.** (Loss is a destination, not an ending: the energy leaves the wire as heat; conservation holds.)

**Chain position (the 2.1→2.5 contract).** *Inherits:* voltage drives, current flows (2.1, felt with the wire fixed); resistance is the wire's opposition, set by its shape (2.2). *Pins:* the wire itself — same wire, same resistance, all beats; nothing about the wire ever changes on screen. The only manipulated variable is current. This pin is what lets 2.5 later flip the held-constant to *fixed power, free wire* as a twist instead of a contradiction.

## 2. Guiding-question link + CER contribution

Episode question (pinned on the evidence board all activity): **"The plant is far away — how do we send power across that distance without losing it all on the way?"**

This beat supplies the middle premise of the episode claim ("we send at very high voltage so the current stays tiny, because wire heat grows with the square of current"): **sending current through a long wire bleeds energy as heat — that's what "losing it on the way" physically is.**

- Relevant evidence: tile `heat_leaves_wire` (§9) — the wire glowing while warmth streams off it en route to the lamp.
- **Distractor proposal:** tile `rubbed_warm` (§9) — rubbing the wire by hand makes the same heat. TRUE (friction is the same physics), but it answers *what kind of process heating is*, not *how we send power far without losing it*. Flag to the EP2 CER-config owner as a candidate for one of the episode's exactly-2 distractors; if the episode's distractor pair is taken elsewhere, ship this tile anyway as relevant:false in the catalog or drop it — owner's call.

## 3. The felt discovery (discovery → reaction)

1. **Discovery A:** the learner drags one slider (current) up. → **Reaction:** the wire — the thing that until now was just the carrier — begins to glow from within, dull ember to deep orange, and sheds a rising heat shimmer into the dark. The HEAT number climbs with the CURRENT number. Drop the slider → pulses and heat *generation* stop the same frame; the residual glow cools away.
2. **Discovery B (the friction parallel, felt not told):** with the current locked at zero, the learner rubs a finger back and forth along the wire. → **Reaction:** the same orange warmth blooms under the finger, the same shimmer rises, and the SAME HEAT number climbs — while CURRENT reads 0. Two different causes, one identical response: the system itself reveals that current-through-resistance is a kind of rubbing.
3. **Discovery C (the destination):** current high again, the learner watches energy pulses travel toward the lamp and visibly shed warmth along the way — the stream that reaches the lamp is thinner than the stream that left the plant. The "lost" energy is *seen leaving* as heat.

The interaction IS the concept: nothing explains heat; the wire heats under the learner's own push, and the rub makes the mechanism kinship tactile before any line names "friction" or "loss".

## 4. Felt vs named vs numbered

- **Felt:** the wire's internal glow (ember → deep orange); the rising heat-shimmer motes; warmth blooming under the rubbing finger; the wire cooling when current drops; the lamp's small brightness at the far end; energy pulses thinning toward the lamp while motes peel off.
- **Named (each a beat AFTER it is felt):** "heat" (after the first glow), "friction" (after the rub), **"loss"** (named last, the term this activity owns — only after heat has been felt from both causes and seen leaving the wire).
- **Numbered (exactly 2, live, relative — never absolute units):** `CURRENT` (0–100, slider-driven) and `HEAT` (0–100, the wire's warmth). No third number ever. No ratings table. No number for any qualitative judgment — the glow and shimmer are the felt readout; the numbers ride alongside it.
- Heat physics is honest: heat input ∝ current² (normalized so CURRENT 100 → HEAT 100). The text NEVER names or points at the growth rate — noticing the square is beat 2.4's job (see §13/§16-OD1).

## 5. On-screen text (EXACT — the complete set)

Two registers only: **imperatives** (Bricolage Grotesque, large, Title Case, ≤5 words) and *meaning-lines* (Plus Jakarta Sans, de-personified facts). No mascot, no info-cards, no inline fact (deliberately none — an aside here would dilute the foundational landing).

**Beat A — push the current**
- A1 imperative (on entry): **Raise the Current**
- A2 secondary (only once wireTemp ≥ 0.35 — never before the effect is visible): **Higher — Hotter**
- A3 meaning-line (discovery, current ≥ 0.75 held 600 ms): *The wire itself is heating.*
- A4 meaning-line (+2800 ms): *Current forced through resistance gives off heat.*
- A5 imperative: **Now Drop It Low**
- A6 meaning-line (current ≤ 0.15 and wireTemp ≤ 0.25): *The wire cools the moment the current drops.*

**Beat B — the rub (friction, felt)**
- B1 imperative (slider locked at 0): **Now Rub the Wire**
- B2 secondary (rubHeat ≥ 0.2, mid-rub): **Faster — Warmer**
- B3 meaning-line (rubHeat ≥ 0.5 with ≥3 stroke reversals): *Rubbing turns motion into heat — that is friction.*
- B4 meaning-line (+3000 ms): *Current pushing through resistance is the same kind of rubbing.*

**Beat C — the destination (loss named last)**
- C1 imperative (slider unlocked): **Raise the Current Again**
- C2 imperative (current ≥ 0.75 held 600 ms; mote emphasis on): **Now Watch the Wire**
- C3 meaning-line (+1800 ms; capture fires here): *The warmth rising off the wire is energy leaving it.*
- C4 meaning-line (+3000 ms): *That energy is not destroyed — it is heat now, spreading into the air instead of reaching the lamp.*
- C5 meaning-line (+3600 ms, the naming): *This is what "loss" means on a power line: energy leaving as heat along the way.*

**Beat D — synthesis → card**
- D1 meaning-line (synthesis, +3400 ms): *Lost energy is not gone — it leaves as heat.*

**Chrome (static, mono micro-labels, 9–10 px):** header title **The Hot Wire**, eyebrow `EPISODE 2 · TRANSMISSION`; scene tags `PLANT` (left node), `LAMP` (right node), `SAME WIRE` (under midspan — the visible held-constant); number chips `CURRENT` / `HEAT`; slider label `CURRENT`; CTA **Continue**; card overlay eyebrow `NEW CARD`, brag line: **"You watched energy leave — and knew exactly where it went."**

Rule check: imperatives ≤5 words, instruct only; meaning-lines name the noun, state facts, name destinations ("leaves as heat", "spreading into the air"), never endings ("gone", "wasted away"); no rhyme; "friction" and "loss" land only after being felt; depth-stop: none needed — this concept is **fully explainable** and the lines explain it honestly (never "nobody knows why").

## 6. Beat-by-beat flow (timing + gating)

- **t=0:** entrance reveals (pylon posts, catenary wire, plant stub, lamp: slide+scale+fade, 450 ms, 80 ms stagger). 600 ms → A1 **Raise the Current**. Slider live, rub disabled.
- **Beat A (learner-paced, typically 8–18 s):** slider drives current (eased τ 120 ms). Wire glow + shimmer + both numbers respond continuously. wireTemp ≥ 0.35 → A2 secondary. **Gate:** current ≥ 0.75 sustained 600 ms → DISCOVERY: glow flash (700 ms envelope) + `heavyImpact` → A3 (hold 2800 ms) → A4 (hold 3200 ms) → A5 **Now Drop It Low**. **Gate:** current ≤ 0.15 AND wireTemp ≤ 0.25 → A6 (hold 2600 ms). Reversible throughout — the learner may pump the slider freely; gates only ever advance.
- **Beat B (~12–20 s):** slider animates to 0 over 300 ms, then locks (dimmed, CURRENT chip reads 0 — deliberately visible during the whole beat). B1 **Now Rub the Wire**. Rub = pointer strokes inside the wire band; each direction reversal = `selectionClick`; rubHeat accumulates with stroke speed; glow blooms under the finger; HEAT number rises. rubHeat ≥ 0.2 → B2 secondary. **Gate:** rubHeat ≥ 0.5 AND ≥3 reversals → capture `rubbed_warm` (`lightImpact`, CaptureFlash) → B3 (hold 3000 ms) → B4 (hold 3200 ms). Stop rubbing anytime → warmth cools (τ 0.9 s); the gate is a high-water mark, never lost.
- **Beat C (~10–15 s):** slider unlocks; C1 **Raise the Current Again**. **Gate:** current ≥ 0.75 sustained 600 ms → mote emission ×1.6 + pulse-taper emphasis on (pulses visibly thin toward the lamp as motes peel off) → C2 (hold 1800 ms) → capture `heat_leaves_wire` (`lightImpact`) + C3 (hold 3000 ms) → C4 (hold 3600 ms) → C5 (hold 3400 ms).
- **Beat D:** D1 synthesis (hold 2600 ms) → `showContinue = true` (CTA fades into its fixed-height seat; scene stays live under the learner's slider). Continue tap → `CollectibleEarnOverlay` (card §8) → "Add to your deck" → `onCardCollected` → `Navigator.maybePop`.
- All text swaps: 190 ms fade-out → swap → fade-in (never cross-fade). Total guided run ≈ 65–110 s (within the 60–150 s target).
- **Hard gates (instant, pedagogical):** the frame current reaches 0 — pulse travel stops AND heat *generation* (mote spawn + heat input) goes to 0 in that same frame. The residual glow then cools on a physical decay (τ 0.9 s) — that decay is real thermal physics, not a softening fade, and the A6 line glues the cause ("the moment the current drops"). No slider momentum, no coasting anywhere.

## 7. Hero & layout (portrait; clutter caps)

- **The hero is the wire and its heat.** At high current the wire's glow is the brightest thing on screen (additive `BlendMode.plus` bloom, heat `#FF7A2E` core, warm energy `#FFD27A` pulses). The lamp is deliberately secondary — its peak luminance is capped below the wire's glow peak (it is 2.5's payoff, not this beat's).
- **Recedes:** near-black `#070A1C` field + radial vignette darkest behind the wire midspan; plant stub and lamp small at the ends; chrome on dark glass (`0x14FFFFFF` fills, `0x26FFFFFF` borders); 16–20 ambient cool motes max.
- **Portrait stack (top→bottom):** header (back + title) → `EpisodeBoardStrip` (pinned question) → top-text seat (fixed height 96 — stage never resizes) → stage (Expanded; the span scene, §16) → number-chip row (CURRENT | HEAT) → slider → fixed-height CTA seat (84).
- **Clutter caps, stated:** 1 hero (the wire) + 1 essential control (the slider; the wire band doubles as the rub surface) + **exactly 2 numbers** + the current text line + 3 static mono micro-tags (`PLANT`, `LAMP`, `SAME WIRE` — each load-bearing: the span must read as power-going-somewhere, and the held-constant must be visible). **Interactive elements: 4** (back, slider, wire rub band, Continue) — under the 6 cap. Nothing else.

## 8. Reward

**Card: YES** — the concept is two fused rows of the curriculum quick-reference table ("Current through resistance makes heat" + "'Lost' energy is really energy turned to heat"), and the context pack's expected-EP2-cards list includes current→heat. Proposed copy (shared-infra owner assigns the number, builds the motif painter, updates `deckTotal`):

- **Front:** playful name **Electric Friction** · real term (mono specimen) `JOULE HEATING` · law: **"Current forced through resistance sheds energy as heat."** · kicker: **"Loss isn't gone — it's heat."** · section `transmission`, accent `#3FB9F5` · motif suggestion: a glowing catenary wire shedding rising heat strokes.
- **Back:** tie-back to the felt: **"You raised the current and the wire itself warmed — then you made the very same heat with your finger, just by rubbing."** · outward reach: **"Every toaster, kettle and room heater is a wire built to 'lose' on purpose."** · **linked card: 01 Conservation of Energy** (loss-as-heat is conservation in its recurring costume, per curriculum §8).
- Guard: must NOT restate orphaned Card 04 "The Great Escape" (conversion-chain loss; stays untouched). This card names Joule heating in a wire specifically; flag the distinction to the shared-infra owner.
- Earn: `CollectibleEarnOverlay(card: kElectricFrictionCard, eyebrow: 'NEW CARD', brag: 'You watched energy leave — and knew exactly where it went.', showMascot: false, onDone: controller.onCardCollected)`.
- **Inline fact: none** (deliberate empty slot — nothing may dilute the first loss=heat landing).

## 9. CER capture hook (proposed tiles — ids LOCKED by the EP2 evidence catalog owner from this proposal)

1. **`heat_leaves_wire`** — relevant: **true**. Label: **"Heat Leaves"**. Caption: **"Energy escaped the wire as heat before it could reach the lamp."** Fires: beat C, the exact frame meaning-line C3 appears (current ≥ 0.75 sustained, motes streaming, lamp lit at the end). Proposed cropFactor ≈ `Rect.fromLTRB(0.04, 0.16, 0.96, 0.62)` (wire span + shimmer + lamp). Motif fallback: glowing wire with rising heat strokes.
2. **`rubbed_warm`** — relevant: **false (distractor proposal — true but irrelevant)**. Label: **"Rubbing Warms"**. Caption: **"Rubbing the wire by hand made the same heat — friction."** Fires: beat B, the frame the rub gate passes (finger glow on the wire, CURRENT chip reading 0). Proposed cropFactor ≈ `Rect.fromLTRB(0.15, 0.20, 0.85, 0.60)`. Motif fallback: a small glow arc under a stroke mark on a wire.

Wiring (verbatim shipped pattern): scene wrapped in `RepaintBoundary(key: _sceneKey)`; `controller.onCapture = _onCapture` → `HapticFeedback.lightImpact()` → postFrame `captureScenePng(_sceneKey, cropFactor: evidenceByIdFor('episode2_electricity', id)?.cropFactor)` → `_board.capture(id, imageBytes: bytes)`; `EpisodeBoardStrip` pinned under the header with the EP2 question. Captures are idempotent; replays only backfill image bytes.

## 10. Build notes

- **Rendering: plain `CustomPainter` + `Ticker`** (the hand-crank template — `CrankSurface`/`StagePainter` pattern), NOT Flame: one stage, one painter, controller-owned particles. The scene is a single precision surface (wire + pulses + motes + lamp), no component tree needed. **No Forge2D** (banned; all motion controlled; cutoffs are hard gates in `tick()`).
- Controller: `HeatWireController extends ChangeNotifier` owning sim + factor geometry + phase machine + `_schedule(ms, fn)` timers; painters/widgets read getters only. Pointer routing: `Listener` on the stage forwards to `controller.onPointerDown/Move/Up(Offset local)`; the controller decides rub-band hit-testing (the slider is its own widget below the stage).
- Reuse/copy-adapt: `ParticleField` approach from `hand_crank_lamp/state/crank_particles.dart`; `lbGlow()` / `lbReveal()` entrance helpers from the retired leaky bucket's `lb_paint.dart`; `InstructionBanner` fade-out→swap→fade-in (190 ms) pattern; `EnergyFieldBackground` dark-vignette variant (local copy, per shipped convention).
- Sim: `current` eases toward slider value (τ 0.12 s); `heatInput = current² · kGain + rubInput`; `wireTemp` leaky integrator (rise τ ≈ 0.25 s, cool τ ≈ 0.9 s); displayed numbers sampled ~5×/s so they tick legibly; trend arrows (↑/↓) on both chips when changing.
- Shell: `MediaQuery(textScaler: TextScaler.noScaling)`; respect `MediaQuery.disableAnimations` (calm motes, static shimmer bands, flash→fade) — gates and the same-frame generation stop NEVER soften. Audio: **silent** (no BGM). Haptics: `selectionClick` per 0.1 slider crossing + per rub reversal; `heavyImpact` at the A3 discovery; `lightImpact` inside the capture handler.
- File surface: write ONLY inside `lib/screens/missions/current_heats_wire/`. Registry entry, EP2 evidence catalog (`evidence_models_ep2.dart`), card constants/painters, wowConcepts wiring are owned by other phases — if a shared file seems to need a change, STOP and report. Completion = `Navigator.maybePop(context)` after the card overlay. Persistence: none beyond the shared evidence/card stores.
- Verification: `fvm dart analyze lib/screens/missions/current_heats_wire` clean; also analyze each shared import. Never multi-path repo-wide analyze.

## 11. Acceptance criteria (the pedagogy as testable checks)

1. **Discoverable from interaction alone:** with all captions hidden (dev flag), dragging the slider up visibly heats the wire (glow + shimmer + HEAT number) within 1 s of crossing mid-range; rubbing the dead wire visibly warms it. No text is required to find either.
2. **Hard gate:** in the frame `current` reaches 0, pulse travel stops and mote spawn + heat input are exactly 0 (assert in `tick()`); residual glow decays only via the cooling constant (τ ≈ 0.9 s) — no UI fade curve is applied to it, and `disableAnimations` does not change this behavior.
3. **Held-constant visible:** the wire's drawn geometry is byte-identical across all beats (no morph, no thickness change); the `SAME WIRE` tag is visible whenever the slider is enabled.
4. **Exactly 2 live numbers** (CURRENT, HEAT), relative 0–100, no physical units anywhere; no ratings table; no third numeric readout (no "energy in/out" chips — the pulse taper + motes carry the budget).
5. **Friction is felt before named:** the line *"Rubbing turns motion into heat — that is friction."* can only ever appear after rubHeat ≥ 0.5 with ≥3 stroke reversals; during the rub beat the CURRENT chip reads 0 while the HEAT number rises (test both).
6. **Loss is named last:** the word "loss" appears in no line before C5; C5 and D1 name a destination ("leaves as heat"), and no line anywhere says energy is "gone", "used up", or "disappears" without naming heat as where it went.
7. **No square pre-spoil:** the slider is detentless (no 1×/2×/3× stops); no line, label, or animation names or points at how *fast* heat grows with current (reserve for 2.4). Heat physics may still be honestly ∝ I².
8. **Hero check:** at current ≥ 0.75 the wire glow is the brightest region on screen (sample luminance); the lamp's peak luminance is lower than the wire's.
9. **Captures:** `rubbed_warm` fires exactly at the rub gate; `heat_leaves_wire` exactly when C3 appears; both idempotent; both render on the `EpisodeBoardStrip` with the EP2 question pinned.
10. **Card:** the earn overlay fires once, only from the Continue tap after D1; "Add to your deck" persists the card; `Navigator.maybePop` follows `onDone`.
11. **Flow integrity:** every gate is reachable; gates only advance (high-water marks); pumping the slider mid-meaning-line never breaks the phase machine; full guided run completes in 60–150 s.
12. `fvm dart analyze lib/screens/missions/current_heats_wire` is clean; small-phone portrait (≈ 360×640 logical) shows hero, both chips, slider and text without overflow; reduced-motion run still passes checks 2, 5, 6.

## 12. Anti-patterns (THIS activity)

- **A thermometer/meter as the hero.** The glow IS the readout; the HEAT chip rides alongside, small.
- **Naming "loss" early** (in beat A or B), or naming "friction" before the rub. Name-last is the spine here.
- **Ending language:** "the energy is wasted/gone/disappears" — always destination: it *left as heat*.
- **Cartoon fire, smoke, or a red "DANGER" state.** Warm internal glow + rising shimmer only; this is physics, not peril.
- **Pre-teaching 2.4:** detents at doublings, a heat *curve* plot, or any "look how much it jumps" line.
- **Softening the stop:** pulses coasting or motes still spawning after current hits 0; conversely, snapping the *glow* to black instantly (cooling is real physics — generation stops instantly, temperature decays).
- **Making the lamp the star** or adding a town — that's 2.5's payoff; here the lamp is a small witness.
- **A third number** ("ENERGY IN 100 / OUT 62") — the Sankey-style budget is carried by the pulse taper and motes, not chips.
- **Rub gamification:** no rub score, streak, or timer; the rub exists only to make friction felt.
- Editing shared files (registry, evidence catalogs, collectible files, wowConcepts) from the build agent.

## 13. Open decisions

1. **Honest I² heat curve (recommended, decided here) vs linearized display** — keep heat ∝ current², unremarked; coordinate with the 2.4 PRD owner so 2.4's "nudge a little, heat jumps a lot" still owns the *noticing* (it does: 2.3 never invites comparison).
2. **Pulse taper in beats A/B** — recommended subtle always (honest), amplified ×1.6 with mote emphasis only in beat C; build agent may tune subtlety on device.
3. **Rub gesture thresholds** (≥3 reversals, rubHeat 0.5, stroke min-travel 0.04 W) — tune on device for ages-12-to-80 finger ergonomics.
4. **`rubbed_warm` as one of the episode's exactly-2 distractors** — CER-config owner's call across all 8 EP2 activities.
5. **Card name/number** ("Electric Friction" / `JOULE HEATING`) — shared-infra owner finalizes catalog copy, number, motif.
6. **Audio** — default silent; an optional faint warm hum scaling with wireTemp (vol ≤ 0.2) may be added if the episode adopts ambient audio uniformly.

## 14. State machine sketch

```dart
enum HeatWirePhase {
  raiseCurrent,   // A1–A2: slider live, rub off
  wireHot,        // A3–A4 meaning-lines on timers (entered via discovery gate)
  dropLow,        // A5: gate current<=0.15 && wireTemp<=0.25
  cooled,         // A6 line (2600ms) -> lock slider to 0 (300ms ease)
  rubWire,        // B1–B2: rub live, slider locked, CURRENT chip = 0
  frictionNamed,  // B3–B4 meaning-lines on timers (capture 'rubbed_warm' on entry)
  raiseAgain,     // C1: slider unlocked; gate current>=0.75 for 600ms
  lossMoment,     // C2..C5 chain on timers (capture 'heat_leaves_wire' at C3)
  synthesis,      // D1 (2600ms)
  done,           // showContinue; Continue -> card overlay -> maybePop
}
```

- **ValueNotifiers:** `phase`, `caption` (record: text + `isImperative` flag), `secondary` (String?), `sliderEnabled`, `showContinue`, `showCardEarn`, `currentDisplay` / `heatDisplay` (ints 0–100, sampled at 5 Hz), `heatTrend` / `currentTrend` (−1/0/+1).
- **Hot-path getters** (painter repaints via the controller): `current` (0–1, eased τ 0.12 s), `wireTemp` (leaky integrator: `dT = (heatInput − T/coolTau)·dt`, rise τ 0.25 s, cool τ 0.9 s, `heatInput = current²·kGain + rubInput`), `rubGlowX` / `rubGlowIntensity`, `pulsePhase`, `motes` (pooled particles; spawn rate ∝ heatInput, hard 0 when heatInput 0), `lampGlow` (∝ current, luminance-capped below wire peak), `flashIntensity` (0.7 s envelope), `reveal` values for entrance (0→0.45 s).
- **Timers:** `_schedule(ms, fn)` one-shots — 600 (first caption), 600 (sustain gates, tracked in `tick`), 1800/2600/2800/3000/3200/3400/3600 (line holds per §6), 190 (text swap, in the banner widget), 300 (slider lock ease), 700 (flash).
- **Gating conditions:** `raiseCurrent→wireHot`: `current ≥ 0.75` continuously for 600 ms (accumulator resets below). `dropLow→cooled`: `current ≤ 0.15 && wireTemp ≤ 0.25`. `rubWire→frictionNamed`: `rubHeat ≥ 0.5 && strokeReversals ≥ 3` (high-water; rubHeat accumulates ∝ pointer speed inside the wire band, band = |dy from catenary| ≤ 0.07·H; decays τ 0.9 s but the gate latches). `raiseAgain→lossMoment`: `current ≥ 0.75` for 600 ms. All other transitions timer-driven. Gates never regress.
- **Hooks:** `onDiscovery` (→ `heavyImpact`, at wireHot entry), `onCapture(String id)` (→ shell handler), `onSliderTick` (→ `selectionClick` per 0.1 crossing), `onRubStroke` (→ `selectionClick` per reversal), `onCardCollected` (→ maybePop), `reducedMotion` set from MediaQuery each build.

## 15. File plan (mirrors the hand-crank shipped structure)

```
lib/screens/missions/current_heats_wire/
├── current_heats_wire_screen.dart        — shell: noScaling MediaQuery, Ticker, header
│       (title "The Hot Wire", eyebrow EPISODE 2 · TRANSMISSION), EpisodeBoardStrip
│       (EP2 question), fixed-96 top-text banner, RepaintBoundary(stage), chip row,
│       slider, fixed-84 CTA seat, CaptureFlash + CollectibleEarnOverlay, capture wiring
├── state/heat_wire_controller.dart       — HeatWireController extends ChangeNotifier:
│       phase machine (§14), sim (current/wireTemp/rubHeat/motes), factor geometry
│       (setStageSize), pointer handlers (rub band), _schedule timers, hooks
├── state/heat_wire_particles.dart        — pooled heat motes (rise + dissolve, additive,
│       ~1.6 s life) + ambient cool motes (≤20); spawn-rate API hard-gated by controller
├── config/heat_wire_tuning.dart          — HWTune: geometry factors (pylonX .08/.92,
│       wireTopY .30, sagY .12, rubBandH .07, lampX .88), time constants, gate thresholds,
│       kGain, mote rates, all timings (ms) from §6
├── config/heat_wire_beats.dart           — HeatWirePhase enum + HWCopy: every §5 string
│       as consts with register flags (imperative vs meaning), hold durations
└── widgets/
    ├── wire_stage.dart                   — Listener + CustomPaint(StagePainter(controller),
    │       repaint: controller); forwards pointer to controller
    ├── stage_painter.dart                — pure renderer, back→front: vignette anchor →
    │       pylons + PLANT/LAMP/SAME WIRE mono tags → catenary wire (fixed geometry) →
    │       wire core glow (BlendMode.plus, #FF7A2E) → traveling pulses (#FFD27A, taper
    │       toward lamp) → heat motes → rub finger glow → lamp (small, capped) → flash ring
    ├── readout_chips.dart                — CURRENT / HEAT mono chips (IBM Plex Mono, dark
    │       glass, trend arrows), fed by currentDisplay/heatDisplay notifiers
    ├── current_slider.dart               — detentless custom slider, warm thumb glow,
    │       lock/dim state, mono CURRENT label; selectionClick per 0.1 crossing
    └── energy_field_background.dart      — local dark-vignette variant (shipped pattern)
```

No edits outside this directory. Imports from shared: `episode_board/*` (strip, capture, snapshot, evidenceByIdFor), `collectibles/collectible_earn_overlay.dart` + the card const, `careerTheme.dart`, google_fonts.

## 16. Scene sketch (portrait, top → bottom, factor-based off stage size W×H)

1. **Header** (~56 px): glass back button · title **The Hot Wire** (Bricolage 21 w800) · mono eyebrow `EPISODE 2 · TRANSMISSION`.
2. **EpisodeBoardStrip:** pinned EP2 question + up to 5 mini evidence tiles, gold `#E8C98A` border.
3. **Top-text seat** (fixed 96 px): imperatives Bricolage ~28 w800; meaning-lines PJS ~18 (long lines C4/C5 step down to ~16.5); 190 ms fade-swap; secondary line smaller beneath.
4. **Stage (Expanded, the RepaintBoundary):**
   - Pylon posts at `x = 0.08·W` and `0.92·W`, tops at `y = 0.30·H`; small plant stub behind the left post (`PLANT` tag at `0.08·W, 0.24·H`), small lamp on the right post (`LAMP` tag at `0.88·W, 0.24·H`), lamp bulb at `(0.90·W, 0.34·H)`.
   - **The wire (hero):** catenary from post-top to post-top, midspan sag to `y ≈ 0.42·H`; stroke ~`0.012·H`; internal glow layer widens with `wireTemp` (up to ~3× stroke, additive #FF7A2E→#FFD27A gradient); `SAME WIRE` mono tag at `(0.50·W, 0.50·H)`, never moves.
   - **Rub band:** invisible hit region |dy from catenary y(x)| ≤ `0.07·H` for `x ∈ [0.15, 0.85]·W`; finger glow radius ~`0.06·H` at the clamped pointer x.
   - **Pulses:** 3 packets traveling left→right along the catenary, speed ∝ current, brightness tapering toward the lamp (taper amplified in beat C); stop dead the frame current = 0.
   - **Heat shimmer:** motes spawn along the glowing span, rise from the wire (`0.42·H → 0.10·H`), drift + dissolve; emission ∝ heatInput (hard 0 at heatInput 0).
   - Radial vignette darkest behind midspan; ≤20 ambient cool motes far layer.
5. **Chip row** (~44 px): `CURRENT 62 ↑` · `HEAT 38 ↑` (mono 16–19, dark glass, centered, gap 12).
6. **Slider** (~64 px): full-width minus 2×16 padding; detentless; locked state dimmed at 0 during beat B.
7. **CTA seat** (fixed 84 px): gold gradient pill **Continue** (`#F5C451→#D9A43B`, h 52) fades in at `done`.

Small-phone note: stage min-height guarded by the fixed seats; if H is tight, shrink pylon/lamp art before the wire band (the hero and rub target never shrink below `0.07·H`).
