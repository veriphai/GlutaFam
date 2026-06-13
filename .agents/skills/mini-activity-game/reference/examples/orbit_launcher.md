# Example 3 — Orbit Launcher (slider-sim + scripted trajectory, Flame)

Third activity built with this playbook. A *third distinct mechanic*: a one-knob
**parameter simulation** — set a value, watch a scripted outcome, iterate to the
"just right" band. Use as the blueprint when the brief is "tune one input until a
target behaviour emerges" (orbit, trajectory, mixing, balancing, dosing…).

Lives at: `lib/screens/missions/orbit_launcher/`

## Mechanic & tech
- **Mechanic:** Tap LAUNCH → satellite goes straight up + falls (teaches "height
  alone isn't enough") → unlock a single **Sideways Speed** slider (0–100) →
  TEST LAUNCH → the speed maps to one of four banded outcomes
  (`≤42 tooSlow · 43–61 almost · 62–78 orbitLocked · 79–100 tooFast`) → each
  plays a distinct scripted trajectory → fail = Try Again (keep slider), success
  = Continue → bridge screen (empty-box satellite orbiting + 6 part-icon tease).
  **No real physics** — outcomes are thresholds, motion is authored curves.
- **Tech:** Flame stage + Flutter shell, but the **opposite input split** from
  restore_earth: the game owns **no input at all**. All controls (LAUNCH / slider
  / TEST / card buttons) are Flutter widgets calling the controller; the Flame
  game purely **listens to the controller** and plays the scene's visuals,
  calling back at beats (`straightLaunchDone`, `launchResolved`) to advance.

## Module layout
```
orbit_launcher/
  orbit_launcher_screen.dart           # full-bleed Stack: cosmic + GameWidget + Positioned overlays
  config/  asset_paths · orbit_tuning(THE tuning map: framings, thresholds, durations, colours) · parts_catalog
  state/   orbit_launcher_state(immutable + OrbitActivityState/OrbitOutcome/McMood) · controller(ChangeNotifier) · analytics(no-op)
  game/    orbit_launcher_game(transparent bg; root components; listener-driven; scripted runners)
    components/ earth(horizon↔globe crossfade + geometry source) · launch_pad · satellite_actor · trajectory(dashed renderer) · orbit_ring
  widgets/ activity_top_bar · mission_control_bubble · sideways_speed_slider · orbit_button(shared CTA) · result_card · bridge_panel
lib/screens/activities/activities_screen.dart   # +1 EP-3 entry
```

## Patterns worth reusing (new this build)
- **Controller-driven Flame (zero in-stage input):** the game adds a single
  `controller` listener; a `switch(scene)` against a cached `_lastScene` fires
  each transition's sequence **once**, and intra-scene notifies (slider moves)
  fall through to a live-preview update. The opposite of restore_earth's
  PanDetector aiming — pick this when the gameplay is driven by Flutter controls,
  not by touching the stage.
- **Two-framing Earth with a crossfade (`earth_component.dart`):** one component
  holds BOTH a bottom "horizon" band and a centred "globe", crossfades opacity
  (+ a small globe scale-up) between them, and is the **single geometry source of
  truth** (`globeCenter/globeRadius/orbitRadius/launchPoint`) the game reads to
  build trajectories. Delivers the PRD's "zoom-out is the aha moment" cheaply.
- **Scripted trajectories as authored curves (`trajectory_component.dart` +
  builders):** a reusable dashed-polyline renderer (`setPath`/`progress`/`color`,
  two-pass additive glow+core) driven by a generic `_FlightRunner`
  (0→1 over duration·curve, `onStep`/`onDone`) that samples the path
  (`pointAtFraction`) to move the satellite **in lock-step with the revealed
  dashes**. Curves are built from `_bezier`/`_arc` helpers off the live earth
  geometry. A separate `_OrbitRunner` sweeps an angle for the continuous loop.
  → Reuse for any "object travels an authored path while a trail draws in".
- **Banded-outcome parameter sim:** `OT.outcomeFor(int)` is the whole "physics".
  Thresholds + per-band colour/curve/copy live in config; trivially retunable.
- **Live predicted-path preview:** the same trajectory renderer at low opacity,
  rebuilt on each slider change, colour-coded by band — shows intent before commit.
- **Shared CTA widget (`orbit_button.dart`):** one gradient-pill button (glow +
  idle pulse + disabled state) reused by LAUNCH/TEST/TryAgain/Continue/Build.
- **Full-bleed stack shell:** unlike restore_earth's Column, the stage is
  `Positioned.fill` and all chrome floats as `Positioned` overlays (MC bubble
  top-left, scene-swapped bottom panel via `AnimatedSwitcher`). More immersive;
  the bottom panel is bottom-anchored so it can't be pushed off a tall viewport.

## Asset issues hit (carry forward)
- All 28 sprites baked-bg, `hasAlpha: no` (34 MB → 9 MB after strip + downscale).
- **Dark-checkerboard backgrounds:** `orbit_ring_glow` + `success_sparkles` shipped
  on a *dark* grey checkerboard (below the default `--min-bright 228`), so the
  first pass stripped **nothing** (0% transparent). Fix: re-run with
  `--min-bright 24 --neutral-tol 34`. Then the ring's **enclosed interior** + the
  sparkle **central blob** survived as holes → add `--min-hole-area 5000 / 1200`.
  General rule: a 0.0%-transparent result on a glow sprite = the checkerboard is
  dark; lower `--min-bright` and clear enclosed holes.
- **No mislabeled files this time** — all 28 matched their names (verified by eye).
- `crash_puff` (grey smoke) + `confetti_burst` (colourful) render **normal blend**;
  every other effect (beam/glow/ring/trail/sparkles/warning) is **additive**.

## Live-tuning notes (expected pass)
Spatial factors in `orbit_tuning.dart` were eyeballed from the mockup: horizon
height/anchor, `launchPoint`/`padCenter`, globe centre/radius, `orbitRingWidthMul`
(align the glow loop to the orbit), and the per-outcome arc control points in the
game's `_play*` builders. Budget one device pass to nudge these.
