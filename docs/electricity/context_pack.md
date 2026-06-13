# Electricity Module — Build Context Pack (Episodes 2–5)
### The covenant every PRD agent, reviewer, and build agent must follow

This pack is the consolidated, binding context for building the remaining activities of the
"How Electricity Reaches Your Home" wowConcept. It encodes the decisions already made, the
corrections to older docs, the integration contracts with the existing codebase, and the
quality bar set by the shipped activities. Read it in full before writing a PRD or code.

Companion file: `docs/electricity/architecture_reference.md` — exact APIs, file trees,
class names, and verbatim snippets from the four shipped electricity activities and the
shared systems (CER engine, evidence board, collectibles, lessonRunner). Treat it as the
authoritative map of the code you are extending.

---

## 1. Source-of-truth hierarchy (and the corrections that matter)

1. **`/Users/Sahu/Downloads/howwow_electricity_curriculum.md`** — THE single source of truth
   for pedagogy, episode/beat content, text rules, UI minimalism, depth-stops, CER pattern,
   and the PRD section list (§13). When any other document disagrees, the curriculum wins.
2. **Post-build delta specs** (what the user actually corrected after building):
   - `/Users/Sahu/Downloads/howwow_activity2_update_consolidated.md` (Voltix removed → top-text
     imperatives + meaning-lines; converging-repetition technique; witnessed-absence technique;
     depth-stop wording)
   - `/Users/Sahu/Downloads/howwow_activity3_update_spec.md` (driver + power live numbers
     co-varying; dramatic failure moments; auto-play day; quantify-vs-felt split)
   - `/Users/Sahu/Downloads/howwow_handcrank_screen_polish_spec.md`, 
     `/Users/Sahu/Downloads/howwow_activity2_traceback_polish_spec.md` (house visual style)
3. **Old PRDs** — format/depth exemplars ONLY (their Voltix dialogue and "bedrock" framing are
   obsolete): `prd_prologue.md`, `prd_activity2_generator_traceback.md`,
   `prd_activity3_source_personalities.md`, `prd_episode1_cer_closing.md` (this one is still
   the live spec for the CER pattern), all in `/Users/Sahu/Downloads/`.
4. **`/Users/Sahu/Downloads/howwow_method_playbook.md`** — philosophy + anti-patterns (§1, §9
   are gold) BUT its companion-bot sections are superseded.
5. **Interaction blueprint v2** (`/Users/Sahu/Downloads/How Electricity reaches your home?/
   howwow_electricity_interaction_blueprint_v2.md`) — per-beat interaction-mechanic inspiration
   only. Its per-section games and leaky-bucket beat are obsolete.

**Hard corrections (do not regress on these):**
- **No mascot, no narrator, no Voltix, no info-cards.** One voice: the on-screen text itself.
  Short **imperatives** for actions ("Raise the Voltage"); separate **meaning-lines** for the
  lesson, de-personified, stated as fact.
- **No per-episode games.** Every episode closes with the 3-screen CER "Make Your Case".
- **Leaky bucket (old 1.3) is removed** from EP1's flow (code remains, unwired). Episode 2
  beat 2.3 now teaches "loss = heat" FROM SCRATCH and must carry that weight.
- **Induction is a DEPTH-STOP, not bedrock.** Never write "nobody knows why". The honest line
  pattern (from the shipped build): *"Electricity and magnetism are secretly the same thing —
  you'll meet the deep reason in a few years."* Same rule for conductors/insulators in 3.4
  (free vs bound electrons — a depth-stop, halted by choice, said so honestly). **No analogy
  at a depth-stop's floor.**
- **Register is 12–80, not "kids".** Simple ≠ soft. Real terms, explained properly. The test:
  "would this read as well-written to an adult?" Childish = vagueness + forced enthusiasm +
  addressing-as-child + rhyme.
- **Numbers vs felt (settled):** genuine physical quantities (power, voltage, current,
  wind, cost, frequency, kWh) may appear as LIVE, RELATIVE numbers (input = 100 style, ≤2 on
  screen). Qualitative judgments stay FELT (haze, darkness, flicker). The one banned thing is
  a static pros/cons ratings table.

---

## 2. Locked decisions (made by the user — do not reopen)

- **One activity per numbered curriculum beat.** EP2 = 8 activities + CER; EP3 = 5 + CER;
  EP4 = 5 + CER; EP5 = 4 + grand finale.
- **EP4 beat 4.2 (spinning machines + frequency) is IN.**
- **EP5 finale = a grand multi-episode CER** ("How does electricity reach your home?") drawing
  evidence from all episodes. No town-sim game.
- Build order: shared infra (CER engine v2 + evidence catalogs + cards) first, then activities
  in parallel, then integration (registry + wowConcepts) last, done centrally.

---

## 3. The activity plan (IDs are LOCKED — use exactly these)

Directory = `lib/screens/missions/<dir>/`. Registry id = backend `activityId` string.

| Beat | Registry id / dir | Screen class | Episode evidence id |
|---|---|---|---|
| 2.1 voltage vs current | `voltage_and_current` | `VoltageAndCurrentScreen` | `episode2_electricity` |
| 2.2 what resistance is | `what_resistance_is` | `WhatResistanceIsScreen` | `episode2_electricity` |
| 2.3 current heats the wire | `current_heats_wire` | `CurrentHeatsWireScreen` | `episode2_electricity` |
| 2.4 the squared loss | `squared_loss` | `SquaredLossScreen` | `episode2_electricity` |
| 2.5 the transmission trick | `transmission_trick` | `TransmissionTrickScreen` | `episode2_electricity` |
| 2.6 the transformer | `the_transformer` | `TheTransformerScreen` | `episode2_electricity` |
| 2.7 AC and DC | `ac_vs_dc` | `AcVsDcScreen` | `episode2_electricity` |
| 2.8 why the grid is AC | `war_of_currents` | `WarOfCurrentsScreen` | `episode2_electricity` |
| EP2 CER | `make_your_case_ep2` | thin wrapper on shared CER engine | `episode2_electricity` |
| 3.1 stepping down | `stepping_down` | `SteppingDownScreen` | `episode3_electricity` |
| 3.2 current through you | `current_through_you` | `CurrentThroughYouScreen` | `episode3_electricity` |
| 3.3 the bird on the wire | `bird_on_the_wire` | `BirdOnTheWireScreen` | `episode3_electricity` |
| 3.4 conductors & insulators | `conductors_insulators` | `ConductorsInsulatorsScreen` | `episode3_electricity` |
| 3.5 earthing | `earthing` | `EarthingScreen` | `episode3_electricity` |
| EP3 CER | `make_your_case_ep3` | thin wrapper | `episode3_electricity` |
| 4.1 supply must match demand | `hold_the_balance` | `HoldTheBalanceScreen` | `episode4_electricity` |
| 4.2 spinning machines & frequency | `grid_frequency` | `GridFrequencyScreen` | `episode4_electricity` |
| 4.3 the living demand curve | `demand_curve` | `DemandCurveScreen` | `episode4_electricity` |
| 4.4 baseload vs peaking | `baseload_peaking` | `BaseloadPeakingScreen` | `episode4_electricity` |
| 4.5 cascading blackout | `cascading_blackout` | `CascadingBlackoutScreen` | `episode4_electricity` |
| EP4 CER | `make_your_case_ep4` | thin wrapper | `episode4_electricity` |
| 5.1 energy, not power | `energy_vs_power` | `EnergyVsPowerScreen` | `episode5_electricity` |
| 5.2 why 6pm costs more | `peak_pricing` | `PeakPricingScreen` | `episode5_electricity` |
| 5.3 one shared grid | `one_shared_grid` | `OneSharedGridScreen` | `episode5_electricity` |
| 5.4 the bill is a receipt | `the_bill_receipt` | `TheBillReceiptScreen` | `episode5_electricity` |
| Grand finale CER | `make_your_case_finale` | grand CER over ALL episodes | `finale_electricity` |

Episode guiding questions (pinned on the evidence board; final phrasing owned by each
episode's CER PRD, drawn from the curriculum's "*Question:*" lines):
- EP2: how do we send power across that distance without losing it all on the way?
- EP3: how does it get into your house without killing you?
- EP4: who keeps making exactly what the city uses, this very second — and what happens at 6pm?
- EP5: who pays for all this, and why does 6pm cost more than 3am?
- Finale: how does electricity reach your home?

---

## 4. Integration contracts (what every activity MUST do)

**The activity contract** (see architecture_reference.md for verbatim snippets):
1. Register-ready: a `const <Name>Screen()` StatefulWidget at
   `lib/screens/missions/<dir>/<dir>_screen.dart`. Registration in `activityRegistry.dart`
   is done centrally at integration time — DO NOT edit shared files from a build agent.
2. Completion = `Navigator.maybePop(context)` from your post-card Continue CTA. Any pop counts
   as completion to the lessonRunner; there is no result payload.
3. Wrap the screen in `MediaQuery(...textScaler: TextScaler.noScaling)` like the shipped
   activities; respect `MediaQuery.disableAnimations` (reduced motion: calm particles, fades
   instead of flourishes — but NEVER soften a pedagogical instant-cutoff).
4. Portrait, mobile-first. Factor-based geometry off one stage size (the `TBTune`/`CrankConfig`
   pattern). No fixed pixel scene layouts.
5. State: a `<Name>Controller extends ChangeNotifier` owning sim + geometry + phase machine;
   ValueNotifiers for discrete UI channels; pure-renderer painters/Flame components that only
   read controller getters. Flame `GameWidget` for living scenes; plain `CustomPainter` for
   single-precision widgets. **No Forge2D** (controlled motion only; instant cutoffs are hard
   gates in the update loop, never decay/momentum).
6. Evidence capture: wrap the scene in `RepaintBoundary(key: _sceneKey)`; wire
   `controller.onCapture = _onCapture` → `captureScenePng(_sceneKey, cropFactor:
   evidenceByIdFor(<episodeId>, id)?.cropFactor)` → `_board.capture(id, imageBytes: bytes)`;
   show `EpisodeBoardStrip` pinned under the header with the episode question. Capture ids are
   LOCKED by the episode's evidence catalog (shared infra) — call exactly those ids at exactly
   the moments the PRD specifies.
7. Card earn: `CollectibleEarnOverlay(card: k<YourCard>, eyebrow: 'NEW CARD', brag: <one-line>,
   showMascot: false, onDone: controller.onCardCollected)`. Card constants are created by the
   shared-infra phase — reference them, never define cards locally, never touch
   `collectible_models.dart` / `collectible_painters.dart` / `collectible_card_view.dart`.
8. Haptics map (match shipped feel): `selectionClick` per control detent / chip tap;
   `heavyImpact` at the discovery moment; `lightImpact` on evidence capture; medium impact is
   inside the card overlay already.
9. Audio: optional. If used, copy the `audioplayers` + `AudioContext` mixWithOthers pattern and
   `audioSource()` S3 helper; BGM volume ≤ 0.2. Most shipped electricity activities are silent
   or BGM-only — silence is fine.
10. Text chrome: header back button on glass; title (Bricolage Grotesque w800 ~20–21px) +
    mono eyebrow subtitle; instruction banner with 190ms fade-out → swap → fade-in (never
    cross-fade); gold gradient pill Continue CTA.

**File-surface rule for build agents:** write ONLY inside your own activity directory.
The per-episode evidence catalogs, CER configs, card constants/painters, registry entries and
wowConcepts wiring are owned by other phases. If you believe a shared file must change, STOP
and report it in your final message instead of editing it.

**Verification gate for every build agent:** `fvm dart analyze lib/screens/missions/<dir>`
must come back clean (the repo has ~468 pre-existing errors in unreferenced legacy files —
they are NOT yours; never run repo-wide `flutter analyze` with multiple paths, it crashes).
Also run `fvm dart analyze` on any shared file you import to confirm your imports resolve.

---

## 5. The CER engine v2 (shared infra — built before activities)

The shipped `make_your_case` is EP1-hardcoded. Shared infra parameterizes it:
- `CerConfig` (question, evidence catalog, stage groups, claim template segments with 2 tap-fill
  slots + options, capstone line, incomplete nudge, card + earn copy), with
  `kEp1CerConfig` preserving today's behavior exactly.
- Evidence registry: per-episode catalogs `kEpisode2Evidence` … in per-episode files
  (`evidence_models_ep2.dart` etc.) + `evidenceByIdFor(episodeId, id)` lookup; 
  `EpisodeBoardCapture` switched to the registry lookup (back-compatible with EP1).
- Per-episode motif painters in per-episode painter files (fallback art when a real PNG capture
  is missing).
- Thin registered wrappers: `make_your_case_ep2/3/4` → `MakeYourCaseScreen(config: ...)`.
- Grand finale: a `finale` config whose catalog is built from a small per-episode selection of
  the strongest tiles ACROSS episodes (loaded captures preferred, motif fallback otherwise),
  with episode badges on tiles; 3-screen flow unchanged; may use a 3-slot claim template.

CER rules (non-negotiable, from `prd_episode1_cer_closing.md` + curriculum §7): evidence =
felt moments as replayable tiles, never text bullets; distractors = exactly 2, true-but-
irrelevant; claim is BUILT from slots, never picked whole; playback carries the reasoning;
no score, no ✓/✗, no tabs; ≤6 tiles visible per screen (stage if more).

---

## 6. Cards (shared infra owns the catalog)

Existing: 01 Conservation (Prologue), 02 Induction (1.1), 03 No Free Lunch (1.2),
04 The Great Escape (orphaned with leaky bucket — leave untouched), 05 The Grid Is a Mix
(EP1 CER). Sections/accents already themed: transmission #3FB9F5, homeSafety #3FD99B,
grid #B08CF7, theBill #E0A96D.

Rules for new cards:
- A beat earns a card ONLY if its concept is a row in the curriculum's quick-reference table
  (that's the "completed idea" list). Episode CERs earn one synthesis card each (EP1 precedent).
  Expected new cards ≈ EP2: voltage/current, resistance, current→heat, I²R, transmission trick,
  transformer (linked to 02), AC/DC, + EP2 CER synthesis; EP3: distribution grid, potential
  difference, conductors/insulators (depth-stop card), earthing, + CER; EP4: the-grid/no-buffer,
  frequency, baseload/peaking, + CER; EP5: kWh (linked to transmission trick — the rectangle),
  natural monopoly, + finale "The Whole Machine" card.
- Front = playful name + real term (mono specimen label) + one-line law + kicker. Back =
  tie-back to what was FELT + one outward reach. A card names the LAW, never re-narrates the
  activity. No card may restate another card's law.
- PRD agents PROPOSE exact card copy in §8 of their PRD. The shared-infra agent consolidates
  the final catalog, assigns numbers, updates `deckTotal` on ALL constants in one pass, and
  implements motif painters. Build agents only reference `k<Name>Card` constants.

---

## 7. Visual language tokens (the shipped house style — match it)

- Backgrounds: near-black `#070A1C` base; ink `#0B1026` / `#161D3A`; radial vignette darkest
  behind the hero; whisper-faint circuit texture (~5% alpha); EnergyFieldBackground variants.
- Warm light vs cool dark: the hero (current, glow, lit town, heat) is the brightest thing on
  screen; chrome recedes (glass fills `0x14FFFFFF`, borders `0x26FFFFFF`).
- Type trio: Bricolage Grotesque (display/imperatives), Plus Jakarta Sans (meaning-lines/body),
  IBM Plex Mono (labels, live numbers, specimen text). Sizes per architecture reference.
- Accents: per-section card accents above; in-scene warm energy `#FFD27A`, heat `#FF7A2E`,
  warm bulb `#FFE9B8`, gold CTA gradient `#F5C451 → #D9A43B`, episode-board gold `#E8C98A`.
- Premium = layered depth (far/mid/near), additive glows (`BlendMode.plus`), soft shadows,
  specular highlights, entrance reveals (slide+scale+fade 0→0.45s), 16–26 ambient motes max,
  one orchestrated moment (the discovery or the earn), restraint everywhere else.
- Live numbers: mono font chips, dark glass containers, trend arrows where rate matters;
  ≤2 numbers on screen.
- The clutter test on every element: load-bearing for THIS activity's one concept, or cut.

---

## 8. What a PRD must contain (curriculum §13, plus build-spec additions)

Sections 1–13 exactly as the curriculum defines (one-concept statement; guiding-question link
+ CER contribution incl. whether a moment is a distractor; felt discovery; felt/named/numbered;
EXACT on-screen text beat by beat; beat-by-beat flow with timing/gating; hero & layout with
clutter caps; reward incl. proposed card copy; CER capture hook with proposed tile ids/labels/
captions; build notes; acceptance criteria encoding the pedagogy; anti-patterns; open
decisions). PLUS, for the build agent:
- **State machine sketch**: phases, ValueNotifiers, timers (ms), gating conditions.
- **File plan**: the exact files to create under the activity dir (screen / state / config /
  game-or-widgets), mirroring the shipped structure.
- **Scene sketch**: portrait layout described top-to-bottom with factor-based anchor hints.
- Held-constant variables named explicitly, with HOW they are shown to be held constant.
- Verbatim imperatives/meaning-lines obeying §3 (name the noun; consequence/destination, not
  behaviour/ending; no rhyme; meaning-lines may be a touch longer; Title Case short imperatives
  like the shipped "Spin the Magnet" / "Now Hold It Still").

The chain rule: 2.1 → 2.5 must never be reordered, and each of those PRDs must state what its
beat inherits (what the learner already felt) and what it pins (held constant) so the
"fixed wire" → "fixed power" flip in 2.5 reads as a twist, not a contradiction.

---

## 9. Known traps for THIS module (beyond playbook §9)

- A premium fade softening an instant cutoff (2.6's dead-transformer-on-DC moment, 4.1's
  tipping, the blackout) — cutoffs are hard gates.
- A meter where a consequence belongs: the town darkening IS the readout; the wire warming IS
  the loss. Numbers ride alongside, they never replace the felt thing.
- Explaining in an imperative: imperatives ≤5 words, they instruct; only meaning-lines teach.
- Pre-spoiling: never reveal a catch/twist in text before it is felt (the 2.5 current-drop,
  the dead DC transformer, solar's night death in the finale montage).
- Fail-states about the wrong thing: any struggle must be about the concept (e.g. in 4.1 the
  struggle is the unstoppable wiggle of demand, not fiddly slider ergonomics).
- Two ideas on one screen: if a screen teaches two things, sequence it into beats.
- Drag-lines, tabs, checkboxes, scores anywhere in CER flows.
- Touching another agent's files (registry, cards, evidence catalogs, wowConcepts).
