# PRD — Stepping It Down (EP3 beat 3.1)
### howwow · Episode 3 "Into Your House (Without Getting Hurt)" · registry id `stepping_down` · `SteppingDownScreen` · evidence episode `episode3_electricity`

Binding context: `docs/electricity/context_pack.md`, `docs/electricity/architecture_reference.md`, curriculum §3.1.
This PRD is self-contained: every on-screen line is quoted verbatim here.

---

## 1. One-concept statement

**Stepping down is STAGED, not single-shot — and that staging IS the distribution grid.**

Inherits from EP2: the learner already felt that high voltage + low current crosses distance without loss (2.5), that a transformer steps voltage with its turns and more turns out = higher voltage (2.6), and that the supply into the home is AC (2.8 bridge). This activity runs that same transformer THE OTHER WAY (fewer turns out than in) — referenced in one callback line, never re-taught.
Pins (held constant, visible): the **arriving transmission line voltage** (mono chip `LINE ×1000 HOUSE`, pinned top, shimmering but never changing; the line above the first drop keeps its corona the entire activity) and **the house** (same house, same socket, bottom of the route, all activity). The learner changes ONLY where and in how many stages the voltage drops.

## 2. Guiding-question link & CER contribution

Episode question (pinned on the board strip): *"The power reaches your town still at lethal transmission voltage — how does it get into your house without killing you?"*

- **Relevant evidence:** `staged_descent` — the success frame: two seated stages, the socket reading 230V AC, the house lit. It carries the first leg of the episode claim (*managed danger: staged step-down* + contain (3.4) + escape route (3.5)).
- **Distractor (proposed):** `fewer_turns_out` — TRUE (each stage is the 2.6 transformer wound in reverse) but it answers *how the stage device works inside*, not *how the power gets into the house without killing you*. Mirrors EP1's `still_magnet` / EP2's proposed `changing_field` distractor logic. Final allocation of EP3's exactly-2 distractors is owned by the EP3 CER PRD; this PRD proposes `fewer_turns_out` as one of them.

## 3. The felt discovery (discovery → reaction)

1. **Discovery:** the learner places the single transformer near the town edge (it drops the line straight to house level). **Reaction:** the long run below ignites heat-orange along its whole length in the same beat, heat shimmer rises, and the house at the bottom flickers dim — EP2's loss made local.
2. **Discovery:** the learner places it near the house instead. **Reaction:** the high line has to extend down into the streets to reach it — at the rooftop boundary an arc SNAPS across the air gap (one frame, hard flash, `heavyImpact`), and the line recoils. It cannot come near a street.
3. **The core discovery:** there is NO position on the route where one drop works — placements high burn, placements low arc. The route itself refuses single-shot. **Reaction:** a second transformer appears and two staged seats glow: the answer is *more drops, not a better spot*.
4. **Payoff:** substation seated (hard drop) → the mid-level feeder crosses the whole town cool AND passes the rooftop zone without arcing; pole seated (last drop) → one short street at house level, the socket ticks `230V AC`, the house lights warm and steady, the neighbours light off the same pole. The staging is then SEEN as a network — and named: the distribution grid.

## 4. Felt vs named vs numbered

- **Felt:** voltage level as physical presence — clearance height, insulator size, line tint (high = intense cool blue-violet with corona shimmer; mid = calm blue; house level = soft warm-neutral); loss as heat-orange glow + shimmer on the over-long run; danger as the arc snap at the rooftop boundary; success as the warm, steady house and the pulse riding the full descent; network-ness as the neighbours lighting off one pole and faint feeders branching off the substation.
- **Named (a beat after felt / objects on sight):** "substation" and "pole transformer" — visible objects, small mono specimen labels appear when each seat activates; the 2.6 callback ("the long-line transformer… the other way") lands when the first stage seats and its coil chip shows fewer turns out; "the **distribution grid**" is named ONLY after the full journey replay; "transmission grid" named beside it as counterpart. The bare word "the grid" is never used (EP4 owns it).
- **Numbered (live, ≤2 at a time):** chip 1 `LINE ×1000 HOUSE` (relative — house level = 1; pinned, constant, the held-constant given). Chip 2 `SOCKET —` → `SOCKET 230V AC` at success. The intermediate ×50 appears ONLY inside a meaning-line ("fifty times house level"), never as a third chip. 230V AC is the single absolute value, mandated verbatim by the curriculum beat ("the socket reads 230V AC"); all other numbers stay relative. **No ratings table; no number for any qualitative judgment** (heat, danger, dimness are felt only).

## 5. On-screen text (exact, beat by beat)

Two registers only: **imperatives** (Bricolage, Title Case, ≤5 words) and *meaning-lines* (Plus Jakarta Sans, de-personified facts). No mascot, no info-cards.

| # | Beat | Register | Line (verbatim) |
|---|---|---|---|
| 1 | intro | meaning | Power arrives at the town edge at a thousand times house voltage. |
| 2 | intro (secondary) | meaning | No socket can take the line as it arrives. |
| 3 | singleDrop | imperative | Place the Transformer |
| 4 | singleDrop, burn ignition | meaning | At house level, the long run across town turns the power to heat. |
| 5 | singleDrop, nudge if only burn seen | imperative | Now Try Near the House |
| 6 | singleDrop, arc snap | meaning | At a thousand times house level, current leaps the air — the line cannot come near a street. |
| 7 | singleDrop, nudge if only arc seen | imperative | Now Try the Town Edge |
| 8 | pivot | meaning | No single drop works anywhere on this route. |
| 9 | pivot (secondary) | meaning | It has to come down in stages. |
| 10 | placeSub | imperative | Place the First Drop |
| 11 | placeSub, on seat (callback) | meaning | The substation runs the long-line transformer the other way — fewer turns out, lower voltage out. |
| 12 | placeSub, feeder sweep done | meaning | Fifty times house level — low enough for the streets, high enough to cross town without burning. |
| 13 | placePole | imperative | Place the Last Drop |
| 14 | placePole, on seat | meaning | The pole transformer makes the last drop — one short street at house level, too short a run to burn. |
| 15 | placePole, socket ticks live | meaning | The socket reads 230 volts AC. |
| 16 | journey, after replay | meaning | Down in stages — a hard drop at the substation, a last drop at the pole. |
| 17 | naming | meaning | This staged network below the substation is the distribution grid. |
| 18 | naming (allowed-longer, persists) | meaning | The transmission grid carries power across the country. The distribution grid steps it down and hands it to every house — two stages of one system. |

No depth-stop in this beat: why-staged is FULLY explained by the two felt constraints (burn / arc). The transformer's inner why rests on 2.6's already-delivered induction depth-stop — referenced by line 11, never reopened, never re-explained. The strings "nobody", "no one knows" must not appear anywhere.
Card earn brag (overlay one-liner): `The staged descent that ends at your socket.`

## 6. Beat-by-beat flow (timing + gating)

Text swaps use the shipped 190 ms fade-out → swap → fade-in. Interaction is locked during auto phases. Play length target ≈ 90–130 s.

| Phase | What happens | Timing / gate |
|---|---|---|
| `intro` (auto) | Entrance reveals (horizon line + pylons 0→450 ms, town silhouettes +150 ms, route poles +300 ms, house +450 ms; slide+scale+fade). Corona shimmer on the arriving line starts immediately and never stops above the first drop. Line 1 at 400 ms; line 2 at 2600 ms. Transformer puck fades into its tray at 3000 ms. | auto-advance at 4600 ms |
| `singleDrop` | Line 3. Drag the puck; while dragging, a ghost preview splits the route at the nearest point t — above stays high-tint, below previews warm-neutral. Release commits (snap 320 ms). **t < kArcBoundary (0.35):** burn — heat ramps along the run below over 1100 ms, ignition frame at ~350 ms (`heavyImpact`), house flickers dim from 600 ms, line 4 at 1100 ms, held 3200 ms, puck auto-returns to tray over 450 ms. **t ≥ 0.35:** arc — the high line extends toward the drop over 600 ms and SNAPS at the rooftop boundary (1 frame, flash 260 ms envelope, `heavyImpact`), line 6 at snap+250 ms, line recoils 500 ms, held 3000 ms, puck returns. After a failure, if only one type seen: nudge imperative (line 5 or 7) at +400 ms. Re-tries unlimited; failures replayable. | gate: `burnSeen && arcSeen` → `pivot` |
| `pivot` (auto) | Scene calms; puck returns to tray; line 8 at 400 ms; line 9 at 2600 ms; a SECOND puck fades in beside the first at 2600 ms; seat 1 (substation yard) begins glowing at 3400 ms; mono label `SUBSTATION` fades in on the yard. | auto-advance at 4400 ms |
| `placeSub` | Line 10. Only seat 1 accepts (drops elsewhere glide back over 350 ms, no text; seat glow brightens after 2 rejects). On seat: snap 320 ms + `selectionClick`; coil chip reveals over 500 ms beside the device — many loops in, few loops out, drawn and countable; `onCapture('fewer_turns_out')` at the chip-reveal frame (+600 ms); line 11 at 600 ms. Then the feeder re-tints mid-blue in a 1400 ms sweep crossing the whole town — past the rooftop boundary, NO arc, NO heat (containment + efficiency, witnessed); line 12 at 3600 ms; seat 2 (street pole) begins glowing at 5400 ms; mono label `POLE TRANSFORMER` fades in. | auto-advance at 7400 ms → `placePole` |
| `placePole` | Line 13. Only seat 2 accepts. On seat: snap + `selectionClick`; the street segment re-tints warm-neutral over 600 ms; line 14 at 600 ms; at 3400 ms the SOCKET chip ticks `230V AC` in the same frame the house window lights warm (500 ms bloom) — `heavyImpact`; line 15 at 3400 ms; `onCapture('staged_descent')` at 4000 ms (house fully lit, both stages in frame). | auto-advance at 6000 ms → `journey` |
| `journey` (auto) | One bright pulse rides the whole route top→bottom over 2800 ms: high line → step-flash at the substation → cool feeder across town → step-flash at the pole → short street → socket; the two neighbour houses light off the same pole as it lands; faint secondary feeders branch off the substation, dim, in the background. Line 16 at 2900 ms. | auto-advance at 6100 ms |
| `naming` (auto) | Line 17 at 0 ms; the staged network (substation + feeder + poles + street) brightens ~15% as one object while the chrome dims. Line 18 at 2800 ms (smaller body size per shipped long-line pattern) and PERSISTS for the rest of the screen. | at 7000 ms → `showCardEarn = true` |
| `done` | Card overlay (`CollectibleEarnOverlay`, eyebrow `NEW CARD`, showMascot false). `onCardCollected` → `showContinue = true`. Continue → `Navigator.maybePop(context)`. | learner-gated |

Reversibility: `singleDrop` placements are freely reversible and re-triable; staged seats, once placed, stay (the route is solved). Auto phases are not skippable (the staging must be witnessed end to end).

## 7. Hero & layout

- **Hero:** the descending power line — alive the whole activity (corona at ×1000, heat when abused, the arc, the re-tinted staged descent, the journey pulse). The lit house joins it at the climax; together they are the brightest thing on screen.
- **Recedes:** near-black `#070A1C` base with radial vignette darkest along the route; town silhouettes flat ink `#0B1026`/`#161D3A`; sky quiet; chips dark glass `0x14FFFFFF`; labels mono, tiny.
- **Portrait, top-to-bottom = the journey in:** header → `EpisodeBoardStrip` (episode question) → top-text (fixed height ~96) → scene (Expanded): horizon pylons top, substation yard upper, town crossing middle, street pole lower, hero house bottom → fixed-height CTA seat (84).
- **Clutter caps:** one hero; ONE gesture (drag the puck[s]); 2 live numbers (`LINE` / `SOCKET` chips); current text line; board strip + back + Continue. Interactive elements ≤6 (actual: puck drag, two phase-scoped seats, back, Continue = 5). 16–22 ambient motes max. Heat-orange `#FF7A2E` appears ONLY during the burn failure; high voltage is never rendered warm.

## 8. Reward

**Card: yes** — the concept is a quick-reference table row ("Local last-mile delivery network | distribution grid | 3 | —") and context-pack §6 expects an EP3 distribution-grid card. Proposed copy (shared-infra agent assigns number/motif; section `homeSafety`, accent `#3FD99B`; build agent only references the constant, proposed `kLastMileCard`):

- **Front — playful name:** The Last Mile
- **Front — real term (mono specimen):** DISTRIBUTION GRID
- **Front — one-line law:** Stepping down is staged — a hard drop at the substation, a last drop at the pole, 230 volts at the socket.
- **Front — kicker:** No single drop can do it.
- **Back — tie to what was felt:** You tried one giant drop — it burned across town or arced at the street. Two staged drops reached the socket at 230 volts.
- **Back — outward reach:** The fenced, humming yard at the edge of town is a substation — the top step of every descent around you.
- **Linked card:** The Still Machine (2.6, transformer) — the recurring stage device; this card's law is the staging, so it does not restate the turns rule.

**Inline fact: none** (deliberate empty slot — the failure drama and the naming carry the close).

## 9. CER capture hook

`RepaintBoundary(key: _sceneKey)` around the scene; `controller.onCapture = _onCapture` → `captureScenePng(_sceneKey, cropFactor: evidenceByIdFor('episode3_electricity', id)?.cropFactor)` → `_board.capture(id, imageBytes: bytes)`; `lightImpact` in `_onCapture`.

| id | label (≤3 words) | caption (one line) | flag | fires |
|---|---|---|---|---|
| `staged_descent` | Staged Descent | Two staged drops brought a thousand-times line down to 230 volts at the socket. | **relevant** | `placePole` at 4000 ms — house fully lit, socket chip reading 230V AC, both stages in frame |
| `fewer_turns_out` | Fewer Turns Out | Each stage is the long-line transformer run in reverse — fewer turns out than in. | **distractor** (true-but-irrelevant: explains the stage device, not the safe way in) | `placeSub` at +600 ms — the coil-chip reveal frame on the seated substation |

Crop factors are owned by the EP3 evidence catalog; suggested: `staged_descent` crops the lower-centre band (street + house + socket chip with the pole stage in frame), `fewer_turns_out` crops the substation + coil chip region.

## 10. Build notes

- **Flame `GameWidget` + Flutter overlay** (trace_it_back / source_personalities are the templates): living scene of ~9 pure-render component layers; gesture stays in Flutter (transparent `Listener` above the GameWidget forwarding to the controller). GameWidget built once in `initState`.
- **No Forge2D.** All motion controlled. The drag has no momentum (release = commit or glide-back). The arc snap, the burn ignition frame, and the socket tick are hard gates in the controller's `tick` — never decay, never eased values.
- The arc render: a jagged violet-white bolt (`#B45CFF` core → white) from the high line's tip to the nearest rooftop/ground point, 1-frame snap, 260 ms decay envelope, plus a brief whole-scene shudder (±2 px, 120 ms, suppressed under reduced motion — the snap itself stays). **Register: serious and factual — no person, no body, no cartoon shock anywhere near the arc** (3.2 owns the body; this beat must not touch it).
- The high line above the first drop NEVER renders past `kArcBoundary` — clamp `highReach ≤ kArcBoundary` in the controller, assert in debug.
- Controller owns sim + geometry + phase machine (`setStageSize`, factor-based anchors per §16); `_schedule(ms, fn)` timers (cancel-on-dispose); `reducedMotion` from MediaQuery each build.
- `MediaQuery(...textScaler: TextScaler.noScaling)` wrap; reduced motion = calm corona/motes, fade entrances — but the arc snap, burn ignition, socket tick, and same-frame house bloom are pedagogical and stay hard.
- Haptics: `selectionClick` on each seat snap; `heavyImpact` at burn ignition, arc snap, and socket-live; `lightImpact` on capture; medium is inside the card overlay.
- Audio: silent by default (matches shipped EP activities). Optional single arc-crack SFX is an open decision (§13).
- Persistence: none beyond shared evidence/card stores. Write ONLY inside `lib/screens/missions/stepping_down/`; registry entry, EP3 evidence catalog ids, `kEpisode3Question`, and the card constant are owned by other phases — report needs in the final build message, never edit shared files. Verify with `fvm dart analyze lib/screens/missions/stepping_down`.

## 11. Acceptance criteria (pedagogy as testable checks)

1. **Discoverable from interaction alone:** with all text hidden, dragging the puck previews the split (high above / house-level below), and every single-drop placement produces a legible felt failure (orange burning run + dim house, OR arc snap + recoil); the staged solution produces a cool full route + lit house. The concept reads without reading.
2. **No safe single placement:** for every t in [0,1] the single drop fails — t < 0.35 burns (intensity ∝ remaining run length, floored at 0.55 so it always reads as failure), t ≥ 0.35 arcs. Test t = 0.05, 0.34, 0.35, 0.95.
3. **Both failures gated:** `pivot` is unreachable until `burnSeen && arcSeen` are both true; the cross-nudge imperative (line 5 or 7) appears only after the first failure type repeats or completes.
4. **Hard gates:** the arc snap reaches full flash in ≤1 frame (no fade-in); the high line never renders past the rooftop boundary; the socket chip tick and the house bloom start in the SAME frame; reduced motion softens none of these.
5. **Felt consequence in the scene, not a stat:** loss is wire glow + shimmer + the dim flickering house — no loss meter, no percentage, no warning popup, no red ✗.
6. **Held-constant visible:** the `LINE ×1000 HOUSE` chip is pinned and never changes; the line above the first drop keeps its corona the entire activity, including after both stages seat.
7. **≤2 live numbers** (`LINE` chip relative; `SOCKET 230V AC` at success only — the lone absolute, mandated by the beat); ×50 exists only inside line 12; no ratings table anywhere.
8. **Containment + efficiency witnessed:** after the substation seats, the mid feeder's 1400 ms sweep visibly crosses the rooftop boundary with NO arc and the full town with NO heat; after the pole seats, the short ×1 street run shows NO heat (the run-length contrast with failure 1 is visible).
9. **Name-after-felt:** "distribution grid" (line 17) appears only after the journey replay completes; the bare word "grid" never appears outside the exact phrases "distribution grid" / "transmission grid".
10. **Callback, not re-teach:** line 11 is the only transformer-mechanism text; the words "induction", "magnetic field", and any turns-ratio arithmetic are absent; the coil chip is drawn, not numbered.
11. **No body content:** no person, body figure, current-through-you wording, or harm-to-people imagery anywhere (3.2 owns it). The arc targets air/structures only.
12. **Captures fire exactly once** at the two specified frames with `lightImpact`; the board strip backfills thumbnails; the strip shows the episode question throughout.
13. Imperatives ≤5 words; meaning-lines match §5 verbatim; "nobody"/"no one knows" absent; no rhyme.
14. Card overlay fires only after line 18 has held ≥4200 ms; Continue appears only after `onCardCollected`; Continue pops via `Navigator.maybePop`; play length 90–130 s under normal interaction; portrait small-phone layout sane; `fvm dart analyze lib/screens/missions/stepping_down` clean.

## 12. Anti-patterns (this activity)

- A warning popup, red ✗, or "UNSAFE!" badge on failures — the burn and the arc ARE the teaching.
- Rendering high voltage as hot/warm/red — corona is cool blue-violet; heat-orange is reserved for the burn failure (loss), per EP2 iconography.
- Re-teaching the transformer (turns arithmetic, induction, field bloom) — 2.6 owns it; one callback line only.
- Teaching body harm or showing a person near the arc — 3.2's beat; pre-spoiling it here breaks the episode arc.
- Saying bare "the grid" — EP4 claims that word.
- Pre-spoiling staging: lines 8–9 ("stages") must not appear, even faintly, before both failures are felt; the second puck must not be visible during `singleDrop`.
- A free-form two-puck puzzle in the resolution — the concept-struggle already happened in `singleDrop`; staged placement is guided (glowing seats), so any later struggle would be about ergonomics, not the concept.
- A premium fade softening the arc snap, the burn ignition, or the socket tick.
- A third number chip (×50 mid-level) or numeric voltage labels along the route — the felt iconography (tint/clearance/insulators) carries levels; ×50 lives in line 12 only.
- A voltage slider on the transformers — the learner chooses WHERE and IN HOW MANY STAGES, never how much; windings are fixed per device.
- Editing `activityRegistry.dart`, evidence catalogs, `collectible_models.dart`, or wowConcepts from the build agent.

## 13. Open decisions

1. **Relative values:** ×1000 / ×50 / ×1 (rounded from real 220 kV / 11 kV / 230 V). Tunable in `SdTune`; must stay honest order-of-magnitude and keep line 12's "fifty times" literally matching the chip-free mid level.
2. **Neighbour houses + background feeders** at the climax (the network-ness cue): default IN; cut if on-device review finds the climax frame cluttered — line 17 still lands on the staged route alone.
3. **Arc SFX:** default silent; a single ≤0.2 vol crack at the arc snap is allowed if it survives taste review.
4. **Socket absolute number:** `SOCKET 230V AC` is curriculum-mandated; if covenant review insists on fully-relative, fall back to chip `SOCKET ×1 HOUSE` with line 15 unchanged (the named fact stays). Default: 230V AC on the chip.
5. **Distractor allocation:** `fewer_turns_out` is proposed as one of EP3's two distractors — final call by the EP3 CER PRD/catalog owner.
6. **Board-strip question string:** use the shared `kEpisode3Question` constant; final phrasing owned by the EP3 CER PRD.

## 14. State machine sketch

```dart
enum SdPhase { intro, singleDrop, pivot, placeSub, placePole, journey, naming, done }

class SteppingDownController extends ChangeNotifier {
  // ValueNotifiers (discrete UI channels)
  final phase        = ValueNotifier<SdPhase>(SdPhase.intro);
  final caption      = ValueNotifier<SdCaption?>(null);   // carries register flag (imperative/meaning)
  final secondary    = ValueNotifier<SdCaption?>(null);   // intro/pivot second lines
  final burnSeen     = ValueNotifier<bool>(false);
  final arcSeen      = ValueNotifier<bool>(false);
  final stage1Seated = ValueNotifier<bool>(false);
  final stage2Seated = ValueNotifier<bool>(false);
  final socketLive   = ValueNotifier<bool>(false);        // drives SOCKET chip 230V AC
  final showCardEarn = ValueNotifier<bool>(false);
  final showContinue = ValueNotifier<bool>(false);

  // Hot-path getters (read by Flame components; updated in tick())
  Offset? dragPos;        // puck under finger (null = in tray/seated)
  double  previewT;       // nearest route-t while dragging (ghost split preview)
  double  dropT;          // committed single-drop position, -1 = none
  double  highReach;      // how far the x1000 line extends, CLAMPED <= kArcBoundary
  double  heatLevel;      // 0..1 burn intensity on the house-level run (failure 1)
  double  arcFlash;       // 1-frame snap -> 260 ms decay envelope
  double  shudder;        // scene shake envelope (reduced motion: 0)
  double  coronaPhase;    // shimmer clock on the high line (never stops above stage 1)
  double  feederSweepT;   // 0..1 mid-level re-tint crossing the town (placeSub)
  double  streetTintT;    // 0..1 warm-neutral street re-tint (placePole)
  double  journeyT;       // 0..1 replay pulse along the full route
  double  houseGlow;      // hero house window bloom (snaps on with socketLive)
  double  neighborGlow;   // climax-only
  double  coilChipReveal; // fewer-turns-out chip on seated substation
  double  sceneDim;       // naming-phase chrome dim
  double  flashIntensity; // ignition / snap / socket flashes

  // Input: Flutter Listener forwards pointers. Down: grab puck if within radius.
  // Move: previewT = nearest t on route polyline. Up: commit (singleDrop: evaluate
  // burn/arc; placeSub/placePole: seat if within seat radius else glide back 350 ms).
  // No momentum anywhere.
  void onPointerDown/Move/Up(Offset local);

  // Timers: _schedule(ms, fn), cancel-on-dispose, per the SS6 table.
  // Gates: singleDrop->pivot on (burnSeen && arcSeen); placeSub gate = seat-1 hit;
  //        placePole gate = seat-2 hit; journey/naming timer-driven; input ignored
  //        outside singleDrop/placeSub/placePole.
  // Hooks: onCapture(String id); onIgnite/onArcSnap/onSocketLive (heavyImpact);
  //        onSeat (selectionClick).
  void tick(double dt); // clamps highReach, hard-gates arcFlash snap + socket tick
}
```

Timers (ms): intro 400/2600/3000 → 4600 · burn 350-ignite/1100-line/3200-hold/450-return · arc 600-extend/snap/+250-line/3000-hold · nudge +400 · pivot 400/2600/3400 → 4400 · placeSub seat-snap 320, chip 500, capture +600, lines 600/3600, seat-2 glow 5400 → 7400 · placePole lines 600/3400, socket+bloom 3400, capture 4000 → 6000 · journey 2800-pulse, line 2900 → 6100 · naming 0/2800 → card 7000.

## 15. File plan (`lib/screens/missions/stepping_down/`)

```
stepping_down_screen.dart              (~340) — shell: noScaling MediaQuery, RepaintBoundary(_sceneKey)
                                               [EnergyFieldBackground + GameWidget], Listener forward,
                                               header, EpisodeBoardStrip(kEpisode3Question), _FadeSwapCaption
                                               top-text (h≈96), CTA seat (h=84), capture wiring,
                                               CollectibleEarnOverlay, CaptureFlash
state/stepping_down_controller.dart    (~440) — SteppingDownController per §14 (route math, failure
                                               evaluation, phase machine, timers, gates)
config/stepping_down_tuning.dart       (~120) — SdTune: route polyline factors (§16), kArcBoundary 0.35,
                                               seat anchors + radii, burn floor 0.55, timings table,
                                               tint palette (high/mid/house/heat/arc), chip anchors
config/stepping_down_copy.dart         (~75)  — SdCaption enum + verbatim strings (§5) + register flags
game/stepping_down_game.dart           (~55)  — FlameGame: transparent bg, onGameResize→setStageSize,
                                               update→controller.tick, adds layers back→front
game/components/scene_components.dart  (~700) — AmbientMotes, SkyHorizon (pylons + arriving line +
                                               corona), TownSilhouettes (rooftop-boundary band),
                                               RouteLine (HERO: per-segment tint/heat/pulses/journey),
                                               SubstationYard (fence + seat + coil chip), StreetPole
                                               (seat 2), Houses (hero + neighbours, window bloom),
                                               ArcBolt (snap + decay), TransformerPucks (tray + drag
                                               ghost + seat snap), VoltageChips (LINE / SOCKET mono),
                                               FlashLayer
widgets/energy_field_background.dart   (~100) — copy-adapt of the static dark vignette variant
```

Shared imports only: episode_board (strip/capture/snapshot), collectibles (overlay + card const), careerTheme, google_fonts. No edits outside this directory.

## 16. Scene sketch (portrait, factors of stage size w×h)

```
y 0.02–0.10  HORIZON: last transmission pylons (x 0.55→0.82w) + line arriving from vanishing
             point (0.78w, 0.05h); corona shimmer; LINE chip anchored (0.22w, 0.07h)
y 0.10–0.24  TOWN EDGE: substation yard (fenced rect ~0.32w × 0.10h) centred (0.32w, 0.17h);
             SEAT 1 inside; mono label SUBSTATION below the fence (pivot onward); faint
             branch feeders exit the yard left/right (lit only at climax)
y 0.24–0.62  TOWN CROSSING: route polyline descends centre-right (x ≈ 0.55w), distribution
             poles every ~0.09h; ink building silhouettes flank both sides; ROOFTOP BOUNDARY
             at y 0.36 (= route t 0.35, kArcBoundary) — the arc's snap line
y 0.62–0.80  THE STREET: pole with SEAT 2 at (0.62w, 0.70h), mono label POLE TRANSFORMER;
             two neighbour houses flanking (0.26w / 0.84w, 0.76h)
y 0.80–0.97  HERO HOUSE: (0.46w, 0.88h), warm window + entry wire; SOCKET chip (0.72w, 0.86h);
             puck TRAY floats at (0.14w, 0.50h) as a glass holder (1 puck, then 2)
```

Route param t: 0 at the town-edge line entry (0.46w, 0.12h) → 1 at the house entry (0.46w, 0.84h); drops map to nearest t. The flow reads top (country, ×1000) → bottom (socket, ×1): the descent IS the layout. All anchors live in `SdTune`; no fixed pixels.

Puck tray occupancy by phase (anti-spoil): `intro`/`singleDrop` show exactly ONE puck in the tray; the SECOND puck fades in only at `pivot` (3400 ms) — never sooner, so the staged answer is not pre-revealed (see §6, §12). From `placeSub` onward, seated pucks leave the tray; the tray is empty by `journey`.
