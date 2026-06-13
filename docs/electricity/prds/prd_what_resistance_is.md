# PRD — What Resistance Actually Is (Episode 2, beat 2.2)
### howwow · registry id `what_resistance_is` · dir `lib/screens/missions/what_resistance_is/` · class `WhatResistanceIsScreen` · evidence episode `episode2_electricity`

Binding context: `docs/electricity/context_pack.md` (the covenant), `docs/electricity/architecture_reference.md`
(APIs/patterns), curriculum beat 2.2. No mascot, no info-cards, one voice (the on-screen text). This PRD is
self-contained: every on-screen line is quoted verbatim here.

---

## 1. One-concept statement

**Resistance is the wire's opposition to current, set by its physical shape.**
(Long and thin opposes hard; short and fat barely opposes. Nothing else in this activity.)

## 2. Guiding-question link + CER contribution

Episode question (pinned on the evidence board strip all activity, via shared `kEpisode2Question`):
*"The plant is far away — how do we send power across that distance without losing it all on the way?"*

**What this beat inherits (chain rule 2.1 → 2.5):** from 2.1 the learner has FELT that voltage drives and
current flows — raise voltage, current rises — *while the wire was visibly pinned fixed*. Voltage and
current are already named and may be used in text from the first line of this activity.

**What this beat pins:** **voltage**. The pin that sat on the wire in 2.1 visibly MOVES to the voltage dial
in this activity's opening beat (witnessed, not stated only). The wire becomes the adjustable thing. This
visible pin-move is load-bearing for 2.5's later flip (fixed wire → fixed power) reading as a twist, not a
contradiction.

**CER contribution (proposals; final set owned by the EP2 CER PRD):**
- `thin_wire_chokes` — **DISTRACTOR** (true-but-irrelevant). "A thin wire chokes the current" is true and
  tempting (it mentions wires and current), but it answers *what resistance is*, not *how we send power far
  without losing it* — the episode claim is the high-voltage trick. Exactly the EP1 `still_magnet` pattern:
  the beat's own core discovery furnishes a distractor.
- `arm_thick_cable` — **RELEVANT**. "Real grid cables are arm-thick — fat metal keeps resistance low" is a
  genuine half of the on-the-way answer (engineers lower R; the star half, high voltage, comes in 2.5).

## 3. The felt discovery (discovery → reaction)

**Discovery:** the learner grabs the wire itself and drags it — stretching it long and thin, squashing it
short and fat.
**Reaction:** in the SAME frame, the current packets inside the wire thin to a sparse crawl (stretched) or
surge into a wide fast stream (squashed); the small lamp at the wire's end dims/blazes; the CURRENT number
falls/climbs — while the VOLTAGE chip sits frozen under its pin the entire time. The push never changed;
the wire itself set how much flows. The interaction IS the concept: reshaping the conductor is the only
control, and the wire is both hero and handle. The name "resistance" lands only after both extremes are felt.

## 4. Felt vs named vs numbered

- **Felt:** amount of flow (packet density + speed inside the wire), the choke at thin, the surge at fat,
  the lamp's echo brightness, the wire's co-varying length/width (same metal — longer is visibly thinner,
  same frame), the immovable pinned dial (tap it: it refuses with a shake).
- **Named:** **resistance** — named at the naming beat, AFTER both extremes are felt (short gap, per §3 of
  the curriculum). "Voltage" and "current" are inherited names from 2.1, usable from the start.
- **Numbered (live, relative, ≤2 on screen):** `VOLTAGE 100` (frozen, pin glyph, never changes) and
  `CURRENT` (live, baseline 100, ~45 at full thin, ~400 at full fat, trend arrow while moving).
- **Explicitly absent:** no resistance number or meter (resistance stays felt + named here, never numbered);
  no absolute units (no volts/amps); **no ratings table**; no temperature/heat cue of any kind (2.3's job).
- **Depth honesty:** fully showable, fully explained — **no depth-stop**, so no honesty line is needed. The
  water-pipe analogy is in range for this beat (curriculum-blessed) and appears as ONE text line, no graphic.

## 5. On-screen text (exact, verbatim — complete set)

Header — title: **"Shape the Wire"** · mono eyebrow: **"EPISODE 2 · THE LONG WAY HOME"**
(The on-screen title must NOT contain the word "resistance" — pre-naming guard.)

| # | Beat | Register | Line (verbatim) |
|---|------|----------|-----------------|
| m1 | B0 pin-move | meaning-line | "The pin moved. This time, voltage is held fixed." |
| i1 | B1 stretch | imperative | "Stretch the Wire" |
| e1 | B1 echo (secondary, while first stretching) | echo | "Longer — Thinner" |
| m2 | B1 thin discovery | meaning-line | "Same voltage. The long, thin wire chokes the current." |
| i2 | B2 squash | imperative | "Now Squash It Fat" |
| e2 | B2 echo (secondary, while first squashing) | echo | "Shorter — Fatter" |
| m3 | B2 fat discovery | meaning-line | "Same voltage again. The short, fat wire lets the current run." |
| i3 | B3 sweep | imperative | "Sweep It Thin and Fat" |
| m4 | B3 converging point | meaning-line | "The voltage never moved. The wire's shape set the current." |
| m5 | B4 naming | meaning-line | "That opposition has a name: resistance." |
| m6 | B4 the shape law | meaning-line | "Long and thin — high resistance. Short and fat — low resistance." |
| m7 | B4 pipe analogy | meaning-line | "Water does the same in a pipe — narrow throttles the flow, wide lets it pour." |
| m8 | B5 landing | meaning-line | "This is why transmission cables are arm-thick — fat wire, low resistance." |
| d1 | any: learner taps/drags the pinned dial | guard flash | "Voltage Stays Pinned" |
| — | B4 wire specimen label (mono, fades in at m5) | label | "RESISTANCE" |
| — | B5 cable label (mono) | label | "REAL TRANSMISSION CABLE" |
| — | chips (mono) | label | "VOLTAGE 100" (+pin glyph) / "CURRENT <n>" (+↑/↓) |
| — | CTA | button | "Continue" |
| — | card earn eyebrow / brag | overlay | "NEW CARD" / "Thin chokes it, fat frees it — the wire sets the current." |

Rules check: imperatives ≤5 words, Title Case, instruct only; meaning-lines name the noun, state facts,
no rhyme, never address the reader; m2 names the consequence on the current ("chokes the current"), not a
behaviour of the wire. d1 shows at most twice per session.

## 6. Beat-by-beat flow (timing in ms, gating)

- **B0 — entry + pin-move (auto, ~2600 total).** 0–600: scene entrance reveals (slide+scale+fade ≤450 each):
  source bar + dial top, the mid-shape wire (morphT = 0.5, the SAME wire silhouette 2.1 used), lamp, faint
  return path. 600–1500: the pin visibly unclips from the wire, arcs to the voltage dial, clamps (900 flight;
  reduced-motion: fade-out at wire, fade-in at dial). At clamp: `selectionClick`, VOLTAGE chip gains the pin
  glyph, m1 fades in. 1500–2600: hold m1. Then i1 + pulsing grab ring on the wire's lower handle. Wire input
  enabled from here.
- **B1 — stretch (learner-paced).** Drag down on the wire → morphT rises; length/width/flow/lamp/number all
  respond same-frame. e1 shows as small secondary text during the first sustained stretch (t crosses 0.62
  while rising), hides after 2200. **Gate:** morphT ≥ 0.85 sustained 400 → **THIN DISCOVERY**:
  `heavyImpact`, discovery flash (~700 envelope), `onCapture('thin_wire_chokes')` (`lightImpact` in shell),
  caption swaps to m2. Hold 2400, input stays live.
- **B2 — squash (learner-paced).** i2. Drag up through mid toward fat; e2 on first sustained squash (t
  crosses 0.38 while falling), hides after 2200. **Gate:** morphT ≤ 0.15 sustained 400 → fat moment:
  `selectionClick` + brief surge shimmer on the stream (no second heavy flash — one orchestrated discovery
  per activity), caption m3. Hold 2400.
- **B3 — sweep (learner-paced, capped).** i3. **Gate:** after sweep starts, visit both bands (t ≤ 0.2 AND
  t ≥ 0.8, either order) OR 8000 timeout → m4 for 2600. Input stays live through B4.
- **B4 — naming (auto).** m5 (3400) — mono "RESISTANCE" specimen label fades onto the wire over 600 →
  m6 (3200) → m7 (3000). Caption swaps are always fade-out 190 → swap → fade-in (never cross-fade).
- **B5 — landing (auto, input disabled at entry).** Lab scene crossfades to the arm-thick cable
  cross-section + ghost forearm silhouette (`landingBlend` 0→1 over 1600; chips and lamp fade to 12%).
  At blend complete: `onCapture('arm_thick_cable')`, m8. Hold 3200.
- **B6 — card + finish.** `showCardEarn = true` → `CollectibleEarnOverlay` (card §8). `onDone` →
  `showContinue = true`; gold-pill "Continue" in the fixed CTA seat → `Navigator.maybePop(context)`.

Reversibility: morph is freely reversible B1–B4 and HOLDS on release (no spring-back — the steady state must
be readable). Phase gates only ratchet forward. Typical play length 60–110 s (within the 60–150 target).

## 7. Hero & layout (clutter caps)

- **The hero:** the wire and the current flowing inside it — the brightest, most alive thing on screen
  (warm energy `#FFD27A` packets, additive `BlendMode.plus` glow). The lamp is a small secondary echo;
  the source/dial, return path, chips and chrome all recede (glass `0x14FFFFFF`, borders `0x26FFFFFF`).
- **Portrait, single column** (full sketch in §16): header → episode board strip → caption seat (fixed 96)
  → stage (Expanded) → CTA seat (fixed 84).
- **Clutter caps for this screen:** the hero wire, 2 chips (the only 2 numbers, relative), the current
  caption line (+ optional small echo), the grab ring, the lamp, the faint return path. Nothing else.
  **Interactive elements: 3** (wire drag handle, pinned dial deny-tap, Continue CTA) — well under the 6 cap.
  Background: `#070A1C` base, radial vignette darkest behind the wire, ≤20 ambient motes, whisper circuit
  texture ~5% alpha.

## 8. Reward — collectible card (proposed copy; shared infra owns the constant)

`resistance` IS a row in the curriculum quick-reference table ("The wire's opposition to current →
resistance → Ep 2 → fully explained") → **card warranted.** Section: **transmission** (accent `#3FB9F5`).
Number + `deckTotal` assigned by the shared-infra agent; this activity only references `kNarrowPipeCard`.

- **Front** — playful name: **"The Narrow Pipe"** · mono specimen label: **RESISTANCE** ·
  law line: *"Every wire opposes the current through it — its shape sets how much."* ·
  kicker: *"Thin fights. Fat flows."*
- **Back** — tie to what was felt: *"You pinned the voltage and reshaped the wire — stretched thin, the
  current choked; squashed fat, it surged."* · outward reach: *"Every cable in your house is sized for the
  current it must carry — fatter for the oven, slimmer for a lamp."* · linked card: **none** (resistance is
  not one of the recurring-idea threads).
- Earn invocation: `CollectibleEarnOverlay(card: kNarrowPipeCard, eyebrow: 'NEW CARD', brag: 'Thin chokes
  it, fat frees it — the wire sets the current.', showMascot: false, onDone: controller.onCardCollected)`.
- **Inline fact: none** — a fact mid-flow would compete with the naming beat. Deliberate empty slot.

## 9. CER capture hook (proposed tiles; ids LOCKED by the EP2 evidence catalog at shared-infra time)

Shell wiring per the shipped verbatim pattern: scene in `RepaintBoundary(key: _sceneKey)`;
`controller.onCapture = _onCapture` → `captureScenePng(_sceneKey, cropFactor:
evidenceByIdFor('episode2_electricity', id)?.cropFactor)` → `_board.capture(id, imageBytes: bytes)`;
`EpisodeBoardStrip` pinned under the header with the EP2 question.

| id | label (≤3 words) | caption (one line) | flag | onCapture fires at |
|---|---|---|---|---|
| `thin_wire_chokes` | "Thin Wire Chokes" | "Same pinned voltage — stretched thin, the wire cut the current to a trickle." | distractor (true-but-irrelevant: answers *what resistance is*, not *how power travels far*) | THIN DISCOVERY: first time morphT ≥ 0.85 sustained 400 ms (B1 gate), once |
| `arm_thick_cable` | "Arm-Thick Cable" | "Real grid cables run arm-thick — fat metal keeps resistance low." | relevant | B5: the frame `landingBlend` reaches 1.0 (cable reveal complete), once |

Proposed cropFactors (normalized LTRB, final values in the catalog): `thin_wire_chokes`
`Rect.fromLTRB(0.16, 0.10, 0.96, 0.78)` (wire + CURRENT chip in frame); `arm_thick_cable`
`Rect.fromLTRB(0.10, 0.16, 0.90, 0.72)` (cable cross-section + forearm ghost).

## 10. Build notes

- **Rendering: plain `CustomPainter` + Ticker** (the hand-crank-lamp pattern, not Flame). This is a single
  high-precision morphing widget with one gesture and one particle channel — a full Flame scene is overkill.
  `WireSurface` = `Listener` + `CustomPaint(painter: ResistanceStagePainter(controller), repaint: controller)`.
- **No Forge2D** (banned). Morph maps directly from drag delta — no momentum, no spring; current is computed,
  never integrated. Cause/effect glued same-frame.
- **Current model** (tunables in `RTune`): `lengthFactor Lf(t) = lerp(0.60, 1.80, t)`, t = morphT, start 0.5;
  rendered width ∝ `1/sqrt(Lf)` (cross-section × length conserved — same metal, visibly); relative current
  `I(t) = 100 × (Lf(0.5)/Lf(t))²` → ≈400 fat / 100 mid / ≈45 thin (≈9× swing). The squared form is internal
  drama only — never surfaced as text, curve, or readout (2.4 owns the square).
- **Flow rendering:** packet speed ∝ `I^0.6` (legibility compression), packet count 8–34 ∝ I, packet size ∝
  wire width: thin = sparse slow single-file, fat = wide fast multi-lane. Lamp glow ∝ normalized I, small.
  Reuse `paintBulb` from `hand_crank_lamp/widgets/bulb.dart` (precedent: trace_it_back imports it).
- **Display number cadence:** visuals update per-frame; the CURRENT chip ticks every ~100–120 ms with ↑/↓
  trend (the source-personalities `displayPowerKW` pattern), so the number reads, not blurs.
- **Haptics:** `selectionClick` per 0.125 morphT detent crossed and at pin clamp; `heavyImpact` at THIN
  DISCOVERY; `lightImpact` on each capture (in shell); medium impact is inside the card overlay already.
- **Audio: silent** (no BGM, no SFX) — consistent with shipped electricity activities; no manifest needed.
- **Reduced motion:** pin flight → fade-out/fade-in; calmer/fewer packets; landing = simple fade; entrance
  reveals shorter. The same-frame morph→current response is pedagogy, NOT motion polish — never softened.
- **Accessibility/chrome:** screen wrapped in `MediaQuery(...textScaler: TextScaler.noScaling)`; caption seat
  fixed-height 96 so the stage never resizes; 190 ms fade-out → swap → fade-in caption swaps; gold gradient
  pill CTA (`#F5C451 → #D9A43B`, h 52); header back button on glass.
- **File-surface rule:** write ONLY inside `lib/screens/missions/what_resistance_is/`. Registry entry, EP2
  evidence catalog (`evidence_models_ep2.dart`), card constant/painter are other agents' files — if any needs
  changing, STOP and report. Verification: `fvm dart analyze lib/screens/missions/what_resistance_is` clean,
  plus analyze on every shared file imported.

## 11. Acceptance criteria (the pedagogy as testable checks)

1. **Same-frame response:** a morphT change from input is reflected in wire geometry, packet flow, lamp and
   (next tick) the CURRENT value with ≤1 frame of latency; no easing/inertia on morphT itself.
2. **Conservation visible:** width and length co-vary every frame; rendered cross-section × length constant
   within 2% across the full sweep.
3. **The pin is witnessed and absolute:** the pin's flight from wire to dial plays before input unlocks and
   cannot be skipped; thereafter the VOLTAGE chip value never changes by even 1; the dial accepts no input —
   tapping/dragging it produces only the deny shake + pin glint (+ d1, max twice).
4. **Discoverable from interaction alone:** with all captions suppressed (dev flag), stretch→choke and
   squash→surge are fully readable from flow density/speed, lamp, and the CURRENT number.
5. **Name-after-felt:** the string "resistance" (any case) appears nowhere — header, eyebrow, labels,
   captions — before m5; verified by a copy scan of `RCopy` usage order and a runtime phase assert.
6. **Gate order holds:** i2 cannot appear before THIN DISCOVERY; m4 requires both extremes (or the 8 s sweep
   timeout, which still requires both B1 and B2 gates already passed); naming requires m4.
7. **≤2 numbers, relative only** (VOLTAGE frozen at 100, CURRENT live); no third readout, no resistance
   number, no absolute units, **no ratings table**.
8. **No heat anywhere:** the thin wire never warms, reddens, or glows hot — the choke reads as *less flow*
   (dimmer, sparser, cooler), never temperature. No orange/red shift on the wire body at any morphT.
9. **Copy fidelity:** on-screen text is exactly §5, verbatim; imperatives ≤5 words; no rhyme; no
   reader-address; m2/m3 name "the current" as the affected noun.
10. **Captures:** `thin_wire_chokes` fires exactly once at the B1 gate frame; `arm_thick_cable` exactly once
    at landingBlend = 1.0; both via the RepaintBoundary PNG path; board strip shows the EP2 question
    throughout.
11. **Hero brightness:** the wire + packets are the brightest element in every phase before B5; lamp and
    chrome measurably dimmer; return path ≤20% alpha.
12. **Completion contract:** card overlay only after the landing; Continue calls `Navigator.maybePop`; any
    pop counts as completion (no result payload).
13. **Interactive elements ≤3**; reduced-motion respected per §10; portrait small-phone (≈360×690 logical)
    shows the full loop without scrolling.
14. `fvm dart analyze lib/screens/missions/what_resistance_is` is clean.
15. Unhurried full play (both extremes + sweep + naming + landing + card) lands in 60–150 s.

## 12. Anti-patterns (this activity)

- **A resistance meter or number** — resistance stays felt (shape) and named, never numbered in this beat.
- **A slider controlling the wire** — the wire itself is the control; a detached slider breaks
  "the interaction IS the concept".
- **Any heat cue on the thin wire** (warm glow, red shift, shimmer) — pre-teaches 2.3 and confuses the choke
  with loss. The thin wire dims; it does not warm.
- **Surfacing the square** (loss curves, "double → quadruple" copy, I² anywhere) — 2.4's discovery.
- **Pre-naming** — the title/eyebrow/any label leaking "resistance" before m5 (the registry id
  `what_resistance_is` is internal; the on-screen title is "Shape the Wire").
- **A drifting pin** — voltage animating even decoratively (chip pulse, value jitter) destroys the
  held-constant; the frozen number IS the pin's proof.
- **Spring-back on release** — the wire snapping to mid erases the steady-state read of shape→current.
- **An animated water-pipe graphic** at m7 — the analogy is one text line; a pipe visual would compete with
  the hero and over-extend the analogy.
- **Lamp as hero** — the lamp is a quiet echo; if it outshines the wire, the activity reads as "about light".
- **A premium fade smoothing the same-frame current response** — the instant cause/effect is the lesson.
- **Explaining in imperatives** — i1–i3 instruct only; all teaching lives in m1–m8.

## 13. Open decisions (flagged, not silently resolved)

1. **Pin glyph continuity with 2.1:** the pin/lock visual must be the SAME glyph the `voltage_and_current`
   build puts on the wire, or the "pin moved" beat loses its referent. Coordinate at integration; default: a
   small gold map-pin/clamp glyph shared as copy-adapted painter code.
2. **Long-wire rendering on small phones:** straight elongation vs a 2-bend serpentine at high morphT
   (recommended: gentle serpentine above t ≈ 0.7 so "long" stays legible without pushing the lamp off-stage).
3. **Current range tuning:** ship targets ≈45–400 (≥8× swing required); exact `RTune` values tuned on device.
4. **Landing art:** cable cross-section + ghost forearm (recommended) vs a pylon-span wide shot (rejected by
   default — a landscape/town shot would pre-empt 2.5's payoff scene).
5. **Final CER flags:** whether `thin_wire_chokes` ends up one of EP2's exactly-two distractors is the EP2
   CER PRD's call; this PRD guarantees the capture moments regardless.

## 14. State machine sketch

```dart
enum RPhase { intro, pinMove, stretch, thinFound, squash, fatFound, sweep, naming, landing, synthesis, done }

class ResistanceController extends ChangeNotifier {
  // ValueNotifiers (discrete UI channels)
  final phase          = ValueNotifier<RPhase>(RPhase.intro);
  final caption        = ValueNotifier<RCaption>(RCaption.none); // enum carries text + register flag
  final echo           = ValueNotifier<RCaption>(RCaption.none); // e1/e2 secondary, auto-hide 2200 ms
  final displayCurrent = ValueNotifier<int>(100);                // sampled every ~110 ms
  final currentTrend   = ValueNotifier<int>(0);                  // -1 / 0 / +1
  final showContinue   = ValueNotifier<bool>(false);
  final showCardEarn   = ValueNotifier<bool>(false);

  // Hot-path getters (repaint via notifyListeners in tick)
  double morphT = 0.5;          // 0 = short+fat, 1 = long+thin; set ONLY by drag delta, clamped
  double get lengthFactor;       // lerp(0.60, 1.80, morphT)
  double get widthFactor;        // ∝ 1/sqrt(lengthFactor)  (conservation)
  double get currentNorm;        // (Lf(0.5)/Lf(t))²  → relative I = 100 × currentNorm
  double flowPhase, pinFlight, pinDenyShake, lampGlow, discoveryFlash, landingBlend;
  // entrance reveals: sourceReveal, wireReveal, lampReveal (0→1, ≤450 ms each)
  List<FlowPacket> get packets;  // pooled, count 8–34 ∝ currentNorm
  bool reducedMotion = false;    // set from MediaQuery each build

  // Input (from WireSurface Listener; active stretch→naming only)
  void onPointerDown/Move/Up(Offset local);   // vertical dy → morphT += dy / dragRangePx, same frame
  void onDialTouched();                       // pinDenyShake envelope + d1 (max 2 shows)

  // Hooks (wired by the shell)
  VoidCallback? onDetent;        // selectionClick per 0.125 morphT detent
  VoidCallback? onDiscovery;     // heavyImpact at thinFound
  void Function(String id)? onCapture;
  void onCardCollected();        // showCardEarn=false → showContinue=true

  void tick(double dt);          // Ticker 60 Hz: envelopes, flowPhase advance ∝ currentNorm^0.6,
                                 // gate checks, display sampling, notifyListeners()
}
```

**Timers** (`_schedule(ms, fn)`, all cancelled on dispose): intro→pinMove 600 · pin flight 900 · m1 hold 1100
→ i1 · thinFound: flash 700, m2 hold 2400 → i2 · fatFound: m3 hold 2400 → i3 · sweep timeout 8000 ·
m4 2600 · m5 3400 · m6 3200 · m7 3000 · landing blend 1600 + m8 hold 3200 → card. Caption swap animation
190 ms out → swap → in (lives in the caption widget).

**Gating conditions:** stretch→thinFound: `morphT ≥ 0.85` sustained 400 ms (capture + heavyImpact fire here);
squash→fatFound: `morphT ≤ 0.15` sustained 400 ms; sweep→m4: both bands `(≤0.2 AND ≥0.8)` visited after sweep
entry, OR 8000 ms; landing entry disables pointer input; `arm_thick_cable` capture at `landingBlend ≥ 1.0`
(once); synthesis→done: card `onDone` → Continue → `Navigator.maybePop`.

## 15. File plan (mirrors `hand_crank_lamp` — the CustomPainter template)

```
lib/screens/missions/what_resistance_is/
├── what_resistance_is_screen.dart        (~330) — const WhatResistanceIsScreen(); noScaling MediaQuery;
│        Ticker; RepaintBoundary(_sceneKey) around background+stage; header (back on glass, title
│        "Shape the Wire", mono eyebrow); EpisodeBoardStrip(kEpisode2Question); fixed-96 caption seat;
│        Expanded WireSurface; fixed-84 CTA seat; CaptureFlash; CollectibleEarnOverlay(kNarrowPipeCard);
│        _onCapture → captureScenePng(cropFactor: evidenceByIdFor('episode2_electricity', id)?.cropFactor)
│        → _board.capture; haptic hook wiring
├── state/resistance_controller.dart      (~340) — ResistanceController (per §14)
├── state/flow_particles.dart             (~120) — pooled FlowPacket field (in-wire packets, ≤20 bg motes)
├── config/resistance_tuning.dart         (~110) — RTune: all geometry factors (§16), Lf range, current
│        model constants, packet caps, drag range, every timer ms, sustain windows, band thresholds
├── config/resistance_beats.dart          (~90)  — RPhase + RCaption enums + RCopy: ALL §5 strings verbatim,
│        with isImperative/isEcho style flags
└── widgets/
    ├── wire_surface.dart                 (~40)  — Listener + CustomPaint(ResistanceStagePainter,
    │        repaint: controller); forwards pointer; dial hit-region → onDialTouched
    ├── resistance_stage_painter.dart     (~620) — pure renderer, paint order back→front: vignette focus →
    │        return path (faint) → source bar + dial + pin (flight + clamp + deny shake) → hero wire
    │        (morphing body, specular sheen, additive flow packets) → grab ring → lamp (paintBulb import)
    │        → chips (VOLTAGE pinned / CURRENT + trend) → discovery flash ring → landing cable
    │        cross-section + forearm ghost + labels (landingBlend crossfade)
    ├── caption_text.dart                 (~120) — fixed-height two-register caption: imperative Bricolage
    │        ~28 w800 / meaning-line PJS ~18 (long lines smaller) / echo small mono; 190 ms fade-swap
    └── energy_field_background.dart      (~100) — static dark vignette variant (copy-adapt, trace_it_back's)
```

Cross-dir imports (read-only, precedented): `hand_crank_lamp/widgets/bulb.dart` (`paintBulb`),
`episode_board/*` (strip, capture, snapshot), `collectibles/*` (card constant + overlay), `careerTheme.dart`.
Registry/catalog/card files are NOT touched by this build.

## 16. Scene sketch (portrait, top → bottom; factors of stage size W×H)

```
┌──────────────────────────────────────┐
│ header: ← back · "Shape the Wire"    │  Flutter chrome (outside stage)
│ eyebrow EPISODE 2 · THE LONG WAY HOME│
│ EpisodeBoardStrip (EP2 question)     │
│ caption seat, fixed 96 (i/m lines)   │
├─ stage (Expanded, RepaintBoundary) ──┤
│ source bar: center (0.50W, 0.085H),  │  width 0.46W; dial at its right end (0.66W) — PIN clamps here
│   VOLTAGE chip at left end (0.32W)   │  chip: mono "VOLTAGE 100" + pin glyph, frozen forever
│ top terminal (0.50W, 0.17H)          │
│ HERO WIRE: vertical, from 0.18H down │  morphT=0   → bottom ≈0.40H, width ≈0.16W  (short + fat)
│   to yEnd = lerp(0.40H, 0.66H, Lf̂)   │  morphT=0.5 → bottom ≈0.52H, width ≈0.075W (the 2.1 wire)
│   gentle 2-bend serpentine t>0.7     │  morphT=1   → bottom ≈0.66H, width ≈0.018W (long + thin)
│   flow packets inside, #FFD27A, plus │  brightest thing on screen; vignette darkest behind it
│ grab ring rides wire's lower end     │  pulses until first drag; drag range ≈0.34H ↔ full morph
│ CURRENT chip (0.80W, 0.36H)          │  mono "CURRENT 100" + ↑/↓, ticks ~9 Hz
│ lamp at (0.50W, yEnd + 0.10H)        │  small warm bulb (paintBulb), glow ∝ current; secondary
│ return path: lamp → 0.86W → up to    │  ≤20% alpha, quiet — loop honesty from 2.1, never labelled
│   source (thin cool line)            │
│ B5 landing overlay: cable cross-     │  disc center (0.50W, 0.42H) r≈0.30W, stranded aluminium;
│   section + forearm ghost (10% α,    │  mono label "REAL TRANSMISSION CABLE"; everything else 12% α
│   spans 0.62W) via landingBlend      │
├──────────────────────────────────────┤
│ CTA seat, fixed 84: "Continue" pill  │  gold gradient, appears only at done
└──────────────────────────────────────┘
```

All geometry = factor × stage size set once per paint (`setStageSize`); no fixed pixels. Small-phone check:
at morphT = 1 the lamp sits at ≈0.76H — inside the stage on ≈360×690 logical with the fixed seats above/below.
