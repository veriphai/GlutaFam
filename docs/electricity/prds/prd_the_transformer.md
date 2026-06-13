# PRD — The Transformer (EP2 beat 2.6)
### howwow · Episode 2 "The Long Way Home" · registry id `the_transformer` · `TheTransformerScreen` · evidence episode `episode2_electricity`

Binding context: `docs/electricity/context_pack.md`, `docs/electricity/architecture_reference.md`, curriculum §2.6.
This PRD is self-contained: every on-screen line is quoted verbatim here.

---

## 1. One-concept statement

**A transformer steps voltage up/down via induction, has no moving parts, and needs a CHANGING current.**

Inherits from 2.5: the learner just chose to send at very high voltage (fixed power → raise voltage → current drops → wire cools). The open problem this activity answers: *you must SEND at high voltage — so how do you raise it?*
Pins (held constant, visible): the **input voltage (IN 100, live chip, steady value)** and the **primary coil's turns (4 loops, drawn, never change)**. The learner changes ONLY the secondary coil's turns.

## 2. Guiding-question link & CER contribution

Episode question (pinned on the board strip): *"The plant is far away — how do we send power across that distance without losing it all on the way?"*

- **Relevant evidence:** `turns_step_up` — the moment winding more turns doubles the sending voltage and the line lights to the horizon. This is the enabler-link in the episode claim: *we send at very high voltage so the current stays tiny — and the transformer is what makes that high voltage possible.*
- **Distractor (proposed):** `changing_field` — TRUE (the changing field through the core induces the voltage) but it answers *how the device works inside*, not *how we cross the distance without loss*. Mirrors EP1's `still_magnet` distractor logic. Final allocation of EP2's exactly-2 distractors is owned by the EP2 CER PRD; this PRD proposes `changing_field` as one of them.

## 3. The felt discovery (discovery → reaction)

1. **Discovery:** the learner winds turns onto the secondary coil with a drag. **Reaction:** in the same frame each turn snaps on, OUT steps up (100 → 125 → … → 200), and the outgoing line's pulses travel farther toward the horizon; at max turns the farthest pylon catches light. Unwinding steps OUT down and the line's reach shrinks. *More turns out → more voltage out; fewer → less.*
2. **Discovery (witnessed):** the learner is pointed at the core — nothing spins, no part moves — yet the voltage changed. **Reaction:** time slows; one input surge is isolated; the field blooms through the core, and the output kicks alive **only while the field is changing** — at the crest of the bloom, where the field momentarily stops changing, the output visibly slackens. The same rule the learner FELT in EP1 (still magnet = nothing) reappears with no moving parts at all.
3. **Cliffhanger (posed, never answered here):** everything ran on a field that keeps changing — *so what if the current is steady?*

## 4. Felt vs named vs numbered

- **Felt:** the wind/unwind gesture with detents; OUT stepping in the same frame as each turn; the outgoing line's pulses reaching farther / the far pylon igniting; the core's amber field breathing in sync with the input surges (ambient, the whole time); the slow-motion surge with the output kick tracking the field's *rate of change* (slack at the crest); the stillness of the machine.
- **Named (a beat after felt):** "transformer" — a visible object, named on sight at entry (§1 of curriculum: objects named immediately); "electromagnetic induction" — named at the output-kick moment as the EP1 callback; the rule ("steps voltage up or down with the turns — no moving parts") named at synthesis; step-down's destination ("the city end") named after the unwind is felt.
- **Numbered (live, relative, exactly 2):** `IN 100` (held constant, visibly steady while alive) and `OUT 50–200` (steps with turns). Turns are conveyed by **countable drawn loops, not a number**. **No ratings table; no number for any qualitative judgment** (the line's "reach" is felt, never scored).

## 5. On-screen text (exact, beat by beat)

Two registers only: **imperatives** (Bricolage, short, Title Case) and *meaning-lines* (Plus Jakarta Sans, de-personified facts). No mascot, no info-cards.

| # | Beat | Register | Line (verbatim) |
|---|---|---|---|
| 1 | intro | meaning | This is a transformer. |
| 2 | intro (secondary) | meaning | The line ahead needs far more voltage than the plant sends. |
| 3 | windUp | imperative | Wind the Coil |
| 4 | windUp, after first added turn | feedback | More Turns — Higher Voltage |
| 5 | windUp, at max turns (post-ignition) | meaning | Twice the turns — twice the voltage. Now it is high enough to send. |
| 6 | windDown | imperative | Now Unwind the Coil |
| 7 | windDown, after first removed turn | feedback | Fewer Turns — Lower Voltage |
| 8 | windDown, at min turns | meaning | The same device steps voltage down — the city end will need that. |
| 9 | watchCore | imperative | Watch the Core |
| 10 | watchCore | meaning | Nothing spins here. No part moves at all. |
| 11 | watchCore | meaning | So what raised the voltage? |
| 12 | slowSurge, field blooms | meaning | Current in the first coil builds a magnetic field through the core. |
| 13 | slowSurge, output kick | meaning | While that field is changing, it pushes a voltage into the second coil. |
| 14 | slowSurge, callback | meaning | Electromagnetic induction — the same rule that lit the bulb behind the spinning magnet. |
| 15 | depthStop (allowed-longer) | meaning | Electricity and magnetism are secretly the same thing — you'll meet the deep reason in a few years. |
| 16 | synthesis | meaning | A transformer steps voltage up or down with the turns — no moving parts. |
| 17 | cliffhanger | meaning | Everything here runs on a field that keeps changing. |
| 18 | cliffhanger (final, persists) | meaning | So what if the current is steady? |

Line 15 is the shipped depth-stop wording verbatim — same floor, same words as EP1, by design (recognition of one recurring law). NEVER "nobody knows why". No analogy anywhere in lines 12–15.
Card earn brag (overlay one-liner): `The still machine that lifts voltage for the journey.`

## 6. Beat-by-beat flow (timing + gating)

Text swaps use the shipped 190 ms fade-out → swap → fade-in. Interaction is locked in all auto phases. Play length target ≈ 75–115 s.

| Phase | What happens | Timing / gate |
|---|---|---|
| `intro` (auto) | Entrance reveals (core 0→450 ms, coils +150 ms, lines +300 ms, pylons +450 ms; slide+scale+fade). Line 1 at 400 ms; line 2 at 2200 ms. Input surges + field breathing start immediately and never stop. | auto-advance at 3600 ms |
| `windUp` | Line 3. Drag UP along the secondary limb; each detent = +1 turn: loop wraps on over 160 ms, `selectionClick`, OUT steps in the SAME frame, line pulses extend. After first added turn: line 4 (600 ms delay). Down-drag allowed (exploration); gate is reaching max. | gate: `turnsOut == 8` → ignition: 1400 ms pulse-train sails to horizon, far pylon lights, `onCapture('turns_step_up')` → line 5, held 2600 ms → `windDown` |
| `windDown` | Line 6. Drag DOWN removes turns; OUT steps down, line reach shrinks, far pylon goes dark the frame OUT drops below 200 (hard sync, no fade tail on its core glow). After first removed turn: line 7. | gate: `turnsOut <= 2` → line 8, held 3000 ms → `watchCore` |
| `watchCore` (auto) | Chrome and lines dim 30%; vignette tightens on the core. Line 9 at 0 ms; line 10 at 1400 ms; line 11 at 3400 ms. | auto-advance at 5400 ms |
| `slowSurge` (auto, scripted, time 0.35×) | One surge isolated: input pulse enters (0–1200 ms), field blooms through the core (1200–2600 ms) with line 12 at 1200 ms; at 2600 ms the output kicks — flash, `heavyImpact`, `onCapture('changing_field')`, line 13. Output envelope ∝ \|d(field)/dt\| the whole phase: visibly slack at the bloom's crest, alive on the rise and fall. Line 14 at 5000 ms. | auto-advance at 7400 ms |
| `depthStop` (auto) | Line 15 (smaller body size per shipped long-line pattern). Scene calm, field still breathing. | auto-advance at 4600 ms |
| `synthesis` (auto) | Line 16. Time restores to 1×; turns auto-rewind to 8 over 700 ms (no haptics) — the device returns to its grid job, stepped up and sending. | auto-advance at 3000 ms |
| `cliffhanger` | Line 17 at 0 ms → line 18 at 2400 ms; scene dims slightly, field breathing becomes the loudest motion. Line 18 PERSISTS for the rest of the screen. | at 5000 ms → `showCardEarn = true` |
| `done` | Card overlay (`CollectibleEarnOverlay`, eyebrow `NEW CARD`, showMascot false). `onCardCollected` → `showContinue = true`. Continue → `Navigator.maybePop(context)`. | learner-gated |

Reversibility: winding is freely reversible inside `windUp`/`windDown`; auto phases are not skippable (the mechanism must be witnessed). Nothing in this activity ever feeds a steady current — the cliffhanger stays unanswered (2.7 owns the dead-DC moment).

## 7. Hero & layout

- **Hero:** the transformer — the dark iron core ring with its breathing amber field (`#FFD27A`, additive) — the brightest, most-alive thing on screen.
- **Recedes:** background near-black `#070A1C` with radial vignette darkest behind the core; plant silhouette and horizon pylons faint; chips dark glass; line pulses cool transmission-blue `#3FB9F5` (NEVER warm/heat-colored — heat = loss is 2.3's iconography and must not be contradicted).
- **Portrait, top-to-bottom:** header → `EpisodeBoardStrip` (episode question) → top-text (fixed height ~96) → scene (Expanded): horizon pylons top, output line descending from top-right, core center, input line rising from a small plant bottom-left → fixed-height CTA seat (84).
- **Clutter caps:** one hero; ONE gesture surface (the secondary limb); 2 live numbers (IN/OUT chips); current text line; board strip + back + Continue. Interactive elements ≤ 6 (actual: 3). 16–22 ambient motes max.

## 8. Reward

**Card: yes** — the concept is a quick-reference table row ("A device that changes voltage | transformer | 2 | runs on the induction depth-stop"). Proposed copy (shared-infra agent assigns number/motif; section `transmission`, accent `#3FB9F5`; build agent only references the constant, proposed `kStillMachineCard`):

- **Front — playful name:** The Still Machine
- **Front — real term (mono specimen):** TRANSFORMER
- **Front — one-line law:** Turns set the voltage: wind more and it steps up, wind fewer and it steps down.
- **Front — kicker:** Nothing moves but the field.
- **Back — tie to what was felt:** You wound turns onto a coil and watched the voltage climb — nothing spinning, only a changing field at work.
- **Back — outward reach:** The grey cylinder on a street pole is one of these, stepping the line down for your home.
- **Linked card:** 02 — The Magnet Trick (the recurring induction law; this card's law is the turns rule, so it does not restate 02's).

**Inline fact: none** (a fact here would dilute the cliffhanger; deliberate empty slot).

## 9. CER capture hook

`RepaintBoundary(key: _sceneKey)` around the scene; `controller.onCapture = _onCapture` → `captureScenePng(_sceneKey, cropFactor: evidenceByIdFor('episode2_electricity', id)?.cropFactor)` → `_board.capture(id, imageBytes: bytes)`; `lightImpact` in `_onCapture`.

| id | label (≤3 words) | caption (one line) | flag | fires |
|---|---|---|---|---|
| `turns_step_up` | Voltage Stepped Up | Winding more turns raised the sending voltage high enough for the journey. | **relevant** | `windUp` ignition moment — the frame `turnsOut == 8` resolves and the far pylon lights |
| `changing_field` | The Changing Field | While the field through the core is changing, it induces a voltage in the second coil. | **distractor** (true-but-irrelevant: explains the device, not the distance) | `slowSurge` at 2600 ms — the output-kick / `heavyImpact` frame |

Crop factors are owned by the EP2 evidence catalog; suggested: `turns_step_up` crops the upper-right (line + pylons + OUT chip region), `changing_field` crops the core.

## 10. Build notes

- **Flame `GameWidget` + Flutter overlay** (trace_it_back is the template): living scene with ~8 pure-render component layers; gesture stays in Flutter (transparent `Listener` above the GameWidget forwarding to the controller). GameWidget built once in `initState`.
- **No Forge2D.** All motion is controlled. The wind gesture has NO momentum: release stops detents where they are. Turn detents, OUT steps, pylon light/dark, and the output-kick envelope are hard-synced in the controller's `tick`.
- Controller owns sim + geometry + phase machine (`setStageSize`, factor-based anchors); `_schedule(ms, fn)` timers for auto beats; `reducedMotion` from MediaQuery each build.
- `MediaQuery(...textScaler: TextScaler.noScaling)` wrap; reduced motion = calm motes, fades instead of flourishes, softer flash — but the surge breathing, the same-frame OUT steps, and the kick-tracks-change behavior are pedagogical and stay.
- Haptics: `selectionClick` per detent; `heavyImpact` at the line-13 output kick; `lightImpact` on capture; medium is inside the card overlay.
- Audio: silent (matches shipped EP activities). Optional low hum is an open decision (§13).
- Persistence: none beyond shared evidence/card stores. Write ONLY inside `lib/screens/missions/the_transformer/`; registry entry, evidence catalog ids, and the card constant are owned by other phases — report needs in the final build message, never edit shared files. Verify with `fvm dart analyze lib/screens/missions/the_transformer`.

## 11. Acceptance criteria (pedagogy as testable checks)

1. **Discoverable from interaction alone:** with all text hidden, dragging on the secondary coil visibly winds turns, steps OUT, and extends the line's reach — the turns→voltage relationship reads without reading.
2. **Same-frame response:** each turn detent changes OUT and the line pulses in the SAME frame (no eased lag on the value; the chip may tick its glyphs ≤240 ms but the step lands instantly).
3. **Held-constant visible:** the primary coil's 4 loops never change and stay on screen throughout; IN reads 100 the entire activity while its chip shimmers in sync with the surges (alive but constant) — the learner changes only secondary turns.
4. **Both directions witnessed:** the flow cannot reach `watchCore` until the learner has reached max turns (step-up, OUT 200) AND min turns (step-down, OUT 50).
5. **No moving parts is true on screen:** no element of the transformer ever rotates or translates during generation; the only motion is field/pulse rendering.
6. **The kick tracks change:** during `slowSurge`, output activity is proportional to |d(field)/dt| — visibly slack at the bloom's crest, alive on rise and fall; the line-13 caption lands AT the kick frame with `heavyImpact`.
7. **Depth-stop honesty:** line 15 appears verbatim; the strings "nobody", "no one knows", and any analogy are absent from the whole copy file.
8. **Cliffhanger unanswered:** no battery, no steady-feed toggle, no DC/AC/Hz naming anywhere; line 18 is a question and persists behind the card and Continue.
9. **≤2 live numbers** (IN, OUT), both relative; turns are countable loops with no numeric label; no ratings table anywhere.
10. **Iconography guard:** output line and pulses use cool `#3FB9F5`; nothing renders higher voltage as hotter/redder.
11. **Hero check:** the core + field is the brightest element in every phase; pylon ignition is the only moment the periphery briefly outshines it (≤1400 ms).
12. **Captures fire exactly once** at the two specified frames with `lightImpact`, and the board strip backfills the thumbnails.
13. Hard gates respected with reduced motion ON (no fade softening the pylon-dark frame or the kick timing); portrait small-phone layout sane; `fvm dart analyze lib/screens/missions/the_transformer` clean.
14. Card overlay fires only after line 18 has held ≥2400 ms; Continue appears only after `onCardCollected`; Continue pops via `Navigator.maybePop`.

## 12. Anti-patterns (this activity)

- Rendering voltage as heat (warm/red line glow) — contradicts 2.3/2.4's loss iconography.
- Adding a current readout, a power readout, or an energy-conservation caveat ("more voltage but less current out") — second concept; cut.
- Answering the cliffhanger: any steady-current demo, battery icon, flat-line graph, or the words AC/DC/50 Hz (all owned by 2.7).
- A continuous turns slider — turns are integers; detents with haptics, loops countable.
- A formula on screen (V₂/V₁ = N₂/N₁) — the relationship is felt and stated in words ("Twice the turns — twice the voltage"), never written as algebra.
- An analogy at the depth-stop floor, or softening it ("it's like magic", "nobody knows why").
- Explaining inside an imperative (imperatives ≤5 words; only meaning-lines teach).
- Pre-spoiling: lines 12–14 must not appear, even faintly, before `slowSurge`; "no moving parts" is not mentioned until the learner has wound and unwound.
- A premium fade on the pylon going dark or on the output slackening at the crest.
- Editing `activityRegistry.dart`, evidence catalogs, or collectible files from the build agent.

## 13. Open decisions

1. **Turns label:** default is NO numeric turns label (loops countable, max 8, chunky). If on-device QA shows counting fails at small sizes, a single tiny mono `×8` under the secondary coil may be added — flag for review (it is a 3rd number).
2. **Turns range/mapping:** default primary 4, secondary 2–8 → OUT 50–200. Tunable in `TxTune`; ratio must keep "Twice the turns — twice the voltage" literally true at the extremes (4→8, 100→200).
3. **Audio:** default silent. A barely-audible transformer hum (≤0.15 vol) during generation is allowed if it survives taste review; note a mains hum weakly foreshadows AC — acceptable, it names nothing.
4. **Distractor allocation:** `changing_field` is proposed as one of EP2's two distractors — final call by the EP2 CER PRD/catalog owner.
5. **Board-strip question string:** use the shared `kEpisode2Question` constant; final phrasing owned by the EP2 CER PRD.

## 14. State machine sketch

```dart
enum TxPhase { intro, windUp, windDown, watchCore, slowSurge, depthStop, synthesis, cliffhanger, done }

class TransformerController extends ChangeNotifier {
  // ValueNotifiers (discrete UI channels)
  final phase        = ValueNotifier<TxPhase>(TxPhase.intro);
  final caption      = ValueNotifier<TxCaption>(TxCaption.introName); // carries register flag
  final secondaryCap = ValueNotifier<TxCaption?>(null);               // intro line 2
  final turnsOut     = ValueNotifier<int>(4);                         // 2..8, detented
  final showCardEarn = ValueNotifier<bool>(false);
  final showContinue = ValueNotifier<bool>(false);

  // Hot-path getters (read by Flame components; updated in tick())
  double surgePhase;     // 0..1 looping input-surge clock (period ~1.1 s; ×0.35 in slowSurge)
  double fieldBloom;     // core field intensity, follows surge
  double fieldRate;      // |d(fieldBloom)/dt| — drives outputKick (the honest envelope)
  double outputKick;     // output-side activity ∝ fieldRate (× outVoltage scale)
  double outVoltage;     // turnsOut / 4 * 100  → 50..200
  double lineReach;      // 0..1 how far output pulses travel; 1.0 only at OUT 200
  double coilWindT;      // 0..1 per-detent loop-wrap animation
  double flashIntensity; // kick + ignition flashes
  double sceneDim;       // watchCore/cliffhanger dimming
  double timeScale;      // 1.0, 0.35 in slowSurge

  // Input (Flutter Listener forwards): vertical drag on the secondary-limb rect.
  // Accumulate dy; every kDetentDrag px → turnsOut ±1 (clamped 2..8), selectionClick,
  // OUT/lineReach updated same frame. Release = stop (no momentum).
  void onPointerDown/Move/Up(Offset local);

  // Timers: _schedule(ms, fn) (cancel-on-dispose). Per-phase schedule per §6 table.
  // Gates: windUp→ignition on turnsOut==8 (once); windDown→exit on turnsOut<=2;
  //        all other transitions timer-driven; input ignored outside windUp/windDown.
  // Hooks: onCapture(String id), onDetent (selectionClick), onKick (heavyImpact).
  void tick(double dt); // dt*timeScale; hard-gates outputKick to fieldRate every frame
}
```

Timers (ms): intro 3600 · ignition 1400 + hold 2600 · windDown exit hold 3000 · watchCore 5400 (lines at 0/1400/3400) · slowSurge 7400 (lines at 1200/2600/5000; kick+capture at 2600) · depthStop 4600 · synthesis 3000 (auto-rewind 700) · cliffhanger 2400→line 18, +2600→card.

## 15. File plan (`lib/screens/missions/the_transformer/`)

```
the_transformer_screen.dart            (~330) — shell: noScaling MediaQuery, RepaintBoundary(_sceneKey)
                                               [EnergyFieldBackground + GameWidget], Listener forward,
                                               header, EpisodeBoardStrip(kEpisode2Question), _FadeSwapCaption
                                               top-text (h≈96), CTA seat (h=84), capture wiring,
                                               CollectibleEarnOverlay, CaptureFlash
state/transformer_controller.dart      (~420) — TransformerController per §14 (sim + geometry + phases)
config/transformer_tuning.dart         (~110) — TxTune: all geometry factors (§16), detent px, surge
                                               period, timeScale, timings table, voltage mapping, palette
config/transformer_copy.dart           (~70)  — TxCaption enum + verbatim strings (§5) + register flags
game/transformer_game.dart             (~55)  — FlameGame: transparent bg, onGameResize→setStageSize,
                                               update→controller.tick, adds layers back→front
game/components/scene_components.dart  (~650) — AmbientMotes, BackgroundGlow, PlantSilhouette, InputLine
                                               (surge pulses), CoreField (HERO: ring + additive amber
                                               breathing ribbon), PrimaryCoil (4 fixed loops), SecondaryCoil
                                               (2..8 loops + wind anim + grab hint), OutputLine (reach-gated
                                               pulses, cool blue), HorizonPylons (far-pylon ignition),
                                               VoltageChips (IN/OUT mono chips), FlashLayer
widgets/energy_field_background.dart   (~100) — copy-adapt of the static dark vignette variant
```

Shared imports only: episode_board (strip/capture/snapshot), collectibles (overlay + card const), careerTheme, google_fonts. No edits outside this directory.

## 16. Scene sketch (portrait, factors of stage size w×h)

```
y 0.04–0.12  HORIZON: output line converging to vanishing point (0.88w, 0.08h);
             4 pylons shrinking along it (x 0.60→0.86w); farthest pylon = ignition target
y 0.12–0.30  OUTPUT RUN: line from secondary top (0.62w, 0.38h) → (0.78w, 0.20h) → horizon;
             OUT chip anchored (0.74w, 0.15h), clear of the board strip above
y 0.30–0.64  THE TRANSFORMER (hero): core = upright rounded ring, center (0.46w, 0.48h),
             outer ~0.46w × 0.30h, limb thickness 0.055w; amber field ribbon circulates the
             ring (BlendMode.plus), intensity = fieldBloom; PRIMARY coil = 4 fixed loops on
             LEFT limb; SECONDARY coil = 2..8 chunky countable loops on RIGHT limb;
             gesture rect = right limb ± (0.16w, 0.20h); vignette darkest here
y 0.64–0.82  INPUT RUN: line from plant (0.14w, 0.88h) rising to primary bottom (0.35w, 0.62h),
             carrying repeating surge pulses (the CHANGING current, always alive);
             IN chip anchored (0.18w, 0.70h), micro-shimmer synced to surges, value pinned 100
y 0.82–1.00  FOREGROUND: faint plant silhouette + ink ground band; 16–22 ambient motes overall
```

Flow reads bottom-left (plant) → core → top-right (horizon): the journey, vertically staged for portrait. All anchors live in `TxTune`; no fixed pixels.
