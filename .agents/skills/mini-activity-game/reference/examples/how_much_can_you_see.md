# Example — How Much Can You See? (Activity 2, Satellite Engineer)

> **VO note:** carries a 13-clip Orbit voice track (`assets/sounds/how_much_can_you_see/orbit_01..13.mp3`)
> wired per the skill's voice-over pattern — `voiceClip`/`voiceToken`/`voicePlaying` on state,
> config-indexed clips (per-level `voiceClip`, per-wrong-option `wrongVoiceClip`), two audio
> lanes in the shell, stop-before-play + catchError + 12s safety, and `CtaButton.enabled`
> gating (BEGIN / TAKE CHALLENGE / CONTINUE wait for the line; rail + cards stay usable).
> This is the LIGHT variant: voice never drives transitions (flow stays user-driven), so no
> `onVoiceFinished` router is needed — only the playing flag.

**Mechanic:** guided **discovery / drag-a-slider** — a camera marker is dragged up
a vertical height rail through six levels (Ground → Building → Mountain → Drone →
Airplane → Satellite); the view (background + glowing visible-area circle) grows
with height. Ends with a 4-option **multiple-choice challenge** (place the camera
to watch a cyclone → Satellite), a success beat, and a next-mission teaser.

**Learning goal:** higher altitude = wider view of Earth (one concept only).

## Tech chosen + why — **Flutter + Flame hybrid** (a scene state-machine)

This activity is mostly a **multi-scene state machine** (8 PRD scenes) with
full-screen background crossfades and lots of Flutter text — pure Flutter would
have been defensible. We used the **hybrid** the PRD recommended:

- **Flame** renders ONLY Scene 2's animated *stage*: crossfading scene
  backgrounds, the floating drone/airplane/satellite (slide-in + bob/glide), and
  the drifting cloud / blocked-view / city-lights / forest overlays. (A glowing
  visible-area ring + scan cone were built but **removed per user feedback** —
  even at normal alpha they veiled the scene; the backgrounds zooming out already
  carry "you see more with height".) ⚠️ **Additive only over a DARK stage** — see
  the gotcha; these bright scene backgrounds blew additive glows out to white.
- **Flutter** owns everything else: the scene router, the draggable height rail
  + node labels, the Mission Control panel text, the 2×2 challenge grid, and the
  intro/success/bridge/teaser scenes.

The rail lives in **Flutter**, not Flame (same call as Restore Earth's
ProgressRail) — a 1-D snap drag that needs text labels beside each node is far
simpler as a Flutter `Stack` + `GestureDetector` than as Flame components.

## Module layout

```
lib/screens/missions/how_much_can_you_see/
  how_much_can_you_see_screen.dart   # shell: owns controller + Flame game (built ONCE) + SFX + idle timer; AnimatedSwitcher scene router
  config/
    asset_paths.dart                 # HM registry (.flame/.flutter); backgrounds are .jpg; stagePreload list
    height_levels.dart               # ViewHeightLevel enum + HeightLevelConfig map (label/view/problem/mission/bg/area/cone/object/overlays/railNormY) + nearestLevelForNormY()
    challenge_options.dart           # 4 options + per-option wrong feedback; correct = satellite
    scene_copy.dart                  # all non-level Flutter text
  state/
    how_much_state.dart              # ActivityScene enum (8) + immutable HeightViewActivityState + copyWith
    how_much_controller.dart         # ChangeNotifier state machine; satellite delayed unlock (Timer); challenge logic
    analytics.dart                   # no-op debug analytics
  game/
    height_stage_game.dart           # FlameGame stage; reacts to controller; per-level composition with tunable layout factors
    components/
      cover_background.dart          # BoxFit.cover bg + crossfade (old→0, new 0→1, scale 1.04→1.0)
      floating_stage_object.dart     # drone/airplane/satellite; entrance lerp + idle bob/glide ALL in update()
      drift_overlay.dart             # clouds drift / glow layers breathe; opacity envelope ALL in update()
  widgets/
    mission_header.dart  cta_button.dart  mission_control_panel.dart
    height_rail.dart                 # rail + 6 nodes + draggable marker (snap) + labels + tap-to-jump
    choice_card.dart  mascot_robot.dart
  scenes/
    story_intro_scene.dart  mission_test_scene.dart  exploration_scene.dart
    cyclone_challenge_scene.dart  success_scene.dart  story_bridge_scene.dart  teaser_scene.dart
```

## What was reused vs new

**Reused:** the state pattern (immutable state + single `ChangeNotifier` +
`AnimatedBuilder`), `careerTheme`/`careerCommon` (`Floaty`, `PressableScale`,
`RevealOnLoad`, `GlassSurface`), `cosmicBackground`, the no-op analytics shape,
the transparent-`backgroundColor()` Flame stage with components on the game root,
additive `BlendMode.plus` for glow sprites, the existing app SFX, and the
Activities-hub entry pattern.

**New (folded into the skill):**
- **Scene state-machine shell** — `AnimatedSwitcher` keyed by an `ActivityScene`
  enum routes 8 full-screen scene widgets; the Flame `GameWidget` is built once
  in the shell and passed into the one scene that needs it (never re-attached).
- **Flame stage embedded as ONE scene** of an otherwise-Flutter activity.
- **`update()`-vs-`Effect` conflict gotcha** (see below).
- **JPEG the full-bleed backgrounds** (22M PNG → 5.3M JPEG, no alpha needed).

## Asset prep notes

- Every one of the 60 sprites was `hasAlpha: no` (light-grey checkerboard).
  Folders 02–07 → `strip_bg.py` flood-fill-from-border (the **dark navy** panels
  & choice cards are correctly kept — the fill only removes the *bright* border
  region). Folder 01 (backgrounds) → copied, then converted to JPEG q86.
- The glow UI (marker, rail, nodes, visible-area circles, scan cones) keeps a
  faint pale matte fringe from the glow's own soft falloff — **not** removable as
  background. Over the dark stage it's hidden by rendering those **additively**
  (`BlendMode.plus`) in Flame; the Flutter rail/marker sit over bright scene
  backgrounds where the fringe disappears anyway.
- The robot character pack here IS correctly labelled (unlike Restore Earth's).

## Layout tuning

All stage positions/sizes are factors of the stage rect in
`height_stage_game.dart` (`_areaWidthFactor`, `_coneWidthFactor`,
`_objectLayout`, `_overlaySpec`) and the rail node positions are `railNormY` in
`height_levels.dart`. These were eyeballed from the styleboard/mockup — **budget
a live tuning pass** on a tall device viewport.
