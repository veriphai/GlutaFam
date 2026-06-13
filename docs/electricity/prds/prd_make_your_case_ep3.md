# PRD — Make Your Case (Episode 3 CER closer)
### howwow · Episode 3 "Into Your House (Without Getting Hurt)" · registry id `make_your_case_ep3` · `MakeYourCaseScreen(config: kEp3CerConfig)` · evidence episode `episode3_electricity`

Binding context: `docs/electricity/context_pack.md` (the covenant — §5 CER engine, §7 visual tokens, §9 traps), `docs/electricity/architecture_reference.md` (Part 3 — the shipped CER engine, evidence board, and `CerConfig` v2 refactor), `howwow_electricity_curriculum.md` §7 (the CER pattern) + §3.x (the EP3 spine), and `prd_episode1_cer_closing.md` (the LIVE CER pattern spec — its rules are obeyed verbatim here).

**This PRD specifies CONTENT, not a new engine.** `make_your_case_ep3` is a thin registered wrapper on the shared parameterized CER engine: `MakeYourCaseScreen(config: kEp3CerConfig)`. This document defines the `CerConfig` payload (the catalog, the staging, the claim template, the playback/capstone, the nudge, the card + earn copy) and the exact on-screen text for all three screens. It does **not** redesign the 3-screen flow, the chrome, or the capture infra — those ship from EP1 and are reused unchanged.

**This PRD is the EP3 evidence-catalog OWNER.** Every EP3 beat PRD (3.1–3.5) defers its final evidence tile set, distractor allocation, ids, labels, captions, accents, motifs, and crop factors to *this* document, and several have already reconciled to it (3.2, 3.3, 3.4, 3.5 cite it by name). The catalog locked in §3 below is authoritative; §11 lists the deltas the build/shared-infra agents must apply to the beat PRDs.

---

## 1. One-concept statement (what the case must land)

**Household electricity is a managed-danger system: the lethal supply is stepped down in stages, contained passively, and given a deliberate escape route — so it gets into your house without killing you.**

The synthesis is genuinely new — it is not any single beat's lesson restated. The episode taught five separate felt facts; the CER is where the learner assembles them into one architecture: *staged step-down (3.1) lowers it to a manageable — not harmless (3.2) — level; insulators contain it passively (3.4); and because it is current across a potential difference that crosses a grounded body (3.3), earthing routes a fault away on purpose (3.5).* The three load-bearing pillars are **step down → contain → escape route**, sitting on the premise that *it is current through you, across a difference, that harms.*

## 2. Guiding-question link

**Episode question (LOCKED — the single `kEpisode3Question` constant, pinned on the board strip all episode AND at the top of all three CER screens):**

> **"The power reaches your town still at lethal transmission voltage — how does it get into your house without killing you?"**

The answer the assembled case is meant to build toward (for the developer's understanding — **never shown as text up front**): *We step it down in stages to a manageable level, wrap it in insulators to contain it, and give any fault a deliberate path to ground that trips the fuse — managed danger, not a harmless utility.*

Three reasoning threads the relevant evidence must cover, so the claim is honest:
- **Why it must be managed at all** — even stepped-down 230V still drives harmful current (`socket_not_harmless`), and that harm is current across a potential difference through a grounded body (`same_level_safe`, `ground_is_zero`).
- **How it is brought to a manageable level** — staged step-down (`staged_descent`).
- **How that managed danger is kept off you** — passive containment (`copper_in_plastic`) + an active escape route (`surge_blows_fuse`).

## 3. FINAL evidence catalog (LOCKED — the EP3 catalog of record)

`episode3_electricity`. **5 relevant tiles + exactly 2 distractors = 7 total** (within §7's 4–6-relevant + exactly-2-distractor bound; staged so ≤6 are visible per screen, §4). Source label = the beat's within-episode index (3.1 → `ACT 1` … 3.5 → `ACT 5`). All ids are unique within the episode; the shared-infra agent transcribes this table verbatim into `kEpisode3Evidence` (the per-episode catalog in `evidence_models_ep3.dart`), wires `evidenceByIdFor('episode3_electricity', …)`, and implements the fallback motif painters named here.

| # | id | label (≤3 words) | caption (one line, shown in the tap-preview) | relevant | accent | source | motif (fallback painter) | captured by (beat · moment) |
|---|---|---|---|---|---|---|---|---|
| 1 | `staged_descent` | Staged Descent | Two staged drops brought a thousand-times line down to 230 volts at the socket. | **relevant** | `#3FB9F5` transmission blue | ACT 1 | `stagedDescent` — a line descending top→bottom through two step-flashes (substation + pole), the bottom segment warm, a lit house at the base | 3.1 `stepping_down` · `placePole` ~4000 ms (house lit, socket reads 230V AC, both stages in frame) |
| 2 | `socket_not_harmless` | Socket Not Harmless | Stepped-down socket voltage still drives current past the danger bands. | **relevant** | `#FF6259` band red | ACT 2 | `socketNotHarmless` — a slim 3-band vertical meter, a hot dot ABOVE the top band, a marker notch at ~70% on a column beside it | 3.2 `current_through_you` · `offScale` discovery frame (dot off-scale, SOCKET marker in frame, flash live) |
| 3 | `same_level_safe` | Same Level, Safe | Touching two wires at one level — zero difference, zero current across the bird. | **relevant** | `#3FD99B` homeSafety green | ACT 3 | `sameLevelSafe` — two wires drawn at one equal height, a bird bridging both, the level-bracket collapsed to a single dot, both chips at 0 | 3.3 `bird_on_the_wire` · the equal-levels zero-snap frame |
| 4 | `ground_is_zero` | Ground Is Zero | Feet on the ground, hand on the wire — the full difference fell across the body. | **relevant** | `#FF7A2E` heat orange | ACT 3 | `groundIsZero` — a standing silhouette, hand on a high wire, feet on a ground line, a full-scale bracket and a current path running hand→body→feet→along the ground | 3.3 `bird_on_the_wire` · the person hand-contact frame (full-scale bracket, lit return path, CURRENT at max) |
| 5 | `copper_in_plastic` | Conductor In Insulator | Copper carries the current; the plastic sleeve keeps it off you. | **relevant** | `#3FD99B` homeSafety green | ACT 4 | `copperInPlastic` — a cable cross-section: a glowing copper core inside a calm plastic ring | 3.4 `conductors_insulators` · cable payoff, ~500 ms after the cross-section reveal |
| 6 | `surge_blows_fuse` | Surge Blows Fuse | Fault current surges down the thick earth wire — the fuse blows and cuts the power. | **relevant** | `#FFD27A` surge gold | ACT 5 | `surgeBlowsFuse` — a thick earth wire from an appliance case to a ground terminal with a surge racing down it, and a fuse with a snapped filament | 3.5 `earthing` · the blow frame (discovery flash live, blown fuse, earth-wire route framed) |
| 7 | `fewer_turns_out` | Fewer Turns Out | Each stage is the long-line transformer run in reverse — fewer turns out than in. | **distractor** | `#B08CF7` grid violet | ACT 1 | `fewerTurnsOut` — a transformer coil pair: many loops in, few loops out (countable), no body, no route | 3.1 `stepping_down` · `placeSub` coil-chip reveal frame |
| 8 | `water_carries` | Water Carries It | Tap water conducts — dimmer than copper, but live. | **distractor** | `#3FB9F5` transmission blue | ACT 4 | `waterCarries` — a circuit loop with a water sample bridging the gap and a dimly-lit bulb | 3.4 `conductors_insulators` · ~500 ms after tap water's bulb response lands |

**Crop factors** (normalized LTRB of each beat's captured scene; owned here, not re-tuned by the beats):
`staged_descent` `(0.10, 0.55, 0.92, 0.98)` (street + house + socket chip + pole stage) ·
`socket_not_harmless` `(0.30, 0.06, 1.0, 0.92)` (meter + bands + column with the SOCKET marker) ·
`same_level_safe` `(0.06, 0.04, 0.98, 0.62)` (both equal wires + bird + chips + scale) ·
`ground_is_zero` `(0.02, 0.12, 0.80, 0.96)` (person + wire + ground return path) ·
`copper_in_plastic` `(0.18, 0.30, 0.82, 0.72)` (cable cross-section) ·
`surge_blows_fuse` `(0.0, 0.0, 0.78, 0.95)` (fuse + case + earth wire + terminal) ·
`fewer_turns_out` `(0.10, 0.10, 0.60, 0.40)` (substation + coil chip) ·
`water_carries` `(0.22, 0.06, 0.86, 0.66)` (bulb + seated water sample).

### Why these two distractors pass the distractor test (true-but-irrelevant; answer a DIFFERENT question)

The test (from `prd_episode1_cer_closing.md` §2.3 and curriculum §7): a distractor is **true and genuinely witnessed**, never false or tricky; setting it aside is recognizing it belongs to a *different* question.

- **`fewer_turns_out`** — TRUE (each EP3 stage really is the 2.6 transformer wound in reverse, fewer turns out than in). But it answers *how the step-down device works inside* (the induction mechanism, an EP2 thread), **not** *how the power gets into your house without killing you*. It is the EP3 mirror of EP1's `still_magnet` / `turbine_spin` — the beat's own true detail, belonging to the "how it's made / how it works" thread, not the "how it's safe" thread. The episode's safety architecture does not turn on the winding ratio; it turns on the *staging*, which `staged_descent` already carries.
- **`water_carries`** — TRUE (tap water conducts — dimmer than copper, but live; a real, surprising, safety-*flavoured* fact). But it answers *which materials conduct* (the conductors/insulators thread), **not** *how the supply reaches you safely*: no part of the delivery chain runs through water. Its safety-flavour is exactly what makes it a *good* distractor — relevance is a real judgment, not trap-spotting. (Its honest safety lesson — wet hands and live sockets — already lives, felt, inside 3.4; the tile here is a clue about a material, not about the delivery system.)

Neither is false, neither is tricky, neither punishes; both are real discoveries the learner made. Leaving them behind is the reasoning.

### Dropped / reconciled tiles (catalog deltas — see §11 for the full list)

- `transmission_off_scale` (proposed by an earlier 3.2 draft) — **DROPPED**: redundant with `socket_not_harmless` (same instrument, same idea — "even past the socket it's above the bands"); `socket_not_harmless` already frames both the off-scale dot and the SOCKET marker in one shot.
- `body_in_path` (proposed by an earlier 3.5 draft) — **DROPPED**: redundant with `ground_is_zero` (both are "the full difference crosses a grounded body"). 3.5's body-danger half stays fully *witnessed* in the activity; only its `onCapture` is removed. 3.5 keeps exactly one relevant tile, `surge_blows_fuse`.

This trims to **fewer, stronger tiles**: one tile per distinct reasoning move, no two tiles making the same point.

## 4. Staging (how tiles group into screens of ≤6 visible)

7 tiles > 6, so Screen 1 (Evidence) stages in **two groups**, mirroring EP1's `_groupA` / `_groupB` two-stage pattern in `cer_controller.dart`. The grouping is thematic, not difficulty-ordered, and each group is a real judgment (each group mixes relevant tiles with a planted distractor, so relevance must actually be weighed):

- **Group A — "What the danger is" (4 tiles):** `socket_not_harmless`, `same_level_safe`, `ground_is_zero`, `water_carries` *(distractor)*. The premise thread — what makes the supply dangerous and when current crosses a body — with the material-conductivity distractor mixed in (it *feels* like it belongs to "what's dangerous," which is the discrimination).
- **Group B — "How it's handled" (4 tiles):** `staged_descent`, `copper_in_plastic`, `surge_blows_fuse`, `fewer_turns_out` *(distractor)*. The management thread — step down, contain, escape route — with the device-internals distractor mixed in (it *feels* like it belongs to "how it's handled," which is the discrimination).

Each group shows **≤6 (here 4) at once** → the ≤6-visible cap holds with headroom. Stage A is shown first; "More Clues" reveals Stage B (the shipped two-stage staging UI). Kept tiles persist across the stage switch into the "my evidence" tray.

Screen 2 (Claim) shows **only kept tiles** (≤6 when the case is correct: the 5 relevant; distractors, if mistakenly kept, also show — still ≤7, and the playback's incompleteness on Screen 3 is the gentle correction, never a ✗). Screen 3 (Playback) montages the kept relevant tiles in the §6 order.

## 5. Claim build (2-slot template — built, never picked whole)

Following EP1's spirit (a near-complete sentence with the key insight as the learner's choice; ~2 meaningful slots; each a quick tap from 3 chips; the honest insight reachable **only by assembly**). The two slots are the two load-bearing ideas of the EP3 synthesis: **(1) what the danger does to the supply level — it is not removed, only managed; (2) what keeps that managed danger off a body.** The right pairing states *managed danger handed an escape route*; every wrong pairing is true-sounding but misses the architecture.

**Template (verbatim — `claimSegments` + `slotOptions` in `kEp3CerConfig`):**

> "The lethal supply is **[slot1]**, so it gets into your house without killing you because it is **[slot2]**."

**slot1 options** (what happens to the danger — the honest one is "managed, never removed"):
1. `made harmless` *(decoy — contradicts 3.2's "manageable, not harmless"; the episode's central honesty)*
2. **`stepped down to a manageable level`** *(the honest choice)*
3. `switched off before the house` *(decoy — false; the supply is live at the socket)*

**slot2 options** (what keeps it off you — the honest one names contain + escape route):
1. `too small to feel` *(decoy — restates the rejected "harmless"; 230V still drives harmful current)*
2. **`contained, with a fault's escape route to ground`** *(the honest choice)*
3. `kept far from every home` *(decoy — false; it is brought right to the socket)*

The assembled honest claim: **"The lethal supply is stepped down to a manageable level, so it gets into your house without killing you because it is contained, with a fault's escape route to ground."** The learner authors it; no full pre-written claim is ever offered. The decoys are not "wrong answers" with ✗ — they simply make a claim the playback then can't fully support; the learner may revise (gentle, see §6).

## 6. Playback (montage order + capstone) and the completeness nudge

### Montage order (Screen 3)

The kept **relevant** tiles animate in sequence (650 ms/tile, the shipped stagger), ordered as a reasoning chain that walks the episode question's answer — premise → bringing it down → keeping it off you:

1. `socket_not_harmless` — *even stepped down, it still harms*
2. `same_level_safe` — *current crosses a body only across a difference*
3. `ground_is_zero` — *a grounded body spans the full difference — that is the danger*
4. `staged_descent` — *so it is stepped down in stages to a manageable level*
5. `copper_in_plastic` — *contained — a conductor wrapped in an insulator*
6. `surge_blows_fuse` — *and any fault gets a deliberate route to ground that trips the fuse*

(If the learner kept fewer relevant tiles, the montage plays only those and *feels* incomplete — the gentle prompt fires; see below. Distractors mistakenly kept are simply not part of the argument's spine and read as not belonging when the capstone lands.)

### Capstone line (after the montage, `capstone` in config)

> **"Managed, not made harmless — stepped down, contained, and handed an escape route. That is how it reaches your socket without reaching you."**

It names the architecture, not any one tile; it lands the §1 synthesis; it carries the playback's reasoning, not a grade.

### Completeness nudge (gentle — no score, no checkmarks, `nudge` copy)

If the case is missing a relevant pillar (the `caseComplete` heuristic from the shipped `cer_controller.dart` returns false), the playback finishes a touch thin and a calm two-option prompt appears (the shipped "Add a clue" / "Finish anyway" pattern):

- **`Add a Clue`** → returns to the evidence stage with kept tiles preserved (never resets).
- **`Finish Anyway`** → proceeds to the card; the learner is never blocked or marked wrong.

Nudge body copy (one line, no ✓/✗, no number): *"Your case is missing a step — go back and add a clue, or finish as it is."*

No score anywhere. No ✓/✗ anywhere. It *responds* (the montage feels complete or thin), exactly like the rest of the module.

## 7. The card (EP3 synthesis card — full front/back)

**Card: YES** — one episode-synthesis card per CER (the EP1 precedent: `grid_is_a_mix`, "The Grid Is a Mix"). This card names the *system-level law* of EP3 — managed danger, the three-part architecture — which no beat card states: 3.1's "The Last Mile" owns staging, 3.4's "The Free and the Locked" owns carry/block, 3.3's "The Bird's Secret" owns potential difference, 3.5's "The Third Pin" owns the escape-route mechanism. This card owns the **synthesis of all of them into one managed-danger system**, so it restates no other card's law (covenant §6).

Shared-infra agent assigns the number, sets `deckTotal` on ALL constants in one pass, implements the motif painter, and adds the `collectible_card_view.dart` dispatch case. Build agent references the constant only. Section `homeSafety`, accent `#3FD99B`. Proposed constant: **`kManagedDangerCard`**. It visibly links the four EP3 beat cards together (the deck-as-shape-of-the-system payoff), mirroring how EP1's CER card links Card 02 + Card 03.

- **Front — playful name:** **The Tamed Line**
- **Front — real term (mono specimen label):** `MANAGED DANGER`
- **Front — one-line law:** *Lethal supply is made livable, never harmless — stepped down, contained, and handed an escape route to ground.*
- **Front — kicker:** *Safe is the wrong word; managed is the right one.*
- **Back — tie to what was FELT:** *You felt it never gets safe — 230 volts still drove current past the danger line, and a grounded body spanned the full difference. So it is staged down to a manageable level, wrapped in insulators, and given a fault an escape route that blew the fuse.*
- **Back — outward reach:** *Every socket in your home is this same bargain: a tamed lethal line, kept off you by three things working at once — distance brought down, danger boxed in, and a door held open to the earth.*
- **Linked cards:** `kLastMileCard` (3.1), `kBirdsSecretCard` (3.3), `kConductorsInsulatorsCard` (3.4), `kEarthingCard` (3.5) — the four EP3 beat cards this synthesis ties together. (Shared infra confirms the link rendering + numbering.)
- **Earn copy:** eyebrow `CASE CLOSED` (matching EP1's CER earn eyebrow); brag (`brag:` in the overlay): *"You proved how a lethal line reaches your socket without reaching you."*; `showMascot: false`.
- **Inline fact:** none — a CER closer earns its synthesis card; an inline fact would dilute the capstone.

## 8. Curriculum §13 sections that apply

This is a synthesis closer, not a manipulable-primitive activity, so several §13 sections collapse onto the CER's own structure (already specced in `prd_episode1_cer_closing.md`). The sections that apply and where they land:

- **§13.1 One-concept statement** → §1 (the managed-danger synthesis).
- **§13.2 Guiding-question link + CER contribution (incl. distractor flags)** → §2, §3 (this IS the CER; distractors flagged and justified).
- **§13.3 The felt discovery** → the *assembly* is the cognition: selecting relevant clues, building the claim, watching it play back (curriculum §7; EP1 §3–§4). Not a hands-on sim.
- **§13.4 Felt vs named vs numbered** → §3 + §6: evidence is **felt replayable moments** (the tiles), never text bullets; nothing is **numbered** in the CER (no score, no count, no %); the claim's two slots are the only "naming," and they're **built**.
- **§13.5 On-screen text (exact)** → §10 (all three screens, verbatim).
- **§13.6 Beat-by-beat flow + gating** → §10 (the 3-screen sequence, staging gate, nudge gate).
- **§13.7 Hero & layout + clutter caps** → §10 (the hero is the evidence/claim/playback; ≤6 tiles visible; pinned question + one task + tiles, nothing else).
- **§13.8 Reward** → §7 (the synthesis card; no inline fact).
- **§13.9 CER capture hook** → N/A as a *producer* (the CER consumes captures); §3 documents which beats produce which tiles.
- **§13.10 Build notes** → §10 build line (thin wrapper on `MakeYourCaseScreen(config:)`; no Forge2D; reuses shipped flow).
- **§13.11 Acceptance criteria** → §9 (the anti-worksheet rules as testable checks).
- **§13.12 Anti-patterns** → §9 (worksheet, tabs, drag-lines, ✓/✗, score, false distractors).
- **§13.13 Open decisions** → §12.

Global guards inherited (not re-derived): felt-first (§2); text rules (§3 — name the noun, fact-not-narration, no rhyme); UI minimalism (§4 — sequence don't cram, ≤6 visible); build/stack + no-Forge2D (§5); honest depth-stops (§6 — N/A here, EP3's depth-stop lives in 3.4, never reopened); CER anti-worksheet rules (§7).

## 9. Acceptance criteria (the anti-worksheet rules, as testable checks)

The non-negotiables from `prd_episode1_cer_closing.md` §5 and curriculum §7, restated for EP3:

1. **Evidence is captured felt MOMENTS (replayable visual tiles), never text bullets.** All 7 tiles render as scene thumbnails (real `Image.memory` capture when present, else the §3 motif painter) + a ≤3-word label; the caption appears only inside the tap-preview, never as a standing bullet list.
2. **The claim is BUILT (assembled by tapping the two slots), never selected from full pre-written claims.** Screen 2 offers the §5 template with two 3-chip slots; no full-sentence option list exists anywhere.
3. **Reasoning is carried by the PLAYBACK** (the §6 ordered montage IS the argument), not a typed essay and **no drag-lines** between evidence and claim.
4. **The payoff is the case PLAYED BACK, never a score. No ✓/✗ anywhere.** No score, no grade, no correct/wrong feedback on tile selection or slot choice; the screen *responds* (montage complete vs thin; capstone).
5. **Distractors are exactly 2, TRUE-but-irrelevant** (`fewer_turns_out`, `water_carries`) — never false or tricky; leaving them behind is the relevance judgment, not trap-spotting (§3 justification).
6. **3 sequential screens, one task each — never tabs.** Evidence → Claim → Playback; no tabbed checkbox lists anywhere.
7. **≤6 tiles visible per screen** — Screen 1 stages 7 into two groups of 4 (§4); Screens 2–3 show only kept tiles.
8. **The guiding question is pinned** at the top of every screen (the `kEpisode3Question` constant, identical to the board strip used all episode).
9. **The synthesis is the EPISODE's, not a restated beat:** the capstone (§6) and card (§7) name the step-down + contain + escape-route architecture, and the card restates no beat card's law (§7 link check).
10. **The case responds, doesn't reset:** an incomplete case triggers the gentle "Add a Clue / Finish Anyway" nudge (§6) preserving kept tiles; "Finish Anyway" never blocks; the card always earns on Finish.
11. **Dev-entry robustness (inherited):** if NOTHING was captured (dev entry into the wrapper), the engine falls back to the full §3 catalog so the screen is always playable (shipped behavior — do not regress).
12. **Completion contract:** Finish → card overlay (`CASE CLOSED`) → `Navigator.maybePop`; `MakeYourCaseScreen(config: kEp3CerConfig)` constructible; analyzer clean on `make_your_case_ep3`.

## 10. Exact on-screen text — all three screens

Header title: `Make Your Case` · mono eyebrow subtitle: `EPISODE 3 · HOME & SAFETY`. Pinned question (all screens, the `CerQuestionHeader` from `cer_chrome.dart`, with 3 progress dots): **"The power reaches your town still at lethal transmission voltage — how does it get into your house without killing you?"**

Two registers as everywhere: short imperative task lines (Bricolage, Title Case, ≤5 words) and de-personified meaning/prompt lines (Plus Jakarta Sans). No mascot, no info-cards.

### Screen 1 — Evidence ("Which clues answer the question?")
- **Task line (imperative):** `Pick the Clues That Fit`
- **Stage-A sub-label (meaning, small):** *What makes it dangerous?*
- **Stage-B sub-label (meaning, small), on advance:** *And how is it handled?*
- **CTA (between stages):** `More Clues` → (on stage B) `Build the Claim`
- Tap a tile → it lifts into the "my evidence" tray; tap again to set it back. No correct/wrong marking. Tap-preview shows the §3 caption + a keep/remove control (the shipped `evidence_preview.dart`).
- (No other text. The two distractors sit among the relevant tiles with no visual tell.)

### Screen 2 — Claim ("Build your answer")
- **Task line (imperative):** `Build Your Claim`
- **The template (the only body text — two tap-fill slots, §5):**
  > "The lethal supply is **[ … ]**, so it gets into your house without killing you because it is **[ … ]**."
- **slot1 chips:** `made harmless` · `stepped down to a manageable level` · `switched off before the house`
- **slot2 chips:** `too small to feel` · `contained, with a fault's escape route to ground` · `kept far from every home`
- **CTA (gated until both slots filled):** `See My Case`

### Screen 3 — Playback ("Here's your case")
- **Header label (meaning, small):** *Your case, played back.*
- The kept relevant tiles animate in the §6 order (650 ms each), the built claim pinned above.
- **Capstone (meaning, lands after the montage):**
  > "Managed, not made harmless — stepped down, contained, and handed an escape route. That is how it reaches your socket without reaching you."
- **If incomplete — gentle nudge (no ✓/✗, no score):** *"Your case is missing a step — go back and add a clue, or finish as it is."* with `Add a Clue` · `Finish Anyway`.
- **Finish CTA:** `Close the Case` → card overlay (`CASE CLOSED`) → `Navigator.maybePop`.

**Build line:** `make_your_case_ep3` is a thin registered wrapper: `MakeYourCaseScreen(config: kEp3CerConfig)`. The shared-infra agent authors `kEp3CerConfig` from this PRD (catalog §3, staging §4, claim §5, playback/capstone/nudge §6, card/earn §7, screen text §10) and registers the wrapper in `activityRegistry.dart`. No new engine, no new chrome, no Forge2D. The build agent for this id touches only the wrapper + config payload; the CER engine, evidence board, capture infra, and card overlay ship unchanged from EP1.

## 11. CATALOG DELTAS vs the beat PRDs (reconciliation the shared-infra/build agents must apply)

The beat PRDs are reconciled to *this* catalog. Net effect: **5 relevant + 2 distractors, one tile per reasoning move.**

1. **3.1 `stepping_down`** — KEEP `staged_descent` (relevant). KEEP `fewer_turns_out` but **confirm it as a DISTRACTOR** (the beat proposed it tentatively; it is now locked as one of EP3's exactly-2 distractors). No change to capture frames.
2. **3.2 `current_through_you`** — KEEP `socket_not_harmless` (relevant). **DROP `transmission_off_scale`** (redundant; do not wire it). The beat PRD already reflects this — no further change.
3. **3.3 `bird_on_the_wire`** — KEEP both `same_level_safe` and `ground_is_zero` (both relevant). The beat's *recommendation* to source EP3's distractors elsewhere is **honored** (its distractors come from 3.1 and 3.4, not 3.3). No change.
4. **3.4 `conductors_insulators`** — KEEP `copper_in_plastic` (relevant) and `water_carries` (locked as the second DISTRACTOR). No change.
5. **3.5 `earthing`** — KEEP `surge_blows_fuse` (relevant). **DROP `body_in_path`** (redundant with `ground_is_zero`); the beat keeps the body-danger half *witnessed* but removes its `onCapture`. The beat PRD already reflects this — no further change.

Accent/motif/crop authority: all owned by §3 of this PRD. Where a beat PRD suggested its own accent or crop (e.g. 3.2's `(0.30,0.06,1.0,0.92)`, 3.3's suggested crops), §3 adopts them verbatim where sensible and is otherwise authoritative — beats must not re-tune locally.

## 12. Open decisions

1. **Two distractors vs three** — locked at exactly 2 per the covenant/EP1 rule (3+ → clutter/test-feel; 0 → "select all" wins). Not reopened.
2. **Staging split** — Group A "what's dangerous" / Group B "how it's handled" (§4), each 4 tiles. Alternative: catches-first / management-second by source act. Recommend the thematic split (it makes each group a real relevance judgment with a planted distractor). Tunable in `kEp3CerConfig.stageGroups` without code change.
3. **Claim granularity** — 2-slot template (§5), per the EP1 recommendation (enough cognition, lowest friction, not disguised multiple-choice). Not chip-assembly, not full-claim pick.
4. **Playback form** — lighter tile-sequence + capstone (the shipped EP1 form), upgradeable to scene-replays later. Recommend shipping the tile-sequence.
5. **Card name** — "The Tamed Line" / `MANAGED DANGER` (§7). Alternative: "Managed, Not Safe". Recommend "The Tamed Line" (playful + precise; pairs with the `MANAGED DANGER` specimen). Final copy confirmed with shared infra.
6. **Question-string source** — the single `kEpisode3Question` constant (owned here, used by all 5 beats' board strips and all 3 CER screens); phrasing locked in §2.

---

## RETURN SUMMARY (for the calling script)

**Final evidence catalog (`episode3_electricity`) — 5 relevant + 2 distractors:**

| id | relevant | source beat |
|---|---|---|
| `staged_descent` | relevant | 3.1 `stepping_down` |
| `socket_not_harmless` | relevant | 3.2 `current_through_you` |
| `same_level_safe` | relevant | 3.3 `bird_on_the_wire` |
| `ground_is_zero` | relevant | 3.3 `bird_on_the_wire` |
| `copper_in_plastic` | relevant | 3.4 `conductors_insulators` |
| `surge_blows_fuse` | relevant | 3.5 `earthing` |
| `fewer_turns_out` | **distractor** | 3.1 `stepping_down` |
| `water_carries` | **distractor** | 3.4 `conductors_insulators` |

**Claim template (verbatim):**
"The lethal supply is **[slot1]**, so it gets into your house without killing you because it is **[slot2]**."
slot1: `made harmless` / **`stepped down to a manageable level`** / `switched off before the house`
slot2: `too small to feel` / **`contained, with a fault's escape route to ground`** / `kept far from every home`

**Card name:** "The Tamed Line" (`MANAGED DANGER`), proposed constant `kManagedDangerCard`, section `homeSafety`, earn eyebrow `CASE CLOSED`.

**Catalog deltas vs the beat PRDs:**
- DROPPED `transmission_off_scale` (3.2) — redundant with `socket_not_harmless`.
- DROPPED `body_in_path` (3.5) — redundant with `ground_is_zero`.
- LOCKED `fewer_turns_out` (3.1) as a distractor (beat proposed it tentatively).
- LOCKED `water_carries` (3.4) as the second distractor.
- All other proposed tiles kept as-is; accents/motifs/crops now owned by this catalog.
