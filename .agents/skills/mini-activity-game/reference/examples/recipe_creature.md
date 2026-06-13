# Example — Recipe Creature ("The One Thing You Need", de-extinction Prologue)

**Mechanic:** parametric build + reveal + "bring it back" — the kid moves four
instruction sliders and a creature is drawn live from them; the instructions are
revealed as a four-letter code (DNA/genome); the creature goes extinct and only
its *genome* (not bones/photo) rebuilds it alive.

**Tech chosen + why:** **PURE FLUTTER** (`CustomPainter` + `AnimationController`/
`Ticker` + `GestureDetector`). No Flame, no Forge2D, **no art assets** — the
creature is a controlled value-mapping (`Genome` → a drawn body), the exact
single-widget-precision case for plain Flutter. The PRD mandated this (its
acceptance criteria forbid Flame/Forge2D and any sprite). This is the
de-extinction module's **vertical slice** — it stands up primitives every later
episode reuses.

## What this slice established (reusable primitives)
- **Parametric-creature painter** (`widgets/creature_painter.dart`) — one
  `CustomPainter` draws all four `CreatureRenderMode`s (live / wireframe / photo /
  broken) + the extinction dissolve + the rebuild splash, reading controller
  getters (`repaint: controller`). Four genes → four unmistakable, *independent*
  visual responses (size=scale, limbs=appendage length, colour=hue,
  pattern=spot count). The "broken" mode = clip away the right half + a ragged
  red edge + one eye → reads instantly as "half a creature".
- **`HelixBeatEngine`** (`engine/helix_beat_engine.dart`) — a generic,
  `BeatConfig`-driven dialogue engine with the three reactive sockets
  (`onIdle`/`onCounterproductive`/`onDiscovery`) + before/after lines, moods,
  monotonic tokens, cooldown/escalation gating, and a scheduled-line queue. The
  host calls `reportDiscovery()`/`playAfter()` at physical moments; the engine
  owns timing + firing order. Mood discipline (surprised at the kid's discovery,
  celebrating only at the card, idea only for the companion's own suggestion) is
  structural. Every later de-extinction episode feeds it its own `BeatConfig`s.
- **`InstructionControl`** (`widgets/instruction_control.dart`) — the reusable
  instruction-slider (one per `Genome` field; immediate drag; rainbow track for
  the colour gene; a trailing "peek" affordance enabled only in the reveal beat).
- **Companion-as-placeholder pattern (`HelixAvatar`)** — no sprite art existed,
  so the mascot is a drawn, mood-expressive `CustomPainter` placeholder that
  *first tries* `assets/images/helix/helix_<mood>.png` and falls back via
  `errorBuilder`. Dropping real PNGs in later (+ pubspec decl + full re-run) needs
  zero call-site changes. Good default when "placeholder now, art later".

## Reused (not rebuilt)
- **`CollectibleStore`** (shared_preferences) for deck persistence — already
  existed; the PRD listed "card-deck persistence" as a primitive but it was done.
- **`CollectibleEarnOverlay`** — extended with one optional `mascot` widget so the
  Helix card shows Helix, not the hardcoded Voltix sprite (backward-compatible
  default).
- **Collectibles model/painters/card-view** — added a `CardMotif.recipe` (a
  coiled-strand / certified-specimen painter), a `kRecipeIsCreatureCard` reusing
  the prismatic **Foundations** section (the rarest, first-card look), and made
  the card back's companion mark dynamic (`companionName`/`companionIcon`) so it
  reads HELIX. NOTE: the de-extinction card shares the Foundations section with
  electricity's Card 01 for now — a real **module/deck split is deferred** (only
  one card exists; don't over-build the slice).

## Module layout
```
recipe_creature/
  recipe_creature_screen.dart        shell: Stack of Positioned.fill; Ticker → controller.tick
  state/recipe_creature_controller.dart  Genome + RCPhase machine + anim envelopes + drives Helix
  engine/helix_beat_engine.dart      reusable BeatConfig dialogue engine
  config/genome.dart                 Genome + CreatureRenderMode + encodeForDisplay (illustrative ATCG)
  config/prologue_beats.dart         verbatim Helix lines + BeatConfigs + timing knobs
  config/creature_tuning.dart        colour/motion tokens
  widgets/{creature_painter, helix_avatar, helix_helper, instruction_control,
           dna_peek, artifact_tray, inline_fact}.dart
```
Wired: `activityRegistry.dart` (`'recipe_creature'`) + the de-extinction Prologue
lesson's `resources` in `wowConcepts.dart`.

## The load-bearing rule (this activity's "instant cutoff")
**The rebuild contrast.** Only the GENOME restores the living, breathing,
controllable creature; bones → inert grey wireframe, photo → flat frozen snapshot.
No score, no "wrong" feedback for poking bones/photo (they're optional
discoveries). Protect that contrast above all.

## Premium pass (10x) — reusable techniques for a pure-Flutter hero
Done in 4 tiers, each landed + screenshot-verified before the next:
- **Tier 1 — alive parametric creature:** evolve a flat blob into a volumetric
  head+body critter — radial-gradient body shading + rim-light arc + soft
  specular, a blurred contact shadow, a pulsing hue-matched aura, ears/snout/
  glossy eyes (blink + idle pupil drift) + idle-wagging tail. Keep it 100%
  gene-driven (size→scale, limbs→leg length, colour→hue, pattern→spots). A `_Pal`
  helper derives base/light/dark/spot/outline/wire from the hue gene per render
  mode so all four modes share one palette path.
- **Tier 2 — living stage:** a `StageBackground` CustomPainter (repaint via
  controller clock): deep gradient + a warm radial "spotlight" behind the hero +
  slow drifting two-pass (glow+core) life-motes + a very faint helix/cell
  watermark + an edge vignette. Keep every layer low-contrast so the hero out-glows
  the chrome (PRD §9).
- **Tier 3 — showpiece motion (the emotional peak):** procedural, state-free
  particle FX driven by the controller's 0→1 progress getters. Extinction =
  silhouette-sampled particles rising/scattering + a few floating A/T/C/G glyphs
  ("dissolves back into its code"). Rebuild = particles *converging* onto the
  silhouette (reverse) + a descending double-helix + a white "born" flash +
  shockwave ring + easeOutBack overshoot. A `_silhouette(u)` sampler (points
  around the body+head ellipses) feeds both emit (extinction) and target
  (rebuild) sites. Plus a trait-change ripple ring.
- **Tier 4 — chrome to match:** group sliders into a glass "Genome Console"
  (per-gene glyph + value chip/colour-swatch + recessed glowing track + premium
  thumb); replace mismatched Material icons in the tray with custom-drawn glyphs
  (ribcage / polaroid / helix / torn-helix, one `CustomPainter` switching on the
  artifact); a slim 3-beat progress strip (Build·Read·Restore) off the phase; faint
  gold "certified-specimen" corner brackets tying the activity to the card frame;
  a mood-tinted glow + gradient fill on the Helix bubble.

**Verifying animation FX headless:** don't fight the flaky play-through driver —
build a THROWAWAY harness that subclasses the real controller and overrides only
the getters the painter reads (`displayGenome`/`renderMode`/`extinctionProgress`/
`rebuildProgress`/`liveMotion`/`clock`/`phase.value`), then render a GRID of
fixed-progress frames (e.g. extinct@0.35/0.70, rebuild@0.40/0.75) or all render
modes side-by-side. One screenshot validates every mode/frame deterministically.
Same trick renders a single sub-widget (e.g. the artifact tray) in isolation.

## New gotchas folded back in
- **Illustrative-code strings: don't take the LCW's LOW bits.** `letters[x % 4]`
  on a classic LCG (`x = x*1103515245 + 12345`) is near-degenerate → "GAAAAAA…"
  all-one-letter runs (the low 2 bits have a tiny period). Use HIGH bits
  (`letters[(x >> 24) & 3]`) for a well-mixed A/T/C/G string. Caught only by
  *looking* at the rendered string (a screenshot), not by analyze/build.
- **Beat-scoped overlays must be cleared on the beat transition.** The 0.2 peek
  panel + inline fact lingered into 0.3 because nothing reset their flags — clear
  `peekOpen`/`showFact` in `_enterExtinction`. When a panel belongs to one beat,
  reset it when you leave that beat, not just when you enter it.
- **Cascade-after-arrow absorbs the cascade (controller hook setup).**
  `ctrl..onA = () => foo()..onB = ...` parses `..onB` into the lambda body →
  "setter isn't defined for Future<void>". Use **block bodies**
  `..onA = () { foo(); }` for every cascaded callback (same as the other
  activities' haptic hooks).
- **Extension methods need the defining library imported at the USE site.**
  `GeneField.label` (an extension in `genome.dart`) failed in `dna_peek.dart`
  because it imported only the controller — importing `genome.dart` transitively
  doesn't bring the extension into scope. Import the file that declares the
  extension wherever you call it.
- **Headless click targeting on a Flutter canvas: locate by STRUCTURE, not just
  colour.** Colour-thresholding for a small amber "Peek" button kept landing on
  the rainbow colour-slider and the green→amber pattern-fill (multiple amber
  elements). Locating the four slider rows by their **white thumb** blobs (then
  clicking the 3rd row's far right) was unambiguous. For the gold Continue bar,
  detect the wide gold band. Build self-driving Playwright around stable visual
  anchors, and accept that a tiny on-canvas button may still need a few tries —
  it's targeting flakiness, not an app bug (verify by reading the resulting
  screenshot, e.g. "did the bubble line change?").
```
