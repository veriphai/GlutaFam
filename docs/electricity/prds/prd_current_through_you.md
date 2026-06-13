# PRD — Why Bother Stepping Down: Current Through YOU (EP3 beat 3.2)
### howwow · Episode 3 "Into Your House (Without Getting Hurt)" · registry id `current_through_you` · `CurrentThroughYouScreen` · evidence episode `episode3_electricity`

Working title: **Current Through You.** Complies with `docs/electricity/context_pack.md` (the covenant), `docs/electricity/architecture_reference.md`, curriculum §1–§9 + §3.2 + §13, and the locked EP3 CER catalog (`prd_make_your_case_ep3.md` §3, which OWNS this beat's evidence id, label, caption, and capture frame — reconciled below). No mascot, no Voltix, no info-cards; one voice = the on-screen text in two registers (imperatives + meaning-lines). Register note: this is the beat most easily mishandled — the register is **calm, grave honesty**: managed danger, never fear-mongering, never gore, never false reassurance. This PRD is self-contained: every on-screen line is quoted verbatim here.

---

## 1. One-concept statement

**It is CURRENT through the body that harms — high voltage drives dangerous current; stepping down makes the supply MANAGEABLE, not harmless.**

A single idea, no "and": the harm is the current; the current is set by the voltage across a roughly-fixed body resistance (the quiet mirror of 2.1); so a lower voltage means a manageable current, low enough for insulation and safety systems to contain — but 230V still drives current past the danger line, so "manageable" is not "safe to grab."

## 2. Guiding-question link + CER contribution

Episode question (pinned on the board strip all activity, verbatim, defined once as `kEpisode3Question` by the EP3 CER catalog):
> **"The power reaches your town still at lethal transmission voltage — how does it get into your house without killing you?"**

- **Inherits:** 3.1 — supply steps down in stages to 230V AC at the socket (the distribution grid). EP2 2.1 — voltage drives current through a fixed wire (`current = voltage ÷ resistance`); this beat reuses that exact law with the body as the resistor (named in one callback line, never re-derived). The learner already owns "voltage," "current," and "resistance" from EP2.
- **Pins (held constant, visibly):** the **body's resistance** — drawn as a fixed badge on the figure-as-instrument (mono chip `BODY R · FIXED`), never shown as a number; CURRENT tracks VOLTAGE in strict lockstep, which IS the felt proof that the only thing the learner changes is the voltage. The danger bands on the meter are fixed and labelled; they never move.
- **Sets up:** 3.3 (current crosses a body only across a potential difference — WHEN this current can flow at all) and 3.5 (earthing routes that current away from the body). This beat establishes WHY the level had to come down; 3.3 establishes WHEN it crosses you; 3.5 establishes the escape route.
- **CER contribution — exactly 1 RELEVANT tile, no distractor from this beat.** `socket_not_harmless` (id, label, caption LOCKED by the EP3 CER catalog) is core to the episode claim *managed danger: staged step-down (3.1) + contain (3.4) + escape route (3.5)*: it carries the "why management is needed at all, and why it is never harmless" leg. The episode's exactly-2 distractors are owned and sourced elsewhere (`fewer_turns_out` from 3.1, `water_carries` from 3.4) — **this beat produces no distractor.** *(Reconciliation note: an earlier draft proposed a second tile `transmission_off_scale` from this beat; the EP3 CER catalog DROPPED it as redundant — same instrument, same idea — so this PRD captures only `socket_not_harmless`. Do not wire `transmission_off_scale`.)*

## 3. The felt discovery (discovery → reaction)

The interaction IS the concept: an **abstract body-as-resistor in a circuit** — two glowing contact dots on a neutral standing figure, a voltage column the learner raises, and a **vertical CURRENT meter with fixed, labelled danger bands** that the current dot climbs. Never gore, never a person being hurt: the figure is an instrument, the dots are the contacts, the meter is the reading.

- **Discovery 1 (the law, felt):** the learner raises the voltage column → *reaction, same frame:* the current dot climbs the banded meter, a thin current channel lights between the two body-dots, and two numbers rise together at different scales. Voltage up, current up — through a body whose `BODY R · FIXED` badge never changes. The relationship is the same one from 2.1, now with a body in the gap.
- **Discovery 2 (the harm is the current, witnessed by the bands):** as the dot climbs, it crosses fixed labelled thresholds — `BARELY FELT` → `CAN'T LET GO` → `HEART STOPS`. At `CAN'T LET GO` the body-dots latch with a low judder and the channel will not release (the let-go muscles seized — felt, not narrated); the meter is the readout, not a stat. It is the dot's HEIGHT on the bands — the current — that names the danger, never the voltage number.
- **Discovery 3 (THE discovery — why we step down):** two fixed markers sit on the voltage column: a high `LINE` marker (transmission level, at the top) and a `SOCKET` marker (230V, near 70%). Dragging the column up to `LINE` slams the current dot far ABOVE every band — off the scale, hard flash. Then the learner drags down to the `SOCKET` marker → *reaction:* the dot drops a long way down the meter — but it still sits ABOVE the bottom of `CAN'T LET GO`. Stepping down moved the current from off-the-scale to a level insulation can contain — and yet 230V is still past the let-go line. **Managed, not harmless** is something the learner SEES on the meter, not a sentence they are told.
- **Honest nuance (felt by a toggle, not a lecture):** a single `WET SKIN` toggle drops the body badge (resistance falls), and at the SAME socket voltage the current dot jumps up into a worse band. The pin was held only for this experiment; in real life wet skin lowers body resistance sharply and lets far more current through — which is exactly why electricity near water is dangerous.

## 4. Felt vs named vs numbered

- **Felt:** the current dot climbing the vertical meter; the three fixed labelled danger bands it crosses; the body-channel between the two contact dots, intensity ∝ current; the `CAN'T LET GO` latch-judder (the seized-muscle felt-event); the dot punching OFF-SCALE at the `LINE` marker (hard flash); the long drop to `SOCKET` that still lands above the let-go line; the `WET SKIN` jump at the same voltage; the fixed `BODY R · FIXED` badge that never moves while the column does.
- **Named (a beat after felt / objects on sight):** the two markers `LINE` and `SOCKET` are labelled on sight (positions on the column). The body's resistance is named (`BODY R · FIXED`) but never numbered. "Current," "voltage," "resistance" already owned — the LAW (`current = voltage ÷ body resistance`) lands as a meaning-line only after the climb is felt; the word "manageable" lands only after the LINE→SOCKET drop is seen. No depth-stop in this beat — the law is Ohm applied, fully explained; the strings "nobody"/"no one knows" never appear.
- **Numbered (live, relative, ≤2 at a time):** chip 1 `VOLTAGE 0–100` (relative — the column you raise; the `SOCKET` marker sits at ≈70, the `LINE` marker at 100). Chip 2 `CURRENT 0–100` on the meter (relative; fixed ratio to voltage so the two chips never display the same value at dry resistance — the lockstep IS the fixed-R pin). The band thresholds are positions on the meter, not extra numbers. The intermediate fact ("230 volts") lives inside a meaning-line, never as a third chip. **No ratings table; no number for any qualitative judgment** (danger, "manageable," "harmless" are felt via the bands, never scored). **No absolute volts on a chip** — `VOLTAGE` stays relative; "230 volts" appears only inside a meaning-line, matching 3.1's discipline.

## 5. On-screen text — EXACT, beat by beat

Imperatives = Bricolage Grotesque large, Title Case, ≤5 words; meaning-lines = Plus Jakarta Sans (short ones Title Case, long ones sentence case at the smaller size). Swap = 190 ms fade-out → swap → fade-in. Meaning-lines are general facts (state-independent) so free play during auto-naming never contradicts the text.

| # | Beat | Register | Line (verbatim) | Trigger |
|---|---|---|---|---|
| T1 | intro | imperative | `Raise the Voltage` | entry, after entrance reveals (1000 ms) |
| T2 | climb | imperative | `Higher — Watch the Current` | first frame VOLTAGE ≥ 25 |
| T3 | bandCross | meaning | `It Is the Current That Harms` | first frame the dot enters `CAN'T LET GO` |
| T4 | bandCross (long) | meaning | `The voltage across you sets the current through you — and your body's resistance barely changes.` | 2200 ms after T3 |
| T5 | toLine | imperative | `Take It to the Line` | 2400 ms after T4 (the `LINE` marker pulses) |
| T6 | offScale | meaning | `At transmission voltage, the current is off the scale — no house could contain it.` | the off-scale flash frame at the `LINE` marker |
| T7 | toSocket | imperative | `Now Drop It to the Socket` | 2200 ms after T6 (the `SOCKET` marker pulses) |
| T8 | atSocket | meaning | `Stepped down to 230 volts, the current is manageable — low enough for insulation to contain.` | the frame the dot settles at the `SOCKET` marker |
| T9 | atSocket (long) | meaning | `Manageable is not harmless — 230 volts still drives current past the let-go line. It can still kill.` | 2400 ms after T8 |
| T10 | wetSkin | imperative | `Wet the Skin` | 2600 ms after T9 (the `WET SKIN` toggle reveals) |
| T11 | wetSkin (long) | meaning | `Wet skin lowers your resistance, so the same voltage drives far more current — which is why water near electricity is so dangerous.` | the toggle-on frame (current jumps to a worse band) |
| T12 | synthesis (long) | meaning | `Stepping down does not make the supply safe to touch. It makes it manageable — a current insulation and earthing can keep off you.` | 3000 ms after the toggle auto-resets (synthesis) |

Rules check: every imperative ≤5 words; T3/T6/T8 name the consequence/destination, not the behaviour (the current "harms", is "off the scale", is "manageable" — never "the dot goes up"); no rhyme; no narration-to-a-child; no analogy at all (none needed — the law is shown directly); the depth-stop strings "nobody"/"no one knows" never appear (this beat is fully explained). No card brag string (no card — §8). Header title: `Current Through You`; mono eyebrow subtitle: `EPISODE 3 · HOME & SAFETY`. Chip labels: `VOLTAGE`, `CURRENT`. Scene labels: `BODY R · FIXED`, `BODY R · LOW`, `LINE`, `SOCKET`, `WET SKIN`; band labels: `BARELY FELT`, `CAN'T LET GO`, `HEART STOPS`. No other text exists in the activity.

## 6. Beat-by-beat flow (timing + gating)

Text swaps use the shipped 190 ms fade-out → swap → fade-in. Interaction is locked only during the brief off-scale and toggle-jump flash frames; otherwise the column is live. Straight-through play length ≈ 75–120 s.

1. **Intro (0–1000 ms):** entrance reveals (slide+scale+fade) — the meter column + three labelled bands fade in (0→400 ms), the standing figure-as-instrument with two contact dots and the `BODY R · FIXED` badge (150→650 ms), the voltage column at the bottom with `LINE`/`SOCKET` markers drawn but unlit (300→750 ms). Chips hidden, current dot at 0. T1 at 1000 ms. Column live immediately — a learner who grabs early skips nothing.
2. **The climb (learner-paced):** drag the column up. Same frame: `current = ratio × voltage` (dry ratio ≈ 0.9 so the dot can punch off-scale at LINE); the current dot climbs the meter; the body-channel between the two dots lights ∝ current; chips reveal and tick. First frame VOLTAGE ≥ 25 → T2 + `selectionClick`. `selectionClick` at every 10-unit detent of the column.
3. **Band crossing (gate: dot enters `CAN'T LET GO`):** as the dot rises past `BARELY FELT` (band 1 top) into `CAN'T LET GO`, same frame: the two body-dots latch with a low 120 ms judder, the channel saturates and will not dim below a floor until voltage drops back under the band-1 top (the seized let-go muscles — felt), `mediumImpact`; T3. At `HEART STOPS` (top band) the channel pulses a grave slow throb (no gore, no figure animation). T4 at +2200 ms.
4. **THE OFF-SCALE (gate: column reaches the `LINE` marker) — DISCOVERY + CAPTURE:** T5 at +2400 ms; the `LINE` marker (top of column) pulses. When the column reaches LINE: the current dot drives to the TOP of the meter and **punches off-scale** — a clamp arrow above the top band, the whole meter flashes (≈500 ms envelope), `heavyImpact`. **This is the §6.4 discovery frame named by the EP3 CER catalog: dot above the bands, SOCKET marker engaged in frame, flash live → `onCapture('socket_not_harmless')`** (lightImpact via the capture path) — see §9 for why the capture frame keeps the SOCKET marker visible. T6 at the flash frame.
5. **THE DROP (gate: column reaches the `SOCKET` marker):** T7 at +2200 ms; the `SOCKET` marker (≈70% of the column) pulses. When the column drops to SOCKET: the current dot settles a long way down the meter — but visibly ABOVE the bottom of `CAN'T LET GO` (it must NOT fall into `BARELY FELT`). `selectionClick` at the settle. T8 at the settle frame; T9 at +2400 ms.
6. **The wet-skin honesty (gate: toggle on):** T10 at +2600 ms; the `WET SKIN` toggle reveals beside the body badge. Toggling ON: `BODY R · FIXED` dims to `BODY R · LOW` (the only time the badge changes), and at the SAME socket voltage the current dot jumps up two bands into worse territory (reaching `HEART STOPS`), brief flash (≈400 ms), `mediumImpact`; T11 at the jump frame. The toggle auto-resets after 2200 ms (badge returns to `BODY R · FIXED`, dot drops back) — a felt one-shot, not a persistent state.
7. **Synthesis (auto; column stays live):** T12 at +3000 ms after the toggle reset. All lines are general facts, so free play (re-raising the column) never contradicts them.
8. **Close → Continue (NO card):** +2800 ms after T12 → `canFinish = true`, the Continue CTA appears in its fixed seat. Column, dots, and toggle stay live for free play. Continue → `Navigator.maybePop(context)` (any pop = completion; no payload).

Reversibility: the column is always reversible; the band-cross latch releases the frame voltage drops below the `CAN'T LET GO` floor (contact never "breaks" — the body stays in circuit; only the current changes); the wet-skin toggle is a momentary one-shot. Phases never regress; the single capture and the one-shot lines latch (idempotent).

## 7. Hero & layout (with clutter caps)

- **The hero:** the **current dot climbing the banded danger meter**, with the body-channel between the two contact dots — the brightest, most-alive thing on screen. The off-scale punch at LINE and the long drop to SOCKET own the frame. The meter is large and central; the bands are read at a glance.
- **What recedes:** near-black `#070A1C` base; radial vignette darkest behind the meter; whisper-faint circuit texture ~5% alpha; the standing figure is a recessive neutral steel silhouette (an instrument, never a character); the voltage column in cool transmission blue `#3FB9F5` (clearly the control, never outglowing the meter); chips on glass `0x14FFFFFF` / borders `0x26FFFFFF`; 16–20 ambient cool motes. Band fills: `BARELY FELT` cool/neutral, `CAN'T LET GO` amber `#FFB347`, `HEART STOPS` band red `#FF6259` — the current dot and channel use the same heat ramp as the dot climbs.
- **Portrait layout (top→bottom):** header → `EpisodeBoardStrip` (EP3 question) → instruction banner (fixed h 96, 190 ms fade-swap) → stage (CURRENT meter with three bands occupying the center-right vertical; the figure-as-instrument center-left with two contact dots + `BODY R · FIXED` badge + `WET SKIN` toggle; chips top-right; the VOLTAGE column with `LINE`/`SOCKET` markers along the bottom) → fixed-height CTA seat (84).
- **Clutter caps (hard):** 1 hero; **3 interactive elements** (voltage column, `WET SKIN` toggle, back button) + Continue = 4 ≤6 ✓; **exactly 2 live numbers** (`VOLTAGE`, `CURRENT`); static word labels only (`BODY R · FIXED`, `LINE`, `SOCKET`, `WET SKIN`, three band names); the current text line. Nothing else. No scenery, no sky, no gore, no second figure. The band thresholds are NOT numbers.

## 8. Reward

**No card.** Argued: the curriculum quick-reference table (§ "terms and where they're introduced") has NO row for this beat. The harm-from-current law is **Ohm applied to the body** — the same law whose card is earned at 2.1 ("voltage / current") and whose "difference between two points" refinement earns the card at 3.3 ("potential difference"). The beat note states it plainly: "the law is Ohm applied; argue it if you disagree — likely No card." A card here would restate 2.1's law in a grim new costume, which context-pack §6 forbids ("No card may restate another card's law"). The EP3 distribution-grid card is earned at 3.1 (`stepping_down`); the potential-difference card at 3.3 (`bird_on_the_wire`); the EP3 synthesis card at the CER. This beat's payoff is the FELT meter and its evidence tile, not a collectible.

**Inline fact: none** — a deliberate empty slot. The wet-skin honesty already carries a surprising, specific real-world truth in the flow (T11); any inline fact would either restate the lesson or pre-spoil 3.3/3.5.

## 9. CER capture hook

`RepaintBoundary(key: _sceneKey)` around the scene (background + stage only; banner/CTA excluded); `controller.onCapture = _onCapture` → `captureScenePng(_sceneKey, cropFactor: evidenceByIdFor('episode3_electricity', id)?.cropFactor)` → `_board.capture(id, imageBytes: bytes)`; `lightImpact` in `_onCapture`; `EpisodeBoardStrip` pinned under the header with the EP3 question all activity. Single capture, idempotent.

| id | label (≤3 words) | caption (one line) | flag | fires |
|---|---|---|---|---|
| `socket_not_harmless` | Socket Not Harmless | Stepped-down socket voltage still drives current past the danger bands. | **relevant** | `offScale` §6.4 — the discovery frame: current dot driven above the top band (off-scale clamp), the `SOCKET` marker visible in the column, meter flash live |

Locked by the EP3 CER catalog (`prd_make_your_case_ep3.md` §3, tile #2): id, label, caption, `relevant: true`, source `ACT 2`, accent `#FF6259`, motif `socketNotHarmless` (a slim vertical band meter, three stacked bands, a hot dot ABOVE the third band, plus a marker notch at ~70% on a column beside it — the fallback art matches this scene), cropFactor `(0.30, 0.06, 1.0, 0.92)` (meter + bands + column). The capture composition deliberately frames BOTH the off-scale dot AND the `SOCKET` marker at ≈70% in one shot, so the single tile reads as "even past the socket marker this is above the bands" — the catalog's intent. No `transmission_off_scale` tile (dropped by the catalog as redundant). Crop is owned by the catalog; do not re-tune locally.

## 10. Build notes

- **Rendering: plain `CustomPainter` + Ticker** — the same single-precision instrument pattern as `voltage_and_current` (2.1) and `bird_on_the_wire` (3.3). One diagram scene, one column drag, one toggle, a deterministic climbing dot + banded meter — Flame would be overhead. **No Forge2D** (motion is controlled; every cutoff/jump is a hard gate in `tick`, never decay/momentum).
- **Controller-owns-geometry:** `CtyController extends ChangeNotifier`; `setStageSize(size)` once per paint; ALL anchors = factor × stage size (`CtyTune`, per §16). Hit-testing for the column drag and the toggle lives in the controller with generous slop (column ≥0.10w, toggle ≥0.06w).
- **The law:** `current = ratio × voltage` with `ratio = dryRatio (≈0.9)` when dry, `wetRatio (≈1.6, clamped to off-scale)` when the toggle is on. `BODY R · FIXED` is the visible held-constant; the badge is the ONLY thing that changes (to `BODY R · LOW`) during the momentary wet-skin toggle. The lockstep (current strictly proportional to voltage) is the felt fixed-R proof and must read every frame.
- **The meter + bands:** a vertical track; band boundaries are fixed factors of track height (`kBand1Top`, `kBand2Top`); the `SOCKET` marker maps to ≈70% of the VOLTAGE column and its resulting dry current lands visibly inside `CAN'T LET GO` (above `kBand1Top`, below `kBand2Top`); the `LINE` marker maps to 100% and its current clamps OFF-SCALE above the track. The off-scale clamp is a hard cap with an arrow glyph, never a value that keeps rising past the frame.
- **The body channel:** 2–3 jittered additive (`BlendMode.plus`) polyline strands between the two contact dots through the figure, intensity + jitter ∝ current; at the `CAN'T LET GO` latch the strands gain a low judder and a brightness floor (the seize); never any skeleton flash, scream, convulsion, or X-eyes — the figure is a neutral instrument silhouette. Register: grave, factual, 12–80; the danger is honest, never morbid or comic.
- **Numbers:** `displayVoltage = round(voltage)`, `displayCurrent = round(min(current, 100))` (off-scale shows `100+` or a clamp glyph, never a runaway number); integer, updated every frame; mono chips (IBM Plex Mono), painted inside the painter so captures include them and anchors stay factor-based.
- **Haptics:** `selectionClick` per 10-unit column detent and at the SOCKET settle; `mediumImpact` at the `CAN'T LET GO` band entry and the wet-skin jump; `heavyImpact` at the off-scale punch (THE discovery); `lightImpact` on the capture; (no card overlay, so no medium-in-overlay).
- **Audio:** silent (matches most shipped electricity activities). Open decision §13 for an optional low hum ∝ current.
- `MediaQuery(...textScaler: TextScaler.noScaling)` wrapper; `reducedMotion` from `MediaQuery.disableAnimations` → calm motes, fade-style reveals, shorter flash envelopes — **but the off-scale punch, the band-entry latch, and the wet-skin jump stay instant** (pedagogical hard gates, never softened).
- **File-surface rule:** write ONLY inside `lib/screens/missions/current_through_you/`. The registry entry, the EP3 evidence catalog (`kEpisode3Evidence`, `kEpisode3Id`, `kEpisode3Question`, the `socket_not_harmless` tile + `socketNotHarmless` motif painter) are owned by other phases — code against the names; report if missing; never edit shared files.
- **Verify:** `fvm dart analyze lib/screens/missions/current_through_you` clean (the repo's ~468 pre-existing errors are not yours; never run repo-wide multi-path analyze).

## 11. Acceptance criteria (pedagogy as testable checks)

1. **Discoverable from interaction alone:** with all top-text suppressed (debug flag), a fresh user can read the concept — raise voltage → current dot climbs the bands and the body-channel brightens; at `CAN'T LET GO` the dots latch; at the `LINE` marker the dot punches off-scale; dragging to the `SOCKET` marker drops it a long way but visibly still above the let-go line; `WET SKIN` jumps it up at the same voltage. The concept reads without reading.
2. **The harm is the CURRENT, not the voltage number:** the band the dot occupies (its height/current) is what changes the scene — the latch, the saturated channel, the throb — never the voltage number alone. Test: at a low voltage that yields a high current under `WET SKIN`, the danger reads worse than a higher dry voltage that yields a lower current.
3. **Held-constant visible:** `BODY R · FIXED` is pinned and never changes EXCEPT during the momentary `WET SKIN` toggle (→ `BODY R · LOW`, then auto-reverts); CURRENT and VOLTAGE move in strict lockstep at dry resistance (the fixed-R pin) and never display the same value.
4. **Managed-not-harmless is SEEN, not told:** at the `SOCKET` marker the current dot settles strictly ABOVE the bottom of `CAN'T LET GO` and strictly BELOW the off-scale clamp — it must NOT fall into `BARELY FELT` and must NOT reach `HEART STOPS` at rest. Test the SOCKET-marker frame directly.
5. **Off-scale is a hard gate:** at the `LINE` marker the current dot reaches the off-scale clamp in ≤1 frame (no fade-in), with the flash; the displayed CURRENT never runs past the frame as a growing number (clamped). Reduced motion does not soften the punch.
6. **Felt consequence in the scene, not a stat:** no danger meter percentage, no "lethality: N%", no warning popup, no red ✗; the bands + dot + channel + latch ARE the readout; the chips ride alongside and never replace them.
7. **≤2 live numbers** (`VOLTAGE`, `CURRENT`), both relative; band thresholds are positions, not numbers; "230 volts" appears only inside T8 (and the let-go honesty in T9), never on a chip; no ratings table anywhere.
8. **Wet-skin honesty present and felt:** the `WET SKIN` toggle drops resistance and raises current at the same voltage (T11 fires on the jump); it is a momentary one-shot that auto-resets, so the held-constant pin is restored for the rest of the activity.
9. **No depth-stop language:** the strings "nobody", "no one knows", "no deeper" never appear; the law is stated as fully explained (`current = voltage ÷ body resistance`), with no analogy.
10. **Register — grave, never morbid or comic:** the figure is a neutral steel instrument silhouette; no skeleton flash, scream, convulsion, X-eyes, blood, or cartoon shock; the `HEART STOPS` band is a band label and a grave channel throb only — no animated harm to a person.
11. **No card:** no `CollectibleEarnOverlay` is shown; the close goes meaning-line → Continue → `Navigator.maybePop`; no card constant is referenced.
12. **Capture:** exactly one, id `socket_not_harmless`, at the §6.4 off-scale discovery frame (dot above the bands, SOCKET marker in frame, flash live), idempotent, with `lightImpact`; the board strip shows the EP3 question throughout.
13. **Completion contract:** Continue → `Navigator.maybePop`; `const CurrentThroughYouScreen()` constructible with no arguments; the screen wraps in `MediaQuery(...textScaler: TextScaler.noScaling)`.
14. Imperatives ≤5 words; meaning-lines match §5 verbatim; no rhyme; analyzer clean on the activity dir; straight-through run 75–120 s on device; small-phone (360×640 logical) layout sane (meter, figure, and column do not collide; chips do not overlap the meter top).

## 12. Anti-patterns (this activity)

- **A separate danger stat** — the banded CURRENT meter IS the felt consequence (the dot's band is the harm); what is banned is a *separate* "danger %", "lethality", or "safety score" number layered on top. The bands are felt thresholds, never a rating.
- **Gore or a person being hurt** — the figure is an instrument; no skeleton flash, no convulsion, no scream, no X-eyes, no blood, no cartoon zap. The beat note is explicit: tasteful, abstract body-as-resistor, never gruesome.
- **Pre-spoiling 3.3 (potential difference) or 3.5 (earthing):** no "you need a difference across you" or "earthing saves you" text — this beat owns only "current through a fixed-R body harms; step-down makes it manageable." 3.3 owns WHEN the current can flow; 3.5 owns the escape route.
- **An absolute-volts chip** — `VOLTAGE` stays relative (0–100); "230 volts" lives only in T8/T9 meaning-lines (3.1's discipline).
- **A premium fade softening the off-scale punch, the band-entry latch, or the wet-skin jump** — all three are hard gates.
- **"Safe" framing** — the activity must never imply 230V is safe to touch; T9 ("manageable is not harmless… can still kill") is mandatory and the SOCKET-marker current must sit above the let-go line (AC4).
- **A second figure, scenery, or a transmission-line scene** — 3.1 owns the step-down route; this beat is the instrument only. Do not import the route or re-teach staging.
- **Restating 2.1's law as a new card** — No card (§8); the callback line is the only voltage/current text, and it does not re-derive Ohm.
- **Capturing `transmission_off_scale`** — the EP3 CER catalog dropped it; capture only `socket_not_harmless`.
- **Drag ergonomics as the struggle** — generous slop and detents; any difficulty must be conceptual (where on the bands the current lands), never motor.
- **Editing `activityRegistry.dart`, evidence catalogs, `collectible_models.dart`, or wowConcepts from the build agent.**

## 13. Open decisions

1. **Dry/wet ratios:** `dryRatio ≈ 0.9` (so LINE → off-scale, SOCKET → mid-`CAN'T LET GO`) and `wetRatio ≈ 1.6` (clamped). Tunable in `CtyTune`; constraints: at SOCKET the dry dot must land strictly inside `CAN'T LET GO` (AC4); at LINE the dry dot must clamp off-scale; wet at SOCKET must reach `HEART STOPS`. Verify on device.
2. **Band boundary factors** (`kBand1Top`, `kBand2Top` on the meter track) and the `SOCKET`/`LINE` marker positions on the column — propose `SOCKET ≈ 0.70`, `LINE = 1.00`; tune so the felt geometry of AC4 holds at 360×640.
3. **Wet-skin toggle persistence:** specced as a momentary one-shot (auto-reset after 2200 ms) so the held-constant pin is restored. Alternative: a sticky toggle the learner can leave on — rejected (it would muddy the held-constant proof for the rest of free play); confirm the one-shot reads clearly.
4. **`CAN'T LET GO` latch:** specced — the body-dots judder and the channel floors until voltage drops below band 1 top. Alternative: a purely visual throb with no latch — propose the latch (it makes "the muscles you'd use to let go" felt, not narrated); verify it never reads as a stuck UI.
5. **Optional low hum ∝ current (vol ≤ 0.2):** propose shipping silent; flag for polish.
6. **Board-strip question string:** use the shared `kEpisode3Question` constant; final phrasing owned by the EP3 CER catalog.
7. **Capture crop:** `(0.30, 0.06, 1.0, 0.92)` is catalog-owned; do not re-tune locally — flagged only so the build agent knows it is fixed.

## 14. State machine sketch

```dart
enum CtyPhase {
  intro, climb, bandCross, toLine, offScale, toSocket,
  atSocket, wetSkin, synthesis, done,
}

class CurrentThroughYouController extends ChangeNotifier {
  // ValueNotifiers (discrete UI channels)
  final phase         = ValueNotifier<CtyPhase>(CtyPhase.intro);
  final caption       = ValueNotifier<CtyCaption?>(null);  // carries register flag (imperative/meaning/long)
  final lineReached   = ValueNotifier<bool>(false);        // dot punched off-scale at LINE marker
  final socketSettled = ValueNotifier<bool>(false);        // dot settled at SOCKET marker
  final wetSkinOn     = ValueNotifier<bool>(false);        // momentary toggle state
  final canFinish     = ValueNotifier<bool>(false);        // Continue CTA gate (NO card)

  // Hot-path getters (read by the painter; updated in tick() via Ticker)
  double  voltage;        // 0..100, driven by the column drag (the only level control)
  double  current;        // = ratio * voltage; ratio = dry/wet; display CLAMPED at 100, off-scale flag above
  bool    offScale;       // current beyond the top band (LINE marker) — hard clamp + arrow
  int     band;           // 0 barelyFelt / 1 cantLetGo / 2 heartStops (by dot height)
  bool    letGoLatched;   // true while band>=1 (dots judder, channel floored)
  double  channelGlow;    // body-channel intensity ∝ current (additive)
  double  judderPhase;    // CAN'T LET GO latch judder (0 when band<1)
  double  dotY;           // current dot position on the meter track (factor)
  double  flashIntensity; // off-scale / band-entry / wet-jump envelopes (0.4–0.7 s)
  double  bodyR;          // 1.0 fixed, drops during wetSkinOn (badge text is the only visible change)
  double  meterReveal, figureReveal, columnReveal, toggleReveal; // entrance reveals

  // Input: a Flutter Listener forwards pointers. Down: grab column if within slop, or hit
  // the WET SKIN toggle. Move: map pointer.y -> voltage (clamped 0..100), snap-assist near
  // the SOCKET and LINE markers. Up: release (no momentum). Toggle: flips wetSkinOn and
  // schedules auto-reset. No other interactive targets exist.
  void onPointerDown/Move/Up(Offset local);
  void toggleWetSkin();

  // Timers: _schedule(ms, fn), cancel-on-dispose, per §6.
  // Gates: climb->bandCross on (band>=1 first time); offScale capture on (voltage at LINE
  //   marker first time) -> onCapture('socket_not_harmless'); atSocket on (voltage at SOCKET
  //   marker after offScale); wetSkin line on (toggle on); synthesis timer-driven; canFinish
  //   set after T12 dwell. Phases never regress; capture + one-shot lines latch (idempotent).
  // Hooks: onCapture(String id) [lightImpact]; onOffScale [heavyImpact]; onBandEnter /
  //   onWetJump [mediumImpact]; onDetent / onSocketSettle [selectionClick].
  void tick(double dt); // hard-gates off-scale clamp, band latch, wet jump; clamps current display
}
```

Timers (ms): intro→T1 1000 · climb T2 on V≥25 · bandCross T3 on band-1 entry, T4 +2200 · toLine T5 +2400 (LINE pulse), offScale T6 on punch + capture · toSocket T7 +2200 (SOCKET pulse), atSocket T8 on settle, T9 +2400 · wetSkin T10 +2600 (toggle reveal), T11 on jump, auto-reset +2200 · synthesis T12 +3000 → canFinish +2800.

## 15. File plan — `lib/screens/missions/current_through_you/`

```
current_through_you_screen.dart        (~320) — shell: noScaling MediaQuery, Ticker, header (back on
                                                glass; title 'Current Through You' + mono eyebrow
                                                'EPISODE 3 · HOME & SAFETY'), EpisodeBoardStrip
                                                (kEpisode3Question), instruction banner (h 96, 190 ms
                                                fade-swap), RepaintBoundary[background + stage],
                                                fixed CTA seat (h 84, NO CollectibleEarnOverlay),
                                                capture wiring (§9). Continue → Navigator.maybePop.
state/cty_controller.dart              (~360) — CurrentThroughYouController per §14 (Ohm law, meter/band
                                                math, phase machine, timers, gates, drag + toggle
                                                mapping, hooks, hard gates)
config/cty_config.dart                 (~110) — CtyTune: geometry factors (§16), dryRatio/wetRatio,
                                                kBand1Top/kBand2Top, SOCKET/LINE marker positions,
                                                detent size, snap-assist zones, timing constants (ms),
                                                flash envelopes, palette tokens (band fills, channel
                                                heat ramp, column blue)
config/cty_copy.dart                   (~70)  — CtyCaption enum (text + register flags) + CtyCopy:
                                                T1–T12 verbatim, chip labels 'VOLTAGE'/'CURRENT',
                                                scene labels 'BODY R · FIXED'/'BODY R · LOW'/'LINE'/
                                                'SOCKET'/'WET SKIN', band names 'BARELY FELT'/
                                                "CAN'T LET GO"/'HEART STOPS'
widgets/cty_stage.dart                 (~40)  — Listener + CustomPaint(painter: CtyStagePainter(
                                                controller), repaint: controller); forwards pointers
widgets/cty_stage_painter.dart         (~520) — pure renderer, back→front: vignette pool → ambient
                                                motes → meter track + three band fills + band labels →
                                                figure-as-instrument silhouette + two contact dots +
                                                BODY R badge + WET SKIN toggle → body-channel (additive
                                                strands, judder when latched) → current dot + off-scale
                                                clamp arrow → voltage column + LINE/SOCKET markers →
                                                VOLTAGE/CURRENT chips → discovery flash ring
widgets/energy_field_background.dart   (~100) — copied static dark vignette variant (shipped pattern)
```

Shared imports only: episode_board (strip/capture/snapshot), careerTheme, google_fonts. No `CollectibleEarnOverlay` import (no card). No edits outside this directory.

## 16. Scene sketch — portrait, factor-based (stage = w × h of the Expanded area)

```
y≈0.04–0.16h   CHIPS — top-right (right-aligned at 0.95w): mono 'VOLTAGE 62' stacked over
               'CURRENT 56', dark glass; CURRENT shows clamp glyph / '100+' when off-scale
y 0.10→0.78h   CURRENT METER — vertical track centred at x≈0.62w, width ≈0.12w; three stacked
               bands bottom→top: BARELY FELT (y 0.62→0.78, cool/neutral), CAN'T LET GO
               (y 0.40→0.62, amber #FFB347), HEART STOPS (y 0.10→0.40, band red #FF6259);
               band labels mono at the right edge of each band; the CURRENT DOT rides the
               track (bright, heat-ramped); an OFF-SCALE clamp arrow sits above y 0.10 (LINE level)
figure         FIGURE-AS-INSTRUMENT at x≈0.32w: neutral steel silhouette, head ≈0.18h, feet
               ≈0.74h; TWO CONTACT DOTS — hand-dot near the column reach (x 0.42w, y 0.46h)
               and feet-dot at base (x 0.32w, y 0.74h); BODY-CHANNEL strands run dot→body→dot,
               additive, intensity ∝ current, judder when latched
               BODY R badge: mono 'BODY R · FIXED' chip at (0.18w, 0.40h) on the figure's torso
               WET SKIN toggle: small pill at (0.18w, 0.58h), revealed at beat 6
y 0.80→0.94h   VOLTAGE COLUMN — vertical slider whose level the LEARNER drags 0→100, centred
               at x≈0.50w, drawn cool blue #3FB9F5; LINE marker at the top (level 100, mono
               'LINE'); SOCKET marker at ≈0.70 of the column (mono 'SOCKET'); detent ticks
               every 10
return wire    a thin circuit return drawn from the feet-dot to the column base (the body is in
               a complete loop — consistent with 2.1/3.3's complete-circuit model); faint, cool
ambient        16–20 cool drifting motes behind everything; vignette darkest behind the meter
```

Above the stage (Flutter chrome, outside the RepaintBoundary): header → `EpisodeBoardStrip` (EP3 question) → instruction banner (h 96). Below: the fixed CTA seat (h 84). Small-phone check: at 360×640 the meter (x 0.56→0.68w) must not collide with the figure's hand-dot (x 0.42w) or the chips (right-aligned 0.95w); the off-scale arrow must stay below the chips. All anchors live in `CtyTune`; no fixed pixels. The flow reads: the column you push (bottom) → through the fixed-R body (left) → the current that results, climbing the danger bands (center-right) — the layout IS `current = voltage ÷ body resistance`.
