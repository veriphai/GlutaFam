# Example — Code the Satellite (drag-to-arrange sequencing + mission SIMULATOR)

Activity 10. The child arranges 9 command blocks into a sequence, runs the
mission, and watches the satellite EXECUTE each command step by step; a wrong
order fails at the exact step whose precondition is unmet and explains why.

> ⚠️ Reference for STRUCTURE & methodology only. Author behaviour from the PRD.

Lives at: `lib/screens/missions/code_satellite/`

## Mechanic & tech
- **Mechanic:** drag-to-arrange a 9-step program (tray ⇄ horizontal timeline,
  replace/reorder/remove), then a **step-by-step simulator** plays each command —
  the satellite swaps to that command's state sprite + the named effect fires
  (PRD §10). Validation is a **state-dependency step machine** (`validateAndApply`,
  PRD §8), NOT an array-compare: it mutates a `MissionState` and fails at the
  first unmet precondition with a kid-friendly reason. Debug → reorder → retry.
- **Tech:** **Flutter + Flame hybrid.** Flutter owns every scene, the timeline,
  the tray, drag/drop, all text, overlays, rewards. Flame owns ONE permanent
  stage (satellite actor + props + additive effects). This is the **inverse of
  signal_rescue's controller-owns-geometry**: here the game owns NO gestures and
  NO logic — the controller orchestrates and *pushes* animation to the game.

## Why this split — controller-awaits-stage execution loop
The core loop is "run the program one instruction at a time." So the controller's
`async runMission()` loop `await`s `game.playCommand(cmd)` — each call swaps the
sprite, spawns effects, and completes its Future after the beat. The game exposes
a tiny **`MissionStage` interface (declared in state/, implemented by the game)**
so `state/` never imports `game/` → one-directional controller→game, no import
cycle, no listener on the game side. Clean separation of *discrete orchestration*
(controller) from *per-command animation* (game).

## Module layout
```
code_satellite_screen.dart            # shell: Stack of Positioned.fill (cosmic bg / GameWidget / scene switcher)
config/  asset_paths.dart  code_satellite_tuning.dart   # CS registry + palette + stage anchors + timings
models/  satellite_command.dart       # enum + meta (label/icon/state sprite/explanation) + correct order
state/   mission_validation.dart      # MissionState + MissionStepResult + validateAndApply (PRD §8 verbatim)
         code_satellite_state.dart    # immutable state; Activity10Phase + SceneGroup + OrbitMood
         code_satellite_controller.dart  # ChangeNotifier + MissionStage interface + run loop
         analytics.dart               # no-op debug logs
game/    code_satellite_game.dart     # FlameGame implements MissionStage; command-driven renderer
         components/stage_components.dart  # SatelliteActor / PropActor / TravelingSprite
widgets/ command_block (CommandCard) / command_timeline / command_tray / mission_header /
         orbit_dialogue / cta_button / captured_thumbnail / failure_overlay / success_overlay
scenes/  intro_scene / brief_scene / play_scene
```

## Phase machine
`storyIntro → missionBrief → arranging → running → (failed → arranging) | success`
(PRD §17). `SceneGroup` maps arranging+running+failed all to the **`play`** scene
(failure is an overlay over the puzzle, no remount) — routed by an
`AnimatedSwitcher` keyed by `SceneGroup` (KeyedSubtree). intro/brief/success are
their own scenes.

## Reused vs new
- **Reused:** the signal_rescue screen-shell idiom (GameWidget built ONCE as a
  permanent Positioned.fill), the additive `_spawnEffect` helper, careerTheme/
  careerCommon (PressableScale/Floaty/RevealOnLoad), app SFX, `textScaler`
  noScaling, the Activities-hub entry, no-op analytics.
- **New (folded into the skill):** controller-awaits-stage execution loop; the
  `MissionStage` interface-in-state pattern; drag-to-arrange permutation puzzle;
  the permanent-stage-but-not-every-scene layering.

## Assets
88 sprites, **clean kit** (real alpha, transparent corners, 15–85% coverage) →
trim-to-bbox + downscale ONLY, no flood-fill (would erase Orbit's white body +
white success glows). Skipped `01_satellite_core` (used the 12 pre-composed
`02_satellite_states`) and `04_command_blocks` (block/slot FRAMES drawn in Flutter
— the baked block sprites ship at mismatched sizes; only the `05_command_icons`
cut-outs are used). One dark-checkerboard glow (`sparkle_burst`, 0% transparent)
re-stripped at `--min-bright 24 --neutral-tol 34 --min-hole-area 1200`. Verified
every state/mascot/icon via dark-navy montages (no mislabels). 178MB → 21MB.

## Voice-over (60-clip Orbit track)
Combines the existing skill patterns rather than inventing new ones:
**choke-point map** in the controller's `_set` (`kOrbitClipForMessage` built
arithmetically from the command list: coach=11+i, wrong=21+i, "Running: X"=32+2i,
beat=33+2i — Power Balance pattern), `voiceClip`+`voiceToken`+`voicePlaying`
state, shell `_voice` lane with `voiceStarted/Finished/Failed`, and a
**voice-paced run loop**: the "Running: X" status clip narrates OVER the command
animation, then `_voicePaced()` (gate on completion / clip-length muted fallback
/ failed→advance-now / clip+5s safety) before the beat line, and again before
the next step. Static scenes (intro/brief/success threads) use a reusable
`OrbitVoiceThread` (own player, completion-driven `current` index for bubble
reveals, clip+2.5s reading fallback, idempotent advance, dispose-stops).
Listen-before-skip on the success Continue; Run Mission gated on `voicePlaying`.
An explicit `voiceClip` stamp in `rejectPlace` re-voices repeated identical
wrong lines (the choke point's message-diff would swallow them).

## Tuning still pending (live on-device pass)
All in `config/code_satellite_tuning.dart`: `CSStage` satellite/prop anchors +
widths (satellite center & size, sun/earth/station/chip placements), the bob
amplitude, and the stage-vs-bottom-panel split (the play scene leaves the upper
region transparent for the stage — confirm the satellite sits above the timeline
on a tall viewport and the bottom controls are fully visible). Beat timings in
`CSTiming` are gameplay-validated but feel-tune on device.
