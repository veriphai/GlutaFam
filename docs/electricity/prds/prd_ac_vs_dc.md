# PRD — AC vs DC (EP2 beat 2.7)
### howwow · Episode 2 "The Long Way Home" · registry id `ac_vs_dc` · `AcVsDcScreen` · evidence episode `episode2_electricity`

Binding context: `docs/electricity/context_pack.md`, `docs/electricity/architecture_reference.md`, curriculum §2.7.
This PRD is self-contained: every on-screen line is quoted verbatim here.

---

## 1. One-concept statement

**DC flows steadily one way, AC reverses many times a second — and a transformer works only on AC.**

Inherits: from 2.6, the transformer itself and its unanswered cliffhanger (*"So what if the current is steady?"* — this activity opens on that exact question and answers it with the learner's hands); from EP1 beat 1.1, the felt rule that only a CHANGING field induces (still magnet = nothing).
Pins (held constant, visible): the **transformer is identical throughout** — same core, same coils (primary 4 loops, secondary 8, matching 2.6's ending state), nothing ever rewound or moved; and the **current's strength is equal for both feeds** — the battery's flat line and the machine's wave reach the exact same height on the tiny current graph. Only the current's *behavior over time* changes.

## 2. Guiding-question link & CER contribution

Episode question (pinned on the board strip): *"The plant is far away — how do we send power across that distance without losing it all on the way?"*

- **Relevant evidence:** `ac_springs_alive` — the reversing current bringing the dead transformer fully to life. This is the second enabler-link in the episode claim: *we send at very high voltage so the current stays tiny — transformers make that voltage possible, and transformers run only on AC.*
- **Relevant evidence (supporting contrast):** `dc_dead_transformer` — the steady battery current leaving the transformer dead. True AND relevant (it is half the case for why the long lines carry AC, and it directly loads 2.8). Both tiles are proposed relevant; the EP2 CER owner may trim one (EP1 precedent: gas/hydro catch but don't capture). **No distractor is proposed from this beat** — EP2 already has three distractor candidates from 2.1 and 2.6; the CER owner selects the episode's exactly-2.

## 3. The felt discovery (discovery → reaction)

1. **Discovery (the absence — the hard gate):** the learner connects a battery to the transformer's input. **Reaction:** one-direction pulses run up the input line at constant speed, the graph draws a flat line, the core's field rises once and **freezes** — motionless amber, no breathing — and the output bulb stays **dark**. Nothing happens for a held beat. The dead transformer is the discovery, witnessed in silence before any text names it.
2. **Discovery (the learner makes alternation by hand):** the learner flips the battery. **Reaction:** the current reverses, the field collapses and rebuilds the other way, and **during that change** the output bulb blinks once — then dies the instant the field settles (hard gate, no tail). Flip after flip: every reversal wakes the coil; every steady moment kills it. Flipping fast produces a living flicker — the learner has built crude AC with a thumb.
3. **Discovery (the machine finishes the thought):** a hand can't flip fast enough; the plant's source slides in and reverses the current smoothly, continuously. **Reaction:** the graph becomes a wave, the field never stops changing, the bulb climbs to full steady brightness — the transformer springs to life. Only THEN are the two currents named: DC, AC, 50 hertz.

## 4. Felt vs named vs numbered

- **Felt:** the direction of the input pulses (one-way vs reversing); the field freezing (breathing stops dead) vs breathing fast; the dark bulb on steady feed; one blink per flip, kick width = flip width; flicker density rising with flip rate; the steady full-bright bulb on the machine's wave; flat line → hand-made square steps → smooth fast wave on the tiny graph.
- **Named (a beat after felt):** "dead" / "alive" as the transformer's states (after each is witnessed); the echo law *Only a Changing Current Works* (after the flip burst is felt); **DC — direct current** and **AC — alternating current** (only in the naming phase, after both behaviors are felt); **50 hertz** (only after the wave is seen).
- **Numbered (≤2 numbers-ish elements, relative):** (1) the **tiny live current graph** — a strip chart of the genuine quantity (current vs time), relative, no axis numbers, amplitude ±1; (2) its **`50 CYCLES / SEC`** mono label, appearing only in the alive phase. **No voltage chips, no power readout, no ratings table, no number for any qualitative judgment.** Aliveness is read on the bulb and field, never as a stat.

## 5. On-screen text (exact, beat by beat)

Two registers only: **imperatives** (Bricolage, short, Title Case) and *meaning-lines* (Plus Jakarta Sans, de-personified facts). No mascot, no info-cards.

| # | Beat | Register | Line (verbatim) |
|---|---|---|---|
| 1 | intro | meaning | A transformer, ready to step voltage up — but nothing feeds it yet. |
| 2 | intro (the 2.6 question, re-posed) | meaning | So what if the current is steady? |
| 3 | connect | imperative | Connect the Battery |
| 4 | steadyDead, after witnessed hold | meaning | A steady, one-way current. The field rises once — then freezes. |
| 5 | steadyDead, the dead discovery | meaning | A frozen field induces nothing. The transformer is dead. |
| 6 | flipOnce | imperative | Flip the Battery |
| 7 | flipOnce, after the first kick dies | meaning | The reversal changed the field — for that instant, the second coil woke. |
| 8 | flipFast | imperative | Now Flip It Fast |
| 9 | flipFast, feedback during the burst | feedback | Each Flip Wakes the Coil |
| 10 | flipFast, gate met (the echo law) | meaning | Only a Changing Current Works |
| 11 | handoff | meaning | A hand manages a few flips a second. The transformer needs the change to never stop. |
| 12 | handoff, machine slides in | meaning | Now the Current Reverses Itself |
| 13 | handoff, wave establishes (held-constant) | meaning | No stronger than the battery — it only keeps reversing. |
| 14 | alive, the spring-to-life | meaning | The field never stops changing — the transformer is fully alive. |
| 15 | alive, the count | meaning | In India the current completes fifty cycles every second — 50 hertz. |
| 16 | naming | meaning | Steady, one-way current is DC — direct current. Batteries make it; chips run on it. |
| 17 | naming | meaning | Current that keeps reversing is AC — alternating current. |
| 18 | synthesis | meaning | The transformer works only on AC. |
| 19 | bridge | meaning | The long lines ahead need enormous voltage — and only a transformer can raise it. |
| 20 | bridge (final, persists) | meaning | So which current can cross the country? |

Line 10 deliberately echoes EP1's shipped "Only a Moving Magnet Works" — same law, third costume. Line 20 is 2.8's setup and persists behind the card and Continue; the word "grid" is never used (claimed by EP4). No depth-stop line here — this beat is **fully explained** (the induction depth-stop was delivered in 2.6 and is not repeated).
Card earn brag (overlay one-liner): `The restless current that wakes the transformer.`

## 6. Beat-by-beat flow (timing + gating)

Text swaps use the shipped 190 ms fade-out → swap → fade-in. Interaction is locked in all auto phases. Play length target ≈ 75–120 s.

| Phase | What happens | Timing / gate |
|---|---|---|
| `intro` (auto) | Entrance reveals (core 0→450 ms, coils +150 ms, bulb +300 ms, dock + graph +450 ms; slide+scale+fade). Field dark and still; graph drawing a zero line. Line 1 at 400 ms; line 2 at 2600 ms. Battery sits in the dock with a soft grab hint. | auto-advance at 4400 ms → `connect` |
| `connect` | Line 3. Tap the battery: it clicks into the terminals (160 ms), `selectionClick`. One-direction pulses start up the input line; graph steps to +1 and draws flat; field ramps up over 600 ms (one faint ≤250 ms output flicker as it rises — honest, un-captioned; see §13.1) then freezes solid. Bulb dark. | gate: battery tapped → `steadyDead` |
| `steadyDead` (auto) | **Witnessed absence:** 2800 ms of nothing — steady pulses, flat line, frozen field, dark bulb, no text. Then line 4. At +1600 ms: line 5, `heavyImpact`, slight scene-dim underline, `onCapture('dc_dead_transformer')`. | auto-advance 2600 ms after line 5 → `flipOnce` |
| `flipOnce` | Line 6; the battery gains a flip affordance (visible + / − ends, rocking hint). Tap = battery rotates 180° over 140 ms; current sweeps +1→−1 over 120 ms; graph steps down; field collapses/rebuilds reversed; output kicks for the width of the change — bulb blinks once, then dies (hard gate). `selectionClick` per flip. | gate: first flip completed → kick dies → line 7 at +700 ms, held 2600 ms → `flipFast` |
| `flipFast` | Line 8. Free flipping. During a fast run (≥2 flips within 900 ms) line 9 shows as feedback. Flicker density tracks flip rate honestly (overlapping kicks). | gate: total flips ≥ 5 AND a burst of ≥3 flips within 1200 ms → line 10, `heavyImpact`, held 2800 ms → `handoff` |
| `handoff` (auto) | Line 11 at 0 ms. At 2600 ms the battery slides out left, the plant's source slides in (1400 ms) — a quiet rounded unit, NO "AC" label, no waveform icon; line 12 at 3200 ms. The new source starts reversing the current: wave begins slow (~2 Hz) and ramps; line 13 at 5400 ms as the wave's amplitude visibly matches the battery's old flat-line height. | auto-advance at 7600 ms → `alive` |
| `alive` (auto) | Wave ramps to full speed over 900 ms (graph timebase compresses oscilloscope-style so ~7 cycles stay readable); field breathes fast and bright; bulb climbs to full steady brightness. At 1200 ms: flash, `heavyImpact`, `onCapture('ac_springs_alive')`, line 14. At +2600 ms: `50 CYCLES / SEC` mono label fades onto the graph (400 ms) + line 15. | auto-advance at 7400 ms → `naming` |
| `naming` (auto) | Line 16 at 0 ms (slightly smaller body size per shipped long-line pattern); line 17 at 3400 ms. Scene unchanged — transformer alive throughout. | auto-advance at 6400 ms → `synthesis` |
| `synthesis` (auto) | Line 18 alone, full size. The bulb and field at their steadiest. | auto-advance at 3000 ms → `bridge` |
| `bridge` (auto) | Line 19 at 0 ms; line 20 at 2800 ms, PERSISTS. Scene dims slightly; the breathing field and the wave stay the loudest motion. | at 5600 ms → `showCardEarn = true` |
| `done` | Card overlay (`CollectibleEarnOverlay`, eyebrow `NEW CARD`, showMascot false). `onCardCollected` → `showContinue = true`. Continue → `Navigator.maybePop(context)`. | learner-gated |

Reversibility: flipping is free inside `flipOnce`/`flipFast` (the deadness between flips is re-felt every time — converging repetition); auto phases are not skippable (the dead hold and the spring-to-life must be witnessed). The battery is never reconnectable after `handoff`.

## 7. Hero & layout

- **Hero:** the transformer — core ring + its amber field (`#FFD27A`, additive). Its two states ARE the readout: frozen-and-faint when dead, breathing-and-bright when alive. Even dead, it stays the visual center (faint static amber against the darkest vignette); nothing else outshines it except the bulb for ≤1200 ms at the spring-to-life flash.
- **Recedes:** background near-black `#070A1C`, radial vignette darkest behind the core; input pulses cool transmission-blue `#3FB9F5` (never warm — heat = loss is 2.3's iconography); dock and graph in dark glass (`0x14FFFFFF`, border `0x26FFFFFF`); 16–22 ambient motes max.
- **Portrait, top-to-bottom:** header → `EpisodeBoardStrip` (EP2 question) → top-text (fixed height ~96) → scene (Expanded): bulb top-center, transformer center, source dock lower-center (thumb reach), tiny graph strip at the very bottom of the scene → fixed-height CTA seat (84).
- **Clutter caps:** one hero; ONE gesture surface (the battery in the dock); the graph + its one label as the only numbers-ish elements; current text line; board strip + back + Continue. Interactive elements ≤6 (actual: 3). The graph is TINY (≤0.10 of stage height) — it rides alongside the felt thing, never replaces it.

## 8. Reward

**Card: yes** — the concept is a quick-reference table row ("Steady one-way vs reversing current | DC / AC | 2 | fully explained"). Proposed copy (shared-infra agent assigns number/motif; section `transmission`, accent `#3FB9F5`; build agent only references the constant, proposed `kTwoCurrentsCard`):

- **Front — playful name:** The Two Currents
- **Front — real term (mono specimen):** DIRECT / ALTERNATING CURRENT
- **Front — one-line law:** DC flows steadily one way; AC reverses many times a second.
- **Front — kicker:** Only the restless one can work a transformer.
- **Back — tie to what was felt:** You flipped a battery and the dead transformer blinked awake — every reversal, one flicker; every steady moment, nothing.
- **Back — outward reach:** The wall socket reverses its current fifty times a second — yet every chip in your phone insists on steady DC.
- **Linked card:** The Still Machine (2.6 — the device this rule feeds; the induction lineage runs back to 02 The Magnet Trick through it). This card's law is the two currents' definitions — it does not restate the turns rule or the induction rule.

**Inline fact: none** (a fact here would dilute the bridge question; deliberate empty slot).

## 9. CER capture hook

`RepaintBoundary(key: _sceneKey)` around the scene (background + GameWidget only; chrome excluded); `controller.onCapture = _onCapture` → `lightImpact` → `captureScenePng(_sceneKey, cropFactor: evidenceByIdFor('episode2_electricity', id)?.cropFactor)` → `_board.capture(id, imageBytes: bytes)`; `EpisodeBoardStrip` pinned under the header.

| id | label (≤3 words) | caption (one line) | flag | fires |
|---|---|---|---|---|
| `dc_dead_transformer` | Dead on Steady | A steady one-way current froze the field — the transformer gave nothing. | **relevant** (supporting contrast; CER owner may trim) | `steadyDead`, the line-5 / `heavyImpact` frame (flat line + frozen field + dark bulb on screen) |
| `ac_springs_alive` | Alive on AC | A current that keeps reversing keeps the field changing — the transformer came alive. | **relevant** | `alive` at 1200 ms — the spring-to-life flash frame (full bulb + fast field + wave drawn) |

Suggested cropFactors (catalog owner finalizes): `dc_dead_transformer` ≈ `Rect.fromLTRB(0.10, 0.24, 0.90, 1.00)` (core + dock + flat graph); `ac_springs_alive` ≈ `Rect.fromLTRB(0.10, 0.02, 0.90, 0.78)` (bulb + breathing core + wave edge). Both ids are unique within EP2 (existing: voltage_drives_current, no_voltage_no_current, heat_quadruples, square_curve, current_drops_itself, cold_wire_full_town, turns_step_up, changing_field).

## 10. Build notes

- **Flame `GameWidget` + Flutter overlay** (trace_it_back / the_transformer are the templates): ~10 pure-render component layers; gesture stays in Flutter (transparent `Listener` above the GameWidget forwards taps on the dock rect to the controller). GameWidget built once in `initState`.
- **No Forge2D.** All motion controlled. The flip is a scripted 140 ms rotation; the current sweep is a 120 ms controlled transition; release/no-tap = nothing moves. **The cutoff is a hard gate in `tick`:** `outputLevel = fieldRate > eps ? f(fieldRate) : 0.0` every frame; the bulb has fast attack and INSTANT release (≤2% within 50 ms of the field settling) — never a decayed value, with reduced motion ON too.
- The honest engine: `currentLevel` (−1..+1) → `fieldLevel` follows with tiny lag (τ ≈ 0.08 s) → `fieldRate = |d(fieldLevel)/dt|` drives output kick, field-breathing brightness, and the spring-to-life. The flip kick's width literally equals the transition width; overlapping fast flips merge into flicker with no special-casing. At wave speed, `fieldRate` is nearly always above eps → steady bulb (50 Hz flicker honestly fuses).
- **Graph:** a `GraphStrip` Flame component (so captures include it) — scrolling ring buffer of `currentLevel`, centerline zero, mono micro-eyebrow `CURRENT`, no axis numbers; timebase compresses when the wave ramps (oscilloscope convention, no on-screen multiplier) so ~7 cycles stay readable; `50 CYCLES / SEC` label revealed only in `alive`.
- Controller owns sim + geometry + phase machine (`setStageSize`, factor anchors in `AcdcTune`); `_schedule(ms, fn)` cancel-on-dispose timers; `reducedMotion` from MediaQuery each build (calm motes, shorter reveals, softer flash — the frozen field, the 50 ms cutoff, and the witnessed dead hold are pedagogical and stay).
- `MediaQuery(...textScaler: TextScaler.noScaling)` wrap; haptics: `selectionClick` per connect/flip; `heavyImpact` at lines 5, 10, and 14; `lightImpact` on capture; medium inside the card overlay.
- Audio: silent by default (matches shipped EP2 activities). Optional faint hum gated ON only while the transformer is alive is an open decision (§13.5).
- Persistence: none beyond shared evidence/card stores. Write ONLY inside `lib/screens/missions/ac_vs_dc/`; registry entry, EP2 evidence catalog, and the card constant are owned by other phases — report needs in the final build message, never edit shared files. Verify with `fvm dart analyze lib/screens/missions/ac_vs_dc`.

## 11. Acceptance criteria (pedagogy as testable checks)

1. **Discoverable from interaction alone:** with all text hidden, tapping the battery yields steady pulses + flat line + frozen field + dark bulb; each flip yields exactly one blink; fast flips yield flicker; the machine yields a wave + steady-bright bulb. The dead/alive rule reads without reading.
2. **The cutoff is a hard gate:** whenever `fieldRate` falls below eps (steady feed, and between every pair of flips), bulb + output pulses reach ≤2% within 50 ms — no fade tail, including with reduced motion ON.
3. **Witnessed absence:** the dead state holds ≥2800 ms with NO text before line 4; line 5 ("…dead") lands only after the absence is witnessed.
4. **Held-constant visible:** the transformer's coils never change (primary 4 / secondary 8 loops drawn identically all activity; nothing on the device ever moves or rewinds); the machine wave's amplitude matches the battery's flat-line height within ±2% on the graph, and line 13 states it.
5. **Name-last:** the strings "DC", "AC", "direct", "alternating", "hertz", "Hz", "50" (and the graph's 50-label) appear nowhere — in copy, labels, or source art — before the `alive` phase; DC/AC are named only in `naming`, after both behaviors are felt. The machine source carries no waveform icon or name when it slides in.
6. **The kick is honest:** kick width equals the flip-transition width; no kick ever fires without a field change; flicker density rises monotonically with flip rate; during `alive` the bulb is steady (no theatrical pulsing).
7. **Numbers cap:** the graph + its single `50 CYCLES / SEC` label are the only numbers-ish elements; no voltage/power chips; no ratings table; aliveness is never shown as a stat or meter.
8. **The echo law:** line 10 reads exactly "Only a Changing Current Works" (the EP1 "Only a Moving Magnet Works" echo).
9. **Captures fire exactly once** each at the §9 frames with `lightImpact`; board strip backfills thumbnails; ids exactly `dc_dead_transformer` / `ac_springs_alive`.
10. **Scope guards:** no 1880s/Edison/Tesla/War content, no map, no charger/household AC→DC content (all owned by 2.8 and its bridge); line 20 is a question, persists behind card and Continue, and never contains the word "grid".
11. **DC is not "weak":** the steady feed's pulses and graph level visibly equal the wave's amplitude — the failure reads as changelessness, never as low strength.
12. **Hero check:** the core + field is the brightest element in every phase except the ≤1200 ms spring-to-life flash; the graph occupies ≤0.10 of stage height; imperatives ≤5 words.
13. Flip gate enforced: `handoff` is unreachable until ≥5 total flips including a ≥3-flips-in-1200 ms burst; auto phases unskippable.
14. Card overlay fires only after line 20 has held ≥2800 ms; Continue appears only after `onCardCollected`; Continue pops via `Navigator.maybePop`; play length 60–150 s; `fvm dart analyze lib/screens/missions/ac_vs_dc` clean; portrait small-phone sane.

## 12. Anti-patterns (this activity)

- A waveform-selector toggle (flat vs wave buttons) replacing the hand-flip — the learner must MAKE alternation with their thumb before the machine takes over.
- Any residual shimmer, breathing, or premium glow on the dead transformer — dead means motionless; softening the frozen field destroys the discovery.
- Pre-spoiling: naming DC/AC/50 Hz early, printing "AC" or a sine glyph on the machine source, or any text hinting the transformer will die before it is felt dead.
- Rendering the steady current as weaker/dimmer than the wave — the lesson is changelessness, not strength.
- A frequency slider or pitch control — "how does frequency change things" is a second concept; the only rates are hand-speed and the fixed 50 Hz.
- Explaining why the bulb looks steady at 50 Hz (persistence of vision) — cut; out of concept.
- Promoting the graph: axis numbers, a big scope panel, grid lines, a timebase readout — keep it a tiny strip; the transformer's aliveness is the readout.
- Momentum/inertia on flips, or an eased "settling" of output after the field stops changing.
- Explaining inside an imperative (imperatives ≤5 words; only meaning-lines teach); rhyme or sing-song in any line.
- Editing `activityRegistry.dart`, evidence catalogs, or collectible files from the build agent.

## 13. Open decisions

1. **The connection blip:** when the battery first connects, the rising field honestly induces one faint ≤250 ms output flicker before the freeze. Default: KEEP (it is true, and it quietly seeds the flip discovery). If on-device QA shows it muddies "steady = dead", shrink toward imperceptible — never extend it.
2. **Graph timebase compression** at wave speed (oscilloscope-style, ~7 visible cycles) vs a dense honest band: default compression; the `50 CYCLES / SEC` label carries the literal truth either way.
3. **Flip gesture:** default tap-to-flip (reliable, fast). A drag-rotate alternative is more physical but risks fiddly fail-states about ergonomics, not the concept — only revisit if QA finds tapping reads as abstract.
4. **Flip gate numbers** (≥5 total, ≥3 within 1200 ms) are tunable in `AcdcTune`; the burst must stay strict enough that the flicker is genuinely felt before line 10.
5. **Audio:** default silent. An optional faint 50 Hz-flavored hum, gated ON only while the transformer is alive (≤0.15 vol), is allowed if it survives taste review — the hum starting exactly at the spring-to-life would be a quiet reinforcement.
6. **Tile allocation:** both tiles proposed relevant; final keep/trim and cropFactors owned by the EP2 CER PRD / evidence catalog.
7. **Board-strip question string:** use the shared `kEpisode2Question` constant; final phrasing owned by the EP2 CER PRD.

## 14. State machine sketch

```dart
enum AcdcPhase { intro, connect, steadyDead, flipOnce, flipFast, handoff, alive, naming, synthesis, bridge, done }

class AcdcController extends ChangeNotifier {
  // ValueNotifiers (discrete UI channels)
  final phase        = ValueNotifier<AcdcPhase>(AcdcPhase.intro);
  final caption      = ValueNotifier<AcdcCaption>(AcdcCaption.introWaits); // carries register flag
  final showCardEarn = ValueNotifier<bool>(false);
  final showContinue = ValueNotifier<bool>(false);

  // Hot-path getters (read by Flame components; updated in tick())
  double currentLevel;   // −1..+1 actual current; battery: ±1 steady; flips: 120 ms sweeps; machine: wave
  double fieldLevel;     // follows currentLevel, tau 0.08 s
  double fieldRate;      // |d(fieldLevel)/dt| — the one honest driver of everything output-side
  double outputLevel;    // HARD GATE: fieldRate > eps ? f(fieldRate) : 0.0 (every frame)
  double bulbBrightness; // fast attack from outputLevel; INSTANT release (≤50 ms to ≤2%)
  double flipT;          // 0..1 battery 180° rotation anim (140 ms)
  double swapT;          // 0..1 battery-out / machine-in slide (handoff)
  double wavePhase, waveFreq;     // machine oscillator; ramps 2 Hz → render-rate-capped "50 Hz"
  double graphTimebase;           // strip-chart window; compresses during alive ramp
  final List<double> graphSamples; // ring buffer feeding GraphStrip
  double flashIntensity, sceneDim, labelReveal, entranceT;
  int    flipCount; final List<double> flipTimestamps; // burst detection (≥3 within 1.2 s)

  // Input (Flutter Listener forwards): tap inside the dock rect.
  //   connect phase  → dock tap = connect (once);
  //   flip phases    → dock tap = flip (rejected while flipT mid-anim < 0.6);
  //   everywhere else → ignored.
  void onTapDown(Offset local);

  // Timers: _schedule(ms, fn), cancel-on-dispose; per-phase schedule per §6 table.
  // Gates: connect → battery tapped; flipOnce → first flip kick completed;
  //        flipFast → flipCount >= 5 && burstOf3Within(1200 ms); all others timer-driven.
  // Hooks: onCapture(String id), onFlip (selectionClick), onDiscovery (heavyImpact ×3: lines 5/10/14).
  void tick(double dt); // recomputes fieldLevel/fieldRate, hard-gates outputLevel + bulb, advances graph
}
```

Timers (ms): intro 4400 (lines 400/2600) · steadyDead hold 2800 → line 4 → +1600 line 5 + capture → +2600 → flipOnce · flipOnce: kick→+700 line 7, +2600 → flipFast · flipFast gate → line 10 held 2800 · handoff 7600 (lines 0/3200/5400; swap 2600–4000) · alive 7400 (flash+capture 1200; label+line 15 at 3800) · naming 6400 (lines 0/3400) · synthesis 3000 · bridge 5600 (lines 0/2800) → card.

## 15. File plan (`lib/screens/missions/ac_vs_dc/`)

```
ac_vs_dc_screen.dart                   (~330) — shell: noScaling MediaQuery, RepaintBoundary(_sceneKey)
                                               [EnergyFieldBackground + GameWidget], Listener forward,
                                               header, EpisodeBoardStrip(kEpisode2Question), _FadeSwapCaption
                                               top-text (h≈96), CTA seat (h=84), capture wiring,
                                               CollectibleEarnOverlay, CaptureFlash
state/acdc_controller.dart             (~430) — AcdcController per §14 (sim + geometry + phase machine)
config/acdc_tuning.dart                (~110) — AcdcTune: geometry factors (§16), tau/eps, flip anim ms,
                                               gate numbers, wave ramp, graph window, timings, palette
config/acdc_copy.dart                  (~75)  — AcdcCaption enum + verbatim strings (§5) + register flags
game/acdc_game.dart                    (~55)  — FlameGame: transparent bg, onGameResize→setStageSize,
                                               update→controller.tick, adds layers back→front
game/components/scene_components.dart  (~640) — AmbientMotes, BackgroundGlow, OutputBulb (shared paintBulb
                                               style), OutputLine (kick-gated pulses), CoreField (HERO:
                                               ring + additive amber field; frozen vs breathing),
                                               PrimaryCoil (4 loops, fixed), SecondaryCoil (8 loops, fixed),
                                               InputLine (directional pulses tracking currentLevel sign),
                                               SourceDock (battery + flip anim + machine swap + grab hint),
                                               GraphStrip (strip chart + CURRENT eyebrow + 50-label),
                                               FlashLayer
widgets/energy_field_background.dart   (~100) — copy-adapt of the static dark vignette variant
```

Shared imports only: episode_board (strip/capture/snapshot), collectibles (overlay + card const), careerTheme, google_fonts. No edits outside this directory.

## 16. Scene sketch (portrait, factors of stage size w×h)

```
y 0.04–0.16  OUTPUT BULB: center (0.50w, 0.10h), shared paintBulb language; warm bloom
             scales with bulbBrightness; SNAPS off (the aliveness readout)
y 0.16–0.30  OUTPUT LINE: secondary top (0.62w, 0.34h) → bulb base; kick-gated pulses,
             cool blue #3FB9F5
y 0.30–0.58  THE TRANSFORMER (hero): core = upright rounded ring, center (0.50w, 0.44h),
             outer ~0.44w × 0.26h, limb thickness 0.05w; amber field ribbon (BlendMode.plus),
             intensity/breath = fieldLevel/fieldRate — FROZEN solid on steady feed;
             PRIMARY coil = 4 fixed loops LEFT limb; SECONDARY = 8 fixed loops RIGHT limb;
             vignette darkest here; nothing on the device ever moves
y 0.58–0.74  INPUT LINE: dock top (0.50w, 0.76h) → primary bottom (0.38w, 0.58h);
             directional pulses follow sign(currentLevel) — visibly reverse on every flip
y 0.74–0.86  SOURCE DOCK (the one gesture surface): dark-glass bay centered (0.50w, 0.80h);
             battery ~0.20w × 0.09h with visible +/− ends, 180° flipT rotation, grab hint;
             machine source slides in at handoff (same footprint, no label/icon)
y 0.86–0.97  GRAPH STRIP (tiny): dark glass, x 0.06–0.94w, height ~0.09h; centerline zero;
             mono micro-eyebrow CURRENT; trace = graphSamples (flat / steps / wave);
             50 CYCLES / SEC mono label fades in top-right of the strip during alive
```

Flow reads bottom (source) → core → top (bulb): the same vertical source-to-light chain as trace_it_back, so the felt grammar carries over. All anchors live in `AcdcTune`; no fixed pixels.
