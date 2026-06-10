# Example — The Leaky Bucket (electricity beat 1.3, "energy loss")

> **FINAL = the consolidated PRD: a tight "build-and-watch-it-leak" DEMONSTRATION, not a game.** The kid **snap-builds** the plant (all 4 machines in a tray, each drag SNAPS to its own correct slot — *no wrong order possible, no fail-state, no puzzle*: `placeMachine(kind)` → its home index), then taps **Power It Up** → a `flowProgress` sweep wakes the machines IN SEQUENCE, each leaking heat as the flow reaches it (a `machineAlive(i)`/`leakReveal(i)` gate ramps each from cold→alive), the stream thinning stage by stage → dim bulb (~38). Then engine-timed **meaning-lines** in the instruction banner (`So Much Fuel, So Little Light → The 'Lost' Energy Became Heat → Every Step Leaks Some, You Can't Catch It All`) → Card 04 → a transmission hand-off line. The earlier assemble-as-you-leak + drag-to-plug + flick + hydro-beat-4 (below) were all **cut** in this consolidation ("the *order* isn't the lesson, the *leaking* is; fixing teaches efficiency-engineering, the wrong angle"). Two reusable wins: **no-fail snap-build** (drop anywhere → snaps home; assembly is fun, not a permutation test) and **power-up sweep reveal** (the lesson is *felt to accumulate* as the chain wakes top→bottom, not dumped in one end-flow).

**Mechanic (an earlier rework, since superseded):** *assemble-the-machine + drag-to-plug*
— the kid **drags conversion stages** (burn → boil → spin → wire → bulb) onto the
chain; each placed stage leaks heat the instant it connects and the surviving
stream **thins as they build** (the loss is discovered by building, not read off a
diagram), ending in a dim bulb (~38 of 100). Then they **drag a cover over each
leak gap** — it shrinks live (stream fattens, output rises, bulb brightens) but
**never fully seals** (eff capped <1 — the bound felt in the finger). Optional:
rebuild a **short hydro chain** (no burn/boil) for a brighter bulb. *(V1 was
send-and-watch + a per-step ratchet "Improve"; the rework made both beats hands-on
direct-manipulation because the ratchet read as a dead control.)*

**Tech chosen:** **Flame scene + Flutter overlay**, **controller-owns-geometry**.
Both drags are **Flutter overlay** (a tray `Draggable` + a `DragTarget` over the
scene for assembly; a per-leak cover `GestureDetector` puck for plugging) — easier
to label + robust on mobile than in-scene Flame gestures. No Forge2D (the stream
widths/leaks are a **value-mapping**, not physics). No art assets.

**No mascot, no dialogue.** Voltix and all narration were removed from the
electricity activities (the shared `bot_beat_engine`/`voltix_helper` were deleted
upstream). The teaching is carried by the visuals + numbers; a single **large-font
instruction banner** ("Build the Machine" → "Drag a Part In" → "Add the Bulb" →
"Plug a Leak"), derived from the phase, tells the kid what to do. The bot engine is
a pure **phase + timer** machine that emits no text; the card-earn overlay uses
`showMascot: false`.

## Module layout (`lib/screens/missions/leaky_bucket/`)
- `config/leaky_chain_defs.dart` — the chain as DATA: `LeakStepKind`
  (burn/boil/spin/wire) with per-source `defaultEff`/`maxEff`; `LeakySourceDef`
  for coal (4 steps) / hydro / wind (2 steps). The numbers are tuned so coal
  lands ≈38 and every `maxEff < 1` (the bound is in the model, not the narration).
- `config/leaky_beats.dart` — Voltix lines verbatim from PRD §5 (no "nobody knows
  why" — fully explainable). `config/leaky_tuning.dart` — factor anchors + timings.
- `state/leaky_model.dart` — the **Sankey arithmetic** (pure, no Flutter):
  `out_i = in_i·eff_i`, `leak_i = in_i·(1-eff_i)`; `improve()` ratchets eff toward
  max; `allMaxed`/`output`/`bulbBrightness`.
- `state/leaky_bucket_controller.dart` — owns model + geometry (pixel anchors =
  factors × stage size, step nodes spread evenly between two Y factors so the
  count can be 2 or 4) + the **flow animation** (`flowProgress` 0→1) + the bot
  engine; per-frame `notifyListeners` for the renderer, `ValueNotifier`s for
  discrete UI (botLine/phase/readyToSend/sent/controlsLive/showCardEarn/canFinish).
- `engine/leaky_bot_engine.dart` — `sp_bot_engine`-style: framing → ready →
  flowing → reflecting → improving → closing; the synthesis (gated to fire only
  after the small output is felt + beat 3 engaged) fires Card 04.
- `game/leaky_bucket_game.dart` + `game/components/scene_components.dart` — ambient
  motes + the Sankey renderer: tapering warm ribbon (half-width ∝ value, narrows
  at each leak), per-step sideways **heat-particle branches** (additive, alternate
  sides), step nodes (phosphor glyph via `TextPainter` in-canvas), bulb (glow ∝
  survivor).
- `widgets/` — `lb_voltix_helper` (copy of the SP helper), `scene_numbers`
  (Flutter number chips anchored to controller pixel anchors — 100 IN, a per-leak
  −HEAT chip, the OUT survivor), `improve_dock` (Coal/Hydro/Wind toggle + per-step
  Improve ratchet cards with notch pips, dim+check at max), `inline_fact`
  (one car-engine ¾-as-heat fact), `energy_field_background` (self-contained copy).
- `leaky_bucket_screen.dart` — the standard shell (Stack of `Positioned.fill`,
  GameWidget built once, top chrome, bottom dock faded until `controlsLive`, Send
  CTA / Continue CTA / `CollectibleEarnOverlay`).

## Reused vs new
- **Reused:** the Flame-scene+Flutter-overlay shell, controller-owns-geometry,
  the `BotUtterance`/`VoltixLine`/`VoltixMood` types + the SP-style engine, the
  Voltix helper + sprites, `CollectibleEarnOverlay` + `CollectibleStore`, the
  number-chip / source-selector idioms, `EnergyFieldBackground`.
- **New:** the **`energy_flow_sankey`** primitive (tapering value-proportional
  stream + leak branches + numbers, all recomputed when an efficiency changes —
  reused for Episode 2's transmission loss), **Card 04 "The Great Escape"**
  (`CardMotif.escape` + `EscapeMotifPainter`, linked to Card 01 — the first
  recurring-idea pair the kid sees), and the **per-step ratchet** control.

## What was validated headless (Playwright on a `flutter build web` static serve)
Composition, Send→flow, all four leak numbers (−15/−10/−34/−3), the dim 38-out
bulb, improve shrinking the Spin leak (−34→−26) + raising output (38→45, bounded),
the controls/inline-fact layout, and Card 04 front+back. Deferred to the user's
on-device pass: anchor fine-tuning, the hydro chain-shorten visual, the card-earn
moment, brightness/feel.
