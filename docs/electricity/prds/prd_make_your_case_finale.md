# PRD — Make Your Case: THE GRAND FINALE
### howwow electricity · registry id `make_your_case_finale` · thin wrapper on the shared CER engine · finale catalog id `finale_electricity` · the module's LAST activity

Binding context: `docs/electricity/context_pack.md` (the covenant, esp. §2 + §5), `docs/electricity/architecture_reference.md` (PART 3), curriculum §7 + §13 + "The journey at the end", `prd_episode1_cer_closing.md` (the live CER pattern spec — its rules apply verbatim here), and the episode CER PRDs (`prd_make_your_case_ep2/3/4.md`) whose locked catalogs this PRD draws from. This PRD is self-contained: every on-screen line is quoted verbatim.

**What this PRD is.** `make_your_case_finale` is NOT a new engine. It is `MakeYourCaseScreen(config: kFinaleCerConfig)` — a thin registered wrapper on the shared parameterized CER engine, whose `CerConfig` already supports a multi-episode `sourceEpisodeIds` list and a 3-slot claim template (both shipped for exactly this beat). This PRD specifies the **finale CerConfig CONTENT**: the locked cross-episode evidence catalog (this document is the finale catalog owner), the staging, the one 3-slot claim template in the module, the journey playback, the nudges, and the closing "The Whole Machine" card.

**What this beat replaces (locked decisions — do not reopen):** the EP5 capstone is this grand multi-episode CER, NOT a town-sim game (curriculum 5.4's open decision is resolved: option (a)). EP5 has **no separate episode CER** — this beat is simultaneously Episode 5's closer and the whole module's finale. It answers the question the module is named after.

**What this beat inherits / pins (chain rule).** It inherits *everything* — all five episodes, felt and named; it teaches nothing new and names nothing new. It pins nothing: a pure synthesis. Every reaction in this flow is a recognition.

---

## 1. One-concept statement

**Electricity reaches your home as one unbroken live machine: made by a spinning magnet the instant you use it, sent across the country at enormous voltage so almost nothing is lost, stepped down in stages to your socket, balanced every second — and paid for, stage by stage, on one bill.**

The learner does not learn this here — they *assemble* it. This is the module's emotional payoff: the whole journey, in their own hands, in order, ending on their own sentence.

## 2. Guiding question + the answer the case builds toward

### 2.1 The pinned question (LOCKED — `kFinaleQuestion`, defined once in the finale evidence file)

> **"How does electricity reach your home?"**

This is the module's title question — it has hung over the wowConcept since the first screen, and 5.4's closing bridge line poses it explicitly over the filled evidence board (*"One question is left, and every clue is on the board: how does electricity reach your home?"* — B1's embedded phrasing must match this constant, case-adjusted, at integration). The three finale screens pin it verbatim in `CerQuestionHeader`.

### 2.2 The answer (developer-facing — NEVER shown as text up front)

The journey, clause by clause — each clause carried by exactly the evidence the learner captured when they first felt it:
- **Made** — every source spins the same magnet (EP1), and it is made *the instant it is used*: nothing buffers the grid (EP4).
- **Sent** — for fixed power, enormous sending voltage makes the current tiny, so almost nothing leaks as heat across the long lines; the power sails across (EP2).
- **In** — the lethal line voltage comes down in stages through the distribution grid to 230V at the socket (EP3).
- **Held** — the match between making and using is held live, every second (EP4).
- **Paid for** — the bill is an itemised receipt for every one of those stages (EP5).

## 3. The felt discovery (discovery → reaction)

The interaction IS the synthesis, at module scale:
1. **Discriminate across episodes** — on the evidence screen the learner judges relevance against a NEW question: which of these witnessed moments is a *stage of the journey*, and which is a true thing that answers a *different episode's* question. The finale's freshest move: **both distractors were RELEVANT evidence in their own episodes** — the learner must discover that relevance belongs to the question, not to the clue.
2. **Author the journey** — the claim screen offers the module's only 3-slot template (made → sent → paid-for). The honest journey sentence is reachable only by assembly; it is pre-written nowhere.
3. **Watch the whole machine run** — the playback orders their kept moments into the journey: magnet → high voltage → the crossing → the staged descent → the live balance → the receipt — ending on their claim, the capstone, and the deck's closing card.

## 4. Felt vs named vs numbered

- **Felt:** the evidence tiles are the learner's own captured frames from across the whole module (or their drawn motifs) — the convergence scene, the gold rectangle, the cold line into the lit far city, the stepped street, the tipped town, the stacked receipt. The image carries each tile; text rides as a ≤3-word label + an episode badge.
- **Named:** nothing new. Every word in the claim, captions and capstone (magnet, voltage, current, socket, demand, bill) was named in its own beat. "The whole machine" appears only in the capstone and on the card — after the case is built, never before.
- **Numbered:** **zero live numbers on all three screens.** No tile counts, no progress %, no score (the 3 progress dots in `CerQuestionHeader` are navigation chrome). Numerals exist only *inside* captured frames (the 230V chip, BILL 100) — those are the moments themselves, not chrome. **No ratings table. No ✓/✗ anywhere.**

## 5. THE FINAL EVIDENCE CATALOG (LOCKED — this table is the finale catalog of record)

**8 tiles: 6 relevant + exactly 2 distractors.** One to two tiles per episode; every episode represented. Ids are the SOURCE episodes' locked ids, reused verbatim (this is what makes cross-episode capture reuse work — §13). Catalog order below IS the montage order. `sourceLabel` is the episode badge on the tile (`showSource: true` in the closing grid).

| # | id | relevant | label (≤3 words) | caption (one line, preview + playback) | source episode / beat / capture moment | badge | accent | motif (reused) |
|---|---|---|---|---|---|---|---|---|
| 1 | `same_magnet` | **true** | Same Magnet Trick | Coal, nuclear, wind, water — every source just spins the same magnet. | EP1 · 1.1 `trace_it_back` · closing convergence | `EP 1` | `#FF9B42` | `sameMagnet` (EP1 painter) |
| 2 | `current_drops_itself` | **true** | Current Drops | Raising the sending voltage made the current fall on its own — the pinned power stayed the same. | EP2 · 2.5 `transmission_trick` · discovery latch | `EP 2` | `#F5C451` | EP2 painter (tall gold rectangle + ghost) |
| 3 | `ac_sails_across` | **true** | AC Sails Across | Stepped up by the transformer, the current fell to a trickle — the line ran cold and the far city lit to full. | EP2 · 2.8 `war_of_currents` · AC arrival | `EP 2` | `#FFE9B8` | EP2 painter (cool route line to lit cluster) |
| 4 | `staged_descent` | **true** | Staged Descent | Two staged drops brought a thousand-times line down to 230 volts at the socket. | EP3 · 3.1 `stepping_down` · house lit + socket chip | `EP 3` | `#3FD99B` | EP3 painter (`stagedDescent`) |
| 5 | `demand_never_still` | **true** | Never Holds Still | Production froze for four seconds — demand walked away and the city tipped. | EP4 · 4.1 `hold_the_balance` · M5 let-go discovery | `EP 4` | `#FFD27A` | EP4 painter (`demandNeverStill`) |
| 6 | `receipt_whole_journey` | **true** | The Whole Receipt | Stacked back to the same hundred — every slice pays a stage of the journey, magnet to socket. | EP5 · 5.4 `the_bill_receipt` · restack lands on 100 | `EP 5` | `#E0A96D` | EP5 painter (itemised stack over a tiny lit journey strip) |
| 7 | `fossil_haze` | **false (distractor)** | Fossil Fuels Choke | Coal and gas burn steadily — but both choke the sky with smog. | EP1 · 1.2 `source_personalities` · pollution ≥ .6 (coal+gas clubbed) | `EP 1` | `#9AA0A6` | `coalHaze` (EP1 painter) |
| 8 | `peaker_sets_price` | **false (distractor)** | Peakers Set Price | At the evening peak the most expensive plant running set the price for every unit. | EP5 · 5.2 `peak_pricing` · M2 second ignition | `EP 5` | `#FF8A3D` | EP5 painter (demand hill + gold staircase + flaring plant) |

`kFinaleDistractorIds = ['fossil_haze', 'peaker_sets_price']`.

**ID-FIDELITY (load-bearing — verified against shipped code):** every finale id above is the EXACT id its source episode captures — this is the only thing that makes the cross-store lookup hit (§13). Confirmed against `evidence_models.dart`: the EP1 dirty-air tile ships as **`fossil_haze`** (coal+gas clubbed — `source_personalities` maps both `SourceKind.coal` and `SourceKind.gas` → `'fossil_haze'`); there is NO `coal_haze` id in the shipped catalog, so the finale uses `fossil_haze`. The other seven ids (`same_magnet`, `current_drops_itself`, `ac_sails_across`, `staged_descent`, `demand_never_still`, `receipt_whole_journey`, `peaker_sets_price`) match their source-PRD locked ids verbatim. If the shared-infra owner renames any source id, this catalog must track it or the tile silently never loads.

**Why these six reals (one journey clause each, zero duplication):** the magnet that makes it (1) → the trick that sends it (2) → the proof it crosses (3) → the staged way in (4) → the live balance that holds it (5) → the receipt that pays for all of it (6). Per episode: EP1 contributes its convergence (the strongest single tile of the episode — the catches belong to "why so many", not the journey); EP2 contributes two (the trick AND the crossing — the heavyweight episode keeps its mechanism and its payoff); EP3 contributes the staged descent (the journey clause; the safety nuance stays in EP3's own case); EP4 contributes the no-buffer tip (the "this very second" clause — the strongest of the five EP4 tiles for THIS question); EP5 contributes the receipt — flagged by 5.4's PRD as "arguably the single strongest closing tile of the whole module", and the montage's natural final frame.

**Why these two distractors (the finale's distinct move — RELEVANCE FLIPS):** both are true, dramatic, personally-witnessed moments that were *relevant evidence in their own episode's case* — and answer that episode's question, not this one:
- `fossil_haze` answered *"why do we make electricity from so many different sources?"* (a catch — dirty). It is no stage of the journey: the smog says nothing about how power travels from plant to socket. Setting it aside is recognizing which question it belongs to.
- `peaker_sets_price` answered *"why does 6pm cost more than 3am?"* (the hourly price mechanism). The journey's payment clause is "the bill pays for every stage" — *what hour costs more* is the other half of EP5's question, deliberately outside this one.

Neither contradicts any clause of the assembled claim (the distractor test: true-but-irrelevant, never false/tricky). The flip is the deepest CER lesson the module can close on: **the same true clue answers one question and not another.** (Device-innards distractors — `still_magnet`, `changing_field`, `fewer_turns_out`, `lockstep_spin` — were considered and passed over: the learner has already practiced setting each aside in its own episode CER; the flips are the fresh judgment.)

### Catalog deltas / reconciliation notes (this PRD is the finale catalog owner)

1. **`magnet_in_the_bill` (5.4's proposed EP5 distractor) is NOT promoted to the finale.** 5.4's PRD correctly notes its relevance would FLIP here (the spinning magnet is core to this question) — but as a relevant tile it duplicates `same_magnet` (the same magnet, twice on one board). It stays in the EP5 catalog as a board-strip tile only.
2. **`one_kwh_either_way` (5.1, the rectangle) is not included.** The "include the receipt or the rectangle" requirement is met by the receipt — the stronger closer; the rectangle's law lives on 5.1's own card and inside the receipt's energy story. Six reals, one per clause; fewer, stronger tiles.
3. **No tile from 5.3** (`street_choked` / `price_capped`) — "why one company" is the episode's civic aside, not a journey stage; and `street_choked` was screened as a third distractor candidate and rejected (exactly 2, per the pattern rules).
4. **EP5 catalog dependency (shared infra):** the EP5 evidence file (`evidence_models_ep5.dart`) ships all 8 beat-proposed tiles for the board strip + capture crops (`one_kwh_either_way`, `bulb_beats_heater`, `peaker_sets_price`, `cheap_at_3am`, `street_choked`, `price_capped`, `receipt_whole_journey`, `magnet_in_the_bill`); the finale consumes exactly 2 of them. With no EP5 episode-CER, the EP5 catalog's `relevant` flags are inert in-episode — they matter only here, where this catalog re-declares its own.
5. **Relevance re-declaration is intentional and catalog-scoped:** `fossil_haze` ships `relevant: true` in `kEpisode1Evidence` and `relevant: false` in `kFinaleEvidence`; `peaker_sets_price` likewise true in EP5's file, false here. The finale catalog is a separate `EvidenceTile` list under its own `kEvidenceCatalogs` key — no source catalog is edited.
6. **No new capture calls anywhere.** The finale fires zero `onCapture`s; every tile above is captured by its source activity at its already-locked moment. Nothing in any beat PRD changes because of this document.
7. **cropFactors:** mirrored verbatim from each source catalog entry (they describe the source scene's crop). They are inert in the finale (no captures fire here) — kept identical so a single tile definition convention holds.

## 6. Staging (Screen 1 — ≤6 visible per stage)

Two stages of 4 — the far half and the near half of the journey — **one flipped distractor seeded into each**, so the relevance judgment is live on both screens and no stage is a relevance tell:

```dart
stages: [
  // Stage 1 — far away: made & sent
  ['same_magnet', 'current_drops_itself', 'ac_sails_across', 'fossil_haze'],
  // Stage 2 — near you: in, held, paid
  ['staged_descent', 'demand_never_still', 'receipt_whole_journey', 'peaker_sets_price'],
]
```

(The engine renders each stage's tiles in catalog order, so the distractors draw last within their stage.) Navigation via the engine's `More clues` / `Back` — no tabs. 4 visible per stage, comfortably under the cap; tiles stay comfortably sized, never shrunk to cram.

## 7. Claim build (Screen 2 — built, never selected; the module's one 3-slot template)

**The template (verbatim — 3 slots, 3 chips each; the one place the bigger template is allowed):**

> **"Somewhere far away, a spinning magnet makes it [slot1] — it crosses the country at [slot2] voltage, steps down in stages to your socket, and the bill pays for [slot3]."**

```dart
claimTask: "So — what's your answer?",
textParts: [
  'Somewhere far away, a spinning magnet makes it',
  '— it crosses the country at',
  'voltage, steps down in stages to your socket, and the bill pays for',
  '.',
],
slotOptions: [
  ['the night before', 'the instant you use it', 'hours in advance'],
  ['socket', 'gentle', 'enormous'],
  ['every stage of the journey', 'the fuel alone', 'the wires alone'],
],
slotCaptions: ['Made when?', 'At what voltage?', 'The bill pays for…'],
slotPlaceholders: ['?', '?', '…'],
toPlaybackCta: 'See your case',
```

**Assembled honest claim (reachable ONLY by assembly — never pre-written anywhere):**

> **"Somewhere far away, a spinning magnet makes it the instant you use it — it crosses the country at enormous voltage, steps down in stages to your socket, and the bill pays for every stage of the journey."**

Why these chips are honest work, not traps (each decoy is a real misconception, each adjudicated by kept evidence):
- **Slot 1 (made-when):** `the night before` and `hours in advance` are the stockpile misconception at two magnitudes — both defeated by `demand_never_still` (production froze four seconds and the city tipped; nothing waits in a store).
- **Slot 2 (sent-how):** `socket` is the send-it-ready misconception — defeated by `staged_descent` (it arrives a thousand times too strong and must come DOWN in stages; it was never sent at socket level); `gentle` is defeated by `current_drops_itself` + `ac_sails_across` (the whole trick is raising it enormous so the current falls and the line runs cold).
- **Slot 3 (paid-what):** `the fuel alone` and `the wires alone` are each one slice of the receipt — defeated by `receipt_whole_journey` (five slices, plant to operators, stacked back to the same hundred).

Honest chips sit at positions 2 / 3 / 1 (no tap-the-first-chip or fixed-position pattern). Every chip combination is grammatical in the sentence; no chip is false-on-its-face; nothing marks a pick right or wrong. Engine check (`claimText` spacing): `'— it crosses…'` takes a leading space (em-dash is not in the attach-punctuation set), `'.'` attaches without one — the assembled string renders exactly as above.

## 8. Playback (Screen 3 — the journey, carried by the montage)

**Montage order = catalog order of kept tiles (the engine behavior; never selection order).** With a complete case the argument runs the module end to end:

1. `same_magnet` — somewhere far away, every source is spinning the same magnet
2. `current_drops_itself` — raise the sending voltage and the current falls on its own
3. `ac_sails_across` — so the line runs cold across the distance, and the far city lights
4. `staged_descent` — it comes down in stages, a thousand-times line to a 230-volt socket
5. `demand_never_still` — and it is being made *right now*, because demand never holds still and nothing buffers it
6. `receipt_whole_journey` — and the bill, stacked back to the same hundred, pays for every stage of it

…ending on the learner's assembled claim (the claim banner glows above the montage, emphasised at the finale), then the capstone. A kept distractor simply plays in its catalog slot after the receipt — the case feels padded; that IS the gentle consequence.

**Capstone (verbatim, lands after the last tile):**

> **…so the switch on your wall reaches back across the whole machine — a magnet spinning far away, a tiny current riding an enormous voltage, the staged descent to your socket, a balance held this very second — and the bill is the receipt for all of it.**

**Completeness nudge (gentle — fires only when a relevant captured tile is missing; never blocking, never names a tile):**

> **Played back, your case doesn't reach your home yet — a stage of the journey is missing. Want to add it?**

**Distractor note (gentle, non-blocking aside when a flipped clue is kept):**

> **One of your clues answers a different episode's question — not how the power reaches your home. Still a true thing you found!**

CTAs (engine): `Add a clue` · `Finish anyway` · `Finish`. Completeness heuristic unchanged from the engine: complete ⇔ every relevant tile *in `available`* is kept (a kept distractor never blocks or "fails" anything; it only triggers the aside).

## 9. On-screen text — EXACT (the complete config copy)

No mascot, no info-cards, no score, no ✓/✗ anywhere. One voice. All strings verbatim:

| config field | text |
|---|---|
| `question` (pinned, all 3 screens) | How does electricity reach your home? |
| `beatName` | Make Your Case |
| **Screen 1** `evidenceTask` | Which clues answer the question? |
| `evidenceHint` | Tap a clue to open it, then keep the ones that fit. |
| `moreCta` / `backCta` | More clues / Back |
| `toClaimCta` | State your answer |
| **Screen 2** `claimTask` | So — what's your answer? |
| `textParts` + `slotOptions` + `slotCaptions` + `slotPlaceholders` | as §7, verbatim |
| `toPlaybackCta` | See your case |
| **Screen 3** `capstone` | …so the switch on your wall reaches back across the whole machine — a magnet spinning far away, a tiny current riding an enormous voltage, the staged descent to your socket, a balance held this very second — and the bill is the receipt for all of it. |
| `incompleteNudge` | Played back, your case doesn't reach your home yet — a stage of the journey is missing. Want to add it? |
| `distractorNote` | One of your clues answers a different episode's question — not how the power reaches your home. Still a true thing you found! |
| `addEvidenceCta` / `finishCta` / `finishAnywayCta` | Add a clue / Finish / Finish anyway |
| `earnEyebrow` | CASE CLOSED |
| `earnBrag` | You closed the final case — from a spinning magnet far away to the socket on your wall, balanced every second, paid for on one bill. |

Tile labels and captions are locked in §5. Engine-owned strings (`Add to my case` / `Remove from my case` / `Close` / `Skip`) ship unchanged. No other text exists in this flow. Rules check: no rhyme, no addressing-as-child, no exclamation outside the established distractor-note pattern; the capstone names nouns and destinations; "the whole machine" appears in no copy before the capstone; the assembled claim exists nowhere as a single selectable string.

## 10. Reward — Card: THE WHOLE MACHINE (the deck's closing trophy)

**Card: YES** — the context pack (§6) reserves the finale's "The Whole Machine" card explicitly. Proposed copy (shared-infra owner assigns the number, builds/renders the treatment, updates `deckTotal` on ALL constants; this wrapper only references the constant — proposed `kWholeMachineCard`, proposed id `the_whole_machine`):

- **Front — playful name:** **The Whole Machine**
- **Front — real term (mono specimen):** `HOW ELECTRICITY REACHES A HOME`
- **Front — one-line law:** *From the spinning magnet to the socket, electricity is one machine, run live, end to end — and the bill pays for the whole of it.*
- **Front — kicker:** *Flip a switch — the whole country answers.*
- **Back — tie to what was felt:** *You spun the magnet, starved the wire with voltage, stepped the line down to the socket, held the 6pm rush second by second, and stacked the bill back to a hundred.*
- **Back — outward reach:** *Stand in your kitchen tonight and flip a switch — somewhere far away, a magnet leans into the load that very instant.*
- **Section / rarity (PROPOSED — open decision §16):** `foundations`, **prismatic, foundational-tier treatment like Card 01** (pre-rendered PNG art in `assets/images/collectibles/`). The deck opens on a prismatic card (Conservation) and closes on one (The Whole Machine) — the bookends of the system. Fallback if rarity is declined: section `theBill`, accent `#E0A96D`, standard painter.
- **Motif suggestion:** the journey in one line — a tiny magnet-and-coil at the far left, one long catenary line crossing the card through a step-down pole, ending in a lit doorway; a small receipt stack glowing beneath the doorway.
- **Linked card (proposed):** **Card 01 — The Unbreakable Rule** (conservation): the law the whole machine obeys, first card to last. (Shared infra may instead link the four episode-synthesis cards as a visible lineage — single-link default.)
- **No-restatement check:** Card 05 owns the mix; The High Road owns EP2's distance composite; Managed, Not Harmless owns EP3's; The Control Room owns EP4's; Pay for the Area owns the kWh. This card's law is the *journey altitude* — the one sentence none of them states: that it is a single end-to-end machine.

**Inline fact: none** (deliberate empty slot — the capstone is the last thing read before the card, and the card back carries the outward reach).

## 11. Beat-by-beat flow (timing + gating — engine behavior, restated for acceptance)

1. **Entry** (from the wowConcepts flow after 5.4): `CerController.load()` aggregates across ALL FIVE stores — for each tile it checks `EvidenceStore.captured(epId)` for every id in `sourceEpisodeIds` and pulls session image bytes where present (§13). Captured tiles render their frame (bundled perfect-frame asset → live PNG → motif painter, the tile view's cascade); if NOTHING was captured anywhere (dev entry), the full §5 catalog seeds so the screen is always playable.
2. **Screen 1 — Evidence.** Pinned question + task + Stage 1 (4 tiles, episode badges visible). Tap a tile → preview modal (full frame + caption + keep/remove — engine chrome). `More clues` → Stage 2. No correct/wrong feedback on any keep. `State your answer` enables once ≥1 tile is kept.
3. **Screen 2 — Claim.** Pinned question + only the kept tiles (small strip; scrolls if >6, never shrinks) + the §7 three-slot template. All three slots filled → `See your case`. Chips are re-tappable; no slot is pre-filled.
4. **Screen 3 — Playback.** Kept tiles play in §8's catalog order (engine stagger/dwell — the playback ORDER is pedagogy and never changes, reduced motion included), the assembled claim above, capstone after the last tile. Incomplete → §8 nudge + `Add a clue` (returns to Screen 1, selections preserved) / `Finish anyway`. Kept distractor → §8 aside, non-blocking. `Finish` → `CollectibleEarnOverlay(card: kWholeMachineCard, eyebrow: 'CASE CLOSED', brag: §9, showMascot: false, onDone: controller.onCardCollected)` → auto-pop via `Navigator.maybePop` (any pop = completion; no payload).
5. Back-navigation between screens never loses kept tiles or slot picks. Straight-through play ≈ 75–150 s (the 3-slot claim and 6-tile montage run a touch longer than the episode CERs — correct for a finale).

## 12. Hero & layout (portrait; clutter caps)

- **Hero per screen:** S1 — the learner's own evidence from five episodes (real captured frames, the brightest things on the dark `_CerBackground`); S2 — the journey sentence under assembly; S3 — the montage. Chrome recedes (glass `0x14FFFFFF` / borders `0x26FFFFFF`, near-black field, episode-board gold `#E8C98A`).
- Per screen: pinned question + ONE task + a handful of tiles — nothing else. **≤6 tiles visible** (stages of 4); **zero live numbers; no drag-lines, no tabs, no checkboxes, no score**; tiles = thumbnail + ≤3-word label + episode badge only.
- 3 sequential screens via the engine's `AnimatedSwitcher`; `MediaQuery(...textScaler: TextScaler.noScaling)`; reduced motion → montage becomes fades, order unchanged.
- **Small-phone wrap check:** `textParts[2]` is the longest scaffold part in the module — verify it wraps cleanly (no ellipsis) with three chip rows on a ≈360×640 logical portrait phone; the claim screen may stack scaffold and chip groups vertically (engine layout), never truncate.

## 13. Build notes — incl. THE MULTI-EPISODE STORE AGGREGATION

- **Wrapper only.** `lib/screens/missions/make_your_case_finale/` exposes a `const` no-arg screen returning `MakeYourCaseScreen(config: kFinaleCerConfig)`. Registration of `make_your_case_finale` in `activityRegistry.dart` + wowConcepts wiring are central-integration work — not this build.
- **CerConfig content (this PRD's deliverable to the shared-infra owner):**
  - `episodeId: kFinaleId` — `'finale_electricity'` (the catalog key; the finale catalog MUST be registered under it in `kEvidenceCatalogs`)
  - `sourceEpisodeIds: ['episode1_electricity', 'episode2_electricity', 'episode3_electricity', 'episode4_electricity', 'episode5_electricity']` — the shipped `CerConfig` field built for exactly this; `CerController.load()` already walks it
  - `question: kFinaleQuestion` (§2 verbatim) · `beatName: 'Make Your Case'`
  - `tiles: kFinaleEvidence` — the §5 catalog (8 re-declared `EvidenceTile`s, finale-scoped flags/badges/captions) in a new `evidence_models_finale.dart`
  - `stages:` per §6 · claim fields per §7 · all copy per §9 · `card: kWholeMachineCard`
- **How cross-episode reuse actually works (and its honest limit):**
  - **Ids:** captured-id sets persist per episode in `shared_preferences` (`'howwow_evidence_<episodeId>'`) — cross-session. The finale therefore *always* knows which of its 8 moments were genuinely witnessed, however long ago.
  - **Pixels:** captured PNG bytes live in `EvidenceStore`'s **in-memory, session-scoped** cache. A learner reaching the finale in a later session has ids but no bytes — those tiles fall back per the tile view's cascade: bundled perfect-frame asset (`assets/images/episode_board/evidence/<id>.png`) → live bytes → drawn motif. **Because the finale reuses source ids verbatim, `assetPath` resolves to the same file the source episode uses — one dropped PNG serves both boards.** RECOMMENDATION (open decision §16): bundle perfect frames for all 8 finale ids so the module's emotional payoff never plays on motif fallbacks.
  - **Flags:** `relevant`, `sourceLabel`, captions and accents come from the FINALE catalog (the tile object), never the source catalog — the engine resolves tiles from `config.tiles`, so the §5 flips are automatic. No source file is edited.
- **No new motifs, no new painters:** the finale references the same `EvidenceMotif` values its source tiles use (EP1's `sameMagnet`/`coalHaze` exist today; EP2/EP3/EP4/EP5 values land with their per-episode shared-infra files). Dependency to verify, not fork: all four per-episode evidence files + painters must exist before this config compiles.
- **No captures, no board strip, no Flame, no Forge2D, no audio** in this flow. The finale never calls `onCapture`; cropFactors are mirrored but inert.
- **Engine untouched.** If the config cannot express something in this PRD, STOP and report — never fork the engine for the finale.
- **Card constant** `kWholeMachineCard` in `collectible_models.dart` + treatment + dispatch case + `deckTotal` bump on ALL constants — single-owner files, shared-infra agent only, one pass (the prismatic decision §16 lands there).
- Verify: `fvm dart analyze` clean on the wrapper dir, `make_your_case`, `episode_board`, and each new per-episode file — one path per invocation (multi-path analyze crashes).

## 14. Acceptance criteria (the anti-worksheet rules as testable checks)

1. **Evidence is felt moments, never text bullets:** every tile renders a captured/bundled frame or its drawn motif + ≤3-word label + episode badge; no tile is a sentence-card; no checkbox exists anywhere.
2. **The catalog spans the module:** all five episodes appear among the 8 tiles (EP1 ×2, EP2 ×2, EP3 ×1, EP4 ×1, EP5 ×2); every tile's id, label, caption, flag, badge and accent is verbatim from §5.
3. **Exactly 2 distractors, true-but-irrelevant, both FLIPS:** `fossil_haze` and `peaker_sets_price` carry `relevant: false` here while their source catalogs carry `relevant: true` — both catalogs intentionally disagree; neither caption contradicts the assembled claim; no distractor is trap-worded; no tile leaks relevance (no dimming, shared tell, badging or ordering).
4. **The claim is BUILT, never selected:** Screen 2 offers only the §7 template — 3 slots, 3 chips each; the honest journey sentence exists nowhere in copy, chips or chrome as a unit; every chip combination is grammatical; all three slots must be tapped.
5. **Reasoning is carried by the playback:** kept tiles play in §8's journey order (catalog order, never selection order), the claim banner above, the §9 capstone verbatim after the last tile. **No drag-lines** anywhere.
6. **No score, no ✓/✗, no tabs:** 3 sequential screens, one task each; selection produces no correct/wrong feedback; nothing displays a count, percentage or grade.
7. **≤6 tiles visible per screen:** stages of 4 per §6; the Screen-2 kept-strip scrolls rather than shrinking tiles.
8. **The incomplete case responds gently:** a missing relevant tile (scoped to `available` — a learner who skipped an episode can still complete an honest smaller case) → §8 nudge + `Add a clue` (state preserved) / `Finish anyway` (never blocked); a kept distractor → the §8 aside only.
9. **Multi-episode aggregation works:** with captures spread across all five episode stores, `load()` finds every captured finale id; with zero captures anywhere, the full catalog seeds and the flow is playable end to end; tiles without session bytes render bundled asset or motif (never a broken image).
10. **Question fidelity:** the §2 string is identical on all three screens AND matches 5.4's B1 embedded phrasing (case-adjusted) at integration.
11. **No new teaching:** no meaning-line, caption or chip introduces a term or re-derives a mechanism; captions restate only what was felt and named in the source beats.
12. **Completion contract:** `Finish` → card overlay (eyebrow `CASE CLOSED`, the §10 card) exactly once → `onCardCollected` → `Navigator.maybePop`; any pop = completion. Reduced motion respected (fades; order unchanged). Analyzer clean per §13.
13. **The finale fires zero captures** and edits zero shared files from the wrapper build.

## 15. Anti-patterns (this beat)

- **Worksheet drift at the very last moment** — text-bullet tiles, checkboxes, tabs, a "6/8" readout. Fatal anywhere; unforgivable on the module's closing screen.
- A pre-written journey sentence sneaking in (as a "suggested answer", the nudge's wording, or intro copy).
- Marking the flipped distractors — any dimming, red state, warning chrome, or a shared visual tell. The flip must be the learner's own judgment.
- Playback in selection order — the montage must run the journey, magnet to receipt.
- A tricky distractor: anything whose caption must be *disbelieved* to be set aside. Both §5 distractors are true; the work is relevance. (This is why `solar_night` was passed over for `fossil_haze`: a no-magnet-adjacent tile could read as contradicting the claim's first clause.)
- Re-teaching inside the CER — no re-derivation of the square, the staging, the balance, or the kWh; the captions only point at remembered moments.
- A third distractor, or zero — exactly 2.
- Restating any beat or episode card's law on The Whole Machine.
- Giving the finale a different engine behavior (special montage, new chrome) — it is config content on the shared engine, full stop.
- Editing source evidence catalogs to re-flag the flips — the finale catalog owns its own flags.

## 16. Open decisions

1. **Card rarity (the flagged decision):** prismatic foundational-tier treatment like Card 01 (pre-rendered PNGs, section `foundations`) vs standard `theBill` styling. PROPOSED: prismatic — the deck's bookends. Shared-infra owner decides in the one-pass card consolidation, with the number, constant name and link target (Card 01 proposed; the four episode-synthesis cards as an alternative lineage).
2. **Bundled perfect frames** for all 8 finale ids (strongly recommended — cross-session learners otherwise see motif fallbacks at the module's emotional peak). Asset production owner decides; ids/paths per §13.
3. **Episode badge format:** `EP 1` … `EP 5` (default, fits the tiny chip) vs `EPISODE 1`. Catalog implementer at integration.
4. **Playback dwell for the finale:** engine default vs a config-level longer dwell so the six-frame journey breathes (a shared-infra knob if added — never a finale fork).
5. **Final EP5 accents/motifs** for `receipt_whole_journey` / `peaker_sets_price` (§5 proposals) — EP5 catalog owner, one pass with the EP5 file.
6. **`beatName`** 'Make Your Case' (default, consistent) vs 'The Final Case' (a finale flourish). Cosmetic; integrator's call.
7. **Small-phone claim layout:** if the long `textParts[2]` + three chip rows crowd a 360-wide phone, the claim screen may tighten type or stack groups — the wording does not change.

---

## One-line summary

End the module the way it was lived: from eight of their own witnessed moments — gathered across five episodes — the learner keeps the six that ARE the journey (the same magnet, the current that fell, the line that sailed across, the staged descent, the city that tipped, the receipt that stacked back to a hundred), sets aside two true clues that answer other episodes' questions, assembles *"Somewhere far away, a spinning magnet makes it **the instant you use it** — it crosses the country at **enormous** voltage, steps down in stages to your socket, and the bill pays for **every stage of the journey**"* — and watches the whole machine run, magnet to bill, before pocketing **The Whole Machine**.
