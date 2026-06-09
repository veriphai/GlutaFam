# Example 2 — Satellite Superpowers: Restore Earth (aim-and-fire, Flame)

Second activity built with this playbook. A *different mechanic* from Build
Satellite — proof the methodology generalises. Use as a blueprint when an
activity is "aim a tool at a target on a scene and trigger an effect."

Lives at: `lib/screens/missions/restore_earth/`

## Mechanic & tech
- **Mechanic:** select 1 of 4 powers (Flutter buttons) → **drag an aiming reticle
  on the Earth (in the Flame canvas)** → release → check `power == correctPower`
  AND `reticle within hotspot` → correct: beam + per-scenario repair timeline +
  progress; wrong: soft fizzle + tiered hint; missed: "aim closer" (not a wrong
  power). 7 scenarios, 3 rounds, completion badge + next-episode hook.
- **Tech:** Flame stage + Flutter shell. The aim gesture is **native Flame** via a
  full-stage **gesture-catcher component** (`PositionComponent with TapCallbacks,
  DragCallbacks`, `containsLocalPoint => true`) — handles tap AND drag reliably
  (the game-level `PanDetector` missed taps and `TapDetector` is deprecated). NOT a
  Flutter→Flame `DragTarget`, because the drag happens *inside* the stage rather
  than starting from a Flutter tray. Power selection is Flutter → controller.

## Module layout
```
restore_earth/
  restore_earth_screen.dart            # shell: header/rail/stage(+zone labels)/mission panel/powers/CTA
  config/  asset_paths · powers · scenarios · earth_layout(THE tuning map)
  state/   restore_earth_state(immutable+enums) · restore_earth_controller(ChangeNotifier) · analytics(no-op)
  game/    restore_earth_game(gesture-catcher; components on root; transparent bg)
    components/ earth_stage · satellite · problem · reticle · beam · icon_fx
    effects/    repair_effects(per-scenario timelines) · completion_controller
  widgets/ activity_header · progress_rail · mission_panel · power_panel · power_button · cta_button · zone_labels
lib/screens/activities/activities_screen.dart   # hub listing all activities
```

## Patterns worth reusing (new this build)
- **Native in-stage aiming via a gesture-catcher component** (`TapCallbacks` +
  `DragCallbacks`, `containsLocalPoint => true`): forward `event.canvasPosition` /
  accumulated `localDelta` to the game; magnetic-ease the reticle to the hotspot,
  swap to the "active" sprite when near. **Reticle spawns OFFSET from the target**
  (random distance) so aiming is a skill, and the hit target is **biased onto the
  object body** (sprites carry shadow below centre).
- **Icon-font glyphs rendered in the Flame canvas** (`IconFx`): a `TextPainter`
  paints an `IconData` (`fontFamily`/`fontPackage` + `codePoint`) with pop-in +
  glow — used for the location-pin/wifi/thunderstorm/etc. payoff symbols, replacing
  poor AI effect sprites. The success tick is the reused green-check **badge sprite**
  (copied in from How Much Can You See).
- **Dim-base + emerge-and-zoom focus:** dim the Earth's own sprites, then present
  the active zone enlarged + centred, animating it rising from its place on the
  Earth and zooming in (component Move+Scale, one coord space — no camera).
- **Constant-stage bottom UI:** mission panel / powers / CTA occupy fixed reserved
  heights and only *reorder* by phase (intro: mission drops above Start; play:
  mission above powers) — so the `GameWidget` never resizes and the aim stays
  aligned on every screen.
- **Completion = connection beams, not a halo:** coloured beams draw from the
  satellite to each zone and stay lit (Earth "fully connected") + badge — the
  additive online-glow overlay was cut (blew out the bright Earth).
- **Programmatic beam + route:** the vertical beam sprites + island route sprites
  don't transform cleanly, so the beam is a 3-pass additive line (outer glow / mid
  / white core) and the navigation route is a self-drawing glowing polyline
  (progress 0→1). (PRD §14.1 explicitly allows this.) Endpoint glow sprites used.
- **Composited diorama from a bare base + props:** `earth_layout.dart` holds the
  base placement + each district's `center`/`width` factor + zone-label positions.
  One map drives the Flame composite AND the Flutter label overlay. **Heavy live
  tuning expected** — the props are mini-islands (seams).
- **Config-driven content:** `powers.dart` (4) + `scenarios.dart` (7, with
  hotspot factor + forgiving radius + per-scenario copy + `RepairKind`). Reskin =
  swap these + `earth_layout` + assets.
- **No-op analytics:** `analytics.dart` implements the 9 PRD events as debug logs;
  calls are wired at the real points, ready for a real tracker.
- **Activities hub + bottom-nav entry:** `ActivitiesScreen` lists every activity;
  the career `CareerBottomNav` got an optional `onSelect(label)` callback, and the
  home pushes the hub on the "Play" tab. New activities = one entry in the hub.
- **Text-in-Flutter over a Flame stage:** zone-label pills are Flutter widgets
  positioned from the SAME earth-rect factors the Flame composite uses.

## Asset issues hit (carry forward)
- All sprites baked-checkerboard 1254² → strip_bg + downscale (107MB → 17MB).
- **Mislabeled assets:** `07_mascot/orbit_mascot_idle.png` & `_excited` are green
  checkmarks, `_celebrate` is a burst — only `hint`/`oops` are the robot. Reused
  the **satellite face sprites** as the mission-panel mascot expressions instead.
  → Always eyeball every sprite; don't trust filenames.
- Route/`*_route_path` and `*_zone_props` repairs are whole-island renders, not
  clean overlays → routes drawn programmatically; districts composited + tuned.
