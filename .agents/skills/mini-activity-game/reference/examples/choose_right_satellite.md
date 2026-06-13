# Example 5 — Choose the Right Satellite (drag-to-dispatch matching, PURE FLUTTER)

Episode 5 / Activity 5. The first activity built **without Flame** — proof that
when the mechanic is "drag a tray card onto a card" + sprite-overlay effects
(fade/scale/rotate/pulse), Pure Flutter delivers the premium feel with zero
Flame gotchas (no re-attach, no stage-resize drift, no global→local bridging).

> ⚠️ Reference for STRUCTURE & methodology only. Author behaviour from the PRD.

Lives at: `lib/screens/missions/choose_right_satellite/`

## Mechanic & tech
- **Mechanic:** five Mission Control dispatch missions. A mission card slides in;
  the child drags the correct satellite from a 4-card tray onto the glowing
  dispatch zone. Correct → snap flash → mission-specific success effect (GPS
  beam / weather scan rings / comm waves / camera scan cone) → reveal layer
  (location pin / brightened Wi-Fi / lit TV) → success label + green border.
  Wrong → soft orange pulse + card shake + bounce-implied + two-tier hint
  escalation (soft → stronger + pulse correct card → "try this one"). Ends with a
  5-card Mission Log + a power "bridge" to the next activity.
- **Tech:** **Pure Flutter.** `Draggable`/`DragTarget` for dispatch;
  `AnimationController`s for every beat; sprite overlays composited with
  **normal alpha** (NOT additive — the mission art is bright, and the playbook
  warns `BlendMode.plus` blows glows out to white over bright backgrounds; the
  effect sprites are clean cut-outs so alpha reads as a glow without blowout).

## Module layout
```
choose_right_satellite/
  choose_right_satellite_screen.dart  # shell: Stack of Positioned.fill (bg image / scrim / scene switcher)
  config/asset_paths.dart             # CrsAssets registry + kCrsAspect map + CrsSounds
  data/choose_satellite_missions.dart # the 5 missions, PRD copy VERBATIM
  models/satellite_type.dart          # enum + label/sprite/accent/glyph extension
  models/satellite_mission.dart       # SceneLayer (factor anchors) + EffectPlacement + mission
  state/choose_satellite_state.dart   # immutable state; scene/phase/mascot enums
  state/choose_satellite_controller.dart  # ChangeNotifier; resolveDrop/hints/markSolved
  state/analytics.dart                # no-op debug logs (PRD §26)
  scenes/{intro,mission_play,mission_log,bridge}_scene.dart
  widgets/{mission_header,mission_progress,mission_card,dispatch_zone,
           satellite_tray,success_effect_layer,mascot_helper,mission_log_card,
           cta_button,scene_positioning,idle_motion}.dart
```

## Key patterns (reusable beyond this mission)
- **Pure-Flutter tray→card dispatch:** the play scene wraps the mission card in a
  `DragTarget<SatelliteType>`; `onMove`→`setHovering(true)` lights the zone
  (whole-card hover, kid-friendly — no GlobalKey coordinate math), `onLeave`→
  false, `onAcceptWithDetails`→`controller.resolveDrop(type)`. A drop OUTSIDE the
  card never reaches the target (Flutter only fires accept within bounds) → "drop
  outside = no wrong attempt" (PRD §25.1) is free. Tray cards are immediate
  `Draggable`s (never LongPress) with `dragAnchorStrategy: pointerDragAnchorStrategy`
  and feedback centred via `Transform.translate(-size/2)` + a drag-trail sprite.
- **Controller owns discrete state, scene owns timing:** the `ChangeNotifier`
  holds scene/phase/hint/tokens; the scene listens and **diffs cached values**
  (`_lastPhase`, `_lastIndex`, `_lastWrongToken`) to fire `AnimationController`s —
  never from `build()`. Chaining via status listeners: correct drop → phase
  `resolving` → `_snap.forward()` → on done `_effect.forward()` → on done
  `controller.markSolved()` (phase `solved`). Plain 0..1 values feed a **stateless-
  timing** `MissionCard` (`enterT/snapT/effectT/wrongT`), so all the juice lives in
  one widget that owns no controllers.
- **One-shot transient via a token:** wrong feedback is fired by bumping
  `wrongPulseToken` in state; the scene plays the pulse+shake exactly once when the
  token changes. Cleaner than a bool you must reset.
- **One-active-drag rule in state:** `activeDragType` + `canDrag(type)` =
  `trayEnabled && (activeDragType == null || == type)` disables the other three
  cards mid-drag; `trayEnabled` is false while resolving/solved (PRD §25.3–4).
- **Config-driven layered scenes:** each mission's illustration is a list of
  `SceneLayer`s with `centerFactor`/`widthFactor` (fractions of the scene rect) +
  flags (`revealOnSuccess`, `driftUp`, `rotateOnSuccess`, `idleOpacity`). One
  `crsLayer(scene, centerFactor, widthFactor, aspect, child)` helper places
  everything — layers, the success effect, the docked satellite, snap flash. Swap
  data + assets to reskin.
- **Runtime aspect map instead of decoding:** `kCrsAspect` holds each sprite's
  intrinsic w/h (captured at asset-processing time) so factor-based center
  placement is exact without async `ui.Image` decode. Cheap and precise.
- **Scene state-machine shell (4 scenes):** `ActivityScene` enum routed by an
  `AnimatedSwitcher` keyed by scene; the 5 missions all reuse ONE `missionPlay`
  scene (controller swaps mission data; sub-states don't remount). Mirrors
  How Much Can You See.
- **Per-mission success effect from one value:** `SuccessEffectLayer(type, t)`
  with a fade-in/hold/fade-out **envelope** + type-specific math (gps beam settle+
  pulse, weather rings scale 0.8→1.15 + rotate, two staggered comm waves, camera
  cone L→R sweep). All from a single `_effect` controller's 0..1.
- **Reused house kit:** `careerTheme`, `careerCommon` (`PressableScale`, `Floaty`,
  `RevealOnLoad`, `GlassSurface`), existing SFX (`jumpSound`/`correct_answer`/
  `incorrect_answer`), `MediaQuery textScaler noScaling`, the Activities-hub entry.

## Asset pipeline used
The kit arrived **already clean** — every sprite had real alpha (corners α=0,
25–75% coverage) and correct filenames (verified via dark-navy contact sheets).
So `strip_bg.py` was deliberately NOT run (its border flood-fill would have
erased the white art — white clouds, `mission_cloud_overlay_white`, the snap
flash, the robot's white body). A small PIL pass only **trimmed to the alpha
bbox + downscaled** (39MB→9.7MB) and converted the opaque `mission_control_background`
PNG→JPEG. Lesson: when `hasAlpha: yes` AND corners are transparent, skip the
flood-fill and just trim/resize.

## Voice-over (v2 script, 37 clips)
Implements the playbook's full VO stack in PURE FLUTTER (no Flame bridge):
`lineIndex`/`voiceToken`/`voicePlaying` on the immutable state; every mutation
that changes the dialogue list resets lineIndex + bumps the token (markSolved
deliberately does NOT — resolving→solved share the success lines, so the
sequence keeps playing across it). One `onVoiceFinished()` router advances
multi-line sequences and holds on the last line. THREE audio lanes (sfx /
looping ambient / voice) each get the per-player `AudioFocus.none` mix context;
ambient ducks to 25% while Orbit speaks. Reading-time fallback (3.8s) covers
muted users, missing clips, AND web autoplay-block (catchError takes the same
fallback rather than advancing instantly — instant advance would fast-cycle the
intro silently). Primary CTAs gate on `voicePlaying` (dim + IgnorePointer).
Dialogue lives as `OrbitLine(text, clip)` — clip numbers 1–37 in master-script
order, files `orbit/orbit_NN.mp3`, renamed from `scene-N-*.wav` at copy-time and
verified by the duration sanity-check (shortest line = smallest file).
