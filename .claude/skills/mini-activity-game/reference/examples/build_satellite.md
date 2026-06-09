# Example 1 — Build Your Satellite (drag-and-assemble, Flame)

The first activity built with this playbook. Use it as a concrete blueprint when
a new activity has a similar shape (a "stage" where the child places parts onto
a base). It is **fully config-driven**: to make a similar mission you mostly swap
`part_catalog` + `slot_config` + `mission_steps` + assets and reuse the generic
game/widget/state code.

> ⚠️ **Reference for STRUCTURE & methodology only.** Do not copy this activity's
> interactions, animation beats, effects, meters, or feel. Those must come from
> the new activity's own PRD + storyboard. Reuse the *plumbing* (module layout,
> the bridge, state pattern, asset pipeline) — author the *behaviour* from the PRD.

Lives at: `lib/screens/missions/build_satellite/`

## Mechanic & tech
- **Mechanic:** 7-step guided assembly — drag each part from a tray onto the
  correct slot on the satellite body; meters (Power / Signal / Stability) fill;
  finish unlocks a launch preview + reward popup.
- **Tech:** **Flame** for the build stage (spatial drop detection, install
  animations) inside a **Flutter** shell (tray, header, meters, rail, mascot,
  popup). Chosen because it needs spatial drag-drop onto a rendered scene.

## Module layout
```
build_satellite/
  build_satellite_screen.dart   # Flutter shell — see "the bridge" below
  config/
    asset_paths.dart            # SatAssets registry: dual Flame/Flutter path
                                #   flavours + preload list; SatSounds
    part_catalog.dart           # SatellitePart: id, sprite, slotId, step,
                                #   mascot copy, deploymentKey, meter deltas
    slot_config.dart            # SlotConfig: positionFactor/partAnchor/width/
                                #   angle as factors RELATIVE to the body rect
  state/
    build_satellite_controller.dart  # ChangeNotifier; installPart/registerWrongDrop
    build_satellite_state.dart       # immutable state (step, installed, meters…)
    mission_steps.dart               # ordered steps: intro/success copy + required parts
  game/
    build_satellite_game.dart        # FlameGame; components on game ROOT
    components/                      # satellite_body, drop_zone, installed_part
    effects/                         # deployment + launch-preview animations
  widgets/
    inventory_tray.dart  mission_header.dart  status_meters.dart
    step_progress_rail.dart  mascot_helper.dart  reward_popup.dart
    launch_preview_button.dart  mission_tip_card.dart  tilt_view.dart
```

## Key patterns (reusable beyond this mission)
- **Coordinate model:** components are added to the **game root** (no camera
  world), so game coords == GameWidget logical pixels. The Flutter→Flame drop is
  then a trivial global→local offset conversion.
- **The bridge:** the screen wraps the `GameWidget` in a `DragTarget<String>`.
  While dragging it feeds the pointer (`details.offset`, via `pointerDragAnchorStrategy`)
  to `game.updateHover(...)` (lights the matching slot ring); on release it converts
  the global offset with `renderBox.globalToLocal` and calls
  `game.tryPlace(partId, localOffset)`, which does spatial slot detection, plays
  correct/wrong feedback, spawns the installed part, and updates the controller.
- **Drag source (immediate, not hold):** the tray is a horizontally **scrolling**
  `ListView` of comfortable cards; each active card is a `Draggable<String>` with
  **`affinity: Axis.vertical`** — a vertical drag grabs the part instantly, a
  horizontal swipe scrolls the tray. (We started with `LongPressDraggable` and
  removed it: hold-to-drag is wrong for a kids' mobile app.) The active card
  auto-scrolls into view at each step.
- **Fake-3D feel:** the build stage is wrapped in `tilt_view.dart` (perspective
  `Matrix4`: idle sway + drag-to-tilt that springs back, ~±10°) so the flat
  single-angle satellite reads as a solid object. Kept subtle so drops stay accurate.
- **Shell layout:** the screen is a `Stack` of `Positioned.fill` layers
  (cosmic background / content `Column` / reward overlay) so `Expanded` is
  height-bounded and the meters/tray/launch button stay on-screen on tall phones.
- **State:** one `ChangeNotifier` owns an immutable state object; the Flame game
  calls it after placement; the Flutter shell rebuilds via `ListenableBuilder`.
  No Provider/Riverpod.
- **Resolution independence:** slot positions are factors of the body rect, so
  the layout holds on any screen size — tuning a snap point = editing one number.
- **Asset registry with two path flavours** (the gotcha worth copying):
  - Flame `images.load` wants the path **relative to** `assets/images/` (prefix implicit) → `build_satellite/x.png`.
  - Flutter `Image.asset` wants the **full** path → `assets/images/build_satellite/x.png`.
- **Reuse:** pulls `careerTheme`, `careerCommon`, `cosmicBackground` from the home
  feature, and existing SFX (`jumpSound`, `correct_answer`, `incorrect_answer`,
  `levelComplete`).

## Asset pipeline used
Source sprites were generated with baked checkerboard backgrounds (`hasAlpha: no`).
`tools/process_satellite_sprites.py` (the project-specific batch processor that
the generic `scripts/strip_bg.py` was distilled from) flood-fills the background
from the borders, clears large enclosed cut-outs (camera bay) via per-sprite
`min_hole_area`, de-fringes, trims, downscales, and writes
`assets/images/build_satellite/` + an `asset_meta.json` whose `content_center_norm`
helped derive slot anchors.
