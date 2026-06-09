# Signal Rescue Mission (Activity 7) — worked example

**Mechanic:** aim-and-time — rotate a satellite antenna toward a ground station,
**wait for the communication window**, check battery, lock the signal, then send
the cyclone image as data packets that reveal a Mission-Control monitor.

**Tech:** **Flutter shell + a single Flame stage**, *controller-owns-geometry*
variant. Closest to `orbit_launcher` (GameWidget built once, `ChangeNotifier`
controller, `AnimatedBuilder` overlays) but with **in-stage drag** (the antenna)
handled by a full-stage `PositionComponent with TapCallbacks, DragCallbacks`
(`containsLocalPoint => true`) like `restore_earth`.

## Why this split
The PRD's signal logic is *continuous* (angle × range × battery → state), so the
usual "controller = discrete state, game = motion" split is bent: here the
**controller owns the logic AND the scene geometry**, and the game is a pure
renderer + input forwarder. This kept all the PRD §10 thresholds in one testable
place.

- The game reports the stage size once (`controller.setStageSize`), then each
  frame calls `controller.tick(dt)` and renders from controller getters
  (`satelliteCenterPx`, `antennaPivotPx`, `stationCenterPx`).
- The controller computes pixel anchors from `SRTune` **factor** anchors × stage
  size, advances the orbit clock / battery / timers, runs the signal cascade,
  derives the phase, and writes helper copy — notifying once per change.
- The game feeds back **only** the antenna drag: `aimAt(canvasPos)` → angle from
  pivot → `controller.setAntennaAngle` (with magnetic easing applied in the
  controller).

## Module layout
```
signal_rescue_screen.dart              # Stack of Positioned.fill layers; GameWidget built once
config/  asset_paths.dart  signal_tuning.dart
state/   signal_rescue_state.dart  signal_rescue_controller.dart  analytics.dart
game/    signal_rescue_game.dart
         components/ satellite, antenna, ground_station, signal_beam,
                     data_packet, orbit_path, earth, gesture_catcher
widgets/ activity_top_bar, signal_meter, battery_meter, helper_card,
         send_data_button, mission_monitor, mission_success_overlay, part_callouts
```

## Phase machine
`intro → explainParts → alignAntenna → waitForRange → checkPower → dataLocked →
transmitting → success` (+ `failed`, reachable only if the optional storm timer
is enabled — it ships OFF/forgiving). Early phases auto-advance on `tick` timers;
the **search cluster** (waitForRange/checkPower/dataLocked) is *derived from the
live signal state* each frame (`locked→dataLocked, strong→checkPower,
else→waitForRange`) so the child can slip back and forth without penalty.

## Reused vs new
- **Reused:** the orbit_launcher screen shell idiom, the additive `_spawnEffect`
  helper, the gesture-catcher pattern, careerTheme/careerCommon, app SFX.
- **New (folded into the skill):** controller-owns-geometry; live signal-state
  machine from continuous inputs; programmatic multi-pass beam with a
  dashed-broken mode; the centred communication-window; the Flutter bottom-up
  monitor reveal; the fixed-height action slot.

## Assets
57 sprites, mixed-background pack (all baked, `hasAlpha:no`). Mostly LIGHT
checkerboard → default `strip_bg.py`. Three dark-bg additive FX
(`data_packet_trail_glow`, `signal_beam_red_glitch`, `monitor_reveal_mask`)
re-stripped at `--min-bright 24 --neutral-tol 34 --min-hole-area 1500`. Three
full-bleed rectangles (`cyclone_image_full`+alt, `static_overlay`) → JPEG from
originals (no flood-fill — it would eat the photo's own light clouds). The Earth
globe stripped to transparent corners (ideal for placing on the dark stage). 60MB
→ 13MB.

## Voice-over + BGM (29-clip Orbit track)
Implements the **voice choke point** pattern (Power Balance) end-to-end: every
line is a NAMED const in `signal_tuning.dart` keying `orbitClipFor` (line→clip);
the controller's single `_set()` stamps `voiceClip` + bumps `voiceToken` when
`helperMessage` changes. The screen runs three audio lanes (`_sfx`/`_voice`/
`_bgm`) with per-player `AudioFocus.none`+`mixWithOthers` contexts set BEFORE
the BGM loop, volume ducking (0.20→0.05) under speech, a 12s safety Timer, and
`play().catchError` → advance. **Voice-paced clocks:** the briefing `_explainT`
and the line-sequencer `_seqT` FREEZE while a clip plays and release to a 0.35s
breath on completion (muted users fall back to the fixed clocks). The
transmission was stretched (8s→27.5s) with per-line progress windows sized to
each clip's measured duration. Success chain 22→23→24 routes through the
screen's `_voiceDone`; Continue unlocks after 24 (listen-before-skip). Start is
gated on `voicePlaying`; Send deliberately is NOT (gameplay timing beats
listen-gating). **New gameplay consequence of VO:** the orbit clock HOLDS while
`dataLocked` — the lock window (~2.7s) is shorter than the "data locked / tap
send" clips, so without the hold the satellite drifts out of range mid-sentence.

## Tuning still pending (live on-device pass)
All in `config/signal_tuning.dart`: earth globe placement, ground-station anchor
resting on the curve, dish pivot offset + `dishAngleOffset` (the dish sprite's
"forward"), satellite/dish sizes, and the `PartCallouts` label anchors. Beam
colours/widths and the window timing are gameplay-validated but feel-tune on
device.
