# PRD — War of the Currents (EP2 beat 2.8)
### howwow · Episode 2 "The Long Way Home" · registry id `war_of_currents` · `WarOfCurrentsScreen` · `lib/screens/missions/war_of_currents/` · evidence episode `episode2_electricity`

Binding context: `docs/electricity/context_pack.md`, `docs/electricity/architecture_reference.md`, curriculum §1–§9 + beat 2.8. This PRD is self-contained: every on-screen line is quoted verbatim here.

**Chain inheritance (what the learner already felt):** 2.5 — for fixed power, higher voltage → lower current → far lower loss (the trick). 2.6 — a transformer steps voltage up/down with its turns, no moving parts, and needs a CHANGING current. 2.7 — DC is steady one-way, AC reverses many times a second; the transformer works only on AC. The terms DC and AC are established and may be used on sight.
**What this beat pins (held constant, visible):** the plant, the route, the distance, the power to send, and the era (the 1880s — no modern electronics). The ONLY variable is the kind of current. The pin is named on screen (line C2), the map/route/plant render identically across both runs, and the era rides the scene as a tiny mono tag (`THE 1880s`) for the whole contest.

---

## 1. One-concept statement
**Only AC could be cheaply transformed up to the voltages that kill transmission loss — so the grid runs on AC.**

## 2. Guiding-question link + CER contribution
Episode 2 question (pinned on the board strip all activity, via the shared `kEpisode2Question`): *"The plant is far away — how do we send power across that distance without losing it all on the way?"*
This beat supplies the episode claim's enabler half made witnessable end-to-end: high voltage is the trick (2.5), the transformer makes high voltage possible (2.6), and ONLY AC works the transformer (2.7) — here the learner watches the whole chain succeed and watches its absence fail.
- `dc_line_cooks` — **relevant** (the witnessed counterfactual: with no way to raise the voltage, the current is enormous and the power leaves as heat before the city).
- `ac_sails_across` — **relevant** (the full solution: stepped up, trickle current, cold line, lit city).
No distractor is proposed from this beat by default; the EP2 CER owner selects the episode's exactly-2 distractors (candidates already proposed by 2.1 and 2.6). If the CER owner wants a 2.8 candidate, see §13.3.

## 3. The felt discovery (discovery → reaction)
**Discovery:** the learner chooses a current — taps `DC` or `AC` — and sends the same power, down the same line, to the same far city, with 1880s technology. Both runs launch identically (low voltage, big current, same plant bloom); the divergence happens AT the transformer, in front of the learner.
**Reaction (DC):** the feed enters the transformer and the core stays dark — the dead-transformer moment from 2.7, now with consequences. The voltage stays low, so the current onto the long line is enormous: fat slow pulses, the wire glowing hotter and hotter from the plant end, the pulses visibly thinning as their energy leaves into the wire — until the line flares and the advance gutters out short of the city. The city's faint flicker dies in that same frame. Felt failure, witnessed.
**Reaction (AC):** the feed enters the same transformer and the core blooms alive; VOLTAGE rolls 10→200 while CURRENT falls 100→5 in sync. A handful of thin, fast, cool pulses sail the entire route over a cold wire; the city lights window by window to full bloom.
Only after BOTH runs is the contest named: this literally happened — Edison's DC against Tesla/Westinghouse's AC — the **War of the Currents**, and AC won because only AC could be transformed up.

## 4. Felt vs named vs numbered
- **Felt:** the transformer dead (no bloom, ever, on DC) vs alive (breathing amber field on AC); wire heat ∝ I² (saturated orange glow + shimmer + rising heat motes on DC; zero glow on AC); pulses thinning and guttering out (energy leaving as heat) vs sailing the whole route; the city's flicker dying hard vs the window-sweep ignition; the charger brick's faint warmth in the bridge vignette. No meter for any of these — the line and the city ARE the readouts.
- **Named (a beat after felt):** the era constraint ("in the 1880s there was no other way to raise a voltage", D2 — after the dead core is seen); the failure's destination ("it left as heat along the line", D4 — after the cook is seen); **"The War of the Currents"** with Edison/Tesla/Westinghouse (S1/S2 — strictly after both runs); the household correction (B1–B4 — each line lands as its vignette element lights). DC/AC themselves were named in 2.7 and are used on sight.
- **Numbered (live, relative, exactly 2):** `VOLTAGE` and `CURRENT` mono chips at the line's sending end, visible only during runs. Both runs launch at `VOLTAGE 10 / CURRENT 100`; AC rolls to `200 / 5` at the transformer (same product-1000 scheme as 2.5 — deliberate continuity). **No ratings table; no "% delivered"; no winner score; no number for heat, brightness, or distance.**
- **Depth-stops: none.** Everything here is fully explainable from 2.5–2.7; the honest refinement (modern HVDC) is the one inline fact (§8).

## 5. On-screen text (exact, beat by beat)
Imperatives: Bricolage Grotesque ~28 w800, Title Case, ≤5 words. Meaning-lines: Plus Jakarta Sans ~18 (long lines render smaller), de-personified facts. Swap = 190 ms fade-out → swap → fade-in. No mascot, no info-cards.

| id | beat | register | text (verbatim) |
|---|---|---|---|
| C1 | intro | meaning | The 1880s. A city, far away — and a plant that must send it full power. |
| C2 | intro (the pin) | meaning | Same plant, same line, same power to send. The only choice is the kind of current. |
| I1 | choose | imperative | Choose a Current |
| D1 | DC run, dead transformer | meaning | A steady current — the field never changes. The transformer stays dead and the voltage stays low. |
| D2 | DC run, era constraint | meaning | In the 1880s there was no other way to raise a voltage. |
| D3 | DC run, post-flare | meaning | Low voltage means enormous current — and the wire takes the power as heat. |
| D4 | DC fail, aftermath | meaning | The power didn't vanish — it left as heat along the line. Almost none of it reached the city. |
| A1 | AC run, alive transformer | meaning | A reversing current — the field keeps changing. The transformer comes alive and steps the voltage up. |
| A2 | AC run, journey | meaning | High voltage, a trickle of current — the line stays cold. |
| A3 | AC arrival | meaning | Nearly all the power arrives — the city lights to full. |
| I2 | interlude (one run left) | imperative | Now Send the Other |
| S1 | war | meaning | This exact contest was fought in the 1880s. Edison's companies sold DC — Tesla and Westinghouse backed AC. |
| S2 | war (named) | meaning | The War of the Currents. AC won, because only AC could be cheaply stepped up to the voltages that kill the loss. |
| S3 | war (the landing) | meaning | That is why the grid runs on AC. |
| F1 | inline fact (tap-reveal, skippable) | fact | Today's longest links run on high-voltage DC — modern electronics can now step DC up and down. Into a home, AC is still the right picture. |
| B1 | bridge | meaning | Past the city, transformers step the voltage down, stage by stage, to the wall socket — still AC. |
| B2 | bridge | meaning | Kettles, heaters, and fan motors run on that AC directly. |
| B3 | bridge | meaning | Phones, laptops, and LED bulbs need steady DC — so the charger brick converts AC to DC, paying a little heat to do it. |
| B4 | bridge (final, persists) | meaning | High-voltage AC across the country. Stepped-down AC into the house. DC made inside your gadgets. |

Chrome strings: dock chips `DC` (flat-line glyph, mono sub-label `STEADY`) and `AC` (sine glyph, mono sub-label `REVERSING`) — glyphs recall 2.7's graph, neutral colors, no outcome hint. Fact chip (mono, appears with S3): `140 YEARS LATER`. Era tag (mono 9, letter-spaced, on the map): `THE 1880s`. Number chips: `VOLTAGE <n>` / `CURRENT <n>`. CTA: `Continue`. No other text exists.
D1/A1 are deliberate mirrors; D3 and D4 name destinations (heat, the line), never behaviours/endings; no rhyme anywhere.

## 6. Beat-by-beat flow (timing + gating)
Either run may be chosen first; copy and behavior are order-agnostic. Play length ≈ 65–110 s.

| Phase | What happens | Timing / gate |
|---|---|---|
| `intro` (auto) | Entrance reveals (map terrain 0→450 ms, route draw 300→900 ms, plant+transformer +450 ms, city +600 ms; slide+scale+fade). Era tag fades in with the map. C1 at 900 ms (hold 3000); C2 at 3900 (hold 3400). | auto → `choose` at 7300 ms |
| `choose` | I1. Dock slides up (300 ms); both chips pulse gently (scale 1.0→1.08 loop). | WAIT for tap. `selectionClick` on tap → `sending` with `activeRun` set; dock locks |
| `sending` — common launch | +300 ms after tap: plant bloom pulse (identical both runs), VOLTAGE/CURRENT chips fade in reading `10 / 100`, warm-gold pulses travel the short plant→transformer feed (900 ms). At 1200 ms: vignette tightens slightly on the transformer (600 ms). | scripted, input locked |
| `sending` — DC branch | Core NEVER blooms (hard absence — no glow at any frame). D1 at 1400 ms (hold 3400); D2 at 4800 (hold 2800). At 2600 ms the journey starts: fat slow warm pulses onto the long route; wire heat grows from the plant end (∝ I², saturated); pulses thin with distance; reach-front advances to ≈ 0.62 of the route by 7400 ms and stalls. **7400 ms: THE FAILURE (hard gate)** — line flare peak (white-hot bloom ~700 ms envelope), `heavyImpact`, the city's faint flicker forced to 0 in the SAME frame (no fade tail; reduced motion changes nothing). `onCapture('dc_line_cooks')` at 7800 ms (post-flare: red line + dark city in frame). D3 at 7600 (hold 3000); D4 at 10800 (hold 3400). | auto → at 14200 ms: `interlude` if AC not yet run, else `war` |
| `sending` — AC branch | At 1200 ms the core blooms alive (700 ms, breathing amber field); VOLTAGE rolls 10→200 and CURRENT 100→5 over 600 ms, in sync with the bloom; A1 at 1400 ms (hold 3400). At 2600 ms: 3–4 thin fast cool-blue pulses sail the full route (~2600 ms), wire shows zero heat. A2 at 5000 (hold 3000). **5200 ms: ARRIVAL** — city window sweep 900 ms + warm bloom (the orchestrated payoff). `onCapture('ac_sails_across')` at 6300 ms (full-lit frame). A3 at 6400 (hold 3200). | auto → at 9800 ms: `interlude` if DC not yet run, else `war` |
| `interlude` | Scene resets to baseline over 800 ms (wire cools / city dims to start state — visible reset so run 2 starts identical); number chips fade out; run chip dims with a small neutral dot (no ✓/✗); the remaining chip pulses. I2. | WAIT for tap → `sending` (other run) |
| `war` (auto) | Dock fades out (300 ms). If DC ran last, crossfade the scene to the AC end-state over 700 ms (cold line, lit city — the world where AC won). S1 at 0 ms (hold 3800); S2 at 3800 (hold 4200); S3 at 8000 (hold 3000). Fact chip `140 YEARS LATER` appears with S3 and persists until `done`; tapping it expands F1 in a small glass panel (collapse on second tap or after 6000 ms); it never gates anything. | auto → `bridge` at 11600 ms |
| `bridge` (auto) | Map dims to 25 %; bridge vignette rises center-stage (700 ms): city edge → two small step-down cores → house with socket → inside, a kettle and a phone+charger brick. B1 at 0 ms (hold 3600) as the step-down chain's pulses animate; B2 at 3600 (hold 3000) as the kettle glows warm directly off the socket; B3 at 6600 (hold 4200) as the brick gains a faint warm glow and the phone screen lights cool-white; B4 at 10800 and PERSISTS. | auto → `done` at 13200 ms |
| `done` | Gold Continue CTA in its fixed-height seat (no card — §8). | learner-gated → `Navigator.maybePop(context)` |

Gating summary: `war` requires BOTH runs witnessed (`ranDc && ranAc`); runs are scripted and not skippable; captures and the failure latch fire exactly once; phases never regress. Reversibility: the only free choice is run order; no re-runs (default — §13.1).

## 7. Hero & layout (portrait) + clutter caps
- **Hero: the long line across the map** — the route from plant to city. It is the brightest, most-alive thing in every run: cooking orange-red on DC, sailing cool-blue pulses on AC. The city is its payoff readout (dark/flicker vs full bloom); the transformer is the supporting pivot (small — 2.6 owns its glory), the plant is small, dim, and never changes.
- **Recedes:** near-black `#070A1C` map with faint terrain ridges + a river (≤5 % alpha), radial vignette darkest along the route; chips dark glass (`0x14FFFFFF` fills, `0x26FFFFFF` borders); 16–22 ambient motes.
- **Palette discipline:** low-voltage pulses warm gold `#FFD27A`; stepped-up high-voltage pulses cool transmission-blue `#3FB9F5`; heat orange `#FF7A2E` lives ONLY on the wire's glow; city bloom warm `#FFE9B8`.
- **Portrait, top-to-bottom:** header (title "War of the Currents", mono eyebrow `EPISODE 2 · TRANSMISSION`) → `EpisodeBoardStrip` (EP2 question) → top-text seat (fixed h ≈ 96) → stage (Expanded; §16) → choice dock (fixed h ≈ 72) → CTA seat (fixed h = 84).
- **Clutter caps:** one hero; interactive elements = DC chip, AC chip, fact chip, back, Continue (5 ≤ 6); exactly 2 live numbers; one current text line; era tag + board strip are read-only chrome. Nothing else.

## 8. Reward
**No card.** "Why the grid is AC" is not a row in the curriculum's quick-reference table — the `DC / AC` row is 2.7's (the `ac_vs_dc` activity owns that card), and this beat is the application/synthesis whose payoff feeds the EP2 CER, which earns the episode-synthesis card. A card here would have no law of its own to name without restating 2.7's or 2.5's.
**Inline fact: exactly 1 (mandated)** — the honest refinement, F1 (§5), behind the `140 YEARS LATER` chip at `war`. Glanceable, tap-to-reveal, skippable, never a gate, never restates the lesson (it complicates it honestly: "AC always wins" is a simplification; into a home, AC is the right picture).
The activity's reward is the witnessed win + B4's end-to-end line; completion is the Continue CTA (no `CollectibleEarnOverlay` anywhere on this screen).

## 9. CER capture hook
`RepaintBoundary(key: _sceneKey)` wraps background + GameWidget (text/dock/CTA outside). `controller.onCapture = _onCapture` → `HapticFeedback.lightImpact()` → `captureScenePng(_sceneKey, cropFactor: evidenceByIdFor('episode2_electricity', id)?.cropFactor)` → `_board.capture(id, imageBytes: bytes)`. `EpisodeBoardStrip` pinned under the header. Captures idempotent, never block flow.

| id | label (≤3 words) | caption (one line) | flag | fires |
|---|---|---|---|---|
| `dc_line_cooks` | The Line Cooks | With no way to raise DC voltage, the enormous current cooked the line — the power left as heat before the city. | **relevant** | DC failure +400 ms (7800 ms into the DC run): red-hot line, flare afterglow, dark city in frame |
| `ac_sails_across` | AC Sails Across | Stepped up by the transformer, the current fell to a trickle — the line ran cold and the far city lit to full. | **relevant** | AC arrival +1100 ms (6300 ms into the AC run): cold line, full-lit city, `VOLTAGE 200 / CURRENT 5` chips in frame |

Suggested cropFactors (EP2 catalog owner finalizes): `dc_line_cooks` ≈ `Rect.fromLTRB(0.04, 0.04, 0.96, 0.80)` (route + dark city); `ac_sails_across` ≈ `Rect.fromLTRB(0.04, 0.02, 0.96, 0.78)` (route + lit city + chips). Fallback motifs: a red-hot polyline dying short of a dark cluster / a thin cool line reaching a lit cluster.

## 10. Build notes
- **Flame `GameWidget` + Flutter overlay** (trace_it_back template): living map scene (terrain, route pulses, heat shimmer/motes, window grid, bridge vignette) as ~7 pure-render component layers; chrome (dock chips, fact panel, captions, CTA) in Flutter. GameWidget built once in `initState`; transparent `backgroundColor`; `onGameResize → controller.setStageSize`; `update(dt)` guards `dt > 0 && dt < 0.1` → `controller.tick(dt)`.
- **No Forge2D.** All motion is scripted/controlled in the controller's tick. The DC failure is a **hard gate**: the frame the failure latch fires, city flicker, pulse alphas past the reach-front, and advance speed are forced — never decayed.
- Input is taps only: dock chips are Flutter (`PressableScale` + `selectionClick`); no gesture forwarding needed over the scene (no Listener layer required — keep the RepaintBoundary wrap identical to shipped anyway).
- Sim (config-tuned in `WocTune`): pinned product `V×I = 1000`; DC: V 10, I 100, `wireHeat(s) ∝ (I/100)² × falloff(s − reachFront)`; pulse thickness/alpha decay along distance ∝ energy remaining; AC: V 200, I 5, wireHeat ≡ 0. Both runs launch with identical plant bloom + feed pulses (the visible held-constant).
- Haptics: `selectionClick` chip taps + fact chip; `heavyImpact` at the DC failure frame only; `lightImpact` per capture; no card haptic (no card).
- Audio: silent (matches shipped EP2 activities).
- Reduced motion (`MediaQuery.disableAnimations`): calm motes, entrance reveals become fades, flare becomes a brief glow step — but the same-frame city-dark gate, the V/I roll sync, and the dead-core absence are pedagogical and stay exact. Wrap screen in `MediaQuery(...textScaler: TextScaler.noScaling)`.
- File surface: write ONLY inside `lib/screens/missions/war_of_currents/`. Registry entry, EP2 evidence catalog, CER config, wowConcepts are other phases' files — if a shared change seems needed, STOP and report. Verify `fvm dart analyze lib/screens/missions/war_of_currents` clean.

## 11. Acceptance criteria (pedagogy as testable checks)
1. **Discoverable from interaction alone:** with all top-text suppressed (debug flag), tapping DC then AC (or the reverse) yields the full contrast — dead core / hot dying line / dark city vs live core / cold line / lit city — with zero reading required.
2. **Identical launch:** both runs render the same plant bloom, the same feed pulses, and the same `VOLTAGE 10 / CURRENT 100` chips for the first 1200 ms; the first divergent frame is at the transformer.
3. **Held constants visible:** map, route, plant, and city geometry are bit-identical across both runs (same component state at run start, verified after the interlude reset); the `THE 1880s` tag is visible from intro through both runs; C2 names the pin before any choice.
4. **The dead core is absolute:** during the entire DC run the transformer core emits zero bloom in every frame; on AC the bloom and the V/I roll complete within the same 700 ms window, in sync.
5. **The failure is a hard gate:** at the DC failure frame, the city's flicker is 0 in that same frame (no fade tail), the flare + `heavyImpact` fire once, and reduced-motion does not soften the cutoff.
6. **Heat reads as I²:** DC wire glow/shimmer/motes are saturated; AC wire shows zero glow at all times; heat color `#FF7A2E` appears only on the wire, never on pulses or chips.
7. **Order-agnostic:** either chip may be tapped first; D/A lines, captures, and gates behave identically in both orders; `war` is unreachable until both `ranDc && ranAc`.
8. **Name-last:** the strings "War of the Currents", "Edison", "Tesla", "Westinghouse" appear nowhere (text or texture) before S1/S2; no chip, color, or icon hints an outcome before it is run (no red/green chips, no winner badge ever).
9. **Exactly 2 live numbers** (VOLTAGE, CURRENT), relative, product pinned at 1000 at every displayed state; no third number, no "% delivered", no ratings table, no score.
10. **The inline fact is optional and single:** flow timing is identical whether F1 is opened or not; F1 appears only via the `140 YEARS LATER` chip; it is the only fact; its text is verbatim §5.
11. **The bridge lands element-by-element:** B1–B3 each land within 200 ms of their vignette element activating (step-down pulses / kettle glow / brick warmth + screen); B4 persists behind the Continue CTA; the kettle lights directly off the socket while the phone lights only after the brick.
12. **Catch lines name destinations:** D3/D4 say the power left AS HEAT along the line (never "the power ran out/stopped"); B3 names the brick's warmth as the conversion's cost. No rhyme anywhere in the copy file.
13. **Captures fire exactly once** at their specified frames with `lightImpact` + capture flash, and tiles backfill on the board strip.
14. **No card:** no `CollectibleEarnOverlay` import/usage; Continue appears only in `done` (B4 held ≥ 2400 ms) and pops via `Navigator.maybePop`.
15. `fvm dart analyze lib/screens/missions/war_of_currents` is clean; small-phone portrait (≈360×640 logical) shows city, route, station, dock, and text without shrinking the route below legibility; reduced-motion path works.

## 12. Anti-patterns (this activity)
- A winner badge, scoreboard, ✓/✗ on the chips, or "% delivered" meter — the city and the line are the only readouts.
- Pre-spoiling: any pre-run hint that DC will fail (red-tinted DC chip, warning copy, a demo run, naming the war early).
- Softening the failure: a premium fade on the city going dark, or pulses gently dissolving instead of guttering at the reach-front.
- The wire visibly breaking/melting through — that would teach "the circuit opened" (a different lesson); the line cooks and stays whole, glowing.
- Editorializing the history (Edison as villain, exclamation marks) — S1/S2 are stated facts.
- Re-deriving 2.4/2.5 math — D3 and A2 recall in one line each; no rectangle, no curve, no formula here.
- Making the transformer the hero again — it is small; 2.6 owns its close-up. The line/journey is the hero.
- A third number (distance, years, Hz, heat) or absolute units anywhere.
- "AC always wins" as an unqualified claim — S2 is historical ("could be cheaply stepped up"), and F1 carries the modern refinement; do not drop F1.
- Skipping or text-only-ing the bridge — each B-line must land on a lit vignette element.
- Editing `activityRegistry.dart`, evidence catalogs, CER configs, or collectible files from the build agent.

## 13. Open decisions
1. **Replays:** default is no re-runs after both runs complete (flow advances to `war`). If on-device QA wants free replay, allow chip re-taps during a post-`done` idle state only — flag for review.
2. **Relative number scheme:** proposed 10/100 → 200/5 (product 1000, continuity with 2.5). Tunable in `WocTune`; keep the product exact at both displayed states.
3. **Optional distractor candidate:** if the EP2 CER owner needs a distractor from this beat, `edison_vs_tesla` (synthesis frame; caption "Edison's companies sold DC — Tesla and Westinghouse backed AC."; TRUE but answers *who fought whom*, not *how distance loss is beaten*). Default proposal remains the two relevant tiles only.
4. **Reach-front stall point** (default 0.62 of route) and flare position (default 0.45) — tune so the failure reads "died on the way", not "arrived weakly".
5. **Bridge vignette density:** default kettle + phone/brick (two devices). A fan glyph may join B2's beat if it survives the clutter test on small phones.
6. **Era tag placement/size** (default map top-left, mono 9) — may move to the eyebrow line if it fights the city on small screens.
7. **Final cropFactors + motif art** for both tiles — EP2 evidence-catalog owner.

## 14. State machine sketch
```dart
enum WocPhase { intro, choose, sending, interlude, war, bridge, done }
enum WocRun { dc, ac }
enum WocCaption { none, c1Era, c2Pin, i1Choose, d1Dead, d2NoOtherWay, d3HeatTax, d4Aftermath,
                  a1Alive, a2Trickle, a3Arrives, i2Other, s1Contest, s2WarNamed, s3Landing,
                  b1StepDown, b2AcDirect, b3ChargerBrick, b4EndToEnd }   // copy table flags imperative vs meaning

class WocController extends ChangeNotifier {
  // ValueNotifiers (discrete UI channels)
  final phase        = ValueNotifier<WocPhase>(WocPhase.intro);
  final caption      = ValueNotifier<WocCaption>(WocCaption.none);
  final activeRun    = ValueNotifier<WocRun?>(null);
  final ranDc        = ValueNotifier<bool>(false);
  final ranAc        = ValueNotifier<bool>(false);
  final showFactChip = ValueNotifier<bool>(false);
  final factOpen     = ValueNotifier<bool>(false);
  final showContinue = ValueNotifier<bool>(false);

  // Hot-path getters (read by Flame layers; advanced in tick())
  double mapReveal, routeReveal, stationReveal, cityReveal; // entrance 0..1
  double launchBloom;        // plant pulse, identical both runs
  double feedPulseT;         // plant→transformer segment 0..1
  double coreBloom;          // transformer field; HARD 0 for the entire DC run
  double dispVoltage, dispCurrent;   // 10/100 → (AC only) 200/5, rolled over 600 ms
  double reachFront;         // 0..1 along route; DC stalls at kStallS, AC reaches 1.0
  double wireHeat(double s); // per-arclength heat 0..1 (DC: (I/100)² falloff behind front; AC: 0)
  double pulseThickness, pulseSpeed, pulseCount;  // DC fat/slow/many · AC thin/fast/few
  double flareIntensity;     // 700 ms envelope at the failure frame
  double cityLit;            // 0 / feeble flicker (DC pre-fail) / sweep→1.0 (AC); HARD 0 at fail frame
  double sceneDim, bridgeReveal, kettleGlow, brickWarm, phoneScreen, stepDownPulseT;
  bool   reducedMotion;      // set from MediaQuery each build

  void chooseRun(WocRun r);  // ignored unless phase == choose/interlude and run not yet done;
                             // selectionClick → phase = sending, schedules the run script (§6 ms table)
  void toggleFact();         // war/bridge/done only; never gates
  void tick(double dt);      // advances reveals/pulses/front; enforces hard gates every frame
  // Timers: _schedule(ms, fn), cancelled on dispose. Gates: war ⇐ ranDc && ranAc (on run-end check);
  // failure latch once per DC run; captures once; done ⇐ bridge timer; Continue → Navigator.maybePop.
  // Hooks: onCapture(String id) (lightImpact + PNG in shell), onFailure (heavyImpact), onChipTap (selectionClick).
}
```
Timers (ms): intro 900/3900/7300 · run-common 300/1200 · DC 1400/2600/4800/7400 (failure)/7600/7800 (capture)/10800/14200 · AC 1400/2600/5000/5200 (arrival)/6300 (capture)/6400/9800 · interlude reset 800 · war 0/3800/8000/11600 · bridge 0/3600/6600/10800/13200 · text swap 190 · fact auto-collapse 6000.

## 15. File plan (`lib/screens/missions/war_of_currents/`)
```
war_of_currents_screen.dart           (~340) — shell: noScaling MediaQuery, RepaintBoundary(_sceneKey)
                                              [EnergyFieldBackground + GameWidget], header, EpisodeBoardStrip
                                              (kEpisode2Question), _FadeSwapCaption top-text (h≈96), choice
                                              dock seat (h≈72), fixed CTA seat (h=84), capture wiring
                                              (EpisodeBoardCapture('episode2_electricity')), CaptureFlash;
                                              NO CollectibleEarnOverlay
state/woc_controller.dart             (~430) — WocController per §14 (run scripts, hard gates, geometry)
config/woc_tuning.dart                (~120) — WocTune: anchor factors (§16), V/I scheme, stall/flare s-values,
                                              heat falloff, pulse params per run, all timer ms, palette, mote cap
config/woc_copy.dart                  (~70)  — WocCaption enum + verbatim strings (§5) + register flags + holds
game/woc_game.dart                    (~55)  — FlameGame: transparent bg, onGameResize→setStageSize,
                                              update→controller.tick, adds layers back→front
game/components/map_layer.dart        (~140) — terrain ridges + river (≤5% alpha), era tag, ambient motes
game/components/route_layer.dart      (~260) — THE HERO: polyline route, traveling pulses (count/thickness/
                                              speed/color per run), per-segment heat glow + shimmer + heat
                                              motes, reach-front gutter, flare envelope
game/components/station_layer.dart    (~170) — plant silhouette + launch bloom, small transformer core +
                                              field bloom (hard-zero on DC), VOLTAGE/CURRENT mono chips
game/components/city_layer.dart       (~150) — window grid (feeble flicker / hard-dark / 900 ms sweep), bloom
game/components/bridge_layer.dart     (~180) — step-down chain, house + socket, kettle glow, phone + brick
                                              (brickWarm faint #FF7A2E at low alpha), reveal choreography
widgets/choice_dock.dart              (~120) — DC/AC chips (PressableScale, waveform glyphs, pulse hint,
                                              neutral run-dot, dim when done) + fact chip + F1 glass panel
widgets/energy_field_background.dart  (~100) — copy-adapt static dark vignette variant
```
Shared imports only: episode_board (strip/capture/snapshot), careerTheme/careerCommon, google_fonts. No collectibles import. No edits outside this directory.

## 16. Scene sketch (portrait, factors of stage size w × h)
```
y 0.03–0.07  ERA TAG: mono 'THE 1880s' at (0.08w, 0.05h), 9px letter-spaced, 60% alpha
y 0.06–0.24  CITY (payoff readout): cluster x 0.58–0.94w, bases y 0.24h, heights to 0.07h;
             window grid + warm bloom; feeble-flicker target during DC, sweep target on AC
y 0.20–0.72  ROUTE (hero): polyline city-feed (0.76w, 0.24h) → bend (0.30w, 0.40h) →
             bend (0.64w, 0.56h) → transformer (0.30w, 0.70h); terrain ridges + river faint
             beneath; heat glow hugs the route ∝ wireHeat(s); flare anchor at s≈0.45;
             DC reach-front stalls at s≈0.62 (measured from the transformer end)
y 0.70–0.86  STATION: transformer core (small ring, 0.30w, 0.70h) with amber field bloom;
             plant silhouette x 0.08–0.26w, base y 0.86h, launch bloom at its terminal;
             feed segment plant → transformer; VOLTAGE chip (0.54w, 0.68h) and CURRENT chip
             (0.54w, 0.74h) riding the route's send end (inside the RepaintBoundary,
             so captures include them)
y 0.86–1.00  FOREGROUND: ink ground band; 16–22 ambient motes across the scene
BRIDGE VIGNETTE (phase bridge; map dimmed to 25%): panel-less drawn scene centered
             x 0.16–0.84w, y 0.30–0.78h — city edge top → two small step-down cores →
             house + socket → kettle (left, direct warm glow) · phone + brick (right,
             brick faintly warm, screen cool-white)
DOCK (Flutter, below stage, h≈72): [ DC · STEADY ]  [ AC · REVERSING ] centered;
             fact chip '140 YEARS LATER' docks left of center during war/bridge/done
```
Journey reads bottom-left (plant) → top-right (city), vertically staged for portrait, consistent with 2.6's horizon direction. All anchors live in `WocTune`; no fixed pixels.
