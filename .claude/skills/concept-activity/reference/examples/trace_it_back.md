# Worked example — Trace It Back (Episode 1, beat 1.1 · generation)

The first **thin-Flame** concept-activity (Handle Lamp + the EP2 series are
pure-Flutter or Flame too, but this one is the cleanest reference for the
Flame-component-tree renderer + a no-mascot, caption-only build). PRD:
`prd_activity2_generator_traceback (1).md` + `howwow_activity2_update_consolidated.md`.
Lives at `lib/screens/missions/trace_it_back/`. Wired as Episode 1's resource of
the "How Electricity Reaches Your Home" WOW concept.

Teaches methodology + contracts, not a look to copy.

## The load-bearing rule
**Almost all electricity is made by *spinning a magnet* — one universal trick — and
a power source is just a tireless replacement for your hand.** The kid spins a
magnet → a bulb lights; **hold it still → it dies instantly** (the hard cutoff,
same rule as Handle Lamp). Then they turn a turbine by hand (same trick, one step
back), then a source takes over the turning, and they walk six sources that all
just spin the same magnet — *only solar breaks it.*

## Renderer: thin Flame (the reference for it)
A vertical scene graph of ~9 layers → Flame, kept dumb (controller owns
sim+geometry+phase). `trace_back_game.dart`: transparent `backgroundColor`,
`onGameResize → setStageSize`, `update → tick`, `onLoad → addAll([...layers])`.
Input is a Flutter `Listener` over the GameWidget forwarding `localPosition →
controller.onPointer*` (the controller computes the turn angle about the active
grab-point — magnet in b1, turbine in b2). No Forge2D; the spin is a hand-rolled
signed-angular-velocity integration.

## File map
```
trace_it_back_screen.dart        # shell: bg + GameWidget(once) + gesture Listener + top caption + Next/Continue + earn overlay
config/
  trace_back_tuning.dart         # factor geometry (vertical chain) + physics + timings
  source_defs.dart               # 6 EnergySource defs (kind, accent, spinsTurbine/usesMagnet, flowColor)
  trace_back_beats.dart          # TBCaption (imperative vs meaning, +long), all copy, kSourceOrder, source two-beats
engine/
  trace_back_bot_engine.dart     # now JUST the TBPhase enum (the dialogue engine was deleted with Voltix)
state/
  trace_back_controller.dart     # ChangeNotifier: physics + geometry + the silent step machine
game/
  trace_back_game.dart           # thin FlameGame
  components/scene_components.dart# the layers (bg glow, ambient motes, source+flow, shaft, turbine, wire, coil/magnet, bulb, discovery ring, grab hint)
widgets/
  energy_field_background.dart    # the Flutter bg behind the transparent GameWidget
```
(Note: `widgets/trace_voltix_helper.dart` + `source_selector.dart` were **deleted** —
the mascot and the chooser both went away. See below.)

## Novel patterns this added to the skill

- **Connector TYPE = meaning (not decoration).** The chain has three *visually
  distinct* connectors and the type teaches *where electricity is born*: the **WIRE**
  (bulb↔coil) is the ONLY segment with a current-pulse; the **SHAFT** (magnet↔turbine)
  shows rotation but NO pulse; the **FLOW** (turbine↔source) is per-source particles.
  Because the pulse lives only above the coil, the screen silently says "electricity
  is born at the spinning magnet; everything below is just motion + fuel" — pre-empting
  the "current flows from the coal" misconception with zero words.
- **Vertical chain, anchored connectors.** Top→bottom bulb → wire → coil/magnet →
  shaft → turbine → flow → source, all `dx=0.5`. Connectors are computed from the
  REAL component edges (wire = bulb screw-base `bulbBaseDrop` → coil top; shaft into
  the coil bottom AND into the turbine hub) and the component draws ON TOP of the
  overlap, so the join always reads solid. ("Wire/shaft float, not joined" was the
  fix.) "Make it bigger / shift the whole chain down to clear the caption" = one-line
  factor edits.
- **Sequential sources with two converging beats (repetition is the lesson).** No
  chooser. The activity auto-shows coal→gas→nuclear→hydro→wind→solar, one at a time,
  advanced by a single **Next** button. Each source is TWO captions: an input that
  *varies* then a result that *converges on the same word* — "Coal Burns → Steam Spins
  It", "Gas Burns → Steam Spins It", "Atoms Split → Still Just Steam", … so by solar
  the kid has read "spins it / same spin / same wheel" five times and **"No Spinning
  Here"** lands as a record-scratch. The accumulation does the teaching; don't
  pre-spoil solar in any earlier source's copy or visual.
- **Witnessed-absence for the odd-one-out.** Solar skips the magnet + turbine. Don't
  show a static gap — **fade the shared core OUT as an event** (`coreFade` eased to 0,
  ~0.4s) as the kid enters solar, so they *see* the part every other source had being
  removed. A solar panel fades in where the magnet was; the sun casts ray-beams (not
  particle "bullets") up to it.
- **A process must be LEGIBLE — a labeled flow diagram, not an abstract box.** The
  thermal source first shipped as a pretty vertical "blue box with flames" → the user
  couldn't tell what it was. Fixed by drawing it as a **horizontal, labeled flow**:
  `[fuel] → [heat] → [boiling water] → [steam]`, an icon per step + a **text word
  under each** (`TextPainter` in the Flame canvas) + arrows, on a subtle dark-glass
  panel. Only step 1's icon+label varies (Coal lumps / Gas cylinder / splitting
  Atoms); heat→water→steam are shared. Legibility came from the WORDS, not prettier
  art.
- **Entrance reveals + a handoff surge.** Each component eases in (`reveal` 0→1,
  slide+scale+fade) as its beat arrives — the chain *assembles* downward. When the
  source takes over, ramp the drive 0→full (`handoffRamp`) so the bulb *surges* to
  life, not pops.

## No mascot — two caption registers
Voltix (mascot + speech bubble + 26 VO clips + the whole bot engine) was **deleted**.
Replaced with two de-personified registers in one fixed-height top slot:
- **Imperatives** — big bold Bricolage 28px ("Spin the Magnet", "Turn the Turbine").
- **Meaning-lines** — the lesson; rendered at the SAME big size EXCEPT one `long`
  flag for the depth-stop, which stays 17–18px so it fits. (`TBCaption{meaning, long}`.)
The caption uses the **sequential fade-out→swap→fade-in** widget, NOT AnimatedSwitcher
(the cross-fade overlapped the two lines for ~280ms — a real bug the user caught).
The shared card-earn overlay was parameterised with `showMascot:false` so the reward
moment is mascot-free too (default keeps Voltix for the other activities).

## Get the physics right (the depth-stop journey — a real lesson)
The "deeper why" caption went through four corrections, all user-driven, each a
genuine accuracy fix — **verify pedagogy claims with a web search; never assert from
memory; the audience is 12–80, not kids:**
1. "Nobody can explain why" → **false.** Induction IS explained (Maxwell, then
   relativity). It's a *depth-stop* (a real deeper reason, just advanced), never a
   mystery.
2. "You'll meet the deep reason in a few years" → **wrong audience.** 12–80, not
   schoolkids — don't frame the depth as homework-for-later.
3. "The deep reason is Einstein's relativity" → *accurate* (relativity unifies E&M;
   induction literally opens Einstein's 1905 paper) BUT a sharp reader objects "isn't
   that Faraday's law?" — Faraday's law is the *rule*; relativity is the deeper *why
   they're one thing*. Both true at different layers; verified by search.
4. "Magnetism is simply electricity in motion" → **wrong for permanent magnets**
   (their field is electron *spin*, intrinsic, not moving charge — and the activity's
   magnet IS permanent). Cut it.
Final, fully-honest line: **"Electricity and magnetism are two sides of the same coin
called electromagnetism."** The real law lives on the collectible card; the caption
only needs to be true and awe-adjacent.

## On-device tuning notes
- Chain `dy` factors pushed DOWN (~+0.04) so the bulb cleared the caption; hero sizes
  bumped ~25% to fill the column.
- The instant-cutoff is honoured in b1 AND b2 (kid-driven); b3 is source-driven so it
  stays steadily lit (a plant doesn't tire — correct).
- Audio was added (clip-indexed VO via the caption channel + BGM + voice-pacing +
  audio-focus fix) then fully REMOVED when Voltix was cut; only BGM remains. The
  audio-hook stubs (`onDiscovery`/`onSourceStep` → haptics) stayed so audio can drop
  back in trivially.
