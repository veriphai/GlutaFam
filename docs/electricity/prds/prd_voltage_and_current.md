# PRD — Voltage and Current Are Two Different Things
### howwow · Episode 2 "The Long Way Home" · beat 2.1 · registry id `voltage_and_current` · `VoltageAndCurrentScreen` · evidence episode `episode2_electricity`

Working title: **The Push and the Flow.** Complies with `docs/electricity/context_pack.md` (the covenant), `docs/electricity/architecture_reference.md`, and curriculum §1–§9 + §13. No mascot, no Voltix, no info-cards; one voice = the on-screen text in two registers (imperatives + meaning-lines).

---

## 1. One-concept statement
**Voltage and current are distinct — one drives, one flows.** (Voltage is the push you set; current is how much flow results, through a wire that never changes.)

## 2. Guiding-question link + CER contribution
- Episode question (pinned on the board strip all activity): **"The plant is far away — how do we send power across that distance without losing it all on the way?"**
- This beat opens the locked chain 2.1 → 2.5. **Inherits:** the learner has *felt* pushing energy in (Prologue crank) and where the push originates (EP1 induction). **Pins:** THE WIRE — held visibly constant via a pinned chip, so 2.5's flip of the pinned quantity (wire-fixed → power-fixed) reads as a new case, not a contradiction.
- **CER contribution: distractor evidence.** Both proposed tiles are TRUE but answer *what voltage and current are*, not *how distance loss is beaten* (mirror of EP1's `still_magnet`/`turbine_spin` distractors). The EP2 CER owner selects exactly 2 distractors episode-wide; `voltage_drives_current` is the recommended keeper from this beat. No relevant-evidence tile is produced here.

## 3. The felt discovery (discovery → reaction)
- **Discovery 1 (the relationship):** the learner drags one vertical pressure column upward → *reaction:* warm motes start streaming around the complete circuit loop, faster and brighter the higher the column; the lamp blooms; two numbers rise together at different scales.
- **Discovery 2 (the cutoff — the heavyImpact moment):** the learner slams the column to zero → *reaction:* the current, the motes, and the lamp die **in the same frame**. Push gone = flow gone. Nothing coasts.
- **Discovery 3 (the asymmetry, felt not told):** only the voltage column is grabbable. Touching the wire, the lamp, or the CURRENT readout does nothing. The current is never yours to set — it *answers*. The interaction is the concept: you operate the push; the flow is the response.

## 4. Felt vs named vs numbered
- **Felt:** mote stream speed/brightness in the wire (the current made visible); lamp bloom; the instant double-death at zero; the one-handle asymmetry; the pin chip that never changes.
- **Named:** *voltage* and *current* appear as readout labels from entry (gauge labels — objects on sight); their **meaning** (push / flow) lands as meaning-lines only after the cutoff is felt. **"Resistance" is never said** — the wire's fixedness is shown (chip "SAME WIRE"); the term lands in 2.2 after geometry is felt.
- **Numbered (live, relative, ≤2):** `VOLTAGE 0–100` and `CURRENT 0–40` (fixed wire ratio 0.4 — deliberately different scales so the two quantities never display the same number and can never read as one quantity with two names). Mono chips, dark glass. **No ratings table. No number for any qualitative judgment. No resistance number** — the pin is a label, not a value.

## 5. On-screen text — EXACT, beat by beat
Imperatives = Bricolage Grotesque large; meaning-lines = Plus Jakarta Sans (short ones Title Case, the long ones sentence case at the smaller size). Swap = 190 ms fade-out → swap → fade-in.

| # | Register | Line (verbatim) | Trigger |
|---|---|---|---|
| T1 | imperative | `Raise the Voltage` | entry, after entrance reveals |
| T2 | imperative | `Higher — Watch the Current` | first frame V ≥ 25 |
| T3 | imperative | `Now Drop It to Zero` | V ≥ 80 sustained 700 ms |
| T4 | meaning | `No Voltage, No Current` | the cutoff instant (V ≤ 2 after maxV ≥ 80) |
| T5 | meaning | `Voltage Is the Push. Current Is the Flow.` | 2400 ms after T4 |
| T6 | meaning (long) | `Like water in a pipe — pressure is the push, flow is how much water actually moves.` | 3000 ms after T5 |
| T7 | imperative | `Raise It Again` | 3800 ms after T6 |
| T8 | meaning (long) | `More voltage, more current — while the wire stays the same.` | pin-gate satisfied (V ≥ 70) |
| T9 | meaning | `Voltage Drives. Current Flows.` | 3200 ms after T8 (synthesis) |

Rules check: every imperative ≤5 words; T4 names the consequence with both nouns (the "No Wind, No Power" pattern); no rhyme; no narration-to-a-child; the analogy (T6) is the load-bearing water-in-pipes one and goes no further (never "the water travels to your house"). Card brag (earn overlay one-liner): `The Push and the Flow — two quantities, two jobs.` Eyebrow: `NEW CARD`. No other text exists in the activity.

## 6. Beat-by-beat flow (timing + gating)
1. **Intro (0–900 ms):** entrance reveals (loop slides/fades in 0→450 ms, source column 150→600 ms, chip pins on at 600 ms with a small settle, lamp dark). Slider is live immediately — a learner who grabs early skips nothing. T1 at 900 ms.
2. **Explore up (learner-paced):** drag column up. Same-frame: `current = 0.4 × voltage`; motes stream ∝ current; lamp brightness ripple-smoothed (tau 0.11 s) toward current; both numbers tick. First frame V ≥ 25 → T2 + `selectionClick`. Haptic `selectionClick` at every 10-unit detent crossing of the column.
3. **Drop prompt:** V ≥ 80 sustained 700 ms → T3. (If the learner has already slammed to zero after touching ≥80, skip straight to step 4 — discovery is never blocked by an unread prompt.)
4. **THE CUTOFF (hard gate):** first frame V ≤ 2 with `maxVoltageEver ≥ 80` → current, mote speed, mote alpha, lamp bloom all forced to 0 **in that same frame** (no decay, no fade tail, reduced-motion changes nothing here); discovery flash ~700 ms envelope; `heavyImpact`; **capture `no_voltage_no_current`** (lightImpact via capture path); T4. Hold 2400 ms.
5. **Naming (auto, slider stays live):** T5 (2400 ms after T4) → T6 (3000 ms later). Raising the slider during this is allowed and harmless — every line stays true.
6. **Pin beat:** T7 (3800 ms after T6). Gate: any frame with V ≥ 70 (if already ≥ 70 at beat entry, a 600 ms dwell satisfies it). On satisfied: the SAME WIRE chip pulses once (scale 1→1.15→1 + glow, 900 ms), T8, **capture `voltage_drives_current`**.
7. **Synthesis → card:** 3200 ms after T8 → T9. 2600 ms later → `showCardEarn = true` → `CollectibleEarnOverlay` (proposed card §8). `onDone → onCardCollected` → `canFinish = true`, Continue CTA appears in its fixed seat. Slider remains live for free play.
8. **Finish:** Continue → `Navigator.maybePop(context)` (any pop = completion; no payload).

Reversibility: the slider is always reversible; phases never regress; captures and the card fire once (idempotent). Straight-through play length ≈ 60–110 s.

## 7. Hero & layout (with clutter caps)
- **The hero:** the living circuit loop — the warm mote stream (`#FFD27A`) and the lamp it lights (`#FFE9B8` bloom, `BlendMode.plus`). Brightest things on screen, center stage.
- **What recedes:** near-black `#070A1C` base + radial vignette darkest behind the lamp; faint circuit texture ~5% alpha; the source station and voltage column in cool transmission blue `#3FB9F5` (clearly the control, never outglowing the lamp); chrome on glass fills `0x14FFFFFF`/borders `0x26FFFFFF`; 16–20 ambient motes max.
- **Portrait layout (top→bottom):** header → board strip → instruction banner (fixed h 96) → stage (loop: lamp top-center, wires down both sides, source station bottom-center, CURRENT chip under the lamp, SAME WIRE pin chip on the left wire, VOLTAGE chip above the source) → fixed-height CTA seat (84).
- **Clutter caps (hard):** 1 hero, **3 interactive elements** (voltage column, back button, Continue) — ≤6 ✓; **exactly 2 live numbers**; 1 pinned label chip; the current text line. Nothing else. Board strip is read-only. The wire shows **no heat, ever** (that is 2.3's whole job).

## 8. Reward
**Card: YES** — quick-reference row "Pressure driving flow / amount flowing → voltage / current (Ep 2, fully explained)". Proposed copy for the shared-infra catalog (number/deckTotal assigned centrally; build agent only references the future `kPushFlowCard`):
- `id: 'voltage_and_current'` · `cardName: 'The Push and the Flow'` · `realName: 'VOLTAGE & CURRENT'`
- `law: 'Voltage is the push that drives charge; current is how much actually flows.'`
- `kicker: 'They can rise together — they are never the same thing.'`
- `section: CardSection.transmission` (accent `#3FB9F5`) · `rarity: core` · proposed `motif: pushFlow` (a pressure column driving a mote stream around a loop to a lit lamp)
- `tieBack: 'One slider set the push; the current answered on its own. And the instant the voltage hit zero, the flow and the lamp died with it — same frame, nothing stored.'`
- `reach: 'A doorknob spark is tens of thousands of volts — enormous push, almost no flow. That is why it stings instead of kills.'`
- `linkedCardName: null` (flag for shared infra: EP3's potential-difference card may link back to this one).
**Inline fact: none** — deliberate empty slot; anything here would either restate the lesson or pre-spoil 2.2/2.5.

## 9. CER capture hook (proposed tiles — ids locked by the EP2 evidence catalog at shared-infra time)
1. `voltage_drives_current` · label `Voltage Drives Current` · caption `Raising the voltage raised the current — through the same fixed wire.` · **distractor** (true; answers what the quantities are, not how loss over distance is beaten) · fires at T8 (pin-chip pulse, V ≥ 70, lamp bright — the scene at its most legible). Suggested cropFactor ≈ `Rect.fromLTRB(0.08, 0.04, 0.92, 0.92)` (full loop + both readouts).
2. `no_voltage_no_current` · label `Both Hit Zero` · caption `Voltage dropped to zero and the current died the same instant.` · **distractor** · fires at the cutoff frame (dark lamp + discovery flash). Suggested cropFactor ≈ `Rect.fromLTRB(0.15, 0.02, 0.85, 0.55)` (dead lamp + zeroed CURRENT chip).
Wiring: scene wrapped in `RepaintBoundary(key: _sceneKey)` (background + stage only — banner/CTA excluded); `controller.onCapture = _onCapture` → `captureScenePng(_sceneKey, cropFactor: evidenceByIdFor(kEpisode2Id, id)?.cropFactor)` → `_board.capture(id, imageBytes: bytes)`; `EpisodeBoardStrip` pinned under the header with the EP2 question.

## 10. Build notes
- **Rendering: plain `CustomPainter` + Ticker** (the hand_crank_lamp pattern). One loop, one deterministic mote stream, one lamp, three chips — a single-precision scene; Flame would be overhead. **No Forge2D** (motion is controlled; the cutoff is a hard gate in `tick`, never decay).
- Controller-owns-geometry: `VCController extends ChangeNotifier`; `setStageSize(size)` once per paint; all anchors = factor × stage size (`VCTune`).
- Mote stream: N≈14 phase offsets advancing along the loop path at speed ∝ current; mote alpha ∝ current → at current 0 they stop AND vanish the same frame. Direction: one-way clockwise, unlabeled (no charge/DC claims; AC is 2.7's job).
- Reuse `paintBulb` via import from `lib/screens/missions/hand_crank_lamp/widgets/bulb.dart` (read-only import — same bulb the learner has lit twice; continuity is free pedagogy).
- Readout chips + SAME WIRE chip painted inside the painter (TextPainter, IBM Plex Mono) so captures include them and anchors stay factor-based. Pin glyph drawn (a small angled pin + dot), not an emoji.
- Numbers: `displayVoltage = round(v×100)`, `displayCurrent = round(v×40)`; integer rounding, updated every frame (slider-driven, so legible).
- Haptics: `selectionClick` per 10-unit slider detent + on T2; `heavyImpact` at the cutoff discovery; `lightImpact` on each capture; medium is inside the card overlay.
- Audio: **silent** (matches most shipped electricity activities). Open decision §13 for an optional hum.
- `MediaQuery(...textScaler: TextScaler.noScaling)` wrapper; `reducedMotion` from `MediaQuery.disableAnimations` → calm ambient motes, fade-style reveals, **but the zero-cutoff stays instant**.
- File-surface rule: write only inside `lib/screens/missions/voltage_and_current/`. Registry entry, EP2 evidence catalog, and the card constant are owned by other phases — if `kEpisode2Evidence` / `kPushFlowCard` don't exist yet, code against the names and report in the final message; do not edit shared files.
- Verify: `fvm dart analyze lib/screens/missions/voltage_and_current` clean.

## 11. Acceptance criteria (pedagogy as testable checks)
1. **Discoverable from interaction alone:** with all top-text suppressed (debug flag), a fresh user dragging the column up/down can read the concept: column up → motes + lamp + CURRENT rise; column to zero → all dead instantly.
2. **Hard cutoff:** from the frame V ≤ 2, current, mote alpha, and lamp bloom are ≤2% within 50 ms — no fade tail; identical under reduced motion.
3. **Held-constant visible:** the SAME WIRE pin chip is visible 100% of the activity (never occluded by banner, flash, or CTA), is a label not a number, and the word "resistance" appears nowhere.
4. **Exactly 2 live numbers**, relative scales; at no slider position do VOLTAGE and CURRENT display the same value (ratio 0.4 guarantees it for v > 0); no third number exists.
5. **Asymmetry enforced:** pointer events on the wire, lamp, or CURRENT chip change nothing; only the voltage column responds to drag.
6. **Consequence lives in the scene:** mote speed/brightness and lamp bloom respond in the same frame as the slider; the numbers ride alongside and never replace the felt response (lamp + motes visibly brighter than any chip).
7. **Gating:** T3 only after V ≥ 80 sustained 700 ms; the cutoff discovery fires on the first V ≤ 2 after maxVoltageEver ≥ 80 even if T3 never displayed; the pin beat satisfies only at V ≥ 70 (600 ms dwell rule if pre-satisfied); T9 → card only after T8.
8. **Text exactness:** all nine lines verbatim from §5; imperatives ≤5 words; T4 names both nouns; the water analogy appears once, at T6, and is never extended to energy-travels-to-your-house.
9. **No heat anywhere:** the wire never warms, glows red, or sheds heat particles at any current (reserved for 2.3). No rectangle visual (2.5), no waveform (2.7).
10. **Captures:** exactly two, ids exact, at the §9 moments, idempotent; board strip shows the EP2 question throughout.
11. **Completion contract:** card overlay → Continue → `Navigator.maybePop`; `const VoltageAndCurrentScreen()` constructible with no arguments.
12. ≤3 interactive elements; analyzer clean on the activity dir; straight-through run 60–110 s on device.

## 12. Anti-patterns (this activity)
- **Wire warming with current** — pre-spoils 2.3 and smuggles "loss" into a beat that isn't about loss.
- **V and I ever showing the same number** — reads as one quantity with two names, the exact misconception this beat exists to kill.
- **A second slider or draggable current** — current must be an answer, never a handle.
- **A premium fade on the zero-cutoff** — the instant double-death IS discovery 2.
- **Naming "resistance"** — the chip says SAME WIRE; the term is 2.2's, after geometry is felt.
- **Pre-spoiling the 2.5 flip** — no "remember this for later", no fixed-power talk, no rectangle.
- **Meter-first staging** — chips brighter/larger than the lamp + flow; the scene is the readout, numbers ride along.
- **Stretching the water analogy** — pipes explain push vs flow only; never "the electricity/water travels from the plant to your lamp".
- **A floating wire segment** — the loop must be complete (source → wire → lamp → return), or "current through what?" becomes a lie 3.3 has to unwind.

## 13. Open decisions
1. Current scale ratio (0.4 proposed) — tune so the two numbers feel proportional yet unmistakably distinct on device.
2. VOLTAGE chip placement: separate chip above the source (specced) vs merged into the column as its fill-level label.
3. Optional silent→soft electrical hum with pitch ∝ current (vol ≤ 0.2) — propose shipping silent; flag for polish.
4. Final cropFactors for both tiles — EP2 evidence-catalog owner.
5. Whether EP3's potential-difference card links back to `The Push and the Flow` — shared-infra catalog decision.

---

## 14. State machine sketch
```dart
enum VCPhase { intro, exploreUp, dropPrompt, cutoff, naming, pinBeat, synthesis, done }
```
- **ValueNotifiers:** `caption: ValueNotifier<VCCaption>` (text + meaning/long flags), `phase: ValueNotifier<VCPhase>`, `showCardEarn: ValueNotifier<bool>`, `canFinish: ValueNotifier<bool>`.
- **Hot-path getters (notifyListeners via Ticker):** `voltage` (0–1, slider-set), `current` (= voltage × kCurrentRatio, hard-gated to 0 when voltage ≤ 0.02), `lampBrightness` (ripple tau 0.11 s toward current; forced 0 same frame current hits 0), `motePhase`, `moteAlpha`, `flashIntensity` (0.7 s envelope), `chipPulse` (0.9 s), reveals (`loopReveal`, `sourceReveal`, `chipReveal`), `displayVoltage`, `displayCurrent`, `maxVoltageEver`.
- **Input:** `onDragStart/Update/End(Offset local)` → vertical delta mapped over 0.30h drag range → `voltage` clamp(0,1); detent haptic each 0.1 crossing. Pointer hit-test limited to the source-station rect (±0.06w/h slop).
- **Timers (`_schedule(ms, fn)`, all cancelable):** intro→T1 900; T4 hold 2400 → T5; T5 3000 → T6; T6 3800 → T7; T8 3200 → T9; T9 2600 → card. Sustain checks (`V≥80 for 700`, dwell 600) accumulated in `tick(dt)`.
- **Gates:** `dropPrompt` ⇐ V ≥ 0.80 sustained 0.7 s · `cutoff` ⇐ V ≤ 0.02 && maxVoltageEver ≥ 0.80 (phase ∈ {exploreUp, dropPrompt}) · `pinBeat satisfied` ⇐ V ≥ 0.70 (dwell 0.6 s if already true at entry) · `done` ⇐ card collected. Phases never regress; captures/card fire once.
- **Hooks:** `onDiscovery` (heavyImpact at cutoff), `onCapture(String id)`, `onDetent` (selectionClick), `onCardCollected` (→ canFinish), `reducedMotion` set from MediaQuery each build.

## 15. File plan — `lib/screens/missions/voltage_and_current/`
```
voltage_and_current_screen.dart   — shell: noScaling MediaQuery, Ticker, header (back on glass;
                                    title 'The Push and the Flow' + mono eyebrow 'EPISODE 2 · TRANSMISSION'),
                                    EpisodeBoardStrip (EP2 question), instruction banner (h 96,
                                    190 ms fade-swap), RepaintBoundary[background + stage],
                                    fixed CTA seat (h 84), CollectibleEarnOverlay, capture wiring
state/vc_controller.dart          — VCController extends ChangeNotifier (§14: sim, geometry,
                                    phase machine, timers, gates, hooks)
config/vc_config.dart             — VCTune: geometry factors (§16), kCurrentRatio = 0.4,
                                    thresholds (.80/.02/.70), sustain/dwell ms, mote count,
                                    ripple tau, palette tokens
config/vc_copy.dart               — VCCaption (text/meaning/long) + VCCopy: T1–T9 verbatim,
                                    chip label 'SAME WIRE', readout labels, brag/eyebrow,
                                    all timing constants (ms)
widgets/vc_stage.dart             — Listener + CustomPaint(painter: VCStagePainter(controller),
                                    repaint: controller); forwards pointer to controller
widgets/vc_stage_painter.dart     — pure renderer, back→front: vignette pool → loop wire →
                                    mote stream (additive) → source station + voltage column →
                                    lamp (imported paintBulb) + bloom → SAME WIRE chip →
                                    readout chips → discovery flash ring
widgets/energy_field_background.dart — copied static dark vignette variant (per shipped pattern)
```

## 16. Scene sketch — portrait, factor-based (stage = w × h of the Expanded area)
```
y≈0.16h   LAMP  — center (0.50w, 0.16h), bulb radius 0.085w (paintBulb), warm bloom
                  radius up to 0.30w × brightness, additive; vignette darkest here
y≈0.285h  CURRENT chip — centered (0.50w), mono 'CURRENT 32', dark glass, under the lamp
y≈0.16h–0.74h  LOOP — rounded-rect wire: left run x=0.22w, right run x=0.78w, corner
                  radius 0.06w; stroke 0.012w cool steel; motes ride the path clockwise
y≈0.45h   SAME WIRE chip — pinned ON the left run (0.22w, 0.45h): drawn pin glyph + mono
                  'SAME WIRE'; always visible; pulses once at T8
y≈0.635h  VOLTAGE chip — centered (0.50w), mono 'VOLTAGE 80', sits just above the station
y≈0.74h–0.86h  SOURCE STATION — centered (0.50w, 0.78h), 0.34w × 0.16h glass housing;
                  inside: the vertical VOLTAGE COLUMN (fill level = voltage, #3FB9F5 fill,
                  subtle up-arrow grab affordance at the fill line); whole station rect is
                  the drag target (drag range maps over 0.30h)
ambient   16–20 cool motes drifting in the background; reduced-motion → near-static
```
Above the stage (Flutter chrome, outside the RepaintBoundary): header → EpisodeBoardStrip → instruction banner. Below: the fixed CTA seat. Small-phone check: lamp bloom and station must not collide with banner/CTA at 360×640 logical.
