---
name: concept-activity
description: >-
  Playbook for building a premium, self-contained interactive CONCEPT lesson
  from a PRD — the methodology behind the Handle Lamp + the EP2 electricity
  series (Hot Wire, Squared Loss, the Transformer, AC/DC). Render EITHER as
  pure-Flutter (CustomPainter + Ticker) for simple single-surface mechanics OR
  as a THIN Flame GameWidget (a layered Component tree) for richer scene-graph
  scenes — the controller owns sim+geometry+phase-machine identically either way,
  and input ALWAYS comes through a Flutter Listener, never Flame (no Forge2D —
  the sims are hand-rolled "honest" models). Covers the controller-owns-geometry
  ChangeNotifier architecture, the single "load-bearing" pedagogy rule, a reusable
  PREMIUM-CRAFT LIBRARY (one global upper-left key light, cylindrical-member steel,
  glossy-glass controls, dark-glass chrome, additive bloom, built wires, graded
  environment), GEOMETRY/PLACEMENT collision rules, CAPTION-DRIVEN UX (tiny
  3–4 word on-screen instructions instead of mascot dialogue, with
  fade-out→swap→fade-in transitions and progress dots), the sequential step
  machine (no chooser), the 10x premium-polish pass (energy-field background,
  additive glow, particles, light rays, crafted metal hardware, dark-background
  contrast tuning, sibling-matched layout, fill-the-space sizing), audio (looping
  BGM + optional VO with the audio-focus fix), a collectible-card reward (procedural
  OR pre-rendered image faces) with a coin-toss reveal, and the headless-Playwright
  verify loop. This is the polished, caption-driven SPECIALISATION of
  `mini-activity-game` — reuse that skill's intake / sprite-cleaning for
  sprite-heavy/collision games, use THIS one for premium caption-driven
  physics/concept mini-lessons (pure-Flutter OR a thin Flame component tree). Use when
  the user says "concept activity", "wow concept activity", "premium activity",
  "build an activity like the handle lamp", "10x polish an activity", "caption the
  instructions", or provides a PRD for a hands-on physics/concept mini-lesson.
---

# Concept Activity — a premium felt lesson, from PRD to collectible

Turn a PRD for a hands-on concept (one physical idea the kid should *feel*) into
a single, self-contained, beautiful Flutter screen: a continuous-logic mechanic
they drive with a finger, a short caption telling them what to do, premium
custom-painted visuals, looping music, and a collectible card at the end.

This is the **caption-driven, premium** specialisation of the generic
`mini-activity-game` playbook — rendered as pure-Flutter for simple scenes or a
thin Flame component tree for layered ones. Worked examples: **Handle Lamp**
(`lib/screens/missions/hand_crank_lamp/`, `reference/examples/hand_crank_lamp.md`),
the **EP2 transmission series** (Hot Wire / Squared Loss / Transformer / AC-DC,
`reference/examples/ep2_transmission_series.md`), and **Trace It Back**
(`lib/screens/missions/trace_it_back/`, `reference/examples/trace_it_back.md`) — the
cleanest thin-Flame + no-mascot/caption-only reference.

> ### ⛔ The PRD is law — its *one rule* is load-bearing
> Every concept PRD has a single idea the whole activity exists to make the kid
> *feel in their hands*. For Handle Lamp it was: **electricity isn't stored —
> stop making it and the light dies instantly.** Find that one rule first. It
> dictates the mechanic, and it is implemented as a HARD, un-softenable behaviour
> (see "the load-bearing rule" below). Never let polish, easing, or a nice fade
> undermine it. Build *behaviour from the PRD*, reuse only *plumbing*.

> This skill is meant to **grow.** Every new concept activity folds its reusable
> patterns, new gotchas, and copy lessons back into this file and
> `reference/examples/`. See "Keep this skill growing" at the end.

Output: a module under `lib/screens/missions/<activity_id>/`, wired into a
`Lesson`'s `resources` (a `HowwowLessonResource(type:'activity', activityId:…)`)
so the lessonRunner launches it; reward art under `assets/images/collectibles/`.

---

## The non-negotiables (read before building)

1. **One load-bearing rule, felt by hand.** Distil the PRD to one sentence. The
   mechanic must make the kid *cause* it and *feel* the consequence.
2. **Caption, don't narrate.** No mascot monologue, no speech bubbles, no
   walls of text. A single **3–4 word instruction** at the top ("Spin the
   Handle", "Now the Fan"), swapped one at a time. This was the single biggest
   quality jump on Handle Lamp — we deleted an entire voiced-companion dialogue
   engine and replaced it with captions. (See "Caption-driven UX".)
3. **Premium or it's not done.** A working mechanic on a flat background is a
   draft. The bar is the 10x pass: lit-from-within hero, additive glow, particles,
   light rays, crafted metal hardware, an energy-field background, and contrast
   that survives a dark screen. (See "The 10x premium pass".)
4. **Match the family.** New activities in the same concept series share a visual
   language (e.g. Handle Lamp's generator box + shaft echoes Trace It Back's
   turbine→magnet). Look at the sibling activity and reuse its motifs.
5. **Verify before you claim.** Drive it headlessly (Playwright), screenshot it,
   and *look*. Then iterate on the user's on-device feedback. Don't report "done"
   from a clean analyzer alone.

---

## Architecture: controller-owns-geometry (same contract, two renderers)

The controller is the single source of truth in EITHER renderer: it owns the sim,
the factor-based geometry, and the silent phase machine, and exposes pure read
getters. The renderer is dumb. Pick the renderer by scene complexity:

- **Pure Flutter** (`CustomPainter` + `Ticker`) — for 1–3 render surfaces (crank,
  slide, balance, trace, pour, one hero + a slider). Simplest; start here.
  *Used by Hot Wire (2.3) and Squared Loss (2.4).*
- **Thin Flame** (`FlameGame` + a Component tree) — when the scene is a layered
  scene graph of ~6+ distinct renderers (background → towers → wire → coils →
  hero → dock → graph → flash). *Used by the Transformer (2.6), AC/DC (2.7), and
  Trace It Back (the vertical bulb→magnet→turbine→source chain, 9 layers).* See
  "### Two renderers" below.

**NO Forge2D / physics engine.** Every one of these sims is a few state vars + a
hand-rolled `tick(dt)` integration (an "honest model"); an engine would obscure the
one rule the activity teaches. (Defer to `mini-activity-game` only for genuinely
sprite-heavy / multi-body / collision games.)

The contract:

- **The controller owns physics AND geometry.** The view reports the stage size
  once (`setStageSize`) and forwards raw pointer positions; the controller
  computes everything (velocity, the driven value, the step machine, particle
  spawning) and exposes read-only getters.
- **Geometry is factor-based.** Every anchor is a fraction of the stage rect in a
  `*_config.dart` (`pivotFactor = Offset(0.5, 0.84)`, `outputRadiusFactor = 0.21`,
  …). This makes the whole "make it bigger / move it / longer wire" iteration a
  one-line edit — and it's responsive for free.
- **The painter is a pure renderer** (`repaint: controller`): reads getters, holds
  no state, makes no decisions. Glow/flash/pulse use `BlendMode.plus` so they read
  as light.
- **Two notification lanes.** The `ChangeNotifier` fires every frame → the canvas
  repaints (no widget rebuild). *Discrete* UI state (the caption string, the step
  index, the done flag, the active device) lives in dedicated `ValueNotifier`s so
  the banner/dots/Continue rebuild only on real change, not 60×/s.

Module layout (mirror Handle Lamp):

```
lib/screens/missions/<activity_id>/
  <activity_id>_screen.dart        # shell: Ticker clock, layout, audio, reward overlay
  config/
    <thing>_config.dart            # factor-based geometry + tuning constants
    output_defs.dart / sequence.dart  # the step list / device defs (data, editable in one place)
  state/
    <thing>_controller.dart        # ChangeNotifier: physics + geometry + step machine
    <thing>_particles.dart         # ParticleField (sparks/embers/wind/motes)
  widgets/
    <thing>_surface.dart           # GestureDetector → controller.onPointer*; hosts the CustomPaint
    stage_painter.dart             # the single CustomPainter
    instruction_banner.dart        # the caption + progress dots
    <hero>.dart                    # reusable hero art (e.g. bulb.dart) — share across siblings
```

Shell clock pattern (pure Flutter):

```dart
_ticker = createTicker(_onTick)..start();
void _onTick(Duration e) {
  final dt = (e - _last).inMicroseconds / 1e6;
  _last = e;
  if (dt > 0 && dt < 0.1) _controller.tick(dt); // guard pauses/long frames
}
```

### Two renderers: pure-Flutter vs thin-Flame

When the scene is a layered scene graph, host it in Flame — but keep Flame **dumb**.
The controller still owns everything; Flame does exactly three jobs:

1. **Size** — `onGameResize(size) => controller.setStageSize(size)` (once). All
   geometry getters are factors of this rect (resolution-independent).
2. **Clock** — `update(dt)` guards `0 < dt < 0.1` then calls `controller.tick(dt)`.
   There is ONE clock; the shell runs no Ticker. The controller's phase-machine
   timers advance inside `tick` (NOT Dart `Timer`s) so they pause with the game.
3. **Render** — `onLoad → addAll([...layers])`, back→front. Each layer is a bare
   `Component` taking the controller and reading its getters every `render`.

```dart
class FooGame extends FlameGame {
  FooGame(this.c);
  final FooController c;
  @override Color backgroundColor() => const Color(0x00000000); // transparent → Flutter bg shows through
  @override Future<void> onLoad() async => addAll([BgLayer(c), HeroLayer(c), ...]);
  @override void onGameResize(Vector2 s) { super.onGameResize(s); c.setStageSize(s.toSize()); }
  @override void update(double dt) { if (dt > 0 && dt < 0.1) c.tick(dt); }
}
```

- **Input does NOT go through Flame.** Put a transparent Flutter `Listener`
  (`HitTestBehavior.opaque`) over the `GameWidget` and forward
  `onPointerDown.localPosition → controller.onTapDown`. The controller hit-tests
  (e.g. `switchHit`/`batteryHit` rects) and routes by phase. Flame has no gestures.
- **The Flutter shell still owns** the full-bleed `Stack`: a `RepaintBoundary` around
  the scene (so a capture snapshots the real painted frame), the background widget
  behind the transparent GameWidget, the fixed top-text seat, the CTA seat, and the
  card-earn / evidence overlays. The hero scene shows through an empty `Expanded`.
- **Decouple discrete UI from the hot path** exactly as in pure-Flutter: `caption` /
  `phase` / `showCardEarn` are `ValueNotifier`s the shell listens to; the per-frame
  sim values are plain getters the Flame layers poll.

Pick Flame when you have ~6+ distinct layers or want the component tree; otherwise
pure Flutter is less ceremony. The premium-craft library below is identical for both
(it's all `Canvas` painting).

---

## The load-bearing rule (make it un-softenable)

The PRD's one rule is implemented as a hard behaviour in `tick()`, with a comment
that says so, so no future "polish" eases it away. Handle Lamp's instant cutoff:

```dart
if (_isGenerating) {
  final target = brightnessCurve(_energyInput);
  _brightness += (target - _brightness) * (1 - math.exp(-dt / rippleTau));
} else {
  _brightness = 0; // HARD cutoff — no fade, no coast-down, no afterglow.
}
// And: particles, wire-pulse, glow, device spin are ALL gated on `_isGenerating`
//      and cleared the same frame, so nothing lingers after release.
```

Key generalisation: derive *everything visible* from the driven value
(`brightness`/energy) so that zeroing it snaps the entire scene off at once. If
any layer reads a separate clock, it will "leak" past the cutoff and break the
lesson.

---

## Sequential step machine (no chooser)

For "try the same input on several outputs" PRDs, **don't** give a selection bar —
walk the kid through them one at a time and auto-advance. It's calmer, needs no
chrome, and guarantees they experience every case.

- A `kSequence` list of `StepDef`s (device + caption + optional `diesText`) in
  `config/sequence.dart` — all copy in one editable place.
- Controller holds `stepIndex` / `done` (`ValueNotifier`s) + `_stepLit`.
- Advance rule: drive the current output clearly (`brightness ≥ threshold` →
  `_stepLit = true`), then on release (`wasGenerating && !isGenerating &&
  _stepLit`) advance. The load-bearing "it dies on release" *is* the gate.
- Optional **consequence hold**: the teaching step can hold a short message
  (`"No Spin, No Light"`) for ~1.8 s before advancing; others advance instantly.
- End → `done = true`, optional auto-driven "victory lap", then a Continue button
  reveals the reward.
- **"Compare across cases" variant (Trace It Back's six sources):** when the kid only
  *watches* each case (not drives it), advance with a single **Next** button instead
  of the release-gate, and give each case **two converging captions** — an input that
  *varies* then a result that lands on the **same word** ("Coal Burns → Steam Spins
  It", "Gas Burns → Steam Spins It", "Atoms Split → Still Just Steam"). The repetition
  IS the lesson; the final case breaks it ("No Spinning Here") and lands as a
  record-scratch. Don't pre-spoil the breaker in any earlier case's copy or visual.

---

## Caption-driven UX (the biggest quality lever)

Replace mascots/dialogue with a **large 3–4 word caption** at the top + small
**progress dots**. Rules learned the hard way:

- **Tiny imperative captions only.** "Spin the Handle", "Now the Fan", "Now, Let
  Go". A separate `diesText` for the teaching beat. The full synthesis line can be
  longer ("One Handle — Light, Motion, Heat, Sound") — auto-shrink it (`fontSize:
  text.length > 22 ? 23 : 34`, `maxLines: 2`).
- **Transitions must be SEQUENTIAL, never a cross-fade.** `AnimatedSwitcher`
  cross-fades, so the old and new captions overlap for a few frames and look like
  garbled double-text. The fix is a one-controller state machine: **fade old out
  → swap the string at opacity 0 → fade new in.** Queue a newer caption that
  arrives mid-fade and apply it at the next zero-opacity point. (See
  `instruction_banner.dart` in the example — `_toss`-style status-listener swap.)
- **Fixed-height slots.** Put the banner and the bottom (Continue) area in
  fixed-height `SizedBox`es so the stage between them never resizes when text
  swaps or the button appears.
- **No companion by default.** Handle Lamp shipped with the mascot + VO deleted.
  If a brief truly wants a voice, keep it to short VO clips, not on-screen prose.

### Trimming captions (do it aggressively — the user always wants fewer)

Captions balloon as you build the beats; on review the user almost always wants
FEWER, SHORTER lines. We cut 16→6 (Hot Wire), 17→9 (Squared Loss), 21→9 (AC/DC).

- **What to CUT:** redundant narrating lines the VISUAL already shows (a dashed ghost
  line carries "it's not a straight line"; the ×4/×9 numbers carry "grows faster than
  current"); intro scene-setting; in-activity algebra PROOFS (over-reach for a 12–80
  audience — the law belongs on the collectible card, not in a timed monologue);
  multi-line derivations (merge to one). **KEEP:** the imperative prompts, the one
  felt-discovery line per beat, the named law, the bridge question if the series needs
  it.
- **Name-last is verifiable:** the vocabulary (DC/AC/I²R/hertz) must be ABSENT from
  the copy file until the naming phase — `grep` to confirm. The kid feels both
  behaviours before any word lands.
- **Match the verb to the quantity:** "Raise the Current" (an amount); "push" is for
  voltage — don't let a prompt fight an earlier card's framing.
- **Silent beats are deliberate** — a blank caption during a dead/still state or
  before a spring-to-life is the point; the witnessed absence IS the discovery.
- **Render short meaning-lines BIG** (the imperative size, 28px Bricolage), not the
  template's default medium body size. Only LONG meaning-lines step down. The `_line`
  selector becomes: `if (cap.meaning && cap.long) → small (17px); else → big (28px)`.

### Cutting copy = phase-machine surgery (the controller side)

The silent step machine is an enum of phases + `_enter<Phase>()` methods, each
setting the caption and `_schedule(ms, nextCallback)` against the controller's own
ms-timer list (advanced in `tick`, NOT Dart `Timer`s, so it pauses with the app).
When you trim copy: (1) redefine the caption consts/enum cleanly — no gaps like
`t1,t3,t7`; (2) rewire each `_enter` method to the new lines + delays; (3) DELETE the
now-dead phases, `_enter` methods, and timing consts; (4) `grep` for dangling
references, then `fvm dart analyze <dir>`. Removing the LAST caller of a private
helper triggers an `unused_element` warning — delete the orphaned helper too (e.g. a
scripted handle-ease that only the cut derivation used).

---

## Get the concept right (verify the physics; the audience is 12–80)

The copy teaches real science to a 12–80 audience — a wrong or kid-flavoured line
is a worse bug than a misaligned wire, and a sharp reader WILL catch it. Trace It
Back's "deeper why" caption took **four** corrections to get honest.

- **Verify any factual/pedagogy claim with a web search — never assert from memory,
  and never ship a falsehood for simplicity.** "Nobody knows why induction works" is
  false (it's explained); "magnetism is simply electricity in motion" is wrong for
  permanent magnets (electron *spin*, not moving charge). When the user says "are you
  sure?" / "check properly", actually search and report layers + sources.
- **Depth-stops, not mysteries.** When the real "why" is genuinely advanced, say *a
  deeper reason exists* (name it if you can) — never claim nobody knows. Distinguish
  the **rule** (Faraday's law describes induction) from the **deep why** (relativity
  unifies E&M); both can be true at different layers.
- **No kid-framing.** The audience is 12–80. Cut "you'll learn this in a few years"
  (homework-for-later), childish exclamations ("No Magnet!"), and in-activity algebra
  proofs. The full law belongs on the collectible card; the caption only needs to be
  short, true, and awe-adjacent.
- **A short true line beats a long impressive one.** Trace It Back's depth-stop ended
  as just *"Electricity and magnetism are two sides of the same coin called
  electromagnetism."* — after relativity/Faraday/spin versions were all reverted.

## The 10x premium pass

A mechanic that works is ~30%. The polish is the rest. Do visuals as a deliberate
pass once the mechanic is correct. The toolkit (all additive/blurred for light):

- **Energy-field background** — a radial gradient + vignette focused on the hero,
  faint circuit texture, drifting motes, and a subtle warm response to the driven
  value. Not flat black.
- **Lit-from-within hero** — for a glowing object, lerp the *body* toward a hot
  colour with brightness AND add an inner `RadialGradient` bloom (`BlendMode.plus`)
  so it reads as glowing, not just tinted. (Bulb fix: warm the glass globe AND add
  the inner wash — tinting alone looks dead.)
- **Light rays** — soft god-rays fanned from the lit hero, each pulsing on its own
  phase. **Particles** — `ParticleField` spawning sparks at the input + per-output
  debris (embers/wind/motes), all `.clear()`ed the instant generation stops.
- **Crafted hardware** — mechanical parts read as real: a mounting flange with
  bolt-heads, a recessed housing, a cylindrical shaft with travelling rib-rings, a
  beveled grip knob with a specular highlight + grip ridges. Steel = a
  dark→light→dark gradient, not a flat fill.
- **Match the sibling layout.** Handle Lamp became a vertical column (device on
  top → wire → generator box → shaft → handle at the bottom) to echo Trace It
  Back's turbine→magnet stack. Reuse the family's motifs and orientation.

### Contrast on dark backgrounds (do this, it's always needed)
Off-state metal/housings sink into the dark navy and become invisible at low
brightness. **Lift every off-state fill + edge to a bright steel-blue.** Keep a
consistent palette: bodies ~`0xFF54649E→0xFF313F6C`, rims/edges ~`0xFFAEB9E8`,
device off-glyphs ~`0xFF6F7DB2`. Lit state adds glow on top, so a brighter base is
free. Expect to push it 1.5–2× brighter than your first instinct — the user asked
for "more contrasting" twice.

### Sizing & alignment
- **Fill the space.** Empty top/bottom → scale the hero and the input up (they're
  factors, so bump `outputRadiusFactor` / `handleLenFactor`). Derived parts
  (flange, knob, shaft) scale off the input length automatically.
- **Centre on one axis.** All anchors share `dx = 0.5` with symmetric padding.
  Verify with a PIL centroid measurement (see verify recipe) rather than eyeballing
  — asymmetric-looking handles/arms can still be perfectly centred.

---

## Premium craft library (the reusable finishes)

The 10x toolkit above is the *concept*; this is the **reusable craft** from the EP2
series — every item is `Canvas` painting that works in either renderer, ported from
Handle Lamp's metal craft and proven across Hot Wire / Squared Loss / the
Transformer / AC-DC. (Concrete hexes + factors live in
`reference/examples/ep2_transmission_series.md`.)

- **ONE global key light — UPPER-LEFT.** The single rule that unifies a scene of
  dozens of separately-drawn pieces. Define `const _lightUL = Offset(-0.7071,
  -0.7071);`. Then forever: every radial highlight centres up-left
  (`Alignment(-0.35,-0.45)`); every drop shadow offsets DOWN-RIGHT; every specular
  dot / bolt speck sits up-left.
- **Cylindrical member — the steel workhorse.** To make a thin bar / lattice leg /
  cable read as round steel, fill it with a cross-section gradient PERPENDICULAR to
  its axis: dark edge → bright spine → dark edge
  (`ui.Gradient.linear(m - n*half, m + n*half, [edge, spine, edge], [0,0.5,1])`,
  `n` = unit perpendicular at the midpoint) + a thin bright up-left chamfer-rim
  stroke offset by `_lightUL`. This turned flat-wireframe towers into real lattice
  steel.
- **Radial for SOLID round lumps only** — knobs, domes, insulator discs, lugs, bolt
  heads (`RadialGradient(center: Alignment(-0.35,-0.45))`). Don't radial a thin
  member (use the cylinder trick); don't cylinder a round lump.
- **Bolts + AO at joints.** A bolt = a dark dot (`#0C1430`) + a tiny up-left white
  speck, scattered at member intersections — the cheapest convincing "real machine"
  cue.
- **Ground shadow + lift silhouette.** A wide flat blurred black ellipse under the
  feet, plus ONE blurred silhouette of the whole shape offset down-right drawn
  BEFORE the crisp pass (cheaper + cleaner than per-member shadows).
- **Additive bloom (`BlendMode.plus`) for every glow** — halo → core → hot-centre,
  with BOTH alpha AND radius keyed to the live value. Cap secondary glows LOW
  (`~0.14×value`) so they recede: the hero is the only thing allowed to be
  bright/warm.
- **Glossy-glass control (slider thumb / toggle knob).** Radial 4-stop gradient
  (light → mid → deep) + a crisp white specular cap up-left + a drop shadow + a
  2-stop rim; warm controls add an additive under-glow riding the live value. A
  **recessed groove rail** = a vertical 3-stop (dark top lip → wall → lit floor) + a
  1px top gloss line + an inner top-shadow line; the fill glows from inside the
  groove. Drive the glow off the SIM value (e.g. `wireTemp`), not just the handle
  position, so the control feels like the thing it controls.
- **Wires — the clean hand_crank_lamp look.** A gently BOWED quad-bezier stroke (dim
  steel → cool/warm glow when live) + travelling pulses sampled via
  `path.computeMetrics()`. **No junction-hardware lugs** — we tried metal
  collar+bolt lugs at the ends and the user rejected them as ugly; the bare glowing
  conductor reads better. Join a wire to the shared bulb at its screw base via
  `bulbBaseDrop(radius)` (from `hand_crank_lamp/widgets/bulb.dart`). Add a vertical
  `bowY` to arc a wire OVER a shape it would otherwise clip.
- **Along-span / loss gradient.** To vary colour/alpha ALONG a curved path (hottest
  at one end, cooling to the other), key a `ui.Gradient.linear` to the SCENE anchors
  (`wirePoint(0) → wirePoint(1)`), not screen position. + a thin white-hot blow-out
  spine + one soft anamorphic streak + a low-amplitude breathing sine on the core
  alpha → genuine incandescence.
- **Dark-glass chrome (panels, docks, chips, scopes, compartments).** One language:
  deep fill (~`#0B1026` @0.55–0.85) + an inset recessed well + a top catch-light
  band (white @0.05) + a crisp white rim (`0x26FFFFFF`) + a soft drop shadow. Reuse
  for every panel so the whole activity feels of-a-piece.
- **Readout chips/gauges.** Dark-glass chip + a value-linked glow CAPPED low
  (`0.16×norm`) + mono IBM Plex Mono digits + a thin accent needle bar + a trend ↑/↓
  glyph + a 1px top gloss line. If a chip shares the hero's exact hue (a HEAT chip vs
  the ember wire), give it an `emphasis<1` that damps its FLARE (glow/border) only —
  so it confirms the hero, never competes (digits stay full strength).
- **Labels are BUILT, not floated.** Never leave bare text floating. Endpoints → a
  grounded plate (scrim pill + a tiny icon + a ground tick). A held-constant callout
  → an annotation pill with a thin leader line to the thing + a small lock glyph,
  placed OUT of the bright/busy zone.
- **Environment, drawn inside the stage.** A graded ground band + faint cool distant
  glows behind the scene's poles (warm is the hero's alone) + blurred parallax depth
  motes. Draw it INSIDE the stage painter; don't mutate a shared background widget
  other screens use.
- **Connector TYPE = meaning, not decoration.** When a chain has several connectors,
  make them *visually distinct* and let the type teach what travels through it: an
  electrical **wire** carries the current-pulse (and ONLY it); a mechanical **shaft**
  shows rotation with NO pulse; a **flow** is particles. (Trace It Back: the pulse
  lives only above the coil → "electricity is born at the magnet; below is just motion
  + fuel" with zero words — it pre-empts the "current flows from the coal"
  misconception.)
- **A multi-step PROCESS must be legible — a labeled flow diagram, not a pretty box.**
  A "what happens inside" subunit (a power plant's burn→boil→steam) drawn as an
  abstract container reads as nothing — the user literally can't tell what it is.
  Draw it as a **horizontal labeled flow**: an icon per step + a **word under each**
  (`TextPainter` paints text in the Flame/Canvas layer) + arrows, on a dark-glass
  panel; vary only the step that differs (Coal lumps / Gas cylinder / Atoms), share
  the rest. Legibility comes from the WORDS, not nicer art. Keep it secondary to the
  hero.
- **Make the odd-one-out's absence an EVENT.** When one case breaks the pattern (solar
  skips the spinning core), don't show a static gap — **fade the shared core OUT**
  (an eased `coreFade` 0, ~0.4s) as the kid arrives, so they *witness* the part every
  other case had being removed. Fade the replacement in where it was.
- **Entrance reveals + a "comes alive" surge.** Ease each component in (`reveal` 0→1:
  slide+scale+fade) as its beat arrives so the scene *assembles*, not pops; and when a
  driver takes over, ramp the drive 0→full (a `handoffRamp`) so the hero *surges* to
  life. Both are controller-owned eased values the renderer reads.

A graph/curve that teaches a relationship gets the same treatment: a CENTRED modal
card (backdrop scrim + the dark-glass chrome) with **proper labelled axes** (ticks +
gridlines), the learner's glowing trail, a dashed ghost line for contrast, and
data-point markers with dotted drop-lines to both axes. When it's done, **remove it
completely** (slide + fade), don't dim it.

---

## Geometry & placement (collision rules)

Everything is a factor of the stage; a placement fix is a one-number edit. The
recurring traps:

- **The full-bleed stage sits UNDER fixed top/bottom seats.** The Flutter column is
  header → fixed-height top-text seat → `Expanded` stage → controls → fixed CTA seat,
  and the painter/GameWidget is full-bleed behind it. A hero near the top (bulb at
  `0.10`) collides with the caption — lower it. A readout/graph at the bottom
  collides with the control dock — leave a gap, and **recompute the gap when you move
  or resize the dock** (a dock you moved up that also grew taller can re-overlap).
- **Anchor connectors to the REAL component, not a guessed factor.** A wire that ends
  at a hand-picked mid-factor lands INSIDE a shape's window. Compute the endpoint from
  the component geometry — e.g. a transformer limb x = `coreCenter.dx ∓ coreOuterW/2
  ± limbThickness/2`; coil span = `0.8·coreOuterH` so coil-bottom = `center +
  0.4·coreOuterH`. Then the wire visibly joins the coil.
- **Bow a wire over a shape it crosses** with a vertical `bowY` (negative = up).
- **A maxing readout trace rides into its own label** if the scope's zero-line is the
  panel CENTRE with a tall amplitude (a DC `+1` climbs into the top label). Give the
  trace its OWN plot area BELOW the label: `plotTop` under the label, `midY` = plot
  centre, `amp` sized so ±1 fit the plot.
- **A "toggle" renders tall, not wide, if you ignore the aspect ratio.**
  `switchWFactor×stageW` vs `switchHFactor×stageH`: on a portrait stage (h≫w) a
  "square" factor pair (`0.15w × 0.14h`) is actually TALLER than wide in pixels. For a
  horizontal toggle make `switchHFactor ≪ switchWFactor` (e.g. `0.20w × 0.055h`).
  Reason in pixels, not factors, for aspect.
- **A bay/well holding a horizontal element** must not inset its well by a
  height-derived value horizontally (it over-pinches the sides so the element
  overflows) — use a width-proportional horizontal inset.

---

## Audio

- One looping **BGM** bed via `audioplayers`, `ReleaseMode.loop`, low volume
  (~0.18), started in a post-frame callback.
- **Audio-focus fix (always apply):** set a per-player `AudioContext` with
  `AndroidAudioFocus.none` + iOS `mixWithOthers`, so the bed mixes instead of
  grabbing focus / pausing the user's music. Wrap plays in `.catchError((_){})`.
- A sound toggle in the header pauses/resumes the bed.
- Optional VO: short per-line clips, `AssetSource('sounds/<id>/..mp3')`. If you
  voice-pace gameplay, the engine must FREEZE its timers while a clip plays and
  resume on `onComplete` — otherwise idle/next-line timers fire mid-clip and you
  get overlapping or looping audio (a real bug we hit). Default: no VO, just BGM.

---

## The reward: a collectible card + coin-toss reveal

End on a premium card in `CollectibleEarnOverlay` (scale-up + glow burst + haptic
+ "Add to deck"). Two ways to render the card face:

- **Procedural** (`CollectibleCardView` + `collectible_painters.dart`): a 5:7
  guilloché-framed, section-accented, flippable card with a current-sheen — for
  cards without bespoke art.
- **Pre-rendered image faces** (preferred when the user supplies art): set
  `frontImage`/`backImage` on the `CollectibleCard`. The card view then renders
  the PNG (square aspect, frame/glow baked in) instead of painting. Gotchas:
  bespoke art is usually **square, not 5:7** → make the card + earn-overlay
  reserve **square** dimensions when `hasImageFaces`; the **back face is
  auto-mirrored** by the parent flip transform, so render it normally.
- **De-personify a shared overlay with a flag, don't fork it.** The earn overlay is
  shared across activities (some have a mascot, some don't). Add a `showMascot` (and
  `mascot`/`brag`) param — default keeps the companion; pass `showMascot:false` for a
  no-mascot activity (Trace It Back) so the reward shows a plain centred banner (no
  avatar, no speech tail). One widget, parameterised — never copy it.
- **Coin-toss entry** (`tossOnEnter: true`): a multi-turn `rotateY` that
  decelerates and lands on the front — `angle = (1 - Curves.decelerate(t)) *
  turns * 2π + flipAngle`; `showBack` from `angle % 2π ∈ (π/2, 3π/2)`. Honour
  reduced-motion (skip to settled).

---

## Verify it (headless Playwright loop)

You cannot judge this from the analyzer. Drive it and look.

1. **Throwaway entrypoint.** Write `lib/_preview.dart` that boots straight into the
   screen (or the earn overlay). Restore it to the repo's default when done.
2. **Serve:** `fvm flutter run -d web-server --web-port <port> -t lib/_preview.dart`,
   wait for "is being served at". **Const config changes need a restart** (no hot
   reload over web-server) — kill + rerun.
3. **Screenshot** at `412×915 @2x` with Playwright; `Read` the PNG and actually
   look at it.
4. **Drive the mechanic** by dispatching `PointerEvent`s in JS — orbit the pointer
   around the pivot to "crank". Because the load-bearing cutoff makes the lit state
   exist only *while* driving, screenshot **during** the drive (a settled
   screenshot shows it dark). If an animation is too fast to catch, **temporarily
   slow it** (e.g. toss 1.3s→5s), verify, then revert.
5. **Measure when in doubt** — alignment/centroid with PIL, not your eye.

See the verify recipe block in `reference/examples/hand_crank_lamp.md`.

---

## Challenges & fixes (the gotcha ledger — append to this)

| Symptom | Cause | Fix |
|---|---|---|
| Captions overlap/garble on change | `AnimatedSwitcher` cross-fades both children | Sequential fade-out → swap at opacity 0 → fade-in state machine |
| Black screen on overlay reveal | A non-positioned `SizedBox.shrink()` child collapses a `Stack` to 0×0 | Keep every Stack overlay layer `Positioned.fill` |
| Hero "lit" but looks dead | Only tinting the body | Lerp body toward hot colour **and** add inner `BlendMode.plus` bloom |
| Glow/particles linger after release | A layer read a separate clock | Gate every visible layer on `isGenerating`/`brightness`; clear same frame |
| Components invisible on dark bg | Off-state steel ≈ background | Lift all off-state fills + edges to bright steel-blue (1.5–2×) |
| Lit state un-screenshottable | Instant cutoff → dark when idle | Screenshot **while** driving pointer events; slow fast anims to verify |
| Config edit didn't show | web-server has no hot reload for consts | Kill + restart the preview |
| Audio loops / overlaps | Idle/next-line timers fired during a VO clip | Freeze engine timers while a clip plays; resume on `onComplete` |
| BGM pauses the user's music | Player grabbed audio focus | Per-player `AudioContext`: `AndroidAudioFocus.none` + iOS `mixWithOthers` |
| Image card distorted/clipped | Bespoke art is square, view assumed 5:7 | Square sizing when `hasImageFaces`; the PNG *is* the card (no extra frame) |
| Card back mirrored | Forgot the parent flip already mirrors the back | Render the back face/image normally |
| Relative imports fail to resolve | `config/`+`widgets/` are deeper than the screen | Count the `../` to shared dirs (e.g. `../../../home/career/`) |
| Fresh install crashes on a card | `GoogleFonts.allowRuntimeFetching=false`; only some fonts bundled | Bundle the card's fonts under `google_fonts/`, or fall back to a bundled family |
| `flutter analyze` crashes / noisy | multi-path bug; ~hundreds of pre-existing errors in unreferenced files | Analyze ONE path (`fvm dart analyze lib/screens/missions/<id>`) |
| Detented slider reads the wrong value (×2 shows 1.4) | tick LABELS at full-span `(d-1)/3` but the handle/value normalize to the ACTIVE range | Make both use the full span; the active range only CLAMPs the value |
| Connector wire ends INSIDE a shape | endpoint set to a guessed mid-factor, not the component | Anchor to real geometry (coil-limb x, bulb base via `bulbBaseDrop`); `bowY` to arc over |
| Readout trace climbs into its own label | scope zero-line = panel centre + tall amplitude, so `+1` hits the top | Give the trace its own plot area BELOW the label; size `amp` so ±1 fit |
| "Toggle" renders tall, not wide | square factor pair on a portrait stage (h≫w) | Landscape in PIXELS: `switchHFactor ≪ switchWFactor` (~`0.20w × 0.055h`) |
| Element overflows its bay/well | well inset derived from HEIGHT applied horizontally | Width-proportional horizontal inset |
| Hero/readout collides with caption/dock | full-bleed stage under fixed top/bottom seats | Lower the hero / add a gap; recompute the gap when the dock moves OR grows |
| Junction lugs look ugly | over-built metal collar+bolt at every wire end | Clean bowed glowing conductor + pulses, NO hardware (hand_crank_lamp style) |
| Two labels overlap (LED on "POWER" text) | side-by-side in a narrow element | Stack them (light on top, label below) and centre each |
| Unused helper after a copy trim | removed its last caller (e.g. a scripted-ease) | Delete the orphaned private method/enum; `grep` + analyze |
| Flame layer never updates / input dead | put logic/gestures in the Flame game | Controller owns it all; a Flutter `Listener` over the GameWidget forwards taps |
| A process subunit is unreadable ("what is this?") | drawn as an abstract pretty box | Redraw as a horizontal **labeled** flow: icon + word-under-each + arrows (`TextPainter`) |
| Row chips shrink to content, big gaps between | a `Stack` (`StackFit.loose`) gives the body loose width so it hugs its content | `Stack(fit: StackFit.passthrough)` (or `width: double.infinity`) so the body fills its `Expanded` slot |
| `..onX = () => f()` in a cascade kills later `..` | the `=>` arrow body greedily absorbs the following cascade | Use a block body: `..onX = () { f(); }` |
| `ValueListenable` undefined | only `material.dart` imported | `import 'package:flutter/foundation.dart' show ValueListenable;` |
| Shipped a wrong science claim | asserted from memory ("nobody knows why", "magnetism is electricity in motion") | Web-verify the claim; depth-stop honesty; keep the line short + true (audience 12–80) |

---

## How to take iteration feedback (this is most of the work)

The user reviews on-device and gives short, surgical notes. Translate each into
the smallest config/paint change, ship it, re-screenshot. Patterns seen:

- "make X bigger / there's space" → bump the factor; let derived parts scale.
- "more contrast" → lift off-state palette again (they'll often ask twice).
- "looks overlapped for a moment" → it's a transition cross-fade; sequence it.
- "make it like activity 2" → open the sibling, copy its layout/motif.
- "centre aligned?" → measure (PIL centroid), then state the numbers.
- "caption it / messages are too big" → shrink to 3–4 imperative words.
- "remove this line / not required" → cut the copy const + rewire the phase; persist
  the right neighbour line behind Continue.
- "update the captions with these" → it's a copy trim → phase-machine surgery (see
  the Caption section); expect to delete phases + timing consts.
- "the wire isn't connected / goes inside the X" → anchor the endpoint to the real
  component geometry, not a factor; `bowY` to arc over a shape it crosses.
- "give padding on top of it" → it overlaps the element above; move/resize and
  recompute the gap (the dock may have grown when it moved).
- "make the wires like handle_lamp / join the bulb" → clean bowed glowing conductor +
  pulses, NO lugs; `bulbBaseDrop` to the screw base.
- "make X a smooth toggle / more premium" → glossy-glass control + a landscape toggle
  (mind the aspect-ratio trap).
- "×2 shows 1.4 / fix the reading" → the detent LABEL span and the value span
  disagree; align them.
- "I can't understand what this is" → an abstract icon/box; redraw as a horizontal
  labeled flow diagram (icon + word per step + arrows).
- "are you sure it's X? / check properly" → STOP; web-verify the physics, report the
  layers + sources, then change the copy — never defend an asserted claim.
- "we target 12–80, not just kids" → strip kid-framing ("you'll learn it later"),
  childish exclamations, and in-activity proofs; keep one short true line.
- "remove the mascot / make it cleaner" → delete the mascot+bubble+VO+bot-engine;
  replace dialogue with the two caption registers; pass `showMascot:false` to the
  shared earn overlay.

Respond with the change + one verifying screenshot, not a wall of options.

---

## Keep this skill growing

After each new concept activity:
- Add a one-file worked example to `reference/examples/<activity_id>.md` (file map,
  the load-bearing rule, the mechanic, anything novel, on-device tuning notes).
- Append any new gotcha to the ledger above.
- If you found a better copy/polish/verify pattern, fold it into the relevant
  section here. This file is the living spec.
