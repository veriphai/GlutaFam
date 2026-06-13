# PRD — What Carries It and What Stops It (Episode 3, beat 3.4)
### howwow · registry id `conductors_insulators` · dir `lib/screens/missions/conductors_insulators/` · class `ConductorsInsulatorsScreen` · evidence episode `episode3_electricity`

Binding context: `docs/electricity/context_pack.md` (the covenant), `docs/electricity/architecture_reference.md`
(APIs/patterns), curriculum beat 3.4. No mascot, no info-cards, one voice (the on-screen text). This PRD is
self-contained: every on-screen line is quoted verbatim here.

---

## 1. One-concept statement

**Conductors carry current easily; insulators block it.**
(One live circuit, one swap-in gap, seven materials. Nothing else in this activity.)

## 2. Guiding-question link + CER contribution

Episode question (pinned on the evidence board strip all activity, via shared `kEpisode3Question`):
*"The power reaches your town still at lethal transmission voltage — how does it get into your house without killing you?"*

**What this beat inherits:** from 3.2 the learner has felt that it is CURRENT through a body that harms;
from 3.3 that current flows only across a potential difference between connected points. The open dread
3.4 answers: *so what stands between that difference and your hand?* Answer: the material itself.
**What this beat pins (held constant, visibly):** the entire circuit — power cell, wires, bulb, gap
position — never changes for all seven tests. The ONLY variable is the material bridging the gap. The
unchanging loop is on screen the whole time; the contrast meaning-line names the pin out loud.

**CER contribution (proposals; final set owned by the EP3 CER PRD).** The episode claim lands "managed
danger — staged step-down + contain + escape route." Sibling beats already supply: step-down
(`staged_descent`), current-through-body (`socket_not_harmless`), the difference-drives-flow centre
(`same_level_safe`, `ground_is_zero`), and the escape route (`surge_blows_fuse`). This activity supplies the
passive **contain** clue plus one true-but-irrelevant distractor:
- `copper_in_plastic` — **RELEVANT**. The cable payoff: a conductor wrapped in an insulator is precisely
  how lethal supply is contained passively inside your walls. This is the episode claim's "contain" slot.
- `water_carries` — **DISTRACTOR** (true-but-irrelevant). "Tap water carries current" is true and feels
  safety-flavored, but it answers *which materials conduct*, not *how the supply gets into your house
  safely* — no part of the delivery chain runs through water. Exactly the EP1 `still_magnet` pattern: the
  beat's own surprise furnishes the distractor. (Both ids are unique within `episode3_electricity` —
  no collision with the sibling tiles listed above.)

## 3. The felt discovery (discovery → reaction)

**Discovery:** the learner picks a material chip and drops it into the open gap of a live circuit, then
keeps swapping materials into the same gap.
**Reaction:** the instant a metal seats, the WHOLE loop comes alive — current packets stream around the
full ring and the bulb lights (≤150 ms ramp). The instant rubber seats, nothing anywhere in the loop moves:
the bulb stays dead, the ring stays inert, a brief dull shimmer dies at the sample's edges, `CURRENT` reads 0.
Same circuit, same cell, opposite worlds — the material alone decides. The interaction IS the concept: the
only control is *which stuff bridges the gap*. The names "conductor"/"insulator" land only after all seven
materials are felt. (Correct physics is load-bearing: with an insulator seated, NO part of the loop carries
current — the felt contrast is dead-everywhere vs alive-everywhere, never "packets pile up at the sample".)

## 4. Felt vs named vs numbered

- **Felt:** the loop snapping alive vs staying dead; the bulb's instant death on eject/insulator (hard
  gate); tap water lighting the bulb visibly DIMMER than copper; the blocked shimmer dying at the sample
  edge; the two shelves the chips later sort themselves into; the cable cross-section and pylon-disc payoffs.
- **Named:** **conductors** / **insulators** — named at the naming beat, AFTER all seven are tested (short
  gap, per curriculum §3). "Current", "circuit", "voltage" are inherited names from EP2/3.2/3.3.
- **Numbered (live, relative, exactly 1 of the ≤2 allowed):** `CURRENT` mono chip — copper 100 (the silent
  reference), steel 97, tap water 28, all insulators 0, open gap 0. Counts up over ~350 ms for conductors;
  **snaps to 0 in the same frame** for insulators/eject. No second number.
- **Explicitly absent:** no answers table up front (chips are visually neutral until tested); **no ratings
  table** ever (post-test residue marks are the learner's own results, never stars/ranks); no absolute units
  (no amps); no ✓/✗ or fail-state — blocking is a result, not a mistake.
- **Depth honesty:** this is a **DEPTH-STOP** (like induction): free vs bound electrons is a real deeper
  reason, halted by choice and said so honestly. NEVER "nobody knows why". **No analogy at the floor.**

## 5. On-screen text (exact, beat by beat)

Imperatives: Bricolage Grotesque, Title Case, ≤5 words. Meaning-lines: Plus Jakarta Sans, de-personified
facts (the allowed-longer register). One imperative + at most one meaning-line visible at a time;
swaps via the shipped 190 ms fade-out → swap → fade-in.

**Intro**
- I1 (imperative): **Bridge the Gap**
- I2 (secondary imperative, only if no test within 4.5 s): **Tap a Material Below**

**Testing — result captions** (each appears 400 ms AFTER the loop has already responded; converging
repetition: the second word pair accumulates the lesson)
- Copper: **Copper Carries It**
- Steel: **Steel Carries It**
- Tap water: **Tap Water Carries It**
  - water-only meaning-line (shown under the caption, once): *Tap water carries current — that is why wet
    hands and live sockets never mix.*
- Rubber: **Rubber Blocks It**
- Plastic: **Plastic Blocks It**
- Dry wood: **Dry Wood Blocks It**
- Ceramic: **Ceramic Blocks It**
- First-contrast meaning-line (fires once, the first time the learner has witnessed BOTH behaviors,
  under whichever caption is up): *Same circuit, same power — only the bridge changed.*
- Between tests (after a caption's 2600 ms hold, if untested chips remain): **Test Every Material**

**Naming (all 7 tested; chips sort into two shelves)**
- M1: *Three materials carried the current. Four blocked it.*
- M2: *The carriers are called conductors.*  (mono shelf label fades in: `CONDUCTORS`)
- M3: *The blockers are called insulators.*  (mono shelf label fades in: `INSULATORS`)

**Payoff 1 — the cable** (auto vignette: copper rod stretches into a wire, a plastic sleeve slides over it,
cross-section reveal)
- M4: *Home wiring is a conductor inside an insulator — copper carries the current, plastic keeps it off you.*

**Payoff 2 — the pylon** (auto vignette: pylon arm, bare line hanging from a stack of ceramic discs)
- M5: *Out on the pylons, bare live lines hang from ceramic discs — the ceramic keeps the current out of the tower.*

**Depth-stop (honest, no analogy)**
- M6: *Why the difference? In a metal, the outer electrons roam free — they can carry current. In rubber or
  ceramic, every electron is locked to its atom.*
- M7: *A whole materials course sits beneath that — we stop here by choice.*

**Synthesis → card**
- M8: *Conductors carry current easily. Insulators block it.*
- Card earn overlay — eyebrow: `NEW CARD` · brag: *The difference every safe wire is built on.*
- CTA: **Continue**

No other text appears anywhere in the activity.

## 6. Beat-by-beat flow (timing + gating)

1. **Intro (0–1000 ms).** Loop + cell + dark bulb slide-scale-fade in (0→450 ms). Gap visible at the loop's
   bottom segment, terminals faintly energized (a static cool glimmer at the two gap ends — NOT traveling
   packets; an open loop carries no current). Tray of 7 neutral chips rises 600→1000 ms (horizontally
   scrollable, ≤5 in viewport). I1 at 300 ms. If no test by 4500 ms: grab-hint pulse on the tray + I2.
2. **Testing (learner-paced, reversible).** Tap a chip (`selectionClick`) → any seated sample ejects back to
   the tray — **if it was a conductor, bulb + packets + CURRENT hit 0 in the SAME frame (hard gate)** → chip
   flies to the slot (280 ms) → seats (`selectionClick`) → result in the same frame as seating:
   - **Conductor:** packets stream around the FULL loop; bulb ramps in ≤150 ms (copper/steel ≈ full
     brightness; tap water ≈ 0.45 brightness — visibly dimmer); `CURRENT` counts up to its value over 350 ms.
   - **Insulator:** loop stays fully inert; a dull cool shimmer (350 ms envelope) dies at the sample's two
     edges; `CURRENT` snaps to 0 instantly.
   - Caption swaps at +400 ms (result felt first, text names it after). Caption holds 2600 ms, then reverts
     to **Test Every Material** if chips remain.
   - **First-contrast moment:** on the first test whose result differs from the first test's result —
     `heavyImpact` + the contrast meaning-line (held 2600 ms). This is THE discovery; it works in any order.
   - **Tap water:** caption + the wet-hands meaning-line; `onCapture('water_carries')` at +500 ms
     (`lightImpact`, capture flash).
   - Tested chips gain a quiet residue mark (warm underline if it carried, cool tick if it blocked) — the
     learner's own results accumulating, deliberately NOT pre-printed.
   - Retesting any chip is allowed; results are deterministic and identical.
3. **Naming (auto; gated on all 7 tested; starts 2400 ms after the 7th result so its caption lands).** Tray
   slides away (350 ms); the 7 chips drift into two stage shelves — carriers to the warm upper row, blockers
   to the cool lower row (1100 ms, staggered). M1 at +600 ms (hold 2400 ms) → M2 + `CONDUCTORS` label + warm
   row pulse (hold 2400 ms) → M3 + `INSULATORS` label + cool row pulse (hold 2800 ms).
4. **Payoff 1 — cable (auto).** Shelves recede (scale 0.92, dim). Center vignette: copper rod stretches into
   a wire (500 ms) → plastic sleeve slides over it (700 ms) → cross-section cut reveal (400 ms). M4 on
   sleeve-seat. `onCapture('copper_in_plastic')` 500 ms after the cross-section reveal (`lightImpact`,
   flash). Hold 3400 ms after M4.
5. **Payoff 2 — pylon (auto).** Crossfade (400 ms) to pylon-arm vignette: ceramic disc stack, bare line with
   a faint live shimmer, dead grey tower steel. M5. Hold 3600 ms.
6. **Depth-stop (auto).** Vignette fades; the two shelf rows return, dim and calm. M6 (hold 3800 ms) → M7
   (hold 3000 ms). Text only — no electron graphic, no analogy.
7. **Synthesis → card (auto).** M8 (hold 1800 ms) → `showCardEarn` → card overlay (medium haptic inside the
   overlay) → "Add to your deck" → `onCardCollected` → `canFinish = true` → **Continue** appears in its
   fixed-height seat → tap → `Navigator.maybePop(context)`.

Play length: ~50 s testing + ~30 s tail ≈ 80–110 s (target 60–150 s ✓). Phases 3–7 are auto-timed and
not skippable; testing is fully reversible until the 7th result.

## 7. Hero & layout (portrait, clutter caps)

**The hero is the living loop — the bulb plus the sample gap.** When a conductor seats, the lit loop and
bulb bloom are the brightest things on screen; when an insulator seats, the hero's deadness IS the readout.
Everything else recedes: near-black field background, dark-glass chips, mono `CURRENT` chip on dark glass,
chrome at glass-fill alphas.

Top to bottom: header (back, title `CONDUCTORS & INSULATORS` eyebrow style) → `EpisodeBoardStrip` (EP3
question, gold accent) → top-text block (fixed height, imperative + meaning-line) → stage (the loop, ~55%
of the body) → material tray (fixed height ~96) → fixed-height CTA seat (84).

**Clutter caps (stated):** 1 hero (the loop) · interactive elements ≤6 at any moment (≤5 chips in the tray
viewport — 7 total, scrollable — plus the Continue CTA when present; the slot itself is not tappable;
swapping happens via chips) · live numbers ≤2 (exactly 1: `CURRENT`) · one imperative + one meaning-line of
text. No other element passes the clutter test; nothing else is drawn.

## 8. Reward

**Card: YES** — "Carries current vs blocks it → conductors / insulators" is a row in the curriculum
quick-reference table (a depth-stop row), and the covenant's expected-card list includes the EP3
conductors/insulators depth-stop card. Constant referenced as `kConductorsInsulatorsCard` (created by
shared infra; number/deckTotal owned there). Section `homeSafety`, accent `#3FD99B`.

- **Front** — playful name: **The Free and the Locked** · real term (mono specimen label):
  `CONDUCTORS & INSULATORS` · one-line law: *Conductors carry current easily; insulators block it.* ·
  kicker: *Every safe cable is both at once.*
- **Back** — tie-back to what was felt: *You bridged one live circuit with seven materials: copper, steel
  and tap water lit the bulb; rubber, plastic, wood and ceramic left the loop dead.* · outward reach:
  *In a metal the outer electrons roam free; in an insulator they are locked to their atoms — that one
  difference decides every cable, every switch, and the ceramic discs on every pylon.*
- **Linked card (proposed):** the resistance card (beat 2.2) — an insulator is the wire's opposition taken
  to its extreme. Shared infra confirms the link and numbering.
- **Inline fact:** none by default (deliberate empty slot). Candidate flagged in §13.

## 9. CER capture hook

`RepaintBoundary(key: _sceneKey)` wraps background + stage. `controller.onCapture = _onCapture` →
`captureScenePng(_sceneKey, cropFactor: evidenceByIdFor(kEpisode3Id, id)?.cropFactor)` →
`_board.capture(id, imageBytes: bytes)`; `EpisodeBoardStrip` pinned under the header.

| id | label (≤3 words) | caption (one line) | relevant? | fires exactly when |
|---|---|---|---|---|
| `copper_in_plastic` | Conductor In Insulator | Copper carries the current; the plastic sleeve keeps it off you. | **RELEVANT** (the episode claim's "contain" slot) | Payoff 1, 500 ms after the cable cross-section reveal |
| `water_carries` | Water Carries It | Tap water conducts — dimmer than copper, but live. | **DISTRACTOR** (true; doesn't answer how supply reaches you safely) | Testing, 500 ms after tap water's bulb response lands |

Proposed cropFactors (normalized LTRB of the stage scene): `copper_in_plastic` ≈ (0.18, 0.30, 0.82, 0.72)
around the cable vignette; `water_carries` ≈ (0.22, 0.06, 0.86, 0.66) catching bulb + seated water sample.
Final tile definitions live in the shared `kEpisode3Evidence` catalog — call these ids exactly, define nothing locally.

## 10. Build notes

- **Plain CustomPainter + Ticker** (hand-crank pattern), NOT Flame: one precision circuit widget with
  controlled phase choreography — a full Flame scene is overkill. **No Forge2D** (nothing emergent here;
  the insulator/eject cutoff is a hard gate in `tick()`, never decay).
- Reuse `paintBulb()` from `lib/screens/missions/hand_crank_lamp/widgets/bulb.dart` (precedented reuse).
- Copy-adapt `energy_field_background.dart` (static dark vignette variant) into this activity's widgets.
- Chips are Flutter widgets (drawn material swatches — no PNG assets); the fly-to-slot animation is
  controller-owned geometry (chip origin → slot anchor, 280 ms easeOutCubic).
- Haptics: `selectionClick` chip tap + seat · `heavyImpact` first-contrast discovery · `lightImpact` both
  captures · medium impact lives inside the card overlay.
- Audio: silent (no BGM, no manifest). Persistence: none beyond the shared evidence/card stores.
- Reduced motion (`MediaQuery.disableAnimations`): packets become a static warm glow along a live loop;
  chip fly-in becomes a fade; shelf sort becomes a crossfade; capture flash simplifies — **the instant
  cutoff and instant-0 CURRENT snap are never softened**.
- `MediaQuery(...textScaler: TextScaler.noScaling)` wraps the screen. Verification:
  `fvm dart analyze lib/screens/missions/conductors_insulators` clean.

## 11. Acceptance criteria (pedagogy as testable checks)

1. **Discoverable from interaction alone:** with all text hidden, tapping chips and watching the loop
   respond still teaches carry-vs-block (the gap terminals invite; the loop's alive/dead contrast is the lesson).
2. **No answers up front:** before testing, all 7 chips are visually neutral — no color coding, ordering, or
   grouping that hints at conductivity; residue marks appear only AFTER the learner's own test.
3. **Hard gates:** seating an insulator, or ejecting a seated conductor, drives bulb bloom + packets +
   `CURRENT` to 0 within one frame (≤17 ms) — no fade tail, including under reduced motion.
4. **Correct open/blocked physics:** with the gap open or an insulator seated, NO traveling packets appear
   anywhere in the loop (no packets piling at the sample); the blocked cue is a dying ≤350 ms edge shimmer.
5. **Felt before named:** each result caption appears ≥400 ms after the visual result; "conductors"/
   "insulators" are not uttered (in any text) until all 7 materials are tested.
6. **Held-constant is visible:** cell, wires, bulb, and gap position are pixel-identical across all 7 tests;
   the contrast meaning-line *"Same circuit, same power — only the bridge changed."* fires exactly once, at
   the first witnessed behavior-flip, in any test order.
7. **Water reads as a weaker conductor:** tap water lights the bulb at visibly lower brightness (~0.45) with
   `CURRENT 28` vs copper's 100; it still counts as a carrier in the naming sort.
8. **Numbers:** exactly one live number (`CURRENT`), relative (copper = 100), mono chip; no units, no second
   number, **no ratings table**, no ✓/✗, no score, no fail-state.
9. **Depth-stop honesty:** M6/M7 state free vs locked electrons and "we stop here by choice"; the strings
   "nobody knows", "no one knows" appear nowhere; no analogy accompanies the depth-stop (text-only beat).
10. **Naming gate:** the naming phase cannot begin until all 7 results have been witnessed; retests don't
    double-count; the 7th result's caption gets its full 2400 ms before the sort begins.
11. **Captures:** `water_carries` fires once at its testing moment; `copper_in_plastic` fires once at the
    cross-section reveal; both flash via the shared capture flow; ids match the EP3 catalog exactly.
12. **Hero rule:** the lit loop/bulb is measurably the brightest element when a conductor is seated; chips,
    chrome, and the CURRENT chip all sit at glass alphas; payoff vignettes are secondary in scale.
13. **Card:** `kConductorsInsulatorsCard` fires once after M8 (1800 ms hold), via `CollectibleEarnOverlay`
    with `showMascot: false`; Continue appears only after `onCardCollected`; tap → `Navigator.maybePop`.
14. **Flow length:** a straight-through run lands in 60–150 s; testing is learner-paced and reversible.

## 12. Anti-patterns (this activity)

- A pre-labeled materials table, color-coded chips, or any up-front answer key — the learner tests first.
- A premium fade on the insulator/eject cutoff — the loop's death is the pedagogy; it snaps.
- Packets crawling up to and queuing at an insulator (false physics — the whole loop is dead).
- A buzzer, red X, or "wrong" treatment on insulators — blocking is half the lesson, not a mistake.
- Pre-spoiling water: no lightning tint on its chip, no caption before the bulb has already responded dim.
- Turning residue marks into a ratings grid (stars/rankings) — they stay quiet binary residue.
- The depth-stop drifting into "nobody knows why", or an electrons-as-traffic analogy at the floor.
- Naming conductors/insulators in any earlier caption ("Copper Conducts It" is banned; "Carries" until named).
- Making the payoffs interactive or adding a second number (e.g. a resistance meter) — both fail the clutter test.
- Explaining inside an imperative ("Bridge the Gap to See What Conducts" is two registers jammed together).

## 13. Open decisions

1. **Tap water's relative current (28) and brightness (0.45)** — tune on device so it reads "weaker but
   genuinely live"; physics-stylized (real tap water wouldn't light an incandescent bulb in this loop),
   accepted to serve the curriculum's "water carries" point. Flag, don't silently change.
2. **"Metal" from the beat note realized as steel** (copper is already the named metal) — confirm label.
3. **Optional inline fact** (currently an empty slot): tap-reveal on the water chip after its test —
   *"It's the dissolved minerals in tap water that carry the current — pure water barely conducts."*
   Misconception-killer from the blueprint; include only if it survives the clutter test on small phones.
4. **Card link target** (resistance card, 2.2) — shared infra confirms link + numbering + deckTotal.
5. **Distractor survival:** whether `water_carries` is one of the EP3 CER's exactly-2 distractors is the
   EP3 CER PRD's call; if dropped, water still captures nothing else (no replacement tile from this beat).
6. **Chip input:** default tap-to-place (fly animation); upgrade to drag-to-slot only if it stays smooth on
   low-end devices.

## 14. State machine sketch

```dart
enum CIPhase { intro, testing, naming, payoffCable, payoffPylon, depthStop, synthesis, done }
enum CIMaterial { copper, steel, tapWater, rubber, plastic, dryWood, ceramic }
```
`CIController extends ChangeNotifier` —
- **ValueNotifiers:** `phase`, `caption` (enum CICaption; carries register flag imperative/meaning),
  `secondaryCaption`, `activeSample: ValueNotifier<CIMaterial?>`, `currentReading: ValueNotifier<int>`,
  `showCardEarn`, `canFinish`.
- **Hot-path getters (repaint listenable):** `loopAlive`, `bulbBrightness` (0/0.45/1.0 target, ≤150 ms
  ripple up, hard 0 down), `pulsePhase`, `blockedShimmer` (0→1→0 over 350 ms), `chipFlight` (origin, t),
  `shelfMorph` (0..1), `cableReveal`, `pylonReveal`, `depthDim`, `flashIntensity`, `testedResults:
  Map<CIMaterial, bool>`.
- **Timers:** `_schedule(ms, fn)` one-shots — caption holds (2400/2600/2800), naming chain (600 → 2400 →
  2400 → 2800), cable (500+700+400, capture +500, hold 3400), pylon (400, hold 3600), depth (3800, 3000),
  synthesis (1800). Ticker drives `tick(dt)` at 60 fps from the screen shell.
- **Gating conditions:** `testing → naming` iff `testedResults.length == 7` (+2400 ms grace);
  `firstContrastFired` latch (set when a result differs from the first result → `onDiscovery` →
  `heavyImpact` + contrast line); insulator-seat / eject ⇒ `bulbBrightness = 0; currentReading.value = 0;`
  in the same `tick` (no interpolation); capture latches (`waterCaptured`, `cableCaptured`) so `onCapture`
  fires once each; `synthesis → showCardEarn` after M8 hold; `onCardCollected ⇒ canFinish = true`.
- **Hooks:** `onCapture(String id)`, `onDiscovery()`, `onChipTap()`, `reducedMotion` set from MediaQuery
  each build.

## 15. File plan

```
lib/screens/missions/conductors_insulators/
├── conductors_insulators_screen.dart   — shell: noScaling MediaQuery, Ticker, header, EpisodeBoardStrip,
│                                          top-text (fixed h), RepaintBoundary stage, tray, CTA seat,
│                                          capture wiring, CollectibleEarnOverlay, maybePop
├── state/ci_controller.dart            — ChangeNotifier per §14: phase machine, geometry, tick, hard gates
├── config/ci_config.dart               — CITune: all geometry factors, timing ms, current values,
│                                          brightness map, palette accents
├── config/ci_materials.dart            — CIMaterial enum + MaterialDef(label, carries, relCurrent,
│                                          brightness, swatch colors, resultCaption)
├── config/ci_captions.dart             — CICaption enum + verbatim copy (§5), register flags
└── widgets/
    ├── ci_stage.dart                   — CustomPaint(painter: CIStagePainter(controller), repaint: controller)
    ├── ci_stage_painter.dart           — pure renderer: vignette glow, loop, cell, gap terminals, sample,
    │                                      packets (BlendMode.plus), bulb via paintBulb, blocked shimmer,
    │                                      shelves + mono labels, cable/pylon vignettes, capture-flash hint
    ├── material_tray.dart              — horizontal scrollable chip row (≤5 visible), neutral → residue
    │                                      states, grab-hint pulse, fly-out handoff to controller
    └── energy_field_background.dart    — static dark vignette variant (copy-adapted)
```
No edits to any shared file (registry, evidence catalogs, cards, wowConcepts) — report needs, don't touch.

## 16. Scene sketch (portrait, factor-based on stage size S = w × h)

Top to bottom of the screen: header → board strip → top-text (fixed h ≈ 96) → **stage** → tray (h ≈ 96)
→ CTA seat (h = 84). Within the stage:

- `CURRENT` mono chip: anchored (0.78w, 0.07h), dark glass, right-aligned.
- **The loop:** rounded-rect ring, corners r ≈ 0.06w, spanning (0.18w, 0.16h)–(0.82w, 0.62h). Stroke ≈
  0.012w; alive state adds an additive inner glow + 10–14 traveling packets.
- **Bulb:** seated on the top segment at (0.50w, 0.16h), radius ≈ 0.085w (`paintBulb`); its bloom is the
  vignette's brightest point when lit.
- **Power cell:** on the left segment at (0.18w, 0.40h), small dimensional block ≈ 0.10w × 0.07h with a
  constant faint hum-glow (the visible held-constant source).
- **Gap + slot:** bottom segment centered (0.50w, 0.62h), gap width 0.16w; two terminal nubs with a static
  cool glimmer; the seated sample fills the gap as a rounded swatch ≈ 0.14w × 0.05h.
- **Naming shelves:** carriers row at y ≈ 0.30h, blockers row at y ≈ 0.50h, chips ≈ 0.105w wide, centered
  groups; mono labels 0.02h above each row.
- **Payoff vignettes:** centered (0.50w, 0.42h) within ≈ 0.64w × 0.34h — cable cross-section (copper core
  ≈ 0.04w radius inside plastic ring ≈ 0.085w); pylon arm enters from the right, 3-disc ceramic stack
  hanging a bare line, tower steel kept cold grey.
- **Tray (Flutter, below stage):** chips ≈ 64–72 px square, 12 px gaps, horizontal scroll, ≤5 in viewport.

Ambient motes ≤ 20; vignette darkest behind the bulb; warm energy `#FFD27A` for packets/bloom; section
accent `#3FD99B` reserved for chrome accents (shelf labels, residue ticks).
