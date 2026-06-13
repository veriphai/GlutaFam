# PRD — Wire the Street (Episode 5, beat 5.3)
### howwow electricity · registry id `one_shared_grid` · class `OneSharedGridScreen` · `lib/screens/missions/one_shared_grid/` · evidence episode `episode5_electricity`

Binding context: `docs/electricity/context_pack.md` (the covenant), `docs/electricity/architecture_reference.md`, and `howwow_electricity_curriculum.md` §1–§9 + beat 5.3. This PRD is **self-contained** — every on-screen line is quoted verbatim here; nothing is delegated to another doc. No mascot, no Voltix, no info-cards. **No depth-stop in this beat** — every "why" bottoms out in cost arithmetic and one civic decision, all showable (curriculum §6, EP5 has no honest floor).

**Chain inheritance (what the learner already felt).** 5.1 — you pay for *energy* (power × time, the kWh rectangle). 5.2 — the price of a unit at any hour tracks the plant mix the rush switches on (peak pricing). So **"price"** and **"the company you pay"** are inherited vocabulary. This beat asks a different question entirely: not *what a unit costs at 6pm*, but *why there is only one company on the street at all — and who keeps its price fair*. No time-of-day, no kWh, no demand curve, no peaker appears here.

**What this beat pins (held constant, visibly).** (a) The **twelve homes** — a `HOMES 12` chip that never moves through the whole build phase, and the houses themselves never change geometry. (b) The **homes' window brightness** — identical whichever company's wire feeds them (the proof that the electricity is the same product). (c) The **electricity itself** — the gliding energy pulses are the SAME warm gold, SAME speed, SAME packet count on every network; only the poles/wire *hardware* are company-tinted. The only thing the learner's action changes in Phase A is the **number of wire networks** (and the cost); in Phase B, the **price** (and the windows it can or can't keep lit).

---

## 1. One-concept statement

**The grid is a natural monopoly — one shared network beats many competing ones — which is why electricity is a regulated utility.**

The regulator is not a second idea: it is the *consequence clause* of the same idea — where competition cannot exist, a price cap stands in for it. Both halves are **felt before either is named**. (If this needed an "and," it would be two activities; it does not — it is one idea with a consequence.)

## 2. Guiding-question link + CER contribution

Episode question, pinned on the board strip all activity (verbatim): **"Who pays for all this - and why does 6pm cost more than 3am?"**

This beat answers the **"who pays for all this"** half from a structural angle the other EP5 beats don't touch: *why the whole street is paid for once, through one company, and why a referee caps that company's price.* It does **not** touch the "why 6pm" half (that is 5.2's job).

- **Relevant evidence — `street_choked`:** the street under three full wire networks, `COST 300`, `HOMES 12` frozen. The "who pays" insight: every duplicate pole and wire would land on the same twelve homes — which is *why* there is one network, paid for once, by everyone.
- **Relevant evidence — `price_capped`:** the lone network with the price column held at the regulator's cap, every window relit. The "who keeps what you pay fair" insight: a regulator, standing in for the competition that cannot exist here.
- **Distractor candidacy (per the evidence rule — TRUE-but-irrelevant to the episode question).** A third capturable moment exists and is offered as the beat's distractor: **`identical_pulses`** — the frame where the same gold electricity glides on all three rival networks at once. It is **true** (the electricity is genuinely identical across companies) but **irrelevant to "who pays / why 6pm"** — it answers *whether the rival product differs* (it doesn't), a sidebar, not the bill. Flag for the catalog owner: include it only if the finale CER wants a second EP5 distractor; otherwise drop it (the two relevant tiles are the load-bearing ones).
- **Standing note:** EP5 has **no separate episode CER** — its closer is the grand finale CER (separate PRD, `prd_make_your_case_finale.md`). These tiles feed the episode board strip and are selection candidates for the finale catalog. The finale PRD currently consumes neither 5.3 tile (it treats "one company" as a civic aside, not a journey stage) and uses `street_choked` only as a screened-out distractor candidate — both ids are nonetheless declared here so the EP5 catalog (`evidence_models_ep5.dart`) can ship them for the board strip and the finale's selection pool. Do not change the finale's choice; just expose the tiles.

## 3. The felt discovery (discovery → reaction)

The interaction **is** the concept: the learner personally **builds the competing-companies world, watches it waste, tears it back to one — then watches what an unrivalled price does until they cap it.** Nobody narrates "monopoly"; the learner's own hand makes the waste and the fix.

1. **Discovery — the duplicate build.** The learner drags a second company's wire run across the same street, pole by pole. **Reaction:** poles thunk in, wire pays out behind the finger with catenary sag, `COST` climbs `100 → 200` in the same frames — and `HOMES` sits at `12`, unmoved. Six homes switch their service drop over to the new company: their windows do not change by one candela. Same street, same light, double the wires.
2. **THE discovery — the absurdity compounded.** A third drag, a third company. **Reaction:** the sky over the street becomes a thicket; `COST` hits `300`; the identical gold pulses glide on all three networks at once; `HOMES` still reads `12`. The learner *built* the waste with their own hand — three networks for the same twelve homes carrying the same electricity. (`heavyImpact`, capture `street_choked`.)
3. **Discovery — the relief.** Reverse drags reel the rivals back out. **Reaction:** the street breathes, `COST` falls live to `100`, every home stays served, nothing was lost. One network was always enough. **Only now is it named: a natural monopoly.**
4. **Discovery — the new problem, felt.** With the street consolidated, the lone company's `PRICE` column starts climbing — nothing on screen opposes it — and homes that can no longer afford it go dark, two at a time, in the same frame each threshold is crossed. The perfectly-wired street goes dim *for cost, not for wires*.
5. **Discovery — the fix is theirs.** The learner drags a cap bar down the price rail; the price compresses beneath it, windows relighting threshold by threshold as it falls; the cap refuses to drop below the cost of the wires. Released in the fair band, it holds. **Only then is the cap named: the regulator.**

## 4. Felt vs named vs numbered

- **Felt (visual consequences, never a stat):** the wire-sky thickening per network (clutter = cost made visible); poles thunking in under the finger; the six service drops swinging companies with **zero** change in window brightness; identical warm pulses on all three networks; the reel-back relief; windows snapping dark as the price crosses thresholds; windows relighting as the cap pushes the price back down; the cap's hard floor-bounce at the cost of the wires.
- **Named (a beat *after* felt):** **natural monopoly** — only after one-serves-all-cheaper has been built, witnessed, and undone by hand (T11). **regulator** — only after the cap has held and the windows relit (T16). **regulated utility** — last, in the synthesis (T17). "Company" and "network" are *visible objects* — named on sight (T2, T4).
- **Numbered (live, relative, ≤2 on screen at any time):** Phase A — `COST` (one full network = 100; climbs in lockstep with lay progress; trend arrow while changing) and `HOMES` (pinned at 12 — the held-constant made visible). Phase B — the chips crossfade out and a single `PRICE` number rides the price column (fair = 100, relative; never a currency symbol). The cap is a **bar, not a number**.
- **No ratings table. No per-company stat panel. No number for any qualitative judgment** — waste is *clutter*, unaffordability is *dark windows*. (Curriculum §3/§4: the one banned thing is a static pros/cons grid; these live relative numbers are exactly what makes the relationship deducible.)

## 5. On-screen text — EXACT, beat by beat

Imperatives = Bricolage Grotesque, large, Title Case, ≤5 words (instruct only). Meaning-lines = Plus Jakarta Sans, de-personified facts (short ones Title Case at display size, long ones sentence case at body size). Swap = 190 ms fade-out → swap → fade-in (never cross-fade). Every line is a state-independent fact; none pre-spoils a later beat.

| # | Phase | Register | Line (verbatim) |
|---|---|---|---|
| T1 | intro | meaning | `One street, one network. Twelve homes, every window lit.` |
| T2 | intro | meaning | `Phone companies compete, each with its own towers and lines. Why not electricity companies too?` |
| T3 | laySecond | imperative | `Lay a Second Network` |
| T4 | laySecond complete | meaning | `A second company - a full second set of poles and wires, down the same street.` |
| T5 | switchOver | meaning | `Six homes switch over. Their light does not change - the electricity in every wire is identical.` |
| T6 | layThird | imperative | `Now Lay a Third` |
| T7 | choked (discovery) | meaning | `Three Networks for the Same Street` |
| T8 | choked | meaning | `Every pole and every wire must be paid for - and the only people who can pay are the same twelve homes.` |
| T9 | clearWires | imperative | `Clear the Extra Wires` |
| T10 | oneShared | meaning | `One shared network serves every home - for a third of the cost.` |
| T11 | oneShared (naming) | meaning | `One network for everyone beats rivals each building their own. That is a natural monopoly.` |
| T12 | priceClimb | meaning | `No rival undercuts the only company on the street. Nothing stops the price.` |
| T13 | priceClimb (first dark homes) | meaning | `Homes that cannot pay go dark - wired to a network they can no longer afford.` |
| T14 | capPrice | imperative | `Cap the Price` |
| T15 | capped (cap holds) | meaning | `The Cap Holds - Every Window Relights` |
| T16 | capped (naming) | meaning | `The cap is held by a regulator. It sets the rules and the price, standing in for the competition that cannot exist here.` |
| T17 | synthesis | meaning | `One shared network, with a regulator holding the price fair - that is why electricity is a regulated utility.` |
| T18 | bridge (persists) | meaning | `So who pays for all of it? The answer arrives every month - the bill.` |
| G1 | capPrice (cap pushed below 100, once) | meaning | `The cap cannot fall below the cost of the wires - the network must still be paid for.` |
| G2 | capPrice (cap released above fair band, after 1600 ms) | meaning | `Homes are still dark - the cap sits above a fair price.` |

Notes on the copy, for the build agent:
- **T2 is the only mention of phone networks** — one line of text, never modeled on screen (no towers, no second visual world). It poses the learner's own natural question; the activity answers it by *doing*.
- **T13 names the consequence/destination** (homes go dark; *a network they can no longer afford*), never the behaviour ("the price keeps rising"). This is the §3 catch-line rule.
- **T7 and T15** are the short Title Case meaning-lines (sibling precedent: 5.2's "The Spike Outran the Plant" / 1.1's "Only a Moving Magnet Works") — a discovery and a relief that an imperative can't carry.
- **T18 poses 5.4's question** without revealing the receipt/itemization — no "receipt", no slices.
- **Card-earn brag** (the `CollectibleEarnOverlay` one-liner): `Why your electricity company has no rival.`

## 6. Beat-by-beat flow (timing in ms + gating)

Text swaps 190 ms. Play-length target ≈ **90–135 s** (within the 60–150 s window; Phase A ≈ 50 s, Phase B ≈ 45 s, plus card/CTA). `COST`/`PRICE` are relative (one network = 100; fair price = 100). All timings are wall-clock ms from phase entry unless noted.

| Phase | What happens | Timing / gate |
|---|---|---|
| `intro` (auto) | Entrance reveals: street + houses fade/slide 0→450 ms; network A strings itself across 450→1500 ms; windows warm up staggered; gold pulses begin. Chips appear: `COST 100`, `HOMES 12`. T1 at 700 ms; T2 at 3400 ms. | auto → `laySecond` at **6200 ms** |
| `laySecond` | T3. Grab hint pulses at the left end of the B crossarm height. Horizontal drag (left→right) anywhere in the wire-sky band: progress = high-water of pointer x; 5 poles thunk in at fixed detents (`selectionClick` each); wire pays out behind the finger with catenary sag; `COST = 100 + 100·progress` **same frame**. B hardware tinted cool blue; **no pulses on B until the run completes**. | gate: `layProgressB ≥ 0.98` → B settles, identical gold pulses start on B, T4 at +400 ms → 3000 ms → `switchOver` |
| `switchOver` (auto) | Six service drops swing from A to B, staggered 150 ms (≈1.2 s total). Window brightness **provably unchanged** (same value asserted before/after). T5 at 1400 ms. | auto → `layThird` at **5600 ms** |
| `layThird` | T6. Same gesture at the C crossarm height (magenta-tinted hardware); poles jostle visibly into the now-crowded sky; `COST 200 → 300` live with the drag. | gate: `layProgressC ≥ 0.98` → C pulses start → 600 ms → `choked` |
| `choked` (auto) | All three networks pulse **identically**. At 600 ms: T7 + `heavyImpact` + `onCapture('street_choked')` (COST 300 · HOMES 12 both in frame). T8 at 3400 ms. | auto → `clearWires` at **8000 ms** |
| `clearWires` | T9. Reverse drag (right→left) in the wire-sky reels the topmost rival: C poles pop out under the finger (`selectionClick` each), `COST` falls live. A second reverse pass reels B; as B reels, its six drops swing back to A (120 ms each), windows never dim. A forward drag does nothing; the grab-hint arrow points left. | gate: `clearProgressC ≥ 0.98 && clearProgressB ≥ 0.98` → `oneShared` |
| `oneShared` (auto) | Street clean; A's pulses glide; `COST 100`, `HOMES 12`. T10 at 400 ms; T11 at 3600 ms (the **first** naming: natural monopoly). | auto → `priceClimb` at **7600 ms** |
| `priceClimb` (auto) | Chips crossfade out; the PRICE rail slides in at the right edge (600 ms) with the price column at 100 and the mono number riding its top. Price climbs ≈ **9 units/s**. T12 at 2600 ms. At price 140 (~4.4 s): **two windows snap dark in the same frame** + T13; another two homes go dark per +30 after that. Climb continues toward a plateau of 320 (**2 homes always stay lit — never total darkness**). | auto → `capPrice` at **5200 ms** (the climb continues *inside* `capPrice`) |
| `capPrice` | T14. The cap bar slides in at the rail top (340 mark), small mono label `CAP`. Vertical drag: the bar tracks the finger instantly; `price = min(price, cap)` **same frame**; windows relight threshold by threshold as price falls back through them (reversible while dragging). Hard floor at 100: the bar refuses + soft 80 ms bounce + G1 (fires once). Release inside the fair band **[100, 130]** (a faint gold notch zone on the rail) → success. Release above the band: price holds at the cap, homes above thresholds stay dark, after 1600 ms G2; remain in `capPrice` until placed fairly. | gate: cap released with `capValue ∈ [100, 130]` → `heavyImpact` + `onCapture('price_capped')` → `capped` |
| `capped` (auto) | Relight cascade completes ≤ 900 ms; price column rests at the cap. T15 at 0 ms; T16 at 2200 ms (the **second** naming: regulator). Interaction locked. | auto → `synthesis` at **6400 ms** |
| `synthesis` (auto) | T17 alone, full size — the one-concept landing. Scene calm: one network, fair price, twelve lit homes. | auto → `bridge` at **4200 ms** |
| `bridge` (auto) | T18 at 0 ms, **persists** behind card and CTA. | at 3800 ms → `showCardEarn = true` |
| `done` | Card overlay → "Add to your deck" → Continue CTA (gold pill) → `Navigator.maybePop`. | — |

Gating summary: every auto-advance is timed; every learner-gate (lay B, lay C, clear B+C, cap-in-band) is a **hard threshold** — the flow does not advance on a timer past an ungated build/clear/cap. The `choked` discovery (T7 + heavy haptic + capture) is **latched once**. `street_choked` and `price_capped` capture exactly once each.

## 7. Hero & layout (portrait, clutter caps)

- **The one hero: the street cross-section** — the **wire-sky** (poles + up to three catenary networks with gliding warm pulses) above, and the terraced row of **twelve homes** below, read as one scene (cause above, consequence beneath). Brightest pixels: the warm windows and the gold pulses. In `choked`, the triple thicket of wires is the loudest *shape* while the pulses stay the loudest *light*.
- **What recedes:** near-black `#070A1C` base; radial vignette darkest behind the houses; chips in dark glass (`0x14FFFFFF` fill, `0x26FFFFFF` border); the PRICE rail is chrome (thin, glass-framed, **never** brighter than the windows); board strip standard gold (`#E8C98A`).
- **Clutter caps (this screen):** hero street; **one live gesture surface at a time** (the wire-sky for lay/clear; the cap bar for capPrice) — **interactive elements ≤ 2** at any moment (plus the Continue CTA at the very end), far under the 6 cap; **≤ 2 live numbers** (Phase A: COST + HOMES; Phase B: PRICE only); the current text line; the pinned board strip. **Nothing else** — no company logos, no legend, no price-history graph, no phone-network visual, no per-company panel.
- **Portrait order, top-to-bottom:** header → board strip → top text (fixed h=96) → wire-sky → service drops → house row → chips row (Phase A) → CTA seat. The PRICE rail overlays the right edge of the scene in Phase B. Full sketch in §16.

## 8. Reward

**Card: YES.** "One efficient network, price-capped → **natural monopoly / regulation**" is a row in the curriculum quick-reference table, and the context pack (§6) names an EP5 natural-monopoly card explicitly. The shared-infra agent assigns the final number + motif painter and updates `deckTotal` on all constants; this build only references the constant `kOnlyGameInTownCard`. Section `theBill`, accent `#E0A96D`.

- **Front — playful name:** `The Only Game in Town`
- **Front — real term (mono specimen label):** `NATURAL MONOPOLY / REGULATION`
- **Front — one-line law:** `Where one shared network beats many competing ones, a regulator stands in for the competition that cannot exist.`
- **Front — kicker:** `One wire for everyone - and a referee on the price.`
- **Back — tie to what was FELT:** `You laid three full sets of wires down one street - triple the cost, the same twelve homes, the same electricity in every wire. Cleared back to one, the price climbed unopposed until you capped it.`
- **Back — outward reach:** `Water mains, gas pipes and railway tracks work the same way - one shared network, one regulator watching the price.`
- **Linked card:** **none.** Natural monopoly is not one of the curriculum's four flagged recurring ideas (§8: induction, the fixed-area rectangle, loss-as-heat, baseload/peaking); no link invented. (A card may not restate another card's law — this one names monopoly/regulation, which no existing card touches.)
- **Motif suggestion (for the painter owner):** one clean catenary wire across two poles, with two ghost wire-sets fading above it.

**Inline fact: none** (info-cards are removed module-wide; deliberate empty slot — a fact mid-flow would risk pre-stating the conclusion).

## 9. CER capture hook

`RepaintBoundary(key: _sceneKey)` wraps background + GameWidget; `controller.onCapture = _onCapture` → `captureScenePng(_sceneKey, cropFactor: evidenceByIdFor('episode5_electricity', id)?.cropFactor)` → `_board.capture(id, imageBytes: bytes)`; `EpisodeBoardStrip` pinned under the header with the episode question. Proposed tiles for the EP5 catalog (ids LOCKED here; catalog owner finalizes motifs/crops):

| id | label (≤3 words) | caption (one line) | relevant? | onCapture fires at |
|---|---|---|---|---|
| `street_choked` | `Triple the Wires` | `Three full networks down one street - triple the cost, the same twelve homes, the same electricity.` | RELEVANT | `choked`, the T7 discovery frame (third network complete, COST 300 + HOMES 12 visible) |
| `price_capped` | `The Cap Holds` | `With no rival, the price climbed until a regulator's cap held it - and every window relit.` | RELEVANT | `capPrice → capped` transition (cap released in the fair band, with the `heavyImpact`) |
| `identical_pulses` | `Same Electricity` | `The very same current flowed on every company's wire - the rival product was no different.` | DISTRACTOR (true-but-irrelevant) | `choked`, +1200 ms after T7 — optional; emit only if `evidence_models_ep5.dart` requests a 3rd EP5 distractor (see §2) |

Suggested cropFactors: `street_choked` → `Rect.fromLTRB(0.04, 0.06, 0.96, 0.70)` (wire thicket + house row, chips excluded); `price_capped` → `Rect.fromLTRB(0.22, 0.04, 0.98, 0.70)` (price rail + relit homes); `identical_pulses` → `Rect.fromLTRB(0.04, 0.04, 0.96, 0.44)` (wire-sky only, the three pulse-streams). The two RELEVANT captures are non-optional and always fire; `identical_pulses` is gated behind a tuning flag so the default flow stays clean.

## 10. Build notes

- **Flame `GameWidget`** for the living scene (poles, three catenary networks, shared pulses, service drops, the 12-house row, ambient motes) — a multi-layer animated world; the `trace_it_back` / `source_personalities` Flame-scene + Flutter-overlay pattern. **Flutter overlay** for chrome: header, `EpisodeBoardStrip`, `_FadeSwapCaption` top text, chips, the `PriceCapRail` widget, CTA, `CaptureFlash`, `CollectibleEarnOverlay`. GameWidget built **once** in `initState`; `backgroundColor() => const Color(0x00000000)` so the Flutter background shows through the RepaintBoundary.
- **No Forge2D.** All motion is controlled: lay/clear progress is a **high-water/low-water transport** of the pointer's x; pole pops and drop swings are explicit envelopes; the price climb is `rate × dt` in `controller.tick`; window dark/relight states are **hard per-frame functions** of price vs thresholds — never decayed/coasting values.
- **Controller-owns-geometry:** `OneSharedGridController extends ChangeNotifier` owns the street model, phase machine, price model, and all factor anchors via `setStageSize`. Flame components are **pure renderers** reading getters. Gesture stays in Flutter: a transparent `Listener` above the GameWidget forwards pointers to the controller (shipped pattern).
- **`PriceCapRail`** is a Flutter precision widget (the lever pattern, like `crank_surface`/`time_scrubber`): the bar = the learner's cap (instant, zero smoothing); the column = the price from the controller; the fair-band notch painted on the rail; the floor refusal = clamp + 80 ms bounce envelope.
- **Identical-pulse rule, enforced in code:** one shared pulse renderer parameterized only by the network's polyline — color `#FFD27A`, speed and packet-count are constants **shared** across A/B/C (the constancy is literal, not just visual). Company tint applies to the poles/wire stroke sheen only.
- **Haptics:** `selectionClick` per pole plant/pop and per cap detent (every 20 price units); `heavyImpact` at the `choked` discovery (T7) and the cap landing; `lightImpact` inside `_onCapture` (medium impact lives inside the card overlay already).
- **Audio:** silent by default (most shipped electricity activities are). Optional BGM loop ≤ 0.2 via the `audioplayers` + `AudioContext` `mixWithOthers` pattern if EP5 gets episode-wide audio.
- **Reduced motion** (`MediaQuery.disableAnimations`, read each build): calm motes, reveals become fades, drop-swings shorten — **but** the window dark-snaps at thresholds and the same-frame COST/lay coupling are pedagogy and are **NEVER** softened.
- **Chips:** `displayCost` / `displayPrice` sampled ~5 Hz into ValueNotifiers (legible ticking, not 60 Hz jitter), mono font, dark glass, trend arrow on whichever is moving.
- **Accessibility & shell:** wrap in `MediaQuery(...textScaler: TextScaler.noScaling)`. Completion = `Navigator.maybePop(context)` from the Continue CTA. `CollectibleEarnOverlay(card: kOnlyGameInTownCard, eyebrow: 'NEW CARD', brag: 'Why your electricity company has no rival.', showMascot: false, onDone: controller.onCardCollected)`.
- **File-surface rule:** write ONLY inside `lib/screens/missions/one_shared_grid/`. The EP5 evidence catalog (`evidence_models_ep5.dart`), the card constant/painter, the registry entry, and wowConcepts wiring belong to other phases — call the ids/constant, never define them here.
- **Persistence:** none beyond the shared evidence board and card store.
- **Verification:** `fvm dart analyze lib/screens/missions/one_shared_grid` clean (the repo's ~468 pre-existing errors in unreferenced files are not yours; never run repo-wide `flutter analyze` with multiple paths). `fvm dart analyze` each imported shared file individually to confirm imports resolve.

## 11. Acceptance criteria (pedagogy as testable checks)

1. **Discoverable from interaction alone (text hidden):** dragging strings a complete second wire network; `COST` visibly doubles in lockstep with the drag while `HOMES` never moves; the third network visibly chokes the sky; reverse drags clean it; the cap drag pushes the price down and relights windows. The one concept reads from hands + scene **before** any line is read.
2. **Waste is felt through cost/clutter, never tedium:** one continuous drag (≈2–4 s) lays a full network; no per-pole tapping grind; the lay gesture never fails for ergonomic reasons (the struggle, if any, is *economic absurdity*, not finger-fiddling — curriculum trap §9).
3. **Identical electricity (assert equality, not approximation):** pulse color, speed, and packet count are bit-identical shared constants across networks A/B/C; window brightness value is **identical** before and after a home's supplier switch.
4. **Held-constant is visible:** `HOMES 12` is on screen and unchanged from `intro` through `oneShared`; the twelve houses never change geometry; T5 states the brightness identity only *after* the switch is witnessed.
5. **Same-frame coupling:** `COST` tracks lay/clear progress with zero eased delay (≤ 1 frame); each window dark-snap occurs in the **same frame** its price threshold is crossed (no fade-out tail); relight during the cap-drag tracks the clamped price per frame.
6. **Name-last:** "natural monopoly" appears nowhere (text, labels, art) before T11; "regulator"/"regulated" nowhere before T16/T17; the cap bar is labeled only `CAP` while live.
7. **The price climb is unstoppable except by the cap:** no timeout resolves it; plateau at 320 with exactly **2 homes still lit** (never total darkness); cap floor at 100 refuses with G1 (once); release above the fair band leaves homes dark and fires G2 at 1600 ms; success **only** on release within [100, 130].
8. **Numbers discipline:** at most 2 live numbers at any time (COST+HOMES in Phase A; PRICE alone in Phase B); all relative (network = 100, fair = 100); no currency symbol; no ratings table; no per-company stats; no phone-network visual.
9. **Captures fire correctly:** `street_choked` and `price_capped` fire exactly at the §9 moments, idempotently, each with `lightImpact`; `identical_pulses` fires only when its tuning flag is on; the board strip shows the EP5 question all activity.
10. **Text registers:** imperatives ≤ 5 words Title Case (instruct only); meaning-lines de-personified facts; T13 names the consequence/destination; 190 ms fade-out → swap → fade-in (never cross-fade); T18 persists behind card and CTA; **no rhyme / sing-song cadence** anywhere.
11. **5.4 stays unspoiled:** no occurrence of "receipt"; no bill breakdown/itemization; no bill imagery; T18 only poses the question.
12. **Flow integrity:** completion = Continue → `Navigator.maybePop`; `CollectibleEarnOverlay(showMascot: false)` references `kOnlyGameInTownCard`; `MediaQuery noScaling` wrapper present; reduced-motion respected per §10; `fvm dart analyze` clean on the activity dir.

## 12. Anti-patterns to avoid (this activity)

- **A bar-chart or table comparing the three companies** — the street IS the comparison; clutter and COST carry it.
- **Tinting the pulses per company** — different-colored electricity would imply different products; only *hardware* is tinted. The identical gold pulse is load-bearing (it's why a duplicate company is pure waste).
- **Making the build a grind** (tap-per-pole, slow paywall-style progress) — the absurdity must be *economic*, not *ergonomic*; one smooth drag per network.
- **Pre-spoiling:** no "wasteful" before the third network is felt; no "monopoly" before the clear; no regulator/cap visible before the price has climbed and homes have gone dark.
- **A greedy-CEO villain framing** — the price climbs as a *fact of absent competition* (T12), de-personified; no moustache-twirling, no company mascots, no "evil monopolist".
- **Total blackout during the climb** — despair is not the lesson; 2 homes stay lit and the plateau holds until the learner acts.
- **Auto-snapping the cap to the fair band** — the learner *places* it; the system only refuses below cost (G1) and nudges when left above fair (G2).
- **A second number on the price rail** (cap value, company profit) — the cap is a *bar*; PRICE is Phase B's only number.
- **Entangling 5.2** — no time-of-day, no peak/off-peak, no kWh, no peaker here; this beat is about the network and its single owner, not the hourly unit price.
- **A premium fade softening the window dark-snaps** — thresholds are hard gates (covenant §9).
- **Narration instead of naming** — the meaning-lines state facts; nothing addresses the reader as a child or explains in an imperative.

## 13. Open decisions

1. **Tuning constants** (climb 9 units/s, plateau 320, dark thresholds at 140/+30, fair band [100,130], 5 lay detents/network): defaults specified; tune on device so the climb reads *urgent but uncapped* for ≥ 5 s and the cap placement feels deliberate, not twitchy.
2. **Home count and split** (default 12 homes; 6 switch to company B): adjust 10–14 for small-phone width; the switch-over count only needs to read as "about half".
3. **Clear-gesture passes** (default two right→left passes, one per rival): a single sweep clearing both is acceptable if two passes test as friction.
4. **Header title** (default "Wire the Street"; eyebrow `EPISODE 5 · THE BILL`): "One Shared Grid" deliberately rejected as the on-screen title because it pre-states the conclusion; the integrator may align with the episode-list naming if needed.
5. **Company tints** (default B `#5CA8FF`, C `#B45CFF`): must stay clearly dimmer than the gold pulses and distinct from the board-strip gold.
6. **`identical_pulses` distractor tile** — ship it in the EP5 catalog but default the capture flag OFF; the finale/catalog owner decides whether a second EP5 distractor is wanted (§2/§9).
7. **BGM:** silent by default; optional ≤ 0.2 loop if EP5 gets episode-wide audio.

---

## 14. State machine sketch

```dart
enum OSGPhase {
  intro, laySecond, switchOver, layThird, choked, clearWires,
  oneShared, priceClimb, capPrice, capped, synthesis, bridge, done,
}

enum OSGLine {
  none, t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11,
  t12, t13, t14, t15, t16, t17, t18, g1, g2,
}

enum CapState { hidden, live, set }
```

- **ValueNotifiers (discrete UI channels):**
  - `phase: ValueNotifier<OSGPhase>`
  - `line: ValueNotifier<OSGLine>` (register flag resolved via the §5 copy table in `osg_copy.dart`)
  - `displayCost: ValueNotifier<int>` (+ `costTrend`), `displayHomes: ValueNotifier<int>` (pinned 12, shown Phase A), `displayPrice: ValueNotifier<int>` (+ `priceTrend`) — all 5 Hz sampled
  - `priceRailVisible: ValueNotifier<bool>`
  - `capState: ValueNotifier<CapState>`
  - `showCardEarn: ValueNotifier<bool>`, `showContinue: ValueNotifier<bool>`
- **Hot-path getters (read by Flame layers each frame):** `layProgressB`, `layProgressC` (0–1, high-water of pointer x); `clearProgressC`, `clearProgressB` (0–1, low-water reverse); per-network settle/reveal envelopes; `pulsePhase` (shared across all networks); `dropSwing[i]` envelopes (switch-over and switch-back); `windowLit[12]` (hard booleans from price thresholds); `price`, `capValue`, `fairBandTop = 130`, `costFloor = 100`, `plateau = 320`; `flashIntensity`; entrance reveals (`streetReveal`, `networkAReveal`, `railReveal`); `reducedMotion`.
- **Inputs (all phase-gated; ignored otherwise):**
  - `onSkyDragStart/Update(Offset local)` — in `laySecond`/`layThird`: `progress = max(progress, normalizedX)`, pole-detent crossings → `onPoleTick`; in `clearWires`: reverse high-water (right→left) reels the topmost rival.
  - `onCapDragUpdate(double localY)` — `capValue = clamp(yToPrice(localY), 100, 340)`, instant; `price = min(price, capValue)` same frame.
  - `onCapDragEnd()` — if `capValue ∈ [100, 130]` → success path; if `< 100` floor-refused earlier (G1); if `> 130` → hold + G2 after 1600 ms.
- **Timers:** `_schedule(int ms, VoidCallback fn)` (shipped pattern) drives every auto-advance and text-timing in §6; `tick(double dt)` advances `pulsePhase`, the price climb (only in `priceClimb`/`capPrice`), and all envelopes; clamps `dt` to `(0, 0.1)`.
- **Gating conditions:**
  - `laySecond → switchOver`: `layProgressB ≥ 0.98` (+T4 beat timing).
  - `layThird → choked`: `layProgressC ≥ 0.98`.
  - `choked` discovery: T7 + `heavyImpact` + `onCapture('street_choked')` latched once at +600 ms.
  - `clearWires → oneShared`: `clearProgressC ≥ 0.98 && clearProgressB ≥ 0.98`.
  - `capPrice → capped`: cap released with `capValue ∈ [100, 130]` → `heavyImpact` + `onCapture('price_capped')` (latched once).
  - G1 latched once on first floor refusal; G2 re-armable per high release.
  - `bridge` end → `showCardEarn = true`; card `onDone` (`onCardCollected`) → `showContinue = true`; Continue → `Navigator.maybePop`.
- **Hooks:** `onPoleTick` → `HapticFeedback.selectionClick()`; `onDiscovery` → `heavyImpact` (T7 and the cap landing); `onCapture(String id)` → `lightImpact` + screen-side PNG snapshot.

## 15. File plan

Mirrors the shipped `trace_it_back` / `source_personalities` structure (screen / state / config / game-or-widgets). Create ONLY these, all under `lib/screens/missions/one_shared_grid/`:

```
lib/screens/missions/one_shared_grid/
├── one_shared_grid_screen.dart             — shell: noScaling MediaQuery; header (back; title "Wire the
│       Street", mono eyebrow "EPISODE 5 · THE BILL"); EpisodeBoardStrip (EP5 question); _FadeSwapCaption
│       top text (fixed h=96); RepaintBoundary(_sceneKey) wrapping background + GameWidget; transparent
│       Listener forwarding sky/cap pointers; chips row; PriceCapRail overlay (Phase B); fixed-height CTA
│       seat; CaptureFlash; CollectibleEarnOverlay(kOnlyGameInTownCard)
├── state/one_shared_grid_controller.dart   — ChangeNotifier: phase machine, _schedule timers, lay/clear
│       transports, price model, window-threshold logic, capture/haptic hooks, setStageSize anchors
├── state/street_model.dart                 — pure data: pole x-detents, network polylines per crossarm
│       height, 12 homes (x, drop attach point, supplier), price thresholds → windowLit mapping
├── config/osg_tuning.dart                  — OSGTune: geometry factors (§16), lay/clear feel, shared pulse
│       constants, price rates/thresholds/bands, phase timings (§6), company tints
├── config/osg_copy.dart                    — OSGLine → verbatim §5 strings + register flags
├── game/one_shared_grid_game.dart          — FlameGame: transparent bg; layers back→front;
│       onGameResize → controller.setStageSize; update(dt) → controller.tick(dt) (dt in 0..0.1)
├── game/components/ambient_layer.dart      — vignette glow, ≤ 20 motes, calm sky band
├── game/components/wire_sky_layer.dart     — THE HERO (upper half): poles at detents; up to 3 catenary
│       networks (company-tinted hardware, ONE shared gold-pulse renderer); lay pay-out + reel-back art;
│       grab hints; jostle/choke crowding at network C
├── game/components/street_layer.dart       — terraced 12-house row + pavement: warm window glow; service
│       drops with swing envelopes; hard windowLit dark-snaps; relight cascade
└── widgets/
    ├── price_cap_rail.dart                 — Flutter precision control: glass rail; climbing price column +
    │       mono number riding its top; fair-band notch; draggable CAP bar (instant); floor-bounce envelope
    └── energy_field_background.dart        — static dark vignette variant (copy-adapt from shipped)
```

Registration in `activityRegistry.dart` and wowConcepts wiring are **central integration** — NOT this build. The EP5 evidence catalog entries (`street_choked`, `price_capped`, optional `identical_pulses`) and the card constant belong to shared infra; this build only **calls** the ids and **references** `kOnlyGameInTownCard` (final name per shared infra).

## 16. Scene sketch (portrait, top-to-bottom, factor-based)

Stage = the Expanded scene area below fixed chrome (header ≈ 56 px, board strip, top text h=96). **All anchors are factors of stage size (w, h)** set via `setStageSize` in `OSGTune`; no fixed-pixel layouts.

```
┌──────────────────────────────────────────┐
│ header: ‹back›   WIRE THE STREET          │  Flutter chrome (fixed)
│ EpisodeBoardStrip — EP5 question pinned   │
│ top text (imperative / meaning, h=96)     │
├──────────────────────────────────────────┤  ← stage top
│ WIRE-SKY (hero, upper half)               │  y: 0.04h–0.42h · x: 0.04w–0.96w
│   crossarm C  ~y 0.12h (magenta tint)     │  5 poles at x ≈ 0.08/0.29/0.50/0.71/0.92
│   crossarm B  ~y 0.22h (blue tint)        │  catenary sag between detents; ONE identical
│   crossarm A  ~y 0.32h (gold-neutral)     │  gold pulse (#FFD27A) on every network
│   [PRICE RAIL overlays right edge,        │  rail x: 0.86w–0.95w · y: 0.05h–0.52h
│    Phase B only: column + CAP bar +        │  fair-band notch at 100–130; number rides
│    mono number]                           │  the column top (Phase B's only number)
├──────────────────────────────────────────┤
│ SERVICE DROPS                             │  y: 0.42h–0.55h · thin lines; swing
│   (per home, from its supplier's wire)    │  envelopes on switch-over / switch-back
├──────────────────────────────────────────┤
│ HOUSE ROW (hero, lower half)              │  y: 0.55h–0.82h · 12 terraced homes,
│   warm windows = the brightest pixels     │  ~0.075w each; hard dark-snap states;
│   pavement strip beneath                  │  vignette darkest behind the row
├──────────────────────────────────────────┤
│ chips row: [COST 300 ▲]  [HOMES 12]       │  y ≈ 0.88h · dark-glass mono chips
│   (Phase A; crossfades out in Phase B)    │
├──────────────────────────────────────────┤
│ CTA seat (h=84, empty until done)         │  Flutter chrome (fixed)
└──────────────────────────────────────────┘
```

The wire-sky and house row read as **one street cross-section** — cause above, consequence below. On very small phones the chips row compresses first; the wire-sky never drops below 0.34h and the house row never below 0.22h, so the hero keeps the majority of the frame. The lay/clear gesture is accepted **anywhere in the wire-sky band** (a fat target); the cap drag is accepted on the rail's full width.
