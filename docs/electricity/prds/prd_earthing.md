# PRD — Earthing: A Deliberate Escape Route
### howwow · Episode 3 "Into Your House (Without Getting Hurt)" · beat 3.5 (synthesis) · registry id `earthing` · `EarthingScreen` · evidence episode `episode3_electricity`

Working title (header): **The Escape Route.** Complies with `docs/electricity/context_pack.md` (the covenant), `docs/electricity/architecture_reference.md`, curriculum §1–§9 + §13, and the locked EP3 evidence catalog defined by `prd_make_your_case_ep3.md` (the catalog owner — reconciled below). No mascot, no Voltix, no info-cards; one voice = on-screen text in two registers (imperatives + de-personified meaning-lines). Register: this is EP3's synthesis and its only *triumphant* beat — but the triumph is crisp engineered satisfaction (a safety system doing its job), never confetti-glee. The danger half inherits 3.2's calm, grave honesty and its tasteful body abstraction. **Fully explained — no depth-stop** (every part was earned in 3.2–3.4).

---

## 1. One-concept statement
**Earthing routes fault current safely to ground — and trips the fuse — instead of through a person.** One idea: hand the fault a deliberately easier route. The fuse blowing is that route's built-in consequence, not a second concept. (If it needed an "and", it would be two activities — it does not: the route *is* the fuse-trip's cause.)

## 2. Guiding-question link + CER contribution (incl. distractor flags)
- **Episode question (pinned on the board strip all activity, verbatim — the single `kEpisode3Question` constant):** `The power reaches your town still at lethal transmission voltage — how does it get into your house without killing you?`
- **Inherits (what the learner already felt):** 3.2 — it is *current through a body* that harms (current = voltage ÷ body resistance); stepped-down supply is *manageable, not harmless*. 3.3 — current flows only across a *potential difference*; ground is zero, and being connected to it is the danger; the body closes the loop. 3.4 — conductors carry (a metal case spreads a live touch to every inch); insulators block *passively*. 2.2 — resistance is set by a wire's shape (why the earth wire is deliberately thick = low resistance).
- **Pins (held constant, made visible):** **THE FAULT** — the same loose live wire stays sprung against the case in both halves, marked by a pinned `SAME FAULT` chip (the deliberate sibling of 2.1's `SAME WIRE` and 3.2's `SAME BODY`). **THE BODY** — same sign-figure, same spot, throughout. The only variable across the two halves is **the route** (through the body vs down the earth wire).
- **CER contribution — relevant, the episode claim's third clause.** The EP3 claim is *managed danger = staged step-down + contain + escape route*. 3.1 supplies "staged step-down", 3.4 supplies "contain"; **this beat supplies "escape route"** and the passive-vs-active synthesis that turns the three into one *system*. On the board this is the tile `surge_blows_fuse` (relevant), the ACT 5 clue, montage position 6 ("when containment fails, the earth wire takes the fault and the fuse cuts the power").
- **Distractor flags — none from this beat.** Per the EP3 catalog owner, this beat contributes exactly **one** relevant capture and **zero** distractors. EP3's two true-but-irrelevant distractors are sourced from earlier beats (`fewer_turns_out` from 3.1, `water_carries` from 3.4) — not this activity's concern.

## 3. The felt discovery (discovery → reaction)
The activity is one continuous safety experiment in four felt moments. The danger is witnessed FIRST, with no fix visible; then the learner builds the fix and watches the same fault drain harmlessly.

- **Discovery 1 — the fault.** The learner drags the frayed live wire end inside the appliance until it springs against the metal case → *reaction:* a spark snaps and the **whole case floods with live tint** — every inch, instantly. A conductor carries the fault everywhere (3.4, felt again). Irreversible.
- **Discovery 2 — the danger, witnessed.** Prompted, the learner presses the abstract body's hand to the case → *reaction:* a current **channel lights through the body to ground** (3.3's loop, felt again); the single meter shows a small trickle — and the fuse **does nothing**. The quiet, honest horror: a body-sized trickle is far below what a fuse notices, and more than enough to harm. Release → channel dies instantly (hard gate).
- **Discovery 3 — THE discovery (the `heavyImpact` moment).** The learner drags a thick earth wire from the case's lug down to the ground terminal → *reaction:* the instant it connects, fault current **abandons everything else and rushes down the thick wire** — the meter slams past the `FUSE LIMIT` mark — the fuse filament flares and **snaps**, and in the same frame the whole rig goes dead. The learner *built* the escape route; the system used it and slammed the door.
- **Discovery 4 — the proof (witnessed absence).** Prompted, the learner touches the case again → *reaction:* nothing. No channel, no trickle, meter at zero. The same gesture that lit a body now does nothing — that contrast is the payoff.

The interaction *is* the concept: the learner does not read "earthing routes the fault away"; they *route* it, by hand, and watch the fuse cut the power.

## 4. Felt vs named vs numbered
- **Felt (visual consequences):** the spark at the fault; the case's instant live flood; the channel glowing through the body; the silent, unmoved fuse during the body path; the surge packets racing down the earth wire; the filament flare → crack → dark window + smoke wisp; the same-frame death of every live visual; the dead second touch.
- **Named:** objects on sight (mono labels): `FUSE`, `LIVE` (on the cord), `GROUND` (on the earth band) from entry; `EARTH WIRE` tag the moment it connects. The *behaviour* is named only after it is felt: **earthing** lands at T13 — after the fault has drained and the fuse has blown — never before. "The third pin" lands in the same breath as earthing's real-world carrier.
- **Numbered (live, relative, ≤2):** exactly **one** live number — `FAULT CURRENT 0–100` (relative scale; ~3 through the body, ~100 down the earth wire, 0 after the blow). The meter carries two **word-labelled ticks** — `HARM` (low) and `FUSE LIMIT` (mid) — which are instrument markings, not numbers (3.2's labelled-band idiom). The geometry of those three positions *is* the honest insight: harm sits far below what a fuse notices. **No ratings table; no number for any qualitative judgment; no other numeral anywhere** (no amps, no mA, no "230").

## 5. On-screen text — EXACT, beat by beat
Imperatives = Bricolage Grotesque large (Title Case, ≤5 words); meaning-lines = Plus Jakarta Sans (short ones Title Case, long ones sentence case at the smaller size). Banner swap = 190 ms fade-out → swap → fade-in (never cross-fade).

| # | Register | Line (verbatim) | Trigger |
|---|---|---|---|
| T1 | meaning | `A metal-cased appliance, plugged in and running.` | entry, 700 ms after reveals start |
| T2 | imperative | `Pull the Live Wire Loose` | 2400 ms after T1 (or 1000 ms if drag already started) |
| T3 | meaning | `The Case Is Live` | the frame the frayed wire snaps to the case |
| T4 | meaning (long) | `The case is metal — a conductor. The loose live wire puts every inch of it at live voltage.` | 1800 ms after T3 |
| T5 | imperative | `Touch the Case` | 2600 ms after T4; touch zone arms |
| T6 | meaning (long) | `Hand at live, feet at ground — the difference drives current through the body, to ground.` | body contact sustained 600 ms |
| T7 | meaning (long) | `The fuse stays silent. A trickle this small is too little to blow it — and more than enough to harm.` | 2800 ms after T6 |
| T8 | imperative | `Connect the Case to Ground` | T7 shown ≥ 2600 ms && touch released; earth kit reveals |
| T9 | meaning | `The Surge Blows the Fuse` | the blow frame (THE discovery) |
| T10 | meaning (long) | `Fault current took the easier route — the thick earth wire, low resistance, straight to ground — not the body.` | 2600 ms after T9 |
| T11 | imperative | `Touch the Case Again` | 3200 ms after T10; touch zone re-arms |
| T12 | meaning | `The Case Is Dead` | proof contact sustained 900 ms |
| T13 | meaning (long) | `The blown fuse cut the supply — nothing is live until the fault is mended. A deliberate path to ground for fault current: this is earthing. The third pin on a plug carries this wire.` | 1200 ms after proof release |
| T14 | meaning (long) | `Insulators block danger passively. Earthing hands fault current an escape route on purpose — and the surge trips the fuse, cutting the power.` | 4200 ms after T13 (synthesis) |

In-scene instrument text (mono caps, painted into the scene so captures include it): `FUSE` (entry), `LIVE` (entry, on the cord), `GROUND` (entry, on the earth band), `HARM` + `FUSE LIMIT` (entry, meter ticks), `FAULT CURRENT n` chip (entry, reads `0` dim), `SAME FAULT` chip (pins on at T3, persists), `EARTH WIRE` tag (fades in at connect).

Rules check: imperatives ≤5 words (5/3/5/4); every catch names the **consequence/destination** (`more than enough to harm`; `through the body, to ground`; `straight to ground — not the body`; `cut the supply`) — never the behaviour or a vague ending; no rhyme, no narration-to-a-child; de-personified facts (no "you"; "the body", "a plug"); T12 deliberately mirrors T3 (`Is Live` → `Is Dead`); "earthing" / "third pin" appear in NO text before T13. Card copy in §8. No other text exists in the activity.

## 6. Beat-by-beat flow (timing + gating)
1. **Intro (0–900 ms):** entrance reveals (supply panel + fuse 0→450 ms, appliance cutaway 150→600 ms, body + ground band 300→700 ms, meter + chips 450→900 ms; slide+scale+fade). Cord carries gentle warm pulses (power on). The frayed live wire end shimmers (grab hint). T1 at 700 ms; T2 at +2400 ms.
2. **Fault (learner-paced, irreversible):** drag the frayed wire end (small range inside the cutaway); within snap radius of the inner case wall → it springs to contact, a spark burst fires, the case live tint floods in ≤250 ms, cord pulses quicken slightly; `selectionClick`; `SAME FAULT` chip pins at the contact point; T3 same frame; T4 at +1800 ms. The fault never un-springs (one-way).
3. **The danger (gated, witnessed — NO capture):** T5 arms the touch zone (hand + facing case wall; soft pulse-ring hint). Press-and-hold → channel glow ramps ≤120 ms hand→torso→feet→ground, meter dot rises to ~3 tinted hot red (above `HARM`, far below `FUSE LIMIT`), chip reads `FAULT CURRENT 3`; the fuse visibly does **nothing**. Sustained 600 ms → T6 (no `onCapture` — see §9). T7 at +2800 ms. Release at any time → channel + meter to 0 **instantly** (hard gate). Re-touching is allowed. Gate forward: T7 displayed ≥ 2600 ms && touch released.
4. **Build the route (learner-paced):** T8; the earth **LUG** on the case underside + a **coiled thick wire** + a ground **TERMINAL** reveal (slide+fade 450 ms — *none of these existed on screen before this beat*). Drag the wire's free end; it renders as a thick catenary following the finger; release off-target → springs back to the coil (200 ms). Within snap radius of the terminal → connect: click + `selectionClick`, `EARTH WIRE` tag fades in. Touch zone is disarmed from T8 until step 6 completes.
5. **THE DISCOVERY (auto, hard beat):** 700 ms after connect → an 800 ms surge envelope: bright packets rush case→earth wire→ground, the wire blooms additively, the meter dot slams to ~100 past `FUSE LIMIT`, the fuse filament flares white → at the envelope's end the filament **snaps** (visible gap, tiny smoke wisp) and in the **same frame** every live visual dies (case tint, cord pulses, surge, channel, meter→0). `heavyImpact`; discovery flash (~700 ms envelope) framed on fuse + earth wire; T9 same frame; **capture `surge_blows_fuse`** at the blow frame. T10 at +2600 ms. The blow fires exactly once.
6. **The proof (gated, witnessed):** T11 at +3200 ms; touch zone re-arms with a calm hint. Press ≥ 900 ms → nothing flows (no channel, meter stays 0) → T12. Release → T13 at +1200 ms.
7. **Synthesis → card:** T14 at +4200 ms. +2600 ms → `showCardEarn = true` → `CollectibleEarnOverlay(card: kEarthingCard, eyebrow: 'NEW CARD', brag: 'The fault took the easier route — and the fuse slammed the power off.', showMascot: false, onDone: controller.onCardCollected)` → `canFinish = true`, Continue CTA appears in its fixed seat.
8. **Finish:** Continue → `Navigator.maybePop(context)` (any pop = completion; no payload).

Reversibility: touches are reversible (instant off); the fault and the earth connection are one-way; phases never regress; all T-lines and the single capture fire once. Straight-through play length ≈ **75–120 s**.

## 7. Hero & layout (with clutter caps stated)
- **The one hero:** the fault current's **route** — the live case flood, the channel through the body, and above all the surge down the earth wire. It is the brightest thing on screen in every phase (warm `#FFD27A` for live flow, hot `#FF6259` through the body, blazing gold-white for the surge). The fuse is its adjacent instrument — second-brightest only at the blow.
- **What recedes:** near-black `#070A1C` base; radial vignette darkest behind the appliance; faint circuit texture ~5% alpha; case/cord cool steel; supply panel + meter in `#3FD99B`-tinted glass (homeSafety accent — clearly instruments); chrome on glass `0x14FFFFFF`, borders `0x26FFFFFF`; 14–18 ambient cool motes.
- **Tastefulness (binding, inherited from 3.2):** the body is a minimal sign-figure (head dot + simple strokes), **static except the channel glow**. No limb animation, no convulsion, no face, no gore. The danger reads from the route, the meter, and T7 — never from depicted suffering.
- **Portrait layout (top→bottom):** header → EpisodeBoardStrip (EP3 question) → instruction banner (fixed h 96) → stage (supply + fuse top-left, appliance cutaway center, body right, meter left edge, ground band bottom) → fixed-height CTA seat (84). Full factor map in §16.
- **Clutter caps (hard):** **1 hero**; **5 interactive elements** (frayed-wire handle, touch zone, earth-wire handle, back button, Continue) — ≤6 ✓; **exactly 1 live number**; 2 chips (`SAME FAULT`, `FAULT CURRENT`); 5 static instrument labels; the one current text line. Nothing else. No bird, no insulation tester, no transformer, no second appliance, no second meter.

## 8. Reward
**Card: YES** — "Deliberate path to ground for fault current → earthing · Ep 3 · Fully explained" is a row in the curriculum quick-reference table, and the covenant's EP3 card list includes earthing. Section `homeSafety`, accent `#3FD99B`. Proposed constant `kEarthingCard` (number + `deckTotal` owned by shared infra; build agent references the constant only).
- **Front** — playful name: **The Third Pin** · real term (mono specimen): `EARTHING` · one-line law: `Fault current is given a deliberate low-resistance path to ground — and the surge trips the fuse.` · kicker: `Built to be the easier path.`
- **Back** — tie to what was felt: `The same fault ran twice. Through a body: a trickle, and the fuse stayed silent. Down the thick earth wire: a surge — and the fuse blew the power off.` · outward reach: `Every third pin on a plug ends at a metal rod driven into the actual earth — every earthed building quietly wears this escape route.` · **linked card:** *The Bird's Secret* (3.3, `kBirdsSecretCard`, `POTENTIAL DIFFERENCE`) — ground-as-zero is the recurring idea earthing weaponises.
- Name check: distinct from orphaned Card 04 "The Great Escape"; states the LAW, never re-narrates the activity; restates no other card's law (3.4's "The Free and the Locked" owns block/carry; 3.1's "The Last Mile" owns staging; 3.3's "The Bird's Secret" owns potential difference; this card owns the deliberate route + fuse).
**Inline fact: none** — deliberate empty slot; anything here would restate the lesson or trespass on 3.4.

## 9. CER capture hook
**One capture from this beat** (reconciled to the EP3 catalog owner, which DROPPED the earthing `body_in_path` tile as redundant with 3.3's `ground_is_zero` — the body-danger half stays fully intact in the activity, but its `onCapture` call is removed):

1. `surge_blows_fuse` · label `Surge Blows Fuse` · caption `Fault current surges down the thick earth wire — the fuse blows and cuts the power.` · **relevant** · fires at **§6.5's blow frame** (discovery flash live, blown fuse, earth-wire route framed). Suggested `cropFactor ≈ Rect.fromLTRB(0.0, 0.0, 0.78, 0.95)` (fuse + case + earth wire + terminal).

**Do NOT call `onCapture('body_in_path')`** — that id is removed from the EP3 catalog; calling it would orphan a tile and break acceptance check §10 of the EP3 CER PRD. The body half is *witnessed*, not *captured*.

Wiring (verbatim pattern, copy from `trace_it_back`): scene wrapped in `RepaintBoundary(key: _sceneKey)` (background + stage only); `_board = EpisodeBoardCapture(kEpisode3Id)`; `_board.load()`; `controller.onCapture = _onCapture`; on capture → `HapticFeedback.lightImpact()` then post-frame `captureScenePng(_sceneKey, cropFactor: evidenceByIdFor(kEpisode3Id, 'surge_blows_fuse')?.cropFactor)` → `_board.capture('surge_blows_fuse', imageBytes: bytes)`. `EpisodeBoardStrip(question: kEpisode3Question, …)` pinned under the header, accent `CareerColors.gold`.

## 10. Build notes
- **Rendering: plain `CustomPainter` + `Ticker`** (the `current_through_you` / `hand_crank_lamp` pattern — one fixed scene, controlled state, painter-drawn pulses; Flame's component tree is overhead for a single non-scrolling rig). **No Forge2D** — all motion driven directly; every cutoff is a hard gate in `tick`.
- Controller-owns-geometry: `ErtController extends ChangeNotifier`; `setStageSize(size)` once per `paint`; all anchors = factor × stage size (`ErtTune`). View is a pure renderer reading getters.
- The body glyph deliberately echoes 3.2's sign-figure idiom for visual continuity — **copy the drawing locally** (file-surface rule forbids importing from `current_through_you/`); static except channel glow.
- Current model (relative scale 0–100): body path `kBodyTrickle = 3`; earth-path surge ramps to `kSurgePeak = 100` across the 800 ms envelope; `kHarmTick = 3`, `kFuseLimit = 40`. Fuse logic: blows iff `meterValue ≥ kFuseLimit` (only ever true on the earth route — `assert` in debug that the body path can never blow it). After blow, a `supplyDead` flag zeroes every live channel in the same `tick`.
- Hard gates: touch release → channel + meter 0 within one frame; fuse blow → caseLive, cordPulse, surge, channel, meter all 0 within one frame; both identical under reduced motion.
- Pointer routing per phase: `faultPrompt` → frayed-wire hit-test; `touchPrompt`/`bodyPath` + `proofPrompt`/`proofTouch` → touch-zone hit-test; `earthPrompt`/`earthDrag` → earth-wire-end hit-test; all else inert. One `Listener` on the stage forwards local offsets to the controller.
- Numbers/labels painted in the painter (`TextPainter`, IBM Plex Mono via `google_fonts`) so captures include them. `displayCurrent = round(meterValue)`.
- Haptics: `selectionClick` on fault snap, touch start, earth connect; `heavyImpact` at the blow; `lightImpact` per capture; medium lives inside the card overlay already.
- Audio: **silent** (matches shipped EP3 siblings; silence is fine per covenant §4.9).
- `MediaQuery(...textScaler: TextScaler.noScaling)` wrapper; `reducedMotion` from `MediaQuery.disableAnimations` → calmer motes, fade-style reveals, gentler surge bloom — **but every instant gate stays instant** (covenant: never soften a pedagogical cutoff).
- **File-surface rule:** write only inside `lib/screens/missions/earthing/`. Registry entry, the EP3 evidence catalog (`kEpisode3Evidence` / `kEpisode3Id` / `kEpisode3Question`), and `kEarthingCard` are owned by other phases — code against the names; if any is absent at build time, STOP and report in the final message; never edit shared files.
- Verify: `fvm dart analyze lib/screens/missions/earthing` clean (single path; repo has ~468 pre-existing errors in legacy files — not yours).

## 11. Acceptance criteria (pedagogy encoded as testable checks)
1. **Discoverable from interaction alone:** with top-text suppressed (debug flag), a fresh user reads the concept from the rig: pull wire → case floods live; touch → channel through body + tiny meter trickle + fuse unmoved; connect thick wire → surge + fuse snaps + everything dies; touch again → nothing.
2. **Hard gates / instant cutoffs:** touch release kills the body channel and meter within 50 ms; the fuse blow kills every live visual in the same frame (≤50 ms), no fade tail; both identical under reduced motion.
3. **The fuse never blows on the body path:** during `bodyPath` the meter dot sits visibly above `HARM` and far below `FUSE LIMIT`, and the fuse state is unchanged — the build makes the fuse's silence legible (T7's honesty made visible). Debug `assert(meterValue < kFuseLimit)` whenever `phase == bodyPath`.
4. **Witnessed-absence ordering:** the earth lug, coiled wire, and ground terminal do not exist on screen before T8; T8 is unreachable until the body path was sustained ≥600 ms and T7 shown ≥2600 ms — the danger is always witnessed with **no escape route visible**.
5. **The discovery is gated, singular, earned:** the surge auto-fires once, only after the learner's own connect gesture; `heavyImpact` + capture `surge_blows_fuse` fire exactly once at the blow frame; the blow cannot be re-triggered.
6. **Held-constant visible:** the `SAME FAULT` chip pins at the contact from T3 to the end; the sprung wire's contact is visibly unchanged when the earth route is added — **route is the only variable**.
7. **Exactly 1 live number**, relative; `HARM` / `FUSE LIMIT` are word ticks; **no other numeral exists anywhere** (no amps, mA, volts, "230").
8. **The proof is felt before it is told:** the second touch produces nothing — same gesture, dead rig — before any text says so (T12 lands only after 900 ms of felt nothing).
9. **Text exactness:** all 14 lines verbatim from §5; imperatives ≤5 words; T7/T10's catch names the consequence/destination; "earthing" / "third pin" appear in no text or label before T13.
10. **Tasteful abstraction:** the figure is static except the channel glow — no limb motion, no depiction of pain; the blow moment's flash is crisp resolution, not confetti.
11. **Consequences live in the scene, not a stat:** the case flood, channel, surge, filament snap, and dead rig carry the story; the meter rides alongside and never replaces them; the hero outshines all chrome in every phase.
12. **Single relevant capture, no orphan:** the activity calls `onCapture('surge_blows_fuse')` exactly once and **never** calls `onCapture('body_in_path')` (dropped from the catalog).
13. **Scope fences:** no insulation/material testing, no bird, no step-down staging, no waveform, no RCD/breaker terminology — 3.4/3.3/3.1/2.7 own those; the word "fuse" is used generically.
14. **Completion contract:** card fires after T14, then Continue → `Navigator.maybePop`; `const EarthingScreen()` constructible with no arguments; ≤6 interactive elements; analyzer clean on the activity dir; straight-through run 75–120 s on device.

## 12. Anti-patterns (this activity)
- **Cartoon electrocution** — any animated suffering on the figure; the 3.2 abstraction is mandatory, not a style choice.
- **The fuse "protecting" the person** — letting the fuse react during the body path is the exact falsehood this beat exists to kill; the fuse must be demonstrably inert until the earth route exists.
- **A premium fade on the blow** — the power cut is the pedagogical instant; softening it muddies "the fuse cut the supply".
- **Pre-spoiling the fix** — an earth wire, lug, or terminal visible during the danger half turns the discovery into an instruction.
- **Pre-naming** — "earthing" or "third pin" in any text, label, or banner before T13 (header uses the working title "The Escape Route", not "Earthing").
- **Celebratory danger** — sparkle, score, or upbeat motion while the body is in the path; gravity until the blow, crisp satisfaction after.
- **A second meter or absolute units** — one relative number; the route comparison is carried by thickness, glow, and the tick geometry.
- **Fail-states about ergonomics** — drags snap generously; the struggle is never aiming a wire end, it is witnessing the routes.
- **Re-teaching the parts** — no potential-difference level diagram, no conductor test tray; this beat *uses* 3.2–3.4, it does not replay them.
- **A safety checklist or green ✓** — the proof is the dead case, not a badge.
- **Capturing the body half** — do not snapshot `body_in_path`; the catalog owner removed it (redundant with `ground_is_zero`).

## 13. Open decisions
1. Meter constants (`kBodyTrickle 3`, `kFuseLimit 40`, `kSurgePeak 100`) — tune on device so the trickle reads unmistakably tiny-yet-hot and the surge unmistakably past the limit.
2. Whether a faint cooling afterglow may linger on the earth wire ~1 s post-blow (helps the `surge_blows_fuse` tile read) vs the absolute same-frame cut — recommend **absolute cut** (the capture fires at the blow frame, which already contains the route); flag for visual review.
3. Proof touch required vs optional before synthesis — recommend **required** (it is the witnessed payoff); if device QA shows stalling, add one calm re-hint pulse at +6 s.
4. Header title "The Escape Route" vs "Earthing" — recommend the working title to protect the T13 naming beat (registry id stays `earthing` regardless).
5. T13 length on one banner line — if it overflows two lines at the long-line size, split into T13a (`The blown fuse cut the supply — nothing is live until the fault is mended.`) and T13b (`A deliberate path to ground for fault current: this is earthing. The third pin on a plug carries this wire.`) at +2600 ms; copy above is the source of truth either way.
6. A one-line honest nod to modern breakers ("today a breaker does the fuse's job and resets") — recommend **omit** (scope creep); flagged.
7. Final cropFactor + tile id confirmation — EP3 evidence-catalog owner (`prd_make_your_case_ep3.md`) is authoritative; this PRD is reconciled to it.

---

## 14. State machine sketch
```dart
enum ErtPhase {
  intro, faultPrompt, faultLive, touchPrompt, bodyPath,
  earthPrompt, earthDrag, surge, blown, proofPrompt, proofTouch, synthesis, done
}
```
- **ValueNotifiers:** `caption: ValueNotifier<ErtCaption>` (text + imperative/meaning/long flags), `phase: ValueNotifier<ErtPhase>`, `showCardEarn: ValueNotifier<bool>`, `canFinish: ValueNotifier<bool>`.
- **Hot-path getters (notify via Ticker at 60 fps):** `caseLive` (0–1, ramps ≤250 ms on, hard 0 on blow), `channelGlow` (0–1, ≤120 ms on, hard 0 on release/blow), `meterValue` + `displayCurrent`, `surgeEnvelope` (0–1 over 800 ms), `fuseFlare`, `fuseBlown` (bool), `supplyDead` (bool), `cordPulsePhase`, `sparkBurst`, `earthWireEnd` (Offset during drag), `earthConnected`, `flashIntensity` (0.7 s envelope), `chipPulse`, grab-hint phases, entrance reveals (`supplyReveal`, `applianceReveal`, `bodyReveal`, `meterReveal`, `earthKitReveal`).
- **Input:** `onPointerDown/Move/Up(Offset local)` routed by phase — `faultPrompt`: frayed-end drag (snap radius ~0.04w → spring + spark, irreversible); `touchPrompt`/`proofPrompt`: touch-zone press-and-hold; `earthPrompt`: wire-end drag (snap ~0.05w at terminal; off-target release springs back 200 ms). All other phases inert to stage pointers.
- **Timers (`_schedule(ms, fn)`, cancelable):** T1 700; T2 +2400 (fast path 1000); T3→T4 1800; T4→T5 2600; T6→T7 2800; T7 gate (≥2600 && released) → T8; connect→surge 700; surge 800 → blow; blow→T10 2600; T10→T11 3200; proof hold 900 → T12; release→T13 1200; T13→T14 4200; T14→card 2600.
- **Gating conditions (checked in `tick(dt)`):** `faultLive` ⇐ snap contact · `bodyPath` ⇐ contact sustained 0.6 s (fires T6 once; **no capture**) · `earthPrompt` ⇐ T7 age ≥ 2.6 s && !touching · `surge` ⇐ earthConnected + 0.7 s · `blown` ⇐ surgeEnvelope == 1 (fuse blow + capture `surge_blows_fuse` + heavyImpact, same frame: all live channels → 0) · `proofTouch` ⇐ contact 0.9 s with `supplyDead` · `done` ⇐ Continue. Phases never regress; debug `assert(meterValue < kFuseLimit)` while `phase == bodyPath`.
- **Hooks:** `onDiscovery` (heavyImpact at blow), `onCapture(String id)` (lightImpact in shell), `onSnap` / `onConnect` / `onTouchStart` (selectionClick), `reducedMotion` set from MediaQuery each build.

## 15. File plan — `lib/screens/missions/earthing/` (mirrors the shipped `current_through_you` / `hand_crank_lamp` structure)
```
earthing_screen.dart                 — shell: noScaling MediaQuery, Ticker, header (back on glass;
                                       title 'The Escape Route' + mono eyebrow
                                       'EPISODE 3 · HOME & SAFETY'), EpisodeBoardStrip (EP3
                                       question), instruction banner (h 96, 190 ms fade-swap),
                                       RepaintBoundary[background + stage], fixed CTA seat (h 84),
                                       capture wiring (EpisodeBoardCapture(kEpisode3Id)),
                                       CollectibleEarnOverlay(kEarthingCard)
state/ert_controller.dart            — ErtController extends ChangeNotifier (§14: sim, geometry,
                                       phase machine, timers, gates, hooks)
config/ert_config.dart               — ErtTune: geometry factors (§16), kBodyTrickle 3 /
                                       kFuseLimit 40 / kSurgePeak 100 / kHarmTick 3, snap radii,
                                       ramp/envelope ms, palette tokens (homeSafety #3FD99B,
                                       live #FFD27A, body-route #FF6259, surge gold-white)
config/ert_copy.dart                 — ErtCaption (text + register flags) + ErtCopy: T1–T14 verbatim,
                                       chip/instrument labels, brag line, all timing constants (ms)
widgets/ert_stage.dart               — Listener + CustomPaint(painter: ErtStagePainter(controller),
                                       repaint: controller); forwards pointer to controller
widgets/ert_stage_painter.dart       — pure renderer, back→front: vignette pool → ground band +
                                       terminal → cord + pulses → supply panel + fuse (filament
                                       window, flare, snap gap, smoke wisp) → appliance cutaway
                                       (case live flood, terminal block, frayed wire, SAME FAULT
                                       chip) → earth wire (coil / drag catenary / connected, surge
                                       packets additive) → body glyph + channel → meter (ticks,
                                       labels, live dot) → FAULT CURRENT chip → spark burst →
                                       discovery flash → grab hints
widgets/energy_field_background.dart — copied static dark vignette variant (per shipped pattern)
```

## 16. Scene sketch — portrait, factor-based (stage = w × h of the Expanded area)
```
y≈0.04–0.16h  SUPPLY PANEL — glass box x 0.05–0.29w; FUSE cartridge with a visible filament
              window centered in it, mono label `FUSE` beneath; cord (mono tag `LIVE`) leaves
              its right edge and arcs down to the appliance top; warm pulses ride the cord while
              power is on
y≈0.30–0.58h  APPLIANCE — metal case x 0.24–0.62w, cutaway front; inside-left: terminal block +
              the frayed LIVE wire end (drag handle, shimmer hint); inner-left case wall = snap
              target; `SAME FAULT` chip pins at the contact (~0.27w, 0.40h) from T3 on; case
              floods with live tint when faulted; earth LUG at case underside (0.43w, 0.585h) —
              exists only from T8
y≈0.30–0.82h  BODY — sign-figure at x≈0.78w, ~0.30h tall, standing on the ground band; hand
              extended toward the case's right wall, gap ≈0.05w; touch zone = hand + facing
              wall rect; channel path hand→torso→feet→ground, additive `#FF6259` glow
y≈0.26–0.68h  METER — slim vertical bar at x≈0.105w (below the supply panel); word ticks to its
              right: `HARM` at 3/100 (low), `FUSE LIMIT` at 40/100; live dot rides it (red on the
              body route, gold on the earth route)
y≈0.745h      FAULT CURRENT chip — (0.115w), mono `FAULT CURRENT 3`, dark glass, under the meter
y≈0.84–0.92h  GROUND — hatched earth band full width, mono `GROUND`; earth TERMINAL stub at
              (0.43w, 0.85h) — exists only from T8
earth wire    coiled at the lug (T8); drag end → thick catenary (stroke ≈0.020w, visibly ~2× the
              cord); connected: lug→terminal run with `EARTH WIRE` mono tag; surge packets race
              down it during §6.5
ambient       14–18 cool motes; reduced motion → near-static
```
Above the stage (Flutter chrome, outside the RepaintBoundary): header → EpisodeBoardStrip → instruction banner. Below: the fixed CTA seat. Small-phone check at 360×640 logical: meter ticks must not collide with the appliance's left edge (case starts at 0.24w for this reason); the body's head bloom stays clear of the banner; the earth-wire catenary must not occlude the `FAULT CURRENT` chip mid-drag.
