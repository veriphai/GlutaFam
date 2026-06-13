# PRD — The Transmission Trick (Episode 2, beat 2.5) · THE STAR
### howwow electricity · registry id `transmission_trick` · `TransmissionTrickScreen` · `lib/screens/missions/transmission_trick/` · evidence episode `episode2_electricity`

Binding context: `docs/electricity/context_pack.md`, `docs/electricity/architecture_reference.md`, curriculum §1–§9 + beat 2.5. This PRD is self-contained: every on-screen line is quoted verbatim here.

**Chain inheritance (what the learner already felt):** 2.1 — voltage and current are distinct; with the WIRE pinned, more voltage meant MORE current. 2.2 — resistance is the wire's opposition, set by shape. 2.3 — current through resistance turns energy to heat; that heat IS the loss. 2.4 — the heat grows with the SQUARE of the current.
**What this beat pins:** the POWER leaving the plant (the pinned rectangle area). The wire itself also never changes (same route, same wire — only its heat varies). The pin FLIP from 2.1 (fixed wire → fixed power) is named on screen at mission start (line L2), and the contrast is drawn again after it is felt (line L5).

---

## 1. One-concept statement
**For fixed power delivered, higher voltage means lower current means far lower loss.**

## 2. Guiding-question link + CER contribution
Episode 2 question (pinned on the board strip all activity): *"The plant is far away — how do we send power across that distance without losing it all on the way?"*
This beat IS the episode's answer, so both its evidence tiles are **relevant** — no distractor comes from this activity (EP2's two distractors are owned by other beats' PRDs).
- `current_drops_itself` (relevant) — captured at the discovery: voltage raised, current fell on its own.
- `cold_wire_full_town` (relevant) — captured at max voltage: hairline current, cold wire, fully lit town.

## 3. The felt discovery (discovery → reaction)
**Discovery:** the learner drags the top edge of a glowing, pinned-area rectangle upward — raising the sending voltage, the only control.
**Reaction:** the rectangle's width — the CURRENT — shrinks BY ITSELF in the same frame (nobody touched it); the live CURRENT number ticks down while VOLTAGE ticks up; the hot, shimmering wire visibly cools (heat ∝ I², so it cools dramatically); the distant town brightens window by window. Drag back down and it all reverses: current fattens, wire reheats, town dims. The surprise is the inversion of 2.1: more voltage now means LESS current — because the pinned quantity flipped from the wire to the power.

## 4. Felt vs named vs numbered
**Felt (in the scene, never numeric):** wire heat (orange glow + heat-shimmer + rising heat motes, all ∝ I²); current as pulse count/thickness on the wire AND as the rectangle's width; town brightness (lit-window count + warm bloom); the pinned area visibly never changing while the shape does.
**Named (a beat after felt, except the mission pin which is setup named on sight):** "the power is held fixed" (L2, mission setup — an arrangement, named immediately like an object); "power is voltage times current — the area of this rectangle" (L5, after the width-shrink is felt); the I² recall (L6, after the cooling is felt); "the transmission trick" (L8, named last, after the full win is felt).
**Numbered (exactly 2, live, relative, mono chips riding the rectangle's sides):** `VOLTAGE` 10 → 200 and `CURRENT` 100 → 5. Their product is constant (1000) but that number is never shown — the area is felt, not printed. **No ratings table. No number for heat, loss, brightness, or "% delivered" — the wire and the town ARE those readouts.**
**Depth-stops: none.** This beat is fully explainable (the rectangle). It USES 2.4's squared law without re-deriving it.

## 5. On-screen text (exact, complete)
Imperatives: Bricolage Grotesque ~28 w800, Title Case, ≤5 words. Meaning-lines: Plus Jakarta Sans ~18 (long lines auto-shrink), de-personified facts. Swap = 190 ms fade-out → swap → fade-in.

| id | kind | text |
|---|---|---|
| L1 | meaning | A town, far away. The plant must send it full power. |
| L2 | meaning (THE PIN FLIP, named as it happens) | Last mission the wire was held fixed. This time the power is held fixed — the town needs all of it. |
| L3 | meaning (the enemy, names the destination) | Right now the wire takes most of the power as heat — the town gets what's left. |
| I1 | imperative | Raise the Voltage |
| L4 | meaning (post-discovery) | You only raised the voltage — the current fell by itself, keeping the power the same. |
| L5 | meaning (the mechanism) | Power is voltage times current — the area of this rectangle. The area is pinned: taller means narrower. |
| L6 | meaning (the 2.4 payoff, names the destination) | Less current, far less heat — the wire's heat falls with the square of the current. |
| I2 | imperative | Light the Whole Town |
| L7 | meaning (loss defeated, names where the power goes) | The wire's heat was the loss. Starve the wire of current and the power reaches the town instead. |
| I3 | imperative | Send It to the Top |
| L8 | meaning (named last) | This is the transmission trick: enormous voltage, tiny current, almost nothing lost as heat. |
| L9 | meaning (outward landing) | Real transmission lines run at hundreds of thousands of volts for exactly this reason. |

Rectangle center label (mono, IBM Plex Mono ~11, letter-spaced): `POWER · PINNED` with a small pin glyph. Side chips (mono): `VOLTAGE <n>` (left of the vertical edge) and `CURRENT <n>` (under the bottom edge). Card-earn brag line: `You starved the wire and lit the town.` CTA: `Continue`. No other text exists. No mascot, no info-cards, no inline fact (deliberate empty slot — L9 already carries the outward reach; a fact chip would crowd the finale).

## 6. Beat-by-beat flow (timing + gating)
Phase **intro** (auto, ~12 s):
1. 0 ms — scene entrance: plant slides/fades in (450 ms), wire draws across (450 ms, +200 ms stagger), town fades in (450 ms, +400 ms stagger). Wire is already HOT (glow + shimmer + motes); town dim, ~30 % windows, some flickering.
2. 1400 ms — L1 (hold 2600 ms).
3. 4000 ms — L2, the pin-flip naming (hold 3400 ms). Simultaneously the rectangle enters (scale+fade 450 ms, easeOutBack ≤0.45 s): a squat, WIDE slab (low voltage, huge current), warm-gold fill, `POWER · PINNED` + pin glyph pulses once, `selectionClick`.
4. 7400 ms — L3 (hold 3000 ms).
5. 10400 ms — I1 "Raise the Voltage" appears; drag handle on the rectangle's top edge pulses (scale 1.0→1.15 loop). **WAIT for the learner. Drag is enabled from this moment.**

Phase **raise** (interactive):
6. Vertical drag anywhere on the rectangle (forgiving hit zone) maps to voltage, clamped 10–200. **Same-frame** updates: rect height/width, both number chips, wire glow/shimmer/motes (∝ I²), pulse count/thickness on the wire (∝ I), town windows/bloom (∝ delivered). `selectionClick` at every +10 voltage detent crossed. Fully reversible — dragging down reheats the wire and dims the town (the relationship felt both ways).
7. **DISCOVERY latch** — first time voltage ≥ 20 (one-way): `heavyImpact`; brief discovery ring around the CURRENT chip (~700 ms envelope); fire `onCapture('current_drops_itself')` (lightImpact + capture flash).
8. +600 ms after latch — L4 (hold 3000 ms) → L5 (hold 3400 ms) → L6 (hold 3000 ms).

Phase **lightTown** (interactive):
9. I2 "Light the Whole Town". **Gate: delivered ≥ 0.95** (voltage ≈ 38+), one-way latch. On latch: remaining windows sweep on over 800 ms (the town bloom), `lightImpact`.
10. +500 ms — L7 (hold 3200 ms).

Phase **sendTop** (interactive):
11. I3 "Send It to the Top". **Gate: voltage ≥ 180 held continuously for 600 ms** (one-way latch — the steadiness makes the capture frame clean). On latch: fire `onCapture('cold_wire_full_town')`. By here the wire shows zero glow/shimmer/motes and the current side is a hairline sliver; pulses are few and thin but the town stays at full — current shrank, power didn't.
12. +400 ms — L8 (hold 3400 ms) → L9 (hold 3000 ms).

Phase **closing**:
13. +400 ms after L9 — `showCardEarn.value = true` → `CollectibleEarnOverlay` (transmission-trick card, eyebrow `NEW CARD`, brag above, `showMascot: false`).
14. `onCardCollected` → `canFinish.value = true` → gold Continue CTA in its fixed-height seat → tap → `Navigator.maybePop(context)`.

Gates are high-water marks: once latched, dragging back down never regresses a beat or re-fires a capture. Play length: ~12 s auto + 30–90 s interaction = 60–120 s.

## 7. Hero & layout (portrait) + clutter caps
**The hero is the pinned power rectangle** — the brightest, steadiest glow on screen (warm gold `#FFD27A` fill, soft additive bloom), live and manipulable; it is the mechanism AND the control, and the same rectangle returns in 5.1 (energy = power × time) — plant it well. The journey band (plant → wire → town) is the consequence stage above it: the plant is small and dim (it never changes); the wire's heat is saturated but thin (the enemy); the town's full-lit bloom is the one orchestrated payoff moment. Chrome recedes (glass fills `0x14FFFFFF`, borders `0x26FFFFFF`); background near-black `#070A1C` with radial vignette darkest behind the rectangle; ≤18 heat motes.
**Clutter caps:** 1 hero + 1 interactive element (the rectangle drag; back button + read-only board strip + end-state CTA are chrome) — well under the 6-element cap; **exactly 2 live numbers** (VOLTAGE, CURRENT); one current text line. Nothing else.

## 8. Reward — collectible card (concept IS a quick-reference row: "High voltage → low current → low loss | (the transmission trick) | Ep 2")
Propose (shared-infra agent finalizes number/constant; section **transmission**, accent `#3FB9F5`):
- **Front** — playful name: **Starve the Wire** · real term (mono specimen label): **HIGH-VOLTAGE TRANSMISSION** · law: *Fixed power: higher voltage means lower current — and the loss falls with the current squared.* · kicker: *Why pylon lines carry hundreds of thousands of volts.*
- **Back** — tie to what was felt: *You dragged the rectangle taller and the current thinned by itself — the wire went cold and the far town lit to full.* · outward reach: *The same pinned-area rectangle prices your electricity bill: energy is power × time.* · linked card: the I² card from 2.4 (this trick is how the squared loss is defeated); note for shared infra — the 5.1 kWh card links back to THIS card (the rectangle recurrence).
The card names the LAW; it does not re-narrate the activity, and it does not restate 2.4's card (which owns "loss grows with I²" — this card owns the fixed-power inversion).

## 9. CER capture hook (ids LOCKED for the EP2 evidence catalog)
- **`current_drops_itself`** — label: `Current Drops` · caption: *Raising the sending voltage made the current fall on its own — the pinned power stayed the same.* · **relevant** · fires at the discovery latch (step 7), framing the rectangle zone (proposed cropFactor ≈ Rect.fromLTRB(0.10, 0.42, 0.90, 0.98) of the scene).
- **`cold_wire_full_town`** — label: `Wire Runs Cold` · caption: *At huge voltage the current is a sliver — the wire stays cold and the whole town lights.* · **relevant** · fires at the sendTop latch (step 11), framing the journey band (proposed cropFactor ≈ Rect.fromLTRB(0.02, 0.02, 0.98, 0.44)).
Wiring per the shipped pattern: `RepaintBoundary(key: _sceneKey)` around background + GameWidget; `controller.onCapture = _onCapture` → `captureScenePng(_sceneKey, cropFactor: evidenceByIdFor(kEpisode2Id, id)?.cropFactor)` → `_board.capture(id, imageBytes: bytes)`; `EpisodeBoardStrip` pinned under the header with the EP2 question. Captures are idempotent and never block flow.

## 10. Build notes
- **Flame `GameWidget`** (living scene: particles, traveling pulses, window grid, shimmer) + Flutter overlay chrome — the trace_it_back template. GameWidget built once in `initState`; `backgroundColor` transparent; `onGameResize` → `controller.setStageSize`; `update(dt)` guards `dt > 0 && dt < 0.1` → `controller.tick(dt)`.
- **Gesture stays in Flutter:** a transparent `Listener` above the GameWidget forwards `onPointerDown/Move/Up(Offset local)` to the controller, which maps vertical delta → voltage only while the pointer started inside the rectangle's (generous) hit zone and phase ≥ raise. **No Forge2D**; no momentum — voltage holds exactly where the finger leaves it.
- Sim (all in controller, config-tuned): `V ∈ [10, 200]`, `I = 1000 / V`, `wireHeat = (I/100)²` (normalized 0–1), `lossFrac = 0.70 × wireHeat`, `delivered = 1 − lossFrac`, `townLit = f(delivered)` (window count + flicker below 0.5; all-on ≥ 0.95). Pixel mapping is LINEAR both axes (`heightPx = kV·V`, `widthPx = kI·I`) so the on-screen area is mathematically constant — the pin is exact, not approximate.
- Haptics: `selectionClick` per +10 V detent; `heavyImpact` at discovery; `lightImpact` on captures (inside `_onCapture`).
- Audio: **silent** (matches most shipped electricity activities).
- Reduced motion (`MediaQuery.disableAnimations`): shimmer becomes a static heat gradient, motes calmed, window sweep becomes a fast fade, entrance reveals become fades — but all same-frame causal updates (rect/numbers/heat/town) are untouched.
- Wrap the screen in `MediaQuery(...textScaler: TextScaler.noScaling)`. Completion = `Navigator.maybePop`. Do not touch registry/cards/evidence/wowConcepts files; reference `k<TransmissionTrick>Card` and EP2 evidence ids only.
- Verify: `fvm dart analyze lib/screens/missions/transmission_trick` clean.

## 11. Acceptance criteria (pedagogy as testable checks)
1. **Discoverable from interaction alone:** with all text ignored, dragging the pulsing handle up produces the full causal chain (current shrinks, wire cools, town brightens) with zero reading required.
2. **Same-frame causality:** rect width, both number chips, wire heat, pulse density, and town brightness all update in the SAME frame as the drag — no tween lag between cause and effect.
3. **The pin is exact and visible:** at every drag position, on-screen `heightPx × widthPx` is constant within 0.5 %; the `POWER · PINNED` label + pin glyph are visible whenever the rectangle is (label floats beside the rect when height < 0.06 h).
4. **The flip is named when it happens:** L2 (verbatim) appears at mission start, before interaction, and names BOTH pins (last mission's wire, this mission's power) — and never reveals that current will drop (no pre-spoiling the catch).
5. **The inversion is felt before explained:** L4/L5 appear only after the discovery latch (V ≥ 20 via the learner's own drag); the CURRENT number visibly ticks DOWN while VOLTAGE ticks UP.
6. **Catch/consequence lines name destinations:** L3 says the power leaves AS HEAT and the town gets what's left; L7 says the power REACHES THE TOWN — never "the power goes away" or behaviour/ending phrasing. No rhyme anywhere.
7. **Felt, not metered:** no loss %, no delivered %, no heat number, no brightness number anywhere; exactly 2 live numbers (VOLTAGE, CURRENT), relative, mono; no ratings table.
8. **The squared payoff reads:** wire glow/shimmer scale with I² (not I) — halving the current visibly quarters the heat; at V ≥ 180 the wire shows zero glow/shimmer/motes while the town stays at full.
9. **Current ≠ power is visible on the wire:** pulse count/thickness fall as voltage rises while the town stays bright once lit.
10. **Reversible but never regressing:** dragging down reheats/dims live; latched beats, captions, and captures never re-fire or rewind.
11. **Both captures fire exactly once** at their specified latches, with flash + light haptic, and tiles appear on the board strip; card fires after L9, exactly once; Continue appears only after `onCardCollected`; pop completes the activity.
12. **Hero dominance:** the rectangle is the brightest steady element; the plant never changes; chrome recedes; ≤18 motes; reduced-motion honored without weakening checks 2–3.
13. `fvm dart analyze lib/screens/missions/transmission_trick` is clean; small-phone portrait (≈360×640 logical) shows all zones without shrinking the rectangle below usability.

## 12. Anti-patterns (this activity)
- A separate slider for voltage — the rectangle itself is the control; a detached control demotes the mechanism to an illustration.
- A "% delivered" / loss meter or heat number — the town and the wire are the readouts; numbers ride alongside only as VOLTAGE/CURRENT.
- Pre-spoiling: any pre-drag text or visual hinting the current will drop (including an animated demo drag).
- The area visibly wobbling during drag (approximate tweening) — breaks the pin's credibility and the lesson with it.
- Smoothing the current's response so it lags the drag — cause and effect must be glued in time.
- Re-deriving I² here (2.4 owns the derivation; this beat cites and uses it — L6 only).
- Absolute units (volts, amps, kW) — relative numbers only; "hundreds of thousands of volts" lives in prose (L9), not in a readout.
- Making the plant detailed/bright or the town a thumbnail; clutter that competes with the rectangle.
- A premium fade on the heat response, or letting beats regress when dragging down.

## 13. Open decisions
1. Relative number scheme: proposed 10→200 / 100→5 (product 1000); tune ranges + detent size on device.
2. Journey band orientation: proposed horizontal band (plant left → town right) above the rectangle; if small-phone width starves the town, fall back to plant top-left / town bottom-right diagonal within the band.
3. Final cropFactors for the two tiles (evidence-catalog agent owns; proposals in §9).
4. Card constant name/number (`kStarveTheWireCard` proposed) and final link wiring — shared-infra agent owns.
5. Whether the town's dim-state flicker at start reads as "starved" without implying a grid fault — tune flicker amplitude.

## 14. State machine sketch
```dart
enum TTPhase { intro, raise, lightTown, sendTop, closing }   // engine/transmission_phases.dart or in controller
enum TTCaption { none, l1Town, l2PinFlip, l3Enemy, i1Raise, l4Dropped, l5Rectangle,
                 l6Squared, i2LightTown, l7Starve, i3SendTop, l8Trick, l9RealLines }
```
`TransmissionController extends ChangeNotifier`:
- **ValueNotifiers:** `caption: ValueNotifier<TTCaption>` (copy table marks imperative vs meaning per id), `phase: ValueNotifier<TTPhase>`, `showCardEarn: ValueNotifier<bool>`, `canFinish: ValueNotifier<bool>`.
- **Hot-path getters (read by Flame layers):** `voltage`, `current` (= 1000/voltage), `wireHeat` ((I/100)²), `delivered`, `townLit`, `rectRectPx` (baseline-anchored, linear kV/kI mapping), `handlePulse` (loops until first drag), `flashIntensity`, entrance reveals (`plantReveal`, `wireReveal`, `townReveal`, `rectReveal`), `pulsePhase`, `motes`.
- **Input:** `onPointerDown/Move/Up(Offset local)` — down inside rect hit zone (rect inflated ×1.4) arms the drag; move maps `-dy → dV` (≈ full stage-height drag ≈ full range); clamp [10, 200]; up freezes voltage (no inertia). Detent haptic via `onDetent` hook each +10 crossing.
- **Timers:** `_schedule(ms, fn)` chain per §6 — intro: 1400/4000/7400/10400 ms; post-discovery: +600 → L4 (3000) → L5 (3400) → L6 (3000); lightTown: +500 → L7 (3200); sendTop: +400 → L8 (3400) → L9 (3000) → +400 card. `tick(dt)` (≤60×/s from Flame) advances reveals, pulses, motes, the sendTop 600 ms steadiness window, and latch checks.
- **Latches (one-way bools):** `_discovered` (V ≥ 20, phase raise) → heavyImpact + `onCapture('current_drops_itself')` + caption chain; `_townLit` (delivered ≥ 0.95) → window sweep + L7; `_topped` (V ≥ 180 continuously 600 ms) → `onCapture('cold_wire_full_town')` + closing chain.
- **Gating:** drag enabled iff `phase.value.index >= TTPhase.raise.index`; captures/card fire exactly once; `onCardCollected()` → `canFinish.value = true`.
- **Hooks:** `onDetent` (selectionClick), `onDiscovery` (heavyImpact), `onCapture(String id)` (lightImpact + PNG in shell). `reducedMotion: bool` set from MediaQuery each build.

## 15. File plan (mirror trace_it_back)
```
lib/screens/missions/transmission_trick/
├── transmission_trick_screen.dart        — shell: noScaling MediaQuery, RepaintBoundary(_sceneKey) around
│     background + GameWidget, transparent Listener forwarding pointers, header (back), EpisodeBoardStrip
│     (EP2 question), _FadeSwapCaption top text (fixed height, 190 ms swap), fixed-height CTA seat,
│     CaptureFlash, CollectibleEarnOverlay; EpisodeBoardCapture('episode2_electricity').load(); maybePop
├── state/transmission_controller.dart    — ChangeNotifier per §14 (sim + geometry + phase machine + latches)
├── config/transmission_tuning.dart       — TTTune: vMin 10 · vMax 200 · viProduct 1000 · lossAtStart 0.70 ·
│     discoveryV 20 · townDeliveredGate 0.95 · topV 180 · topHoldMs 600 · detentV 10 · kV/kI px factors ·
│     anchor factors (§16) · all timer ms · mote cap 18 · pulse count 2–14
├── config/transmission_beats.dart        — TTCaption enum + verbatim copy table (§5) + isImperative flag +
│     hold durations
├── game/transmission_game.dart           — FlameGame: transparent bg, adds layers back→front, onGameResize →
│     controller.setStageSize, update → controller.tick
├── game/components/journey_layer.dart    — plant (compact, static), 2 pylons + catenary wire, heat glow/
│     shimmer/motes ∝ wireHeat, traveling pulses (count/thickness ∝ current, additive)
├── game/components/town_layer.dart       — building cluster, window grid ∝ townLit (flicker when starved),
│     warm bloom, 800 ms full-lit sweep on _townLit
├── game/components/rectangle_layer.dart  — THE HERO: pinned-area rect (gold fill + additive bloom),
│     POWER · PINNED + pin glyph (floats beside rect when thin), VOLTAGE/CURRENT mono chips riding the
│     edges, top-edge drag handle + pulse, discovery ring on the CURRENT chip
└── widgets/energy_field_background.dart  — static dark vignette + faint circuit texture (copy-adapt from
      trace_it_back)
```

## 16. Scene sketch (portrait, top → bottom; factors of stage size w × h)
1. **Header** (SafeArea): back button on glass; title "The Transmission Trick" (Bricolage 21 w800); mono eyebrow `EPISODE 2 · TRANSMISSION`.
2. **EpisodeBoardStrip** — EP2 question pinned + captured mini-tiles.
3. **Top text** — fixed-height (~96) caption seat: imperatives Bricolage 28 w800 / meaning-lines PJS 18 (L2/L5/L8 render ~16.5).
4. **Stage (Expanded), journey band y 0.02–0.42 h:** plant at x 0.05–0.20 w (base y 0.36 h, stack + low building, dim, static); pylons at x ≈ 0.36 w and 0.62 w (tops y ≈ 0.10 h); catenary wire from plant terminal (0.19 w, 0.16 h) sagging ~0.05 h between supports to the town feed (0.84 w, 0.18 h) — heat glow/shimmer hugs the wire; town at x 0.68–0.96 w (bases y 0.40 h, heights to 0.16 h), window grid + bloom.
5. **Rectangle zone y 0.46–0.98 h:** baseline at y 0.92 h, centered on x 0.5 w; `heightPx = 0.0023 h × V` (0.023 h squat slab at V 10 → 0.46 h column at V 200); `widthPx = 0.0062 w × I` (0.62 w at I 100 → 0.031 w hairline at I 5); drag handle = 0.09 w pill with chevron-up centered on the top edge; `VOLTAGE` chip tracks the left edge's vertical midpoint, `CURRENT` chip sits 0.02 h below the bottom edge center; `POWER · PINNED` centered inside when height ≥ 0.10 h, else floating right of the rect with the pin glyph pointing in.
6. **CTA seat** (fixed 84): gold gradient `#F5C451 → #D9A43B` Continue pill after card collection.
All geometry factor-based off `setStageSize`; vignette darkest behind the rectangle zone.
