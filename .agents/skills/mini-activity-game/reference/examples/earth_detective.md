# Example — Earth Detective Mission (Episode 8, Satellite Engineer)

**Mechanic:** a six-mission **satellite-image investigation**. Mission Control
sends a satellite image; the child drags a **scanner reticle** over it (lens
glows *near* the clue, locks *on* it), then taps to lock the clue → overlay
reveal → impact "why it matters" → next mission. Four interaction modes share one
stage: **scan-and-tap** (cyclone / flood / dry farm), **follow-trail** (forest
fire — find the source, not the biggest smoke), **zoom-and-tap** (ship in ocean),
**compare-before-after** (forest change — a slider wipes the "after" image in).
Ends with a six-badge summary and the payoff *"Because of you, the warning can be
sent early."*

**Learning goal:** satellite images carry readable Earth clues, and finding them
early lets people respond (warn, rescue, protect crops/forests, track ships).

> ⚠️ Reference for STRUCTURE & methodology only. Author behaviour from the PRD,
> and match the provided per-screen visual mocks (they were the spec here).

Lives at: `lib/screens/missions/earth_detective/`

## Tech chosen + why — **Flutter shell + ONE Flame stage (synced via `update()`)**

Mostly a Flutter scene state-machine (`EdScene` enum via `AnimatedSwitcher`):
intro → tutorial → per-mission **play → impact** ×6 → summary → reward. Only the
mission-play scene embeds a Flame stage (the satellite image + scanner + overlays
+ zoom + before/after). The `GameWidget` is built **once** in the shell and passed
into the play scene.

**Key correctness decision:** because the play scene mounts/unmounts as the child
moves between missions, the stage syncs the active mission by **diffing
`controller.state.missionIndex` inside `SatelliteImageStage.update()`** — NOT a
controller listener added in `onLoad`/removed in `onRemove`. The listener version
shipped first and broke: after the first unmount the listener was gone and
missions 2–6 all kept showing mission 1's image. (Now a universal gotcha.)

**One shared transform:** the stage renders scene image, scan-grid HUD, clue
overlays, the scanner reticle, and the before/after composite all in ONE
component with one `imageRect`/`displayRect` (zoom about the scanner focal,
clamped). Everything maps through `normToScreen`/`screenToNorm`, so hit zones stay
correct under zoom and nothing drifts. The satellite + beam + scanner draw OUTSIDE
the image clip (satellite floats in a reserved top headroom band).

## Module layout
```
earth_detective/
  earth_detective_screen.dart   # shell: controller + Flame game (built once) + SFX/haptics + idle timer; AnimatedSwitcher by EdScene
  config/asset_paths.dart       # EdAssets registry (flame-relative) + edFlutter() + kEdAspect + EdSounds
  config/missions.dart          # 6 EarthDetectiveMission (PRD copy verbatim, normalised hit/proximity zones) + EdCopy
  models/earth_detective_mission.dart   # InteractionMode, OverlayAnim, MissionOverlayConfig, EarthDetectiveMission
  state/earth_detective_state.dart      # EdScene/PlayPhase/ScannerState/MascotPose enums + immutable state + copyWith
  state/earth_detective_controller.dart # ChangeNotifier: scanner drag, tap resolve, hint escalation, zoom, slider, scene flow
  state/analytics.dart          # no-op debug logs
  game/earth_detective_game.dart        # FlameGame: preload, full-stage tap+drag catcher, gesture → controller
  game/components/satellite_image_stage.dart  # the one big stage component (render + transform + reticle + overlays + compare)
  scenes/{intro,tutorial,mission_select,mission_play,impact,summary,reward}_scene.dart
  widgets/{ed_top_bar,ed_cta_button,mascot_helper_bubble,mission_instruction_card,
           earth_detective_progress_rail,final_reward_panel}.dart
```
(`mission_select_scene` is kept but unreached — flow switched to linear
auto-advance; it's a one-line restore.)

## What was reused vs new

**Reused:** the immutable-state + single-`ChangeNotifier` pattern, the
scene-state-machine shell (How Much / Choose), the full-stage `TapCallbacks +
DragCallbacks` gesture catcher (Restore Earth), the runtime aspect-map idea
(Choose), `careerTheme`/`careerCommon`/`cosmicBackground`, no-op analytics,
transparent-`backgroundColor()` Flame root, the Activities-hub entry, project SFX,
the "reuse a sibling activity's polished asset" rule (we pulled the bright robo
mascots + the Earth hologram from Choose the Right Satellite).

**New (folded into the skill):**
- `update()`-diff sync for a scene-switched embedded `GameWidget` (the listener
  bug + fix).
- Programmatic **scanner/target reticle** (concentric rings + crosshair + rotating
  sweep + translucent centre, cyan→green state tint) — same painter for the
  tutorial demo and the live stage; replaced 5 AI scanner sprites.
- **Zoom as free exploration on every mission** with explicit +/− controls (not a
  cycle-up button), magnify-about-focal + clamp.
- **Speech bubble with a conical tail** + situational mascot-pose mapping.
- **Visual-mock fidelity** as the acceptance criterion (intro/tutorial rebuilt to
  the mocks); use the provided mission-control bg instead of the house cosmic bg.
- **Baked-checker-in-RGB** detection (transparent corners ≠ clean interior) and
  the **mask-don't-crop** fix for a round subject (circle-masked the hologram;
  colour-keyed the deforestation overlay interior).
- Fixed-aspect-panel letterbox decision + reserved headroom + aligning overlay
  controls to the image rect (zoom-button-centring bug).

## Asset pipeline used
Clean kit (alpha corners α=0) → **skipped `strip_bg.py`**, trim-bbox + downscale
the PNGs, JPEG'd the 7 scene images (4:3) + 2 full-bleed backgrounds (114MB →
19MB). Two sprites had **opaque checkerboard baked into the RGB** that the
corner-alpha probe passed but rendered as a visible checker in-app: the Earth
hologram (fixed by detecting the globe circle and applying a feathered ellipse
mask — a rectangular crop had sliced a flat bottom) and the deforestation overlay
(fixed by colour-keying out the bright neutral interior, keeping the red ring).
Reprocessing changed aspect ratios → had to update `kEdAspect` + dependent sizes.

## Layout / tuning notes
All clue hit/proximity zones are normalised `Rect`s in `config/missions.dart`,
seeded from the scene art and tuned on device. The satellite headroom is
`SatelliteImageStage._topHeadFactor` (0.20 of width); overlay controls in
`mission_play_scene` offset by the same factor to stay centred on the image. This
activity took ~20 mock-driven visual iterations after it compiled — backgrounds,
mascot swaps, panel polish, scanner/zoom UX, asset re-cropping — budget that.
